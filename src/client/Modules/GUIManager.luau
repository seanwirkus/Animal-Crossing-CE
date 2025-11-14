-- GUIManager.luau
-- Manages GUI visibility so only one GUI is visible at a time

local GUIManager = {}
GUIManager.__index = GUIManager

-- GUI registry
local registeredGUIs = {}
local currentVisibleGUI = nil
local suppressedUntil: { [string]: number } = {}

function GUIManager.new()
    local self = setmetatable({}, GUIManager)
    return self
end

-- Register a GUI with a unique name
function GUIManager:registerGUI(name, guiObject)
    if not name or not guiObject then
        warn("[GUIManager] Invalid registration:", name, guiObject)
        return false
    end

    registeredGUIs[name] = {
        object = guiObject,
        name = name,
    }

    print("[GUIManager] ✅ Registered GUI:", name)

    -- Apply universal presets to newly registered GUI
    task.spawn(function()
        local success, err = pcall(function()
            local UniversalGUIPreset = require(script.Parent.UniversalGUIPreset)
            UniversalGUIPreset.applyToGUI(guiObject)
        end)
        if not success then
            warn("[GUIManager] Failed to apply universal presets to", name, ":", err)
        end
    end)

    return true
end

-- Helper to hide a GUI object
local function hideGUIObject(obj)
    if not obj then
        return
    end

    -- Check if it's a table (Lua object) or Instance (Roblox object)
    local objType = typeof(obj)

    -- For tables, check for Hide method using rawget (capitalized first, then lowercase)
    if objType == "table" then
        local hideMember = rawget(obj, "Hide") or rawget(obj, "hide")
        if hideMember and typeof(hideMember) == "function" then
            local ok, err = pcall(function()
                hideMember(obj) -- Call with obj as self
            end)
            if not ok then
                warn("[GUIManager] Hide()/hide() threw error:", err)
            else
                print("[GUIManager] ✅ Called Hide()/hide() method successfully")
            end
            return
        else
            -- Try accessing through metatable/index
            local hasHide, hideFunc = pcall(function()
                return obj.Hide
            end)
            if hasHide and hideFunc and typeof(hideFunc) == "function" then
                local ok, err = pcall(function()
                    obj:Hide()
                end)
                if not ok then
                    warn("[GUIManager] obj:Hide() threw error:", err)
                else
                    print("[GUIManager] ✅ Called obj:Hide() successfully")
                end
                return
            end
            -- Try lowercase
            local hasHide2, hideFunc2 = pcall(function()
                return obj.hide
            end)
            if hasHide2 and hideFunc2 and typeof(hideFunc2) == "function" then
                local ok, err = pcall(function()
                    obj:hide()
                end)
                if not ok then
                    warn("[GUIManager] obj:hide() threw error:", err)
                else
                    print("[GUIManager] ✅ Called obj:hide() successfully")
                end
                return
            end
        end
    end

    -- For Instances, check for Hide method safely
    if objType == "Instance" then
        local hasHide, hideMethod = pcall(function()
            return obj.Hide
        end)
        if hasHide and typeof(hideMethod) == "function" then
            local ok, err = pcall(function()
                obj:Hide()
            end)
            if not ok then
                warn("[GUIManager] Hide() threw error:", err)
            end
            return
        end
    end

    -- Inventory pattern (works for both tables and Instances)
    -- Safely check if setInventoryVisible exists and is a function
    local hasSetInventoryVisible, setInventoryVisibleMethod = pcall(function()
        return obj.setInventoryVisible
    end)
    if hasSetInventoryVisible and setInventoryVisibleMethod and typeof(setInventoryVisibleMethod) == "function" then
        local ok, err = pcall(function()
            obj:setInventoryVisible(false)
        end)
        if not ok then
            warn("[GUIManager] setInventoryVisible() threw error:", err)
        end
        return
    end

    -- Generic close pattern - safely check
    local hasClose, closeMethod = pcall(function()
        return obj.close
    end)
    if hasClose and closeMethod and typeof(closeMethod) == "function" then
        local ok, err = pcall(function()
            obj:close()
        end)
        if not ok then
            warn("[GUIManager] close() threw error:", err)
        end
        return
    end

    -- Instance fallbacks
    if objType == "Instance" then
        if obj:IsA("GuiObject") then
            obj.Visible = false
        elseif obj:IsA("ScreenGui") then
            obj.Enabled = false
        end
    end
end

-- Helper to show a GUI object
local function showGUIObject(obj)
    if not obj then
        return
    end

    -- Check if it's a table (Lua object) or Instance (Roblox object)
    local objType = typeof(obj)

    -- For tables, check for Show method using rawget (capitalized first, then lowercase)
    if objType == "table" then
        local showMember = rawget(obj, "Show") or rawget(obj, "show")
        if showMember and typeof(showMember) == "function" then
            local ok, err = pcall(function()
                showMember(obj) -- Call with obj as self
            end)
            if not ok then
                warn("[GUIManager] Show()/show() threw error:", err)
            else
                print("[GUIManager] ✅ Called Show()/show() method successfully")
            end
            return
        else
            -- Try accessing through metatable/index
            local hasShow, showFunc = pcall(function()
                return obj.Show
            end)
            if hasShow and showFunc and typeof(showFunc) == "function" then
                local ok, err = pcall(function()
                    obj:Show()
                end)
                if not ok then
                    warn("[GUIManager] obj:Show() threw error:", err)
                else
                    print("[GUIManager] ✅ Called obj:Show() successfully")
                end
                return
            end
            -- Try lowercase
            local hasShow2, showFunc2 = pcall(function()
                return obj.show
            end)
            if hasShow2 and showFunc2 and typeof(showFunc2) == "function" then
                local ok, err = pcall(function()
                    obj:show()
                end)
                if not ok then
                    warn("[GUIManager] obj:show() threw error:", err)
                else
                    print("[GUIManager] ✅ Called obj:show() successfully")
                end
                return
            end
        end
    end

    -- For Instances, check for Show method safely
    if objType == "Instance" then
        local hasShow, showMethod = pcall(function()
            return obj.Show
        end)
        if hasShow and typeof(showMethod) == "function" then
            local ok, err = pcall(function()
                obj:Show()
            end)
            if not ok then
                warn("[GUIManager] Show() threw error:", err)
            end
            return
        end
    end

    -- Inventory pattern - safely check
    local hasSetInventoryVisible, setInventoryVisibleMethod = pcall(function()
        return obj.setInventoryVisible
    end)
    if hasSetInventoryVisible and setInventoryVisibleMethod and typeof(setInventoryVisibleMethod) == "function" then
        local ok, err = pcall(function()
            obj:setInventoryVisible(true)
        end)
        if not ok then
            warn("[GUIManager] setInventoryVisible() threw error:", err)
        end
        return
    end

    -- Generic open pattern - safely check
    local hasOpen, openMethod = pcall(function()
        return obj.open
    end)
    if hasOpen and openMethod and typeof(openMethod) == "function" then
        local ok, err = pcall(function()
            obj:open()
        end)
        if not ok then
            warn("[GUIManager] open() threw error:", err)
        end
        return
    end

    if objType == "Instance" then
        if obj:IsA("GuiObject") then
            obj.Visible = true
        elseif obj:IsA("ScreenGui") then
            obj.Enabled = true
        end
    end
end

-- Show a GUI (hides current one if different)
function GUIManager:showGUI(name)
    if not registeredGUIs[name] then
        warn("[GUIManager] GUI not registered:", name)
        return false
    end

    -- Suppression window: ignore auto-show for specific GUIs for a short time
    local now = os.clock()
    local untilTs = suppressedUntil[name]
    if untilTs and now < untilTs then
        print(string.format("[GUIManager] ⏳ Suppressed show for '%s' for %.2fs more", name, untilTs - now))
        return false
    end

    local guiData = registeredGUIs[name]

    -- Prevent showing if already visible
    if currentVisibleGUI == name then
        -- Check if GUI is actually visible
        local isVisible = false
        if guiData.object and typeof(guiData.object) == "table" then
            local hasIsVisible = pcall(function()
                return guiData.object.isVisible
            end)
            if hasIsVisible and guiData.object.isVisible then
                local visibleResult = pcall(function()
                    return guiData.object:isVisible()
                end)
                if visibleResult then
                    isVisible = guiData.object:isVisible()
                end
            end
        end

        if isVisible then
            print("[GUIManager] GUI already visible:", name)
            return true
        end
    end

    -- Hide current GUI if it's different
    if currentVisibleGUI and currentVisibleGUI ~= name then
        local currentData = registeredGUIs[currentVisibleGUI]
        if currentData and currentData.object then
            hideGUIObject(currentData.object)
            print("[GUIManager] Hiding GUI:", currentVisibleGUI)
        end
    end

    -- Show new GUI
    showGUIObject(guiData.object)

    currentVisibleGUI = name
    print("[GUIManager] Showing GUI:", name)
    return true
end

-- Hide a GUI
function GUIManager:hideGUI(name)
    if not registeredGUIs[name] then
        return false
    end

    local guiData = registeredGUIs[name]

    -- Use helper to hide
    hideGUIObject(guiData.object)

    if currentVisibleGUI == name then
        currentVisibleGUI = nil
    end

    print("[GUIManager] Hiding GUI:", name)
    return true
end

-- Toggle a GUI (show if hidden, hide if shown, hide others)
function GUIManager:toggleGUI(name)
    if not registeredGUIs[name] then
        warn("[GUIManager] GUI not registered:", name)
        return false
    end

    if currentVisibleGUI == name then
        -- Currently visible, hide it
        return self:hideGUI(name)
    else
        -- Currently hidden, show it (will hide others)
        return self:showGUI(name)
    end
end

-- Hide all GUIs
function GUIManager:hideAll()
    for name, _ in pairs(registeredGUIs) do
        self:hideGUI(name)
    end
    print("[GUIManager] All GUIs hidden")
end

-- Get currently visible GUI name
function GUIManager:getCurrentVisible()
    return currentVisibleGUI
end

-- Check if a GUI is visible
function GUIManager:isVisible(name)
    return currentVisibleGUI == name
end

-- Expose currentVisibleGUI for external access (used by DebugManager wrapper)
function GUIManager:setCurrentVisible(name)
    currentVisibleGUI = name
end

-- Suppress auto-show for specific GUI names for a duration (seconds)
function GUIManager:suppress(names: { string }, duration: number)
    local untilTs = os.clock() + math.max(0, duration or 0)
    for _, n in ipairs(names) do
        suppressedUntil[n] = untilTs
        print(string.format("[GUIManager] 🚫 Suppressing '%s' for %.2fs", n, duration))
    end
end

-- Clear suppression for a GUI name
function GUIManager:clearSuppression(name: string)
    suppressedUntil[name] = nil
end

-- Clear all suppressions
function GUIManager:clearAllSuppressions()
    suppressedUntil = {}
end

-- Apply universal presets to all registered GUIs
function GUIManager:applyUniversalPresets()
    task.spawn(function()
        local success, err = pcall(function()
            local UniversalGUIPreset = require(script.Parent.UniversalGUIPreset)
            UniversalGUIPreset.applyToRegisteredGUIs(registeredGUIs)
        end)
        if not success then
            warn("[GUIManager] Failed to apply universal presets:", err)
        end
    end)
end

return GUIManager
