# Grammar files for CommonTongue (engine v2)

The addon's translation engine was rewritten while the dictionaries were being written. Dictionaries (`Dict/xx.lua`) keep their format. Each language can now also have a grammar file, `Grammar/xx.lua`, which is what turns a word-for-word gloss into fluent English. This guide tells you how to write one.

Addon folder: the `CommonTongue/` folder next to `tools/` in this project.

Read first, in this order:
1. `Grammar\es.lua`: the complete worked example (Spanish). Copy its structure.
2. The header comment of `Engine.lua` and the functions `Lang:Clitics`, `Lang:Verbs`, `Lang:Conjugation`, `Lang:Patterns` (their comments define the syntax).

## What the engine now does by itself (do not duplicate it)

- **Accent folding**: `mision` finds `misión`, `fur` finds `für`, `е` finds `ё`. Template literals are folded too, so write templates WITHOUT accents duplicates; one spelling is enough. Dictionary entries no longer need unaccented variants either (existing ones are harmless).
- **Elongation**: `holaaaa`, `siiii`, `приветттт` are squeezed before lookup.
- **Elision**: a token with an apostrophe that is not a key is split: `l'entrée` = `l'` + `entrée`.
- **Hyphens**: `peut-être` is read as the phrase `peut être` (keys with hyphens are stored with spaces).
- **Plural kept** for es/pt/fr/nl when a plural `s` is stripped: `minas` → `mines`.
- **Reordering** for es/pt/fr/it: noun + adjective → adjective + noun (`pociones baratas` → `cheap potions`), `X of Y` → `Y X` for two bare nouns (`potions of mana` → `mana potions`), `5 of gold` → `5 gold`.
- **English post-editing**: `can to help` → `can help`, `can you to invite me` → `can you invite me`, `no I find it` → `I don't find it`, doubled subjects (`I I killed`) are merged, `a item` → `an item`.
- **Detection** is by explanation: each candidate language translates the line and the one that explains most wins; multi-word phrases and templates weigh most. English competes using stopwords plus every English word that any dictionary translates into. So templates and phrases also make detection better.
- Multi-word dictionary keys made only of English/neutral words (`lets go`, `for free`) are ignored on purpose.

## The grammar file

```lua
-- CommonTongue / Grammar/xx.lua  —  <Language> verbs, conjugation and sentence templates
local L = CommonTongue.Languages.xx
if not L then return end

L:Clitics([==[ ... ]==])       -- optional
L:Verbs([==[ ... ]==])         -- optional but valuable where verbs conjugate regularly
L:Conjugation([==[ ... ]==])   -- goes with Verbs
L:Patterns([==[ ... ]==])      -- the most valuable part: always write this
```

All blocks use `left = right` lines; `#` starts a comment line; `|` separates alternatives.

### 1. Patterns (sentence templates), every language

```
busco grupo para * | busco party para * = looking for group for *
kann mir jemand bei * helfen = can anyone help me with *
vendo * por * | vendo * a * = selling * for *
alguien sabe donde esta * = does anyone know where * is
```

- `*` is a slot: one or more tokens (words, numbers, item links). It is translated on its own by the whole engine again, so slots can contain further templates and phrases.
- Left side: one or more native patterns. Right side: the English output (first alternative is used; further `|` alternatives only add reverse English→native patterns).
- Slots are matched lazily; a template may start or end with a slot or a literal. A template does not need to cover the whole clause: text before it is translated separately, and if it ends with a literal, text after it too. Clauses are split at `, . ! ? ; :` so write templates for one clause.
- The most specific template wins (most literal words). So write BOTH the specific and the general form: `alguien sabe donde esta *` (4 literals) and `alguien sabe *` (2).
- A dictionary phrase that is longer than the template's opening literal words wins over the template (`tengo sueño` beats `tengo *`), and a template may not cut through a phrase that started earlier. You do not need to worry about colliding with dictionary phrases.
- English output may reorder slots: `* 的 * = $2 of $1`; otherwise the k-th `*` on the right is the k-th `*` on the left.
- Slot content keeps its own grammar: after `quiero * = I want *` the slot `matar al jefe` becomes `to kill the boss`, giving "I want to kill the boss". After modal templates the post-editor removes the extra `to` (`puedo * = I can *` + `to help` → `I can help`).
- Avoid one-literal templates built on very common function words that would swallow unrelated sentences (`es *`, `a *`, `que *`). One-literal templates on content verbs are fine (`vendo *`, `busco *`, `necesito *`).
- Keep the English canonical and natural: "looking for group for *", "does anyone have *", "can anyone help me with *", "where is *", "how much is *", "selling * for *", "I need *", "we need *", "need *" (for "missing X"), "anyone for *", "who wants *", "I'm in *", "let's *", "I'm going to *", "do you want *", "can you *", "I can't *", "I don't have *", "thanks for *", "invite me to *", "is anyone selling *", "guild * is recruiting".
- **Languages written without spaces (zh, ja)**: the pattern is matched against one run of text as a whole; write the literal characters directly around `*`, no spaces: `求组* = looking for group for *`, `*在哪 | *在哪里 = where is *`, `*募集 | *募集してます = recruiting *`, `有人*吗 = does anyone *`. Templates are tried longest-literal first and must match the whole run. Each `*` must be non-empty.
- **Verb-final and suffixing languages (ja, ko, tr, de subordinate clauses, fi)**: this is where templates matter most, because word order differs from English. Write them with the slot first: `* arıyorum = looking for *`, `* lazım | * lazim = need *`, `* var mı | * var mi = is there *`, `* 구합니다 | * 구해요 | * 구함 = looking for *`, `* 어디에요 | * 어디 = where is *`, `kann mir jemand bei * helfen`, `wer hat lust auf * = who's up for *`.

Target: 100 to 160 template lines per language (several native alternatives per line where natural), covering: looking for group/people/guild/roles; need/missing; questions (where is/are, where do I get/buy, how do I get to, how much is, what level is, what time, does anyone know/have/want/sell/buy, can anyone help/take/enchant/summon, who wants/has/can, can you …); trade (selling/buying/trading/giving away … for …, price asking, best offer, whisper me for); statements (I have/don't have, I want/don't want, I can/can't, I'm going to, let's, we have to, I'm in/at, we're in, I'm level, there is no, thanks for, sorry for, invite …, help me with, wait for, follow …, come to …, go to …); guild recruitment; dungeon and raid calls (ready for …, pull …, kill … first, heal …, res …, summon … please, need … more for …).

### 2. Verbs and Conjugation, for languages with regular suffix conjugation

```
L:Verbs([==[
matar = kill
buscar | busquar = look for
encontrar | encuentrar = find
]==])
L:Conjugation([==[
amos > ar = we %s
ando > ar = %ing
ó > ar = %ed
ame > ar = %s me
]==])
```

- `Verbs`: `infinitive | alternative stems = English base verb` (base form without "to"; may be two words: `look for`, `go down`). Each infinitive is also added to the dictionary as "to <base>".
- `Conjugation`: `suffix > infinitive ending = template`. A word that is not in the dictionary is tested against the rules, longest suffix first: strip `suffix`, add `infinitive ending`, look the result up in the verb list, fill the template. Template codes: `%s` base, `%s3` he/she form, `%ing`, `%ed` (past), `%en` (participle). English irregular verbs are handled for you.
- Stem or spelling changes: add a pseudo-infinitive as an alternative so the rules land on it (`encontrar | encuentrar`: `encuentro` → strip `o`, add `ar` → `encuentrar` → find; `pagar | paguar` for `pagué`).
- If the language prefixes or circumfixes (German `ge-…-t`, Dutch `ge-…-d`), the suffix rules cannot express it: put the frequent participles in the dictionary instead and use rules only for the suffix forms (`-e`, `-st`, `-t`, `-en`, `-te`).
- If the language's verb morphology is too irregular for suffix rules to work reliably (Russian aspect pairs, Finnish consonant gradation, Turkish vowel harmony with many suffix chains, Korean, Japanese), prefer listing the common conjugated forms in templates and in the dictionary, and write rules only for patterns that are safe. Wrong rules are worse than none: every rule you write should be tested with at least two verbs.
- Only words NOT found in the dictionary reach the rules, so existing entries are never overridden.
- Target for Romance and Germanic languages: 100 to 150 verbs (include the gaming loan-verbs the language actually uses: tanken, healen, farmen, looten, pullen, tankować, хилить, танчить…) and a full rule set for present, past, future, gerund/participle and imperative, plus enclitic forms where the language has them.

### 3. Clitics, for languages with object pronouns before the verb (Romance mainly)

```
L:Clitics([==[
lo | la = it
me = me
se = ~
]==])
```

When one of these words stands directly before a conjugated verb, it is moved behind the verb as its object: `lo maté` → "I killed it", `la encuentro` → "I find it". Reflexives that repeat the subject are dropped (`me muero` → "I die"). `~` drops the word. A dictionary phrase always wins (`lo siento` stays "sorry"). Italian: lo la li le mi ti ci vi si; French: le la les me te nous vous se (plus `l'`, `m'`, `t'`, `s'`); Portuguese: o a os as me te nos se lhe.

## Rules

- Write ONLY `Grammar/xx.lua` for your language(s). You may also fix or extend your own `Dict/xx.lua` when testing shows a gap (missing common word, wrong primary English value, an article that should be dropped with `~`). Do not touch other files.
- No combinatorial variant lists. Accent variants are unnecessary now.
- Do not put English or neutral gaming terms on the native side unless speakers really use that exact wording.

## Validate

```
C:\Users\User\AppData\Local\Temp\claude\9c26f63c4f1796ea\ea1023c8-616f-44fe-8af3-cc203fbffddd\scratchpad\luaenv\Scripts\python.exe -I C:\Users\User\AppData\Local\Temp\claude\9c26f63c4f1796ea\ea1023c8-616f-44fe-8af3-cc203fbffddd\scratchpad\run_tests.py "<addon folder>" "line 1" "line 2" ...
```

Each line prints `[xx 0.85] original` and, when a translation would be shown, `-> original [xx>en: translation]`. A "LOAD ERROR" in a file that is not yours means another agent is mid-write; wait a minute and retry. A LOAD ERROR in your file is yours to fix.

Test with at least 25 realistic chat lines per language that exercise your templates, conjugation rules and clitics: LFG requests with a dungeon name, trade ads with prices and an item link (`|cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r`), where/how/how-much questions, help requests, guild recruitment, short replies, past-tense and future statements ("we killed the boss", "I'll wait at the entrance"), object pronouns. Also run 5 plain English lines and 3 lines in the languages closest to yours; none of them may be detected as your language. Iterate until the English reads naturally. Judge by reading the output as a player would: could you act on it?

Report: number of templates, verbs and rules; 12 before/after sample lines; anything you could not make work.
