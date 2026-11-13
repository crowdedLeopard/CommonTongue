"""The addon (Lua) and the companion (Python) must compute the same loose key
for every chat line. Compare them on awkward input and on random text."""
import importlib.util, os, random, sys
ROOT = sys.argv[3]
comp_file = [f for f in os.listdir(os.path.join(ROOT, "Companion")) if f.endswith("companion.py")][0]
spec = importlib.util.spec_from_file_location("companion", os.path.join(ROOT, "Companion", comp_file))
comp = importlib.util.module_from_spec(spec); spec.loader.exec_module(comp)

lua_key = B.Text.LooseKey
samples = [
    "Hola, ¿ALGUIEN me ayuda?",
    "ÑANDÚ Über STRASSE ÉCOLE Çà et là",
    "ПРИВЕТ, Ёжик! Ищу ГРУППУ",
    "İstanbul IŞIK ığdır ŞİŞLİ",
    "ΚΑΛΗΜΕΡΑ Άνθρωπος",
    "求组死亡矿井，来个坦克！",
    "タンク募集してます。ヒーラーも",
    "탱커 구합니다!! ㅋㅋㅋ",
    "vendo |cff1eff00|Hitem:2592::::::::60:::::|h[Wool Cloth]|h|r barato, 2g c/u",
    "{rt1} go {skull} kill |TInterface\\Icons\\x:0|t now",
    "WTS [Thunderfury, Blessed Blade of the Windseeker] 5000g!!!",
    "it's 20:30... don't—stop “quotes” ‘single’ 1.5k",
    "emoji 😀 test ★ ♥ → ok",
    "Łódź ŻÓŁĆ Čeština Ďábel Ő Ű",
    "   spaces   and\ttabs  ",
    "|cffff0000red|r |Hplayer:Bob|h[Bob]|h says hi|n new line",
    "Ǆ ǅ Ȁ Ȑ Ⱥ ẞ Ѐ Ѝ Ӏ Ԁ",
    "ｆｕｌｌｗｉｄｔｈ ＡＢＣ １２３",
    "",
]
random.seed(7)
pool = [chr(c) for c in list(range(32, 127)) + list(range(0xA1, 0x250)) + list(range(0x370, 0x530))
        + list(range(0x3040, 0x3100)) + list(range(0x4E00, 0x4E80)) + list(range(0xAC00, 0xAC80))
        + [0x2019, 0x2018, 0x201C, 0x2026, 0x3002, 0xFF0C, 0x1F600]]
for _ in range(3000):
    samples.append("".join(random.choice(pool) for _ in range(random.randint(1, 40))))

bad = 0
for s in samples:
    a, b = lua_key(s), comp.loose_key(s)
    if a != b:
        bad += 1
        if bad <= 8:
            print("MISMATCH", repr(s)); print("   lua:", repr(a)); print("   py :", repr(b))
print(f"{len(samples)} samples, {bad} mismatches")
for s in samples[:10]:
    print("  ", repr(s[:50]), "->", repr(comp.loose_key(s)[:60]))
