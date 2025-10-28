-- KEYBIND_INTEGRATION.md
-- Integration guide for KeybindManager with InventoryClient

## Quick Start

Add this to `init.client.luau` after `InventoryClient` is initialized:

```lua
-- At top with other requires
local KeybindManager = require(script.Parent.KeybindManager)
local UserInputService = game:GetService("UserInputService")

-- After InventoryClient is created and started:
local keybindManager = KeybindManager.new()

-- Register inventory keybind
keybindManager:registerBind("INVENTORY", function(inputState)
    if inputState == "began" then
        inventoryClient:setInventoryVisible(not inventoryClient.visible)
        if inventoryClient.visible then
            inventoryClient:requestInventory()
        end
    end
end)

-- Register other keybinds as needed
keybindManager:registerBind("REACTION", function(inputState)
    if inputState == "began" then
        print("[Keybind] Reaction triggered (R key)")
        -- TODO: Add reaction handler
    end
end)

keybindManager:registerBind("CRAFTING", function(inputState)
    if inputState == "began" then
        print("[Keybind] Crafting menu triggered (Tab key)")
        -- TODO: Add crafting handler
    end
end)

keybindManager:registerBind("TOOL_WHEEL", function(inputState)
    if inputState == "began" then
        print("[Keybind] Tool wheel triggered (Space key)")
        -- TODO: Add tool wheel handler
    end
end)

-- Connect all keybinds to input events
keybindManager:connect(UserInputService)

-- Print debug reference
keybindManager:printKeybindReference()

-- Optional: Store manager globally for debugging
_G.KeybindManager = keybindManager
```

## Keybind Reference

**Current Mappings:**

| Bind Name | Key | Action |
|-----------|-----|--------|
| INVENTORY | E | Toggle inventory open/closed |
| DROP_ITEM | Q | Drop item to ground |
| REACTION | R | Play reaction/animation |
| CRAFTING | Tab | Open crafting menu |
| TOOL_WHEEL | Space | Open tool wheel |
| MAP | M | Open map |
| EMOTE | V | Play emote |
| SETTINGS | Escape | Open settings |

## Adding New Keybinds

1. **Add to KeybindManager.KEYBINDS:**
   ```lua
   DANCE = Enum.KeyCode.Z,
   ```

2. **Register handler in init.client.luau:**
   ```lua
   keybindManager:registerBind("DANCE", function(inputState)
       if inputState == "began" then
           print("Dance triggered!")
       end
   end)
   ```

3. **Done!** The keybind is now active.

## Debugging

```lua
-- Print all active keybinds
keybindManager:printKeybindReference()

-- Check which keybinds are active
print(keybindManager:getActiveBinds())

-- Manually unregister a keybind
keybindManager:unregisterBind("INVENTORY")

-- Disable all keybinds
keybindManager:disconnect()
```

## Notes

- Handlers receive an `inputState` parameter: `"began"` (key pressed) or `"ended"` (key released)
- Handlers that don't need "ended" events can ignore that parameter
- All errors in handlers are caught and logged (won't crash the game)
- Keybinds don't fire if `gameProcessed` is true (e.g., typing in chat)
