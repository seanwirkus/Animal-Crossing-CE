local FishData = {}

FishData.Rarity = {
    COMMON = { chance = 0.5, multiplier = 1.0 },
    UNCOMMON = { chance = 0.3, multiplier = 1.4 },
    RARE = { chance = 0.15, multiplier = 2.2 },
    ULTRA_RARE = { chance = 0.05, multiplier = 4.0 },
}

FishData.RarityRollOrder = { "COMMON", "UNCOMMON", "RARE", "ULTRA_RARE" }
FishData.RarityFallbackOrder = { "ULTRA_RARE", "RARE", "UNCOMMON", "COMMON" }

local function cloneArray(array)
    local result = {}
    if typeof(array) ~= "table" then
        return result
    end
    for index, value in ipairs(array) do
        result[index] = value
    end
    return result
end

FishData.Fish = {
    river_bitterling = {
        name = "Bitterling",
        rarity = "COMMON",
        value = 900,
        spriteIndex = 301,
        inventoryId = "fish_bitterling",
        description = "A tiny winter river fish.",
        locations = { "river" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    river_pale_chub = {
        name = "Pale Chub",
        rarity = "UNCOMMON",
        value = 200,
        spriteIndex = 302,
        inventoryId = "fish_pale_chub",
        description = "A quick little river fish that prefers daylight.",
        locations = { "river" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    river_crucian_carp = {
        name = "Crucian Carp",
        rarity = "COMMON",
        value = 160,
        spriteIndex = 303,
        inventoryId = "fish_crucian_carp",
        description = "A hardy all-day river fish.",
        locations = { "river" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    river_dace = {
        name = "Dace",
        rarity = "UNCOMMON",
        value = 240,
        spriteIndex = 304,
        inventoryId = "fish_dace",
        description = "Leaps at dusk and dawn in flowing rivers.",
        locations = { "river" },
        timeOfDay = { "evening", "night", "morning" },
        activeHours = { { start = 16, finish = 24 }, { start = 0, finish = 9 } },
    },
    river_carp = {
        name = "Carp",
        rarity = "COMMON",
        value = 300,
        spriteIndex = 305,
        inventoryId = "fish_carp",
        description = "A classic carp that lurks in calm rivers.",
        locations = { "river", "pond" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    river_koi = {
        name = "Koi",
        rarity = "RARE",
        value = 4000,
        spriteIndex = 295,
        inventoryId = "fish_koi",
        description = "Graceful koi that surface at night.",
        locations = { "river", "pond" },
        timeOfDay = { "evening", "night" },
        activeHours = { { start = 16, finish = 24 }, { start = 0, finish = 9 } },
    },
    river_stringfish = {
        name = "Stringfish",
        rarity = "ULTRA_RARE",
        value = 15000,
        spriteIndex = 312,
        inventoryId = "fish_stringfish",
        description = "A massive fish found in cold clifftop rivers.",
        locations = { "river" },
        timeOfDay = { "evening", "night" },
        activeHours = { { start = 17, finish = 24 }, { start = 0, finish = 9 } },
    },
    river_bluegill = {
        name = "Bluegill",
        rarity = "COMMON",
        value = 180,
        spriteIndex = 308,
        inventoryId = "fish_bluegill",
        description = "A friendly river regular that loves sunny weather.",
        locations = { "river" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    river_rainbowfish = {
        name = "Rainbowfish",
        rarity = "RARE",
        value = 800,
        spriteIndex = 314,
        inventoryId = "fish_rainbowfish",
        description = "A shimmering tropical fish that appears in daylight.",
        locations = { "river" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    river_piranha = {
        name = "Piranha",
        rarity = "RARE",
        value = 2500,
        spriteIndex = 315,
        inventoryId = "fish_piranha",
        description = "A sharp-toothed night hunter from the river.",
        locations = { "river" },
        timeOfDay = { "night" },
        activeHours = { { start = 21, finish = 24 }, { start = 0, finish = 4 } },
    },
    river_arapaima = {
        name = "Arapaima",
        rarity = "ULTRA_RARE",
        value = 10000,
        spriteIndex = 316,
        inventoryId = "fish_arapaima",
        description = "A gigantic river dweller from the tropics.",
        locations = { "river" },
        timeOfDay = { "evening", "night" },
        activeHours = { { start = 16, finish = 24 }, { start = 0, finish = 9 } },
    },
    river_tilapia = {
        name = "Tilapia",
        rarity = "UNCOMMON",
        value = 800,
        spriteIndex = 309,
        inventoryId = "fish_tilapia",
        description = "An adaptable fish found year-round in rivers.",
        locations = { "river" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    pond_goldfish = {
        name = "Goldfish",
        rarity = "UNCOMMON",
        value = 1300,
        spriteIndex = 67,
        inventoryId = "fish_goldfish",
        description = "A dainty pond fish that glitters all day.",
        locations = { "pond" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    pond_ranchu_goldfish = {
        name = "Ranchu Goldfish",
        rarity = "RARE",
        value = 4500,
        spriteIndex = 306,
        inventoryId = "fish_ranchu_goldfish",
        description = "A prized pond goldfish with a regal crest.",
        locations = { "pond" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    pond_killifish = {
        name = "Killifish",
        rarity = "UNCOMMON",
        value = 300,
        spriteIndex = 307,
        inventoryId = "fish_killifish",
        description = "A miniscule pond fish that appears on warm days.",
        locations = { "pond" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    pond_loach = {
        name = "Loach",
        rarity = "COMMON",
        value = 400,
        spriteIndex = 69,
        inventoryId = "fish_loach",
        description = "A muddy pond fish that digs after rain.",
        locations = { "pond" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    pond_catfish = {
        name = "Catfish",
        rarity = "UNCOMMON",
        value = 800,
        spriteIndex = 313,
        inventoryId = "fish_catfish",
        description = "A whiskered pond resident that prowls at night.",
        locations = { "pond" },
        timeOfDay = { "night" },
        activeHours = { { start = 18, finish = 24 }, { start = 0, finish = 4 } },
    },
    pond_betta = {
        name = "Betta",
        rarity = "RARE",
        value = 2500,
        spriteIndex = 61,
        inventoryId = "fish_betta",
        description = "A vibrant pond fish that loves calm mornings.",
        locations = { "pond" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 16 } },
    },
    ocean_red_snapper = {
        name = "Red Snapper",
        rarity = "UNCOMMON",
        value = 3000,
        spriteIndex = 66,
        inventoryId = "fish_snapper",
        description = "A ruby ocean catch available year-round.",
        locations = { "ocean" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    ocean_sea_bass = {
        name = "Sea Bass",
        rarity = "COMMON",
        value = 400,
        spriteIndex = 321,
        inventoryId = "fish_sea_bass",
        description = "It's at least a C+.",
        locations = { "ocean" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    ocean_tuna = {
        name = "Tuna",
        rarity = "RARE",
        value = 7000,
        spriteIndex = 64,
        inventoryId = "fish_tuna",
        description = "A hefty pier catch that appears all day.",
        locations = { "ocean" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    ocean_blue_marlin = {
        name = "Blue Marlin",
        rarity = "ULTRA_RARE",
        value = 10000,
        spriteIndex = 318,
        inventoryId = "fish_blue_marlin",
        description = "A legendary ocean fish that towers over the dock.",
        locations = { "ocean" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    ocean_mahi_mahi = {
        name = "Mahi-Mahi",
        rarity = "RARE",
        value = 6000,
        spriteIndex = 319,
        inventoryId = "fish_mahi_mahi",
        description = "A vibrant seasonal fish drawn to sunny piers.",
        locations = { "ocean" },
        timeOfDay = { "day", "evening" },
        activeHours = { { start = 5, finish = 21 } },
    },
    ocean_giant_trevally = {
        name = "Giant Trevally",
        rarity = "RARE",
        value = 4500,
        spriteIndex = 317,
        inventoryId = "fish_giant_trevally",
        description = "A powerful ocean fish that loves sunlit waters.",
        locations = { "ocean" },
        timeOfDay = { "day" },
        activeHours = { { start = 5, finish = 18 } },
    },
    ocean_clownfish = {
        name = "Clownfish",
        rarity = "UNCOMMON",
        value = 650,
        spriteIndex = 62,
        inventoryId = "fish_clown",
        description = "A small reef fish that hides among anemones.",
        locations = { "ocean" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 17 } },
    },
    ocean_pufferfish = {
        name = "Pufferfish",
        rarity = "UNCOMMON",
        value = 250,
        spriteIndex = 63,
        inventoryId = "fish_puffer",
        description = "Inflates defensively in warm shallow seas.",
        locations = { "ocean" },
        timeOfDay = { "day" },
        activeHours = { { start = 12, finish = 18 } },
    },
    ocean_squid = {
        name = "Squid",
        rarity = "COMMON",
        value = 500,
        spriteIndex = 320,
        inventoryId = "fish_squid",
        description = "A slippery cephalopod drawn to moonlit waters.",
        locations = { "ocean" },
        timeOfDay = { "day", "night" },
        activeHours = { { start = 0, finish = 24 } },
    },
    ocean_seahorse = {
        name = "Seahorse",
        rarity = "RARE",
        value = 1100,
        spriteIndex = 70,
        inventoryId = "fish_seahorse",
        description = "A delicate ocean critter that clings to kelp.",
        locations = { "ocean" },
        timeOfDay = { "day" },
        activeHours = { { start = 9, finish = 19 } },
    },
}

local function normalizeLocation(location)
    if typeof(location) ~= "string" then
        return nil
    end
    local lower = string.lower(location)
    if lower == "shore" then
        return "ocean"
    end
    return lower
end

local function resolveHourAndPeriod(currentTime)
    local hour
    local period
    local timeType = typeof(currentTime)

    if timeType == "number" then
        hour = currentTime % 24
    elseif timeType == "string" then
        local lower = string.lower(currentTime)
        local numeric = tonumber(lower)
        if numeric then
            hour = numeric % 24
        else
            period = lower
        end
    elseif timeType == "table" then
        if typeof(currentTime.hour) == "number" then
            hour = currentTime.hour % 24
        elseif typeof(currentTime.Hour) == "number" then
            hour = currentTime.Hour % 24
        elseif typeof(currentTime.hours) == "number" then
            hour = currentTime.hours % 24
        end

        if currentTime.period then
            period = string.lower(tostring(currentTime.period))
        elseif currentTime.timeOfDay then
            period = string.lower(tostring(currentTime.timeOfDay))
        elseif currentTime.dayState then
            period = string.lower(tostring(currentTime.dayState))
        end
    end

    if not period and hour then
        if hour >= 5 and hour < 18 then
            period = "day"
        elseif hour >= 18 and hour < 21 then
            period = "evening"
        else
            period = "night"
        end
    end

    return hour, period
end

local function matchesLocation(fish, location)
    if not location then
        return true
    end
    if typeof(fish.locations) ~= "table" then
        return true
    end
    for _, entry in ipairs(fish.locations) do
        local lower = string.lower(entry)
        if lower == "any" or lower == location then
            return true
        end
    end
    return false
end

local function matchesTimeOfDay(fish, period)
    if not period then
        return true
    end
    if typeof(fish.timeOfDay) ~= "table" or #fish.timeOfDay == 0 then
        return true
    end

    local normalized = string.lower(period)
    for _, entry in ipairs(fish.timeOfDay) do
        local lower = string.lower(entry)
        if lower == "all" or lower == normalized then
            return true
        end
        if lower == "day" and normalized == "morning" then
            return true
        end
        if lower == "night" and (normalized == "evening" or normalized == "late") then
            return true
        end
    end

    return false
end

local function matchesHourWindow(fish, hour)
    if not hour then
        return true
    end

    if typeof(fish.activeHours) ~= "table" or #fish.activeHours == 0 then
        return true
    end

    local normalizedHour = (math.floor(hour) % 24 + 24) % 24

    for _, window in ipairs(fish.activeHours) do
        local startHour = window.start or window.from or window.begin or 0
        local endHour = window.finish or window.stop or window["end"] or 24

        startHour = (math.floor(startHour) % 24 + 24) % 24
        endHour = (math.floor(endHour) % 24 + 24) % 24

        if startHour == endHour then
            return true
        end

        if startHour < endHour then
            if normalizedHour >= startHour and normalizedHour < endHour then
                return true
            end
        else
            if normalizedHour >= startHour or normalizedHour < endHour then
                return true
            end
        end
    end

    return false
end

local function rollRarity()
    local roll = math.random()
    local cumulative = 0

    for _, rarityName in ipairs(FishData.RarityRollOrder) do
        local rarity = FishData.Rarity[rarityName]
        if rarity then
            cumulative += rarity.chance
            if roll <= cumulative then
                return rarityName
            end
        end
    end

    return "COMMON"
end

function FishData.getRandomFish(location, currentTime)
    local normalizedLocation = normalizeLocation(location)
    local hour, period = resolveHourAndPeriod(currentTime)

    local candidatesByRarity = {}
    for rarityName in pairs(FishData.Rarity) do
        candidatesByRarity[rarityName] = {}
    end

    for fishId, fish in pairs(FishData.Fish) do
        if fish and fish.rarity and FishData.Rarity[fish.rarity] then
            if
                matchesLocation(fish, normalizedLocation)
                and matchesTimeOfDay(fish, period)
                and matchesHourWindow(fish, hour)
            then
                table.insert(candidatesByRarity[fish.rarity], fishId)
            end
        end
    end

    local rolledRarity = rollRarity()
    local fallbackIndex = table.find(FishData.RarityFallbackOrder, rolledRarity) or #FishData.RarityFallbackOrder

    for index = fallbackIndex, #FishData.RarityFallbackOrder do
        local rarityName = FishData.RarityFallbackOrder[index]
        local bucket = candidatesByRarity[rarityName]
        if bucket and #bucket > 0 then
            return bucket[math.random(#bucket)]
        end
    end

    for index = fallbackIndex - 1, 1, -1 do
        local rarityName = FishData.RarityFallbackOrder[index]
        local bucket = candidatesByRarity[rarityName]
        if bucket and #bucket > 0 then
            return bucket[math.random(#bucket)]
        end
    end

    local commonBucket = candidatesByRarity.COMMON
    if commonBucket and #commonBucket > 0 then
        return commonBucket[math.random(#commonBucket)]
    end

    return "river_bitterling"
end

function FishData.getFishInfo(fishId)
    local entry = FishData.Fish[fishId]
    if not entry then
        return nil
    end

    local copy = {}
    for key, value in pairs(entry) do
        if typeof(value) == "table" then
            copy[key] = cloneArray(value)
        else
            copy[key] = value
        end
    end
    return copy
end

return FishData
