# Changelog

All notable changes to CommonTongue. The format follows Keep a Changelog;
versions follow the `## Version` line of the TOC.

## 3.0.0 - 2026-11-16

Built-in translation that copes with the way people really type in chat.

### Added
- A fuzzy layer (`Fuzzy.lua`) that runs once a line's language is known and
  resolves the words no lookup knows: missing apostrophes (`cest`, `jregarde`,
  `daccord`), per-language respelling rules (`koi`, `kestion`, `aki`, `fuer`,
  `naum`, `perke`), typos (a letter dropped, doubled, swapped or next to the
  right key: `tyrouve`, `paser`, `serveru`, `minde`, `cherhce`) and compounds
  in the Germanic languages (`heilergruppe` = healer group, `groepsleider` =
  group leader). Corrections are made in place before templates and phrases
  run, so `je cherhce un groupe` still meets the "I'm looking for a group"
  template. Detection never uses the layer: English and neutral lines stay
  untouched.
- English words inside a foreign line (`outlook est down`, `fake news`,
  `need 1 tank pour ...`) are passed through and no longer count as unknown,
  so such lines are shown and `/tongue missing` lists real gaps only.
- Phrases typed with stretched letters (`au revoiiiir`) are recognised.
- `L:Respell` blocks for French, Spanish, Portuguese, Italian, German, Dutch,
  Swedish, Danish, Norwegian and Finnish, documented in the grammar guide.
- A fuzzy corpus (`tools/tests/ct_fuzzy_cases.txt`: 144 chat spellings from
  the real chat log, player names removed, 30 of them English lines that must
  stay untouched) and `tools/tests/ct_fuzzy_check.py`, which prints the hit
  rate per category: 97%.
- French: the basic function words (`le la de du un une en y qui que par ma
  ...`) are stopwords, so French lines with few content words are no longer
  read as Spanish or Italian; about 200 entries from the real chat log (SMS
  forms such as `chai pas`, `vla`, `cava`, `kestufé`, `tes où`; the `a`/`à`
  homograph before determiners and pronouns; `terre`, `poisson`, `hauteur`,
  `réussi`, `plutôt`, `carrière`, `question` and other gaps; the client's
  "Emplacement marqué sur la carte" map pin line) and twelve verbs (`sentir`,
  `mener`, `réussir`, `détester`, `découvrir` ...). German and Spanish
  entries for the shared map pin line (the localised strings could not be
  verified against those clients). Swedish `tyvärr`.

### Fixed
- The client's shared map pin line (`|A:Waypoint-MapPin-ChatIcon...|a
  Emplacement marqué sur la carte`) was read as Spanish ("sur" = south) and
  hidden as shaky. The atlas markup itself was already stripped.
- Stretched letters no longer count as characteristic letter pairs
  (`Saluuuuut` is French, not four Dutch `uu`).
- Conjugation rules are indexed by their last letter, so a word is only tried
  against the rules that can match it: 0.78 → 0.59 ms per line even with the
  fuzzy pass.

### Quality
- Replaying the real chat log: 195 → 208 lines translated, 22 → 11 hidden,
  9 → 8 without a language, every one of the 614 English lines unchanged.
  "Yéti, y es-tu ?", "vive la raclette", "La réserve volée de ...", "Oula le
  dérapage" and the map pin line are French now; "le pupu" is hidden.
- Load 0.75 s, 36.5 MB of Lua memory, 0.59 ms per new chat line, nothing per
  frame. 116 unit tests, `misdetected: 0`, parity `0 mismatches`, bridge
  `ALL PASSED`.

## 2.0.0 - 2026-11-13

First public release for World of Warcraft: Forever (interface 16001).

### Added
- Built-in translation into English for 17 languages: Spanish, Portuguese,
  French, Italian, German, Dutch, Swedish, Norwegian, Danish, Finnish, Polish,
  Turkish, Russian, Ukrainian, Chinese, Korean and Japanese, from about
  151,000 dictionary entries with game slang and chat spelling.
- Sentence templates, phrase tables, verb conjugation, object pronouns,
  noun/adjective reordering and English post-editing.
- Language detection by script and by explanation; English lines and
  language-neutral shorthand are left alone.
- Inline, below-the-line and replace display modes, a language tag, a minimum
  understanding threshold, per-channel settings, an options panel and the
  `/tongue` commands.
- `/tsay`, `/tyell`, `/tparty`, `/traid`, `/tguild`, `/twhisper` and `/tprev`
  to speak in another language.
- Translation memory (`Learned.lua`), player-taught entries (`/tongue teach`)
  and a record of unknown words (`/tongue missing`).
- Optional live bridge: a companion program (Google, DeepL, LibreTranslate or
  offline Argos) adds machine translations to chat lines a second after they
  appear, through load-on-demand slot addons and the client's chat log.
- An icon in the AddOn list.

### Quality
- Replaying real General chat from the Forever launch week fixed: emoticons
  and lone letters being translated, "JESUS CHRIST" read as French,
  stretched shouts ("yoooooo") read as Spanish, Portuguese "le" as "read",
  Dutch "praten", "aan", "natuurlijk" and "wat bedoel je", and about a hundred
  missing French words; a line with little evidence for its language and many
  unknown words is no longer shown.
- Login load time 0.73 s, 36 MB, about 0.8 ms per chat line, nothing per frame.
- Every module documented; the slash commands are a command table; the version
  is read from the TOC; the chat filter, the bridge and every command run
  under `pcall`.
- Companion: slot files are written under a lock, memory save errors are
  reported instead of crashing, `/tsay` requests are accepted only from the
  player's own whispers, an invalid `--target` is rejected at start, and every
  WoW client executable name is recognised.
- Installer copies to a staging folder and swaps it in, and reads the
  interface number from the TOC.
- Test harness: pass/fail unit tests (`ct_unit.py`), a leaked-globals check,
  a chat-log replay and a missing-word check.

### Known limits
- Chat in dungeons, raids and battlegrounds is hidden from addons by the
  client and is not translated.
- Translations are literal; the goal is to understand what is being
  discussed, not fluent prose. Proper names, item names and heavy
  abbreviations stay as they are.
- Chat-log flushing for the companion has only been verified once per
  session in the live client; later flushes are unconfirmed.
