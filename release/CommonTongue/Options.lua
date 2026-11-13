-- CommonTongue / Options.lua
--
-- The options panel (Esc > Options > AddOns > CommonTongue, or /tongue with
-- no arguments). Built from plain widgets so it works on every modern
-- client; every control reads its state from the saved variables when the
-- panel is shown and writes it back on change, so the slash commands and
-- the panel never disagree.
--
-- Public API:
--   B:SetupOptions()   build and register the panel (once, at ADDON_LOADED)
--   B:OpenOptions()    open it

local B = CommonTongue

local panel
local refreshers = {}   -- functions that re-read the saved variables into the widgets

--- A static text label.
local function label(parent, text, x, y, font)
  local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetText(text)
  return fs
end

--- A check box bound to a boolean setting through get/set functions.
local function check(parent, text, x, y, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetSize(26, 26)
  local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  fs:SetText(text)
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
    B:ClearCache()
  end)
  refreshers[#refreshers + 1] = function() cb:SetChecked(get()) end
  return cb
end

--- A push button; when isSelected is given it is drawn highlighted while
-- the setting it represents is the current one.
local function button(parent, text, x, y, w, onClick, isSelected)
  local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  btn:SetPoint("TOPLEFT", x, y)
  btn:SetSize(w, 22)
  btn:SetText(text)
  btn:SetScript("OnClick", function()
    onClick()
    B:ClearCache()
    for _, r in ipairs(refreshers) do r() end
  end)
  if isSelected then
    refreshers[#refreshers + 1] = function()
      if isSelected() then btn:LockHighlight() else btn:UnlockHighlight() end
    end
  end
  return btn
end

--- Build the panel and register it with the client's settings UI.
function B:SetupOptions()
  panel = CreateFrame("Frame")
  panel.name = "CommonTongue"
  panel:Hide()

  label(panel, "CommonTongue " .. B.Version, 16, -16, "GameFontNormalLarge")
  label(panel, "Translates chat written in other languages into yours. Blue: built in, instant. Green: machine translation.", 16, -40, "GameFontHighlightSmall")

  local y = -70
  check(panel, "Enable translation", 16, y,
    function() return B.db.enabled end, function(v) B.db.enabled = v end)
  check(panel, "Show language tag  [es>en]", 220, y,
    function() return B.db.showTag end, function(v) B.db.showTag = v end)
  check(panel, "Translate my own messages", 420, y,
    function() return B.db.translateSelf end, function(v) B.db.translateSelf = v end)

  -- Target language --------------------------------------------------------
  y = y - 40
  label(panel, "Translate into:", 16, y)
  y = y - 20
  local codes = { "en" }
  for _, code in ipairs(B.LanguageOrder) do codes[#codes + 1] = code end
  local col, row, perRow, w = 0, 0, 7, 82
  for _, code in ipairs(codes) do
    local name = (code == "en") and "English" or B.Languages[code].name
    button(panel, name, 16 + col * (w + 4), y - row * 26, w,
      function() B.db.target = code end,
      function() return B.db.target == code end)
    col = col + 1
    if col >= perRow then col, row = 0, row + 1 end
  end
  y = y - (row + (col > 0 and 1 or 0)) * 26 - 10

  -- Display mode -----------------------------------------------------------
  label(panel, "Show translation:", 16, y)
  y = y - 20
  local modes = { { "inline", "Inline  (original [translation])" }, { "below", "On the line below" }, { "replace", "Replace the original" } }
  for i, m in ipairs(modes) do
    button(panel, m[2], 16 + (i - 1) * 204, y, 200,
      function() B.db.mode = m[1] end,
      function() return B.db.mode == m[1] end)
  end
  y = y - 36

  -- Minimum coverage slider ------------------------------------------------
  local minLabel = label(panel, "", 16, y)
  local slider = CreateFrame("Slider", nil, panel)
  slider:SetOrientation("HORIZONTAL")
  slider:SetPoint("TOPLEFT", 16, y - 20)
  slider:SetSize(300, 16)
  slider:SetMinMaxValues(0, 100)
  slider:SetValueStep(5)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local bg = slider:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  if bg.SetColorTexture then bg:SetColorTexture(0.15, 0.15, 0.15, 0.8) else bg:SetTexture(0.15, 0.15, 0.15, 0.8) end
  local function updateMinLabel()
    minLabel:SetText(("Only show a translation when at least %d%% of the words were understood"):format((B.db.minCoverage or 0) * 100))
  end
  slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value / 5 + 0.5) * 5
    B.db.minCoverage = value / 100
    updateMinLabel()
    B:ClearCache()
  end)
  refreshers[#refreshers + 1] = function()
    slider:SetValue((B.db.minCoverage or 0) * 100)
    updateMinLabel()
  end
  y = y - 50

  -- Channels ---------------------------------------------------------------
  label(panel, "Translate these channels:", 16, y)
  y = y - 22
  local names = {
    SAY = "Say", YELL = "Yell", GUILD = "Guild", OFFICER = "Officer", PARTY = "Party", RAID = "Raid",
    INSTANCE = "Instance / BG", WHISPER = "Whisper", CHANNEL = "Numbered channels (General, Trade, LFG...)",
    EMOTE = "Emote", BN_WHISPER = "Battle.net whisper",
  }
  col, row = 0, 0
  for _, key in ipairs(B.CHANNEL_ORDER) do
    local wide = (key == "CHANNEL")
    check(panel, names[key], 16 + col * 150, y - row * 26,
      function() return B.db.channels[key] end, function(v) B.db.channels[key] = v end)
    col = col + (wide and 2 or 1)
    if col >= 4 then col, row = 0, row + 1 end
  end
  y = y - (row + 1) * 26 - 12

  -- Live translation --------------------------------------------------------
  check(panel, "Live machine translation: when the CommonTongue companion is running, add its translation to each chat line", 16, y,
    function() return B.db.live ~= false end,
    function(v)
      B.db.live = v
      if v then B.Bridge:EnsureLogging(); B.Bridge:Probe(true) else B.Bridge.live = false end
    end)
  y = y - 26
  check(panel, "Keep chat logging on (needed by the companion's overlay window)", 16, y,
    function() return B.db.companion end, function(v) B:SetCompanion(v) end)
  y = y - 30
  label(panel, "Slash commands: /tongue help    Speak another language: /tsay es <text>, /tparty de <text>, /twhisper Name fr <text>", 16, y, "GameFontHighlightSmall")

  panel:SetScript("OnShow", function() for _, r in ipairs(refreshers) do r() end end)

  -- modern settings API first, the pre-Dragonflight one as a fallback
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "CommonTongue")
    Settings.RegisterAddOnCategory(category)
    B.optionsCategory = category
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
  B.optionsPanel = panel
end

--- Open the panel, or print the status when no settings UI is available.
function B:OpenOptions()
  if B.optionsCategory and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(B.optionsCategory:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory and B.optionsPanel then
    -- the old API needs two calls to land on the right page the first time
    InterfaceOptionsFrame_OpenToCategory(B.optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(B.optionsPanel)
  else
    B:Status()
  end
end
