--[[
    ChibiCharacter.luau

    Applies a cosy, Animal Crossing inspired look to the local player's avatar.
    The module re-scales the character with proper HumanoidDescription values
    and sets soft pastel body colours. It also exposes a style API that we can
    reuse for the upcoming avatar customiser.
]]

local Players = game:GetService("Players")

local CHIBI_SCALES = {
    BodyHeightScale = 0.85,
    BodyWidthScale = 0.95,
    BodyDepthScale = 0.9,
    HeadScale = 1.35,
    BodyTypeScale = 0,
    BodyProportionScale = 0.35,
}

local DEFAULT_STYLE = {
    bodyColors = {
        head = Color3.fromRGB(255, 228, 200),
        torso = Color3.fromRGB(255, 228, 200),
        leftArm = Color3.fromRGB(255, 228, 200),
        rightArm = Color3.fromRGB(255, 228, 200),
        leftLeg = Color3.fromRGB(92, 159, 115),
        rightLeg = Color3.fromRGB(92, 159, 115),
    },
    face = 0, -- keep the player's face by default
    shirt = 0,
    pants = 0,
    accessories = {},
}

local ChibiCharacter = {}
ChibiCharacter.__index = ChibiCharacter

local function setBodyColor(description, key, color)
    if not color then
        return
    end

    local brick = BrickColor.new(color)
    description[key] = brick
end

local function cloneStyle(style)
    if typeof(style) ~= "table" then
        return {}
    end

    local copy = {}
    for key, value in pairs(style) do
        if typeof(value) == "table" then
            copy[key] = cloneStyle(value)
        else
            copy[key] = value
        end
    end

    return copy
end

local function applyAccessoryPreset(humanoid, accessories)
    if typeof(accessories) ~= "table" then
        return
    end

    for _, accessoryId in ipairs(accessories) do
        if type(accessoryId) == "number" and accessoryId > 0 then
            -- Placeholder hook for future accessory loading logic.
            -- Actual accessory assets will be inserted by the avatar customiser.
            warn("[ChibiCharacter] Accessory preset", accessoryId, "not yet implemented")
        end
    end
end

function ChibiCharacter.new()
    local self = setmetatable({}, ChibiCharacter)

    self.player = Players.LocalPlayer
    self.style = cloneStyle(DEFAULT_STYLE)
    self.appliedCharacters = {}

    self:_setup()

    return self
end

function ChibiCharacter:setStyle(style)
    if typeof(style) ~= "table" then
        return
    end

    self.style = cloneStyle(style)

    if self.player.Character then
        self:applyToCharacter(self.player.Character)
    end
end

function ChibiCharacter:_setup()
    if self.player.Character then
        self:applyToCharacter(self.player.Character)
    end

    self.player.CharacterAdded:Connect(function(character)
        self:applyToCharacter(character)
    end)

    print("[ChibiCharacter] ✅ Chibi avatar system initialised")
end

function ChibiCharacter:applyToCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        warn("[ChibiCharacter] ⚠️ No humanoid found for chibi conversion")
        return
    end

    task.defer(function()
        self:_applyDescription(humanoid)
        self:_tuneCharacter(character, humanoid)
        self.appliedCharacters[character] = true
        print("[ChibiCharacter] ✨ Chibi makeover applied!")
    end)
end

function ChibiCharacter:_getHumanoidDescription()
    local description

    local success, result = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(self.player.UserId)
    end)

    if success and result then
        description = result
    end

    if not description then
        description = Instance.new("HumanoidDescription")
    end

    return description
end

function ChibiCharacter:_applyDescription(humanoid)
    local description = humanoid:GetAppliedDescription()
    if not description then
        description = self:_getHumanoidDescription()
    end

    for property, value in pairs(CHIBI_SCALES) do
        if description[property] ~= nil then
            description[property] = value
        end
    end

    local style = self.style or DEFAULT_STYLE

    if style.bodyColors then
        setBodyColor(description, "HeadColor", style.bodyColors.head)
        setBodyColor(description, "TorsoColor", style.bodyColors.torso)
        setBodyColor(description, "LeftArmColor", style.bodyColors.leftArm)
        setBodyColor(description, "RightArmColor", style.bodyColors.rightArm)
        setBodyColor(description, "LeftLegColor", style.bodyColors.leftLeg)
        setBodyColor(description, "RightLegColor", style.bodyColors.rightLeg)
    end

    if type(style.face) == "number" and style.face > 0 then
        description.Face = style.face
    end

    if type(style.shirt) == "number" then
        description.Shirt = style.shirt
    end

    if type(style.pants) == "number" then
        description.Pants = style.pants
    end

    humanoid:ApplyDescription(description)

    applyAccessoryPreset(humanoid, style.accessories)
end

function ChibiCharacter:_tuneCharacter(character, humanoid)
    humanoid.AutomaticScalingEnabled = false
    humanoid.HipHeight = 1.5

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Size = Vector3.new(2, 2, 1)
    end

    local cameraOffset = Vector3.new(0, -0.75, 0)
    humanoid.CameraOffset = cameraOffset

    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") and accessory.Handle then
            accessory.Handle.Massless = true
        end
    end
end

function ChibiCharacter:resetCharacter(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local description = self:_getHumanoidDescription()
    humanoid:ApplyDescription(description)
    humanoid.AutomaticScalingEnabled = true
    humanoid.HipHeight = 2
    self.appliedCharacters[character] = nil
end

return ChibiCharacter

