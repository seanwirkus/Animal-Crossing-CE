--[[
	InteractionController
	Handles player interactions with objects in the world (resources, villagers, furniture, etc.)
	Shows proximity prompts and manages interaction state
]]


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Load DialogueSystem from the sibling UI folder
local DialogueSystem = require(script.Parent.Parent.UI.DialogueSystem)
local VillagerData = require(ReplicatedStorage.Data.Villagers)

local InteractionController = {}
InteractionController.__index = InteractionController

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local INTERACTION_RANGE = 8  -- studs
local CHECK_INTERVAL = 0.2  -- seconds
local HANDS_TOOL_ID = "tool_none"

local VALID_HARVEST_TYPES = {
        tree = true,
        rock = true,
        water = true,
        bug = true,
        digspot = true,
        plant = true,
        fossil = true,
        ground = true,
}

local function normalizeHarvestType(harvestType)
        if typeof(harvestType) ~= "string" then
                return nil
        end

        return string.lower(harvestType)
end

local function isValidHarvestType(harvestType)
        local normalized = normalizeHarvestType(harvestType)
        if not normalized then
                return false
        end

        return VALID_HARVEST_TYPES[normalized] == true
end

local function resolveHarvestTarget(instance)
        local current = instance
        while current do
                local harvestType = current:GetAttribute("HarvestType") or current:GetAttribute("ResourceType")
                if isValidHarvestType(harvestType) then
                        return current, harvestType
                end
                current = current.Parent
        end

        return nil, nil
end

local function getInstancePosition(instance)
        if not instance then
                return nil
        end

        if instance:IsA("Model") then
                return instance:GetPivot().Position
        elseif instance:IsA("Attachment") then
                return instance.WorldPosition
        elseif instance:IsA("BasePart") then
                return instance.Position
        end

        return nil
end

function InteractionController.new(remotes, toolSelector)
	local self = setmetatable({}, InteractionController)
	self._remotes = remotes
	self._toolSelector = toolSelector
	self._nearbyInteractables = {}
	self._currentTarget = nil
	self._promptGui = nil

	self:_buildPromptUI()
	self:_setupInput()
	self:_startProximityCheck()

	return self
end

function InteractionController:_buildPromptUI()
	local screenGui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("InteractionPrompts")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "InteractionPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 15
		screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	local promptFrame = Instance.new("Frame")
	promptFrame.Name = "PromptFrame"
	promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	promptFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
	promptFrame.Size = UDim2.new(0, 200, 0, 50)
	promptFrame.BackgroundColor3 = Color3.fromRGB(62, 39, 35)
	promptFrame.BackgroundTransparency = 0.2
	promptFrame.BorderSizePixel = 0
	promptFrame.Visible = false
	promptFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = promptFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 248, 220)
	stroke.Thickness = 2
	stroke.Parent = promptFrame
	
	local promptText = Instance.new("TextLabel")
	promptText.Name = "PromptText"
	promptText.Size = UDim2.new(1, 0, 1, 0)
	promptText.BackgroundTransparency = 1
	promptText.Font = Enum.Font.GothamBold
	promptText.TextSize = 16
	promptText.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptText.Text = "[E] Interact"
	promptText.Parent = promptFrame
	
	self._promptGui = promptFrame
	self._promptText = promptText
end

function InteractionController:_setupInput()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.E then
			self:_tryInteract()
		end
	end)
	
	-- Handle building clicks with mouse
	local mouse = player:GetMouse()
	mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if target then
			local current = target
			while current and current.Parent do
				if current:GetAttribute("Clickable") == true then
					local buildingType = current:GetAttribute("BuildingType")
					if buildingType then
						local buildingClickRemote = self._remotes:Get("BuildingClicked")
						if buildingClickRemote then
							buildingClickRemote:FireServer(buildingType)
						end
					end
					return
				end
				current = current.Parent
			end
		end
	end)
end

function InteractionController:_startProximityCheck()
	task.spawn(function()
		while true do
			self:_checkNearbyObjects()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

function InteractionController:_checkNearbyObjects()
	if not humanoidRootPart then
		character = player.Character
		if character then
			humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		end
		return
	end

	local playerPosition = humanoidRootPart.Position
	local closestTarget = nil
	local closestDistance = INTERACTION_RANGE

	-- Check for interactable objects in workspace
	local interactables = workspace:FindFirstChild("Interactables")
	if interactables then
		for _, obj in pairs(interactables:GetChildren()) do
			if obj:IsA("Model") or obj:IsA("Part") then
				local objPosition = obj:GetPivot().Position
				local distance = (playerPosition - objPosition).Magnitude

				if distance < closestDistance then
					closestTarget = obj
					closestDistance = distance
				end
			end
		end
	end

        -- Also check for tool-based resources tagged in workspace
        local visitedHarvestTargets = {}
        for _, descendant in pairs(workspace:GetDescendants()) do
                local harvestTarget = resolveHarvestTarget(descendant)
                if harvestTarget and not visitedHarvestTargets[harvestTarget] then
                        visitedHarvestTargets[harvestTarget] = true

                        local objPosition = getInstancePosition(harvestTarget)
                        if objPosition then
                                local distance = (playerPosition - objPosition).Magnitude

                                if distance < closestDistance then
                                        closestTarget = harvestTarget
                                        closestDistance = distance
                                end
                        end
                end
        end

	-- Update current target
	if closestTarget ~= self._currentTarget then
		self._currentTarget = closestTarget
		self:_updatePrompt()
	end
end

function InteractionController:_updatePrompt()
	if not self._currentTarget then
		self._promptGui.Visible = false
		return
	end

        -- Determine interaction type from object
        local interactionType = self._currentTarget:GetAttribute("InteractionType")
        local harvestInstance, rawHarvestType = resolveHarvestTarget(self._currentTarget)
        if harvestInstance and harvestInstance ~= self._currentTarget then
                self._currentTarget = harvestInstance
        end

        local harvestType = normalizeHarvestType(rawHarvestType)
        local promptText = "[E] Interact"

        if harvestType then
                -- Tool-based interaction
                local selectedTool = self._toolSelector:GetSelectedTool()
                local usingHands = not selectedTool or selectedTool == HANDS_TOOL_ID

                if harvestType == "tree" then
                        if usingHands then
                                promptText = "[E] 🌳 Shake Tree"
                        elseif selectedTool == "tool_flimsy_axe" or selectedTool == "tool_axe" then
                                promptText = "[E] 🪓 Chop Tree"
                        else
                                promptText = "[E] 🧰 Need Axe (T)"
                        end
                elseif harvestType == "water" then
                        if selectedTool == "tool_fishing_rod_basic" or selectedTool == "tool_fishing_rod" then
                                promptText = "[E] 🎣 Cast Line"
                        elseif usingHands then
                                promptText = "[E] 🧰 Need Rod (T)"
                        else
                                promptText = "[E] 🧰 Need Rod"
                        end
                elseif harvestType == "bug" then
                        if selectedTool == "tool_bug_net_basic" or selectedTool == "tool_bug_net" then
                                promptText = "[E] 🦋 Catch Bug"
                        elseif usingHands then
                                promptText = "[E] 🧰 Need Net (T)"
                        else
                                promptText = "[E] 🧰 Need Net"
                        end
                elseif harvestType == "rock" or harvestType == "digspot" then
                        if selectedTool == "tool_shovel_basic" or selectedTool == "tool_shovel" then
                                promptText = "[E] ⛏️ Dig"
                        elseif usingHands then
                                promptText = "[E] 💎 Need Shovel (T)"
                        else
                                promptText = "[E] 💎 Need Shovel"
                        end
                elseif harvestType == "plant" then
                        if selectedTool == "tool_watering_can_basic" or selectedTool == "tool_watering_can" then
                                promptText = "[E] 💧 Water"
                        elseif usingHands then
                                promptText = "[E] 🧰 Need Can (T)"
                        else
                                promptText = "[E] 🧰 Need Can"
                        end
                else
                        self._promptGui.Visible = false
                        return
                end
        elseif interactionType == "Resource" then
                local resourceType = self._currentTarget:GetAttribute("ResourceType")
                if resourceType == "Fish" then
                        promptText = "[E] 🎣 Cast Line"
		elseif resourceType == "Bug" then
			promptText = "[E] 🦋 Catch Bug"
		elseif resourceType == "Fruit" then
			promptText = "[E] 🍎 Pick Fruit"
		elseif resourceType == "Shell" then
			promptText = "[E] 🐚 Collect Shell"
		end
	elseif interactionType == "Villager" then
		local villagerName = self._currentTarget:GetAttribute("VillagerName")
		promptText = string.format("[E] Talk to %s", villagerName or "Villager")
        elseif interactionType == "Furniture" then
                promptText = "[E] Use"
        elseif interactionType == "Shop" then
                promptText = "[E] Browse Shop"
        elseif interactionType == "QuestBoard" then
                promptText = "[E] View Quests"
        else
                self._promptGui.Visible = false
                return
        end

        self._promptText.Text = promptText
        self._promptGui.Visible = true
end

function InteractionController:_tryInteract()
	if not self._currentTarget then
		return
	end

        local harvestInstance, rawHarvestType = resolveHarvestTarget(self._currentTarget)
        if harvestInstance and harvestInstance ~= self._currentTarget then
                self._currentTarget = harvestInstance
        end

        local harvestType = normalizeHarvestType(rawHarvestType)
        local interactionType = self._currentTarget:GetAttribute("InteractionType")

        if harvestType then
                -- Tool-based interaction
                local selectedTool = self._toolSelector:GetSelectedTool()
                local usingHands = not selectedTool or selectedTool == HANDS_TOOL_ID
                if usingHands then
                        if harvestType == "tree" then
                                local shakeRemote = self._remotes:Get("ShakeTree")
                                if shakeRemote then
                                        shakeRemote:FireServer(self._currentTarget)
                                end
                        end
                elseif selectedTool then
                        local useToolRemote = self._remotes:Get("UseTool")
                        if useToolRemote then
                                useToolRemote:FireServer(selectedTool, humanoidRootPart.Position, self._currentTarget)
                        end
                end
		-- Hide prompt temporarily
		self._currentTarget = nil
		self._promptGui.Visible = false
	else
		-- Legacy interaction types
		if interactionType == "Resource" then
			self:_interactWithResource()
		elseif interactionType == "Villager" then
			self:_interactWithVillager()
		elseif interactionType == "Shop" then
			self:_interactWithShop()
		elseif interactionType == "QuestBoard" then
			self:_interactWithQuestBoard()
		elseif interactionType == "Furniture" then
			self:_interactWithFurniture()
		end
	end
end

function InteractionController:_interactWithResource()
	local resourceType = self._currentTarget:GetAttribute("ResourceType")
	local resourceId = self._currentTarget:GetAttribute("ResourceId")
	
	-- Fire server event to collect resource
	local collectRemote = self._remotes:FindFirstChild("CollectResource")
	if collectRemote then
		collectRemote:FireServer(self._currentTarget, resourceType, resourceId)
	end
	
	-- Hide prompt temporarily
	self._currentTarget = nil
	self._promptGui.Visible = false
end

function InteractionController:_interactWithVillager()
	local villagerId = self._currentTarget:GetAttribute("VillagerId")
	local villagerName = self._currentTarget:GetAttribute("VillagerName") or villagerId or "Villager"
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Check onboarding state (simple: check if player has an island)
	local hasIsland = false
	local success, result = pcall(function()
		return player:GetAttribute("HasIsland")
	end)
	if success and result then
		hasIsland = result
	end

	if not hasIsland then
		-- Show onboarding message for all villagers except Tom Nook
		if villagerName == "Tom Nook" then
			DialogueSystem.ShowVillagerDialogue(
				playerGui,
				"Tom Nook",
				"Welcome! Let's get you set up with your very own island. Ready to begin your new life?",
				player.Name,
				{ color = "light", continueButton = true, nameTagColor = "yellow" }
			)
		else
			DialogueSystem.ShowVillagerDialogue(
				playerGui,
				villagerName,
				"You should talk to Tom Nook first! He'll help you get started on your island adventure.",
				player.Name,
				{ color = "light", continueButton = true, nameTagColor = "blue" }
			)
		end
		return
	end

	-- If player has an island, show normal villager dialogue
	local villager = VillagerData[villagerId]
	local dialogueText = "Hello!"
	if villager and villager.dialogue and villager.dialogue.greetings then
		local greetings = villager.dialogue.greetings
		dialogueText = greetings[math.random(1, #greetings)]
	end
	DialogueSystem.ShowVillagerDialogue(
		playerGui,
		villagerName,
		dialogueText,
		player.Name,
		{ color = "light", continueButton = true, nameTagColor = "yellow" }
	)
end

function InteractionController:_interactWithShop()
	-- Open shop UI
	print("Opening shop...")
	-- TODO: Implement shop UI
end

function InteractionController:_interactWithQuestBoard()
	-- Open quest board UI
	print("Opening quest board...")
	-- TODO: This should be handled by Hud
end

function InteractionController:_interactWithFurniture()
	local furnitureId = self._currentTarget:GetAttribute("FurnitureId")

	-- Fire server event to use furniture
	local useRemote = self._remotes:Get("UseFurniture")
	if useRemote then
		useRemote:FireServer(furnitureId, self._currentTarget)
	end
end

function InteractionController:_getToolName(toolId)
	local Data = ReplicatedStorage.Shared.Data
	local Items = require(Data.Items)
	local toolDef = Items[toolId] or (Data.GeneratedItems and Data.GeneratedItems[toolId])
	if toolDef then
		return toolDef.name or toolId
	else
		return toolId
	end
end

return InteractionController
