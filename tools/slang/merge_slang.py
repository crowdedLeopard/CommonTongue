#!/usr/bin/env python3
"""Merge the slang part files written by the language agents into the addon.

    python tools/slang/merge_slang.py [--dry-run] [lang ...]

For each tools/slang/<lang>_N.txt that has not been merged yet:
  ## DICT     lines are appended to the last L:Add block of Dict/<lang>.lua
  ## PATTERNS lines are appended to the L:Patterns block of Grammar/<lang>.lua
  ## TEST     lines are collected into tools/slang/<lang>_tests.txt
French is generated from tools/frparts, so its lines go into fr_part9.txt
(inside the Add block, before its closing line) and frg_part4.txt, and
fr_build.py is run afterwards.

Native alternatives that already exist in the target dictionary are dropped
(the first definition wins in the engine, so they would be dead weight), as
are English stopwords, neutral gaming terms and multi-word keys with digits.
Patterns whose native side already exists are dropped too. A file is only
written when the result still parses as Lua. Merged part files are recorded
in merged.json by content hash, so editing a part makes it eligible again.
"""
from __future__ import annotations

import argparse
import datetime
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # pragma: no cover
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ADDON = os.path.join(ROOT, "CommonTongue")
FRPARTS = os.path.join(ROOT, "tools", "frparts")
MANIFEST = os.path.join(HERE, "merged.json")
PART_RE = re.compile(r"^([a-z]{2})_(\d+)\.txt$")
MAX_ALTS = 12   # the engine reads any number; shorter lines stay readable

INTERNATIONAL = set("""
gg lol wtf afk brb lfg lfm wts wtb omw np ty pls plz inc dps heal tank pull wipe mob mobs
boss quest raid loot roll need greed inv ress rez bg pvp pve lf lfw wtt rofl lmao xd gl hf
gj wp ns nt ok okay kk k omg idk imo imho btw afaik ftw ffs ty tyvm thx mt ot ap dmg hp mp
cd cc aoe dot hot buff debuff nerf alt main twink farm grind ninja kite aggro tps rp
nice chill cringe sus lit flex bro yo noob nub char toon ez clap lag dc oom mats sorry done top oh
""".split())


# ---------------------------------------------------------------- files

def read(path: str) -> str:
    with open(path, encoding="utf-8-sig", newline="") as f:
        return f.read().replace("\r\n", "\n").replace("\r", "\n")


def write(path: str, text: str) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, path)


def content_hash(path: str) -> str:
    with open(path, "rb") as f:
        return hashlib.sha1(f.read()).hexdigest()


def load_manifest() -> dict:
    try:
        with open(MANIFEST, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_manifest(m: dict) -> None:
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=1, sort_keys=True)


def is_merged(path: str, done: dict) -> bool:
    """Older manifests recorded the file size; newer ones the content hash."""
    rec = done.get(os.path.basename(path))
    if rec is None:
        return False
    if isinstance(rec, int):
        return rec == os.path.getsize(path)
    return rec.get("sha1") == content_hash(path)


def mark_merged(path: str, done: dict) -> None:
    done[os.path.basename(path)] = {"sha1": content_hash(path), "size": os.path.getsize(path)}


# ---------------------------------------------------------------- keys

def norm(key: str) -> str:
    """Normalise a native key the way the engine does: lower case, hyphens
    as spaces, single spaces."""
    key = key.strip().lower()
    key = re.sub(r"(\S)-(\S)", r"\1 \2", key)
    key = re.sub(r"[ \t]+", " ", key)
    return key


def protected_words() -> set[str]:
    """Tokens inside every long string of Dict/en.lua: stopwords + neutral terms."""
    words = set(INTERNATIONAL)
    text = read(os.path.join(ADDON, "Dict", "en.lua"))
    for block in re.findall(r"\[==\[(.*?)\]==\]", text, re.S):
        for tok in block.split():
            if not tok.startswith("#"):
                words.add(tok.lower())
    return words


def left_sides(texts: list[str], opener: str) -> set[str]:
    """All normalised native alternatives defined inside the given block
    kind (L:Add or L:Patterns) of the given Lua sources."""
    keys: set[str] = set()
    pattern = re.escape(opener) + r"\(\[==\[(.*?)\]==\]"
    for text in texts:
        for block in re.findall(pattern, text, re.S):
            for raw in block.split("\n"):
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                for alt in line.split("=", 1)[0].split("|"):
                    if alt.strip():
                        keys.add(norm(alt))
    return keys


def lua_ok(text: str, label: str) -> bool:
    """Does the text parse as Lua 5.1? Without lupa the check cannot run and
    the merge refuses to write."""
    try:
        import lupa.lua51 as lupa
    except ImportError:
        try:
            import lupa  # Lua 5.4 accepts a little more than the game's 5.1
            print("  note: lupa.lua51 not available, checking with lupa's default Lua")
        except ImportError:
            print("  lupa is not installed (pip install lupa): refusing to write unchecked Lua")
            return False
    L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    res = L.eval("function(src, name) local f, err = (loadstring or load)(src, name); if f then return true end; return err end")(text, label)
    if res is True:
        return True
    print("  SYNTAX ERROR in %s: %s" % (label, res))
    return False


# ---------------------------------------------------------------- parts

def parse_parts(lang: str, done: dict) -> tuple[list[str], dict[str, list[str]]]:
    """Part files of this language that have not been merged yet, and their
    sections."""
    candidates = sorted(p for p in glob.glob(os.path.join(HERE, lang + "_*.txt"))
                        if PART_RE.match(os.path.basename(p)))
    files = [p for p in candidates if not is_merged(p, done)]
    sections: dict[str, list[str]] = {"DICT": [], "PATTERNS": [], "TEST": []}
    for p in files:
        cur = None
        for raw in read(p).split("\n"):
            line = raw.rstrip()
            m = re.match(r"^##\s*(DICT|PATTERNS|TEST)\b", line, re.I)
            if m:
                cur = m.group(1).upper()
                continue
            if cur is None or not line.strip():
                continue
            sections[cur].append(line)
    return files, sections


def clean_dict(lines: list[str], existing: set[str], protect: set[str], log: list[str]):
    """Drop alternatives that already exist, are English/neutral words or
    carry digits inside a phrase; split long lines. Returns (lines, stats)."""
    out, seen, stats = [], set(), {"in": 0, "kept": 0, "dropped_alts": 0, "dropped_lines": 0}
    for line in lines:
        s = line.strip()
        if s.startswith("#"):
            out.append(s)
            continue
        stats["in"] += 1
        if "=" not in s or "]==]" in s:
            log.append("  bad line: " + s[:90])
            stats["dropped_lines"] += 1
            continue
        left, right = s.split("=", 1)
        right = right.strip()
        if not right:
            log.append("  empty english: " + s[:90])
            stats["dropped_lines"] += 1
            continue
        kept = []
        for alt in left.split("|"):
            a = alt.strip()
            if not a:
                continue
            k = norm(a)
            why = None
            if k in existing or k in seen:
                why = "duplicate"
            elif " " in k and re.search(r"[0-9]", k):
                why = "digits in phrase"
            elif " " not in k and k in protect:
                why = "english/neutral word"
            elif "=" in a or "]==]" in a:
                why = "bad characters"
            if why:
                if why != "duplicate":
                    log.append("  dropped '%s' (%s)" % (a, why))
                stats["dropped_alts"] += 1
                continue
            seen.add(k)
            kept.append(a)
        if not kept:
            stats["dropped_lines"] += 1
            continue
        if len(kept) > MAX_ALTS:
            log.append("  >%d alternatives, split: %s" % (MAX_ALTS, s[:60]))
        for i in range(0, len(kept), MAX_ALTS):
            out.append(" | ".join(kept[i:i + MAX_ALTS]) + " = " + right)
        stats["kept"] += 1
    return out, stats


def clean_patterns(lines: list[str], existing: set[str], log: list[str]):
    """Keep one English frame per pattern, drop native sides whose slot count
    differs from it or that already exist. Returns (lines, count)."""
    out, n = [], 0
    for line in lines:
        s = line.strip()
        if s.startswith("#"):
            out.append(s)
            continue
        if "=" not in s or "]==]" in s:
            log.append("  bad pattern: " + s[:90])
            continue
        left, right = s.split("=", 1)
        # a pattern has one English frame; a second alternative on the right
        # would only confuse the slot count, so keep the first
        right = right.split("|")[0].strip()
        rc = right.count("*")
        if rc == 0:
            log.append("  pattern without slot on the right: " + s[:90])
            continue
        kept = []
        for alt in left.split("|"):
            a = alt.strip()
            if not a:
                continue
            if a.count("*") != rc:
                log.append("  slot count differs, dropped '%s'" % a)
            elif norm(a) in existing:
                pass
            else:
                kept.append(a)
                existing.add(norm(a))
        if kept:
            out.append(" | ".join(kept) + " = " + right)
            n += 1
    return out, n


def insert_before_last_close(text: str, opener: str | None, block: str) -> str | None:
    """Insert block before the ']==]' that closes the LAST `opener` block
    (or the last ']==]' of the text when opener is None)."""
    if opener:
        starts = [m.end() for m in re.finditer(re.escape(opener), text)]
        if not starts:
            return None
        idx = text.find("]==]", starts[-1])
    else:
        idx = text.rfind("]==]")
    if idx < 0:
        return None
    head = text[:idx].rstrip("\n") + "\n"
    return head + block + text[idx:]


# ---------------------------------------------------------------- merge

def fr_sources(prefix: str) -> list[str]:
    paths = sorted(glob.glob(os.path.join(FRPARTS, prefix + "*.txt")),
                   key=lambda p: int(re.search(r"(\d+)\.txt$", p).group(1)))
    return [read(p) for p in paths]


def merge(lang: str, dry: bool, done: dict) -> bool | None:
    """Merge every unmerged part file of one language. Returns None when
    there was nothing to do, else whether everything succeeded."""
    files, sec = parse_parts(lang, done)
    if not files:
        return None
    log: list[str] = []
    names = ", ".join(os.path.basename(f) for f in files)
    print("== %s: %s" % (lang, names))
    is_fr = lang == "fr"
    if is_fr:
        dict_target = os.path.join(FRPARTS, "fr_part9.txt")
        gram_target = os.path.join(FRPARTS, "frg_part4.txt")
        # the Add block spans parts 1..9 and the Patterns block the frg parts,
        # so join them before looking for existing keys
        existing = left_sides(["".join(fr_sources("fr_part"))], "L:Add")
        existing_pat = left_sides(["".join(fr_sources("frg_part"))], "L:Patterns")
    else:
        dict_target = os.path.join(ADDON, "Dict", lang + ".lua")
        gram_target = os.path.join(ADDON, "Grammar", lang + ".lua")
        existing = left_sides([read(dict_target)], "L:Add")
        existing_pat = left_sides([read(gram_target)], "L:Patterns") if os.path.exists(gram_target) else set()
    protect = protected_words()

    dict_lines, st = clean_dict(sec["DICT"], existing, protect, log)
    pat_lines, npat = clean_patterns(sec["PATTERNS"], existing_pat, log)
    print("  DICT: %d in, %d kept, %d alternatives dropped, %d lines dropped;  PATTERNS: %d kept of %d;  TEST: %d"
          % (st["in"], st["kept"], st["dropped_alts"], st["dropped_lines"], npat,
             len([l for l in sec["PATTERNS"] if not l.strip().startswith("#")]), len(sec["TEST"])))
    for l in log[:40]:
        print(l)
    if len(log) > 40:
        print("  ... %d more notes" % (len(log) - 40))

    tests = [l.strip() for l in sec["TEST"] if "=>" in l]
    if tests and not dry:
        tpath = os.path.join(HERE, lang + "_tests.txt")
        old = set(read(tpath).splitlines()) if os.path.exists(tpath) else set()
        new_tests = [t for t in tests if t not in old]
        if new_tests:
            with open(tpath, "a", encoding="utf-8", newline="\n") as f:
                f.write("".join(t + "\n" for t in new_tests))

    ok = True
    header = "# ---- slang pass (%s): %s ----\n" % (datetime.date.today().isoformat(), names)
    if any(not l.startswith("#") for l in dict_lines):
        block = header + "\n".join(dict_lines) + "\n"
        text = read(dict_target)
        new = insert_before_last_close(text, None if is_fr else "L:Add([==[", block)
        if new is None:
            print("  dict: could not find the Add block")
            ok = False
        elif is_fr or lua_ok(new, os.path.basename(dict_target)):
            if not dry:
                write(dict_target, new)
            print("  dict: %d lines %s %s" % (len(dict_lines), "would go into" if dry else "written to", os.path.relpath(dict_target, ROOT)))
        else:
            ok = False
    if ok and any(not l.startswith("#") for l in pat_lines):
        block = header + "\n".join(pat_lines) + "\n"
        text = read(gram_target)
        new = insert_before_last_close(text, None if is_fr else "L:Patterns([==[", block)
        if new is None:
            print("  grammar: could not find the Patterns block")
            ok = False
        elif is_fr or lua_ok(new, os.path.basename(gram_target)):
            if not dry:
                write(gram_target, new)
            print("  grammar: %d lines %s %s" % (npat, "would go into" if dry else "written to", os.path.relpath(gram_target, ROOT)))
        else:
            ok = False
    if is_fr and not dry and ok:
        r = subprocess.run([sys.executable, "-I", os.path.join(FRPARTS, "fr_build.py"), "all"],
                           capture_output=True, text=True, encoding="utf-8")
        tail = [l for l in r.stdout.splitlines() if "written" in l or "ERROR" in l or "NOT written" in l]
        print("  fr_build: " + "; ".join(tail))
        if r.returncode != 0:
            print(r.stderr.strip())
        ok = r.returncode == 0
    if ok and not dry:
        for p in files:
            mark_merged(p, done)
        save_manifest(done)
    return ok


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Merge slang part files into the addon's dictionaries")
    ap.add_argument("langs", nargs="*", help="language codes to merge (default: every language with unmerged parts)")
    ap.add_argument("--dry-run", action="store_true", help="show what would change without writing")
    args = ap.parse_args(argv)
    langs = args.langs or sorted({PART_RE.match(os.path.basename(p)).group(1)
                                  for p in glob.glob(os.path.join(HERE, "*.txt"))
                                  if PART_RE.match(os.path.basename(p))})
    allok = True
    done = load_manifest()
    for lang in langs:
        r = merge(lang, args.dry_run, done)
        if r is None:
            print("== %s: nothing new to merge" % lang)
        elif not r:
            allok = False
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
