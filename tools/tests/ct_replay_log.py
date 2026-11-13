# Replay a real WoWChatLog.txt through the engine and report what the addon
# would have shown for every chat line, using the same decision as Core.lua.
#
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_replay_log.py [chatlog] [since]
#
#   chatlog  path to WoWChatLog.txt (default: the Forever client's log)
#   since    only lines at or after this stamp, e.g. "11/13 09:59" (default: all)
#
# Prints a summary, then every line the addon would have translated, then the
# foreign lines it would have left alone (too little understood) and the lines
# that looked foreign but matched no language: those are the dictionary gaps.
import io, os, re, sys, collections
sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_LOG = r"C:\Program Files (x86)\World of Warcraft\_forever_\Logs\WoWChatLog.txt"
args = sys.argv[3:]
path = args[0] if args else DEFAULT_LOG
since = args[1] if len(args) > 1 else ""

CHAN = re.compile(r"^(?P<ts>\d\d/\d\d \d\d:\d\d:\d\d)\.\d+  \[(?P<chan>[^\]]+)\] (?P<who>[^:\[\]]+?): (?P<text>.*)$")
SAY = re.compile(r"^(?P<ts>\d\d/\d\d \d\d:\d\d:\d\d)\.\d+  (?P<who>[^:\[\]]+?) (?P<chan>says|yells|whispers)(?: to you)?: (?P<text>.*)$")

try:
    MINC = float(B.db.minCoverage or 0.34)
except Exception:
    MINC = 0.34


def detect(text, prior):
    r = B.DetectLanguage(B, text, prior)
    r = r if isinstance(r, tuple) else (r,)
    r = (list(r) + [None] * 5)[:5]
    return r  # lang, confidence, english, stats, unknownForeign


def translate(text, lang, english, stats):
    r = B.TranslateText(B, text, lang, "en", english, stats)
    r = r if isinstance(r, tuple) else (r,)
    return r[0], float(r[1] or 0) if len(r) > 1 else 0.0


lines_read = chat_lines = 0
seen = {}
order = []
with io.open(path, encoding="utf-8", errors="replace") as f:
    for raw in f:
        lines_read += 1
        raw = raw.rstrip("\r\n")
        m = CHAN.match(raw) or SAY.match(raw)
        if not m:
            continue
        if since and m.group("ts") < since:
            continue
        chat_lines += 1
        text = m.group("text").strip()
        if not text:
            continue
        k = text.lower()
        if k in seen:
            seen[k]["n"] += 1
            continue
        seen[k] = {"ts": m.group("ts"), "chan": m.group("chan"), "who": m.group("who"), "text": text, "n": 1}
        order.append(k)

author_lang = {}
shown, hidden, unknown, english = [], [], [], 0
by_lang_shown = collections.Counter()
by_lang_hidden = collections.Counter()
for k in order:
    e = seen[k]
    text, who = e["text"], e["who"]
    if len(str(B.Text.LooseKey(text) or "")) < 2:
        english += 1  # "o/", ":D", a lone letter: Core.lua never translates these
        continue
    lang, conf, eng, stats, unknown_foreign = detect(text, author_lang.get(who))
    conf = float(conf or 0)
    if lang == "en":
        english += 1
        continue
    if lang is None:
        if unknown_foreign:
            unknown.append(e)
        else:
            english += 1  # neutral: numbers, "lol", "inv pls"
        continue
    translated, cov = translate(text, lang, eng, stats)
    shaky = conf < 0.3 and cov < 0.6
    nonblank = bool(translated) and translated.strip() != ""
    ok = nonblank and not shaky and cov >= MINC and translated.lower() != text.lower()
    if translated and conf >= 0.5 and cov >= 0.5:
        author_lang[who] = lang
    rec = dict(e, lang=lang, conf=conf, cov=cov, out=translated)
    if ok:
        shown.append(rec)
        by_lang_shown[lang] += 1
    else:
        why = "no dictionary" if translated is None else ("empty" if not nonblank else ("shaky" if shaky else ("%d%% understood" % (cov * 100) if cov < MINC else "unchanged")))
        rec["why"] = why
        hidden.append(rec)
        by_lang_hidden[lang] += 1

print("chat log: %s" % path)
if since:
    print("since: %s" % since)
print("lines read: %d   chat lines: %d   distinct texts: %d" % (lines_read, chat_lines, len(order)))
print("english or neutral: %d   translated: %d   foreign but hidden: %d   foreign-looking, no language: %d" % (
    english, len(shown), len(hidden), len(unknown)))
print("translated by language: " + ", ".join("%s %d" % (l, n) for l, n in by_lang_shown.most_common()))
print("hidden by language:     " + ", ".join("%s %d" % (l, n) for l, n in by_lang_hidden.most_common()))


def show(rec, extra=""):
    rep = (" x%d" % rec["n"]) if rec["n"] > 1 else ""
    print("[%s %3d%% %3d%%%s] %s: %s%s" % (rec["lang"], rec["conf"] * 100, rec["cov"] * 100, rep, rec["who"], rec["text"], extra))


print("\n==== TRANSLATED (what the addon showed) ====")
for lang, _ in by_lang_shown.most_common():
    print("\n-- %s --" % lang)
    for rec in shown:
        if rec["lang"] == lang:
            show(rec)
            print("      -> %s" % rec["out"])

print("\n==== FOREIGN BUT HIDDEN (detected, not shown) ====")
for rec in hidden:
    show(rec, "   [%s]" % rec["why"])
    if rec["out"]:
        print("      -> %s" % rec["out"])

print("\n==== FOREIGN-LOOKING, NO LANGUAGE MATCHED ====")
for e in unknown:
    rep = (" x%d" % e["n"]) if e["n"] > 1 else ""
    print("[--%s] %s: %s" % (rep, e["who"], e["text"]))
