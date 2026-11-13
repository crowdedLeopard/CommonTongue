-- CommonTongue / UTF8.lua
--
-- UTF-8 helpers for the game's Lua 5.1, which has no utf8 library.
-- Everything else in the addon builds on this file: decoding code points,
-- lower-casing beyond ASCII, telling which writing system a character
-- belongs to, and cutting a chat line into protected pieces (links, colour
-- codes, textures) and translatable text.
--
-- This is the first file the TOC loads, so it also creates the addon's one
-- global table, CommonTongue. The generated files (Learned.lua written by
-- the companion, and the live-translation slot addons) call into that global.
--
-- Public API (CommonTongue.UTF8):
--   DecodeAt(s, i)      code point and byte length at byte i
--   Encode(cp)          code point -> UTF-8 string
--   Length(s)           number of code points
--   Lower(s)            lower case for Latin, Greek and Cyrillic
--   IsUpperFirst(s)     does the text start with a capital letter?
--   UpperFirst(s)       capitalise the first letter
--   Normalize(s)        dictionary key form: lower case, straight apostrophes, single spaces
--   Script(cp)          "latin" | "cyrillic" | "han" | ... | nil for non-letters
--   ScriptStats(s)      how many letters of each script a text contains
--   Segment(text)       split chat text into protected and translatable pieces

CommonTongue = CommonTongue or {}
local B = CommonTongue
local U = {}
B.UTF8 = U

local byte, char, sub, floor = string.byte, string.char, string.sub, math.floor
local tinsert, tconcat = table.insert, table.concat

-------------------------------------------------------------------------------
-- Decoding and encoding
-------------------------------------------------------------------------------

--- Decode the code point that starts at byte i of s.
-- A malformed or truncated sequence is returned as a single opaque byte so
-- that callers always make progress through the string.
-- @param s  UTF-8 string
-- @param i  byte index (1-based)
-- @return code point, byte length of the sequence; nil past the end
local function decodeAt(s, i)
  local c = byte(s, i)
  if not c then return nil end
  if c < 0x80 then return c, 1 end
  if c >= 0xF0 then
    local c2, c3, c4 = byte(s, i + 1, i + 3)
    if c2 and c3 and c4 then
      return (c - 0xF0) * 262144 + (c2 - 0x80) * 4096 + (c3 - 0x80) * 64 + (c4 - 0x80), 4
    end
  elseif c >= 0xE0 then
    local c2, c3 = byte(s, i + 1, i + 2)
    if c2 and c3 then
      return (c - 0xE0) * 4096 + (c2 - 0x80) * 64 + (c3 - 0x80), 3
    end
  elseif c >= 0xC0 then
    local c2 = byte(s, i + 1)
    if c2 then return (c - 0xC0) * 64 + (c2 - 0x80), 2 end
  end
  return c, 1
end
U.DecodeAt = decodeAt

--- Encode one code point as a UTF-8 string.
-- @param cp  code point
-- @return string of 1 to 4 bytes
function U.Encode(cp)
  if cp < 0x80 then return char(cp)
  elseif cp < 0x800 then return char(0xC0 + floor(cp / 64), 0x80 + cp % 64)
  elseif cp < 0x10000 then
    return char(0xE0 + floor(cp / 4096), 0x80 + floor(cp / 64) % 64, 0x80 + cp % 64)
  else
    return char(0xF0 + floor(cp / 262144), 0x80 + floor(cp / 4096) % 64,
                0x80 + floor(cp / 64) % 64, 0x80 + cp % 64)
  end
end

--- Number of code points in s (not bytes).
-- @param s  UTF-8 string
-- @return integer
function U.Length(s)
  local count, i, n = 0, 1, #s
  while i <= n do
    local _, size = decodeAt(s, i)
    count = count + 1
    i = i + size
  end
  return count
end

-------------------------------------------------------------------------------
-- Case
-------------------------------------------------------------------------------

--- Lower-case one code point: ASCII, Latin-1, Latin Extended-A, Greek and
-- the Cyrillic ranges that occur in chat. Other code points are returned
-- unchanged.
local function lowerCP(cp)
  if cp < 0x80 then
    if cp >= 65 and cp <= 90 then return cp + 32 end
    return cp
  end
  if cp >= 0xC0 and cp <= 0xDE and cp ~= 0xD7 then return cp + 32 end        -- Latin-1  À..Þ
  if cp >= 0x100 and cp <= 0x17F then                                          -- Latin Extended-A
    if cp == 0x130 then return 0x69 end                                        -- dotted capital I -> i
    if cp == 0x178 then return 0xFF end                                        -- Y with diaeresis
    -- the block alternates upper/lower in pairs; which parity is upper
    -- flips twice inside it
    if (cp >= 0x100 and cp <= 0x12F) or (cp >= 0x132 and cp <= 0x137)
       or (cp >= 0x14A and cp <= 0x177) then
      if cp % 2 == 0 then return cp + 1 end
    elseif (cp >= 0x139 and cp <= 0x148) or (cp >= 0x179 and cp <= 0x17E) then
      if cp % 2 == 1 then return cp + 1 end
    end
    return cp
  end
  if cp >= 0x391 and cp <= 0x3A9 and cp ~= 0x3A2 then return cp + 32 end      -- Greek
  if cp >= 0x410 and cp <= 0x42F then return cp + 32 end                       -- Cyrillic A..Ya
  if cp >= 0x400 and cp <= 0x40F then return cp + 80 end                       -- Cyrillic supplement (Yo, Ye, I, Yi)
  if cp >= 0x460 and cp <= 0x481 and cp % 2 == 0 then return cp + 1 end
  if cp >= 0x48A and cp <= 0x4BF and cp % 2 == 0 then return cp + 1 end       -- includes Ghe with upturn
  return cp
end

--- Upper-case one code point (the inverse of lowerCP for the ranges that
-- UpperFirst needs: ASCII, Latin-1, Greek, basic Cyrillic).
local function upperCP(cp)
  if cp >= 97 and cp <= 122 then return cp - 32 end
  if cp >= 0xE0 and cp <= 0xFE and cp ~= 0xF7 then return cp - 32 end
  if cp >= 0x3B1 and cp <= 0x3C9 and cp ~= 0x3C2 then return cp - 32 end
  if cp >= 0x430 and cp <= 0x44F then return cp - 32 end
  if cp >= 0x450 and cp <= 0x45F then return cp - 80 end
  return cp
end

--- Lower-case a string. Pure ASCII takes the fast built-in path.
-- @param s  UTF-8 string
-- @return lower-cased string
function U.Lower(s)
  if not s:find("[\128-\255]") then return s:lower() end
  local out, i, n = {}, 1, #s
  while i <= n do
    local cp, size = decodeAt(s, i)
    local lc = lowerCP(cp)
    if lc == cp then out[#out + 1] = sub(s, i, i + size - 1) else out[#out + 1] = U.Encode(lc) end
    i = i + size
  end
  return tconcat(out)
end

--- Does the text start with an upper-case letter?
-- @param s  UTF-8 string
-- @return boolean
function U.IsUpperFirst(s)
  local cp = decodeAt(s, 1)
  return cp ~= nil and lowerCP(cp) ~= cp
end

--- Upper-case the first letter of the text, leaving the rest alone.
-- @param s  UTF-8 string
-- @return string
function U.UpperFirst(s)
  local cp, size = decodeAt(s, 1)
  if not cp then return s end
  local uc = upperCP(cp)
  if uc == cp then return s end
  return U.Encode(uc) .. sub(s, size + 1)
end

--- The form dictionary keys are stored and looked up in: lower case, curly
-- apostrophes straightened, runs of whitespace collapsed to one space, no
-- leading or trailing space. Called for every key at load time, so text that
-- is already in that form (the common case) is returned without any work.
-- @param s  UTF-8 string
-- @return normalised string
function U.Normalize(s)
  if not s:find("[A-Z\128-\255\t\r\n]") and not s:find("  ", 1, true)
     and byte(s, 1) ~= 32 and byte(s, -1) ~= 32 then
    return s
  end
  s = U.Lower(s)
  s = s:gsub("\226\128\153", "'"):gsub("\226\128\152", "'")   -- curly apostrophes
  s = s:gsub("[ \t\r\n]+", " "):gsub("^ ", ""):gsub(" $", "")
  return s
end

-------------------------------------------------------------------------------
-- Writing systems
-------------------------------------------------------------------------------

--- Writing system of a code point, or nil for digits, punctuation and symbols.
-- Used to decide a line's script before any dictionary is consulted (a line
-- of Hangul is Korean whatever it says) and to tell letters from everything
-- else while tokenising.
-- @param cp  code point
-- @return "latin" | "greek" | "cyrillic" | "armenian" | "hebrew" | "arabic" |
--         "devanagari" | "thai" | "hangul" | "hiragana" | "katakana" | "han" | nil
function U.Script(cp)
  if cp < 0x80 then
    if (cp >= 65 and cp <= 90) or (cp >= 97 and cp <= 122) then return "latin" end
    return nil
  end
  if cp == 0xD7 or cp == 0xF7 then return nil end                             -- × ÷
  if cp >= 0xC0 and cp <= 0x24F then return "latin" end
  if cp >= 0x370 and cp <= 0x3FF then return "greek" end
  if cp >= 0x400 and cp <= 0x52F then return "cyrillic" end
  if cp >= 0x530 and cp <= 0x58F then return "armenian" end
  if cp >= 0x590 and cp <= 0x5FF then return "hebrew" end
  if cp >= 0x600 and cp <= 0x6FF then return "arabic" end
  if cp >= 0x900 and cp <= 0x97F then return "devanagari" end
  if cp >= 0xE00 and cp <= 0xE7F then return "thai" end
  if cp >= 0x1100 and cp <= 0x11FF then return "hangul" end
  if cp >= 0x1E00 and cp <= 0x1EFF then return "latin" end                    -- Latin Extended Additional (Vietnamese)
  if cp >= 0x3040 and cp <= 0x309F then return "hiragana" end
  if cp >= 0x30A0 and cp <= 0x30FF then return "katakana" end
  if cp >= 0x3130 and cp <= 0x318F then return "hangul" end
  if cp >= 0x3400 and cp <= 0x4DBF then return "han" end
  if cp >= 0x4E00 and cp <= 0x9FFF then return "han" end
  if cp >= 0xAC00 and cp <= 0xD7AF then return "hangul" end
  if cp >= 0xF900 and cp <= 0xFAFF then return "han" end
  if cp >= 0xFF66 and cp <= 0xFF9F then return "katakana" end                 -- half-width katakana
  return nil
end

--- Count the letters of each writing system in a text.
-- @param s  UTF-8 string
-- @return table { total = n, latin = n, cyrillic = n, ... } (absent scripts are nil)
function U.ScriptStats(s)
  local stats, i, n = { total = 0 }, 1, #s
  while i <= n do
    local cp, size = decodeAt(s, i)
    local sc = U.Script(cp)
    if sc then
      stats[sc] = (stats[sc] or 0) + 1
      stats.total = stats.total + 1
    end
    i = i + size
  end
  return stats
end

-------------------------------------------------------------------------------
-- Chat markup
-------------------------------------------------------------------------------

-- Pieces of a chat line that must never be translated or re-spaced. Each is
-- a Lua pattern; the earliest match in the text wins.
local PROTECT = {
  "|H.-|h.-|h",            -- hyperlink with its display text
  "|T.-|t",                -- texture
  "|A.-|a",                -- atlas
  "|c%x%x%x%x%x%x%x%x",    -- colour start
  "|r",                    -- colour end
  "{[A-Za-z]+%d*}",        -- raid target icons {rt1} {skull}
}

--- Split chat text into a sequence of pieces: protected markup (links,
-- colours, textures, raid icons) and the plain text between them.
-- @param text  raw chat line
-- @return array of { text = string, protected = boolean }, in order
function U.Segment(text)
  local segs, pos, n = {}, 1, #text
  while pos <= n do
    local bestS, bestE
    for _, pat in ipairs(PROTECT) do
      local s, e = text:find(pat, pos)
      if s and (not bestS or s < bestS) then bestS, bestE = s, e end
    end
    if not bestS then
      tinsert(segs, { text = sub(text, pos), protected = false })
      break
    end
    if bestS > pos then tinsert(segs, { text = sub(text, pos, bestS - 1), protected = false }) end
    tinsert(segs, { text = sub(text, bestS, bestE), protected = true })
    pos = bestE + 1
  end
  return segs
end
