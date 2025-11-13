--[[
	SettingsController.luau
	
	Client-side settings manager with a simple UI for camera options.
	Handles loading/saving settings via remotes, applies camera sensitivity/invert
	immediately, and exposes change notifications for other systems.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UserSettings = UserSettings()
local GameSettings = UserSettings and UserSettings.GameSettings

local LOCAL_PLAYER = Players.LocalPlayer
local REMOTE_FOLDER_NAME = "PlayerSettingsRemotes"
local GET_REMOTE_NAME = "GetSettings"
local SAVE_REMOTE_NAME = "SaveSettings"

local DEFAULT_SETTINGS = {
	cameraSensitivity = 1,
	invertVertical = false,
	blurIntensity = 0.25,
}

local SettingsController = {}
SettingsController.__index = SettingsController

local _state = table.clone(DEFAULT_SETTINGS)
local _initialized = false
local _guiManager = nil
local _screenGui: ScreenGui? = nil
local _changeEvent = Instance.new("BindableEvent")
local _saveDebounce = nil
local _getFunction: RemoteFunction? = nil
local _saveEvent: RemoteEvent? = nil
local _currentRowY = 0
local ROW_HEIGHT = 44
local ROW_PADDING = 10
local SLIDER_MIN_SENSITIVITY = 0.4
local SLIDER_MAX_SENSITIVITY = 2
local SLIDER_STEP_SENSITIVITY = 0.1
local SLIDER_MIN_BLUR = 0
local SLIDER_MAX_BLUR = 1
local SLIDER_STEP_BLUR = 0.05

local function cloneDefaults()
	local clone = {}
	for key, value in pairs(DEFAULT_SETTINGS) do
		clone[key] = value
	end
	return clone
end

local function getRemoteFolder()
	return ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 5)
end

local function sanitizeSettings(candidate)
	local sanitized = cloneDefaults()
	if type(candidate) ~= "table" then
		return sanitized
	end

	for key, defaultValue in pairs(DEFAULT_SETTINGS) do
		local newValue = candidate[key]
		if typeof(newValue) == typeof(defaultValue) then
			sanitized[key] = newValue
		end
	end

	return sanitized
end

local function applyGameSettings()
	if GameSettings then
		pcall(function()
			GameSettings.CameraSensitivity = _state.cameraSensitivity
		end)
		pcall(function()
			GameSettings.MouseSensitivityFirstPerson = _state.cameraSensitivity
		end)
		pcall(function()
			GameSettings.CameraYInvert = _state.invertVertical
		end)
	end

	UserInputService.MouseDeltaSensitivity = _state.cameraSensitivity
end

local function scheduleSave()
	if not _saveEvent then
		return
	end

	if _saveDebounce then
		return
	end

	_saveDebounce = task.delay(0.5, function()
		_saveDebounce = nil
		local ok, err = pcall(function()
			_saveEvent:FireServer(_state)
		end)
		if not ok then
			warn("[SettingsController] ⚠️ Failed to send settings to server:", err)
		end
	end)
end

local function fireChanged(key)
	_changeEvent:Fire(key, _state[key])
	applyGameSettings()
	
	-- Apply graphics quality changes
	if key == "shaderQuality" or key == "waterQuality" or key == "grassQuality" or 
	   key == "particleDensity" or key == "atmosphereQuality" or key == "bloomIntensity" or 
	   key == "colorCorrectionIntensity" then
		-- Update visual effects
		local VisualEffects = require(script.Parent.VisualEffects)
		if VisualEffects and VisualEffects.updateQuality then
			VisualEffects.updateQuality(_state)
		end
		
		-- Update particle effects
		local ParticleEffects = require(script.Parent.ParticleEffects)
		if ParticleEffects and ParticleEffects.updateQuality then
			ParticleEffects.updateQuality(_state)
		end
	end
	
	scheduleSave()
end

-- Forward declarations for tab builders (defined after createToggleRow/createSliderRow)
-- These will be assigned later in the file
local buildCameraTab = nil
local buildGraphicsTab = nil

local function createBaseGui()
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SettingsMenu"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local darken = Instance.new("Frame")
	darken.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	-- Make overlay fully transparent (no darken backdrop)
	darken.BackgroundTransparency = 1
	darken.Size = UDim2.fromScale(1, 1)
	darken.Parent = screenGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Position lower to avoid Roblox player GUI in top-left
	container.Position = UDim2.new(0.5, 0, 0.55, 0) -- Slightly lower than center
	container.Size = UDim2.new(0, 480, 0, 580) -- Slightly smaller
	container.BackgroundColor3 = Color3.fromRGB(32, 36, 40)
	container.BackgroundTransparency = 0.1
	container.Parent = darken

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 180, 255)
	stroke.Thickness = 1.5
	stroke.Parent = container

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(230, 240, 255)
	title.Text = "Settings"
	title.Parent = container

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 34, 0, 34)
	closeButton.Position = UDim2.new(1, -44, 0, 12)
	closeButton.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextScaled = true
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Text = "✕"
	closeButton.Parent = container

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeButton

	-- Tab buttons
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, -40, 0, 40)
	tabContainer.Position = UDim2.new(0, 20, 0, 50)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = container
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabContainer
	
	local cameraTab = Instance.new("TextButton")
	cameraTab.Name = "CameraTab"
	cameraTab.Size = UDim2.new(0, 120, 1, 0)
	cameraTab.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	cameraTab.Text = "Camera"
	cameraTab.Font = Enum.Font.GothamMedium
	cameraTab.TextSize = 16
	cameraTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	cameraTab.Parent = tabContainer
	
	local cameraTabCorner = Instance.new("UICorner")
	cameraTabCorner.CornerRadius = UDim.new(0, 6)
	cameraTabCorner.Parent = cameraTab
	
	local graphicsTab = Instance.new("TextButton")
	graphicsTab.Name = "GraphicsTab"
	graphicsTab.Size = UDim2.new(0, 120, 1, 0)
	graphicsTab.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
	graphicsTab.Text = "Graphics"
	graphicsTab.Font = Enum.Font.GothamMedium
	graphicsTab.TextSize = 16
	graphicsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	graphicsTab.Parent = tabContainer
	
	local graphicsTabCorner = Instance.new("UICorner")
	graphicsTabCorner.CornerRadius = UDim.new(0, 6)
	graphicsTabCorner.Parent = graphicsTab
	
	-- Scrollable content area
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ContentScroll"
	scrollFrame.Size = UDim2.new(1, -40, 1, -110)
	scrollFrame.Position = UDim2.new(0, 20, 0, 100)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.Parent = container
	
	local rowsFrame = Instance.new("Frame")
	rowsFrame.Name = "Rows"
	rowsFrame.BackgroundTransparency = 1
	rowsFrame.Size = UDim2.new(1, 0, 0, 0)
	rowsFrame.Position = UDim2.new(0, 0, 0, 0)
	rowsFrame.Parent = scrollFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, ROW_PADDING)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rowsFrame
	
	-- Auto-size scroll frame content
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		rowsFrame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)
	
	-- Tab switching
	local _currentTab = "camera"
	local function switchTab(tabName)
		_currentTab = tabName
		if tabName == "camera" then
			cameraTab.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
			cameraTab.TextColor3 = Color3.fromRGB(255, 255, 255)
			graphicsTab.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
			graphicsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		else
			cameraTab.BackgroundColor3 = Color3.fromRGB(50, 55, 60)
			cameraTab.TextColor3 = Color3.fromRGB(200, 200, 200)
			graphicsTab.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
			graphicsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		-- Rebuild UI for selected tab
		rowsFrame:ClearAllChildren()
		_currentRowY = 0
		if tabName == "camera" then
			if buildCameraTab then
				buildCameraTab(rowsFrame)
			else
				warn("[SettingsController] ⚠️ buildCameraTab not yet defined")
			end
		else
			if buildGraphicsTab then
				buildGraphicsTab(rowsFrame)
			else
				warn("[SettingsController] ⚠️ buildGraphicsTab not yet defined")
			end
		end
	end
	
	cameraTab.MouseButton1Click:Connect(function()
		switchTab("camera")
	end)
	
	graphicsTab.MouseButton1Click:Connect(function()
		switchTab("graphics")
	end)

	closeButton.MouseButton1Click:Connect(function()
		SettingsController.toggle(false)
	end)

	_screenGui = screenGui
	_currentRowY = 0

	return rowsFrame, switchTab
end

local function createToggleRow(parent, labelText, settingKey)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.fromRGB(41, 46, 52)
	row.BackgroundTransparency = 0.1
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.LayoutOrder = _currentRowY
	row.Parent = parent
	_currentRowY += 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, -10, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(220, 230, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.25, -10, 0.7, 0)
	button.Position = UDim2.new(0.72, 0, 0.15, 0)
	button.BackgroundColor3 = Color3.fromRGB(70, 80, 90)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = SettingsController.getSetting(settingKey) and "ON" or "OFF"
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local function updateButton()
		local enabled = SettingsController.getSetting(settingKey)
		button.Text = enabled and "ON" or "OFF"
		button.BackgroundColor3 = enabled and Color3.fromRGB(90, 150, 110) or Color3.fromRGB(70, 80, 90)
	end

	button.MouseButton1Click:Connect(function()
		local newValue = not SettingsController.getSetting(settingKey)
		SettingsController.setSetting(settingKey, newValue)
		updateButton()
	end)

	updateButton()
end

local function createSliderRow(parent, labelText, settingKey, minValue, maxValue, step)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.fromRGB(41, 46, 52)
	row.BackgroundTransparency = 0.1
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.LayoutOrder = _currentRowY
	row.Parent = parent
	_currentRowY += 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, -10, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(220, 230, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.55, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 18
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.Text = string.format("%.2f", SettingsController.getSetting(settingKey))
	valueLabel.Parent = row

	local minusButton = Instance.new("TextButton")
	minusButton.Size = UDim2.new(0, 34, 0, 34)
	minusButton.Position = UDim2.new(0.8, -40, 0.5, -17)
	minusButton.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	minusButton.Font = Enum.Font.GothamBold
	minusButton.TextSize = 20
	minusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	minusButton.Text = "-"
	minusButton.Parent = row

	local plusButton = Instance.new("TextButton")
	plusButton.Size = UDim2.new(0, 34, 0, 34)
	plusButton.Position = UDim2.new(0.8, 10, 0.5, -17)
	plusButton.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	plusButton.Font = Enum.Font.GothamBold
	plusButton.TextSize = 20
	plusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	plusButton.Text = "+"
	plusButton.Parent = row

	local function applyDelta(delta)
		local current = SettingsController.getSetting(settingKey)
		local newValue = math.clamp(current + delta, minValue, maxValue)
		newValue = math.round(newValue / step) * step
		newValue = math.clamp(newValue, minValue, maxValue)
		SettingsController.setSetting(settingKey, newValue)
		valueLabel.Text = string.format("%.2f", newValue)
	end

	minusButton.MouseButton1Click:Connect(function()
		applyDelta(-step)
	end)

	plusButton.MouseButton1Click:Connect(function()
		applyDelta(step)
	end)
end

-- Define tab builders after createToggleRow and createSliderRow are defined
-- Tab builders are defined later in the file (after createSliderRow)

local function loadSettingsFromServer()
	local folder = getRemoteFolder()
	if not folder then
		warn("[SettingsController] ⚠️ PlayerSettingsRemotes folder not found")
		_state = cloneDefaults()
		applyGameSettings()
		return
	end
	_getFunction = folder:FindFirstChild(GET_REMOTE_NAME)
	_saveEvent = folder:FindFirstChild(SAVE_REMOTE_NAME)

	if not _getFunction or not _getFunction:IsA("RemoteFunction") then
		warn("[SettingsController] ⚠️ GetSettings RemoteFunction missing")
		_state = cloneDefaults()
		applyGameSettings()
		return
	end

	local success, data = pcall(function()
		return _getFunction:InvokeServer()
	end)

	if success and type(data) == "table" then
		_state = sanitizeSettings(data)
	else
		if not success then
			warn("[SettingsController] ⚠️ Failed to load settings:", data)
		end
		_state = cloneDefaults()
	end

	applyGameSettings()
end

-- Assign to forward-declared variables (not "local function" which creates new variables)
buildCameraTab = function(parent)
	createToggleRow(parent, "Invert Vertical Look", "invertVertical")
	createSliderRow(parent, "Camera Sensitivity", "cameraSensitivity", SLIDER_MIN_SENSITIVITY, SLIDER_MAX_SENSITIVITY, SLIDER_STEP_SENSITIVITY)
	createSliderRow(parent, "Camera Blur Intensity", "blurIntensity", SLIDER_MIN_BLUR, SLIDER_MAX_BLUR, SLIDER_STEP_BLUR)
end

buildGraphicsTab = function(parent)
	createSliderRow(parent, "Shader Quality", "shaderQuality", 0, 1, 0.1)
	createSliderRow(parent, "Water Quality", "waterQuality", 0, 1, 0.1)
	createSliderRow(parent, "Grass Quality", "grassQuality", 0, 1, 0.1)
	createSliderRow(parent, "Particle Density", "particleDensity", 0, 1, 0.1)
	createSliderRow(parent, "Atmosphere Quality", "atmosphereQuality", 0, 1, 0.1)
	createSliderRow(parent, "Bloom Intensity", "bloomIntensity", 0, 1, 0.05)
	createSliderRow(parent, "Color Correction", "colorCorrectionIntensity", 0, 1, 0.1)
	
	-- Quality presets
	local presetRow = Instance.new("Frame")
	presetRow.BackgroundColor3 = Color3.fromRGB(41, 46, 52)
	presetRow.BackgroundTransparency = 0.1
	presetRow.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	presetRow.LayoutOrder = _currentRowY
	presetRow.Parent = parent
	_currentRowY += 1
	
	local presetCorner = Instance.new("UICorner")
	presetCorner.CornerRadius = UDim.new(0, 8)
	presetCorner.Parent = presetRow
	
	local presetLabel = Instance.new("TextLabel")
	presetLabel.Size = UDim2.new(0.4, -10, 1, 0)
	presetLabel.Position = UDim2.new(0, 10, 0, 0)
	presetLabel.BackgroundTransparency = 1
	presetLabel.Font = Enum.Font.GothamMedium
	presetLabel.TextSize = 18
	presetLabel.TextColor3 = Color3.fromRGB(220, 230, 240)
	presetLabel.TextXAlignment = Enum.TextXAlignment.Left
	presetLabel.Text = "Quality Preset"
	presetLabel.Parent = presetRow
	
	local function applyPreset(quality)
		local values = {
			low = {shaderQuality = 0.3, waterQuality = 0.3, grassQuality = 0.3, particleDensity = 0.3, atmosphereQuality = 0.3, bloomIntensity = 0.2, colorCorrectionIntensity = 0.5},
			medium = {shaderQuality = 0.6, waterQuality = 0.6, grassQuality = 0.6, particleDensity = 0.6, atmosphereQuality = 0.6, bloomIntensity = 0.3, colorCorrectionIntensity = 0.75},
			high = {shaderQuality = 0.8, waterQuality = 0.8, grassQuality = 0.8, particleDensity = 0.8, atmosphereQuality = 0.8, bloomIntensity = 0.4, colorCorrectionIntensity = 0.9},
			ultra = {shaderQuality = 1.0, waterQuality = 1.0, grassQuality = 1.0, particleDensity = 1.0, atmosphereQuality = 1.0, bloomIntensity = 0.5, colorCorrectionIntensity = 1.0},
		}
		local preset = values[quality]
		if preset then
			for key, value in pairs(preset) do
				SettingsController.setSetting(key, value)
			end
		end
	end
	
	local lowBtn = Instance.new("TextButton")
	lowBtn.Size = UDim2.new(0, 60, 0.7, 0)
	lowBtn.Position = UDim2.new(0.45, 0, 0.15, 0)
	lowBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	lowBtn.Text = "Low"
	lowBtn.Font = Enum.Font.GothamBold
	lowBtn.TextSize = 14
	lowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	lowBtn.Parent = presetRow
	lowBtn.MouseButton1Click:Connect(function() applyPreset("low") end)
	
	local medBtn = Instance.new("TextButton")
	medBtn.Size = UDim2.new(0, 60, 0.7, 0)
	medBtn.Position = UDim2.new(0.58, 0, 0.15, 0)
	medBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	medBtn.Text = "Med"
	medBtn.Font = Enum.Font.GothamBold
	medBtn.TextSize = 14
	medBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	medBtn.Parent = presetRow
	medBtn.MouseButton1Click:Connect(function() applyPreset("medium") end)
	
	local highBtn = Instance.new("TextButton")
	highBtn.Size = UDim2.new(0, 60, 0.7, 0)
	highBtn.Position = UDim2.new(0.71, 0, 0.15, 0)
	highBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	highBtn.Text = "High"
	highBtn.Font = Enum.Font.GothamBold
	highBtn.TextSize = 14
	highBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	highBtn.Parent = presetRow
	highBtn.MouseButton1Click:Connect(function() applyPreset("high") end)
	
	local ultraBtn = Instance.new("TextButton")
	ultraBtn.Size = UDim2.new(0, 60, 0.7, 0)
	ultraBtn.Position = UDim2.new(0.84, 0, 0.15, 0)
	ultraBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
	ultraBtn.Text = "Ultra"
	ultraBtn.Font = Enum.Font.GothamBold
	ultraBtn.TextSize = 14
	ultraBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ultraBtn.Parent = presetRow
	ultraBtn.MouseButton1Click:Connect(function() applyPreset("ultra") end)
end

local function buildUI()
	local rowsParent, _switchTab = createBaseGui()
	buildCameraTab(rowsParent) -- Start with camera tab
end

function SettingsController.init(options)
	if _initialized then
		if options and options.guiManager then
			_guiManager = options.guiManager
		end
		return SettingsController
	end

	if options and options.guiManager then
		_guiManager = options.guiManager
	end

	loadSettingsFromServer()
	buildUI()

	if _guiManager and _screenGui then
		_guiManager:registerGUI("settings", _screenGui)
	end

	applyGameSettings()
	_initialized = true

	return SettingsController
end

function SettingsController.toggle(forceValue)
	if not _screenGui then
		return
	end

	local target
	if typeof(forceValue) == "boolean" then
		target = forceValue
	else
		target = not _screenGui.Enabled
	end

	if _guiManager then
		if target then
			_guiManager:showGUI("settings")
		else
			_guiManager:hideGUI("settings")
		end
	else
		_screenGui.Enabled = target
	end
end

function SettingsController.setGuiManager(guiManager)
	_guiManager = guiManager
	if _guiManager and _screenGui then
		_guiManager:registerGUI("settings", _screenGui)
	end
end

function SettingsController.getSetting(key)
	return _state[key]
end

function SettingsController.setSetting(key, value)
	if DEFAULT_SETTINGS[key] == nil then
		return
	end

	if typeof(value) ~= typeof(DEFAULT_SETTINGS[key]) then
		return
	end

	if _state[key] == value then
		return
	end

	_state[key] = value
	fireChanged(key)
end

function SettingsController.onChanged(callback)
	return _changeEvent.Event:Connect(callback)
end

function SettingsController.getAll()
	local clone = {}
	for key, value in pairs(_state) do
		clone[key] = value
	end
	return clone
end

return SettingsController
