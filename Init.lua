-- UnitMode: Core initialization, saved variables, slash commands

UnitMode = {}
local UM = UnitMode

local DEFAULTS = {
    enabled      = false,
    unitKey      = nil,
    coreSlots    = { 1, 2, 3, 4 },
    ultimateSlot = 5,
    minimapAngle = math.pi / 4,  -- default: upper-right
}

-- ── Event handling ────────────────────────────────────────────────────────────

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "UnitMode" then
        UM:InitDB()
    elseif event == "PLAYER_LOGIN" then
        UM.MinimapBtn:Init()
        if UM.db.enabled then
            UM.ActionBar:Apply()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Secure frames unlock on combat exit; reapply our overlay state
        if UM.db.enabled then
            UM.ActionBar:Apply()
        end
    end
end)

-- ── SavedVariables ────────────────────────────────────────────────────────────

function UM:InitDB()
    if not UnitModeDB then
        UnitModeDB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if UnitModeDB[k] == nil then
            UnitModeDB[k] = v
        end
    end
    -- Deep-copy table defaults (coreSlots)
    if type(UnitModeDB.coreSlots) ~= "table" then
        UnitModeDB.coreSlots = { 1, 2, 3, 4 }
    end
    if type(UnitModeDB.customUnits) ~= "table" then
        UnitModeDB.customUnits = {}
    end
    self.db = UnitModeDB
end

-- ── Slash commands ────────────────────────────────────────────────────────────

SLASH_UNITMODE1 = "/unitmode"
SLASH_UNITMODE2 = "/um"

SlashCmdList["UNITMODE"] = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "enable" then
        UM.db.enabled = true
        UM.ActionBar:Apply()
        print("|cff33ff99[UnitMode]|r Enabled.")

    elseif msg == "disable" then
        UM.db.enabled = false
        UM.ActionBar:Reset()
        print("|cff33ff99[UnitMode]|r Disabled — bars restored.")

    elseif msg == "reset" then
        UM.ActionBar:Reset()
        print("|cff33ff99[UnitMode]|r Action bars reset.")

    elseif msg == "status" then
        local unitName = UM.db.unitKey and UM.Units.library[UM.db.unitKey] and
                         UM.Units.library[UM.db.unitKey].name or "None"
        print(string.format("|cff33ff99[UnitMode]|r Enabled: %s | Unit: %s",
            tostring(UM.db.enabled), unitName))

    else
        UM.UI:Toggle()
    end
end
