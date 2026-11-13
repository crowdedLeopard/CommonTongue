# Load cost of the addon: time to load every file and Lua memory used.
#   python tools/tests/ct_perf.py CommonTongue
import os, sys, time
import lupa.lua51 as lupa
sys.stdout.reconfigure(encoding="utf-8")
ADDON = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
L.execute(open(os.path.join(HERE, "wowstub.lua"), encoding="utf-8").read())
toc = [f for f in os.listdir(ADDON) if f.endswith(".toc")][0]
NAME = toc[:-4]
files = [l.strip().replace("\\", "/") for l in open(os.path.join(ADDON, toc), encoding="utf-8").read().splitlines() if l.strip() and not l.startswith("#")]
loader = L.eval("function(path, name) local f, err = loadfile(path); if not f then error(err) end; return f(name, {}) end")
mem = L.eval("function() collectgarbage('collect'); return collectgarbage('count') end")
m0 = mem()
t0 = time.perf_counter()
per = []
for rel in files:
    p = os.path.join(ADDON, rel).replace("\\", "/")
    if os.path.exists(p):
        t = time.perf_counter(); loader(p, NAME); per.append((time.perf_counter() - t, rel))
t1 = time.perf_counter()
m1 = mem()
total_src = sum(os.path.getsize(os.path.join(ADDON, r)) for r in files if os.path.exists(os.path.join(ADDON, r)))
print("files: %d   source: %.1f MB   load time: %.0f ms   Lua memory after load: %.1f MB (was %.1f MB)" % (
    len(per), total_src / 1e6, (t1 - t0) * 1000, (m1 - m0) / 1024, m0 / 1024))
for dt, rel in sorted(per, reverse=True)[:5]:
    print("  %6.0f ms  %s" % (dt * 1000, rel))
B = L.globals()[NAME]
lines = ["cherche groupe pour les mortemines, manque un tank, mp moi",
         "LMR recrute ! Donjons, quêtes, bons copains et entraide ! Solo ou team, petit ou gros niveau, tout le monde est bienvenu. Déjà 100 membres !",
         "busco grupo para minas de la muerte, falta tanque y sanador", "hello everyone, looking for a group"]
n = 200
t = time.perf_counter()
for i in range(n):
    for s in lines:
        d = B.DetectLanguage(B, s)
        d = d if isinstance(d, tuple) else (d,)
        if d[0] and d[0] != "en":
            B.TranslateText(B, s, d[0], "en", d[2] if len(d) > 2 else None, d[3] if len(d) > 3 else None)
dt = (time.perf_counter() - t) / (n * len(lines)) * 1000
print("detect + translate, uncached: %.2f ms per message (%d-word guild advert included)" % (dt, len(lines[1].split())))
