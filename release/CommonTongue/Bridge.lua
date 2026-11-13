-- CommonTongue / Bridge.lua
--
-- The live bridge: real machine translation inside the chat frame, without
-- the addon ever touching the network.
--
-- An addon cannot open a connection or read a file. It can, however, load
-- another addon on demand, and a load-on-demand addon is read from disk at
-- the moment it is loaded. The companion program (Companion/) tails the
-- game's chat log, translates new lines, and keeps a ring of tiny "slot"
-- addons (CommonTongue_Slot_000 ...) up to date with its latest results.
-- When a line needs translating, this file loads the slot that belongs to
-- the current second; the slot's data file calls Bridge:Receive with the
-- translations, and the matching chat line is edited in place.
--
--   game --(chat log file)--> companion --(slot addon file)--> game
--
-- Each slot can be loaded once per session (the client caches it), so slots
-- are a budget; a /reload refills them. Nothing here reads memory, injects
-- input or looks at the screen.
--
-- Public API:
--   Bridge:Init()                      count the installed slots (at login)
--   Bridge:Request(key, line)          a foreign line is on screen: fetch its translation
--   Bridge:RequestOutgoing(key, req)   translate something the player wants to say
--   Bridge:Receive(...)                called by a slot's data file
--   Bridge:Probe(announce)             is the companion running?
--   Bridge:ShouldRetry()               time to look for a quiet companion again?
--   Bridge:Status()                    one-line status for /tongue status
--   Bridge:Flush() / EnsureLogging()   drive the client's chat log
--   Bridge:AutoProbe()                 probe a few times after login

local B = CommonTongue
local Memory = B.Memory

local Bridge = {
  prefix = "CommonTongue_Slot_",
  slots = 0,            -- how many slot addons are installed
  loaded = {},          -- slot index -> true once used this session
  used = 0,             -- slots consumed this session
  live = false,         -- the companion answered recently
  lastBeat = 0,         -- companion clock (unix seconds) of the last answer
  lastRetry = nil,      -- when a quiet companion was last looked for
  received = false,     -- set by Receive during a Pull
  backend = nil,        -- translation service the companion reported
  pending = {},         -- loose key -> { key, lines = { lineID -> line }, t0, tries }
  npending = 0,
  outgoing = {},        -- loose key -> { chatType, lang, target, text, t0, tries }
  nout = 0,
  timer = false,        -- a Tick is scheduled
  flushing = false,     -- a chat-log flush is in progress
  flushes = 0,          -- chat-log flushes this session (diagnostics)
  warned = nil,         -- last warning printed: "stale" | "none" | nil
}
B.Bridge = Bridge

local FRESH = 8           -- seconds a companion heartbeat stays believable
local FIRST_DELAY = 1.3   -- wait this long for the companion before the first pull
local RETRY_DELAY = 1.6   -- between further pulls while lines are waiting
local MAX_TRIES = 3       -- pulls before a line falls back to the built-in translation
local RETRY_EVERY = 60    -- seconds between attempts to find a quiet companion again
local RETRY_LOW_WATER = 0.3 -- stop retrying when fewer than this share of slots is left

local function now() return time() end

--- Does a load-on-demand addon with this name exist on disk?
local function addOnExists(name)
  if C_AddOns and C_AddOns.DoesAddOnExist then return C_AddOns.DoesAddOnExist(name) end
  if C_AddOns and C_AddOns.GetAddOnInfo then
    local _, _, _, _, reason = C_AddOns.GetAddOnInfo(name)
    return reason ~= "MISSING"
  end
  return false
end

--- Count the installed slot addons. Called once at login.
-- @return number of slots
function Bridge:Init()
  local n = 0
  while n < 1000 and addOnExists(self.prefix .. ("%03d"):format(n)) do n = n + 1 end
  self.slots = n
  return n
end

--- Slots not yet used this session.
function Bridge:SlotsLeft()
  return self.slots - self.used
end

--- When the companion has gone quiet (restarted, or started after the login
-- probes), look for it again now and then instead of waiting for
-- /tongue live: at most once a minute, five minutes if it was never seen
-- this session, and only while plenty of slots are left.
-- @return true when the caller should spend a slot on a fresh request
function Bridge:ShouldRetry()
  if self.live or self.slots == 0 or B.db.live == false then return false end
  if self:SlotsLeft() < self.slots * RETRY_LOW_WATER then return false end
  local t = now()
  local every = (self.lastBeat > 0) and RETRY_EVERY or RETRY_EVERY * 5
  if (self.lastRetry or t) + every > t then
    self.lastRetry = self.lastRetry or t
    return false
  end
  self.lastRetry = t
  return true
end

--- Called by a slot addon's data file with the companion's latest results.
-- @param slot     slot index the file belongs to (unused, for diagnostics)
-- @param beat     companion clock in unix seconds when the file was written
-- @param backend  name of the translation service
-- @param target   language the translations are in
-- @param items    array of { sourceLanguage, looseKey, translation [, targetLanguage] };
--                 source ">" marks a reply to the player's own request
function Bridge:Receive(slot, beat, backend, target, items)
  self.received = true
  if type(beat) == "number" and beat > self.lastBeat then self.lastBeat = beat end
  self.backend = backend or self.backend
  if type(items) ~= "table" then return end
  for _, item in ipairs(items) do
    local src, key, tr, tgt = item[1], item[2], item[3], item[4]
    if type(key) == "string" and type(tr) == "string" then
      Memory:Store(tgt or target or "en", key, src, tr)
    end
  end
end

--- Load the slot for the current second and take in what it holds.
-- @return ok (the companion is alive), reason:
--   "ok" | "stale" (file older than FRESH seconds: companion not running) |
--   "empty" (nothing received) | "wait" (this second's slot was used already) |
--   "none" (no slots installed or all used)
function Bridge:Pull()
  if self.slots == 0 then return false, "none" end
  if self.used >= self.slots then return false, "none" end
  local t = now()
  local slot = t % self.slots
  if self.loaded[slot] then return false, "wait" end
  self.loaded[slot] = true
  self.used = self.used + 1
  self.received = false
  pcall(C_AddOns.LoadAddOn, self.prefix .. ("%03d"):format(slot))
  if not self.received then
    self.live = false
    return false, "empty"
  end
  local fresh = (t - self.lastBeat) <= FRESH
  local was = self.live
  self.live = fresh
  if fresh and not was then
    B:Print(("live translation connected (%s)."):format(self.backend or "companion"))
  end
  return fresh, fresh and "ok" or "stale"
end

-------------------------------------------------------------------------------
-- The client's chat log
-------------------------------------------------------------------------------

--- Ask the game to write its buffered chat lines to Logs\WoWChatLog.txt now.
-- The client writes the file when logging is switched off; it is switched
-- on again on the next frame so the two calls cannot cancel each other out.
function Bridge:Flush()
  if not LoggingChat or self.flushing then return end
  self.flushing = true
  self.flushes = self.flushes + 1
  pcall(LoggingChat, false)
  C_Timer.After(0, function()
    self.flushing = false
    pcall(LoggingChat, true)
  end)
end

--- Switch chat logging on if it is off (the companion reads the log).
function Bridge:EnsureLogging()
  if LoggingChat and not LoggingChat() then pcall(LoggingChat, true) end
end

-------------------------------------------------------------------------------
-- Requests
-------------------------------------------------------------------------------

--- Run a Tick after delay seconds, unless one is already scheduled.
function Bridge:Schedule(delay)
  if self.timer then return end
  self.timer = true
  C_Timer.After(delay, function()
    self.timer = false
    local ok, err = pcall(self.Tick, self)
    if not ok and B.db and B.db.debug then B:Print("bridge error: " .. tostring(err)) end
  end)
end

--- A foreign line is on screen untranslated: fetch its translation.
-- @param key   loose key of the line
-- @param line  { id = lineID, msg = raw text, lang = detected code or "?",
--                fallback = built-in suffix or nil, author = sender }
function Bridge:Request(key, line)
  local p = self.pending[key]
  if not p then
    p = { key = key, lines = {}, t0 = GetTime(), tries = 0 }
    self.pending[key] = p
    self.npending = self.npending + 1
    if B.db.flush then self:Flush() end
  end
  if not p.lines[line.id] then p.lines[line.id] = line end
  self:Schedule(FIRST_DELAY)
end

--- Ask the companion to translate something the player wants to say.
-- @param key      loose key of the text
-- @param request  { chatType, lang, target, text }
function Bridge:RequestOutgoing(key, request)
  if not self.outgoing[key] then self.nout = self.nout + 1 end
  request.t0, request.tries = GetTime(), 0
  self.outgoing[key] = request
  if B.db.flush then self:Flush() end
  self:Schedule(FIRST_DELAY)
end

local function dropPending(self, key)
  if self.pending[key] then
    self.pending[key] = nil
    self.npending = self.npending - 1
  end
end

--- One round: pull a slot, answer every waiting line the memory now knows,
-- give up on lines that have waited too long, and reschedule while
-- anything is still waiting.
function Bridge:Tick()
  if self.npending == 0 and self.nout == 0 then return end
  local ok, why = self:Pull()
  if why == "wait" then
    self:Schedule(0.5)
    return
  end
  local target = B.db.target or "en"
  local alive = ok

  for key, p in pairs(self.pending) do
    local tr, src = Memory:Lookup(nil, target, key)
    if tr ~= nil then
      for _, line in pairs(p.lines) do B:ShowLate(line, tr, src, true) end
      dropPending(self, key)
    else
      p.tries = p.tries + 1
      if alive and p.tries == 1 and not B.db.flush then
        -- the companion is there but has not seen the line: from now on ask
        -- the game to flush its chat log whenever a line is waiting
        B.db.flush = true
        self:Flush()
      elseif not alive or p.tries >= MAX_TRIES then
        for _, line in pairs(p.lines) do B:ShowLate(line, nil, line.lang, false) end
        dropPending(self, key)
      elseif B.db.flush then
        -- still waiting: give the game another chance to write the log
        self:Flush()
      end
    end
  end

  for key, req in pairs(self.outgoing) do
    local tr = Memory:Lookup(nil, req.lang, key)
    if tr ~= nil and tr ~= "" then
      self.outgoing[key] = nil
      self.nout = self.nout - 1
      B:DeliverOutgoing(req, tr, true)
    else
      req.tries = req.tries + 1
      if not alive or req.tries >= MAX_TRIES then
        self.outgoing[key] = nil
        self.nout = self.nout - 1
        B:DeliverOutgoing(req, nil, false)
      end
    end
  end

  if not alive and why ~= "none" and self.warned ~= "stale" then
    self.warned = "stale"
    B:Print("the companion is not answering; using the built-in translation and checking for it again every minute (/tongue live checks now).")
  elseif why == "none" and self.slots > 0 and self.warned ~= "none" then
    self.warned = "none"
    B:Print("live translation slots are used up for this session; type /reload to refill them. Using the built-in translation meanwhile.")
    self.live = false
  end
  if alive then self.warned = nil end

  if self.npending > 0 or self.nout > 0 then self:Schedule(RETRY_DELAY) end
end

-------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------

--- Check whether the companion is running. Costs one slot.
-- @param announce  print the result to the chat frame
-- @return true when the companion answered freshly
function Bridge:Probe(announce)
  if self.slots == 0 then
    if announce then B:Print("live translation is not installed (no slot addons found).") end
    return false
  end
  local ok, why = self:Pull()
  if why == "wait" then
    C_Timer.After(1, function() self:Probe(announce) end)
    return false
  end
  if announce then
    if ok then
      B:Print(("live translation is connected (%s). Slots left this session: %d of %d.")
        :format(self.backend or "companion", self:SlotsLeft(), self.slots))
    elseif why == "none" then
      B:Print("live translation slots are used up; type /reload to refill them.")
    else
      B:Print("the companion is not running. Start it and type /tongue live again.")
    end
  end
  return ok
end

--- One-line status for /tongue status.
function Bridge:Status()
  if self.slots == 0 then return "not installed" end
  local age = now() - self.lastBeat
  local logging = "n/a"
  if LoggingChat then
    local ok, on = pcall(LoggingChat)
    logging = (ok and on) and "on" or "off"
  end
  return ("%s, %d of %d slots left%s%s, chat logging %s, %d flushes"):format(
    self.live and "connected" or "not connected",
    self:SlotsLeft(), self.slots,
    self.lastBeat > 0 and (", last answer %ds ago"):format(age) or "",
    B.db.flush and ", log flush on" or "", logging, self.flushes)
end

--- Probe a few times after login (5 s, 1, 4 and 10 minutes), in case the
-- companion is started a little later than the game.
function Bridge:AutoProbe()
  if self.slots == 0 or B.db.live == false then return end
  self:EnsureLogging()
  local delays = { 5, 60, 240, 600 }
  local i = 0
  local function try()
    if self.live or B.db.live == false then return end
    if self:Probe(false) then return end
    i = i + 1
    if delays[i + 1] then C_Timer.After(delays[i + 1] - delays[i], try) end
  end
  C_Timer.After(delays[1], try)
end
