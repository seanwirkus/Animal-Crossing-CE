# GUI Content Management System

## Overview

The `GUIContentManager.luau` provides a centralized system for managing all GUI content, styling, and configuration across your Animal Crossing CE game. This replaces scattered hardcoded strings and configurations with a single source of truth.

## Key Benefits

- **Centralized Content**: All text, messages, and UI strings in one place
- **Consistent Styling**: Predefined style presets for buttons, windows, and text
- **Easy Maintenance**: Change content across all GUIs by editing one file
- **Theme Integration**: Automatic application of ACNH color scheme and styling
- **Extensible**: Easy to add new GUI modules and content

## File Structure

```
GUIContentManager
├── LoadingScreen     # Loading screen tips, buttons, assets
├── Inventory         # Inventory titles, buttons, messages
├── Crafting          # Crafting interface content
├── Shop              # Shop interface content
├── Dialogue          # NPC dialogue and conversation content
├── Settings          # Settings menu content
├── Notifications     # Notification messages and styles
├── Tutorial          # Tutorial steps and content
└── Styles            # UI style presets (buttons, windows, text)
```

## Usage Examples

### Getting Loading Screen Content

```lua
local GUIContent = require(path.to.GUIContentManager)

-- Get all loading tips
local tips = GUIContent.getLoadingTips()

-- Get start button configuration
local startButton = GUIContent.LoadingScreen.buttons.start
print(startButton.text) -- "Start Your Island Life!"
```

### Using Style Presets

```lua
-- Get a primary button style
local buttonStyle = GUIContent.getButtonStyle("primary")
-- Returns: {backgroundColor="buttonBrown", textColor="textLight", ...}

-- Apply theme colors automatically
local themedStyle = GUIContent.applyThemeToStyle(buttonStyle)
```

### Formatting Messages

```lua
-- Format messages with placeholders
local message = GUIContent.formatMessage(
    "Received {item}!",
    {item = "Golden Axe"}
)
-- Result: "Received Golden Axe!"
```

### Getting GUI-Specific Content

```lua
-- Get all crafting GUI content
local craftingContent = GUIContent.getGUIContent("Crafting")
print(craftingContent.title) -- "Crafting"
print(craftingContent.buttons.craft) -- "Craft"
```

## Integration Guide

### 1. Replace Hardcoded Strings

**Before:**
```lua
startButton.Text = "Press to Start"
```

**After:**
```lua
local GUIContent = require(path.to.GUIContentManager)
startButton.Text = GUIContent.LoadingScreen.buttons.start.text
```

### 2. Use Style Presets

**Before:**
```lua
button.BackgroundColor3 = Color3.fromRGB(121, 85, 72)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
```

**After:**
```lua
local buttonStyle = GUIContent.getButtonStyle("primary")
local themedStyle = GUIContent.applyThemeToStyle(buttonStyle)
button.BackgroundColor3 = themedStyle.backgroundColor
button.TextColor3 = themedStyle.textColor
```

### 3. Centralize Messages

**Before:**
```lua
showMessage("Not enough materials!")
```

**After:**
```lua
local message = GUIContent.Crafting.messages.noMaterials
showMessage(message)
```

## Adding New Content

### Adding a New GUI Module

```lua
GUIContentManager.NewGUI = {
    title = "My New GUI",
    buttons = {
        confirm = {text = "Confirm", size = UDim2.new(0, 100, 0, 40)},
        cancel = {text = "Cancel", size = UDim2.new(0, 100, 0, 40)},
    },
    messages = {
        success = "Operation completed!",
        error = "Something went wrong.",
    },
}
```

### Adding New Style Presets

```lua
GUIContentManager.Styles.buttons.danger = {
    backgroundColor = "notificationRed",
    textColor = "textLight",
    cornerRadius = "medium",
    font = "bold",
    textSize = "medium",
}
```

## Current Integrations

- ✅ **LoadingScreen**: Tips, button text, status messages
- ✅ **Theme Integration**: Automatic color and style application
- 🔄 **Crafting GUI**: Partially integrated (needs API fixes)
- 🔄 **Other GUIs**: Ready for integration

## Migration Checklist

- [ ] Update LoadingScreen to use GUIContentManager
- [ ] Update CraftingGUI to use centralized content
- [ ] Update ShopGUI to use centralized content
- [ ] Update DialogueGUI to use centralized content
- [ ] Update SettingsGUI to use centralized content
- [ ] Update Notification system to use centralized messages
- [ ] Update Tutorial system to use centralized content

## Best Practices

1. **Always use GUIContentManager** for new GUI development
2. **Test changes** in Roblox Studio to ensure proper display
3. **Use style presets** for consistency
4. **Format messages** with placeholders for dynamic content
5. **Document new content** in this README

## Troubleshooting

**GUI not updating?**
- Ensure you're requiring the correct path to GUIContentManager
- Check that the content key exists in the module
- Verify ThemeProvider is properly loaded for styling

**Styles not applying?**
- Use `applyThemeToStyle()` to convert theme references to actual colors
- Check that ThemeProvider has the required color/radius methods

**Content not found?**
- Verify the content exists in GUIContentManager
- Check for typos in key names
- Ensure the module is properly loaded