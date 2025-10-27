# StarterGUI Styling Reference (as of 10.26)

**CRITICAL NOTE:** All styling properties in your `starterGUI(as-of-10.26).rbxmx` file are **BAKED IN** via XML properties. These are **NOT** controlled by Lua—they are direct GUI properties in Studio.

## Overview

Your StarterGUI contains **completely defined styling** unless explicitly overridden in a Lua file. Any changes to styling **must be done in one of two ways**:

1. **Studio GUI Editor** - Click elements and modify properties directly (one-off changes, tedious for bulk edits)
2. **Lua Script** - Code in `init.client.luau` or a dedicated styling module that programmatically sets properties at runtime

---

## GUI Hierarchy & Styling

### ✅ **InventoryGUI** (ScreenGui)
- **Status:** Fully styled in Studio
- **Display:** `Enabled = false` (hidden by default; shown via `E` key toggle)
- **Frame:** `InventoryFrame`
  - **Background:** Cream/beige RGB(255, 251, 231)
  - **Transparency:** 0 (opaque)
  - **Corner Radius:** 0.25 (soft rounded corners)
  - **Size:** 75% width, 50% height

#### **InventoryItems** (ScrollingFrame - Grid Layout)
- **Background:** White RGB(255, 255, 255) with Transparency 1 (transparent)
- **Grid:** 36px cells with 25px padding between slots
- **Layout:** 10 columns, auto rows

#### **ItemSlotTemplate** (Frame - 100x100px)
- **Background:** Tan/beige RGB(238, 226, 204)
- **Transparency:** 0 (opaque)
- **Corner Radius:** 1 (fully rounded to square circle)
- **Padding:** 15% all sides (internal item padding)

**Slot Children:**
- `ItemIcon` (ImageLabel) - Displays item sprite
  - Transparency: 1 (transparent background)
  - Size: Full slot (100x100)
- `ItemCount` (TextLabel) - Shows quantity
  - **Color:** Black text RGB(0, 0, 0)
  - **Transparency:** 0 (opaque)
  - **TextScaled:** true
  - **Position:** Bottom-right corner (20% of slot)
  - **Background:** White stroke with `TextStrokeTransparency: 0`
- `ItemName` (TextLabel) - Shows item name on hover
  - **Color:** Teal/cyan RGB(4, 175, 166) **← HOVER COLOR**
  - **Transparency:** 0 (opaque)
  - **BackgroundColor:** Teal RGB(130, 213, 187) **← HIGHLIGHT BG**
  - **Corner Radius:** 8px
  - **Padding:** 15% all sides
  - **Position:** Bottom-center (75% of slot)

---

### ✅ **StatsBar** (Frame - Bottom UI)
- **Background:** White RGB(255, 255, 255) with Transparency 100 (fully transparent)
- **Position:** Bottom 20% of inventory

#### **MilesCount & BellsCount** (Currency Display Frames)
- **Background:** Teal/cyan RGB(130, 213, 187)
- **Transparency:** 0 (opaque)
- **Size:** 101x40px (gold badges)
- **Rotation:** 3° (slight tilt)

**Each Badge Contains:**
- Label (BellsLabel/MilesLabel)
  - **Color:** Brown RGB(186, 168, 85) with Transparency 100
  - **Background:** Gold RGB(186, 168, 85)
  - **TextSize:** 36px (scaled)
  - **Corner Radius:** 1 (fully rounded)
- Icon (NookMilesImage/BellsBagImage)
  - 50x49px sprite image
  - **Stroke:** White 3px outline
  - **Corner Radius:** 1

---

### ✅ **NookPhoneGUI** (ScreenGui - Nook Phone App)
- **Status:** Fully styled in Studio
- **Display:** `Enabled = false` (hidden by default)
- **Background:** Light cream RGB(248, 244, 232)
- **Size:** 50% width, 75% height
- **Corner Radius:** 0.25

#### **TopBar** (Header)
- **Background:** Transparent White
- **Content:** Time label, WiFi icon, Location icon

#### **AppGrid** (3x3 App Icons)
- **Background:** White + 50% transparency
- **Size:** 221x70px
- **Each App Icon:** 73x75px with 8px corner radius

#### **BellsCountMinimal** (Bottom-Right Badge)
- **Background:** Gold RGB(190, 167, 69) + 25% transparency
- **Rotation:** 3°
- **Hidden by default:** `Visible = false`

---

### ✅ **ToolTipsGUI** (ScreenGui - Bottom-Right Help Text)
- **Status:** Styled with tooltips and buttons
- **Display:** `Enabled = false` (hidden by default)

**Help Buttons:**
- **Inventory (E)** → Light background
- **Reaction (R)** → Light background  
- **Crafting Menu (Tab)** → Light background
- **Tool Wheel (Spacebar)** → Light background
- **Close (X)** → Red background RGB(255, 38, 0)

---

### ✅ **CraftingGUI** (ScreenGui - Not in XML)
- Mentioned in the file but no properties visible
- Likely styled separately in another .rbxmx or studio build

---

## Key Colors Used

| Element | RGB | Hex | Usage |
|---------|-----|-----|-------|
| Item Name Highlight | 4, 175, 166 | #04AFA6 | Teal hover color (on ItemName label) |
| Item Slot Background | 238, 226, 204 | #EEDCCB | Tan slot backgrounds |
| Inventory Frame | 255, 251, 231 | #FFFBE7 | Cream main background |
| Currency Badge | 130, 213, 187 | #82D5BB | Teal badge background |
| Gold/Bells | 186, 168, 85 | #BAAA55 | Currency color |
| White Stroke | 255, 255, 255 | #FFFFFF | Text outlines |
| Error/Close Button | 255, 38, 0 | #FF2600 | Red close button |

---

## How to Modify Styling

### **Option 1: Modify in Studio (GUI Editor)**
1. Open place file in Roblox Studio
2. Navigate to `StarterGui` → `InventoryGUI` → `InventoryFrame`
3. Click element and change properties in Properties panel
4. ✅ Live updates in Studio
5. ❌ Must export/republish to see in source files

### **Option 2: Modify in Lua (init.client.luau)**

**Example - Change ItemName color on hover:**

```lua
-- In configureSlotInteractions() function
clickRegion.MouseEnter:Connect(function()
    local nameLabel = slot:FindFirstChild("ItemName")
    if nameLabel and nameLabel.Text ~= "" then
        nameLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 100)  -- Orange instead of teal
        nameLabel.Visible = true
    end
end)
```

**Example - Programmatic ItemSlotTemplate styling:**

```lua
function configureSlotTemplate(template)
    template.BackgroundColor3 = Color3.fromRGB(200, 180, 150)  -- New tan
    template.CornerRadius = UDim.new(0, 16)  -- More rounded
    
    local itemCount = template:FindFirstChild("ItemCount")
    if itemCount then
        itemCount.TextColor3 = Color3.fromRGB(50, 50, 50)  -- Darker text
    end
end
```

### **Option 3: Create Global Styling Module** (Recommended for bulk changes)

Create `src/client/InventoryStyling.lua`:

```lua
local Styling = {}

Styling.COLORS = {
    INVENTORY_BG = Color3.fromRGB(255, 251, 231),
    SLOT_BG = Color3.fromRGB(238, 226, 204),
    ITEM_NAME_HOVER = Color3.fromRGB(4, 175, 166),
    TEAL_BADGE = Color3.fromRGB(130, 213, 187),
    GOLD = Color3.fromRGB(186, 168, 85),
}

Styling.RADIUS = {
    INVENTORY_FRAME = UDim.new(0, 16),
    ITEM_SLOT = UDim.new(1, 0),  -- Fully rounded
    BADGE = UDim.new(1, 0),
}

function Styling.applyInventoryFrameStyle(frame)
    frame.BackgroundColor3 = Styling.COLORS.INVENTORY_BG
    frame.BackgroundTransparency = 0
    -- Add corner radius if needed
end

function Styling.applySlotStyle(slot)
    slot.BackgroundColor3 = Styling.COLORS.SLOT_BG
    slot.BackgroundTransparency = 0
end

return Styling
```

Then use in `init.client.luau`:

```lua
local Styling = require(script.Parent.InventoryStyling)

function configureSlotFrame(slot, slotIndex)
    Styling.applySlotStyle(slot)
    -- ... rest of code
end
```

---

## Current Styling Status in Your Code

### ✅ **What's Controlled by GUI (Studio XML)**
- All base frame colors and backgrounds
- Button/slot sizes and positioning
- Font family (SourceSansPro)
- Corner radius values
- Padding and margins

### ✅ **What's Controlled by Lua (init.client.luau)**
- Item name visibility toggle (on hover)
- Item count text update
- Ghost item styling (during drag)
- Dynamic color changes based on game state

### ⚠️ **Best Practice**
- **Studio:** Define base styling (colors, sizes, layout)
- **Lua:** Define behavior-based styling (hover, select, drag states)
- **Module:** Extract reusable color/dimension constants

---

## Notes for Future Changes

1. **Hover Effects:** Currently, item names show on hover with no background color change (per your preference). To add color change, update `configureSlotInteractions()` in `init.client.luau`.

2. **Empty Slot Labels:** ItemName labels are hidden when slots are empty to avoid visual clutter.

3. **Compatibility:** Any Lua style changes will override Studio XML properties at runtime, so define precedence carefully.

4. **Responsive Design:** Current styling uses pixel-based sizes (100x100 slots). For responsive UI, convert to `UDim2` scale-based values.

---

## Summary

Your `starterGUI(as-of-10.26).rbxmx` file contains **100% of your visual styling as XML properties**. To modify:
- **Quick change?** → Edit in Studio GUI editor
- **Bulk/programmatic change?** → Edit Lua or create styling module
- **Consistency?** → Use a global Styling module and reference in all files

**Any changes to source files (Lua) will override Studio XML at runtime.** Document your intent clearly in code comments to avoid confusion.
