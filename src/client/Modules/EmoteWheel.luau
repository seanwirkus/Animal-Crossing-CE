local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GUIContentManager = require(script.Parent.GUIContentManager)
local GUIStyleUtil = require(script.Parent.GUIStyleUtil)

local EmoteWheel = {}
EmoteWheel.__index = EmoteWheel

local EMOTES = {
    { id = "wave", name = "Wave", animationId = "rbxassetid://507770239", icon = "👋" },
    { id = "cheer", name = "Cheer", animationId = "rbxassetid://507770677", icon = "🎉" },
    { id = "laugh", name = "Laugh", animationId = "rbxassetid://507770818", icon = "😂" },
    { id = "tilt", name = "Tilt", animationId = "rbxassetid://507771019", icon = "🤔" },
    { id = "dance", name = "Dance", animationId = "rbxassetid://507771019", icon = "💃" },
    { id = "clap", name = "Clap", animationId = "rbxassetid://507770453", icon = "👏" },
}

function EmoteWheel.new()
    local self = setmetatable({}, EmoteWheel)
    self.player = Players.LocalPlayer
    self.gui = nil
    self.visible = false
    self.currentTrack = nil
    self.buttons = {}

    self:_createGui()
    return self
end

function EmoteWheel:_createGui()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EmoteWheel"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.DisplayOrder = 60
    screenGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.6, 0)
    container.Size = UDim2.new(0, 320, 0, 320)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local copy = GUIContentManager.Emotes or {}

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 28)
    titleLabel.Position = UDim2.new(0, 0, 0, -32)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    GUIStyleUtil.applyTextStyle(titleLabel, "subtitle")
    GUIStyleUtil.setTextContent(titleLabel, copy.title or "Emotes")
    titleLabel.Parent = container

    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Size = UDim2.new(1, 0, 0, 40)
    descriptionLabel.Position = UDim2.new(0, 0, 1, 4)
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.TextWrapped = true
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    descriptionLabel.Text = copy.hint or "Select an emote"
    GUIStyleUtil.applyTextStyle(descriptionLabel, "caption")
    descriptionLabel.Parent = container

    local radius = 110
    for index, emote in ipairs(EMOTES) do
        local angle = (math.pi * 2 / #EMOTES) * (index - 1)
        local button = Instance.new("TextButton")
        button.Name = emote.id
        button.Size = UDim2.new(0, 72, 0, 72)
        button.AnchorPoint = Vector2.new(0.5, 0.5)
        button.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
        button.Text = string.format("%s\n%s", emote.icon or "", emote.name)
        button.TextWrapped = true
        button.TextSize = 14
        button.AutoButtonColor = false
        GUIStyleUtil.applyButtonStyle(button, "secondary")
        button.Parent = container

        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), { Size = UDim2.new(0, 80, 0, 80) }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), { Size = UDim2.new(0, 72, 0, 72) }):Play()
        end)

        button.MouseButton1Click:Connect(function()
            self:playEmote(emote)
            self:hide()
        end)

        self.buttons[index] = button
    end

    self.gui = screenGui
end

function EmoteWheel:playEmote(emote)
    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not emote or not emote.animationId then
        return
    end

    if self.currentTrack then
        self.currentTrack:Stop()
        self.currentTrack:Destroy()
        self.currentTrack = nil
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = emote.animationId
    local track = humanoid:LoadAnimation(animation)
    track:Play()
    self.currentTrack = track
end

function EmoteWheel:show()
    if self.visible or not self.gui then
        return
    end

    self.visible = true
    self.gui.Enabled = true
end

function EmoteWheel:hide()
    if not self.visible or not self.gui then
        return
    end

    self.visible = false
    self.gui.Enabled = false
end

function EmoteWheel:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

return EmoteWheel
