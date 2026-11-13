# CommonTongue architecture

CommonTongue translates World of Warcraft chat inside the game client. The
client's Lua sandbox has no network access, no file access and no regular
expressions, so the addon carries its own dictionaries and grammar and does
all the work itself. An optional companion program adds real machine
translation through the only channels an addon has: the chat log the client
writes, and addon files the client reads when it loads them.

## Data flow

```
chat event ──► Core.lua chat filter
                 │  secret values, channel settings, own messages
                 ▼
               B:Process ── cache ── Memory:Lookup (sentences seen before)
                 │
                 ▼
               Detect.lua  B:DetectLanguage  ──► language, confidence,
                 │                                English rendering, stats
                 ▼
               Engine.lua  B:TranslateText   (reuses the rendering)
                 │
                 ├─ built-in result: line decorated at once  (blue)
                 └─ live bridge on: line shown as is, Bridge:Request
                                      │  slot addon loaded a second later
                                      ▼
                                    B:ShowLate edits the line in place (green)
```

Everything pivots through English: a Spanish line is rendered in English and,
if the player reads German, that English is rendered in German by the German
dictionary's reverse direction.

## Files

| File | Responsibility |
|---|---|
| `UTF8.lua` | Code points, case, scripts, chat markup segmentation. Creates the global `CommonTongue` table. |
| `Text.lua` | Accent folding, emphasis squeezing, plain text, loose keys, the atomiser. |
| `English.lua` | English verb inflection, noun and adjective sets, post-editing. |
| `Engine.lua` | Language registration, dictionary parsing, templates, phrases, word lookup, reordering, `TranslateText`. |
| `Detect.lua` | Language detection by script and by explanation. |
| `Dict/<code>.lua` | One file per language: stopwords, hints, suffixes, then `L:Add` and `L:Reverse` blocks. `Dict/en.lua` holds English stopwords and the neutral word list. |
| `Grammar/<code>.lua` | Clitics, verbs, conjugation rules, sentence templates. |
| `Memory.lua` | Translation memory, taught entries, missing-word counts. |
| `Learned.lua` | Written by the companion; a stub in the shipped addon. |
| `Bridge.lua` | The live bridge: slot addons, pending requests, chat-log flushing. |
| `Core.lua` | Settings, chat filter, outgoing translation, slash commands, startup. |
| `Options.lua` | The options panel. |

Load order is the TOC order above; each file takes what it needs from the
`CommonTongue` table, which is the addon's only global besides its saved
variables and slash-command names (the test harness fails on any other).

## The engine

A line is first cut into **atoms** by `Text.Atomize`: words, numbers, mixed
tokens like `5g`, punctuation, clause breaks, and protected markup (links,
colours, textures, raid icons) that is copied through untouched. Each word
atom carries its normalised form, its accent-folded form and whether it was
capitalised.

Each clause is translated by `translateSpan`, a cascade:

1. **Sentence templates** (`Lang:Patterns`): `busco grupo para *` becomes
   `looking for group for *`; the slot is translated recursively by the same
   cascade. The most specific template wins (most literal words), a template
   loses to a dictionary phrase longer than its opening literals, and it may
   not cut through a phrase that started before it. Up to four levels deep.
2. **Phrases**: the longest dictionary key starting at the current word, up
   to the language's longest key.
3. **Clitics**: an object pronoun before a verb (`lo maté` = `I killed it`).
4. **Words** (`lookupWord`): exact, accent-folded, with an ending stripped
   (plurals kept in English), elided (`l'entrée`), as a conjugated form of a
   listed verb (rendered from the English base by `English.lua`), and finally
   with repeated letters squeezed (`holaaaa`). Neutral shorthand with no entry
   of its own is left alone, so `grats` is never a Danish plural.
5. **Reordering**: noun + adjective becomes adjective + noun for languages
   that put adjectives after the noun; `potions of mana` becomes `mana potions`.

The English result goes through `EN.PostEdit`, a set of conservative fixes
for patterns that are wrong in every reading (`can to help`, `there is mobs`,
`a elite`). A statistics record counts hits, misses and template or phrase
words; **coverage** is hits over hits plus misses and decides whether a
translation is shown at all.

Languages written without spaces (Chinese, Japanese) are translated greedily
by the longest dictionary key at each position, with their own templates
compiled to Lua patterns.

## Detection

Scripts decide first: Hangul is Korean, kana Japanese, Han without kana
Chinese, Cyrillic Russian unless a Ukrainian-only letter occurs.

For Latin scripts every language collects cheap evidence: stopwords,
dictionary hits, characteristic letters (`ñ`, `ção`, `ij`), a possible verb
form on short lines, and a bonus when the speaker used that language before.
The top four candidates each **explain** the line by translating it; phrase
and template matches weigh most. English competes with its own stopwords and
with the lexicon of every English word the dictionaries produce, so English
lines are left alone, and words that belong to every language (`lfg`, `tank`,
`lol`) count for none.

The winner's score must beat a floor and one and a half times the English
score; the confidence is its lead over the runner-up. Core then applies two
more guards: a line with little evidence and many unknown words is not shown
(`shaky`), and the player's minimum coverage (34% by default) must be met.
Lines whose loose key is shorter than two characters (`o/`, `:D`, a lone
letter) are never translated.

## Dictionary format

```
native | native alt | ... = english | english alt | ...
```

Every native form on a line maps to the **first** English form, so a line
holds one meaning; further English forms only add reverse entries. The first
definition of a key wins, so corrections go into the existing line, not a new
one. `~` as the English side drops the word. Lines starting with `#` are
comments. The same format serves phrases (keys with spaces), which are looked
up before single words.

French is generated: edit `tools/frparts/fr_part*.txt` and run
`tools/frparts/fr_build.py all`. The Add block spans parts 1 to 9 and closes
at the end of part 9; new entries go before that closing line. Slang
contributions for any language go through `tools/slang/merge_slang.py`,
which appends to the right block, drops duplicates and verifies the Lua.

## The live bridge

The companion (`Companion/commontongue_companion.py`) tails
`Logs\WoWChatLog.txt`, translates each new foreign line through the chosen
service, and writes the results into a ring of load-on-demand slot addons
(`CommonTongue_Slot_000` ...), one file per wall-clock second modulo the ring
size. When the addon needs a translation it loads the slot for the current
second; the slot's `data.lua` calls `Bridge:Receive` and the chat line is
edited in place. A slot can be loaded once per session, so slots are a budget
that `/reload` refills. The companion also writes every translation into
`Learned.lua`, the translation memory, which the addon loads at login.

The client buffers its chat log and writes it only when logging is toggled;
the bridge toggles it on each request (`Bridge:Flush`). The addon sends the
player's own `/tsay` requests to the companion as a whisper to the player's
own character, hidden by the chat filter; the companion accepts such requests
only from the outgoing copy of that whisper.

## Saved variables

`CommonTongueDB` holds the settings listed in `Core.lua`'s `DEFAULTS`, plus
`taught` (player entries, re-applied at login), `missing` (unknown words per
language, capped at 400 each, fed back into the dictionaries by the
maintainers) and `flush` (set once a companion has been seen).

## Performance

Measured with `tools/tests/ct_perf.py` on 3.2 MB of dictionaries, about
151,000 keys over 17 languages: 0.73 s to load at login (inside the loading
screen), 36 MB of Lua memory, 0.8 ms per new chat line. Nothing runs per
frame; the only timers belong to the live bridge and fire while a line waits.

## Testing

`tools/tests/` loads the real addon into a Lua 5.1 runtime (via the `lupa`
package) with a stub of the client API (`wowstub.lua`):

| Script | Checks |
|---|---|
| `ct_unit.py` | pass/fail assertions for every module |
| `run_tests.py` | loads, detects, translates, slash commands, leaked globals, timing |
| `ct_check_all.py` | regression lines in every language, must report `misdetected: 0` |
| `ct_bridge_test.py` | the live bridge end to end with a fake companion |
| `ct_parity.py` | the addon and the companion compute the same loose keys |
| `ct_replay_log.py` | replays the client's real chat log with Core's exact decision |
| `ct_missing_check.py` | which words saved as missing in-game are still unknown |
| `ct_perf.py` | load time, memory, time per message |

## Privacy

With the addon alone nothing leaves the player's computer. The companion
sends chat lines that are not in the player's language to the chosen
translation service, and only those; `missing` word lists hold single words
without names. The addon never reads game memory, injects input or looks at
the screen, and respects the client's secret-value protection, so chat in
instances is neither read nor translated.
