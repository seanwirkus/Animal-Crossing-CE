--[[
	ErrorHandler Module - Standardized Error Handling
	
	Provides:
	- Safe pcall wrapper
	- Retry logic with exponential backoff
	- Structured error responses
	- Error recovery suggestions
	
	Usage:
		local ErrorHandler = require(script.Parent.ErrorHandler)
		local ok, result = ErrorHandler:SafeCall(function() return apiService:GetData() end)
		if not ok then ErrorHandler:LogError("MyModule", result) end
]]

local Logger = require(script.Parent.Logger)

local ErrorHandler = {}
ErrorHandler.__index = ErrorHandler

--[[
	Safely execute a function with error handling
	@param fn function - Function to execute
	@param context table? - Context for error logging
	@return boolean, any - (success, result)
]]
function ErrorHandler:SafeCall(fn, context)
	context = context or {}
	local ok, result = pcall(fn)
	
	if not ok then
		Logger:Error("ErrorHandler", "SafeCall failed", {
			error = tostring(result),
			context = context,
		})
	end
	
	return ok, result
end

--[[
	Execute function with retry logic
	@param fn function - Function to execute
	@param maxRetries number - Maximum retry attempts
	@param baseDelay number - Base delay in seconds (exponential backoff)
	@param context table? - Context for logging
	@return boolean, any - (success, result)
]]
function ErrorHandler:RetryCall(fn, maxRetries, baseDelay, context)
	context = context or {}
	baseDelay = baseDelay or 0.5
	maxRetries = maxRetries or 3
	
	for attempt = 1, maxRetries do
		local ok, result = self:SafeCall(fn, context)
		
		if ok then
			return true, result
		end
		
		if attempt < maxRetries then
			local delay = baseDelay * math.pow(2, attempt - 1)
			Logger:Warn("ErrorHandler", "Retry attempt " .. attempt .. " in " .. delay .. "s", context)
			task.wait(delay)
		end
	end
	
	Logger:Error("ErrorHandler", "RetryCall exhausted " .. maxRetries .. " attempts", context)
	return false, "Max retries exceeded"
end

--[[
	Validate that required parameters exist
	@param params table - Parameters to validate
	@param required table - Array of required param names
	@return boolean, string? - (isValid, errorMessage)
]]
function ErrorHandler:ValidateParams(params, required)
	for _, paramName in ipairs(required) do
		if not params[paramName] then
			return false, "Missing required parameter: " .. paramName
		end
	end
	return true
end

--[[
	Create structured error response
	@param errorType string - Type of error (VALIDATION, SERVER, API, UNKNOWN)
	@param message string - Error message
	@param data table? - Additional error data
	@return table - Structured error object
]]
function ErrorHandler:CreateError(errorType, message, data)
	return {
		success = false,
		error = {
			type = errorType,
			message = message,
			data = data,
			timestamp = os.time(),
		}
	}
end

--[[
	Create success response
	@param data any - Response data
	@param metadata table? - Additional metadata
	@return table - Structured success object
]]
function ErrorHandler:CreateSuccess(data, metadata)
	return {
		success = true,
		data = data,
		metadata = metadata or {},
		timestamp = os.time(),
	}
end

--[[
	Log error with full context
	@param module string - Module name
	@param errorType string - Type of error
	@param message string - Error message
	@param data table? - Error context
]]
function ErrorHandler:LogError(module, errorType, message, data)
	Logger:Error(module, message, {
		errorType = errorType,
		data = data,
	})
end

return ErrorHandler
