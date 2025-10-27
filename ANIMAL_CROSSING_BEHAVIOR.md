# Animal Crossing Drag & Drop Behavior - Implementation Guide

## How It Works Now

Your inventory now uses the classic Animal Crossing drag-and-drop system:

### Step 1: Click an Item
```
User clicks on an item in their inventory
↓
Item image "picks up" and follows the cursor
↓
Item stays attached to cursor until released
```

### Step 2: Move Around
```
Item follows cursor position exactly
↓
No delays, no animations
↓
User can drag to any location
```

### Step 3: Drop Item
```
User clicks anywhere (second click)
↓
Item instantly drops at cursor location
↓
If over inventory: swap/move items
↓
If outside inventory: item goes to ground
```

---

## The Code Logic

### Click Detection
```lua
clickButton.MouseButton1Down:Connect(function()
    if dragInfo then
        -- Currently dragging something
        -- Drop it at new location
        finishDrag(UserInputService:GetMouseLocation(), false)
    else
        -- Not dragging yet
        -- Start dragging this item
        beginDrag(slotIndex)
    end
end)
```

**Translation**:
- First click: Start drag
- Second click: End drag (drop)
- No multiple clicks needed

### During Drag
```lua
dragInfo.mouseConnection = RunService.RenderStepped:Connect(function()
    -- Every frame, update ghost position to match cursor
    dragInfo.ghost.Position = UDim2.fromOffset(
        mousePos.X - inventoryGui.AbsolutePosition.X,
        mousePos.Y - inventoryGui.AbsolutePosition.Y
    )
end)
```

**Translation**:
- Ghost item follows cursor in real-time
- No tweens, no delays
- Smooth but instant response

### On Drop
```lua
-- Figure out where item landed
local targetIndex = getSlotUnderPoint(mousePosition)

if targetIndex then
    if targetIndex == currentSlot then
        -- Dropped on same slot - do nothing
    else
        -- Dropped on different slot - swap/move
        swapItems(currentSlot, targetIndex)
    end
else
    -- Dropped outside inventory - drop to ground
    dropItemToGround(item, mousePosition)
end
```

**Translation**:
- Hit detection determines action
- Swap logic if on another slot
- Ground drop if outside inventory

---

## Comparing to Real Animal Crossing

### Animal Crossing (Switch/PC)
```
1. Click item
2. Item follows cursor
3. Click again to drop
4. No animations or effects
5. Simple, fast, responsive
```

### Your Inventory (Now)
```
1. Click item ✅
2. Item follows cursor ✅
3. Click again to drop ✅
4. No animations or effects ✅
5. Simple, fast, responsive ✅
```

**Result**: Your inventory behaves exactly like Animal Crossing!

---

## Game Flow Examples

### Example 1: Swapping Two Items

```
Initial State:
Slot 1: Shovel
Slot 2: Net

User clicks Shovel (Slot 1)
↓ Shovel picks up, follows cursor
User drags mouse to Slot 2
User clicks again
↓ Shovel drops on Slot 2

Final State:
Slot 1: Net
Slot 2: Shovel
```

**Code flow**: beginDrag → RenderStepped loop → click → finishDrag → detectSlot → swapItems

### Example 2: Dropping Item on Ground

```
Initial State:
Player inventory open
Shovel in Slot 1

User clicks Shovel
↓ Shovel picks up, follows cursor
User drags mouse OUTSIDE inventory
User clicks again
↓ Shovel drops to ground near player

Final State:
Slot 1: Empty
Ground: Shovel
```

**Code flow**: beginDrag → RenderStepped loop → click outside → finishDrag → detectOutside → dropItemToGround

### Example 3: Moving Item to Empty Slot

```
Initial State:
Slot 1: Shovel
Slot 2: Empty

User clicks Shovel
↓ Shovel picks up, follows cursor
User drags to Slot 2
User clicks
↓ Shovel drops in Slot 2

Final State:
Slot 1: Empty
Slot 2: Shovel
```

**Code flow**: beginDrag → RenderStepped loop → click → finishDrag → detectSlot → moveItem

---

## Performance Benefits

### Why This Is Better
1. **No Tweens**: Each frame just updates position - O(1) operation
2. **No Animations**: Zero overhead from animation calculations
3. **No Effects**: No glow/shadow/particle systems running
4. **Instant Response**: Cursor feedback is immediate
5. **Lower CPU**: Fewer calculations per frame

### Performance Metrics
- **Drag FPS**: No impact on frame rate
- **Ghost Item**: Simple Frame, no complex effects
- **Memory**: Minimal - just position tracking
- **Network**: Only send on drop, not during drag

---

## What Happens Behind the Scenes

### When You Click:
```
1. ClickButton detects MouseButton1Down
2. Check if already dragging (dragInfo)
3. If yes: finish drag (drop)
4. If no: start drag (beginDrag)
```

### During Drag:
```
1. RenderStepped fires every frame (~60 FPS)
2. Get current mouse position
3. Update ghost position = mouse position
4. Ghost is now at cursor
5. Repeat until user clicks again
```

### When You Click Again:
```
1. ClickButton detects second click
2. Stop RenderStepped connection
3. Get final mouse position
4. Determine drop location:
   - getSlotUnderPoint() → hit detection
   - Inside inventory? → swap/move
   - Outside inventory? → drop to ground
5. Update inventory state
6. Send to server
7. Refresh GUI
```

---

## Customization Points

Since there's no styling, you can add:

### Visual Feedback
- Glow effect on picked-up item
- Particle trail following cursor
- Drop preview (show where item will land)
- Sound effects on pick/drop

### Animations
- Pick-up animation (scale/bounce)
- Drop animation (bounce/rotate)
- Swap animation (slots rearrange)
- Ground drop animation (throw/fade)

### UI Enhancements
- Hover effects on items
- Item labels/tooltips
- Inventory backdrop customization
- Slot styling

### Quality of Life
- Undo last action
- Quick-move (drag to left/right to move)
- Favorite items (special slot)
- Item categories

---

## Technical Details

### No Mouse Button Release Detection
**Why**: Traditional drag-and-drop uses MouseButton1Up. Animal Crossing uses click-again.

**How**: Click detector checks if already dragging:
- If no active drag: start drag
- If active drag: end drag

**Benefit**: User has more control, can move cursor around before dropping

### Ghost Item Tracking
```lua
dragInfo = {
    slotIndex = slotIndex,              -- Where item came from
    state = copySlotData(state),        -- Item data
    ghost = ghost,                      -- Visual representation
    mouseConnection = connection,       -- Frame update
}
```

**Ghost is just a container with**:
- ItemIcon (image)
- ItemCount (number)
- Nothing else

### Drop Detection
```lua
getSlotUnderPoint(mousePosition)
```

Simple hit detection:
1. Loop through all slots
2. Check if mouse is inside slot bounds
3. Return slot index if found
4. Return nil if not in any slot

---

## Error Handling

### What If User Drags Item That Doesn't Exist?
```
beginDrag checks: if not state then return
```
✅ Won't create ghost, drag stops

### What If Item Falls Into Void?
```
finishDrag has 3-level fallback:
1. Raycast from camera through mouse
2. Raycast straight down from camera
3. Default position in front of player
```
✅ Item always goes somewhere

### What If Inventory Closes During Drag?
```
setInventoryVisible checks:
if not visible and dragInfo then
    finishDrag(UserInputService:GetMouseLocation(), true)
end
```
✅ Drag is cancelled, item returns to slot

---

## Server Communication

### What Gets Sent to Server
```lua
inventoryRemote:FireServer("MoveItem", {
    fromIndex = originalSlot,
    toIndex = targetSlot,
    swap = true,  -- Or false
})

inventoryRemote:FireServer("DropItem", {
    itemId = item.id,
    count = item.count,
    slotIndex = slotIndex,
    worldPosition = position3D,  -- Where it lands in world
})
```

### When Does Server Update Happen
- ✅ After drop (not during drag)
- ✅ Only if action is valid
- ✅ Server validates move

**Result**: No "lag" during drag, instant feedback to player

---

## Next Steps

1. **Test in Game**
   - Open inventory
   - Click and drag items
   - Verify Animal Crossing feel

2. **Customize Visuals** (See CUSTOM_STYLING_GUIDE.md)
   - Remove yellow outline if you want
   - Add glow effects
   - Style slots how you like

3. **Add Effects** (Optional)
   - Pick-up sound
   - Drop sound
   - Visual feedback

4. **Iterate**
   - Play your game
   - Adjust as needed
   - Get feedback

---

## Summary

✅ **Simple**: One file, clean logic
✅ **Responsive**: Instant cursor feedback
✅ **Familiar**: Works like Animal Crossing
✅ **Efficient**: No animations overhead
✅ **Customizable**: You can add any effects you want

The inventory is now a blank canvas ready for your artistic vision!

