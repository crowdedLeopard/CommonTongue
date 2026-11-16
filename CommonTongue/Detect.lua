-- CommonTongue / Detect.lua
--
-- Which language is this chat line written in?
--
-- Non-Latin scripts are decided by the writing system alone: Hangul is
-- Korean, kana is Japanese, Han without kana is Chinese, Cyrillic is Russian
-- unless it contains letters only Ukrainian has.
--
-- Latin-script languages are decided by explanation. Cheap evidence
-- (stopwords, dictionary hits, characteristic letter pairs such as "ij" or
-- "ção") shortlists a few candidates; each candidate then translates the
-- whole line, and the one that accounts for the most of it, with the most
-- phrase and template matches, wins. English competes like any other
-- language, so that English lines are left alone, and words that belong to
-- every language ("lfg", "tank", "lol") count for none.
--
-- Public API:
--   B:DetectLanguage(text, prior) -> code, confidence, english, stats, unknownForeign
--
-- The English rendering produced while explaining is handed to the
-- translator, so a detected line is not translated twice.

local B = CommonTongue
local U = B.UTF8
local T = B.Text

-- Evidence weights.
local W_STOP = 1.0        -- a stopword of the language ("het", "pour")
local W_DICT = 0.5        -- any dictionary entry
local W_HINT = 2.0        -- a characteristic accented letter or pair ("ção", "ñ")
local W_HINT_ASCII = 0.75 -- a characteristic plain letter pair ("ij", "sch")
local W_PHRASE = 1.5      -- each phrase or template word matched while explaining
local SHORTLIST = 4       -- how many candidates get the full explanation pass

-- Letters that exist in Ukrainian but not in Russian: і ї є ґ
local UK_LETTERS = { "\209\150", "\209\151", "\209\148", "\210\145" }

--- Number of non-overlapping plain-text occurrences of needle in text.
local function countOccurrences(text, needle)
  local count, pos = 0, 1
  while true do
    local s, e = text:find(needle, pos, true)
    if not s then return count end
    count = count + 1
    pos = e + 1
  end
end

--- The word with runs of three or more repeated letters collapsed
-- ("holaaaa" -> "hola"), cached on the atom. Doubles are left alone here:
-- "till" and "takk" are words of their own, not "til" and "tak".
-- @return squeezed word, or false when there was nothing to squeeze
local function squeezed(a)
  if a.sq == nil then
    a.sq = T.Squeeze(a.fold) or false
  end
  return a.sq
end

--- Does language L have a dictionary entry for this word, exactly, accent
-- folded, or de-emphasised?
local function hasEntry(L, a)
  if L.toEnglish[a.lower] ~= nil then return true end
  if a.fold ~= a.lower and L.toEnglish[a.fold] ~= nil then return true end
  if L.fold[a.fold] ~= nil then return true end
  local sq = squeezed(a)
  if sq and (L.toEnglish[sq] ~= nil or L.fold[sq] ~= nil) then return true end
  return false
end

--- Is this word a stopword of language L?
local function isStop(L, a)
  if L.stopwords[a.lower] or L.stopwords[a.fold] then return true end
  local sq = squeezed(a)
  return (sq and L.stopwords[sq]) or false
end

--- Russian or Ukrainian: Ukrainian-only letters settle it; otherwise the
-- language that knows more of the words.
local function detectCyrillic(lowerText, words)
  for _, ch in ipairs(UK_LETTERS) do
    if lowerText:find(ch, 1, true) then return "uk", 1 end
  end
  local uk, ru = B.Languages.uk, B.Languages.ru
  local ukScore, ruScore = 0, 0
  for _, a in ipairs(words) do
    if uk and (isStop(uk, a) or hasEntry(uk, a)) then ukScore = ukScore + 1 end
    if ru and (isStop(ru, a) or hasEntry(ru, a)) then ruScore = ruScore + 1 end
  end
  if ukScore > ruScore then return "uk", 0.8 end
  return "ru", 0.9
end

--- Detect the language of a chat line.
-- @param text   raw chat line (markup is ignored)
-- @param prior  optional language code this speaker used before; a small
--               bonus when the line is ambiguous
-- @return code            language code, "en" for English, nil when undecided
-- @return confidence      0..1: how far ahead the winner is of its rival
-- @return english         the line rendered in English by the winner (reused
--                         by the translator), nil for non-dictionary results
-- @return stats           the winner's translation statistics (see Engine)
-- @return unknownForeign  true when the line looks foreign but matches no
--                         dictionary here (a candidate for the live bridge)
function B:DetectLanguage(text, prior)
  local plain = T.PlainText(text)
  local stats = U.ScriptStats(plain)
  if stats.total == 0 then return nil, 0 end
  local latin = stats.latin or 0

  -- scripts that identify a language by themselves
  if (stats.hangul or 0) > 0 and (stats.hangul or 0) >= (stats.han or 0) then return "ko", 1 end
  if ((stats.hiragana or 0) + (stats.katakana or 0)) > 0 then return "ja", 1 end
  if (stats.han or 0) > 0 then return "zh", 1 end
  if (stats.thai or 0) > latin then return "th", 1 end
  if (stats.arabic or 0) > latin then return "ar", 1 end
  if (stats.hebrew or 0) > latin then return "he", 1 end
  if (stats.greek or 0) > latin then return "el", 1 end

  local atoms, tail = T.Atomize(text)
  local words = T.Words(atoms)
  if #words == 0 then return nil, 0 end
  local lowerText = U.Lower(plain)

  if (stats.cyrillic or 0) > latin then
    return detectCyrillic(lowerText, words)
  end

  -- English evidence. Words that say nothing about any language are set
  -- aside; English stopwords are kept as "ambiguous" because many of them
  -- are words in other languages too ("a", "no", "me", "in").
  local en = B.Languages.en
  local lexicon = B.EnglishLexicon
  local enScore = 0
  local informative, ambiguous = {}, {}
  for _, a in ipairs(words) do
    if en and isStop(en, a) then
      enScore = enScore + ((#a.lower == 1) and 0.5 or W_STOP)
      ambiguous[#ambiguous + 1] = a
    elseif B.Neutral[a.lower] or B.Neutral[a.fold] or B.Neutral[squeezed(a) or ""] then
      -- lfg, tank, mobs: the same in every language, evidence for none
    else
      informative[#informative + 1] = a
      -- ordinary English vocabulary ("stone", "potion") is weaker evidence
      -- than a stopword, since dictionaries translate into these words
      if lexicon[a.lower] or B.English.Nouns[a.lower] or B.English.AttrAdj[a.lower] then
        enScore = enScore + 0.5
      end
    end
  end

  --- A line with little English in it that no dictionary recognises is
  -- probably a language without a dictionary here; the live bridge can
  -- still take it.
  local function foreignGuess()
    if enScore / #words >= 0.25 then return false end
    local long = 0
    for _, a in ipairs(informative) do
      if #a.lower >= 3 then long = long + 1 end
    end
    if long >= 3 then return true end
    return long >= 2 and plain:find("[\195-\197][\128-\191]") ~= nil
  end

  -- cheap evidence for every Latin-script language; letter pairs are counted
  -- on the text with stretched letters collapsed, so that "Saluuuuut" is
  -- not four Dutch "uu"
  local hintText = T.Collapse(lowerText)
  local cands = {}
  for _, code in ipairs(B.LanguageOrder) do
    local L = B.Languages[code]
    if L.script == "latin" and code ~= "en" then
      local ev = 0
      for _, a in ipairs(informative) do
        if isStop(L, a) then ev = ev + W_STOP end
        if hasEntry(L, a) then ev = ev + W_DICT end
      end
      for _, h in ipairs(L.hints) do
        local n = countOccurrences(hintText, h)
        if n > 0 then
          -- an accented letter is a strong sign; a plain letter pair is not
          ev = ev + (h:find("[\128-\255]") and W_HINT or W_HINT_ASCII) * n
        end
      end
      if ev < 1.0 and #informative <= 4 and #L.conj > 0 then
        -- a short line may consist of one verb form: "ajudas?", "tankst du"
        for _, a in ipairs(informative) do
          if not hasEntry(L, a) and not lexicon[a.lower] and L:Conjugates(a.lower) then ev = ev + W_STOP end
        end
      end
      local amb = 0
      for _, a in ipairs(ambiguous) do
        if isStop(L, a) or hasEntry(L, a) then amb = amb + 1 end
      end
      if code == prior and ev > 0 then ev = ev + 1.0 end
      if ev > 0 or amb > 0 then
        cands[#cands + 1] = { code = code, L = L, ev = ev, amb = amb, order = #cands }
      end
    end
  end
  local englishLikely = enScore > 0 and (#words <= 2 or enScore / #words >= 0.25)
  if #cands == 0 then
    if englishLikely then return "en", 1 end
    return nil, 0, nil, nil, foreignGuess()
  end
  table.sort(cands, function(a, b)
    local sa, sb = a.ev + 0.5 * a.amb, b.ev + 0.5 * b.amb
    if sa ~= sb then return sa > sb end
    return a.order < b.order
  end)

  -- explanation: the shortlisted languages each translate the line
  local best, second
  for i = 1, math.min(SHORTLIST, #cands) do
    local c = cands[i]
    local english, st = c.L:Explain(text, atoms, tail)
    c.english, c.st = english, st
    c.ev = c.ev + W_PHRASE * st.phraseWords + W_DICT * (st.conjugated or 0)
    -- shared words (a, no, me, in ...) count once the language has evidence of its own
    c.score = c.ev + ((c.ev > 0) and c.amb or 0)
    if not best or c.score > best.score or (c.score == best.score and st.hits > best.st.hits) then
      second, best = best, c
    elseif not second or c.score > second.score then
      second = c
    end
  end

  local needed = (#words <= 2) and 0.5 or 1.5
  if best.score < needed or best.score <= 1.5 * enScore then
    -- no dictionary language explains the line: English if it looks like
    -- English, otherwise possibly a language without a dictionary here
    if englishLikely then return "en", 1 end
    return nil, 0, nil, nil, foreignGuess()
  end
  local rival = math.max(enScore, second and second.score or 0)
  local confidence = (best.score - rival) / best.score
  return best.code, confidence, best.english, best.st
end
