-- CommonTongue / Memory.lua
--
-- Translation memory: whole sentences whose translation is already known,
-- plus the two small stores that live in the saved variables.
--
-- Three sources feed the memory:
--   * Learned.lua, written by the companion from real machine translation
--     of the chat on the player's realm (loaded at login and /reload)
--   * the live bridge, while the companion is running (this session only)
--   * entries the player adds with /tongue teach (saved, re-applied at login)
--
-- A sentence found here is answered before any dictionary work, with the
-- quality of the service that produced it. Sentences are identified by
-- their loose key (see Text.LooseKey), so punctuation, case and item links
-- do not matter.
--
-- Public API:
--   B:Learn(target, items)              called by Learned.lua
--   Memory:Store(target, key, src, tr)  remember one sentence for this session
--   Memory:Lookup(text, target, key)    translation, source language or nil
--   B:Teach(code, native, english)      player-taught entry
--   B:ApplyTaught()                     re-apply taught entries at login
--   B:NoteMissing(code, words)          count words the dictionaries lacked
--   B:TopMissing(code, limit)           most frequent missing words

local B = CommonTongue
local U = B.UTF8
local T = B.Text

local Memory = {
  byTarget = {},   -- target language -> { looseKey -> { translation, sourceLanguage } }
  count = 0,       -- sentences known from every source
  session = 0,     -- sentences added by the bridge this session
}
B.Memory = Memory

local MAX_SESSION = 4000   -- cap on bridge results kept in memory per session
local MAX_MISSING = 400    -- cap on missing words recorded per language

-------------------------------------------------------------------------------
-- Sentences
-------------------------------------------------------------------------------

--- Load sentences from Learned.lua, which the companion writes as
--   CommonTongue:Learn("en", { { "es", "busco grupo para ...", "Looking for ..." }, ... })
-- @param target  language the translations are in
-- @param items   array of { sourceLanguage, looseKey, translation }
function B:Learn(target, items)
  if type(target) ~= "string" or type(items) ~= "table" then return end
  local store = Memory.byTarget[target]
  if not store then
    store = {}
    Memory.byTarget[target] = store
  end
  for _, item in ipairs(items) do
    local src, key, tr = item[1], item[2], item[3]
    if type(key) == "string" and type(tr) == "string" and key ~= "" then
      if store[key] == nil then Memory.count = Memory.count + 1 end
      store[key] = { tr, src }
    end
  end
end

--- Remember one sentence for this session (a live bridge result).
-- @param target  language the translation is in
-- @param key     loose key of the original line
-- @param src     source language code ("?" when unknown, ">" for the
--                player's own outgoing request)
-- @param tr      translation; "" means "the line is already in the target language"
function Memory:Store(target, key, src, tr)
  local store = self.byTarget[target]
  if not store then
    store = {}
    self.byTarget[target] = store
  end
  if store[key] == nil then
    if self.session >= MAX_SESSION then return end
    self.count = self.count + 1
    self.session = self.session + 1
  end
  store[key] = { tr, src }
end

--- Look a line up in the memory.
-- @param text    raw chat line, used to put item links back; may be nil
-- @param target  language wanted
-- @param key     loose key, computed from text when nil
-- @return translation ("" when the line is already in the target language)
--         and source language, or nil when the line is unknown
function Memory:Lookup(text, target, key)
  local store = self.byTarget[target]
  if not store then return nil end
  local hit = store[key or T.LooseKey(text)]
  if not hit then return nil end
  local tr = hit[1]
  if text and tr ~= "" then tr = T.Relink(tr, text) end
  return tr, hit[2]
end

-------------------------------------------------------------------------------
-- Words the player teaches:  /tongue teach es mazmorra = dungeon
-------------------------------------------------------------------------------

--- Add a dictionary entry that wins over the shipped one and survives logout.
-- @param code     language code
-- @param native   word or phrase in that language
-- @param english  its English meaning
-- @return true, or false and a message for the player
function B:Teach(code, native, english)
  local L = B.Languages[code]
  if not L or code == "en" then return false, "unknown language '" .. tostring(code) .. "'" end
  native, english = U.Normalize(native or ""), (english or ""):gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", "")
  if native == "" or english == "" then return false, "usage: /tongue teach <lang> <word or phrase> = <english>" end
  B.db.taught = B.db.taught or {}
  B.db.taught[code] = B.db.taught[code] or {}
  B.db.taught[code][native] = english
  L:Override(native, english)
  if B.db.missing and B.db.missing[code] then B.db.missing[code][native] = nil end
  B:ClearCache()
  return true
end

--- Re-apply every taught entry from the saved variables (at login).
function B:ApplyTaught()
  if not B.db or not B.db.taught then return end
  for code, entries in pairs(B.db.taught) do
    local L = B.Languages[code]
    if L then
      for native, english in pairs(entries) do L:Override(native, english) end
    end
  end
end

-------------------------------------------------------------------------------
-- Words the dictionaries did not know, counted so the gaps can be filled
-------------------------------------------------------------------------------

local missingCount = {}   -- code -> number of distinct words recorded (cache)

--- Count unknown words from a translated line. Only called for lines the
-- detector was sure about, so the words really are of that language. The
-- store is capped; once full, new words are ignored and known ones are
-- still counted up.
-- @param code   language code
-- @param words  array of lower-case unknown words (from the engine's stats)
function B:NoteMissing(code, words)
  if not B.db or not words or #words == 0 then return end
  B.db.missing = B.db.missing or {}
  local t = B.db.missing[code]
  if not t then
    t = {}
    B.db.missing[code] = t
  end
  local n = missingCount[code]
  if n == nil then
    n = 0
    for _ in pairs(t) do n = n + 1 end
  end
  for _, w in ipairs(words) do
    if #w >= 3 and not w:find("%d") then
      if t[w] then
        t[w] = t[w] + 1
      elseif n < MAX_MISSING then
        t[w] = 1
        n = n + 1
      end
    end
  end
  missingCount[code] = n
end

--- The most frequent missing words of a language.
-- @param code   language code
-- @param limit  how many (default 15)
-- @return array of { word, count }, most frequent first
function B:TopMissing(code, limit)
  local t = B.db and B.db.missing and B.db.missing[code]
  if not t then return {} end
  local list = {}
  for w, n in pairs(t) do list[#list + 1] = { w, n } end
  table.sort(list, function(a, b)
    if a[2] ~= b[2] then return a[2] > b[2] end
    return a[1] < b[1]
  end)
  local out = {}
  for i = 1, math.min(limit or 15, #list) do out[i] = list[i] end
  return out
end
