-- ToolRingGUI.lua
-- Animal Crossing-style tool ring that appears when T is pressed
-- Displays 8 tools in a circular arrangement
-- Only shows tools (fishing rods, axes, nets, etc.), not regular items

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ToolRingGUI = {}
ToolRingGUI.__index = ToolRingGUI

-- Tool Ring Configuration
local RING_RADIUS = 110
local TOOL_SLOT_SIZE = 60
local CENTER_SIZE = 80
local GLOW_SIZE = 68

-- Tool Categories - items that can be equipped from tool ring
local TOOL_KEYWORDS = {
	"fishing", "rod", "axe", "net", "shovel", "pickaxe", "watering", "can", 
	"slingshot", "ladder", "flimsy", "stone", "iron", "golden", "tools", "tool",
	"bug_net", "net_", "rod_", "fishing_rod", "golden_"
}

-- Colors - ACNH Aesthetic
local COLORS = {
	-- Item states
	ITEM_GRABBED = Color3.fromRGB(255, 234, 160),  -- #FFEEA0 (grabbing)
	ITEM_SELECTED = Color3.fromRGB(3, 176, 170),   -- #03B0AA (selected/teal)
	
	-- UI Theme (Animal Crossing style)
	BG_PRIMARY = Color3.fromRGB(255, 251, 231),    -- Cream background
	BG_SECONDARY = Color3.fromRGB(255, 255, 255),  -- White
	ACCENT_BROWN = Color3.fromRGB(120, 100, 80),   -- Brown titles
	TEXT_DARK = Color3.fromRGB(60, 50, 40),
	TEXT_LIGHT = Color3.fromRGB(255, 255, 255),
	SLOT_NORMAL = Color3.fromRGB(240, 235, 220),
	SLOT_HOVER = Color3.fromRGB(220, 215, 200),
	SLOT_EQUIPPED = Color3.fromRGB(255, 234, 160), -- Bright highlight when equipped
	BORDER_DARK = Color3.fromRGB(100, 80, 60),
	GLOW_COLOR = Color3.fromRGB(3, 176, 170),      -- Teal glow for selected
}

-- 8 Tool slots - will be populated from inventory
local function createEmptyToolSlots()
	return {
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
		{name = "Empty", icon = "", description = "No tool equipped", isEmpty = true},
	}
end

-- Check if an item is a tool
local function isTool(itemId, itemName)
	if not itemId then return false end
	-- itemName can be nil, that's OK - we have itemId as fallback
	
	local lowerName = string.lower(tostring(itemName))
	local lowerId = string.lower(tostring(itemId))
	
	print("[ToolRing] 🔍 isTool DEBUG: itemId='" .. lowerId .. "' itemName='" .. lowerName .. "'")
	print("[ToolRing] ⚙️ TOOL_KEYWORDS type: " .. type(TOOL_KEYWORDS) .. " length: " .. (TOOL_KEYWORDS and #TOOL_KEYWORDS or "nil"))
	
	if not TOOL_KEYWORDS then
		print("[ToolRing] ❌ ERROR: TOOL_KEYWORDS is nil!")
		return false
	end
	
	-- Check if item name/id contains tool keywords
	print("[ToolRing] 📋 Checking " .. #TOOL_KEYWORDS .. " keywords...")
	for _, keyword in ipairs(TOOL_KEYWORDS) do
		print("[ToolRing]   Testing keyword: '" .. keyword .. "'")
		local nameMatch = string.find(lowerName, keyword)
		local idMatch = string.find(lowerId, keyword)
		print("[ToolRing]     nameMatch: " .. tostring(nameMatch) .. " idMatch: " .. tostring(idMatch))
		if nameMatch or idMatch then
			print("[ToolRing] ✅ MATCHED keyword: '" .. keyword .. "' (name:" .. tostring(nameMatch) .. " id:" .. tostring(idMatch) .. ")")
			return true
		end
	end
	
	-- Also check for specific tool-like item IDs with proper Lua pattern matching
	-- Suffix patterns (ends with) - use %z for end anchor
	if string.match(lowerId, "_rod%z") or 
	   string.match(lowerId, "_net%z") or 
	   string.match(lowerId, "_axe%z") or 
	   string.match(lowerId, "_shovel%z") or
	   string.match(lowerId, "_pick%z") then
		print("[ToolRing] ✅ Matched suffix pattern")
		return true
	end
	
	-- Prefix patterns (starts with) - ^ means start
	if string.match(lowerId, "^rod_") or 
	   string.match(lowerId, "^net_") or 
	   string.match(lowerId, "^axe_") or 
	   string.match(lowerId, "^shovel_") then
		print("[ToolRing] ✅ Matched prefix pattern")
		return true
	end
	
	print("[ToolRing] ❌ No match for: " .. lowerId)
	return false
end

function ToolRingGUI.new()
	local self = setmetatable({}, ToolRingGUI)
	
	self.gui = nil
	self.visible = false
	self.selectedSlot = 1
	self.toolSlots = {}
	self.tools = createEmptyToolSlots()  -- Initialize with empty slots
	self.centerLabel = nil
	self.backgroundFrame = nil
	self.inventoryClient = nil  -- Will be set when connected to inventory
	
	self:createGUI()
	
	return self
end

-- Connect to inventory client to populate tools
function ToolRingGUI:setInventoryClient(inventoryClient)
	self.inventoryClient = inventoryClient
	
	-- Initial update (may be empty if inventory not loaded yet)
	self:updateToolsFromInventory()
	
	-- Listen to inventory remote events to update tool ring when items change
	local inventoryRemote = inventoryClient.inventoryRemote
	if inventoryRemote then
		inventoryRemote.OnClientEvent:Connect(function()
			print("[ToolRing] 🔔 Inventory remote event fired, updating tools...")
			self:updateToolsFromInventory()
		end)
	end
	
	-- Also set up a periodic check to catch inventory updates
	-- This helps with timing issues where items arrive after this function is called
	task.spawn(function()
		for i = 1, 50 do  -- Check for 5 seconds (50 * 0.1s)
			task.wait(0.1)
			if #self.tools > 0 and not self.tools[1].isEmpty then
				-- Tools are now populated, stop checking
				print("[ToolRing] ✅ Tools populated, stopping periodic checks")
				return
			end
			self:updateToolsFromInventory()
		end
	end)
end

-- Update tool slots from inventory (only includes tools)
function ToolRingGUI:updateToolsFromInventory()
	if not self.inventoryClient then 
		print("[ToolRing] ⚠️ No inventory client set yet")
		return 
	end
	
	-- Collect all tools from inventory
	local toolList = {}
	local slotState = self.inventoryClient.slotState
	
	if slotState then
		print("[ToolRing] 🔍 slotState exists, iterating items...")
		local itemCount = 0
		for slotIndex, itemState in pairs(slotState) do
			itemCount = itemCount + 1
			if itemState and itemState.itemId then
				local itemId = tostring(itemState.itemId)
				local itemName = tostring(itemState.name or "Unknown")
				print("[ToolRing] 🔍 Checking slot " .. tostring(slotIndex) .. ": " .. itemId .. " (" .. itemName .. ")")
				
				-- Check if this item is a tool
				if isTool(itemState.itemId, itemState.name) then
					table.insert(toolList, {
						name = itemState.name or "Unknown",
						itemId = itemState.itemId,
						spriteIndex = itemState.spriteIndex,
						description = itemState.name or "Tool",
						isEmpty = false,
						count = itemState.count or 1,
						slotIndex = slotIndex
					})
					print("[ToolRing] ✅ Found tool: " .. itemId .. " (" .. itemName .. ")")
				else
					print("[ToolRing] ❌ Not a tool: " .. itemId .. " (" .. itemName .. ")")
				end
			end
		end
		print("[ToolRing] 📊 Checked " .. tostring(itemCount) .. " items total")
	else
		print("[ToolRing] ⚠️ slotState is nil")
	end
	
	print("[ToolRing] 📊 Total tools found: " .. tostring(#toolList))
	
	-- Fill tool ring with collected tools (up to 8)
	for i = 1, 8 do
		if i <= #toolList then
			self.tools[i] = toolList[i]
		else
			self.tools[i] = {name = "Empty", icon = "", description = "No tool", isEmpty = true}
		end
	end
	
	-- Update UI if visible
	if self.visible then
		self:updateSlotUI()
	end
end

-- Update all slot UI elements with sprites and visual feedback
function ToolRingGUI:updateSlotUI()
	if not self.gui then return end
	
	local container = self.gui:FindFirstChild("ToolRingContainer")
	if not container then return end
	
	-- Load SpriteConfig for sprite display
	local success, SpriteConfig = pcall(function()
		return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("SpriteConfig"))
	end)
	
	if not success then
		print("[ToolRing] ⚠️ Could not load SpriteConfig")
		return
	end
	
	for i = 1, 8 do
		local slot = container:FindFirstChild("ToolSlot" .. i)
		if slot then
			local tool = self.tools[i]
			local icon = slot:FindFirstChild("Icon")
			local name = slot:FindFirstChild("Name")
			local countLabel = slot:FindFirstChild("Count")
			
			-- Update name and count
			if name then
				name.Text = tool.name
			end
			
			-- Update icon with sprite if item has sprite index
			if icon and tool.spriteIndex and not tool.isEmpty then
				local spriteSuccess = pcall(function()
					SpriteConfig.applySprite(icon, tool.spriteIndex)
				end)
				if not spriteSuccess then
					icon.Image = ""
				end
			elseif icon then
				icon.Image = ""  -- Clear if empty
			end
			
			-- Update count label
			if tool.count and tool.count > 1 then
				if countLabel then
					countLabel.Text = tostring(tool.count)
					countLabel.Visible = true
				end
			elseif countLabel then
				countLabel.Visible = false
			end
		end
	end
	
	-- Update center display
	self:updateCenterDisplay()
end

-- Update the center label display
function ToolRingGUI:updateCenterDisplay()
	if not self.centerLabel then return end
	
	local selectedTool = self.tools[self.selectedSlot]
	if selectedTool then
		-- Show item count if not empty
		if not selectedTool.isEmpty then
			self.centerLabel.Text = selectedTool.count and tostring(selectedTool.count) or "1"
		else
			self.centerLabel.Text = ""
		end
		self.descriptionLabel.Text = selectedTool.description
	end
end

function ToolRingGUI:createGUI()
	-- Get player and playerGui
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create ScreenGui with high visibility
	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "ToolRingGUI"
	self.gui.ResetOnSpawn = false
	self.gui.DisplayOrder = 20  -- Higher priority for visibility
	self.gui.Enabled = false
	self.gui.IgnoreGuiInset = false
	self.gui.Parent = playerGui
	
	-- Main container (center of screen) - NO BACKGROUND
	local container = Instance.new("Frame")
	container.Name = "ToolRingContainer"
	local diameter = (RING_RADIUS + TOOL_SLOT_SIZE) * 2.2
	container.Size = UDim2.new(0, diameter, 0, diameter)
	container.Position = UDim2.new(0.5, -(diameter/2), 0.5, -(diameter/2))
	container.BackgroundTransparency = 1  -- Fully transparent
	container.ZIndex = 1
	container.Parent = self.gui
	
	-- Center indicator (large, highlighted circle)
	self.centerLabel = Instance.new("TextLabel")
	self.centerLabel.Name = "CenterLabel"
	self.centerLabel.Size = UDim2.new(0, CENTER_SIZE, 0, CENTER_SIZE)
	self.centerLabel.Position = UDim2.new(0.5, -(CENTER_SIZE/2), 0.5, -(CENTER_SIZE/2))
	self.centerLabel.BackgroundColor3 = COLORS.BG_PRIMARY
	self.centerLabel.BorderSizePixel = 0
	self.centerLabel.Text = ""
	self.centerLabel.TextSize = 32
	self.centerLabel.Font = Enum.Font.GothamBold
	self.centerLabel.TextColor3 = COLORS.ITEM_SELECTED
	self.centerLabel.ZIndex = 5
	self.centerLabel.Parent = container
	
	-- Center label corner (fully round)
	local centerCorner = Instance.new("UICorner")
	centerCorner.CornerRadius = UDim.new(1, 0)  -- Fully round (circle)
	centerCorner.Parent = self.centerLabel
	
	-- Center glow effect (larger, semi-transparent background)
	local glowBg = Instance.new("Frame")
	glowBg.Name = "GlowBg"
	glowBg.Size = UDim2.new(0, GLOW_SIZE, 0, GLOW_SIZE)
	glowBg.Position = UDim2.new(0.5, -(GLOW_SIZE/2), 0.5, -(GLOW_SIZE/2))
	glowBg.BackgroundColor3 = COLORS.ITEM_SELECTED
	glowBg.BackgroundTransparency = 0.85  -- Very transparent
	glowBg.BorderSizePixel = 0
	glowBg.ZIndex = 3
	glowBg.Parent = container
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glowBg
	
	-- Create tool slots in circle with enhanced styling
	for i, tool in ipairs(self.tools) do
		local angle = (i - 1) * (math.pi * 2 / #self.tools) - (math.pi / 2)  -- Start at top
		local x = math.cos(angle) * RING_RADIUS
		local y = math.sin(angle) * RING_RADIUS
		
		-- Create slot frame
		local slot = Instance.new("TextButton")
		slot.Name = "ToolSlot" .. i
		slot.Size = UDim2.new(0, TOOL_SLOT_SIZE, 0, TOOL_SLOT_SIZE)
		slot.Position = UDim2.new(0.5, x - (TOOL_SLOT_SIZE/2), 0.5, y - (TOOL_SLOT_SIZE/2))
		slot.BackgroundColor3 = COLORS.SLOT_NORMAL
		slot.BorderSizePixel = 0
		slot.Text = ""  -- No text on button itself
		slot.AutoButtonColor = false  -- Disable auto color change
		slot.ZIndex = 4
		slot.Parent = container
		
		-- Slot corner rounding (fully round)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)  -- Fully round (circle)
		corner.Parent = slot
		
		-- Inner frame for visual separation
		local innerFrame = Instance.new("Frame")
		innerFrame.Name = "InnerFrame"
		innerFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
		innerFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
		innerFrame.BackgroundTransparency = 1
		innerFrame.BorderSizePixel = 0
		innerFrame.ZIndex = 5
		innerFrame.Parent = slot
		
		-- Tool icon (ImageLabel for sprites)
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Image = ""  -- Will be populated with sprites
		icon.ZIndex = 5
		icon.Parent = innerFrame
		
		-- Tool name (shown on hover or when empty)
		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.Size = UDim2.new(1, 0, 0.4, 0)
		name.Position = UDim2.new(0, 0, 0.6, 0)
		name.BackgroundTransparency = 0.8
		name.BackgroundColor3 = COLORS.TEXT_DARK
		name.Text = tool.name
		name.TextSize = 11
		name.Font = Enum.Font.GothamBold
		name.TextColor3 = COLORS.TEXT_LIGHT
		name.TextScaled = true
		name.TextWrapped = true
		name.ZIndex = 6
		name.Visible = false  -- Hidden by default
		name.Parent = slot
		
		-- Count label for stacked items
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "Count"
		countLabel.Size = UDim2.new(0, 24, 0, 24)
		countLabel.Position = UDim2.new(1, -28, 1, -28)
		countLabel.BackgroundColor3 = COLORS.ITEM_GRABBED
		countLabel.BorderSizePixel = 0
		countLabel.Text = "1"
		countLabel.TextSize = 12
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextColor3 = COLORS.TEXT_DARK
		countLabel.Visible = false
		countLabel.ZIndex = 7
		local countCorner = Instance.new("UICorner")
		countCorner.CornerRadius = UDim.new(0, 4)
		countCorner.Parent = countLabel
		countLabel.Parent = slot
		
		-- Store reference
		self.toolSlots[i] = {
			frame = slot,
			icon = icon,
			name = name,
			tool = tool,
			index = i,
			innerFrame = innerFrame,
			countLabel = countLabel,
			glow = glowBg
		}
		
		-- Click handler - equip the tool
		slot.MouseButton1Click:Connect(function()
			self:selectTool(i)
			-- Equip the item if it exists
			if not self.tools[i].isEmpty then
				self:equipTool(i)
			end
		end)
		
		-- Hover effects - show name on hover
		slot.MouseEnter:Connect(function()
			local slotData = self.toolSlots[i]
			if slotData then
				-- Show name label
				if slotData.name then
					slotData.name.Visible = true
				end
				-- Hover animation
				if i ~= self.selectedSlot then
					local hoverTween = TweenService:Create(slot, 
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
						{BackgroundColor3 = COLORS.SLOT_HOVER}
					)
					hoverTween:Play()
				end
			end
		end)
		
		slot.MouseLeave:Connect(function()
			local slotData = self.toolSlots[i]
			if slotData then
				-- Hide name label
				if slotData.name then
					slotData.name.Visible = false
				end
				-- Leave animation
				if i ~= self.selectedSlot then
					local leaveTween = TweenService:Create(slot, 
						TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
						{BackgroundColor3 = COLORS.SLOT_NORMAL}
					)
					leaveTween:Play()
				end
			end
		end)
	end
	
	-- Tool description at bottom - LARGER AND MORE PROMINENT
	self.descriptionLabel = Instance.new("TextLabel")
	self.descriptionLabel.Name = "Description"
	self.descriptionLabel.Size = UDim2.new(0, 300, 0, 40)
	self.descriptionLabel.Position = UDim2.new(0.5, -150, 1, -60)
	self.descriptionLabel.BackgroundColor3 = COLORS.BG_PRIMARY
	self.descriptionLabel.BorderSizePixel = 0
	self.descriptionLabel.Text = "Select a tool"
	self.descriptionLabel.TextSize = 14
	self.descriptionLabel.Font = Enum.Font.GothamBold
	self.descriptionLabel.TextColor3 = COLORS.TEXT_DARK
	self.descriptionLabel.TextWrapped = true
	self.descriptionLabel.ZIndex = 4
	self.descriptionLabel.Parent = self.gui
	
	-- Description corner - rounded
	local descCorner = Instance.new("UICorner")
	descCorner.CornerRadius = UDim.new(0, 8)
	descCorner.Parent = self.descriptionLabel
	
	-- Add instruction label at top
	local instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "Instructions"
	instructionLabel.Size = UDim2.new(0, 320, 0, 28)
	instructionLabel.Position = UDim2.new(0.5, -160, 0, 8)
	instructionLabel.BackgroundColor3 = COLORS.BG_PRIMARY
	instructionLabel.BorderSizePixel = 0
	instructionLabel.Text = "⚒️ TOOL RING - Click a tool to equip"
	instructionLabel.TextSize = 12
	instructionLabel.Font = Enum.Font.GothamBold
	instructionLabel.TextColor3 = COLORS.ACCENT_BROWN
	instructionLabel.ZIndex = 4
	instructionLabel.Parent = self.gui
	
	local instructCorner = Instance.new("UICorner")
	instructCorner.CornerRadius = UDim.new(0, 8)
	instructCorner.Parent = instructionLabel
end

function ToolRingGUI:selectTool(index)
	if index < 1 or index > #self.tools then return end
	
	-- Update previous selection - return to normal
	if self.toolSlots[self.selectedSlot] then
		local prevSlot = self.toolSlots[self.selectedSlot]
		prevSlot.frame.BackgroundColor3 = COLORS.SLOT_NORMAL
		
		-- Animate back to normal size
		local prevTween = TweenService:Create(prevSlot.frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, TOOL_SLOT_SIZE, 0, TOOL_SLOT_SIZE)}
		)
		prevTween:Play()
	end
	
	-- Update new selection - highlight it
	self.selectedSlot = index
	local newSlot = self.toolSlots[self.selectedSlot]
	if newSlot then
		newSlot.frame.BackgroundColor3 = COLORS.ITEM_GRABBED  -- Bright highlight
		
		-- Animate to larger size for emphasis
		local newTween = TweenService:Create(newSlot.frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, TOOL_SLOT_SIZE + 8, 0, TOOL_SLOT_SIZE + 8)}
		)
		newTween:Play()
	end
	
	-- Update center display with count
	self:updateCenterDisplay()
	
	local selectedTool = self.tools[self.selectedSlot]
	print("[ToolRing] ✅ Selected tool:", selectedTool.name, "(Slot " .. self.selectedSlot .. ")")
end

-- Equip a tool from the ring (sends to server via inventory remote)
function ToolRingGUI:equipTool(index)
	if not self.inventoryClient then
		print("[ToolRing] ⚠️ No inventory client connected")
		return
	end
	
	if index < 1 or index > 8 then
		print("[ToolRing] ⚠️ Invalid tool slot:", index)
		return
	end
	
	local tool = self.tools[index]
	if not tool or tool.isEmpty then
		print("[ToolRing] ⚠️ Slot", index, "is empty")
		return
	end
	
	if not tool.itemId then
		print("[ToolRing] ⚠️ Tool has no itemId")
		return
	end
	
	-- Get the inventory remote from the inventory client
	local inventoryRemote = self.inventoryClient.inventoryRemote
	if not inventoryRemote then
		print("[ToolRing] ❌ No inventory remote found")
		return
	end
	
	-- Fire equip event to server with item details
	print("[ToolRing] ⚒️ Equipping tool:", tool.name, "from slot", index)
	
	local success, err = pcall(function()
		inventoryRemote:FireServer("EquipItem", {
			itemId = tool.itemId,
			name = tool.name
		})
	end)
	
	if not success then
		print("[ToolRing] ❌ Failed to send equip request:", err)
	else
		print("[ToolRing] ✅ Equip request sent to server")
	end
end

function ToolRingGUI:show()
	if self.visible then return end
	
	self.visible = true
	self.gui.Enabled = true
	
	-- Refresh tool list before showing
	self:updateToolsFromInventory()
	self:updateSlotUI()
	
	-- Fast pop-out animation - no staggering
	for i, slotData in pairs(self.toolSlots) do
		local slot = slotData.frame
		slot.Size = UDim2.new(0, 0, 0, 0)
		
		local tween = TweenService:Create(slot,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, TOOL_SLOT_SIZE, 0, TOOL_SLOT_SIZE)}
		)
		tween:Play()
	end
	
	-- Animate center with pop effect
	self.centerLabel.Size = UDim2.new(0, 10, 0, 10)
	local centerTween = TweenService:Create(self.centerLabel,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, CENTER_SIZE, 0, CENTER_SIZE)}
	)
	centerTween:Play()
	
	print("[ToolRing] 🎯 Tool ring OPENED - Tools available for equipping")
end

function ToolRingGUI:hide()
	if not self.visible then return end
	
	self.visible = false
	
	-- Fast animate out
	for i, slotData in pairs(self.toolSlots) do
		local slot = slotData.frame
		local tween = TweenService:Create(slot,
			TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		tween:Play()
	end
	
	-- Animate center out
	local centerTween = TweenService:Create(self.centerLabel,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 0, 0, 0)}
	)
	centerTween:Play()
	
	-- Hide GUI after animation (shorter wait)
	task.wait(0.2)
	self.gui.Enabled = false
	
	print("[ToolRing] 🎯 Tool ring CLOSED")
end

function ToolRingGUI:toggle()
	if self.visible then
		self:hide()
	else
		self:show()
	end
end

function ToolRingGUI:isVisible()
	return self.visible
end

function ToolRingGUI:getSelectedTool()
	return self.tools[self.selectedSlot]
end

function ToolRingGUI:destroy()
	if self.gui then
		self.gui:Destroy()
		self.gui = nil
	end
end

-- Capitalized aliases for GUIManager compatibility
ToolRingGUI.Show = ToolRingGUI.show
ToolRingGUI.Hide = ToolRingGUI.hide
ToolRingGUI.Toggle = ToolRingGUI.toggle

return ToolRingGUI