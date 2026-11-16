# Replay the fuzzy corpus (ct_fuzzy_cases.txt) with Core's exact decision and
# print the hit rate per category.
#
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_fuzzy_check.py [cases.txt] [-v]
#
# A positive case hits when the line is detected as its language, would be
# shown, and every " & "-separated fragment of the expectation appears in the
# translation (case-insensitive; "a | b" inside a fragment accepts either).
# An UNTOUCHED case hits when the line would be left alone. Exits non-zero
# when any UNTOUCHED case fails: those are the regression guards.
import io
import os
import sys

sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
args = [a for a in sys.argv[3:] if not a.startswith("-")]
verbose = "-v" in sys.argv
path = args[0] if args else os.path.join(HERE, "ct_fuzzy_cases.txt")
try:
    MINC = float(B.db.minCoverage or 0.34)
except Exception:
    MINC = 0.34


def tup(r):
    return r if isinstance(r, tuple) else (r,)


def decide(text):
    """Core's decision for a line: (shown, lang, translation, confidence, coverage)."""
    if len(str(B.Text.LooseKey(text) or "")) < 2:
        return False, None, None, 0.0, 0.0
    r = (list(tup(B.DetectLanguage(B, text, None))) + [None] * 5)[:5]
    lang, conf, eng, stats, _ = r
    conf = float(conf or 0)
    if lang is None or lang == "en":
        return False, lang, None, conf, 0.0
    t = tup(B.TranslateText(B, text, lang, "en", eng, stats))
    out = t[0]
    cov = float(t[1] or 0) if len(t) > 1 else 0.0
    shaky = (conf < 0.3 and cov < 0.6) or (conf < 0.1 and cov < 0.8)
    nonblank = bool(out) and out.strip() != ""
    shown = nonblank and not shaky and cov >= MINC and out.lower() != text.lower()
    return shown, lang, out, conf, cov


def matches(expected, out):
    low = out.lower()
    for frag in expected.split(" & "):
        alts = [a.strip().lower() for a in frag.split("|")]
        if not any(a and a in low for a in alts):
            return False
    return True


categories = []   # [name, hits, total, failures]
current = None
negatives_failed = 0
with io.open(path, encoding="utf-8") as f:
    for raw in f:
        line = raw.strip()
        if not line or line.startswith("#!"):
            continue
        if line.startswith("##"):
            current = [line[2:].strip(), 0, 0, []]
            categories.append(current)
            continue
        if line.startswith("#"):
            continue
        if "=>" not in line or ":" not in line.split("=>")[0]:
            continue
        if current is None:
            current = ["cases", 0, 0, []]
            categories.append(current)
        left, expected = [p.strip() for p in line.split("=>", 1)]
        lang, text = [p.strip() for p in left.split(":", 1)]
        shown, got, out, conf, cov = decide(text)
        if expected == "UNTOUCHED":
            hit = not shown
        else:
            hit = shown and got == lang and out is not None and matches(expected, out)
        current[2] += 1
        if hit:
            current[1] += 1
        else:
            if expected == "UNTOUCHED":
                negatives_failed += 1
            current[3].append((lang, text, expected, got, shown, out, conf, cov))

hits = total = 0
for name, h, t, failures in categories:
    hits += h
    total += t
    print("%-70s %3d/%-3d %3d%%" % (name, h, t, 100.0 * h / t if t else 0))
    for lang, text, expected, got, shown, out, conf, cov in failures:
        print("   MISS [%s] %s" % (lang, text))
        print("        expected: %s" % expected)
        print("        got: [%s%s %d%% %d%%] %s" % (got or "--", "" if shown else " hidden", conf * 100, cov * 100, out or ""))
print()
print("fuzzy corpus: %d/%d hits (%d%%), %d negative case(s) failed" % (hits, total, 100.0 * hits / total if total else 0, negatives_failed))
sys.exit(1 if negatives_failed else 0)
