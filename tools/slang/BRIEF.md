# Slang pass: brief for one language

You are adding **chat slang** for one language to CommonTongue, a World of
Warcraft chat translator with a rule-based engine. Players type fast, sloppy,
abbreviated, regional and rude text. The dictionaries cover standard language
well and slang badly. Your job: one language, as much real slang as you can,
in the exact format below. You write ONE or TWO new text files and nothing
else. Do not edit any file under `CommonTongue/`. Do not run tests.

## What to read first

1. `CommonTongue/Dict/<lang>.lua`: skim the first 60 lines to see the format,
   then grep it for every key you intend to add. Keys that already exist are
   dropped by the merge script, so they are wasted effort. Existing entries win.
2. The `L:Patterns([==[ ... ]==])` block at the end of
   `CommonTongue/Grammar/<lang>.lua`: the template format.

## Output

Write `tools/slang/<lang>_1.txt` (UTF-8, at most 250 lines). If you have more,
write `tools/slang/<lang>_2.txt` (same limit). Layout:

```
## DICT
# comment lines start with #
native | native alt | native alt = english | english alt
...
## PATTERNS
native frame with * | other frame * = english frame *
...
## TEST
a realistic slangy chat line => the English you expect
...
```

Aim for 180-250 DICT lines (several alternatives each), up to 25 PATTERNS,
and 15 TEST lines. Quality and realism over count: every entry must be
something a player in this language would actually type in game chat.

## Dictionary line rules

- Left side: native forms, lowercase, separated by ` | `. Put the **standard
  spelling first** (the engine uses the first form when translating English
  into this language), then the slang, phonetic and abbreviated spellings.
- Right side: English, lowercase unless a name. The **first** English form is
  what players see. Further English forms are optional synonyms; keep them
  real, because each one becomes a reverse key (English into this language).
- `= ~` drops the word entirely. Use it for fillers and particles that have no
  English equivalent (Dutch "eens", German "mal", Spanish "pues" as a filler).
- Multi-word keys match as phrases and beat single words, so **prefer phrases**
  for idioms: `doe es normaal = act normal`, not a word-by-word attempt.
- Multi-word keys must contain **no digits** ("2 mains" cannot match). Single
  tokens with digits are fine ("w8" is fine).
- At most 12 alternatives per line; split long sets over several lines with the
  same right side.
- Never use `]==]`, `|` inside a form, or `=` on the left side.
- Accents: the engine folds accents for matching, but players also type
  accentless; if the accentless form is common and not an existing word, add it.

## What to cover (in rough priority)

1. Abbreviations and texting spellings specific to this language (not the
   international ones, see below): dropped vowels, numbers-as-syllables,
   merged words ("kga" = "ik ga"), common typos that became spellings.
2. Discourse particles, fillers, interjections and reaction words: map to `~`
   or to a natural English equivalent ("joh", "hoor", "nou", "halt", "eben",
   "pues", "vaya", "cazzo", "bref", "ну", "же", "no" at the end of a sentence).
3. Youth slang and regional slang used online (Flemish for Dutch, Latin America
   for Spanish, Brazil for Portuguese, Austria/Switzerland for German, Quebec
   for French, and so on). Mark nothing; just include it.
4. Swearing, insults, trash talk and toxic gamer phrases with their plain
   English meaning. Do NOT include ethnic, religious, homophobic, transphobic
   or ableist slurs.
5. Gaming and WoW slang in this language: native spellings and
   transliterations of English terms ("хил", "танкуй", "healować", "tankear",
   "mobeja"), role and class nicknames, "noob" variants, "learn to play",
   "ninja looting", "camping", "ganking", "wipe", "pull" in native verb forms,
   trade and price slang, quest and dungeon slang.
6. Emotional and social phrases: agreement, disagreement, "whatever", "no way",
   "come on", "calm down", "shut up", "good one", "my bad", "told you",
   goodbyes and greetings in slang form.
7. Slang verb forms and contractions players type ("kwil", "kheb", "t is",
   "m'n", "'k heb", "ta", "tu veux" as "tv").

## What NOT to add

- International gaming shorthand that is identical in English: gg, lol, wtf,
  afk, brb, lfg, lfm, wts, wtb, omw, np, ty, pls, inc, dps, heal, tank, pull,
  wipe, mob, boss, quest, raid, loot, roll, need, greed, inv, ress, rez, bg,
  pvp, pve. These already belong to no language.
- Plain English words with their English meaning. Detection scores words by
  dictionary membership; an English word in this dictionary makes English chat
  look like this language.
- Anything already in `Dict/<lang>.lua`.
- Lines you are not confident a native speaker would recognise.

## Patterns (optional)

Templates with `*` slots, same `|` alternative syntax, same number of `*` on
both sides, at most 25. Use them only for slang frames that wrap arbitrary
content: `doe es * = just *`, `* ofzo = * or something`, `t is * = it's *`.

## Test lines

15 realistic chat lines a player might type, slang included, each followed by
` => ` and the English you expect. These are for the maintainer to eyeball,
so make them varied: trade, dungeon, insult, banter, question, goodbye.

## When done

Reply with five lines at most: file names written, number of DICT lines,
number of PATTERNS, anything you were unsure about. No file contents.
