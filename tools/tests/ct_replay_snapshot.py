# Snapshot of Core's decision for EVERY distinct line of a chat log, one line
# per text, in a stable format for diffing before and after an engine change:
#
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_replay_snapshot.py <chatlog> <out.tsv>
#   ... change the engine ...
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_replay_snapshot.py <chatlog> <after.tsv>
#   diff <out.tsv> <after.tsv>
#
# Every changed line is then a decision that changed: a line newly shown or
# hidden, a different language, a different translation. ct_replay_log.py
# gives the readable report; this gives the regression diff. The output holds
# other players' chat, so keep it out of the repository.
#
# Columns:  decision  lang  confidence%  coverage%  text  translation
#   decision: skip (loose key under two characters), en, neutral,
#             foreign? (looks foreign, no language), shown, hidden:<why>
import io
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
if len(sys.argv) < 5:
    sys.exit("usage: ct_dbg.py <addon> ct_replay_snapshot.py <chatlog> <out.tsv>")
path, out_path = sys.argv[3], sys.argv[4]
CHAN = re.compile(r"^(?P<ts>\d\d/\d\d \d\d:\d\d:\d\d)\.\d+  \[(?P<chan>[^\]]+)\] (?P<who>[^:\[\]]+?): (?P<text>.*)$")
SAY = re.compile(r"^(?P<ts>\d\d/\d\d \d\d:\d\d:\d\d)\.\d+  (?P<who>[^:\[\]]+?) (?P<chan>says|yells|whispers)(?: to you)?: (?P<text>.*)$")
try:
    MINC = float(B.db.minCoverage or 0.34)
except Exception:
    MINC = 0.34


def tup(r):
    return r if isinstance(r, tuple) else (r,)


seen, order = {}, []
with io.open(path, encoding="utf-8", errors="replace") as f:
    for raw in f:
        m = CHAN.match(raw.rstrip("\r\n")) or SAY.match(raw.rstrip("\r\n"))
        if not m:
            continue
        text = m.group("text").strip()
        if not text:
            continue
        k = text.lower()
        if k in seen:
            continue
        seen[k] = (m.group("who"), text)
        order.append(k)

author_lang = {}
rows, counts = [], {}
for k in order:
    who, text = seen[k]
    if len(str(B.Text.LooseKey(text) or "")) < 2:
        rows.append(("skip", "", 0, 0, text, ""))
        counts["skip"] = counts.get("skip", 0) + 1
        continue
    r = (list(tup(B.DetectLanguage(B, text, author_lang.get(who)))) + [None] * 5)[:5]
    lang, conf, eng, stats, unknown_foreign = r
    conf = float(conf or 0)
    if lang == "en":
        rows.append(("en", "en", 100, 0, text, ""))
        counts["en"] = counts.get("en", 0) + 1
        continue
    if lang is None:
        d = "foreign?" if unknown_foreign else "neutral"
        rows.append((d, "", 0, 0, text, ""))
        counts[d] = counts.get(d, 0) + 1
        continue
    t = tup(B.TranslateText(B, text, lang, "en", eng, stats))
    translated = t[0]
    cov = float(t[1] or 0) if len(t) > 1 else 0.0
    shaky = (conf < 0.3 and cov < 0.6) or (conf < 0.1 and cov < 0.8)  # Core.lua's rule
    nonblank = bool(translated) and translated.strip() != ""
    ok = nonblank and not shaky and cov >= MINC and translated.lower() != text.lower()
    if translated and conf >= 0.5 and cov >= 0.5:
        author_lang[who] = lang
    if ok:
        d = "shown"
    else:
        why = "no dictionary" if translated is None else ("empty" if not nonblank else ("shaky" if shaky else ("low" if cov < MINC else "unchanged")))
        d = "hidden:" + why
    counts[d] = counts.get(d, 0) + 1
    rows.append((d, lang, int(conf * 100), int(cov * 100), text, translated or ""))

with io.open(out_path, "w", encoding="utf-8") as f:
    for d, lang, conf, cov, text, out in rows:
        f.write("%s\t%s\t%d\t%d\t%s\t%s\n" % (d, lang, conf, cov, text, out))
print("distinct texts: %d  ->  %s" % (len(rows), out_path))
for d in sorted(counts):
    print("  %-16s %d" % (d, counts[d]))
