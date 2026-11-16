# Contributing to CommonTongue

The most valuable contribution is a bad translation with the original line:
post both, say what it should have said, and it goes into the next release.
This file is for people who want to change the code or the dictionaries.

## Set-up

- The addon folder is `CommonTongue/`; the game loads it from
  `World of Warcraft\_forever_\Interface\AddOns\CommonTongue`.
  `python install.py` copies it there (and creates the live-translation slots).
- Tests need Python 3.10+ and the `lupa` package (`pip install lupa`), which
  embeds Lua 5.1, the version the game runs. Nothing else is required.
- `docs/ARCHITECTURE.md` explains how the pieces fit; read it first.

## Before every change

```
python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_unit.py     # unit tests, must end "0 failed"
python tools/tests/run_tests.py CommonTongue                          # load, globals check, timing
python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_check_all.py # must print "misdetected: 0"
python tools/tests/ct_bridge_test.py .                                # must print "ALL PASSED"
```

`tools/README.md` lists the rest, including the replay of a real chat log,
which is the best way to see what a dictionary change does to real lines.

## Changing a dictionary

The format and the rules are in `docs/ARCHITECTURE.md` ("Dictionary format").
The three that bite:

1. **One meaning per line.** Every native alternative on a line maps to the
   first English alternative. `je bois = I drink` and `je bois pas = I don't
   drink` are two lines.
2. **The first definition wins.** To correct a word, change the line that
   already defines it (`grep -n "| word |" CommonTongue/Dict/xx.lua` finds it,
   remembering that the key may be the first or last alternative); a new line
   at the end is ignored.
3. **French is generated.** Edit `tools/frparts/fr_part*.txt`, keep new
   entries before the `]==])` that closes part 9, and run
   `python tools/frparts/fr_build.py all`.

Larger batches go through `tools/slang/merge_slang.py`: write a
`tools/slang/<lang>_N.txt` with `## DICT`, `## PATTERNS` and `## TEST`
sections (see `tools/slang/BRIEF.md`) and run the merger, which drops
duplicates, checks the Lua and records what it merged.

Sentence templates (`## PATTERNS`, or the `L:Patterns` block of
`Grammar/<lang>.lua`) have one English frame on the right and the same number
of `*` slots on both sides.

## Adding a language

1. `CommonTongue/Dict/<code>.lua`: `B:RegisterLanguage(code, name, opts)` with
   stopwords, hints (letters that mark the language), suffixes the lookup may
   strip, and `adjAfterNoun` where adjectives follow the noun; then the
   `L:Add` and `L:Reverse` blocks.
2. `CommonTongue/Grammar/<code>.lua`: clitics, verbs, conjugation rules,
   templates and the respelling rules the fuzzy layer tries on unknown words
   (`L:Respell`). `tools/tests/ct_GRAMMAR_GUIDE.md` documents each block.
3. Add both files to `CommonTongue.toc` (dictionaries before grammars), add
   regression lines to `tools/tests/ct_check_all.py`, and run the suite.

## Code

- Lua: two-space indentation, every file starts with a header that states
  its purpose and public API, every public function has a `---` doc comment
  with its parameters and return values, locals everywhere (the harness fails
  on a leaked global), and `pcall` around anything the client may reject.
  `.luacheckrc` is provided for `luacheck CommonTongue`.
- Python: type hints and docstrings on public functions, `argparse` for
  command lines, no network calls in tools.
- Keep the companion file-based: it reads the chat log and writes addon
  files, nothing else. No memory reading, input injection or screen capture.

## Releasing

`tools/RELEASE.md`: bump `## Version` in the TOC, run the suite, build with
`tools/build_release.py`, upload the CurseForge zip, attach the full zip to
the GitHub release, update `CHANGELOG.md`.
