# CommonTongue for World of Warcraft: Forever

Translates chat written in other languages into yours, inside the game's own chat frame. It works the moment it is installed, and it gets better the longer you use it.

## How it translates

Every incoming chat line goes through the best method available, in this order:

| | Method | Quality | Needs |
|---|---|---|---|
| 1 | **Translation memory.** Sentences that were machine-translated before are answered instantly. Chat is repetitive, so this covers more every day. | Machine translation | Nothing at play time. The memory is filled by the companion. |
| 2 | **Live bridge.** A new sentence in another language is shown at once; a second or so later its machine translation is added to the same chat line, in green. Works for any language the translation service knows, not only the 18 with dictionaries. | Machine translation | The companion program running. |
| 3 | **Built-in engine.** Sentence templates ("busco grupo para …" → "looking for group for …"), a phrase table, verb conjugation, object pronouns and word reordering, for 18 languages. Shown in blue. | Readable, often fluent for typical game chat | Nothing. This is what you get with only the addon installed. |

Green means a real translation service produced it; blue means the addon worked it out by itself.

Languages with built-in support: English, Spanish, Portuguese, German, French, Italian, Dutch, Swedish, Norwegian, Danish, Finnish, Polish, Turkish, Russian, Ukrainian, Chinese, Korean, Japanese.

## Install

Run the installer from this folder:

```bash
python install.py
```

It copies the addon into `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns` and creates the live translation slots next to it (see "How the live bridge works"). Pass `--wow "<folder>"` if your game is elsewhere, `--slots 0` if you only want the built-in engine, `--uninstall` to remove everything.

Without Python you can copy the `CommonTongue` folder into `Interface\AddOns` by hand. That gives you the built-in engine and the translation memory, but not the live bridge.

Then start the game, or type `/reload`. You'll see one line in chat: *CommonTongue: ready.*

## Live machine translation

Start the companion and leave its window open while you play:

```bash
python Companion\commontongue_companion.py --me Yourcharactername
```

or double-click `Start Companion.bat`. In the game, type `/tongue live` once to check the connection. It answers with "live translation is connected" and the number of slots left.

From then on a foreign chat line looks like this, the green part arriving a moment after the line:

```
[2. Trade] Pedro: vendo 20 pociones de mana a 5 de plata [es>en: I sell 20 mana potions at 5 silver]
```

Everything the companion translates is also remembered. It writes the memory into the addon folder, so at your next login those sentences are translated instantly, with or without the companion.

Translation services (`--backend`):

| Backend | Setup | Notes |
|---|---|---|
| `google` (default) | none | Google's free keyless endpoint. Unofficial, so heavy use can be rate-limited; the addon then falls back to its own engine. Chat lines that are not in your language are sent to Google. |
| `argos` | `pip install argostranslate`, then `argospm install translate-es_en` per language pair | Fully offline on your PC. Nothing leaves your machine, no limits. Add `pip install langdetect` for automatic language detection. |
| `libre --url http://…` | a LibreTranslate server | Open source, self-hostable. |
| `deepl --key …` | free DeepL API key | Best quality for European languages. |

Other options: `--target de` to translate into another language, `--channels say,trade,general,guild` to limit what is translated, `--overlay` to also show translations in an always-on-top window.

### How the live bridge works

An addon cannot open a network connection or read a file. It can load another addon on demand, and a load-on-demand addon is read from disk at the moment it is loaded. The installer creates 200 tiny "slot" addons. The companion follows the game's chat log, translates, and keeps the slots up to date; when a chat line needs a translation, the addon loads the slot that belongs to the current second and receives it. The translation is then added to the chat line that is already on screen.

Things to know:

- Each slot can be loaded once per session, so there are 200 live fetches between reloads. Repeated sentences come from memory and cost nothing. When the slots run out, the addon says so and uses its own engine; `/reload` refills them.
- The slots appear in the game's AddOn list under their own category, which you can collapse. Leave them enabled.
- Chat logging is switched on automatically, because the chat log is how the companion sees the chat. The file is `_forever_\Logs\WoWChatLog.txt`; you can delete it whenever you like.
- **Dungeons, raids and PvP matches:** the game hides chat text from all addons there (the "secret values" restriction Forever inherits from the modern client), so nothing can be translated inside the chat frame. Start the companion with `--overlay` to see translations in a separate window in those places; run the game in windowed or borderless mode so the window is visible.

## Speak another language

| Command | Example |
|---|---|
| `/tsay <lang> <text>` | `/tsay es hello, I need a tank for the dungeon` |
| `/tyell`, `/tparty`, `/traid`, `/tguild` | same, in that channel |
| `/twhisper <player> <lang> <text>` | whisper someone in their language |
| `/tprev <lang> <text>` | preview only |

With the companion running, your text is machine-translated and placed in the chat box for you to check and send with Enter. Without it, the built-in engine translates and sends directly.

## Options

`/tongue` opens the options panel (also under Esc → Options → AddOns).

| Command | Effect |
|---|---|
| `/tongue on` / `off` | enable or disable |
| `/tongue to de` | translate into another language |
| `/tongue mode inline` / `below` / `replace` | where the translation goes |
| `/tongue tag off` | hide the `[es>en]` tag |
| `/tongue self on` | translate your own messages too |
| `/tongue min 50` | only show a built-in translation when at least 50% of the words were understood (default 34%) |
| `/tongue chan trade off` | stop translating a channel |
| `/tongue ignore fr` | never translate a language |
| `/tongue live` / `live off` | reconnect to the companion and show status / turn the live bridge off |
| `/tongue teach es mazmorra = dungeon` | add your own word or phrase; it wins over the shipped dictionary |
| `/tongue missing es` | the words the Spanish dictionary did not know, most frequent first |
| `/tongue test <text>` | see what the addon makes of some text |
| `/tongue status` | settings, memory size, bridge state |

## The built-in engine, briefly

Each language has a dictionary (`Dict\xx.lua`) and a grammar file (`Grammar\xx.lua`), both plain text:

```
busco grupo | busco party = looking for group | lfg              (phrase table)
busco grupo para * = looking for group for *                     (sentence template; * is translated on its own)
matar = kill          amos > ar = we %s        ó > ar = %ed      (verb + conjugation rules: "matamos", "mató")
lo | la = it                                                      (object pronouns: "lo maté" → "I killed it")
```

Translation between two languages other than English pivots through English. The language of a line is decided by letting the candidate languages each try to explain it; the one that accounts for most of it wins, and English competes so that English lines are left alone. Accents may be missing, letters may be repeated for emphasis ("holaaaa"), and item links are kept intact.

## Blizzard's rules

The addon uses only the public addon API. The companion reads a log file the game writes on purpose and writes data files into the AddOns folder, which is how the TradeSkillMaster and WeakAuras companion apps work. It does not read game memory, inject key presses or read the screen, and it automates nothing in the game. Blizzard has not reviewed it; no companion app is officially approved.

## First-run check

The live bridge relies on three things I could verify in Blizzard's interface source for build 1.60.1 but not in a running game: that the chat log is written promptly (the addon asks the game to flush it if not), that a slot addon's file is read fresh when it is loaded, and that a whisper to yourself is logged (used for `/tsay`). `/tongue live` tells you whether the bridge is connected. If it is not, everything else still works: the built-in engine, and the translation memory after each `/reload`.

## For developers

`docs/ARCHITECTURE.md` explains how the addon works, `CONTRIBUTING.md` how to
change dictionaries or code and run the tests, `CHANGELOG.md` what changed,
and `tools/README.md` the developer tools. The addon's only globals are
`CommonTongue`, its saved variables and its slash commands.
