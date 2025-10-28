--[[
	ToolIcons - Letter-based tool icon generator
	Creates simple letter icons for tools until proper assets are uploaded
]]

local ToolIcons = {}

-- Tool ID to letter mapping
local TOOL_LETTERS = {
	tool_flimsy_axe = "A",
	tool_axe = "A",
	tool_fishing_rod_basic = "F",
	tool_fishing_rod = "F",
	tool_bug_net_basic = "N",
	tool_bug_net = "N",
	tool_watering_can_basic = "W",
	tool_watering_can = "W",
	tool_shovel_basic = "S",
	tool_shovel = "S",
	tool_slingshot = "L",
	tool_ladder = "D",
	tool_vaulting_pole = "V",
}

-- Tool colors for visual distinction
local TOOL_COLORS = {
	tool_flimsy_axe = Color3.fromRGB(139, 69, 19), -- Brown
	tool_axe = Color3.fromRGB(101, 67, 33), -- Dark brown
	tool_fishing_rod_basic = Color3.fromRGB(0, 119, 190), -- Blue
	tool_fishing_rod = Color3.fromRGB(0, 100, 170),
	tool_bug_net_basic = Color3.fromRGB(34, 139, 34), -- Green
	tool_bug_net = Color3.fromRGB(0, 128, 0),
	tool_watering_can_basic = Color3.fromRGB(64, 164, 223), -- Light blue
	tool_watering_can = Color3.fromRGB(30, 144, 255),
	tool_shovel_basic = Color3.fromRGB(205, 133, 63), -- Peru
	tool_shovel = Color3.fromRGB(160, 82, 45),
}

--[[
	Get letter for tool
	@param toolId string - Tool identifier
	@return string - Single letter representing the tool
]]
function ToolIcons:GetLetter(toolId)
	return TOOL_LETTERS[toolId] or "?"
end

--[[
	Get color for tool
	@param toolId string - Tool identifier
	@return Color3 - Color for the tool
]]
function ToolIcons:GetColor(toolId)
	return TOOL_COLORS[toolId] or Color3.fromRGB(128, 128, 128)
end

--[[
	Create letter icon ImageLabel for tool
	@param toolId string - Tool identifier
	@return ImageLabel - UI element with letter
]]
function ToolIcons:CreateIcon(toolId, size)
	size = size or UDim2.new(0, 48, 0, 48)
	
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.BackgroundColor3 = self:GetColor(toolId)
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = self:GetLetter(toolId)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = frame
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.PaddingLeft = UDim.new(0.15, 0)
	padding.PaddingRight = UDim.new(0.15, 0)
	padding.Parent = label
	
	return frame
end

return ToolIcons
