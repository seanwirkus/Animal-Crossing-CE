--[[
	DIYWorkbenchService.luau
	
	Manages DIY Workbench models in the world and handles player interactions.
	When a player interacts with a workbench, opens the crafting GUI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DIYWorkbenchService = {}
DIYWorkbenchService.__index = DIYWorkbenchService

-- Workbench template will be in ReplicatedStorage
local WORKBENCH_TEMPLATE_NAME = "DIYWorkBench"

function DIYWorkbenchService.new()
    local self = setmetatable({}, DIYWorkbenchService)

    self.workbenches = {}
    self.playerCooldowns = {} -- Prevent spam

    return self
end

function DIYWorkbenchService:initialize()
    print("[DIYWorkbenchService] 🔨 Initializing...")

    -- Find or create Remotes folder
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        remotes = Instance.new("Folder")
        remotes.Name = "Remotes"
        remotes.Parent = ReplicatedStorage
    end

    -- Create remote to open crafting GUI
    local openCraftingRemote = remotes:FindFirstChild("OpenCraftingGUI")
    if not openCraftingRemote then
        openCraftingRemote = Instance.new("RemoteEvent")
        openCraftingRemote.Name = "OpenCraftingGUI"
        openCraftingRemote.Parent = remotes
    end
    self.openCraftingRemote = openCraftingRemote

    -- Find all existing workbenches in workspace
    self:scanForWorkbenches()

    -- Listen for new workbenches being added
    workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == WORKBENCH_TEMPLATE_NAME and descendant:IsA("Model") then
            task.wait(0.1) -- Wait for model to fully load
            self:setupWorkbench(descendant)
        end
    end)

    print("[DIYWorkbenchService] ✅ Initialized with", #self.workbenches, "workbenches")
end

function DIYWorkbenchService:scanForWorkbenches()
    local found = 0

    -- Recursively search workspace for workbench models
    local function scanFolder(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name == WORKBENCH_TEMPLATE_NAME and child:IsA("Model") then
                self:setupWorkbench(child)
                found = found + 1
            elseif child:IsA("Folder") or child:IsA("Model") then
                scanFolder(child)
            end
        end
    end

    scanFolder(workspace)

    print(string.format("[DIYWorkbenchService] Found %d existing workbenches", found))
end

function DIYWorkbenchService:setupWorkbench(workbench)
    if not workbench or not workbench:IsDescendantOf(workspace) then
        return
    end

    -- Check if already set up
    if table.find(self.workbenches, workbench) then
        return
    end

    print("[DIYWorkbenchService] Setting up workbench:", workbench:GetFullName())

    -- Find or create ProximityPrompt
    local prompt = workbench:FindFirstChildOfClass("ProximityPrompt", true)
    if not prompt then
        -- Find a good part to attach the prompt to
        local attachPart = workbench.PrimaryPart or workbench:FindFirstChildWhichIsA("BasePart", true)

        if attachPart then
            prompt = Instance.new("ProximityPrompt")
            prompt.Name = "CraftingPrompt"
            prompt.ObjectText = "DIY Workbench"
            prompt.ActionText = "Craft"
            prompt.MaxActivationDistance = 8
            prompt.RequiresLineOfSight = false
            prompt.Parent = attachPart

            print("[DIYWorkbenchService] Created ProximityPrompt on", attachPart.Name)
        else
            warn("[DIYWorkbenchService] Could not find part to attach prompt to!")
            return
        end
    end

    -- Connect prompt to open crafting GUI
    prompt.Triggered:Connect(function(player)
        self:onWorkbenchInteraction(player, workbench)
    end)

    table.insert(self.workbenches, workbench)

    print("[DIYWorkbenchService] ✅ Workbench ready:", workbench:GetFullName())
end

function DIYWorkbenchService:onWorkbenchInteraction(player, workbench)
    if not player or not player:IsA("Player") then
        return
    end

    -- Check cooldown
    local userId = player.UserId
    local lastUse = self.playerCooldowns[userId] or 0
    local now = tick()

    if now - lastUse < 0.5 then
        return -- Prevent spam
    end

    self.playerCooldowns[userId] = now

    print(string.format("[DIYWorkbenchService] Player %s is using workbench", player.Name))

    -- Fire remote to open crafting GUI on client
    self.openCraftingRemote:FireClient(player)
end

-- Place a workbench at a position
function DIYWorkbenchService:placeWorkbench(position, rotation)
    local template = ReplicatedStorage:FindFirstChild(WORKBENCH_TEMPLATE_NAME)

    if not template then
        warn("[DIYWorkbenchService] Workbench template not found in ReplicatedStorage!")
        return nil
    end

    local workbench = template:Clone()

    -- Position the workbench
    if workbench.PrimaryPart then
        workbench:SetPrimaryPartCFrame(CFrame.new(position) * CFrame.Angles(0, math.rad(rotation or 0), 0))
    else
        workbench:MoveTo(position)
    end

    -- Parent to workspace (this will trigger our DescendantAdded connection)
    workbench.Parent = workspace

    print(string.format("[DIYWorkbenchService] Placed workbench at %s", tostring(position)))

    return workbench
end

-- Create a simple workbench model (fallback if no template exists)
function DIYWorkbenchService:createSimpleWorkbench()
    local workbench = Instance.new("Model")
    workbench.Name = WORKBENCH_TEMPLATE_NAME

    -- Table top
    local top = Instance.new("Part")
    top.Name = "TableTop"
    top.Size = Vector3.new(6, 0.5, 4)
    top.Position = Vector3.new(0, 3, 0)
    top.Anchored = true
    top.Material = Enum.Material.Wood
    top.BrickColor = BrickColor.new("Brown")
    top.Parent = workbench

    -- Legs
    for i = 1, 4 do
        local leg = Instance.new("Part")
        leg.Name = "Leg" .. i
        leg.Size = Vector3.new(0.5, 3, 0.5)
        leg.Anchored = true
        leg.Material = Enum.Material.Wood
        leg.BrickColor = BrickColor.new("Dark orange")

        local x = (i == 1 or i == 2) and -2.5 or 2.5
        local z = (i == 1 or i == 3) and -1.5 or 1.5
        leg.Position = Vector3.new(x, 1.5, z)

        leg.Parent = workbench
    end

    -- Tool decorations
    local hammer = Instance.new("Part")
    hammer.Name = "Hammer"
    hammer.Size = Vector3.new(0.3, 1.5, 0.3)
    hammer.Position = top.Position + Vector3.new(-1, 0.5, 0)
    hammer.Anchored = true
    hammer.Material = Enum.Material.Wood
    hammer.BrickColor = BrickColor.new("Brown")
    hammer.Parent = workbench

    workbench.PrimaryPart = top

    return workbench
end

-- Get all workbenches
function DIYWorkbenchService:getWorkbenches()
    return self.workbenches
end

return DIYWorkbenchService
