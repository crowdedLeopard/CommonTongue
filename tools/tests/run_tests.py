"""Load the CommonTongue addon in a Lua 5.1 runtime with a WoW API stub and run checks."""
import os, re, sys, time
import lupa.lua51 as lupa
sys.stdout.reconfigure(encoding="utf-8")

ADDON = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))

L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
with open(os.path.join(HERE, "wowstub.lua"), encoding="utf-8") as f:
    L.execute(f.read())

# Load files in TOC order, passing (addonName, namespace) like the game does.
toc = open(os.path.join(ADDON, "CommonTongue.toc"), encoding="utf-8").read()
files = [l.strip().replace("\\", "/") for l in toc.splitlines() if l.strip() and not l.startswith("#")]
m = re.search(r"^## Version:\s*(\S+)", toc, re.M)
L.globals().__tocVersion = m.group(1) if m else "dev"
globals_before = set(L.globals().keys())
loader = L.eval("function(path) local f, err = loadfile(path); if not f then error(err) end; return f('CommonTongue', {}) end")
t0 = time.time()
for rel in files:
    path = os.path.join(ADDON, rel).replace("\\", "/")
    if not os.path.exists(path):
        print("skip missing", rel); continue
    try:
        loader(path)
    except Exception as e:  # noqa
        print("LOAD ERROR in", rel, "->", e)
        sys.exit(1)
print(f"loaded {len(files)} files in {time.time()-t0:.2f}s")

L.execute("__fire('ADDON_LOADED', 'CommonTongue'); __fire('PLAYER_LOGIN')")
B = L.globals().CommonTongue

# Strict globals: the addon may create exactly its own table, its saved
# variables and its slash-command names. Anything else is a leaked local.
ALLOWED_GLOBALS = {"CommonTongue", "CommonTongueDB"}
leaked = sorted(k for k in set(L.globals().keys()) - globals_before
                if k not in ALLOWED_GLOBALS and not str(k).startswith("SLASH_"))
if leaked:
    print("FAIL leaked globals:", ", ".join(map(str, leaked)))
    sys.exit(1)
print("globals: clean")
print("target:", B.db.target, "| languages:", ", ".join(f"{c}({B.Languages[c].entryCount})" for c in list(B.LanguageOrder.values())))
print("welcome:", list(L.globals().__printed.values()))

detect = B.DetectLanguage
translate = B.TranslateText
chat = L.globals().__chat

def show(msg, expect=None):
    res = detect(B, msg)
    lang, conf = (res[0], res[1]) if isinstance(res, tuple) else (res, 0)
    out = chat("CHAT_MSG_SAY", msg)
    flag = ""
    if expect is not None:
        flag = "  OK" if lang == expect else f"  !! expected {expect}"
    print(f"[{lang or '--'} {conf:.2f}]{flag} {msg}")
    if out != msg:
        print("      ->", out)

if len(sys.argv) > 2:
    # free-form: python run_tests.py <addon> "<text>" ...
    for m in sys.argv[2:]:
        show(m)
    sys.exit(0)

print("\n--- Spanish -> English ---")
for m in [
    "hola alguien me ayuda con la mision?",
    "Busco grupo para mazmorra, falta tanque y sanador",
    "vendo pociones baratas, 5 de oro cada una",
    "donde esta la entrada de la mina?",
    "Hola buenas, alguien sabe donde consigo lino?",
    "jajaja no se",
    "gracias",
    "vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato, 2g cada uno",
    "QUIEN QUIERE HACER STOCKADES?",
    "me voy a dormir, hasta mañana a todos",
    "¿Alguien tiene una llave para la puerta?",
    "necesitamos un healer para RFC, estamos en la entrada",
]:
    show(m, "es")

print("\n--- English / neutral (should be left alone) ---")
for m in ["LFG tank for SM", "ok", "wts 20 linen cloth 1g", "anyone need a healer for deadmines?", "lol", "inv pls", "a", "123"]:
    show(m)

print("\n--- English -> Spanish (target es) ---")
B.HandleSlash(B, "to es")
for m in ["hello, I need a tank for the dungeon", "where is the entrance?", "thanks, see you later"]:
    out = chat("CHAT_MSG_SAY", m)
    print(" ", m, "->", out)
B.HandleSlash(B, "to en")

print("\n--- outgoing /tsay ---")
L.globals().SlashCmdList["TONGUESAY"]("es hello everyone, I'm looking for a group for the dungeon, need tank and healer")
L.globals().SlashCmdList["TONGUEPREVIEW"]("es where is the entrance?")
print("  sent:", [(s.chatType, s.msg) for s in L.globals().__sent.values()])
print("  printed:", list(L.globals().__printed.values())[-2:])

print("\n--- slash: test / status ---")
B.HandleSlash(B, "test hola amigos, buscamos gente para la banda")
B.HandleSlash(B, "status")
for p in list(L.globals().__printed.values())[-4:]:
    print("  ", p)

# Speed check
t0 = time.time()
n = 300
for i in range(n):
    B.ClearCache(B)
    chat("CHAT_MSG_SAY", "hola alguien me ayuda con la mision de la mina? necesito un tanque " + str(i))
dt = (time.time() - t0) / n * 1000
print(f"\navg per message (uncached): {dt:.2f} ms")
