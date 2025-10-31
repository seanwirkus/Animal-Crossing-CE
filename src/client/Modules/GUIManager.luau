-- GUIManager.luau
-- Manages GUI visibility so only one GUI is visible at a time

local GUIManager = {}
GUIManager.__index = GUIManager

-- GUI registry
local registeredGUIs = {}
local currentVisibleGUI = nil

function GUIManager.new()
	local self = setmetatable({}, GUIManager)
	return self
end

-- Register a GUI with a unique name
function GUIManager:registerGUI(name, guiObject)
	if not name or not guiObject then
		warn("[GUIManager] Invalid registration:", name, guiObject)
		return false
	end
	
	registeredGUIs[name] = {
		object = guiObject,
		name = name,
	}
	
	print("[GUIManager] ✅ Registered GUI:", name)
	return true
end

-- Helper to hide a GUI object
local function hideGUIObject(obj)
	if not obj then
		return
	end
	
	-- Try different hide methods
	if obj.Hide then
		obj:Hide()
	elseif obj.setInventoryVisible then
		obj:setInventoryVisible(false)
	elseif obj.close then
		obj:close()
	elseif typeof(obj) == "Instance" then
		if obj:IsA("GuiObject") then
			obj.Visible = false
		elseif obj:IsA("ScreenGui") then
			obj.Enabled = false
		end
	end
end

-- Helper to show a GUI object
local function showGUIObject(obj)
	if not obj then
		return
	end
	
	-- Try different show methods
	if obj.Show then
		obj:Show()
	elseif obj.setInventoryVisible then
		obj:setInventoryVisible(true)
	elseif obj.open then
		obj:open()
	elseif typeof(obj) == "Instance" then
		if obj:IsA("GuiObject") then
			obj.Visible = true
		elseif obj:IsA("ScreenGui") then
			obj.Enabled = true
		end
	end
end

-- Show a GUI (hides current one if different)
function GUIManager:showGUI(name)
	if not registeredGUIs[name] then
		warn("[GUIManager] GUI not registered:", name)
		return false
	end
	
	local guiData = registeredGUIs[name]
	
	-- Hide current GUI if it's different
	if currentVisibleGUI and currentVisibleGUI ~= name then
		local currentData = registeredGUIs[currentVisibleGUI]
		if currentData and currentData.object then
			hideGUIObject(currentData.object)
			print("[GUIManager] Hiding GUI:", currentVisibleGUI)
		end
	end
	
	-- Show new GUI
	showGUIObject(guiData.object)
	
	currentVisibleGUI = name
	print("[GUIManager] Showing GUI:", name)
	return true
end

-- Hide a GUI
function GUIManager:hideGUI(name)
	if not registeredGUIs[name] then
		return false
	end
	
	local guiData = registeredGUIs[name]
	
	-- Use helper to hide
	hideGUIObject(guiData.object)
	
	if currentVisibleGUI == name then
		currentVisibleGUI = nil
	end
	
	print("[GUIManager] Hiding GUI:", name)
	return true
end

-- Toggle a GUI (show if hidden, hide if shown, hide others)
function GUIManager:toggleGUI(name)
	if not registeredGUIs[name] then
		warn("[GUIManager] GUI not registered:", name)
		return false
	end
	
	if currentVisibleGUI == name then
		-- Currently visible, hide it
		return self:hideGUI(name)
	else
		-- Currently hidden, show it (will hide others)
		return self:showGUI(name)
	end
end

-- Hide all GUIs
function GUIManager:hideAll()
	for name, _ in pairs(registeredGUIs) do
		self:hideGUI(name)
	end
	print("[GUIManager] All GUIs hidden")
end

-- Get currently visible GUI name
function GUIManager:getCurrentVisible()
	return currentVisibleGUI
end

-- Check if a GUI is visible
function GUIManager:isVisible(name)
	return currentVisibleGUI == name
end

-- Expose currentVisibleGUI for external access (used by DebugManager wrapper)
function GUIManager:setCurrentVisible(name)
	currentVisibleGUI = name
end

return GUIManager

