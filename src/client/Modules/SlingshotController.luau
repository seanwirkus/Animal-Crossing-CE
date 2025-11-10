local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Get ToolObjects module
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ToolObjects = require(Shared:WaitForChild("ToolObjects"))

local SlingshotController = {}
SlingshotController.__index = SlingshotController

function SlingshotController.new()
    local self = setmetatable({}, SlingshotController)
    
    self.player = Players.LocalPlayer
    self.mouse = self.player:GetMouse()
    self.equippedTool = nil
    self.isAiming = false
    self.lastShootTime = 0
    self.shootCooldown = 0.3 -- 300ms cooldown between shots
    
    -- Connect to tool equipped/unequipped
    self.player.CharacterAdded:Connect(function(character)
        self:onCharacterAdded(character)
    end)
    
    if self.player.Character then
        self:onCharacterAdded(self.player.Character)
    end
    
    -- Use mouse input instead of Tool.Activated to prevent sitting bug
    self.mouseConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.equippedTool then
                self:onShoot()
            end
        end
    end)
    
    print("[SlingshotController] ✅ Initialized")
    return self
end

function SlingshotController:onCharacterAdded(character)
    -- Monitor when tools are equipped (when they become a child of character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            self:onToolEquipped(child)
        end
    end)
    
    -- Monitor when tools are unequipped (removed from character)
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            self:onToolUnequipped(child)
        end
    end)
end

function SlingshotController:onToolEquipped(tool)
    -- Check if it's a slingshot
    local toolType = tool:GetAttribute("ToolType")
    if toolType and string.find(string.lower(tostring(toolType)), "slingshot") then
        self.equippedTool = tool
        self.isAiming = false
        print("[SlingshotController] 🎯 Slingshot equipped:", tool.Name)
        
        -- Configure tool to prevent sitting
        tool.ManualActivationOnly = true
        tool.CanBeDropped = false
    end
end

function SlingshotController:onToolUnequipped(tool)
    if self.equippedTool == tool then
        self.equippedTool = nil
        self.isAiming = false
        print("[SlingshotController] Slingshot unequipped")
    end
end

function SlingshotController:onShoot()
    if not self.equippedTool then
        return
    end
    
    if UserInputService:GetFocusedTextBox() then
        return
    end
    
    -- Check cooldown
    local currentTime = tick()
    if currentTime - self.lastShootTime < self.shootCooldown then
        return
    end
    
    local character = self.player.Character
    if not character then
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    
    -- Prevent shooting while sitting
    if humanoid.Sit then
        humanoid.Sit = false
        return
    end
    
    -- Get target position from mouse, but aim slightly higher
    local aimOffset = Vector3.new(0, 2, 0) -- Aim 2 studs higher
    local targetPosition = self.mouse.Hit.Position + aimOffset
    
    print("[SlingshotController] 🎯 Shooting at:", targetPosition)
    
    -- Update last shoot time
    self.lastShootTime = currentTime
    
    -- Use ToolObjects to shoot
    local success, result = ToolObjects.shootSlingshot(self.equippedTool, character, targetPosition)
    if success then
        print("[SlingshotController] ✅ Shot fired!")
    else
        warn("[SlingshotController] ⚠️ Failed to shoot:", result)
    end
end

return SlingshotController
