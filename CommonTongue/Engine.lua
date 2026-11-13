-- CommonTongue / Engine.lua
-- The translation engine. Every language is described against English, and
-- any-to-any translation pivots through English. A line is translated by a
-- cascade, best method first:
--
--   1. sentence templates  "busco grupo para *" -> "looking for group for *"
--                          fluent output and correct word order; the * slots
--                          are translated recursively
--   2. phrase table        idioms and multi-word expressions
--   3. word lookup         exact, accent-folded, suffix-stripped, elided
--                          ("l'entrée"), conjugated (any form of a known verb)
--                          and de-emphasised ("holaaaa")
--   4. reordering          noun + adjective -> adjective + noun where needed
--
-- (Whole sentences already seen are answered before any of this, from the
-- translation memory in Memory.lua.)

local B = CommonTongue
local U = B.UTF8
local T = B.Text
local EN = B.English
local tinsert, tconcat, sub = table.insert, table.concat, string.sub

B.Languages = {}        -- code -> language object
B.LanguageOrder = {}    -- codes in registration order
B.Neutral = {}          -- words that belong to no language (lfg, wts, dps ...)
B.EnglishLexicon = {}   -- every English word the dictionaries translate into

local ADJ_AFTER_NOUN = { es = true, pt = true, fr = true, it = true }
local PLURAL_S = { es = true, pt = true, fr = true, nl = true }
local CURRENCY = { gold = true, silver = true, copper = true }
local EN_ARTICLES = { the = true, a = true, an = true }
local EN_SUFFIXES = { "s", "es", "ed", "ing" }
local SLOT = "\1*"      -- marks a slot inside a compiled template
local MAX_DEPTH = 4

local Lang = {}
Lang.__index = Lang

local function trim(s)
  return (s:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

--- Number of space-separated words in a normalised key.
local function countWords(key)
  if not key:find(" ", 1, true) then return 1 end
  local n = 1
  for _ in key:gmatch(" ") do n = n + 1 end
  return n
end

-- Dictionary key: lower case, straight apostrophes, hyphens as spaces.
local function normKey(k)
  k = U.Normalize(k)
  k = k:gsub("([^ \t\r\n])%-([^ \t\r\n])", "%1 %2")
  k = k:gsub("([^ \t\r\n])%-([^ \t\r\n])", "%1 %2")
  return k
end

local function eachLine(block, fn)
  for line in block:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" and sub(line, 1, 1) ~= "#" then
      local eq = line:find("=", 1, true)
      if eq then fn(trim(sub(line, 1, eq - 1)), trim(sub(line, eq + 1))) end
    end
  end
end

local function splitAlts(s)
  local out = {}
  for part in s:gmatch("[^|]+") do
    part = trim(part)
    if part ~= "" then out[#out + 1] = part end
  end
  return out
end

-------------------------------------------------------------------------------
-- Registration
-------------------------------------------------------------------------------

--- Create a language. Called once at the top of each Dict/<code>.lua; the
-- language object it returns receives the dictionary blocks.
-- @param code  two-letter code ("es")
-- @param name  English name ("Spanish")
-- @param opts  optional table:
--   native       the language's own name
--   script       "latin" (default) | "cyrillic" | "han" | "hangul" | "kana"
--   spaceless    true for languages written without spaces (zh, ja)
--   stopwords    whitespace-separated function words (evidence for detection)
--   hints        array of characteristic letters or letter pairs ("ñ", "ij")
--   suffixes     array of endings the word lookup may strip ("s", "en")
--   adjAfterNoun true when adjectives follow the noun (reordered in English)
-- @return the language object
function B:RegisterLanguage(code, name, opts)
  opts = opts or {}
  local adj = opts.adjAfterNoun
  if adj == nil then adj = ADJ_AFTER_NOUN[code] or false end
  local L = setmetatable({
    code = code,
    name = name,
    native = opts.native or name,
    script = opts.script or "latin",
    spaceless = opts.spaceless or false,
    adjAfterNoun = adj,
    toEnglish = {},
    fromEnglish = {},
    fold = {},              -- accent-folded key -> real key
    maxTokens = 1,
    maxEnTokens = 1,
    stopwords = {},
    hints = opts.hints or {},
    suffixes = opts.suffixes or {},
    verbs = {},             -- infinitive -> English base verb
    verbFold = {},
    conj = {},              -- conjugation rules
    patterns = { idx = {}, slotIdx = {}, count = 0 },
    enPatterns = { idx = {}, slotIdx = {}, count = 0 },
    spPatterns = {},        -- templates for languages written without spaces
    entryCount = 0,
  }, Lang)
  if opts.stopwords then L:SetStopwords(opts.stopwords) end
  B.Languages[code] = L
  tinsert(B.LanguageOrder, code)
  return L
end

--- Words that belong to every language ("lfg", "dps", "lol"): they count as
-- evidence for none and are never translated unless a dictionary has an
-- entry of its own for them.
-- @param block  whitespace- or comma-separated words
function B:AddNeutral(block)
  for w in block:gmatch("[^ \t\r\n,]+") do B.Neutral[U.Normalize(w)] = true end
end

--- English name of a language code, or the code itself when unknown.
function B:LanguageName(code)
  local L = B.Languages[code]
  if L then return L.name end
  return code
end

--- Function words of the language, stored both as typed and accent-folded.
-- @param block  whitespace- or comma-separated words
function Lang:SetStopwords(block)
  for w in block:gmatch("[^ \t\r\n,]+") do
    w = U.Normalize(w)
    self.stopwords[w] = true
    local f = T.Fold(w)
    if f ~= w and self.stopwords[f] == nil then self.stopwords[f] = true end
  end
end

-- English function words and language-neutral gaming terms say nothing
-- about which language a line is in ("for", "a", "lets", "tank").
local function isEnglishWord(w)
  local en = B.Languages.en
  return (en ~= nil and en.stopwords[w] == true) or B.Neutral[w] == true
end

-- May a typed key that only matches after accent folding stand for the real
-- key? Not when a typed English stopword would become a different word:
-- "for" is not "för", "for a" is not "for å".
local function foldAllowed(typed, real)
  if typed == real then return true end
  local en = B.Languages.en
  if not en then return true end
  if not typed:find(" ", 1, true) then return not en.stopwords[typed] end
  local realWords, i = {}, 0
  for w in real:gmatch("[^ ]+") do realWords[#realWords + 1] = w end
  for w in typed:gmatch("[^ ]+") do
    i = i + 1
    if w ~= realWords[i] and en.stopwords[w] then return false end
  end
  return true
end

--- Store one native -> English entry. The first definition of a key wins
-- unless override is set (player-taught entries).
function Lang:_setKey(key, value, override)
  if self.toEnglish[key] == nil then
    self.entryCount = self.entryCount + 1
  elseif not override then
    return
  end
  self.toEnglish[key] = value
  local n = countWords(key)
  if n > self.maxTokens then self.maxTokens = n end
  local f = T.Fold(key)
  if f ~= key and self.fold[f] == nil then self.fold[f] = key end
  self._sorted = nil
end

--- Store one English -> native entry and note the English words in the
-- shared lexicon (which tells the detector a word is ordinary English).
function Lang:_setReverse(english, native, override, allowEmpty)
  local k = U.Normalize(english)
  if k == "" or (native == "" and not allowEmpty) then return end
  for w in k:gmatch("[A-Za-z']+") do
    if #w >= 2 then B.EnglishLexicon[w] = true end
  end
  if self.fromEnglish[k] ~= nil and not override then return end
  self.fromEnglish[k] = native
  local n = countWords(k)
  if n > self.maxEnTokens then self.maxEnTokens = n end
end

--- Dictionary block, one entry per line:
--   native | native alt | ... = english | english alt | ...
-- Every native form translates to the FIRST English form; the further
-- English forms only add reverse (English -> native) entries. The first
-- native form is what English is translated into. '~' as the English side
-- means the word is dropped from the translation. Lines starting with '#'
-- are comments. Keys may be phrases; phrases are looked up before words.
-- @param block  multi-line string
function Lang:Add(block)
  eachLine(block, function(left, right)
    local keys, values = {}, splitAlts(right)
    for _, k in ipairs(splitAlts(left)) do
      k = self.spaceless and U.Normalize(k) or normKey(k)
      if k ~= "" then keys[#keys + 1] = k end
    end
    if #keys == 0 or #values == 0 then return end
    local primary = values[1]
    if primary == "~" then primary = "" end
    for _, k in ipairs(keys) do self:_setKey(k, primary) end
    for _, v in ipairs(values) do
      if v ~= "~" then self:_setReverse(v, keys[1]) end
    end
  end)
end

--- Explicit English -> native preferences:  english | english alt = native
-- These win over the reverse entries derived from Add. '~' as the native
-- side means the English word is simply left out.
-- @param block  multi-line string
function Lang:Reverse(block)
  eachLine(block, function(left, right)
    local native = U.Normalize(right)
    local omit = (native == "~")
    if omit then native = "" end
    for _, k in ipairs(splitAlts(left)) do self:_setReverse(k, native, true, omit) end
  end)
end

--- A single entry that wins over the shipped dictionary (/tongue teach).
-- @param native   word or phrase in this language
-- @param english  its translation
function Lang:Override(native, english)
  local k = self.spaceless and U.Normalize(native) or normKey(native)
  if k == "" then return end
  self:_setKey(k, english, true)
  self:_setReverse(english, k, true)
end

--- Object pronouns that stand before the verb:  lo | la = it     se = ~
-- "lo maté" is then read as verb + object: "I killed it". A pronoun that
-- repeats the subject ("me voy" = "I go") is given as '~' and dropped.
-- @param block  multi-line string
function Lang:Clitics(block)
  self.clitics = self.clitics or {}
  eachLine(block, function(left, right)
    local v = splitAlts(right)[1] or ""
    if v == "~" then v = "" end
    for _, k in ipairs(splitAlts(left)) do
      self.clitics[T.Fold(U.Normalize(k))] = v
    end
  end)
end

--- Verb list:  infinitive | alt = english base verb
-- Together with the Conjugation rules this covers every form of the verb:
-- the infinitive itself becomes "to <base>", and any conjugated form found
-- by a rule is rendered from the base with English.lua.
-- @param block  multi-line string
function Lang:Verbs(block)
  eachLine(block, function(left, right)
    local base = splitAlts(right)[1]
    if not base then return end
    for i, inf in ipairs(splitAlts(left)) do
      inf = normKey(inf)
      self.verbs[inf] = base
      local f = T.Fold(inf)
      if self.verbFold[f] == nil then self.verbFold[f] = base end
      self:_setKey(inf, "to " .. base)
      if i == 1 then
        self:_setReverse("to " .. base, inf)
        self:_setReverse(base, inf)
      end
    end
  end)
end

--- Conjugation rules:  suffix > infinitive ending = english template
--   amos > ar = we %s        ando > ar = %ing        ó > ar = %ed
-- A word ending in the suffix is tried as "stem + infinitive ending"; when
-- that is a listed verb, the template is rendered with its English base.
-- Template codes: %s base, %s3 he/she form, %ing, %ed (past), %en (participle).
-- Longer suffixes are tried first.
-- @param block  multi-line string
function Lang:Conjugation(block)
  eachLine(block, function(left, template)
    local suf, inf = left:match("^([^ \t\r\n]*)[ \t\r\n]*>[ \t\r\n]*([^ \t\r\n]*)$")
    if not suf or suf == "" then return end
    suf = U.Normalize(suf)
    local sufF = T.Fold(suf)
    tinsert(self.conj, { suf = suf, sufF = sufF, inf = U.Normalize(inf or ""), tpl = template, plain = (suf == sufF) })
  end)
  table.sort(self.conj, function(a, b)
    if #a.sufF ~= #b.sufF then return #a.sufF > #b.sufF end
    if a.plain ~= b.plain then return a.plain end
    return a.suf < b.suf
  end)
end

-------------------------------------------------------------------------------
-- Templates
-------------------------------------------------------------------------------

-- Compile one side of a template into items: folded literal words and slots.
-- A slot is { ref = n }. '*' numbers slots in order; '$2' names slot 2.
local function compileSide(text, foldLiterals)
  local items, lit, nslots, raws = {}, 0, 0, {}
  text = text:gsub("([^ \t\r\n])%-([^ \t\r\n])", "%1 %2")
  for tok in text:gmatch("[^ \t\r\n]+") do
    if tok == "*" then
      nslots = nslots + 1
      items[#items + 1] = { ref = nslots }
    elseif tok:match("^%$%d$") then
      nslots = nslots + 1
      items[#items + 1] = { ref = tonumber(tok:sub(2)) }
    else
      local w = U.Normalize(tok)
      items[#items + 1] = foldLiterals and T.Fold(w) or w
      raws[#items] = w
      lit = lit + 1
    end
  end
  return items, lit, nslots, raws
end

local function indexTemplate(store, tpl)
  local lead = 0
  for _, it in ipairs(tpl.items) do
    if type(it) ~= "string" then break end
    lead = lead + 1
  end
  tpl.lead = lead
  -- literal words that count as evidence for the language, and the length
  -- of the first literal run (for templates that begin with a slot)
  local evidence, run, inRun = 0, 0, false
  for k, it in ipairs(tpl.items) do
    if type(it) == "string" then
      if not isEnglishWord(tpl.raws and tpl.raws[k] or it) then evidence = evidence + 1 end
      if run == 0 or inRun then run = run + 1; inRun = true end
    elseif inRun then
      inRun = false
    end
  end
  tpl.evidence = evidence
  tpl.firstRun = run
  local first = tpl.items[1]
  if type(first) == "string" then
    store.idx[first] = store.idx[first] or {}
    tinsert(store.idx[first], tpl)
  else
    for _, it in ipairs(tpl.items) do
      if type(it) == "string" then
        store.slotIdx[it] = store.slotIdx[it] or {}
        tinsert(store.slotIdx[it], tpl)
        break
      end
    end
  end
  store.count = store.count + 1
end

local function luaPattern(side)
  -- template for a language without spaces: literals around lazy captures
  local parts, lit, nslots = {}, 0, 0
  local pos = 1
  while true do
    local s, e = side:find("*", pos, true)
    local literal = sub(side, pos, (s or 0) - 1)
    literal = U.Normalize(literal):gsub(" ", "")
    lit = lit + #literal
    -- escape only Lua's own magic characters; %p would depend on the locale
    parts[#parts + 1] = (literal:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
    if not s then break end
    nslots = nslots + 1
    parts[#parts + 1] = "(.-)"
    pos = e + 1
  end
  local pat = "^" .. tconcat(parts) .. "$"
  return pat, lit, nslots
end

--- Sentence templates:  native pattern | alt pattern = english pattern | english alt
-- '*' is a slot of one or more words, translated on its own by the whole
-- engine again (so slots may contain phrases and further templates):
--   busco grupo para * = looking for group for *
--   kann mir jemand bei * helfen = can anyone help me with *
--   vendo * por * = selling * for *
-- English may reorder slots with $1 $2:   * 的 * = $2 of $1
-- The first English form is the output; further English forms add reverse
-- templates for the English -> native direction.
-- @param block  multi-line string
function Lang:Patterns(block)
  eachLine(block, function(left, right)
    local natives, englishes = splitAlts(left), splitAlts(right)
    if #natives == 0 or #englishes == 0 then return end
    local english = englishes[1]
    for _, native in ipairs(natives) do
      if self.spaceless then
        local pat, lit, nslots = luaPattern(native)
        if lit > 0 and nslots > 0 then
          tinsert(self.spPatterns, { pat = pat, lit = lit, out = english, nslots = nslots })
          self._spSorted = false
        end
      else
        local items, lit, nslots, raws = compileSide(native, true)
        if lit > 0 then
          indexTemplate(self.patterns, { items = items, raws = raws, lit = lit, out = english, nslots = nslots })
        end
      end
    end
    -- reverse direction: English pattern -> first native form
    if not self.spaceless then
      local native = natives[1]
      for _, en in ipairs(englishes) do
        local items, lit, nslots, raws = compileSide(en, false)
        if lit > 0 then
          -- out is native text whose k-th '*' takes the English slot with ref k
          local order = {}
          local j = 0
          for _, it in ipairs(items) do
            if type(it) == "table" then j = j + 1; order[it.ref] = j end
          end
          indexTemplate(self.enPatterns, { items = items, raws = raws, lit = lit, out = native, nslots = nslots, order = order })
        end
      end
    end
  end)
end

-- Fill a template's output with translated slot texts.
local function render(tpl, caps)
  local k = 0
  return (tpl.out:gsub("[%$%*]%d?", function(tok)
    if tok == "*" then
      k = k + 1
      if tpl.order then return caps[tpl.order[k] or k] or "" end
      return caps[k] or ""
    elseif #tok == 2 and sub(tok, 1, 1) == "$" then
      return caps[tonumber(sub(tok, 2))] or ""
    end
  end))
end

-- Try to match compiled items against atoms[pos..q]. Slots take one or more
-- atoms, as few as possible. Returns the last matched position or nil; caps
-- receives { first, last } per slot in order of appearance.
local function matchItems(items, k, atoms, pos, q, caps, raws)
  local it = items[k]
  if it == nil then return pos - 1 end
  if type(it) == "table" then
    if pos > q then return nil end
    if items[k + 1] == nil then
      caps[#caps + 1] = { pos, q }
      return q
    end
    for e = pos, q - 1 do
      caps[#caps + 1] = { pos, e }
      local r = matchItems(items, k + 1, atoms, e + 1, q, caps, raws)
      if r then return r end
      caps[#caps] = nil
    end
    return nil
  end
  local a = atoms[pos]
  if pos <= q and a and (a.kind == "word" or a.kind == "mixed") and a.fold == it then
    -- a typed English stopword must match the literal as spelled ("for" is not "för")
    local raw = raws and raws[k]
    if raw and a.lower ~= raw and B.Languages.en and B.Languages.en.stopwords[a.lower] then
      return nil
    end
    return matchItems(items, k + 1, atoms, pos + 1, q, caps, raws)
  end
  return nil
end

-------------------------------------------------------------------------------
-- Word lookup
-------------------------------------------------------------------------------

--- Exact dictionary lookup of a word or phrase, then accent-folded, then via
-- the folded-key index (so "mision" finds "misión"), provided the typed
-- form is not an English word in its own right.
-- @param dir  translation direction (see DirTo/DirFrom)
-- @param key  normalised word or phrase
-- @return the entry ("" for omitted words) or nil
local function lookupKey(dir, key)
  local v = dir.map[key]
  if v ~= nil then return v end
  if dir.toEn then
    local fk = T.Fold(key)
    if fk ~= key then
      v = dir.map[fk]
      if v ~= nil then return v end
    end
    local real = dir.L.fold[fk]
    if real and foldAllowed(key, real) then return dir.map[real] end
  end
  return nil
end

-- The word with one of the language's endings removed, if that is an entry.
local function stripSuffix(dir, word)
  local v
  local suffixes = dir.toEn and dir.L.suffixes or EN_SUFFIXES
  for _, suf in ipairs(suffixes) do
    local sl = #suf
    if #word > sl + 2 and sub(word, -sl) == suf then
      v = lookupKey(dir, sub(word, 1, -sl - 1))
      if v ~= nil then
        -- "minas" found as "mina": keep the plural in English
        if dir.toEn and (suf == "s" or suf == "es") and PLURAL_S[dir.L.code]
           and v ~= "" and sub(v, -1) ~= "s" and EN.IsNoun(v) then
          v = EN.Plural(v)
        end
        return v
      end
    end
  end
  return nil
end

-- Any conjugated form of a verb in the language's verb list.
local function conjugate(L, word)
  if #L.conj == 0 then return nil end
  local fword = T.Fold(word)
  for pass = 1, 3 do
    for _, rule in ipairs(L.conj) do
      local w, suf
      if pass == 1 then w, suf = word, rule.suf
      elseif pass == 2 then if rule.plain then w, suf = fword, rule.sufF end
      else if not rule.plain then w, suf = fword, rule.sufF end end
      if w and #w > #suf + 1 and sub(w, -#suf) == suf then
        local inf = sub(w, 1, -#suf - 1) .. rule.inf
        local base = L.verbs[inf] or L.verbFold[T.Fold(inf)]
        if base then return EN.Render(rule.tpl, base) end
      end
    end
  end
  return nil
end

local function lookupStem(dir, word)
  local v = lookupKey(dir, word)
  if v ~= nil then return v end
  return stripSuffix(dir, word)
end

-- Is this word a conjugated form of one of the language's verbs?
function Lang:Conjugates(word)
  return conjugate(self, word) ~= nil
end

--- Translate a single word by every means available, cheapest first:
-- exact or folded entry, a stripped ending, elision ("l'entrée"), a
-- conjugated verb form, and finally the de-emphasised spelling ("holaaaa").
-- @param dir        translation direction
-- @param word       normalised word
-- @param noSqueeze  internal: do not try the de-emphasised forms again
-- @return the translation or nil, and true when it came from a verb rule
local function lookupWord(dir, word, noSqueeze)
  local v = lookupKey(dir, word)
  if v ~= nil then return v end
  -- An ending was stripped. For a language with conjugation rules this is
  -- trusted at once only for noun plurals ("minas" = mines); otherwise a
  -- conjugated verb reading gets the first try ("spielten" = played).
  local stemmed = stripSuffix(dir, word)
  if stemmed ~= nil and not (dir.toEn and #dir.L.conj > 0 and not EN.IsNoun(stemmed)) then
    return stemmed
  end
  -- elision: "l'entrée" = "l'" + "entrée"
  local apos = word:find("'", 1, true)
  if apos and apos > 1 and apos < #word then
    local rest = lookupStem(dir, sub(word, apos + 1))
    if rest ~= nil then
      local prefix = dir.map[sub(word, 1, apos)]
      if prefix == nil or prefix == "" then return rest end
      return prefix .. " " .. rest
    end
  end
  if dir.toEn then
    v = conjugate(dir.L, word)
    if v ~= nil then return v, true end
  end
  if stemmed ~= nil then return stemmed end
  if not noSqueeze then
    local a, b = T.Squeeze(word)
    local isVerb
    if a then v, isVerb = lookupWord(dir, a, true); if v ~= nil then return v, isVerb end end
    if b then v, isVerb = lookupWord(dir, b, true); if v ~= nil then return v, isVerb end end
  end
  return nil
end

local function startsWithSubject(v)
  return v:match("^I[ ']") or v:match("^you[ ']") or v:match("^we[ ']") or v:match("^they[ ']")
      or v:match("^he ") or v:match("^she ")
end

-------------------------------------------------------------------------------
-- Languages written without spaces (Chinese, Japanese)
-------------------------------------------------------------------------------
local translateSpacelessChunk

local function spacelessGreedy(L, text, st)
  local map = L.toEnglish
  if not L._sorted then
    local keys = {}
    for k in pairs(map) do tinsert(keys, k) end
    table.sort(keys, function(a, b)
      if #a ~= #b then return #a > #b end
      return a < b
    end)
    L._sorted = keys
    local byLead = {}
    for _, k in ipairs(keys) do
      local _, size = U.DecodeAt(k, 1)
      local lead = sub(k, 1, size or 1)
      byLead[lead] = byLead[lead] or {}
      tinsert(byLead[lead], k)
    end
    L._byLead = byLead
  end
  local pieces, pending = {}, {}
  local function flushPending()
    if #pending > 0 then
      tinsert(pieces, tconcat(pending))
      pending = {}
    end
  end
  local i, n = 1, #text
  while i <= n do
    local cp, size = U.DecodeAt(text, i)
    local found
    local candidates = L._byLead[sub(text, i, i + size - 1)]
    if candidates then
      for _, k in ipairs(candidates) do
        if sub(text, i, i + #k - 1) == k then found = k; break end
      end
    end
    if found then
      flushPending()
      local v = map[found]
      if v ~= "" then tinsert(pieces, v) end
      st.hits = st.hits + U.Length(found)
      i = i + #found
    else
      if cp >= 0x80 and U.Script(cp) then
        st.misses = st.misses + 1
      end
      tinsert(pending, sub(text, i, i + size - 1))
      i = i + size
    end
  end
  flushPending()
  return tconcat(pieces, " ")
end

translateSpacelessChunk = function(L, text, st, depth)
  if depth < MAX_DEPTH and #L.spPatterns > 0 then
    if not L._spSorted then
      table.sort(L.spPatterns, function(a, b) return a.lit > b.lit end)
      L._spSorted = true
    end
    for _, tpl in ipairs(L.spPatterns) do
      local caps = { text:match(tpl.pat) }
      if #caps == tpl.nslots and caps[1] ~= nil then
        local ok = true
        for _, c in ipairs(caps) do if c == "" then ok = false; break end end
        if ok then
          for k, c in ipairs(caps) do caps[k] = translateSpacelessChunk(L, c, st, depth + 1) end
          st.hits = st.hits + tpl.lit / 3
          st.phraseWords = st.phraseWords + 1
          st.templates = st.templates + 1
          return render(tpl, caps)
        end
      end
    end
  end
  return spacelessGreedy(L, text, st)
end

-------------------------------------------------------------------------------
-- Span translation
-------------------------------------------------------------------------------

local function isWordAtom(a)
  return a ~= nil and (a.kind == "word" or a.kind == "mixed")
end

-- Phrase and word pass over atoms[p..q]. Returns text without the leading
-- whitespace of the first atom.
local function glossSpan(dir, atoms, p, q, st)
  local pieces = {}
  local neutral = B.Neutral
  local carry
  local function push(piece)
    if carry and piece.pre == "" then piece.pre = carry end
    carry = nil
    pieces[#pieces + 1] = piece
  end
  local i = p
  while i <= q do
    local a = atoms[i]
    if isWordAtom(a) then
      if dir.spaceless and a.wide then
        local s = translateSpacelessChunk(dir.L, a.lower, st, 0)
        push({ text = s, pre = a.pre, hit = true })
        i = i + 1
      else
        local run, j = { i }, i
        while #run < dir.maxN do
          local nxt = atoms[j + 1]
          if j + 1 <= q and isWordAtom(nxt) and nxt.pre ~= "" then
            j = j + 1
            run[#run + 1] = j
          else
            break
          end
        end
        local value, last
        -- a phrase that starts with the pronoun wins: "se lance pas" = "won't start"
        for n = #run, 2, -1 do
          local parts = {}
          for m = 1, n do parts[m] = atoms[run[m]].lower end
          local v = lookupKey(dir, tconcat(parts, " "))
          if v ~= nil then
            value, last = v, run[n]
            st.hits = st.hits + n
            for m = 1, n do
              if not isEnglishWord(atoms[run[m]].lower) then st.phraseWords = st.phraseWords + 1 end
            end
            break
          end
        end
        -- object pronoun before a verb: "lo maté" -> "I killed it"
        local clitic = dir.toEn and dir.L.clitics and dir.L.clitics[a.fold]
        if value == nil and clitic ~= nil and #run >= 2 then
          local nxt = atoms[run[2]]
          if lookupKey(dir, a.lower .. " " .. nxt.lower) == nil then
            local v2, isVerb = lookupWord(dir, nxt.lower)
            if v2 and v2 ~= "" and (isVerb or startsWithSubject(v2)) then
              local obj = clitic
              if (a.fold == "me" or a.fold == "mi" or a.fold == "m'") and v2:match("^I[ ']") then obj = "" end
              if (a.fold == "te" or a.fold == "ti" or a.fold == "t'") and v2:match("^you[ ']") then obj = "" end
              if (a.fold == "nos" or a.fold == "nous" or a.fold == "ci") and v2:match("^we[ ']") then obj = "" end
              value = (obj ~= "") and (v2 .. " " .. obj) or v2
              last = run[2]
              st.hits = st.hits + 2
            end
          end
        end
        if value == nil then
          local v, isVerb
          if dir.toEn and (neutral[a.lower] or neutral[T.Squeeze(a.lower) or ""]) and lookupKey(dir, a.lower) == nil then
            -- international shorthand with no entry of its own stays as it is:
            -- "grats" must not be read as a Danish plural of "grat" (gray)
            v = nil
          else
            v, isVerb = lookupWord(dir, a.lower)
          end
          if v == nil and a.kind == "mixed" and dir.toEn then
            -- a number glued to a currency word: "3po" = "3 gold", "50pa" = "50 silver"
            local num, unit = a.lower:match("^([0-9]+)([a-z]+)$")
            if num then
              local g = lookupKey(dir, unit)
              if g and CURRENCY[g] then v = num .. " " .. g end
            end
          end
          if v == nil and not dir.toEn and EN_ARTICLES[a.lower] then
            v = ""   -- an English article the target language has no word for
          end
          if v ~= nil then
            value, last = v, i
            st.hits = st.hits + 1
            if isVerb then st.conjugated = st.conjugated + 1 end
          end
        end
        -- pronoun attached with a hyphen: "matei-o" -> "I killed it"
        if value ~= nil and value ~= "" and dir.toEn and dir.L.clitics then
          local nxt = atoms[last + 1]
          if last + 1 <= q and isWordAtom(nxt) and nxt.pre == "-" and dir.L.clitics[nxt.fold] ~= nil then
            local obj = dir.L.clitics[nxt.fold]
            if obj ~= "" then value = value .. " " .. obj end
            last = last + 1
            st.hits = st.hits + 1
          end
        end
        if value ~= nil then
          if value ~= "" then
            push({ text = value, pre = a.pre, hit = true })
          elseif a.pre ~= "" and not carry then
            carry = a.pre
          end
          i = last + 1
        else
          if a.kind == "word" and #a.lower > 1 and not neutral[a.lower] then
            st.misses = st.misses + 1
            st.unknown[#st.unknown + 1] = a.lower
          end
          push({ text = a.text, pre = a.pre, kind = a.kind })
          i = i + 1
        end
      end
    else
      push({ text = a.text, pre = a.pre, kind = a.kind })
      i = i + 1
    end
  end

  if dir.adjSwap then
    -- noun + adjective -> adjective + noun
    local k = 1
    while k < #pieces do
      local a, b = pieces[k], pieces[k + 1]
      if a.hit and b.hit and b.pre ~= "" and b.pre ~= "-" and EN.IsAttrAdj(b.text) and EN.IsNoun(a.text) then
        a.text, b.text = b.text, a.text
        st.reordered = st.reordered + 1
        k = k + 2
      else
        k = k + 1
      end
    end
    -- "potions of mana" -> "mana potions";  "5 of gold" -> "5 gold"
    k = 1
    while k + 2 <= #pieces do
      local a, b, c, d = pieces[k], pieces[k + 1], pieces[k + 2], pieces[k + 3]
      if b.hit and b.text == "of" and c.hit and not c.text:find(" ", 1, true) then
        if (a.kind == "num" or a.kind == "mixed") and CURRENCY[c.text] then
          table.remove(pieces, k + 1)
          st.reordered = st.reordered + 1
        elseif a.hit and EN.IsNoun(a.text) and EN.IsNoun(c.text) and sub(c.text, -1) ~= "s"
               and not (d and (d.kind == "num" or d.kind == "mixed" or d.hit)) then
          a.text, c.text = c.text, a.text
          table.remove(pieces, k + 1)
          st.reordered = st.reordered + 1
        end
      end
      k = k + 1
    end
  end

  local out = {}
  for k, piece in ipairs(pieces) do
    if k > 1 then
      if dir.joinTight and piece.hit and pieces[k - 1].hit then
        -- target written without spaces
      elseif piece.pre == "-" and (piece.hit or pieces[k - 1].hit) then
        out[#out + 1] = " "
      else
        out[#out + 1] = piece.pre
      end
    end
    out[#out + 1] = piece.text
  end
  return tconcat(out)
end

local translateSpan

-- Number of words in the longest dictionary phrase starting at atoms[i].
local function longestPhraseAt(dir, atoms, i, q)
  local run, j = { i }, i
  while #run < dir.maxN do
    local nxt = atoms[j + 1]
    if j + 1 <= q and isWordAtom(nxt) and nxt.pre ~= "" then
      j = j + 1
      run[#run + 1] = j
    else
      break
    end
  end
  for n = #run, 2, -1 do
    local parts = {}
    for m = 1, n do parts[m] = atoms[run[m]].lower end
    if lookupKey(dir, tconcat(parts, " ")) ~= nil then return n end
  end
  return 1
end

--- Find the best sentence template inside atoms[p..q]: the one with the
-- most literal words, and among equals the earliest. A template loses to a
-- dictionary phrase that is longer than its opening literals, and may not
-- cut through a phrase that began before it.
-- @return { tpl, start, stop, caps } or nil
local function bestTemplate(dir, atoms, p, q)
  local pats = dir.pats
  if not pats or pats.count == 0 then return nil end
  local best
  local phraseLen = {}
  local function consider(tpl, start)
    if best and tpl.lit < best.tpl.lit then return end
    if best and tpl.lit == best.tpl.lit and start >= best.start then return end
    if tpl.lead > 0 then
      -- "tengo sueño" (a phrase) beats the template "tengo *"
      local n = phraseLen[start]
      if not n then
        n = longestPhraseAt(dir, atoms, start, q)
        phraseLen[start] = n
      end
      if n > tpl.lead then return end
      -- a template may not cut through a phrase that began earlier:
      -- "me voy a dormir" is one phrase, not "me" + "voy a *"
      for j = math.max(p, start - dir.maxN + 1), start - 1 do
        if isWordAtom(atoms[j]) then
          local m = phraseLen[j]
          if not m then
            m = longestPhraseAt(dir, atoms, j, q)
            phraseLen[j] = m
          end
          if m > 1 and j + m - 1 >= start then
            -- only real overlaps count: the phrase must reach the template
            local reach, k = j, 1
            while k < m do
              reach = reach + 1
              if isWordAtom(atoms[reach]) then k = k + 1 end
            end
            if reach >= start then return end
          end
        end
      end
    end
    local caps = {}
    local stop = matchItems(tpl.items, 1, atoms, start, q, caps, tpl.raws)
    if not stop then return end
    if tpl.lead == 0 and caps[1] then
      -- template that begins with a slot: its first literal words get the
      -- same protection against cutting through a dictionary phrase
      local first = caps[1][2] + 1
      local n = phraseLen[first]
      if not n then
        n = longestPhraseAt(dir, atoms, first, q)
        phraseLen[first] = n
      end
      if n > tpl.firstRun then return end
      for j = math.max(p, first - dir.maxN + 1), first - 1 do
        if isWordAtom(atoms[j]) then
          local m = phraseLen[j]
          if not m then
            m = longestPhraseAt(dir, atoms, j, q)
            phraseLen[j] = m
          end
          if m > 1 then
            local reach, k = j, 1
            while k < m do
              reach = reach + 1
              if isWordAtom(atoms[reach]) then k = k + 1 end
            end
            if reach >= first then return end
          end
        end
      end
    end
    best = { tpl = tpl, start = start, stop = stop, caps = caps }
  end
  for i = p, q do
    local a = atoms[i]
    if isWordAtom(a) then
      local list = pats.idx[a.fold]
      if list then
        for _, tpl in ipairs(list) do consider(tpl, i) end
      end
      if i > p then
        list = pats.slotIdx[a.fold]
        if list then
          for _, tpl in ipairs(list) do consider(tpl, p) end
        end
      end
    end
  end
  return best
end

-- Translate atoms[p..q] (one clause or part of one).
translateSpan = function(dir, atoms, p, q, st, depth)
  if p > q then return "" end
  local m = depth < MAX_DEPTH and bestTemplate(dir, atoms, p, q) or nil
  if not m then return glossSpan(dir, atoms, p, q, st) end

  local caps = {}
  for k, c in ipairs(m.caps) do
    caps[k] = translateSpan(dir, atoms, c[1], c[2], st, depth + 1)
  end
  -- slots that name their position ($2) index by reference
  local byRef, k = {}, 0
  for _, it in ipairs(m.tpl.items) do
    if type(it) == "table" then
      k = k + 1
      byRef[it.ref] = caps[k]
    end
  end
  local mid = render(m.tpl, m.tpl.order and caps or byRef)
  st.hits = st.hits + m.tpl.lit
  st.phraseWords = st.phraseWords + (m.tpl.evidence or m.tpl.lit)
  st.templates = st.templates + 1

  local out = {}
  if m.start > p then
    local left = translateSpan(dir, atoms, p, m.start - 1, st, depth)
    if left ~= "" then
      out[#out + 1] = left
      out[#out + 1] = (atoms[m.start].pre ~= "" and atoms[m.start].pre ~= "-") and atoms[m.start].pre or " "
    end
  end
  out[#out + 1] = mid
  if m.stop < q then
    local right = translateSpan(dir, atoms, m.stop + 1, q, st, depth)
    if right ~= "" then
      local pre = atoms[m.stop + 1].pre
      out[#out + 1] = (pre == "-") and " " or pre
      out[#out + 1] = right
    end
  end
  return tconcat(out)
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

-- Remove "article noun = noun" entries: the article translates by itself.
function Lang:_prune()
  self._pruned = true
  if self.spaceless then return end
  local drop = {}
  for key, value in pairs(self.toEnglish) do
    local first, rest = key:match("^([^ ]+) (.+)$")
    if first then
      local article = self.toEnglish[first]
      if article and EN_ARTICLES[article] and (value == rest or self.toEnglish[rest] == value) then
        drop[#drop + 1] = key
      end
    end
  end
  for _, key in ipairs(drop) do
    self.toEnglish[key] = nil
    self.entryCount = self.entryCount - 1
  end
end

--- The native -> English translation direction: the lookup map, the
-- templates and the reordering flags the span translator needs. Built on
-- first use, after the dictionary has been pruned.
function Lang:DirTo()
  if not self._pruned then self:_prune() end
  if not self._dirTo then
    self._dirTo = { L = self, toEn = true, map = self.toEnglish, pats = self.patterns,
                    spaceless = self.spaceless, adjSwap = self.adjAfterNoun }
  end
  self._dirTo.maxN = self.maxTokens
  return self._dirTo
end

--- The English -> native translation direction.
function Lang:DirFrom()
  if not self._dirFrom then
    self._dirFrom = { L = self, toEn = false, map = self.fromEnglish, pats = self.enPatterns,
                      joinTight = self.spaceless }
  end
  self._dirFrom.maxN = self.maxEnTokens
  return self._dirFrom
end

--- Statistics of one translation pass:
--   hits         words (and template literals) the dictionary accounted for
--   misses       words it did not know
--   phraseWords  words matched as part of a phrase or template (strong evidence)
--   templates    sentence templates applied
--   reordered    noun/adjective swaps made
--   conjugated   words read as conjugated verbs
--   unknown      the missed words themselves (for /tongue missing)
local function newStats()
  return { hits = 0, misses = 0, phraseWords = 0, templates = 0, reordered = 0, conjugated = 0, unknown = {} }
end

-- One pass over a whole line. atoms may be supplied to avoid re-atomising.
local function runPass(dir, text, atoms, tail)
  if not atoms then atoms, tail = T.Atomize(text) end
  local st = newStats()
  local out = {}
  local n, p = #atoms, 1
  for i = 1, n + 1 do
    local a = atoms[i]
    if a == nil or a.kind == "clause" then
      if p <= i - 1 then
        local s = translateSpan(dir, atoms, p, i - 1, st, 0)
        s = s:gsub("^[ \t\r\n]+", "")
        if s ~= "" then
          for k = p, i - 1 do
            if isWordAtom(atoms[k]) then
              -- English "I" is always a capital; it says nothing about the sentence
              if atoms[k].cap and not (dir.toEn == false and atoms[k].lower:match("^i$") or
                                       dir.toEn == false and atoms[k].lower:match("^i'")) then
                s = U.UpperFirst(s)
              end
              break
            end
          end
          out[#out + 1] = atoms[p].pre
          out[#out + 1] = s
        end
      end
      if a then
        out[#out + 1] = a.pre
        if not T.DROP[a.text] then out[#out + 1] = a.text end
      end
      p = i + 1
    end
  end
  out[#out + 1] = tail or ""
  return tconcat(out), st
end

-- Explain a line as language L: how much of it the language accounts for.
-- Used by detection; the translation is reused if L wins.
function Lang:Explain(text, atoms, tail)
  local s, st = runPass(self:DirTo(), text, atoms, tail)
  return s, st
end

--- Translate text from one language to another, pivoting through English.
-- @param text     raw chat line
-- @param from     source language code ("en" or a dictionary code)
-- @param to       target language code
-- @param english  optional: the line already rendered in English by the
--                 detector, so the first pass is not repeated
-- @param stats    optional: the statistics of that rendering
-- @return translated text, coverage (0..1: share of words understood),
--         hits, misses, stats; or nil when a language has no dictionary
function B:TranslateText(text, from, to, english, stats)
  if from == to then return text, 1, 0, 0 end
  local L1 = (from ~= "en") and B.Languages[from] or nil
  local L2 = (to ~= "en") and B.Languages[to] or nil
  if from ~= "en" and not L1 then return nil end
  if to ~= "en" and not L2 then return nil end

  local s, st = text, stats
  if L1 then
    if english then
      s = english            -- already explained during detection
    else
      s, st = runPass(L1:DirTo(), text)
    end
  end
  if L2 then
    local s2, st2 = runPass(L2:DirFrom(), s)
    s = s2
    st = st or st2
  else
    s = EN.PostEdit(s)
  end
  st = st or newStats()
  local total = st.hits + st.misses
  local coverage = total > 0 and (st.hits / total) or 0
  return s, coverage, st.hits, st.misses, st
end
