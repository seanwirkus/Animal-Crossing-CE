-- RemoteEvents.lua
-- Creates the necessary RemoteEvents for client-server communication

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create InventoryEvent RemoteEvent
local inventoryRemote = ReplicatedStorage:FindFirstChild("InventoryEvent") or Instance.new("RemoteEvent")
inventoryRemote.Name = "InventoryEvent"
inventoryRemote.Parent = ReplicatedStorage

-- Create EnterPlane RemoteEvent
local enterPlaneRemote = ReplicatedStorage:FindFirstChild("EnterPlane") or Instance.new("RemoteEvent")
enterPlaneRemote.Name = "EnterPlane"
enterPlaneRemote.Parent = ReplicatedStorage

-- Create PlaneInput RemoteEvent
local planeInputRemote = ReplicatedStorage:FindFirstChild("PlaneInput") or Instance.new("RemoteEvent")
planeInputRemote.Name = "PlaneInput"
planeInputRemote.Parent = ReplicatedStorage

print("[RemoteEvents] ✅ Created InventoryEvent RemoteEvent")
print("[RemoteEvents] ✅ Created EnterPlane RemoteEvent")
print("[RemoteEvents] ✅ Created PlaneInput RemoteEvent")
