#!/usr/bin/env python3
r"""
CommonTongue companion: real machine translation for World of Warcraft chat,
delivered inside the game's own chat frame.

How it works
  1. The game writes chat to  <WoW>\_forever_\Logs\WoWChatLog.txt  when chat
     logging is on (the addon switches it on).
  2. This program follows that file, translates every line that is not in your
     language, and
       * keeps a ring of tiny "slot" addons up to date; the CommonTongue addon
         loads the slot for the current second and so receives the translation
         a moment after the line appeared (the live bridge), and
       * remembers every translation and writes them to  CommonTongue\Learned.lua
         so the addon knows them at the next login or /reload, even when this
         program is not running (the translation memory).
  3. It only reads the chat log and writes data files into the AddOns folder,
     the same way the TradeSkillMaster and WeakAuras companion apps do. It does
     not read game memory, inject input or look at the screen.

Backends
  google   (default) Google's keyless public endpoint. Free, no signup.
           Unofficial, so heavy use can be rate-limited. Chat lines that are
           not in your language are sent to Google for translation.
  argos    Fully offline:  pip install argostranslate   then one package per
           language pair, e.g.  argospm install translate-es_en
  libre    A LibreTranslate server:  --url http://localhost:5000  [--key ...]
  deepl    DeepL API (free tier works):  --key YOUR_KEY

Examples
  python commontongue_companion.py
  python commontongue_companion.py --target de --me Mychar
  python commontongue_companion.py --backend argos --overlay
"""
import argparse
import collections
import html
import json
import os
import queue
import re
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

ADDON = "CommonTongue"
SLOT_PREFIX = ADDON + "_Slot_"
DEFAULT_WOW = r"C:\Program Files (x86)\World of Warcraft\_forever_"

# ----------------------------------------------------------------------------
# Text keys. These mirror UTF8.lua / Text.lua in the addon exactly: both sides
# must compute the same "loose key" for a chat line.
# ----------------------------------------------------------------------------

def _lower_cp(cp):
    if cp < 0x80:
        return cp + 32 if 65 <= cp <= 90 else cp
    if 0xC0 <= cp <= 0xDE and cp != 0xD7:
        return cp + 32
    if 0x100 <= cp <= 0x17F:
        if cp == 0x130:
            return 0x69
        if cp == 0x178:
            return 0xFF
        if (0x100 <= cp <= 0x12F) or (0x132 <= cp <= 0x137) or (0x14A <= cp <= 0x177):
            return cp + 1 if cp % 2 == 0 else cp
        if (0x139 <= cp <= 0x148) or (0x179 <= cp <= 0x17E):
            return cp + 1 if cp % 2 == 1 else cp
        return cp
    if 0x391 <= cp <= 0x3A9 and cp != 0x3A2:
        return cp + 32
    if 0x410 <= cp <= 0x42F:
        return cp + 32
    if 0x400 <= cp <= 0x40F:
        return cp + 80
    if 0x460 <= cp <= 0x481 and cp % 2 == 0:
        return cp + 1
    if 0x48A <= cp <= 0x4BF and cp % 2 == 0:
        return cp + 1
    return cp


def _is_letter(cp):
    if cp < 0x80:
        return (65 <= cp <= 90) or (97 <= cp <= 122)
    if cp in (0xD7, 0xF7):
        return False
    return (0xC0 <= cp <= 0x24F or 0x370 <= cp <= 0x3FF or 0x400 <= cp <= 0x52F
            or 0x530 <= cp <= 0x58F or 0x590 <= cp <= 0x5FF or 0x600 <= cp <= 0x6FF
            or 0x900 <= cp <= 0x97F or 0xE00 <= cp <= 0xE7F or 0x1100 <= cp <= 0x11FF
            or 0x1E00 <= cp <= 0x1EFF or 0x3040 <= cp <= 0x309F or 0x30A0 <= cp <= 0x30FF
            or 0x3130 <= cp <= 0x318F or 0x3400 <= cp <= 0x4DBF or 0x4E00 <= cp <= 0x9FFF
            or 0xAC00 <= cp <= 0xD7AF or 0xF900 <= cp <= 0xFAFF or 0xFF66 <= cp <= 0xFF9F)


_CODES = [
    (re.compile(r"\|c[0-9a-fA-F]{8}"), ""),
    (re.compile(r"\|r"), ""),
    (re.compile(r"\|H.*?\|h"), ""),
    (re.compile(r"\|h"), ""),
    (re.compile(r"\|T.*?\|t"), ""),
    (re.compile(r"\|A.*?\|a"), ""),
    (re.compile(r"\|K.*?\|k"), ""),
    (re.compile(r"\|n"), " "),
    (re.compile(r"\{[A-Za-z]+[0-9]*\}"), ""),
]


def plain_text(text):
    """Remove WoW escape codes but keep what the player sees."""
    if "|" not in text and "{" not in text:
        return text
    for rx, repl in _CODES:
        text = rx.sub(repl, text)
    return text


def loose_key(text):
    """Lower case, letters and digits only, single spaces."""
    out, space = [], True
    for ch in plain_text(text):
        cp = _lower_cp(ord(ch))
        if (48 <= cp <= 57) or (97 <= cp <= 122) or (cp >= 0x80 and _is_letter(cp)):
            out.append(chr(cp))
            space = False
        elif not space:
            out.append(" ")
            space = True
    if out and out[-1] == " ":
        out.pop()
    return "".join(out)


def lua_str(s):
    return '"' + (s.replace("\\", "\\\\").replace('"', '\\"').replace("\r", " ")
                   .replace("\n", "\\n").replace("\0", "")) + '"'


# ----------------------------------------------------------------------------
# Deciding what needs translating
# ----------------------------------------------------------------------------
ENGLISH_HINTS = set("""
the a an and or but is are am was were be been i you he she it we they me him her us them my
your his its our their this that these those what which who where when why how not no
yes do does did have has had can could will would should to of in on at by for with
from about into over after before up down out off if then than so because as there
here all any some many much more most other just also too now later again please
thanks thank sorry hello hi hey bye need want looking anyone someone help selling
buying lfg lfm wts wtb pst inv tank heal healer dps afk brb gg wp gl hf ty np omw
quest group guild level gold dungeon raid boss ready wait gonna wanna lol go get got
come see know think make take give good bad new one two more less still here there
""".split())


def clearly_english(text):
    if any(ord(ch) > 127 for ch in text):
        return False
    words = re.findall(r"[a-zA-Z']+", text.lower())
    if not words:
        return True
    hits = sum(1 for w in words if w in ENGLISH_HINTS)
    return hits / len(words) >= 0.7


def script_language(text):
    """Language implied by the writing system, or None for Latin script."""
    for ch in text:
        cp = ord(ch)
        if 0xAC00 <= cp <= 0xD7AF or 0x1100 <= cp <= 0x11FF:
            return "ko"
        if 0x3040 <= cp <= 0x30FF:
            return "ja"
    for ch in text:
        cp = ord(ch)
        if 0x4E00 <= cp <= 0x9FFF:
            return "zh"
        if 0x0400 <= cp <= 0x04FF:
            return "ru"
        if 0x0370 <= cp <= 0x03FF:
            return "el"
        if 0x0E00 <= cp <= 0x0E7F:
            return "th"
        if 0x0600 <= cp <= 0x06FF:
            return "ar"
        if 0x0590 <= cp <= 0x05FF:
            return "he"
    return None


def short_code(code):
    """'zh-CN' -> 'zh', 'iw' -> 'he'; anything odd -> '?'."""
    if not code:
        return "?"
    code = code.lower().split("-")[0].split("_")[0]
    code = {"iw": "he", "jw": "jv"}.get(code, code)
    return code if re.fullmatch(r"[a-z]{2,3}", code) else "?"


# ----------------------------------------------------------------------------
# Translation backends: translate(text, target) -> (translated, detected source)
# ----------------------------------------------------------------------------

class RateLimited(Exception):
    pass


def http_json(url, data=None, headers=None, timeout=10):
    req = urllib.request.Request(url, data=data, headers=headers or {})
    req.add_header("User-Agent", "Mozilla/5.0 (chat-translator-companion)")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code in (429, 503):
            raise RateLimited(str(exc))
        raise


class GoogleBackend:
    name = "google"

    def __init__(self, **_):
        pass

    def translate(self, text, target):
        q = urllib.parse.quote(text)
        url = ("https://translate.googleapis.com/translate_a/single?client=gtx"
               f"&sl=auto&tl={target}&dt=t&q={q}")
        data = http_json(url)
        translated = "".join(part[0] for part in data[0] if part and part[0])
        detected = data[2] if len(data) > 2 and isinstance(data[2], str) else None
        return html.unescape(translated), detected


class LibreBackend:
    name = "libre"

    def __init__(self, url=None, key=None, **_):
        if not url:
            raise SystemExit("--url is required for the libre backend (e.g. http://localhost:5000)")
        self.url, self.key = url.rstrip("/"), key

    def translate(self, text, target):
        payload = {"q": text, "source": "auto", "target": target, "format": "text"}
        if self.key:
            payload["api_key"] = self.key
        data = http_json(self.url + "/translate", json.dumps(payload).encode("utf-8"),
                         {"Content-Type": "application/json"})
        detected = None
        if isinstance(data.get("detectedLanguage"), dict):
            detected = data["detectedLanguage"].get("language")
        return data.get("translatedText", ""), detected


class DeepLBackend:
    name = "deepl"

    def __init__(self, key=None, **_):
        if not key:
            raise SystemExit("--key is required for the deepl backend")
        self.key = key
        self.url = ("https://api-free.deepl.com/v2/translate" if key.endswith(":fx")
                    else "https://api.deepl.com/v2/translate")

    def translate(self, text, target):
        body = urllib.parse.urlencode({"text": text, "target_lang": target.upper()}).encode("utf-8")
        data = http_json(self.url, body, {"Authorization": f"DeepL-Auth-Key {self.key}",
                                          "Content-Type": "application/x-www-form-urlencoded"})
        tr = data["translations"][0]
        return tr["text"], (tr.get("detected_source_language") or "").lower() or None


class ArgosBackend:
    """Offline translation with Argos Translate (pip install argostranslate)."""
    name = "argos"

    def __init__(self, source=None, **_):
        try:
            import argostranslate.translate as at
        except ImportError:
            raise SystemExit("argostranslate is not installed:  pip install argostranslate\n"
                             "then e.g.  argospm install translate-es_en")
        self.at, self.source = at, source
        try:
            from langdetect import detect  # optional
            self.detect = detect
        except ImportError:
            self.detect = None
        self.pairs = None

    def _pairs(self):
        if self.pairs is None:
            self.pairs = set()
            for lang in self.at.get_installed_languages():
                for tr in getattr(lang, "translations_from", []):
                    self.pairs.add((lang.code, tr.to_lang.code))
        return self.pairs

    def translate(self, text, target):
        src = script_language(text) or (self.detect(text) if self.detect else None) or self.source
        if not src:
            raise RuntimeError("cannot detect the language; pass --source xx or pip install langdetect")
        src = short_code(src)
        if src == target:
            return text, src
        if (src, target) not in self._pairs():
            raise RuntimeError(f"no Argos package for {src}->{target}:  argospm install translate-{src}_{target}")
        return self.at.translate(text, src, target), src


BACKENDS = {"google": GoogleBackend, "libre": LibreBackend, "deepl": DeepLBackend, "argos": ArgosBackend}


# ----------------------------------------------------------------------------
# Translation memory -> Learned.lua
# ----------------------------------------------------------------------------

class Memory:
    """target language -> { loose key: [source, translation, last used] }"""

    def __init__(self, path, limit=6000):
        self.path, self.limit = path, limit
        self.data, self.dirty = {}, False
        self.lock = threading.Lock()
        try:
            with open(path, encoding="utf-8") as fh:
                self.data = json.load(fh)
        except (OSError, ValueError):
            self.data = {}

    def get(self, target, key):
        with self.lock:
            hit = self.data.get(target, {}).get(key)
            if hit:
                hit[2] = int(time.time())
                return hit[1], hit[0]
        return None

    def put(self, target, key, source, translation):
        """Remember one sentence. Outgoing requests (source ">") are not kept.
        When the store outgrows its limit the least recently used tenth is
        evicted in one pass, so eviction does not run on every insert."""
        if not key or source == ">":
            return
        with self.lock:
            store = self.data.setdefault(target, {})
            store[key] = [source, translation, int(time.time())]
            if len(store) > self.limit:
                excess = len(store) - int(self.limit * 0.9)
                for old in sorted(store, key=lambda k: store[k][2])[:excess]:
                    del store[old]
            self.dirty = True

    def count(self):
        with self.lock:
            return sum(len(v) for v in self.data.values())

    def save(self, force=False):
        """Write the memory to disk when it changed (or when forced).
        Returns True when a file was written. A locked or unwritable file
        (antivirus scan, cloud sync) is reported and tried again next time."""
        with self.lock:
            if not self.dirty and not force:
                return False
            try:
                folder = os.path.dirname(self.path)
                if folder:
                    os.makedirs(folder, exist_ok=True)
                tmp = self.path + ".tmp"
                with open(tmp, "w", encoding="utf-8") as fh:
                    json.dump(self.data, fh, ensure_ascii=False)
                os.replace(tmp, self.path)
            except OSError as exc:
                print(f"  could not save the memory to {self.path}: {exc}")
                return False
            self.dirty = False
            return True

    def write_learned(self, addon_dir):
        """Rewrite <addon>/Learned.lua from the memory."""
        path = os.path.join(addon_dir, "Learned.lua")
        if not os.path.isdir(addon_dir):
            return False
        lines = [
            f"-- {ADDON} / Learned.lua",
            "-- Translation memory, written by the companion. Loaded at login and /reload.",
            f"if not {ADDON} or not {ADDON}.Learn then return end",
        ]
        with self.lock:
            for target, store in sorted(self.data.items()):
                items = [(k, v) for k, v in store.items() if v[1] != ""]
                items.sort(key=lambda kv: -kv[1][2])
                for start in range(0, len(items), 400):
                    lines.append(f"{ADDON}:Learn({lua_str(target)}, {{")
                    for key, (source, translation, _) in items[start:start + 400]:
                        lines.append("{" + ",".join((lua_str(source), lua_str(key), lua_str(translation))) + "},")
                    lines.append("})")
        return atomic_write(path, "\n".join(lines) + "\n")


def atomic_write(path, content, attempts=4):
    """Write content to path through a temporary file and an atomic replace,
    retrying briefly when the game has the file open. Callers that may write
    the same path from several threads must serialise their calls."""
    tmp = path + ".tmp"
    for _ in range(attempts):
        try:
            with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(content)
            os.replace(tmp, path)
            return True
        except PermissionError:
            time.sleep(0.03)  # the game is reading the file right now
        except OSError:
            return False
    return False


# ----------------------------------------------------------------------------
# The live bridge: a ring of load-on-demand "slot" addons
# ----------------------------------------------------------------------------

class SlotRing:
    """The ring of slot addons. Slot k holds what the addon should learn if it
    loads a slot at a wall-clock second s with s % count == k.

    Two threads write slots: the log follower (add) and the heartbeat
    (heartbeat), and both may pick the same slot, so file writes are
    serialised with write_lock."""

    def __init__(self, addons_dir, backend_name, target, keep_seconds=150, max_items=80):
        self.addons_dir, self.backend_name, self.target = addons_dir, backend_name, target
        self.keep, self.max_items = keep_seconds, max_items
        self.items = collections.deque()   # (time, [src, key, translation, target or None])
        self.lock = threading.Lock()        # guards items
        self.write_lock = threading.Lock()  # guards the slot files
        self.count = 0
        while os.path.isdir(os.path.join(addons_dir, f"{SLOT_PREFIX}{self.count:03d}")):
            self.count += 1
        self.failed = 0

    def add(self, source, key, translation, target=None):
        """Publish one translation: it goes into the next few seconds' slots,
        since the addon may pull any moment now."""
        with self.lock:
            self.items.append((time.time(), [source, key, translation, target]))
        now = int(time.time())
        for offset in range(0, 4):
            self.write(now + offset)

    def _content(self, slot, beat):
        cutoff = time.time() - self.keep
        with self.lock:
            while self.items and self.items[0][0] < cutoff:
                self.items.popleft()
            recent = [item for _, item in self.items][-self.max_items:]
        rows = []
        for source, key, translation, target in recent:
            fields = [lua_str(source), lua_str(key), lua_str(translation)]
            if target and target != self.target:
                fields.append(lua_str(target))
            rows.append("{" + ",".join(fields) + "},")
        return (f"if {ADDON} and {ADDON}.Bridge then {ADDON}.Bridge:Receive({slot}, {beat}, "
                f"{lua_str(self.backend_name)}, {lua_str(self.target)}, {{\n" + "\n".join(rows) + "\n}) end\n")

    def write(self, second):
        """Write the slot file for the given wall-clock second. Returns True
        when the file was written."""
        if self.count == 0:
            return False
        slot = second % self.count
        path = os.path.join(self.addons_dir, f"{SLOT_PREFIX}{slot:03d}", "data.lua")
        content = self._content(slot, int(time.time()))
        with self.write_lock:
            ok = atomic_write(path, content)
        if not ok:
            self.failed += 1
        return ok

    def heartbeat(self):
        """Call about once a second: prepares the slot two seconds ahead."""
        self.write(int(time.time()) + 2)


def game_running():
    """Is a WoW client process running? Any executable whose name starts with
    "wow" counts (Wow.exe, WowT.exe, WowClassic.exe, Wow-64.exe). On a
    platform without tasklist, or when the check fails, the game is assumed
    to be running so that the slots stay fresh."""
    if sys.platform != "win32":
        return True
    try:
        flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
        out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq wow*", "/NH"], capture_output=True,
                             text=True, timeout=5, creationflags=flags).stdout
        return any(line.strip().lower().startswith("wow") for line in out.splitlines())
    except Exception:
        return True


# ----------------------------------------------------------------------------
# Chat log
# ----------------------------------------------------------------------------
LINE_RE = re.compile(r"^(?P<date>\d{1,2}/\d{1,2})\s+(?P<time>\d{1,2}:\d{2}:\d{2}\.\d{3})\s+(?P<body>.*)$")
CHAN_RE = re.compile(r"^\[(?P<chan>[^\]]+)\]\s+(?P<name>[^:]+?):\s*(?P<msg>.*)$")
SAY_RE = re.compile(r"^(?P<name>\S+)\s+(?P<verb>says|yells|whispers):\s*(?P<msg>.*)$")
OWN_RE = re.compile(r"^To (?P<name>\S+):\s*(?P<msg>.*)$")
REQUEST_RE = re.compile(r"^\[CT>(?P<lang>[A-Za-z]{2})\]\s*(?P<text>.+)$")


def tail(path, poll=0.15, from_start=False, stop=None):
    """Yield new lines appended to the file; survives truncation and rotation.

    Only lines written from now on count. A log that does not exist yet is
    read from its first line once the game creates it."""
    pos = 0
    if not from_start:
        try:
            pos = os.path.getsize(path)
        except OSError:
            pos = 0
    while not (stop and stop.is_set()):
        try:
            with open(path, "rb") as fh:
                fh.seek(pos)
                buffer = b""
                while not (stop and stop.is_set()):
                    chunk = fh.readline()
                    if chunk:
                        buffer += chunk
                        if buffer.endswith(b"\n"):
                            pos = fh.tell()
                            yield buffer.decode("utf-8", errors="replace").rstrip("\r\n")
                            buffer = b""
                    else:
                        time.sleep(poll)
                        try:
                            if os.path.getsize(path) < pos:   # truncated or replaced
                                pos = 0
                                break
                        except OSError:
                            pos = 0
                            break
        except OSError:
            time.sleep(0.5)


def parse_line(raw):
    """Return (channel, name, message) or None. Channel 'To' is the player's own whisper."""
    m = LINE_RE.match(raw)
    if not m:
        return None
    body = m.group("body").strip()
    m2 = CHAN_RE.match(body)
    if m2:
        chan = re.sub(r"^\d+\.\s*", "", m2.group("chan"))
        return chan, plain_text(m2.group("name")).strip(), m2.group("msg")
    m3 = SAY_RE.match(body)
    if m3:
        chan = {"says": "Say", "yells": "Yell", "whispers": "Whisper"}[m3.group("verb")]
        return chan, plain_text(m3.group("name")).strip(), m3.group("msg")
    m4 = OWN_RE.match(body)
    if m4:
        return "To", m4.group("name"), m4.group("msg")
    return None


# ----------------------------------------------------------------------------
# Optional overlay window (useful in dungeons and raids, where the game hides
# chat from addons and the in-frame translation cannot work)
# ----------------------------------------------------------------------------
CHANNEL_COLORS = {
    "say": "#ffffff", "yell": "#ff3f40", "whisper": "#ff80ff", "party": "#aaaaff",
    "raid": "#ff7f00", "guild": "#40ff40", "officer": "#40c040", "default": "#ffc0c0",
}


class Overlay:
    def __init__(self, args):
        import tkinter as tk
        import tkinter.font as tkfont
        self.root = tk.Tk()
        self.root.title(ADDON + " companion")
        self.root.overrideredirect(True)
        self.root.attributes("-topmost", True)
        self.root.attributes("-alpha", args.opacity)
        self.root.geometry(f"{args.width}x{args.height}+{args.x}+{args.y}")
        self.root.configure(bg="#0c0c14")
        bar = tk.Frame(self.root, bg="#1b1b2a", height=18, cursor="fleur")
        bar.pack(fill="x", side="top")
        title = tk.Label(bar, text=f"  {ADDON}  (drag to move, double-click to hide this bar, right-click to quit)",
                         bg="#1b1b2a", fg="#9ad0ff", font=("Segoe UI", 8))
        title.pack(side="left")
        for w in (bar, title):
            w.bind("<ButtonPress-1>", self._start_move)
            w.bind("<B1-Motion>", self._do_move)
            w.bind("<Double-Button-1>", lambda e: bar.pack_forget())
            w.bind("<Button-3>", lambda e: self.root.destroy())
        self.text = tk.Text(self.root, bg="#0c0c14", fg="#e0e0e0", bd=0, highlightthickness=0, wrap="word",
                            font=tkfont.Font(family="Segoe UI", size=args.font_size), state="disabled", padx=6, pady=4)
        self.text.pack(fill="both", expand=True)
        for chan, color in CHANNEL_COLORS.items():
            self.text.tag_configure("chan_" + chan, foreground=color)
        self.text.tag_configure("name", foreground="#ffd27f")
        self.text.tag_configure("lang", foreground="#6fb6ff")
        if args.click_through and sys.platform == "win32":
            self.root.after(200, self._click_through)

    def _start_move(self, e):
        self._dx, self._dy = e.x_root - self.root.winfo_x(), e.y_root - self.root.winfo_y()

    def _do_move(self, e):
        self.root.geometry(f"+{e.x_root - self._dx}+{e.y_root - self._dy}")

    def _click_through(self):
        """Let mouse clicks pass through the window (Windows only)."""
        GWL_EXSTYLE = -20
        WS_EX_TRANSPARENT = 0x20
        WS_EX_LAYERED = 0x80000
        try:
            import ctypes
            hwnd = ctypes.windll.user32.GetParent(self.root.winfo_id())
            style = ctypes.windll.user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
            ctypes.windll.user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style | WS_EX_LAYERED | WS_EX_TRANSPARENT)
        except Exception as exc:
            print("click-through not available:", exc)

    def add(self, chan, name, src, translated):
        t = self.text
        t.configure(state="normal")
        tag = "chan_" + chan.lower().replace(" ", "")
        if tag not in t.tag_names():
            tag = "chan_default"
        t.insert("end", f"[{chan}] ", tag)
        t.insert("end", name, "name")
        t.insert("end", f" ({src}): ", "lang")
        t.insert("end", translated + "\n", tag)
        lines = int(t.index("end-1c").split(".")[0])
        if lines > 300:
            t.delete("1.0", f"{lines - 300}.0")
        t.see("end")
        t.configure(state="disabled")

    def run(self, q):
        def pump():
            try:
                while True:
                    self.add(*q.get_nowait())
            except queue.Empty:
                pass
            self.root.after(150, pump)
        self.root.after(100, pump)
        self.root.mainloop()


# ----------------------------------------------------------------------------
# The engine
# ----------------------------------------------------------------------------

class Companion:
    def __init__(self, args, backend, out_queue=None):
        self.args, self.backend, self.out = args, backend, out_queue
        self.target = args.target
        self.me = {n.lower() for n in args.me}
        self.addons_dir = args.addons or os.path.join(args.wow, "Interface", "AddOns")
        self.addon_dir = os.path.join(self.addons_dir, ADDON)
        self.log_path = args.log or os.path.join(args.wow, "Logs", "WoWChatLog.txt")
        self.memory = Memory(args.memory or default_memory_path())
        self.ring = SlotRing(self.addons_dir, backend.name, self.target)
        self.stop = threading.Event()
        self.translated = self.failed = 0
        self.backoff_until = 0
        self.backoff_delay = 20
        self.last_calls = collections.deque(maxlen=4)
        self.recent_requests = {}
        self.skipped_old = 0

    # The game buffers its chat log and writes it out in bursts (the addon asks
    # for a flush when a line is waiting). The first burst after login carries
    # everything said since login; nobody is waiting for those lines any more,
    # and translating them all at once gets the companion rate-limited.
    MAX_LINE_AGE = 60.0

    def line_age(self, raw):
        """Seconds since the line was written, or None when the stamp is unreadable."""
        m = LINE_RE.match(raw)
        if not m:
            return None
        try:
            now = time.localtime()
            month, day = (int(x) for x in m.group("date").split("/"))
            hh, mm, rest = m.group("time").split(":")
            ss = float(rest)
            year = now.tm_year
            stamp = time.mktime((year, month, day, int(hh), int(mm), int(ss), 0, 0, -1))
            if stamp - time.time() > 86400:          # a log line from last year
                stamp = time.mktime((year - 1, month, day, int(hh), int(mm), int(ss), 0, 0, -1))
            return time.time() - stamp
        except (ValueError, OverflowError):
            return None

    # -- translation --------------------------------------------------------
    def _call_backend(self, text, target):
        """One throttled call to the translation service: at most about two
        requests a second, and a pause that doubles (20 s up to 5 minutes)
        each time the service rate-limits us. Returns (translated, detected
        source) or None when the call was skipped or failed."""
        now = time.time()
        if now < self.backoff_until:
            return None
        if len(self.last_calls) == self.last_calls.maxlen and now - self.last_calls[0] < 2.0:
            time.sleep(2.0 - (now - self.last_calls[0]))
        self.last_calls.append(time.time())
        try:
            result = self.backend.translate(text, target)
        except RateLimited:
            self.backoff_until = time.time() + self.backoff_delay
            print(f"  translation service is rate-limiting; pausing {self.backoff_delay} s (the addon falls back to its dictionaries)")
            self.backoff_delay = min(self.backoff_delay * 2, 300)
            return None
        except Exception as exc:
            self.failed += 1
            print(f"  translate failed: {exc}")
            return None
        self.backoff_delay = 20
        return result

    def translate(self, text, target):
        """Translate an incoming chat line into the target language.
        Returns (translation, source, publish) or None; translation '' means
        the line is already in the target language, publish False means the
        result is not worth a slot entry."""
        plain = plain_text(text).strip()
        key = loose_key(plain)
        if not key:
            return None
        hit = self.memory.get(target, key)
        if hit:
            return hit[0], hit[1], True
        if target == "en" and clearly_english(plain):
            return "", "en", False
        if script_language(plain) == target:
            return "", target, False
        result = self._call_backend(plain, target)
        if result is None:
            return None
        translated, detected = result
        source = short_code(detected) if detected else (script_language(plain) or "?")
        translated = (translated or "").strip()
        if source == target or loose_key(translated) == key:
            translated = ""
        self.memory.put(target, key, source, translated)
        self.translated += 1
        return translated, source, True

    # -- one chat line ------------------------------------------------------
    def handle(self, raw):
        parsed = parse_line(raw)
        if not parsed:
            return
        age = self.line_age(raw)
        if age is not None and age > self.MAX_LINE_AGE:
            self.skipped_old += 1
            if self.skipped_old == 1:
                print(f"  skipping chat lines the game buffered more than {int(self.MAX_LINE_AGE)} s ago")
            return
        chan, name, msg = parsed
        request = REQUEST_RE.match(plain_text(msg).strip())
        if request:
            # The player asked for their own text to be translated (/tsay es
            # hello). The addon sends that as a whisper to the player's own
            # character, which the log records as "To <name>: ..." and again
            # as an incoming whisper. Only the outgoing copy is trusted: a
            # request-shaped whisper from another player must never spend
            # our translation quota or publish an "outgoing" entry.
            if chan == "To":
                lang, text = request.group("lang").lower(), request.group("text").strip()
                stamp = self.recent_requests.get((lang, text), 0)
                if time.time() - stamp < 10:
                    return
                self.recent_requests[(lang, text)] = time.time()
                if len(self.recent_requests) > 200:
                    self.recent_requests.clear()
                result = self.translate_outgoing(text, lang)
                if result:
                    self.ring.add(">", loose_key(text), result, lang)
                    print(f"  you ({lang}): {result}")
            return
        if chan == "To" or not msg.strip():
            return
        if name.split("-")[0].lower() in self.me:
            return
        if self.args.channels and chan.lower() not in self.args.channels:
            return
        result = self.translate(msg, self.target)
        if result is None:
            return
        translated, source, publish = result
        if publish:
            self.ring.add(source, loose_key(msg), translated)
        if translated:
            print(f"  [{chan}] {name} ({source}): {translated}")
            if self.out is not None:
                self.out.put((chan, name, source, translated))

    def translate_outgoing(self, text, lang):
        """Translate the player's own text into lang, through the same
        throttling as incoming lines. Returns the translation or None."""
        result = self._call_backend(text, lang)
        if result is None:
            return None
        translated, _ = result
        return (translated or "").strip() or None

    # -- threads ------------------------------------------------------------
    def follow_log(self):
        for raw in tail(self.log_path, from_start=self.args.from_start, stop=self.stop):
            try:
                self.handle(raw)
            except Exception as exc:
                print(f"  error on a chat line: {exc}")

    def keep_alive(self):
        running, checked, saved = True, 0.0, time.time()
        while not self.stop.is_set():
            now = time.time()
            if now - checked > 20:
                running, checked = game_running(), now
            if running or self.args.always:
                self.ring.heartbeat()
            if now - saved > 60:
                saved = now
                if self.memory.save():
                    self.memory.write_learned(self.addon_dir)
            time.sleep(1.0 - (time.time() % 1.0) + 0.02)   # just after each second starts

    def start(self):
        print(f"{ADDON} companion  |  backend: {self.backend.name}  |  translating into: {self.target}")
        print(f"  chat log : {self.log_path}" + ("" if os.path.exists(self.log_path) else
              "   (not there yet: it appears once chat logging is on and someone speaks)"))
        if self.ring.count:
            print(f"  live     : {self.ring.count} slots in {self.addons_dir}")
        else:
            print(f"  live     : no slot addons found in {self.addons_dir}; only the memory and the overlay will work")
        print(f"  memory   : {self.memory.count()} sentences ({self.memory.path})")
        self.memory.save(force=True)
        self.memory.write_learned(self.addon_dir)
        threads = [threading.Thread(target=self.follow_log, daemon=True, name="chat log"),
                   threading.Thread(target=self.keep_alive, daemon=True, name="heartbeat")]
        for t in threads:
            t.start()
        return threads

    def close(self):
        """Stop the threads and write the memory and Learned.lua one last time."""
        self.stop.set()
        self.memory.save()
        self.memory.write_learned(self.addon_dir)
        if self.ring.failed:
            print(f"  {self.ring.failed} slot file write(s) failed this session (the game had the file open)")
        print(f"  translated {self.translated} line(s), {self.failed} failed")


def default_memory_path():
    base = os.environ.get("APPDATA") or os.path.expanduser("~")
    return os.path.join(base, ADDON, "memory.json")


def build_parser():
    ap = argparse.ArgumentParser(description=ADDON + " companion: live machine translation for WoW chat")
    ap.add_argument("--wow", default=DEFAULT_WOW, help="WoW flavour folder (default: %(default)s)")
    ap.add_argument("--addons", help="AddOns folder (default: <wow>\\Interface\\AddOns)")
    ap.add_argument("--log", help="chat log file (default: <wow>\\Logs\\WoWChatLog.txt)")
    ap.add_argument("--memory", help="where the translation memory is kept (default: %%APPDATA%%\\" + ADDON + ")")
    ap.add_argument("--target", default="en", help="language to translate into (default en)")
    ap.add_argument("--backend", choices=sorted(BACKENDS), default="google")
    ap.add_argument("--url", help="LibreTranslate server url (libre backend)")
    ap.add_argument("--key", help="API key (deepl / libre)")
    ap.add_argument("--source", help="source language for argos when it cannot be detected")
    ap.add_argument("--me", action="append", default=[], help="your character name(s); repeatable")
    ap.add_argument("--channels", default="", help="only these channels, e.g. say,trade,general,guild (default all)")
    ap.add_argument("--from-start", action="store_true", help="process the whole existing log, not only new lines")
    ap.add_argument("--always", action="store_true", help="keep the slots fresh even when the game is not running")
    ap.add_argument("--overlay", action="store_true", help="also show translations in an always-on-top window")
    ap.add_argument("--x", type=int, default=40, help="overlay window position, pixels from the left (default %(default)s)")
    ap.add_argument("--y", type=int, default=600, help="overlay window position, pixels from the top (default %(default)s)")
    ap.add_argument("--width", type=int, default=560, help="overlay window width (default %(default)s)")
    ap.add_argument("--height", type=int, default=260, help="overlay window height (default %(default)s)")
    ap.add_argument("--opacity", type=float, default=0.88, help="overlay opacity 0..1 (default %(default)s)")
    ap.add_argument("--font-size", type=int, default=10, help="overlay font size (default %(default)s)")
    ap.add_argument("--click-through", action="store_true", help="mouse clicks pass through the overlay (Windows)")
    return ap


def main(argv=None):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    args = build_parser().parse_args(argv)
    args.channels = {c.strip().lower() for c in args.channels.split(",") if c.strip()}
    target = short_code(args.target)
    if target == "?":
        raise SystemExit(f"--target must be a two-letter language code such as en, de or fr (got {args.target!r})")
    args.target = target
    backend = BACKENDS[args.backend](url=args.url, key=args.key, source=args.source)
    out_queue = queue.Queue() if args.overlay else None
    companion = Companion(args, backend, out_queue)
    threads = companion.start()
    try:
        if args.overlay:
            Overlay(args).run(out_queue)
        else:
            print("  running. Leave this window open while you play; close it or press Ctrl+C to stop.")
            while all(t.is_alive() for t in threads):
                time.sleep(0.5)
            for t in threads:
                if not t.is_alive():
                    print(f"  the {t.name} thread stopped unexpectedly; shutting down")
    except KeyboardInterrupt:
        pass
    finally:
        companion.close()


if __name__ == "__main__":
    main()
