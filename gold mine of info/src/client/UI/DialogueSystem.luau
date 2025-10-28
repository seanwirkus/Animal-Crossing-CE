--[[
	DialogueSystem - Animal Crossing Villager Dialogue UI
	Translated from Tailwind React components to Luau
	
	Features:
	- Light/Dark dialogue boxes
	- Name tags with customizable colors
	- Continue button support
	- Multi-paragraph text with colored sections
	- Auto text wrapping and sizing
]]

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local DialogueSystem = {}
DialogueSystem.__index = DialogueSystem

-- Color palette (from Tailwind/AC design)
local COLORS = {
	-- Background colors
	LightDialogBg = Color3.fromRGB(255, 250, 231), -- Cream/beige
	DarkDialogBg = Color3.fromRGB(45, 52, 68), -- Dark blue-gray
	
	-- Text colors
	LightText = Color3.fromRGB(138, 123, 102), -- Brown text on light
	DarkText = Color3.fromRGB(180, 220, 255), -- Light blue text on dark
	AccentCyan = Color3.fromRGB(4, 175, 166), -- Cyan for highlights
	
	-- Name tag backgrounds
	SubtlePink = Color3.fromRGB(255, 228, 228),
	SubtleBlue = Color3.fromRGB(220, 235, 255),
	SubtleGreen = Color3.fromRGB(220, 255, 235),
	SubtleYellow = Color3.fromRGB(255, 250, 220),
}

-- Font settings
local FONTS = {
	DialogText = Enum.Font.GothamMedium,
	DialogBold = Enum.Font.GothamBold,
	NameTag = Enum.Font.GothamBold,
}

--[[
	Creates a new dialogue box
	@param parent GuiObject - Parent GUI element
	@param options table - Configuration options:
		- color: "light" or "dark"
		- continueButton: boolean
		- villagerName: string
		- nameTagColor: "pink", "blue", "green", "yellow"
		- text: string or table of {text, color} pairs
		- size: UDim2 (default: medium size)
]]
function DialogueSystem.CreateDialogueBox(parent, options)
	options = options or {}
	local color = options.color or "light"
	local continueButton = options.continueButton or false
	local villagerName = options.villagerName or "Villager"
	local nameTagColor = options.nameTagColor or "pink"
	local dialogueText = options.text or "Hello!"
	local size = options.size or UDim2.new(0, 1256, 0, 402)
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "DialogueBox"
	container.Size = size
	container.Position = UDim2.new(0.5, 0, 0.85, 0) -- Bottom center
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Background box (92.04% of height, offset by 7.96%)
	local bgBox = Instance.new("Frame")
	bgBox.Name = "Background"
	bgBox.Size = UDim2.new(1, 0, 0.9204, 0)
	bgBox.Position = UDim2.new(0, 0, 0.0796, 0)
	bgBox.BackgroundColor3 = color == "light" and COLORS.LightDialogBg or COLORS.DarkDialogBg
	bgBox.BorderSizePixel = 0
	bgBox.Parent = container
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 24)
	corner.Parent = bgBox
	
	-- Shadow effect
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.8
	shadow.ZIndex = bgBox.ZIndex - 1
	shadow.Parent = bgBox
	
	-- Name tag
	local nameTag = DialogueSystem._createNameTag(container, villagerName, nameTagColor)
	
	-- Dialogue text area (inside the background box)
	local textArea = Instance.new("TextLabel")
	textArea.Name = "DialogueText"
	textArea.Size = continueButton and UDim2.new(0.5113, 0, 0.6404, 0) or UDim2.new(0.5596, 0, 0.4649, 0)
	textArea.Position = UDim2.new(0.0701, 0, 0.1501, 0)
	textArea.BackgroundTransparency = 1
	textArea.TextColor3 = color == "light" and COLORS.LightText or COLORS.DarkText
	textArea.Font = FONTS.DialogBold
	textArea.TextSize = 24
	textArea.TextWrapped = true
	textArea.TextXAlignment = Enum.TextXAlignment.Left
	textArea.TextYAlignment = Enum.TextYAlignment.Top
	textArea.RichText = true
	textArea.Parent = bgBox
	
	-- Format text with colors
	if type(dialogueText) == "table" then
		local richText = ""
		for _, segment in ipairs(dialogueText) do
			local text = segment.text or segment[1]
			local textColor = segment.color or segment[2]
			if textColor then
				local r, g, b = math.floor(textColor.R * 255), math.floor(textColor.G * 255), math.floor(textColor.B * 255)
				richText = richText .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text)
			else
				richText = richText .. text
			end
		end
		textArea.Text = richText
	else
		textArea.Text = dialogueText
	end
	
	-- Continue button (if enabled)
	local continueArrow = nil
	if continueButton then
		continueArrow = DialogueSystem._createContinueButton(bgBox)
	end
	
	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.Parent = textArea
	
	-- Animate in
	DialogueSystem._animateIn(container, bgBox, nameTag)
	
	return {
		Container = container,
		Background = bgBox,
		NameTag = nameTag,
		TextArea = textArea,
		ContinueArrow = continueArrow,
		
		-- Methods
		SetText = function(self, newText)
			if type(newText) == "table" then
				local richText = ""
				for _, segment in ipairs(newText) do
					local text = segment.text or segment[1]
					local textColor = segment.color or segment[2]
					if textColor then
						local r, g, b = math.floor(textColor.R * 255), math.floor(textColor.G * 255), math.floor(textColor.B * 255)
						richText = richText .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text)
					else
						richText = richText .. text
					end
				end
				textArea.Text = richText
			else
				textArea.Text = newText
			end
		end,
		
		SetVillagerName = function(self, newName)
			local nameLabel = nameTag:FindFirstChild("NameLabel")
			if nameLabel then
				nameLabel.Text = newName
			end
		end,
		
		ShowContinueArrow = function(self, show)
			if continueArrow then
				continueArrow.Visible = show
			end
		end,
		
		AnimateOut = function(self, callback)
			DialogueSystem._animateOut(container, callback)
		end,
		
		Destroy = function(self)
			container:Destroy()
		end
	}
end

--[[
	Creates a name tag for the villager
]]
function DialogueSystem._createNameTag(parent, name, colorName)
	-- Name tag container (17.43% height, 17.52% width, positioned at 2.29%, 3.12%)
	local nameTag = Instance.new("Frame")
	nameTag.Name = "NameTag"
	nameTag.Size = UDim2.new(0.1752, 0, 0.1743, 0)
	nameTag.Position = UDim2.new(0.0229, 0, 0.0312, 0)
	nameTag.BackgroundColor3 = COLORS["Subtle" .. colorName:sub(1,1):upper() .. colorName:sub(2)] or COLORS.SubtlePink
	nameTag.BorderSizePixel = 0
	nameTag.Parent = parent
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = nameTag
	
	-- Name text
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -16, 1, -8)
	nameLabel.Position = UDim2.new(0, 8, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = COLORS.LightText
	nameLabel.Font = FONTS.NameTag
	nameLabel.TextSize = 20
	nameLabel.TextScaled = true
	nameLabel.TextWrapped = true
	nameLabel.Parent = nameTag
	
	-- Text size constraint
	local textSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = 20
	textSizeConstraint.Parent = nameLabel
	
	return nameTag
end

--[[
	Creates a continue button/arrow indicator
]]
function DialogueSystem._createContinueButton(parent)
	-- Continue arrow (positioned at 47.97%, 90.27%, size 4.07% x 9.73%)
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "ContinueArrow"
	arrow.Size = UDim2.new(0.0407, 0, 0.0973, 0)
	arrow.Position = UDim2.new(0.4797, 0, 0.9027, 0)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6031094678" -- Down arrow
	arrow.ImageColor3 = COLORS.AccentCyan
	arrow.Parent = parent
	
	-- Pulsing animation
	local pulseTween = TweenService:Create(arrow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		ImageTransparency = 0.3
	})
	pulseTween:Play()
	
	return arrow
end

--[[
	Animates dialogue box appearing
]]
function DialogueSystem._animateIn(container, bgBox, nameTag)
	-- Start off-screen
	container.Position = UDim2.new(0.5, 0, 1.2, 0)
	
	-- Slide up animation
	local tween = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.85, 0)
	})
	tween:Play()
	
	-- Scale in name tag slightly delayed
	nameTag.Size = UDim2.new(0, 0, 0, 0)
	task.wait(0.2)
	local nameTagTween = TweenService:Create(nameTag, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.1752, 0, 0.1743, 0)
	})
	nameTagTween:Play()
end

--[[
	Animates dialogue box disappearing
]]
function DialogueSystem._animateOut(container, callback)
	local tween = TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.2, 0)
	})
	
	tween.Completed:Connect(function()
		if callback then
			callback()
		end
	end)
	
	tween:Play()
end

--[[
	Convenience function: Show dialogue with player name substitution
]]
function DialogueSystem.ShowVillagerDialogue(parent, villagerName, dialogueText, playerName, options)
	options = options or {}
	
	-- Replace NAME HERE with actual player name
	if type(dialogueText) == "string" then
		dialogueText = dialogueText:gsub("NAME HERE", playerName)
	elseif type(dialogueText) == "table" then
		for i, segment in ipairs(dialogueText) do
			local text = segment.text or segment[1]
			if text then
				segment.text = text:gsub("NAME HERE", playerName)
				segment[1] = segment.text
			end
		end
	end
	
	-- Create the dialogue box
	options.villagerName = villagerName
	options.text = dialogueText
	
	return DialogueSystem.CreateDialogueBox(parent, options)
end

--[[
	Example: Create a light dialogue box with colored text
	
	Usage:
	local dialogue = DialogueSystem.ShowVillagerDialogue(
		playerGui,
		"Tom Nook",
		{
			{text = "Welcome, ", color = Color3.fromRGB(138, 123, 102)},
			{text = "Sean", color = Color3.fromRGB(4, 175, 166)},
			{text = "!\nHow can I help you today?", color = Color3.fromRGB(138, 123, 102)}
		},
		"Sean",
		{
			color = "light",
			continueButton = false,
			nameTagColor = "blue"
		}
	)
	
	-- Later, to close:
	dialogue:AnimateOut(function()
		dialogue:Destroy()
	end)
]]

return DialogueSystem

