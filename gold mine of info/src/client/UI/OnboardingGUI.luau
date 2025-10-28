--[[
        OnboardingGUI - Orchestrates the island selection and naming flow shown
        when a player begins onboarding with Tom Nook. The module reuses the
        IslandSelection gallery for template browsing, then guides the player
        through a themed naming prompt before notifying the caller.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GUIComponents = require(ReplicatedStorage.GUIComponents)
local Theme = require(ReplicatedStorage.Theme)
local IslandSelection = require(script.Parent.IslandSelection)

export type TemplateEntry = {
        id: string,
        displayName: string,
        tagline: string?,
        difficulty: string?,
        biomeTags: { string }?,
        startingVillagers: { string }?,
        startingResources: { string }?,
        startingBells: number?,
        startingMiles: number?,
        features: { string }?,
}

export type SelectionResult = {
        template: TemplateEntry,
        islandName: string,
}

export type OnboardingOptions = {
        templates: { TemplateEntry },
        onConfirm: (SelectionResult) -> (),
        onCancel: (() -> ())?,
}

local OnboardingGUI = {}
OnboardingGUI.__index = OnboardingGUI

local function deriveDefaultName(template: TemplateEntry): string
        if not template then
                return "New Island"
        end

        local name = template.displayName or "New Island"
        name = name:gsub("^[^%w]+", "") -- Strip leading emoji/punctuation
        name = name:gsub("^%s+", "")

        if name == "" then
                name = "New Island"
        end

        return name
end

local function validateIslandName(rawText: string): (boolean, string, string?)
        local text = rawText or ""
        local trimmed = text:gsub("^%s*(.-)%s*$", "%1")
        if trimmed == "" then
                return false, trimmed, "Enter a name to continue."
        end

        local ok, length = pcall(utf8.len, trimmed)
        if not ok or length == nil then
                length = #trimmed
        end

        if length < 3 then
                return false, trimmed, "Names must be at least 3 characters."
        end

        if length > 14 then
                return false, trimmed, "Names can be up to 14 characters."
        end

        if not trimmed:match("^[%w%s%-%']+$") then
                return false, trimmed, "Use letters, numbers, spaces, hyphens, or apostrophes."
        end

        return true, trimmed, nil
end

function OnboardingGUI.new(options: OnboardingOptions)
        assert(options and typeof(options) == "table", "OnboardingGUI.new requires an options table.")
        assert(options.templates and #options.templates > 0, "OnboardingGUI.new requires at least one template.")

        local self = setmetatable({}, OnboardingGUI)
        self._player = Players.LocalPlayer
        self._templates = options.templates
        self._onConfirm = options.onConfirm or function() end
        self._onCancel = options.onCancel
        self._selection = nil
        self._promptGui = nil
        self._connections = {}
        self._destroyed = false

        self:_openSelection()

        return self
end

function OnboardingGUI:_openSelection()
        if self._destroyed then
                return
        end

        self:_destroyPrompt()
        if self._selection then
                self._selection:Destroy()
                self._selection = nil
        end

        self._selection = IslandSelection.new({
                templates = self._templates,
                onConfirm = function(template)
                        self:_promptIslandName(template)
                end,
                onCancel = function()
                        self:_handleCancel()
                end,
        })
end

function OnboardingGUI:_destroyPrompt()
        for _, connection in ipairs(self._connections) do
                connection:Disconnect()
        end
        table.clear(self._connections)

        if self._promptGui then
                self._promptGui:Destroy()
                self._promptGui = nil
        end
end

function OnboardingGUI:_handleCancel()
        if self._destroyed then
                return
        end

        local cancelCallback = self._onCancel
        self:Destroy()
        if cancelCallback then
                cancelCallback()
        end
end

local function createSummarySection(parent: Instance, theme, template: TemplateEntry)
        local section = Instance.new("Frame")
        section.Name = "TemplateSummary"
        section.BackgroundColor3 = Color3.fromRGB(252, 247, 232)
        section.BackgroundTransparency = 0
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.Size = UDim2.new(1, 0, 0, 0)
        section.LayoutOrder = 3
        section.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = section

        local stroke = Instance.new("UIStroke")
        stroke.Color = theme.secondaryColor or GUIComponents.DEFAULT_THEME.secondaryColor
        stroke.Thickness = 1
        stroke.Transparency = 0.6
        stroke.Parent = section

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 12)
        padding.PaddingBottom = UDim.new(0, 12)
        padding.PaddingLeft = UDim.new(0, 16)
        padding.PaddingRight = UDim.new(0, 16)
        padding.Parent = section

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = section

        local title = Instance.new("TextLabel")
        title.Name = "SummaryTitle"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.Size = UDim2.new(1, 0, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 22
        title.TextColor3 = theme.textColor or GUIComponents.DEFAULT_THEME.textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = string.format("%s • %s", template.displayName, template.difficulty or "Relaxed")
        title.LayoutOrder = 1
        title.Parent = section

        if template.tagline and template.tagline ~= "" then
                local tagline = Instance.new("TextLabel")
                tagline.Name = "Tagline"
                tagline.AutomaticSize = Enum.AutomaticSize.Y
                tagline.Size = UDim2.new(1, 0, 0, 0)
                tagline.BackgroundTransparency = 1
                tagline.Font = Enum.Font.Gotham
                tagline.TextSize = 18
                tagline.TextColor3 = theme.secondaryColor or GUIComponents.DEFAULT_THEME.secondaryColor
                tagline.TextWrapped = true
                tagline.TextXAlignment = Enum.TextXAlignment.Left
                tagline.LayoutOrder = 2
                tagline.Text = template.tagline
                tagline.Parent = section
        end

        if template.features and #template.features > 0 then
                local feature = Instance.new("TextLabel")
                feature.Name = "Features"
                feature.AutomaticSize = Enum.AutomaticSize.Y
                feature.Size = UDim2.new(1, 0, 0, 0)
                feature.BackgroundTransparency = 1
                feature.Font = Enum.Font.Gotham
                feature.TextSize = 17
                feature.TextColor3 = Theme.secondaryTextColor()
                feature.TextWrapped = true
                feature.TextXAlignment = Enum.TextXAlignment.Left
                feature.LayoutOrder = 3
                feature.Text = table.concat(template.features, "\n")
                feature.Parent = section
        end

        if template.startingVillagers and #template.startingVillagers > 0 then
                local villagers = Instance.new("TextLabel")
                villagers.Name = "Villagers"
                villagers.AutomaticSize = Enum.AutomaticSize.Y
                villagers.Size = UDim2.new(1, 0, 0, 0)
                villagers.BackgroundTransparency = 1
                villagers.Font = Enum.Font.Gotham
                villagers.TextSize = 17
                villagers.TextColor3 = Theme.textColor()
                villagers.TextWrapped = true
                villagers.TextXAlignment = Enum.TextXAlignment.Left
                villagers.LayoutOrder = 4
                villagers.Text = "Villagers joining you: " .. table.concat(template.startingVillagers, ", ")
                villagers.Parent = section
        end

        if template.startingResources and #template.startingResources > 0 then
                local resources = Instance.new("TextLabel")
                resources.Name = "Resources"
                resources.AutomaticSize = Enum.AutomaticSize.Y
                resources.Size = UDim2.new(1, 0, 0, 0)
                resources.BackgroundTransparency = 1
                resources.Font = Enum.Font.Gotham
                resources.TextSize = 17
                resources.TextColor3 = Theme.textColor()
                resources.TextWrapped = true
                resources.TextXAlignment = Enum.TextXAlignment.Left
                resources.LayoutOrder = 5
                resources.Text = "Starter kit: " .. table.concat(template.startingResources, ", ")
                resources.Parent = section
        end

        local currencyParts = {}
        if template.startingBells and template.startingBells > 0 then
                table.insert(currencyParts, string.format("🔔 %s Bells", tostring(template.startingBells)))
        end
        if template.startingMiles and template.startingMiles > 0 then
                table.insert(currencyParts, string.format("⭐ %s Nook Miles", tostring(template.startingMiles)))
        end

        if #currencyParts > 0 then
                local currency = Instance.new("TextLabel")
                currency.Name = "Currency"
                currency.AutomaticSize = Enum.AutomaticSize.Y
                currency.Size = UDim2.new(1, 0, 0, 0)
                currency.BackgroundTransparency = 1
                currency.Font = Enum.Font.Gotham
                currency.TextSize = 17
                currency.TextColor3 = Theme.textColor()
                currency.TextWrapped = true
                currency.TextXAlignment = Enum.TextXAlignment.Left
                currency.LayoutOrder = 6
                currency.Text = table.concat(currencyParts, "  •  ")
                currency.Parent = section
        end

        return section
end

function OnboardingGUI:_promptIslandName(template: TemplateEntry)
        if self._destroyed then
                return
        end

        self:_destroyPrompt()
        if self._selection then
                self._selection:Destroy()
                self._selection = nil
        end

        local playerGui = self._player:WaitForChild("PlayerGui")
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "IslandNamingPrompt"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 20
        screenGui.Parent = playerGui
        self._promptGui = screenGui

        local overlay = Instance.new("Frame")
        overlay.Name = "Overlay"
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.Parent = screenGui

        TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.35,
        }):Play()

        local panel, theme = GUIComponents.CreatePanel(overlay, {
                name = "NamingPanel",
                minWidth = 520,
                minHeight = 420,
        })
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.new(0.5, 0, 0.5, 0)
        panel.AutomaticSize = Enum.AutomaticSize.None
        panel.Size = UDim2.new(0, 520, 0, 440)

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 12)
        layout.Parent = panel

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.AutomaticSize = Enum.AutomaticSize.Y
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 36
        title.TextColor3 = theme.textColor or GUIComponents.DEFAULT_THEME.textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextWrapped = true
        title.Text = "Name Your Island"
        title.LayoutOrder = 1
        title.Parent = panel

        local info = Instance.new("TextLabel")
        info.Name = "Info"
        info.AutomaticSize = Enum.AutomaticSize.Y
        info.BackgroundTransparency = 1
        info.Font = Enum.Font.Gotham
        info.TextSize = 18
        info.TextColor3 = theme.lightTextColor or GUIComponents.DEFAULT_THEME.lightTextColor
        info.TextWrapped = true
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.LayoutOrder = 2
        info.Text = string.format("You're departing to %s. Choose a name for your new getaway.", template.displayName)
        info.Parent = panel

        createSummarySection(panel, theme, template)

        local prompt = Instance.new("TextLabel")
        prompt.Name = "Prompt"
        prompt.AutomaticSize = Enum.AutomaticSize.Y
        prompt.BackgroundTransparency = 1
        prompt.Font = Enum.Font.GothamMedium
        prompt.TextSize = 20
        prompt.TextColor3 = theme.textColor or GUIComponents.DEFAULT_THEME.textColor
        prompt.TextXAlignment = Enum.TextXAlignment.Left
        prompt.Text = "Island name"
        prompt.LayoutOrder = 4
        prompt.Parent = panel

        local nameInput = Instance.new("TextBox")
        nameInput.Name = "NameInput"
        nameInput.BackgroundColor3 = Color3.new(1, 1, 1)
        nameInput.BorderSizePixel = 0
        nameInput.Size = UDim2.new(1, -40, 0, 54)
        nameInput.Position = UDim2.new(0, 20, 0, 0)
        nameInput.ClearTextOnFocus = false
        nameInput.Font = Enum.Font.GothamBold
        nameInput.TextSize = 28
        nameInput.TextColor3 = theme.textColor or GUIComponents.DEFAULT_THEME.textColor
        nameInput.Text = deriveDefaultName(template)
        nameInput.TextXAlignment = Enum.TextXAlignment.Left
        nameInput.LayoutOrder = 5
        nameInput.Parent = panel

        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 12)
        inputCorner.Parent = nameInput

        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = theme.borderColor or GUIComponents.DEFAULT_THEME.borderColor
        inputStroke.Thickness = 1
        inputStroke.Parent = nameInput

        local errorLabel = Instance.new("TextLabel")
        errorLabel.Name = "Error"
        errorLabel.AutomaticSize = Enum.AutomaticSize.Y
        errorLabel.BackgroundTransparency = 1
        errorLabel.Font = Enum.Font.GothamSemibold
        errorLabel.TextSize = 16
        errorLabel.TextColor3 = theme.errorColor or GUIComponents.DEFAULT_THEME.errorColor
        errorLabel.TextWrapped = true
        errorLabel.TextXAlignment = Enum.TextXAlignment.Left
        errorLabel.Visible = false
        errorLabel.LayoutOrder = 6
        errorLabel.Parent = panel

        local buttonRow = Instance.new("Frame")
        buttonRow.Name = "Buttons"
        buttonRow.BackgroundTransparency = 1
        buttonRow.Size = UDim2.new(1, 0, 0, 54)
        buttonRow.LayoutOrder = 7
        buttonRow.Parent = panel

        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.FillDirection = Enum.FillDirection.Horizontal
        buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        buttonLayout.Padding = UDim.new(0, 12)
        buttonLayout.Parent = buttonRow

        local function styleButton(button: TextButton, color: Color3, textColor: Color3)
                button.AutoButtonColor = false
                button.BackgroundColor3 = color
                button.Size = UDim2.new(0, 160, 0, 48)
                button.Font = Enum.Font.GothamBold
                button.TextSize = 20
                button.TextColor3 = textColor
                button.TextWrapped = true

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 12)
                corner.Parent = button

                local stroke = Instance.new("UIStroke")
                stroke.Color = color:Lerp(Color3.new(1, 1, 1), 0.25)
                stroke.Thickness = 1
                stroke.Transparency = 0.4
                stroke.Parent = button
        end

        local backButton = Instance.new("TextButton")
        backButton.Name = "BackButton"
        backButton.Text = "Back"
        backButton.Parent = buttonRow
        styleButton(backButton, Color3.fromRGB(220, 220, 220), Color3.fromRGB(90, 90, 90))

        local confirmButton = Instance.new("TextButton")
        confirmButton.Name = "ConfirmButton"
        confirmButton.Text = "Confirm"
        confirmButton.Parent = buttonRow
        styleButton(confirmButton, theme.primaryColor or GUIComponents.DEFAULT_THEME.primaryColor, Color3.new(1, 1, 1))

        local function returnToSelection()
                if self._destroyed then
                        return
                end
                self:_destroyPrompt()
                self:_openSelection()
        end

        local function updateConfirmState(showError: boolean)
                local isValid, trimmed, reason = validateIslandName(nameInput.Text)
                if isValid then
                        confirmButton.Active = true
                        confirmButton.AutoButtonColor = true
                        confirmButton.BackgroundColor3 = theme.primaryColor or GUIComponents.DEFAULT_THEME.primaryColor
                        confirmButton.TextColor3 = Color3.new(1, 1, 1)
                        errorLabel.Visible = false
                        errorLabel.Text = ""
                        return true, trimmed
                else
                        confirmButton.Active = false
                        confirmButton.AutoButtonColor = false
                        confirmButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                        confirmButton.TextColor3 = Color3.fromRGB(140, 140, 140)
                        if showError and reason then
                                errorLabel.Text = reason
                                errorLabel.Visible = true
                        else
                                errorLabel.Visible = false
                                errorLabel.Text = ""
                        end
                        return false, trimmed
                end
        end

        table.insert(self._connections, nameInput:GetPropertyChangedSignal("Text"):Connect(function()
                updateConfirmState(false)
        end))

        table.insert(self._connections, nameInput.FocusLost:Connect(function(enterPressed)
                local valid, trimmed = updateConfirmState(true)
                if enterPressed and valid then
                        self:_completeSelection(template, trimmed)
                end
        end))

        table.insert(self._connections, confirmButton.MouseButton1Click:Connect(function()
                local valid, trimmed = updateConfirmState(true)
                if valid then
                        self:_completeSelection(template, trimmed)
                end
        end))

        table.insert(self._connections, backButton.MouseButton1Click:Connect(function()
                returnToSelection()
        end))

        table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
                if processed then
                        return
                end
                if input.KeyCode == Enum.KeyCode.Escape then
                        returnToSelection()
                end
        end))

        updateConfirmState(false)

        nameInput:CaptureFocus()
end

function OnboardingGUI:_completeSelection(template: TemplateEntry, islandName: string)
        if self._destroyed then
                return
        end

        local callback = self._onConfirm
        self:Destroy()
        if callback then
                callback({
                        template = template,
                        islandName = islandName,
                })
        end
end

function OnboardingGUI:Destroy()
        if self._destroyed then
                return
        end

        self._destroyed = true
        self:_destroyPrompt()
        if self._selection then
                self._selection:Destroy()
                self._selection = nil
        end
end

return OnboardingGUI
