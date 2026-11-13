-- CommonTongue / English.lua
--
-- English is the pivot language: every dictionary maps its language to
-- English, and any-to-any translation goes through it. This file holds the
-- English knowledge the engine needs:
--
--   * verb inflection, so that one English base verb covers every conjugated
--     form of a foreign verb ("look for" -> "looking for", "looked for")
--   * which English words are nouns and which adjectives normally stand
--     before a noun, so "pociones baratas" can be reordered to "cheap potions"
--   * post-editing of a word-for-word result ("can to help" -> "can help",
--     "there is mobs" -> "there are mobs", "a useless" -> "a useless" but
--     "a elite" -> "an elite")
--
-- Public API (CommonTongue.English):
--   Ing(verb) Past(verb) Part(verb) S3(verb)   inflected forms
--   Render(template, base)                     fill a conjugation template
--   Plural(noun) IsNoun(text) IsAttrAdj(text)  nouns and attributive adjectives
--   PostEdit(sentence)                         tidy a translated sentence
--   Nouns, AttrAdj                             the word sets themselves

local B = CommonTongue
local EN = {}
B.English = EN

--- Build a set from a whitespace-separated word list.
local function set(block)
  local t = {}
  for w in block:gmatch("[^ \t\r\n]+") do t[w] = true end
  return t
end

-------------------------------------------------------------------------------
-- Verb inflection
-------------------------------------------------------------------------------

-- base = { past, participle [, -ing form] }. Regular verbs are not listed;
-- the -ing form is only given where the regular rule would double a letter
-- wrongly ("opening", not "openning").
local IRREGULAR = {
  be = { "was", "been", "being" }, have = { "had", "had" }, ["do"] = { "did", "done" },
  go = { "went", "gone" }, come = { "came", "come" }, get = { "got", "got" },
  give = { "gave", "given" }, take = { "took", "taken" }, make = { "made", "made" },
  see = { "saw", "seen" }, know = { "knew", "known" }, think = { "thought", "thought" },
  find = { "found", "found" }, buy = { "bought", "bought" }, sell = { "sold", "sold" },
  pay = { "paid", "paid" }, run = { "ran", "run" }, win = { "won", "won" },
  lose = { "lost", "lost" }, leave = { "left", "left" }, keep = { "kept", "kept" },
  send = { "sent", "sent" }, say = { "said", "said" }, tell = { "told", "told" },
  read = { "read", "read" }, write = { "wrote", "written" }, speak = { "spoke", "spoken" },
  hear = { "heard", "heard" }, put = { "put", "put" }, cut = { "cut", "cut" },
  hit = { "hit", "hit" }, let = { "let", "let" }, set = { "set", "set" },
  bring = { "brought", "brought" }, fight = { "fought", "fought" },
  begin = { "began", "begun", "beginning" }, fall = { "fell", "fallen" },
  eat = { "ate", "eaten" }, drink = { "drank", "drunk" }, sleep = { "slept", "slept" },
  meet = { "met", "met" }, hold = { "held", "held" }, stand = { "stood", "stood" },
  understand = { "understood", "understood" }, forget = { "forgot", "forgotten", "forgetting" },
  ["break"] = { "broke", "broken" }, choose = { "chose", "chosen" }, wear = { "wore", "worn" },
  ride = { "rode", "ridden" }, fly = { "flew", "flown" }, steal = { "stole", "stolen" },
  throw = { "threw", "thrown" }, draw = { "drew", "drawn" }, build = { "built", "built" },
  spend = { "spent", "spent" }, feel = { "felt", "felt" }, mean = { "meant", "meant" },
  sit = { "sat", "sat" }, teach = { "taught", "taught" }, catch = { "caught", "caught" },
  shoot = { "shot", "shot" }, grow = { "grew", "grown" }, become = { "became", "become" },
  swim = { "swam", "swum" }, sing = { "sang", "sung" }, wake = { "woke", "woken" },
  quit = { "quit", "quit" }, shut = { "shut", "shut" }, cost = { "cost", "cost" },
  hurt = { "hurt", "hurt" }, lead = { "led", "led" }, lend = { "lent", "lent" },
  open = { "opened", "opened", "opening" }, enter = { "entered", "entered", "entering" },
  level = { "leveled", "leveled", "leveling" }, happen = { "happened", "happened", "happening" },
  listen = { "listened", "listened", "listening" }, visit = { "visited", "visited", "visiting" },
  travel = { "traveled", "traveled", "traveling" }, cancel = { "canceled", "canceled", "canceling" },
  answer = { "answered", "answered", "answering" }, offer = { "offered", "offered", "offering" },
  gather = { "gathered", "gathered", "gathering" }, remember = { "remembered", "remembered", "remembering" },
  summon = { "summoned", "summoned", "summoning" }, whisper = { "whispered", "whispered", "whispering" },
  follow = { "followed", "followed", "following" }, fix = { "fixed", "fixed", "fixing" },
  play = { "played", "played", "playing" }, stay = { "stayed", "stayed", "staying" },
  cast = { "cast", "cast" }, reset = { "reset", "reset", "resetting" },
  equip = { "equipped", "equipped", "equipping" }, prefer = { "preferred", "preferred", "preferring" },
  control = { "controlled", "controlled", "controlling" }, transfer = { "transferred", "transferred", "transferring" },
  split = { "split", "split", "splitting" }, beat = { "beat", "beaten" }, bet = { "bet", "bet", "betting" },
  spread = { "spread", "spread" }, upset = { "upset", "upset", "upsetting" }, bite = { "bit", "bitten" },
  hide = { "hid", "hidden" }, shake = { "shook", "shaken" }, freeze = { "froze", "frozen" },
  swear = { "swore", "sworn" }, tear = { "tore", "torn" }, bleed = { "bled", "bled" },
  feed = { "fed", "fed" }, flee = { "fled", "fled" }, light = { "lit", "lit" },
  deal = { "dealt", "dealt" }, sweep = { "swept", "swept" }, strike = { "struck", "struck" },
  stick = { "stuck", "stuck" }, dig = { "dug", "dug", "digging" }, hang = { "hung", "hung" },
  rise = { "rose", "risen" }, seek = { "sought", "sought" }, bind = { "bound", "bound" },
  wind = { "wound", "wound" }, ring = { "rang", "rung" }, spin = { "spun", "spun", "spinning" },
}

--- Split a verb phrase into its head verb and the rest: "look for" -> "look", " for".
-- Only the head inflects.
local function split(verb)
  local head, rest = verb:match("^([^ \t\r\n]+)(.*)$")
  return head or verb, rest or ""
end

--- Does the final consonant double before -ing/-ed? ("stop" -> "stopping")
local function doubles(v)
  return v:match("^[^aeiou]*[aeiou][^aeiouwxy]$") ~= nil
end

--- The -ing form: "take" -> "taking", "die" -> "dying", "stop" -> "stopping".
-- @param verb  base verb or verb phrase
-- @return string
function EN.Ing(verb)
  local v, rest = split(verb)
  local irr = IRREGULAR[v]
  local out
  if irr and irr[3] then out = irr[3]
  elseif v:sub(-2) == "ie" then out = v:sub(1, -3) .. "ying"
  elseif v:sub(-1) == "e" and not v:match("[eyo]e$") and #v > 2 then out = v:sub(1, -2) .. "ing"
  elseif doubles(v) then out = v .. v:sub(-1) .. "ing"
  else out = v .. "ing" end
  return out .. rest
end

--- Regular past tense: "try" -> "tried", "stop" -> "stopped", "like" -> "liked".
local function regularPast(v)
  if v:sub(-1) == "e" then return v .. "d" end
  if v:match("[^aeiou]y$") then return v:sub(1, -2) .. "ied" end
  if doubles(v) then return v .. v:sub(-1) .. "ed" end
  return v .. "ed"
end

--- The simple past: "go" -> "went", "play" -> "played".
-- @param verb  base verb or verb phrase
-- @return string
function EN.Past(verb)
  local v, rest = split(verb)
  local irr = IRREGULAR[v]
  return (irr and irr[1] or regularPast(v)) .. rest
end

--- The past participle: "go" -> "gone", "play" -> "played".
-- @param verb  base verb or verb phrase
-- @return string
function EN.Part(verb)
  local v, rest = split(verb)
  local irr = IRREGULAR[v]
  return (irr and irr[2] or regularPast(v)) .. rest
end

--- The third person singular: "go" -> "goes", "try" -> "tries", "have" -> "has".
-- @param verb  base verb or verb phrase
-- @return string
function EN.S3(verb)
  local v, rest = split(verb)
  local out
  if v == "have" then out = "has"
  elseif v == "be" then out = "is"
  elseif v:match("[sxz]$") or v:match("[cs]h$") or v:match("[^aeiou]o$") then out = v .. "es"
  elseif v:match("[^aeiou]y$") then out = v:sub(1, -2) .. "ies"
  else out = v .. "s" end
  return out .. rest
end

--- Fill a conjugation template with the forms of a base verb.
-- Template codes: %s base, %s3 he/she form, %ing, %ed (past), %en (participle).
-- "we %s" with "play" -> "we play"; "%ing" with "take" -> "taking".
-- @param template  string with % codes
-- @param base      English base verb
-- @return string
function EN.Render(template, base)
  return (template:gsub("%%([a-z][a-z0-9]*)", function(code)
    if code == "s" then return base
    elseif code == "s3" then return EN.S3(base)
    elseif code == "ing" then return EN.Ing(base)
    elseif code == "ed" then return EN.Past(base)
    elseif code == "en" then return EN.Part(base)
    end
  end))
end

-------------------------------------------------------------------------------
-- Parts of speech (only what the reordering rule needs)
-------------------------------------------------------------------------------

--- English nouns the reordering rule may move an adjective in front of.
EN.Nouns = set([==[
  group party raid guild quest dungeon instance boss mob monster elite level gold silver copper
  coin money price offer deal item thing stuff weapon armor shield sword axe mace dagger bow
  crossbow gun staff wand ring necklace amulet cloak cape boots gloves helmet helm chest robe
  legs pants shoulders belt bracers cloth leather mail plate tabard bag potion elixir flask
  food water drink bread bandage key door gate mine cave tower castle fortress city town
  village inn tavern bridge river lake sea mountain hill road path forest island camp
  graveyard map zone area place entrance exit mount horse flight boat ship zeppelin
  hearthstone stone home house pet demon mage warrior priest rogue hunter druid paladin
  warlock shaman tank healer class race role talent skill spell mana health energy rage
  profession recipe pattern material ore bar gem jewel herb flower dust essence shard linen
  wool silk iron tin mithril thorium steel bronze wood scroll book battleground arena duel
  fight battle war honor rank alliance horde enemy ally champion lord king queen people
  person guy girl man woman boy kid player newbie veteran leader officer member team gear
  set piece stack character account name server realm faction world game match patch bug
  friend dude dragon wolf bear spider murloc orc troll undead human dwarf gnome elf tauren
  totem trinket gun arrow bullet poison rune charm mask crown hat shirt dress tunic vest
  hammer blade spear polearm fist claw fang egg fish meat cheese fruit wine beer
]==])

-- Words that take "a" although they start with a vowel letter, and words
-- that take "an" although they start with a consonant letter.
local A_BEFORE = set([==[
  useless user users used useful usual usually unique uniform union unit units united universal
  universe university utility euro euros europe european one once ewe
]==])
local AN_BEFORE = set([==[
  hour hours hourly honest honor honour honorable heir heirs herb herbs
]==])

--- Adjectives that normally stand before the noun in English. State words
-- such as ready, dead, full, free and busy are left out on purpose:
-- "tanque listo" means "tank ready", not "ready tank".
EN.AttrAdj = set([==[
  red blue green purple gray grey white black yellow orange golden pink brown
  silk linen wool woolen leather cloth mail plate iron steel copper tin bronze mithril thorium
  motivated experienced active friendly serious casual real true fake
  wooden stone bone arcane fire frost shadow nature elite
  big small huge tiny large little new old cheap expensive good bad better best worse worst
  high low fast slow easy hard strong weak rare epic legendary common uncommon nice pretty
  beautiful ugly dangerous important different same last first next long short heavy light
  dark magic magical ancient sacred cursed holy great giant young poor rich
]==])

-- Irregular and uncountable plurals.
local PLURALS = {
  wolf = "wolves", elf = "elves", dwarf = "dwarves", thief = "thieves", knife = "knives",
  staff = "staves", man = "men", woman = "women", person = "people", mouse = "mice",
  foot = "feet", tooth = "teeth", fish = "fish", gold = "gold", mana = "mana", gear = "gear",
  cloth = "cloth", leather = "leather", stuff = "stuff", money = "money", water = "water",
  food = "food", health = "health", armor = "armor", mail = "mail", plate = "plate",
}

--- Plural of an English noun or noun phrase (the last word inflects).
-- @param text  "potion", "mana potion"
-- @return "potions", "mana potions"
function EN.Plural(text)
  local head, w = text:match("^(.-)([A-Za-z]+)$")
  if not w then return text end
  local lw = w:lower()
  if PLURALS[lw] then return head .. PLURALS[lw] end
  if lw:match("[sxz]$") or lw:match("[cs]h$") then return text .. "es" end
  if lw:match("[^aeiou]y$") then return head .. w:sub(1, -2) .. "ies" end
  return text .. "s"
end

--- Is the (last word of the) text a known noun, singular or plural?
-- @param text  English word or phrase
-- @return boolean
function EN.IsNoun(text)
  local w = text:lower():match("([A-Za-z]+)$")
  if not w then return false end
  if EN.Nouns[w] then return true end
  if w:sub(-1) == "s" and EN.Nouns[w:sub(1, -2)] then return true end
  if w:sub(-2) == "es" and EN.Nouns[w:sub(1, -3)] then return true end
  return false
end

--- Is the text an adjective that stands before its noun?
-- @param text  English word
-- @return boolean
function EN.IsAttrAdj(text)
  return EN.AttrAdj[text:lower()] == true
end

-------------------------------------------------------------------------------
-- Post-editing of a word-for-word English result
-------------------------------------------------------------------------------
-- Each rule below is a Lua pattern applied to the sentence padded with one
-- space at each end, so " word " matches whole words only. The patterns are
-- built once here, not for every message.

local function capitalised(w) return w:sub(1, 1):upper() .. w:sub(2) end

local DETERMINERS = set([==[
  the a an my your his her its our their this that these those some any every each no
  me you him us them
]==])

-- "can to help" -> "can help": a verb after one of these never takes "to".
local MODALS = { "can", "could", "will", "would", "should", "must", "may", "might", "let's",
                 "don't", "doesn't", "didn't", "can't", "won't", "cannot", "to", "I'll", "we'll", "you'll",
                 "help me", "help us", "help you", "help him", "help her", "help them" }
local MODAL_TO = {}
for _, m in ipairs(MODALS) do
  MODAL_TO[#MODAL_TO + 1] = "([ \t\r\n]" .. m .. ") to ([A-Za-z]+)"
  local cap = capitalised(m)
  if cap ~= m then MODAL_TO[#MODAL_TO + 1] = "([ \t\r\n]" .. cap .. ") to ([A-Za-z]+)" end
end

-- "can you to invite me" -> "can you invite me"
local AUX = { "can", "could", "will", "would", "should", "must", "do", "does", "did" }
local SUBJECTS = { "you", "I", "we", "they", "he", "she", "anyone", "someone", "it" }
local AUX_SUBJECT_TO = {}   -- { needle, capNeedle, { patterns } }
for _, aux in ipairs(AUX) do
  local pats = {}
  for _, subj in ipairs(SUBJECTS) do
    pats[#pats + 1] = "([ \t\r\n]" .. aux .. " " .. subj .. ") to "
    pats[#pats + 1] = "([ \t\r\n]" .. capitalised(aux) .. " " .. subj .. ") to "
  end
  AUX_SUBJECT_TO[#AUX_SUBJECT_TO + 1] = { aux, capitalised(aux), pats }
end

-- "he doesn't understands" -> "he doesn't understand"
local NEG_AUX = { "don't", "doesn't", "didn't", "can't", "won't", "couldn't", "wouldn't", "shouldn't", "cannot" }
local NEG_AUX_FORMS = {}
for _, aux in ipairs(NEG_AUX) do
  for _, form in ipairs({ aux, capitalised(aux) }) do
    NEG_AUX_FORMS[#NEG_AUX_FORMS + 1] = { form, "([ \t\r\n]" .. form .. " )([A-Za-z]+)" }
  end
end

-- "I I want" -> "I want";  "no I want" -> "I don't want"
local PRONOUN_RULES = {}
for _, subj in ipairs({ "I", "you", "we", "they" }) do
  PRONOUN_RULES[#PRONOUN_RULES + 1] = {
    subj,
    "([ \t\r\n])" .. subj .. " " .. subj .. "([ '])",
    "%1" .. subj .. "%2",
    "([ \t\r\n])[Nn]o " .. subj .. " ([A-Za-z]+)([ \t\r\n,%.!%?;:])",
  }
end

--- "understands" -> "understand", "goes" -> "go", "tries" -> "try". The base
-- form is only returned when it is a word the dictionaries know, so "this",
-- "yes" or "bonus" are never touched.
local function unS3(w)
  if w == "has" then return "have" end
  if w == "does" then return "do" end
  if #w < 4 or w:sub(-1) ~= "s" or w:sub(-2) == "ss" then return nil end
  local cands = { w:sub(1, -2) }
  if w:sub(-2) == "es" then cands[#cands + 1] = w:sub(1, -3) end
  if w:sub(-3) == "ies" then cands[#cands + 1] = w:sub(1, -4) .. "y" end
  for _, c in ipairs(cands) do
    if EN.S3(c) == w and B.EnglishLexicon and B.EnglishLexicon[c] then return c end
  end
  return nil
end

--- Drop "to" after a modal unless the next word is a determiner, in which
-- case it is a preposition: "have to to the vendor" keeps the second "to".
local function dropTo(lead, nextWord)
  if DETERMINERS[nextWord:lower()] then return nil end
  return lead .. " " .. nextWord
end

--- Tidy a word-for-word English sentence. Every rule is conservative: it
-- only fires on a pattern that is wrong in all readings.
-- @param s  English sentence
-- @return edited sentence
function EN.PostEdit(s)
  s = " " .. s .. " "
  if s:find(" to ", 1, true) then
    for _ = 1, 2 do
      for _, pat in ipairs(MODAL_TO) do s = s:gsub(pat, dropTo) end
    end
    if s:find(" to ", 1, true) then
      for _, entry in ipairs(AUX_SUBJECT_TO) do
        if s:find(entry[1], 1, true) or s:find(entry[2], 1, true) then
          for _, pat in ipairs(entry[3]) do s = s:gsub(pat, "%1 ") end
        end
      end
    end
  end
  for _, rule in ipairs(PRONOUN_RULES) do
    local subj = rule[1]
    s = s:gsub(rule[2], rule[3])
    s = s:gsub(rule[4], function(lead, verb, tail)
      if verb:sub(-2) == "ed" or verb == "don't" or verb == "can't" or verb == "am" or verb == "will" then return nil end
      return lead .. subj .. " don't " .. verb .. tail
    end)
  end
  if s:find("n't", 1, true) or s:find("cannot", 1, true) then
    for _, entry in ipairs(NEG_AUX_FORMS) do
      if s:find(entry[1], 1, true) then
        s = s:gsub(entry[2], function(lead, verb)
          local base = unS3(verb)
          if base then return lead .. base end
          return nil
        end)
      end
    end
  end
  -- "there is mobs" -> "there are mobs", "there is 2 tanks" -> "there are 2 tanks"
  s = s:gsub("([ \t\r\n][Tt]here) is ([A-Za-z0-9]+)", function(lead, w)
    local n = tonumber(w)
    if n and n > 1 then return lead .. " are " .. w end
    local lw = w:lower()
    if lw:sub(-1) == "s" and lw:sub(-2) ~= "ss" and not EN.Nouns[lw] and EN.IsNoun(lw) then
      return lead .. " are " .. w
    end
    return nil
  end)
  s = s:gsub("([ \t\r\n])for to ", "%1to ")
  s = s:gsub("([ \t\r\n])the the ", "%1the ")
  s = s:gsub("([ \t\r\n])a a ", "%1a ")
  s = s:gsub("([ \t\r\n])of of ", "%1of ")
  -- the article agrees with the sound of the next word: "an elite", "a user", "an hour"
  s = s:gsub("([ \t\r\n])([Aa]) ([A-Za-z]+)", function(sp, a, w)
    local lw = w:lower()
    local vowelLetter = lw:match("^[aeiou]") ~= nil
    if (vowelLetter and not A_BEFORE[lw]) or AN_BEFORE[lw] then return sp .. a .. "n " .. w end
    return nil
  end)
  s = s:gsub("([ \t\r\n])i([ \t\r\n'])", "%1I%2")
  s = s:gsub("([ \t\r\n])i([,%.!%?])", "%1I%2")
  return (s:gsub("^ ", ""):gsub(" $", ""))
end
