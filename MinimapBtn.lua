-- UnitMode: Minimap button
-- Draggable around the minimap edge. Angle saved per-character.

UnitMode.MinimapBtn = {}
local MB = UnitMode.MinimapBtn

local RADIUS = 80  -- distance from minimap center to button center

local btn = nil

local function UpdatePosition(angle)
    btn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * RADIUS,
        math.sin(angle) * RADIUS)
end

-- ── Button construction ───────────────────────────────────────────────────────

local function MakeButton()
    local b = CreateFrame("Button", "UnitModeMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Circular coin border — wrapped in a Frame so we can offset it downward;
    -- Texture:SetPoint only accepts 1 arg in Classic 1.x.
    local borderHost = CreateFrame("Frame", nil, b)
    borderHost:SetSize(53, 53)
    borderHost:SetPoint("CENTER", b, "CENTER", 10, -10)
    local border = borderHost:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Dark fill behind the icon
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER")

    -- Icon — crossed swords gives a WC3 combat unit feel
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_OffensiveStance")
    icon:SetPoint("CENTER")

    -- ── Tooltip ───────────────────────────────────────────────────────────────
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cffffcc00Unit|rMode", 1, 1, 1)
        GameTooltip:AddLine("Left-click to open settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to reposition", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- ── Click ─────────────────────────────────────────────────────────────────
    -- Guard against firing a click at the end of a drag
    b:SetScript("OnClick", function(self, mouse)
        if mouse == "LeftButton" and not self.wasDragging then
            UnitMode.UI:Toggle()
        end
        self.wasDragging = false
    end)

    -- ── Drag around the minimap ───────────────────────────────────────────────
    b:SetScript("OnMouseDown", function(self, mouse)
        if mouse == "LeftButton" then
            self.dragging    = true
            self.wasDragging = false
            local scale = UIParent:GetEffectiveScale()
            self.dragStartX, self.dragStartY = GetCursorPosition()
            self.dragStartX = self.dragStartX / scale
            self.dragStartY = self.dragStartY / scale
        end
    end)

    b:SetScript("OnMouseUp", function(self, mouse)
        if mouse == "LeftButton" then
            self.dragging = false
        end
    end)

    b:SetScript("OnUpdate", function(self)
        if not self.dragging then return end

        local mx, my = Minimap:GetCenter()
        local scale  = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale

        -- Detect drag by movement from the press point, not from minimap center
        if not self.wasDragging then
            if math.abs(cx - self.dragStartX) > 4 or math.abs(cy - self.dragStartY) > 4 then
                self.wasDragging = true
            end
        end

        if self.wasDragging then
            local angle = math.atan2(cy - my, cx - mx)
            UnitMode.db.minimapAngle = angle
            UpdatePosition(angle)
        end
    end)

    return b
end

-- ── Public API ────────────────────────────────────────────────────────────────

function MB:Init()
    btn = MakeButton()
    UpdatePosition(UnitMode.db.minimapAngle)
end
