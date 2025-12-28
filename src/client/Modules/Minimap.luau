--[[
	Minimap.luau
	
	Minimap system for Animal Crossing CE
	Shows island overview with player location
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GUIContentManager = require(script.Parent.GUIContentManager)
local GUIStyleUtil = require(script.Parent.GUIStyleUtil)

local Minimap = {}
Minimap.__index = Minimap

local LocalPlayer = Players.LocalPlayer

function Minimap.new()
    local self = setmetatable({}, Minimap)

    self.gui = nil
    self.isVisible = false
    self.updateConnection = nil

    return self
end

function Minimap:createGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Check if GUI already exists
    local existingGui = playerGui:FindFirstChild("MinimapGUI")
    if existingGui then
        existingGui:Destroy()
    end

    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MinimapGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 50
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(1, 0) -- Top-right
    container.Position = UDim2.new(1, -20, 0, 20)
    container.Size = UDim2.new(0, 300, 0, 300)
    container.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
    container.BackgroundTransparency = 0.1
    container.BorderSizePixel = 0
    container.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 120, 160)
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.Parent = container

    -- Title
    local mapCopy = GUIContentManager.Map or {}

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(65, 120, 160)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = mapCopy.title or "🗺️ Island Map"
    title.Parent = container

    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 0, 32)
    hint.BackgroundTransparency = 1
    hint.TextColor3 = Color3.fromRGB(110, 140, 160)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = mapCopy.hint or "Press M to toggle"
    hint.Parent = container

    -- Map view with top-down camera view using ViewportFrame
    local mapFrame = Instance.new("ViewportFrame")
    mapFrame.Name = "MapFrame"
    mapFrame.Size = UDim2.new(1, -20, 1, -70)
    mapFrame.Position = UDim2.new(0, 10, 0, 60)
    mapFrame.BackgroundColor3 = Color3.fromRGB(92, 159, 115) -- Grass green fallback
    mapFrame.BorderSizePixel = 0
    mapFrame.Parent = container

    local mapCorner = Instance.new("UICorner")
    mapCorner.CornerRadius = UDim.new(0, 8)
    mapCorner.Parent = mapFrame
    
    -- Create a camera for the top-down view (MUST be parented to ViewportFrame)
    local mapCamera = Instance.new("Camera")
    mapCamera.Name = "MapCamera"
    mapCamera.Parent = mapFrame -- Parent to ViewportFrame, not workspace
    mapFrame.CurrentCamera = mapCamera
    
    -- Create a WorldModel to hold cloned island content for rendering
    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "IslandWorld"
    worldModel.Parent = mapFrame
    
    -- Set up top-down camera position (high above island center, looking straight down)
    local ISLAND_CENTER = Vector3.new(0, 0, 0) -- Default center
    local ISLAND_RADIUS = 300
    local CAMERA_HEIGHT = 600 -- High above island (increased for better view)
    
    -- Position camera directly above island center, looking straight down
    mapCamera.CFrame = CFrame.new(
        ISLAND_CENTER + Vector3.new(0, CAMERA_HEIGHT, 0), -- Camera position (high above)
        ISLAND_CENTER -- Look at center (straight down)
    )
    mapCamera.FieldOfView = 100 -- Wider FOV to see entire island better
    
    -- Store worldModel for later use
    self.worldModel = worldModel

    -- Player indicator overlay (UI element on top of viewport)
    local playerDotContainer = Instance.new("Frame")
    playerDotContainer.Name = "PlayerDotContainer"
    playerDotContainer.Size = UDim2.new(1, -20, 1, -70)
    playerDotContainer.Position = UDim2.new(0, 10, 0, 60)
    playerDotContainer.BackgroundTransparency = 1
    playerDotContainer.BorderSizePixel = 0
    playerDotContainer.ZIndex = 10 -- Above viewport
    playerDotContainer.Parent = container
    
    -- Player indicator (arrow shape to show direction)
    local playerDot = Instance.new("Frame")
    playerDot.Name = "PlayerDot"
    playerDot.Size = UDim2.new(0, 16, 0, 16)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    playerDot.BorderSizePixel = 0
    playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    playerDot.Position = UDim2.fromScale(0.5, 0.5) -- Center initially
    playerDot.ZIndex = 11 -- Above container
    playerDot.Parent = playerDotContainer

    -- Make it look like an arrow pointing in direction
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0, 2)
    dotCorner.Parent = playerDot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(255, 255, 255)
    dotStroke.Thickness = 2
    dotStroke.Parent = playerDot

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 24
    closeBtn.Parent = container

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:hide()
    end)

    self.gui = screenGui
    self.mapFrame = mapFrame
    self.playerDot = playerDot
    self.playerDotContainer = playerDotContainer
    self.mapCamera = mapCamera
    self.worldModel = worldModel

    -- Clone island terrain and objects into viewport for rendering
    task.spawn(function()
        self:populateViewport()
    end)

    return screenGui
end

function Minimap:populateViewport()
    if not self.worldModel or not self.mapFrame then
        return
    end
    
    -- Clear existing content
    self.worldModel:ClearAllChildren()
    
    local ISLAND_RADIUS = 300
    local ISLAND_CENTER = Vector3.new(0, 0, 0)
    
    -- Try to get player's island center
    local playerIslands = workspace:FindFirstChild("PlayerIslands")
    if playerIslands then
        for _, islandFolder in ipairs(playerIslands:GetChildren()) do
            if islandFolder:IsA("Folder") and islandFolder.Name:find("Island_" .. LocalPlayer.UserId) then
                -- Found player's island - try to get center from island data
                -- For now, use default center
                break
            end
        end
    end
    
    -- Create a large ground plane to represent the island (scaled down for viewport)
    local groundPlane = Instance.new("Part")
    groundPlane.Name = "IslandGround"
    groundPlane.Size = Vector3.new(ISLAND_RADIUS * 2, 2, ISLAND_RADIUS * 2)
    groundPlane.Position = ISLAND_CENTER
    groundPlane.Material = Enum.Material.Grass
    groundPlane.Color = Color3.fromRGB(92, 159, 115) -- Grass green
    groundPlane.Anchored = true
    groundPlane.CanCollide = false
    groundPlane.TopSurface = Enum.SurfaceType.Smooth
    groundPlane.BottomSurface = Enum.SurfaceType.Smooth
    groundPlane.Parent = self.worldModel
    
    -- Add lighting to viewport
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Color = Color3.fromRGB(255, 255, 255)
    light.Range = 1000
    light.Shadows = false
    light.Parent = groundPlane
    
    -- Clone trees from player's island
    task.spawn(function()
        -- Wait for trees to be generated (check multiple times)
        for i = 1, 5 do
            task.wait(0.3)
            
            local playerIslands = workspace:FindFirstChild("PlayerIslands")
            if playerIslands then
                -- Find player's island
                local playerIslandFolder = nil
                for _, islandFolder in ipairs(playerIslands:GetChildren()) do
                    if islandFolder:IsA("Folder") and islandFolder.Name:find("Island_" .. LocalPlayer.UserId) then
                        playerIslandFolder = islandFolder
                        break
                    end
                end
                
                -- If not found by userId, use first island
                if not playerIslandFolder and #playerIslands:GetChildren() > 0 then
                    playerIslandFolder = playerIslands:GetChildren()[1]
                end
                
                if playerIslandFolder then
                    local treesFolder = playerIslandFolder:FindFirstChild("Trees")
                    if treesFolder and #treesFolder:GetChildren() > 0 then
                        local treeCount = 0
                        for _, tree in ipairs(treesFolder:GetChildren()) do
                            if tree:IsA("Model") and tree.PrimaryPart then
                                local treeClone = tree:Clone()
                                -- Make trees smaller for minimap view
                                if treeClone.PrimaryPart then
                                    treeClone:ScaleTo(0.3) -- Scale down trees for minimap
                                end
                                treeClone.Parent = self.worldModel
                                treeCount = treeCount + 1
                                
                                -- Limit tree count for performance
                                if treeCount >= 50 then
                                    break
                                end
                            end
                        end
                        if treeCount > 0 then
                            print(string.format("[Minimap] ✅ Cloned %d trees into viewport", treeCount))
                            break -- Success, exit retry loop
                        end
                    end
                end
            end
        end
    end)
    
    print("[Minimap] ✅ Populated viewport with island representation")
end

function Minimap:show()
    if not self.gui then
        self:createGUI()
    end

    if self.isVisible then
        return
    end

    self.isVisible = true
    self.gui.Enabled = true

    -- Refresh viewport content when showing (with delay to ensure trees are loaded)
    if self.worldModel then
        task.spawn(function()
            task.wait(0.2) -- Small delay to ensure island is fully loaded
            self:populateViewport()
        end)
    end

    -- Animate in
    self.gui.Container.Position = UDim2.new(1, 20, 0, 20) -- Start off-screen
    local tween = TweenService:Create(
        self.gui.Container,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(1, -20, 0, 20) }
    )
    tween:Play()

    -- Start updating player position
    self:startUpdating()
end

function Minimap:hide()
    if not self.isVisible or not self.gui then
        return
    end

    self.isVisible = false

    -- Animate out
    local tween = TweenService:Create(
        self.gui.Container,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(1, 20, 0, 20) }
    )
    tween:Play()
    tween.Completed:Wait()

    self.gui.Enabled = false
    self:stopUpdating()
end

function Minimap:toggle()
    if self.isVisible then
        self:hide()
    else
        self:show()
    end
end

function Minimap:startUpdating()
    if self.updateConnection then
        return
    end

    -- Island bounds (default - can be adjusted based on actual island size)
    -- Based on GenerationRules: ISLAND_RADIUS is typically 300 studs
    local ISLAND_RADIUS = 300 -- studs from center
    local ISLAND_CENTER = Vector3.new(0, 0, 0)
    local ISLAND_MIN_X = -ISLAND_RADIUS
    local ISLAND_MAX_X = ISLAND_RADIUS
    local ISLAND_MIN_Z = -ISLAND_RADIUS
    local ISLAND_MAX_Z = ISLAND_RADIUS
    local CAMERA_HEIGHT = 500
    
    -- Try to detect actual island bounds from terrain or player spawn
    local spawnLocation = LocalPlayer:GetAttribute("SpawnLocation")
    if spawnLocation then
        -- If player has a spawn location attribute, use that as island center
        local spawnPos = typeof(spawnLocation) == "Vector3" and spawnLocation or Vector3.new(0, 0, 0)
        ISLAND_CENTER = spawnPos
        ISLAND_MIN_X = spawnPos.X - ISLAND_RADIUS
        ISLAND_MAX_X = spawnPos.X + ISLAND_RADIUS
        ISLAND_MIN_Z = spawnPos.Z - ISLAND_RADIUS
        ISLAND_MAX_Z = spawnPos.Z + ISLAND_RADIUS
    end
    
    local islandWidth = ISLAND_MAX_X - ISLAND_MIN_X
    local islandDepth = ISLAND_MAX_Z - ISLAND_MIN_Z

    self.updateConnection = RunService.Heartbeat:Connect(function()
        if not self.isVisible then
            return
        end

        -- Update top-down camera to stay centered on island
        if self.mapCamera then
            -- Keep camera fixed above island center, looking straight down
            -- Use wider FOV for better island visibility
            self.mapCamera.FieldOfView = 100
            self.mapCamera.CFrame = CFrame.new(
                ISLAND_CENTER + Vector3.new(0, CAMERA_HEIGHT, 0),
                ISLAND_CENTER
            )
        end

        -- Update player dot position if character exists
        if LocalPlayer.Character then
            local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local worldPos = rootPart.Position
                
                -- Map world coordinates to minimap coordinates (0-1 scale)
                local normalizedX = (worldPos.X - ISLAND_MIN_X) / islandWidth
                local normalizedZ = (worldPos.Z - ISLAND_MIN_Z) / islandDepth
                
                -- Clamp to map bounds (0-1)
                normalizedX = math.clamp(normalizedX, 0, 1)
                normalizedZ = math.clamp(normalizedZ, 0, 1)
                
                -- Update player dot position on minimap
                if self.playerDot then
                    self.playerDot.Position = UDim2.fromScale(normalizedX, normalizedZ)
                    
                    -- Rotate player dot to show facing direction
                    if rootPart.CFrame then
                        local lookDirection = rootPart.CFrame.LookVector
                        local angle = math.atan2(lookDirection.X, lookDirection.Z)
                        self.playerDot.Rotation = math.deg(angle)
                    end
                end
            end
        end
    end)
end

function Minimap:stopUpdating()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
end

-- Singleton instance
local minimapInstance = Minimap.new()

-- Export
return minimapInstance
