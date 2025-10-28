-- Inventory Controller
-- Controller for the imported InventoryGUI.rbxmx
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local InventoryController = {}

function InventoryController.new(gui)
	local self = setmetatable({}, InventoryController)
	
	self._gui = gui
	self._visible = false
	self._inventoryData = {}
	self._itemSlots = {}
	
	self:_initialize()
	
	return self
end

function InventoryController:_initialize()
	if not self._gui then
		warn("[InventoryController] No GUI provided!")
		return
	end
	
	-- Initially hide the GUI
	self._gui.Enabled = false
	
	-- Connect to inventory updates
	self:_setupInventorySync()
	
	-- Setup item slots
	self:_setupItemSlots()
	
	print("[InventoryController] ✅ Connected to", self._gui.Name)
end

-- Input handling is now done by UIController

function InventoryController:_setupInventorySync()
	-- Connect to inventory sync remote
	local inventorySyncRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("InventorySync")
	if inventorySyncRemote then
		inventorySyncRemote.OnClientEvent:Connect(function(inventoryData)
			self:_updateInventory(inventoryData)
		end)
	end
end

function InventoryController:_setupItemSlots()
	-- Find all item slots in the GUI
	self._itemSlots = {}
	
	-- Find InventoryRow3 and InventoryRow2
	local row3 = self._gui:FindFirstChild("InventoryRow3")
	local row2 = self._gui:FindFirstChild("InventoryRow2")
	
	if row3 then
		self:_setupRowSlots(row3)
	end
	
	if row2 then
		self:_setupRowSlots(row2)
	end
	
	print("[InventoryController] Found " .. #self._itemSlots .. " item slots")
end

function InventoryController:_setupRowSlots(row)
	-- Find all Items frames in this row
	for _, child in pairs(row:GetChildren()) do
		if child.Name == "Items" and child:IsA("Frame") then
			self:_setupItemSlot(child)
			table.insert(self._itemSlots, child)
		end
	end
end

function InventoryController:_setupItemSlot(slot)
	-- Find the Empty frame inside this slot
	local emptyItem = slot:FindFirstChild("Empty")
	if not emptyItem then
		warn("[InventoryController] Empty frame not found in item slot")
		return
	end
	
	-- Store reference to the empty item
	slot._emptyItem = emptyItem
	slot._itemData = nil
	
	-- Add click handler
	local clickDetector = Instance.new("TextButton")
	clickDetector.Size = UDim2.new(1, 0, 1, 0)
	clickDetector.BackgroundTransparency = 1
	clickDetector.Text = ""
	clickDetector.Parent = slot
	
	clickDetector.MouseButton1Click:Connect(function()
		self:_onItemSlotClicked(slot)
	end)
	
	-- Add hover effects
	clickDetector.MouseEnter:Connect(function()
		if slot._itemData then
			emptyItem.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
		end
	end)
	
	clickDetector.MouseLeave:Connect(function()
		if slot._itemData then
			emptyItem.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
		end
	end)
end

function InventoryController:_updateInventory(inventoryData)
	self._inventoryData = inventoryData or {}
	
	-- Clear all slots first
	for _, slot in pairs(self._itemSlots) do
		self:_clearItemSlot(slot)
	end
	
	-- Populate slots with items
	local slotIndex = 1
	for itemId, quantity in pairs(self._inventoryData.items or {}) do
		if quantity > 0 and slotIndex <= #self._itemSlots then
			self:_setItemSlot(self._itemSlots[slotIndex], itemId, quantity)
			slotIndex = slotIndex + 1
		end
	end
	
	print("[InventoryController] Updated inventory with " .. (slotIndex - 1) .. " items")
end

function InventoryController:_setItemSlot(slot, itemId, quantity)
	-- Get item info from server
	local getItemInfoRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("GetItemInfo")
	if getItemInfoRemote then
		local itemData = getItemInfoRemote:InvokeServer(itemId)
		if itemData then
			slot._itemData = {
				id = itemId,
				quantity = quantity,
				name = itemData.name,
				emoji = itemData.emoji,
				description = itemData.description,
				sellPrice = itemData.sell_price
			}
			
			-- Update the visual representation
			slot._emptyItem.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			
			-- Add emoji text
			if not slot._emojiLabel then
				slot._emojiLabel = Instance.new("TextLabel")
				slot._emojiLabel.Size = UDim2.new(1, 0, 0.6, 0)
				slot._emojiLabel.Position = UDim2.new(0, 0, 0, 0)
				slot._emojiLabel.BackgroundTransparency = 1
				slot._emojiLabel.TextSize = 32
				slot._emojiLabel.Font = Enum.Font.GothamBold
				slot._emojiLabel.Parent = slot
			end
			slot._emojiLabel.Text = itemData.emoji or "📦"
			
			-- Add quantity text
			if not slot._quantityLabel then
				slot._quantityLabel = Instance.new("TextLabel")
				slot._quantityLabel.Size = UDim2.new(0, 30, 0, 20)
				slot._quantityLabel.Position = UDim2.new(1, -35, 1, -25)
				slot._quantityLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
				slot._quantityLabel.TextSize = 14
				slot._quantityLabel.Font = Enum.Font.GothamBold
				slot._quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				slot._quantityLabel.Parent = slot
				
				local quantityCorner = Instance.new("UICorner")
				quantityCorner.CornerRadius = UDim.new(0.3, 0)
				quantityCorner.Parent = slot._quantityLabel
			end
			slot._quantityLabel.Text = "x" .. quantity
			slot._quantityLabel.Visible = quantity > 1
		end
	end
end

function InventoryController:_clearItemSlot(slot)
	slot._itemData = nil
	slot._emptyItem.BackgroundColor3 = Color3.fromRGB(238, 226, 204)
	
	if slot._emojiLabel then
		slot._emojiLabel.Text = ""
	end
	
	if slot._quantityLabel then
		slot._quantityLabel.Visible = false
	end
end

function InventoryController:_onItemSlotClicked(slot)
	if not slot._itemData then return end
	
	-- Show item details
	print("[InventoryController] Selected item:", slot._itemData.name, "x" .. slot._itemData.quantity)
	
	-- You can add more item interaction logic here
end

function InventoryController:Show()
	if not self._gui then return end
	
	self._gui.Enabled = true
	self._visible = true
	
	-- Refresh inventory data
	self:_refreshInventory()
	
	print("[InventoryController] Inventory opened")
end

function InventoryController:Hide()
	if not self._gui then return end
	
	self._gui.Enabled = false
	self._visible = false
	
	print("[InventoryController] Inventory closed")
end

function InventoryController:Toggle()
	if self._visible then
		self:Hide()
	else
		self:Show()
	end
end

function InventoryController:_refreshInventory()
	-- Get fresh inventory data from server
	local getInventoryRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("GetPlayerInventory")
	if getInventoryRemote then
		local inventoryData = getInventoryRemote:InvokeServer()
		if inventoryData then
			self:_updateInventory(inventoryData)
		end
	end
end

return InventoryController
