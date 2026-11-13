# Concatenate part files into the final .lua files (UTF-8, no BOM, LF) and
# check them before they replace the addon's copy.
#   python fr_build.py dict      -> Dict/fr.lua  from fr_part*.txt
#   python fr_build.py grammar   -> Grammar/fr.lua from frg_part*.txt
#   python fr_build.py all
import glob, io, os, re, sys
sys.stdout.reconfigure(encoding="utf-8")

HERE = os.path.dirname(os.path.abspath(__file__))
# The addon folder lives two levels up: <project>/tools/frparts -> <project>/CommonTongue
ADDON = os.path.normpath(os.path.join(HERE, "..", "..", "CommonTongue"))


def parts(prefix):
    files = glob.glob(os.path.join(HERE, prefix + "*.txt"))
    files.sort(key=lambda p: int(re.search(r"(\d+)\.txt$", p).group(1)))
    return files


def read(path):
    with io.open(path, encoding="utf-8-sig", newline="") as f:
        return f.read().replace("\r\n", "\n").replace("\r", "\n")


def lua_ok(text, label):
    try:
        import lupa.lua51 as lupa
    except Exception as e:  # pragma: no cover
        print("  (lupa not available, syntax not checked: %s)" % e)
        return True
    L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
    res = L.eval("function(src, name) local f, err = loadstring(src, name); if f then return true end; return err end")(text, label)
    if res is True:
        return True
    print("  SYNTAX ERROR in %s: %s" % (label, res))
    return False


def stats(text, label):
    entries, keys, dup = 0, 0, {}
    longest = 0
    seen = {}
    block = None
    counts = {}
    for raw in text.split("\n"):
        line = raw.strip()
        m = re.match(r"L:(\w+)\(\[==\[", line)
        if m:
            block = m.group(1)
            counts.setdefault(block, [0, 0])
            continue
        if line.startswith("]==]"):
            block = None
            continue
        if not block or not line or line.startswith("#") or "=" not in line:
            continue
        left = line.split("=", 1)[0]
        alts = [a.strip() for a in left.split("|") if a.strip()]
        counts[block][0] += 1
        counts[block][1] += len(alts)
        if len(line) > longest:
            longest = len(line)
        if block == "Add":
            if len(alts) > 8:
                print("  >8 alternatives: %s" % line[:90])
            for a in alts:
                k = re.sub(r"(\S)-(\S)", r"\1 \2", a.lower())
                if k in seen and seen[k] != line:
                    dup[k] = (seen[k], line)
                seen.setdefault(k, line)
    for b, (n, k) in counts.items():
        print("  %-12s %5d lines %6d keys" % (b, n, k))
    print("  longest line: %d chars" % longest)
    if dup:
        print("  duplicate keys (first one wins): %d" % len(dup))
        for k, (a, b) in sorted(dup.items()):
            print("    [%s]\n       1: %s\n       2: %s" % (k, a[:100], b[:100]))


def build(prefix, rel):
    files = parts(prefix)
    if not files:
        print("no parts for", prefix)
        return False
    for p in files:
        n = read(p).count("\n")
        if n > 250:
            print("  WARNING %s has %d lines" % (os.path.basename(p), n))
    text = "".join(read(p) if read(p).endswith("\n") else read(p) + "\n" for p in files)
    print("%s: %d parts, %d lines, %d bytes" % (rel, len(files), text.count("\n"), len(text.encode("utf-8"))))
    stats(text, rel)
    if not lua_ok(text, rel):
        print("  NOT written")
        return False
    out = os.path.join(ADDON, rel)
    tmp = out + ".tmp"
    with io.open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, out)
    print("  written:", out)
    return True


what = sys.argv[1] if len(sys.argv) > 1 else "all"
ok = True
if what in ("dict", "all"):
    ok = build("fr_part", os.path.join("Dict", "fr.lua")) and ok
if what in ("grammar", "all"):
    ok = build("frg_part", os.path.join("Grammar", "fr.lua")) and ok
sys.exit(0 if ok else 1)
