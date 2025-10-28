--[[
	UIControllerDebug - Debug helper for the GUI controller system
	Helps verify that controllers are being attached correctly
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local UIControllerDebug = {}

function UIControllerDebug.new()
	local self = setmetatable({}, UIControllerDebug)
	
	self:_setupDebugInput()
	
	return self
end

function UIControllerDebug:_setupDebugInput()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- F10 key to debug GUI detection
		if input.KeyCode == Enum.KeyCode.F10 then
			self:_debugGUIs()
		end
		
		-- F11 key to test inventory
		if input.KeyCode == Enum.KeyCode.F11 then
			self:_testInventory()
		end
	end)
	
	print("[UIControllerDebug] Debug system initialized")
	print("[UIControllerDebug] Press F10 to debug GUIs")
	print("[UIControllerDebug] Press F11 to test inventory")
end

function UIControllerDebug:_debugGUIs()
	print("=== GUI Debug Info ===")
	
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- List all ScreenGuis
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local controllerName = gui:GetAttribute("Controller")
			print("GUI:", gui.Name)
			print("  - Controller attribute:", controllerName or "NONE")
			print("  - Enabled:", gui.Enabled)
			print("  - Visible:", gui.Visible)
		end
	end
	
	-- Check for InventoryGUI specifically
	local inventoryGUI = playerGui:FindFirstChild("InventoryGUI")
	if inventoryGUI then
		print("✅ InventoryGUI found!")
		print("  - Controller attribute:", inventoryGUI:GetAttribute("Controller"))
		print("  - Enabled:", inventoryGUI.Enabled)
	else
		print("❌ InventoryGUI not found in PlayerGui")
	end
	
	print("=== End Debug ===")
end

function UIControllerDebug:_testInventory()
	print("=== Testing Inventory ===")
	
	local inventoryGUI = player:WaitForChild("PlayerGui"):FindFirstChild("InventoryGUI")
	if inventoryGUI then
		print("✅ InventoryGUI found, toggling...")
		inventoryGUI.Enabled = not inventoryGUI.Enabled
		print("InventoryGUI enabled:", inventoryGUI.Enabled)
	else
		print("❌ InventoryGUI not found")
	end
	
	print("=== End Test ===")
end

return UIControllerDebug
