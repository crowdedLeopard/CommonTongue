-- CommonTongue / Core.lua
--
-- Settings, the chat hook and the slash commands: everything that connects
-- the engine to the game.
--
-- How a chat line is handled (B:Process):
--   1. the per-session cache answers lines seen before
--   2. the translation memory answers sentences the companion translated
--   3. the detector names the language and the engine translates
--   4. if the live bridge is on, the line is shown at once and the machine
--      translation is appended a moment later
--
-- The addon is loaded in TOC order: UTF8, Text, English, Engine, Detect, the
-- dictionaries, Memory, Learned, Bridge, Core, Options. Core registers the
-- chat filter at ADDON_LOADED and finishes setup at PLAYER_LOGIN.
--
-- Public API (CommonTongue):
--   B:Process(msg, author, lineID)   decorated line, or nil to leave it alone
--   B:ShowLate(line, tr, src, machine)  append a translation to a line on screen
--   B:TranslateOutgoing(text, toLang)   translate the player's own text
--   B:HandleSlash(input)               the /tongue command
--   B:Print(msg), B:Status(), B:Help(), B:ClearCache()

local ADDON_NAME = ...
local B = CommonTongue
local U = B.UTF8
local T = B.Text
local Memory = B.Memory
local Bridge = B.Bridge

--- The version is the single ## Version line of the TOC.
local function addonVersion()
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local v = get and get(ADDON_NAME, "Version")
  if type(v) == "string" and v ~= "" and not v:find("@", 1, true) then return v end
  return "dev"
end
B.Version = addonVersion()

-- Client locale -> language to translate into, used on first run.
local LOCALE_TO_LANG = {
  enUS = "en", enGB = "en", deDE = "de", esES = "es", esMX = "es", frFR = "fr",
  itIT = "it", ptBR = "pt", ptPT = "pt", ruRU = "ru", koKR = "ko", zhCN = "zh", zhTW = "zh",
}

-- Saved variables (CommonTongueDB). Missing keys are filled in at login, so
-- a new setting never needs a migration.
local DEFAULTS = {
  enabled = true,
  target = nil,            -- filled from GetLocale() on first load
  mode = "inline",         -- inline | replace | below
  showTag = true,          -- show the [es>en] tag
  translateSelf = false,   -- translate my own messages too
  minCoverage = 0.34,      -- hide translations that understood less than this share of words
  color = "7fd4ff",        -- built-in translation
  colorLive = "8fe38f",    -- machine translation (memory and live bridge)
  live = true,             -- use the live bridge when the companion is running
  companion = false,       -- keep chat logging on for the companion overlay
  flush = nil,             -- set by the bridge once a companion has been seen
  channels = {
    SAY = true, YELL = true, GUILD = true, OFFICER = true, PARTY = true, RAID = true,
    INSTANCE = true, WHISPER = true, CHANNEL = true, EMOTE = false, BN_WHISPER = false,
  },
  ignore = {},             -- language codes never to translate
  taught = {},             -- entries added with /tongue teach
  missing = {},            -- unknown words seen, per language
  welcomed = false,        -- the first-run message was shown
  debug = false,
}

-- Chat events -> the channel setting that governs them.
local EVENT_CHANNEL = {
  CHAT_MSG_SAY = "SAY",
  CHAT_MSG_YELL = "YELL",
  CHAT_MSG_GUILD = "GUILD",
  CHAT_MSG_OFFICER = "OFFICER",
  CHAT_MSG_PARTY = "PARTY",
  CHAT_MSG_PARTY_LEADER = "PARTY",
  CHAT_MSG_RAID = "RAID",
  CHAT_MSG_RAID_LEADER = "RAID",
  CHAT_MSG_RAID_WARNING = "RAID",
  CHAT_MSG_INSTANCE_CHAT = "INSTANCE",
  CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE",
  CHAT_MSG_BATTLEGROUND = "INSTANCE",
  CHAT_MSG_BATTLEGROUND_LEADER = "INSTANCE",
  CHAT_MSG_WHISPER = "WHISPER",
  CHAT_MSG_CHANNEL = "CHANNEL",
  CHAT_MSG_EMOTE = "EMOTE",
  CHAT_MSG_BN_WHISPER = "BN_WHISPER",
}
B.EVENT_CHANNEL = EVENT_CHANNEL
B.CHANNEL_ORDER = { "SAY", "YELL", "GUILD", "OFFICER", "PARTY", "RAID", "INSTANCE", "WHISPER", "CHANNEL", "EMOTE", "BN_WHISPER" }

local CACHE_MAX = 300      -- distinct lines remembered before the cache is cleared
local AUTHORS_MAX = 500    -- speakers whose language is remembered

-- raw message -> decorated line | false (leave alone) | table (live request pending)
local cache, cacheCount = {}, 0
-- speaker -> language they last wrote in (a hint for the detector)
local authorLang, authorCount = {}, 0
local playerName

--- Fill in missing settings, recursively for nested tables.
local function copyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      copyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

--- Print a line to the default chat frame with the addon's prefix.
function B:Print(msg)
  local frame = DEFAULT_CHAT_FRAME or ChatFrame1
  if frame then frame:AddMessage("|cff7fd4ffCommonTongue|r: " .. tostring(msg)) else print(msg) end
end

--- Forget cached results and speaker languages (after any setting that
-- changes what a line would look like).
function B:ClearCache()
  cache, cacheCount = {}, 0
  authorLang, authorCount = {}, 0
end

--- Cache the outcome for a raw message.
local function remember(msg, result)
  if cacheCount >= CACHE_MAX then B:ClearCache() end
  if cache[msg] == nil then cacheCount = cacheCount + 1 end
  cache[msg] = result
end

--- Remember which language a speaker used.
local function rememberAuthor(author, lang)
  if authorLang[author] == nil then
    if authorCount >= AUTHORS_MAX then authorLang, authorCount = {}, 0 end
    authorCount = authorCount + 1
  end
  authorLang[author] = lang
end

--- Is this chat author the player (with or without a realm suffix)?
local function isSelf(author)
  if not author or author == "" or not playerName then return false end
  local name = author:match("^[^%-]+") or author
  return name == playerName
end

--- Send a chat message through whichever API the client offers.
local function sendChat(text, chatType, target)
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  if send then send(text, chatType, nil, target) end
end

-------------------------------------------------------------------------------
-- Formatting
-------------------------------------------------------------------------------

--- The text appended to a chat line.
-- @param machine  true for memory and live results (green), false for the
--                 built-in engine (blue)
local function suffixText(translated, from, to, machine)
  local db = B.db
  local color = "|cff" .. (machine and (db.colorLive or "8fe38f") or (db.color or "7fd4ff"))
  local tag = db.showTag and (from .. ">" .. to .. ": ") or ""
  if db.mode == "below" then
    return "\n" .. color .. "    " .. tag .. translated .. "|r"
  end
  return " " .. color .. "[" .. tag .. translated .. "]|r"
end

--- The whole decorated line for the current display mode.
local function formatResult(msg, translated, from, to, machine)
  local db = B.db
  if db.mode == "replace" then
    local color = "|cff" .. (machine and (db.colorLive or "8fe38f") or (db.color or "7fd4ff"))
    local suffix = db.showTag and (" |cff888888[" .. from .. "]|r") or ""
    return color .. translated .. "|r" .. suffix
  end
  return msg .. suffixText(translated, from, to, machine)
end

-------------------------------------------------------------------------------
-- Message processing
-------------------------------------------------------------------------------

--- Decide what to show for an incoming chat line.
-- @param msg     raw message text
-- @param author  sender name ("Name-Realm"), may be nil
-- @param lineID  the client's line id, needed to edit the line later; may be nil
-- @return the decorated message, or nil when the line should stay as it is
--         (nothing to translate, or a translation will be appended later)
function B:Process(msg, author, lineID)
  local db = B.db
  local cached = cache[msg]
  if cached ~= nil then
    if type(cached) == "table" then
      -- still waiting for the live translation of this text
      if lineID then
        Bridge:Request(cached.key, { id = lineID, msg = msg, lang = cached.lang, fallback = cached.fallback, author = author })
      end
      return nil
    end
    return cached or nil
  end

  local target = db.target or "en"
  local key = T.LooseKey(msg)
  if #key < 2 then
    -- nothing to translate: "o/", ":D", a lone letter
    remember(msg, false)
    return nil
  end

  -- 1. translation memory
  local known, src = Memory:Lookup(msg, target, key)
  if known ~= nil then
    local result = false
    if known ~= "" and U.Lower(known) ~= U.Lower(msg) then
      result = formatResult(msg, known, (src and src ~= "" and src ~= ">") and src or "?", target, true)
    end
    remember(msg, result)
    return result or nil
  end

  -- 2. language detection and the built-in translator
  local prior = author and authorLang[author]
  local lang, confidence, english, stats, unknownForeign = B:DetectLanguage(msg, prior)
  local gloss
  if lang and lang ~= target and not db.ignore[lang] then
    local translated, coverage, _, _, st = B:TranslateText(msg, lang, target, english, stats)
    -- probably another language altogether: little evidence for this one and
    -- a good part of the words unknown
    local shaky = (confidence < 0.3 and coverage < 0.6) or (confidence < 0.1 and coverage < 0.8)
    -- a line made only of dropped filler words translates to nothing: leave it alone
    if translated and translated:find("[^ \t\r\n]") and not shaky and coverage >= (db.minCoverage or 0) and U.Lower(translated) ~= U.Lower(msg) then
      gloss = translated
    elseif db.debug then
      if translated then
        B:Print(("skipped %s (%d%% understood): %s"):format(lang, coverage * 100, msg))
      else
        B:Print(("no dictionary for %s: %s"):format(lang, msg))
      end
    end
    if translated and confidence >= 0.5 and coverage >= 0.5 then
      if author then rememberAuthor(author, lang) end
      if st then B:NoteMissing(lang, st.unknown) end
    end
  elseif not (lang == nil and unknownForeign and Bridge.live and Bridge:SlotsLeft() > Bridge.slots * 0.3) then
    if db.debug and lang then B:Print(("detected %s (ignored): %s"):format(lang, msg)) end
    remember(msg, false)
    return nil
  end

  -- 3. live bridge: show the line now, add the machine translation when it arrives
  if (Bridge.live or Bridge:ShouldRetry()) and db.live ~= false and lineID then
    local from = lang or "?"
    local entry = { key = key, lang = from, fallback = gloss and suffixText(gloss, from, target, false) or nil }
    remember(msg, entry)
    Bridge:Request(key, { id = lineID, msg = msg, lang = from, fallback = entry.fallback, author = author })
    return nil
  end

  local result = gloss and formatResult(msg, gloss, lang, target, false) or false
  remember(msg, result)
  return result or nil
end

--- Append text to a chat line that is already on screen, in every chat window.
-- @param lineID  the client's line id
-- @param suffix  text to append (not appended twice)
-- @return true when at least one line was changed
function B:AppendToLine(lineID, suffix)
  local changed = false
  local maxWindows = (Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows)
    or NUM_CHAT_WINDOWS or 10
  local function predicate(message, r, g, b, infoID, accessID, typeID, event, eventArgs)
    return type(eventArgs) == "table" and eventArgs[11] == lineID
  end
  local function transform(message, ...)
    local ok, new = pcall(function()
      if message:find(suffix, 1, true) then return message end
      return message .. suffix
    end)
    if ok and new then
      if new ~= message then changed = true end
      return new, ...
    end
    return message, ...
  end
  for i = 1, maxWindows do
    local frame = _G["ChatFrame" .. i]
    if frame and frame.TransformMessages then
      pcall(frame.TransformMessages, frame, predicate, transform)
    end
  end
  return changed
end

--- The bridge has an answer (or gave up) for a line shown earlier.
-- @param line     the request record given to Bridge:Request
-- @param tr       translation; "" when the line is already in the target
--                 language; nil when the companion did not answer, in which
--                 case the built-in gloss (line.fallback) is used
-- @param src      source language the companion reported
-- @param machine  colour the result as a machine translation
function B:ShowLate(line, tr, src, machine)
  if cache[line.msg] ~= nil then
    cache[line.msg] = nil
    cacheCount = cacheCount - 1
  end
  local suffix
  if tr == nil then
    suffix = line.fallback
  elseif tr ~= "" and U.Lower(tr) ~= U.Lower(line.msg) then
    local from = (src and src ~= "" and src ~= ">") and src or line.lang or "?"
    suffix = suffixText(T.Relink(tr, line.msg), from, B.db.target or "en", machine)
  end
  if not suffix then return end
  if not B:AppendToLine(line.id, suffix) then
    -- the line has scrolled out of every window: print the translation on its own
    local frame = DEFAULT_CHAT_FRAME
    if frame then
      local who = line.author and (line.author:match("^[^%-]+") .. ": ") or ""
      frame:AddMessage("   " .. who .. (suffix:gsub("^[ \t\r\n]+", "")))
    end
  end
end

--- The chat message event filter. Returns the decorated message in place
-- of the original, hides the addon's own whispers to the companion, and
-- never raises: a failure leaves the line untouched.
local function chatFilter(frame, event, msg, author, ...)
  local db = B.db
  if not db then return false end
  if issecretvalue and (issecretvalue(msg) or issecretvalue(author)) then return false end
  if type(msg) ~= "string" or msg == "" then return false end
  if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM") and msg:find("^%[CT[>%?]") then
    return true -- our own request to the companion: keep it out of the chat window
  end
  if not db.enabled then return false end
  local channel = EVENT_CHANNEL[event]
  if not channel or not db.channels[channel] then return false end
  if type(author) ~= "string" then author = nil end
  if not db.translateSelf and isSelf(author) then return false end
  local lineID = select(9, ...)
  if type(lineID) ~= "number" then lineID = nil end
  local ok, newMsg = pcall(B.Process, B, msg, author, lineID)
  if ok and newMsg then return false, newMsg, author, ... end
  if not ok and db.debug then B:Print("error: " .. tostring(newMsg)) end
  return false
end
B.ChatFilter = chatFilter

-------------------------------------------------------------------------------
-- Speaking another language:  /tsay es hello everyone
-------------------------------------------------------------------------------

--- Translate the player's own text from the target language into another.
-- @param text    what the player typed
-- @param toLang  language code
-- @return translation, nil, coverage; or nil and an error message
function B:TranslateOutgoing(text, toLang)
  local source = (B.db and B.db.target) or "en"
  toLang = U.Lower(toLang or "")
  if toLang == "" then return nil, "missing language code" end
  if toLang ~= "en" and not B.Languages[toLang] then
    return nil, ("no dictionary for '%s' (see /tongue langs)"):format(toLang)
  end
  local translated, coverage = B:TranslateText(text, source, toLang)
  if not translated then return nil, "translation unavailable" end
  return translated, nil, coverage
end

local CHAT_PREFIX = { SAY = "/s ", YELL = "/y ", PARTY = "/p ", RAID = "/raid ", GUILD = "/g " }

--- Put text into the chat box for the player to send with Enter.
local function openChat(text)
  local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
  if open then
    open(text, DEFAULT_CHAT_FRAME)
    return true
  end
  return false
end

--- A machine translation of the player's own text arrived, or timed out.
-- The result goes into the chat box rather than straight out: sending
-- needs a hardware event, and the player should see it first.
-- @param req      the request record from Bridge:RequestOutgoing
-- @param tr       translation, nil to fall back to the built-in engine
-- @param machine  whether tr came from the companion
function B:DeliverOutgoing(req, tr, machine)
  if not tr then
    tr = B:TranslateOutgoing(req.text, req.lang)
    if not tr then return end
  end
  if req.chatType == "PREVIEW" then
    B:Print(("(%s) %s"):format(req.lang, tr))
    return
  end
  local prefix = CHAT_PREFIX[req.chatType] or ("/w " .. tostring(req.target) .. " ")
  if openChat(prefix .. tr) then
    B:Print(machine and "translation ready in the chat box: press Enter to send." or
      "the companion did not answer; built-in translation is in the chat box: press Enter to send.")
  else
    B:Print(("(%s) %s"):format(req.lang, tr))
  end
end

--- The /tsay family: "<lang> <text>", or "<player> <lang> <text>" for whispers.
local function speak(chatType, input, needsTarget)
  input = input or ""
  local target
  if needsTarget then
    target, input = input:match("^([^ \t\r\n]+)[ \t\r\n]+(.*)$")
    if not target then B:Print("usage: /twhisper <player> <lang> <text>") return end
  end
  local lang, text = input:match("^([A-Za-z][A-Za-z])[ \t\r\n]+(.+)$")
  if not lang then
    B:Print(("usage: /t%s <lang> <text>   e.g. /t%s es hello, need a tank"):format(chatType:lower(), chatType:lower()))
    return
  end
  lang = lang:lower()
  if Bridge.live and B.db.live ~= false and playerName then
    -- ask the companion through a whisper to ourselves (hidden by the chat filter)
    sendChat("[CT>" .. lang .. "] " .. text, "WHISPER", playerName)
    Bridge:RequestOutgoing(T.LooseKey(text), { chatType = chatType, lang = lang, target = target, text = text })
    return
  end
  local translated, err = B:TranslateOutgoing(text, lang)
  if not translated then B:Print(err) return end
  if chatType == "PREVIEW" then
    B:Print(("(%s) %s"):format(lang, translated))
    return
  end
  sendChat(translated, chatType, target)
end

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

local function onoff(v) return v and "|cff44ff44on|r" or "|cffff4444off|r" end

--- "on"/"off" and their synonyms; anything else toggles.
local function parseBool(arg, current)
  arg = (arg or ""):lower()
  if arg == "on" or arg == "1" or arg == "true" or arg == "yes" then return true end
  if arg == "off" or arg == "0" or arg == "false" or arg == "no" then return false end
  return not current
end

--- Keep chat logging on or off for the companion's overlay window.
function B:SetCompanion(enabled)
  B.db.companion = enabled
  if LoggingChat then LoggingChat(enabled) end
end

--- Print the available dictionaries with their entry counts.
function B:ListLanguages()
  local parts = {}
  for _, code in ipairs(B.LanguageOrder) do
    if code ~= "en" then
      local L = B.Languages[code]
      parts[#parts + 1] = ("%s=%s (%d)"):format(code, L.name, L.entryCount)
    end
  end
  B:Print("Target: |cffffff00en|r=English, " .. table.concat(parts, ", "))
end

--- Print the current settings and the state of the live bridge.
function B:Status()
  local db = B.db
  local chans = {}
  for _, c in ipairs(B.CHANNEL_ORDER) do if db.channels[c] then chans[#chans + 1] = c:lower() end end
  local ignored = {}
  for code in pairs(db.ignore) do ignored[#ignored + 1] = code end
  B:Print(("v%s  translating %s  into |cffffff00%s|r (%s)  mode=%s  tag=%s  self=%s  min=%d%%")
    :format(B.Version, onoff(db.enabled), db.target, B:LanguageName(db.target), db.mode,
            onoff(db.showTag), onoff(db.translateSelf), (db.minCoverage or 0) * 100))
  B:Print("channels: " .. table.concat(chans, " ") .. (#ignored > 0 and ("   ignoring: " .. table.concat(ignored, " ")) or ""))
  B:Print(("memory: %d sentences   live translation: %s"):format(Memory.count, Bridge:Status()))
end

-- The command table. Each entry: names (first is canonical), a usage line
-- for /tongue help, and the handler, which receives the rest of the input.
local COMMANDS, COMMAND_ORDER = {}, {}
local function command(names, usage, run)
  local entry = { usage = usage, run = run }
  for _, name in ipairs(names) do COMMANDS[name] = entry end
  COMMAND_ORDER[#COMMAND_ORDER + 1] = entry
end

command({ "" }, "/tongue                 open the options panel", function()
  if B.OpenOptions then B:OpenOptions() else B:Status() end
end)

command({ "on", "enable" }, "/tongue on|off          enable or disable translation", function()
  B.db.enabled = true; B:Print("translation " .. onoff(true))
end)
command({ "off", "disable" }, nil, function()
  B.db.enabled = false; B:Print("translation " .. onoff(false))
end)
command({ "toggle" }, nil, function()
  B.db.enabled = not B.db.enabled; B:Print("translation " .. onoff(B.db.enabled))
end)

command({ "to", "lang", "target" }, "/tongue to <lang>       language to translate into (en, de, es, fr, ru ...)", function(rest)
  local code = U.Lower(rest)
  if code == "en" or B.Languages[code] then
    B.db.target = code; B:ClearCache()
    B:Print("translating into |cffffff00" .. code .. "|r (" .. B:LanguageName(code) .. ")")
  else
    B:Print("unknown language '" .. rest .. "'"); B:ListLanguages()
  end
end)

command({ "mode" }, "/tongue mode inline|replace|below", function(rest)
  local m = rest:lower()
  if m == "inline" or m == "replace" or m == "below" then
    B.db.mode = m; B:ClearCache(); B:Print("mode: " .. m)
  else
    B:Print("mode must be inline, replace or below")
  end
end)

command({ "tag" }, "/tongue tag on|off      show the [es>en] tag", function(rest)
  B.db.showTag = parseBool(rest, B.db.showTag); B:ClearCache(); B:Print("language tag " .. onoff(B.db.showTag))
end)

command({ "flush" }, "/tongue flush           ask the game to write its chat log now (live bridge check)", function()
  local function state()
    if not LoggingChat then return "n/a" end
    local ok, on = pcall(LoggingChat)
    return (ok and on) and "on" or "off"
  end
  local before = state()
  Bridge:Flush()
  C_Timer.After(0.3, function()
    B:Print(("chat log flush requested (logging was %s, now %s; %d flushes this session)")
      :format(before, state(), Bridge.flushes or 0))
  end)
end)

command({ "self" }, "/tongue self on|off     translate your own messages too", function(rest)
  B.db.translateSelf = parseBool(rest, B.db.translateSelf); B:Print("translate own messages " .. onoff(B.db.translateSelf))
end)

command({ "min" }, "/tongue min <0-100>     minimum share of words understood before showing a translation", function(rest)
  local n = tonumber(rest)
  if n and n >= 0 and n <= 100 then
    B.db.minCoverage = n / 100; B:ClearCache(); B:Print(("minimum understood: %d%%"):format(n))
  else
    B:Print("usage: /tongue min <0-100>")
  end
end)

command({ "chan", "channel" }, "/tongue chan <name> [on|off]   say yell guild officer party raid instance whisper channel emote", function(rest)
  local db = B.db
  local name, state = rest:match("^([^ \t\r\n]+)[ \t\r\n]*([^ \t\r\n]*)$")
  name = name and name:upper()
  if name and db.channels[name] ~= nil then
    db.channels[name] = parseBool(state, db.channels[name])
    B:Print(name:lower() .. " " .. onoff(db.channels[name]))
  else
    B:Status()
  end
end)

command({ "ignore" }, "/tongue ignore <lang>   toggle ignoring a detected language", function(rest)
  local db = B.db
  local code = U.Lower(rest)
  if code == "" then B:Status() return end
  if db.ignore[code] then db.ignore[code] = nil else db.ignore[code] = true end
  B:ClearCache()
  B:Print(("%s %s"):format(code, db.ignore[code] and "ignored" or "translated again"))
end)

command({ "live" }, "/tongue live [on|off]   live machine translation through the companion; no argument: reconnect and show status", function(rest)
  local db = B.db
  local arg = rest:lower()
  if arg == "on" or arg == "off" then
    db.live = (arg == "on")
    if not db.live then Bridge.live = false end
    B:ClearCache()
    B:Print("live translation " .. onoff(db.live))
  end
  if db.live ~= false then
    Bridge:EnsureLogging()
    Bridge:Probe(true)
  end
end)

command({ "teach" }, "/tongue teach <lang> <word or phrase> = <english>     add your own entry", function(rest)
  local code, native, english = rest:match("^([A-Za-z][A-Za-z])[ \t\r\n]+(.-)[ \t\r\n]*=[ \t\r\n]*(.+)$")
  local ok, err = B:Teach(code and code:lower(), native, english)
  if ok then
    B:Print(("learned (%s): %s = %s"):format(code:lower(), native, english))
  else
    B:Print(err or "usage: /tongue teach <lang> <word or phrase> = <english>")
  end
end)

command({ "missing" }, "/tongue missing [lang]  words the dictionaries did not know, most frequent first", function(rest)
  local code = U.Lower(rest)
  local shown = false
  for _, c in ipairs(B.LanguageOrder) do
    if code == "" or code == c then
      local top = B:TopMissing(c, code == "" and 6 or 20)
      if #top > 0 then
        local parts = {}
        for _, e in ipairs(top) do parts[#parts + 1] = e[1] .. " (" .. e[2] .. ")" end
        B:Print(c .. ": " .. table.concat(parts, ", "))
        shown = true
      end
    end
  end
  if not shown then B:Print("no unknown words recorded yet.") end
end)

command({ "companion", "log" }, nil, function(rest)
  B:SetCompanion(parseBool(rest, B.db.companion))
  B:Print("chat logging " .. onoff(B.db.companion) ..
    (B.db.companion and "  (Logs\\WoWChatLog.txt is being written)" or ""))
end)

command({ "test" }, "/tongue test <text>     detect and translate some text", function(rest)
  local db = B.db
  if rest == "" then B:Print("usage: /tongue test <text>") return end
  local lang, confidence, english, stats = B:DetectLanguage(rest)
  if not lang then B:Print("could not detect a language") return end
  B:Print(("detected |cffffff00%s|r (%s, %d%% sure)"):format(lang, B:LanguageName(lang), confidence * 100))
  if lang == db.target then return end
  local translated, coverage, _, _, st = B:TranslateText(rest, lang, db.target, english, stats)
  if translated then
    B:Print(("%d%% understood%s: %s"):format(coverage * 100,
      (st and st.templates > 0) and ", sentence pattern" or "", translated))
  else
    B:Print("no dictionary for " .. lang)
  end
end)

command({ "langs", "languages" }, "/tongue langs           list dictionaries", function() B:ListLanguages() end)
command({ "status" }, "/tongue status          settings and live bridge state", function() B:Status() end)
command({ "debug" }, nil, function(rest)
  B.db.debug = parseBool(rest, B.db.debug); B:Print("debug " .. onoff(B.db.debug))
end)
command({ "reset" }, "/tongue reset           restore the default settings", function()
  local db = B.db
  for k in pairs(db) do db[k] = nil end
  copyDefaults(db, DEFAULTS)
  db.target = LOCALE_TO_LANG[GetLocale()] or "en"
  B:ClearCache(); B:Print("settings reset"); B:Status()
end)
command({ "help", "?" }, nil, function() B:Help() end)

local SPEAK_HELP = {
  "/tsay|/tyell|/tparty|/traid|/tguild <lang> <text>   speak in another language",
  "/twhisper <player> <lang> <text>,  /tprev <lang> <text> (preview only)",
}

--- Print every command's usage line.
function B:Help()
  B:Print("commands:")
  for _, entry in ipairs(COMMAND_ORDER) do
    if entry.usage then B:Print("  " .. entry.usage) end
  end
  for _, l in ipairs(SPEAK_HELP) do B:Print("  " .. l) end
end

--- Run a /tongue command line. Unknown commands print the help; a failing
-- command reports the error instead of raising it into the UI.
-- @param input  everything after "/tongue"
function B:HandleSlash(input)
  input = (input or ""):gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", "")
  local cmd, rest = input:match("^([^ \t\r\n]+)[ \t\r\n]*(.*)$")
  cmd = (cmd or ""):lower()
  rest = rest or ""
  local entry = COMMANDS[cmd]
  if not entry then B:Help() return end
  local ok, err = pcall(entry.run, rest)
  if not ok then B:Print("command failed: " .. tostring(err)) end
end

--- Register the slash commands with the client.
function B:SetupSlash()
  SLASH_COMMONTONGUE1 = "/tongue"
  SLASH_COMMONTONGUE2 = "/commontongue"
  SlashCmdList["COMMONTONGUE"] = function(msg) B:HandleSlash(msg) end

  SLASH_TONGUESAY1 = "/tsay"
  SlashCmdList["TONGUESAY"] = function(msg) speak("SAY", msg) end
  SLASH_TONGUEYELL1 = "/tyell"
  SlashCmdList["TONGUEYELL"] = function(msg) speak("YELL", msg) end
  SLASH_TONGUEPARTY1 = "/tparty"
  SlashCmdList["TONGUEPARTY"] = function(msg) speak("PARTY", msg) end
  SLASH_TONGUERAID1 = "/traid"
  SlashCmdList["TONGUERAID"] = function(msg) speak("RAID", msg) end
  SLASH_TONGUEGUILD1 = "/tguild"
  SlashCmdList["TONGUEGUILD"] = function(msg) speak("GUILD", msg) end
  SLASH_TONGUEWHISPER1 = "/twhisper"
  SLASH_TONGUEWHISPER2 = "/twhis"
  SlashCmdList["TONGUEWHISPER"] = function(msg) speak("WHISPER", msg, true) end
  SLASH_TONGUEPREVIEW1 = "/tprev"
  SlashCmdList["TONGUEPREVIEW"] = function(msg) speak("PREVIEW", msg) end
end

-------------------------------------------------------------------------------
-- Startup
-------------------------------------------------------------------------------

--- ADDON_LOADED: saved variables, taught entries, chat filter, slash commands, options panel.
function B:Initialize()
  CommonTongueDB = CommonTongueDB or {}
  B.db = CommonTongueDB
  copyDefaults(B.db, DEFAULTS)
  if not B.db.target then
    B.db.target = LOCALE_TO_LANG[GetLocale and GetLocale() or "enUS"] or "en"
  end
  if B.db.target ~= "en" and not B.Languages[B.db.target] then B.db.target = "en" end
  B:ApplyTaught()

  local addFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
  if addFilter then
    for event in pairs(EVENT_CHANNEL) do addFilter(event, chatFilter) end
    addFilter("CHAT_MSG_WHISPER_INFORM", chatFilter)
  end
  B:SetupSlash()
  if B.SetupOptions then
    local ok, err = pcall(B.SetupOptions, B)
    if not ok and B.db.debug then B:Print("options panel unavailable: " .. tostring(err)) end
  end
end

--- PLAYER_LOGIN: the player's name, the slot count, the first-run message, the login probes.
function B:OnLogin()
  playerName = UnitName("player")
  local slots = Bridge:Init()
  if B.db.companion and LoggingChat then LoggingChat(true) end
  if not B.db.welcomed then
    B.db.welcomed = true
    B:Print(("ready. Chat in other languages is translated into |cffffff00%s|r (%s). Type /tongue for options.")
      :format(B.db.target, B:LanguageName(B.db.target)))
  end
  if slots > 0 then Bridge:AutoProbe() end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then B:Initialize() end
  elseif event == "PLAYER_LOGIN" then
    B:OnLogin()
  end
end)
