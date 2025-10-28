
--[[
	ResponsiveUI
	Utility module for creating cross-platform responsive UI elements
	Handles different screen sizes, aspect ratios, and input methods
]]

-- Use the same safe gameInstance pattern as other modules so analysis tools
-- can resolve services in non-Studio environments.

local gameInstance = game or _G.game
if not gameInstance then
	error("ResponsiveUI requires a Roblox game context to resolve services")
end

local GuiService = gameInstance:GetService("GuiService")
local UserInputService = gameInstance:GetService("UserInputService")
-- Prefer GetService for Workspace to make static analysis happier in some environments
local Workspace = (gameInstance and gameInstance.GetService) and gameInstance:GetService("Workspace") or workspace

local ResponsiveUI = {}

function ResponsiveUI.getDeviceType()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	elseif UserInputService.GamepadEnabled then
		return "Console"
	else
		return "Desktop"
	end
end

function ResponsiveUI.getScreenInsets()
	local insets = GuiService:GetGuiInset()
	return {
		top = math.max(insets.Y, 20),
		bottom = 20,
		left = math.max(insets.X, 20),
		right = 20,
	}
end

function ResponsiveUI.responsiveSize(width, height, minWidth, minHeight)
	local scale = math.min(1, Workspace.CurrentCamera.ViewportSize.X / 1920) -- Base on 1920px width
	
	return UDim2.new(
		0, math.max(width * scale, minWidth or width * 0.5),
		0, math.max(height * scale, minHeight or height * 0.5)
	)
end

function ResponsiveUI.safePosition(xScale, yScale, xOffset, yOffset)
	local insets = ResponsiveUI.getScreenInsets()
	
	return UDim2.new(
		xScale, (xOffset or 0) + (xScale < 0.5 and insets.left or -insets.right),
		yScale, (yOffset or 0) + (yScale < 0.5 and insets.top or -insets.bottom)
	)
end

function ResponsiveUI.responsiveTextSize(baseSize)
	local scale = math.min(1, Workspace.CurrentCamera.ViewportSize.X / 1920)
	return math.max(math.floor(baseSize * scale), 12) -- Minimum 12px
end

function ResponsiveUI.addConstraints(guiObject, config)
	-- config expected to be a table with optional fields:
	-- config.minSize, config.maxSize, config.aspectRatio, config.textScaled
	-- Size constraints
	if config.minSize or config.maxSize then
		local sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.MinSize = config.minSize or Vector2.new(0, 0)
		sizeConstraint.MaxSize = config.maxSize or Vector2.new(math.huge, math.huge)
		sizeConstraint.Parent = guiObject
	end
	
	-- Aspect ratio
	if config.aspectRatio then
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = config.aspectRatio
		aspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
		aspectRatio.Parent = guiObject
	end
	
	-- Text scaling
	if config.textScaled and guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
		guiObject.TextScaled = true
		local textSizeConstraint = Instance.new("UITextSizeConstraint")
		textSizeConstraint.MaxTextSize = guiObject.TextSize
		textSizeConstraint.MinTextSize = 12
		textSizeConstraint.Parent = guiObject
	end
end

function ResponsiveUI.createMobileButton(config)
	-- config expected to be a table with fields:
	-- name, text, size?, position?, backgroundColor?, textColor?, font?, cornerRadius?
	local button = Instance.new("TextButton")
	button.Name = config.name
	button.Text = config.text
	button.Size = config.size or UDim2.new(0, 150, 0, 50)
	button.Position = config.position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = config.backgroundColor or Color3.fromRGB(139, 195, 74)
	button.TextColor3 = config.textColor or Color3.fromRGB(255, 255, 255)
	button.Font = config.font or Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	
	-- Make text responsive
	button.TextScaled = true
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 20
	textConstraint.MinTextSize = 12
	textConstraint.Parent = button
	
	-- Add corner radius
	if config.cornerRadius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, config.cornerRadius)
		corner.Parent = button
	end
	
	-- Minimum size for touch targets (44x44pt on iOS guidelines)
	ResponsiveUI.addConstraints(button, {
		minSize = Vector2.new(88, 88) -- 2x for better UX
	})
	
	return button
end

function ResponsiveUI.createPadding(parent, padding)
	local uiPadding = Instance.new("UIPadding")
	
	if type(padding) == "number" then
		uiPadding.PaddingTop = UDim.new(0, padding)
		uiPadding.PaddingBottom = UDim.new(0, padding)
		uiPadding.PaddingLeft = UDim.new(0, padding)
		uiPadding.PaddingRight = UDim.new(0, padding)
	else
		uiPadding.PaddingTop = UDim.new(0, padding.top)
		uiPadding.PaddingBottom = UDim.new(0, padding.bottom)
		uiPadding.PaddingLeft = UDim.new(0, padding.left)
		uiPadding.PaddingRight = UDim.new(0, padding.right)
	end
	
	uiPadding.Parent = parent
	return uiPadding
end

function ResponsiveUI.scale(value)
	local viewport = Workspace.CurrentCamera.ViewportSize
	local baseWidth = 1920
	return math.floor(value * (viewport.X / baseWidth))
end

function ResponsiveUI.isTouchDevice()
	return UserInputService.TouchEnabled
end

function ResponsiveUI.isGamepadActive()
	return UserInputService.GamepadEnabled
end

function ResponsiveUI.createGridLayout(config)
	-- config: { cellSize, cellPadding?, fillDirection?, startCorner? }
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = config.cellSize
	grid.CellPadding = config.cellPadding or UDim2.new(0, 10, 0, 10)
	grid.FillDirection = config.fillDirection or Enum.FillDirection.Horizontal
	grid.StartCorner = config.startCorner or Enum.StartCorner.TopLeft
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	return grid
end

function ResponsiveUI.createListLayout(config)
	-- config: { padding?, fillDirection?, horizontalAlignment?, verticalAlignment? }
	local list = Instance.new("UIListLayout")
	list.Padding = config.padding or UDim.new(0, 10)
	list.FillDirection = config.fillDirection or Enum.FillDirection.Vertical
	list.HorizontalAlignment = config.horizontalAlignment or Enum.HorizontalAlignment.Center
	list.VerticalAlignment = config.verticalAlignment or Enum.VerticalAlignment.Top
	list.SortOrder = Enum.SortOrder.LayoutOrder
	return list
end

function ResponsiveUI.animateIn(guiObject, direction, duration)
	duration = duration or 0.3
	
	local originalPosition = guiObject.Position
	local viewport = Workspace.CurrentCamera.ViewportSize
	
	-- Set starting position based on direction
	if direction == "top" then
		guiObject.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 0, -viewport.Y)
	elseif direction == "bottom" then
		guiObject.Position = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, viewport.Y)
	elseif direction == "left" then
		guiObject.Position = UDim2.new(0, -viewport.X, originalPosition.Y.Scale, originalPosition.Y.Offset)
	elseif direction == "right" then
		guiObject.Position = UDim2.new(1, viewport.X, originalPosition.Y.Scale, originalPosition.Y.Offset)
	end
	
	-- Animate to original position
	guiObject:TweenPosition(
		originalPosition,
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		duration,
		true
	)
end

function ResponsiveUI.pulse(guiObject, scale, duration)
	scale = scale or 1.1
	duration = duration or 0.2
	
	local originalSize = guiObject.Size
	
	guiObject:TweenSize(
		UDim2.new(originalSize.X.Scale * scale, 0, originalSize.Y.Scale * scale, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		duration,
		true,
		function()
			guiObject:TweenSize(
				originalSize,
				Enum.EasingDirection.In,
				Enum.EasingStyle.Quad,
				duration,
				true
			)
		end
	)
end

return ResponsiveUI
