local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Data)
local Logger = require(ReplicatedStorage.Logger)

local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(remotes)
	local self = setmetatable({}, InventoryService)
	self._remotes = remotes
	self._inventories = {}

	self:_initialize()
	self:_setupInventoryRemotes()

	return self
end

function InventoryService:_initialize()
	Logger:Info("InventoryService", "Initializing")
	
	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		Logger:Info("InventoryService", "Player leaving - cleaning up inventory", { playerId = player.UserId })
		self._inventories[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end
end

function InventoryService:_initPlayer(player)
	if self._inventories[player] then
		return
	end

	Logger:Debug("InventoryService", "Initializing inventory for player", { playerId = player.UserId })
	
	self._inventories[player] = {
		items = {},
	}

	self:_pushUpdate(player)
end

function InventoryService:_pushUpdate(player)
	local inventory = self._inventories[player]
	if not inventory then
		Logger:Warn("InventoryService", "Attempted to push update for non-existent inventory", { playerId = player.UserId })
		return
	end

	local remote = self._remotes:Get("InventorySync")
	remote:FireClient(player, {
		items = inventory.items,
	})
end

local function normalizeAmount(amount)
	if not amount then
		return 0
	end
	return math.max(0, math.floor(amount))
end

function InventoryService:AddItem(playerOrUserId, itemId, amount)
	local player = playerOrUserId
	if typeof(playerOrUserId) == "number" then
		-- Find player by userId
		for p, _ in pairs(self._inventories) do
			if p.UserId == playerOrUserId then
				player = p
				break
			end
		end
	end
	
	local inventory = self._inventories[player]
	if not inventory then
		Logger:Warn("InventoryService", "Attempted to add item to non-existent inventory", { playerId = player and player.UserId or playerOrUserId, itemId = itemId })
		return
	end

	local itemDef = Data.Items[itemId] or (Data.GeneratedItems and Data.GeneratedItems[itemId])
	if not itemDef then
		Logger:Warn("InventoryService", "Unknown item attempted to be added", { itemId = itemId })
		return
	end

	local delta = normalizeAmount(amount)
	if delta <= 0 then
		return
	end

	local current = inventory.items[itemId] or 0
	inventory.items[itemId] = current + delta
	
	Logger:Debug("InventoryService", "Added item to inventory", { 
		playerId = player.UserId, 
		itemId = itemId, 
		amount = delta,
		newTotal = inventory.items[itemId]
	})
	
	self:_pushUpdate(player)
end

function InventoryService:RemoveItem(playerOrUserId, itemId, amount)
	local player = playerOrUserId
	if typeof(playerOrUserId) == "number" then
		-- Find player by userId
		for p, _ in pairs(self._inventories) do
			if p.UserId == playerOrUserId then
				player = p
				break
			end
		end
	end
	
	local inventory = self._inventories[player]
	if not inventory then
		return false
	end

	local delta = normalizeAmount(amount)
	if delta <= 0 then
		return false
	end

	local current = inventory.items[itemId] or 0
	if current < delta then
		return false
	end

	if current == delta then
		inventory.items[itemId] = nil
	else
		inventory.items[itemId] = current - delta
	end
	self:_pushUpdate(player)
	return true
end

function InventoryService:GetItemCount(playerOrUserId, itemId)
	local player = playerOrUserId
	if typeof(playerOrUserId) == "number" then
		-- Find player by userId
		for p, _ in pairs(self._inventories) do
			if p.UserId == playerOrUserId then
				player = p
				break
			end
		end
	end
	
	local inventory = self._inventories[player]
	if not inventory then
		return 0
	end
	
	return inventory.items[itemId] or 0
end

function InventoryService:HasItem(playerOrUserId, itemId, minAmount)
	minAmount = minAmount or 1
	return self:GetItemCount(playerOrUserId, itemId) >= minAmount
end

function InventoryService:GetSnapshot(playerOrUserId)
	local player = playerOrUserId
	if typeof(playerOrUserId) == "number" then
		-- Find player by userId
		for p, _ in pairs(self._inventories) do
			if p.UserId == playerOrUserId then
				player = p
				break
			end
		end
	end
	
        local inventory = self._inventories[player]
        if not inventory then
                return nil
        end

        local snapshot = {
                items = {},
        }

        for itemId, amount in pairs(inventory.items) do
                snapshot.items[itemId] = amount
        end

        return snapshot
end

-- Setup inventory remote handlers
function InventoryService:_setupInventoryRemotes()
	-- Get player inventory
	local getInventoryRemote = self._remotes:Get("GetPlayerInventory")
	if getInventoryRemote and getInventoryRemote:IsA("RemoteFunction") then
		getInventoryRemote.OnServerInvoke = function(player)
			return self:GetSnapshot(player.UserId)
		end
	end
	
	-- Get item info with emoji
	local getItemInfoRemote = self._remotes:Get("GetItemInfo")
	if getItemInfoRemote and getItemInfoRemote:IsA("RemoteFunction") then
		getItemInfoRemote.OnServerInvoke = function(player, itemName)
			local itemDB = _G.ItemDB
			if itemDB then
				return itemDB:GetItemWithEmoji(itemName)
			end
			return nil
		end
	end
end

function InventoryService:Destroy()
	self._inventories = {}
end

return InventoryService
