local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Theme)
local Data = require(ReplicatedStorage.Data)
local GameTypes = require(ReplicatedStorage.GameTypes)

-- Template structure: { id, displayName, tagline, difficulty, biomeTags, startingVillagers, startingResources, description, thumbnail? }
-- Options structure: { templates, onConfirm }

local PLACEHOLDER_THUMBNAIL = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local DIFFICULTY_COLORS = {
	Calm = Color3.fromRGB(120, 200, 160),
	Balanced = Color3.fromRGB(108, 168, 255),
	Spirited = Color3.fromRGB(255, 149, 128),
}

local IslandSelection = {}
IslandSelection.__index = IslandSelection

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function joinTags(tags)
	return table.concat(tags, ", ")
end

local function createDivider(parent)
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = Theme.color("PanelBorder")
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Parent = parent
end

local function getThumbnail(template)
	if template.thumbnail and template.thumbnail ~= "" then
		return template.thumbnail
	end
	return PLACEHOLDER_THUMBNAIL
end

function IslandSelection.new(options)
        assert(options.templates and #options.templates > 0, "IslandSelection requires templates to display.")

        local self = setmetatable({}, IslandSelection)
        self._templates = options.templates
        self._onConfirm = options.onConfirm
        self._onCancel = options.onCancel
        self._selectedId = nil
        self._cards = {}
        self._connections = {}
        self._destroyed = false

        self:_buildGui()
        self:_populateTemplates()

        return self
end

function IslandSelection:_buildGui()
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "IslandSelection"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.DisplayOrder = 10
	self._screenGui.IgnoreGuiInset = true
	self._screenGui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.BackgroundColor3 = Color3.fromRGB(139, 195, 74)  -- ACNH green gradient base
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Parent = self._screenGui

	-- Gradient effect
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 195, 74)),  -- Island green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(33, 150, 243))   -- Ocean blue
	})
	gradient.Rotation = 45
	gradient.Parent = overlay

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromScale(0.5, 0.5)
        container.Size = UDim2.fromScale(0.8, 0.8)  -- Increased size for better visibility
        container.BackgroundColor3 = Color3.fromRGB(255, 251, 239)  -- Warm cream
	container.BorderSizePixel = 0
	container.Parent = overlay
	container.ClipsDescendants = true  -- Prevent overflow
	self._container = container

	-- Size constraints for better scaling
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(500, 350)
	sizeConstraint.MaxSize = Vector2.new(1000, 700)
	sizeConstraint.Parent = container

	-- No aspect ratio constraint - let it be flexible

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)  -- Fixed corner radius
	corner.Parent = container

	-- Thick border stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(139, 195, 74)
	stroke.Thickness = 4
	stroke.Parent = container

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "DropShadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.5)
	shadow.Size = UDim2.new(1, 80, 1, 80)
	shadow.ZIndex = container.ZIndex - 1
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.3
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(34, 34, 234, 234)
	shadow.Parent = overlay

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 20)
        layout.Parent = container
        self._layout = layout

        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.AnchorPoint = Vector2.new(1, 0)
        closeButton.Position = UDim2.new(1, -18, 0, 18)
        closeButton.Size = UDim2.new(0, 34, 0, 34)
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.BackgroundTransparency = 0.05
        closeButton.BorderSizePixel = 0
        closeButton.Text = "✕"
        closeButton.TextColor3 = Color3.fromRGB(120, 120, 120)
        closeButton.TextSize = 20
        closeButton.Font = Enum.Font.GothamBold
        closeButton.ZIndex = 2
        closeButton.Parent = container
        closeButton.Visible = true

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(1, 0)
        closeCorner.Parent = closeButton

        local closeStroke = Instance.new("UIStroke")
        closeStroke.Thickness = 1
        closeStroke.Color = Color3.fromRGB(210, 210, 210)
        closeStroke.Parent = closeButton

        table.insert(self._connections, closeButton.MouseButton1Click:Connect(function()
                self:_handleCancel()
        end))

	local listColumn = Instance.new("ScrollingFrame")
	listColumn.Name = "TemplateList"
	listColumn.BackgroundTransparency = 1
	listColumn.Size = UDim2.fromScale(0.45, 0.88)
	listColumn.Position = UDim2.fromScale(0.025, 0.06)
	listColumn.BorderSizePixel = 0
	listColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
	listColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listColumn.ScrollBarThickness = 6
	listColumn.ScrollBarImageColor3 = Color3.fromRGB(139, 195, 74)
	listColumn.Parent = container
	self._listColumn = listColumn

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0.02, 0)  -- Responsive padding
	listLayout.Parent = listColumn

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0.02, 0)
	listPadding.PaddingBottom = UDim.new(0.02, 0)
	listPadding.PaddingLeft = UDim.new(0.02, 0)
	listPadding.PaddingRight = UDim.new(0.02, 0)
	listPadding.Parent = listColumn

        local detailColumn = Instance.new("Frame")
        detailColumn.Name = "DetailPanel"
        detailColumn.BackgroundTransparency = 1
        detailColumn.Size = UDim2.fromScale(0.48, 0.88)
        detailColumn.Parent = container
        self._detailColumn = detailColumn

	local detailLayout = Instance.new("UIListLayout")
	detailLayout.FillDirection = Enum.FillDirection.Vertical
	detailLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	detailLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	detailLayout.Padding = UDim.new(0.025, 0)  -- Responsive padding
	detailLayout.Parent = detailColumn

	-- Text size constraint for responsive text
	local function createTextSizeConstraint(textLabel, maxSize, minSize)
		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = maxSize or textLabel.TextSize
		constraint.MinTextSize = minSize or 10
		constraint.Parent = textLabel
		textLabel.TextScaled = true
	end

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 24
	header.Size = UDim2.new(1, 0, 0, 30)
	header.TextColor3 = Theme.textColor()
	header.Text = "Choose Your Island Style"
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.LayoutOrder = 1
	header.Parent = detailColumn
	createTextSizeConstraint(header, 24, 14)

	local subHeader = Instance.new("TextLabel")
	subHeader.Name = "SubHeader"
	subHeader.BackgroundTransparency = 1
	subHeader.Font = Enum.Font.Gotham
	subHeader.TextSize = 14
	subHeader.TextXAlignment = Enum.TextXAlignment.Left
	subHeader.TextWrapped = true
	subHeader.Size = UDim2.new(1, 0, 0, 40)
	subHeader.TextColor3 = Theme.secondaryTextColor()
	subHeader.Text = "Each island focuses on a different vibe. Pick the one that matches how you want to begin."
	subHeader.LayoutOrder = 2
	subHeader.Parent = detailColumn
	createTextSizeConstraint(subHeader, 14, 10)

	createDivider(detailColumn)

	local detailTitle = Instance.new("TextLabel")
	detailTitle.Name = "DetailTitle"
	detailTitle.BackgroundTransparency = 1
	detailTitle.Font = Enum.Font.GothamBold
	detailTitle.TextSize = 28
	detailTitle.TextXAlignment = Enum.TextXAlignment.Left
	detailTitle.TextColor3 = Theme.textColor()
	detailTitle.Size = UDim2.new(1, 0, 0, 34)
	detailTitle.Text = "Select an island to preview"
	detailTitle.Parent = detailColumn
	self._detailTitle = detailTitle

	local detailTagline = Instance.new("TextLabel")
	detailTagline.Name = "DetailTagline"
	detailTagline.BackgroundTransparency = 1
	detailTagline.Font = Enum.Font.GothamSemibold
	detailTagline.TextSize = 18
	detailTagline.TextXAlignment = Enum.TextXAlignment.Left
	detailTagline.TextWrapped = true
	detailTagline.TextColor3 = Color3.fromRGB(139, 195, 74)  -- Green accent
	detailTagline.Size = UDim2.new(1, 0, 0, 30)
	detailTagline.Text = ""
	detailTagline.Parent = detailColumn
	self._detailTagline = detailTagline

	-- Top row container for image and basic info
	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.BackgroundTransparency = 1
	topRow.Size = UDim2.new(1, 0, 0, 110)
	topRow.Parent = detailColumn

	local previewImage = Instance.new("ImageLabel")
	previewImage.Name = "PreviewImage"
	previewImage.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	previewImage.Size = UDim2.new(0, 100, 0, 100)  -- 100x100 for island image
	previewImage.Image = PLACEHOLDER_THUMBNAIL
	previewImage.ScaleType = Enum.ScaleType.Fit
	previewImage.BorderSizePixel = 0
	previewImage.Parent = topRow
	self._detailImage = previewImage

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 12)
	previewCorner.Parent = previewImage

	local previewStroke = Instance.new("UIStroke")
	previewStroke.Color = Color3.fromRGB(139, 195, 74)
	previewStroke.Thickness = 3
	previewStroke.Parent = previewImage

	-- Description next to image
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Position = UDim2.new(0, 115, 0, 0)
	description.Size = UDim2.new(1, -115, 1, 0)
	description.BackgroundTransparency = 1
	description.Font = Enum.Font.Gotham
	description.TextSize = 15
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.TextColor3 = Color3.fromRGB(80, 80, 80)
	description.Text = ""
	description.Parent = topRow
	self._detailDescription = description

	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "Stats"
	statsFrame.BackgroundTransparency = 1
	statsFrame.Size = UDim2.new(1, 0, 0, 260)  -- Space for 3 sections: Welcome(70) + Players(70) + Starter Kit(90) + padding
	statsFrame.Parent = detailColumn
	self._statsFrame = statsFrame

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Vertical
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	statsLayout.Padding = UDim.new(0, 10)
	statsLayout.Parent = statsFrame

	local stretch = Instance.new("Frame")
	stretch.BackgroundTransparency = 1
	stretch.Size = UDim2.new(1, 0, 1, -260)
	stretch.Parent = detailColumn

	local confirmButton = Instance.new("TextButton")
	confirmButton.Name = "ConfirmButton"
	confirmButton.Size = UDim2.fromScale(1, 0.1)
	confirmButton.AutoButtonColor = false
	confirmButton.Text = "🏝️ Start Your Island Adventure!"
	confirmButton.Font = Enum.Font.GothamBold
	confirmButton.TextSize = 20
        confirmButton.TextScaled = true
        confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)  -- Golden yellow
        confirmButton.Visible = true
        confirmButton.Active = true
        confirmButton.Parent = detailColumn
        self._confirmButton = confirmButton
        createTextSizeConstraint(confirmButton)

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0.2, 0)  -- Responsive corner
	confirmCorner.Parent = confirmButton

	-- Size constraint for button
	local buttonConstraint = Instance.new("UISizeConstraint")
	buttonConstraint.MinSize = Vector2.new(100, 40)
	buttonConstraint.MaxSize = Vector2.new(800, 70)
	buttonConstraint.Parent = confirmButton

	-- Button stroke for depth
	local confirmStroke = Instance.new("UIStroke")
	confirmStroke.Color = Color3.fromRGB(255, 152, 0)
	confirmStroke.Thickness = 3
	confirmStroke.Parent = confirmButton

	-- Button hover effect
	confirmButton.MouseEnter:Connect(function()
		confirmButton.BackgroundColor3 = Color3.fromRGB(255, 213, 79)
	end)
	confirmButton.MouseLeave:Connect(function()
		confirmButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
	end)

        confirmButton.MouseButton1Click:Connect(function()
                if not self._selectedId then
                        return
                end
                local template = self:_findTemplate(self._selectedId)
                if template and self._onConfirm then
                        self._onConfirm(template)
                end
        end)

        self:_setConfirmState(false, "Select an island to begin")

        table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
                if processed then
                        return
                end
                if input.KeyCode == Enum.KeyCode.Escape then
                        self:_handleCancel()
                end
        end))
end

function IslandSelection:_populateTemplates()
	for _, template in ipairs(self._templates) do
		local card = Instance.new("TextButton")
		card.Name = template.id
		card.Size = UDim2.new(1, -6, 0, 120)
		card.AutoButtonColor = false
		card.Text = ""
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.BorderSizePixel = 0
		card.Parent = self._listColumn

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(210, 210, 210)
		stroke.Thickness = 2
		stroke.Transparency = 0.4
		stroke.Parent = card

		local thumbnail = Instance.new("ImageLabel")
		thumbnail.Name = "Thumbnail"
		thumbnail.BackgroundTransparency = 1
		thumbnail.Image = getThumbnail(template)
		thumbnail.ScaleType = Enum.ScaleType.Crop
		thumbnail.Size = UDim2.new(0, 65, 0, 65)
		thumbnail.Position = UDim2.new(0, 12, 0, 25)
		thumbnail.Parent = card

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = UDim.new(0, 8)
		thumbCorner.Parent = thumbnail

		local thumbStroke = Instance.new("UIStroke")
		thumbStroke.Color = Color3.fromRGB(139, 195, 74)
		thumbStroke.Thickness = 2
		thumbStroke.Transparency = 0.25
		thumbStroke.Parent = thumbnail

		local textOffset = 85

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 18
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.fromRGB(62, 39, 35)
		title.Text = template.displayName
		title.Size = UDim2.new(1, -textOffset - 12, 0, 22)
		title.Position = UDim2.new(0, textOffset, 0, 12)
		title.Parent = card
		
		local titleConstraint = Instance.new("UITextSizeConstraint")
		titleConstraint.MaxTextSize = 18
		titleConstraint.MinTextSize = 12
		titleConstraint.Parent = title

		local tagline = Instance.new("TextLabel")
		tagline.Name = "Tagline"
		tagline.BackgroundTransparency = 1
		tagline.Font = Enum.Font.Gotham
		tagline.TextSize = 13
		tagline.TextScaled = true
		tagline.TextXAlignment = Enum.TextXAlignment.Left
		tagline.TextColor3 = Color3.fromRGB(100, 100, 100)
		tagline.TextWrapped = true
		tagline.Size = UDim2.new(1, -textOffset - 12, 0, 35)
		tagline.Position = UDim2.new(0, textOffset, 0, 38)
		tagline.Text = template.tagline
		tagline.Parent = card
		
		local taglineConstraint = Instance.new("UITextSizeConstraint")
		taglineConstraint.MaxTextSize = 13
		taglineConstraint.MinTextSize = 10
		taglineConstraint.Parent = tagline

		local biome = Instance.new("TextLabel")
		biome.Name = "BiomeLine"
		biome.BackgroundTransparency = 1
		biome.Font = Enum.Font.Gotham
		biome.TextSize = 12
		biome.TextScaled = true
		biome.TextColor3 = Theme.secondaryTextColor()
		biome.TextXAlignment = Enum.TextXAlignment.Left
		biome.Text = "Biomes: " .. joinTags(template.biomeTags)
		biome.Size = UDim2.new(1, -textOffset - 12, 0, 16)
		biome.Position = UDim2.new(0, textOffset, 0, 78)
		biome.Parent = card
		
		local biomeConstraint = Instance.new("UITextSizeConstraint")
		biomeConstraint.MaxTextSize = 12
		biomeConstraint.MinTextSize = 9
		biomeConstraint.Parent = biome

		local badge = Instance.new("Frame")
		badge.Name = "DifficultyBadge"
		badge.AnchorPoint = Vector2.new(1, 1)
		badge.Position = UDim2.new(1, -12, 1, -12)
		badge.Size = UDim2.new(0, 90, 0, 24)
		badge.BackgroundColor3 = Color3.fromRGB(139, 195, 74)
		badge.BorderSizePixel = 0
		badge.Parent = card

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 12)
		badgeCorner.Parent = badge

		local badgeText = Instance.new("TextLabel")
		badgeText.BackgroundTransparency = 1
		badgeText.Font = Enum.Font.GothamBold
		badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeText.TextSize = 13
		badgeText.TextScaled = true
		badgeText.TextXAlignment = Enum.TextXAlignment.Left
		badgeText.Size = UDim2.new(1, -10, 1, 0)
		badgeText.Position = UDim2.new(0, 8, 0, 0)
		badgeText.Text = template.difficulty
		badgeText.Parent = badge
		
		local badgeConstraint = Instance.new("UITextSizeConstraint")
		badgeConstraint.MaxTextSize = 13
		badgeConstraint.MinTextSize = 10
		badgeConstraint.Parent = badgeText

		card.MouseEnter:Connect(function()
			if self._selectedId ~= template.id then
				card.BackgroundColor3 = Color3.fromRGB(248, 247, 240)
				stroke.Color = Color3.fromRGB(139, 195, 74)
				stroke.Transparency = 0
			end
		end)

		card.MouseLeave:Connect(function()
			if self._selectedId ~= template.id then
				card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				stroke.Color = Color3.fromRGB(210, 210, 210)
				stroke.Transparency = 0.4
			end
		end)

		card.MouseButton1Click:Connect(function()
			self:_selectTemplate(template.id)
		end)

		self._cards[template.id] = card
	end
end

function IslandSelection:_selectTemplate(templateId)
	self._selectedId = templateId
	for id, card in pairs(self._cards) do
		self:_styleCard(card, id == templateId)
	end

	local template = self:_findTemplate(templateId)
	if template then
		self:_updateDetails(template)
	end
end

function IslandSelection:_updateDetails(template)
	self._detailTitle.Text = template.displayName
	local difficultyColor = DIFFICULTY_COLORS[template.difficulty] or Color3.fromRGB(139, 195, 74)
	self._detailTagline.TextColor3 = difficultyColor
	self._detailTagline.Text = string.format("%s • %s", template.tagline, template.difficulty)
	self._detailDescription.Text = template.description
	self._detailImage.Image = getThumbnail(template)

	for _, child in ipairs(self._statsFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Island Vibe
	if template.vibe then
		self:_addStatSection("Island Vibe", "✨", {template.vibe}, 16)
	end

	-- Add villager section with larger text
	self:_addStatSection("Starting Villagers", "🏠", template.startingVillagers, 18)
	
	-- Island Features
	if template.features then
		self:_addStatSection("What to Explore", "🗺️", template.features, 15)
	end
	
	-- Weather & Time Bonus
	if template.weatherPreference then
		self:_addStatSection("Best Time to Visit", "🌤️", {template.weatherPreference}, 14)
	end
	if template.timeOfDayBonus then
		self:_addStatSection("Special Events", "🌙", {template.timeOfDayBonus}, 14)
	end
	
	-- Add biome section
	self:_addStatSection("Island Biomes", "🌿", template.biomeTags, 16)
	
	-- Add starter items with larger text
	self:_addStatSection("Your Starter Kit", "🎁", template.startingResources, 18)
	
	-- Starting Currency
	if template.startingBells or template.startingMiles then
		local currency = {}
		if template.startingBells then
			table.insert(currency, "🔔 " .. tostring(template.startingBells) .. " Bells")
		end
		if template.startingMiles then
			table.insert(currency, "⭐ " .. tostring(template.startingMiles) .. " Nook Miles")
		end
		self:_addStatSection("Starting Resources", "💰", currency, 16)
	end

	self:_setConfirmState(true, string.format("Begin on %s", template.displayName))
end

function IslandSelection:_styleCard(card, isSelected)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if isSelected then
		card.BackgroundColor3 = Color3.fromRGB(255, 245, 225)
		if stroke then
			stroke.Color = Color3.fromRGB(139, 195, 74)
			stroke.Transparency = 0
			stroke.Thickness = 3
		end
	else
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		if stroke then
			stroke.Color = Color3.fromRGB(210, 210, 210)
			stroke.Transparency = 0.4
			stroke.Thickness = 2
		end
	end
end

function IslandSelection:_setConfirmState(enabled, text)
        self._confirmButton.Active = enabled
        self._confirmButton.AutoButtonColor = enabled
        self._confirmButton.Text = text
        if enabled then
		self._confirmButton.BackgroundColor3 = Theme.color("BoardButtonAccept")
		self._confirmButton.TextColor3 = Theme.color("TextLight")
	else
		self._confirmButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		self._confirmButton.TextColor3 = Color3.fromRGB(120, 120, 120)
	end
end

function IslandSelection:_handleCancel()
        if self._destroyed then
                return
        end

        local cancelCallback = self._onCancel
        self:Destroy()
        if cancelCallback then
                cancelCallback()
        end
end

function IslandSelection:_addStatSection(title, icon, entries, textSize)
        if not entries or #entries == 0 then
                return
        end

	local section = Instance.new("Frame")
	section.BackgroundTransparency = 1
	section.Size = UDim2.new(1, 0, 0, 0)
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Parent = self._statsFrame

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamSemibold
	header.TextSize = 18
	header.TextColor3 = Theme.textColor()
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = string.format("%s %s", icon, title)
	header.Size = UDim2.new(1, 0, 0, 24)
	header.Parent = section

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.new(0, 0, 0, 26)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = section

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	for _, entry in ipairs(entries) do
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Gotham
		row.TextSize = textSize or 16  -- Use provided text size or default to 16
		row.TextColor3 = Theme.secondaryTextColor()
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Size = UDim2.new(1, 0, 0, textSize and textSize + 4 or 20)  -- Adjust height based on text size
		row.Text = "• " .. entry
		row.Parent = list
	end
end

function IslandSelection:_updateLayout()
	if not self._container or not self._layout then
		return
	end

	local size = self._container.AbsoluteSize
	local portrait = size.X < 720

	if portrait then
		self._layout.FillDirection = Enum.FillDirection.Vertical
		self._listColumn.Size = UDim2.fromScale(0.92, 0.45)
		self._detailColumn.Size = UDim2.fromScale(0.92, 0.45)
	else
		self._layout.FillDirection = Enum.FillDirection.Horizontal
		self._listColumn.Size = UDim2.fromScale(0.45, 0.88)
		self._detailColumn.Size = UDim2.fromScale(0.48, 0.88)
	end
end

function IslandSelection:_findTemplate(templateId: string): GameTypes.IslandTemplate?
	for _, template in ipairs(self._templates) do
		if template.id == templateId then
			return template
		end
	end
	return nil
end

function IslandSelection:Destroy()
        if self._destroyed then
                return
        end

        self._destroyed = true

        for _, connection in ipairs(self._connections) do
                connection:Disconnect()
        end
        table.clear(self._connections)

        if self._screenGui then
                self._screenGui:Destroy()
                self._screenGui = nil
        end
        self._cards = {}
end

return IslandSelection
