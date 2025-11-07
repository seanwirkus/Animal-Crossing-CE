--[[
    CurrencyDisplay.luau
    Client-side currency display using existing HudGUI StatsBar
    
    Uses existing GUI structure:
    HudGUI > StatsBar > BellsCount, MilesCount
    
    DEPENDS ON: CurrencyManager.luau (server)
    USED BY: init.client.luau
]]

local CurrencyDisplay = {}
CurrencyDisplay.__index = CurrencyDisplay

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for CurrencyEvent RemoteEvent
local currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")

-- Format number with commas (1000 -> "1,000")
local function formatNumber(num: number): string
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

function CurrencyDisplay.new()
	local self = setmetatable({}, CurrencyDisplay)
	
	self.player = Players.LocalPlayer
	self.hudGui = nil
	self.statsBar = nil
	self.bellsCount = nil
	self.milesCount = nil
	self.connections = {}
	
	self.currentBells = 0
	self.currentMiles = 0
	
	self:findGUI()
	self:connectToServer()
	
	print("[CurrencyDisplay] ✅ Initialized")
	return self
end

function CurrencyDisplay:findGUI()
	local playerGui = self.player:WaitForChild("PlayerGui")
	
	-- Find existing HudGUI
	self.hudGui = playerGui:WaitForChild("HudGUI", 5)
	if not self.hudGui then
		warn("[CurrencyDisplay] ❌ HudGUI not found!")
		return
	end
	print("[CurrencyDisplay] ✅ Found HudGUI")
	
	-- Find StatsBar
	self.statsBar = self.hudGui:FindFirstChild("StatsBar")
	if not self.statsBar then
		warn("[CurrencyDisplay] ❌ StatsBar not found in HudGUI!")
		print("[CurrencyDisplay] HudGUI children:", self.hudGui:GetChildren())
		return
	end
	print("[CurrencyDisplay] ✅ Found StatsBar")
	
	-- Find BellsCount Frame and BellsLabel inside it
	local bellsFrame = self.statsBar:FindFirstChild("BellsCount")
	if bellsFrame then
		self.bellsCount = bellsFrame:FindFirstChild("BellsLabel")
		if self.bellsCount then
			print("[CurrencyDisplay] ✅ Found BellsCount > BellsLabel")
		else
			warn("[CurrencyDisplay] ⚠️ BellsLabel not found inside BellsCount!")
			print("[CurrencyDisplay] BellsCount children:", bellsFrame:GetChildren())
		end
	else
		warn("[CurrencyDisplay] ⚠️ BellsCount frame not found in StatsBar!")
		print("[CurrencyDisplay] StatsBar children:", self.statsBar:GetChildren())
	end
	
	-- Find MilesCount Frame and MilesLabel inside it
	local milesFrame = self.statsBar:FindFirstChild("MilesCount")
	if milesFrame then
		self.milesCount = milesFrame:FindFirstChild("MilesLabel")
		if self.milesCount then
			print("[CurrencyDisplay] ✅ Found MilesCount > MilesLabel")
		else
			warn("[CurrencyDisplay] ⚠️ MilesLabel not found inside MilesCount!")
			print("[CurrencyDisplay] MilesCount children:", milesFrame:GetChildren())
		end
	else
		warn("[CurrencyDisplay] ⚠️ MilesCount frame not found in StatsBar!")
		print("[CurrencyDisplay] StatsBar children:", self.statsBar:GetChildren())
	end
	
	if self.bellsCount and self.milesCount then
		print("[CurrencyDisplay] ✅ Both labels found - ready to update!")
	end
end

function CurrencyDisplay:updateBells(amount: number)
	self.currentBells = amount
	
	if self.bellsCount then
		self.bellsCount.Text = formatNumber(amount)
		
		-- Pulse animation
		if self.bellsCount:FindFirstChildOfClass("UIScale") then
			local scale = self.bellsCount:FindFirstChildOfClass("UIScale")
			local tween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1.1
			})
			tween:Play()
			tween.Completed:Connect(function()
				local shrink = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Scale = 1
				})
				shrink:Play()
			end)
		end
	end
end

function CurrencyDisplay:updateMiles(amount: number)
	self.currentMiles = amount
	
	if self.milesCount then
		self.milesCount.Text = formatNumber(amount)
		
		-- Pulse animation
		if self.milesCount:FindFirstChildOfClass("UIScale") then
			local scale = self.milesCount:FindFirstChildOfClass("UIScale")
			local tween = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = 1.1
			})
			tween:Play()
			tween.Completed:Connect(function()
				local shrink = TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Scale = 1
				})
				shrink:Play()
			end)
		end
	end
end

function CurrencyDisplay:connectToServer()
	-- Listen for currency updates from server
	local connection = currencyRemote.OnClientEvent:Connect(function(action, data)
		print("[CurrencyDisplay] 📨 Received event - Action:", action, "Data:", data)
		
		if action == "UpdateBells" then
			self:updateBells(data.bells)
			print("[CurrencyDisplay] 💰 Bells updated:", data.bells)
		elseif action == "UpdateMiles" then
			self:updateMiles(data.miles)
			print("[CurrencyDisplay] ✈️ Miles updated:", data.miles)
		elseif action == "UpdateAll" then
			self:updateBells(data.bells)
			self:updateMiles(data.miles)
			print("[CurrencyDisplay] 💰✈️ Currency updated - Bells:", data.bells, "Miles:", data.miles)
		end
	end)
	
	table.insert(self.connections, connection)
	
	-- Request initial currency from server
	print("[CurrencyDisplay] 📤 Requesting initial currency from server...")
	currencyRemote:FireServer("GetCurrency")
end

function CurrencyDisplay:destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}
end

return CurrencyDisplay
