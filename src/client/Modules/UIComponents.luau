--[[
	UIComponents.luau
	
	Standardized UI component library for Animal Crossing CE.
	Provides reusable button/tooltip components with keybind display.
	
	Styling:
	- Background: #F7F8E6 (light beige)
	- Text: #8A7B66 (brown)
	- CornerRadius: 0.3
	- Selected/hovered: BG Teal #04AFA6, Text #FFFFF7
]]

local TweenService = game:GetService("TweenService")

local UIComponents = {}

-- Color constants
local COLORS = {
    background = Color3.fromRGB(0xF7, 0xF8, 0xE6), -- Light beige
    text = Color3.fromRGB(0x8A, 0x7B, 0x66), -- Brown
    selectedBg = Color3.fromRGB(0x04, 0xAF, 0xA6), -- Teal
    selectedText = Color3.fromRGB(0xFF, 0xFF, 0xF7), -- Off-white
    keyIconBg = Color3.fromRGB(0xE7, 0xDD, 0xB9), -- Light tan for key icons
    keyIconText = Color3.fromRGB(0x8A, 0x7B, 0x66), -- Brown text for key icons
    statusActive = Color3.fromRGB(0x04, 0xAF, 0xA6),
    statusInactive = Color3.fromRGB(0xB9, 0xA5, 0x87),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeybindSymbols = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KeybindSymbols"))

--[[
	Creates a standardized keybind button component
	@param parent Instance - Parent GUI element
	@param keybindName string - Keybind name (e.g., "INVENTORY")
	@param text string - Button text label
	@param callback function - Click callback
	@param keybinds table - Optional keybinds table (defaults to KeybindManager.KEYBINDS)
	@return Frame - The button frame
]]
function UIComponents.createKeybindButton(parent, keybindName, text, callback, keybinds)
    if not keybinds then
        local KeybindManager = require(script.Parent.Parent.KeybindManager)
        keybinds = KeybindManager.KEYBINDS
        -- Also check debug keybinds
        for k, v in pairs(KeybindManager.DEBUG_KEYBINDS) do
            if not keybinds[k] then
                keybinds[k] = v
            end
        end
    end

    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "KeybindButton"
    buttonFrame.Size = UDim2.new(1, 0, 0, 44)
    buttonFrame.BackgroundColor3 = COLORS.background
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = buttonFrame

    -- Key symbol icon (square)
    local keyIcon = Instance.new("Frame")
    keyIcon.Name = "KeyIcon"
    keyIcon.Size = UDim2.new(0, 36, 0, 36)
    keyIcon.Position = UDim2.new(0, 8, 0, 4)
    keyIcon.BackgroundColor3 = COLORS.keyIconBg
    keyIcon.BorderSizePixel = 0
    keyIcon.Parent = buttonFrame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 3)
    iconCorner.Parent = keyIcon

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 16
    iconLabel.TextColor3 = COLORS.keyIconText
    iconLabel.Text = KeybindSymbols.getSymbolForBind(keybindName, keybinds)
    iconLabel.Parent = keyIcon

    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.Size = UDim2.new(1, -52, 1, 0)
    textLabel.Position = UDim2.new(0, 48, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamSemibold
    textLabel.TextSize = 18
    textLabel.TextColor3 = COLORS.text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Text = text
    textLabel.Parent = buttonFrame

    -- Click detection (invisible button overlay)
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = buttonFrame

    local isSelected = false

    local function updateState(selected)
        isSelected = selected
        if selected then
            buttonFrame.BackgroundColor3 = COLORS.selectedBg
            textLabel.TextColor3 = COLORS.selectedText
            keyIcon.BackgroundColor3 = COLORS.selectedBg
            iconLabel.TextColor3 = COLORS.selectedText
        else
            buttonFrame.BackgroundColor3 = COLORS.background
            textLabel.TextColor3 = COLORS.text
            keyIcon.BackgroundColor3 = COLORS.keyIconBg
            iconLabel.TextColor3 = COLORS.keyIconText
        end
    end

    clickButton.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    clickButton.MouseEnter:Connect(function()
        if not isSelected then
            TweenService:Create(buttonFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(0xE8, 0xE9, 0xD6),
            }):Play()
        end
    end)

    clickButton.MouseLeave:Connect(function()
        if not isSelected then
            TweenService:Create(buttonFrame, TweenInfo.new(0.2), {
                BackgroundColor3 = COLORS.background,
            }):Play()
        end
    end)

    -- Expose selection function
    buttonFrame.setSelected = function(selected)
        updateState(selected)
    end

    buttonFrame.isSelected = function()
        return isSelected
    end

    return buttonFrame
end

--[[
	Creates a keybind tooltip component
	@param parent Instance - Parent GUI element
	@param keybindName string - Keybind name
	@param text string - Tooltip text
	@param keybinds table - Optional keybinds table
	@return Frame - The tooltip frame
]]
function UIComponents.createKeybindTooltip(parent, keybindName, text, keybinds, options)
    if not keybinds then
        local KeybindManager = require(script.Parent.Parent.KeybindManager)
        keybinds = KeybindManager.KEYBINDS
        -- Also check debug keybinds
        for k, v in pairs(KeybindManager.DEBUG_KEYBINDS) do
            if not keybinds[k] then
                keybinds[k] = v
            end
        end
    end

    options = options or {}
    local fillWidth = if options.fillWidth == nil then true else options.fillWidth
    local rowHeight = options.height or 52
    local cornerRadius = options.cornerRadius or 8
    local padding = options.padding or 10
    local statusWidth = options.statusWidth or 140
    local backgroundTransparency = options.backgroundTransparency or 0
    local iconSize = math.max(options.iconSize or (rowHeight - 16), 28)
    local statusText = options.statusText
    local statusColor = options.statusColor or (statusText and COLORS.statusInactive or COLORS.text)
    local keybindsTable = options.overrideKeybinds or keybinds

    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "KeybindTooltip"
    if fillWidth then
        tooltipFrame.Size = UDim2.new(1, options.widthOffset or 0, 0, rowHeight)
    else
        tooltipFrame.Size = UDim2.new(0, 0, 0, 0)
    end
    tooltipFrame.BackgroundColor3 = COLORS.background
    tooltipFrame.BackgroundTransparency = backgroundTransparency
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.AutomaticSize = if fillWidth then Enum.AutomaticSize.None else Enum.AutomaticSize.Y
    tooltipFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius)
    corner.Parent = tooltipFrame

    local paddingInstance = Instance.new("UIPadding")
    paddingInstance.PaddingLeft = UDim.new(0, padding)
    paddingInstance.PaddingRight = UDim.new(0, padding)
    paddingInstance.PaddingTop = UDim.new(0, math.max(6, math.floor((rowHeight - iconSize) / 2)))
    paddingInstance.PaddingBottom = UDim.new(0, math.max(6, math.floor((rowHeight - iconSize) / 2)))
    paddingInstance.Parent = tooltipFrame

    -- Key icon
    local keyIcon = Instance.new("Frame")
    keyIcon.Name = "KeyIcon"
    keyIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    keyIcon.Position = UDim2.new(0, 0, 0, 0)
    keyIcon.BackgroundColor3 = COLORS.keyIconBg
    keyIcon.BorderSizePixel = 0
    keyIcon.Parent = tooltipFrame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, math.max(4, cornerRadius - 1))
    iconCorner.Parent = keyIcon

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = math.clamp(iconSize - 10, 12, 20)
    iconLabel.TextColor3 = COLORS.keyIconText
    iconLabel.Text = KeybindSymbols.getSymbolForBind(keybindName, keybindsTable)
    iconLabel.Parent = keyIcon

    -- Text label
    local textLabel = Instance.new("TextLabel")
    local textOffset = iconSize + padding * 2
    textLabel.Size = UDim2.new(1, -(textOffset + (statusText and statusWidth or 0)), 1, 0)
    textLabel.Position = UDim2.new(0, textOffset, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = options.textSize or 14
    textLabel.TextColor3 = COLORS.text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    textLabel.Text = text
    textLabel.Parent = tooltipFrame

    if not fillWidth then
        textLabel.Size = UDim2.new(0, 0, 0, 0)
        textLabel.Position = UDim2.new(0, 40, 0, 8)
        textLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
            textLabel.Size = UDim2.new(0, textLabel.TextBounds.X, 0, textLabel.TextBounds.Y)
            tooltipFrame.Size = UDim2.new(0, textLabel.TextBounds.X + 48, 0, math.max(40, textLabel.TextBounds.Y + 16))
        end)
    end

    if statusText then
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.AnchorPoint = Vector2.new(1, 0.5)
        statusLabel.Position = UDim2.new(1, -padding, 0.5, 0)
        statusLabel.Size = UDim2.new(0, statusWidth - padding, 0, math.max(16, iconSize - 6))
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamSemibold
        statusLabel.TextSize = 12
        statusLabel.TextColor3 = statusColor
        statusLabel.TextXAlignment = Enum.TextXAlignment.Right
        statusLabel.Text = statusText
        statusLabel.Parent = tooltipFrame
    end

    return tooltipFrame
end

return UIComponents
