"""End-to-end test of the live bridge: the real addon (in a Lua 5.1 runtime
with a WoW API stub) against the real companion classes, joined only by the
files they would share in the game: the chat log and the slot addons.

usage: ct_bridge_test.py <dev root containing CommonTongue/ and Companion/> [--google]
"""
import importlib.util, os, shutil, sys, tempfile, threading, time
import lupa.lua51 as lupa

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.abspath(sys.argv[1])
USE_GOOGLE = "--google" in sys.argv
HERE = os.path.dirname(os.path.abspath(__file__))
ADDON_SRC = [d for d in os.listdir(ROOT) if os.path.isdir(os.path.join(ROOT, d)) and
             any(f.endswith(".toc") for f in os.listdir(os.path.join(ROOT, d)))][0]
NAME = ADDON_SRC
comp_file = [f for f in os.listdir(os.path.join(ROOT, "Companion")) if f.endswith("companion.py")][0]
spec = importlib.util.spec_from_file_location("companion", os.path.join(ROOT, "Companion", comp_file))
comp = importlib.util.module_from_spec(spec); spec.loader.exec_module(comp)

fails = []
def check(label, cond, detail=""):
    print(("  PASS  " if cond else "  FAIL  ") + label + (("   " + str(detail)) if detail and not cond else ""))
    if not cond: fails.append(label)

# ---- a fake game folder: AddOns with the addon and 40 slot addons, Logs ----
game = tempfile.mkdtemp(prefix="ct_game_")
addons = os.path.join(game, "Interface", "AddOns"); os.makedirs(addons)
os.makedirs(os.path.join(game, "Logs"))
shutil.copytree(os.path.join(ROOT, ADDON_SRC), os.path.join(addons, NAME))
SLOTS = 40
for i in range(SLOTS):
    d = os.path.join(addons, f"{NAME}_Slot_{i:03d}"); os.makedirs(d)
    open(os.path.join(d, f"{NAME}_Slot_{i:03d}.toc"), "w").write("## Interface: 16001\n## LoadOnDemand: 1\ndata.lua\n")
    open(os.path.join(d, "data.lua"), "w").write("-- empty\n")
chatlog = os.path.join(game, "Logs", "WoWChatLog.txt")

# ---- the companion, with a deterministic backend unless --google ----
class FakeBackend:
    name = "fake"
    table = {
        "busco grupo para minas de la muerte": ("Looking for a group for the Deadmines", "es"),
        "vendo [Wool Cloth] barato": ("Selling [Wool Cloth] cheap", "es"),
        "keresek egy csapatot a banyaba": ("I am looking for a team for the mine", "hu"),
        "hello everyone need a tank": None,  # same language
    }
    def translate(self, text, target):
        if target == "es":
            return "hola a todos, necesito un tanque", "en"
        hit = self.table.get(text, "MISSING")
        if hit == "MISSING":
            raise RuntimeError("no fake translation for " + repr(text))
        if hit is None:
            return text, target
        return hit

args = comp.build_parser().parse_args(["--wow", game, "--memory", os.path.join(game, "memory.json"),
                                       "--me", "Tester", "--always"])
args.channels = set()
backend = comp.GoogleBackend() if USE_GOOGLE else FakeBackend()
companion = comp.Companion(args, backend)

# ---- the addon ----
L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
L.execute(open(os.path.join(HERE, "wowstub.lua"), encoding="utf-8").read())
G = L.globals()
G.__addonsDir = addons.replace("\\", "/")
G.__chatlog = chatlog.replace("\\", "/")
G.__logAutoFlush = False         # the game buffers the chat log until asked
G.__player = "Tester"
toc = os.path.join(addons, NAME, NAME + ".toc")
files = [l.strip().replace("\\", "/") for l in open(toc, encoding="utf-8").read().splitlines() if l.strip() and not l.startswith("#")]
loader = L.eval("function(path, name) local f, err = loadfile(path); if not f then error(err) end; return f(name, {}) end")
for rel in files:
    p = os.path.join(addons, NAME, rel).replace("\\", "/")
    if os.path.exists(p): loader(p, NAME)
B = G[NAME]
chat, advance, line = G.__chat, G.__advance, G.__line

def run(seconds, step=0.1):
    """Let real time and the game clock pass together."""
    end = time.time() + seconds
    while time.time() < end:
        time.sleep(step); advance(step)

def printed(): return list(G.__printed.values())

print("== 1. login with the companion not running ==")
L.execute(f"__fire('ADDON_LOADED', '{NAME}'); __fire('PLAYER_LOGIN')")
check("slot addons counted", B.Bridge.slots == SLOTS, B.Bridge.slots)
out = chat("CHAT_MSG_SAY", "busco grupo para mazmorra", "Pedro-Realm")
check("not live: instant built-in translation inline", "looking for group for dungeon" in out.lower(), out)
run(6.0)
check("probe found no companion", not B.Bridge.live)
used_before = B.Bridge.used

print("== 2. companion starts; /tongue live connects ==")
threads = companion.start()
time.sleep(2.5)
B.HandleSlash(B, "live")
run(1.5)
check("bridge is live", bool(B.Bridge.live), printed()[-2:])
check("chat logging switched on", bool(G.__logging))

print("== 3. a foreign line gets its machine translation appended in place ==")
msg = "busco grupo para minas de la muerte"
out = chat("CHAT_MSG_SAY", msg, "Pedro-Realm"); lid = G.__lastLine
check("line appears untouched first", out == msg, out)
t0 = time.time(); got = None
while time.time() - t0 < 8 and not got:
    run(0.2)
    text = line(lid, 1)
    if text and text != "[Pedro-Realm]: " + msg: got = text
dt = time.time() - t0
check(f"translation appended in chat frame 1 after {dt:.1f}s", bool(got) and ("Deadmines" in got or "group" in got.lower()), got)
text2 = line(lid, 2)
check("also appended in chat frame 2", bool(text2) and text2 != "[Pedro-Realm]: " + msg, text2)
check("machine translation colour used", bool(got) and "8fe38f" in got, got)
check("log flush was learned as necessary", bool(B.db.flush))
print("     ", got)

print("== 4. the same sentence again is instant, from memory ==")
out = chat("CHAT_MSG_SAY", msg, "Maria-Realm")
check("inline at once", out != msg and "8fe38f" in out, out)

print("== 5. item links survive machine translation ==")
linkmsg = "vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato"
out = chat("CHAT_MSG_CHANNEL", linkmsg, "Pedro-Realm"); lid = G.__lastLine
t0 = time.time(); got = None
while time.time() - t0 < 8 and not got:
    run(0.2)
    text = line(lid, 1)
    if text and "8fe38f" in text: got = text
check("translated with the real item link put back", bool(got) and got.count("|Hitem:2592") == 2, got)

print("== 6. a language with no dictionary (Hungarian) still gets translated ==")
hmsg = "keresek egy csapatot a banyaba"
out = chat("CHAT_MSG_SAY", hmsg, "Bela-Realm"); lid = G.__lastLine
t0 = time.time(); got = None
while time.time() - t0 < 8 and not got:
    run(0.2)
    text = line(lid, 1)
    if text and "8fe38f" in text: got = text
check("unknown language sent through the bridge and translated", bool(got), line(lid, 1))
print("     ", got)

print("== 7. speaking: /bsay es ... goes through the companion ==")
G.SlashCmdList["TONGUESAY"]("es hello everyone, need a tank")
t0 = time.time(); opened = []
while time.time() - t0 < 8 and not opened:
    run(0.2); opened = list(G.__opened.values())
check("translated text placed in the chat box", bool(opened) and opened[0].startswith("/s ") and "tanque" in opened[0], opened)
whispers = [s.msg for s in G.__sent.values() if s.chatType == "WHISPER"]
check("request went out as a hidden whisper to self", bool(whispers) and whispers[0].startswith("[CT>es]"), whispers)

print("== 8. companion stops: graceful fallback to the built-in translation ==")
companion.stop.set(); time.sleep(1.5)
fmsg = "necesito un sanador para la mazmorra"
time.sleep(9)   # let the heartbeat go stale
advance(9)
out = chat("CHAT_MSG_SAY", fmsg, "Pedro-Realm"); lid = G.__lastLine
t0 = time.time(); got = None
while time.time() - t0 < 10 and not got:
    run(0.2)
    text = line(lid, 1)
    if text and text != "[Pedro-Realm]: " + fmsg: got = text
check("built-in translation appended when the companion is gone", bool(got) and "healer" in got and "7fd4ff" in got, got)
check("bridge marked not live", not B.Bridge.live)
out = chat("CHAT_MSG_SAY", "donde esta la entrada", "Pedro-Realm")
check("later lines are instant inline again", "where is the entrance" in out.lower(), out)

print("== 9. the memory was written for the next login ==")
companion.close()
learned = open(os.path.join(addons, NAME, "Learned.lua"), encoding="utf-8").read()
check("Learned.lua contains the sentence", "busco grupo para minas de la muerte" in learned, learned[:300])
L2 = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
L2.execute(open(os.path.join(HERE, "wowstub.lua"), encoding="utf-8").read())
loader2 = L2.eval("function(path, name) local f, err = loadfile(path); if not f then error(err) end; return f(name, {}) end")
for rel in files:
    p = os.path.join(addons, NAME, rel).replace("\\", "/")
    if os.path.exists(p): loader2(p, NAME)
L2.execute(f"__fire('ADDON_LOADED', '{NAME}'); __fire('PLAYER_LOGIN')")
out = L2.globals().__chat("CHAT_MSG_SAY", msg, "Pedro-Realm")
check("fresh session, no companion: sentence known from Learned.lua", "8fe38f" in out and out != msg, out)

print(f"\nslots used: {B.Bridge.used} of {SLOTS}")
print("RESULT:", "ALL PASSED" if not fails else f"{len(fails)} FAILED: {fails}")
shutil.rmtree(game, ignore_errors=True)
sys.exit(1 if fails else 0)
