--[[
	TomNookProximityHandler
	
	INSTRUCTIONS:
	1. Place this script inside your Tom Nook model in Workspace
	2. (Optional) Add a custom model from InsertService by pasting Asset ID below
	3. The prompt will fire the TalkToTomNook remote when triggered
	
	This allows players to interact with Tom Nook to open the island creation GUI
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

--═══════════════════════════════════════════════════════════════════════════
-- 📦 CUSTOM MODEL CONFIGURATION
--═══════════════════════════════════════════════════════════════════════════
-- To use a custom model from the Roblox library:
-- 1. Find a Tom Nook model in the Toolbox or Creator Marketplace
-- 2. Get the Asset ID (from the URL or model properties)
-- 3. Paste the Asset ID below (as a number)
-- 4. Leave as 0 to use the existing model this script is inside

local CUSTOM_MODEL_ASSET_ID = 5657298378  -- Tom Nook model from Toolbox

--═══════════════════════════════════════════════════════════════════════════

-- Get or load the Tom Nook model
local tomNookModel = script.Parent

-- If a custom model Asset ID is provided, try to load it
if CUSTOM_MODEL_ASSET_ID and CUSTOM_MODEL_ASSET_ID > 0 then
	print("[TomNook] Loading custom model from Asset ID:", CUSTOM_MODEL_ASSET_ID)
	
	local success, loadedModel = pcall(function()
		return InsertService:LoadAsset(CUSTOM_MODEL_ASSET_ID)
	end)
	
	if success and loadedModel then
		-- Find the actual model inside the loaded asset
		local model = loadedModel:FindFirstChildOfClass("Model")
		if model then
			-- Position it where the current model is
			if tomNookModel:IsA("Model") and tomNookModel.PrimaryPart then
				model:SetPrimaryPartCFrame(tomNookModel:GetPrimaryPartCFrame())
			end
			
			-- Parent the new model to workspace
			model.Parent = workspace
			model.Name = "TomNook"
			
			-- Destroy the old placeholder model
			if tomNookModel:IsA("Model") then
				tomNookModel:Destroy()
			end
			
			-- Move this script to the new model
			script.Parent = model
			tomNookModel = model
			
			print("[TomNook] ✅ Custom model loaded successfully!")
		else
			warn("[TomNook] ⚠️ No model found in loaded asset, using existing model")
		end
		
		loadedModel:Destroy()  -- Clean up container
	else
		warn("[TomNook] ⚠️ Failed to load custom model:", loadedModel)
		warn("[TomNook] Using existing model instead")
	end
end

assert(tomNookModel and tomNookModel:IsA("Model"), "This script must be a child of the Tom Nook Model")

-- Find or create ProximityPrompt
local function findOrCreatePrompt()
	-- Check if prompt already exists
	for _, descendant in pairs(tomNookModel:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			return descendant
		end
	end
	
	-- Create new prompt if it doesn't exist
	local primaryPart = tomNookModel.PrimaryPart or tomNookModel:FindFirstChildOfClass("Part")
	if not primaryPart then
		warn("[TomNook] No PrimaryPart found to attach ProximityPrompt!")
		return nil
	end
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Tom Nook"
	prompt.ActionText = "Talk & Create Island"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = primaryPart
	
	print("[TomNook] Created ProximityPrompt on", primaryPart.Name)
	return prompt
end

local proximityPrompt = findOrCreatePrompt()
if not proximityPrompt then
        warn("[TomNook] Failed to set up ProximityPrompt!")
        return
end

-- Wait for remotes to be ready
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotes then
        warn("[TomNook] Remotes folder not found!")
        return
end

local talkToNookRemote = remotes:WaitForChild("TalkToTomNook", 10)
if not talkToNookRemote then
        warn("[TomNook] TalkToTomNook remote not found!")
        return
end

local openOnboardingRemote = remotes:FindFirstChild("OpenOnboardingGUI")

local function getTomNookSpawner(timeout)
        local start = os.clock()
        repeat
                local spawner = rawget(_G, "TomNookSpawner")
                if spawner then
                        return spawner
                end
                task.wait(0.1)
        until timeout and os.clock() - start >= timeout

        return rawget(_G, "TomNookSpawner")
end

-- Connect ProximityPrompt to fire remote
proximityPrompt.Triggered:Connect(function(player)
        if not player or not player:IsA("Player") then
                warn("[TomNook] ProximityPrompt triggered without a valid player")
                return
        end

        print("[TomNook] Player triggered:", player.Name)

        if RunService:IsClient() then
                talkToNookRemote:FireServer()
                return
        end

        local spawner = getTomNookSpawner(5)
        if spawner and spawner.HandleInteraction then
                local ok, err = pcall(function()
                        spawner:HandleInteraction(player)
                end)

                if not ok then
                        warn("[TomNook] Failed to route interaction to TomNookSpawner:", err)
                end
                return
        end

        warn("[TomNook] TomNookSpawner not available; falling back to opening onboarding GUI directly.")

        if openOnboardingRemote then
                openOnboardingRemote:FireClient(player)
        end
end)

print("[TomNook] ✅ ProximityHandler ready! Players can now talk to Tom Nook to create their island.")

