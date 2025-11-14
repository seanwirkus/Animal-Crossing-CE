-- QuestHandlers.luau - Handles quest progress updates from game events

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local QuestTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestTypes"))

local QuestHandlers = {}
QuestHandlers._questService = nil

function QuestHandlers.initialize(questService)
    QuestHandlers._questService = questService
    print("[QuestHandlers] ✅ Initialized")
end

-- Handle fish caught
function QuestHandlers.onFishCaught(player, fishData)
    if not QuestHandlers._questService or not player then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        -- Check if quest has catch_fish objective
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.CATCH_FISH then
                -- Check if it's a rare fish quest
                if objective.targetId == "rare" then
                    -- Check if fish is rare (worth 5000+ bells)
                    local fishValue = fishData.value or 0
                    if fishValue >= 5000 then
                        QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                        print("[QuestHandlers] ✅ Rare fish quest progress:", quest.id)
                    end
                else
                    -- Regular fish catch quest
                    QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                    print("[QuestHandlers] ✅ Fish catch quest progress:", quest.id)
                end
            end
        end
    end
end

-- Handle bug caught
function QuestHandlers.onBugCaught(player, bugData)
    if not QuestHandlers._questService or not player then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.CATCH_BUG then
                QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                print("[QuestHandlers] ✅ Bug catch quest progress:", quest.id)
            end
        end
    end
end

-- Handle item collected
function QuestHandlers.onItemCollected(player, itemId, count)
    if not QuestHandlers._questService or not player then
        return
    end

    count = count or 1
    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.COLLECT_ITEM then
                -- Check if specific item is required
                if objective.targetId and objective.targetId ~= itemId then
                    -- Skip if specific item required but doesn't match
                else
                    QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, count)
                    print("[QuestHandlers] ✅ Item collect quest progress:", quest.id, "+", count)
                end
            end
        end
    end
end

-- Handle item crafted
function QuestHandlers.onItemCrafted(player, itemId)
    if not QuestHandlers._questService or not player then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.CRAFT_ITEM then
                -- Check if specific item is required
                if objective.targetId and objective.targetId ~= itemId then
                    -- Skip if specific item required but doesn't match
                else
                    QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                    print("[QuestHandlers] ✅ Craft quest progress:", quest.id)
                end
            end
        end
    end
end

-- Handle fossil dug
function QuestHandlers.onFossilDug(player)
    if not QuestHandlers._questService or not player then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.DIG_FOSSIL then
                QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                print("[QuestHandlers] ✅ Fossil dig quest progress:", quest.id)
            end
        end
    end
end

-- Handle bells earned/spent
function QuestHandlers.onBellsTransaction(player, amount, isEarned)
    if not QuestHandlers._questService or not player then
        return
    end

    -- Only track earned bells for quests
    if not isEarned then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.SPEND_BELLS then
                -- This tracks lifetime earnings, so increment by amount
                QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, amount)
                print("[QuestHandlers] ✅ Bell earning quest progress:", quest.id, "+", amount)
            end
        end
    end
end

-- Handle villager talked to
function QuestHandlers.onVillagerTalked(player, villagerName)
    if not QuestHandlers._questService or not player then
        return
    end

    local userId = player.UserId
    local activeQuests = QuestHandlers._questService:GetActiveQuests(userId)

    for _, quest in ipairs(activeQuests) do
        for _, objective in ipairs(quest.objectives or {}) do
            if objective.type == QuestTypes.ObjectiveType.TALK_TO_VILLAGER then
                QuestHandlers._questService:IncrementQuestProgress(userId, quest.id, 1)
                print("[QuestHandlers] ✅ Villager talk quest progress:", quest.id)
            end
        end
    end
end

return QuestHandlers
