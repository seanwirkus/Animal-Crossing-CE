--[[
	GUIComponents - Reusable, responsive GUI components
	Provides building blocks for all game UIs with consistent styling
	Easy to restyle for Animal Crossing aesthetic later
]]

local TweenService = game:GetService("TweenService")

local GUIComponents = {}
GUIComponents.__index = GUIComponents

-- Default theme (can be overridden)
GUIComponents.DEFAULT_THEME = {
	primaryColor = Color3.fromRGB(76, 175, 80),
	secondaryColor = Color3.fromRGB(33, 150, 243),
	accentColor = Color3.fromRGB(255, 152, 0),
	backgroundColor = Color3.fromRGB(255, 250, 240),
	textColor = Color3.fromRGB(100, 100, 100),
	lightTextColor = Color3.fromRGB(120, 120, 120),
	borderColor = Color3.fromRGB(200, 200, 200),
	errorColor = Color3.fromRGB(244, 67, 54),
	successColor = Color3.fromRGB(76, 175, 80),
}

--[[
	Create a responsive panel that scales with screen size
]]
function GUIComponents.CreatePanel(parent, options)
	options = options or {}
	local minWidth = options.minWidth or 400
	local minHeight = options.minHeight or 300
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	
	local panel = Instance.new("Frame")
	panel.Name = options.name or "Panel"
	panel.BackgroundColor3 = theme.backgroundColor
	panel.BorderSizePixel = 0
	panel.Parent = parent
	
	-- Responsive sizing
	local screenSize = parent.AbsoluteSize
	local width = math.max(minWidth, screenSize.X * 0.8)
	local height = math.max(minHeight, screenSize.Y * 0.8)
	
	panel.Size = UDim2.new(0, math.min(width, screenSize.X - 40), 0, math.min(height, screenSize.Y - 40))
	panel.Position = UDim2.new(0.5, -panel.AbsoluteSize.X / 2, 0.5, -panel.AbsoluteSize.Y / 2)
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = panel
	
	return panel, theme
end

--[[
	Create a responsive button
]]
function GUIComponents.CreateButton(parent, options)
	options = options or {}
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	local text = options.text or "Button"
	local callback = options.callback or function() end
	local color = options.color or theme.primaryColor
	
	local button = Instance.new("TextButton")
	button.Name = options.name or "Button"
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = options.textSize or 24
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = parent
	
	-- Responsive sizing
	button.Size = UDim2.new(1, -40, 0, 60)
	button.Position = UDim2.new(0, 20, 0, options.position or 0)
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		local hoverColor = Color3.new(
			color.R * 0.9,
			color.G * 0.9,
			color.B * 0.9
		)
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = hoverColor
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = color
		}):Play()
	end)
	
	button.MouseButton1Click:Connect(callback)
	
	return button
end

--[[
	Create a responsive text input
]]
function GUIComponents.CreateTextInput(parent, options)
	options = options or {}
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	local label = options.label or "Input:"
	local placeholder = options.placeholder or "Enter text..."
	local callback = options.callback or function() end
	
	-- Label
	local labelText = Instance.new("TextLabel")
	labelText.Name = "Label"
	labelText.BackgroundTransparency = 1
	labelText.Text = label
	labelText.TextSize = 18
	labelText.Font = Enum.Font.GothamMedium
	labelText.TextColor3 = theme.textColor
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Size = UDim2.new(1, -40, 0, 30)
	labelText.Position = UDim2.new(0, 20, 0, options.labelPosition or 0)
	labelText.Parent = parent
	
	-- Input field
	local input = Instance.new("TextBox")
	input.Name = "TextInput"
	input.BackgroundColor3 = Color3.new(1, 1, 1)
	input.BorderSizePixel = 1
	input.BorderColor3 = theme.borderColor
	input.Text = options.defaultText or ""
	input.PlaceholderText = placeholder
	input.TextSize = 20
	input.Font = Enum.Font.Gotham
	input.TextColor3 = theme.textColor
	input.Size = UDim2.new(1, -40, 0, 50)
	input.Position = UDim2.new(0, 20, 0, (options.labelPosition or 0) + 35)
	input.Parent = parent
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = input
	
	-- Callback on text change
	input:GetPropertyChangedSignal("Text"):Connect(callback)
	
	return input, labelText
end

--[[
	Create a responsive title/heading
]]
function GUIComponents.CreateTitle(parent, options)
	options = options or {}
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	local text = options.text or "Title"
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextSize = options.textSize or 42
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = theme.textColor
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -40, 0, 80)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.Parent = parent
	
	return title
end

--[[
	Create a responsive info/description text
]]
function GUIComponents.CreateInfoText(parent, options)
	options = options or {}
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	local text = options.text or "Info text"
	
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoText"
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = text
	infoLabel.TextSize = options.textSize or 16
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextColor3 = theme.lightTextColor
	infoLabel.TextWrapped = true
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextYAlignment = Enum.TextYAlignment.Top
	infoLabel.Size = UDim2.new(1, -40, 0, options.height or 80)
	infoLabel.Position = UDim2.new(0, 20, 0, options.position or 0)
	infoLabel.Parent = parent
	
	return infoLabel
end

--[[
	Create a responsive close button
]]
function GUIComponents.CreateCloseButton(parent, options)
	options = options or {}
	local theme = options.theme or GUIComponents.DEFAULT_THEME
	local callback = options.callback or function() end
	
	local button = Instance.new("TextButton")
	button.Name = "CloseButton"
	button.Size = UDim2.new(0, 50, 0, 50)
	button.Position = UDim2.new(1, -70, 0, 10)
	button.BackgroundColor3 = theme.errorColor
	button.BorderSizePixel = 0
	button.Text = "✕"
	button.TextSize = 32
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	
	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(234, 57, 44)
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = theme.errorColor
		}):Play()
	end)
	
	button.MouseButton1Click:Connect(callback)
	
	return button
end

--[[
	Create a vertical list container with scroll support
]]
function GUIComponents.CreateListContainer(parent, options)
	options = options or {}
	
	local container = Instance.new("Frame")
	container.Name = "ListContainer"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, -40, 0, options.height or 200)
	container.Position = UDim2.new(0, 20, 0, options.position or 0)
	container.Parent = parent
	
	-- List layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = container
	
	return container
end

return GUIComponents
