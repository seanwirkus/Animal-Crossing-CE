--[[
    FishData.luau
    Fish types, rarities, and values for fishing system
    
    TODO: PHASE 1 - DAY 2 PRIORITY
    - Define 20+ fish types
    - Set rarity levels (common, uncommon, rare, ultra-rare)
    - Set bell values
    - Add time/location restrictions
    - Add sprite indices for fish
    
    USED BY: FishingSystem.luau, FishingController.luau
]]

local FishData = {}

-- TODO: Define rarity system
FishData.Rarity = {
    COMMON = {chance = 0.50, multiplier = 1.0},
    UNCOMMON = {chance = 0.30, multiplier = 1.5},
    RARE = {chance = 0.15, multiplier = 2.5},
    ULTRA_RARE = {chance = 0.05, multiplier = 5.0}
}

-- TODO: Define all fish types
FishData.Fish = {
    --[[
    bass = {
        name = "Bass",
        rarity = "COMMON",
        value = 400,
        spriteIndex = 0,  -- TODO: Find correct sprite index
        description = "A common freshwater fish",
        timeAvailable = "all",  -- all, day, night
        monthsAvailable = {1,2,3,4,5,6,7,8,9,10,11,12},  -- all year
        location = "river"  -- river, ocean, pond
    },
    carp = {
        name = "Carp",
        rarity = "COMMON",
        value = 300,
        spriteIndex = 0,
        description = "A peaceful pond fish",
        timeAvailable = "all",
        monthsAvailable = {1,2,3,4,5,6,7,8,9,10,11,12},
        location = "pond"
    },
    -- TODO: Add 18+ more fish types
    ]]
}

-- TODO: Add starter fish data (placeholder)
FishData.Fish.placeholder_fish = {
    name = "Mystery Fish",
    rarity = "COMMON",
    value = 100,
    spriteIndex = 69,  -- Using loach sprite as placeholder
    description = "TODO: Define real fish data",
    timeAvailable = "all",
    monthsAvailable = {1,2,3,4,5,6,7,8,9,10,11,12},
    location = "any"
}

-- TODO: Function to get fish by rarity roll
function FishData.getRandomFish(location: string?, currentTime: string?): string
    -- Roll rarity based on chances
    -- Filter by location and time
    -- Return random fish ID
    warn("[FishData] getRandomFish() NOT IMPLEMENTED")
    return "placeholder_fish"
end

-- TODO: Function to get fish info
function FishData.getFishInfo(fishId: string): table?
    return FishData.Fish[fishId]
end

return FishData
