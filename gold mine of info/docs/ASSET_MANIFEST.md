# Asset Manifest Workflow

The project now supports **drop-in manifests** so you can mirror Animal Crossing: New Horizons and still reskin everything without touching the core scripts.

## Where manifests are loaded from
The `AssetManager` automatically checks the following locations (in order):

1. `ReplicatedStorage/Shared/AssetManifest` – the default manifest shipped with the repo.
2. `ReplicatedStorage/AssetManifest` – great for Studio-only overrides that you do not want committed.
3. `ReplicatedStorage/Assets/Manifest` – lives alongside the actual assets so artists can update values without script access.

Whichever modules exist are required and merged together. Later manifests override earlier ones on a per-key basis.

## Manifest structure
```lua
return {
        Settings = {
                RootFolder = "Assets", -- rename if your assets live somewhere else
                Folders = {
                        Models = "Models",
                        Sprites = "Textures",
                        Audio = "Audio",
                },
        },

        Models = {
                MapleHouse = 1234567890, -- Catalog/Creator Marketplace asset id
                QuestBoard = "rbxasset://quest_board", -- fall back to the shared folder
        },

        Sprites = {
                BellIcon = 9876543210, -- asset id or ImageLabel/Decal instance reference
                HudBackground = "rbxasset://texture/custom_panel",
        },

        Audio = {
                MorningTheme = 4561237890,
        },

        Colors = {
                PanelBackground = "#FFF4E1",
                SeasonAccentNight = { r = 115, g = 175, b = 230 },
        },
}
```

### Settings
- **RootFolder** – swaps out the `ReplicatedStorage/<RootFolder>` lookup used when resolving placeholder ids (`rbxasset://`).
- **Folders** – rename individual subfolders if you prefer `ReplicatedStorage/Assets/UI` instead of `Textures`, etc.

### Models, Sprites, Audio
- Accept Roblox asset ids (numbers or strings), preloaded Instances, or keep the `rbxasset://` placeholder to pull from the folder structure.
- Sprite lookups support `Decal`, `Texture`, `ImageLabel`, and `ImageButton` instances. Models are cloned before returning.

### Colors
- Accept `Color3` values, hex strings (e.g. `"#88CC44"`), or `{ r, g, b }` tables. Any color defined here is available via `Theme.color("Key")`.

## Editing workflow
1. **Create a copy** of `src/shared/AssetManifest.luau` and place it in one of the runtime locations above.
2. **Add/override** any entry you need—only the fields you provide are touched.
3. **Start the game**; the HUD/quests automatically pick up your overrides.
4. **Iterate safely**. Delete the runtime manifest to fall back to repository defaults.

For an even smoother pipeline, check in a team-wide manifest under `ReplicatedStorage/Assets/Manifest` and keep personal experiments inside `ReplicatedStorage/AssetManifest` which is ignored by Git.
