# CurseForge listing text

Paste the two parts below into the project's Summary and Description fields.

## Summary (one line)

Shows an English translation next to chat written in other languages, right in the chat frame. Works offline, 17 languages, no setup. Good enough to follow what people are talking about.

## Description

**CommonTongue adds a translation to chat lines written in another language, on the same line, in the same chat frame.** Nothing to configure, nothing to run alongside the game: install it and the next French, Dutch or Spanish line in General chat gets its English meaning appended in blue.

```
[1. General] Zirok: pour un chaman heal cest mieu de prendre quelle metier ? [fr>en: for a shaman healer it's better to take which profession ?]
```

**Languages:** Spanish, Portuguese, French, Italian, German, Dutch, Swedish, Norwegian, Danish, Finnish, Polish, Turkish, Russian, Ukrainian, Chinese, Korean and Japanese, all into English. Lines that are already in English are left alone.

**What to expect.** This is not Google Translate, and it does not pretend to be. The addon carries its own dictionaries and grammar for each language (about 150,000 entries, with a lot of game slang and the way people actually type in chat) and works out the meaning itself, inside the game, with nothing sent anywhere. The result is often fluent, sometimes clumsy and literal, and now and then wrong. That is a deliberate trade: the goal of version 2 is to **give you a sense of what is being discussed**, so a guild advert, a trade offer or a joke in a language you don't read is no longer a wall of noise. When it has understood too little of a line, it says nothing rather than guess.

Each release improves the dictionaries, mostly from real chat: lines the addon could not handle are collected (without names, nothing leaves your computer) and worked into the next version. If a translation is bad, post the original line and what it should have said: that is the most useful thing you can do for the addon.

**Performance.** Dictionaries load once at login in under a second and use about 36 MB. A new chat line costs about a millisecond. Nothing runs per frame, so there is no effect on frame rate.

**Limits worth knowing.**

- In dungeons, raids and PvP matches the game client hides chat from addons, so nothing is translated there.
- Proper names, item names and heavy abbreviations are often left as they are.
- It translates for reading. The `/tsay`, `/tparty`, `/tguild` and `/twhisper` commands let you send a message translated into another language, but treat that as a courtesy, not a conversation.

**Commands.** `/tongue` opens the options (channels, colour, minimum confidence, tag on or off). `/tongue status` shows what is loaded, `/tongue test` runs a quick self-check.

**Optional: live machine translation.** A small companion program (Python, runs on your PC, download it separately from the project links) can add real machine translations from Google, DeepL, LibreTranslate or an offline Argos install, in green, a second after the line appears. The addon remembers every sentence the companion translated, so those come back instantly next time, with or without the companion. The addon itself never needs it.

Built for World of Warcraft: Forever. Feedback and bad-translation reports are very welcome.
