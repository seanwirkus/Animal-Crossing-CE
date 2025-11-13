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
    self.isInitialized = false  -- Track if already initialized
    
    -- Find existing NookShoppingGUI in PlayerGui
    self.gui = self.playerGui:FindFirstChild("NookShoppingGUI")
    
    if not self.gui then
        warn("[NookShoppingGUI] ⚠️ NookShoppingGUI not found in PlayerGui")
        return self
    end
    
    print("[NookShoppingGUI] ✅ Found NookShoppingGUI in PlayerGui")
    
    -- CRITICAL: Disable GUI immediately before doing anything else
    if self.gui:IsA("ScreenGui") then
        self.gui.Enabled = false  -- Disable FIRST (before anything else)
        self.gui.DisplayOrder = 50  -- High enough to be on top
        self.gui.ResetOnSpawn = false  -- Don't reset on spawn
        self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        self.gui.IgnoreGuiInset = false
        
        -- Note: We don't monitor property changes here to avoid conflicts
        -- The show() and hide() methods have guards to prevent duplicate calls
    end
    
    -- Load dependencies
    local shared = ReplicatedStorage:WaitForChild("Shared")
    self.spriteConfig = require(shared:WaitForChild("SpriteConfig"))
    self.shopData = require(shared:WaitForChild("ShopData"))
    
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
    
    -- CRITICAL: Ensure GUI is completely hidden on initialization
    self.gui.Enabled = false
    
    -- Hide ALL frames in the GUI to prevent any from showing
    local function hideAllFrames(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
        -- Also hide direct children
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end
    hideAllFrames(self.gui)
    
    -- Explicitly hide the main frame to prevent it from showing unexpectedly
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or self.gui:FindFirstChild("ShopContainer") or self.gui:FindFirstChildWhichIsA("Frame")
    if mainFrame then
        mainFrame.Visible = false
    end
    
    -- Setup GUI (but don't populate items yet)
    self:setupGUI()
    self:connectToServer()
    
    -- CRITICAL: Ensure GUI is completely disabled and hidden after setup
    self.gui.Enabled = false
    self.visible = false
    
    -- Hide main frame if found
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or 
                      self.gui:FindFirstChild("ShopContainer") or
                      self.gui:FindFirstChildWhichIsA("Frame")
    if mainFrame then
        mainFrame.Visible = false
        -- Hide all children too
        for _, child in ipairs(mainFrame:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end
    
    -- Track if items have been populated to avoid re-populating unnecessarily
    self.itemsPopulated = false
    
    -- Track if we're currently showing/hiding to prevent re-entrancy
    self.isShowing = false
    self.isHiding = false
    
    -- Track initialization to prevent duplicate setup
    self.isInitialized = true
    
    -- Final safety check: Ensure GUI stays disabled
    task.spawn(function()
        -- Wait a moment for everything to settle
        task.wait(0.5)
        -- If GUI got enabled somehow during initialization, disable it
        if self.gui and self.gui.Enabled and not self.visible then
            warn("[NookShoppingGUI] ⚠️ GUI was enabled during initialization - disabling")
            self.gui.Enabled = false
            if mainFrame then
                mainFrame.Visible = false
            end
        end
    end)
    
    print("[NookShoppingGUI] ✅ Initialized (hidden and disabled)")
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
    
    -- Find close button (only connect once - store connection to prevent duplicates)
    local closeBtn = findByName(self.gui, "CloseButton")
    if closeBtn and closeBtn:IsA("GuiButton") then
        -- Store connection reference to prevent duplicate connections
        if not self.closeButtonConnection then
            self.closeButtonConnection = closeBtn.MouseButton1Click:Connect(function()
                print("[NookShoppingGUI] ✕ Close button clicked")
                self:hide()
            end)
            print("[NookShoppingGUI] ✅ Connected Close button")
        else
            print("[NookShoppingGUI] ℹ️ Close button already connected")
        end
    else
        -- Try to find close button by other names
        local altCloseBtn = findByName(self.gui, "Close") or 
                           findByName(self.gui, "XButton") or
                           findByName(self.gui, "ExitButton")
        if altCloseBtn and altCloseBtn:IsA("GuiButton") then
            if not self.closeButtonConnection then
                self.closeButtonConnection = altCloseBtn.MouseButton1Click:Connect(function()
                    print("[NookShoppingGUI] ✕ Close button clicked (alternative)")
                    self:hide()
                end)
                print("[NookShoppingGUI] ✅ Connected Close button (alternative)")
            end
        end
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
        else
            print("[NookShoppingGUI] ℹ️ No slot template found - will populate existing labels or create slots")
        end
        
        -- DON'T populate items during setup - wait until show() is called
    -- This prevents the GUI from opening during initialization
    print("[NookShoppingGUI] ℹ️ Items will be populated when GUI is shown")
    else
        warn("[NookShoppingGUI] ⚠️ Could not find items frame in your GUI")
        -- Try to find or create a ScrollingFrame for items
        local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or self.gui:FindFirstChild("ShopContainer")
        if mainFrame then
            -- Try to find a ScrollingFrame or create one
            local scrollFrame = mainFrame:FindFirstChildWhichIsA("ScrollingFrame")
            if scrollFrame then
                self.itemsFrame = scrollFrame
                print("[NookShoppingGUI] ✅ Found ScrollingFrame:", scrollFrame.Name)
                -- DON'T populate items during setup
            else
                warn("[NookShoppingGUI] ⚠️ No ScrollingFrame found for items")
            end
        end
    end
end

-- Unified populate items function that tries multiple methods
function NookShoppingGUI:populateItems()
    if not self.itemsFrame then
        warn("[NookShoppingGUI] ⚠️ Cannot populate - no items frame")
        return
    end
    
    local allShopItems = self.shopData.getAllItems()
    if #allShopItems == 0 then
        warn("[NookShoppingGUI] ⚠️ No items to populate")
        return
    end
    
    -- Try template method first
    if self.slotTemplate then
        print("[NookShoppingGUI] 🛒 Using template method to populate items")
        self:populateItemsFromTemplate()
        return
    end
    
    -- Try existing labels method
    print("[NookShoppingGUI] 🛒 Trying to populate existing labels")
    local populatedCount = self:populateExistingLabels()
    
    -- Check if we actually populated anything
    local hasVisibleItems = false
    for _, child in ipairs(self.itemsFrame:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
            -- Check if it's not a template
            if not child:FindFirstAncestor("ItemSlotTemplate") and
               not child:FindFirstAncestor("NookipediaItem" .. (math.huge)) then
                hasVisibleItems = true
                break
            end
        end
    end
    
    -- If no items were populated, use dynamic method
    if not hasVisibleItems then
        print("[NookShoppingGUI] 🛒 No existing labels found - using dynamic method")
        self:populateItemsDynamic()
    else
        print("[NookShoppingGUI] ✅ Populated existing labels")
    end
end

-- Dynamic item slot creation (fallback if no template or existing labels)
function NookShoppingGUI:populateItemsDynamic()
    if not self.itemsFrame then return end
    
    -- Get all items from ShopData
    local allShopItems = self.shopData.getAllItems()
    
    if #allShopItems == 0 then
        warn("[NookShoppingGUI] ⚠️ No items found in ShopData")
        return
    end
    
    print("[NookShoppingGUI] 🛒 Creating", #allShopItems, "item slots dynamically...")
    
    -- Clear existing dynamic slots
    for _, child in ipairs(self.itemsFrame:GetChildren()) do
        if child.Name:find("DynamicItemSlot") then
            child:Destroy()
        end
    end
    
    -- Create slots for each item
    for i, shopItem in ipairs(allShopItems) do
        local slot = Instance.new("Frame")
        slot.Name = "DynamicItemSlot_" .. shopItem.id
        slot.Size = UDim2.new(1, -20, 0, 80)
        slot.Position = UDim2.new(0, 10, 0, (i - 1) * 85)
        slot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        slot.BorderSizePixel = 1
        slot.BorderColor3 = Color3.fromRGB(100, 100, 100)
        slot.Parent = self.itemsFrame
        
        -- Item icon
        local icon = Instance.new("ImageLabel")
        icon.Name = "ItemIcon"
        icon.Size = UDim2.new(0, 64, 0, 64)
        icon.Position = UDim2.new(0, 10, 0, 8)
        icon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        icon.BorderSizePixel = 1
        icon.Parent = slot
        
        if shopItem.spriteIndex then
            self.spriteConfig.applySprite(icon, shopItem.spriteIndex)
        end
        
        -- Item name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ItemName"
        nameLabel.Size = UDim2.new(1, -90, 0, 30)
        nameLabel.Position = UDim2.new(0, 80, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = shopItem.name or shopItem.id
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 18
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.Parent = slot
        
        -- Item price
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Name = "ItemPrice"
        priceLabel.Size = UDim2.new(1, -90, 0, 30)
        priceLabel.Position = UDim2.new(0, 80, 0, 40)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(shopItem.buyPrice) .. " 🔔"
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextSize = 16
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.Parent = slot
        
        -- Buy button
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyButton"
        buyBtn.Size = UDim2.new(0, 80, 0, 30)
        buyBtn.Position = UDim2.new(1, -90, 0, 25)
        buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        buyBtn.Text = "Buy"
        buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyBtn.TextSize = 16
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.Parent = slot
        
        buyBtn.MouseButton1Click:Connect(function()
            print("[NookShoppingGUI] 💳 Buying:", shopItem.name, "for", shopItem.buyPrice, "bells")
            if self.shopRemote then
                self.shopRemote:FireServer("BuyItem", {
                    itemId = shopItem.id,
                    price = shopItem.buyPrice,
                    count = 1,
                })
            end
        end)
    end
    
    -- Update ScrollingFrame canvas size
    if self.itemsFrame:IsA("ScrollingFrame") then
        self.itemsFrame.CanvasSize = UDim2.new(0, 0, 0, #allShopItems * 85)
    end
    
    print("[NookShoppingGUI] ✅ Created", #allShopItems, "dynamic item slots")
end

function NookShoppingGUI:populateExistingLabels()
    -- Populate the NookipediaItem frames with real data from ShopData
    if not self.itemsFrame then return 0 end
    
    -- Get all items from ShopData
    local allShopItems = self.shopData.getAllItems()
    
    if #allShopItems == 0 then
        warn("[NookShoppingGUI] ⚠️ No items found in ShopData")
        return 0
    end
    
    print("[NookShoppingGUI] 🛒 Loading", #allShopItems, "items from Nook Shopping...")
    
    local populatedCount = 0
    
    for i, shopItem in ipairs(allShopItems) do
        -- Try multiple naming patterns
        local itemFrame = self.itemsFrame:FindFirstChild("NookipediaItem" .. i) or
                         self.itemsFrame:FindFirstChild("Item" .. i) or
                         self.itemsFrame:FindFirstChild(shopItem.id)
        
        if itemFrame then
            print("[NookShoppingGUI] 📝 Populating item frame:", itemFrame.Name, "with:", shopItem.name)
            
            -- Update name
            local nameLabel = itemFrame:FindFirstChild("ItemName") or 
                             itemFrame:FindFirstChild("Name") or
                             itemFrame:FindFirstChild("ItemNameLabel")
            if nameLabel and nameLabel:IsA("TextLabel") then
                nameLabel.Text = shopItem.name
                nameLabel.Visible = true
                populatedCount = populatedCount + 1
            end
            
            -- Update price
            local priceLabel = itemFrame:FindFirstChild("ItemPrice") or
                              itemFrame:FindFirstChild("Price") or
                              itemFrame:FindFirstChild("PriceLabel")
            if priceLabel and priceLabel:IsA("TextLabel") then
                priceLabel.Text = tostring(shopItem.buyPrice) .. " 🔔"
                priceLabel.Visible = true
            end
            
            -- Update icon
            local iconImage = itemFrame:FindFirstChild("ItemIcon") or
                             itemFrame:FindFirstChild("Icon") or
                             itemFrame:FindFirstChild("ItemImage")
            if iconImage and iconImage:IsA("ImageLabel") then
                if shopItem.spriteIndex then
                    local success = self.spriteConfig.applySprite(iconImage, shopItem.spriteIndex)
                    if success then
                        iconImage.Visible = true
                        print("[NookShoppingGUI] ✅ Applied sprite", shopItem.spriteIndex, "to", shopItem.name)
                    else
                        print("[NookShoppingGUI] ⚠️ Failed to apply sprite", shopItem.spriteIndex, "for", shopItem.name)
                    end
                else
                    print("[NookShoppingGUI] ⚠️ No sprite for", shopItem.name, "- needs sprite mapping")
                end
            end
            
            -- Make the frame visible
            itemFrame.Visible = true
            
            -- Find the Frame inside that contains icon/name
            local contentFrame = nil
            for _, child in ipairs(itemFrame:GetChildren()) do
                if child:IsA("Frame") and (child.Name == "Frame" or child.Name == "Content") then
                    contentFrame = child
                    break
                end
            end
            
            -- Try finding icon in the content frame
            if contentFrame and shopItem.spriteIndex then
                local frameIcon = contentFrame:FindFirstChild("ItemIcon") or
                                 contentFrame:FindFirstChild("Icon")
                if frameIcon and frameIcon:IsA("ImageLabel") then
                    local success = self.spriteConfig.applySprite(frameIcon, shopItem.spriteIndex)
                    if success then
                        frameIcon.Visible = true
                        print("[NookShoppingGUI] ✅ Applied sprite to content frame")
                    end
                end
            end
        end
    end
    
    if populatedCount > 0 then
        print("[NookShoppingGUI] ✅ Populated", populatedCount, "existing item frames")
    else
        print("[NookShoppingGUI] ℹ️ No existing item frames found to populate")
    end
    
    return populatedCount
end

function NookShoppingGUI:populateItemsFromTemplate()
    -- If you have a template slot, clone it and populate with real items
    if not self.slotTemplate or not self.itemsFrame then return end
    
    -- Get all items from ShopData
    local allShopItems = self.shopData.getAllItems()
    
    if #allShopItems == 0 then
        warn("[NookShoppingGUI] ⚠️ No items found in ShopData")
        return
    end
    
    print("[NookShoppingGUI] 🛒 Loading", #allShopItems, "items from Nook Shopping...")
    
    for _, shopItem in ipairs(allShopItems) do
        local slot = self.slotTemplate:Clone()
        slot.Name = shopItem.id
        slot.Visible = true
        
        -- Update label names in your slot template
        local nameLabel = slot:FindFirstChild("ItemName") or slot:FindFirstChild("Name") or slot:FindFirstChild("ItemNameLabel")
        local priceLabel = slot:FindFirstChild("ItemPrice") or slot:FindFirstChild("Price") or slot:FindFirstChild("PriceLabel")
        local iconLabel = slot:FindFirstChild("ItemIcon") or slot:FindFirstChild("Icon") or slot:FindFirstChild("ItemImage")
        
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = shopItem.name
        end
        
        if priceLabel and priceLabel:IsA("TextLabel") then
            priceLabel.Text = tostring(shopItem.buyPrice) .. "🔔"
        end
        
        if iconLabel and iconLabel:IsA("ImageLabel") then
            if shopItem.spriteIndex then
                local success = self.spriteConfig.applySprite(iconLabel, shopItem.spriteIndex)
                if not success then
                    -- Fallback: show placeholder
                    iconLabel.BackgroundTransparency = 0
                    iconLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    iconLabel.Image = ""
                    print("[NookShoppingGUI] ⚠️ Failed to apply sprite", shopItem.spriteIndex, "for", shopItem.name)
                end
            else
                -- No sprite available - show placeholder
                iconLabel.BackgroundTransparency = 0
                iconLabel.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                iconLabel.Image = ""
                print("[NookShoppingGUI] ⚠️ No sprite for", shopItem.name, "- needs sprite mapping")
            end
        end
        
        -- Find and connect buy button if it exists
        local buyBtn = slot:FindFirstChild("BuyButton") or slot:FindFirstChildWhichIsA("TextButton")
        if buyBtn then
            buyBtn.MouseButton1Click:Connect(function()
                print("[NookShoppingGUI] 💳 Buying:", shopItem.name, "for", shopItem.buyPrice, "bells")
                if self.shopRemote then
                    self.shopRemote:FireServer("BuyItem", {
                        itemId = shopItem.id,
                        price = shopItem.buyPrice,
                        count = 1,
                    })
                end
            end)
        end
        
        slot.Parent = self.itemsFrame
    end
    
    print("[NookShoppingGUI] ✅ Populated", #allShopItems, "items from Nook Shopping")
end

function NookShoppingGUI:connectToServer()
    -- Listen for currency updates (but don't open GUI)
    if self.currencyRemote then
        -- Only connect once - store connection to prevent duplicates
        if not self.currencyConnection then
            self.currencyConnection = self.currencyRemote.OnClientEvent:Connect(function(action, data)
                if action == "UpdateBells" then
                    self.bells = data.amount or data.bells or 0
                    -- Don't print every time - only if GUI is visible
                    if self.visible then
                        print("[NookShoppingGUI] 💰 Bells updated:", self.bells)
                    end
                    -- CRITICAL: Do NOT open GUI when currency updates
                end
            end)
        end
    end
end

function NookShoppingGUI:show()
    if not self.gui then 
        print("[NookShoppingGUI] ❌ Cannot show - gui is nil")
        return 
    end
    
    -- CRITICAL: Prevent re-entrancy (if already showing, ignore)
    if self.isShowing then
        print("[NookShoppingGUI] ℹ️ Already showing - ignoring duplicate show() call")
        return
    end
    
    -- CRITICAL: Prevent repeated opening if already visible
    if self.visible and self.gui.Enabled then
        print("[NookShoppingGUI] ℹ️ Already visible - ignoring show() call")
        return
    end
    
    -- Set flag to prevent re-entrancy
    self.isShowing = true
    
    -- Prevent hiding while showing
    if self.isHiding then
        print("[NookShoppingGUI] ⚠️ Currently hiding - waiting...")
        task.wait(0.1)
        -- Re-check visibility after waiting
        if not self.visible then
            self.isShowing = false
            return
        end
    end
    
    -- Only show if explicitly called (not auto-opened)
    self.visible = true
    self.gui.Enabled = true
    
    -- Find and show the main frame (try multiple names)
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or 
                      self.gui:FindFirstChild("ShopContainer") or
                      self.gui:FindFirstChildWhichIsA("Frame")
    
    if mainFrame then
        mainFrame.Visible = true
        -- Also ensure all child frames are visible (but skip templates)
        for _, child in ipairs(mainFrame:GetDescendants()) do
            if child:IsA("GuiObject") and child.Name ~= "ItemSlotTemplate" then
                -- Only show if it's not a template or placeholder
                if not child.Name:find("Template") and not child.Name:find("Placeholder") then
                    child.Visible = true
                end
            end
        end
        print("[NookShoppingGUI] 🛒 NookShopping opened - MainFrame:", mainFrame.Name)
    else
        warn("[NookShoppingGUI] ⚠️ Main frame not found - GUI structure may be incorrect")
    end
    
    -- Refresh items when showing (in case data changed) - only if not already populated
    if not self.itemsPopulated then
        self:populateItems()
        self.itemsPopulated = true
    end
    
    -- Clear showing flag
    self.isShowing = false
end

function NookShoppingGUI:hide()
    if not self.gui then return end
    
    -- CRITICAL: Prevent re-entrancy (if already hiding, ignore)
    if self.isHiding then
        print("[NookShoppingGUI] ℹ️ Already hiding - ignoring duplicate hide() call")
        return
    end
    
    -- CRITICAL: Prevent repeated hiding if already hidden
    if not self.visible and not self.gui.Enabled then
        print("[NookShoppingGUI] ℹ️ Already hidden - ignoring hide() call")
        return
    end
    
    -- Set flag to prevent re-entrancy
    self.isHiding = true
    
    -- Prevent showing while hiding
    if self.isShowing then
        print("[NookShoppingGUI] ⚠️ Currently showing - waiting...")
        task.wait(0.1)
    end
    
    self.visible = false
    self.gui.Enabled = false  -- Disable the ScreenGui first
    
    -- Hide ALL frames in the GUI (including main frame)
    local function hideAllFrames(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
        -- Also hide direct children
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end
    hideAllFrames(self.gui)
    
    -- Hide the main frame explicitly
    local mainFrame = self.gui:FindFirstChild("NookShoppingFrame") or 
                      self.gui:FindFirstChild("ShopContainer") or
                      self.gui:FindFirstChildWhichIsA("Frame")
    if mainFrame then
        mainFrame.Visible = false
    end
    
    -- Double-check that GUI is disabled
    self.gui.Enabled = false
    
    -- Clear hiding flag
    self.isHiding = false
    
    print("[NookShoppingGUI] 🛒 NookShopping closed")
end

function NookShoppingGUI:toggle()
    -- Use explicit check to prevent issues
    if self.visible then
        self:hide()
    else
        self:show()
    end
end

function NookShoppingGUI:isVisible()
    -- Return true only if both flags indicate visibility
    return self.visible and (self.gui and self.gui.Enabled == true)
end

-- Cleanup function to disconnect events
function NookShoppingGUI:cleanup()
    if self.currencyConnection then
        self.currencyConnection:Disconnect()
        self.currencyConnection = nil
    end
    if self.closeButtonConnection then
        self.closeButtonConnection:Disconnect()
        self.closeButtonConnection = nil
    end
    self:hide()
end

-- Alias methods for GUIManager compatibility
NookShoppingGUI.Show = NookShoppingGUI.show
NookShoppingGUI.Hide = NookShoppingGUI.hide
NookShoppingGUI.Toggle = NookShoppingGUI.toggle

return NookShoppingGUI

