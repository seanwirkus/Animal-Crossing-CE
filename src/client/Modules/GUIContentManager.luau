--[[
	GUIContentManager.luau

	CENTRALIZED GUI CONTENT MANAGEMENT SYSTEM
	=======================================

	Single source of truth for ALL GUI content, styling, and configuration.
	Edit text, colors, sizes, assets, and layouts from this one file.

	This replaces scattered hardcoded strings and configurations across
	all GUI modules for easier maintenance and consistency.

	USAGE:
		local GUIContent = require(path.to.GUIContentManager)
		local loadingTips = GUIContent.getLoadingTips()
		local buttonStyle = GUIContent.getButtonStyle("primary")
]]

local ThemeProvider = require(script.Parent.ThemeProvider)

local GUIContentManager = {}

-- =============================================================================
-- LOADING SCREEN CONTENT
-- =============================================================================

GUIContentManager.LoadingScreen = {
    -- Loading tips shown during game startup
    tips = {
        "Did you know? You can shake trees to find furniture!",
        "Tip: Talk to villagers every day to build friendship.",
        "Catching bugs is easier when you walk slowly!",
        "Pro tip: Fish shadows show their size. Bigger shadow = bigger fish!",
        "Don't forget to check Nook's Cranny for new items daily!",
        "Balloons often carry furniture and DIY recipes!",
        "Tip: Plant fruit trees to grow bells!",
        "Did you know? Different fish appear at different times.",
        "Fossils can be found by digging X-marks on the ground!",
        "Tip: Donate bugs and fish to Blathers for the museum!",
        "Pro tip: Save your game regularly at the tent!",
        "Did you know? You can customize some furniture items!",
        "Tip: Nook Miles can be earned by completing daily tasks!",
        "Press E to open your inventory!",
        "Tip: Golden tools are more durable than regular ones!",
        "Did you know? You can catch snowflakes in winter!",
        "Pro tip: Plant flowers to attract rare bugs!",
        "Tip: Check the beach for message bottles with DIY recipes!",
        "Did you know? Turnip prices change twice daily!",
        "Tip: Visit other players' islands for new items!",
    },

    -- Assets to preload during loading
    preloadAssets = {
        "rbxassetid://79857338226248", -- Main sprite sheet
        "rbxassetid://98139431900134", -- Additional assets
    },

    -- Button configurations with ACNH styling
    buttons = {
        start = {
            text = "Begin Your Adventure",
            size = UDim2.new(0, 280, 0, 65),
            position = UDim2.new(0.5, 0, 0.85, 0),
            anchorPoint = Vector2.new(0.5, 0.5),
            font = "bold",
            textSize = "xlarge",
            backgroundColor = Color3.fromRGB(4, 175, 166), -- ACNH teal
            textColor = Color3.fromRGB(255, 251, 231), -- ACNH cream
            cornerRadius = 12,
            strokeColor = Color3.fromRGB(255, 255, 255),
            strokeThickness = 2,
        },
        settings = {
            text = "Settings",
            size = UDim2.new(0, 150, 0, 40),
            font = "primary",
            textSize = "medium",
            backgroundColor = Color3.fromRGB(255, 251, 231), -- ACNH cream
            textColor = Color3.fromRGB(120, 100, 80), -- ACNH brown
            cornerRadius = 8,
            strokeColor = Color3.fromRGB(146, 128, 98),
            strokeThickness = 1,
        },
        continue = {
            text = "Continue",
            size = UDim2.new(0, 150, 0, 40),
            font = "primary",
            textSize = "medium",
            backgroundColor = Color3.fromRGB(4, 175, 166), -- ACNH teal
            textColor = Color3.fromRGB(255, 255, 255),
            cornerRadius = 8,
            strokeColor = Color3.fromRGB(255, 255, 255),
            strokeThickness = 1,
        },
    },

    -- Status messages
    statusMessages = {
        loading = "Loading your island paradise...",
        preloading = "Preloading assets...",
        ready = "Ready to start!",
        initializing = "Initializing game systems...",
    },

    -- Overall styling
    styling = {
        backgroundColor = Color3.fromRGB(255, 251, 231), -- ACNH cream background
        overlayColor = Color3.fromRGB(28, 48, 66), -- Dark overlay
        overlayTransparency = 0.3,
        titleColor = Color3.fromRGB(120, 100, 80), -- ACNH brown
        subtitleColor = Color3.fromRGB(4, 175, 166), -- ACNH teal
        tipColor = Color3.fromRGB(96, 75, 54), -- Dark brown for tips
        progressBarColor = Color3.fromRGB(4, 175, 166), -- ACNH teal
        progressBackgroundColor = Color3.fromRGB(200, 200, 200),
        cornerRadius = 12,
        font = Enum.Font.Gotham,
        boldFont = Enum.Font.GothamBold,
    },
}

-- =============================================================================
-- INVENTORY GUI CONTENT
-- =============================================================================

GUIContentManager.Inventory = {
    -- Window title
    title = "Inventory",

    -- Slot configuration
    slots = {
        rows = 1,
        columns = 10,
        totalSlots = 10,
        slotSize = UDim2.new(0, 64, 0, 64),
        slotSpacing = UDim2.new(0, 8, 0, 8),
    },

    -- Button labels
    buttons = {},

    -- Status messages
    messages = {},

    -- Categories
    categories = {
        "All",
        "Tools",
        "Furniture",
        "Clothing",
        "Food",
        "Materials",
        "Other",
    },

    upgrades = {
        title = "Pocket Upgrades",
        summary = "Level {level} • {slots} slots",
        description = "Invest Bells with Nook Inc. to expand your carry capacity.",
        button = "Upgrade ({cost} Bells)",
        maxButton = "Pocket Maxed",
        maxDescription = "You're already carrying as much as possible!",
        successMessage = "Your pockets feel roomier already!",
        errors = {
            MAX_LEVEL = "You've already unlocked every upgrade.",
            INSUFFICIENT_FUNDS = "You need more Bells to purchase this.",
        },
        stations = {
            title = "Crafting Stations",
            unlocked = "Unlocked",
            locked = "Locked - {cost} Bells",
            unlockButton = "Unlock ({cost} Bells)",
        },
    },
}

-- =============================================================================
-- LAYOUT TOKENS (shared by Inventory/NookPhone/other GUIs)
-- =============================================================================

GUIContentManager.Layouts = {
    Inventory = {
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 0, 1, -32),
        size = UDim2.new(0, 760, 0, 380),
        cornerRadius = 24,
        padding = {
            top = 32,
            bottom = 28,
            left = 32,
            right = 32,
        },
        headerHeight = 52,
        searchHeight = 36,
        footerHeight = 28,
        slot = {
            size = UDim2.new(0, 64, 0, 64),
            padding = UDim.new(0, 10),
            maxColumns = 10,
        },
    },
    NookPhone = {
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 0, 1, -24),
        size = UDim2.new(0, 400, 0, 680),
        aspectRatio = 9 / 16,
        padding = {
            horizontal = 14,
            vertical = 16,
        },
        notchHeight = 42,
        statusRowHeight = 52,
        closeButtonOffset = Vector2.new(0, -46),
        grid = {
            columns = 4,
            iconSize = 78,
            spacing = 8,
        },
    },
}

function GUIContentManager.getLayoutConfig(layoutName: string)
    local layout = GUIContentManager.Layouts[layoutName]
    if not layout then
        warn(string.format("[GUIContentManager] ⚠️ Layout '%s' is not defined", tostring(layoutName)))
    end
    return layout
end

-- =============================================================================
-- CRAFTING GUI CONTENT
-- =============================================================================

GUIContentManager.Crafting = {
    title = "Crafting",

    -- Recipe categories
    categories = {
        "All Recipes",
        "Tools",
        "Furniture",
        "Clothing",
        "Wall/Floor",
        "Other",
    },

    -- Button labels
    buttons = {
        craft = "Craft",
        cancel = "Cancel",
        close = "X",
        search = "Search recipes...",
    },

    -- Status messages
    messages = {
        noMaterials = "Missing materials",
        crafting = "Crafting...",
        complete = "Crafting complete!",
        insufficientSpace = "Not enough inventory space",
    },

    -- Recipe display
    recipeDisplay = {
        materialsLabel = "Required Materials:",
        resultLabel = "Creates:",
        timeLabel = "Crafting Time:",
        instant = "Instant",
    },
}

-- =============================================================================
-- SHOP GUI CONTENT
-- =============================================================================

GUIContentManager.Shop = {
    title = "Nook's Cranny",

    -- Shop sections
    sections = {
        buy = "Buy",
        sell = "Sell",
        catalog = "Catalog",
    },

    -- Button labels
    buttons = {
        buy = "Buy",
        sell = "Sell",
        close = "X",
    },

    -- Messages
    messages = {
        welcome = "Welcome to Nook's Cranny!",
        noMoney = "Not enough Bells",
        soldOut = "Sold out",
        thankYou = "Thank you for your purchase!",
    },
}

-- =============================================================================
-- DIALOGUE GUI CONTENT
-- =============================================================================

GUIContentManager.Dialogue = {
    -- Default NPC dialogue
    defaultLines = {
        greeting = "Hello there!",
        farewell = "See you later!",
        busy = "I'm a bit busy right now...",
    },

    -- Special character dialogue
    characters = {
        tomNook = {
            greeting = "Welcome to my island!",
            help = "How can I help you today?",
        },
        isabelle = {
            greeting = "Good day! How are you?",
            help = "Is there anything I can assist with?",
        },
    },

    -- Button labels
    buttons = {
        next = "Next",
        close = "X",
        accept = "Accept",
        decline = "Decline",
    },
}

-- =============================================================================
-- SETTINGS GUI CONTENT
-- =============================================================================

GUIContentManager.Settings = {
    title = "Settings",

    -- Categories
    categories = {
        "Audio",
        "Graphics",
        "Controls",
        "Gameplay",
    },

    -- Audio settings
    audio = {
        masterVolume = "Master Volume",
        musicVolume = "Music Volume",
        sfxVolume = "Sound Effects",
    },

    -- Graphics settings
    graphics = {
        quality = "Graphics Quality",
        shadows = "Shadows",
        particles = "Particles",
    },

    -- Control settings
    controls = {
        keybinds = "Keybinds",
        mouseSensitivity = "Mouse Sensitivity",
        invertY = "Invert Y Axis",
    },

    -- Button labels
    buttons = {
        apply = "Apply",
        reset = "Reset to Default",
        close = "X",
    },
}

-- =============================================================================
-- NOTIFICATION SYSTEM CONTENT
-- =============================================================================

GUIContentManager.Notifications = {
    -- Notification types
    types = {
        success = {
            color = "leafGreen",
            icon = "✓",
        },
        warning = {
            color = "bellGold",
            icon = "⚠",
        },
        error = {
            color = "notificationRed",
            icon = "✕",
        },
        info = {
            color = "skyBlue",
            icon = "ℹ",
        },
    },

    -- Common messages
    messages = {
        itemReceived = "Received {item}!",
        bellsEarned = "Earned {amount} Bells!",
        levelUp = "Level up! Now level {level}",
        achievement = "Achievement unlocked: {achievement}",
    },
}

-- =============================================================================
-- TUTORIAL CONTENT
-- =============================================================================

GUIContentManager.Tutorial = {
    -- Tutorial steps
    steps = {
        {
            title = "Welcome to Animal Crossing!",
            content = "Let's get you started with the basics of island life.",
            button = "Let's Go!",
        },
        {
            title = "Your Inventory",
            content = "Press E to open your inventory. Here you can store items, tools, and furniture.",
            button = "Got it!",
        },
        {
            title = "Crafting",
            content = "Press C to open the crafting menu. Use materials to create new items!",
            button = "Understood!",
        },
        {
            title = "Exploring",
            content = "Walk around your island to discover trees, rocks, and hidden treasures.",
            button = "Ready to explore!",
        },
    },

    -- Skip tutorial option
    skip = {
        text = "Skip Tutorial",
        confirm = "Are you sure you want to skip the tutorial?",
    },
}

GUIContentManager.Emotes = {
    title = "Reactions",
    hint = "Select an emote to share how you're feeling!",
}

GUIContentManager.Map = {
    title = "🗺️ Island Map",
    hint = "Shows your island layout and player position.",
}

-- =============================================================================
-- GUI STYLE PRESETS
-- =============================================================================

GUIContentManager.Styles = {
    -- Button style presets
    buttons = {
        primary = {
            backgroundColor = "buttonBrown",
            textColor = "textLight",
            cornerRadius = "medium",
            font = "bold",
            textSize = "medium",
        },
        secondary = {
            backgroundColor = "eggshell",
            textColor = "textPrimary",
            cornerRadius = "medium",
            font = "primary",
            textSize = "medium",
            strokeColor = "lightBrown",
            strokeThickness = 1,
        },
        danger = {
            backgroundColor = "notificationRed",
            textColor = "textLight",
            cornerRadius = "medium",
            font = "bold",
            textSize = "medium",
        },
        success = {
            backgroundColor = "leafGreen",
            textColor = "textLight",
            cornerRadius = "medium",
            font = "bold",
            textSize = "medium",
        },
    },

    -- Window/container presets
    windows = {
        main = {
            backgroundColor = "offWhite",
            cornerRadius = "large",
            strokeColor = "lightBrown",
            strokeThickness = 2,
            shadow = "medium",
        },
        popup = {
            backgroundColor = "cream",
            cornerRadius = "xlarge",
            strokeColor = "buttonBrown",
            strokeThickness = 1,
            shadow = "large",
        },
        tooltip = {
            backgroundColor = "eggshell",
            cornerRadius = "small",
            strokeColor = "darkBrown",
            strokeThickness = 1,
            shadow = "small",
        },
    },

    -- Text style presets
    text = {
        title = {
            font = "black",
            textSize = "xxlarge",
            textColor = "textPrimary",
        },
        subtitle = {
            font = "bold",
            textSize = "xlarge",
            textColor = "textPrimary",
        },
        body = {
            font = "primary",
            textSize = "medium",
            textColor = "textPrimary",
        },
        caption = {
            font = "primary",
            textSize = "small",
            textColor = "textSecondary",
        },
    },
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Get loading screen tips
function GUIContentManager.getLoadingTips()
    return GUIContentManager.LoadingScreen.tips
end

-- Get a random loading tip
function GUIContentManager.getRandomLoadingTip()
    local tips = GUIContentManager.getLoadingTips()
    local random = Random.new()
    return tips[random:NextInteger(1, #tips)]
end

-- Get loading screen assets to preload
function GUIContentManager.getPreloadAssets()
    return GUIContentManager.LoadingScreen.preloadAssets
end

-- Get button style by preset name
function GUIContentManager.getButtonStyle(styleName)
    return GUIContentManager.Styles.buttons[styleName] or GUIContentManager.Styles.buttons.primary
end

-- Get window style by preset name
function GUIContentManager.getWindowStyle(styleName)
    return GUIContentManager.Styles.windows[styleName] or GUIContentManager.Styles.windows.main
end

-- Get text style by preset name
function GUIContentManager.getTextStyle(styleName)
    return GUIContentManager.Styles.text[styleName] or GUIContentManager.Styles.text.body
end

-- Get notification style by type
function GUIContentManager.getNotificationStyle(typeName)
    return GUIContentManager.Notifications.types[typeName] or GUIContentManager.Notifications.types.info
end

-- Format a message with placeholders
function GUIContentManager.formatMessage(template, replacements)
    local result = template
    for key, value in pairs(replacements) do
        result = result:gsub("{" .. key .. "}", tostring(value))
    end
    return result
end

-- Get all content for a specific GUI module
function GUIContentManager.getGUIContent(guiName)
    return GUIContentManager[guiName] or {}
end

-- Apply theme colors to a style configuration
function GUIContentManager.applyThemeToStyle(styleConfig)
    local themedConfig = {}

    for key, value in pairs(styleConfig) do
        if type(value) == "string" then
            -- Check if it's a theme reference
            if key == "backgroundColor" or key == "textColor" or key == "strokeColor" then
                themedConfig[key] = ThemeProvider.getColor(value)
            elseif key == "cornerRadius" then
                themedConfig[key] = ThemeProvider.getRadius(value)
            elseif key == "font" then
                themedConfig[key] = ThemeProvider.getFont(value)
            elseif key == "textSize" then
                themedConfig[key] = ThemeProvider.getTextSize(value)
            elseif key == "shadow" then
                -- Handle shadow references
                local shadowData = ThemeProvider.getTheme().shadows[value]
                if shadowData then
                    themedConfig[key] = shadowData
                else
                    themedConfig[key] = value
                end
            else
                themedConfig[key] = value
            end
        else
            themedConfig[key] = value
        end
    end

    return themedConfig
end

return GUIContentManager
