-- CommonTongue / Text.lua
--
-- Text preparation shared by detection, translation, the translation memory
-- and the live bridge:
--
--   * accent folding, so "misión" and "mision" find the same entry
--   * squeezing of letters repeated for emphasis ("holaaaa" -> "hola")
--   * plain-text extraction (chat markup removed, item names kept)
--   * the loose key that identifies "the same sentence again"; the companion
--     computes the identical key in Python, so both must stay in step
--   * the atomiser, which turns a chat line into words, numbers,
--     punctuation and protected codes with their surrounding whitespace
--
-- Public API (CommonTongue.Text):
--   Fold(s)              accent-folded string
--   Squeeze(word)        up to two de-emphasised candidates, or nil
--   PlainText(text)      markup removed, display text kept
--   LooseKey(text)       sentence identity key
--   LinkMap(text)        display text -> full link code
--   Relink(tr, orig)     put the original links back into a translation
--   Atomize(text)        atoms and trailing whitespace
--   Words(atoms)         only the word atoms
--   DROP                 punctuation dropped from output ("¿", "¡")

local B = CommonTongue
local U = B.UTF8
local T = {}
B.Text = T

local byte, sub = string.byte, string.sub
local tconcat = table.concat

-------------------------------------------------------------------------------
-- Accent folding
-------------------------------------------------------------------------------

-- Two-byte UTF-8 sequence -> ASCII replacement. Only the two-byte range is
-- folded; that covers every accented Latin letter chat uses.
local FOLD = {}
local function addFold(chars, to)
  for ch in chars:gmatch("[\194-\223][\128-\191]") do FOLD[ch] = to end
end
addFold("áàâäãåāăą", "a")
addFold("çćčĉ", "c")
addFold("ďđ", "d")
addFold("éèêëēėęě", "e")
addFold("ğĝ", "g")
addFold("íìîïīįı", "i")
addFold("ĺľł", "l")
addFold("ñńň", "n")
addFold("óòôöõøōő", "o")
addFold("ŕř", "r")
addFold("śšşș", "s")
addFold("ťţț", "t")
addFold("úùûüūůűų", "u")
addFold("ýÿ", "y")
addFold("źżž", "z")
addFold("ß", "ss")
addFold("æ", "ae")
addFold("œ", "oe")
addFold("ё", "е") -- Cyrillic yo -> ye, as typed in most Russian chat

--- Replace accented Latin letters by their plain form. Text with no two-byte
-- sequence is returned as is.
-- @param s  lower-case UTF-8 string
-- @return folded string
function T.Fold(s)
  if not s:find("[\194-\223]") then return s end
  return (s:gsub("[\194-\223][\128-\191]", FOLD))
end

-------------------------------------------------------------------------------
-- Emphasis
-------------------------------------------------------------------------------

--- Collapse every run of at least minRun identical characters to one.
-- @return the squeezed word, or nil when nothing was collapsed
local function squeezeRuns(word, minRun)
  local out, i, n = {}, 1, #word
  local changed = false
  while i <= n do
    local _, size = U.DecodeAt(word, i)
    local ch = sub(word, i, i + size - 1)
    local j, count = i + size, 1
    while sub(word, j, j + size - 1) == ch do
      count = count + 1
      j = j + size
    end
    if count >= minRun then
      out[#out + 1] = ch
      changed = true
    else
      for _ = 1, count do out[#out + 1] = ch end
    end
    i = j
  end
  if changed then return tconcat(out) end
  return nil
end

--- De-emphasise a word typed with repeated letters: "holaaaa" -> "hola".
-- Returns two candidates because some words legitimately double a letter:
-- the first collapses runs of three or more ("till" stays "till"), the
-- second also collapses doubles ("hoola" -> "hola").
-- @param word  lower-case word
-- @return candidate with 3+ runs collapsed or nil, candidate with 2+ runs collapsed or nil
function T.Squeeze(word)
  if #word < 3 then return nil, nil end
  local a = squeezeRuns(word, 3)
  local b = squeezeRuns(a or word, 2)
  return a, b
end

--- Collapse every run of three or more identical characters in a text
-- ("Saluuuuut :)" -> "Salut :)"), so that stretched letters count as
-- evidence of nothing. Returns the text itself when nothing collapses.
-- @param s  UTF-8 string
-- @return collapsed string
function T.Collapse(s)
  if not s:find("(.)%1%1") then return s end
  return squeezeRuns(s, 3) or s
end

-------------------------------------------------------------------------------
-- Plain text and loose keys
-------------------------------------------------------------------------------

--- Remove WoW escape codes but keep what the player sees: a linked item
-- becomes "[Wool Cloth]", colours and textures disappear.
-- @param text  raw chat line
-- @return plain text
function T.PlainText(text)
  if not text:find("|", 1, true) and not text:find("{", 1, true) then return text end
  local s = text
  s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
  s = s:gsub("|r", "")
  s = s:gsub("|H.-|h", "")
  s = s:gsub("|h", "")
  s = s:gsub("|T.-|t", "")
  s = s:gsub("|A.-|a", "")
  s = s:gsub("|K.-|k", "")
  s = s:gsub("|n", " ")
  s = s:gsub("{[A-Za-z]+%d*}", "")
  return s
end

--- The key under which a sentence is remembered: lower case, letters and
-- digits of any script, everything else collapsed to single spaces. Two
-- lines that differ only in punctuation, case or an item link share a key.
-- The companion (Python) computes exactly the same key; tools/tests/ct_parity.py
-- checks that the two implementations agree.
-- @param text  raw chat line
-- @return key string ("" when the line has no letters or digits)
function T.LooseKey(text)
  local s = U.Lower(T.PlainText(text))
  local out, i, n = {}, 1, #s
  local space = true
  while i <= n do
    local c = byte(s, i)
    local size, keep = 1, false
    if c < 0x80 then
      keep = (c >= 48 and c <= 57) or (c >= 97 and c <= 122)
    else
      local cp
      cp, size = U.DecodeAt(s, i)
      keep = U.Script(cp) ~= nil
    end
    if keep then
      out[#out + 1] = sub(s, i, i + size - 1)
      space = false
    elseif not space then
      out[#out + 1] = " "
      space = true
    end
    i = i + size
  end
  if out[#out] == " " then out[#out] = nil end
  return tconcat(out)
end

--- Map of visible link text (lower case) -> full link code, for every link
-- in the text. Used to put real, clickable links back into a translation
-- that only carries "[Wool Cloth]".
-- @param text  raw chat line
-- @return table or nil when the text has no links
function T.LinkMap(text)
  local map
  for link in text:gmatch("|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r") do
    local shown = link:match("|h(.-)|h")
    if shown and shown ~= "" then
      map = map or {}
      map[U.Lower(shown)] = link
    end
  end
  for link in text:gmatch("|H.-|h.-|h") do
    local shown = link:match("|h(.-)|h")
    if shown and shown ~= "" then
      map = map or {}
      local k = U.Lower(shown)
      if not map[k] then map[k] = link end
    end
  end
  return map
end

--- Replace "[Item Name]" in a translation by the original line's link code.
-- @param translation  text containing bracketed item names
-- @param original     the raw chat line the links come from
-- @return translation with links restored
function T.Relink(translation, original)
  local map = T.LinkMap(original)
  if not map then return translation end
  return (translation:gsub("%b[]", function(shown)
    return map[U.Lower(shown)]
  end))
end

-------------------------------------------------------------------------------
-- Atomiser
-------------------------------------------------------------------------------
-- An atom is { kind=, text=, pre= } plus lower/fold/cap/wide for words.
--   kind: "word"   letters (may contain apostrophes)
--         "num"    digits (1.5 and 20:30 stay one atom)
--         "mixed"  letters and digits (5g, lvl60, qq1)
--         "punct"  other punctuation inside a clause
--         "clause" punctuation that ends a clause  , . ! ? ; : and CJK forms
--         "prot"   colour codes, links, textures, raid icons: never touched
--   pre:  what stood before the atom: whitespace, "" or "-" for a word glued
--         to the previous one by a hyphen ("peut-être")
--   lower: normalised text   fold: accent-folded lower   cap: starts upper case
--   wide: contains CJK or Hangul letters (translated without spaces)

local CLAUSE_ASCII = { [44] = true, [46] = true, [33] = true, [63] = true, [59] = true, [58] = true, [10] = true }
local CLAUSE_CP = {
  [0xBF] = true, [0xA1] = true,               -- inverted ? and !
  [0x3002] = true, [0x3001] = true,            -- CJK full stop, comma
  [0xFF0C] = true, [0xFF01] = true, [0xFF1F] = true, [0xFF1B] = true, [0xFF1A] = true,
  [0x2026] = true,                             -- ellipsis
}

--- Clause punctuation that is dropped from the output because English has no
-- equivalent (Spanish "¿" and "¡").
T.DROP = { ["\194\191"] = true, ["\194\161"] = true }

local function isDigit(c) return c ~= nil and c >= 48 and c <= 57 end

--- Atomise one piece of plain text, appending to atoms.
-- @param s      plain text (no markup)
-- @param atoms  array to append to
-- @param pre    whitespace carried over from before this piece
-- @return whitespace left over after the last atom
local function atomizePlain(s, atoms, pre)
  local i, n = 1, #s
  local wstart, hasDigit, hasAlpha, glue = nil, false, false, false
  local function flush(endPos)
    if not wstart then return end
    local text = sub(s, wstart, endPos)
    local kind
    if hasAlpha and hasDigit then kind = "mixed"
    elseif hasDigit then kind = "num"
    elseif hasAlpha then kind = "word"
    else kind = "punct" end
    local a = { kind = kind, text = text, pre = glue and "-" or pre }
    if kind == "word" or kind == "mixed" then
      local lower = U.Normalize(text)
      lower = lower:gsub("^'+", "")
      if #lower > 3 then lower = lower:gsub("'+$", "") end
      a.lower = lower
      a.fold = T.Fold(lower)
      a.cap = U.IsUpperFirst(text)
      a.wide = lower:find("[\227-\237]") ~= nil -- CJK / Hangul / kana
    end
    atoms[#atoms + 1] = a
    pre, glue = "", false
    wstart, hasDigit, hasAlpha = nil, false, false
  end
  while i <= n do
    local c = byte(s, i)
    local size, isWord, isAlpha, digit = 1, false, false, false
    local cp
    if c < 0x80 then
      if c >= 48 and c <= 57 then
        isWord, digit = true, true
      elseif (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
        isWord, isAlpha = true, true
      elseif c == 39 then
        isWord = true -- apostrophe inside a word: l'entrée, don't
      elseif (c == 46 or c == 44 or c == 58) and isDigit(byte(s, i - 1)) and isDigit(byte(s, i + 1)) then
        isWord = true -- 1.5  1,000  20:30
      end
    else
      cp, size = U.DecodeAt(s, i)
      if cp == 0x2019 or cp == 0x2018 then
        isWord = true -- curly apostrophes
      elseif U.Script(cp) then
        isWord, isAlpha = true, true
      end
    end
    if isWord then
      if not wstart then wstart = i end
      if digit then hasDigit = true end
      if isAlpha then hasAlpha = true end
    elseif c == 32 or c == 9 or c == 13 then
      flush(i - 1)
      pre = pre .. sub(s, i, i)
    elseif c == 45 and wstart and hasAlpha and i < n and byte(s, i + 1) ~= 32 and byte(s, i + 1) ~= 45
           and (byte(s, i + 1) >= 0x80 or sub(s, i + 1, i + 1):find("%w")) then
      flush(i - 1) -- "peut-être": two words glued by a hyphen
      glue = true
    else
      flush(i - 1)
      local text = sub(s, i, i + size - 1)
      local clause = (c < 0x80 and CLAUSE_ASCII[c]) or (cp and CLAUSE_CP[cp]) or false
      atoms[#atoms + 1] = { kind = clause and "clause" or "punct", text = text, pre = glue and "-" or pre }
      pre, glue = "", false
    end
    i = i + size
  end
  flush(n)
  if glue then pre = pre .. "-" end
  return pre
end

--- Turn a raw chat line into atoms. Markup pieces become "prot" atoms that
-- the engine copies through untouched.
-- @param text  raw chat line
-- @return atoms array, trailing whitespace after the last atom
function T.Atomize(text)
  local atoms, pre = {}, ""
  for _, seg in ipairs(U.Segment(text)) do
    if seg.protected then
      atoms[#atoms + 1] = { kind = "prot", text = seg.text, pre = pre }
      pre = ""
    else
      pre = atomizePlain(seg.text, atoms, pre)
    end
  end
  return atoms, pre
end

--- Only the word atoms of a line, in order (detection and statistics).
-- @param atoms  array from Atomize
-- @return array of word atoms
function T.Words(atoms)
  local words = {}
  for _, a in ipairs(atoms) do
    if a.kind == "word" then words[#words + 1] = a end
  end
  return words
end
