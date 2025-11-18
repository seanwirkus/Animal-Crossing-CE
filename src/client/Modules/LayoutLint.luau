--[[
    LayoutLint.luau
    ----------------
    Small helper that validates layout tables declared in GUIContentManager
    and reports missing keys so we can keep every GUI anchored/aligned in
    the same way. Also exposes a merge helper to layer defaults over the
    supplied layouts without mutating the original tables.
]]

local LayoutLint = {}

local function cloneTable(value)
    if typeof(table.clone) == "function" then
        return table.clone(value)
    end

    local cloned = {}
    for key, inner in pairs(value) do
        if typeof(inner) == "table" then
            cloned[key] = cloneTable(inner)
        else
            cloned[key] = inner
        end
    end
    return cloned
end

function LayoutLint.validate(layoutName: string, layout: { [string]: any }?, requiredKeys: { string }?)
    layout = layout or {}
    requiredKeys = requiredKeys or {}

    local missing = {}
    for _, key in ipairs(requiredKeys) do
        if layout[key] == nil then
            table.insert(missing, key)
        end
    end

    if #missing > 0 then
        warn(string.format("[LayoutLint] ⚠️ %s layout missing keys: %s", layoutName, table.concat(missing, ", ")))
    else
        print(string.format("[LayoutLint] ✅ %s layout validated", layoutName))
    end

    return layout
end

function LayoutLint.extendWithDefaults(layout: { [string]: any }?, defaults: { [string]: any }?)
    layout = layout or {}
    defaults = defaults or {}

    local merged = cloneTable(defaults)
    for key, value in pairs(layout) do
        if typeof(value) == "table" and typeof(defaults[key]) == "table" then
            merged[key] = LayoutLint.extendWithDefaults(value, defaults[key])
        else
            merged[key] = value
        end
    end

    return merged
end

return LayoutLint
