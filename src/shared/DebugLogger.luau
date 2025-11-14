local DebugLogger = {}

local LOG_LEVELS = {
    INFO = "INFO",
    WARN = "WARN",
    ERROR = "ERROR",
    DEBUG = "DEBUG",
}

local function formatPrefix(moduleName, level)
    local timeStamp = os.date("%X")
    return string.format("[%s] [%s] [%s]", timeStamp, moduleName or "unknown", level)
end

local function tryStringify(value)
    if value == nil then
        return "nil"
    end

    if typeof(value) == "table" then
        local parts = {}
        for key, val in pairs(value) do
            table.insert(parts, string.format("%s=%s", tostring(key), tostring(val)))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    return tostring(value)
end

function DebugLogger.log(moduleName, level, message, context)
    local prefix = formatPrefix(moduleName, level)
    local body = message or "<no message>"
    if context ~= nil then
        body = body .. " | " .. tryStringify(context)
    end
    print(string.format("%s %s", prefix, body))
end

function DebugLogger.info(moduleName, message, context)
    DebugLogger.log(moduleName, LOG_LEVELS.INFO, message, context)
end

function DebugLogger.warn(moduleName, message, context)
    DebugLogger.log(moduleName, LOG_LEVELS.WARN, message, context)
end

function DebugLogger.error(moduleName, message, context)
    DebugLogger.log(moduleName, LOG_LEVELS.ERROR, message, context)
end

function DebugLogger.debug(moduleName, message, context)
    DebugLogger.log(moduleName, LOG_LEVELS.DEBUG, message, context)
end

function DebugLogger.activity(moduleName, activity, state)
    local status = state or "update"
    DebugLogger.info(moduleName, string.format("Activity %s", activity), status)
end

return DebugLogger
