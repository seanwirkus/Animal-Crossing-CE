--[[
	Logger Module - Centralized Logging System
	
	Provides structured logging with levels: DEBUG, INFO, WARN, ERROR, CRITICAL
	
	Usage:
		local Logger = require(game.ServerScriptService.Logger)
		Logger:Info("MyModule", "Player joined", { playerId = player.UserId })
		Logger:Error("MyModule", "API call failed", { endpoint = "/villagers", statusCode = 500 })
]]

local HttpService = game:GetService("HttpService")

local Logger = {}
Logger.__index = Logger

-- Log levels
local LOG_LEVELS = {
	DEBUG = { priority = 1, symbol = "🐛" },
	INFO = { priority = 2, symbol = "ℹ️" },
	WARN = { priority = 3, symbol = "⚠️" },
	ERROR = { priority = 4, symbol = "❌" },
	CRITICAL = { priority = 5, symbol = "🚨" },
}

-- Current log level (set this to filter logs)
local CURRENT_LEVEL = 1 -- Show all logs

-- Color codes for console output
local COLORS = {
	RESET = "\27[0m",
	RED = "\27[31m",
	YELLOW = "\27[33m",
	BLUE = "\27[34m",
	CYAN = "\27[36m",
	MAGENTA = "\27[35m",
	GRAY = "\27[90m",
}

--[[
	Internal: Format log message with timestamp and context
	@param level string - Log level (DEBUG, INFO, WARN, ERROR, CRITICAL)
	@param module string - Module name
	@param message string - Log message
	@param data table? - Optional context data
	@return string - Formatted log message
]]
local function formatMessage(level, module, message, data)
	local timestamp = os.date("%H:%M:%S")
	local levelInfo = LOG_LEVELS[level]
	local levelSymbol = levelInfo.symbol or level
	
	local context = ""
	if data then
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(data)
		end)
		if ok and encoded then
			context = " | " .. encoded:sub(1, 100)
		else
			context = " | (data encoding failed)"
		end
	end
	
	return string.format("[%s] %s [%s] %s%s", timestamp, levelSymbol, module, message, context)
end

--[[
	Log message at DEBUG level
	@param module string - Module name (e.g., "VillagerService")
	@param message string - Log message
	@param data table? - Optional context data
]]
function Logger:Debug(module, message, data)
	if LOG_LEVELS["DEBUG"].priority < CURRENT_LEVEL then return end
	print(formatMessage("DEBUG", module, message, data))
end

--[[
	Log message at INFO level
	@param module string - Module name
	@param message string - Log message
	@param data table? - Optional context data
]]
function Logger:Info(module, message, data)
	if LOG_LEVELS["INFO"].priority < CURRENT_LEVEL then return end
	print(formatMessage("INFO", module, message, data))
end

--[[
	Log message at WARN level
	@param module string - Module name
	@param message string - Log message
	@param data table? - Optional context data
]]
function Logger:Warn(module, message, data)
	if LOG_LEVELS["WARN"].priority < CURRENT_LEVEL then return end
	warn(formatMessage("WARN", module, message, data))
end

--[[
	Log message at ERROR level
	@param module string - Module name
	@param message string - Log message
	@param data table? - Optional context data
]]
function Logger:Error(module, message, data)
	if LOG_LEVELS["ERROR"].priority < CURRENT_LEVEL then return end
	warn(formatMessage("ERROR", module, message, data))
end

--[[
	Log message at CRITICAL level
	@param module string - Module name
	@param message string - Log message
	@param data table? - Optional context data
]]
function Logger:Critical(module, message, data)
	warn(formatMessage("CRITICAL", module, message, data))
end

--[[
	Set minimum log level to display
	@param level string - "DEBUG", "INFO", "WARN", "ERROR", or "CRITICAL"
]]
function Logger:SetLevel(level)
	if not LOG_LEVELS[level] then
		warn("Invalid log level:", level)
		return
	end
	CURRENT_LEVEL = LOG_LEVELS[level].priority
end

--[[
	Get current log level
	@return string - Current log level
]]
function Logger:GetLevel()
	for level, info in pairs(LOG_LEVELS) do
		if info.priority == CURRENT_LEVEL then
			return level
		end
	end
	return "UNKNOWN"
end

return Logger
