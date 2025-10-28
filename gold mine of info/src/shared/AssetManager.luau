--[[
        ACNH Asset Manager

        Provides a central lookup for models, textures, audio, and palette values
        so the project can mimic Animal Crossing: New Horizons while still being
        easy to reskin. Players can drop overrides into ReplicatedStorage/Assets
        or supply a manifest module to replace any entry.
]]

local gameInstance = game or _G.game
if not gameInstance then
        error("AssetManager requires a Roblox game context to resolve services")
end
local ReplicatedStorage = gameInstance:GetService("ReplicatedStorage")
local InsertService = gameInstance:GetService("InsertService")

local AssetManager = {}
AssetManager.__index = AssetManager

AssetManager._assetRootName = "Assets"
AssetManager._folders = {
        Models = "Models",
        Sprites = "Textures",
        Audio = "Audio",
}
AssetManager._manifests = {}

local function parseColor(value)
        if typeof(value) == "Color3" then
                return value
        elseif typeof(value) == "string" then
                local hex = value:gsub("#", "")
                if #hex == 6 then
                        local r = tonumber(hex:sub(1, 2), 16) or 255
                        local g = tonumber(hex:sub(3, 4), 16) or 255
                        local b = tonumber(hex:sub(5, 6), 16) or 255
                        return Color3.fromRGB(r, g, b)
                end
        elseif typeof(value) == "table" then
                local r = value.r or value[1]
                local g = value.g or value[2]
                local b = value.b or value[3]
                if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
                        if r <= 1 and g <= 1 and b <= 1 then
                                return Color3.new(r, g, b)
                        else
                                return Color3.fromRGB(r, g, b)
                        end
                end
        end
        return nil
end

-- 🏠 BUILDING & FURNITURE MODELS
AssetManager.Models = {
        -- Villager Houses (Replace with your custom house models)
        MapleHouse = "rbxasset://house_maple", -- Replace with your model ID
        FinnHouse = "rbxasset://house_finn",

        -- Furniture Models
        BonsaiTree = "rbxasset://furniture_bonsai",
        ShellLamp = "rbxasset://furniture_shell_lamp",
        WoodenChair = "rbxasset://furniture_chair_wood",

        -- Interactive Objects
        QuestBoard = "rbxasset://quest_board",
        ShopCounter = "rbxasset://shop_counter",
        BridgeWood = "rbxasset://bridge_wooden",

        -- Nature & Environment
        TreeApple = "rbxasset://tree_apple",
        TreeCherry = "rbxasset://tree_cherry",
        TreePear = "rbxasset://tree_pear",
        TreeOak = "rbxasset://tree_oak",
        FruitApple = "rbxasset://fruit_apple",
        FruitCherry = "rbxasset://fruit_cherry",
        FruitPear = "rbxasset://fruit_pear",
        VillagerDefault = "rbxasset://villager_default",
        Villager_maple = "rbxasset://villager_maple",
        Villager_finn = "rbxasset://villager_finn",
        Villager_tangy = "rbxasset://villager_tangy",
        Villager_apollo = "rbxasset://villager_apollo",
        Villager_celeste = "rbxasset://villager_celeste",
        Villager_sprig = "rbxasset://villager_sprig",
        FlowerBed = "rbxasset://flower_bed",
        Rock = "rbxasset://rock_standard",
}

-- 🎨 UI SPRITES & IMAGES
AssetManager.Sprites = {
	-- Currency Icons (uploaded to Roblox)
	BellIcon = "rbxassetid://140175723274467", -- Bell bag icon
	MileIcon = "rbxassetid://122418299304061", -- Nook Miles icon

	-- UI Textures (from assets/Textures)
	GrassTexture = "rbxasset://textures/grass_texture.png",
	WoodTexture = "rbxasset://textures/wood_texture.png",
	StoneTexture = "rbxasset://textures/stone_texture.png",
	WaterTexture = "rbxasset://textures/water_texture.png",
	
	-- UI Panels
	PaperPanel = "rbxasset://textures/paper_panel.png",
	WoodPanel = "rbxasset://textures/wood_panel.png",
	SpeechBubble = "rbxasset://textures/speech_bubble.png",
	
	-- Building Assets
	ResidentServices = "rbxasset://textures/resident_services.png",
	NooksCranny = "rbxasset://textures/nooks_cranny.png",
	
	-- Home/Housing
	PlayerHomeTent = "rbxasset://textures/player_home_tent.png",
	PlayerHomeHouse = "rbxasset://textures/player_home_house.png",
	PlayerHomeExpanded = "rbxasset://textures/player_home_expanded.png",
	PlayerHomeDeluxe = "rbxasset://textures/player_home_deluxe.png",
	
	-- Item Category Icons
	BellBag = "rbxasset://textures/bell_bag.png",
	MilesIcon = "rbxasset://textures/miles_icon.png",
	TicketButton = "rbxasset://textures/ticket_button.png",
	
	-- Effects & Overlays
	NoiseOverlay = "rbxasset://textures/noise_overlay.png",
	SoftShadow = "rbxasset://textures/soft_shadow.png",

	-- Item Category Icons (Roblox asset IDs - upgrade these as needed)
	FruitIcon = "rbxasset://texture/fruit_icon",
	FishIcon = "rbxasset://texture/fish_icon",
	BugIcon = "rbxasset://texture/bug_icon",
	NetIcon = "rbxassetid://77065401941486",
	FlimsyAxeIcon = "rbxassetid://95847187923407",
	FurnitureIcon = "rbxasset://texture/furniture_icon",

	-- Weather Icons
	SunnyIcon = "rbxasset://texture/weather_sunny",
	CloudyIcon = "rbxasset://texture/weather_cloudy",
	RainyIcon = "rbxasset://texture/weather_rainy",
	SnowyIcon = "rbxasset://texture/weather_snowy",

	-- Seasonal Decorations
	SpringIcon = "rbxasset://texture/season_spring",
	SummerIcon = "rbxasset://texture/season_summer",
	AutumnIcon = "rbxasset://texture/season_autumn",
	WinterIcon = "rbxasset://texture/season_winter",

	-- UI Backgrounds
	HudBackground = "rbxasset://texture/hud_bg_large",
	QuestPaper = "rbxasset://texture/quest_paper_large",
	DialogueBox = "rbxasset://texture/dialogue_box_large",
}

-- 🎵 AUDIO ASSETS
AssetManager.Audio = {
        -- Background Music (New Horizons tracks)
        MorningTheme = "rbxasset://audio/morning_theme",
        AfternoonTheme = "rbxasset://audio/afternoon_theme",
        EveningTheme = "rbxasset://audio/evening_theme",
        NightTheme = "rbxasset://audio/night_theme",

        -- Sound Effects
        BellSound = "rbxasset://audio/bell_sound",
        QuestComplete = "rbxasset://audio/quest_complete",
        VillagerGreeting = "rbxasset://audio/villager_hello",
}

-- 🎨 NEW HORIZONS COLOR PALETTE
AssetManager.Colors = {
        -- Main UI Colors (from New Horizons)
        IslandGreen = Color3.fromRGB(139, 195, 74),
        OceanBlue = Color3.fromRGB(33, 150, 243),
        SandBeige = Color3.fromRGB(255, 224, 178),

        -- Text Colors
        TextDark = Color3.fromRGB(62, 39, 35),
        TextLight = Color3.fromRGB(255, 255, 255),

        -- Currency Colors
        BellGold = Color3.fromRGB(255, 193, 7),
        MileBlue = Color3.fromRGB(33, 150, 243),

        -- Weather/Time Colors
        Morning = Color3.fromRGB(255, 235, 59),
        Afternoon = Color3.fromRGB(255, 152, 0),
        Evening = Color3.fromRGB(255, 87, 34),
        Night = Color3.fromRGB(63, 81, 181),
}

local function getAssetFolder(rootName, folderName)
        local assetRoot = ReplicatedStorage:FindFirstChild(rootName)
        if not assetRoot then
                return nil
        end
        if not folderName then
                return assetRoot
        end
        return assetRoot:FindFirstChild(folderName)
end

local function cloneIfInstance(instance)
        if instance and instance:IsA("Instance") then
                return instance:Clone()
        end
        return nil
end

function AssetManager:GetModel(modelName)
        local assetId = self.Models[modelName]
        if not assetId then
                warn("Model not found:", modelName)
                return nil
        end

        if typeof(assetId) == "Instance" then
                return cloneIfInstance(assetId)
        end

        local assetIdString = tostring(assetId)

        if string.sub(assetIdString, 1, 11) == "rbxasset://" then
                local assetsFolder = getAssetFolder(self._assetRootName, self._folders.Models)
                if assetsFolder then
                        local model = assetsFolder:FindFirstChild(modelName)
                        if model then
                                return cloneIfInstance(model)
                        end
                end
                warn("Custom model not found in ReplicatedStorage/" .. self._assetRootName .. ":", modelName)
                return nil
        end

        local numericId = tonumber(assetIdString)
        if numericId then
                local success, asset = pcall(function()
                        return InsertService:LoadAsset(numericId)
                end)
                if success then
                        return asset
                else
                        warn("Failed to load asset", modelName, asset)
                end
        end

        warn("Unable to resolve model asset:", modelName)
        return nil
end

function AssetManager:GetSprite(spriteName)
        local assetId = self.Sprites[spriteName]
        if not assetId then
                warn("Sprite not found:", spriteName)
                return "rbxasset://textures/ui/GuiImagePlaceholder.png"
        end

        if typeof(assetId) == "Instance" then
                if assetId:IsA("Decal") or assetId:IsA("Texture") then
                        return assetId.Texture
                elseif assetId:IsA("ImageLabel") or assetId:IsA("ImageButton") then
                        return assetId.Image
                end
        end

        local assetIdString = tostring(assetId)
        if string.sub(assetIdString, 1, 11) == "rbxasset://" then
                local texturesFolder = getAssetFolder(self._assetRootName, self._folders.Sprites)
                if texturesFolder then
                        local texture = texturesFolder:FindFirstChild(spriteName)
                        if texture and texture:IsA("Decal") then
                                return texture.Texture
                        elseif texture and (texture:IsA("ImageLabel") or texture:IsA("ImageButton")) then
                                return texture.Image
                        elseif texture and texture:IsA("Texture") then
                                return texture.Texture
                        end
                end
                return "rbxasset://textures/ui/GuiImagePlaceholder.png"
        elseif string.sub(assetIdString, 1, 13) == "rbxassetid://" then
                -- Asset ID is already a full URL
                return assetIdString
        end

        return "rbxassetid://" .. assetIdString
end

function AssetManager:GetAudio(audioName)
        local assetId = self.Audio[audioName]
        if not assetId then
                warn("Audio not found:", audioName)
                return nil
        end

        if typeof(assetId) == "Instance" then
                if assetId:IsA("Sound") then
                        return assetId.SoundId
                end
                return nil
        end

        local assetIdString = tostring(assetId)
        if string.sub(assetIdString, 1, 11) == "rbxasset://" then
                local audioFolder = getAssetFolder(self._assetRootName, self._folders.Audio)
                if audioFolder then
                        local sound = audioFolder:FindFirstChild(audioName)
                        if sound and sound:IsA("Sound") then
                                return sound.SoundId
                        end
                end
                return nil
        end

        return "rbxassetid://" .. assetIdString
end

function AssetManager:GetColor(colorName, fallback)
        local value = self.Colors[colorName]
        local parsed = value and parseColor(value)
        if parsed then
                return parsed
        end
        if fallback then
                return fallback
        end
        return nil
end

local function mergeCategory(target, source)
        for key, value in pairs(source) do
                target[key] = value
        end
end

function AssetManager:ApplyManifest(manifest)
        if typeof(manifest) ~= "table" then
                return
        end
        table.insert(self._manifests, manifest)

        for category, payload in pairs(manifest) do
                if category == "Settings" and typeof(payload) == "table" then
                        if payload.RootFolder then
                                self._assetRootName = payload.RootFolder
                        end
                        if payload.Folders then
                                for kind, folderName in pairs(payload.Folders) do
                                        if kind == "Textures" then
                                                self._folders.Sprites = folderName
                                        else
                                                self._folders[kind] = folderName
                                        end
                                end
                        end
                else
                        local target = self[category]
                        if typeof(target) == "table" and typeof(payload) == "table" then
                                mergeCategory(target, payload)
                        end
                end
        end
end

local function tryApplyManifest(moduleScript)
        if not moduleScript or not moduleScript:IsA("ModuleScript") then
                return
        end

        local success, manifest = pcall(require, moduleScript)
        if success and typeof(manifest) == "table" then
                AssetManager:ApplyManifest(manifest)
        else
                warn("Failed to load asset manifest", moduleScript:GetFullName(), manifest)
        end
end

tryApplyManifest(script.Parent:FindFirstChild("AssetManifest"))
tryApplyManifest(ReplicatedStorage:FindFirstChild("AssetManifest"))

local assetsFolder = ReplicatedStorage:FindFirstChild(AssetManager._assetRootName)
if assetsFolder then
        tryApplyManifest(assetsFolder:FindFirstChild("Manifest"))
end

return AssetManager
