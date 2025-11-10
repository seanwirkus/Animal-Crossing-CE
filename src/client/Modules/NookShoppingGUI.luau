--[[
    NookShoppingGUI.luau
    Controller for your custom NookShopping GUI
    Finds your existing styled frame and populates it with items
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NookShoppingGUI = {}
NookShoppingGUI.__index = NookShoppingGUI

function NookShoppingGUI.new()
    local self = setmetatable({}, NookShoppingGUI)
    
    self.player = Players.LocalPlayer
    self.playerGui = self.player:WaitForChild("PlayerGui")
    self.gui = nil
    self.visible = false
    self.bells = 0
    
    -- Find existing NookShoppingGUI in PlayerGui
    self.gui = self.playerGui:FindFirstChild("NookShoppingGUI")
    
    if not self.gui then
        warn("[NookShoppingGUI] ⚠️ NookShoppingGUI not found in PlayerGui")
        return self
    end
    
    print("[NookShoppingGUI] ✅ Found NookShoppingGUI in PlayerGui")
    
    -- Ensure it's a ScreenGui and set properties
    if self.gui:IsA("ScreenGui") then
        self.gui.DisplayOrder = 50  -- High enough to be on top
        self.gui.ResetOnSpawn = false
        self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    end
    
    -- Load dependencies
    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    
    -- Currency remote
    self.currencyRemote = ReplicatedStorage:WaitForChild("CurrencyEvent")
    
    -- Shop remote (for buying/selling)
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEventsFolder then
        self.shopRemote = remoteEventsFolder:FindFirstChild("ShopTransaction")
        if not self.shopRemote then
            self.shopRemote = Instance.new("RemoteEvent")
            self.shopRemote.Name = "ShopTransaction"
            self.shopRemote.Parent = remoteEventsFolder
        end
    end
    
    -- Initially hide (will be shown via GUIManager)
    self.gui.Enabled = false
    
    -- Setup and populate
    self:setupGUI()
    self:connectToServer()
    
    print("[NookShoppingGUI] ✅ Initialized")
    return self
end

function NookShoppingGUI:setupGUI()
    -- Find the main content area to populate - look for what you already designed
    local function findByName(parent, name)
        for _, child in ipairs(parent:GetDescendants()) do
            if child.Name == name then
                return child
            end
        end
        return nil
    end
    
    print("[NookShoppingGUI] 🔍 Full GUI structure:")
    local function printStructure(obj, indent)
        indent = indent or ""
        for i, child in ipairs(obj:GetChildren()) do
            print("[NookShoppingGUI] " .. indent .. "- " .. child.Name .. " (" .. child.ClassName .. ")")
            if child:IsA("GuiObject") then
                printStructure(child, indent .. "  ")
            end
        end
    end
    printStructure(self.gui)
    
    -- Find close button
    local closeBtn = findByName(self.gui, "CloseButton")
    if closeBtn and closeBtn:IsA("GuiButton") then
        closeBtn.MouseButton1Click:Connect(function()
            self:hide()
        end)
        print("[NookShoppingGUI] ✅ Connected Close button")
    end
    
    -- Look for your item display frame/labels that you designed
    local itemsFrame = findByName(self.gui, "NookipediaItemlist") or
                       findByName(self.gui, "ItemList") or
                       findByName(self.gui, "ItemsFrame") or
                       findByName(self.gui, "ShopFrame") or
                       findByName(self.gui, "ItemsContainer") or
                       self.gui:FindFirstChildWhichIsA("ScrollingFrame") or
                       self.gui:FindFirstChildWhichIsA("Frame")
    
    if itemsFrame then
        self.itemsFrame = itemsFrame
        print("[NookShoppingGUI] ✅ Found items frame:", itemsFrame.Name)
        
        -- Look for template slot to clone
        self.slotTemplate = findByName(itemsFrame, "ItemSlot") or
                           findByName(itemsFrame, "ItemSlotTemplate")
        
        if self.slotTemplate then
            print("[NookShoppingGUI] ✅ Found slot template:", self.slotTemplate.Name)
            self.slotTemplate.Visible = false
            self:populateItemsFromTemplate()
        else
            print("[NookShoppingGUI] ℹ️ No slot template found - will populate your existing labels")
            self:populateExistingLabels()
        end
    else
        warn("[NookShoppingGUI] ⚠️ Could not find items frame in your GUI")
    end
end

function NookShoppingGUI:populateExistingLabels()
    -- Populate the NookipediaItem frames with real data
    if not self.itemsFrame then return end
    
    local itemsToShow = {
        { id = "fishing_rod", name = "Fishing Rod", price = 500, spriteIndex = 5 },
        { id = "bug_net", name = "Bug Net", price = 600, spriteIndex = 3 },
        { id = "shovel", name = "Shovel", price = 800, spriteIndex = 1 },
        { id = "axe", name = "Axe", price = 1000, spriteIndex = 2 },
    }
    
    for i, itemData in ipairs(itemsToShow) do
        local itemFrame = self.itemsFrame:FindFirstChild("NookipediaItem" .. i)
        if itemFrame then
            print("[NookShoppingGUI] 📝 Populating NookipediaItem" .. i .. ": " .. itemData.name)
            
            -- Update name
            local nameLabel = itemFrame:FindFirstChild("ItemName")
            if nameLabel and nameLabel:IsA("TextLabel") then
                nameLabel.Text = itemData.name
            end
            
            -- Update price
            local priceLabel = itemFrame:FindFirstChild("ItemPrice")
            if priceLabel and priceLabel:IsA("TextLabel") then
                priceLabel.Text = tostring(itemData.price) .. "🔔"
            end
            
            -- Update icon
            local iconImage = itemFrame:FindFirstChild("ItemIcon")
            if iconImage and iconImage:IsA("ImageLabel") then
                local success = self.spriteConfig.applySprite(iconImage, itemData.spriteIndex)
                if not success then
                    print("[NookShoppingGUI] ⚠️ Failed to apply sprite", itemData.spriteIndex, "for", itemData.name)
                end
            end
            
            -- Find the Frame inside that contains icon/name
            local contentFrame = nil
            for _, child in ipairs(itemFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name == "Frame" then
                    contentFrame = child
                    break
                end
            end
            
            -- Try finding icon in the content frame
            if contentFrame then
                local frameIcon = contentFrame:FindFirstChild("ItemIcon")
                if frameIcon and frameIcon:IsA("ImageLabel") then
                    local success = self.spriteConfig.applySprite(frameIcon, itemData.spriteIndex)
                    if success then
                        print("[NookShoppingGUI] ✅ Applied sprite", itemData.spriteIndex, "to", itemData.name)
                    end
                end
            end
        end
    end
    
    print("[NookShoppingGUI] ✅ Populated existing NookipediaItem frames with data")
end

function NookShoppingGUI:populateItemsFromTemplate()
    -- If you have a template slot, clone it and populate with real items
    if not self.slotTemplate or not self.itemsFrame then return end
    
    local itemsToShow = {
        { id = "fishing_rod", name = "Fishing Rod", price = 500 },
        { id = "net", name = "Net", price = 600 },
        { id = "shovel", name = "Shovel", price = 800 },
        { id = "axe", name = "Axe", price = 1000 },
        { id = "watering_can", name = "Watering Can", price = 200 },
        { id = "slingshot", name = "Slingshot", price = 1250 },
    }
    
    for _, itemData in ipairs(itemsToShow) do
        local slot = self.slotTemplate:Clone()
        slot.Name = itemData.id
        slot.Visible = true
        
        -- Update label names in your slot template
        local nameLabel = slot:FindFirstChild("ItemName") or slot:FindFirstChild("Name") or slot:FindFirstChild("ItemNameLabel")
        local priceLabel = slot:FindFirstChild("ItemPrice") or slot:FindFirstChild("Price") or slot:FindFirstChild("PriceLabel")
        local iconLabel = slot:FindFirstChild("ItemIcon") or slot:FindFirstChild("Icon") or slot:FindFirstChild("ItemImage")
        
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = itemData.name
        end
        
        if priceLabel and priceLabel:IsA("TextLabel") then
            priceLabel.Text = tostring(itemData.price) .. "🔔"
        end
        
        if iconLabel and iconLabel:IsA("ImageLabel") then
            local success = self.spriteConfig.applySprite(iconLabel, itemData.id)
            if not success then
                iconLabel.BackgroundTransparency = 0
                iconLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        
        -- Find and connect buy button if it exists
        local buyBtn = slot:FindFirstChild("BuyButton") or slot:FindFirstChildWhichIsA("TextButton")
        if buyBtn then
            buyBtn.MouseButton1Click:Connect(function()
                print("[NookShoppingGUI] 💳 Buying:", itemData.name, "for", itemData.price, "bells")
                if self.shopRemote then
                    self.shopRemote:FireServer("BuyItem", {
                        itemId = itemData.id,
                        price = itemData.price,
                        count = 1,
                    })
                end
            end)
        end
        
        slot.Parent = self.itemsFrame
    end
    
    print("[NookShoppingGUI] ✅ Populated", #itemsToShow, "items from template")
end

function NookShoppingGUI:connectToServer()
    -- Listen for currency updates
    if self.currencyRemote then
        self.currencyRemote.OnClientEvent:Connect(function(action, data)
            if action == "UpdateBells" then
                self.bells = data.amount
                print("[NookShoppingGUI] 💰 Bells updated:", self.bells)
            end
        end)
    end
end

function NookShoppingGUI:show()
    if not self.gui then 
        print("[NookShoppingGUI] ❌ Cannot show - gui is nil")
        return 
    end
    
    self.visible = true
    self.gui.Enabled = true
    
    -- Find and show the main frame (try both names)
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or self.gui:FindFirstChild("ShopContainer")
    if mainFrame then
        mainFrame.Visible = true
        print("[NookShoppingGUI] 🛒 NookShopping opened - MainFrame visible: true")
    else
        print("[NookShoppingGUI] ⚠️ Main frame not found (tried NookShoppingFrame and ShopContainer)")
    end
end

function NookShoppingGUI:hide()
    if not self.gui then return end
    
    self.visible = false
    self.gui.Enabled = false
    
    -- Hide the main frame
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or self.gui:FindFirstChild("ShopContainer")
    if mainFrame then
        mainFrame.Visible = false
    end
    
    print("[NookShoppingGUI] 🛒 NookShopping closed")
end

function NookShoppingGUI:toggle()
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookShoppingGUI:isVisible()
    return self.visible
end

-- Alias methods for GUIManager compatibility
NookShoppingGUI.Show = NookShoppingGUI.show
NookShoppingGUI.Hide = NookShoppingGUI.hide
NookShoppingGUI.Toggle = NookShoppingGUI.toggle

return NookShoppingGUI
