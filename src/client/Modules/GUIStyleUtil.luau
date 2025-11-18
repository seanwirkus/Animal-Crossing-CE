--[[
        GUIStyleUtil.luau

        Helper utilities for applying GUIContentManager copy and ThemeProvider
        styling across all GUIs. This keeps individual GUI modules lightweight
        while guaranteeing consistent fonts, colors, and layout tokens.
]]

local GUIContentManager = require(script.Parent.GUIContentManager)
local ThemeProvider = require(script.Parent.ThemeProvider)

local GUIStyleUtil = {}

local function applyStyleToInstance(instance: Instance?, styleConfig: { [string]: any }?)
    if not instance or not styleConfig then
        return
    end

    local themed = GUIContentManager.applyThemeToStyle(styleConfig)

    if instance:IsA("GuiObject") then
        if themed.backgroundColor then
            instance.BackgroundColor3 = themed.backgroundColor
        end
        if themed.cornerRadius then
            ThemeProvider.applyCornerRadius(instance, themed.cornerRadius)
        end
        if themed.strokeColor then
            ThemeProvider.applyStroke(instance, themed.strokeColor, themed.strokeThickness or 1)
        end
    end

    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        if themed.textColor then
            instance.TextColor3 = themed.textColor
        end
        if themed.font then
            instance.Font = themed.font
        end
        if themed.textSize then
            instance.TextSize = themed.textSize
        end
    end
end

function GUIStyleUtil.applyButtonStyle(button: TextButton?, styleName: string?)
    if not button then
        return
    end

    local style = GUIContentManager.getButtonStyle(styleName or "primary")
    applyStyleToInstance(button, style)
end

function GUIStyleUtil.applyWindowStyle(frame: GuiObject?, styleName: string?)
    if not frame then
        return
    end

    local style = GUIContentManager.getWindowStyle(styleName or "main")
    applyStyleToInstance(frame, style)
end

function GUIStyleUtil.applyTextStyle(textObject: GuiObject?, styleName: string?)
    if not textObject then
        return
    end

    local style = GUIContentManager.getTextStyle(styleName or "body")
    applyStyleToInstance(textObject, style)
end

function GUIStyleUtil.setButtonContent(button: TextButton?, content)
    if not button or not content then
        return
    end

    if typeof(content) == "table" then
        button.Text = content.text or button.Text
        if content.style then
            GUIStyleUtil.applyButtonStyle(button, content.style)
        end
        if content.icon then
            button.Text = string.format("%s %s", content.icon, button.Text)
        end
    else
        button.Text = tostring(content)
    end
end

function GUIStyleUtil.setTextContent(textObject: GuiObject?, textValue)
    if not textObject or not textValue then
        return
    end

    if typeof(textValue) == "table" then
        textObject.Text = textValue.text or textObject.Text
        if textValue.style then
            GUIStyleUtil.applyTextStyle(textObject, textValue.style)
        end
    else
        textObject.Text = tostring(textValue)
    end
end

return GUIStyleUtil
