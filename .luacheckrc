-- luacheck configuration for the addon (run: luacheck CommonTongue)
std = "lua51"
max_line_length = false
codes = true

-- the addon's own globals
globals = {
  "CommonTongue",      -- the addon table (created in UTF8.lua)
  "CommonTongueDB",    -- saved variables
  "SLASH_COMMONTONGUE1", "SLASH_COMMONTONGUE2",
  "SLASH_TONGUESAY1", "SLASH_TONGUEYELL1", "SLASH_TONGUEPARTY1", "SLASH_TONGUERAID1",
  "SLASH_TONGUEGUILD1", "SLASH_TONGUEWHISPER1", "SLASH_TONGUEWHISPER2", "SLASH_TONGUEPREVIEW1",
}

-- WoW API the addon reads
read_globals = {
  "C_AddOns", "C_ChatInfo", "C_Timer", "ChatFrameUtil", "ChatFrame_AddMessageEventFilter",
  "ChatFrame_OpenChat", "CreateFrame", "DEFAULT_CHAT_FRAME", "ChatFrame1", "Constants",
  "NUM_CHAT_WINDOWS", "GetAddOnMetadata", "GetLocale", "GetTime", "InterfaceOptions_AddCategory",
  "InterfaceOptionsFrame_OpenToCategory", "LoggingChat", "SendChatMessage", "Settings",
  "SlashCmdList", "UnitName", "issecretvalue", "time",
}

-- generated and data files
exclude_files = { "CommonTongue/Dict/*.lua", "CommonTongue/Grammar/*.lua", "CommonTongue/Learned.lua", "release/", "dist/" }

ignore = {
  "212/self",   -- unused self in methods kept for a uniform call style
  "212/_.*",    -- underscore-prefixed unused arguments
}
