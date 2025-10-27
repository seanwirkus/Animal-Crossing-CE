# InventoryStyling Module - Quick Reference

Location: `src/client/InventoryStyling.lua`

This module centralizes all inventory visual styling. Make changes here instead of hunting through the main inventory script!

---

## Quick Color Change

### Change Hover Color to Teal (04AFA6)

Edit `InventoryStyling.lua` and find:

```lua
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(200, 200, 200),
	DefaultBackgroundTransparency = 0.2,
	HoverBackgroundColor = Color3.fromRGB(4, 175, 166),      -- ← CHANGE THIS
	HoverBackgroundTransparency = 0.1,
	...
}
```

That's already set to the teal color you wanted! (04AFA6 in hex = 4, 175, 166 in RGB)

---

## All Customizable Colors

### Slot Colors
```lua
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(200, 200, 200),    -- Normal state
	DefaultBackgroundTransparency = 0.2,                        -- Transparency 0-1
	HoverBackgroundColor = Color3.fromRGB(4, 175, 166),        -- On hover
	HoverBackgroundTransparency = 0.1,                          -- Hover transparency
	BorderColor = Color3.fromRGB(100, 100, 100),               -- Border color
	BorderSizePixel = 1,                                        -- Border thickness
}
```

### Item Count Badge
```lua
InventoryStyling.ItemCount = {
	TextColor = Color3.fromRGB(255, 255, 255),        -- Number color (white)
	BackgroundColor = Color3.fromRGB(0, 0, 0),        -- Badge background (black)
	BackgroundTransparency = 0.3,                      -- Badge transparency
	TextSize = 16,                                     -- Size of number
	Font = Enum.Font.GothamBold,                       -- Font style
	Visible = true,                                    -- Show badge when count > 1
}
```

### Item Name Label
```lua
InventoryStyling.ItemName = {
	TextColor = Color3.fromRGB(0, 0, 0),              -- Text color (black)
	BackgroundColor = Color3.fromRGB(255, 255, 255),  -- Label background (white)
	BackgroundTransparency = 0.5,                      -- Label transparency
	TextSize = 14,                                     -- Size of label text
	Font = Enum.Font.Gotham,                          -- Font style
	Visible = false,                                   -- Hidden by default
}
```

### Inventory Frame
```lua
InventoryStyling.InventoryFrame = {
	BackgroundColor = Color3.fromRGB(220, 220, 220),  -- Frame background
	BackgroundTransparency = 0.05,                     -- Frame transparency
	BorderColor = Color3.fromRGB(100, 100, 100),      -- Border color
	BorderSizePixel = 1,                              -- Border thickness
}
```

---

## Color Reference

### Pre-Made Colors (Copy-Paste)
```lua
-- Grays
Color3.fromRGB(200, 200, 200)    -- Light gray
Color3.fromRGB(150, 150, 150)    -- Medium gray
Color3.fromRGB(100, 100, 100)    -- Dark gray
Color3.fromRGB(50, 50, 50)       -- Very dark gray

-- Bright Colors
Color3.fromRGB(255, 0, 0)        -- Red
Color3.fromRGB(0, 255, 0)        -- Green
Color3.fromRGB(0, 0, 255)        -- Blue
Color3.fromRGB(255, 255, 0)      -- Yellow

-- Pastels
Color3.fromRGB(255, 200, 150)    -- Peachy
Color3.fromRGB(200, 255, 200)    -- Light green
Color3.fromRGB(150, 200, 255)    -- Light blue

-- Animal Crossing-style
Color3.fromRGB(216, 200, 180)    -- AC Tan
Color3.fromRGB(139, 90, 43)      -- AC Brown
Color3.fromRGB(4, 175, 166)      -- AC Teal (your choice!)
```

---

## Using Hex Colors

If you have a hex color code, use the helper function:

```lua
-- Instead of figuring out RGB values:
local teal = InventoryStyling.HexToRGB("04AFA6")
slot.BackgroundColor3 = teal

-- Or in the module:
HoverBackgroundColor = InventoryStyling.HexToRGB("04AFA6"),
```

---

## Animation Settings

```lua
InventoryStyling.Animation = {
	HoverDuration = 0,              -- 0 for instant, 0.1-0.5 for animation
	DragDuration = 0,               -- Duration when starting drag
	DropDuration = 0,               -- Duration when dropping
	EasingStyle = Enum.EasingStyle.Sine,
	EasingDirection = Enum.EasingDirection.Out,
}
```

### Make Hover Animated (Optional)
```lua
HoverDuration = 0.2,  -- Smooth 0.2 second transition
```

---

## Example Customizations

### Make Inventory Look Like Animal Crossing

```lua
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(216, 200, 180),    -- AC Tan
	DefaultBackgroundTransparency = 0,                          -- Opaque
	HoverBackgroundColor = Color3.fromRGB(4, 175, 166),        -- AC Teal
	HoverBackgroundTransparency = 0,                            -- Opaque
	BorderColor = Color3.fromRGB(139, 90, 43),                 -- AC Brown
	BorderSizePixel = 2,                                        -- Thicker border
}
```

### Dark Mode Theme

```lua
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(50, 50, 50),       -- Dark gray
	DefaultBackgroundTransparency = 0,
	HoverBackgroundColor = Color3.fromRGB(100, 100, 100),      -- Lighter on hover
	HoverBackgroundTransparency = 0,
	BorderColor = Color3.fromRGB(255, 255, 255),               -- White border
	BorderSizePixel = 1,
}

InventoryStyling.ItemCount = {
	TextColor = Color3.fromRGB(255, 255, 255),                 -- White text
	BackgroundColor = Color3.fromRGB(0, 0, 0),                 -- Black badge
	...
}
```

### Neon/Bright Theme

```lua
InventoryStyling.Slot = {
	DefaultBackgroundColor = Color3.fromRGB(0, 0, 0),          -- Black
	DefaultBackgroundTransparency = 0,
	HoverBackgroundColor = Color3.fromRGB(0, 255, 0),          -- Bright green
	HoverBackgroundTransparency = 0,
	BorderColor = Color3.fromRGB(255, 0, 255),                 -- Magenta
	BorderSizePixel = 2,
}
```

---

## Functions Available

### Apply Styling Functions
```lua
-- Apply default styling to a slot
InventoryStyling.ApplySlotStyling(slot)

-- Apply hover styling to a slot
InventoryStyling.ApplyHoverStyling(slot)

-- Remove hover styling (reset to default)
InventoryStyling.ResetSlotStyling(slot)

-- Apply styling to item count badge
InventoryStyling.ApplyItemCountStyling(itemCountLabel)

-- Apply styling to item name label
InventoryStyling.ApplyItemNameStyling(itemNameLabel)
```

### Utility Functions
```lua
-- Convert hex color to RGB
local color = InventoryStyling.HexToRGB("04AFA6")

-- Create tween info with styling settings
local tweenInfo = InventoryStyling.CreateTweenInfo(duration)
```

---

## How It's Used in init.client.luau

The main inventory script now calls styling functions:

```lua
function configureSlotFrame(slot, slotIndex)
	-- ... setup code ...
	
	-- Apply styling
	InventoryStyling.ApplySlotStyling(slot)
	
	-- Hover effects
	clickButton.MouseEnter:Connect(function()
		InventoryStyling.ApplyHoverStyling(slot)
	end)
	
	clickButton.MouseLeave:Connect(function()
		InventoryStyling.ResetSlotStyling(slot)
	end)
	
	-- ... rest of setup ...
end
```

---

## File Location

**Module**: `/Users/sean/Desktop/Animal Crossing CE/src/client/InventoryStyling.lua`

**Used by**: `/Users/sean/Desktop/Animal Crossing CE/src/client/init.client.luau`

---

## Changes Needed Going Forward

### If You Want to Change Hover Color
Edit `InventoryStyling.lua`, change `HoverBackgroundColor`:

```lua
HoverBackgroundColor = Color3.fromRGB(4, 175, 166),  -- Your color here
```

### If You Want to Change All Slot Colors
Edit each property in the `Slot` table:

```lua
DefaultBackgroundColor = Color3.fromRGB(255, 0, 0),  -- Red slots
HoverBackgroundColor = Color3.fromRGB(0, 255, 0),    -- Green on hover
```

### If You Want Animated Hover
Set `HoverDuration`:

```lua
HoverDuration = 0.3,  -- Smooth 0.3 second transition
```

---

## Tips

1. **Make Changes Here First** - Before adding styling code elsewhere
2. **Test Immediately** - Changes to the module take effect on next game load
3. **Use Helper Functions** - Don't duplicate styling logic in multiple places
4. **Keep It Organized** - Add comments if you create custom color schemes
5. **Compare Themes** - Keep old color values commented for easy switching

---

## Common Tasks

### Task: Change slot hover color to bright blue
```lua
HoverBackgroundColor = Color3.fromRGB(0, 150, 255),
```

### Task: Make slots transparent
```lua
DefaultBackgroundTransparency = 0.7,
HoverBackgroundTransparency = 0.5,
```

### Task: Make item count more visible
```lua
TextSize = 20,                              -- Bigger
BackgroundTransparency = 0.1,               -- Less transparent
```

### Task: Hide item count completely
```lua
Visible = false,
```

### Task: Animated hover effect
```lua
HoverDuration = 0.2,
EasingStyle = Enum.EasingStyle.Back,
EasingDirection = Enum.EasingDirection.Out,
```

---

You've got the power now! Customize away! 🎨

