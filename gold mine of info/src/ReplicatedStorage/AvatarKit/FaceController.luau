local FaceController = {}

local RunService = game:GetService("RunService")
local ChatService = game:GetService("Chat")

local function getFaceSlot(head: BasePart, name: string): ImageLabel?
	local faceGui = head:FindFirstChild("FaceGui")
	if not faceGui or not faceGui:IsA("SurfaceGui") then
		return nil
	end
	local slot = faceGui:FindFirstChild(name)
	if slot and slot:IsA("ImageLabel") then
		return slot
	end
	return nil
end

function FaceController.attach(character: Model)
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local eyes = getFaceSlot(head, "Eyes")
	local mouth = getFaceSlot(head, "Mouth")

	if eyes then
		local openSize = eyes.Size
		local blinkSize = UDim2.fromOffset(openSize.X.Offset, math.max(4, math.floor(openSize.Y.Offset * 0.12)))

		task.spawn(function()
			while character.Parent and eyes.Parent do
				task.wait(math.random(2, 5))
				if not (character.Parent and eyes.Parent) then
					break
				end

				eyes.Size = blinkSize
				task.wait(0.08)
				if eyes.Parent then
					eyes.Size = openSize
				end
			end
		end)
	end

	if mouth then
		ChatService.Chatted:Connect(function(player, message)
			if not character.Parent then
				return
			end
			local accumulated = 0
			local startPosition = mouth.Position
			local connection
			connection = RunService.Heartbeat:Connect(function(dt)
				accumulated += dt
				if accumulated >= 0.75 or not mouth.Parent then
					if connection then
						connection:Disconnect()
					end
					if mouth.Parent then
						mouth.Rotation = 0
						mouth.Position = startPosition
					end
					return
				end

				local wobble = math.sin(accumulated * 24)
				mouth.Rotation = wobble * 3
				mouth.Position = startPosition + UDim2.fromOffset(0, wobble * 2)
			end)
		end)
	end
end

return FaceController
