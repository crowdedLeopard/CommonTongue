-- Minimal WoW API stub for testing the addon outside the game.
-- Models the parts of the Forever (1.60.1) client the addon touches:
-- chat filters, chat frames with TransformMessages, timers, load-on-demand
-- addons read from disk at load time, and a chat log file.
_G.__frames = {}
_G.__filters = {}
_G.__sent = {}
_G.__printed = {}
_G.__clock = 0
_G.__timers = {}
_G.__lineID = 100
_G.__loadedAddOns = {}
_G.__opened = {}

GetLocale = function() return _G.__locale or "enUS" end
UnitName = function() return _G.__player or "Tester" end
GetTime = function() return _G.__clock end
time = os.time
issecretvalue = function() return false end

-- chat logging: lines are buffered until the log is "flushed" (toggled or forced)
_G.__logging = false
_G.__logBuffer = {}
_G.__logAutoFlush = true
local function flushLog()
  if _G.__chatlog and #_G.__logBuffer > 0 then
    local f = io.open(_G.__chatlog, "ab")
    if f then
      for _, l in ipairs(_G.__logBuffer) do f:write(l, "\r\n") end
      f:close()
    end
  end
  _G.__logBuffer = {}
end
_G.__flushLog = flushLog
LoggingChat = function(v)
  if v == nil then return _G.__logging end
  if v == false and _G.__logging then flushLog() end
  _G.__logging = v
  return v
end
local function logLine(text)
  if not _G.__logging then return end
  local stamp = os.date("%m/%d %H:%M:%S") .. ".000"
  stamp = stamp:gsub("^0", "")
  table.insert(_G.__logBuffer, stamp .. "  " .. text)
  if _G.__logAutoFlush then flushLog() end
end

-- sending chat
local function send(msg, chatType, lang, target)
  table.insert(_G.__sent, { msg = msg, chatType = chatType, target = target })
  if chatType == "WHISPER" and target == UnitName("player") and not _G.__noSelfWhisper then
    logLine("To " .. target .. ": " .. msg)
    __chat("CHAT_MSG_WHISPER_INFORM", msg, target)
    logLine(target .. " whispers: " .. msg)
    __chat("CHAT_MSG_WHISPER", msg, target)
  end
end
SendChatMessage = send
C_ChatInfo = { SendChatMessage = send }

SlashCmdList = {}
InterfaceOptions_AddCategory = function() end
Constants = { ChatFrameConstants = { MaxChatWindows = 2 } }

-- timers on a manual clock
C_Timer = {
  After = function(delay, fn)
    table.insert(_G.__timers, { t = _G.__clock + delay, fn = fn })
  end,
}
function __advance(dt)
  local target = _G.__clock + dt
  while true do
    local best, bi
    for i, tm in ipairs(_G.__timers) do
      if tm.t <= target and (not best or tm.t < best.t) then best, bi = tm, i end
    end
    if not best then break end
    table.remove(_G.__timers, bi)
    _G.__clock = best.t
    best.fn()
  end
  _G.__clock = target
end

-- load-on-demand addons, read from disk when loaded
C_AddOns = {
  GetAddOnMetadata = function(name, field)
    if field == "Version" then return _G.__tocVersion or "dev" end
    return nil
  end,
  DoesAddOnExist = function(name)
    if not _G.__addonsDir then return false end
    local f = io.open(_G.__addonsDir .. "/" .. name .. "/" .. name .. ".toc", "rb")
    if f then f:close() return true end
    return false
  end,
  LoadAddOn = function(name)
    if _G.__loadedAddOns[name] then return true end
    if not C_AddOns.DoesAddOnExist(name) then return false, "MISSING" end
    _G.__loadedAddOns[name] = true
    local chunk = loadfile(_G.__addonsDir .. "/" .. name .. "/data.lua")
    if chunk then chunk(name, {}) end
    return true
  end,
}

-- chat frames
local function newChatFrame(index)
  local f = { messages = {}, index = index }
  function f:AddMessage(msg, r, g, b, infoID, accessID, typeID, event, eventArgs, formatter)
    table.insert(self.messages, { msg, r, g, b, infoID, accessID, typeID, event, eventArgs, formatter })
    if index == 1 and not event then table.insert(_G.__printed, msg) end
  end
  function f:TransformMessages(predicate, transform)
    for i, e in ipairs(self.messages) do
      if predicate(unpack(e, 1, 10)) then
        local ok, a, b2, c, d, e2, f2, g2, h, i2, j = pcall(transform, unpack(e, 1, 10))
        if ok then self.messages[i] = { a, b2, c, d, e2, f2, g2, h, i2, j } else self.messages[i] = nil end
      end
    end
  end
  return f
end
ChatFrame1 = newChatFrame(1)
ChatFrame2 = newChatFrame(2)
DEFAULT_CHAT_FRAME = ChatFrame1

-- chat filters (modern and deprecated registration)
local function addFilter(event, fn)
  _G.__filters[event] = _G.__filters[event] or {}
  table.insert(_G.__filters[event], fn)
end
ChatFrame_AddMessageEventFilter = addFilter
ChatFrameUtil = {
  AddMessageEventFilter = addFilter,
  OpenChat = function(text) table.insert(_G.__opened, text) end,
}

local function noop() end
local function widget()
  local w = { scripts = {} }
  for _, m in ipairs({ "RegisterEvent", "Hide", "Show", "SetPoint", "SetSize", "SetText", "SetChecked",
      "LockHighlight", "UnlockHighlight", "SetOrientation", "SetMinMaxValues", "SetValueStep",
      "SetObeyStepOnDrag", "SetThumbTexture", "SetValue", "SetAllPoints", "SetColorTexture", "SetTexture" }) do
    w[m] = noop
  end
  w.GetChecked = function() return false end
  w.SetScript = function(self, ev, fn) self.scripts[ev] = fn end
  w.CreateFontString = function() return widget() end
  w.CreateTexture = function() return widget() end
  return w
end
CreateFrame = function(ftype, name, parent, template)
  local f = widget()
  f.ftype = ftype
  table.insert(_G.__frames, f)
  return f
end

function __fire(event, ...)
  for _, f in ipairs(_G.__frames) do
    if f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
  end
end

-- Deliver a chat event the way the client does: log it, run the filters for
-- each chat frame, add the formatted line. Returns the text shown in frame 1.
function __chat(event, msg, author)
  author = author or "Someone-Realm"
  _G.__lineID = _G.__lineID + 1
  local lineID = _G.__lineID
  if event == "CHAT_MSG_SAY" then logLine(author .. " says: " .. msg)
  elseif event == "CHAT_MSG_CHANNEL" then logLine("[2. Trade] " .. author .. ": " .. msg)
  elseif event == "CHAT_MSG_GUILD" then logLine("[Guild] " .. author .. ": " .. msg)
  elseif event == "CHAT_MSG_PARTY" then logLine("[Party] " .. author .. ": " .. msg) end
  local shown
  for _, frame in ipairs({ ChatFrame1, ChatFrame2 }) do
    local text, hidden = msg, false
    local args = { msg, author, "", "", "", "", 0, 1, "General", 0, lineID, "guid", 0, false }
    for _, fn in ipairs(_G.__filters[event] or {}) do
      local res = { fn(frame, event, unpack(args, 1, 14)) }
      if res[1] == true then hidden = true break end
      if res[2] ~= nil then
        text = res[2]
        for i = 2, 15 do if res[i] ~= nil then args[i - 1] = res[i] end end
      end
    end
    if not hidden then
      local eventArgs = { n = 14, unpack(args, 1, 14) }
      local function formatter(t) return "[" .. author .. "]: " .. t end
      frame:AddMessage(formatter(text), 1, 1, 1, 1, 0, 0, event, eventArgs, formatter)
    end
    if frame == ChatFrame1 then shown = hidden and "FILTERED" or text end
  end
  _G.__lastLine = lineID
  return shown
end

-- The current text of a chat line in a frame (after any late edits).
function __line(lineID, frameIndex)
  local frame = (frameIndex == 2) and ChatFrame2 or ChatFrame1
  for _, e in ipairs(frame.messages) do
    local eventArgs = e[9]
    if type(eventArgs) == "table" and eventArgs[11] == lineID then return e[1] end
  end
  return nil
end
