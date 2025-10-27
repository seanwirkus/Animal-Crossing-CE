# GUI Implementation Guide - Animal Crossing CE

This document outlines all GUI elements that need to be created in Roblox Studio. The client script (`init.client.luau`) contains **LOGIC ONLY** and will automatically integrate with any GUI you build following this structure.

---

## 1. INVENTORY SYSTEM (REQUIRED ✓)

### Directory Structure
```
PlayerGui
└── InventoryGUI (ScreenGui)
    └── InventoryFrame (Frame)
        ├── InventoryItems (ScrollingFrame or Frame)
        │   └── ItemSlotTemplate (Frame) [TEMPLATE - Will be cloned for each slot]
        │       ├── ItemIcon (ImageLabel)
        │       ├── ItemCount (TextLabel)
        │       └── ItemName (TextLabel)
        └── InventoryDragDetection (TextButton) [AUTO-CREATED - Drag detection layer]
```

### Details

**InventoryGUI**
- Type: ScreenGui
- Size: Fill entire screen (UDim2.fromScale(1, 1))
- BackgroundTransparency: 0.3 - 0.05 (animates when visible)
- ZIndex: 50 (so status bar can be on top)

**InventoryFrame**
- Type: Frame
- Size: Your desired size (e.g., UDim2.new(0, 400, 0, 500))
- BackgroundTransparency: Animates between 0.3 and 0.05
- Position: Centered on screen recommended

**InventoryItems**
- Type: ScrollingFrame (for scrollable inventory) or Frame (fixed)
- Parent: InventoryFrame
- Contains all item slots
- The script will add scroll detection if using ScrollingFrame

**ItemSlotTemplate**
- Type: Frame
- Size: UDim2.new(0, 64, 0, 64)
- Name: `ItemSlotTemplate` (EXACT NAME REQUIRED)
- This is cloned for each inventory slot
- Visible: Set to false initially (script will manage visibility)
- BackgroundColor3: Your choice (gray/brown recommended)
- BackgroundTransparency: 0.2 - 0.7 (animates)

**ItemIcon**
- Type: ImageLabel
- Size: UDim2.new(1, -4, 1, -4) (with padding)
- ImageScaled: true
- Image: Will be set by script to SpriteSheet

**ItemCount**
- Type: TextLabel
- Size: UDim2.new(0, 20, 0, 20)
- Position: UDim2.new(1, -22, 1, -22) (bottom-right corner)
- BackgroundColor3: Black or dark gray
- TextColor3: White
- TextScaled: true
- Visible: false initially
- Text: Will show "5", "10", etc.

**ItemName**
- Type: TextLabel
- Size: Full slot (UDim2.new(1, 0, 1, 0))
- BackgroundTransparency: Animates between 0.4 and 0.2
- TextColor3: White
- TextScaled: true
- Text Alignment: Center / Middle
- TextWrapped: true
- TextTransparency: 1 (shows on hover)

---

## 2. STATUS/HEALTH BAR (OPTIONAL - LOGIC READY)

### Directory Structure
```
PlayerGui
└── InventoryGUI
    └── StatusBar (Frame)
        ├── Fill (Frame) [The bar that animates]
        └── HealthText (TextLabel) [Shows "50 / 100"]
```

### Details

**StatusBar**
- Type: Frame
- Size: UDim2.new(0, 200, 0, 30)
- Position: Your choice (top-left recommended)
- BackgroundColor3: Dark gray (base)
- BackgroundTransparency: 0.3
- Attributes (for script reference):
  - `MaxHealth` (Number): 100
  - `CurrentHealth` (Number): 100

**Fill**
- Type: Frame
- Size: UDim2.new(1, 0, 1, 0) [Will animate to healthPercent]
- Position: UDim2.new(0, 0, 0, 0)
- BackgroundColor3: Green (Color3.fromRGB(0, 200, 0))
- BackgroundTransparency: 0.1
- BorderSizePixel: 0
- ZIndex: 50

**HealthText**
- Type: TextLabel
- Size: UDim2.new(1, 0, 1, 0)
- BackgroundTransparency: 1
- TextColor3: White
- TextScaled: true
- Text: "50 / 100"
- ZIndex: 51 (above Fill)

### How It Works
The script's `updateHealthBar(currentHealth, maxHealth)` function will:
1. Calculate healthPercent = currentHealth / maxHealth
2. Animate Fill.Size to match percentage
3. Update HealthText with current/max values

---

## 3. STATUS EFFECTS (OPTIONAL - LOGIC READY)

### Directory Structure
```
PlayerGui
└── InventoryGUI
    └── StatusEffectsContainer (Frame)
        ├── UIGridLayout (UIGridLayout)
        └── [Effect icons will be added here dynamically]
```

### Details

**StatusEffectsContainer**
- Type: Frame
- Size: UDim2.new(0, 200, 0, 50)
- Position: Your choice (top-right recommended)
- BackgroundTransparency: 1
- BorderSizePixel: 0

**UIGridLayout**
- Type: UIGridLayout
- CellSize: UDim2.new(0, 32, 0, 32)
- CellPadding: UDim2.new(0, 4, 0, 4)
- SortOrder: LayoutOrder
- FillDirection: Horizontal

### How It Works
The script's `updateStatusEffects(effectsList)` function will:
1. Clear old effect displays
2. Create new Frame for each effect
3. Add effect icon (from sprite sheet or custom)
4. Show duration timer

---

## 4. DRAG & DROP VISUAL FEEDBACK

### What Happens Automatically
The script creates these elements automatically during drag:

**DragGhost**
- Transparent clone of the item being dragged
- Has golden glow effect (Color3.fromRGB(255, 200, 100))
- Has shadow frame beneath it for depth
- Size: 90x90 (larger than slot for visibility)
- BackgroundTransparency: 1 (no white background)

**InventoryDragDetection**
- Auto-created on InventoryFrame
- Allows drag-start from anywhere in inventory
- Not visible (BackgroundTransparency: 1)

### What You Need to Provide
- **ItemSlotTemplate** children with correct names
- **InventoryItems** container to hold slots
- That's it! Everything else is automatic.

---

## 5. SETUP CHECKLIST

Before pressing E to open inventory:

- [ ] Created InventoryGUI in PlayerGui
- [ ] Created InventoryFrame inside InventoryGUI
- [ ] Created InventoryItems inside InventoryFrame
- [ ] Created ItemSlotTemplate inside InventoryItems with these children:
  - [ ] ItemIcon (ImageLabel)
  - [ ] ItemCount (TextLabel)
  - [ ] ItemName (TextLabel)
- [ ] ItemSlotTemplate is set to Visible: false
- [ ] (Optional) Created StatusBar for health display
- [ ] (Optional) Created StatusEffectsContainer for buffs/debuffs

---

## 6. NOTES FOR DEVELOPERS

### Drag & Drop Behavior
✓ **Drag anywhere in InventoryItems** - No need to click specific slots
✓ **White background removed** - Ghost item is transparent with glow only
✓ **Smooth animations** - Items animate into place when dropped
✓ **Never lost** - Multiple fallback positioning systems
✓ **Auto slot detection** - Dragging to different slot automatically swaps

### What the Script Does NOT Do
- ✗ Does NOT create any GUI (you must create in Studio)
- ✗ Does NOT handle server communication (server script does this)
- ✗ Does NOT manage player stats (except health bar display)

### What the Script DOES Do
- ✓ Finds your GUI structure
- ✓ Populates inventory from server data
- ✓ Handles all drag & drop logic
- ✓ Animates all transitions
- ✓ Updates status bars/effects when called
- ✓ Communicates item changes to server

---

## 7. EXAMPLE GUI SIZES

If you're starting fresh, here are good starting sizes:

**InventoryFrame**: 400 x 500 pixels, centered
**ItemSlotTemplate**: 64 x 64 pixels, in a 5x4 grid
**StatusBar**: 200 x 30 pixels, top-left corner
**StatusEffectsContainer**: 200 x 50 pixels, top-right corner

---

## 8. TESTING

In Studio with this setup:

1. Place LocalScript with init.client.luau in PlayerScripts
2. Press E to toggle inventory
3. Items should appear from server data
4. Drag items around (click and drag from anywhere in inventory)
5. Items should swap or drop to ground
6. Ghost item should have golden glow, NO white background

If you see errors:
- Check Debug output (View > Output)
- Look for "[Debug]" messages to see what's missing
- Verify GUI names match exactly (case-sensitive)

---

## 9. FUTURE ADDITIONS (LOGIC READY)

The following features have logic implemented but need GUI:

- Health/mana bar system: `updateHealthBar(currentHealth, maxHealth)`
- Status effects display: `updateStatusEffects(effectsList)`
- Equipment slots: Structure prepared, awaiting EquipmentFrame creation
- Quick use slots: Structure prepared, awaiting creation

Once you create the GUI, uncomment the related code in the script and it will work automatically.

