--[[
	Theme.lua

	Centralized Animal Crossing-inspired design system.
	Provides typed tokens, reusable component styles, and helpers to keep
	every GUI aligned with the AC aesthetic.
]]

export type ShadowConfig = {
    Color: Color3,
    Transparency: number,
    Offset: Vector2,
    Blur: number,
}

export type StatePalette = {
    default: Color3,
    hover: Color3?,
    pressed: Color3?,
    textDefault: Color3?,
    textHover: Color3?,
    textPressed: Color3?,
}

export type ComponentStyle = {
    className: string?,
    size: UDim2?,
    anchorPoint: Vector2?,
    position: UDim2?,
    backgroundColor: Color3?,
    backgroundTransparency: number?,
    textColor: Color3?,
    font: Enum.Font?,
    textSize: number?,
    text: string?,
    autoButtonColor: boolean?,
    borderColor: Color3?,
    borderWidth: number?,
    radius: string?,
    shadow: string?,
    padding: string?,
    stateColors: StatePalette?,
}

local Theme: { [string]: any } = {}

-- =============================================================================
-- TOKEN DEFINITIONS
-- =============================================================================

local colors = {
    offWhite = Color3.fromRGB(252, 250, 242),
    eggshell = Color3.fromRGB(240, 237, 228),
    cream = Color3.fromRGB(255, 251, 231),
    warmYellow = Color3.fromRGB(250, 209, 43),
    bellGold = Color3.fromRGB(253, 147, 3),
    leafGreen = Color3.fromRGB(156, 204, 101),
    skyBlue = Color3.fromRGB(129, 212, 250),
    buttonBrown = Color3.fromRGB(133, 90, 37),
    darkBrown = Color3.fromRGB(76, 60, 51),
    lightBrown = Color3.fromRGB(209, 198, 153),
    notificationRed = Color3.fromRGB(244, 67, 54),
    teal = Color3.fromRGB(4, 175, 166),
    tealAccent = Color3.fromRGB(130, 213, 187),
    goldAccent = Color3.fromRGB(190, 167, 69),
    inventorySlot = Color3.fromRGB(238, 226, 204),
    inventorySlotHover = Color3.fromRGB(130, 213, 187),
    inventorySlotEmpty = Color3.fromRGB(248, 240, 220),
    textPrimary = Color3.fromRGB(133, 90, 37),
    textSecondary = Color3.fromRGB(120, 100, 80),
    textLight = Color3.fromRGB(255, 255, 255),
}

local radius = {
    small = UDim.new(0, 8),
    medium = UDim.new(0, 16),
    large = UDim.new(0, 24),
    xlarge = UDim.new(0, 32),
    xxlarge = UDim.new(0, 36),
}

local shadows: { [string]: ShadowConfig } = {
    small = {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.3,
        Offset = Vector2.new(0, 2),
        Blur = 4,
    },
    medium = {
        Color = Color3.fromRGB(62, 39, 35),
        Transparency = 0.25,
        Offset = Vector2.new(0, 4),
        Blur = 8,
    },
    large = {
        Color = Color3.fromRGB(62, 39, 35),
        Transparency = 0.2,
        Offset = Vector2.new(0, 6),
        Blur = 12,
    },
}

local fonts = {
    primary = Enum.Font.Gotham,
    secondary = Enum.Font.GothamMedium,
    bold = Enum.Font.GothamBold,
    black = Enum.Font.GothamBlack,
}

local textSizes = {
    xsmall = 12,
    small = 14,
    medium = 16,
    large = 18,
    xlarge = 20,
    xxlarge = 24,
    xxxlarge = 32,
}

local spacing = {
    xs = 4,
    sm = 8,
    md = 12,
    lg = 16,
    xl = 24,
    xxl = 32,
}

Theme.tokens = {
    colors = colors,
    radius = radius,
    shadows = shadows,
    fonts = fonts,
    textSizes = textSizes,
    spacing = spacing,
}

Theme.colors = colors
Theme.radius = radius
Theme.shadows = shadows
Theme.fonts = fonts
Theme.textSizes = textSizes
Theme.spacing = spacing

-- =============================================================================
-- COMPONENT PRESETS
-- =============================================================================

local components: { [string]: ComponentStyle } = {
    dialogPanel = {
        className = "Frame",
        size = UDim2.fromScale(0.8, 0.6),
        anchorPoint = Vector2.new(0.5, 0.5),
        position = UDim2.fromScale(0.5, 0.5),
        backgroundColor = colors.offWhite,
        backgroundTransparency = 0.05,
        borderColor = colors.bellGold,
        borderWidth = 3,
        radius = "large",
        shadow = "large",
        padding = "lg",
    },
    primaryButton = {
        className = "TextButton",
        size = UDim2.new(0, 200, 0, 48),
        backgroundColor = colors.buttonBrown,
        textColor = colors.textLight,
        font = fonts.bold,
        textSize = textSizes.medium,
        autoButtonColor = false,
        radius = "medium",
        stateColors = {
            default = colors.buttonBrown,
            hover = colors.lightBrown,
            pressed = Color3.fromRGB(93, 64, 55),
            textDefault = colors.textLight,
            textHover = colors.textLight,
            textPressed = colors.textLight,
        },
    },
    secondaryButton = {
        className = "TextButton",
        size = UDim2.new(0, 200, 0, 48),
        backgroundColor = colors.eggshell,
        textColor = colors.buttonBrown,
        borderColor = colors.buttonBrown,
        borderWidth = 2,
        font = fonts.primary,
        textSize = textSizes.medium,
        autoButtonColor = false,
        radius = "medium",
        stateColors = {
            default = colors.eggshell,
            hover = colors.cream,
            pressed = colors.warmYellow,
            textDefault = colors.buttonBrown,
            textHover = colors.buttonBrown,
            textPressed = colors.darkBrown,
        },
    },
    closeButton = {
        className = "TextButton",
        size = UDim2.new(0, 32, 0, 32),
        anchorPoint = Vector2.new(1, 0),
        position = UDim2.new(1, -40, 0, 10),
        backgroundColor = colors.notificationRed,
        textColor = colors.textLight,
        font = fonts.bold,
        textSize = textSizes.medium,
        text = "✕",
        autoButtonColor = false,
        radius = "small",
        stateColors = {
            default = colors.notificationRed,
            hover = Color3.fromRGB(211, 47, 47),
            pressed = Color3.fromRGB(183, 28, 28),
        },
    },
    toastCard = {
        className = "Frame",
        size = UDim2.new(0, 320, 0, 80),
        backgroundColor = colors.eggshell,
        borderColor = colors.lightBrown,
        borderWidth = 2,
        radius = "medium",
        shadow = "medium",
        padding = "md",
    },
    hudPanel = {
        className = "Frame",
        size = UDim2.new(0, 300, 0, 80),
        backgroundColor = colors.eggshell,
        borderColor = colors.lightBrown,
        borderWidth = 2,
        radius = "medium",
        shadow = "small",
        padding = "sm",
    },
}

Theme.components = components

-- =============================================================================
-- INTERNAL HELPERS
-- =============================================================================

local function ensureUICorner(instance: GuiObject, radiusKey: string | UDim)
    local key: UDim
    
    -- Handle both string keys and direct UDim values
    if typeof(radiusKey) == "UDim" then
        key = radiusKey
    elseif typeof(radiusKey) == "string" then
        key = radius[radiusKey]
        if not key then
            warn(string.format("[Theme] Unknown radius '%s'", radiusKey))
            return
        end
    else
        warn(string.format("[Theme] Invalid radius type: %s (expected string or UDim)", typeof(radiusKey)))
        return
    end

    local corner = instance:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = Instance.new("UICorner")
        corner.Name = "ThemeCorner"
        corner.Parent = instance
    end
    corner.CornerRadius = key
end

local function ensureUIStroke(instance: GuiObject, color: Color3?, thickness: number?)
    if not color then
        return
    end
    local stroke = instance:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Name = "ThemeStroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = instance
    end
    stroke.Color = color
    stroke.Thickness = thickness or 2
    return stroke
end

local function ensurePadding(instance: GuiObject, spacingKey: string)
    local padValue = spacing[spacingKey]
    if not padValue then
        warn(string.format("[Theme] Unknown padding '%s'", spacingKey))
        return
    end

    local paddingInstance = instance:FindFirstChildOfClass("UIPadding")
    if not paddingInstance then
        paddingInstance = Instance.new("UIPadding")
        paddingInstance.Name = "ThemePadding"
        paddingInstance.Parent = instance
    end
    paddingInstance.PaddingTop = UDim.new(0, padValue)
    paddingInstance.PaddingBottom = UDim.new(0, padValue)
    paddingInstance.PaddingLeft = UDim.new(0, padValue)
    paddingInstance.PaddingRight = UDim.new(0, padValue)
end

local function attachButtonStates(button: GuiButton, palette: StatePalette)
    if button:GetAttribute("ThemeHasMouseHooks") then
        return
    end

    button:SetAttribute("ThemeHasMouseHooks", true)
    local defaultColor = palette.default
    local hoverColor = palette.hover or defaultColor
    local pressedColor = palette.pressed or hoverColor
    local textDefault = palette.textDefault
    local textHover = palette.textHover or textDefault
    local textPressed = palette.textPressed or textHover

    local function setState(state: string)
        if state == "default" then
            button.BackgroundColor3 = defaultColor
            if textDefault then
                button.TextColor3 = textDefault
            end
        elseif state == "hover" then
            button.BackgroundColor3 = hoverColor
            if textHover then
                button.TextColor3 = textHover
            end
        elseif state == "pressed" then
            button.BackgroundColor3 = pressedColor
            if textPressed then
                button.TextColor3 = textPressed
            end
        end
    end

    button.MouseEnter:Connect(function()
        setState("hover")
    end)
    button.MouseLeave:Connect(function()
        setState("default")
    end)
    button.MouseButton1Down:Connect(function()
        setState("pressed")
    end)
    button.MouseButton1Up:Connect(function()
        setState("hover")
    end)

    setState("default")
end

-- =============================================================================
-- PUBLIC HELPERS
-- =============================================================================

function Theme.applyShadow(instance: GuiObject, shadowKey: string)
    local config = shadows[shadowKey]
    if not config then
        warn(string.format("[Theme] Unknown shadow '%s'", shadowKey))
        return
    end

    local shadow = instance:FindFirstChild("ThemeShadow")
    if not shadow then
        shadow = Instance.new("Frame")
        shadow.Name = "ThemeShadow"
        shadow.ZIndex = math.max(0, instance.ZIndex - 1)
        shadow.Parent = instance
    end

    shadow.Size = UDim2.new(1, config.Blur * 2, 1, config.Blur * 2)
    shadow.Position = UDim2.new(0.5, config.Offset.X, 0.5, config.Offset.Y)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundColor3 = config.Color
    shadow.BackgroundTransparency = config.Transparency
    shadow.BorderSizePixel = 0
    ensureUICorner(shadow, "large")
end

function Theme.applyStroke(instance: GuiObject, color: Color3, thickness: number?)
    return ensureUIStroke(instance, color, thickness)
end

function Theme.applyCornerRadius(instance: GuiObject, radiusKey: string | UDim)
    ensureUICorner(instance, radiusKey)
end

function Theme.applyPadding(instance: GuiObject, paddingKey: string)
    ensurePadding(instance, paddingKey)
end

function Theme.applyTextStyle(label: TextLabel | TextButton, variant: string)
    local size = textSizes[variant]
    if not size then
        warn(string.format("[Theme] Unknown text variant '%s'", variant))
        return
    end
    label.Font = fonts.primary
    label.TextSize = size
    label.TextColor3 = colors.textPrimary
end

function Theme.applyComponent(instance: GuiObject, componentKey: string)
    local style = components[componentKey]
    if not style then
        warn(string.format("[Theme] Unknown component '%s'", componentKey))
        return instance
    end

    if style.size then
        instance.Size = style.size
    end
    if style.anchorPoint then
        instance.AnchorPoint = style.anchorPoint
    end
    if style.position then
        instance.Position = style.position
    end
    if style.backgroundColor then
        instance.BackgroundColor3 = style.backgroundColor
    end
    if style.backgroundTransparency ~= nil then
        instance.BackgroundTransparency = style.backgroundTransparency
    end

    local isTextObject = instance:IsA("TextLabel") or instance:IsA("TextButton")
    if isTextObject and style.textColor then
        (instance :: TextLabel).TextColor3 = style.textColor
    end
    if isTextObject and style.font then
        (instance :: TextLabel).Font = style.font
    end
    if isTextObject and style.textSize then
        (instance :: TextLabel).TextSize = style.textSize
    end
    if isTextObject and style.text then
        (instance :: TextLabel).Text = style.text
    end
    if instance:IsA("TextButton") and style.autoButtonColor ~= nil then
        instance.AutoButtonColor = style.autoButtonColor
    end

    if style.borderColor or style.borderWidth then
        ensureUIStroke(instance, style.borderColor or colors.darkBrown, style.borderWidth or 2)
    end
    if style.radius then
        ensureUICorner(instance, style.radius)
    end
    if style.shadow then
        Theme.applyShadow(instance, style.shadow)
    end
    if style.padding then
        ensurePadding(instance, style.padding)
    end
    if style.stateColors and instance:IsA("GuiButton") then
        attachButtonStates(instance, style.stateColors)
    end

    return instance
end

function Theme.createComponent(componentKey: string, parent: Instance?): GuiObject?
    local style = components[componentKey]
    if not style then
        warn(string.format("[Theme] Cannot create unknown component '%s'", componentKey))
        return nil
    end

    local instance = Instance.new(style.className or "Frame") :: GuiObject
    Theme.applyComponent(instance, componentKey)
    if parent then
        instance.Parent = parent
    end
    return instance
end

function Theme.createDialogPanel(parent: Instance): Frame
    local panel = Theme.createComponent("dialogPanel", parent)
    return panel :: Frame
end

function Theme.createPrimaryButton(parent: Instance, text: string): TextButton
    local button = Theme.createComponent("primaryButton", parent)
    if button then
        (button :: TextButton).Text = text
    end
    return button :: TextButton
end

function Theme.createSecondaryButton(parent: Instance, text: string): TextButton
    local button = Theme.createComponent("secondaryButton", parent)
    if button then
        (button :: TextButton).Text = text
    end
    return button :: TextButton
end

function Theme.createCloseButton(parent: Instance): TextButton
    local button = Theme.createComponent("closeButton", parent)
    return button :: TextButton
end

function Theme.createToast(parent: Instance, copy: string): Frame
    local toast = Theme.createComponent("toastCard", parent)
    if toast then
        local label = Instance.new("TextLabel")
        label.Name = "ToastText"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = colors.textPrimary
        label.TextWrapped = true
        label.Font = fonts.secondary
        label.TextSize = textSizes.medium
        label.Text = copy
        label.Parent = toast
    end
    return toast :: Frame
end

return Theme
