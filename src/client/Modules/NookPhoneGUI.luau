--[[
    NookPhoneGUI.luau
    Controller for the NookPhone interface
    
    Expects a ScreenGui named "NookPhoneGUI" to exist in PlayerGui
    with your custom design and app buttons.
]]

local Players = game:GetService("Players")

local NookPhoneGUI = {}
NookPhoneGUI.__index = NookPhoneGUI

function NookPhoneGUI.new()
    local self = setmetatable({}, NookPhoneGUI)

    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.nookShoppingGUI = nil

    -- Find existing NookPhoneGUI in PlayerGui
    self.gui = self.playerGui:FindFirstChild("NookPhoneGUI")

    if not self.gui then
        warn("[NookPhoneGUI] ⚠️ NookPhoneGUI not found in PlayerGui - please add it in Roblox Studio")
        return self
    end

    print("[NookPhoneGUI] ✅ Found existing NookPhoneGUI in PlayerGui")

    -- Find the main frame
    local mainFrame = self.gui:FindFirstChild("NookPhone")
    if not mainFrame then
        mainFrame = self.gui:FindFirstChildWhichIsA("Frame")
    end

    if mainFrame then
        print("[NookPhoneGUI] ✅ Found main frame:", mainFrame.Name)
        self.mainFrame = mainFrame
    else
        warn("[NookPhoneGUI] ⚠️ Could not find main frame in NookPhoneGUI")
    end

    -- Initially hide the GUI
    self.gui.Enabled = false
    if self.mainFrame then
        self.mainFrame.Visible = false
    end

    -- Setup button connections (customize these paths based on your GUI structure)
    self:setupButtons()

    print("[NookPhoneGUI] ✅ Initialized")
    return self
end

function NookPhoneGUI:setupButtons()
    -- This function should connect your app buttons to their actions
    -- Customize based on your actual GUI structure

    -- Helper function to find any GuiObject by name
    local function findByName(parent, objectName)
        for _, child in ipairs(parent:GetDescendants()) do
            if child.Name == objectName then
                return child
            end
        end
        return nil
    end

    -- Set up Nook Shopping app icon (ImageButton)
    local nookShoppingIcon = findByName(self.gui, "NookShoppingIcon")
    if nookShoppingIcon then
        print(
            "[NookPhoneGUI] 🔍 Found NookShoppingIcon:",
            nookShoppingIcon:GetFullName(),
            "Type:",
            nookShoppingIcon.ClassName
        )

        if nookShoppingIcon:IsA("ImageButton") then
            nookShoppingIcon.Image = "rbxassetid://129651169921180"
            nookShoppingIcon.MouseButton1Click:Connect(function()
                print("[NookPhoneGUI] 🛒 Nook Shopping icon clicked!")
                self:openApp("nook_shopping")
            end)
            print("[NookPhoneGUI] ✅ Set Nook Shopping icon and connected button")
        else
            warn("[NookPhoneGUI] ⚠️ NookShoppingIcon is not an ImageButton, it's a:", nookShoppingIcon.ClassName)
        end
    else
        warn("[NookPhoneGUI] ⚠️ NookShoppingIcon not found in GUI")
    end

    -- Try to find close button
    local closeBtn = findByName(self.gui, "CloseButton")
    if closeBtn then
        print("[NookPhoneGUI] 🔍 Found CloseButton:", closeBtn:GetFullName())

        if closeBtn:IsA("GuiButton") then
            closeBtn.MouseButton1Click:Connect(function()
                print("[NookPhoneGUI] ✕ Close button clicked!")
                self:hide()
            end)
            print("[NookPhoneGUI] ✅ Connected Close button")
        end
    else
        warn("[NookPhoneGUI] ⚠️ CloseButton not found in GUI")
    end
end

function NookPhoneGUI:setShopGUI(shopGUI)
    -- Connect the NookShoppingGUI module
    self.nookShoppingModule = shopGUI
    print("[NookPhoneGUI] ✅ NookShoppingGUI module connected")
end

function NookPhoneGUI:openApp(appId)
    print("[NookPhoneGUI] 📱 Opening app:", appId)

    if appId == "nook_shopping" then
        if self.nookShoppingModule then
            self:hide()
            self.nookShoppingModule:show()
            print("[NookPhoneGUI] ✅ Opened Nook Shopping")
        else
            warn("[NookPhoneGUI] ⚠️ NookShoppingGUI module not connected!")
        end
    else
        print("[NookPhoneGUI] ⚠️ App not yet implemented:", appId)
    end
end

function NookPhoneGUI:show()
    if not self.gui then
        warn("[NookPhoneGUI] ❌ Cannot show - gui is nil")
        return
    end
    if self.visible then
        print("[NookPhoneGUI] ℹ️ Already visible")
        return
    end

    self.visible = true
    self.gui.Enabled = true

    -- Make sure the main frame is visible too
    if self.mainFrame then
        self.mainFrame.Visible = true
        print("[NookPhoneGUI] 📱 NookPhone opened - Frame:", self.mainFrame.Name, "Visible:", self.mainFrame.Visible)
    else
        local mainFrame = self.gui:FindFirstChild("NookPhone") or self.gui:FindFirstChildWhichIsA("Frame")
        if mainFrame and mainFrame:IsA("GuiObject") then
            mainFrame.Visible = true
            self.mainFrame = mainFrame
            print("[NookPhoneGUI] 📱 NookPhone opened - Found frame:", mainFrame.Name)
        else
            warn("[NookPhoneGUI] ⚠️ No main frame found to show!")
        end
    end
end

function NookPhoneGUI:hide()
    if not self.gui then
        return
    end
    if not self.visible then
        return
    end

    self.visible = false
    self.gui.Enabled = false

    -- Hide the main frame too
    if self.mainFrame then
        self.mainFrame.Visible = false
        print("[NookPhoneGUI] 📱 NookPhone closed")
    else
        local mainFrame = self.gui:FindFirstChild("NookPhone") or self.gui:FindFirstChildWhichIsA("Frame")
        if mainFrame and mainFrame:IsA("GuiObject") then
            mainFrame.Visible = false
            print("[NookPhoneGUI] 📱 NookPhone closed")
        end
    end
end

function NookPhoneGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookPhoneGUI:isVisible()
    return self.visible
end

-- Alias methods for GUIManager compatibility
NookPhoneGUI.Show = NookPhoneGUI.show
NookPhoneGUI.Hide = NookPhoneGUI.hide
NookPhoneGUI.Toggle = NookPhoneGUI.toggle

return NookPhoneGUI
