-- RemoteEvents.lua
-- Creates the necessary RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create InventoryEvent RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

print("[RemoteEvents] ✅ Created InventoryEvent RemoteEvent")
