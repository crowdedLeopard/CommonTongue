# Unit tests with pass/fail assertions for every module of the addon.
#
#   python tools/tests/ct_dbg.py CommonTongue tools/tests/ct_unit.py
#
# Exits non-zero when any check fails. Each check names what it covers, so a
# failure points at the module and rule that broke.
import sys

L.execute("__fire('ADDON_LOADED', '%s'); __fire('PLAYER_LOGIN')" % NAME)
U, T, EN, Memory, Bridge = B.UTF8, B.Text, B.English, B.Memory, B.Bridge

passed, failed = 0, 0


def check(name, cond, got=None):
    global passed, failed
    if cond:
        passed += 1
    else:
        failed += 1
        print("FAIL %s%s" % (name, ("  (got %r)" % (got,)) if got is not None else ""))


def tup(r):
    return r if isinstance(r, tuple) else (r,)


def detect(text):
    return tup(B.DetectLanguage(B, text))[0]


def translate(text, src, dst="en"):
    return tup(B.TranslateText(B, text, src, dst))[0]


def process(text, author="Someone-Realm"):
    B.ClearCache(B)
    return B.Process(B, text, author, None)


def printed():
    return list(G.__printed.values())


# ---------------------------------------------------------------- UTF8
check("UTF8.Lower accents", U.Lower("ÉCOLE Ñandú") == "école ñandú", U.Lower("ÉCOLE Ñandú"))
check("UTF8.Lower cyrillic", U.Lower("ПРИВЕТ") == "привет", U.Lower("ПРИВЕТ"))
check("UTF8.UpperFirst", U.UpperFirst("école") == "École", U.UpperFirst("école"))
check("UTF8.IsUpperFirst", U.IsUpperFirst("Hola") and not U.IsUpperFirst("hola"))
check("UTF8.Normalize spacing", U.Normalize("  Hola   Mundo ") == "hola mundo", U.Normalize("  Hola   Mundo "))
check("UTF8.Normalize apostrophe", U.Normalize("don’t") == "don't", U.Normalize("don’t"))
check("UTF8.Normalize fast path identity", U.Normalize("hola mundo") == "hola mundo")
check("UTF8.Length", U.Length("héllo") == 5, U.Length("héllo"))
check("UTF8.Script han", U.Script(0x4E2D) == "han")
check("UTF8.Script digit", U.Script(ord("5")) is None)
stats = U.ScriptStats("abc привет")
check("UTF8.ScriptStats", stats["latin"] == 3 and stats["cyrillic"] == 6 and stats["total"] == 9, dict(stats))
segs = list(U.Segment("buy |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r now").values())
check("UTF8.Segment protects links", len(segs) == 5 and segs[1]["protected"] and segs[3]["protected"], [(s["text"], s["protected"]) for s in segs])

# ---------------------------------------------------------------- Text
check("Text.Fold", T.Fold("misión señor") == "mision senor", T.Fold("misión señor"))
sq = tup(T.Squeeze("holaaaa"))
check("Text.Squeeze runs of 3", sq[0] == "hola", sq)
check("Text.Squeeze keeps doubles first", tup(T.Squeeze("till"))[0] is None)
check("Text.LooseKey strips links and punctuation",
      T.LooseKey("Vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato, 2g!!") == "vendo wool cloth barato 2g",
      T.LooseKey("Vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato, 2g!!"))
check("Text.LooseKey emote", T.LooseKey("o/") == "o", T.LooseKey("o/"))
check("Text.PlainText", T.PlainText("|cffff0000red|r {skull} go") == "red  go", T.PlainText("|cffff0000red|r {skull} go"))
atoms = list(T.Atomize("Hola, 5g lvl60 1.5 peut-être")[0].values())
kinds = [a["kind"] for a in atoms]
check("Text.Atomize kinds", kinds == ["word", "clause", "mixed", "mixed", "num", "word", "word"], kinds)
check("Text.Atomize hyphen glue", atoms[6]["pre"] == "-", atoms[6]["pre"])
check("Text.Atomize cap flag", atoms[0]["cap"] is True and atoms[5]["cap"] is False)
check("Text.Relink", T.Relink("selling [Wool Cloth] cheap", "vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato")
      == "selling |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r cheap")

# ---------------------------------------------------------------- English
check("EN.Ing take", EN.Ing("take") == "taking", EN.Ing("take"))
check("EN.Ing stop", EN.Ing("stop") == "stopping", EN.Ing("stop"))
check("EN.Ing die", EN.Ing("die") == "dying", EN.Ing("die"))
check("EN.Ing phrase", EN.Ing("look for") == "looking for", EN.Ing("look for"))
check("EN.Past go", EN.Past("go") == "went")
check("EN.Past try", EN.Past("try") == "tried", EN.Past("try"))
check("EN.Part take", EN.Part("take") == "taken")
check("EN.S3 try", EN.S3("try") == "tries", EN.S3("try"))
check("EN.S3 have", EN.S3("have") == "has")
check("EN.Render", EN.Render("we %s", "play") == "we play" and EN.Render("%ing", "take") == "taking")
check("EN.Plural regular", EN.Plural("potion") == "potions")
check("EN.Plural irregular", EN.Plural("wolf") == "wolves")
check("EN.Plural phrase", EN.Plural("mana potion") == "mana potions", EN.Plural("mana potion"))
check("EN.IsNoun plural", EN.IsNoun("potions") is True and EN.IsNoun("quickly") is False)
check("EN.PostEdit modal to", EN.PostEdit("can to help me") == "can help me", EN.PostEdit("can to help me"))
check("EN.PostEdit keeps preposition", EN.PostEdit("have to to the vendor") == "have to to the vendor", EN.PostEdit("have to to the vendor"))
check("EN.PostEdit there are", EN.PostEdit("there is mobs") == "there are mobs", EN.PostEdit("there is mobs"))
check("EN.PostEdit an elite", EN.PostEdit("a elite mob") == "an elite mob", EN.PostEdit("a elite mob"))
check("EN.PostEdit a useless", EN.PostEdit("a useless thing") == "a useless thing", EN.PostEdit("a useless thing"))
check("EN.PostEdit an hour", EN.PostEdit("a hour") == "an hour", EN.PostEdit("a hour"))
check("EN.PostEdit capital I", EN.PostEdit("i think i can") == "I think I can", EN.PostEdit("i think i can"))
check("EN.PostEdit doesn't understands", EN.PostEdit("he doesn't understands") == "he doesn't understand", EN.PostEdit("he doesn't understands"))

# ---------------------------------------------------------------- Detect
check("Detect english", detect("LFG tank for SM") == "en", detect("LFG tank for SM"))
check("Detect spanish", detect("busco grupo para la mazmorra") == "es", detect("busco grupo para la mazmorra"))
check("Detect dutch", detect("ik hoop dat je een mooie dag hebt") == "nl", detect("ik hoop dat je een mooie dag hebt"))
check("Detect french", detect("je cherche un groupe pour le donjon") == "fr", detect("je cherche un groupe pour le donjon"))
check("Detect korean by script", detect("탱커 구합니다") == "ko")
check("Detect chinese by script", detect("求组死亡矿井") == "zh")
check("Detect russian", detect("ищу группу в подземелье") == "ru", detect("ищу группу в подземелье"))
check("Detect neutral shout is nothing", detect("JESUS CHRIST") is None, detect("JESUS CHRIST"))
check("Detect stretched neutral is nothing", detect("yoooooo") is None, detect("yoooooo"))
check("Detect numbers are nothing", detect("123 456") is None)

# ---------------------------------------------------------------- Engine
out = translate("busco grupo para la mazmorra", "es")
check("Engine template", "looking for group" in out.lower(), out)
out = translate("tengo pociones baratas", "es")
check("Engine adjective reorder", "cheap potions" in out.lower(), out)
out = translate("vendo pociones baratas", "es")
check("Engine trade template beats reorder", out.lower() == "selling potions cheap", out)
out = translate("lo maté", "es")
check("Engine clitic", out.lower().startswith("i killed it"), out)
out = translate("vends 2 épées 3po", "fr")
check("Engine glued currency", "3 gold" in out, out)
out = translate("holaaaa amigos", "es")
check("Engine de-emphasis", out.lower().startswith("hello"), out)
out = translate("les joueurs", "fr")
check("Engine plural keeps s", out.lower() == "the players", out)
out = translate("hello, I need a tank", "en", "es")
check("Engine reverse direction", "tanque" in out.lower(), out)
check("Engine same language", translate("whatever", "en", "en") == "whatever")
check("Engine unknown language", tup(B.TranslateText(B, "x", "xx", "en"))[0] is None)

# ---------------------------------------------------------------- Memory
B.Learn(B, "en", L.table(L.table("es", "frase de prueba", "test sentence")))
hit = tup(Memory.Lookup(Memory, "Frase de prueba!", "en", None))
check("Memory.Learn + Lookup", hit[0] == "test sentence" and hit[1] == "es", hit)
check("Memory.Lookup unknown", tup(Memory.Lookup(Memory, "nunca visto", "en", None))[0] is None)
res = process("Frase de prueba!")
check("Process uses memory (green)", res is not None and "8fe38f" in res and "test sentence" in res, res)

# ---------------------------------------------------------------- Core
check("Process skips emotes", process("o/") is None and process(":D") is None and process("y") is None)
check("Process leaves english alone", process("looking for a tank") is None)
res = process("hola alguien me ayuda con la mision?")
check("Process inline tag", res is not None and "[es>en:" in res, res)
check("Process cache hit", B.Process(B, "hola alguien me ayuda con la mision?", "Someone-Realm", None) == res)
B.HandleSlash(B, "mode replace")
res = process("hola alguien me ayuda con la mision?")
check("Process replace mode", res is not None and res.startswith("|cff7fd4ff") and "[es]" in res, res)
B.HandleSlash(B, "mode below")
res = process("hola alguien me ayuda con la mision?")
check("Process below mode", res is not None and "\n" in res, res)
B.HandleSlash(B, "mode inline")
B.HandleSlash(B, "tag off")
res = process("hola alguien me ayuda con la mision?")
check("Process tag off", res is not None and "es>en" not in res, res)
B.HandleSlash(B, "tag on")
B.HandleSlash(B, "min 100")
check("Process min coverage hides partial", process("hola xyzzyx plugh quux") is None)
B.HandleSlash(B, "min 34")
B.HandleSlash(B, "ignore es")
check("Process ignored language", process("hola alguien me ayuda con la mision?") is None)
B.HandleSlash(B, "ignore es")
n = len(printed())
B.HandleSlash(B, "nosuchcommand")
check("HandleSlash unknown prints help", any("commands:" in p for p in printed()[n:]))
n = len(printed())
B.HandleSlash(B, "status")
check("HandleSlash status shows version", any("v" + str(G.__tocVersion) in p for p in printed()[n:]), printed()[n:])
check("Bridge status without slots", "not installed" in Bridge.Status(Bridge))
check("Version comes from the TOC", B.Version == G.__tocVersion, B.Version)

# ---------------------------------------------------------------- Fuzzy
Fz = B.Fuzzy
MAP_PIN = "|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a Emplacement marqué sur la carte"


def fuzzy(lang, w):
    """What the fuzzy layer makes of a single word of that language."""
    Lg = B.Languages[lang]
    d = Lg.DirTo(Lg)
    atoms = tup(T.Atomize(w))[0]
    return tup(Fz.Word(d, atoms[1], True, L.table()))


def stats(text, lang):
    return tup(B.TranslateText(B, text, lang, "en"))[4]


cands = [(c[1], c[2]) for c in list(Fz.Candidates("minde").values())]
check("Fuzzy.Candidates swaps first", cands[0][1] == "swap", cands[:2])
check("Fuzzy.Candidates has the neighbouring key", ("monde", "subst") in cands)
check("Fuzzy.Candidates no dropped letter below six letters", all(k != "drop" for _, k in cands))
check("Fuzzy.Candidates drops a letter in longer words", any(k == "drop" for _, k in [(c[1], c[2]) for c in list(Fz.Candidates("tyrouve").values())]))
check("Fuzzy typo: dropped letter", fuzzy("fr", "tyrouve")[:2] == ("key", "trouve"), fuzzy("fr", "tyrouve"))
check("Fuzzy typo: doubled letter", fuzzy("fr", "paser")[:2] == ("key", "passer"), fuzzy("fr", "paser"))
check("Fuzzy typo: swapped letters", fuzzy("fr", "cherhce")[:2] == ("key", "cherche"), fuzzy("fr", "cherhce"))
check("Fuzzy typo keeps the first letter", fuzzy("nl", "demande")[0] is None, fuzzy("nl", "demande"))
check("Fuzzy apostrophe: dictionary key", fuzzy("fr", "cetait")[:2] == ("key", "c'etait"), fuzzy("fr", "cetait"))
check("Fuzzy apostrophe: pronoun + verb", fuzzy("fr", "jregarde")[:2] == ("value", "I look"), fuzzy("fr", "jregarde"))
check("Fuzzy respell k -> qu", fuzzy("fr", "kestion")[:2] == ("key", "question"), fuzzy("fr", "kestion"))
check("Fuzzy respell spanish", fuzzy("es", "aki")[:2] == ("key", "aqui"), fuzzy("es", "aki"))
check("Fuzzy respell german umlaut", fuzzy("de", "muede")[:2] == ("key", "mude"), fuzzy("de", "muede"))
check("Fuzzy compound", fuzzy("de", "heilergruppe")[:2] == ("value", "healer group"), fuzzy("de", "heilergruppe"))
check("Fuzzy compound with linking letter", fuzzy("nl", "groepsleider")[:2] == ("value", "group leader"), fuzzy("nl", "groepsleider"))
check("Fuzzy leaves a name alone", fuzzy("fr", "Kharanos")[0] is None or "Kharanos" in translate("je t'attends à Kharanos", "fr"))
out = translate("je cherhce un groupe pour la mine", "fr")
check("Fuzzy correction feeds the template", out.lower().startswith("i'm looking for a group"), out)
out = translate("du minde pour le donjon", "fr")
check("Fuzzy correction feeds the phrase", out.lower().startswith("people"), out)
check("Fuzzy counted in stats", stats("je cherhce un groupe", "fr")["fuzzy"] == 1)
check("Fuzzy never runs during detection", "cherhce" in (tup(B.DetectLanguage(B, "je cherhce un groupe pour la mine"))[2] or ""))
out = translate("ta map est down", "fr")
check("Engine passes English words through", out == "your map is down", out)
st = stats("ta map est down", "fr")
check("Engine English words count as neither hit nor miss", st["english"] == 2 and st["misses"] == 0 and st["hits"] == 2, dict(st))
out = translate("au revoiiiir aventurier", "fr")
check("Engine phrase with stretched letters", out.lower().startswith("bye"), out)
out = translate("wir spielten gestern zusammen", "de")
check("Engine conjugation rules indexed by last letter", "played" in out, out)
check("Text.Collapse", T.Collapse("Saluuuuut :)") == "Salut :)" and T.Collapse("hello") == "hello", T.Collapse("Saluuuuut :)"))
check("Text.PlainText strips atlas markup", T.PlainText(MAP_PIN) == " Emplacement marqué sur la carte", T.PlainText(MAP_PIN))
check("Detect map pin line is French", detect(MAP_PIN) == "fr", detect(MAP_PIN))
out = translate(MAP_PIN, "fr")
check("Engine map pin line", "location marked on the map" in out and out.startswith("|A:"), out)
check("Detect stretched letters are not hints", detect("Saluuuuuuuut :)") == "fr", detect("Saluuuuuuuut :)"))
check("Detect french function words", detect("la réserve volée de Tundra MacGrann") == "fr", detect("la réserve volée de Tundra MacGrann"))
check("Detect spanish still spanish", detect("la mina esta llena de mobs") == "es" and detect("busco grupo para la mazmorra de la muerte") == "es")
check("Detect english with french-looking words", detect("the quest is in the cave") == "en" and detect("i need to pass the door") == "en")

# ---------------------------------------------------------------- chat filter end to end
chat = G.__chat
shown = chat("CHAT_MSG_SAY", "busco grupo para la mazmorra")
check("Filter decorates a line", "[es>en:" in shown, shown)
shown = chat("CHAT_MSG_SAY", "LFG tank for SM")
check("Filter leaves english", shown == "LFG tank for SM", shown)
B.HandleSlash(B, "chan say off")
shown = chat("CHAT_MSG_SAY", "busco grupo para la mazmorra")
check("Filter respects channel setting", shown == "busco grupo para la mazmorra", shown)
B.HandleSlash(B, "chan say on")
shown = chat("CHAT_MSG_WHISPER", "[CT>es] hello")
check("Filter hides companion whispers", shown == "FILTERED", shown)

print("\nunit tests: %d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
