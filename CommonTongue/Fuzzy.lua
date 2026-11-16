-- CommonTongue / Fuzzy.lua
--
-- The fuzzy layer: what happens to a word no dictionary lookup knows once
-- the language of the line is known. Chat is typed fast: apostrophes are
-- skipped ("cest", "jpense"), letters are swapped, dropped or doubled
-- ("tyrouve", "paser", "serveru"), SMS spellings replace sounds ("koi",
-- "kestion", "mieu"), and languages that compound glue two words into one
-- ("Heiltrank"). No dictionary can list every such form, so this file derives
-- candidates from the typed word and answers them with ordinary dictionary
-- lookups, cheapest first, first hit wins:
--
--   1. apostrophe restoration   cest -> c'est, jregarde -> j'regarde -> I look
--   2. respelling rules         per language, declared in Grammar/<code>.lua:
--                               k -> qu, oa -> oi, a silent final letter
--   3. typo candidates          two letters swapped, a letter doubled, a vowel
--                               or neighbouring key hit, a letter dropped, a
--                               vowel inserted (words of five letters or more)
--   4. compound splitting       heiltrank -> heil + trank (de, nl, sv, da, no, fi)
--
-- None of this runs while a language is being detected: detection must never
-- widen, so an English or neutral line never reaches this code. The engine
-- calls Fuzzy.Word only from the translation pass that follows detection,
-- only for words it would otherwise count as unknown, and only for a few
-- words per line, so the cost stays bounded. Capitalised words inside a
-- clause are taken for names and left alone (except in German, where every
-- noun is capitalised).
--
-- The engine applies the result before translating: a corrected spelling
-- replaces the typed word in the atom, so "je cherhce un groupe" still meets
-- the template "je cherche un groupe *" and "koi de neuf" the phrase "quoi
-- de neuf"; a ready translation (a split contraction, a compound) is used
-- when the word lookup fails.
--
-- Public API (CommonTongue.Fuzzy):
--   Word(dir, atom, first, st)   "key", corrected spelling | "value", translation, isVerb | nil
--   Candidates(word)             the typo candidates of a word, in order (tests)
--   Lang:Respell(block)          respelling rules of a language (Grammar files)
--   MAX_PER_LINE                 unknown words given typo candidates per line

local B = CommonTongue
local U = B.UTF8
local E = B.Engine
local Lang = E.Lang
local sub, tconcat, tinsert = string.sub, table.concat, table.insert

local F = {}
B.Fuzzy = F

F.MAX_PER_LINE = 4        -- unknown words per line that get typo candidates
local MIN_RESPELL = 3     -- shortest word given apostrophes and respelling
local MIN_TYPO = 5        -- shortest word given typo candidates
local MIN_LONG_TYPO = 6   -- shortest word for a dropped or an inserted letter
local MIN_COMPOUND = 7    -- shortest word split into two known words
local MAX_LEN = 16        -- longer tokens are not words

-- Languages that write compounds as one word.
local COMPOUNDING = { de = true, nl = true, sv = true, da = true, no = true, fi = true }
-- Letters that may join the two parts of a compound ("Arbeitsplatz").
local LINKERS = { "s", "n", "e", "en" }
-- Translations that cannot be a part of a compound: function words.
local FUNCTION_VALUE = {}
for w in ("the a an to of and or in on at for by with from is are am be was were not no yes "
          .. "i you he she it we they me us him her them my your his its our their this that"):gmatch("%S+") do
  FUNCTION_VALUE[w] = true
end

-- Elided subject or object pronouns that chat glues to the verb without the
-- apostrophe: "jsuis", "cest", "tes", "quil". Other elisions ("l'", "d'",
-- "n'", "m'", "s'") are only restored when the result is a dictionary key.
local SUBJECT_PREFIX = { j = "je", c = "ce", t = "tu", qu = "que" }

local VOWELS = { "a", "e", "i", "o", "u", "y" }

-- Keys next to each letter on QWERTY and AZERTY keyboards (union of both).
local NEIGHBOUR_SPEC = {
  q = "wasz", w = "qeasdzx", e = "wrsdfz", r = "etdfg", t = "ryfgh", y = "tughj",
  u = "yihjk", i = "uojkl", o = "ipklm", p = "olm", a = "qwszx", s = "adwezxq",
  d = "sferxc", f = "dgrtcv", g = "fhtyvb", h = "gjyubn", j = "hkuinm", k = "jliom",
  l = "kopm", z = "asxwqe", x = "zsdcw", c = "xdfv", v = "cfgb", b = "vghn",
  n = "bhjm", m = "njklpo",
}
-- letter -> letters to try in its place: the vowels and the neighbouring keys
local SUBST = {}
for c = 97, 122 do
  local ch = string.char(c)
  local list, seen = {}, { [ch] = true }
  for _, v in ipairs(VOWELS) do
    if not seen[v] then seen[v] = true; list[#list + 1] = v end
  end
  for nb in (NEIGHBOUR_SPEC[ch] or ""):gmatch(".") do
    if not seen[nb] then seen[nb] = true; list[#list + 1] = nb end
  end
  SUBST[ch] = list
end

local function trim(s)
  return (s:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

-------------------------------------------------------------------------------
-- Respelling rules
-------------------------------------------------------------------------------

--- Respelling rules, one per line:  from > to
-- Each rule turns the typed word (lower case, accents folded) into one
-- candidate that is then looked up like any other word. "from" is plain
-- text, not a pattern; every occurrence is replaced. Anchors:
--   ^from > to    only at the start of the word        (^k > qu: kestion)
--   from$ > to    only at the end of the word          (o$ > eau: bato)
--   $ > to        append to the word                   ($ > x: mieu -> mieux)
--   ^ > to        prepend to the word                  (^ > h: abitude)
--   from > ~      remove it
-- Rules are tried in order; the first candidate the dictionary knows wins.
-- @param block  multi-line string
function Lang:Respell(block)
  self.respell = self.respell or {}
  for line in block:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" and sub(line, 1, 1) ~= "#" then
      local from, to = line:match("^(.-)[ \t]*>[ \t]*(.-)$")
      if from then
        from, to = U.Normalize(from), U.Normalize(to)
        if to == "~" then to = "" end
        local anchor = "any"
        if from == "$" then
          anchor, from = "append", ""
        elseif from == "^" then
          anchor, from = "prepend", ""
        elseif sub(from, 1, 1) == "^" then
          anchor, from = "prefix", sub(from, 2)
        elseif sub(from, -1) == "$" then
          anchor, from = "suffix", sub(from, 1, -2)
        end
        if from ~= "" or anchor == "append" or anchor == "prepend" then
          tinsert(self.respell, { from = from, to = to, anchor = anchor })
        end
      end
    end
  end
end

--- Apply one rule to a word.
-- @return the respelled word, or nil when the rule does not apply
local function respellOne(word, rule)
  local from, to, anchor = rule.from, rule.to, rule.anchor
  if anchor == "append" then return word .. to end
  if anchor == "prepend" then return to .. word end
  local n = #from
  if anchor == "prefix" then
    if #word > n and sub(word, 1, n) == from then return to .. sub(word, n + 1) end
    return nil
  end
  if anchor == "suffix" then
    if #word > n and sub(word, -n) == from then return sub(word, 1, -n - 1) .. to end
    return nil
  end
  local s, e = word:find(from, 1, true)
  if not s then return nil end
  local out, pos = {}, 1
  while s do
    out[#out + 1] = sub(word, pos, s - 1)
    out[#out + 1] = to
    pos = e + 1
    s, e = word:find(from, pos, true)
  end
  out[#out + 1] = sub(word, pos)
  return tconcat(out)
end

-------------------------------------------------------------------------------
-- Apostrophes
-------------------------------------------------------------------------------

--- The elided prefixes the dictionary knows ("j'", "l'", "qu'" ...), as the
-- letters before the apostrophe, longest first. Built on first use.
local function elisions(L)
  if L._elide == nil then
    local list, seen = {}, {}
    for key in pairs(L.toEnglish) do
      if #key <= 4 and sub(key, -1) == "'" and not key:find(" ", 1, true) then
        local letters = sub(key, 1, -2)
        if letters ~= "" and not seen[letters] then
          seen[letters] = true
          list[#list + 1] = letters
        end
      end
    end
    table.sort(list, function(a, b)
      if #a ~= #b then return #a > #b end
      return a < b
    end)
    L._elide = list
  end
  return L._elide
end

--- "cest" -> "c'est", "jregarde" -> "j'regarde" -> "I look". The restored
-- form must be a dictionary key, or a subject pronoun before a word that is
-- a function word, a verb form or part of a known "je ..." phrase, so that
-- a word merely missing from the dictionary ("joie") is not read as "j'oie".
-- @return "key" and the restored key, or "value" and the translation of a
--         pronoun + verb split (plus true when a verb rule produced it)
local function apostrophe(dir, word)
  local L = dir.L
  for _, p in ipairs(elisions(L)) do
    local n = #p
    if #word > n + 1 and sub(word, 1, n) == p then
      local rest = sub(word, n + 1)
      local cand = p .. "'" .. rest
      if E.LookupKey(dir, cand) ~= nil then return "key", cand end
      local full = SUBJECT_PREFIX[p]
      if full then
        local pv = dir.map[p .. "'"]
        if pv ~= nil then
          local rv, isVerb = E.LookupWord(dir, rest, true)
          if rv ~= nil and (isVerb or L.stopwords[rest] or dir.map[full .. " " .. rest] ~= nil
                            or E.Conjugate(L, rest) ~= nil) then
            if pv == "" then return "value", rv, isVerb end
            if rv == "" then return "value", pv, isVerb end
            return "value", pv .. " " .. rv, isVerb
          end
        end
      end
    end
  end
  return nil
end

-------------------------------------------------------------------------------
-- Typo candidates
-------------------------------------------------------------------------------

--- The word as an array of code points (each a short string).
local function codepoints(w)
  local cps, i, n = {}, 1, #w
  while i <= n do
    local _, size = U.DecodeAt(w, i)
    cps[#cps + 1] = sub(w, i, i + size - 1)
    i = i + size
  end
  return cps
end

--- Call fn(candidate, kind) for every spelling at edit distance one, most
-- likely slip first: two letters swapped, a letter doubled, a letter replaced
-- by a vowel or a neighbouring key, then (longer words only) a letter dropped
-- and a vowel inserted. Stops at the first call that returns a value.
-- @return what fn returned, or nil
local function eachCandidate(word, fn)
  local cps = codepoints(word)
  local n = #cps
  local ascii = not word:find("[\128-\255]")
  local v, isVerb
  -- two letters swapped: "serveru", "cherhce"
  for i = 1, n - 1 do
    if cps[i] ~= cps[i + 1] then
      cps[i], cps[i + 1] = cps[i + 1], cps[i]
      v, isVerb = fn(tconcat(cps), "swap")
      cps[i], cps[i + 1] = cps[i + 1], cps[i]
      if v ~= nil then return v, isVerb end
    end
  end
  -- a letter doubled: "paser" -> "passer"
  for i = 1, n do
    if cps[i] ~= cps[i - 1] then
      v, isVerb = fn(tconcat(cps, "", 1, i) .. cps[i] .. tconcat(cps, "", i + 1, n), "double")
      if v ~= nil then return v, isVerb end
    end
  end
  if ascii then
    -- a vowel or a neighbouring key hit instead: "minde" -> "monde"
    for i = 1, n do
      local alts = SUBST[cps[i]]
      if alts then
        local head, tail = sub(word, 1, i - 1), sub(word, i + 1)
        for _, r in ipairs(alts) do
          v, isVerb = fn(head .. r .. tail, "subst")
          if v ~= nil then return v, isVerb end
        end
      end
    end
  end
  if n >= MIN_LONG_TYPO then
    -- a letter dropped: "tyrouve" -> "trouve"
    for i = 1, n do
      if cps[i] ~= cps[i + 1] then
        v, isVerb = fn(tconcat(cps, "", 1, i - 1) .. tconcat(cps, "", i + 1, n), "drop")
        if v ~= nil then return v, isVerb end
      end
    end
    if ascii then
      -- a vowel left out: "vrment" -> "vraiment" is two slips, "paysge" one
      for i = 1, n + 1 do
        local head, tail = sub(word, 1, i - 1), sub(word, i)
        for _, vw in ipairs(VOWELS) do
          if vw ~= cps[i] and vw ~= cps[i - 1] then
            v, isVerb = fn(head .. vw .. tail, "insert")
            if v ~= nil then return v, isVerb end
          end
        end
      end
    end
  end
  return nil
end

--- The typo candidates of a word, in the order they are tried (for tests).
-- @param word  lower-case word
-- @return array of { candidate, kind }
function F.Candidates(word)
  local out = {}
  eachCandidate(word, function(cand, kind)
    out[#out + 1] = { cand, kind }
    return nil
  end)
  return out
end

-------------------------------------------------------------------------------
-- Compounds
-------------------------------------------------------------------------------

--- A dictionary value that can stand as one part of a compound: a content
-- word, not a dropped filler or a function word.
local function contentValue(v)
  return v ~= nil and v ~= "" and not FUNCTION_VALUE[v] and not v:find("'", 1, true)
end

--- Split a word into two dictionary words, the longest first part first:
-- "heilergruppe" -> "healer group". A linking letter between the parts is
-- allowed ("arbeitsplatz"). Function words are not accepted as parts.
local function compound(dir, word)
  local n = #word
  for k = n - 3, 3, -1 do
    local left, right = sub(word, 1, k), sub(word, k + 1)
    local vr = E.LookupKey(dir, right)
    if vr == nil then vr = E.StripSuffix(dir, right) end
    if contentValue(vr) then
      local vl = E.LookupKey(dir, left)
      if not contentValue(vl) then
        vl = nil
        for _, link in ipairs(LINKERS) do
          local m = #link
          if k > m + 2 and sub(left, -m) == link then
            local v = E.LookupKey(dir, sub(left, 1, -m - 1))
            if contentValue(v) then vl = v; break end
          end
        end
      end
      if vl ~= nil then return vl .. " " .. vr end
    end
  end
  return nil
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Resolve a word the dictionary does not know, by restoring an apostrophe,
-- respelling it, splitting it into a compound or treating it as a typo.
-- Called by the engine only after the language has been detected, before
-- the templates and phrases of the translation pass run.
-- @param dir    translation direction (native -> English)
-- @param a      the word atom (lower, fold, cap)
-- @param first  true when the word opens its clause (so a capital is not a name)
-- @param st     the pass statistics; fuzzyBudget limits the typo work per line
-- @return "key" and the corrected spelling, a word the dictionary knows that
--         is translated in the typed word's place (so phrases and templates
--         see it too); or "value" and a ready translation (a pronoun + verb
--         split, a compound) plus true when it came from a verb rule; or nil
function F.Word(dir, a, first, st)
  local word = a.lower
  local n = #word
  if n < MIN_RESPELL or n > MAX_LEN or a.wide then return nil end
  local L = dir.L
  -- a capitalised word inside the clause is a name (German capitalises nouns)
  if a.cap and not first and L.code ~= "de" then return nil end

  local kind, res, isVerb = apostrophe(dir, word)
  if kind then return kind, res, isVerb end

  local fold = a.fold
  if L.respell then
    for _, rule in ipairs(L.respell) do
      local cand = respellOne(fold, rule)
      if cand and cand ~= fold and cand ~= word and E.LookupWord(dir, cand, true) ~= nil then
        return "key", cand
      end
    end
  end

  if n >= MIN_COMPOUND and COMPOUNDING[L.code] then
    res = compound(dir, word)
    if res ~= nil then return "value", res end
  end

  if n >= MIN_TYPO then
    local budget = st.fuzzyBudget or F.MAX_PER_LINE
    if budget <= 0 then return nil end
    st.fuzzyBudget = budget - 1
    local initial = sub(fold, 1, 1)
    res = eachCandidate(fold, function(cand, kind)
      -- slips rarely change the first letter; demanding it cuts the false
      -- corrections of words that are simply missing from the dictionary
      if sub(cand, 1, 1) ~= initial then return nil end
      if kind == "swap" or kind == "double" or kind == "drop" then
        if E.LookupWord(dir, cand, true) ~= nil then return cand end
        return nil
      end
      if E.LookupKey(dir, cand) ~= nil or E.StripSuffix(dir, cand) ~= nil then return cand end
      return nil
    end)
    if res ~= nil then return "key", res end
  end
  return nil
end
