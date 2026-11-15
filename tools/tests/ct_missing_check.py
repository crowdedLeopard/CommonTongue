# Check the "missing" word lists the addon saved in-game against the current
# dictionaries: which of the words players actually used are still unknown?
#
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_missing_check.py [SavedVariables\CommonTongue.lua]
import glob, io, os, sys
sys.stdout.reconfigure(encoding="utf-8")

WTF_ACCOUNTS = r"C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account"


def default_saved_variables():
    """The newest CommonTongue.lua under any account folder of the Forever client, or None."""
    found = glob.glob(os.path.join(WTF_ACCOUNTS, "*", "SavedVariables", "CommonTongue.lua"))
    return max(found, key=os.path.getmtime) if found else None


path = sys.argv[3] if len(sys.argv) > 3 else default_saved_variables()
if not path or not os.path.isfile(path):
    sys.exit("no SavedVariables file found: pass the path to WTF\\Account\\<account>\\SavedVariables\\CommonTongue.lua")

L.execute(io.open(path, encoding="utf-8").read())
db = G.CommonTongueDB
missing = db and db.missing
if not missing:
    print("no missing lists in", path)
    sys.exit(0)


def words_of(tbl):
    out = []
    for k, v in tbl.items():
        if isinstance(k, int):
            out.append(str(v))
        else:
            out.append(str(k))
    return out


total_known = total_unknown = 0
for lang, tbl in sorted(missing.items()):
    words = sorted(set(words_of(tbl)))
    known, unknown = [], []
    for w in words:
        r = B.TranslateText(B, w, lang, "en", None, None)
        r = r if isinstance(r, tuple) else (r,)
        out, cov = r[0], float(r[1] or 0) if len(r) > 1 else 0.0
        if out and cov > 0 and out.strip().lower() != w.lower():
            known.append("%s=%s" % (w, out.strip()))
        else:
            unknown.append(w)
    total_known += len(known)
    total_unknown += len(unknown)
    print("%s: %d words saved in-game, now known: %d, still unknown: %d" % (lang, len(words), len(known), len(unknown)))
    if known:
        print("   known now: " + ", ".join(known[:60]))
    if unknown:
        print("   still unknown: " + ", ".join(unknown))
print("\ntotal: %d now known, %d still unknown" % (total_known, total_unknown))
