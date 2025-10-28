--[[
        Default asset manifest. Copy this module and place it in
        ReplicatedStorage/AssetManifest or ReplicatedStorage/Assets/Manifest
        to override entries without modifying the core repo.
]]

local manifest = {
        Settings = {
                -- RootFolder = "Assets", -- Change if you keep assets somewhere else
                -- Folders = {
                --         Models = "Models",
                --         Sprites = "Textures",
                --         Audio = "Audio",
                -- },
        },

        Colors = {
                -- Example:
                -- PanelBackground = "#FFF5E0",
                -- SeasonAccentNight = { r = 110, g = 160, b = 240 },
        },

        Models = {
                -- MapleHouse = 1234567890,
        },

        Sprites = {
                -- Animal Crossing UI sprites (placeholders - replace with your asset IDs)
                ["AC/WoodBar"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/PaperPanel"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/PillPanel"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/TicketButton"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/SpeechBubble"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/SoftShadow"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/Noise"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/Pin"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/LeafIcon"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["AC/BellBag"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
                ["MileIcon"] = "rbxasset://textures/Gui/Icons/RobloxPlayerGuiIcon.png",
        },

        Audio = {
                -- MorningTheme = 1234567890,
        },
}

return manifest
