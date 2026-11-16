-- CommonTongue / Grammar/de.lua  —  German verbs, conjugation and sentence templates
local L = CommonTongue.Languages.de
if not L then return end

-- German has no object pronouns before the verb, so there is no Clitics block.

-- infinitive | pseudo-infinitive for a vowel-changed stem = English base verb
-- ("giben" does not exist; it lets "gibst" resolve to "geben". "sammlen" does the
-- same for "sammle".) Participles with ge- cannot be reached by suffix rules; the
-- common ones are in Dict/de.lua.
L:Verbs([==[
machen = do
gehen = go
kommen = come
geben | giben = give
nehmen | nimmen = take
sehen | siehen = see
schauen | gucken | kucken = look
finden = find
suchen = look for
brauchen | benötigen = need
kaufen = buy
verkaufen = sell
zahlen | bezahlen = pay
tauschen = trade
handeln | handlen = trade
warten = wait
laufen | läufen | rennen = run
töten | killen = kill
sterben | stirben = die
heilen | healen = heal
tanken = tank
farmen = farm
grinden = grind
looten | plündern = loot
pullen = pull
leveln | lvln | levlen = level
questen = quest
raiden = raid
porten | teleportieren = port
rezzen | rezen | ressen | wiederbeleben = res
buffen = buff
helfen | hilfen = help
folgen = follow
würfeln | würflen = roll
kicken = kick
joinen = join
gewinnen = win
verlieren = lose
öffnen = open
schließen = close
lassen | lässen = let
beginnen | starten = start
beenden = finish
versuchen | probieren = try
testen = test
denken = think
glauben = believe
meinen = mean
hoffen = hope
lieben = love
hassen = hate
spielen | zocken = play
bekommen | kriegen | holen = get
benutzen | nutzen | verwenden = use
lesen | liesen = read
schreiben = write
flüstern | wispern | whispern = whisper
sagen = say
fragen = ask
antworten = answer
erklären = explain
zeigen = show
bringen = bring
schicken | senden = send
bleiben = stay
passieren = happen
kennen = know
hören = hear
reden | sprechen | sprichen | quatschen | labern = talk
verstehen = understand
lernen = learn
vergessen | vergissen = forget
essen | issen = eat
trinken = drink
schlafen | schläfen | pennen = sleep
arbeiten = work
funktionieren | funzen | klappen = work
leben | wohnen = live
stehen = stand
sitzen = sit
fallen | fällen = fall
springen | hüpfen = jump
schwimmen = swim
tauchen = dive
klettern = climb
fliegen = fly
reiten = ride
fahren = drive
halten | hälen | hälten = hold
werfen | wirfen = throw
schlagen | hauen = hit
treffen | triffen = meet
angreifen | attackieren = attack
verteidigen | deffen = defend
schützen | beschützen = protect
kämpfen = fight
besiegen = defeat
zaubern | casten = cast
beschwören | summonen = summon
verzaubern | enchanten = enchant
herstellen | craften = craft
bauen = build
schmieden = forge
reparieren | reppen = repair
sammeln | sammlen = gather
fischen = fish
kochen = cook
kürschnern | häuten = skin
schürfen = mine
pflücken = pick
ändern | wechseln | wechslen = change
drücken = press
klicken = click
bewegen = move
drehen = turn
stoppen = stop
wählen = choose
zählen = count
melden | reporten = report
ignorieren = ignore
bannen = ban
löschen = delete
speichern = save
installieren = install
aktualisieren = update
reloggen | relogen = relog
erstellen | erschaffen = create
erkunden = explore
besuchen = visit
rufen = call
schreien = yell
lachen = laugh
heulen | weinen = cry
danken = thank
feiern = celebrate
stören = annoy
spammen = spam
trollen = troll
campen = camp
ganken = gank
stunnen = stun
sheepen = sheep
dispellen = dispel
blocken = block
droppen = drop
bieten = offer
leihen = lend
teilen = share
rekrutieren = recruit
schaffen = manage
skillen = skill
clearen = clear
]==])

-- suffix > infinitive ending = English template
L:Conjugation([==[
# present, verbs in -en
e > en = I %s
st > en = you %s
est > en = you %s
t > en = %s3
et > en = %s3
# present, verbs in -eln / -ern (leveln, sammeln, flüstern)
e > n = I %s
st > n = you %s
t > n = %s3
# simple past of weak verbs
te > en = %ed
test > en = you %ed
ten > en = %ed
tet > en = you %ed
ete > en = %ed
etest > en = you %ed
eten > en = %ed
te > n = %ed
test > n = you %ed
ten > n = %ed
# present participle
end > en = %ing
nd > n = %ing
]==])

-- Sentence templates. '*' is a slot of one or more words, translated on its own.
-- German puts infinitives and participles at the end of the clause, so most
-- templates here close with the verb: "kann mir jemand bei * helfen".
L:Patterns([==[
# ---- looking for group / people / guild ----
suche gruppe für * | suche grp für * | suche eine gruppe für * | suche ne gruppe für * | suche noch gruppe für * | sg für * = looking for group for *
suche gruppe nach * | suche gruppe zu * | suche gruppe ins * | suche anschluss für * | suche anschluss an gruppe für * = looking for group for *
suche * für * | suche noch * für * | such * für * = looking for * for *
suchen noch * für * | suchen * für * | wir suchen noch * für * | wir suchen * für * = looking for * for *
* für * gesucht = looking for * for *
wird noch * gesucht | werden noch * gesucht | es wird noch * gesucht | es werden noch * gesucht = still looking for *
wir brauchen noch * für * | brauchen noch * für * | wir brauchen * für * | brauchen * für * = we need * for *
wir brauchen noch * | brauchen noch * = we still need *
noch * für * = need * more for *
noch platz für * | haben noch platz für * | wir haben noch platz für * = still room for *
noch * minuten | noch * min = * more minutes
noch * sekunden | noch * sek = * more seconds
wer hat lust auf * | jemand lust auf * | hat jemand lust auf * | wer hat bock auf * | jemand bock auf * | hat jemand bock auf * | wer bock auf * = anyone up for *
lust auf * | bock auf * = up for *
wer will mit nach * | wer kommt mit nach * | wer will mit in * | wer kommt mit in * | wer will mit zu * = who wants to come to *
bin dabei bei * | bin bei * dabei | wäre bei * dabei | bin dabei für * = I'm in for *
gilde * rekrutiert | die gilde * rekrutiert | gilde * sucht mitglieder | gilde * sucht noch mitglieder | gilde * sucht verstärkung | gilde * nimmt noch auf = guild * is recruiting
gilde * sucht * | die gilde * sucht * | gilde * sucht noch * = guild * is looking for *
suche gilde für * | suche eine gilde für * | suche ne gilde für * = looking for a guild for *

# ---- does anyone know / have / sell ----
weiß jemand wo * ist | weiß wer wo * ist | weiß einer wo * ist | weiß jemand wo * sind | weiß jemand wo * steht | weiß jemand wo * liegt = does anyone know where * is
weiß jemand wo man * findet | weiß jemand wo man * bekommt | weiß jemand wo man * kriegt | weiß jemand wo es * gibt | weiß wer wo man * findet | weiß wer wo es * gibt = does anyone know where to find *
weiß jemand wo man * kaufen kann | weiß wer wo man * kaufen kann | weiß jemand wo ich * kaufen kann = does anyone know where to buy *
weiß jemand wie man * macht | weiß wer wie man * macht | weiß einer wie man * macht = does anyone know how to do *
weiß jemand wie man nach * kommt | weiß jemand wie man zu * kommt | weiß wer wie man nach * kommt | weiß jemand wie ich nach * komme = does anyone know how to get to *
hat jemand * gesehen | hat wer * gesehen | hat einer * gesehen = has anyone seen *
hat jemand * für mich | hat wer * für mich | hat einer * für mich = does anyone have * for me
hat jemand * übrig | hat wer * übrig | hat jemand * über | hat jemand * abzugeben = does anyone have * to spare
hat jemand * | hat wer * | hat einer * | hat noch jemand * | hat vielleicht jemand * | hat zufällig jemand * = does anyone have *
wer verkauft * = who is selling *

# ---- can anyone / can you ... (verb at the end) ----
kann mir jemand bei * helfen | kann mir wer bei * helfen | kann mir einer bei * helfen | könnte mir jemand bei * helfen | kann mir jemand mit * helfen | hilft mir jemand bei * | hilft mir wer bei * = can anyone help me with *
kann jemand bei * helfen | kann wer bei * helfen | kann jemand mit * helfen | hilft jemand bei * | hilft wer bei * = can anyone help with *
kannst du mir bei * helfen | könntest du mir bei * helfen | hilfst du mir bei * | könnt ihr mir bei * helfen = can you help me with *
kann jemand * herstellen | kann wer * herstellen | kann einer * herstellen | kann jemand * craften | kann jemand * bauen | kann jemand * schmieden = can anyone craft *
kann jemand * machen | kann wer * machen | kann einer * machen = can anyone make *
kann mir jemand * herstellen | kann mir wer * herstellen | kann mir jemand * craften | kann mir jemand * bauen | kann mir jemand * schmieden = can anyone craft * for me
kann mir jemand * machen | kann mir wer * machen | kann mir einer * machen = can anyone make me *
kann jemand * verzaubern | kann wer * verzaubern | kann mir jemand * verzaubern | kann mir wer * verzaubern = can anyone enchant *
kann jemand * öffnen | kann wer * öffnen | kann mir jemand * öffnen | kann mir wer * öffnen | kann jemand * aufmachen | kann mir jemand * aufmachen = can anyone open *
kann mir jemand * geben | kann mir wer * geben | kann mir einer * geben = can anyone give me *
kann mir jemand * leihen | kann mir wer * leihen | kann mir einer * leihen = can anyone lend me *
kann mir jemand * zeigen | kann mir wer * zeigen = can anyone show me *
kann mir jemand sagen wo * ist | kann mir wer sagen wo * ist | kann mir einer sagen wo * ist = can anyone tell me where * is
kann mir jemand sagen * | kann mir wer sagen * | kann mir einer sagen * = can anyone tell me *
kann mich jemand nach * porten | kann mich wer nach * porten | kann mich einer nach * porten | portet mich jemand nach * | kann jemand nach * porten = can anyone port me to *
kann mich jemand durch * ziehen | kann mich wer durch * ziehen | zieht mich jemand durch * | zieht mich wer durch * = can anyone boost me through *
kann mich jemand * | kann mich wer * | kann mich einer * | könnte mich jemand * = can anyone * me
wer kann * herstellen | wer kann * craften | wer kann * bauen | wer kann * schmieden = who can craft *
wer kann * machen = who can make *
wer kann * verzaubern = who can enchant *
wer kann * öffnen | wer kann * aufmachen = who can open *
kannst du mir * geben | könntest du mir * geben | gibst du mir * = can you give me *
kannst du mir * machen | kannst du mir * herstellen | kannst du mir * craften | kannst du mir * bauen | machst du mir * = can you make me *
kannst du mir * zeigen | zeigst du mir * = can you show me *
kannst du mir * leihen | leihst du mir * = can you lend me *
kannst du * herstellen | kannst du * craften | kannst du * bauen | kannst du * machen | kannste * machen = can you make *
kannst du * verzaubern | kannste * verzaubern | kannst du mir * verzaubern = can you enchant *
kannst du mich nach * porten | kannste mich nach * porten | kannst du mich nach * bringen = can you port me to *
kannst du mich kurz * | kannste mich kurz * | kannst du mich mal * | kannst du mich bitte * | kannst du mich mal kurz * = can you * me real quick
kannst du mich * | kannste mich * | könntest du mich * = can you * me
kannst du * | kannste * | könntest du * = can you *
könnt ihr mich * = can you * me
könnt ihr * | könntet ihr * = can you *
kann ich * | darf ich * = can I *

# ---- where / how / how much ----
wo ist * | wo steht * | wo befindet sich * = where is *
wo bekomme ich * her | wo krieg ich * her | wo kriege ich * her | wo bekommt man * her | wo kriegt man * her = where do I get *
wo finde ich * | wo find ich * | wo findet man * | wo finde ich denn * = where do I find *
wo kann ich * kaufen | wo kann man * kaufen | wo kaufe ich * | wo kauft man * | wo gibt es * zu kaufen = where can I buy *
wo kann ich * finden | wo kann man * finden | wo kann ich * bekommen | wo kann man * bekommen = where can I find *
wo kann ich * farmen | wo kann man * farmen | wo farmt man * | wo farme ich * = where can I farm *
wo kann ich * lernen | wo kann man * lernen | wo lerne ich * | wo lernt man * = where can I learn *
wo kann ich * abgeben | wo muss ich * abgeben | wo gebe ich * ab | wo gibt man * ab = where do I turn in *
wo droppt * | wo dropt * | wer droppt * | wo bekommt man * als drop = where does * drop
was droppt bei * | was droppt in * | was droppt * = what drops from *
wie bekomme ich * | wie bekomm ich * | wie kriege ich * | wie krieg ich * | wie bekommt man * | wie kriegt man * = how do I get *
wie mache ich * | wie mach ich * | wie macht man * = how do I do *
wie viel kostet * | wieviel kostet * | was kostet * | wie teuer ist * | was kosten * | wie viel kosten * = how much is *
was willst du für * haben | was willst du für * | wieviel willst du für * | wie viel willst du für * | was möchtest du für * | was nimmst du für * = how much do you want for *
was zahlst du für * | wieviel zahlst du für * | wie viel zahlst du für * | was gibst du für * | was bietest du für * = how much will you pay for *
was bekomme ich für * | was kriege ich für * | was krieg ich für * | was gibt es für * | was gibts für * = what do I get for *
welches level braucht man für * | welches lvl braucht man für * | ab welchem level ist * | ab welchem lvl ist * = what level do you need for *
wann startet * | wann beginnt * | wann geht * los | wann fängt * an = when does * start
wie lange dauert * | wie lang dauert * | wie lange geht * | wie lange braucht man für * = how long does * take
gibt es hier * | gibts hier * | gibt es hier irgendwo * | gibts hier irgendwo * = is there * here
gibt es * | gibts * | gibt's * = is there *

# ---- trade ----
verkaufe * für * | vk * für * | verkauf * für * | biete * für * = selling * for *
verkaufe * gegen gebot | verkaufe * gegen gebote | vk * gegen gebot | biete * gegen gebot = selling * to the highest bidder
verkaufe * vb | verkaufe * vhb | vk * vb | vk * vhb = selling * or best offer
* zu verkaufen | * zum verkauf = * for sale
tausche * gegen * | tausch * gegen * | biete * gegen * | tausche * für * = trading * for *
* zu verschenken | * abzugeben = * to give away
gebe dir * für * | geb dir * für * | ich gebe dir * für * | ich geb dir * für * = I'll give you * for *
flüster mich an für * | flüstert mich an für * | pn für * | bei interesse an * = whisper me for *

# ---- have to / want to / can (verb at the end) ----
ich muss noch * abgeben | muss noch * abgeben | ich muss * abgeben | muss * abgeben = I have to turn in *
ich muss noch * holen | muss noch * holen | ich muss * holen | muss * holen | ich muss * besorgen | muss noch * besorgen = I have to get *
ich muss noch * machen | muss noch * machen | ich muss * machen | muss * machen = I have to do *
ich muss noch * kaufen | muss noch * kaufen | ich muss * kaufen | muss * kaufen = I have to buy *
ich muss noch * verkaufen | muss noch * verkaufen | ich muss * verkaufen | muss * verkaufen = I have to sell *
ich muss noch * farmen | muss noch * farmen | ich muss * farmen | muss * farmen | ich muss * sammeln | muss noch * sammeln = I have to farm *
ich muss noch * töten | muss noch * töten | ich muss * töten | muss * töten | ich muss * killen | muss noch * killen = I have to kill *
ich muss noch * finden | muss noch * finden | ich muss * finden | muss * finden | ich muss * suchen | muss noch * suchen = I have to find *
ich muss zum * | ich muss zur * | muss zum * | muss zur * | ich muss noch zum * | ich muss erst zum * | ich muss kurz zum * | muss noch zum * | muss erst zum * | muss kurz zum * = I have to go to the *
ich muss nach * | muss nach * | ich muss noch nach * | ich muss erst nach * | ich muss kurz nach * | muss noch nach * | muss kurz nach * = I have to go to *
ich muss noch * | muss noch * | ich muss erst noch * | muss erst noch * = I still have to *
ich muss kurz * | muss kurz * | ich muss mal kurz * | muss mal kurz * | ich muss eben * | muss eben * = I have to * real quick
ich muss erst * | muss erst * | ich muss zuerst * | muss zuerst * = I have to * first
ich muss * | muss ich * = I have to *
wir müssen noch * | müssen noch * = we still have to *
wir müssen erst * töten | wir müssen zuerst * töten | wir müssen erst * killen | wir müssen zuerst * killen | müssen erst * töten | müssen erst * killen = we have to kill * first
wir müssen * töten | wir müssen * killen | wir müssen noch * töten | wir müssen noch * killen | müssen noch * töten | müssen noch * killen = we have to kill *
wir müssen * machen | wir müssen noch * machen | müssen noch * machen = we have to do *
wir müssen * holen | wir müssen noch * holen | müssen noch * holen = we have to get *
wir müssen erst * | wir müssen zuerst * | müssen erst * = we have to * first
ich will * machen | will * machen | ich möchte * machen | möchte * machen | ich würde gerne * machen = I want to do *
ich will * kaufen | will * kaufen | ich möchte * kaufen | möchte * kaufen | ich würde gerne * kaufen = I want to buy *
ich will * verkaufen | will * verkaufen | ich möchte * verkaufen | möchte * verkaufen = I want to sell *
ich will * haben | will * haben | ich möchte * haben | möchte * haben = I want *
ich hätte gerne * | hätte gerne * | ich hätte gern * | hätte gern * = I'd like *
ich will nach * | ich möchte nach * | will nach * | möchte nach * | ich will zu * = I want to go to *
wollen wir * machen | sollen wir * machen | lass uns * machen | lasst uns * machen | machen wir * = let's do *
soll ich * machen = should I do *
soll ich * holen = should I get *
soll ich * | sollte ich * = should I *
wollen wir * | sollen wir * | wollen wir mal * | sollen wir mal * = should we *
ich kann * herstellen | ich kann * craften | ich kann * bauen | ich kann * schmieden = I can craft *
ich kann * machen = I can make *
ich kann * verzaubern = I can enchant *

# ---- have / perfect tense (participle at the end) ----
ich hab kein * mehr | ich hab keine * mehr | ich hab keinen * mehr | hab kein * mehr | hab keine * mehr | hab keinen * mehr | ich habe kein * mehr | ich habe keine * mehr = I'm out of *
ich hab noch * | hab noch * | ich habe noch * | habe noch * = I still have *
hab * gefunden | habe * gefunden | ich hab * gefunden | ich habe * gefunden = I found *
hab * bekommen | habe * bekommen | hab * gekriegt | habe * gekriegt | hab * geholt | habe * geholt | ich hab * bekommen | ich habe * bekommen | ich hab * gekriegt | ich habe * gekriegt | ich hab * geholt | ich habe * geholt = I got *
hab * gekauft | habe * gekauft | ich hab * gekauft | ich habe * gekauft = I bought *
hab * verkauft | habe * verkauft | ich hab * verkauft | ich habe * verkauft = I sold *
hab * gemacht | habe * gemacht | hab * erledigt | habe * erledigt | hab * geschafft | habe * geschafft | ich hab * gemacht | ich habe * gemacht | ich hab * erledigt | ich habe * erledigt | ich hab * geschafft | ich habe * geschafft = I did *
hab * abgegeben | habe * abgegeben | ich hab * abgegeben | ich habe * abgegeben = I turned in *
hab * vergessen | habe * vergessen | ich hab * vergessen | ich habe * vergessen = I forgot *
hab * gesehen | habe * gesehen | ich hab * gesehen | ich habe * gesehen = I saw *
hab * verloren | habe * verloren | ich hab * verloren | ich habe * verloren = I lost *
hab * getötet | habe * getötet | hab * gekillt | habe * gekillt | hab * gelegt | habe * gelegt | ich hab * getötet | ich habe * getötet | ich hab * gekillt | ich habe * gekillt | ich hab * gelegt | ich habe * gelegt = I killed *
wir haben * getötet | wir haben * gekillt | wir haben * gelegt | wir haben * geschafft = we killed *
haben * getötet | haben * gekillt | haben * gelegt | haben * geschafft = killed *
hast du * gefunden | haste * gefunden | habt ihr * gefunden = did you find *
hast du * bekommen | hast du * gekriegt | haste * bekommen | haste * gekriegt | habt ihr * bekommen = did you get *
hast du * gesehen | haste * gesehen | habt ihr * gesehen = did you see *
hast du * gemacht | haste * gemacht | habt ihr * gemacht = have you done *

# ---- dungeon and group calls ----
sorry für * | sorry wegen * | tut mir leid wegen * = sorry for *
warte auf * | wartet auf * | wart auf * = wait for *
ich warte auf * | warte noch auf * | warten auf * | wir warten auf * | warten noch auf * | wir warten noch auf * = waiting for *
lad mich in * ein | lad mich zu * ein | ladet mich in * ein | lad mich bitte in * ein = invite me to *
lad * ein | lade * ein | ladet * ein | lad mal * ein | lad bitte * ein = invite *
lass uns nach * gehen | lass uns nach * | wollen wir nach * = let's go to *
zuerst * töten | erst * töten | zuerst * killen | erst * killen | killt zuerst * | tötet zuerst * = kill * first
fokus auf * | focus auf * | alle auf * | schaden auf * = focus *
glückwunsch zu * | glückwunsch zum * | gratz zu * | gratz zum * | gratuliere zu * | gratuliere zum * = congrats on *
# ---- slang pass (2026-11-13): de_9.txt ----
sprichst du * | sprecht ihr * | spricht hier jemand * | spricht jemand * | spricht hier wer * | jemand hier der * spricht | jemand der * spricht | wer spricht * | kann hier jemand * | kann jemand * = does anyone speak *
ich spreche kein * | spreche kein * | ich spreche nicht * | ich kann kein * | spreche nicht * | ich versteh kein * | ich verstehe kein * = I don't speak *
ich spreche nur * | spreche nur * | ich kann nur * = I only speak *
auf * bitte | bitte auf * = in * please
# ---- slang pass (2026-11-13): de_1.txt, de_2.txt ----
* oder sowas | * oder so was | * oder was in der art | * oder so in der art = * or something like that
* und so | * und sowas | * und so weiter | * und so n kram | * und so n zeug = * and stuff
mach ma * | mach mal * | mach doch mal * | macht mal * | macht ma * = just *
lass ma * | lasst ma * | lass uns ma * | lass uns mal * | lasst uns mal * = let's *
mega * | ultra * | hammer * | sau * | mords * = super *
ur * | voi * | huere * | uu * = really *
wat is mit * | wat is mit * los | was is mit * | was ist mit * los | was is mit * los | was is mit * passiert = what's up with *
wo bleibt * | wo bleibt denn * | wo bleibt der * | wo bleibt die * | wo bleibt das * | wo bleiben * = what's keeping *
wer braucht noch * | braucht noch wer * | braucht noch jemand * | braucht jemand * | braucht wer * | braucht einer * = does anyone still need *
suche noch * | such noch * | suche nen * | such nen * | suche ne * | such ne * = looking for *
kein bock auf * | keinen bock auf * | null bock auf * | kein bock mehr auf * | keine lust auf * | keine lust mehr auf * = don't feel like *
scheiß auf * | scheiss auf * | scheiß auf den * | scheiß auf die * | scheiß auf das * | kack auf * = screw *
* ist am arsch | * is am arsch | * is im arsch | * ist im arsch | * is kaputt | * ist kaputt = * is screwed
* kann weg | * kann weg ey | * kann man weglassen = * can go
hab kein * | hab keine * | hab keinen * | ich hab kein * | ich hab keine * | ich hab keinen * | hab kein * dabei = I don't have *
hab noch kein * | hab noch keine * | hab noch keinen * | hab * noch nicht | hab * noch nich | hab * noch net = I don't have * yet
gibts noch * | gibt's noch * | gibt es noch * | gibts hier noch * | jibts noch * = is there still *
wer zieht mich durch * | zieht jemand mich durch * | wer zieht mich * | zieht mich einer durch * | wer zieht * = who can boost me through *
ab nach * | ab zum * | ab zur * | ab in die * | ab in den * | ab ins * = off to *
auf nach * | auf zum * | auf zur * | los nach * | los zum * | los zur * | los ins * = let's go to *
bin dann mal * | ich bin dann mal * | bin mal * | bin mal kurz * | bin dann * | ich bin mal * = I'm off to *
* läuft nicht | * läuft net | * läuft nich | * geht nich | * geht net | * geht grad nicht | * will nicht = * isn't working
was soll der * | was soll das * | was soll die * | was soll der scheiß mit * | was soll dat * = what's with the *
* und zwar jetzt | * und zwar sofort | * und zwar zackig | * aber dalli | * aber zackig | * aber hurtig = * right now
noch * dann weg | noch * dann bin ich weg | noch * dann geh ich | noch * dann is schluss | noch * dann bin ich off = * more and then I'm out
# ---- slang pass (2026-11-13): de_10.txt ----
hier wird * gesprochen = * is spoken here
wird * gesprochen = * is spoken
]==])

-- Respelling rules for the fuzzy layer (Fuzzy.lua): each makes one candidate
-- from a word no lookup knows (accents folded), once the line is known to be
-- German. The first candidate the dictionary knows wins.
L:Respell([==[
# umlauts typed as two letters: fuer, schoen, maedchen
ue > u
ae > a
oe > o
# a dropped final letter: hab, nich, is, kannst
$ > e
$ > n
$ > t
# ck/k and ss: zurük, gros
ck > k
k > ck
s$ > ss
]==])
