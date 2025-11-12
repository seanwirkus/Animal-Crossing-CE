-- RemoteEvents.lua
-- Creates the necessary RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create InventoryEvent RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

print("[RemoteEvents] ✅ Created InventoryEvent RemoteEvent")

-- Create CurrencyEvent RemoteEvent
local currencyRemote = ReplicatedStorage:FindFirstChild("CurrencyEvent") or Instance.new("RemoteEvent")
currencyRemote.Name = "CurrencyEvent"
currencyRemote.Parent = ReplicatedStorage

print("[RemoteEvents] ✅ Created CurrencyEvent RemoteEvent")
