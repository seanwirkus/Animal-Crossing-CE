local AssetManager = require(script.Parent.AssetManager)

local FALLBACK_COLORS = {
        -- Core palette lifted from Animal Crossing: New Horizons
        DarkBrown = Color3.fromRGB(101, 67, 33),
        MediumBrown = Color3.fromRGB(139, 100, 66),
        LightBrown = Color3.fromRGB(205, 164, 116),
        Cream = Color3.fromRGB(255, 248, 237),
        TextDark = Color3.fromRGB(62, 39, 35),
        TextLight = Color3.fromRGB(255, 255, 255),
        BellGold = Color3.fromRGB(255, 215, 0),
        MileBlue = Color3.fromRGB(76, 175, 233),

        Spring = Color3.fromRGB(152, 195, 121),
        Summer = Color3.fromRGB(255, 193, 84),
        Autumn = Color3.fromRGB(207, 102, 60),
        Winter = Color3.fromRGB(130, 177, 222),

        -- Extended UI surface tokens
        PanelShadow = Color3.fromRGB(101, 67, 33),
        PanelBackground = Color3.fromRGB(255, 248, 237),
        PanelBorder = Color3.fromRGB(205, 164, 116),
        HintText = Color3.fromRGB(139, 100, 66),

        ActiveQuestBackground = Color3.fromRGB(40, 52, 72),
        ActiveQuestTitle = Color3.fromRGB(240, 246, 255),
        ActiveQuestEntry = Color3.fromRGB(55, 68, 92),
        ActiveQuestText = Color3.fromRGB(200, 220, 255),

        BoardOverlay = Color3.fromRGB(15, 18, 30),
        BoardContainer = Color3.fromRGB(35, 44, 68),
        BoardHeader = Color3.fromRGB(255, 255, 255),
        BoardClose = Color3.fromRGB(60, 70, 98),
        BoardCloseText = Color3.fromRGB(240, 240, 255),
        BoardCard = Color3.fromRGB(58, 70, 96),
        BoardCardTitle = Color3.fromRGB(255, 255, 255),
        BoardCardText = Color3.fromRGB(215, 225, 245),
        BoardCardReward = Color3.fromRGB(255, 228, 150),
        BoardButton = Color3.fromRGB(90, 108, 138),
        BoardButtonText = Color3.fromRGB(240, 246, 255),
        BoardButtonAccept = Color3.fromRGB(108, 168, 255),
        BoardButtonActive = Color3.fromRGB(120, 200, 160),

        DialogueBackground = Color3.fromRGB(30, 38, 54),
        DialogueNameText = Color3.fromRGB(255, 255, 255),
        DialogueMessageText = Color3.fromRGB(235, 240, 255),
        DialogueRewardText = Color3.fromRGB(255, 224, 140),
        DialogueButton = Color3.fromRGB(60, 70, 98),
        DialogueButtonText = Color3.fromRGB(240, 240, 255),

        -- Time of day text colors
        ClockTimeMorning = Color3.fromRGB(62, 39, 35),
        ClockTimeAfternoon = Color3.fromRGB(62, 39, 35),
        ClockTimeEvening = Color3.fromRGB(207, 102, 60),
        ClockTimeNight = Color3.fromRGB(130, 177, 222),

        SeasonAccentMorning = Color3.fromRGB(255, 193, 84),
        SeasonAccentAfternoon = Color3.fromRGB(207, 102, 60),
        SeasonAccentEvening = Color3.fromRGB(152, 195, 121),
        SeasonAccentNight = Color3.fromRGB(130, 177, 222),
}

local Theme = {}
Theme.__index = Theme

local function resolveColor(name, fallback)
        local color = AssetManager:GetColor(name, fallback or FALLBACK_COLORS[name])
        if color then
                return color
        end
        if fallback then
                return fallback
        end
        return FALLBACK_COLORS[name]
end

function Theme.color(name, fallback)
        local resolvedFallback = fallback or FALLBACK_COLORS[name]
        local manifestColor = AssetManager:GetColor(name, resolvedFallback)
        if manifestColor then
                return manifestColor
        end
        if resolvedFallback then
                return resolvedFallback
        end
        return Color3.fromRGB(255, 255, 255)
end

function Theme.seasonAccent(seasonName)
        if not seasonName then
                return Theme.color("Spring")
        end

        local sanitized = seasonName:gsub("%s+", "")
        local accentKey = sanitized .. "Accent"
        local fallback = FALLBACK_COLORS[accentKey] or FALLBACK_COLORS[seasonName] or FALLBACK_COLORS.Spring

        local accent = AssetManager:GetColor(accentKey)
        if accent then
                return accent
        end

        return resolveColor(seasonName, fallback)
end

function Theme.timeOfDayPalette(hour)
        if hour >= 5 and hour < 12 then
                return {
                        timeText = Theme.color("ClockTimeMorning"),
                        accentText = Theme.color("SeasonAccentMorning"),
                }
        elseif hour >= 12 and hour < 17 then
                return {
                        timeText = Theme.color("ClockTimeAfternoon"),
                        accentText = Theme.color("SeasonAccentAfternoon"),
                }
        elseif hour >= 17 and hour < 21 then
                return {
                        timeText = Theme.color("ClockTimeEvening"),
                        accentText = Theme.color("SeasonAccentEvening"),
                }
        else
                return {
                        timeText = Theme.color("ClockTimeNight"),
                        accentText = Theme.color("SeasonAccentNight"),
                }
        end
end

function Theme.shadowColor()
        return Theme.color("PanelShadow")
end

function Theme.backgroundColor()
        return Theme.color("PanelBackground")
end

function Theme.textColor()
        return Theme.color("TextDark")
end

function Theme.secondaryTextColor()
        return Theme.color("HintText")
end

return Theme
