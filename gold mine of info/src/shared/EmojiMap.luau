-- Emoji mapping for Animal Crossing items
-- Maps item categories and types to appropriate emoji placeholders
local EmojiMap = {}

-- Category-based emojis
EmojiMap.Categories = {
    furniture = "🪑",
    clothing = "👕",
    tools = "🔨",
    interior = "🏠",
    fish = "🐟",
    bugs = "🐛",
    sea_creatures = "🦑",
    fossils = "🦴",
    art = "🖼️",
    items = "📦",
    recipes = "📋",
    photos = "📷",
    gyroids = "🎵",
}

-- Specific item type emojis (more detailed)
EmojiMap.Types = {
    -- Furniture
    ["chair"] = "🪑",
    ["table"] = "🪑",
    ["bed"] = "🛏️",
    ["sofa"] = "🛋️",
    ["desk"] = "🪑",
    ["dresser"] = "🗄️",
    ["wardrobe"] = "🚪",
    ["lamp"] = "💡",
    ["rug"] = "🟫",
    ["plant"] = "🪴",
    ["tree"] = "🌳",
    ["flower"] = "🌸",

    -- Clothing
    ["shirt"] = "👕",
    ["dress"] = "👗",
    ["hat"] = "🎩",
    ["pants"] = "👖",
    ["shoes"] = "👟",
    ["socks"] = "🧦",
    ["bag"] = "👜",
    ["accessory"] = "💍",
    ["umbrella"] = "☂️",

    -- Tools
    ["axe"] = "🪓",
    ["shovel"] = "⛏️",
    ["fishing rod"] = "🎣",
    ["net"] = "🥅",
    ["slingshot"] = "🏹",
    ["watering can"] = "🚿",
    ["ladder"] = "🪜",
    ["vaulting pole"] = "🦯",

    -- Fish
    ["sea bass"] = "🐟",
    ["tuna"] = "🐟",
    ["salmon"] = "🐟",
    ["goldfish"] = "🐠",
    ["shark"] = "🦈",
    ["octopus"] = "🐙",

    -- Bugs
    ["butterfly"] = "🦋",
    ["bee"] = "🐝",
    ["beetle"] = "🪲",
    ["dragonfly"] = "🪰",
    ["spider"] = "🕷️",
    ["scorpion"] = "🦂",
    ["tarantula"] = "🕷️",

    -- Sea Creatures
    ["crab"] = "🦀",
    ["lobster"] = "🦞",
    ["sea urchin"] = "🦔",
    ["starfish"] = "⭐",

    -- Materials
    ["wood"] = "🪵",
    ["stone"] = "🪨",
    ["iron"] = "⚙️",
    ["clay"] = "🧱",
    ["gold"] = "⭐",
    ["star fragment"] = "⭐",
    ["fruit"] = "🍎",
    ["apple"] = "🍎",
    ["orange"] = "🍊",
    ["pear"] = "🍐",
    ["peach"] = "🍑",
    ["cherry"] = "🍒",
    ["coconut"] = "🥥",

    -- Fossils
    ["skull"] = "💀",
    ["bone"] = "🦴",
    ["fossil"] = "🦴",

    -- Art
    ["painting"] = "🖼️",
    ["statue"] = "🗿",

    -- Interior
    ["wallpaper"] = "🧱",
    ["flooring"] = "🟫",

    -- DIY/Crafting
    ["recipe"] = "📋",
    ["diy"] = "🔨",

    -- Photos
    ["photo"] = "📷",
    ["poster"] = "🖼️",

    -- Gyroids
    ["gyroid"] = "🎵",
}

-- Get emoji for an item
function EmojiMap:GetEmoji(itemName, category, itemType)
    -- Try specific item name first (lowercase)
    if itemName then
        local lowerName = string.lower(itemName)
        for typeName, emoji in pairs(self.Types) do
            if string.find(lowerName, string.lower(typeName)) then
                return emoji
            end
        end
    end

    -- Try item type
    if itemType then
        local typeEmoji = self.Types[string.lower(itemType)]
        if typeEmoji then
            return typeEmoji
        end
    end

    -- Fall back to category
    if category then
        local categoryEmoji = self.Categories[string.lower(category)]
        if categoryEmoji then
            return categoryEmoji
        end
    end

    -- Default emoji
    return "📦"
end

-- Get emoji by category
function EmojiMap:GetCategoryEmoji(category)
    return self.Categories[string.lower(category)] or "📦"
end

-- Check if item is a tool
function EmojiMap:IsTool(itemName)
    if not itemName then
        return false
    end
    local lowerName = string.lower(itemName)
    local tools = { "axe", "shovel", "fishing rod", "net", "slingshot", "watering can", "ladder", "pole" }
    for _, tool in ipairs(tools) do
        if string.find(lowerName, tool) then
            return true
        end
    end
    return false
end

-- Check if item is craftable
function EmojiMap:IsCraftable(itemType)
    return itemType == "DIY" or itemType == "recipe"
end

return EmojiMap
