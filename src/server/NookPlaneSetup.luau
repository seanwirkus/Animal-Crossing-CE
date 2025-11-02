--[[
	NookPlaneSetup.luau
	Server-side script to setup NookPlane from existing StrcPlaneA00 model
	This script is required from init.server.luau
]]

print("[NookPlaneSetup] 🚀 NookPlaneSetup script starting...")

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Function to setup the plane model (using existing NookPlane)
local function setupPlane()
	-- Find NookPlane in workspace
	local nookPlane = Workspace:FindFirstChild("NookPlane")
	if not nookPlane then
		warn("[NookPlaneSetup] ❌ NookPlane not found in workspace!")
		warn("[NookPlaneSetup] ℹ️ Please ensure NookPlane model is in the workspace")
		return nil
	end

	print("[NookPlaneSetup] ✅ Found NookPlane in workspace")
	
	-- Check if already configured (has PlaneBody with physics)
	local planeBody = nookPlane:FindFirstChild("PlaneBody")
	if planeBody and planeBody:FindFirstChild("BodyVelocity") then
		print("[NookPlaneSetup] ✅ NookPlane already configured")
		return nookPlane
	end

	-- Find PlaneBody (required) - look for largest part or first BasePart
	local planeBody = nookPlane:FindFirstChild("PlaneBody")
	if not planeBody then
		print("[NookPlaneSetup] 🔍 PlaneBody not found by name, searching for largest part...")
		-- Try to find the largest part in the model
		local largestPart = nil
		local largestVolume = 0
		
		for _, descendant in pairs(nookPlane:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local volume = descendant.Size.X * descendant.Size.Y * descendant.Size.Z
				if volume > largestVolume then
					largestVolume = volume
					largestPart = descendant
				end
			end
		end
		
		if largestPart then
			planeBody = largestPart
			planeBody.Name = "PlaneBody"
			print("[NookPlaneSetup] ✅ Found largest part and renamed to PlaneBody:", planeBody.Name, "Volume:", largestVolume)
		else
			warn("[NookPlaneSetup] ❌ No parts found in model!")
			warn("[NookPlaneSetup] Descendants:", #nookPlane:GetDescendants())
			for _, child in pairs(nookPlane:GetChildren()) do
				warn("[NookPlaneSetup]   Child:", child.Name, "(" .. child.ClassName .. ")")
			end
			return nil
		end
	end

	-- Set as primary part
	nookPlane.PrimaryPart = planeBody
	print("[NookPlaneSetup] ✅ PlaneBody configured at:", planeBody.Position)

	-- Scale the plane to 0.75x
	local scaleFactor = 0.75
	local centerPos = planeBody.Position
	
	for _, descendant in pairs(nookPlane:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Scale size
			descendant.Size = descendant.Size * scaleFactor
			-- Scale position relative to center
			local offset = descendant.Position - centerPos
			descendant.Position = centerPos + (offset * scaleFactor)
		end
	end
	print("[NookPlaneSetup] ✅ Scaled plane to 75%")

	-- Check for Propeller (optional - logic disabled anyway)
	local propeller = nookPlane:FindFirstChild("Propeller")
	if propeller then
		print("[NookPlaneSetup] ✅ Found Propeller in model")
	else
		print("[NookPlaneSetup] ℹ️ No Propeller found (optional)")
	end

	-- Ensure all parts are unanchored for physics
	for _, descendant in pairs(nookPlane:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
		end
	end
	print("[NookPlaneSetup] ✅ All parts unanchored and can collide")

	-- Create interior seat part (where player will sit)
	local interiorSeat = Instance.new("Part")
	interiorSeat.Name = "InteriorSeat"
	interiorSeat.Size = Vector3.new(2, 1, 2)
	interiorSeat.Position = planeBody.Position + Vector3.new(0, 2, 0)
	interiorSeat.Anchored = false
	interiorSeat.CanCollide = false
	interiorSeat.Transparency = 1 -- Invisible
	interiorSeat.Parent = nookPlane

	-- Weld seat to plane body
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = planeBody
	seatWeld.Part1 = interiorSeat
	seatWeld.Parent = interiorSeat
	print("[NookPlaneSetup] ✅ Created interior seat")

	-- Add BodyVelocity for movement (will be used by client)
	local bodyVelocity = planeBody:FindFirstChild("BodyVelocity")
	if not bodyVelocity then
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "BodyVelocity"
		bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
		bodyVelocity.P = 1250
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = planeBody
		print("[NookPlaneSetup] ✅ Added BodyVelocity")
	end

	-- Add BodyAngularVelocity for rotation
	local bodyAngularVelocity = planeBody:FindFirstChild("BodyAngularVelocity")
	if not bodyAngularVelocity then
		bodyAngularVelocity = Instance.new("BodyAngularVelocity")
		bodyAngularVelocity.Name = "BodyAngularVelocity"
		bodyAngularVelocity.MaxTorque = Vector3.new(10000, 10000, 10000)
		bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
		bodyAngularVelocity.Parent = planeBody
		print("[NookPlaneSetup] ✅ Added BodyAngularVelocity")
	end
	
	-- Add BodyPosition for water floating (will be used by client)
	local bodyPosition = planeBody:FindFirstChild("BodyPosition")
	if not bodyPosition then
		bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "BodyPosition"
		bodyPosition.MaxForce = Vector3.new(0, 0, 0) -- Disabled by default, enabled when on water
		bodyPosition.P = 500
		bodyPosition.D = 100
		bodyPosition.Position = planeBody.Position
		bodyPosition.Parent = planeBody
		print("[NookPlaneSetup] ✅ Added BodyPosition for water floating")
	end

	-- Add a BillboardGui with label to make it easy to find
	local existingLabel = planeBody:FindFirstChild("PlaneLabel")
	if not existingLabel then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PlaneLabel"
		billboard.Size = UDim2.new(0, 250, 0, 60)
		billboard.StudsOffset = Vector3.new(0, 8, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = planeBody
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		label.BackgroundTransparency = 0.3
		label.BorderSizePixel = 0
		label.Text = "✈️ NOOK PLANE\n[E] Enter | [P] Exit"
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = billboard
		print("[NookPlaneSetup] ✅ Added plane label")
	end
	
	-- Add a subtle PointLight (much dimmer)
	local light = planeBody:FindFirstChild("PlaneLight")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "PlaneLight"
		light.Color = Color3.fromRGB(255, 240, 200)
		light.Brightness = 0.5 -- Much dimmer
		light.Range = 15 -- Smaller range
		light.Shadows = false
		light.Parent = planeBody
		print("[NookPlaneSetup] ✅ Added subtle plane light")
	end

	print("[NookPlaneSetup] ✅ NookPlane setup complete!")
	print("[NookPlaneSetup] 📍 Location:", planeBody.Position)
	print("[NookPlaneSetup] 🔍 Total parts:", #nookPlane:GetDescendants())
	
	return nookPlane
end

-- Setup the plane (with retry if model not loaded yet)
print("[NookPlaneSetup] 🛩️ Setting up NookPlane...")
task.spawn(function()
	-- Try up to 5 times with delays
	for attempt = 1, 5 do
		local plane = setupPlane()
		if plane then
			print("[NookPlaneSetup] ✅ NookPlane ready to fly!")
			return
		end
		
		if attempt < 5 then
			print("[NookPlaneSetup] ⏳ Attempt", attempt, "failed, retrying in 2 seconds...")
			task.wait(2)
		else
			warn("[NookPlaneSetup] ❌ Failed to setup plane after 5 attempts")
			warn("[NookPlaneSetup] ℹ️ Please ensure NookPlane model is in the workspace")
		end
	end
end)

