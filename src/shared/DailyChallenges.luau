local HttpService = game:GetService("HttpService")

local DailyChallenges = {}
DailyChallenges.__index = DailyChallenges

-- Challenge templates are intentionally flavorful so villagers can reference them.
-- Each template now tracks a difficulty tier to allow mixed lineups and reward scaling.
DailyChallenges.templates = {
    {
        id = "dig_three_treasures",
        name = "Buried Bounty",
        description = "Dig up buried surprises around the island.",
        event = "dig_spot",
        target = 3,
        rewardBells = 800,
        rewardMiles = 100,
        difficulty = "easy",
        villagerMessages = {
            "I heard a rumor there's treasure everywhere today!",
            "Keep your shovel handy—shiny things love to hide.",
            "Do you smell that? It's the scent of fresh loam and fortune!",
        },
    },
    {
        id = "dig_five_fossils",
        name = "Fossil Frenzy",
        description = "Uncover fossils for Blathers' museum exhibit.",
        event = "dig_spot",
        target = 5,
        rewardBells = 1400,
        rewardMiles = 200,
        difficulty = "medium",
        villagerMessages = {
            "Blathers is itching to clean some fossils—mind digging extra?",
            "Every fossil has a story. Let's find a whole chapter today!",
        },
    },
    {
        id = "catch_five_fish",
        name = "Casting Call",
        description = "Reel in a handful of fish for the villagers' cookout.",
        event = "catch_fish",
        target = 5,
        rewardBells = 1200,
        rewardMiles = 150,
        difficulty = "easy",
        villagerMessages = {
            "The pier is extra lively—fish won't know what hooked 'em!",
            "If you see a shadow, drop that bobber!",
            "Smells like the tide brought in some curiosities...",
        },
    },
    {
        id = "catch_ten_fish",
        name = "Fisherfolk Fête",
        description = "Stock up on fish for a seaside stew night.",
        event = "catch_fish",
        target = 10,
        rewardBells = 2500,
        rewardMiles = 350,
        difficulty = "hard",
        villagerMessages = {
            "Ten fish! Think you can reel that many before sunset?",
            "K.K. wants background splashes for his next track—cast away!",
        },
    },
    {
        id = "chop_two_trees",
        name = "Woodsy Workout",
        description = "Collect wood by chopping nearby trees.",
        event = "chop_tree",
        target = 2,
        rewardBells = 600,
        rewardMiles = 90,
        difficulty = "easy",
        villagerMessages = {
            "Fresh lumber smells amazing—can you grab a few logs?",
            "Tom Nook mentioned we're low on wood for projects.",
        },
    },
    {
        id = "chop_five_trees",
        name = "Workshop Resupply",
        description = "Gather sturdy wood for the island workshop.",
        event = "chop_tree",
        target = 5,
        rewardBells = 1700,
        rewardMiles = 240,
        difficulty = "medium",
        villagerMessages = {
            "The DIY bench is begging for more lumber!",
            "Let's make the plaza smell like fresh timber today.",
        },
    },
    {
        id = "pop_three_balloons",
        name = "Sky Gifts",
        description = "Pop floating presents drifting across the sky.",
        event = "balloon_pop",
        target = 3,
        rewardBells = 1500,
        rewardMiles = 200,
        difficulty = "medium",
        villagerMessages = {
            "Listen for that whooshing sound; gifts are overhead!",
            "Shooting balloons down never gets old.",
            "Red ribbon? Green ribbon? Pop 'em all and find out!",
        },
    },
    {
        id = "pop_five_balloons",
        name = "Sky Hunter",
        description = "Keep the skies clear and collect every drifting parcel.",
        event = "balloon_pop",
        target = 5,
        rewardBells = 2200,
        rewardMiles = 320,
        difficulty = "hard",
        villagerMessages = {
            "The wind is on our side—balloons everywhere!",
            "Aim true! Gifts are gliding by in a hurry.",
        },
    },
    {
        id = "catch_four_bugs",
        name = "Bug Bonanza",
        description = "Snag bugs for Flick's art references.",
        event = "catch_bug",
        target = 4,
        rewardBells = 1100,
        rewardMiles = 160,
        difficulty = "easy",
        villagerMessages = {
            "Flick is sketching again—he needs fresh buggy models!",
            "Tiptoe through the flowers; wings are fluttering.",
        },
    },
    {
        id = "catch_eight_bugs",
        name = "Insect Investigator",
        description = "Catalog a full page of bugs for the critterpedia.",
        event = "catch_bug",
        target = 8,
        rewardBells = 2100,
        rewardMiles = 300,
        difficulty = "medium",
        villagerMessages = {
            "Do you hear that buzzing? That's opportunity!",
            "Blathers might faint, but science demands specimens.",
        },
    },
    {
        id = "water_ten_flowers",
        name = "Garden Guardian",
        description = "Water flowers to keep the island blooming.",
        event = "water_flower",
        target = 10,
        rewardBells = 900,
        rewardMiles = 140,
        difficulty = "easy",
        villagerMessages = {
            "Hydrate those petals—rain might be late today!",
            "Bud wants to smell fresh roses near the plaza.",
        },
    },
    {
        id = "water_twenty_flowers",
        name = "Master Gardener",
        description = "Keep every garden patch shining with a good soak.",
        event = "water_flower",
        target = 20,
        rewardBells = 2000,
        rewardMiles = 320,
        difficulty = "hard",
        villagerMessages = {
            "Leif brought new fertilizer—prime time to water!",
            "Even cacti appreciate a gentle sprinkle now and then.",
        },
    },
    {
        id = "talk_to_villagers",
        name = "Friendly Faces",
        description = "Chat with villagers to brighten everyone's day.",
        event = "talk_villager",
        target = 6,
        rewardBells = 700,
        rewardMiles = 130,
        difficulty = "easy",
        villagerMessages = {
            "A smile and a hello go a long way—spread some cheer!",
            "Someone's planning a surprise; gossip time!",
        },
    },
    {
        id = "craft_four_items",
        name = "DIY Dynamo",
        description = "Craft handy tools or décor at the workbench.",
        event = "craft_item",
        target = 4,
        rewardBells = 1600,
        rewardMiles = 260,
        difficulty = "medium",
        villagerMessages = {
            "Timmy wants new stock—can you craft a few things?",
            "The workbench is humming today. Let's build!",
        },
    },
    {
        id = "sell_island_goods",
        name = "Market Day",
        description = "Sell island goods to keep commerce booming.",
        event = "sell_item",
        target = 8,
        rewardBells = 1800,
        rewardMiles = 240,
        difficulty = "medium",
        villagerMessages = {
            "Nook's Cranny is running a special—bring in those wares!",
            "Timmy and Tommy love seeing new finds on the counter.",
        },
    },
    {
        id = "plant_four_saplings",
        name = "Future Forest",
        description = "Plant saplings to keep the island green.",
        event = "plant_tree",
        target = 4,
        rewardBells = 1400,
        rewardMiles = 210,
        difficulty = "medium",
        villagerMessages = {
            "Let's add more shade near the river trail!",
            "Imagine how cozy this place will feel with more trees.",
        },
    },
    {
        id = "harvest_fruit_baskets",
        name = "Fruit Frenzy",
        description = "Harvest fruit baskets to share with everyone.",
        event = "harvest_fruit",
        target = 6,
        rewardBells = 1500,
        rewardMiles = 240,
        difficulty = "medium",
        villagerMessages = {
            "The orchards look ripe—grab a basket!",
            "Juice stand pop-up? Only if we have fruit to squeeze!",
        },
    },
    {
        id = "deliver_gifts",
        name = "Courier Extraordinaire",
        description = "Hand-deliver gifts to island friends.",
        event = "deliver_gift",
        target = 3,
        rewardBells = 1200,
        rewardMiles = 200,
        difficulty = "easy",
        villagerMessages = {
            "Wrap it with care—smiles incoming!",
            "Nothing beats a thoughtful surprise.",
        },
    },
    {
        id = "decorate_outdoors",
        name = "Plaza Glow-Up",
        description = "Place new outdoor décor to freshen the plaza.",
        event = "place_furniture",
        target = 5,
        rewardBells = 1800,
        rewardMiles = 260,
        difficulty = "medium",
        villagerMessages = {
            "Label wants photo spots—can you decorate the plaza?",
            "Let's make visiting campers say 'wow!'",
        },
    },
    {
        id = "cook_three_meals",
        name = "Café Rush",
        description = "Cook meals for villagers stopping by the café.",
        event = "cook_meal",
        target = 3,
        rewardBells = 2000,
        rewardMiles = 320,
        difficulty = "hard",
        villagerMessages = {
            "Brewster ran low on specials—time to cook!",
            "The café smells delicious already, keep it coming!",
        },
    },
}

DailyChallenges.villagers = {
    "Isabelle",
    "Tom Nook",
    "Blathers",
    "Celeste",
    "Timmy",
    "Tommy",
    "Mabel",
    "Sable",
    "Flick",
    "C.J.",
    "K.K. Slider",
    "Leif",
}

local function deterministicShuffle(list, seed)
    local rng = Random.new(seed)
    local shuffled = table.clone(list)
    for i = #shuffled, 2, -1 do
        local j = rng:NextInteger(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

local function getSeedFromDate(dateTable)
    return tonumber(dateTable.year .. string.format("%02d%02d%02d", dateTable.yday, dateTable.hour, dateTable.min))
end

function DailyChallenges.getDateKey(targetDate)
    return os.date("!*t", targetDate or os.time())
end

function DailyChallenges.getFeaturedVillager(today)
    local dateTable = DailyChallenges.getDateKey(today)
    local seed = getSeedFromDate(dateTable)
    local villagers = deterministicShuffle(DailyChallenges.villagers, seed)
    return villagers[1]
end

function DailyChallenges.getDailyLineup(count, today)
    local dateTable = DailyChallenges.getDateKey(today)
    local seedValue = getSeedFromDate(dateTable)
    local shuffled = deterministicShuffle(DailyChallenges.templates, seedValue)
    local lineup = {}

    local usedEvents = {}
    for _, template in ipairs(shuffled) do
        if not usedEvents[template.event] then
            table.insert(lineup, template)
            usedEvents[template.event] = true
        end
        if #lineup >= count then
            break
        end
    end

    -- If we ran out of unique events, fill remaining slots normally.
    if #lineup < count then
        for _, template in ipairs(shuffled) do
            table.insert(lineup, template)
            if #lineup >= count then
                break
            end
        end
    end

    return lineup
end

function DailyChallenges.hydrateTemplate(template, opts)
    local chosenVillager = opts and opts.featuredVillager or DailyChallenges.getFeaturedVillager(opts and opts.today)
    local seed = opts and opts.seed or os.time()
    local rng = Random.new(seed)
    local message = nil
    if template.villagerMessages and #template.villagerMessages > 0 then
        message = template.villagerMessages[rng:NextInteger(1, #template.villagerMessages)]
    end

    return {
        id = template.id,
        name = template.name,
        description = template.description,
        event = template.event,
        target = template.target,
        progress = 0,
        rewardBells = template.rewardBells,
        rewardMiles = template.rewardMiles,
        state = "active",
        villagerMessages = template.villagerMessages,
        difficulty = template.difficulty or "easy",
        featuredVillager = chosenVillager,
        openingMessage = message,
    }
end

function DailyChallenges.decorateMessage(challenge, progress)
    local tipPrefix = challenge.featuredVillager and string.format("%s says: ", challenge.featuredVillager) or ""
    local baseMessage = challenge.openingMessage or "Keep going!"
    if progress and challenge.target then
        local remaining = math.max(challenge.target - progress, 0)
        baseMessage = string.format("%s (%d/%d, %d left)", baseMessage, progress, challenge.target, remaining)
    end
    return tipPrefix .. baseMessage
end

function DailyChallenges.serialize(challenge)
    return HttpService:JSONEncode(challenge)
end

function DailyChallenges.deserialize(json)
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(json)
    end)

    if success and type(decoded) == "table" then
        return decoded
    end

    return nil
end

return DailyChallenges
