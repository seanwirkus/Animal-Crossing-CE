--[[
	ShovelClient.luau
	
	Client-side shovel handling:
	- Detects when player uses shovel
	- Sends dig request to server
	- Shows visual feedback
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ShovelClient = {}

local function onToolActivated(tool)
	-- Check if it's a shovel
	if not tool.Name:lower():find("shovel") then
		return
	end
	
	print("[ShovelClient] Shovel activated!")
	
	-- Send dig request to server
	local shovelEvent = ReplicatedStorage:WaitForChild("ShovelDig", 5)
	if shovelEvent then
		shovelEvent:FireServer()
	end
end

function ShovelClient.init()
	print("[ShovelClient] 🔨 Initializing shovel client...")
	
	local player = Players.LocalPlayer
	
	-- Listen for dig results from server
	local shovelEvent = ReplicatedStorage:WaitForChild("ShovelDig", 5)
	if shovelEvent then
		shovelEvent.OnClientEvent:Connect(function(itemId, amount)
			print("[ShovelClient] Dug up", amount, "x", itemId, "!")
			
			-- You can add visual effects here like:
			-- - Particle effect at dig location
			-- - Sound effect
			-- - Item popup notification
		end)
	end
	
	-- Monitor when player equips tools
	local function onCharacterAdded(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				child.Activated:Connect(function()
					onToolActivated(child)
				end)
			end
		end)
		
		-- Check already equipped tools
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				child.Activated:Connect(function()
					onToolActivated(child)
				end)
			end
		end
	end
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	
	print("[ShovelClient] ✅ Shovel client initialized")
end

return ShovelClient
