-- UnitMode: WC3-style portrait overlay
-- Draggable frame anchored near the action bar, shows class icon + unit info.

UnitMode.Portrait = {}
local Portrait = UnitMode.Portrait

local PORTRAIT_W = 210
local PORTRAIT_H = 76

local FACTION_COLORS = {
    ["Alliance"]  = { 0.25, 0.6,  1.0 },
    ["Horde"]     = { 1.0,  0.2,  0.1 },
    ["Undead"]    = { 0.6,  0.2,  0.85 },
    ["Night Elf"] = { 0.3,  0.9,  0.5 },
}
local FALLBACK_COLOR = { 0.8, 0.8, 0.8 }

-- Reliable spell icons that exist in every Classic build
local CLASS_ICONS = {
    ["Warrior"] = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
    ["Paladin"] = "Interface\\Icons\\Spell_Holy_HolyBolt",
    ["Priest"]  = "Interface\\Icons\\Spell_Holy_WordFortitude",
    ["Mage"]    = "Interface\\Icons\\Spell_Holy_MagicCommandeering",
    ["Rogue"]   = "Interface\\Icons\\Ability_Stealth",
    ["Hunter"]  = "Interface\\Icons\\Ability_Hunter_SteadyShot",
    ["Warlock"] = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    ["Shaman"]  = "Interface\\Icons\\Spell_Nature_Lightning",
    ["Druid"]   = "Interface\\Icons\\Ability_Druid_Moonfire",
}
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local frame = nil

-- ── Frame construction ────────────────────────────────────────────────────────

local function MakeFrame()
    local f = CreateFrame("Frame", "UnitModePortraitFrame", UIParent, "BackdropTemplate")
    f:SetSize(PORTRAIT_W, PORTRAIT_H)
    -- Default position: just right of the player unit frame
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 230, 4)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(5)

    -- Background — dark tooltip-style backdrop
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0.04, 0.04, 0.07, 0.94)
    f:SetBackdropBorderColor(0.5, 0.4, 0.1, 1)  -- gold-ish WC3 border

    -- Faction accent stripe along the left edge
    local stripe = f:CreateTexture(nil, "BORDER")
    stripe:SetWidth(4)
    stripe:SetPoint("TOPLEFT",    f, "TOPLEFT",    5,  -5)
    stripe:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 5,   5)
    stripe:SetTexture(1, 0.82, 0, 1)
    f.stripe = stripe

    -- Class icon
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(58, 58)
    icon:SetPoint("LEFT", f, "LEFT", 14, 0)
    icon:SetTexture(FALLBACK_ICON)
    f.icon = icon

    -- Icon border (thin dark frame around icon for WC3 feel)
    local iconBorder = f:CreateTexture(nil, "OVERLAY")
    iconBorder:SetSize(62, 62)
    iconBorder:SetPoint("CENTER", icon, "CENTER")
    iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconBorder:SetVertexColor(0.6, 0.5, 0.1, 1)
    f.iconBorder = iconBorder

    -- Unit name (large, gold)
    local nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT",  icon,  "TOPRIGHT",  10, -2)
    nameText:SetPoint("TOPRIGHT", f,     "TOPRIGHT",  -8, -10)
    nameText:SetJustifyH("LEFT")
    nameText:SetTextColor(1, 0.85, 0.1, 1)
    nameText:SetText("")
    f.nameText = nameText

    -- Faction text (smaller, faction-colored)
    local factionText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    factionText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
    factionText:SetJustifyH("LEFT")
    factionText:SetText("")
    f.factionText = factionText

    -- Class text (small, gray)
    local classText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classText:SetPoint("TOPLEFT", factionText, "BOTTOMLEFT", 0, -2)
    classText:SetJustifyH("LEFT")
    classText:SetTextColor(0.65, 0.65, 0.65, 1)
    classText:SetText("")
    f.classText = classText

    f:Hide()
    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Portrait:Update(unitKey)
    if not frame then return end

    if not unitKey then
        frame.nameText:SetText("")
        frame.factionText:SetText("")
        frame.classText:SetText("")
        frame.icon:SetTexture(FALLBACK_ICON)
        return
    end

    local unit = UnitMode.Units:Get(unitKey)
    if not unit then return end

    frame.nameText:SetText(unit.name)
    frame.classText:SetText(unit.class)

    local c = FACTION_COLORS[unit.faction] or FALLBACK_COLOR
    frame.factionText:SetText(unit.faction)
    frame.factionText:SetTextColor(c[1], c[2], c[3], 1)
    frame.stripe:SetVertexColor(c[1], c[2], c[3], 1)

    frame.icon:SetTexture(CLASS_ICONS[unit.class] or FALLBACK_ICON)
end

function Portrait:Toggle()
    if not frame then frame = MakeFrame() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:Update(UnitMode.db and UnitMode.db.unitKey)
    end
end

function Portrait:IsShown()
    return frame ~= nil and frame:IsShown()
end
