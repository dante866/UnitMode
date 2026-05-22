-- UnitMode: Action bar overlay/hide logic
--
-- We never hide the secure ActionButton frames directly (causes taint in combat).
-- Instead we cover unwanted slots with non-secure overlay frames that block both
-- visibility and mouse interaction. The extra multi-bars are hidden by frame name
-- out of combat and restored on disable/reset.
--
-- Option C chrome: MainMenuBarArtFrame is hidden and replaced by a slim custom
-- frame that spans only the 5 active slots, with a gold separator marking the
-- ultimate slot.

UnitMode.ActionBar = {}
local AB = UnitMode.ActionBar

local MAIN_BAR_SIZE  = 12
local OVERLAY_STRATA = "MEDIUM"
local OVERLAY_LEVEL  = 10

-- Overlay pool: one per main-bar slot index (1–12)
local overlays   = {}
local barChrome  = nil

local EXTRA_BARS = {
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
}

-- ── Overlay helpers ───────────────────────────────────────────────────────────

local function GetOverlay(index)
    if overlays[index] then return overlays[index] end

    local btn = _G["ActionButton" .. index]
    if not btn then return nil end

    local f = CreateFrame("Frame", "UnitModeOverlay" .. index, UIParent)
    f:SetFrameStrata(OVERLAY_STRATA)
    f:SetFrameLevel(OVERLAY_LEVEL)
    f:EnableMouse(true)   -- absorb clicks so the hidden button isn't accidentally used
    f:SetAllPoints(btn)

    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    tex:SetVertexColor(0.05, 0.05, 0.05, 1)

    -- Faint "blocked" icon so players know the slot is intentionally locked
    local lock = f:CreateTexture(nil, "ARTWORK")
    lock:SetPoint("CENTER")
    lock:SetSize(16, 16)
    lock:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
    lock:SetVertexColor(0.6, 0.1, 0.1, 0.8)

    f:Hide()
    overlays[index] = f
    return f
end

-- ── Custom bar chrome ─────────────────────────────────────────────────────────
-- Replaces MainMenuBarArtFrame while UnitMode is active. Spans ActionButton1-5
-- with a WC3-flavored dark background, gold border, and a vertical separator
-- that marks slot 5 as the ultimate.

local function GetBarChrome()
    if barChrome then return barChrome end

    local btn1 = _G["ActionButton1"]
    local btn5 = _G["ActionButton5"]
    if not (btn1 and btn5) then return nil end

    local f = CreateFrame("Frame", "UnitModeBarChrome", UIParent, "BackdropTemplate")
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(1)

    -- Pad 10px around slots 1-5; extra 16px below for the "Ult" label
    f:SetPoint("TOPLEFT",     btn1, "TOPLEFT",     -10,  10)
    f:SetPoint("BOTTOMRIGHT", btn5, "BOTTOMRIGHT",  10, -18)

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(0, 0, 0, 0.88)
    f:SetBackdropBorderColor(0.55, 0.45, 0.1, 1)   -- WC3 aged-gold

    -- Thin gold separator between core (1-4) and ultimate (5)
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(2)
    sep:SetPoint("TOPLEFT",    btn5, "TOPLEFT",    -5,  5)
    sep:SetPoint("BOTTOMLEFT", btn5, "BOTTOMLEFT", -5, -5)
    sep:SetTexture(0.55, 0.45, 0.1, 0.9)

    -- "Ult" label below the ultimate slot
    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOP", btn5, "BOTTOM", 0, -3)
    lbl:SetText("|cff66ccffUlt|r")

    f:Hide()
    barChrome = f
    return f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function AB:Apply()
    local db = UnitMode.db
    if not db.enabled then
        self:Reset()
        return
    end

    -- Build set of visible slot indices
    local visible = {}
    for _, s in ipairs(db.coreSlots) do
        visible[s] = true
    end
    visible[db.ultimateSlot] = true

    -- Overlay every main-bar slot that isn't in the visible set
    for i = 1, MAIN_BAR_SIZE do
        local overlay = GetOverlay(i)
        if overlay then
            if visible[i] then
                overlay:Hide()
            else
                overlay:Show()
            end
        end
    end

    -- Chrome swap + extra bars only safe out of combat;
    -- PLAYER_REGEN_ENABLED re-fires Apply() so this catches up after combat.
    if not InCombatLockdown() then
        for _, barName in ipairs(EXTRA_BARS) do
            local bar = _G[barName]
            if bar then bar:Hide() end
        end
        MainMenuBarArtFrame:Hide()
        local chrome = GetBarChrome()
        if chrome then chrome:Show() end
    end
end

function AB:Reset()
    -- Remove all overlays
    for _, overlay in pairs(overlays) do
        overlay:Hide()
    end

    if not InCombatLockdown() then
        for _, barName in ipairs(EXTRA_BARS) do
            local bar = _G[barName]
            if bar then bar:Show() end
        end
        MainMenuBarArtFrame:Show()
        if barChrome then barChrome:Hide() end
    end
end

-- Load a unit preset into db and reapply if enabled
function AB:LoadUnit(unitKey)
    local db   = UnitMode.db
    local unit = UnitMode.Units:Get(unitKey)
    if not unit then return end

    db.unitKey      = unitKey
    db.coreSlots    = { 1, 2, 3, 4 }
    db.ultimateSlot = 5

    if db.enabled then
        self:Apply()
    end

    UnitMode.Portrait:Update(unitKey)
end
