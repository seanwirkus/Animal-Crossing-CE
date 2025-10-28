--[[
	EconomyService - Manages player economy (bells, miles, etc.)
	Handles currency transactions and economic systems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Logger)

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new()
	local self = setmetatable({}, EconomyService)
	
	self._playerBalances = {}
	
	self:_initialize()
	
	return self
end

function EconomyService:_initialize()
	Logger:Info("EconomyService", "Initializing economy system")
	
	-- Connect to player events
	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self._playerBalances[player] = nil
	end)
	
	-- Initialize existing players
	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end
end

function EconomyService:_initPlayer(player)
	if self._playerBalances[player] then
		return
	end
	
	Logger:Debug("EconomyService", "Initializing economy for player", { playerId = player.UserId })
	
	self._playerBalances[player] = {
		bells = 1000, -- Starting bells
		miles = 500,  -- Starting miles
	}
	
	-- Fire update to client
	self:_updatePlayerBalance(player)
end

function EconomyService:_updatePlayerBalance(player)
	local balance = self._playerBalances[player]
	if not balance then return end
	
	-- Fire remote event to update client
	local updateBalanceRemote = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("UpdateBalance")
	if updateBalanceRemote then
		updateBalanceRemote:FireClient(player, balance)
	end
end

function EconomyService:GetBalance(player, currency)
	local balance = self._playerBalances[player]
	if not balance then return 0 end
	
	return balance[currency] or 0
end

function EconomyService:AddCurrency(player, currency, amount)
	local balance = self._playerBalances[player]
	if not balance then return false end
	
	balance[currency] = (balance[currency] or 0) + amount
	self:_updatePlayerBalance(player)
	
	Logger:Debug("EconomyService", "Added currency", { 
		playerId = player.UserId, 
		currency = currency, 
		amount = amount,
		newBalance = balance[currency]
	})
	
	return true
end

function EconomyService:RemoveCurrency(player, currency, amount)
	local balance = self._playerBalances[player]
	if not balance then return false end
	
	local current = balance[currency] or 0
	if current < amount then return false end
	
	balance[currency] = current - amount
	self:_updatePlayerBalance(player)
	
	Logger:Debug("EconomyService", "Removed currency", { 
		playerId = player.UserId, 
		currency = currency, 
		amount = amount,
		newBalance = balance[currency]
	})
	
	return true
end

function EconomyService:OnStart()
	Logger:Info("EconomyService", "Economy system started")
end

return EconomyService
