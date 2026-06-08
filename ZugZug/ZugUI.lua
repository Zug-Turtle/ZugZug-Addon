ZugZug.UI = {}
ZugZug.UI.frame = nil
ZugZug.UI.tabs = {}
ZugZug.UI.pages = {}
ZugZug.UI.activeTab = nil

local ZUG_UI_WIDTH = 670
local ZUG_UI_HEIGHT = 460
local ZUG_UI_TAB_WIDTH = 80
local ZUG_UI_TAB_HEIGHT = 24

local function ZugZug_UI_ClearPage(page)
    if not page then return end

    local regions = { page:GetRegions() }
    local i = 1
    while regions[i] do
        regions[i]:Hide()
        regions[i]:SetParent(nil)
        i = i + 1
    end

    local children = { page:GetChildren() }
    i = 1
    while children[i] do
        children[i]:Hide()
        children[i]:SetParent(nil)
        i = i + 1
    end
end

local function ZugZug_UI_CreateText(parent, name, text, size)
    local fs = parent:CreateFontString(name, "OVERLAY", "GameFontNormal")
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    if size == "large" then
        fs:SetFontObject(GameFontNormalLarge)
    elseif size == "small" then
        fs:SetFontObject(GameFontHighlightSmall)
    else
        fs:SetFontObject(GameFontNormal)
    end
    return fs
end

local function ZugZug_UI_CreateButton(parent, name, text, width, height)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetWidth(width or 100)
    btn:SetHeight(height or 24)
    btn:SetText(text or "Button")
    return btn
end

local function ZugZug_UI_CreateDropdown(parent, width, items, selectedValue, onSelect)
    if not ZugZug.UI.dropdownSeq then
        ZugZug.UI.dropdownSeq = 0
    end

    ZugZug.UI.dropdownSeq = ZugZug.UI.dropdownSeq + 1

    local dropdownName = "ZugZugDropDown" .. tostring(ZugZug.UI.dropdownSeq)
    local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")

    dropdown.items = items or {}
    dropdown.selectedValue = selectedValue or ""
    dropdown.onSelect = onSelect

    UIDropDownMenu_SetWidth(width, dropdown)

    local selectedText = dropdown.selectedValue
    local i = 1

    while items and i <= table.getn(items) do
        local item = items[i]

        if type(item) == "table" then
            if item.value == dropdown.selectedValue then
                selectedText = item.label or item.value or ""
            end
        elseif item == dropdown.selectedValue then
            selectedText = item
        end

        i = i + 1
    end

    if not selectedText or selectedText == "" then
        if items and table.getn(items) > 0 then
            local first = items[1]

            if type(first) == "table" then
                selectedText = first.label or first.value or ""
                dropdown.selectedValue = first.value or first.label or ""
            else
                selectedText = first or ""
                dropdown.selectedValue = first or ""
            end
        else
            selectedText = ""
        end
    end

    UIDropDownMenu_Initialize(dropdown, function()
        local index = 1

        while dropdown.items and index <= table.getn(dropdown.items) do
            local item = dropdown.items[index]
            local info = UIDropDownMenu_CreateInfo()

            if type(item) == "table" then
                info.text = item.label or item.value or ""
                info.value = item.value or item.label or ""
            else
                info.text = item or ""
                info.value = item or ""
            end

            info.func = function()
                local value = this.value or ""
                local text = this:GetText() or value

                dropdown.selectedValue = value
                UIDropDownMenu_SetText(text, dropdown)

                if dropdown.onSelect then
                    dropdown.onSelect(value, text)
                end
            end

            UIDropDownMenu_AddButton(info)
            index = index + 1
        end
    end)

    UIDropDownMenu_SetText(selectedText, dropdown)

    return dropdown
end

local function ZugZug_UI_CreateRoleIcon(parent, role, size)
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetWidth(size or 16)
    tex:SetHeight(size or 16)
    tex:SetTexture(ZugZug_LFG_GetRoleIcon(role))
    return tex
end

local function ZugZug_UI_CreateZugIcon(parent, size)
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetWidth(size or 14)
    tex:SetHeight(size or 14)
    tex:SetTexture("Interface\\AddOns\\ZugZug\\Textures\\ZugZug")
    return tex
end

local function ZugZug_UI_CreateBox(parent)
    local box = CreateFrame("Frame", nil, parent)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    box:SetBackdropColor(0, 0, 0, 0.72)
    box:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    return box
end

local function ZugZug_UI_CreateCleanEditBox(parent, width, height, text)
    local box = ZugZug_UI_CreateBox(parent)
    box:SetWidth(width)
    box:SetHeight(height)

    local edit = CreateFrame("EditBox", nil, box)
    edit:SetPoint("TOPLEFT", box, "TOPLEFT", 7, -4)
    edit:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -7, 4)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetAutoFocus(false)
    edit:SetText(text or "")
    edit:SetMaxLetters(120)
    edit:SetScript("OnEscapePressed", function()
        this:ClearFocus()

        if ZugZug_UI_Hide and ZugZug.UI and ZugZug.UI.frame and ZugZug.UI.frame:IsShown() then
            ZugZug_UI_Hide()
        end
    end)

    box.edit = edit
    return box, edit
end

local function ZugZug_UI_CreateCard(parent, width, height)
    local card = CreateFrame("Frame", nil, parent)
    card:SetWidth(width)
    card:SetHeight(height)
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    card:SetBackdropColor(0, 0, 0, 0.58)
    card:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    return card
end

local function ZugZug_UI_CreatePickerButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 160)
    btn:SetHeight(height or 20)
    btn:EnableMouse(true)

    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    btn:SetBackdropColor(0, 0, 0, 0.65)
    btn:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", btn, "LEFT", 7, 0)
    fs:SetPoint("RIGHT", btn, "RIGHT", -18, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    btn.text = fs

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetText("|cffaaaaaa▼|r")
    btn.arrow = arrow

    btn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(0, 1, 0, 1)
    end)

    btn:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
    end)

    return btn
end

local function ZugZug_UI_CreatePickerRow(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 170)
    btn:SetHeight(height or 19)
    btn:EnableMouse(true)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture(0, 0, 0, 0)
    btn.bg = bg

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    btn.text = fs

    btn:SetScript("OnEnter", function()
        this.bg:SetTexture(0, 0.35, 0, 0.45)
    end)

    btn:SetScript("OnLeave", function()
        this.bg:SetTexture(0, 0, 0, 0)
    end)

    return btn
end

local function ZugZug_UI_CreateRoleChoiceButton(parent, role, selected, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(width or 72)
    btn:SetHeight(height or 22)
    btn:EnableMouse(true)

    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    btn:SetBackdropColor(0, 0, 0, 0.65)

    if selected then
        btn:SetBackdropBorderColor(0, 1, 0, 1)
    else
        btn:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
    end

    local icon = ZugZug_UI_CreateRoleIcon(btn, role, 14)
    icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
    btn.icon = icon

    local label = role
    if role == "TANK" then label = "Tank" end
    if role == "HEALER" then label = "Heal" end
    if role == "DPS" then label = "DPS" end

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetText(label)
    btn.text = text

    btn:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(0, 1, 0, 1)
    end)

    btn:SetScript("OnLeave", function()
        if this.selected then
            this:SetBackdropBorderColor(0, 1, 0, 1)
        else
            this:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
        end
    end)

    btn.selected = selected

    return btn
end

local function ZugZug_UI_CreateTargetPicker(parent)
    local currentType = ZugZug_LFG_GetCreateType()
    local currentTarget = ZugZug_LFG_GetCreateTarget()

    local pickerButton = ZugZug_UI_CreatePickerButton(parent, currentTarget, 230, 22)

    pickerButton:SetScript("OnClick", function()
        if this.targetPanel and this.targetPanel:IsShown() then
            this.targetPanel:Hide()
        elseif this.targetPanel then
            this.targetPanel:Show()
        end
    end)

    local panel = ZugZug_UI_CreateBox(parent)
    panel:SetWidth(390)
    panel:SetHeight(154)
    panel:SetPoint("TOPLEFT", pickerButton, "BOTTOMLEFT", 0, -3)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(parent:GetFrameLevel() + 40)
    panel:Hide()

    pickerButton.targetPanel = panel

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    scrollFrame:SetWidth(374)
    scrollFrame:SetHeight(138)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(374)

    local targets = ZugZug_LFG_GetTargetsForType(currentType)
    local total = table.getn(targets)
    local rowHeight = 20
    local rows = math.ceil(total / 2)

    if rows < 1 then rows = 1 end

    local childHeight = rows * rowHeight
    if childHeight < 139 then childHeight = 139 end

    scrollChild:SetHeight(childHeight)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()

        if not current then current = 0 end
        if not maxScroll then maxScroll = 0 end

        if arg1 and arg1 > 0 then
            current = current - 30
            if current < 0 then current = 0 end
        else
            current = current + 30
            if current > maxScroll then current = maxScroll end
        end

        this:SetVerticalScroll(current)
    end)

    local i = 1
    while i <= total do
        local target = targets[i]
        local col = 0
        local row = math.floor((i - 1) / 2)

        if math.mod(i - 1, 2) == 1 then
            col = 1
        end

        local targetButton = ZugZug_UI_CreatePickerRow(scrollChild, target, 182, 19)
        targetButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", col * 188, -(row * rowHeight))
        targetButton.targetValue = target
        targetButton.parentPicker = pickerButton

        targetButton:SetScript("OnClick", function()
            ZugZug_LFG_SetCreateTarget(this.targetValue)

            if this.parentPicker and this.parentPicker.text then
                this.parentPicker.text:SetText(this.targetValue)
            end

            if this.parentPicker and this.parentPicker.targetPanel then
                this.parentPicker.targetPanel:Hide()
            end
        end)

        i = i + 1
    end

    return pickerButton
end

local function ZugZug_UI_CreateTypePicker(parent)
    local currentType = ZugZug_LFG_GetCreateType()
    local pickerButton = ZugZug_UI_CreatePickerButton(parent, currentType, 105, 22)

    pickerButton:SetScript("OnClick", function()
        if this.typePanel and this.typePanel:IsShown() then
            this.typePanel:Hide()
        elseif this.typePanel then
            this.typePanel:Show()
        end
    end)

    local panel = ZugZug_UI_CreateBox(parent)
    panel:SetWidth(120)
    panel:SetHeight(70)
    panel:SetPoint("TOPLEFT", pickerButton, "BOTTOMLEFT", 0, -3)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(parent:GetFrameLevel() + 40)
    panel:Hide()

    pickerButton.typePanel = panel

    local i = 1
    while ZugZug.LFG_TYPES and i <= table.getn(ZugZug.LFG_TYPES) do
        local item = ZugZug.LFG_TYPES[i]
        local value = ""
        local label = ""

        if type(item) == "table" then
            value = item.value or item.label or ""
            label = item.label or item.value or ""
        else
            value = item or ""
            label = item or ""
        end

        local row = ZugZug_UI_CreatePickerRow(panel, label, 104, 20)
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8 - ((i - 1) * 20))
        row.typeValue = value
        row.typeLabel = label
        row.parentPicker = pickerButton

        row:SetScript("OnClick", function()
            ZugZug_LFG_SetCreateType(this.typeValue)

            if this.parentPicker and this.parentPicker.text then
                this.parentPicker.text:SetText(this.typeLabel)
            end

            if this.parentPicker and this.parentPicker.typePanel then
                this.parentPicker.typePanel:Hide()
            end

            ZugZug_UI_ShowTab("lfg")
        end)

        i = i + 1
    end

    return pickerButton
end

local function ZugZug_UI_CreateOfficerMacroPicker(parent)
    local selected = ZugZug_GetOfficerMacro()
    local label = selected

    if selected == "bonk" then label = "Bonk / Mod Warning" end
    if selected == "donate" then label = "Donation Progress" end

    local pickerButton = ZugZug_UI_CreatePickerButton(parent, label, 170, 22)

    pickerButton:SetScript("OnClick", function()
        if this.macroPanel and this.macroPanel:IsShown() then
            this.macroPanel:Hide()
        elseif this.macroPanel then
            this.macroPanel:Show()
        end
    end)

    local panel = ZugZug_UI_CreateBox(parent)
    panel:SetWidth(190)
    panel:SetHeight(52)
    panel:SetPoint("TOPLEFT", pickerButton, "BOTTOMLEFT", 0, -3)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(parent:GetFrameLevel() + 40)
    panel:Hide()

    pickerButton.macroPanel = panel

    local bonk = ZugZug_UI_CreatePickerRow(panel, "Bonk / Mod Warning", 174, 20)
    bonk:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    bonk:SetScript("OnClick", function()
        ZugZug_SetOfficerMacro("bonk")
        ZugZug_UI_ShowTab("officer")
    end)

    local donate = ZugZug_UI_CreatePickerRow(panel, "Donation Progress", 174, 20)
    donate:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -28)
    donate:SetScript("OnClick", function()
        ZugZug_SetOfficerMacro("donate")
        ZugZug_UI_ShowTab("officer")
    end)

    return pickerButton
end

local function ZugZug_UI_ClampValue(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function ZugZug_UI_GetUIParentBounds()
    local left = UIParent:GetLeft()
    local right = UIParent:GetRight()
    local top = UIParent:GetTop()
    local bottom = UIParent:GetBottom()

    if not left then left = 0 end
    if not bottom then bottom = 0 end

    if not right then
        right = UIParent:GetWidth()
    end

    if not top then
        top = UIParent:GetHeight()
    end

    return left, right, top, bottom
end

local function ZugZug_UI_SetFrameCenterClamped(frame, centerX, centerY)
    if not frame then return end

    local uiLeft, uiRight, uiTop, uiBottom = ZugZug_UI_GetUIParentBounds()
    local width = frame:GetWidth()
    local height = frame:GetHeight()

    if not width or width <= 0 then width = ZUG_UI_WIDTH end
    if not height or height <= 0 then height = ZUG_UI_HEIGHT end

    local halfWidth = width / 2
    local halfHeight = height / 2

    local minX = uiLeft + halfWidth
    local maxX = uiRight - halfWidth
    local minY = uiBottom + halfHeight
    local maxY = uiTop - halfHeight

    centerX = ZugZug_UI_ClampValue(centerX, minX, maxX)
    centerY = ZugZug_UI_ClampValue(centerY, minY, maxY)

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
end

local function ZugZug_UI_ClampFrameToScreen(frame)
    if not frame then return end

    local centerX, centerY = frame:GetCenter()

    if not centerX or not centerY then
        local uiLeft, uiRight, uiTop, uiBottom = ZugZug_UI_GetUIParentBounds()
        centerX = (uiLeft + uiRight) / 2
        centerY = (uiBottom + uiTop) / 2
    end

    ZugZug_UI_SetFrameCenterClamped(frame, centerX, centerY)
end

local function ZugZug_UI_StartFrameDrag(frame)
    if not frame then return end

    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    if not scale or scale == 0 then
        scale = 1
    end

    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local centerX, centerY = frame:GetCenter()

    if not centerX or not centerY then
        local uiLeft, uiRight, uiTop, uiBottom = ZugZug_UI_GetUIParentBounds()
        centerX = (uiLeft + uiRight) / 2
        centerY = (uiBottom + uiTop) / 2
    end

    frame.dragOffsetX = cursorX - centerX
    frame.dragOffsetY = cursorY - centerY

    frame:SetScript("OnUpdate", function()
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()

        if not s or s == 0 then
            s = 1
        end

        x = x / s
        y = y / s

        ZugZug_UI_SetFrameCenterClamped(
            this,
            x - (this.dragOffsetX or 0),
            y - (this.dragOffsetY or 0)
        )
    end)
end

local function ZugZug_UI_StopFrameDrag(frame)
    if not frame then return end

    frame:SetScript("OnUpdate", nil)
    frame.dragOffsetX = nil
    frame.dragOffsetY = nil

    ZugZug_UI_ClampFrameToScreen(frame)

    if ZugZug_SaveWindowPosition then
        ZugZug_SaveWindowPosition(frame)
    end
end

local function ZugZug_UI_RestoreWindowPosition(frame)
    if not frame then return end

    local pos = nil

    if ZugZug_GetWindowPosition then
        pos = ZugZug_GetWindowPosition()
    end

    frame:ClearAllPoints()

    if pos and pos.x and pos.y then
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    ZugZug_UI_ClampFrameToScreen(frame)
end

local function ZugZug_UI_CreateMainFrame()
    local frame = CreateFrame("Frame", "ZugZugMainFrame", UIParent)
    frame:SetWidth(ZUG_UI_WIDTH)
    frame:SetHeight(ZUG_UI_HEIGHT)
    ZugZug_UI_RestoreWindowPosition(frame)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end

    if frame.SetClampRectInsets then
        frame:SetClampRectInsets(0, 0, 0, 0)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        ZugZug_UI_StartFrameDrag(this)
    end)

    frame:SetScript("OnDragStop", function()
        ZugZug_UI_StopFrameDrag(this)
    end)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)

    local titleIcon = frame:CreateTexture(nil, "OVERLAY")
    titleIcon:SetWidth(24)
    titleIcon:SetHeight(24)
    titleIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -15)
    titleIcon:SetTexture("Interface\\AddOns\\ZugZug\\Textures\\ZugZug")
    frame.titleIcon = titleIcon

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 1)
    title:SetText("|cff00ff00<Zug Zug>|r Welcome, " .. ZugZug_ClassColorize(UnitName("player")) .. "!")
    frame.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.close = close

    if UISpecialFrames then
        local found = false
        local i = 1

        while UISpecialFrames[i] do
            if UISpecialFrames[i] == "ZugZugMainFrame" then
                found = true
                break
            end

            i = i + 1
        end

        if not found then
            table.insert(UISpecialFrames, "ZugZugMainFrame")
        end
    end

    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -48)
    tabBar:SetWidth(ZUG_UI_WIDTH - 32)
    tabBar:SetHeight(28)
    frame.tabBar = tabBar

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -82)
    content:SetWidth(ZUG_UI_WIDTH - 36)
    content:SetHeight(ZUG_UI_HEIGHT - 104)
    frame.content = content

    frame:Hide()
    return frame
end

function ZugZug_UI_GetFrame()
    if not ZugZug.UI.frame then
        ZugZug.UI.frame = ZugZug_UI_CreateMainFrame()
    end
    return ZugZug.UI.frame
end

local function ZugZug_UI_CreateTabButton(parent, label)
    local tab = CreateFrame("Button", nil, parent)
    tab:SetWidth(80)
    tab:SetHeight(24)
    tab:EnableMouse(true)

    tab:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    tab:SetBackdropColor(0, 0, 0, 0.55)
    tab:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)

    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
    text:SetText(label or "")
    tab.text = text

    tab:SetScript("OnEnter", function()
        if not this.selected then
            this:SetBackdropBorderColor(0, 0.8, 0, 1)
        end
    end)

    tab:SetScript("OnLeave", function()
        if this.selected then
            this:SetBackdropBorderColor(0, 1, 0, 1)
        else
            this:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
        end
    end)

    return tab
end

local function ZugZug_UI_SetTabSelected(tab, selected)
    if not tab then return end

    if selected then
        tab.selected = true
        tab:SetBackdropColor(0, 0.18, 0, 0.88)
        tab:SetBackdropBorderColor(0, 1, 0, 1)

        if tab.text then
            tab.text:SetTextColor(1, 1, 1)
        end
    else
        tab.selected = false
        tab:SetBackdropColor(0, 0, 0, 0.55)
        tab:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)

        if tab.text then
            tab.text:SetTextColor(1, 0.82, 0)
        end
    end
end

local function ZugZug_UI_GetTabWidth(label)
    local len = string.len(label or "")
    local width = 42 + (len * 7)

    if width < 72 then width = 72 end
    if width > 120 then width = 120 end

    return width
end

local function ZugZug_UI_LayoutTabs()
    local frame = ZugZug_UI_GetFrame()
    local maxWidth = ZUG_UI_WIDTH - 32
    local x = 0
    local y = 0
    local rowHeight = ZUG_UI_TAB_HEIGHT + 4
    local rows = 1

    local i = 1
    while i <= table.getn(ZugZug.UI.tabs) do
        local tab = ZugZug.UI.tabs[i]
        local width = ZugZug_UI_GetTabWidth(tab.label)

        if x > 0 and x + width > maxWidth then
            x = 0
            y = y - rowHeight
            rows = rows + 1
        end

        tab:ClearAllPoints()
        tab:SetWidth(width)
        tab:SetHeight(ZUG_UI_TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", frame.tabBar, "TOPLEFT", x, y)

        x = x + width + 4
        i = i + 1
    end

    frame.tabBar:SetHeight(rows * rowHeight)
    frame.content:ClearAllPoints()
    frame.content:SetPoint("TOPLEFT", frame.tabBar, "BOTTOMLEFT", 2, -10)
    frame.content:SetWidth(ZUG_UI_WIDTH - 36)
    frame.content:SetHeight(ZUG_UI_HEIGHT - 104 - ((rows - 1) * rowHeight))
end

function ZugZug_UI_RegisterTab(key, label, buildFunc)
    if not key or key == "" then return end
    if not label then label = key end
    if not buildFunc then return end

    local frame = ZugZug_UI_GetFrame()
    local tabIndex = table.getn(ZugZug.UI.tabs) + 1
    local tab = ZugZug_UI_CreateTabButton(frame.tabBar, label)
    local page = CreateFrame("Frame", nil, frame.content)
    page:SetAllPoints(frame.content)
    page:Hide()

    tab.key = key
    tab.label = label
    tab.page = page
    tab.buildFunc = buildFunc

    tab:SetScript("OnClick", function()
        ZugZug_UI_ShowTab(this.key)
    end)

    ZugZug.UI.tabs[tabIndex] = tab
    ZugZug.UI.pages[key] = page
    ZugZug_UI_LayoutTabs()
end

function ZugZug_UI_ShowTab(key)
    local i = 1
    while i <= table.getn(ZugZug.UI.tabs) do
        local tab = ZugZug.UI.tabs[i]
        if tab.key == key then
            tab.page:Show()
            ZugZug_UI_SetTabSelected(tab, true)
            ZugZug.UI.activeTab = key

            ZugZug_UI_ClearPage(tab.page)
            tab.buildFunc(tab.page)

            ZugZug.UI.refreshCount = (ZugZug.UI.refreshCount or 0) + 1
        else
            tab.page:Hide()
            ZugZug_UI_SetTabSelected(tab, false)
        end
        i = i + 1
    end
end

function ZugZug_UI_RefreshActiveTab()
    if not ZugZug.UI then return end
    if not ZugZug.UI.activeTab then return end

    local frame = ZugZug.UI.frame
    if not frame or not frame:IsShown() then return end

    if ZugZug.UI.refreshScheduled and ZugZug.UI.refreshTickerFrame then
        ZugZug.UI.refreshTickerFrame:SetScript("OnUpdate", nil)
        ZugZug.UI.refreshScheduled = nil
        ZugZug.UI.refreshDelay = nil
    end

    ZugZug_UI_ShowTab(ZugZug.UI.activeTab)
end

function ZugZug_UI_RefreshActiveTabThrottled(reason, delay)
    if not ZugZug.UI then return end
    if not ZugZug.UI.activeTab then return end

    local frame = ZugZug.UI.frame
    if not frame or not frame:IsShown() then return end

    delay = tonumber(delay or 0.25) or 0.25
    if delay < 0 then delay = 0 end

    ZugZug.UI.pendingRefreshReason = reason or "unknown"

    if ZugZug.UI.refreshScheduled then
        if delay < (ZugZug.UI.refreshDelay or delay) then
            ZugZug.UI.refreshDelay = delay
        end
        return
    end

    local ticker = ZugZug.UI.refreshTickerFrame
    if not ticker then
        ticker = CreateFrame("Frame")
        ZugZug.UI.refreshTickerFrame = ticker
    end

    ticker.elapsed = 0
    ZugZug.UI.refreshDelay = delay
    ZugZug.UI.refreshScheduled = true

    ticker:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1

        if this.elapsed < (ZugZug.UI.refreshDelay or 0.25) then
            return
        end

        this:SetScript("OnUpdate", nil)
        ZugZug.UI.refreshScheduled = nil
        ZugZug.UI.refreshDelay = nil

        ZugZug_UI_RefreshActiveTab()
    end)
end

function ZugZug_UI_Show()
    local frame = ZugZug_UI_GetFrame()
    frame:Show()

    if not ZugZug.UI.activeTab and table.getn(ZugZug.UI.tabs) > 0 then
        ZugZug_UI_ShowTab(ZugZug.UI.tabs[1].key)
    elseif ZugZug.UI.activeTab then
        ZugZug_UI_ShowTab(ZugZug.UI.activeTab)
    end
end

function ZugZug_UI_Hide()
    local frame = ZugZug_UI_GetFrame()
    frame:Hide()
end

function ZugZug_UI_Toggle()
    local frame = ZugZug_UI_GetFrame()

    if frame:IsShown() then
        frame:Hide()
    else
        ZugZug_UI_Show()
    end
end

local function ZugZug_UI_AddChatMessages(chatFrame, rows, color)
    if not chatFrame then return end

    if not color then
        color = "cff00ff00"
    end

    if not rows or table.getn(rows) == 0 then
        chatFrame:AddMessage("|cff777777No messages yet.|r")
        return
    end

    local i = 1
    while i <= table.getn(rows) do
        local row = rows[i]

        if row then
            local sender = row.sender or "?"
            local msg = row.msg or ""
            msg = string.gsub(msg, "|", "||")
            chatFrame:AddMessage(ZugZug_ClassColorize(sender) .. ": |" .. color .. msg .. "|r")
        end

        i = i + 1
    end

    if chatFrame.ScrollToBottom then
        chatFrame:ScrollToBottom()
    end
end

local function ZugZug_UI_CreateChatPanel(parent, titleText, rows, color, width, height)
    local panel = ZugZug_UI_CreateCard(parent, width, height)

    local title = ZugZug_UI_CreateText(panel, nil, titleText, "normal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)

    local chatFrame = CreateFrame("ScrollingMessageFrame", nil, panel)
    chatFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
    chatFrame:SetWidth(width - 20)
    chatFrame:SetHeight(height - 48)
    chatFrame:SetFontObject(GameFontHighlightSmall)
    chatFrame:SetJustifyH("LEFT")
    chatFrame:SetMaxLines(160)
    chatFrame:SetFading(false)
    chatFrame:EnableMouseWheel(true)

    chatFrame:SetScript("OnMouseWheel", function()
        if arg1 and arg1 > 0 then
            this:ScrollUp()
        else
            this:ScrollDown()
        end
    end)

    ZugZug_UI_AddChatMessages(chatFrame, rows, color)

    return panel
end

local function ZugZug_UI_CreateCapyChatPanel(parent, width, height)
    local panel = ZugZug_UI_CreateCard(parent, width, height)

    local title = ZugZug_UI_CreateText(panel, nil, "|cff69ccf0Discord #capy-chat|r", "normal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)

    local chatFrame = CreateFrame("ScrollingMessageFrame", nil, panel)
    chatFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
    chatFrame:SetWidth(width - 20)
    chatFrame:SetHeight(height - 76)
    chatFrame:SetFontObject(GameFontHighlightSmall)
    chatFrame:SetJustifyH("LEFT")
    chatFrame:SetMaxLines(ZugZug.CAPY_CHAT_MAX_MESSAGES or 100)
    chatFrame:SetFading(false)
    chatFrame:EnableMouseWheel(true)

    chatFrame:SetScript("OnMouseWheel", function()
        if arg1 and arg1 > 0 then
            this:ScrollUp()
        else
            this:ScrollDown()
        end
    end)

    ZugZug_UI_AddChatMessages(chatFrame, ZugZug.capyChatLog or {}, "cffd6e7ff")

    local inputFrame, input = ZugZug_UI_CreateCleanEditBox(panel, width - 78, 24, "")
    inputFrame:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
    input:SetMaxLetters(220)

    local sendButton = ZugZug_UI_CreateButton(panel, nil, "Send", 54, 24)
    sendButton:SetPoint("LEFT", inputFrame, "RIGHT", 6, 0)

    local function sendMessage()
        local text = input:GetText() or ""
        if ZugZug_SendCapyChatMessage and ZugZug_SendCapyChatMessage(text) then
            input:SetText("")
            input:ClearFocus()
            if ZugZug.UI and ZugZug.UI.activeTab == "dashboard" then
                ZugZug_UI_ShowTab("dashboard")
            end
        end
    end

    sendButton:SetScript("OnClick", sendMessage)
    input:SetScript("OnEnterPressed", sendMessage)

    return panel
end

local function ZugZug_UI_FindMyLFGListing()
    local player = UnitName("player")

    if not player then return nil end

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing then
            if listing.leader == player then
                return id, listing
            end

            if ZugZug_LFG_IsListingMember and ZugZug_LFG_IsListingMember(listing, player) then
                return id, listing
            end
        end
    end

    return nil
end

local function ZugZug_UI_CreateMiniLFGRow(parent, listing, x, y, width)
    if not listing then return end

    local title = ZugZug_UI_CreateText(parent, nil, "|cffffd100" .. (listing.target or "Unknown") .. "|r", "small")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    title:SetWidth(width or 280)

    local sub = ZugZug_UI_CreateText(parent, nil, "|cffaaaaaa" .. (listing.type or "Other") .. " by " .. (listing.leader or "?") .. "|r", "small")
    sub:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 15)
    sub:SetWidth(width or 280)

    local memberX = x
    local memberY = y - 34
    local i = 1

    while listing.members and i <= table.getn(listing.members) do
        local member = listing.members[i]

        if member and member.name then
            local role = member.role or "DPS"
            if not ZugZug_LFG_IsValidRole(role) then role = "DPS" end

            local icon = ZugZug_UI_CreateRoleIcon(parent, role, 12)
            icon:SetPoint("TOPLEFT", parent, "TOPLEFT", memberX, memberY)

            local name = ZugZug_UI_CreateText(parent, nil, ZugZug_ClassColorize(member.name), "small")
            name:SetPoint("LEFT", icon, "RIGHT", 3, 0)

            memberX = memberX + 94

            if memberX > x + 185 then
                memberX = x
                memberY = memberY - 15
            end
        end

        i = i + 1
    end
end

local function ZugZug_UI_CreateDashboardLFGPanel(parent, width, height)
    local lfgPanel = ZugZug_UI_CreateCard(parent, width, height)

    local lfgTitle = ZugZug_UI_CreateText(lfgPanel, nil, "|cff00ff00Guild LFG|r", "normal")
    lfgTitle:SetPoint("TOPLEFT", lfgPanel, "TOPLEFT", 10, -8)

    local myId, myListing = ZugZug_UI_FindMyLFGListing()

    if myListing then
        local label = ZugZug_UI_CreateText(lfgPanel, nil, "|cffaaaaaaYour current group|r", "small")
        label:SetPoint("TOPLEFT", lfgPanel, "TOPLEFT", 10, -30)

        ZugZug_UI_CreateMiniLFGRow(lfgPanel, myListing, 10, -50, width - 20)

        local openButton = ZugZug_UI_CreateButton(lfgPanel, nil, "Open LFG", 78, 20)
        openButton:SetPoint("BOTTOMRIGHT", lfgPanel, "BOTTOMRIGHT", -10, 8)
        openButton:SetScript("OnClick", function()
            ZugZug_UI_ShowTab("lfg")
        end)
    else
        local canCreate = true

        if ZugZug_LFG_CanCreateListing and not ZugZug_LFG_CanCreateListing() then
            canCreate = false
        end

        if canCreate then
            local createButton = ZugZug_UI_CreateButton(lfgPanel, nil, "New Group", 88, 20)
            createButton:SetPoint("TOPRIGHT", lfgPanel, "TOPRIGHT", -10, -6)
            createButton:SetScript("OnClick", function()
                if ZugZug_LFG_SetCreateOpen then
                    ZugZug_LFG_SetCreateOpen(true)
                end

                ZugZug_UI_ShowTab("lfg")
            end)
        end

        local scroll = CreateFrame("ScrollFrame", nil, lfgPanel)
        scroll:SetPoint("TOPLEFT", lfgPanel, "TOPLEFT", 10, -34)
        scroll:SetWidth(width - 20)
        scroll:SetHeight(height - 44)
        scroll:EnableMouseWheel(true)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetWidth(width - 20)

        local count = 0
        if ZugZug.LFG and ZugZug.LFG.listings then
            for id, listing in pairs(ZugZug.LFG.listings) do
                if listing then
                    count = count + 1
                end
            end
        end

        local rowHeight = 74
        local childHeight = count * rowHeight

        if childHeight < height - 43 then
            childHeight = height - 43
        end

        child:SetHeight(childHeight)
        scroll:SetScrollChild(child)

        scroll:SetScript("OnMouseWheel", function()
            local current = this:GetVerticalScroll()
            local maxScroll = this:GetVerticalScrollRange()

            if not current then current = 0 end
            if not maxScroll then maxScroll = 0 end

            if arg1 and arg1 > 0 then
                current = current - 34
                if current < 0 then current = 0 end
            else
                current = current + 34
                if current > maxScroll then current = maxScroll end
            end

            this:SetVerticalScroll(current)
        end)

        if count == 0 then
            local empty = ZugZug_UI_CreateText(child, nil, "|cff777777No active LFG groups.|r", "small")
            empty:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
        else
            local listY = 0

            for id, listing in pairs(ZugZug.LFG.listings) do
                if listing then
                    ZugZug_UI_CreateMiniLFGRow(child, listing, 0, listY, width - 20)
                    listY = listY - rowHeight
                end
            end
        end
    end

    return lfgPanel
end

local function ZugZug_UI_CreateIdentityPanel(parent, width, height)
    local panel = ZugZug_UI_CreateCard(parent, width, height)

    local title = ZugZug_UI_CreateText(panel, nil, "|cffffd100Verified Characters|r", "normal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)

    local identity = ZugZug.dashboardIdentity or {}
    local visibleRealms = {}
    local visibleTotal = 0
    local realmOrder = { "capycraft", "turtle" }
    local realmNames = {
        capycraft = "",
        turtle = "Turtle WoW",
    }

    local function addRealmCharacters(realmKey, realmName, chars)
        local visibleChars = {}
        local i = 1

        while chars and i <= table.getn(chars) do
            local character = chars[i]

            if character and character.name and string.lower(character.name) ~= string.lower(ZugZug.BOTNAME or "") then
                if character.isCurrent then
                    table.insert(visibleChars, 1, character)
                else
                    table.insert(visibleChars, character)
                end
            end

            i = i + 1
        end

        if table.getn(visibleChars) > 0 then
            table.insert(visibleRealms, {
                realmKey = realmKey,
                realmName = realmNames[realmKey] or realmName or realmKey,
                characters = visibleChars,
            })
            visibleTotal = visibleTotal + table.getn(visibleChars)
        end
    end

    if identity.realms and table.getn(identity.realms) > 0 then
        local realmsByKey = {}
        local i = 1

        while i <= table.getn(identity.realms) do
            local realm = identity.realms[i]
            if realm and realm.realmKey then
                realmsByKey[string.lower(realm.realmKey)] = realm
            end
            i = i + 1
        end

        i = 1
        while i <= table.getn(realmOrder) do
            local key = realmOrder[i]
            local realm = realmsByKey[key]
            if realm then
                addRealmCharacters(key, realmNames[key] or realm.realmName, realm.characters or {})
            end
            i = i + 1
        end
    else
        addRealmCharacters("", "", identity.characters or {})
    end

    if not identity.updatedAt then
        local pending = ZugZug_UI_CreateText(panel, nil, "|cffaaaaaaChecking Discord verification...|r", "small")
        pending:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
        pending:SetWidth(width - 20)
        return panel
    end

    if not identity.verified or visibleTotal == 0 then
        local prompt = ZugZug_UI_CreateText(panel, nil, "|cffaaaaaaPlease verify on Discord for more features.|r", "small")
        prompt:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
        prompt:SetWidth(width - 20)
        prompt:SetJustifyH("LEFT")

        local verify = ZugZug_UI_CreateText(panel, nil, "|cffaaaaaaTo verify, run the |r|cff69ccf0/capy verify|r|cffaaaaaa command in Discord|r", "small")
        verify:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -52)
        verify:SetWidth(width - 20)
        verify:SetJustifyH("LEFT")

        return panel
    end

    local status = ZugZug_UI_CreateText(panel, nil, "|cff00ff00Verified|r", "small")
    status:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)

    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -34)
    scroll:SetWidth(width - 20)
    scroll:SetHeight(height - 44)
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(width - 20)

    local rowHeight = 20
    local headerHeight = 18
    local childHeight = 0
    local realmIndex = 1

    while realmIndex <= table.getn(visibleRealms) do
        local realm = visibleRealms[realmIndex]
        if realm.realmName and realm.realmName ~= "" then
            childHeight = childHeight + headerHeight
        end
        childHeight = childHeight + (table.getn(realm.characters or {}) * rowHeight)
        realmIndex = realmIndex + 1
    end

    if childHeight < height - 43 then childHeight = height - 43 end
    child:SetHeight(childHeight)
    scroll:SetScrollChild(child)

    scroll:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()

        if not current then current = 0 end
        if not maxScroll then maxScroll = 0 end

        if arg1 and arg1 > 0 then
            current = current - 28
            if current < 0 then current = 0 end
        else
            current = current + 28
            if current > maxScroll then current = maxScroll end
        end

        this:SetVerticalScroll(current)
    end)

    local y = 0
    realmIndex = 1

    while realmIndex <= table.getn(visibleRealms) do
        local realm = visibleRealms[realmIndex]
        local headerText = realm.realmName or ""

        if headerText ~= "" then
            local header = ZugZug_UI_CreateText(child, nil, "|cffffd100" .. headerText .. "|r", "small")
            header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, y)
            header:SetWidth(width - 20)
            y = y - headerHeight
        end

        local i = 1
        while realm.characters and i <= table.getn(realm.characters) do
            local character = realm.characters[i]

            if character and character.name then
                local level = tonumber(character.level or 0) or 0
                local levelText = ""
                if level > 0 then
                    levelText = "|cffaaaaaa[" .. tostring(level) .. "]|r "
                end

                local nameText = levelText .. ZugZug_ClassColorize(character.name)
                if character.isCurrent then
                    nameText = nameText .. " |cffaaaaaa(current)|r"
                end

                local name = ZugZug_UI_CreateText(child, nil, nameText, "normal")
                name:SetPoint("TOPLEFT", child, "TOPLEFT", 6, y)
                name:SetWidth(width - 26)

                y = y - rowHeight
            end

            i = i + 1
        end

        realmIndex = realmIndex + 1
    end

    return panel
end

-- Default Tabs

local function ZugZug_UI_BuildDashboard(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "Dashboard", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local onlineCount = 0
    if ZugZug_GetOnlineMemberCount then
        onlineCount = ZugZug_GetOnlineMemberCount()
    end

    local summary = ZugZug_UI_CreateText(parent, nil, "|cff00ff00Online:|r " .. tostring(onlineCount), "normal")
    summary:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, 0)

    local panelTop = -24
    local leftWidth = 315
    local rightWidth = 315
    local gap = 4
    local fullHeight = 336

    local left = ZugZug_UI_CreateCapyChatPanel(parent, leftWidth, fullHeight)
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, panelTop)

    local state = ZugZug.dashboardState or {}

    local motd = ""
    if state.guildMotd and state.guildMotd ~= "" then
        motd = state.guildMotd
    elseif GetGuildRosterMOTD then
        motd = GetGuildRosterMOTD() or ""
    end

    if motd == "" then
        motd = "No guild MOTD."
    end

    local hasShellcoin = false
    if state.updatedAt and state.shellGold ~= nil and state.shellSilver ~= nil and state.shellCopper ~= nil then
        hasShellcoin = true
    end

    local hasDarkmoon = false
    if state.updatedAt and state.dmfLocation and state.dmfLocation ~= "" then
        hasDarkmoon = true
    end

    local hasDarkmoonNext = false
    if hasDarkmoon and state.dmfNextLocation and state.dmfNextLocation ~= "" then
        hasDarkmoonNext = true
    end

    local motdLen = string.len(motd or "")
    local motdLines = 1

    if motdLen > 42 then
        motdLines = 2
    end

    if motdLen > 84 then
        motdLines = 3
    end

    local infoHeight = 48 + (motdLines * 13)

    if hasShellcoin then
        infoHeight = infoHeight + 18
    end

    if hasDarkmoon then
        infoHeight = infoHeight + 18
    end

    if hasDarkmoonNext then
        infoHeight = infoHeight + 18
    end

    if infoHeight < 92 then
        infoHeight = 92
    end

    if infoHeight > 152 then
        infoHeight = 152
    end

    local bottomRightHeight = fullHeight - infoHeight - gap

    local info = ZugZug_UI_CreateCard(parent, rightWidth, infoHeight)
    info:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, panelTop)

    local infoTitle = ZugZug_UI_CreateText(info, nil, "|cffffd100Guild Info|r", "normal")
    infoTitle:SetPoint("TOPLEFT", info, "TOPLEFT", 10, -8)

    local y = -30
    local labelWidth = 92
    local valueX = 104
    local valueWidth = rightWidth - valueX - 10

    local motdLabel = ZugZug_UI_CreateText(info, nil, "|cff00ff00MOTD|r", "small")
    motdLabel:SetPoint("TOPLEFT", info, "TOPLEFT", 10, y)

    local motdText = ZugZug_UI_CreateText(info, nil, "|cffffffff" .. motd .. "|r", "small")
    motdText:SetPoint("TOPLEFT", info, "TOPLEFT", valueX, y)
    motdText:SetWidth(valueWidth)
    motdText:SetJustifyH("LEFT")

    y = y - (motdLines * 13) - 5

    if hasShellcoin then
        local shellText = ZugZug_FormatMoney(
            state.shellGold or 0,
            state.shellSilver or 0,
            state.shellCopper or 0
        )

        local shellLabel = ZugZug_UI_CreateText(info, nil, "|cff00ff00Shellcoin|r", "small")
        shellLabel:SetPoint("TOPLEFT", info, "TOPLEFT", 10, y)
        shellLabel:SetWidth(labelWidth)

        local shellValue = ZugZug_UI_CreateText(info, nil, "|cffffd100" .. shellText .. "|r", "small")
        shellValue:SetPoint("TOPLEFT", info, "TOPLEFT", valueX, y)
        shellValue:SetWidth(valueWidth)

        y = y - 18
    end

    local dmfNextText = nil

    if hasDarkmoon then
        local dmfCurrent = state.dmfLocation or ""

        local dmfLabel = ZugZug_UI_CreateText(info, nil, "|cff00ff00Darkmoon Faire|r", "small")
        dmfLabel:SetPoint("TOPLEFT", info, "TOPLEFT", 10, y)
        dmfLabel:SetWidth(labelWidth)

        local dmfCurrentText = ZugZug_UI_CreateText(info, nil, "|cffffffff" .. dmfCurrent .. "|r", "small")
        dmfCurrentText:SetPoint("TOPLEFT", info, "TOPLEFT", valueX, y)
        dmfCurrentText:SetWidth(valueWidth)

        y = y - 18
    end

    if hasDarkmoonNext then
        local dmfNext = state.dmfNextLocation or ""

        dmfNextText = ZugZug_UI_CreateText(info, nil, "", "small")
        dmfNextText:SetPoint("TOPLEFT", info, "TOPLEFT", valueX, y)
        dmfNextText:SetWidth(valueWidth)

        local nextLabel = ZugZug_UI_CreateText(info, nil, "|cffaaaaaaNext Location|r", "small")
        nextLabel:SetPoint("TOPLEFT", info, "TOPLEFT", 10, y)
        nextLabel:SetWidth(labelWidth)

        local function updateDashboardCountdown()
            local dmfTime = ""

            if state.dmfNextAt and state.dmfNextAt > 0 then
                dmfTime = ZugZug_FormatTimeRemaining(state.dmfNextAt)
            end

            if dmfTime and dmfTime ~= "" then
                dmfNextText:SetText("|cffffffff" .. dmfNext .. "|r |cffaaaaaain " .. dmfTime .. "|r")
            else
                dmfNextText:SetText("|cffffffff" .. dmfNext .. "|r")
            end
        end

        updateDashboardCountdown()

        info.lastCountdownUpdate = 0
        info:SetScript("OnUpdate", function()
            local now = GetTime()

            if not this.lastCountdownUpdate or now - this.lastCountdownUpdate >= 1 then
                this.lastCountdownUpdate = now
                updateDashboardCountdown()
            end
        end)
    end

    local identityPanel = ZugZug_UI_CreateIdentityPanel(parent, rightWidth, bottomRightHeight)
    identityPanel:SetPoint("TOPRIGHT", info, "BOTTOMRIGHT", 0, -gap)
end

local function ZugZug_UI_BuildLFG(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "Guild LFG", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local canCreate = true

    if ZugZug_LFG_CanCreateListing and not ZugZug_LFG_CanCreateListing() then
        canCreate = false
    end

    if not canCreate and ZugZug_LFG_IsCreateOpen and ZugZug_LFG_IsCreateOpen() then
        ZugZug_LFG_SetCreateOpen(false)
    end

    if canCreate then
        local createButtonText = "New Group"

        if ZugZug_LFG_IsCreateOpen and ZugZug_LFG_IsCreateOpen() then
            createButtonText = "Cancel"
        end

        local createButton = ZugZug_UI_CreateButton(parent, nil, createButtonText, 88, 22)
        createButton:SetPoint("LEFT", title, "RIGHT", 14, 1)
        createButton:SetScript("OnClick", function()
            if ZugZug_LFG_IsCreateOpen and ZugZug_LFG_IsCreateOpen() then
                ZugZug_LFG_SetCreateOpen(false)
            else
                ZugZug_LFG_SetCreateOpen(true)
            end

            ZugZug.UI.selectedJoinListingId = nil
            ZugZug.UI.confirmCloseListingId = nil
            ZugZug_UI_ShowTab("lfg")
        end)
    end

    local count = 0
    if ZugZug_LFG_GetListingCount then
        count = ZugZug_LFG_GetListingCount()
    end

    local summary = ZugZug_UI_CreateText(parent, nil, "|cff00ff00Active:|r " .. count, "normal")
    summary:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, 0)

    local listTop = -34
    local listHeight = 320

    if ZugZug_LFG_IsCreateOpen and ZugZug_LFG_IsCreateOpen() then
        local panel = ZugZug_UI_CreateCard(parent, 634, 136)
        panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -30)

        local typeLabel = ZugZug_UI_CreateText(panel, nil, "Type", "small")
        typeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)

        local typePicker = ZugZug_UI_CreateTypePicker(panel)
        typePicker:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -29)

        local targetLabel = ZugZug_UI_CreateText(panel, nil, "Target", "small")
        targetLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 132, -8)

        local currentType = ZugZug_LFG_GetCreateType()

        if currentType == "Other" then
            local targetFrame, targetEdit = ZugZug_UI_CreateCleanEditBox(panel, 235, 24, ZugZug.LFG.currentCustomTarget or "")
            targetFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 132, -29)
            targetEdit:SetScript("OnTextChanged", function()
                ZugZug_LFG_SetCreateTarget(this:GetText())
            end)
        else
            local targetPicker = ZugZug_UI_CreateTargetPicker(panel)
            targetPicker:SetPoint("TOPLEFT", panel, "TOPLEFT", 132, -29)
        end

        local noteLabel = ZugZug_UI_CreateText(panel, nil, "Note", "small")
        noteLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 390, -8)

        local noteFrame, noteEdit = ZugZug_UI_CreateCleanEditBox(panel, 150, 24, ZugZug_LFG_GetCreateNote())
        noteFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 384, -29)
        noteEdit:SetScript("OnTextChanged", function()
            ZugZug_LFG_SetCreateNote(this:GetText())
        end)

        local postButton = ZugZug_UI_CreateButton(panel, nil, "Post", 70, 24)
        postButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -27)
        postButton:SetScript("OnClick", function()
            ZugZug_LFG_CreateListing(ZugZug_LFG_GetCreateTarget(), ZugZug_LFG_GetCreateNote())
        end)

        local roleLabel = ZugZug_UI_CreateText(panel, nil, "Your role", "small")
        roleLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -64)

        local selectedRole = ZugZug_LFG_GetCreateRole()

        local tankRole = ZugZug_UI_CreateRoleChoiceButton(panel, "TANK", selectedRole == "TANK", 72, 22)
        tankRole:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -82)
        tankRole:SetScript("OnClick", function()
            ZugZug_LFG_SetCreateRole("TANK")
            ZugZug_UI_ShowTab("lfg")
        end)

        local healerRole = ZugZug_UI_CreateRoleChoiceButton(panel, "HEALER", selectedRole == "HEALER", 72, 22)
        healerRole:SetPoint("LEFT", tankRole, "RIGHT", 8, 0)
        healerRole:SetScript("OnClick", function()
            ZugZug_LFG_SetCreateRole("HEALER")
            ZugZug_UI_ShowTab("lfg")
        end)

        local dpsRole = ZugZug_UI_CreateRoleChoiceButton(panel, "DPS", selectedRole == "DPS", 72, 22)
        dpsRole:SetPoint("LEFT", healerRole, "RIGHT", 8, 0)
        dpsRole:SetScript("OnClick", function()
            ZugZug_LFG_SetCreateRole("DPS")
            ZugZug_UI_ShowTab("lfg")
        end)

        local needLabel = ZugZug_UI_CreateText(panel, nil, "Need", "small")
        needLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 300, -64)

        local tankIcon = ZugZug_UI_CreateRoleIcon(panel, "TANK", 18)
        tankIcon:SetPoint("TOPLEFT", panel, "TOPLEFT", 300, -84)

        local tankText = ZugZug_UI_CreateText(panel, nil, tostring(ZugZug.LFG.createNeedTank or 0), "normal")
        tankText:SetPoint("LEFT", tankIcon, "RIGHT", 5, 0)

        local tankMinus = ZugZug_UI_CreateButton(panel, nil, "-", 20, 18)
        tankMinus:SetPoint("LEFT", tankText, "RIGHT", 8, 0)
        tankMinus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("TANK", -1)
            ZugZug_UI_ShowTab("lfg")
        end)

        local tankPlus = ZugZug_UI_CreateButton(panel, nil, "+", 20, 18)
        tankPlus:SetPoint("LEFT", tankMinus, "RIGHT", 2, 0)
        tankPlus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("TANK", 1)
            ZugZug_UI_ShowTab("lfg")
        end)

        local healerIcon = ZugZug_UI_CreateRoleIcon(panel, "HEALER", 18)
        healerIcon:SetPoint("LEFT", tankPlus, "RIGHT", 18, 0)

        local healerText = ZugZug_UI_CreateText(panel, nil, tostring(ZugZug.LFG.createNeedHealer or 0), "normal")
        healerText:SetPoint("LEFT", healerIcon, "RIGHT", 5, 0)

        local healerMinus = ZugZug_UI_CreateButton(panel, nil, "-", 20, 18)
        healerMinus:SetPoint("LEFT", healerText, "RIGHT", 8, 0)
        healerMinus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("HEALER", -1)
            ZugZug_UI_ShowTab("lfg")
        end)

        local healerPlus = ZugZug_UI_CreateButton(panel, nil, "+", 20, 18)
        healerPlus:SetPoint("LEFT", healerMinus, "RIGHT", 2, 0)
        healerPlus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("HEALER", 1)
            ZugZug_UI_ShowTab("lfg")
        end)

        local dpsIcon = ZugZug_UI_CreateRoleIcon(panel, "DPS", 18)
        dpsIcon:SetPoint("LEFT", healerPlus, "RIGHT", 18, 0)

        local dpsText = ZugZug_UI_CreateText(panel, nil, tostring(ZugZug.LFG.createNeedDps or 0), "normal")
        dpsText:SetPoint("LEFT", dpsIcon, "RIGHT", 5, 0)

        local dpsMinus = ZugZug_UI_CreateButton(panel, nil, "-", 20, 18)
        dpsMinus:SetPoint("LEFT", dpsText, "RIGHT", 8, 0)
        dpsMinus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("DPS", -1)
            ZugZug_UI_ShowTab("lfg")
        end)

        local dpsPlus = ZugZug_UI_CreateButton(panel, nil, "+", 20, 18)
        dpsPlus:SetPoint("LEFT", dpsMinus, "RIGHT", 2, 0)
        dpsPlus:SetScript("OnClick", function()
            ZugZug_LFG_AdjustNeed("DPS", 1)
            ZugZug_UI_ShowTab("lfg")
        end)

        listTop = -180
        listHeight = 174
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, listTop)
    scrollFrame:SetWidth(634)
    scrollFrame:SetHeight(listHeight)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(634)

    local cardWidth = 306
    local cardHeight = 132
    local rows = math.ceil(count / 2)

    if rows < 1 then rows = 1 end

    local childHeight = rows * (cardHeight + 10)
    if childHeight < listHeight + 1 then
        childHeight = listHeight + 1
    end

    scrollChild:SetHeight(childHeight)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()

        if not current then current = 0 end
        if not maxScroll then maxScroll = 0 end

        if arg1 and arg1 > 0 then
            current = current - 42
            if current < 0 then current = 0 end
        else
            current = current + 42
            if current > maxScroll then current = maxScroll end
        end

        this:SetVerticalScroll(current)
    end)

    if count == 0 then
        local empty = ZugZug_UI_CreateText(scrollChild, nil, "|cffaaaaaaNo active guild LFG listings.|r", "normal")
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
        return
    end

    local index = 0

    for id, listing in pairs(ZugZug.LFG.listings) do
        if listing then
            local col = math.mod(index, 2)
            local row = math.floor(index / 2)

            local card = ZugZug_UI_CreateCard(scrollChild, cardWidth, cardHeight)
            card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", col * 316, -(row * (cardHeight + 10)))

            local leader = listing.leader or ""
            local leaderText = ZugZug_ClassColorize(leader)
            local leaderRole = listing.leaderRole or "DPS"

            if not ZugZug_LFG_IsValidRole(leaderRole) then
                leaderRole = "DPS"
            end

            local roleCounts = { TANK = 0, HEALER = 0, DPS = 0 }
            if ZugZug_LFG_CountRoles then
                roleCounts = ZugZug_LFG_CountRoles(listing)
            end

            local titleText = "|cffffffff[" .. (listing.type or "Other") .. "]|r |cffffd100" .. (listing.target or "") .. "|r"

            local rowTitle = ZugZug_UI_CreateText(card, nil, titleText, "normal")
            rowTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)

            local leaderIcon = ZugZug_UI_CreateZugIcon(card, 13)
            leaderIcon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -30)

            local rowLeader = ZugZug_UI_CreateText(card, nil, leaderText, "small")
            rowLeader:SetPoint("LEFT", leaderIcon, "RIGHT", 4, 0)

            local needTankIcon = ZugZug_UI_CreateRoleIcon(card, "TANK", 14)
            needTankIcon:SetPoint("TOPLEFT", card, "TOPLEFT", 166, -30)

            local needTankText = ZugZug_UI_CreateText(card, nil, tostring(roleCounts.TANK or 0) .. "/" .. tostring(listing.needTank or 0), "small")
            needTankText:SetPoint("LEFT", needTankIcon, "RIGHT", 2, 0)

            local needHealerIcon = ZugZug_UI_CreateRoleIcon(card, "HEALER", 14)
            needHealerIcon:SetPoint("LEFT", needTankText, "RIGHT", 7, 0)

            local needHealerText = ZugZug_UI_CreateText(card, nil, tostring(roleCounts.HEALER or 0) .. "/" .. tostring(listing.needHealer or 0), "small")
            needHealerText:SetPoint("LEFT", needHealerIcon, "RIGHT", 2, 0)

            local needDpsIcon = ZugZug_UI_CreateRoleIcon(card, "DPS", 14)
            needDpsIcon:SetPoint("LEFT", needHealerText, "RIGHT", 7, 0)

            local needDpsText = ZugZug_UI_CreateText(card, nil, tostring(roleCounts.DPS or 0) .. "/" .. tostring(listing.needDps or 0), "small")
            needDpsText:SetPoint("LEFT", needDpsIcon, "RIGHT", 2, 0)

            local playerName = UnitName("player")
            local isLeader = false
            local isMember = false

            if leader == playerName then
                isLeader = true
            end

            if ZugZug_LFG_IsListingMember and ZugZug_LFG_IsListingMember(listing, playerName) then
                isMember = true
            end

            local isFull = false
            if ZugZug_LFG_IsListingFull and ZugZug_LFG_IsListingFull(listing) then
                isFull = true
            end

            local memberX = 10
            local memberY = -54
            local memberIndex = 1

            while listing.members and memberIndex <= table.getn(listing.members) do
                local member = listing.members[memberIndex]

                if member and member.name then
                    local memberRole = member.role or "DPS"

                    if not ZugZug_LFG_IsValidRole(memberRole) then
                        memberRole = "DPS"
                    end

                    local roleButton = CreateFrame("Button", nil, card)
                    roleButton:SetWidth(13)
                    roleButton:SetHeight(13)
                    roleButton:SetPoint("TOPLEFT", card, "TOPLEFT", memberX, memberY)
                    roleButton.lfgId = id
                    roleButton.memberName = member.name
                    roleButton.memberRole = memberRole

                    local roleIcon = ZugZug_UI_CreateRoleIcon(roleButton, memberRole, 13)
                    roleIcon:SetAllPoints(roleButton)

                    if isLeader then
                        roleButton:SetScript("OnClick", function()
                            ZugZug_LFG_CycleListingMemberRole(this.lfgId, this.memberName)
                        end)

                        roleButton:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                            GameTooltip:SetText("Click to change role")
                            GameTooltip:Show()
                        end)

                        roleButton:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                    elseif member.name == playerName then
                        roleButton:SetScript("OnClick", function()
                            local nextRole = ZugZug_LFG_GetNextRole(this.memberRole)
                            ZugZug_LFG_RequestMyRoleChange(this.lfgId, nextRole)
                        end)

                        roleButton:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                            GameTooltip:SetText("Click to change your role")
                            GameTooltip:Show()
                        end)

                        roleButton:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                    end

                    local memberName = ZugZug_ClassColorize(member.name)
                    local memberText = ZugZug_UI_CreateText(card, nil, memberName, "small")
                    memberText:SetPoint("LEFT", roleButton, "RIGHT", 3, 0)

                    memberX = memberX + 94

                    if memberX > 205 then
                        memberX = 10
                        memberY = memberY - 15
                    end
                end

                memberIndex = memberIndex + 1
            end

            if listing.note and listing.note ~= "" then
                local note = ZugZug_UI_CreateText(card, nil, "|cff777777" .. listing.note .. "|r", "small")
                note:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -84)
            end

            if isLeader then
                if ZugZug.UI.confirmCloseListingId == id then
                    local confirmButton = ZugZug_UI_CreateButton(card, nil, "Confirm", 66, 20)
                    confirmButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -64, 8)
                    confirmButton.lfgId = id
                    confirmButton:SetScript("OnClick", function()
                        ZugZug.UI.confirmCloseListingId = nil
                        ZugZug_LFG_CloseListing(this.lfgId)
                    end)

                    local cancelButton = ZugZug_UI_CreateButton(card, nil, "Cancel", 54, 20)
                    cancelButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
                    cancelButton:SetScript("OnClick", function()
                        ZugZug.UI.confirmCloseListingId = nil
                        ZugZug_UI_ShowTab("lfg")
                    end)
                else
                    local closeButton = ZugZug_UI_CreateButton(card, nil, "Close", 54, 20)
                    closeButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
                    closeButton.lfgId = id
                    closeButton:SetScript("OnClick", function()
                        ZugZug.UI.confirmCloseListingId = this.lfgId
                        ZugZug_UI_ShowTab("lfg")
                    end)
                end
            elseif isMember then
                -- hmm
            else
                local canJoinThis = true

                if ZugZug_LFG_PlayerHasActiveListing and ZugZug_LFG_PlayerHasActiveListing() then
                    canJoinThis = false
                end

                if not canJoinThis then
                    local busyText = ZugZug_UI_CreateText(card, nil, "|cff777777Already in LFG|r", "small")
                    busyText:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 11)
                elseif isFull then
                    local fullText = ZugZug_UI_CreateText(card, nil, "|cff777777Full|r", "small")
                    fullText:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 11)
                elseif ZugZug.UI.selectedJoinListingId == id then
                    local roleText = ZugZug_UI_CreateText(card, nil, "Join as:", "small")
                    roleText:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 11)

                    local last = roleText
                    local added = false

                    if not ZugZug_LFG_IsRoleFull or not ZugZug_LFG_IsRoleFull(listing, "TANK") then
                        local joinTank = ZugZug_UI_CreateRoleChoiceButton(card, "TANK", false, 50, 20)
                        joinTank:SetPoint("LEFT", last, "RIGHT", 6, 0)
                        joinTank.lfgId = id
                        joinTank:SetScript("OnClick", function()
                            ZugZug_LFG_JoinListing(this.lfgId, "TANK")
                        end)
                        last = joinTank
                        added = true
                    end

                    if not ZugZug_LFG_IsRoleFull or not ZugZug_LFG_IsRoleFull(listing, "HEALER") then
                        local joinHealer = ZugZug_UI_CreateRoleChoiceButton(card, "HEALER", false, 50, 20)
                        joinHealer:SetPoint("LEFT", last, "RIGHT", 4, 0)
                        joinHealer.lfgId = id
                        joinHealer:SetScript("OnClick", function()
                            ZugZug_LFG_JoinListing(this.lfgId, "HEALER")
                        end)
                        last = joinHealer
                        added = true
                    end

                    if not ZugZug_LFG_IsRoleFull or not ZugZug_LFG_IsRoleFull(listing, "DPS") then
                        local joinDps = ZugZug_UI_CreateRoleChoiceButton(card, "DPS", false, 50, 20)
                        joinDps:SetPoint("LEFT", last, "RIGHT", 4, 0)
                        joinDps.lfgId = id
                        joinDps:SetScript("OnClick", function()
                            ZugZug_LFG_JoinListing(this.lfgId, "DPS")
                        end)
                        added = true
                    end

                    if not added then
                        roleText:SetText("|cff777777Full|r")
                    end
                else
                    local joinButton = ZugZug_UI_CreateButton(card, nil, "Join", 54, 20)
                    joinButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
                    joinButton.lfgId = id
                    joinButton:SetScript("OnClick", function()
                        ZugZug.UI.selectedJoinListingId = this.lfgId
                        ZugZug_UI_ShowTab("lfg")
                    end)
                end
            end

            index = index + 1
        end
    end
end

local function ZugZug_UI_BuildAuctionHouse(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "WoWAuctions Search", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local body = ZugZug_UI_CreateText(parent, nil, "Auction House search will go here.", "normal")
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
end

local function ZugZug_UI_BuildGuild(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "Online Members", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local playerZone = ""
    if GetRealZoneText then
        playerZone = GetRealZoneText() or ""
    elseif GetZoneText then
        playerZone = GetZoneText() or ""
    end

    local totalOnline = 0
    if ZugZug_GetOnlineMemberCount then
        totalOnline = ZugZug_GetOnlineMemberCount()
    end

    local sameZoneOnly = ZugZug_IsRosterSameZoneOnly()
    local playerName = UnitName("player")

    local visibleCount = 0
    local nearbyCount = 0

    local i = 1
    while ZugZug.onlineMembers and i <= table.getn(ZugZug.onlineMembers) do
        local member = ZugZug.onlineMembers[i]

        if member and member.name then
            if member.zone == playerZone and member.name ~= playerName then
                nearbyCount = nearbyCount + 1
            end

            if not sameZoneOnly or member.zone == playerZone then
                visibleCount = visibleCount + 1
            end
        end

        i = i + 1
    end

    local summaryText = "|cff00ff00Online:|r " .. totalOnline .. " |cffaaaaaa(" .. nearbyCount .. " nearby)|r"

    local summary = ZugZug_UI_CreateText(parent, nil, summaryText, "normal")
    summary:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, 0)

    local zoneCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    zoneCheck:SetWidth(20)
    zoneCheck:SetHeight(20)
    zoneCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", -4, -20)

    if sameZoneOnly then
        zoneCheck:SetChecked(1)
    else
        zoneCheck:SetChecked(nil)
    end

    zoneCheck:SetScript("OnClick", function()
        if this:GetChecked() then
            ZugZug_SetRosterSameZoneOnly(true)
        else
            ZugZug_SetRosterSameZoneOnly(false)
        end

        ZugZug_UI_ShowTab("guild")
    end)

    local zoneCheckText = ZugZug_UI_CreateText(parent, nil, "Only Show Nearby", "small")
    zoneCheckText:SetPoint("LEFT", zoneCheck, "RIGHT", -2, 1)

    -- Columns: Level, Name, Zone
    local headerLevel = ZugZug_UI_CreateText(parent, nil, "|cffaaaaaaLv|r", "small")
    headerLevel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -46)

    local headerName = ZugZug_UI_CreateText(parent, nil, "|cffaaaaaaName|r", "small")
    headerName:SetPoint("TOPLEFT", parent, "TOPLEFT", 52, -46)

    local headerZone = ZugZug_UI_CreateText(parent, nil, "|cffaaaaaaZone|r", "small")
    headerZone:SetWidth(240)
    headerZone:SetJustifyH("RIGHT")
    headerZone:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -46)

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -64)
    scrollFrame:SetWidth(634)
    scrollFrame:SetHeight(290)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(634)

    local rowHeight = 18
    local visibleHeight = 290
    local totalRows = visibleCount

    if totalRows < 1 then
        totalRows = 1
    end

    local childHeight = totalRows * rowHeight
    if childHeight < visibleHeight + 1 then
        childHeight = visibleHeight + 1
    end

    scrollChild:SetHeight(childHeight)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()

        if not current then current = 0 end
        if not maxScroll then maxScroll = 0 end

        if arg1 and arg1 > 0 then
            current = current - 36
            if current < 0 then current = 0 end
        else
            current = current + 36
            if current > maxScroll then current = maxScroll end
        end

        this:SetVerticalScroll(current)
    end)

    if visibleCount == 0 then
        local emptyText = "|cffaaaaaaNo online members cached yet.|r"
        if sameZoneOnly then
            emptyText = "|cffaaaaaaNo online guildies found in your current zone.|r"
        end

        local empty = ZugZug_UI_CreateText(scrollChild, nil, emptyText, "normal")
        empty:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
        return
    end

    local y = 0
    i = 1

    while ZugZug.onlineMembers and i <= table.getn(ZugZug.onlineMembers) do
        local member = ZugZug.onlineMembers[i]

        if member and member.name then
            local showMember = true

            if sameZoneOnly and member.zone ~= playerZone then
                showMember = false
            end

            if showMember then
                local coloredName = ZugZug_ClassColorize(member.name)
                local version = ZugZug_GetAddonVersionForMember(member.name)

                local nameText = coloredName

                if member.rankIndex == 0 then
                    nameText = nameText .. " |cffffd100(GM)|r"
                elseif member.rankIndex and member.rankIndex <= 2 then
                    nameText = nameText .. " |cff00ffff(Officer)|r"
                end

                if version then
                    nameText = nameText .. " |cff777777v" .. version .. "|r"
                end

                local level = member.level or ""
                local zone = member.zone or ""

                local zoneColor = "|cffffffff"
                if zone ~= "" and zone == playerZone then
                    zoneColor = "|cff00ff00"
                end

                local levelFont = ZugZug_UI_CreateText(scrollChild, nil, tostring(level), "normal")
                levelFont:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)

                local nameFont = ZugZug_UI_CreateText(scrollChild, nil, nameText, "normal")
                nameFont:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 52, y)

                local zoneFont = ZugZug_UI_CreateText(scrollChild, nil, zoneColor .. zone .. "|r", "normal")
                zoneFont:SetWidth(240)
                zoneFont:SetJustifyH("RIGHT")
                zoneFont:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, y)

                y = y - rowHeight
            end
        end

        i = i + 1
    end
end

local function ZugZug_UI_BuildSettings(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "Settings", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local leftX = 0
    local rightX = 330

    local savedRole = "DPS"
    if ZugZug_LFG_GetCreateRole then
        savedRole = ZugZug_LFG_GetCreateRole()
    elseif ZugZug_GetSavedLFGRole then
        savedRole = ZugZug_GetSavedLFGRole(UnitName("player")) or "DPS"
    end

    local roleTitle = ZugZug_UI_CreateText(parent, nil, "Preferred Role", "normal")
    roleTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", leftX, -34)

    local tankButton = ZugZug_UI_CreateRoleChoiceButton(parent, "TANK", savedRole == "TANK", 82, 24)
    tankButton:SetPoint("TOPLEFT", parent, "TOPLEFT", leftX, -56)
    tankButton:SetScript("OnClick", function()
        if ZugZug_LFG_SetCreateRole then
            ZugZug_LFG_SetCreateRole("TANK")
        elseif ZugZug_SaveLFGRole then
            ZugZug_SaveLFGRole(UnitName("player"), "TANK")
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local healerButton = ZugZug_UI_CreateRoleChoiceButton(parent, "HEALER", savedRole == "HEALER", 82, 24)
    healerButton:SetPoint("LEFT", tankButton, "RIGHT", 8, 0)
    healerButton:SetScript("OnClick", function()
        if ZugZug_LFG_SetCreateRole then
            ZugZug_LFG_SetCreateRole("HEALER")
        elseif ZugZug_SaveLFGRole then
            ZugZug_SaveLFGRole(UnitName("player"), "HEALER")
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local dpsButton = ZugZug_UI_CreateRoleChoiceButton(parent, "DPS", savedRole == "DPS", 82, 24)
    dpsButton:SetPoint("LEFT", healerButton, "RIGHT", 8, 0)
    dpsButton:SetScript("OnClick", function()
        if ZugZug_LFG_SetCreateRole then
            ZugZug_LFG_SetCreateRole("DPS")
        elseif ZugZug_SaveLFGRole then
            ZugZug_SaveLFGRole(UnitName("player"), "DPS")
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local lfgTitle = ZugZug_UI_CreateText(parent, nil, "LFG", "normal")
    lfgTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", leftX, -96)

    local lfgNotifications = true
    if ZugZug_GetEnableLFGNotifications then
        lfgNotifications = ZugZug_GetEnableLFGNotifications()
    end

    local lfgNotifyCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    lfgNotifyCheck:SetWidth(24)
    lfgNotifyCheck:SetHeight(24)
    lfgNotifyCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", leftX - 4, -114)

    if lfgNotifications then
        lfgNotifyCheck:SetChecked(1)
    else
        lfgNotifyCheck:SetChecked(nil)
    end

    lfgNotifyCheck:SetScript("OnClick", function()
        if this:GetChecked() then
            ZugZug_SetEnableLFGNotifications(true)
        else
            ZugZug_SetEnableLFGNotifications(false)
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local lfgNotifyText = ZugZug_UI_CreateText(parent, nil, "Enable LFG Notifications", "normal")
    lfgNotifyText:SetPoint("LEFT", lfgNotifyCheck, "RIGHT", 0, 1)

    local loginTitle = ZugZug_UI_CreateText(parent, nil, "Startup", "normal")
    loginTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX, -34)

    local showOnLogin = false
    if ZugZug_GetShowWindowOnLogin then
        showOnLogin = ZugZug_GetShowWindowOnLogin()
    end

    local loginCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    loginCheck:SetWidth(24)
    loginCheck:SetHeight(24)
    loginCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX - 4, -52)

    if showOnLogin then
        loginCheck:SetChecked(1)
    else
        loginCheck:SetChecked(nil)
    end

    loginCheck:SetScript("OnClick", function()
        if this:GetChecked() then
            ZugZug_SetShowWindowOnLogin(true)
        else
            ZugZug_SetShowWindowOnLogin(false)
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local loginText = ZugZug_UI_CreateText(parent, nil, "Show window on login", "normal")
    loginText:SetPoint("LEFT", loginCheck, "RIGHT", 0, 1)

    local locationTitle = ZugZug_UI_CreateText(parent, nil, "Guild Location", "normal")
    locationTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX, -90)

    local showLocations = false
    if ZugZug_GetShowGuildLocations then
        showLocations = ZugZug_GetShowGuildLocations()
    end

    local showCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    showCheck:SetWidth(24)
    showCheck:SetHeight(24)
    showCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX - 4, -108)

    if showLocations then
        showCheck:SetChecked(1)
    else
        showCheck:SetChecked(nil)
    end

    showCheck:SetScript("OnClick", function()
        if this:GetChecked() then
            ZugZug_SetShowGuildLocations(true)
        else
            ZugZug_SetShowGuildLocations(false)
            ZugZug_Map_UpdateGuildPins()
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local showText = ZugZug_UI_CreateText(parent, nil, "Show guildies' location on map", "normal")
    showText:SetPoint("LEFT", showCheck, "RIGHT", 0, 1)

    local shareLocation = false
    if ZugZug_GetShareMyLocation then
        shareLocation = ZugZug_GetShareMyLocation()
    end

    local shareCheck = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    shareCheck:SetWidth(24)
    shareCheck:SetHeight(24)
    shareCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX - 4, -134)

    if shareLocation then
        shareCheck:SetChecked(1)
    else
        shareCheck:SetChecked(nil)
    end

    shareCheck:SetScript("OnClick", function()
        if this:GetChecked() then
            ZugZug_SetShareMyLocation(true)

            if ZugZug_BroadcastMyLocation then
                ZugZug_BroadcastMyLocation()
            end
        else
            ZugZug_SetShareMyLocation(false)
        end

        ZugZug_UI_ShowTab("settings")
    end)

    local shareText = ZugZug_UI_CreateText(parent, nil, "Share my location with guildies", "normal")
    shareText:SetPoint("LEFT", shareCheck, "RIGHT", 0, 1)

    local versionText = ZugZug_UI_CreateText(parent, nil, "|cff777777ZugZug v" .. ZugZug.VERSION .. "|r", "small")
    versionText:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
end

local function ZugZug_UI_BuildOfficer(parent)
    local title = ZugZug_UI_CreateText(parent, nil, "Officer Panel", "large")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local panelHeight = 335
    local leftWidth = 315
    local rightWidth = 315
    local panelTop = -20

    local left = ZugZug_UI_CreateCard(parent, leftWidth, panelHeight)
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, panelTop)

    local right = ZugZug_UI_CreateCard(parent, rightWidth, panelHeight)
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, panelTop)

    -- Left Panel
    local chatTitle = ZugZug_UI_CreateText(left, nil, "|cff69ccf0Officer Chat|r", "normal")
    chatTitle:SetPoint("TOPLEFT", left, "TOPLEFT", 10, -8)

    local clearChat = ZugZug_UI_CreateButton(left, nil, "Clear", 54, 20)
    clearChat:SetPoint("TOPRIGHT", left, "TOPRIGHT", -10, -6)
    clearChat:SetScript("OnClick", function()
        ZugZug_ClearOfficerChatLog()
        ZugZug_UI_ShowTab("officer")
    end)

    local chatFrame = CreateFrame("ScrollingMessageFrame", nil, left)
    chatFrame:SetPoint("TOPLEFT", left, "TOPLEFT", 10, -34)
    chatFrame:SetWidth(leftWidth - 20)
    chatFrame:SetHeight(panelHeight - 48)
    chatFrame:SetFontObject(GameFontHighlightSmall)
    chatFrame:SetJustifyH("LEFT")
    chatFrame:SetMaxLines(120)
    chatFrame:SetFading(false)
    chatFrame:EnableMouseWheel(true)

    chatFrame:SetScript("OnMouseWheel", function()
        if arg1 and arg1 > 0 then
            this:ScrollUp()
        else
            this:ScrollDown()
        end
    end)

    local chatCount = 0
    if ZugZug.officerChatLog then
        chatCount = table.getn(ZugZug.officerChatLog)
    end

    if chatCount == 0 then
        chatFrame:AddMessage("|cff777777No officer chat captured yet.|r")
    else
        local i = 1

        while ZugZug.officerChatLog and i <= table.getn(ZugZug.officerChatLog) do
            local row = ZugZug.officerChatLog[i]

            if row then
                local sender = row.sender or "?"
                local msg = row.msg or ""

                chatFrame:AddMessage(ZugZug_ClassColorize(sender) .. ": |cff69ccf0" .. msg .. "|r")
            end

            i = i + 1
        end

        if chatFrame.ScrollToBottom then
            chatFrame:ScrollToBottom()
        end
    end

    -- Right Panel
    local banTitle = ZugZug_UI_CreateText(right, nil, "|cffff5555Bans|r", "normal")
    banTitle:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -8)

    local requestList = ZugZug_UI_CreateButton(right, nil, "Refresh", 70, 20)
    requestList:SetPoint("TOPRIGHT", right, "TOPRIGHT", -10, -6)
    requestList:SetScript("OnClick", function()
        ZugZug_BroadcastAddon("OFC_BANLIST_REQ~1")
    end)

    local nameLabel = ZugZug_UI_CreateText(right, nil, "Name", "small")
    nameLabel:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -34)

    local nameFrame, nameEdit = ZugZug_UI_CreateCleanEditBox(right, 96, 24, "")
    nameFrame:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -50)

    local reasonLabel = ZugZug_UI_CreateText(right, nil, "Reason", "small")
    reasonLabel:SetPoint("TOPLEFT", right, "TOPLEFT", 116, -34)

    local reasonFrame, reasonEdit = ZugZug_UI_CreateCleanEditBox(right, 118, 24, "")
    reasonFrame:SetPoint("TOPLEFT", right, "TOPLEFT", 116, -50)

    local banButton = ZugZug_UI_CreateButton(right, nil, "Ban", 54, 24)
    banButton:SetPoint("TOPRIGHT", right, "TOPRIGHT", -10, -50)
    banButton:SetScript("OnClick", function()
        local target = ZugZug_NormalizeString(nameEdit:GetText())
        local reason = ZugZug_NormalizeString(reasonEdit:GetText()) or ""

        if not target then
            ZugZug_Log("Ban target required.")
            return
        end

        if ZugZug_SendOfficerBan(target, reason) then
            nameEdit:SetText("")
            reasonEdit:SetText("")
            nameEdit:ClearFocus()
            reasonEdit:ClearFocus()
        end
    end)

    local macroTitle = ZugZug_UI_CreateText(right, nil, "Zugbot Macro", "small")
    macroTitle:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -84)

    local macroPicker = ZugZug_UI_CreateOfficerMacroPicker(right)
    macroPicker:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -100)

    local macroButton = ZugZug_UI_CreateButton(right, nil, "Run", 54, 22)
    macroButton:SetPoint("LEFT", macroPicker, "RIGHT", 8, 0)
    macroButton:SetScript("OnClick", function()
        local macro = ZugZug_GetOfficerMacro()

        if ZugZug_RunOfficerMacroCommand then
            ZugZug_RunOfficerMacroCommand(macro)
        end
    end)

    local listTitle = ZugZug_UI_CreateText(right, nil, "Banlist", "small")
    listTitle:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -134)

    local listScroll = CreateFrame("ScrollFrame", nil, right)
    listScroll:SetPoint("TOPLEFT", right, "TOPLEFT", 10, -152)
    listScroll:SetWidth(rightWidth - 20)
    listScroll:SetHeight(panelHeight - 168)
    listScroll:EnableMouseWheel(true)

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetWidth(rightWidth - 20)

    local banCount = 0
    if ZugZug.banlist then
        banCount = table.getn(ZugZug.banlist)
    end

    local banRowHeight = 18
    local listHeight = banCount * banRowHeight
    if listHeight < panelHeight - 167 then listHeight = panelHeight - 167 end

    listChild:SetHeight(listHeight)
    listScroll:SetScrollChild(listChild)

    listScroll:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()

        if not current then current = 0 end
        if not maxScroll then maxScroll = 0 end

        if arg1 and arg1 > 0 then
            current = current - 30
            if current < 0 then current = 0 end
        else
            current = current + 30
            if current > maxScroll then current = maxScroll end
        end

        this:SetVerticalScroll(current)
    end)

    if banCount == 0 then
        local emptyBan = ZugZug_UI_CreateText(listChild, nil, "|cff777777No banlist loaded. Hit Refresh.|r", "small")
        emptyBan:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, 0)
    else
        local y2 = 0
        local j = 1

        while ZugZug.banlist and j <= table.getn(ZugZug.banlist) do
            local ban = ZugZug.banlist[j]

            if ban and ban.name then
                local rowButton = CreateFrame("Button", nil, listChild)
                rowButton:SetWidth(rightWidth - 26)
                rowButton:SetHeight(16)
                rowButton:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, y2)
                rowButton.banName = ban.name
                rowButton.banReason = ban.reason or ""

                local rowText = rowButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                rowText:SetPoint("LEFT", rowButton, "LEFT", 0, 0)
                rowText:SetWidth(rightWidth - 30)
                rowText:SetJustifyH("LEFT")
                rowText:SetText("|cffff7777" .. ban.name .. "|r")
                rowButton.text = rowText

                rowButton:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText(this.banName or "Banned")

                    if this.banReason and this.banReason ~= "" then
                        GameTooltip:AddLine(this.banReason, 1, 1, 1)
                    else
                        GameTooltip:AddLine("No reason saved.", 0.7, 0.7, 0.7)
                    end

                    GameTooltip:Show()
                end)

                rowButton:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                y2 = y2 - banRowHeight
            end

            j = j + 1
        end
    end
end


local function ZugZug_UI_DegToRad(deg)
    return deg * 0.017453292519943 -- Thank fuck https://www.unitjuggler.com/convert-angle-from-deg-to-rad.html
end

local function ZugZug_UI_Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

local function ZugZug_UI_RadToDeg(rad)
    return rad * 57.295779513082
end

local function ZugZug_UI_UpdateMinimapButtonPosition()
    if not ZugZug.UI or not ZugZug.UI.minimapButton then return end

    local angle = ZugZug.minimapAngle or 225
    local radius = 78
    local rad = ZugZug_UI_DegToRad(angle)

    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    ZugZug.UI.minimapButton:ClearAllPoints()
    ZugZug.UI.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ZugZug_UI_CreateMinimapButton()
    if ZugZug.UI.minimapButton then return end

    local button = CreateFrame("Button", "ZugZugMinimapButton", Minimap)
    button:SetWidth(24)
    button:SetHeight(24)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:EnableMouse(true)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture("Interface\\AddOns\\ZugZug\\Textures\\ZugZug")
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(52)
    border:SetHeight(52)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("CENTER", button, "CENTER", 11, -11)
    button.border = border

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            ZugZug_UI_Toggle()
        elseif arg1 == "RightButton" then
            ZugZug_UI_Show()
            ZugZug_UI_ShowTab("settings")
        end
    end)

    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff00ff00Zug Zug|r |cffffffffv" .. ZugZug.VERSION .. "|r")
        GameTooltip:AddLine("Left click: Toggle UI", 1, 1, 1)
        GameTooltip:AddLine("Right click: Settings", 1, 1, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        this:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()

            px = px / scale
            py = py / scale

            local rad = ZugZug_UI_Atan2(py - my, px - mx)
            local deg = ZugZug_UI_RadToDeg(rad)

            if deg < 0 then
                deg = deg + 360
            end

            ZugZug.minimapAngle = deg
            ZugZug_UI_UpdateMinimapButtonPosition()
        end)
    end)

    button:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
        this:UnlockHighlight()
    end)

    ZugZug.UI.minimapButton = button
    ZugZug_UI_UpdateMinimapButtonPosition()
end

function ZugZug_UI_RegisterDefaultTabs()
    if ZugZug.UI.defaultTabsRegistered then return end

    ZugZug_UI_RegisterTab("dashboard", "Dashboard", ZugZug_UI_BuildDashboard)
    ZugZug_UI_RegisterTab("guild", "Roster", ZugZug_UI_BuildGuild)
    ZugZug_UI_RegisterTab("lfg", "LFG", ZugZug_UI_BuildLFG)
    ZugZug_UI_RegisterTab("auction", "AH Search", ZugZug_UI_BuildAuctionHouse)

    if ZugZug_isOfficerOrGM(UnitName("player")) then 
        ZugZug_UI_RegisterTab("officer", "Officer", ZugZug_UI_BuildOfficer)
    end

    ZugZug_UI_RegisterTab("settings", "Settings", ZugZug_UI_BuildSettings)

    ZugZug.UI.defaultTabsRegistered = true
end
