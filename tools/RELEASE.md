# Publishing CommonTongue

Players get the addon from CurseForge (or WowUp, which reads CurseForge). The
live-translation companion is a Python program and cannot go on CurseForge, so
it ships as a separate download with the installer.

## 1. Build the archives

    python tools/build_release.py

writes two files into `dist/`:

| File | What | Where it goes |
|---|---|---|
| `CommonTongue-<version>.zip` | the `CommonTongue` addon folder, nothing else | upload to CurseForge |
| `CommonTongue-<version>-full.zip` | addon + `Companion/` + `install.py` + README + `Start Companion.bat` | GitHub release, Discord, your own site: for players who want the live bridge |

The version in the names comes from `## Version:` in `CommonTongue/CommonTongue.toc`.
For a new release bump that line first (and `## Interface:` if the client's
interface number changed), then build.

The script refuses to build when the TOC lists a missing file, when there are
stray files in the addon folder, when a Lua file does not parse, or when
`Learned.lua` is not the empty stub (your own translation memory must never be
shipped: it contains other players' chat).

## 2. Test before uploading

Offline, from the project root (needs Python with `lupa`, see `tools/README.md`):

    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_unit.py             # "0 failed"
    python tools/tests/run_tests.py CommonTongue                                 # "globals: clean"
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_check_all.py        # "misdetected: 0"
    python tools/tests/ct_bridge_test.py .                                       # "ALL PASSED"
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_parity.py .         # "0 mismatches"
    python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_replay_log.py       # replays your real chat log: read the translations

Then test the archive itself, not the source: unzip `dist/CommonTongue-<version>.zip`
into a scratch folder and run `run_tests.py` on the extracted `CommonTongue` folder.

In the game: `/reload`, then `/tongue status` (shows the version), `/tongue test`,
and type a foreign sentence in /say to see the inline translation.

## 3. First upload to CurseForge

1. Sign in at https://authors.curseforge.com with the account you use in the
   CurseForge app.
2. **Create a project**: game *World of Warcraft*, type *Addon*. Name
   `CommonTongue`. Category *Chat & Communication*. Summary and description:
   paste them from `tools/LISTING.md`. Pick a license. Logo: `dist/CommonTongue-logo.png`
   (regenerate with `python tools/make_logo.py`). Screenshots of a translated
   chat line help a lot.
3. **Upload the file**: *Files → Upload*, choose `dist/CommonTongue-<version>.zip`.
   Display name `CommonTongue <version>`. Release type *Release* (or *Beta* if
   you want a soft start). Game version: the **Forever** flavour, version
   **1.60.1**: do not tick Retail or Classic versions, the addon is built for
   the Forever client (`## Interface: 16001`). Paste the changelog.
4. The first file of a new project is reviewed by a CurseForge moderator before
   the project becomes visible. This usually takes hours, sometimes a day or two.
   Fix anything they flag and re-upload.
5. Once approved, copy the project URL into the TOC for the next release:
   `## X-Website: https://www.curseforge.com/wow/addons/commontongue` (and
   optionally `## X-Curse-Project-ID: <id>` from the project's settings page).

## 4. Every later release

1. Bump `## Version:` in the TOC, run the tests, `python tools/build_release.py`.
2. *Files → Upload* the new `CommonTongue-<version>.zip`, same game version,
   with a changelog. Players on the CurseForge app or WowUp get it automatically.
3. Attach the new `-full.zip` to the GitHub release (or wherever the full
   package lives) and keep the link in the CurseForge description current.

## 5. Things to know about the CurseForge app

- It installs by replacing the whole `CommonTongue` folder. A `Learned.lua`
  written by the companion is lost on every update, and the companion writes it
  again the next time it runs (the memory itself lives in
  `%APPDATA%\CommonTongue\memory.json`).
- The slot addons (`CommonTongue_Slot_NNN`) are separate folders the installer
  creates; the app never touches them.
- The zip must contain exactly one root folder whose name matches the TOC file
  (`CommonTongue/CommonTongue.toc`). The build script checks this; do not
  re-zip the folder by hand from Explorer, which happily adds a second level or
  stray `Thumbs.db` files.
