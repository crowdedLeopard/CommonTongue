"""Load the addon into a Lua 5.1 runtime with the WoW stub, then run a script.

    python tools/tests/ct_dbg.py <addon folder> <script.py> [args...]

The script runs with these names in scope:
    L      the lupa runtime            G   its globals
    B      the CommonTongue table      NAME, ADDON
The game events (ADDON_LOADED, PLAYER_LOGIN) are NOT fired; a script that
needs B.db fires them itself with
    L.execute("__fire('ADDON_LOADED', '%s'); __fire('PLAYER_LOGIN')" % NAME)
"""
import os
import re
import sys

import lupa.lua51 as lupa

sys.stdout.reconfigure(encoding="utf-8")
ADDON = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
L = lupa.LuaRuntime(unpack_returned_tuples=True, encoding="utf-8")
L.execute(open(os.path.join(HERE, "wowstub.lua"), encoding="utf-8").read())
toc = [f for f in os.listdir(ADDON) if f.endswith(".toc")][0]
NAME = toc[:-4]
toc_text = open(os.path.join(ADDON, toc), encoding="utf-8").read()
files = [l.strip().replace("\\", "/") for l in toc_text.splitlines() if l.strip() and not l.startswith("#")]
m = re.search(r"^## Version:\s*(\S+)", toc_text, re.M)
L.globals().__tocVersion = m.group(1) if m else "dev"
loader = L.eval("function(path, name) local f, err = loadfile(path); if not f then error(err) end; return f(name, {}) end")
for rel in files:
    p = os.path.join(ADDON, rel).replace("\\", "/")
    if os.path.exists(p):
        loader(p, NAME)
G = L.globals()
B = G[NAME]
exec(open(sys.argv[2], encoding="utf-8").read())
