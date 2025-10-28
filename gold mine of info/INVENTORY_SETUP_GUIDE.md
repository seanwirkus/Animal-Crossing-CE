# 🎒 Inventory GUI Setup Guide

## How to Use the Dynamic Controller System

### 1. Import Your InventoryGUI.rbxmx

1. **In Roblox Studio:**
   - Import your `InventoryGUI.rbxmx` file into `StarterGui`
   - Make sure it's named `InventoryGUI`

### 2. Set the Controller Attribute

1. **Select your InventoryGUI ScreenGui**
2. **In Properties panel, find Attributes**
3. **Add a new attribute:**
   - Name: `Controller`
   - Type: `String`
   - Value: `InventoryController`

### 3. The System Will Automatically:

- ✅ **Detect the GUI** when it's added to PlayerGui
- ✅ **Load the controller** from ReplicatedStorage.Controllers.InventoryController
- ✅ **Attach the controller** to your GUI
- ✅ **Handle input** (E key to toggle, Escape to close)

### 4. How It Works:

```lua
-- The UIController automatically does this:
local controllerName = gui:GetAttribute("Controller") -- "InventoryController"
local Controller = require(ReplicatedStorage.Controllers[controllerName])
local instance = Controller.new(gui)
```

### 5. Adding More GUIs:

To add more GUIs with controllers:

1. **Import your GUI** (e.g., `ShopGUI.rbxmx`)
2. **Set the Controller attribute** (e.g., `ShopController`)
3. **Create the controller** in `src/shared/Controllers/ShopController.luau`
4. **The system handles the rest automatically!**

### 6. Controller Template:

```lua
-- src/shared/Controllers/YourController.luau
local YourController = {}

function YourController.new(gui)
    local self = setmetatable({}, YourController)
    
    self._gui = gui
    
    -- Your initialization code here
    
    return self
end

-- Add methods like Show(), Hide(), Toggle(), etc.

return YourController
```

## Benefits:

- ✅ **No hardcoded GUI names**
- ✅ **Automatic controller attachment**
- ✅ **Easy to add new GUIs**
- ✅ **Clean separation of concerns**
- ✅ **Reusable controller system**

## Current Setup:

- **E key**: Toggle inventory
- **Escape key**: Close any open GUI
- **Automatic**: Controllers attach when GUIs are added
