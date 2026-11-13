-- CommonTongue / Dict/en.lua
-- English is the pivot language. It has no dictionary of its own, only the
-- stopwords used to recognise English (so it is left alone) and the list of
-- gaming terms that belong to no language at all.

local B = CommonTongue

-- English is registered so that detection can score it, but it is skipped by
-- the translator (see Engine.lua: from/to "en" needs no dictionary).
local L = B:RegisterLanguage("en", "English", {
  native = "English",
  stopwords = [==[
    the a an and or but is are am was were be been being i you he she it we they
    me him her us them my your his its our their mine yours this that these those
    what which who whom whose where when why how not no yes do does did done
    have has had can could will would should may might must shall to of in on at
    by for with from about into over after before up down out off if then than so
    because as until while there here all any some many much more most few other
    another such only own same very just also too now later again always never
    please thanks thank sorry hello hi hey bye need want looking anyone someone
    somebody help selling buying going come get got give take know think let make
    run quest group guild level gold dungeon invite ready wait where's what's
    i'm you're we're they're it's don't can't won't isn't aren't didn't doesn't
    im dont cant wont ive youre thats whats im lets let's gonna wanna
    anybody everyone nobody something nothing everything one two three
    today tonight tomorrow yesterday soon right left back still already yet
    good bad new old big small fast slow cheap free full nice great
    go goes went gone coming came see saw seen look looks looked make makes made says said
    tell told ask asked try tried use used using find found keep kept put play played
    playing start started stop stopped kill killed killing pull pulled heal healing tanking
    join joined leave left stay follow wait waiting buy sell trade pay paid send sent
    like liked love hate feel work works working doing having getting giving taking
    way time times thing things stuff place people guys guy man dude bro team friend friends
    game world life day days week night hour hours minute minutes sec second
    first last next best better worse worst same different easy hard long short high low
    sure maybe probably really actually still even though though yet since until while
    well okay yeah yep yup nope nah hmm oh ah wow hey haha hehe lmao omg wtf
    please thanks thx sorry welcome congrats grats
    with without within around through between against under above below near far
    who's that's there's here's he's she's let's i'll you'll we'll they'll i'd you'd
    i've you've we've they've wasn't weren't hasn't haven't wouldn't couldn't shouldn't
    its it's im i'm ill id ive
    need needs needed want wants wanted looking look anyone anybody someone somebody everyone
    got gotta gonna wanna kinda lets
    more less much many few lot lots some any every each all both either neither none
    up down left right back front inside outside top bottom
    yes no not never always often sometimes already again soon later now today tonight tomorrow
    how what when where why which who whose whom
    one two three four five six seven eight nine ten
  ]==],
})

-- Words used in every language's chat that should never count against a
-- translation, nor be translated.
B:AddNeutral([==[
  lfg lfm lf lft lfh lfd lf1m lf2m lf3m wts wtb wtt pst inv invite tank heal healer heals
  dps dd afk brb bio gg wp gl hf ty tyvm np omw otw bg bgs pvp pve rp mc bwl zg aq
  aq20 aq40 naxx ony onyxia kara sm smc dm dmw dme dmn rfc wc bfd sfk gnomer rfk
  rfd uld ulda zf mara mauradon st brd lbrs ubrs strat scholo dire maul kazzak
  raid dungeon boss mob mobs buff buffs debuff cd cds oom lvl lv lol xd xdd rofl lmao
  gold g k hp mana pt rdy rez res ress mats ench enchant enchanting prof profs
  pal pala lock sham shammy druid rogue mage priest warrior warlock hunter
  paladin shaman hunt war pvpers alt alts main toon gm mod admin ok okay
  ninja noob newb nub pro n1 gj gz grats gratz cya cu l8r ty thx thanx plz pls
  pm whisper wisp w dm discord ts
  http https www com net org
  hs hearth port portal summon summ sum lock summons
  wipe wiped aggro taunt kite los cc stun sheep poly fear root
  tbc wotlk classic retail forever
  ap sp mp5 int str agi sta spi crit haste def
  bop boe bis bis-list pre-bis
  wtf omg brb afk gtg g2g
  op nerf nerfed imba meta proc procs dot dots aoe cleave add adds trash spec respec
  stack stacks gank ganked twink boost carry loot drop mount farm grind ding gear
  yo yoo ahh ahhh aha hmm hm meh oof yikes jesus christ badum tss
  haha hahaha hehe hihi jaja jajaja xaxa kek
]==])
