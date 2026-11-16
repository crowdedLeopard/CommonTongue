-- CommonTongue / Grammar/nl.lua  —  Dutch verbs, conjugation and sentence templates
local L = CommonTongue.Languages.nl
if not L then return end

-- infinitive | pseudo-infinitive with the doubled stem vowel = English base verb
-- ("koopen" does not exist; it lets "koopt" resolve to kopen)
L:Verbs([==[
kopen | koopen = buy
verkopen | verkoopen = sell
zoeken = look for
helpen = help
wachten | wachen = wait
betalen | betaalen = pay
ruilen = trade
komen | koomen = come
gaan | gaen | gaaen = go
maken | maaken = make
spelen | speelen = play
geven | geefen = give
nemen | neemen = take
pakken | paken = grab
brengen = bring
halen | haalen = get
krijgen = get
vinden = find
zien | zieen = see
kijken = look
lezen | leesen = read
schrijven | schrijfen = write
praten | praaen = talk
zeggen | zegen = say
vragen | vraagen = ask
antwoorden | antwoorden = answer
weten | weeen = know
denken = think
geloven | geloofen = believe
hopen | hoopen = hope
proberen | probeeren = try
beginnen | beginen = start
starten | staren = start
stoppen | stopen = stop
eindigen = end
afmaken | afmaaken = finish
openen = open
sluiten | sluien = close
lopen | loopen = walk
rennen | renen = run
vluchten | vluchen = flee
vechten | vechen = fight
doden | dooden = kill
killen = kill
sterven | sterfen = die
winnen | winen = win
verliezen | verliesen = lose
leven | leefen = live
eten | eeen = eat
drinken = drink
slapen | slaapen = sleep
werken = work
gebruiken = use
dragen | draagen = carry
volgen = follow
blijven | blijfen = stay
staan | staen | staaen = stand
zitten | ziten = sit
liggen | ligen = lie
vallen | valen = fall
springen = jump
zwemmen | zwemen = swim
vliegen = fly
rijden = ride
reizen | reisen = travel
sturen | stuuren = send
roepen | roepen = call
horen | hooren = hear
luisteren = listen
leren | leeren = learn
vergeten | vergeeten = forget
herinneren = remember
begrijpen = understand
snappen | snapen = get
kennen | kenen = know
willen | wilen = want
kunnen | kunen = can
moeten | moeen = must
mogen | moogen = may
durven | durfen = dare
hoeven | hoefen = need
laten | laaten = let
zetten | zeten = put
leggen | legen = put
houden | houen = keep
bewaren | bewaaren = keep
verdienen = earn
kosten = cost
duren | duuren = last
veranderen = change
wisselen = switch
kiezen | kiesen = choose
beslissen = decide
accepteren = accept
weigeren = refuse
delen | deelen = share
verdelen | verdeelen = split
verzamelen | verzaamelen = gather
bouwen = build
breken | breeken = break
repareren = repair
fixen = fix
verbeteren = improve
tanken = tank
healen = heal
farmen = farm
looten = loot
droppen | dropen = drop
pullen = pull
kiten = kite
buffen | bufen = buff
rezzen | rezen = res
ressen | resen = res
reviven = revive
leveln | levelen = level
questen = quest
grinden = grind
rushen = rush
skippen | skipen = skip
spammen | spamen = spam
whisperen = whisper
pm'en | pmen = pm
inviten = invite
uitnodigen = invite
kicken = kick
joinen = join
loggen | logen = log
inloggen | inlogen = log in
uitloggen | uitlogen = log out
reloggen | relogen = relog
crashen = crash
laden | laaden = load
herstarten | herstaren = restart
aanvallen | aanvalen = attack
verdedigen = defend
beschermen = protect
raken | raaken = hit
schieten = shoot
casten = cast
enchanten = enchant
craften = craft
summonen = summon
porten = port
wipen = wipe
taunten = taunt
stunnen | stunen = stun
ontwijken = dodge
tellen | telen = count
betekenen | beteekenen = mean
heten | heeten = be called
noemen | noemen = call
tonen | toonen = show
verstoppen | verstopen = hide
verbergen = hide
checken = check
controleren | controleeren = check
waarschuwen = warn
rekruteren | rekruteeren = recruit
recruiten = recruit
werven = recruit
organiseren | organiseeren = organize
regelen | regeelen = arrange
verzorgen = take care of
aggroën | aggroen = aggro
afspreken | afspreeken = agree
ontmoeten = meet
bezoeken = visit
vertrekken | vertreken = leave
verlaten | verlaaten = leave
terugkomen | terugkoomen = come back
terugkeren | terugkeeren = return
doorgaan | doorgaen = continue
stoppen met | stopen met = stop
]==])

-- suffix > infinitive ending = English template
-- (the bare stem "koop", "ga", "kom" is a dictionary entry; the ge- participles are too)
L:Conjugation([==[
t > en = %s3
en > en = %s
te > en = %ed
de > en = %ed
ten > en = %ed
den > en = %ed
end > en = %ing
ende > en = %ing
]==])

-- Sentence templates. '*' is a slot of one or more words, translated on its own.
-- Dutch puts the verb second and the infinitive/object last, so many templates end in a literal.
L:Patterns([==[
# ---- looking for / need ----
zoek groep voor * | ik zoek groep voor * | zoek een groep voor * | ik zoek een groep voor * | zoek mensen voor * | ik zoek mensen voor * | we zoeken mensen voor * | zoek party voor * | zoek pt voor * | zoek nog mensen voor * = looking for group for *
zoek * voor * | ik zoek * voor * | we zoeken * voor * = looking for * for *
zoek * | ik zoek * | ik ben op zoek naar * | op zoek naar * | ik zoek nog * = looking for *
we zoeken * | wij zoeken * | we zijn op zoek naar * | we zoeken nog * = we're looking for *
* gezocht = looking for *
ik heb hulp nodig met * | ik heb hulp nodig bij * | hulp nodig met * | hulp nodig bij * | ik zoek hulp met * | ik zoek hulp bij * | help nodig met * = I need help with *
ik heb * nodig voor * = I need * for *
ik heb * nodig | heb * nodig | ik heb nog * nodig | ik zoek nog * | ik kan * gebruiken | ik moet * hebben = I need *
we hebben * nodig voor * = we need * for *
we hebben * nodig | wij hebben * nodig | we hebben nog * nodig | we kunnen * gebruiken | we moeten * hebben = we need *
nog * nodig voor * | nog * voor * = need * more for *
nog een * nodig | nog een * nodig voor = need another *
nog * nodig | we missen * | we missen nog * | mist nog * | ontbreekt nog * = need *
waarom vraag je het niet in * | waarom vraag je niet in * = why don't you ask in *
waarom vraag je het niet aan * = why don't you ask *
waarom ga je niet naar * | waarom ga je niet * = why don't you go to *
waarom doe je niet * = why don't you do *
waarom * niet = why not *
hij wil niet * | ze wil niet * = he doesn't want to *
ik gebruik * niet meer = I don't use * anymore
ik mis * | ik mis nog * = I'm missing *
alleen nog * | alleen nog * nodig | we missen alleen * | we missen alleen nog * | mis alleen nog * = we only need *
groep voor * | party voor * | pt voor * = group for *
iemand voor * | iemand zin in * | heeft iemand zin in * | wie heeft zin in * | wie heeft er zin in * | wie zin in * = anyone up for *
wie gaat mee naar * | wie wil mee naar * | wie komt mee naar * | iemand mee naar * = who's coming to *
gilde * zoekt leden | gilde * zoekt nieuwe leden | gilde * recruit | gilde * is aan het recruiten | gilde * werft leden | guild * zoekt leden | de gilde * zoekt leden = guild * is recruiting
we zoeken * voor onze gilde | we zoeken * voor de gilde | wij zoeken * voor onze gilde | gilde zoekt * = recruiting *

# ---- questions ----
weet iemand waar * is | weet iemand waar * zit | weet iemand waar * ligt | weet iemand waar * staat | weet er iemand waar * is | iemand die weet waar * is = does anyone know where * is
weet iemand waar * | weet er iemand waar * = does anyone know where *
weet iemand hoe * | weet er iemand hoe * = does anyone know how *
weet iemand of * | weet er iemand of * = does anyone know if *
weet iemand * | weet er iemand * = does anyone know *
heeft iemand * | heeft er iemand * | iemand * over = does anyone have *
wil iemand * | wil er iemand * | heeft iemand zin om * = does anyone want *
kan iemand * | kan er iemand * | zou iemand * = can anyone *
kan iemand mij helpen met * | kan iemand me helpen met * | kan er iemand mij helpen met * | kan er iemand me helpen met * | kan iemand mij helpen bij * | kan iemand me helpen bij * | wil iemand mij helpen met * | wil iemand me helpen met * | iemand die mij kan helpen met * | iemand die me kan helpen met * = can anyone help me with *
kan iemand mij naar * brengen | kan iemand me naar * brengen | kan iemand mij een lift geven naar * | kan iemand me een lift geven naar * | wil iemand mij naar * brengen | wil iemand me naar * brengen = can anyone take me to *
verkoopt iemand * | verkoopt er iemand * | heeft iemand * te koop | iemand * te koop = is anyone selling *
koopt iemand * | koopt er iemand * | wil iemand * kopen | wil er iemand * kopen = is anyone buying *
iemand die * = anyone who *
wie wil * | wie wil er * = who wants *
wie heeft * | wie heeft er * = who has *
wie verkoopt * | wie verkoopt er * = who is selling *
wie kan * | wie kan er * = who can *
waar is * | waar zit * | waar ligt * | waar staat * | waar vind ik * | waar kan ik * vinden = where is *
weet iemand waar ik * kan kopen | weet iemand waar je * kan kopen | weet iemand waar je * kunt kopen = does anyone know where I can buy *
weet iemand waar ik * kan vinden | weet iemand waar je * kan vinden = does anyone know where I can find *
weet iemand waar ik * kan krijgen | weet iemand waar ik * kan halen = does anyone know where I can get *
over * minuten | over * min | over * minuutjes = in * minutes
over * uur = in * hours
over * seconden | over * sec = in * seconds
ben er over * | ik ben er over * | ik ben er in * = I'll be there in *
ik kan * niet vinden | kan * niet vinden = I can't find *
waar zijn * | waar zitten * | waar liggen * | waar staan * = where are *
waar krijg ik * | waar haal ik * | waar kan ik * krijgen | waar kan ik * halen | waar krijg je * | waar haal je * | waar kan je * krijgen | waar dropt * = where do I get *
waar koop ik * | waar kan ik * kopen | waar koop je * | waar kan je * kopen | waar kun je * kopen | wie verkoopt * = where can I buy *
hoe kom ik bij * | hoe kom ik naar * | hoe kom ik in * | hoe ga ik naar * | hoe kom je bij * | hoe kom je naar * | hoe kom je in * | hoe kom ik het snelst bij * = how do I get to *
hoe doe ik * | hoe doe je * | hoe moet ik * doen | hoe moet je * doen | hoe werkt * = how do I do *
hoe krijg ik * | hoe kom ik aan * | hoe haal ik * | hoe krijg je * | hoe kom je aan * = how do I get *
hoeveel kost * | hoeveel kosten * | wat kost * | wat kosten * | hoeveel is * | hoeveel voor * | hoe duur is * | wat moet * kosten = how much is *
hoeveel wil je voor * | hoeveel vraag je voor * | wat wil je voor * | wat vraag je voor * | wat moet je hebben voor * | hoeveel moet je hebben voor * = how much do you want for *
hoeveel geef je voor * | hoeveel betaal je voor * | wat geef je voor * | wat betaal je voor * | hoeveel bied je voor * | wat bied je voor * = how much will you pay for *
welk level is * | welke level is * | welk lvl is * | welke lvl is * | wat voor level is * | hoe hoog is * = what level is *
hoe laat * | om hoe laat * | wanneer * = what time *
kan je me * | kun je me * | kan je mij * | kun je mij * | wil je me * | wil je mij * | zou je me * | zou je mij * = can you * me
kan je me helpen met * | kun je me helpen met * | kan je mij helpen met * | kun je mij helpen met * | help je me met * | help je me even met * | kan je me helpen bij * | kun je me helpen bij * | wil je me helpen met * | kunnen jullie me helpen met * = can you help me with *
kan je * | kun je * | kan jij * | kun jij * | kunnen jullie * | zou je * | zou je kunnen * = can you *
weet je waar * | weet jij waar * | weten jullie waar * | weet je waar * is | weet jij waar * is = do you know where *
weet je of * | weet jij of * | weten jullie of * = do you know if *
weet je * | weet jij * | weten jullie * = do you know *
heb je * | heb jij * | hebben jullie * | heb je nog * | heb je toevallig * | heb je al * = do you have *
wil je * | wil jij * | willen jullie * | heb je zin om * | hebben jullie zin om * = do you want *
ben je * | ben jij * | zijn jullie * = are you *
ga je * | ga jij * | gaan jullie * | ga je mee naar * | ga je naar * = are you going to *

# ---- trade ----
ik verkoop * voor * | verkoop * voor * | te koop * voor * = selling * for *
ik verkoop * goedkoop | verkoop * goedkoop | ik verkoop * voor weinig = selling * cheap
ik verkoop * | verkoop * | te koop * | ik heb * te koop | heb * te koop | tk * = selling *
ik koop * voor * | koop * voor * = buying * for *
ik koop * | koop * | ik wil * kopen | wil * kopen | ik zoek * te koop | ik koop graag * = buying *
ik ruil * voor * | ruil * voor * | ik ruil * tegen * | ruil * tegen * | ik wissel * voor * | ik trade * voor * = trading * for *
ik geef * weg | geef * weg | gratis * | * gratis weg te geven | ik heb * weg te geven = giving away *
ik betaal * voor * | betaal * voor * = paying * for *
ik geef * voor * | geef * voor * | ik bied * voor * | bied * voor * = I'll give * for *
ik geef je * | ik geef jou * | je krijgt * van mij | je krijgt * van me = I'll give you *
geef me * | geef mij * | geef me even * | geef mij even * | mag ik * | kan ik * krijgen = give me *
beste bod voor * | hoogste bod voor * | beste bod op * | hoogste bod op * | bod op * | bied op * = best offer for *
whisper me voor * | whisp me voor * | pm me voor * | w me voor * | stuur me een pm voor * | stuur me een whisper voor * | pm voor * | whisper voor * = whisper me for *
ik heb * over | heb * over | ik heb nog * over = I have * left

# ---- statements ----
ik heb * voor * = I have * for *
ik heb * | heb * | ik heb nog * | ik heb al * = I have *
ik moet * | ik moet nog * | ik moet even * | ik moet eerst * | ik moet nu * = I have to *
je moet * | jij moet * | je moet eerst * | je moet even * | jullie moeten * = you have to *
we moeten * | wij moeten * | we moeten nog * | we moeten eerst * | we moeten even * = we have to *
ik heb geen * | heb geen * | ik heb geen * meer = I don't have *
ik heb al * | heb al * | ik heb * al | heb * al = I already have *
ik wil * | wil * | ik wil graag * | ik zou graag * | ik wil wel * = I want *
ik wil geen * | ik wil niet * | ik wil * niet | wil geen * = I don't want *
we willen * | wij willen * | we willen graag * = we want *
ik kan * | kan ik * | ik kan wel * = I can *
ik kan niet * | ik kan * niet | kan * niet | ik kan geen * | lukt niet om * | het lukt me niet om * = I can't *
we kunnen * | wij kunnen * | we kunnen wel * = we can *
je kan niet * | je kunt niet * | je kan * niet | je kunt * niet | kan niet * = you can't *
ik weet niet * | weet niet * | ik weet niet waar * | ik weet niet hoe * | ik weet niet of * = I don't know *
ik ga * | ik ga naar * | ik ga nu * | ik ga zo * | ik ga even * | ik ga straks * | ik ga eerst * = I'm going to *
we gaan * doen | laten we * doen | we doen * | zullen we * doen = let's do *
we gaan voor * | laten we voor * gaan | op naar * = let's go for *
laten we * | we gaan * | kom we gaan * | zullen we * | gaan we * = let's *
ik ben in * | ik zit in * | ik ben bij * | ik sta bij * | ik ben op * | ik zit op * | ik ben nu in * | ik ben al in * = I'm in *
we zijn in * | we zitten in * | we zijn bij * | we staan bij * | we zijn op * | wij zijn in * = we're in *
ik ben level * | ik ben lvl * | ik ben niveau * | ik zit op level * | ik zit op lvl * | ben level * | ben lvl * = I'm level *
bedankt voor * | dank je voor * | dankjewel voor * | dank voor * | thnx voor * | thanks voor * = thanks for *
sorry voor * | excuses voor * | sorry van * | het spijt me van * = sorry for *
er is geen * | er zijn geen * | er is geen * meer | geen * meer | er is niks * | er is niets * = there is no *
is er iemand * | is er nog iemand * | iemand hier * = is there anyone *
invite * | inv * | nodig * uit | invite * even | inv * even = invite *
invite me voor * | inv me voor * | invite me naar * | inv me naar * | invite mij voor * | nodig me uit voor * | mag ik mee naar * = invite me to *
help me met * | help mij met * | help me even met * | help me bij * | help me even bij * | help even met * = help me with *
wacht op * | wacht even op * | wacht effe op * | wacht ff op * | wachten op * = wait for *
volg * | volg * maar | volg * even = follow *
kom naar * | kom even naar * | kom bij * | kom naar * toe | kom allemaal naar * = come to *
ga naar * | ga even naar * | ga maar naar * | gaan jullie naar * = go to *
klaar voor * | ready voor * | rdy voor * | iedereen klaar voor * | zijn jullie klaar voor * = ready for *
pull * | pull * maar | pull * nu | pullen * = pull *
dood * eerst | kill * eerst | eerst * doden | eerst * killen | eerst * = kill * first
heal * | heal * even | heal * nu | genees * = heal *
rez * | res * | ress * | revive * | rez * even | res * even = res *
summon * aub | summon * please | summon * pls | summ * aub | summon * even | kan iemand * summonen | wil iemand * summonen = summon * please
ik heb * gedood | ik heb * gekilled | ik heb * gekilld | ik heb * vermoord = I killed *
we hebben * gedood | we hebben * gekilled | we hebben * gekilld | we hebben * vermoord | we hebben * gedaan = we killed *
ik heb * gekocht = I bought *
ik heb * verkocht = I sold *
ik heb * gevonden = I found *
ik heb * gekregen | ik heb * gehaald | ik heb * gescoord = I got *
ik heb * gedaan | ik heb * afgemaakt | ik heb * gefixt | ik heb * geregeld = I did *
heb je * gezien | heb jij * gezien | hebben jullie * gezien | zag je * = did you see *
heb je * gedaan | heb jij * gedaan | hebben jullie * gedaan | heb je * al gedaan = did you do *
ik wacht bij * | ik wacht aan * | ik wacht voor * | ik wacht wel bij * | ik wacht even bij * | ik sta bij * te wachten = I'll wait at *
ik wacht op * | ik wacht even op * | ik ben aan het wachten op * | wacht op * = I'm waiting for *
we wachten op * | we wachten even op * | we zijn aan het wachten op * = we're waiting for *
ik kom naar * | ik kom zo naar * | ik kom eraan naar * | ik ben onderweg naar * | ik kom even naar * = I'm coming to *
we gaan naar * | wij gaan naar * | we gaan zo naar * | we gaan nu naar * | we zijn onderweg naar * = we're going to *
ik vind * leuk | ik vind * mooi | ik vind * tof | ik vind * gaaf | ik hou van * = I like *
ik vind * niet leuk | ik vind * niks | ik haat * | ik hou niet van * = I don't like *
ik denk dat * | volgens mij * | ik geloof dat * | ik gok dat * | ik denk * = I think that *
ik hoop dat * | hopelijk * = I hope that *
ik ben * kwijt | ik ben * verloren | ik heb * verloren = I lost *
zin in * | zin om * | heb je zin in * | hebben jullie zin in * = up for *
# ---- slang pass (2026-11-13): nl_9.txt ----
is helemaal geen * | is egt geen * | is echt geen * | is totaal geen * = isn't * at all
helemaal geen * | echt geen * | egt geen * | totaal geen * | absoluut geen * = no * at all
spreekt iemand * | spreekt er iemand * | spreekt hier iemand * | is er iemand die * spreekt | is hier iemand die * spreekt | iemand hier die * spreekt | iemand die * spreekt | iemand die * kan | iemand * hier = does anyone speak *
spreek je * | praat je * | spreken jullie * | spreek jij * | kun je * | kan je * = do you speak *
ik spreek geen * | ik praat geen * | kan geen * | ik kan geen * | spreek geen * | ik versta geen * | ik snap geen * = I don't speak *
# ---- slang pass (2026-11-13): nl_1.txt, nl_2.txt, nl_9.txt ----
kga * | k ga * | kga ff * | kga even * | kga effe * | kga zo * | kga nu * | kga eerst * | kga nog ff * = I'm going to *
kwil * | k wil * | kwil ff * | kwil even * | kwil wel * | kwil graag * | kwil nog * = I want *
kheb * | k heb * | kheb nog * | kheb al * | kheb ff * = I have *
kheb geen * | k heb geen * | kheb geen * meer | kheb nog geen * = I don't have *
kmoet * | k moet * | kmoet ff * | kmoet even * | kmoet effe * | kmoet nog * | kmoet eerst * = I have to *
kkan * | k kan * | kkan wel * | kkan ff * = I can *
kkan niet * | kkan nie * | kkan geen * | k kan niet * | kkan * niet | kkan * nie = I can't *
kweet * | k weet * | kweet wel * | kweet al * = I know *
kweet niet * | kweet nie * | kweet ni * | kweetnie * | kweenie * | kweet niet of * | k weet niet * = I don't know *
kben * | k ben * | kben al * | kben nog * | kben ff * | kben even * | kben nu * | kben zo * | kben bijna * = I'm *
kzit * | k zit * | kzit in * | kzit bij * | kzit op * | kzit nog in * = I'm in *
* ofzo | * of zo | * ofso | * of zoiets | * enzo | * en zo | * of iets | * ofwa = * or something
* toch | * toch? | * tog | * togh | * toch wel | * he | * hè | * hoor | * joh | * zeg = *
t is * | 't is * | tis * | ut is * | tiss * = it's *
das * | da's * | dasse * | das echt * | das egt * | da is * = that's *
das een * | da's een * | das n * | das 'n * | das ne * | das nen * = that's a *
doe ff * | doe even * | doe effe * | doe es * | doe eens * | doe ns * | doe maar * | doe gewoon * | doe nou * | doe dan * = just *
niet * joh | niet * man | niet * zeg | niet * hoor | niet * he | niet * hè | nie * joh | nie * man | ni * joh = don't *
ga * joh | ga * man | ga lekker * | ga maar * | ga dan * | ga nou * | ga toch * | ga ff * | ga even * = go *
wat een * | wat n * | wat 'n * | wat een * zeg | wat een * joh | wat een * man | wa ne * | wat ne * | wa een * = what a *
is helemaal geen * | is egt geen * | is echt geen * | is totaal geen * = isn't * at all
helemaal geen * | echt geen * | egt geen * | totaal geen * | absoluut geen * = no * at all
spreekt iemand * | spreekt er iemand * | spreekt hier iemand * | is er iemand die * spreekt | is hier iemand die * spreekt | iemand hier die * spreekt | iemand die * spreekt | iemand die * kan | iemand * hier = does anyone speak *
spreek je * | praat je * | spreken jullie * | spreek jij * | kun je * | kan je * = do you speak *
ik spreek geen * | ik praat geen * | kan geen * | ik kan geen * | spreek geen * | ik versta geen * | ik snap geen * = I don't speak *
# ---- slang pass (2026-11-13): nl_8.txt ----
# ---- patterns lost in the first merge (right side had two frames) ----
ff * | effe * | efkes * | ekes * | even * | eventjes * = just *
ff * doen | even * doen | effe * doen = just do *
geen * nodig | geen * meer nodig = no * needed
geen * meer | geen * hoor | geen * man | geen * joh | geen * zeg = no *
kut * | kut * zeg | kut * joh | kut * man | klote * | klote * zeg | tering * | tyfus * | kanker * = fucking *
stomme * | domme * | stomme * zeg | stomme * joh | stomme * man = stupid *
kansloze * | hopeloze * | kutte * = hopeless *
# ---- slang pass (2026-11-13): nl_10.txt ----
kan * ook niet vinden = can't find * either
kan * niet vinden = can't find *
ik kan * niet vinden = I can't find *
wil je geen * praten = don't you want to speak *
ik hoop dat je * hebt = I hope you have *
ik hoop dat jullie * hebben = I hope you have *
]==])

-- Respelling rules for the fuzzy layer (Fuzzy.lua): each makes one candidate
-- from a word no lookup knows (accents folded), once the line is known to be
-- Dutch. The first candidate the dictionary knows wins.
L:Respell([==[
# ei/ij, au/ou and g/ch spelt the other way
ei > ij
ij > ei
au > ou
ou > au
ch > g
g > ch
# a dropped or hardened final letter: nie, kom, egt, wor
$ > t
$ > n
$ > e
$ > d
d$ > t
t$ > d
]==])
