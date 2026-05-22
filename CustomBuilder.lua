-- UnitMode: Custom unit builder and export/import

UnitMode.Builder = {}
local Builder = UnitMode.Builder

local BUILDER_W = 320
local BUILDER_H = 398

local builderPanel = nil

-- ── String codec ──────────────────────────────────────────────────────────────
-- Format: UMv1~Name~Faction~Class~Core1~Core2~Core3~Core4~Ultimate
-- Tilde is the separator; ability names never contain one in practice.

local function Encode(unit)
    return table.concat({
        "UMv1",
        unit.name, unit.faction, unit.class,
        unit.core[1], unit.core[2], unit.core[3], unit.core[4],
        unit.ultimate,
    }, "~")
end

local function Decode(str)
    if not str or strtrim(str) == "" then return nil, "Empty string" end
    local parts = { strsplit("~", strtrim(str)) }
    if #parts ~= 9 then
        return nil, "Expected 9 fields, got " .. #parts
    end
    if parts[1] ~= "UMv1" then
        return nil, "Unknown header: " .. tostring(parts[1])
    end
    return {
        name     = parts[2],
        faction  = parts[3],
        class    = parts[4],
        core     = { parts[5], parts[6], parts[7], parts[8] },
        ultimate = parts[9],
    }
end

-- ── Panel construction ────────────────────────────────────────────────────────

local function MakeInputRow(parent, labelText, yPos, inputWidth)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -yPos)
    lbl:SetText(labelText)
    lbl:SetWidth(72)
    lbl:SetJustifyH("RIGHT")

    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(inputWidth or 180, 20)
    eb:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(80)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    return eb, yPos + 26
end

local function MakePanel()
    local f = CreateFrame("Frame", "UnitModeBuilderPanel", UIParent, "BackdropTemplate")
    f:SetSize(BUILDER_W, BUILDER_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 170, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetToplevel(true)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(0, 0, 0, 1)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText("|cffffcc00Custom Unit Builder|r")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    close:SetScript("OnClick", function() f:Hide() end)

    -- ── Input fields ──────────────────────────────────────────────────────────
    local y = 38
    local nameEb,    y = MakeInputRow(f, "Name:",     y, 180)
    local factionEb, y = MakeInputRow(f, "Faction:",  y, 140)
    local classEb,   y = MakeInputRow(f, "Class:",    y, 140)

    y = y + 6  -- small gap before abilities

    local core1Eb, y = MakeInputRow(f, "Core 1:",   y, 180)
    local core2Eb, y = MakeInputRow(f, "Core 2:",   y, 180)
    local core3Eb, y = MakeInputRow(f, "Core 3:",   y, 180)
    local core4Eb, y = MakeInputRow(f, "Core 4:",   y, 180)
    local ultEb,   y = MakeInputRow(f, "Ultimate:", y, 180)

    f.inputs = {
        name     = nameEb,
        faction  = factionEb,
        class    = classEb,
        core     = { core1Eb, core2Eb, core3Eb, core4Eb },
        ultimate = ultEb,
    }

    -- ── Save button ───────────────────────────────────────────────────────────
    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(90, 22)
    saveBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -(y + 4))
    saveBtn:SetText("Save Unit")
    saveBtn:SetScript("OnClick", function() Builder:SaveUnit() end)

    -- ── Divider ───────────────────────────────────────────────────────────────
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -(y + 34))
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -(y + 34))
    sep:SetTexture(0.3, 0.3, 0.3, 1)

    -- ── Export/Import box ─────────────────────────────────────────────────────
    local ioLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ioLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -(y + 42))
    ioLbl:SetText("Export / Import String:")

    local ioBox = CreateFrame("EditBox", "UnitModeIOBox", f, "InputBoxTemplate")
    ioBox:SetSize(BUILDER_W - 42, 20)
    ioBox:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -(y + 60))
    ioBox:SetAutoFocus(false)
    ioBox:SetMaxLetters(512)
    ioBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.ioBox = ioBox

    local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    exportBtn:SetSize(80, 22)
    exportBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -(y + 88))
    exportBtn:SetText("Export")
    exportBtn:SetScript("OnClick", function() Builder:ExportFromInputs() end)

    local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    importBtn:SetSize(80, 22)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function() Builder:ImportFromBox() end)

    -- ── Status line ───────────────────────────────────────────────────────────
    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    statusText:SetText("")
    f.statusText = statusText

    f:Hide()
    return f
end

-- ── Builder logic ─────────────────────────────────────────────────────────────

local function SanitizeKey(name)
    return (name:lower():gsub("%s+", "_"):gsub("[^%w_]", ""))
end

function Builder:ReadInputs()
    if not builderPanel then return nil, "Panel not created" end
    local inp = builderPanel.inputs

    local name     = strtrim(inp.name:GetText())
    local faction  = strtrim(inp.faction:GetText())
    local class    = strtrim(inp.class:GetText())
    local ultimate = strtrim(inp.ultimate:GetText())
    local core     = {}
    for i = 1, 4 do core[i] = strtrim(inp.core[i]:GetText()) end

    if name == ""     then return nil, "Name is required." end
    if faction == ""  then return nil, "Faction is required." end
    if class == ""    then return nil, "Class is required." end
    if ultimate == "" then return nil, "Ultimate is required." end
    for i = 1, 4 do
        if core[i] == "" then return nil, "Core " .. i .. " is required." end
    end

    return { name = name, faction = faction, class = class, core = core, ultimate = ultimate }
end

function Builder:SaveUnit()
    local unit, err = self:ReadInputs()
    if not unit then
        builderPanel.statusText:SetText("|cffff4444" .. err .. "|r")
        return
    end

    if not UnitMode.db.customUnits then UnitMode.db.customUnits = {} end

    local key = SanitizeKey(unit.name)
    UnitMode.db.customUnits[key] = unit

    builderPanel.ioBox:SetText(Encode(unit))
    builderPanel.statusText:SetText("|cff33ff99Saved: " .. unit.name .. "|r")

    UnitMode.UI:RefreshList()
    print("|cff33ff99[UnitMode]|r Custom unit saved: " .. unit.name)
end

function Builder:ExportFromInputs()
    local unit, err = self:ReadInputs()
    if not unit then
        builderPanel.statusText:SetText("|cffff4444" .. err .. "|r")
        return
    end
    local str = Encode(unit)
    builderPanel.ioBox:SetText(str)
    builderPanel.ioBox:SetFocus()
    builderPanel.ioBox:HighlightText()
    builderPanel.statusText:SetText("String ready — Ctrl+C to copy.")
end

function Builder:ImportFromBox()
    local str = strtrim(builderPanel.ioBox:GetText())
    local unit, err = Decode(str)
    if not unit then
        builderPanel.statusText:SetText("|cffff4444Import failed: " .. err .. "|r")
        return
    end

    local inp = builderPanel.inputs
    inp.name:SetText(unit.name)
    inp.faction:SetText(unit.faction)
    inp.class:SetText(unit.class)
    for i = 1, 4 do inp.core[i]:SetText(unit.core[i] or "") end
    inp.ultimate:SetText(unit.ultimate)

    builderPanel.statusText:SetText("|cffffcc00Imported: " .. unit.name .. " — click Save to keep.|r")
end

function Builder:Toggle()
    if not builderPanel then builderPanel = MakePanel() end
    if builderPanel:IsShown() then
        builderPanel:Hide()
    else
        builderPanel:Show()
    end
end
