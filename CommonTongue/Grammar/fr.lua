-- CommonTongue / Grammar/fr.lua  —  French verbs, conjugation and sentence templates
local L = CommonTongue.Languages.fr
if not L then return end

-- Object pronouns that stand before the verb: "je le tue" -> "I kill it".
-- (Elided forms glued to the verb, "l'ai", "m'invite", "t'aide", are single
-- tokens and live in the dictionary.) "vous" is mostly the subject in chat
-- ("vous cherchez quoi"), so it is dropped here rather than repeated.
L:Clitics([==[
le | la | l' = it
les = them
lui = him
leur = them
me | m' = me
te | t' = you
nous = us
vous = ~
se | s' = ~
]==])

-- infinitive | stem-changed or spelling-changed pseudo-infinitive = English base verb
-- ("prenre" does not exist; it lets "prenons", "prenez", "prenait" resolve to "prendre".
--  Accent changes need no help: "achète" folds to "acheter", "commençons" to "commencer".)
L:Verbs([==[
tuer | buter | défoncer = kill
soigner | healer = heal
chercher | rechercher = look for
trouver = find
aider = help
acheter = buy
vendre = sell
payer | paier = pay
échanger | échangeer | troquer = trade
changer | changeer = change
donner | filer = give
attendre | patienter = wait
entrer | rentrer = enter
arriver = arrive
emmener | amener = take
porter = carry
laisser = leave
prendre | prenre | prennre = take
utiliser = use
regarder | mater = look
parler | causer = talk
jouer = play
gagner = win
perdre = lose
inviter | grouper = invite
lancer = cast
virer | kicker = kick
commencer | démarrer | débuter = start
finir | terminer = finish
essayer | essaier | tenter = try
penser = think
croire = think
envoyer | envoier = send
rester = stay
passer = pass
descendre = go down
monter = go up
sortir = go out
partir = leave
quitter = leave
ouvrir = open
fermer = close
courir = run
manger | mangeer | bouffer = eat
boire = drink
apprendre | apprenre | apprennre = learn
comprendre | comprenre | comprennre = understand
lire | lisre = read
écrire | écrivre = write
dire | disre = say
vivre = live
mourir | crever = die
suivre = follow
attaquer = attack
taper | frapper = hit
tanker = tank
farmer = farm
looter = loot
droper | dropper = drop
pexer | xper | pex | xp = level
uper | upper = level up
rusher = rush
puller = pull
kiter = kite
buffer = buff
stuffer = gear up
rezzer | rezer | ressusciter | réanimer | rez = res
wiper = wipe
recruter = recruit
voler = fly
défendre = defend
protéger | protégeer = protect
casser | briser = break
créer = create
crafter | fabriquer = craft
enchanter = enchant
réparer = repair
nettoyer | nettoier = clear
explorer = explore
marcher | fonctionner = work
sauter = jump
pêcher = fish
cuisiner = cook
miner = mine
récolter | ramasser = gather
rendre = turn in
valider | compléter = complete
accepter = accept
refuser = decline
annuler = cancel
demander = ask
répondre = answer
écouter = listen
appeler | appeller = call
chuchoter | wisper = whisper
crier = yell
signaler | reporter = report
ignorer = ignore
bloquer = block
supprimer | effacer = delete
charger | chargeer = load
redémarrer | relancer | rebooter = restart
connecter = connect
déconnecter | déco = disconnect
reconnecter | reloguer | relogger | reco = relog
loger | logger | loguer = log in
mettre | metre = put
dormir = sleep
venir = come
revenir = come back
tenir = hold
obtenir | récupérer = get
connaître | connaitre | connaissre = know
battre | batre = beat
recevoir = receive
partager | partageer = share
permettre | permetre = allow
rejoindre = join
choisir = choose
répéter = repeat
montrer = show
compter = count
coûter = cost
rappeler | rappeller = remind
oublier = forget
garder = keep
prévenir = warn
corriger = fix
équiper = equip
rassembler | regrouper | réunir = gather
provoquer | taunter = taunt
étourdir | stunner = stun
interrompre = interrupt
esquiver = dodge
tirer = shoot
invoquer | tper | tp = summon
téléporter = teleport
enlever | retirer = remove
apporter | ramener = bring
bouger | bougeer | déplacer = move
arrêter | stopper = stop
toucher = touch
vérifier | checker = check
tomber = fall
entendre = hear
sembler = seem
aimer | kiffer = like
adorer = love
préférer = prefer
ajouter = add
espérer = hope
expliquer = explain
skipper | skiper = skip
spammer = spam
focuser = focus
dispeller = dispel
# v3 (2026-11-16): verbs the real chat log used
sentir = smell
ressentir = feel
mener = lead
réussir | reussir = succeed
détester | detester = hate
découvrir | decouvrir = discover
regretter = regret
kiffer = love
galérer | galerer = struggle
ressusciter | ressuciter | rez = resurrect
voler = steal
crier = shout
]==])

-- suffix > infinitive ending = English template
-- French always writes the subject pronoun (je, tu, il, on ...), so most forms
-- give the bare verb and the pronoun comes from the dictionary.
L:Conjugation([==[
# -er: present, imperative
e > er = %s
es > er = you %s
ent > er = %s
ons > er = we %s
ez > er = you %s
# -er: passé composé participle
é > er = %en
ée > er = %en
és > er = %en
ées > er = %en
# -er: imparfait
ais > er = was %ing
ait > er = was %ing
aient > er = were %ing
ions > er = we were %ing
iez > er = you were %ing
# -er: futur, conditionnel
erai > er = will %s
eras > er = will %s
era > er = will %s
erons > er = will %s
erez > er = will %s
eront > er = will %s
erais > er = would %s
erait > er = would %s
eraient > er = would %s
erions > er = would %s
eriez > er = would %s
# -er: gerund
ant > er = %ing
# -ir like finir
is > ir = %s
it > ir = %s3
issons > ir = we %s
issez > ir = you %s
issent > ir = %s
i > ir = %en
ie > ir = %en
ies > ir = %en
issais > ir = was %ing
issait > ir = was %ing
issaient > ir = were %ing
issant > ir = %ing
irai > ir = will %s
iras > ir = will %s
ira > ir = will %s
irons > ir = will %s
irez > ir = will %s
iront > ir = will %s
irais > ir = would %s
irait > ir = would %s
# -ir like partir, ouvrir, venir
e > ir = %s
es > ir = you %s
ons > ir = we %s
ez > ir = you %s
ent > ir = %s
ais > ir = was %ing
ait > ir = was %ing
aient > ir = were %ing
ant > ir = %ing
u > ir = %en
ue > ir = %en
us > ir = %en
ert > rir = %en
erte > rir = %en
iens > enir = %s
ient > enir = %s3
iennent > enir = %s
iendrai > enir = will %s
iendras > enir = will %s
iendra > enir = will %s
iendrons > enir = will %s
iendrez > enir = will %s
iendront > enir = will %s
# -re
s > re = %s
t > re = %s3
d > dre = %s3
ons > re = we %s
ez > re = you %s
ent > re = %s
u > re = %en
ue > re = %en
us > re = %en
ais > re = was %ing
ait > re = was %ing
aient > re = were %ing
rai > re = will %s
ras > re = will %s
ra > re = will %s
rons > re = will %s
rez > re = will %s
ront > re = will %s
rais > re = would %s
rait > re = would %s
ant > re = %ing
]==])

-- Sentence templates. '*' is a slot of one or more words, translated on its own.
-- Two French habits shape this list:
--  * "pour" is left to the dictionary instead of being swallowed by a template
--    ("cherche groupe *" rather than "cherche groupe pour *"): the slot then reads
--    "for the Deadmines" or, with an infinitive, "to do the Deadmines".
--  * players often type "a" for "à"; a typed "a" never matches the literal "à",
--    so templates with "à" also list the unaccented spelling.
L:Patterns([==[
# ---- looking for / need ----
cherche groupe * | cherche grp * | recherche groupe * | ch groupe * | ch grp * | rech groupe * | cherche un groupe * | rech grp * = looking for group *
je cherche un groupe * | je cherche groupe * | je recherche un groupe * | je cherche un grp * = I'm looking for a group *
je cherche à * | je cherche a * | cherche à * | cherche a * | on cherche à * | on cherche a * = looking to *
je cherche * | je recherche * | je suis à la recherche de * | je suis a la recherche de * | j'cherche * = I'm looking for *
on cherche * | nous cherchons * | on recherche * | nous recherchons * = we're looking for *
cherche * | recherche * | ch * | rech * = looking for *
il me faut un * | il me faut une * | j'ai besoin d'un * | j'ai besoin d'une * | j'aurais besoin d'un * | j'aurais besoin d'une * = I need a *
il me faut * | il me faudrait * | me faut * | j'ai besoin de * | j'aurais besoin de * = I need *
il nous faut un * | il nous faut une * | on a besoin d'un * | on a besoin d'une * = we need a *
il nous faut * | il nous faudrait * | on a besoin de * | nous avons besoin de * | on aurait besoin de * = we need *
besoin d'un * | besoin d'une * | bsn d'un * | bsn d'une * = need a *
besoin de * | bsn de * = need *
il manque * | manque * | il nous manque * = need *
il me manque * | me manque * = I'm missing *
il manque plus que * | manque plus que * | il ne manque plus que * | il manque que * | manque que * | il reste plus que * = we only need *
il reste * | il en reste * = * left
y a quelqu'un * | il y a quelqu'un * | y a qqn * | il y a qqn * | ya quelqu'un * | ya qqn * | y'a quelqu'un * | y'a qqn * = is there anyone *
guilde * recrute | la guilde * recrute | guilde * recherche | la guilde * recherche | guilde * cherche | la guilde * cherche = guild * is recruiting
guilde à la recherche de * | guilde a la recherche de * | la guilde à la recherche de * | la guilde a la recherche de * = guild looking for *
guilde * à la recherche de * | guilde * a la recherche de * | la guilde * à la recherche de * | la guilde * a la recherche de * = guild * looking for *
recrute * | on recrute * | nous recrutons * | recrutons * = recruiting *
j'ai envie de * | envie de * | j'ai envie d'un * | j'ai envie d'une * = I want *
ça te dit de * | ça vous dit de * | ça te dirait de * | ça vous dirait de * | ca te dit de * | ca vous dit de * = do you want *
ça te dit * | ça vous dit * | ça te tente * | ça vous tente * | ça te dirait * | ça vous dirait * | ca te dit * | ca vous dit * = are you up for *

# ---- questions ----
quelqu'un sait où est * | qqn sait où est * | quelqu'un sait où se trouve * | qqn sait où se trouve * | qui sait où est * | quelqu'un saurait où est * | qqn saurait où est * | qui sait où se trouve * = does anyone know where * is
quelqu'un sait où sont * | qqn sait où sont * | qui sait où sont * | quelqu'un sait où se trouvent * | qqn sait où se trouvent * = does anyone know where * are
quelqu'un sait où * | qqn sait où * | qui sait où * | quelqu'un saurait où * | qqn saurait où * = does anyone know where *
quelqu'un sait comment * | qqn sait comment * | qui sait comment * | quelqu'un saurait comment * | qqn saurait comment * = does anyone know how *
quelqu'un sait si * | qqn sait si * | qui sait si * | quelqu'un saurait si * | qqn saurait si * = does anyone know if *
quelqu'un sait * | qqn sait * | quelqu'un connaît * | qqn connaît * | quelqu'un saurait * | qqn saurait * = does anyone know *
quelqu'un a * | qqn a * | quelqu'un aurait * | qqn aurait * | y a quelqu'un qui a * | quelqu'un possède * | qq1 a * = does anyone have *
quelqu'un veut * | qqn veut * | quelqu'un voudrait * | qqn voudrait * | qq1 veut * = does anyone want *
quelqu'un peut * | qqn peut * | quelqu'un pourrait * | qqn pourrait * | y a quelqu'un qui peut * | qq1 peut * = can anyone *
quelqu'un peut m'aider * | quelqu'un peut m'aider à * | qqn peut m'aider à * | quelqu'un peut m'aider a * | qqn peut m'aider a * | quelqu'un pourrait m'aider à * | qqn pourrait m'aider à * | quelqu'un pour m'aider à * | quelqu'un pour m'aider a * = can anyone help me *
quelqu'un peut m'emmener à * | qqn peut m'emmener à * | quelqu'un peut m'emmener a * | qqn peut m'emmener a * | quelqu'un peut m'amener à * | quelqu'un m'emmène à * | qqn m'emmène à * | quelqu'un peut me tp à * = can anyone take me to *
quelqu'un vend * | qqn vend * | y a quelqu'un qui vend * | quelqu'un vendrait * | qqn vendrait * = is anyone selling *
quelqu'un achète * | qqn achète * | y a quelqu'un qui achète * = is anyone buying *
quelqu'un qui * | qqn qui * | des gens qui * = anyone who *
qui veut * | qui voudrait * | qui veux * = who wants *
qui a * | qui aurait * = who has *
qui vend * = who is selling *
qui achète * = who is buying *
qui peut * | qui pourrait * = who can *
qui sait * | qui connaît * = who knows *
où est * | où se trouve * | où se situe * | c'est où * | il est où * | elle est où * = where is *
* est où | * c'est où | * se trouve où = where is *
où sont * | où se trouvent * | ils sont où * = where are *
* sont où | * se trouvent où = where are *
où trouver * | où je trouve * | où on trouve * | où je peux trouver * | où est ce que je trouve * | où peut on trouver * | on trouve où * | je trouve où * = where do I get *
où avoir * | où je peux avoir * | où on peut avoir * | où obtenir * | où on loot * | où drop * | où ça drop * | où récupérer * = where do I get *
où acheter * | où je peux acheter * | où on achète * | où est ce qu'on achète * | où s'achète * | où s'achètent * | on achète où * = where can I buy *
comment aller à * | comment on va à * | comment je vais à * | comment aller a * | comment on va a * | comment je vais a * | comment se rendre à * | c'est par où * = how do I get to *
comment aller au * | comment on va au * | comment je vais au * | comment aller aux * | comment se rendre au * = how do I get to the *
comment aller dans * | comment on va dans * | comment entrer dans * | comment on entre dans * | comment rentrer dans * | comment on rentre dans * = how do I get into *
comment faire pour * | comment on fait pour * | comment je fais pour * = how do I *
comment faire * | comment on fait * | comment je fais * = how do I do *
comment avoir * | comment on a * | comment obtenir * | comment on obtient * | comment récupérer * | comment on récupère * = how do I get *
combien pour * | c'est combien * | combien coûte * | combien coûtent * | combien vaut * | à combien * | a combien * | c combien * = how much is *
* c'est combien | * ça coûte combien | * ça vaut combien | * coûte combien | * c combien = how much is *
combien tu veux pour * | tu veux combien pour * | combien tu demandes pour * | tu en veux combien pour * | t'en veux combien pour * = how much do you want for *
combien tu donnes pour * | combien tu paies pour * | tu donnes combien pour * | tu paies combien pour * | combien tu payes pour * = how much will you pay for *
combien tu vends * | tu vends combien * | à combien tu vends * | a combien tu vends * | tu vends à combien * | tu vends a combien * = how much are you selling *
c'est quel niveau * | quel niveau est * | quel est le niveau de * | quel est le niveau du * | c quel niveau * | c'est quel lvl * = what level is *
à quelle heure * | a quelle heure * = what time *
tu peux * | tu pourrais * | vous pouvez * | vous pourriez * | peux tu * | pouvez vous * | tu peu * | tu peut * = can you *
tu veux * | vous voulez * | veux tu * | voulez vous * | tu veu * | tu voudrais * = do you want *

# ---- trade ----
je vends * pour * | vends * pour * | vend * pour * | vds * pour * | je vends * à * | vends * à * | vends * a * | vds * à * = selling * for *
vends * pas cher | vends * pas chère | vends * pas chers | je vends * pas cher | vds * pas cher | vend * pas cher = selling * cheap
je vends * | vends * | vend * | vds * | à vendre * | a vendre * = selling *
* à vendre | * a vendre = * for sale
j'achète * pour * | achète * pour * | ach * pour * | j'achète * à * | achète * à * | achète * a * | j'achète * a * = buying * for *
j'achète * | achète * | ach * | je cherche à acheter * | je cherche a acheter * | cherche à acheter * | cherche a acheter * = buying *
échange * contre * | j'échange * contre * | échange * pour * | troc * contre * | j'échange * pour * = trading * for *
je donne * pour * | je file * pour * | j'offre * pour * | je propose * pour * | je paie * pour * | je paye * pour * = I'll give * for *
je te donne * | je te file * | je te passe * | je vous donne * | j'te donne * = I'll give you *
donne moi * | donnez moi * | file moi * | filez moi * | passe moi * | passez moi * = give me *
je donne * | je distribue * | à donner * | a donner * = giving away *
meilleure offre pour * | meilleur prix pour * | faire offre pour * | faites vos offres pour * | offre pour * = best offer for *
j'ai * à vendre | j'ai * a vendre | j'ai * en vente = I have * for sale

# ---- statements ----
je dois * | faut que je * | il faut que je * | je vais devoir * | j'dois * = I have to *
tu dois * | vous devez * | faut que tu * | il faut que tu * | tu devrais * = you have to *
on doit * | nous devons * | il faut qu'on * | faut qu'on * | on devrait * = we have to *
j'ai pas * | je n'ai pas * | j'ai plus * | je n'ai plus * | j'ai pas de * | j'ai plus de * = I don't have *
j'ai déjà * = I already have *
je veux * | j'veux * | jveux * | je veu * = I want *
je veux pas * | je ne veux pas * | j'veux pas * | j'ai pas envie de * | pas envie de * = I don't want *
on veut * | nous voulons * = we want *
je peux * | j'peux * | jpeux * | je peut * = I can *
je peux pas * | je ne peux pas * | j'peux pas * | je peux plus * | j'arrive pas à * | j'arrive pas a * | je n'arrive pas à * | j'y arrive pas * = I can't *
on peut * | nous pouvons * = we can *
on peut pas * | on ne peut pas * | on peut plus * | on arrive pas à * | on arrive pas a * = we can't *
je sais pas * | je ne sais pas * | jsp * | j'sais pas * | chais pas * = I don't know *
je vais à * | je vais a * | j'vais à * | j'vais a * | je vais sur * | je vais chez * = I'm going to *
je vais au * | je vais aux * | j'vais au * | j'vais aux * = I'm going to the *
je vais dans * | j'vais dans * = I'm going into *
je vais * | j'vais * | jvais * = I'm going to *
on va faire * | on se fait * = let's do *
on va à * | on va a * | nous allons à * | nous allons a * = we're going to *
on va au * | on va aux * | nous allons au * = we're going to the *
on va dans * = we're going into *
on va * | nous allons * = let's *
tu vas * | vous allez * = you're going to *
il va * | elle va * = he's going to *
je suis à * | je suis a * | chui à * | chui a * | j'suis à * | j'suis a * = I'm at *
je suis au * | je suis aux * | chui au * | j'suis au * = I'm at the *
je suis dans * | chui dans * | j'suis dans * = I'm in *
on est à * | on est a * | nous sommes à * | nous sommes a * = we're at *
on est au * | on est aux * | nous sommes au * = we're at the *
on est dans * | nous sommes dans * = we're in *
je suis niveau * | je suis lvl * | chui lvl * | je suis level * | j'suis lvl * | chui niveau * | je suis niv * = I'm level *
merci pour * | merci bcp pour * | merci beaucoup pour * | merci encore pour * = thanks for *
désolé pour * | dsl pour * | pardon pour * | désolée pour * | désolé de * | dsl de * = sorry for *
y a pas de * | il y a pas de * | il n'y a pas de * | y a plus de * | il n'y a plus de * | ya pas de * | y'a pas de * = there is no *
je * pas = I don't *
tu * pas = you don't *
on * pas = we don't *
il * pas = he doesn't *
elle * pas = she doesn't *
ça * pas | ca * pas = it doesn't *
ils * pas | elles * pas = they don't *

# ---- movement, meeting, group and raid calls ----
invite moi dans * | invitez moi dans * | inv moi dans * | groupe moi dans * | invite moi sur * = invite me to *
aide moi à * | aide moi a * | aidez moi à * | aidez moi a * | tu peux m'aider a * | tu m'aides a * = help me *
attends moi à * | attends moi a * | attendez moi à * | attendez moi a * | attend moi à * | attend moi a * = wait for me at *
je t'attends à * | je t'attends a * | je vous attends à * | je vous attends a * | j't'attends à * = I'll wait for you at *
on t'attend à * | on t'attend a * | on vous attend à * | on vous attend a * = we're waiting for you at *
rdv à * | rdv a * | rendez vous à * | rendez vous a * | on se retrouve à * | on se retrouve a * | on se rejoint à * | on se rejoint a * = meet at *
rdv au * | rendez vous au * | on se retrouve au * | on se rejoint au * | rdv devant * | on se retrouve devant * = meet at the *
viens à * | viens a * | venez à * | venez a * | ramène toi à * | ramène toi a * = come to *
va à * | va a * | allez à * | allez a * | vas à * | vas a * = go to *
tuez * en premier | tue * en premier | tuez * d'abord | tue * d'abord | focus * en premier | focus * d'abord | on tue * en premier | on tue * d'abord = kill * first
tp * svp | tp * stp | invoque * svp | invoque * stp | invoc * svp | invoc * stp | invoquez * svp = summon * please
# ---- negation with ne ... pas (the written register) ----
je ne * pas | j'ne * pas = I don't *
tu ne * pas = you don't *
on ne * pas = we don't *
il ne * pas = he doesn't *
elle ne * pas = she doesn't *
ça ne * pas | ca ne * pas = it doesn't *
ils ne * pas | elles ne * pas = they don't *
vous ne * pas | vous * pas = you don't *
nous ne * pas | nous * pas = we don't *
ne * pas * = don't * *
ne * pas = don't *

# ---- things that do not work ----
ça marche pas * | ca marche pas * | ça fonctionne pas * | ca fonctionne pas * | ça marche plus * | ca marche plus * = * doesn't work
* marche pas | * ne marche pas | * fonctionne pas | * ne fonctionne pas | * marche plus | * ne marche plus = * doesn't work

# ---- where is ----
il est où * | elle est où * | il est ou * | elle est ou * = where is *
# ---- negation followed by an object or a second verb ----
je * pas * | j'* pas * = I don't * *
tu * pas * = you don't * *
on * pas * = we don't * *
il * pas * = he doesn't * *
elle * pas * = she doesn't * *
ça * pas * | ca * pas * = it doesn't * *
ils * pas * | elles * pas * = they don't * *
vous * pas * = you don't * *
je ne * pas * = I don't * *
tu ne * pas * = you don't * *
on ne * pas * = we don't * *
il ne * pas * = he doesn't * *
elle ne * pas * = she doesn't * *
ils ne * pas * | elles ne * pas * = they don't * *
vous ne * pas * = you don't * *
n'oublie pas de * | oublie pas de * | n'oubliez pas de * | oubliez pas de * | noublie pas de * | noubliez pas de * = don't forget to *
n'oublie pas * | oublie pas * | n'oubliez pas * | oubliez pas * = don't forget *
# ---- a noun subject with a negated irregular verb ----
* veut pas * | * ne veut pas * = * doesn't want *
* veut pas | * ne veut pas = * doesn't want to
* peut pas * | * ne peut pas * = * can't *
* peut pas | * ne peut pas = * can't
* sait pas * | * ne sait pas * = * doesn't know *
* sait pas | * ne sait pas = * doesn't know
* comprend pas * | * ne comprend pas * = * doesn't understand *
* comprend pas | * ne comprend pas = * doesn't understand
* a pas * | * n'a pas * = * doesn't have *
* a pas | * n'a pas = * doesn't have
* est pas * | * n'est pas * = * isn't *
* est pas là | * n'est pas là | * est pas la | * n'est pas la = * isn't here
* fait pas * | * ne fait pas * = * doesn't do *
* va pas * | * ne va pas * = * isn't going *
* vient pas * | * ne vient pas * = * isn't coming *
* vient pas | * ne vient pas = * isn't coming
* répond pas | * ne répond pas | * repond pas = * doesn't answer
* bouge pas | * ne bouge pas = * isn't moving
* marche pas * | * ne marche pas * = * doesn't work *
# ---- slang pass (2026-11-13): fr_8.txt, fr_9.txt ----
quelqu'un parle * | quelqun parle * | qqn parle * | y a quelqu'un qui parle * | ya quelqu'un qui parle * | il y a quelqu'un qui parle * | qui parle * | quelqu'un qui parle * = does anyone speak *
tu parles * | vous parlez * | tu parle * | parles tu * | parlez vous * | parles-tu * | parlez-vous * = do you speak *
des * ici | y a des * ici | ya des * ici | il y a des * ici | des * là | des * dans le coin = any * here
je parle pas * | je ne parle pas * | jparle pas * | parle pas * | je parle pas du tout * | je ne parle pas du tout * = I don't speak *
je parle que * | je ne parle que * | jparle que * | je parle seulement * | je parle juste * | je parle uniquement * = I only speak *
en * stp | en * svp | en * s'il te plait | en * s'il vous plait | en * s'il te plaît | en * s'il vous plaît = in * please
# ---- slang pass (2026-11-13): fr_1.txt, fr_2.txt ----
putain de * | ptn de * | putin de * | bordel de * | saloperie de * | foutu * | foutue * | sale * = fucking *
espèce de * | espece de * | bande de * | gros * | grosse * | sale * va = you *
* de merde | * de mrd | * à la con | * a la con | * tout pourri | * tout pourrie | * pourri = shitty *
osti de * | esti de * | criss de * | crisse de * | câlisse de * | calisse de * | tabarnak de * | maudit * = fucking *
genre * | en mode * | style * = like *
trop * de ouf | trop * là | trop * la = way too *
* ou quoi | * ou koi | * ou kwa | * ou bien quoi = * or what
* ou pas | * ou pas ? = * or not
t'es * ou quoi | tes * ou quoi | t * ou quoi | t'es * ou koi | tes * ou koi = are you * or what
c'est * ça | c * ça | c'est * ca | c * ca | c * sa | c'est * sa = that's * right there
arrête de * | arrete de * | arrêtez de * | arretez de * | stop de * | arrete un peu de * = stop *
tkt pour * | tkt pr * | t'inquiète pour * | tinquiete pour * = don't worry about *
osef de * | osef du * | osef des * | balec de * | balek de * | rien à foutre de * | rien a foutre de * = who cares about *
j'ai le seum de * | jai le seum de * | g le seum de * = I'm gutted about *
on se fait * ? | on se fait un * ? | on se fait une * ? | ça vous dit * ? | ca vous dit * ? = anyone up for *
qui est chaud pour * | qui est chaud * | ki est chaud pour * | qui veut * ? | ki veut * = who's up for *
ya quelqu'un pour * | y'a quelqu'un pour * | y a quelqu'un pour * | ya qqn pour * | y'a qqn pour * | y a qqn pour * | qqn pour * | quelqu'un pour * = anyone for *
le * là | la * là | le * la | la * la | les * là | les * la = that *
* c'est mort | * c mort | * cest mort = * no way
* de base | * à la base | * a la base = * originally
* vite fait | * vite fais | * viteuf | * rapidos | * rapido | * en vitesse | * en speed = * quickly
]==])

-- Respelling rules for the fuzzy layer (Fuzzy.lua). Each rule turns a word
-- no lookup knows (lower case, accents folded away) into one candidate that
-- is looked up like any other word; the first candidate the dictionary knows
-- wins. They only run once the line is known to be French.
L:Respell([==[
# SMS consonants: koi, ki, kel, kan, kestion
k > qu
k > c
# a sound written as heard: moa, toa, kroa
oa > oi
# a silent final letter left out: mieu, tro, bocou, chapo
$ > x
$ > s
$ > t
$ > p
$ > e
$ > d
$ > r
# a silent h left out: abitude, eure, aricot
^ > h
# -eau written as -o: bato, chato, nivo
o$ > eau
# ph and f
f > ph
ph > f
]==])
