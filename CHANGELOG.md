# Changelog

All notable changes to CommonTongue. The format follows Keep a Changelog;
versions follow the `## Version` line of the TOC.

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
