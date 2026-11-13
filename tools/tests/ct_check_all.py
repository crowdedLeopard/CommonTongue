"""Regression lines across languages, run through ct_dbg.py:
   ct_dbg.py <addon folder> ct_check_all.py
Prints detection + translation, and en->xx samples."""
LINES = [
    ("es", "busco grupo para minas de la muerte, falta tanque y sanador"),
    ("es", "vendo 20 pociones de mana a 5 de plata"),
    ("es", "ya mataron al jefe? yo lo maté ayer"),
    ("es", "encontraste la llave? no la encuentro"),
    ("es", "me voy a dormir, hasta mañana a todos"),
    ("pt", "procurando grupo pra deadmines, falta tank e healer, me chama"),
    ("pt", "alguém sabe onde fica a entrada da mina?"),
    ("de", "kann mir jemand bei der quest helfen? bin am eingang"),
    ("de", "ich muss erst zum händler"),
    ("de", "wir spielten gestern zusammen"),
    ("de", "wir haben den boss gelegt"),
    ("fr", "quelqu'un sait où est l'entrée de la mine ?"),
    ("fr", "cherche groupe pour les mortemines, manque un tank"),
    ("it", "cerco gruppo per le miniere, manca un tank"),
    ("nl", "zoek groep voor deadmines, tank nodig"),
    ("sv", "söker grupp till deadmines, saknar tank och healer"),
    ("no", "kan noen hjelpe meg med questen i vest?"),
    ("da", "kan nogen hjælpe mig med questen i vest?"),
    ("fi", "etsin ryhmää deadminesiin, tarvitaan tankki"),
    ("pl", "szukam grupy do kopalni, potrzebny tank"),
    ("tr", "grup arıyorum, tank lazım"),
    ("ru", "кто-нибудь знает где находится вход в Мародон?"),
    ("ru", "мы убили босса, идем дальше"),
    ("uk", "шукаю групу в ДМ, потрібен танк і хіл"),
    ("zh", "求组死亡矿井 来个坦克"),
    ("ja", "タンク募集してます"),
    ("ko", "탱커 구합니다"),
    ("en", "need 2 more for RFC, pst"),
    ("en", "WTS Arcanite Bar, Thorium Bar, Dense Stone"),
    ("en", "ok team lets go"),
    ("en", "anyone need a healer for the mine?"),
    ("en", "selling iron ore and silk, pst"),
    ("en", "nice one bro, that was ez"),
    ("en", "chill guys, the healer is afk for a sec"),
    ("en", "yo anyone up for a dungeon run? kinda cringe to solo it"),
    ("en", "ta mate, see you at the raid later x"),
    ("en", "lol no way, that mob one shot me again"),
]
bad = 0
for expect, text in LINES:
    r = B.DetectLanguage(B, text)
    r = r if isinstance(r, tuple) else (r,)
    lang = r[0]
    out = ""
    if lang and lang != "en":
        t = B.TranslateText(B, text, lang, "en", r[2] if len(r) > 2 else None, r[3] if len(r) > 3 else None)
        if t and not isinstance(t, tuple): t = (t,)
        out = f"{t[0]}   ({t[1]*100:.0f}%)" if t and t[0] else "(no dictionary)"
    have = B.Languages[expect] is not None
    flag = "ok " if lang == expect else ("-- " if not have else "BAD")
    if flag == "BAD": bad += 1
    print(f"{flag} [{lang or '--'}] {text}\n        {out}")
print()
for tgt in ["es", "de", "fr", "ru", "pl", "zh"]:
    if B.Languages[tgt] is None: continue
    for text in ["hello, I need a tank for the dungeon", "can anyone help me with the quest?", "selling 20 linen cloth for 2 gold"]:
        t = B.TranslateText(B, text, "en", tgt)
        t = t if isinstance(t, tuple) else (t,)
        print(f"en>{tgt}: {text}  ->  {t[0]}")
print("\nmisdetected:", bad)
