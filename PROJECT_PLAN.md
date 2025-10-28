# Animal Crossing CE - Complete Project Plan

## Project Overview
Build a complete Animal Crossing item system that:
- Displays all 290 items from the sprite sheet
- Allows browsing with pagination
- Syncs inventory with server
- Eventually matches items to names from nookipedia JSON

## Current System State

### Technologies
- **Rojo 7.6.0**: Live sync enabled (no builds needed)
- **Luau**: Client/Server scripting
- **Sprite Sheet**: `rbxassetid://74324628581851` (21×24 grid, 504 slots, ~290 used)
- **Sprite Tile**: 36.6px with 6px inner spacing, 4px outer

### Data Sources
1. `nookipedia_items.json` - Item names and metadata
2. `nookipedia_characters.json` - Character data
3. `sample_items.csv` - Sample inventory
4. Sprite sheet asset - 290 items indexed by position

### Key Modules
- `ItemDataFetcher.lua` - Gets items sorted by sprite index
- `SpriteConfig.lua` - Sprite sheet calculations
- `InventoryClient.lua` - Inventory display (E key toggle)
- `DebugInventoryGrid.lua` - Item browser (CURRENTLY: nests in inventory with E, SHOULD: separate UI with G)

## Current Issues

### Issue 1: Debug GUI Keybind Wrong
- **Current**: Triggers on E (same as inventory toggle)
- **Expected**: Should trigger on G key only
- **Impact**: Inventory can't be toggled separately

### Issue 2: Debug GUI Styling
- **Current**: Nested inside inventory frame, fills entire space
- **Expected**: Should be separate, overlay-style UI or modal
- **Impact**: Can't browse items while viewing inventory

### Issue 3: Item Display
- **Current**: 70x70 items in 8-item-per-row grid
- **Expected**: Paginated browsing of all 290 items
- **Impact**: OK but could be better organized

### Issue 4: Item Browser Responsiveness (New)
- **Current**: Rapid G key presses repeatedly re-initialize the browser and feel laggy.
- **Expected**: Browser should cache its UI, reuse a single instance, and respond instantly.
- **Status**: ✅ Singleton + cached ScreenGui implemented; verify responsiveness in playtests.
- **Action**: Profile toggle performance and minimize repeated logging if any lag remains.

## Solution Plan

### Phase 1: Fix UI Architecture (IMMEDIATE)
1. **Create separate item browser UI (not nested in inventory)**
   - Create as ScreenGui in PlayerGui (separate from inventory)
   - Modal window: 800x600 centered
   - Title: "Item Browser"
   - Close button (X) and ESC key support

2. **Fix keybinding**
   - E key: Toggle inventory (existing)
   - G key: Toggle item browser (new, separate)
   - No interaction between them

3. **UI Layout for Item Browser**
   ```
   ┌─────────────────────────┐
   │ Item Browser        [X] │
   ├─────────────────────────┤
   │ Page 1 of 15 (290 items)│
   │                         │
   │ [Item Grid - 5x4 items] │
   │                         │
   │ [← Prev] [Next →]       │
   ├─────────────────────────┤
   │ ← → to browse | Click to add │
   └─────────────────────────┘
   ```

### Phase 2: Implement Pagination
1. **Calculate pages**
   - Items per page: 20 (5 columns × 4 rows)
   - Total pages: ceil(290 / 20) = 15 pages

2. **Grid layout**
   - Item size: 60x60 or 70x70
   - Items per row: 5
   - Padding: 2px
   - Auto-scroll within page

3. **Navigation**
   - Previous/Next buttons
   - Page indicator (e.g., "Page 1/15")
   - Left/Right arrow keys for next/prev

### Phase 3: Item Names & JSON Integration
1. **Load nookipedia_items.json**
   - Parse item names
   - Cross-reference sprite index to item name
   - Create lookup table: spriteIndex → itemName

2. **Display item info**
   - Show sprite
   - Show index number
   - Show item name (from JSON)
   - Show on hover or below sprite

3. **Click to add to inventory**
   - Click item → Fire remote to add itemId
   - Server validates and syncs back
   - Inventory updates

### Phase 4: Polish
1. Hover effects on items
2. Loading states
3. Error handling (missing items, etc)
4. Keyboard controls (1-9 quick add, Q to clear, etc)

## File Structure

```
src/client/
├── init.client.luau           # Bootstrap
├── KeybindManager.lua         # Keybind registry
├── InventoryClient.lua        # Inventory UI (E key)
├── DebugInventoryGrid.lua     # Item browser (G key) ← REFACTOR
├── InventoryStyling.lua       # Styling utils
└── Modules/

src/server/
├── init.server.luau           # Server logic
└── Modules/

ReplicatedStorage/
├── Shared/
│  ├── ItemDataFetcher.lua     # Item data access
│  ├── SpriteConfig.lua        # Sprite calculations
│  └── Modules/
└── InventoryEvent            # Remote events
```

## Implementation Steps

### Step 1: Refactor DebugInventoryGrid
- Detach from inventory frame
- Make it a proper ScreenGui modal
- Update keybinding to G only

### Step 2: Fix Keybinding
- Update KeybindManager to separate E and G
- E = inventory toggle
- G = item browser toggle

### Step 3: Implement Pagination
- Calculate page count
- Add page navigation
- Implement prev/next

### Step 4: Load Item Names
- Parse nookipedia_items.json
- Create name lookup
- Display with items

### Step 5: Polish UI
- Styling
- Hover effects
- Keyboard shortcuts

## Success Criteria
✅ G key opens item browser (separate from inventory)
✅ E key toggles inventory independently  
✅ Item browser shows all 290 items with pagination
✅ Each item shows sprite + index + name (from JSON)
✅ Click items to add to inventory
✅ Inventory syncs correctly
✅ Styled properly (modern, clean look)

## JSON Integration Details

### nookipedia_items.json Structure
```json
{
  "item_name": {
    "id": "item_name",
    "name": "Display Name",
    "spriteIndex": 1,
    ...
  }
}
```

### Matching Strategy
1. Load JSON items
2. Find spriteIndex for each item
3. Build map: spriteIndex → itemName
4. When displaying sprite, also show name

## Timeline
- **Phase 1 (Now)**: Fix UI architecture + keybinding (1-2 hours)
- **Phase 2**: Pagination (30 min)
- **Phase 3**: JSON integration (30 min)
- **Phase 4**: Polish (30 min)

**Total: 2.5-3 hours for complete solution**
