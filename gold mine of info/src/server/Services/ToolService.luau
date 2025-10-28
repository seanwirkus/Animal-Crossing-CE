--[[
	ToolService - Handles tool usage and routing to appropriate handlers
	Routes tool interactions to TreeService, ResourceService, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Logger)

local ToolService = {}
ToolService.__index = ToolService

-- Tool categories and their handlers
local TOOL_CONFIGS = {
	-- Axes
	tool_flimsy_axe = { type = "axe", resource = "Tree" },
	tool_axe = { type = "axe", resource = "Tree" },
	tool_stone_axe = { type = "axe", resource = "Tree" },
	
	-- Shovels
	tool_shovel_basic = { type = "shovel", resource = "Rock" },
	tool_shovel = { type = "shovel", resource = "Rock" },
	
	-- Fishing rods
	tool_fishing_rod_basic = { type = "fishing_rod", resource = "Water" },
	tool_fishing_rod = { type = "fishing_rod", resource = "Water" },
	
	-- Bug nets
	tool_bug_net_basic = { type = "bug_net", resource = "Bug" },
	tool_bug_net = { type = "bug_net", resource = "Bug" },
	
	-- Watering can
	tool_watering_can_basic = { type = "watering_can", resource = "Plant" },
	tool_watering_can = { type = "watering_can", resource = "Plant" },
}

function ToolService.new(remotes, treeService, resourceService)
	local self = setmetatable({}, ToolService)
	self._remotes = remotes
	self._treeService = treeService
	self._resourceService = resourceService
	self._cooldowns = {}  -- Track tool use cooldowns per player
	
	self:_setupRemotes()
	Logger:Info("ToolService", "Initializing tool usage system")
	
	return self
end

function ToolService:_setupRemotes()
	local useToolRemote = self._remotes:Get("UseTool")
	if useToolRemote then
		useToolRemote.OnServerEvent:Connect(function(player, toolId, position, targetInstance)
			self:HandleToolUse(player, toolId, position, targetInstance)
		end)
	end
end

--[[
	Route tool usage to appropriate handler
]]
function ToolService:HandleToolUse(player, toolId, position, targetInstance)
	if not toolId or not targetInstance then
		Logger:Warn("ToolService", "Invalid tool use data", { toolId = toolId, hasTarget = targetInstance ~= nil })
		return
	end
	
	-- Check cooldown (prevent spam)
	local cooldownKey = player.UserId .. "_" .. toolId
	if self._cooldowns[cooldownKey] and (tick() - self._cooldowns[cooldownKey]) < 0.5 then
		return  -- Still in cooldown
	end
	self._cooldowns[cooldownKey] = tick()
	
	local toolConfig = TOOL_CONFIGS[toolId]
	if not toolConfig then
		Logger:Warn("ToolService", "Unknown tool", { toolId = toolId })
		return
	end
	
	Logger:Debug("ToolService", "Tool used", { 
		playerId = player.UserId, 
		toolId = toolId, 
		targetName = targetInstance.Name,
		toolType = toolConfig.type
	})
	
	-- Route to appropriate handler based on target
	local targetType = targetInstance:GetAttribute("HarvestType") or targetInstance.Parent and targetInstance.Parent:GetAttribute("HarvestType")
	
	if targetType == "Tree" and self._treeService then
		self:_handleTreeInteraction(player, toolId, toolConfig, targetInstance)
	elseif targetType == "Rock" and self._resourceService then
		self:_handleRockInteraction(player, toolId, toolConfig, targetInstance)
	elseif targetType == "Water" and self._resourceService then
		self:_handleFishingInteraction(player, toolId, toolConfig, position)
	elseif targetType == "Bug" and self._resourceService then
		self:_handleBugCatchingInteraction(player, toolId, toolConfig, position)
	else
		Logger:Debug("ToolService", "No handler for target type", { targetType = targetType, toolType = toolConfig.type })
	end
end

function ToolService:_handleTreeInteraction(player, toolId, toolConfig, treeModel)
	if toolConfig.type == "axe" then
		-- Chop the tree
		if self._treeService and self._treeService.ChopTree then
			self._treeService:ChopTree(player, treeModel)
			Logger:Debug("ToolService", "Tree chop triggered", { playerId = player.UserId })
		end
	else
		-- Shake the tree (hands or wrong tool)
		if self._treeService and self._treeService.ShakeTree then
			self._treeService:ShakeTree(player, treeModel)
			Logger:Debug("ToolService", "Tree shake triggered", { playerId = player.UserId })
		end
	end
end

function ToolService:_handleRockInteraction(player, toolId, toolConfig, rockModel)
	if toolConfig.type == "shovel" then
		-- Dig the rock
		if self._resourceService and self._resourceService.DiggingStart then
			self._resourceService:DiggingStart(player, rockModel)
			Logger:Debug("ToolService", "Rock dig triggered", { playerId = player.UserId })
		end
	end
end

function ToolService:_handleFishingInteraction(player, toolId, toolConfig, position)
	if toolConfig.type == "fishing_rod" then
		-- Cast fishing line
		if self._resourceService and self._resourceService.CastLine then
			self._resourceService:CastLine(player, position)
			Logger:Debug("ToolService", "Fishing cast triggered", { playerId = player.UserId })
		end
	end
end

function ToolService:_handleBugCatchingInteraction(player, toolId, toolConfig, position)
	if toolConfig.type == "bug_net" then
		-- Swing net
		if self._resourceService and self._resourceService.SwingNet then
			self._resourceService:SwingNet(player, position)
			Logger:Debug("ToolService", "Bug net swing triggered", { playerId = player.UserId })
		end
	end
end

function ToolService:Destroy()
	Logger:Info("ToolService", "Destroying")
	self._cooldowns = {}
end

return ToolService
