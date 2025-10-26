-- InventoryClient.lua
-- Debug version to see why E key doesn't work

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

print("[Debug] Starting InventoryClient...")

-- Try to get modules with error handling
local success, modules = pcall(function()
	return ReplicatedStorage:WaitForChild("Modules", 5) -- 5 second timeout
end)

if not success then
	warn("[Debug] ❌ Could not find Modules folder:", modules)
	return
end

print("[Debug] ✅ Found Modules folder")

-- Try to require modules
local SpriteConfig, ItemData
local success1, result1 = pcall(function()
	return require(modules:WaitForChild("SpriteConfig"))
end)

local success2, result2 = pcall(function()
	return require(modules:WaitForChild("ItemData"))
end)

if not success1 then
	warn("[Debug] ❌ Could not load SpriteConfig:", result1)
	return
end

if not success2 then
	warn("[Debug] ❌ Could not load ItemData:", result2)
	return
end

SpriteConfig = result1
ItemData = result2
print("[Debug] ✅ Modules loaded successfully")

-- Try to get remote event
local success3, inventoryRemote = pcall(function()
	return ReplicatedStorage:WaitForChild("InventoryEvent", 5)
end)

if not success3 then
	warn("[Debug] ❌ Could not find InventoryEvent:", inventoryRemote)
	return
end

print("[Debug] ✅ Found InventoryEvent")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

print("[Debug] ✅ Got PlayerGui")

-- Try to find inventory GUI
local inventoryGui = gui:FindFirstChild("PlayerInventoryGUI") or gui:FindFirstChild("InventoryGUI") or gui:FindFirstChild("InventoryFullGUI")
if not inventoryGui then
	warn("[Debug] ❌ Could not find inventory GUI. Available GUIs:")
	for _, child in ipairs(gui:GetChildren()) do
		print("[Debug]   -", child.Name)
	end
	return
end

print("[Debug] ✅ Found inventory GUI:", inventoryGui.Name)

-- Try to navigate the nested structure
local inventoryFrame = inventoryGui:FindFirstChild("InventoryFrame")
if not inventoryFrame then
	warn("[Debug] ❌ Could not find InventoryFrame in", inventoryGui.Name)
	print("[Debug] Available children:")
	for _, child in ipairs(inventoryGui:GetChildren()) do
		print("[Debug]   -", child.Name)
	end
	return
end

print("[Debug] ✅ Found InventoryFrame")

local inventoryItems = inventoryFrame:FindFirstChild("InventoryItems")
if not inventoryItems then
	warn("[Debug] ❌ Could not find InventoryItems in InventoryFrame")
	print("[Debug] Available children:")
	for _, child in ipairs(inventoryFrame:GetChildren()) do
		print("[Debug]   -", child.Name)
	end
	return
end

print("[Debug] ✅ Found InventoryItems")

local template = inventoryItems:FindFirstChild("ItemSlotTemplate")
if not template then
	warn("[Debug] ❌ Could not find ItemSlotTemplate in InventoryItems")
	print("[Debug] Available children:")
	for _, child in ipairs(inventoryItems:GetChildren()) do
		print("[Debug]   -", child.Name)
	end
	return
end

print("[Debug] ✅ Found ItemSlotTemplate")

-- === STATE VARIABLES ======================================================
local visible = false

-- === INPUT HANDLING ========================================================
print("[Debug] Setting up input handling...")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	print("[Debug] Input detected:", input.KeyCode.Name, "GameProcessed:", gameProcessed)
	
	if gameProcessed then 
		print("[Debug] Input was game processed, ignoring")
		return 
	end
	
	if input.KeyCode == Enum.KeyCode.E then
		print("[Debug] E key pressed! Toggling inventory...")
		visible = not visible
		inventoryFrame.Visible = visible
		if visible then 
			print("[Debug] 📦 Inventory opened")
		else
			print("[Debug] 📦 Inventory closed")
		end
	else
		print("[Debug] Other key pressed:", input.KeyCode.Name)
	end
end)

print("[Debug] ✅ Input handling set up")

-- === REMOTE EVENT HANDLERS ================================================
inventoryRemote.OnClientEvent:Connect(function(action, data)
	print("[Debug] Received remote event:", action, data)
	if action == "SyncInventory" then
		print("[Debug] ✅ Inventory synced with", #data, "items")
	end
end)

-- === INITIALIZATION =======================================================
inventoryFrame.Visible = false

print("[Debug] ✅ InventoryClient ready!")
print("[Debug] 🎮 Press E to toggle inventory")
print("[Debug] 📊 GUI Structure:", inventoryGui.Name, "> InventoryFrame > InventoryItems")