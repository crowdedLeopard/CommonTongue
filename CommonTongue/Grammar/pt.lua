-- CommonTongue / Grammar/pt.lua  —  Portuguese verbs, conjugation and sentence templates
-- (Brazilian chat first, European Portuguese forms alongside)
local L = CommonTongue.Languages.pt
if not L then return end

-- object pronouns that stand before the verb ("me puxa", "te chamo", "o matei");
-- "já" behaves the same way: "já cheguei" reads "I'm here already"
L:Clitics([==[
o | a = it
os | as = them
lhe = him
lhes = them
me = me
te = you
nos = us
vos = you
se = ~
já = already
]==])

-- infinitive | spelling-changed or stem-changed pseudo-infinitive = English base verb
-- ("paguar" does not exist; it lets "paguei", "pague" resolve to "pagar";
--  ç/c needs no alternative because accents are folded: "comecei" finds "começar")
L:Verbs([==[
# -ar
matar = kill
curar | healar = heal
procurar = look for
precisar = need
ajudar = help
comprar = buy
pagar | paguar = pay
trocar | troquar = trade
esperar | aguardar = wait
entrar = enter
chegar | cheguar = arrive
levar = take
deixar = leave
pegar | peguar = get
usar = use
olhar = look
falar = talk
jogar | joguar = play
ganhar = win
chamar | convidar | invitar = invite
rolar = roll
kickar | kikar | expulsar = kick
começar | iniciar = start
terminar | acabar = finish
tentar = try
pensar = think
achar = find
mandar | enviar = send
ficar | fiquar = stay
passar = pass
voltar | retornar = come back
fechar = close
tomar = take
andar | caminhar = walk
pular | saltar = jump
nadar = swim
voar = fly
montar = set up
tankar | tancar | tanquar = tank
farmar = farm
lootar | lootear | looteiar | saquear | saqueiar = loot
dropar = drop
upar | levelar = level
rushar = rush
pullar | puxar = pull
kitar = kite
buffar | bufar = buff
ressar | ressuscitar | ressucitar = res
craftar | fabricar | fabriquar = craft
criar = create
bugar | buguar = bug
lagar | laguar = lag
logar | loguar = log in
deslogar | desloguar = log out
relogar | reloguar = log back in
wipar = wipe
nerfar = nerf
trollar = troll
ninjar = ninja
gankar = gank
campar = camp
focar | foquar = focus
resetar = reset
linkar = link
summonar | sumonar | invocar | invoquar = summon
tauntar | provocar | provoquar = taunt
stunar | atordoar = stun
dispelar | dissipar = dispel
aggrar | agrar = aggro
stackar | stacar = stack
solar = solo
boostar = boost
carregar | carreguar = carry
raidar = raid
grindar = grind
spawnar = spawn
respawnar = respawn
crashar = crash
travar = lock up
bloquear | bloqueiar = block
hackear | hackeiar = hack
mutar = mute
reportar | denunciar = report
ignorar = ignore
deletar | apagar | apaguar = delete
salvar = save
guardar = keep
baixar = download
instalar = install
atualizar = update
reiniciar = restart
funcionar | trabalhar = work
testar = test
clicar | cliquar = click
apertar = press
digitar = type
ligar | liguar = turn on
desligar | desliguar = turn off
conectar = connect
desconectar = disconnect
descansar = rest
acordar = wake up
conversar = chat
brincar | brinquar = joke
gostar = like
amar | adorar = love
lembrar | recordar = remember
avisar | contar = tell
perguntar = ask
explicar | expliquar = explain
mostrar = show
ensinar = teach
emprestar = lend
gastar = spend
custar = cost
encontrar = find
buscar | busquar | arranjar = get
apanhar = pick up
colocar | coloquar | botar = put
tirar = remove
soltar = release
largar | larguar = drop
virar = turn
parar = stop
mudar = change
continuar = continue
checar | chequar | verificar | verifiquar = check
marcar | marquar = mark
limpar = clear
duelar = duel
lutar = fight
caçar = hunt
pescar | pesquar = fish
cozinhar = cook
minerar = mine
coletar = gather
esfolar = skin
encantar | enchantar = enchant
desencantar | dezar = disenchant
portar = port
teleportar = teleport
reparar | consertar = repair
melhorar = improve
equipar = equip
formar = form
juntar = gather
recrutar = recruit
entregar | entreguar = turn in
completar = complete
aceitar = accept
recusar = decline
cancelar = cancel
compartilhar = share
escutar = listen
sussurrar | whispar = whisper
gritar = yell
xingar | xinguar = insult
reclamar = complain
errar = miss
acertar = hit
critar = crit
atirar = shoot
esquivar | desviar = dodge
roubar = steal
quebrar = break
lançar | castar | conjurar = cast
derrotar = defeat
segurar = hold
afastar = move away
recuar = fall back
espalhar = spread out
levantar = get up
recuperar = recover
demorar = take long
# -er
vender = sell
correr = run
comer = eat
beber = drink
aprender = learn
escrever = write
viver = live
morrer = die
perder = lose
receber = receive
conhecer = know
vencer = defeat
esquecer = forget
aparecer = appear
nascer = spawn
acontecer = happen
oferecer = offer
agradecer = thank
descer = go down
escolher = choose
responder = answer
entender = understand
defender = defend
proteger = protect
bater = hit
mexer | mover = move
esconder = hide
interromper = interrupt
sobreviver = survive
reviver = res
perceber = notice
resolver = solve
querer = want
saber = know
fazer = do
dizer = say
trazer = bring
# -ir
abrir = open
sair = leave
cair = fall
seguir = follow
conseguir = manage
pedir = ask for
repetir | repitir = repeat
preferir | prefirir = prefer
dormir = sleep
subir | sobir = go up
fugir = run away
sumir = disappear
dividir = divide
decidir = decide
permitir = allow
desistir = give up
existir = exist
resistir = resist
banir = ban
ouvir = hear
assistir = watch
reunir = gather
]==])

-- suffix > infinitive ending = English template
-- The bare -a / -e forms serve "você", "a gente" and the imperative in Brazilian
-- chat ("vc tanka?", "a gente farma", "pulla o boss"), so they give the base verb.
L:Conjugation([==[
# -ar
o > ar = I %s
as > ar = you %s
a > ar = %s
amos > ar = we %ed
ámos > ar = we %ed
am > ar = %s
ei > ar = I %ed
aste > ar = you %ed
ou > ar = %ed
aram > ar = %ed
ava > ar = was %ing
avas > ar = you were %ing
ávamos > ar = we were %ing
avam > ar = were %ing
arei > ar = I'll %s
arás > ar = you'll %s
ará > ar = will %s
aremos > ar = we'll %s
arão > ar = will %s
aria > ar = would %s
ariam > ar = would %s
ando > ar = %ing
ado > ar = %en
ada > ar = %en
ados > ar = %en
adas > ar = %en
e > ar = %s
es > ar = %s
em > ar = %s
armos > ar = we %s
arem > ar = %s
ares > ar = you %s
# -er
o > er = I %s
es > er = you %s
e > er = %s
emos > er = we %ed
em > er = %s
i > er = I %ed
este > er = you %ed
eu > er = %ed
eram > er = %ed
ia > er = was %ing
ias > er = you were %ing
íamos > er = we were %ing
iam > er = were %ing
erei > er = I'll %s
erás > er = you'll %s
erá > er = will %s
eremos > er = we'll %s
erão > er = will %s
eria > er = would %s
eriam > er = would %s
endo > er = %ing
ido > er = %en
ida > er = %en
idos > er = %en
idas > er = %en
a > er = %s
am > er = %s
ermos > er = we %s
erem > er = %s
eres > er = you %s
# -ir
o > ir = I %s
es > ir = you %s
e > ir = %s
imos > ir = we %ed
em > ir = %s
i > ir = I %ed
iste > ir = you %ed
iu > ir = %ed
iram > ir = %ed
ia > ir = was %ing
ias > ir = you were %ing
íamos > ir = we were %ing
iam > ir = were %ing
irei > ir = I'll %s
irás > ir = you'll %s
irá > ir = will %s
iremos > ir = we'll %s
irão > ir = will %s
iria > ir = would %s
iriam > ir = would %s
indo > ir = %ing
ido > ir = %en
ida > ir = %en
idos > ir = %en
idas > ir = %en
a > ir = %s
am > ir = %s
irmos > ir = we %s
irem > ir = %s
ires > ir = you %s
]==])

-- Sentence templates. '*' is a slot of one or more words, translated on its own.
-- Literals are accent-folded ("alguem" matches "alguém", "e" matches "é"), except
-- that a typed English word only matches a literal spelled the same way, so
-- tô / só / à are listed with their plain spellings to / so / a as well.
-- pra / para / pro / p are different words and are listed separately.
-- "pra" + verb is the usual way to say "to do something", so where a slot after
-- pra/para is normally a dungeon or a role the English says "for", and where it is
-- normally a verb ("preciso de ajuda pra *") the English says "to".
L:Patterns([==[
# ---- looking for group / people ----
procuro grupo pra * | procuro grupo para * | procuro pt pra * | procuro pt para * | procurando grupo pra * | procurando grupo para * | procurando pt pra * | procuro party pra * | lf grupo pra * | lf pt pra * | procuro grupo p * | procuro pt p * = looking for group for *
procuro gente pra * | procuro gente para * | procurando gente pra * | procuramos gente pra * | procuro pessoas pra * | procuro galera pra * | procuro pessoal pra * = looking for people for *
procuro * pra fazer * | procuro * para fazer * | procurando * pra fazer * = looking for * to do *
procuro * pra * | procuro * para * | procurando * pra * | procurando * para * | procuro * p * = looking for * for *
procuro * | procurando * | busco * = looking for *
procuramos * pra * | procuramos * para * = we're looking for * for *
procuramos * = we're looking for *
procura-se * para * | procura-se * pra * | procuram-se * para * | precisa-se de * para * | precisa-se * para * = looking for * for *
ando à procura de * | ando a procura de * | estou à procura de * | estou a procura de * | tou à procura de * | tou a procura de * | andamos à procura de * | andamos a procura de * | estamos à procura de * | estamos a procura de * = I'm looking for *
procura-se * | procuram-se * | precisa-se de * | precisa-se * | à procura de * | a procura de * = looking for *
grupo pra fazer * | grupo para fazer * | pt pra fazer * | pt para fazer * = group to do *
lfg pra * = lfg for *
lfm pra * = lfm for *
tank pra * | tanque pra * | tanker pra * = tank for *
healer pra * | heal pra * | curandeiro pra * | curandeiro para * = healer for *
dps pra * | dd pra * = dps for *
vaga pra * | vaga para * | vagas pra * | vagas para * = spot for *
tem vaga pra * | tem vaga para * | tem vagas pra * | ainda tem vaga pra * | ainda tem vaga para * = is there a spot for *
alguém pra fazer * | alguém para fazer * | alguém p fazer * = anyone to do *
alguém pra ajudar * | alguém pra me ajudar * | alguém para ajudar * | alguém para me ajudar * = can anyone help *
alguém pra tankar * | alguém para tankar * = anyone to tank *
alguém pra healar * | alguém pra curar * | alguém para curar * = anyone to heal *
alguém pra matar * | alguém para matar * = anyone to kill *
alguém pra * | alguém para * | alguém p * = anyone for *
alguém afim de * | alguém a fim de * | alguém afim de fazer * | alguém anima * | quem anima * | alguém topa * | quem topa * | alguém bora * = anyone up for *
mais um pra * | mais um para * | só mais um pra * | so mais um pra * = one more for *

# ---- need / missing ----
preciso de ajuda pra * | preciso de ajuda para * | preciso de uma ajuda pra * | preciso de ajuda p * = I need help to *
preciso de ajuda com * | preciso de ajuda em * | preciso de uma ajuda com * = I need help with *
preciso de ajuda na * | preciso de ajuda no * | preciso de ajuda nas * | preciso de ajuda nos * | preciso de uma ajuda na * | preciso de uma ajuda no * = I need help with the *
preciso de * pra fazer * | preciso de * para fazer * = I need * to do *
preciso de * pra * | preciso de * para * | preciso de * p * = I need * for *
preciso de * | preciso * = I need *
precisamos de * pra * | precisamos de * para * | a gente precisa de * pra * = we need * for *
precisamos de * | precisamos * | a gente precisa de * = we need *
falta um pra fechar | falta mais um pra fechar | só falta um pra fechar | so falta um pra fechar | falta só um pra fechar | falta so um pra fechar = need one more to fill the group
falta um pra * | falta mais um pra * | só falta um pra * | so falta um pra * | falta só um pra * | falta so um pra * | falta um para * = need one more for *
falta * pra fechar | faltam * pra fechar | falta * pra completar | faltam * pra completar | falta * para fechar = need * more to fill the group
falta * pra * | faltam * pra * | falta * para * | faltam * para * | falta * p * | faltando * pra * = need * for *
falta * | faltam * | faltando * = need *
só falta * | so falta * | só faltam * | so faltam * | falta só * | falta so * | faltam só * | faltam so * | falta apenas * = we only need *
ainda falta * | ainda faltam * = still need *
me falta * | me faltam * = I'm missing *
nos falta * | nos faltam * = we're missing *

# ---- guild ----
guilda * recrutando | guilda * recruta | guilda * está recrutando | guilda * tá recrutando | a guilda * recruta | a guilda * está recrutando | guild * recrutando | guild * recruta = guild * is recruiting
guilda * procura * | guilda * busca * | guilda * precisa de * = guild * is looking for *
estamos recrutando * para * | estamos recrutando * pra * | recrutamos * para * | recrutando * para * | recrutando * pra * = recruiting * for *
estamos recrutando * | recrutamos * | recrutando * = recruiting *

# ---- questions: anyone ----
alguém sabe onde fica * | alguém sabe onde é * | alguém sabe onde está * | alguém sabe onde tá * | alguém sabe aonde fica * | alguém sabe onde ficam * | alguém sabe onde estão * = does anyone know where * is
alguém sabe onde pego * | alguém sabe onde consigo * | alguém sabe onde dropa * | alguém sabe onde acho * | alguém sabe onde encontro * | alguém sabe onde arranjo * | alguém sabe onde tem * = does anyone know where to get *
alguém sabe onde compro * | alguém sabe onde compra * | alguém sabe onde vende * = does anyone know where to buy *
alguém sabe onde * = does anyone know where *
alguém sabe como chego em * | alguém sabe como chegar em * | alguém sabe como chego a * | alguém sabe como ir pra * | alguém sabe como vou pra * | alguém sabe chegar em * = does anyone know how to get to *
alguém sabe como chego no * | alguém sabe como chego na * | alguém sabe como chegar no * | alguém sabe como chegar na * | alguém sabe como chego ao * = does anyone know how to get to the *
alguém sabe como * = does anyone know how *
alguém sabe se * = does anyone know if *
alguém sabe quanto custa * | alguém sabe quanto tá * | alguém sabe o preço de * | alguém sabe o preço do * | alguém sabe o preço da * = does anyone know how much * is
alguém sabe * = does anyone know *
alguém tem * pra vender | alguém tem * para vender | alguém tem * à venda | alguém tem * a venda = does anyone have * for sale
alguém tem * = does anyone have *
alguém quer * = does anyone want *
alguém pode me ajudar com * | alguém me pode ajudar com * | alguém me ajuda com * | alguém pode ajudar com * | alguém ajuda com * | alguém me ajuda em * | alguém pode me ajudar em * | alguém podia ajudar com * = can anyone help me with *
alguém pode me ajudar na * | alguém pode me ajudar no * | alguém me pode ajudar na * | alguém me pode ajudar no * | alguém me ajuda na * | alguém me ajuda no * | alguém pode ajudar na * | alguém pode ajudar no * | alguém ajuda na * | alguém ajuda no * = can anyone help me with the *
alguém pode me ajudar a * | alguém me ajuda a * | alguém ajuda a * = can anyone help me *
alguém pode me levar pra * | alguém me leva pra * | alguém me leva até * | alguém pode me levar até * | alguém me leva em * | alguém me leva para * = can anyone take me to *
alguém pode me dar * | alguém me dá * | alguém tem como me dar * = can anyone give me *
alguém me arranja * | alguém me consegue * | alguém me arruma * | alguém me faz * = can anyone get me *
alguém pode * | alguém consegue * | alguém podia * | alguém poderia * = can anyone *
alguém vende * | alguém vendendo * | alguém tá vendendo * = is anyone selling *
alguém compra * | alguém comprando * | alguém quer comprar * = is anyone buying *
alguém faz * = can anyone do *
alguém fazendo * | alguém tá fazendo * | alguém vai fazer * = is anyone doing *
alguém encanta * | alguém pode encantar * = can anyone enchant *
alguém abre * | alguém pode abrir * = can anyone open *
alguém summona * | alguém dá summon * | alguém pode summonar * = can anyone summon *
alguém tanka * | alguém pode tankar * = can anyone tank *
alguém heala * | alguém cura * | alguém pode healar * | alguém pode curar * = can anyone heal *
alguém upando em * | alguém upando no * | alguém upando na * | alguém questando em * = anyone leveling in *
alguém que * = anyone who *
tem grupo pra * | tem pt pra * | tem grupo para * | tem algum grupo pra * | tem alguma pt pra * = is there a group for *
alguém fala * | alguém aqui fala * | alguém aí fala * = does anyone speak *
tem alguém que * = is there anyone who *
tem alguém * = is there anyone *
tem como alguém * | dá pra alguém * = can anyone *

# ---- questions: who / where / how / how much ----
quem quer * = who wants *
quem tem * = who has *
quem vende * | quem tá vendendo * = who is selling *
quem compra * = who is buying *
quem pode * | quem consegue * = who can *
quem sabe * = who knows *
quem vai pra * | quem vai para * | quem vai no * | quem vai na * = who's going to *
quem vai * = who will *
quem precisa de * | quem precisa * = who needs *
onde fica * | onde é * | onde está * | onde tá * | aonde fica * | cadê * | onde que fica * = where is *
onde ficam * | onde estão * | onde tão * = where are *
cadê os * | cadê as * = where are the *
onde tem * | onde acho * | onde encontro * | onde eu acho * | onde eu encontro * | onde posso achar * | onde posso encontrar * = where can I find *
onde pego * | onde consigo * | onde dropa * | onde arranjo * | onde eu pego * | onde eu consigo * | onde se pega * | onde posso pegar * | onde posso conseguir * | onde farmo * | aonde pego * | aonde consigo * = where do I get *
onde compro * | onde eu compro * | onde posso comprar * | onde se compra * | onde vende * | onde vendem * = where can I buy *
onde entrego * | onde eu entrego * | onde se entrega * = where do I turn in *
onde upo no lvl * | onde upar no lvl * | onde upo no nível * | onde upar no nível * | onde eu upo no lvl * | onde upo com lvl * = where should I level at level *
onde upo * | onde upar * | onde eu upo * | onde posso upar * = where should I level *
como chego em * | como chego a * | como chego até * | como vou pra * | como vou para * | como faço pra chegar em * | como faz pra chegar em * | como chegar em * | como se chega a * | como eu chego em * | como ir pra * = how do I get to *
como chego no * | como chego na * | como chego ao * | como chego nas * | como chego nos * | como vou pro * | como faço pra chegar no * | como faço pra chegar na * | como chegar no * | como chegar na * | como eu chego no * | como eu chego na * = how do I get to the *
como faço pra * | como faço para * | como eu faço pra * | como faz pra * | como faz para * | como fazer pra * | como fazer para * | como faço p * = how do I *
como faço * | como faz * | como se faz * | como eu faço * = how do I do *
como consigo * | como pego * | como eu pego * | como eu consigo * | como se consegue * | como arranjo * = how do I get *
quanto custa * | quanto tá * | quanto está * | quanto é * | quanto vale * | quanto sai * | qnt custa * | qnt tá * | qto custa * | qual o preço de * | qual o preço do * | qual o preço da * = how much is *
quanto por * | qnt por * | quanto pelo * | quanto pela * = how much for *
quanto você quer por * | quanto vc quer por * | quanto quer por * | quanto tu quer por * | quanto queres por * | quanto vc quer no * | quanto vc quer na * | quanto tá pedindo por * | quanto vc tá pedindo por * = how much do you want for *
quanto você paga por * | quanto vc paga por * | quanto paga por * | quanto pagas por * | quanto vc dá por * | quanto dá por * = how much will you pay for *
quanto tempo pra * | quanto tempo para * | quanto tempo falta pra * | quanto falta pra * = how long until *
que nível é * | que lvl é * | qual o nível de * | qual o nível do * | qual o nível da * | qual nível de * | qual lvl de * | qual o lvl de * | qual o lvl do * | qual o lvl da * = what level is *
qual lvl pra entrar em * | qual nível pra entrar em * | que lvl pra entrar em * | que nível pra entrar em * | qual lvl pra entrar no * | qual lvl pra entrar na * | qual nível pra entrar no * | qual nível pra entrar na * | qual lvl precisa pra entrar em * = what level to enter *
qual lvl pra fazer * | qual nível pra fazer * | que lvl pra fazer * | que nível pra fazer * = what level to do *
qual nível pra * | qual lvl pra * | que nível pra * | que lvl pra * | qual o nível pra * | qual o lvl pra * | qual nível para * | que nível precisa pra * | qual lvl precisa pra * | qual lvl mínimo pra * = what level for *
que horas é * | que horas vai ser * | que horas começa * | a que horas é * | a que horas começa * = what time is *
que horas * | a que horas * = what time *
qual o melhor * | qual a melhor * | qual é o melhor * | qual é a melhor * = what's the best *
qual é o * | qual é a * | qual o * | qual a * = what's the *

# ---- requests ----
me ajuda com * | me ajuda em * | me ajudem com * | me ajuda aqui com * | ajuda aqui com * | ajuda aí com * = help me with *
me ajuda na * | me ajuda no * | me ajudem na * | me ajudem no * | me ajuda aqui na * | me ajuda aqui no * | ajuda aqui na * | ajuda aqui no * = help me with the *
me ajuda a * | me ajudem a * | me ajuda aqui a * = help me *
tem como me ajudar * | dá pra me ajudar * | tem como ajudar * | dá pra ajudar * = can you help me *
tem como * | dá pra * | tem jeito de * | será que dá pra * | teria como * | tem como vc * | tem como você * = can you *
você pode * | vc pode * | tu pode * | podes * | você consegue * | vc consegue * | consegues * | vc poderia * | você poderia * = can you *
você quer * | vc quer * | tu quer * | queres * | vcs querem * | vocês querem * = do you want *
você tem * | vc tem * | tu tem * | vcs tem * = do you have *
você vai pra * | vc vai pra * | vc vai para * | vc vai no * | vc vai na * | tu vai pra * | vcs vão pra * | vais pra * | vais para * | vais ao * = are you going to *
você vai * | vc vai * | tu vai * | vais * | vcs vão * | vocês vão * = will you *
você sabe * | vc sabe * | tu sabe * = do you know *
você vende * | vc vende * | tu vende * = are you selling *
me convida pra * | me convida pro * | me convida para * | convida-me para * | convidar-me para * | convidem-me para * | me chama pra * | me chama pro * | me invita pra * | convida pra * | chama pra * | inv pra * | convite pra * | invite pra * = invite me to *
me leva pra * | me leva para * | me leva até * | me leva em * | me leva no * | me leva na * = take me to *
espera o * | espera os * | espera as * | esperem o * | esperem a * | esperem os * | espera pelo * | espera pela * = wait for the *
esperando o * | esperando os * | esperando as * | esperando pelo * | esperando pela * = waiting for the *
vem pra * | vem para * | vem pro * | venham pra * | vem aqui pra * | vem aqui em * | cola em * | cola no * | cola na * = come to *
vai pra * | vai para * | vão pra * | vão para * = go to *
vai pro * | vai no * | vai na * | vai ao * | vão pro * = go to the *
volta pra * | volta para * | voltem pra * | volta pro * = go back to *

# ---- trade ----
vendo * por * | vendo * a * | vendendo * por * = selling * for *
vendo * barato | vendo * barata | vendo * baratos | vendo * baratas | vendo * baratinho = selling * cheap
vendo * = selling *
vende-se * | vendem-se * = selling *
compro * por * | compro * a * = buying * for *
compro * = buying *
compra-se * = buying *
troco * por * = trading * for *
troco * = trading *
dou * por * | dou * pelo * | dou * pela * | ofereço * por * = I'll give * for *
pago * pra quem * | pago * para quem * | pago * a quem * | dou * pra quem * | dou * a quem * = paying * to whoever *
pago * por * | pago * pelo * | pago * pela * = paying * for *
dou * = I'll give *
faço * de graça | faço * grátis = I'll do * for free
faço * por * = I'll do * for *
melhor oferta por * | melhor oferta pelo * | melhor oferta pela * | melhor oferta leva * = best offer for *
sussurra pra * | manda pv pra * | chama no pv pra * | pv pra * | pm pra * | whisper pra * = whisper me for *
alguém interessado em * | alguém tem interesse em * = anyone interested in *

# ---- statements ----
tenho * pra vender | tenho * para vender | tenho * à venda | tenho * a venda = I have * for sale
tenho * pra * | tenho * para * = I have * for *
tenho que * | tenho q * | tenho de * | vou ter que * = I have to *
temos que * | temos q * | temos de * | a gente tem que * | a gente tem q * | vamos ter que * = we have to *
você tem que * | vc tem que * | vc tem q * | tu tem que * | tens de * | tens que * = you have to *
não tenho * | n tenho * = I don't have *
já tenho * | eu já tenho * = I already have *
não tem * | n tem * | não há * = there is no *
quero * = I want *
não quero * | n quero * = I don't want *
gostaria de * = I'd like *
não consigo * | n consigo * | não tô conseguindo * | não to conseguindo * | não estou conseguindo * = I can't *
não posso * | n posso * = I can't *
não sei * | n sei * = I don't know *
vou * = I'll * | I'm going to *
vou pra * | vou para * | vou até * = I'm going to *
vou pro * | vou no * | vou na * | vou ao * = I'm going to the *
tô indo pra * | to indo pra * | estou indo pra * | indo pra * | tô indo para * | to indo para * | indo para * | tou a ir para * = on my way to *
tô indo pro * | to indo pro * | estou indo pro * | indo pro * | tô indo no * | to indo no * | tô indo na * | to indo na * = on my way to the *
vou de * = I'll go as *
não vou poder * | n vou poder * | não vou conseguir * = I won't be able to *
não vou * | n vou * = I won't *
não vai * | n vai * = won't *
vai ter * = there will be *
vai * | vão * = will *
a gente vai pra * | a gente vai para * | a gente vai no * | a gente vai na * = we're going to *
a gente vai * = we'll *
bora * | bora lá * = let's *
bora pra * | vamos pra * | vamo pra * | bora para * | partiu * = let's go to *
bora pro * | vamos pro * | vamos na * | bora no * | bora na * | vamos ao * = let's go to the *
vamos fazer * | bora fazer * | vamo fazer * = let's do *
tô em * | to em * | estou em * | tou em * | tô aqui em * | to aqui em * = I'm in *
chegando em * | chegando no * | chegando na * = almost at *
estamos em * | tamo em * | tamos em * | a gente tá em * = we're in *
sou nível * | sou lvl * | sou level * | tô nível * | to nível * | tô no nível * | to no nível * | estou no nível * | estou lvl * | tou lvl * = I'm level *
obrigado por * | obrigada por * | valeu por * | vlw por * | brigado por * | obg por * = thanks for *
obrigado pela * | obrigado pelo * | obrigada pela * | obrigada pelo * | valeu pela * | valeu pelo * | vlw pela * | vlw pelo * | brigado pela * | obg pela * | obg pelo * = thanks for the *
desculpa por * | desculpe por * | foi mal por * | desculpa pelo * | desculpa pela * | foi mal pelo * | foi mal pela * = sorry for *
desculpa a * | desculpa o * | desculpem a * | desculpem o * = sorry for the *
parabéns por * | parabéns pelo * | parabéns pela * | gz pelo * | gz pela * = congrats on *
cuidado com * | atenção com * = watch out for *

# ---- dungeon and raid calls ----
precisamos de mais * pra * | precisa de mais * pra * | falta mais * pra * | faltam mais * pra * | precisamos de mais * para * = need * more for *
todo mundo no * | todo mundo na * | geral no * | geral na * = everyone on the *
summona * pfv | summona * por favor | dá summon em * pfv | dá summon em * por favor = summon * please
pronto pra * | prontos pra * | pronta pra * | pronto para * | prontos para * | rdy pra * | pronto p * = ready to *
pronto pro * | prontos pro * | pronto pra o * | prontos pra o * = ready for the *
mata * primeiro | matem * primeiro | foca * primeiro | foquem * primeiro = kill * first
foca no * | foca na * | foquem no * | foquem na * = focus the *
bate no * | bate na * | batam no * | batam na * = attack the *
cura no * | cura na * | heala no * | heala na * = heal the *
dá summon no * | dá summon na * | summona no * | summona na * = summon the *
# ---- slang pass (2026-11-13): pt_9.txt ----
alguém fala * | alguem fala * | alguém aqui fala * | alguem aqui fala * | tem alguém que fala * | tem alguem que fala * | quem fala * | alguém que fale * | alguem que fale * | tem alguém que fale * = does anyone speak *
você fala * | vc fala * | tu falas * | falas * | vocês falam * | vcs falam * = do you speak *
não falo * | nao falo * | n falo * | eu não falo * | eu nao falo * | não falamos * | nao falamos * | não falo nada de * = I don't speak *
só falo * | so falo * | falo só * | falo so * | eu só falo * | eu so falo * = I only speak *
em * por favor | em * pfv | em * pf | em * plz | em * pls = in * please
# ---- slang pass (2026-11-13): pt_1.txt, pt_2.txt ----
# ---- slang frames ----
que * é esse | que * é essa | q * é esse | q * é essa | que * eh esse | que * eh essa | q * eh esse | q * eh essa | que * é isso | q * é isso | que * eh isso | q * eh isso = what the * is this
* do caralho | * do krl | * da porra | * do cacete | * dos infernos | * do inferno | * do caraças | * do catano = fucking *
deixa de ser * | para de ser * | não seja * | nao seja * | n seja * | deixem de ser * | parem de ser * = stop being *
para de * | parem de * | pára de * | deixa de * | deixem de * | larga de * | larga mão de * = stop *
quem foi que * | quem foi q * | quem que * | quem q * | quem é que * | quem eh que * | quem é q * | quem eh q * = who *
quem tá * | quem ta * | quem está * | quem esta * | quem tão * | quem tao * | quem estão * | quem estao * = who's *
bora de * | vamo de * | partiu de * | vamos de * = let's do *
bora um * | bora uma * | vamo um * | vamo uma * | partiu um * | partiu uma * | bora fazer um * | bora fazer uma * = let's do a *
bora * logo | vamo * logo | vamos * logo | bora logo * | vamo logo * = let's * already
tem * aí | tem * ai | tem * aqui | tem * por aí | tem * por ai | tem algum * aí | tem algum * ai | tem alguma * aí | tem alguma * ai = any * around
tô sem * | to sem * | tou sem * | estou sem * | fiquei sem * | tô zerado de * | to zerado de * = I'm out of *
tamo sem * | tamos sem * | estamos sem * | ficamos sem * | a gente tá sem * | a gente ta sem * | a gente ficou sem * = we're out of *
chega de * | basta de * | já deu de * | ja deu de * | já chega de * | ja chega de * | para com esse * | para com essa * = enough *
cansei de * | cansei desse * | cansei dessa * | tô cansado de * | to cansado de * | tou farto de * | estou farto de * | farto de * | tô de saco cheio de * | to de saco cheio de * | de saco cheio de * | cansado de * = I'm sick of *
olha o * | olha a * | oia o * | oia a * | olha os * | olha as * | se liga no * | se liga na * | olha esse * | olha essa * | olha só o * | olha só a * = look at the *
me passa * | me passa o * | me passa a * | passa * aí | passa * ai | passa * pra mim | passa o * pra mim | passa a * pra mim = pass me *
* nenhum | * nenhuma | nenhum * | nenhuma * | nem um * | nem uma * = no * at all
* é zoeira | * eh zoeira | * é brinks | * eh brinks | * é piada | * eh piada | * é zueira | * eh zueira | * é moleza | * eh moleza = * is a joke
tá * demais | ta * demais | está * demais | tá * dms | ta * dms | tá * pra caramba | ta * pra caramba | tá * pra krl | ta * pra krl | tá * pra caralho | ta * pra caralho | tá * pra kct = it's really *
* e tal | * e tals | * e tal né | * e coisa e tal | * e coisa | * e tudo mais | * e essas coisas = * and stuff
* ou algo assim | * ou algo do tipo | * ou coisa assim | * ou coisa do tipo | * ou sei lá | * ou sla | * ou algo | * ou alguma coisa | * ou qualquer coisa | * ou qlqr coisa = * or something
alguém vivo em * | alguem vivo em * | tem alguém vivo em * | tem alguem vivo em * | alguém em * | alguem em * | tem alguém em * | tem alguem em * | alguém aí em * | alguem ai em * = anyone in *
pago * no * | pago * na * | dou * no * | dou * na * | pago * nesse * | pago * nessa * = paying * for the *
aceito * | aceito até * | aceito ate * | aceito a partir de * | fecho por * | fecho em * | fecho a * = I'll take *
# ---- slang pass (2026-11-13): pt_2.txt ----
# ---- slang frames ----
que * é esse | que * é essa | q * é esse | q * é essa | que * eh esse | que * eh essa | q * eh esse | q * eh essa | que * é isso | q * é isso | que * eh isso | q * eh isso = what the * is this
* do caralho | * do krl | * da porra | * do cacete | * dos infernos | * do inferno | * do caraças | * do catano = fucking *
deixa de ser * | para de ser * | não seja * | nao seja * | n seja * | deixem de ser * | parem de ser * = stop being *
para de * | parem de * | pára de * | deixa de * | deixem de * | larga de * | larga mão de * = stop *
quem foi que * | quem foi q * | quem que * | quem q * | quem é que * | quem eh que * | quem é q * | quem eh q * = who *
quem tá * | quem ta * | quem está * | quem esta * | quem tão * | quem tao * | quem estão * | quem estao * = who's *
bora de * | vamo de * | partiu de * | vamos de * = let's do *
bora um * | bora uma * | vamo um * | vamo uma * | partiu um * | partiu uma * | bora fazer um * | bora fazer uma * = let's do a *
bora * logo | vamo * logo | vamos * logo | bora logo * | vamo logo * = let's * already
tem * aí | tem * ai | tem * aqui | tem * por aí | tem * por ai | tem algum * aí | tem algum * ai | tem alguma * aí | tem alguma * ai = any * around
tô sem * | to sem * | tou sem * | estou sem * | fiquei sem * | tô zerado de * | to zerado de * = I'm out of *
tamo sem * | tamos sem * | estamos sem * | ficamos sem * | a gente tá sem * | a gente ta sem * | a gente ficou sem * = we're out of *
chega de * | basta de * | já deu de * | ja deu de * | já chega de * | ja chega de * | para com esse * | para com essa * = enough *
cansei de * | cansei desse * | cansei dessa * | tô cansado de * | to cansado de * | tou farto de * | estou farto de * | farto de * | tô de saco cheio de * | to de saco cheio de * | de saco cheio de * | cansado de * = I'm sick of *
olha o * | olha a * | oia o * | oia a * | olha os * | olha as * | se liga no * | se liga na * | olha esse * | olha essa * | olha só o * | olha só a * = look at the *
me passa * | me passa o * | me passa a * | passa * aí | passa * ai | passa * pra mim | passa o * pra mim | passa a * pra mim = pass me *
* nenhum | * nenhuma | nenhum * | nenhuma * | nem um * | nem uma * = no * at all
* é zoeira | * eh zoeira | * é brinks | * eh brinks | * é piada | * eh piada | * é zueira | * eh zueira | * é moleza | * eh moleza = * is a joke
tá * demais | ta * demais | está * demais | tá * dms | ta * dms | tá * pra caramba | ta * pra caramba | tá * pra krl | ta * pra krl | tá * pra caralho | ta * pra caralho | tá * pra kct = it's really *
* e tal | * e tals | * e tal né | * e coisa e tal | * e coisa | * e tudo mais | * e essas coisas = * and stuff
* ou algo assim | * ou algo do tipo | * ou coisa assim | * ou coisa do tipo | * ou sei lá | * ou sla | * ou algo | * ou alguma coisa | * ou qualquer coisa | * ou qlqr coisa = * or something
alguém vivo em * | alguem vivo em * | tem alguém vivo em * | tem alguem vivo em * | alguém em * | alguem em * | tem alguém em * | tem alguem em * | alguém aí em * | alguem ai em * = anyone in *
pago * no * | pago * na * | dou * no * | dou * na * | pago * nesse * | pago * nessa * = paying * for the *
aceito * | aceito até * | aceito ate * | aceito a partir de * | fecho por * | fecho em * | fecho a * = I'll take *
]==])

-- Respelling rules for the fuzzy layer (Fuzzy.lua): each makes one candidate
-- from a word no lookup knows (accents folded), once the line is known to be
-- Portuguese. The first candidate the dictionary knows wins.
L:Respell([==[
# naum, entaum
aum$ > ao
# SMS consonants: ki, ke, aki, kem
k > qu
k > c
# x/ch, ss/s and final letters as heard: faze, muitu, noiti, oje
x > ch
ch > x
ss > s
s > ss
$ > r
$ > s
u$ > o
i$ > e
^ > h
]==])
