--[[
	UIController - Dynamic GUI controller system
	Automatically attaches controllers to GUIs based on attributes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local UIController = {}

function UIController.new()
	local self = setmetatable({}, UIController)
	
	self._controllers = {}
	
	self:_initialize()
	
	return self
end

function UIController:_initialize()
	-- Wait for PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Attach controllers to existing GUIs
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then 
			self:_attachController(gui) 
		end
	end
	
	-- Attach controllers to new GUIs
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") then 
			self:_attachController(child) 
		end
	end)
	
	-- Setup global input handling
	self:_setupGlobalInput()
	
	print("[UIController] Dynamic GUI controller system initialized")
end

function UIController:_attachController(gui)
	-- Get controller name from attribute
	local controllerName = gui:GetAttribute("Controller")
	if not controllerName then 
		print("[UIController] No Controller attribute found on", gui.Name)
		return 
	end
	
	print("[UIController] Found Controller attribute:", controllerName, "on", gui.Name)
	
	-- Try to require the controller
	local success, Controller = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild(controllerName))
	end)
	
	if not success then
		warn("[UIController] Controller missing for", gui.Name, controllerName, Controller)
		return
	end
	
	-- Create controller instance
	local success2, instanceOrErr = pcall(function()
		return Controller.new(gui)
	end)
	
	if not success2 then
		warn("[UIController] Controller init failed for", gui.Name, instanceOrErr)
		return
	end
	
	-- Store the controller instance
	self._controllers[gui] = instanceOrErr
	
	print("[UIController] ✅ Controller attached:", controllerName, "to", gui.Name)
end

function UIController:_setupGlobalInput()
	-- Global input handling for all controllers
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- E key for inventory
		if input.KeyCode == Enum.KeyCode.E then
			self:_handleInventoryToggle()
		end
		
		-- Escape key to close any open GUIs
		if input.KeyCode == Enum.KeyCode.Escape then
			self:_handleEscapeKey()
		end
	end)
end

function UIController:_handleInventoryToggle()
	-- Find inventory GUI and toggle it
	local inventoryGUI = player:WaitForChild("PlayerGui"):FindFirstChild("InventoryGUI")
	if inventoryGUI then
		local controller = self._controllers[inventoryGUI]
		if controller and controller.Toggle then
			controller:Toggle()
		else
			-- Fallback: just toggle the GUI
			inventoryGUI.Enabled = not inventoryGUI.Enabled
		end
	end
end

function UIController:_handleEscapeKey()
	-- Close any open GUIs
	for gui, controller in pairs(self._controllers) do
		if gui.Enabled and controller.Hide then
			controller:Hide()
		end
	end
end

return UIController