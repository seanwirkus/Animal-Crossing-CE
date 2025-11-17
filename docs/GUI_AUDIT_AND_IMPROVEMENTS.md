# GUI Audit & Improvement Plan

## Overview
Comprehensive audit of all GUIs to improve usability, resolve Roblox UI overlap issues, and enhance visual presentation with sprite icons and better layouts.

## Key Issues to Address
1. **Left-side overlap** - Roblox UI (player list, chat) overlaps GUIs on left edge
2. **Menu placement** - Move tabs/selections to top to avoid conflicts
3. **Missing sprite icons** - Replace emoji/text with proper sprite icons
4. **Layout density** - Improve spacing and information hierarchy
5. **Responsiveness** - Better mobile/screen adaptation

## Improvements by GUI

### 1. HomeBuildingGUI
**Current Issues:**
- Centered frame can clash with Roblox chat
- No sprite icons for upgrades
- Upgrade info could be more detailed (costs, current progress)
- Limited home customization details

**Improvements:**
- ✅ Move to right side of screen (use Position UDim2.new(0.7, 0, 0.5, 0))
- ✅ Add sprite icons for home types (tent, small house, mansion)
- ✅ Show home stats: rooms, storage capacity, decoration slots
- ✅ Add upgrade preview (show what you'll get)
- ✅ Better home customization hints
- ✅ Top-aligned info banner with current status

### 2. BuildingGUI (Object Placement)
**Current Issues:**
- Large scrolling list could be overwhelming
- No visual preview of items
- Categories hard to navigate
- Menu on left side

**Improvements:**
- ✅ Move tabs to top
- ✅ Add category tabs at top (Furniture, Outdoor, Decorations, etc.)
- ✅ Use sprite icons for each item preview
- ✅ Better search/filter UI
- ✅ Item grid layout with sprites

### 3. ShopGUI / NookShoppingGUI
**Current Issues:**
- Limited item preview
- No sprite icons for merchandise
- Price display could be clearer
- Inventory slots not visible

**Improvements:**
- ✅ Top-aligned category tabs
- ✅ Sprite icons for all shop items
- ✅ Better price display with comparison
- ✅ Show player inventory slots remaining
- ✅ Grid layout with improved spacing

### 4. CraftingGUI / DIYWorkbenchGUI
**Current Issues:**
- Recipe interface hard to navigate
- Material requirements not visually clear
- No sprite icons for recipes
- Menu placement could improve

**Improvements:**
- ✅ Top menu bar with category tabs
- ✅ Sprite icons for recipes and materials
- ✅ Visual material requirement check (✅/❌)
- ✅ Recipe preview pane
- ✅ Crafting queue display

### 5. RecipesInventoryGUI
**Current Issues:**
- Large recipe list could be confusing
- No visual filtering
- Missing recipe icons

**Improvements:**
- ✅ Top search/filter bar
- ✅ Category tabs
- ✅ Sprite icons for recipes
- ✅ Sort options (A-Z, by category, by rarity)
- ✅ Quick preview on hover

### 6. QuestGUI
**Current Issues:**
- Quest objectives could be clearer
- Reward display could use icons
- Progress tracking visual

**Improvements:**
- ✅ Top quest category tabs (Active, Completed, Available)
- ✅ Sprite icons for rewards
- ✅ Better progress visualization
- ✅ Quest objective breakdown

### 7. ToolRingGUI
**Current Issues:**
- Tool selection could use better visual hierarchy

**Improvements:**
- ✅ Sprite icons for tools
- ✅ Top status bar showing equipped tool
- ✅ Tool durability display
- ✅ Quick access buttons

## Implementation Strategy

### Phase 1: High Priority (Most Used)
1. HomeBuildingGUI - Left-side overlap main issue
2. BuildingGUI - Placement interface needs sprite icons
3. ShopGUI/NookShoppingGUI - Important for monetization feedback

### Phase 2: Medium Priority
4. CraftingGUI/DIYWorkbenchGUI - Recipe clarity
5. RecipesInventoryGUI - Navigation improvement

### Phase 3: Low Priority
6. QuestGUI - Visual polish
7. ToolRingGUI - Quality of life

## Common Design Patterns

### Top Navigation Bar
```lua
-- Position at top of screen
- Height: 50px
- Contains: logo/title + category tabs/buttons
- Background: ACCENT_BROWN or darker theme color
- Tabs scroll if needed (horizontal scroll)
```

### Main Content Area
```lua
-- Positioned below nav bar
- Full width, height adjusted
- Left margin: 20px (avoid left edge)
- Right margin: 20px
- Scrollable content inside
```

### Sprite Integration
```lua
-- Use SpriteConfig for all item icons
- 16x16 or 24x24 pixel icon size
- Load sprite at item grid position
- Cache sprites to avoid repeated loads
```

### Right-Side Positioning
```lua
-- GUIs should be positioned on right
- Position: UDim2.new(0.65-0.75, 0, 0.3-0.5, 0)
- Avoids Roblox UI on left (0-0.3 range)
- Leaves room for inventory/other UI
```

## Testing Checklist
- [ ] No overlap with Roblox player list
- [ ] No overlap with Roblox chat
- [ ] Sprite icons load correctly
- [ ] Mobile responsive (landscape mode)
- [ ] Tabs/navigation accessible
- [ ] Scrolling smooth on large lists
- [ ] Information clear and organized
- [ ] Color scheme matches ACNH theme

## Files to Modify
- HomeBuildingGUI.luau
- BuildingGUI.luau
- ShopGUI.luau
- NookShoppingGUI.luau
- CraftingGUI.luau
- DIYWorkbenchGUI.luau
- RecipesInventoryGUI.luau
- QuestGUI.luau
- ToolRingGUI.luau
