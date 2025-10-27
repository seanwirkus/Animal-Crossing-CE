# How to Customize Inventory Styling - Quick Reference

Since all styling has been removed, here's how to add your own effects in Roblox Studio.

---

## 1. Simple Styling in Studio (No Code Needed)

### Remove That Yellow Outline
In Roblox Studio:
1. Select your `ItemSlotTemplate` Frame
2. In Properties, look for child objects
3. Find any `UIStroke` objects → Delete them
4. Add your own UIStroke if you want a different outline

### Change Slot Colors
1. Select `ItemSlotTemplate`
2. In Properties:
   - `BackgroundColor3`: Your slot color
   - `BackgroundTransparency`: 0-1 (0 = fully opaque, 1 = invisible)
   - `BorderColor3`: Border color
   - `BorderSizePixel`: Border thickness

### Add Item Count Styling
1. Select `ItemSlotTemplate` → `ItemCount` (TextLabel)
2. In Properties:
   - `TextColor3`: Number color
   - `BackgroundColor3`: Badge background
   - `Font`: Preferred font
   - `TextSize`: Size of number

---

## 2. Adding Hover Effects (Easy Method)

Create a new LocalScript in StarterPlayer > StarterCharacterScripts:

```lua
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local inventoryGui = gui:WaitForChild("InventoryGUI")
local inventoryFrame = inventoryGui:WaitForChild("InventoryFrame")
local inventoryItems = inventoryFrame:WaitForChild("InventoryItems")

-- Apply hover effects to all slots
for _, slot in ipairs(inventoryItems:GetChildren()) do
    if slot.Name:match("^Slot_") then
        local clickButton = slot:FindFirstChild("ClickButton")
        if clickButton then
            clickButton.MouseEnter:Connect(function()
                -- Hover effect
                slot.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
                slot.BackgroundTransparency = 0.2
            end)
            
            clickButton.MouseLeave:Connect(function()
                -- Return to normal
                slot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                slot.BackgroundTransparency = 0.3
            end)
        end
    end
end
```

---

## 3. Adding Custom Glow Effect

### Using UIStroke (Outline Method)
In Roblox Studio:
1. Select `ItemSlotTemplate`
2. Right-click → Insert Object → UIStroke
3. Properties:
   - `Color`: Your glow color (try Color3.fromRGB(255, 200, 100) for gold)
   - `Thickness`: 2-4 pixels
   - `Transparency`: 0-0.5
   - `Enabled`: true

### Using UICorner (Rounded Corners)
1. Select `ItemSlotTemplate`
2. Right-click → Insert Object → UICorner
3. Set `CornerRadius` to `UDim.new(0, 4)` for subtle rounding

---

## 4. Adding Drag Animation (Advanced)

Create a script in ReplicatedStorage called `DragAnimationModule.lua`:

```lua
local TweenService = game:GetService("TweenService")

local function createGlowEffect(item)
    -- Add glow when dragging
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromRGB(255, 200, 100)
    glow.Thickness = 3
    glow.Parent = item
    
    return glow
end

local function animateDragAppear(ghost)
    TweenService:Create(ghost, TweenInfo.new(0.1), {
        Size = UDim2.new(0, 70, 0, 70),
    }):Play()
end

local function animateDragDisappear(ghost)
    TweenService:Create(ghost, TweenInfo.new(0.15), {
        Size = UDim2.new(0, 10, 0, 10),
    }):Play()
end

return {
    createGlowEffect = createGlowEffect,
    animateDragAppear = animateDragAppear,
    animateDragDisappear = animateDragDisappear,
}
```

Then use it in your inventory script by:
1. Loading the module
2. Calling its functions when dragging starts/ends

---

## 5. Adding Item Name Tooltips

Create a LocalScript in your InventoryFrame:

```lua
local function createTooltip(slot)
    local itemIcon = slot:FindFirstChild("ItemIcon")
    if not itemIcon then return end
    
    local clickButton = slot:FindFirstChild("ClickButton")
    if clickButton then
        clickButton.MouseEnter:Connect(function()
            -- Show item name
            local itemName = slot:FindFirstChild("ItemName")
            if itemName then
                itemName.Visible = true
            end
        end)
        
        clickButton.MouseLeave:Connect(function()
            -- Hide item name
            local itemName = slot:FindFirstChild("ItemName")
            if itemName then
                itemName.Visible = false
            end
        end)
    end
end

-- Apply to all slots
local inventoryItems = script.Parent:FindFirstChild("InventoryItems")
if inventoryItems then
    for _, slot in ipairs(inventoryItems:GetChildren()) do
        if slot.Name:match("^Slot_") then
            createTooltip(slot)
        end
    end
end
```

---

## 6. Adding Item Count Badge Styling

In Studio, select `ItemSlotTemplate` → `ItemCount`:

```
Properties to customize:
- TextColor3: Color3.fromRGB(255, 255, 255) [white]
- BackgroundColor3: Color3.fromRGB(0, 0, 0) [black background]
- BackgroundTransparency: 0.2 [slightly transparent]
- Font: GothamBold [nicer font]
- TextSize: 20 [larger number]
- TextScaled: true [auto-scales]
- Position: UDim2.new(1, -22, 1, -22) [bottom-right corner]
- Size: UDim2.new(0, 24, 0, 24) [square badge]
```

---

## 7. Adding Drop Preview

Show a preview of where items will land:

```lua
-- In a LocalScript
local UserInputService = game:GetService("UserInputService")
local dragInfo = nil  -- Shared with main inventory script

local function createDropPreview()
    local preview = Instance.new("Frame")
    preview.Name = "DropPreview"
    preview.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    preview.BackgroundTransparency = 0.5
    preview.BorderSizePixel = 0
    preview.Size = UDim2.new(0, 64, 0, 64)
    preview.Visible = false
    return preview
end

-- Update this as user drags
RunService.RenderStepped:Connect(function()
    if dragInfo then
        local mousePos = UserInputService:GetMouseLocation()
        -- Update preview position based on mousePos
    end
end)
```

---

## 8. Adding Sound Effects

Create a LocalScript in your inventory GUI:

```lua
local SoundService = game:GetService("SoundService")

local function playPickupSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://YOUR_SOUND_ID"
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playDropSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://YOUR_OTHER_SOUND_ID"
    sound.Volume = 0.5
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

-- Call these when drag starts/ends
```

---

## 9. Quick Color Reference

### Good Slot Colors
- Neutral Gray: `Color3.fromRGB(200, 200, 200)`
- Wood Brown: `Color3.fromRGB(139, 90, 43)`
- Light Tan: `Color3.fromRGB(210, 180, 140)`
- Dark Gray: `Color3.fromRGB(80, 80, 80)`
- Animal Crossing Tan: `Color3.fromRGB(216, 200, 180)`

### Good Hover Colors
- Highlight Yellow: `Color3.fromRGB(255, 200, 100)`
- Bright Green: `Color3.fromRGB(0, 255, 0)`
- Soft Blue: `Color3.fromRGB(100, 150, 255)`
- Orange: `Color3.fromRGB(255, 165, 0)`

### Good Glow Colors
- Golden: `Color3.fromRGB(255, 200, 100)`
- Blue: `Color3.fromRGB(100, 200, 255)`
- Purple: `Color3.fromRGB(200, 100, 255)`
- Green: `Color3.fromRGB(100, 255, 150)`

---

## 10. Testing Your Customizations

After adding styling:

1. ✅ Open inventory (E key)
2. ✅ Check colors and styling in Studio
3. ✅ Hover over items - see your hover effect
4. ✅ Drag items - check ghost appearance
5. ✅ Drop items - verify drop styling
6. ✅ Check inventory is playable and works

---

## Common Issues & Solutions

### Problem: "My changes don't show"
**Solution**: Make sure you're in Play mode and changes to Roblox Studio GUI apply immediately.

### Problem: "I want tweens back but simpler"
**Solution**: Use TweenService in a separate script - don't modify the main inventory script.

### Problem: "How do I know what UI elements exist?"
**Solution**: Use Explorer in Studio (View → Explorer) to see ItemSlotTemplate structure.

### Problem: "My hover effect doesn't work"
**Solution**: Check that you're connecting to the `ClickButton` not the slot itself.

---

## Where to Add Code

| Type | Location |
|------|----------|
| Studio styling | Roblox Studio properties |
| Hover effects | LocalScript in ReplicatedStorage |
| Animations | LocalScript connected to inventory events |
| Sounds | LocalScript in ServerScriptService |
| Themes | ModuleScript with color tables |

---

## Pro Tips

1. **Test in Studio**: Always test changes in Play mode
2. **Save Versions**: Keep backups before major style changes
3. **Use Variables**: Define colors at the top of scripts for easy tweaking
4. **Animate Smoothly**: Use easing styles for natural motion
5. **Keep it Simple**: Don't over-animate - users need responsive feedback

---

Now go make your inventory look amazing! 🎨

