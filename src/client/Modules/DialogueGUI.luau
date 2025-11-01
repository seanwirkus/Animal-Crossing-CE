--[[
	DialogueGUI.luau
	
	A sequential dialogue system for onboarding and villager conversations.
	Uses existing GUI structure from Roblox Studio.
	
	Expected structure in PlayerGui:
	- DialogueGUI (ScreenGui)
	  - DialogueFrame (Frame)
	    - UIListLayout (for vertical stacking)
	    - UIPadding (for spacing)
	    - VillagerCard templates (to be cloned)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")

local DialogueGUI = {}
DialogueGUI.__index = DialogueGUI

-- Default villager image placeholder
local DEFAULT_VILLAGER_IMAGE = "rbxassetid://6031075938"

-- Villager image mappings (using 2D PNG images)
local VILLAGER_IMAGES = {
	["Tom Nook"] = "rbxassetid://133891691065737", -- Tom Nook headshot PNG
	["Isabelle"] = DEFAULT_VILLAGER_IMAGE, -- TODO: Add Isabelle PNG
	["Timmy"] = DEFAULT_VILLAGER_IMAGE,
	["Tommy"] = DEFAULT_VILLAGER_IMAGE,
	["Blathers"] = DEFAULT_VILLAGER_IMAGE,
	["Orville"] = DEFAULT_VILLAGER_IMAGE,
}

-- Character data cache (loaded from JSON)
local CHARACTER_DATA = nil

--[[
	Simple toast notification system
]]
local function showToast(message, duration)
	duration = duration or 3
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Create toast notification
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.new(0, 0, 0, 50)
	toast.Position = UDim2.new(0.5, 0, 0.1, 0)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = Color3.fromRGB(72, 110, 72)
	toast.BorderSizePixel = 0
	toast.ZIndex = 100
	toast.Parent = playerGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(139, 195, 74)
	stroke.Thickness = 2
	stroke.Parent = toast
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -10)
	label.Position = UDim2.new(0, 10, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Parent = toast
	
	-- Update toast size based on text
	toast.Size = UDim2.new(0, math.max(200, label.TextBounds.X + 30), 0, math.max(40, label.TextBounds.Y + 20))
	
	-- Animate in
	toast.Size = UDim2.new(0, 0, 0, 50)
	local tweenIn = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, math.max(200, label.TextBounds.X + 30), 0, math.max(40, label.TextBounds.Y + 20))
	})
	tweenIn:Play()
	
	-- Auto-dismiss
	task.delay(duration, function()
		local tweenOut = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 50),
			BackgroundTransparency = 1
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		toast:Destroy()
	end)
end

DialogueGUI.showToast = showToast

--[[
	Create a new DialogueGUI instance
]]
function DialogueGUI.new()
	local self = setmetatable({}, DialogueGUI)
	
	self._player = Players.LocalPlayer
	self._playerGui = self._player:WaitForChild("PlayerGui")
	self._screenGui = nil
	self._dialogueFrame = nil
	self._listLayout = nil
	self._cards = {}
	self._currentSequence = {}
	self._currentIndex = 1
	self._onComplete = nil
	self._autoAdvance = false
	self._autoAdvanceDelay = 3
	self._cardTemplate = nil

	-- Single-card mode references (prevents duplicate cards)
	self._singleCard = nil
	self._nameLabelRef = nil
	self._dialogueTextRef = nil
	self._villagerImageRef = nil

	-- Skip arrow button reference
	self._skipButton = nil
	
	return self
end

-- Utility: find first descendant by class and optional name candidates
local function findDescendant(root: Instance, className: string, nameCandidates: {string}?)
    if not root then return nil end
    local found
    -- Prefer exact name matches among descendants of the given class
    if nameCandidates and #nameCandidates > 0 then
        for _, candidate in ipairs(nameCandidates) do
            local obj = root:FindFirstChild(candidate, true) -- recursive
            if obj and obj:IsA(className) then
                return obj
            end
        end
    end
    -- Fallback: first instance of class under root
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:IsA(className) then
            found = desc
            break
        end
    end
    return found
end

--[[
	Initialize by finding existing GUI structure
]]
function DialogueGUI:Init()
	if self._screenGui then
		return -- Already initialized
	end
	
	-- Look for existing DialogueGUI ScreenGui
	local screenGui = self._playerGui:FindFirstChild("DialogueGUI")
	if not screenGui then
		warn("[DialogueGUI] ❌ DialogueGUI ScreenGui not found in PlayerGui - make sure it exists in Roblox!")
		return false
	end
	
	print("[DialogueGUI] ✅ Found existing DialogueGUI ScreenGui")
	self._screenGui = screenGui
	
	-- Find DialogueFrame
	local dialogueFrame = screenGui:FindFirstChild("DialogueFrame")
	if not dialogueFrame then
		warn("[DialogueGUI] ❌ DialogueFrame not found in DialogueGUI")
		return false
	end
	
	print("[DialogueGUI] ✅ Found DialogueFrame")
	self._dialogueFrame = dialogueFrame
	
	-- Hide DialogueFrame by default
	dialogueFrame.Visible = false
	
	-- Find UIListLayout
	local listLayout = dialogueFrame:FindFirstChildOfClass("UIListLayout")
	if not listLayout then
		warn("[DialogueGUI] ⚠️ UIListLayout not found, creating it...")
		listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 15)
		listLayout.Parent = dialogueFrame
	end
	self._listLayout = listLayout
	
	-- Find UIPadding (optional)
	local padding = dialogueFrame:FindFirstChildOfClass("UIPadding")
	if padding then
		print("[DialogueGUI] ✅ Found existing UIPadding")
	else
		warn("[DialogueGUI] ⚠️ UIPadding not found (optional)")
	end
	
	-- Look for VillagerCard template (must be named exactly "VillagerCard")
	local cardTemplate = dialogueFrame:FindFirstChild("VillagerCard")
	if cardTemplate then
		print("[DialogueGUI] ✅ Found VillagerCard template")
		self._cardTemplate = cardTemplate
		cardTemplate.Visible = false -- Ensure template itself stays hidden
		cardTemplate.LayoutOrder = -1 -- Ensure template doesn't interfere with cloned cards
	else
		warn("[DialogueGUI] ⚠️ VillagerCard template not found - will create cards programmatically")
	end
	
	-- Setup scrolling if needed
	local scrollFrame = dialogueFrame:FindFirstChildOfClass("ScrollingFrame")
	if scrollFrame then
		self._scrollFrame = scrollFrame
		-- Find list layout inside scroll frame
		local scrollListLayout = scrollFrame:FindFirstChildOfClass("UIListLayout")
		if scrollListLayout then
			-- Connect canvas size to list layout inside scroll frame
			scrollListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollListLayout.AbsoluteContentSize.Y)
			end)
			self._listLayout = scrollListLayout -- Use the one in scroll frame
		else
			-- Use the one on dialogue frame
			listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
			end)
		end
		print("[DialogueGUI] ✅ Found ScrollingFrame")
	end
	
	-- Find or setup continue button
	local continueButton = dialogueFrame:FindFirstChild("ContinueButton")
	if continueButton then
		continueButton.MouseButton1Click:Connect(function()
			self:AdvanceDialogue()
		end)
		self._continueButton = continueButton
		print("[DialogueGUI] ✅ Found ContinueButton")
	end

	-- Create orange carrot down arrow (skip) if not present
	-- Place it in the ScreenGui or at root level, not in DialogueFrame (to avoid UIListLayout)
	local skip = screenGui:FindFirstChild("SkipArrow")
	if not skip then
		skip = Instance.new("TextButton")
		skip.Name = "SkipArrow"
		skip.Text = "▼"
		skip.Font = Enum.Font.GothamBold
		skip.TextSize = 22
		skip.TextColor3 = Color3.fromRGB(255, 255, 255)
		skip.BackgroundColor3 = Color3.fromHex("#FFB400")
		skip.AutoButtonColor = true
		skip.Size = UDim2.new(0, 36, 0, 36)
		skip.AnchorPoint = Vector2.new(0.5, 1)
		-- Position relative to DialogueFrame if it exists
		if dialogueFrame then
			-- Position at bottom center, just below DialogueFrame
			skip.Position = UDim2.new(0.5, 0, 0, dialogueFrame.AbsolutePosition.Y + dialogueFrame.AbsoluteSize.Y + 8)
		else
			skip.Position = UDim2.new(0.5, 0, 1, -20)
		end
		skip.ZIndex = 100
		skip.Visible = false -- Hidden by default
		skip.Parent = screenGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = skip
		
		skip.MouseButton1Click:Connect(function()
			self:AdvanceDialogue()
		end)
		
		-- Update position when DialogueFrame position/size changes
		if dialogueFrame then
			dialogueFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				if skip and skip.Parent then
					skip.Position = UDim2.new(0.5, 0, 0, dialogueFrame.AbsolutePosition.Y + dialogueFrame.AbsoluteSize.Y + 8)
				end
			end)
			dialogueFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if skip and skip.Parent then
					skip.Position = UDim2.new(0.5, 0, 0, dialogueFrame.AbsolutePosition.Y + dialogueFrame.AbsoluteSize.Y + 8)
				end
			end)
		end
		
		self._skipButton = skip
		print("[DialogueGUI] ✅ Created SkipArrow button")
	end
	
	return true
end

--[[
	Create a VillagerCard (using template or programmatically)
	@param villagerName string - Name of the villager
	@param dialogueText string - Dialogue text to display
	@param layoutOrder number - Layout order for stacking
]]
function DialogueGUI:CreateVillagerCard(villagerName, dialogueText, layoutOrder)
	layoutOrder = layoutOrder or #self._cards + 1
	
	local card
	local parentFrame = self._scrollFrame or self._dialogueFrame
	
	-- Use template if available, otherwise create programmatically
	if self._cardTemplate then
		-- Reuse single card if already created
		if self._singleCard and self._singleCard.Parent then
			card = self._singleCard
		else
			card = self._cardTemplate:Clone()
			self._singleCard = card
		end
		card.Name = "VillagerCard_" .. layoutOrder
		card.Visible = true
		-- Respect layout: VillagerCard at index 0
		card.LayoutOrder = 0
		card.Parent = parentFrame

		-- Find and update villager name (direct child of VillagerCard)
		local nameLabel = card:FindFirstChild("VillagerName")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = villagerName
			-- Within VillagerCard: name first
			pcall(function()
				nameLabel.LayoutOrder = 0
			end)
			print("[DialogueGUI] ✅ Updated VillagerName:", villagerName)
		else
			warn("[DialogueGUI] ⚠️ VillagerName TextLabel not found in VillagerCard")
		end
		self._nameLabelRef = nameLabel

		-- Find and update dialogue text (direct child of VillagerCard)
		local dialogueTextLabel = card:FindFirstChild("DialogueText")
		if dialogueTextLabel and dialogueTextLabel:IsA("TextLabel") then
			dialogueTextLabel.Text = dialogueText
			-- Within VillagerCard: dialogue text second
			pcall(function()
				dialogueTextLabel.LayoutOrder = 1
			end)
			print("[DialogueGUI] ✅ Updated DialogueText:", dialogueText:sub(1, 30) .. "...")
		else
			-- Some UIs keep DialogueText as a sibling under DialogueFrame. Try there.
			dialogueTextLabel = self._dialogueFrame and self._dialogueFrame:FindFirstChild("DialogueText")
			if dialogueTextLabel and dialogueTextLabel:IsA("TextLabel") then
				dialogueTextLabel.Text = dialogueText
				-- At frame-level layout: ensure DialogueText index is 1 while VillagerCard is 0
				pcall(function()
					if card then card.LayoutOrder = 0 end
					dialogueTextLabel.LayoutOrder = 1
				end)
				print("[DialogueGUI] ✅ Updated DialogueText (frame-level):", dialogueText:sub(1, 30) .. "...")
			else
				warn("[DialogueGUI] ⚠️ DialogueText TextLabel not found in VillagerCard or DialogueFrame")
			end
		end
		self._dialogueTextRef = dialogueTextLabel

		-- Find and update villager image (direct child of VillagerCard)
		local villagerImage = card:FindFirstChild("VillagerImage")
		if villagerImage and villagerImage:IsA("ImageLabel") then
			local imageAssetId = VILLAGER_IMAGES[villagerName] or DEFAULT_VILLAGER_IMAGE
			villagerImage.Image = imageAssetId
			villagerImage.ImageTransparency = 0 -- Ensure visible
			print("[DialogueGUI] ✅ Updated VillagerImage for:", villagerName, "→", imageAssetId)
		else
			warn("[DialogueGUI] ⚠️ VillagerImage ImageLabel not found in VillagerCard")
			-- List children to help debug structure
			local children = {}
			for _, child in ipairs(card:GetChildren()) do
				table.insert(children, child.Name .. " (" .. child.ClassName .. ")")
			end
			print("[DialogueGUI] 🔍 VillagerCard children:", table.concat(children, ", "))
		end
		self._villagerImageRef = villagerImage
	else
		-- Fallback: create card programmatically (simplified version)
		warn("[DialogueGUI] Creating VillagerCard programmatically (no template found)")
		if self._singleCard and self._singleCard.Parent then
			card = self._singleCard
		else
			card = Instance.new("Frame")
			self._singleCard = card
		end
		card.Name = "VillagerCard_" .. layoutOrder
		card.Size = UDim2.new(1, -40, 0, 0)
		card.BackgroundTransparency = 1
		card.LayoutOrder = layoutOrder
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Parent = parentFrame
		
		-- Simple text label for dialogue
		local textLabel = card:FindFirstChild("DialogueText")
		if not textLabel then
			textLabel = Instance.new("TextLabel")
			textLabel.Name = "DialogueText"
			textLabel.Size = UDim2.new(1, 0, 0, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextColor3 = Color3.fromRGB(138, 123, 102)
			textLabel.Font = Enum.Font.GothamMedium
			textLabel.TextSize = 16
			textLabel.TextWrapped = true
			textLabel.TextXAlignment = Enum.TextXAlignment.Left
			textLabel.TextYAlignment = Enum.TextYAlignment.Top
			textLabel.AutomaticSize = Enum.AutomaticSize.Y
			textLabel.Parent = card
		end
		textLabel.Text = villagerName .. ": " .. dialogueText
		self._dialogueTextRef = textLabel
	end
	
	-- Track only single card to prevent duplicates
	self._cards = { card }
	return card
end

--[[
	Show a sequence of dialogues
	@param dialogues table - Array of {villagerName, text} or {villagerName, text, options}
	@param options table - {onComplete, autoAdvance, autoAdvanceDelay}
]]
function DialogueGUI:ShowSequence(dialogues, options)
	options = options or {}
	self._onComplete = options.onComplete
	self._autoAdvance = options.autoAdvance or false
	self._autoAdvanceDelay = options.autoAdvanceDelay or 3
	
	-- Clear existing cards
	self:Clear()
	
	-- Store sequence
	self._currentSequence = dialogues
	self._currentIndex = 1
	
	-- Show GUI
	self:Show()
	
	-- Single-card mode: create one card and set first dialogue
	local first = dialogues[self._currentIndex]
	if first then
		local villagerName = first.villagerName or first[1]
		local text = first.text or first[2]
		self:CreateVillagerCard(villagerName, text, 1)
	end
	
	-- If auto-advance, start the timer
	if self._autoAdvance then
		self:_startAutoAdvance()
	end
end

--[[
	Show a single dialogue message
	@param villagerName string
	@param dialogueText string
]]
function DialogueGUI:ShowDialogue(villagerName, dialogueText)
	self:ShowSequence({
		{villagerName = villagerName, text = dialogueText}
	}, {autoAdvance = false})
end

--[[
	Advance to the next dialogue or close
]]
function DialogueGUI:AdvanceDialogue()
	if self._currentIndex < #self._currentSequence then
		self._currentIndex += 1
		-- Update single card contents instead of creating new ones
		local entry = self._currentSequence[self._currentIndex]
		local villagerName = entry.villagerName or entry[1]
		local text = entry.text or entry[2]
		if self._nameLabelRef then
			self._nameLabelRef.Text = villagerName or ""
		end
		if self._dialogueTextRef then
			self._dialogueTextRef.Text = text or ""
		end
		-- Update image if ImageLabel exists
		if self._villagerImageRef and self._villagerImageRef:IsA("ImageLabel") then
			local imageAssetId = VILLAGER_IMAGES[villagerName] or DEFAULT_VILLAGER_IMAGE
			self._villagerImageRef.Image = imageAssetId
			print("[DialogueGUI] ✅ Updated image for:", villagerName)
		end
	else
		-- Sequence complete - call onComplete callback (e.g., open island selection)
		if self._onComplete then
			self._onComplete()
		end
		self:Hide()
	end
end

--[[
	Scroll to a specific card
]]
function DialogueGUI:_scrollToCard(card)
	if not card or not self._scrollFrame then
		return
	end
	
	local cardPosition = card.AbsolutePosition.Y
	local cardSize = card.AbsoluteSize.Y
	local scrollPosition = self._scrollFrame.AbsolutePosition.Y
	local scrollSize = self._scrollFrame.AbsoluteSize.Y
	
	-- Calculate target scroll position
	local targetScroll = cardPosition - scrollPosition
	
	-- Tween scroll position
	local tween = TweenService:Create(
		self._scrollFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{CanvasPosition = Vector2.new(0, self._scrollFrame.CanvasPosition.Y + targetScroll)}
	)
	tween:Play()
end

--[[
	Start auto-advance timer
]]
function DialogueGUI:_startAutoAdvance()
	if self._autoAdvanceConnection then
		self._autoAdvanceConnection:Disconnect()
	end
	
	local function advance()
		if self._currentIndex < #self._currentSequence then
			self:AdvanceDialogue()
			self._autoAdvanceConnection = task.delay(self._autoAdvanceDelay, advance)
		else
			self:Hide()
			if self._onComplete then
				self._onComplete()
			end
		end
	end
	
	self._autoAdvanceConnection = task.delay(self._autoAdvanceDelay, advance)
end

--[[
	Clear all dialogue cards
]]
function DialogueGUI:Clear()
	-- Destroy all tracked cards
	for _, card in ipairs(self._cards) do
		if card and card.Parent then
			card:Destroy()
		end
	end
	self._cards = {}
	
	-- Also remove any VillagerCard clones that might exist in the frame
	local parentFrame = self._scrollFrame or self._dialogueFrame
	if parentFrame then
		for _, child in ipairs(parentFrame:GetChildren()) do
			-- Remove any VillagerCard clones (but not the template itself)
			if child.Name:match("^VillagerCard_") then
				child:Destroy()
			end
		end
	end
	
	self._currentSequence = {}
	self._currentIndex = 0
	
	if self._autoAdvanceConnection then
		self._autoAdvanceConnection:Disconnect()
		self._autoAdvanceConnection = nil
	end
end

--[[
	Show the dialogue GUI
]]
function DialogueGUI:Show()
	if not self._screenGui then
		self:Init()
	end
	-- Hide any other GUIs via global GUIManager if available
	local gm = _G and _G.GUIManager
	if gm and typeof(gm.hideAllGUIs) == "function" then
		pcall(function()
			gm:hideAllGUIs()
			if typeof(gm.setCurrentVisible) == "function" then
				gm:setCurrentVisible("dialogue")
			end
		end)
	end
	if self._screenGui then
		self._screenGui.Enabled = true
		if self._dialogueFrame then
			self._dialogueFrame.Visible = true
			-- Update skip button position and show it
			if self._skipButton then
				task.wait(0.1) -- Wait for frame to layout
				self._skipButton.Position = UDim2.new(0.5, 0, 0, self._dialogueFrame.AbsolutePosition.Y + self._dialogueFrame.AbsoluteSize.Y + 8)
				self._skipButton.Visible = true
			end
		end
	end
end

--[[
	Hide the dialogue GUI
]]
function DialogueGUI:Hide()
	if self._skipButton then
		self._skipButton.Visible = false
	end
	if self._dialogueFrame then
		self._dialogueFrame.Visible = false
	end
	if self._screenGui then
		self._screenGui.Enabled = false
	end
end

--[[
	Toggle visibility
]]
function DialogueGUI:Toggle()
	if self._screenGui and self._screenGui.Enabled then
		self:Hide()
	else
		self:Show()
	end
end

--[[
	Destroy the GUI
]]
function DialogueGUI:Destroy()
	self:Clear()
	if self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
	end
end

return DialogueGUI

