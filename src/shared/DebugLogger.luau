local RunService = game:GetService("RunService")

local DebugLogger = {}

local LOG_LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
}

-- Default: Keep logs quiet unless explicitly enabled.
local currentLogLevel = LOG_LEVELS.WARN

-- Set to true to completely disable all logging
local loggingDisabled = false

function DebugLogger.setLogLevel(level)
    if LOG_LEVELS[level] then
        currentLogLevel = LOG_LEVELS[level]
    end
end

function DebugLogger.disableLogging()
    loggingDisabled = true
end

function DebugLogger.enableLogging()
    loggingDisabled = false
end

local function shouldLog(level)
    if loggingDisabled then
        return false
    end
    return LOG_LEVELS[level] <= currentLogLevel
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
    if not shouldLog(level) then
        return
    end

    local body = message or "<no message>"
    if context ~= nil then
        body = body .. " | " .. tryStringify(context)
    end

    if level == "ERROR" then
        warn(string.format("[%s] %s", moduleName or "unknown", body))
    else
        print(string.format("[%s] %s", moduleName or "unknown", body))
    end
end

function DebugLogger.info(moduleName, message, context)
    DebugLogger.log(moduleName, "INFO", message, context)
end

function DebugLogger.warn(moduleName, message, context)
    DebugLogger.log(moduleName, "WARN", message, context)
end

function DebugLogger.error(moduleName, message, context)
    DebugLogger.log(moduleName, "ERROR", message, context)
end

function DebugLogger.debug(moduleName, message, context)
    DebugLogger.log(moduleName, "DEBUG", message, context)
end

function DebugLogger.activity(moduleName, activity, state)
    local status = state or "update"
    DebugLogger.info(moduleName, string.format("Activity %s", activity), status)
end

return DebugLogger
