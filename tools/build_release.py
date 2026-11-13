#!/usr/bin/env python3
r"""
Build the release archives for CommonTongue and check them the way CurseForge
and the game will.

    python tools/build_release.py

writes into dist/ next to the addon folder:

    CommonTongue-<version>.zip        the CurseForge upload: ONE root folder
                                      "CommonTongue" with the addon in it
    CommonTongue-<version>-full.zip   the hand-out package: addon + companion +
                                      install.py + README + Start Companion.bat

Checks made before anything is written:
  - the TOC has ## Interface and ## Version, and every file it lists exists
  - no stray files in the addon folder (only .lua and .toc)
  - Learned.lua is the empty stub (a personal translation memory must never ship)
  - every Lua file parses (when the "lupa" package is installed)
and after writing:
  - the archive has exactly one root folder, named like the TOC, forward slashes only
The version in the file names comes from ## Version in the TOC.
"""
import io
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_NAME = "CommonTongue"
ADDON = os.path.join(ROOT, ADDON_NAME)
DIST = os.path.join(ROOT, "dist")
SKIP_DIRS = {"__pycache__", ".git", ".vs", ".idea"}
SKIP_FILES = {"Thumbs.db", "desktop.ini", ".DS_Store"}
SKIP_EXT = {".pyc", ".bak", ".orig", ".tmp", ".swp"}
LEARNED_STUB_LAST_LINE = "if not CommonTongue or not CommonTongue.Learn then return end"

problems = []


def fail(msg):
    problems.append(msg)
    print("  FAIL  " + msg)


def ok(msg):
    print("  ok    " + msg)


def read_toc():
    toc = os.path.join(ADDON, ADDON_NAME + ".toc")
    if not os.path.isfile(toc):
        fail("missing " + toc)
        return {}, []
    meta, files = {}, []
    with io.open(toc, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("##"):
                if ":" in line:
                    k, v = line[2:].split(":", 1)
                    meta[k.strip()] = v.strip()
            elif not line.startswith("#"):
                files.append(line.replace("\\", "/"))
    return meta, files


def wanted(name):
    return name not in SKIP_FILES and os.path.splitext(name)[1].lower() not in SKIP_EXT


def walk(folder):
    for dirpath, dirnames, filenames in os.walk(folder):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for name in sorted(filenames):
            if wanted(name):
                full = os.path.join(dirpath, name)
                yield full, os.path.relpath(full, folder).replace(os.sep, "/")


def check_addon(meta, files):
    print("checking %s" % ADDON)
    for key in ("Interface", "Version", "Title"):
        if meta.get(key):
            ok("## %s: %s" % (key, meta[key]))
        else:
            fail("TOC has no ## %s" % key)
    missing = [f for f in files if not os.path.isfile(os.path.join(ADDON, f))]
    if missing:
        fail("TOC lists files that do not exist: " + ", ".join(missing))
    else:
        ok("all %d files listed in the TOC exist" % len(files))
    present = {rel for _, rel in walk(ADDON)}
    listed = set(files) | {ADDON_NAME + ".toc"}
    icon = meta.get("IconTexture", "")
    if icon:
        # "Interface\AddOns\CommonTongue\icon.tga" -> "icon.tga"
        icon_rel = icon.replace("\\", "/").split(ADDON_NAME + "/", 1)[-1]
        listed.add(icon_rel)
        if not os.path.isfile(os.path.join(ADDON, icon_rel)):
            fail("## IconTexture names a file that does not exist: " + icon)
    stray = sorted(p for p in present if p not in listed)
    if stray:
        fail("files in the addon folder that the TOC does not load: " + ", ".join(stray))
    else:
        ok("no stray files")
    bad_ext = sorted(p for p in present if os.path.splitext(p)[1].lower() not in (".lua", ".toc", ".tga", ".blp"))
    if bad_ext:
        fail("unexpected file types: " + ", ".join(bad_ext))
    learned = os.path.join(ADDON, "Learned.lua")
    if os.path.isfile(learned):
        with io.open(learned, encoding="utf-8") as f:
            body = [l.strip() for l in f if l.strip()]
        code = [l for l in body if not l.startswith("--")]
        if code == [LEARNED_STUB_LAST_LINE]:
            ok("Learned.lua is the empty stub")
        else:
            fail("Learned.lua is not the empty stub: it holds a translation memory. Restore the stub before building.")
    try:
        try:
            import lupa.lua51 as lupa
        except ImportError:
            import lupa
        rt = lupa.LuaRuntime()
        n = 0
        for full, rel in walk(ADDON):
            if rel.endswith(".lua"):
                with io.open(full, encoding="utf-8") as f:
                    rt.compile(f.read())
                n += 1
        ok("all %d Lua files parse" % n)
    except ImportError:
        print("  note  'lupa' is not installed: Lua syntax was not checked (pip install lupa)")
    except Exception as e:  # lupa.LuaSyntaxError or any other
        fail("Lua syntax error: %s" % e)


def write_zip(path, entries):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for full, arc in entries:
            zf.write(full, arc)
    return os.path.getsize(path)


def check_zip(path, root_name):
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        bad = zf.testzip()
    if bad:
        fail("%s: corrupt entry %s" % (os.path.basename(path), bad))
    if any("\\" in n for n in names):
        fail("%s: backslashes in entry names" % os.path.basename(path))
    roots = {n.split("/", 1)[0] for n in names}
    if roots != {root_name}:
        fail("%s: root folders are %s, expected only %s" % (os.path.basename(path), sorted(roots), root_name))
    else:
        ok("%s: one root folder '%s', %d files" % (os.path.basename(path), root_name, len(names)))
    return names


def main():
    meta, files = read_toc()
    check_addon(meta, files)
    if problems:
        print("\nNOT built: %d problem(s)" % len(problems))
        return 1
    version = meta["Version"]
    os.makedirs(DIST, exist_ok=True)

    # 1. CurseForge upload: the addon folder only, one root folder
    cf = os.path.join(DIST, "%s-%s.zip" % (ADDON_NAME, version))
    entries = [(full, ADDON_NAME + "/" + rel) for full, rel in walk(ADDON)]
    size = write_zip(cf, entries)
    names = check_zip(cf, ADDON_NAME)
    if ADDON_NAME + "/" + ADDON_NAME + ".toc" not in names:
        fail("TOC missing from the archive")

    # 2. full package: addon + companion + installer + docs, under one folder
    top = "%s-%s" % (ADDON_NAME, version)
    full_zip = os.path.join(DIST, top + "-full.zip")
    entries = [(full, "%s/%s/%s" % (top, ADDON_NAME, rel)) for full, rel in walk(ADDON)]
    companion = os.path.join(ROOT, "Companion")
    if os.path.isdir(companion):
        # only source and docs: never a local memory.json, log or key file
        entries += [(full, "%s/Companion/%s" % (top, rel)) for full, rel in walk(companion)
                    if os.path.splitext(rel)[1].lower() in (".py", ".md", ".txt", ".bat")]
    for name in ("install.py", "README.md", "Start Companion.bat"):
        p = os.path.join(ROOT, name)
        if os.path.isfile(p):
            entries.append((p, "%s/%s" % (top, name)))
    size_full = write_zip(full_zip, entries)
    check_zip(full_zip, top)

    print("\nwritten:")
    print("  %s  (%.1f MB)  <- upload this to CurseForge" % (cf, size / 1e6))
    print("  %s  (%.1f MB)  <- hand-out package with companion and installer" % (full_zip, size_full / 1e6))
    if problems:
        print("\n%d problem(s), see FAIL lines above" % len(problems))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
