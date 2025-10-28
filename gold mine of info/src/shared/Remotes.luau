--[[
	Remotes - Remote events for Animal Crossing game
	Centralized remote event management
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Create Remotes folder
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

-- Player Data Remotes
local playerDataLoaded = Instance.new("RemoteEvent")
playerDataLoaded.Name = "PlayerDataLoaded"
playerDataLoaded.Parent = remotesFolder

local updateBalance = Instance.new("RemoteEvent")
updateBalance.Name = "UpdateBalance"
updateBalance.Parent = remotesFolder

-- Island Management Remotes
local createIsland = Instance.new("RemoteEvent")
createIsland.Name = "CreateIsland"
createIsland.Parent = remotesFolder

local selectIsland = Instance.new("RemoteEvent")
selectIsland.Name = "SelectIsland"
selectIsland.Parent = remotesFolder

-- Onboarding Remotes
local startOnboarding = Instance.new("RemoteEvent")
startOnboarding.Name = "StartOnboarding"
startOnboarding.Parent = remotesFolder

local completeOnboarding = Instance.new("RemoteEvent")
completeOnboarding.Name = "CompleteOnboarding"
completeOnboarding.Parent = remotesFolder

-- NPC Interaction Remotes
local interactWithNPC = Instance.new("RemoteEvent")
interactWithNPC.Name = "InteractWithNPC"
interactWithNPC.Parent = remotesFolder

-- Shop Remotes
local openShop = Instance.new("RemoteEvent")
openShop.Name = "OpenShop"
openShop.Parent = remotesFolder

local purchaseItem = Instance.new("RemoteEvent")
purchaseItem.Name = "PurchaseItem"
purchaseItem.Parent = remotesFolder

-- Inventory Remotes
local openInventory = Instance.new("RemoteEvent")
openInventory.Name = "OpenInventory"
openInventory.Parent = remotesFolder

local useItem = Instance.new("RemoteEvent")
useItem.Name = "UseItem"
useItem.Parent = remotesFolder

-- StarterGui Button Manipulation Remotes
local manipulateButtons = Instance.new("RemoteEvent")
manipulateButtons.Name = "ManipulateButtons"
manipulateButtons.Parent = remotesFolder

-- Component Control Remotes
local componentControl = Instance.new("RemoteEvent")
componentControl.Name = "ComponentControl"
componentControl.Parent = remotesFolder

local updateStats = Instance.new("RemoteEvent")
updateStats.Name = "UpdateStats"
updateStats.Parent = remotesFolder

print("[Remotes] Animal Crossing remotes created successfully!")

return Remotes
