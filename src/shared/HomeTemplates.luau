-- HomeTemplates.luau
-- Creates lightweight, in-game friendly home models without external 3D asset dependencies.

local HomeTemplates = {}

export type TentOptions = {
	anchored: boolean?,
	transparency: number?,
	materialOverride: Enum.Material?,
	colorOverride: Color3?,
}

-- Construct a simple tent using primitive parts so we never rely on imported OBJ meshes.
function HomeTemplates.createTentTemplate(options: TentOptions?)
	local config = options or {}
	local anchored = config.anchored ~= false
	local transparency = config.transparency or 0
	local material = config.materialOverride or Enum.Material.Fabric
	local color = config.colorOverride or Color3.fromRGB(241, 179, 105)
	local scale = 3

	local function s(value)
		return value * scale
	end

	local function v(x, y, z)
		return Vector3.new(s(x), s(y), s(z))
	end

	local model = Instance.new("Model")
	model.Name = "TentTemplate"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = v(8, 0.6, 8)
	base.Anchored = anchored
	base.CanCollide = true
	base.Material = Enum.Material.Wood
	base.Color = Color3.fromRGB(155, 110, 80)
	base.Transparency = transparency
	base.Parent = model

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = v(7.5, 0.25, 7.5)
	floor.Anchored = anchored
	floor.CanCollide = true
	floor.Material = Enum.Material.Wood
	floor.Color = Color3.fromRGB(184, 140, 104)
	floor.CFrame = base.CFrame + Vector3.new(0, (base.Size.Y / 2) + (floor.Size.Y / 2), 0)
	floor.Transparency = transparency
	floor.Parent = model

	local wallHeight = s(4.5)
	local wallYOffset = (floor.Size.Y / 2) + (wallHeight / 2)
	local floorWidth = floor.Size.X
	local floorDepth = floor.Size.Z
	local wedgeWidth = base.Size.X / 2

	local leftWall = Instance.new("WedgePart")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(floorDepth, wallHeight, wedgeWidth)
	leftWall.Anchored = anchored
	leftWall.CanCollide = false
	leftWall.Material = material
	leftWall.Color = color
	leftWall.CFrame = floor.CFrame * CFrame.new(-wedgeWidth / 2, wallYOffset, 0) * CFrame.Angles(0, math.rad(90), 0)
	leftWall.Transparency = transparency
	leftWall.Parent = model

	local rightWall = Instance.new("WedgePart")
	rightWall.Name = "RightWall"
	rightWall.Size = Vector3.new(floorDepth, wallHeight, wedgeWidth)
	rightWall.Anchored = anchored
	rightWall.CanCollide = false
	rightWall.Material = material
	rightWall.Color = color
	rightWall.CFrame = floor.CFrame * CFrame.new(wedgeWidth / 2, wallYOffset, 0) * CFrame.Angles(0, math.rad(-90), 0)
	rightWall.Transparency = transparency
	rightWall.Parent = model

	local backPanel = Instance.new("Part")
	backPanel.Name = "BackPanel"
	local panelThickness = s(0.3)
	backPanel.Size = Vector3.new(floorWidth, wallHeight, panelThickness)
	backPanel.Anchored = anchored
	backPanel.CanCollide = true
	backPanel.Material = material
	backPanel.Color = color
	local panelZ = (floorDepth / 2) - (panelThickness / 2)
	backPanel.CFrame = floor.CFrame * CFrame.new(0, wallYOffset, -panelZ)
	backPanel.Transparency = transparency
	backPanel.Parent = model

	local doorWidth = s(2.5)
	local doorHeight = s(3)
	local frontPanelWidth = math.max(0.1, (floorWidth - doorWidth) / 2)

	local frontLeft = Instance.new("Part")
	frontLeft.Name = "FrontPanelLeft"
	frontLeft.Size = Vector3.new(frontPanelWidth, wallHeight, panelThickness)
	frontLeft.Anchored = anchored
	frontLeft.CanCollide = true
	frontLeft.Material = material
	frontLeft.Color = color
	frontLeft.CFrame = floor.CFrame * CFrame.new(-(doorWidth / 2 + frontPanelWidth / 2), wallYOffset, panelZ)
	frontLeft.Transparency = transparency
	frontLeft.Parent = model

	local frontRight = Instance.new("Part")
	frontRight.Name = "FrontPanelRight"
	frontRight.Size = Vector3.new(frontPanelWidth, wallHeight, panelThickness)
	frontRight.Anchored = anchored
	frontRight.CanCollide = true
	frontRight.Material = material
	frontRight.Color = color
	frontRight.CFrame = floor.CFrame * CFrame.new(doorWidth / 2 + frontPanelWidth / 2, wallYOffset, panelZ)
	frontRight.Transparency = transparency
	frontRight.Parent = model

	local doorFlap = Instance.new("Part")
	doorFlap.Name = "DoorFlap"
	doorFlap.Size = Vector3.new(doorWidth, doorHeight, panelThickness / 2)
	doorFlap.Anchored = anchored
	doorFlap.CanCollide = false
	doorFlap.Material = Enum.Material.Fabric
	doorFlap.Color = Color3.fromRGB(210, 160, 120)
	doorFlap.CFrame = floor.CFrame * CFrame.new(0, (floor.Size.Y / 2) + (doorHeight / 2) - s(0.2), panelZ + panelThickness / 2)
	doorFlap.Transparency = transparency
	doorFlap.Parent = model

	local ridgePole = Instance.new("Part")
	ridgePole.Name = "RidgePole"
	ridgePole.Size = Vector3.new(s(0.35), s(0.35), floorDepth)
	ridgePole.Anchored = anchored
	ridgePole.CanCollide = false
	ridgePole.Material = Enum.Material.WoodPlanks
	ridgePole.Color = Color3.fromRGB(120, 84, 66)
	ridgePole.CFrame = floor.CFrame * CFrame.new(0, (floor.Size.Y / 2) + wallHeight, 0)
	ridgePole.Transparency = transparency
	ridgePole.Parent = model

	local centerPole = Instance.new("Part")
	centerPole.Name = "CenterPole"
	centerPole.Size = Vector3.new(s(0.4), wallHeight, s(0.4))
	centerPole.Anchored = anchored
	centerPole.CanCollide = false
	centerPole.Material = Enum.Material.WoodPlanks
	centerPole.Color = Color3.fromRGB(110, 76, 58)
	centerPole.CFrame = floor.CFrame * CFrame.new(0, wallYOffset, 0)
	centerPole.Transparency = transparency
	centerPole.Parent = model

	local ropeFront = Instance.new("Part")
	ropeFront.Name = "RopeFront"
	ropeFront.Size = Vector3.new(s(0.15), wallHeight - s(0.5), s(0.15))
	ropeFront.Anchored = anchored
	ropeFront.CanCollide = false
	ropeFront.Material = Enum.Material.Fabric
	ropeFront.Color = Color3.fromRGB(196, 166, 120)
	ropeFront.CFrame = ridgePole.CFrame * CFrame.new(0, -(ropeFront.Size.Y / 2), panelZ)
	ropeFront.Transparency = transparency
	ropeFront.Parent = model

	local ropeBack = ropeFront:Clone()
	ropeBack.Name = "RopeBack"
	ropeBack.CFrame = ridgePole.CFrame * CFrame.new(0, -(ropeBack.Size.Y / 2), -panelZ)
	ropeBack.Parent = model

	model.PrimaryPart = model.PrimaryPart or base
	model:SetAttribute("TemplateType", "Tent")

	return model
end

return HomeTemplates
