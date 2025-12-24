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

	local model = Instance.new("Model")
	model.Name = "TentTemplate"

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 0.6, 8)
	base.Anchored = anchored
	base.Material = Enum.Material.Wood
	base.Color = Color3.fromRGB(155, 110, 80)
	base.Transparency = transparency
	base.Parent = model

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(7.5, 0.25, 7.5)
	floor.Anchored = anchored
	floor.Material = Enum.Material.Wood
	floor.Color = Color3.fromRGB(184, 140, 104)
	floor.CFrame = base.CFrame + Vector3.new(0, 0.425, 0)
	floor.Transparency = transparency
	floor.Parent = model

	local leftWall = Instance.new("WedgePart")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(7.5, 4.5, 4)
	leftWall.Anchored = anchored
	leftWall.Material = material
	leftWall.Color = color
	leftWall.CFrame = floor.CFrame * CFrame.new(0, 2.25, -1.75) * CFrame.Angles(0, math.rad(180), 0)
	leftWall.Transparency = transparency
	leftWall.Parent = model

	local rightWall = Instance.new("WedgePart")
	rightWall.Name = "RightWall"
	rightWall.Size = Vector3.new(7.5, 4.5, 4)
	rightWall.Anchored = anchored
	rightWall.Material = material
	rightWall.Color = color
	rightWall.CFrame = floor.CFrame * CFrame.new(0, 2.25, 1.75)
	rightWall.Transparency = transparency
	rightWall.Parent = model

	local backPanel = Instance.new("Part")
	backPanel.Name = "BackPanel"
	backPanel.Size = Vector3.new(7.5, 4.5, 0.3)
	backPanel.Anchored = anchored
	backPanel.Material = material
	backPanel.Color = color
	backPanel.CFrame = floor.CFrame * CFrame.new(0, 2.25, -3.7)
	backPanel.Transparency = transparency
	backPanel.Parent = model

	local frontPanel = Instance.new("Part")
	frontPanel.Name = "FrontPanel"
	frontPanel.Size = Vector3.new(7.5, 4.5, 0.3)
	frontPanel.Anchored = anchored
	frontPanel.Material = material
	frontPanel.Color = color
	frontPanel.CFrame = floor.CFrame * CFrame.new(0, 2.25, 3.7)
	frontPanel.Transparency = transparency
	frontPanel.Parent = model

	local doorway = Instance.new("Part")
	doorway.Name = "Doorway"
	doorway.Size = Vector3.new(2.5, 3, 0.35)
	doorway.Anchored = anchored
	doorway.Material = Enum.Material.Wood
	doorway.Color = Color3.fromRGB(210, 160, 120)
	doorway.CFrame = frontPanel.CFrame * CFrame.new(0, -0.25, 0)
	doorway.Transparency = transparency
	doorway.Parent = model

	local ridgePole = Instance.new("Part")
	ridgePole.Name = "RidgePole"
	ridgePole.Size = Vector3.new(7.5, 0.35, 0.35)
	ridgePole.Anchored = anchored
	ridgePole.Material = Enum.Material.WoodPlanks
	ridgePole.Color = Color3.fromRGB(120, 84, 66)
	ridgePole.CFrame = floor.CFrame * CFrame.new(0, 4.5, 0)
	ridgePole.Transparency = transparency
	ridgePole.Parent = model

	local ropeFront = Instance.new("Part")
	ropeFront.Name = "RopeFront"
	ropeFront.Size = Vector3.new(0.15, 4, 0.15)
	ropeFront.Anchored = anchored
	ropeFront.Material = Enum.Material.Fabric
	ropeFront.Color = Color3.fromRGB(196, 166, 120)
	ropeFront.CFrame = ridgePole.CFrame * CFrame.new(0, -2, 3.5)
	ropeFront.Transparency = transparency
	ropeFront.Parent = model

	local ropeBack = ropeFront:Clone()
	ropeBack.Name = "RopeBack"
	ropeBack.CFrame = ridgePole.CFrame * CFrame.new(0, -2, -3.5)
	ropeBack.Parent = model

	model.PrimaryPart = model.PrimaryPart or base
	model:SetAttribute("TemplateType", "Tent")

	return model
end

return HomeTemplates
