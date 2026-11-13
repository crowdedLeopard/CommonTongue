# Developer tools

These are not part of the addon. Players only need the `CommonTongue/` folder
(or `release/`). This folder keeps the sources and checks used while building it.

## frparts/ - the French dictionary and grammar sources

`CommonTongue/Dict/fr.lua` and `CommonTongue/Grammar/fr.lua` are generated.
Edit the part files here, not the generated files:

- `fr_part1.txt` .. `fr_part9.txt` are the entries inside the `L:Add` block;
  `fr_part10.txt` is the `L:Reverse` block and must stay last.
- `frg_part1.txt` .. `frg_part4.txt` are the clitics, verbs, conjugation rules
  and sentence templates.

Rebuild with:

    python tools/frparts/fr_build.py all

It prints entry counts, duplicate keys and lines with more than eight
alternatives, checks the Lua syntax and writes the files only when they parse.
Other languages are hand-edited directly in `CommonTongue/Dict` and
`CommonTongue/Grammar`; `tests/ct_GRAMMAR_GUIDE.md` explains the format.

## slang/ - the slang pass

`BRIEF.md` is the instruction sheet one agent per language followed to write
`<lang>_1.txt` (and `_2.txt`): a `## DICT` section in dictionary format, an
optional `## PATTERNS` section and `## TEST` lines. `merge_slang.py` appends
the dictionary lines to the last `L:Add` block of `CommonTongue/Dict/<lang>.lua`
and the patterns to the `L:Patterns` block of the grammar file (for French it
edits the part files and rebuilds), dropping keys that already exist, English
stopwords, neutral gaming terms and digit-bearing phrases, and writes only when
the Lua still parses. Then:

    python tools/slang/merge_slang.py --dry-run        # see what would change
    python tools/slang/merge_slang.py                  # merge every language
    python tools/tests/ct_dbg.py CommonTongue tools/slang/slang_check.py nl   # eyeball one language's TEST lines

## tests/ - the Lua 5.1 harness

The scripts load the real addon in a Lua 5.1 runtime with a small WoW API stub
(`wowstub.lua`). They need Python with the `lupa` package (`pip install lupa`).

    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_unit.py        # unit tests: must end "0 failed"
    python tools/tests/run_tests.py CommonTongue                         # load, detect, translate, slash commands, leaked globals
    python tools/tests/run_tests.py CommonTongue "texte à tester"        # translate given lines
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_check_all.py   # regression lines in every language
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_parity.py .    # addon and companion compute the same keys
    python tools/tests/ct_bridge_test.py .                               # end-to-end live bridge (add --google to call the real endpoint)

Expected: no "FAIL" lines, "0 misdetected" and "0 mismatches".

    python tools/tests/ct_perf.py CommonTongue                           # load time, Lua memory, ms per message

Two checks use what really happened in the game:

    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_replay_log.py [chatlog] [since]   # replay the client's WoWChatLog.txt: what the addon showed, hid, missed
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_missing_check.py [SavedVariables]  # words saved as "missing" in-game that are still unknown

The chat log is only written when the client flushes it (reload, logout, exit), so
replay after a session, not during one.

## Releasing

`RELEASE.md` has the CurseForge steps. `build_release.py` builds and checks the
two archives in `dist/` (the CurseForge upload with the addon folder only, and
the full package with companion and installer).

Measured on 2026-11-13 after the slang pass, with 3.1 MB of dictionaries
(about 151,000 keys over 17 languages): 0.9 s to load, 36 MB of Lua memory,
about 1 ms per new chat line. Nothing runs per frame.
