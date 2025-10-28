local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local AvatarKit = script.Parent

local function newFallbackCatalog()
	local catalog = {}

	catalog.SkinTones = {
		{ id = "peach01", color = Color3.fromRGB(247, 224, 211) },
		{ id = "peach02", color = Color3.fromRGB(237, 196, 164) },
		{ id = "tan01", color = Color3.fromRGB(213, 163, 139) },
		{ id = "tan02", color = Color3.fromRGB(196, 142, 124) },
		{ id = "brown01", color = Color3.fromRGB(161, 114, 95) },
		{ id = "brown02", color = Color3.fromRGB(124, 86, 70) },
	}

	catalog.EyeColors = {
		Color3.fromRGB(47, 47, 47),
		Color3.fromRGB(42, 109, 178),
		Color3.fromRGB(43, 160, 126),
		Color3.fromRGB(124, 74, 149),
	}

	catalog.Eyes = {
		{ id = "roundLarge", size = { 0.31, 0.23 }, pos = { 0.50, 0.58 } },
		{ id = "ovalSoft", size = { 0.31, 0.20 }, pos = { 0.50, 0.60 } },
		{ id = "smileEyes", size = { 0.31, 0.18 }, pos = { 0.50, 0.62 } },
	}

	catalog.Brows = {
		{ id = "soft", size = { 0.31, 0.10 }, pos = { 0.50, 0.43 } },
		{ id = "thick", size = { 0.31, 0.11 }, pos = { 0.50, 0.41 } },
		{ id = "arched", size = { 0.31, 0.10 }, pos = { 0.50, 0.42 } },
	}

	catalog.Noses = {
		{ id = "triangle", size = { 0.08, 0.08 }, pos = { 0.50, 0.65 } },
		{ id = "dot", size = { 0.06, 0.06 }, pos = { 0.50, 0.66 } },
	}

	catalog.Mouths = {
		{ id = "smile", size = { 0.31, 0.16 }, pos = { 0.50, 0.75 } },
		{ id = "open", size = { 0.31, 0.18 }, pos = { 0.50, 0.76 } },
		{ id = "catMouth", size = { 0.31, 0.14 }, pos = { 0.50, 0.76 } },
	}

	catalog.Hair = {
		{ id = "bob", refPath = "" },
		{ id = "sidebun", refPath = "" },
		{ id = "spiky", refPath = "" },
	}

	catalog.Outfits = {
		Tops = {
			{ id = "bowCoat", templateId = 0 },
			{ id = "plainTee", templateId = 0 },
		},
		Bottoms = {
			{ id = "skirtA", templateId = 0 },
			{ id = "pantsA", templateId = 0 },
		},
		Shoes = {
			{ id = "bootsA", accessoryPath = "" },
			{ id = "sneaksA", accessoryPath = "" },
		},
	}

	catalog.Scales = {
		head = 1.55,
		height = 0.90,
		width = 0.90,
		depth = 0.90,
		proportion = 0.80,
	}

	function catalog.defaultProfile()
		return {
			version = 1,
			skinTone = catalog.SkinTones[2].id,
			eye = { id = catalog.Eyes[1].id, colorIndex = 1 },
			brow = { id = catalog.Brows[1].id },
			nose = { id = catalog.Noses[1].id },
			mouth = { id = catalog.Mouths[1].id },
			hair = { id = catalog.Hair[1].id, color = Color3.fromRGB(213, 145, 151) },
			outfit = {
				top = catalog.Outfits.Tops[2].id,
				bottom = catalog.Outfits.Bottoms[2].id,
				shoes = catalog.Outfits.Shoes[2].id,
			},
			scales = table.clone(catalog.Scales),
		}
	end

	return catalog
end

local function newFallbackAvatarBuilder()
	return {
		applyProfile = function() end,
		spawnPreview = function()
			return nil
		end,
	}
end

local function newFallbackFaceController()
	return {
		attach = function() end,
	}
end

local function loadModule(container: Instance?, moduleName: string, description: string, fallbackFactory)
	if container then
		local module = container:FindFirstChild(moduleName)
		if module and module:IsA("ModuleScript") then
			local ok, result = pcall(require, module)
			if ok then
				return result
			else
				warn(string.format("[CharacterEditor] Failed to require %s: %s", moduleName, tostring(result)))
			end
		end
	end

	warn(string.format("[CharacterEditor] %s missing; using fallback implementation.", description))
	return fallbackFactory()
end

local Catalog = loadModule(AvatarKit, "Catalog", "AvatarKit Catalog", newFallbackCatalog)
local AvatarBuilder = loadModule(AvatarKit, "AvatarBuilder", "AvatarKit AvatarBuilder", newFallbackAvatarBuilder)
local FaceController = loadModule(AvatarKit, "FaceController", "AvatarKit FaceController", newFallbackFaceController)

local RemotesFolder = AvatarKit:FindFirstChild("Remotes")

local CharacterEditor = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local requestSaveRemote: RemoteFunction? = nil
local function getRequestSaveRemote(): RemoteFunction?
	if requestSaveRemote then
		return requestSaveRemote
	end

	if not RemotesFolder then
		RemotesFolder = Instance.new("Folder")
		RemotesFolder.Name = "Remotes"
		RemotesFolder.Parent = AvatarKit
	end

	local remote = RemotesFolder:FindFirstChild("RequestSave") :: RemoteFunction?
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = "RequestSave"
		remote.Parent = RemotesFolder
	end

	requestSaveRemote = remote
	return requestSaveRemote
end

local state = {
	gui = nil :: ScreenGui?,
	main = nil :: Frame?,
	content = nil :: Frame?,
	pageButtons = {} :: { [string]: TextButton },
	currentPage = "",
	profile = nil :: table?,
	previewViewport = nil :: ViewportFrame?,
	previewRig = nil :: Model?,
	isOpen = false,
	hasOpened = false,
}

local PAGES = { "Skin", "Face", "Hair", "Outfit" }

local HAIR_COLORS = {
	Color3.fromRGB(227, 122, 143),
	Color3.fromRGB(196, 140, 93),
	Color3.fromRGB(134, 100, 76),
	Color3.fromRGB(88, 64, 56),
	Color3.fromRGB(65, 74, 97),
	Color3.fromRGB(49, 49, 49),
}

local function clearChildren(instance: Instance)
	for _, child in ipairs(instance:GetChildren()) do
		child:Destroy()
	end
end

local function showError(message: string)
	print("[CharacterEditor] ERROR: " .. message)
	if state.gui then
		state.gui.Enabled = true
		
		-- Clear any existing error displays
		for _, child in ipairs(state.gui:GetChildren()) do
			if child.Name == "ErrorPanel" then
				child:Destroy()
			end
		end
		
		-- Create error panel
		local errorPanel = Instance.new("Frame")
		errorPanel.Name = "ErrorPanel"
		errorPanel.Size = UDim2.fromScale(1, 1)
		errorPanel.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		errorPanel.BackgroundTransparency = 0.7
		errorPanel.ZIndex = 200
		errorPanel.Parent = state.gui
		
		-- Error message
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.fromScale(0.8, 0.2)
		errorLabel.Position = UDim2.fromScale(0.1, 0.4)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Font = Enum.Font.GothamBold
		errorLabel.TextSize = 24
		errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		errorLabel.Text = "⚠️  " .. message
		errorLabel.TextWrapped = true
		errorLabel.Parent = errorPanel
		
		-- Auto-close after 5 seconds
		task.delay(5, function()
			if errorPanel and errorPanel.Parent then
				errorPanel:Destroy()
			end
		end)
	end
end

local function ensureProfile()
	if state.profile then
		return state.profile
	end

	print("[CharacterEditor] ensureProfile: fetching profile from server...")
	local remote = getRequestSaveRemote()
	local fetchedProfile
	if remote then
		local ok, result = pcall(function()
			print("[CharacterEditor] ensureProfile: invoking RequestSave remote...")
			-- Use timeout to prevent hanging
			local success = false
			local profile = nil
			
			task.spawn(function()
				local invokeOk, invokeResult = pcall(function()
					return remote:InvokeServer(nil)
				end)
				if invokeOk and typeof(invokeResult) == "table" then
					profile = invokeResult
					success = true
					print("[CharacterEditor] ensureProfile: received profile from server")
				else
					if not invokeOk then
						print("[CharacterEditor] ensureProfile: server invoke error - " .. tostring(invokeResult))
					else
						print("[CharacterEditor] ensureProfile: server returned non-table: " .. typeof(invokeResult))
					end
				end
			end)
			
			-- Wait max 2 seconds for response
			local waited = 0
			while not success and waited < 20 do
				task.wait(0.1)
				waited = waited + 1
			end
			
			if success then
				return profile
			else
				print("[CharacterEditor] ensureProfile: server timeout, using default")
				return nil
			end
		end)
		if ok and result then
			fetchedProfile = result
		elseif not ok then
			print("[CharacterEditor] ensureProfile: pcall error - " .. tostring(result))
		end
	else
		print("[CharacterEditor] ensureProfile: RequestSave remote not found")
	end

	state.profile = fetchedProfile or Catalog.defaultProfile()
	print("[CharacterEditor] ensureProfile: profile ready (fetched=" .. tostring(fetchedProfile ~= nil) .. ")")
	return state.profile
end

local function ensurePreview()
	if state.previewRig and state.previewRig.Parent then
		return
	end

	print("[CharacterEditor] ensurePreview: initializing preview rig")
	
	if not state.previewViewport then
		print("[CharacterEditor] ensurePreview: no viewport, returning")
		return
	end

	local rig = AvatarBuilder.spawnPreview(state.previewViewport)
	if not rig then
		print("[CharacterEditor] ensurePreview: failed to spawn rig")
		return
	end

	print("[CharacterEditor] ensurePreview: rig spawned, applying profile")
	state.previewRig = rig
	task.defer(function()
		AvatarBuilder.applyProfile(rig, ensureProfile())
		FaceController.attach(rig)
		print("[CharacterEditor] ensurePreview: profile applied and face controller attached")
	end)
end

local function repaint()
	if not state.previewRig or not state.previewRig.Parent then
		ensurePreview()
	end
	if state.previewRig and state.profile then
		AvatarBuilder.applyProfile(state.previewRig, state.profile)
	end
end

local function createMainGui()
	if state.gui then
		return
	end

	print("[CharacterEditor] Creating main GUI...")
	
	if not playerGui then
		warn("[CharacterEditor] ERROR: playerGui is nil!")
		return
	end

    local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CharacterEditorGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.DisplayOrder = 500 -- ensure above HUD
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	state.gui = screenGui
	
	print("[CharacterEditor] ScreenGui created and parented")

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "Main"
	mainFrame.Size = UDim2.fromScale(1, 1)
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 25)
	mainFrame.Parent = screenGui
	state.main = mainFrame
	
	-- 🎨 CLOSE BUTTON (top-right X)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 60, 0, 60)
	closeButton.Position = UDim2.new(1, -80, 0, 20)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)  -- Red
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 32
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Text = "✕"
	closeButton.AutoButtonColor = false
	closeButton.ZIndex = 100
	closeButton.Parent = screenGui
	
	-- Corner and hover effect
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(240, 73, 89)
	end)
	
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	end)
	
	closeButton.Activated:Connect(function()
		print("[CharacterEditor] Close button clicked")
		CharacterEditor.hide()
	end)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 24)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 20)  -- More spacing between preview and panel
	layout.Parent = mainFrame

	local preview = Instance.new("ViewportFrame")
	preview.Name = "Preview"
	preview.BackgroundTransparency = 1
	preview.Size = UDim2.fromScale(0.48, 1)
	preview.LayoutOrder = 1
	preview.Parent = mainFrame
	state.previewViewport = preview

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(0.52, 1)
	panel.BackgroundTransparency = 0.05
	panel.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
	panel.LayoutOrder = 2
	panel.Parent = mainFrame

	local panelPadding = Instance.new("UIPadding")
	panelPadding.PaddingTop = UDim.new(0, 20)
	panelPadding.PaddingBottom = UDim.new(0, 20)
	panelPadding.PaddingLeft = UDim.new(0, 20)
	panelPadding.PaddingRight = UDim.new(0, 20)
	panelPadding.Parent = panel

	local pagesRow = Instance.new("Frame")
	pagesRow.Name = "Tabs"
	pagesRow.Size = UDim2.fromScale(1, 0.10)
	pagesRow.BackgroundTransparency = 1
	pagesRow.Parent = panel

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabsLayout.Padding = UDim.new(0, 10)
	tabsLayout.Parent = pagesRow

	for _, pageName in ipairs(PAGES) do
		local button = Instance.new("TextButton")
		button.Name = pageName .. "Button"
		button.Size = UDim2.new(1 / #PAGES, -10, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
		button.BackgroundTransparency = 0.05
		button.AutoButtonColor = false
		button.Font = Enum.Font.GothamSemibold
		button.TextSize = 16
		button.TextColor3 = Color3.fromRGB(238, 244, 255)
		button.Text = pageName
		button.Parent = pagesRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		button.Activated:Connect(function()
			CharacterEditor.showPage(pageName)
		end)

		state.pageButtons[pageName] = button
	end

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromScale(0, 0.12)
	content.Size = UDim2.fromScale(1, 0.78)
	content.Parent = panel
	state.content = content

	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.fromScale(1, 0.08)
	saveButton.Position = UDim2.fromScale(0, 0.90)
	saveButton.BackgroundColor3 = Color3.fromRGB(86, 162, 118)
	saveButton.Font = Enum.Font.GothamSemibold
	saveButton.TextSize = 18
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.Text = "Save & Play"
	saveButton.AutoButtonColor = true
	saveButton.Parent = panel

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 10)
	saveCorner.Parent = saveButton

	saveButton.Activated:Connect(function()
		if not state.profile then
			return
		end

		local remote = getRequestSaveRemote()
		if not remote then
			saveButton.Text = "Remote missing"
			return
		end

		saveButton.Text = "Saving..."
		local ok, result = pcall(function()
			return remote:InvokeServer(state.profile)
		end)
		if ok and typeof(result) == "table" then
			state.profile = result
			saveButton.Text = "Saved!"
			task.defer(repaint)
			task.delay(1.8, function()
				if saveButton.Parent then
					saveButton.Text = "Save & Play"
				end
			end)
			CharacterEditor.hide()
		else
			saveButton.Text = "Retry? Save failed"
			task.delay(2, function()
				if saveButton.Parent then
					saveButton.Text = "Save & Play"
				end
			end)
		end
	end)
end

local function buildList(parent: Instance, items, getText, onSelect)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarThickness = 6
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroller

	for _, item in ipairs(items) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 48)
		button.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
		button.AutoButtonColor = true
		button.Font = Enum.Font.Gotham
		button.TextSize = 16
		button.TextColor3 = Color3.fromRGB(235, 238, 248)
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Text = getText(item)
		button.Parent = scroller

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.Parent = button

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		button.Activated:Connect(function()
			onSelect(item)
		end)
	end
end

local function populateSkinPage(container: Frame)
	local grid = Instance.new("Frame")
	grid.Name = "SkinGrid"
	grid.Size = UDim2.fromScale(1, 1)
	grid.BackgroundTransparency = 1
	grid.Parent = container

	local columns = 3
	for index, tone in ipairs(Catalog.SkinTones) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1 / columns - 0.02, 0, 0.16, 0)
		local row = math.floor((index - 1) / columns)
		local col = (index - 1) % columns
		button.Position = UDim2.new(col / columns, col * 4, row * 0.18, row * 8)
		button.AutoButtonColor = false
		button.BackgroundColor3 = tone.color
		button.BorderSizePixel = 0
		button.Text = ""
		button.Parent = grid

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		button.Activated:Connect(function()
			state.profile = ensureProfile()
			state.profile.skinTone = tone.id
			repaint()
		end)
	end
end

local function populateFacePage(container: Frame)
	local faceLayout = Instance.new("UIListLayout")
	faceLayout.FillDirection = Enum.FillDirection.Vertical
	faceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	faceLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	faceLayout.Padding = UDim.new(0, 12)
	faceLayout.Parent = container

	local eyesFrame = Instance.new("Frame")
	eyesFrame.Size = UDim2.fromScale(1, 0.35)
	eyesFrame.BackgroundTransparency = 1
	eyesFrame.Parent = container

	local eyesList = Instance.new("Frame")
	eyesList.Size = UDim2.fromScale(0.55, 1)
	eyesList.BackgroundTransparency = 1
	eyesList.Parent = eyesFrame

	buildList(eyesList, Catalog.Eyes, function(item)
		return "Eyes • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.eye.id = item.id
		repaint()
	end)

	local eyeColors = Instance.new("Frame")
	eyeColors.Size = UDim2.fromScale(0.45, 1)
	eyeColors.Position = UDim2.fromScale(0.55, 0)
	eyeColors.BackgroundTransparency = 1
	eyeColors.Parent = eyesFrame

	for index, color in ipairs(Catalog.EyeColors) do
		local swatch = Instance.new("TextButton")
		swatch.Size = UDim2.new(0.45, 0, 0.18, 0)
		local row = math.floor((index - 1) / 2)
		local col = (index - 1) % 2
		swatch.Position = UDim2.new(col * 0.5, col * 8, row * 0.22, row * 8)
		swatch.BackgroundColor3 = color
		swatch.AutoButtonColor = false
		swatch.Text = ""
		swatch.Parent = eyeColors

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = swatch

		swatch.Activated:Connect(function()
			state.profile = ensureProfile()
			state.profile.eye.colorIndex = index
			repaint()
		end)
	end

	local browRow = Instance.new("Frame")
	browRow.Size = UDim2.fromScale(1, 0.2)
	browRow.BackgroundTransparency = 1
	browRow.Parent = container
	buildList(browRow, Catalog.Brows, function(item)
		return "Brows • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.brow.id = item.id
		repaint()
	end)

	local lowerRow = Instance.new("Frame")
	lowerRow.Size = UDim2.fromScale(1, 0.4)
	lowerRow.BackgroundTransparency = 1
	lowerRow.Parent = container

	local noseFrame = Instance.new("Frame")
	noseFrame.Size = UDim2.fromScale(0.5, 1)
	noseFrame.BackgroundTransparency = 1
	noseFrame.Parent = lowerRow
	buildList(noseFrame, Catalog.Noses, function(item)
		return "Nose • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.nose.id = item.id
		repaint()
	end)

	local mouthFrame = Instance.new("Frame")
	mouthFrame.Size = UDim2.fromScale(0.5, 1)
	mouthFrame.Position = UDim2.fromScale(0.5, 0)
	mouthFrame.BackgroundTransparency = 1
	mouthFrame.Parent = lowerRow
	buildList(mouthFrame, Catalog.Mouths, function(item)
		return "Mouth • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.mouth.id = item.id
		repaint()
	end)
end

local function populateHairPage(container: Frame)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 12)
	layout.Parent = container

	local hairListFrame = Instance.new("Frame")
	hairListFrame.Size = UDim2.fromScale(1, 0.5)
	hairListFrame.BackgroundTransparency = 1
	hairListFrame.Parent = container

	buildList(hairListFrame, Catalog.Hair, function(item)
		return "Style • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.hair.id = item.id
		repaint()
	end)

	local colorFrame = Instance.new("Frame")
	colorFrame.Size = UDim2.fromScale(1, 0.5)
	colorFrame.BackgroundTransparency = 1
	colorFrame.Parent = container

	local cols = 3
	for index, color in ipairs(HAIR_COLORS) do
		local button = Instance.new("TextButton")
		local row = math.floor((index - 1) / cols)
		local col = (index - 1) % cols
		button.Size = UDim2.new(1 / cols - 0.02, 0, 0.24, 0)
		button.Position = UDim2.new(col / cols, col * 6, row * 0.26, row * 6)
		button.BackgroundColor3 = color
		button.AutoButtonColor = false
		button.Text = ""
		button.Parent = colorFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		button.Activated:Connect(function()
			state.profile = ensureProfile()
			state.profile.hair.color = color
			repaint()
		end)
	end
end

local function populateOutfitPage(container: Frame)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container

	local topsFrame = Instance.new("Frame")
	topsFrame.Size = UDim2.fromScale(1, 0.33)
	topsFrame.BackgroundTransparency = 1
	topsFrame.Parent = container

	buildList(topsFrame, Catalog.Outfits.Tops, function(item)
		return "Top • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.outfit.top = item.id
		repaint()
	end)

	local bottomsFrame = Instance.new("Frame")
	bottomsFrame.Size = UDim2.fromScale(1, 0.33)
	bottomsFrame.BackgroundTransparency = 1
	bottomsFrame.Parent = container

	buildList(bottomsFrame, Catalog.Outfits.Bottoms, function(item)
		return "Bottom • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.outfit.bottom = item.id
		repaint()
	end)

	local shoesFrame = Instance.new("Frame")
	shoesFrame.Size = UDim2.fromScale(1, 0.34)
	shoesFrame.BackgroundTransparency = 1
	shoesFrame.Parent = container

	buildList(shoesFrame, Catalog.Outfits.Shoes, function(item)
		return "Shoes • " .. item.id
	end, function(item)
		state.profile = ensureProfile()
		state.profile.outfit.shoes = item.id
		repaint()
	end)
end

local pageRenderers = {
	Skin = populateSkinPage,
	Face = populateFacePage,
	Hair = populateHairPage,
	Outfit = populateOutfitPage,
}

function CharacterEditor.showPage(pageName: string)
	if not state.gui then
		return
	end

	state.currentPage = pageName
	if state.content then
		clearChildren(state.content)
		local builder = pageRenderers[pageName]
		if builder then
			builder(state.content)
		end
	end

	for name, button in pairs(state.pageButtons) do
		if button then
			button.BackgroundColor3 = name == pageName and Color3.fromRGB(61, 104, 144) or Color3.fromRGB(35, 42, 58)
		end
	end
end

function CharacterEditor.show()
	print("[CharacterEditor.show] Called")
	print("[CharacterEditor.show] About to call createMainGui")
	createMainGui()
	print("[CharacterEditor.show] createMainGui completed")
	print("[CharacterEditor.show] About to call ensureProfile")
	ensureProfile()
	print("[CharacterEditor.show] ensureProfile completed")
	print("[CharacterEditor.show] About to call ensurePreview")
	ensurePreview()
	print("[CharacterEditor.show] ensurePreview completed")

	if state.gui then
		print("[CharacterEditor.show] state.gui exists, enabling")
		state.gui.Enabled = true
		
		-- 🎬 Fade in animation (on mainFrame, not screenGui)
		if state.main then
			state.main.BackgroundTransparency = 1
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(state.main, tweenInfo, {BackgroundTransparency = 0.2})
			tween:Play()
		end
	else
		warn("[CharacterEditor.show] ERROR: state.gui is nil!")
		showError("Failed to create character editor interface")
		return
	end
	state.isOpen = true
	state.hasOpened = true
	CharacterEditor.showPage(state.currentPage ~= "" and state.currentPage or "Skin")
	repaint()
	print("[CharacterEditor.show] show() completed successfully")
end

function CharacterEditor.hide()
	if state.main then
		-- 🎬 Fade out animation (on mainFrame, not screenGui)
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(state.main, tweenInfo, {BackgroundTransparency = 1})
		tween.Completed:Connect(function()
			if state.gui then
				state.gui.Enabled = false
			end
			print("[CharacterEditor] Hide animation completed")
		end)
		tween:Play()
	end
	state.isOpen = false
end

function CharacterEditor.toggle()
	if state.isOpen then
		CharacterEditor.hide()
	else
		CharacterEditor.show()
	end
end

function CharacterEditor.promptOnce()
	if not state.hasOpened then
		CharacterEditor.show()
	end
end

local function attachFaceControllerToCharacter(character: Model)
	task.defer(function()
		FaceController.attach(character)
	end)
end

player.CharacterAdded:Connect(attachFaceControllerToCharacter)
if player.Character then
	attachFaceControllerToCharacter(player.Character)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F7 then
		CharacterEditor.toggle()
	end
end)

return CharacterEditor
