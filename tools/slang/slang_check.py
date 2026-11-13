# Run the TEST lines of one language's slang files through the real engine.
#   python tools/tests/ct_dbg.py CommonTongue tools/slang/slang_check.py <lang>
# Prints detection, the translation and whether the expected English appears.
import io, os, sys
sys.stdout.reconfigure(encoding="utf-8")
ADDON = os.path.abspath(sys.argv[1])
lang = sys.argv[3]
ROOT = os.path.dirname(ADDON)
path = os.path.join(ROOT, "tools", "slang", lang + "_tests.txt")
if not os.path.exists(path):
    print("no tests for", lang)
    sys.exit(0)

ok = det_ok = n = 0
with io.open(path, encoding="utf-8") as f:
    for raw in f:
        line = raw.strip()
        if not line or "=>" not in line:
            continue
        text, expected = [s.strip() for s in line.split("=>", 1)]
        n += 1
        det = B.DetectLanguage(B, text)
        det = det if isinstance(det, tuple) else (det,)
        code, conf, english, stats = (list(det) + [None] * 4)[:4]
        if code == lang:
            det_ok += 1
        res = B.TranslateText(B, text, code or lang, "en", english if code else None, stats if code else None)
        res = res if isinstance(res, tuple) else (res,)
        translated, coverage = res[0], (res[1] if len(res) > 1 else 0)
        hit = translated is not None and expected.lower() in str(translated).lower()
        ok += 1 if hit else 0
        mark = "OK " if hit else "?? "
        print("%s[%s %3d%% %3d%%] %s\n      -> %s\n      expected: %s" % (
            mark, code or "--", (conf or 0) * 100, (coverage or 0) * 100, text, translated, expected))
print("\n%s: %d lines, detected as %s: %d, expected text found: %d" % (lang, n, lang, det_ok, ok))
