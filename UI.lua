-- UnitMode: Selector panel UI (raw Frame API, no library deps)

UnitMode.UI = {}
local UI = UnitMode.UI

local PANEL_W   = 300
local PANEL_H   = 420
local ROW_H     = 22
local INDENT    = 14
local HEADER_H  = 20

local panel = nil

-- ── Panel construction ────────────────────────────────────────────────────────

local function MakePanel()
    local f = CreateFrame("Frame", "UnitModePanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetToplevel(true)
    f:SetFrameStrata("DIALOG")

    -- Background
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
    title:SetText("|cffffcc00Unit|rMode")

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Enable toggle
    local toggle = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    toggle:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -36)
    toggle.text:SetText("Enable UnitMode")
    toggle:SetScript("OnClick", function(self)
        UnitMode.db.enabled = self:GetChecked()
        if UnitMode.db.enabled then
            UnitMode.ActionBar:Apply()
        else
            UnitMode.ActionBar:Reset()
        end
        f.statusText:SetText(UnitMode.db.enabled and "|cff33ff99Active|r" or "|cffff4444Inactive|r")
    end)
    f.toggle = toggle

    -- Divider
    local div = f:CreateTexture(nil, "ARTWORK")
    div:SetHeight(2)
    div:SetPoint("TOPLEFT",  f, "TOPLEFT",  16, -62)
    div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -62)
    div:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")

    -- Custom Unit and Portrait buttons
    local customBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    customBtn:SetSize(110, 22)
    customBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 36)
    customBtn:SetText("Custom Unit...")
    customBtn:SetScript("OnClick", function() UnitMode.Builder:Toggle() end)

    local portraitBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    portraitBtn:SetSize(82, 22)
    portraitBtn:SetPoint("LEFT", customBtn, "RIGHT", 6, 0)
    portraitBtn:SetText("Portrait")
    portraitBtn:SetScript("OnClick", function() UnitMode.Portrait:Toggle() end)

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "UnitModeScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -72)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 66)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(PANEL_W - 46)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f.content = content

    -- Status line
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 14)
    status:SetText("")
    f.statusText = status

    return f
end

-- ── Unit list ─────────────────────────────────────────────────────────────────

local function PopulateList(content)
    -- Clear any existing children
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local sorted      = UnitMode.Units:GetSorted()
    local curFaction  = nil
    local yOffset     = 0

    for _, entry in ipairs(sorted) do
        local key  = entry.key
        local unit = entry.unit

        -- Faction header
        if unit.faction ~= curFaction then
            curFaction = unit.faction

            local hdr = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
            hdr:SetWidth(PANEL_W - 50)
            hdr:SetJustifyH("LEFT")
            hdr:SetText("|cffffcc00" .. curFaction .. "|r")
            yOffset = yOffset + HEADER_H
        end

        -- Row button
        local row = CreateFrame("Button", nil, content)
        row:SetSize(PANEL_W - 60, ROW_H)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", INDENT, -yOffset)

        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture(1, 1, 1, 0.08)

        -- Highlight selected unit
        local isSelected = (UnitMode.db.unitKey == key)
        local nameFont   = isSelected and "GameFontNormal" or "GameFontNormalSmall"
        local label      = row:CreateFontString(nil, "OVERLAY", nameFont)
        label:SetPoint("LEFT", row, "LEFT", 2, 0)
        label:SetJustifyH("LEFT")
        label:SetText(unit.name .. " |cff888888(" .. unit.class .. ")|r")
        row.label = label

        row.unitKey = key
        row:SetScript("OnClick", function(self)
            UnitMode.ActionBar:LoadUnit(self.unitKey)
            UI:ShowUnitDetails(self.unitKey)
            panel.statusText:SetText("Loaded: |cffffffff" .. unit.name .. "|r")
            -- Rebuild list so selection highlight updates
            PopulateList(content)
        end)

        -- Tooltip with ability preview
        row:SetScript("OnEnter", function(self)
            local u = UnitMode.Units.library[self.unitKey]
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(u.name, 1, 0.82, 0)
            GameTooltip:AddLine("Core abilities:", 0.9, 0.9, 0.9)
            for i, ability in ipairs(u.core) do
                GameTooltip:AddLine("  " .. i .. ". " .. ability, 1, 1, 1)
            end
            GameTooltip:AddLine("Ultimate: " .. u.ultimate, 0.4, 0.8, 1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        yOffset = yOffset + ROW_H + 2
    end

    content:SetHeight(yOffset + 10)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function UI:Toggle()
    if not panel then
        panel = MakePanel()
    end
    if panel:IsShown() then
        panel:Hide()
    else
        panel.toggle:SetChecked(UnitMode.db.enabled)
        panel.statusText:SetText(
            UnitMode.db.enabled and "|cff33ff99Active|r" or "|cffff4444Inactive|r"
        )
        PopulateList(panel.content)
        panel:Show()
    end
end

-- Called by Builder after saving a custom unit to refresh the list.
function UI:RefreshList()
    if panel and panel:IsShown() then
        PopulateList(panel.content)
    end
end

function UI:ShowUnitDetails(unitKey)
    local unit = UnitMode.Units:Get(unitKey)
    if not unit then return end
    print(string.format("|cff33ff99[UnitMode]|r %s (%s %s)",
        unit.name, unit.faction, unit.class))
    print("  Core: " .. table.concat(unit.core, "  |  "))
    print("  Ultimate: |cff66ccff" .. unit.ultimate .. "|r")
    print("  Drag these abilities into slots 1-4 and slot 5 on your action bar.")
end
