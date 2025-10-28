-- Nookipedia API client for Roblox
local HttpService = game:GetService("HttpService")
local NookipediaAPI = {}
NookipediaAPI.__index = NookipediaAPI

local BASE_URL = "https://api.nookipedia.com/v1"

function NookipediaAPI.new(apiKey)
    local self = setmetatable({}, NookipediaAPI)
    self._apiKey = apiKey
    return self
end

local function encodeName(name)
    if type(name) ~= "string" then return "" end
    return HttpService:UrlEncode(name)
end

local function fetchWithHeaders(url, headers)
    local requestInfo = {
        Url = url,
        Method = "GET",
        Headers = headers or {},
    }
    local ok, response = pcall(function()
        return HttpService:RequestAsync(requestInfo)
    end)
    if not ok then
        warn("[NookipediaAPI] Request failed:", url)
        return nil
    end
    if not response.Success then
        warn("[NookipediaAPI] HTTP error:", response.StatusCode, response.StatusMessage)
        return nil
    end
    local body = response.Body
    local decoded = nil
    local okDecode, data = pcall(function() return HttpService:JSONDecode(body) end)
    if okDecode then
        decoded = data
    else
        warn("[NookipediaAPI] JSON decode failed for:", url)
    end
    return decoded
end

function NookipediaAPI:_getCharacterDataByName(name)
    local query = encodeName(name)
    local endpoint = BASE_URL .. "/characters?name=" .. query
    local headers = {}
    if self._apiKey and self._apiKey ~= "" then
        headers["X-API-Key"] = self._apiKey
    end
    local data = fetchWithHeaders(endpoint, headers)
    if data and type(data) == "table" then
        if data.characters then
            return data.characters[1]
        end
        return data
    end
    return nil
end

function NookipediaAPI:GetCharacter(characterName)
    if not characterName then return nil end
    return self:_getCharacterDataByName(characterName)
end

function NookipediaAPI:FetchCharactersByNames(names)
    if type(names) ~= "table" then return {} end
    local results = {}
    for _, name in ipairs(names) do
        local data = self:GetCharacter(name)
        results[name] = data
    end
    return results
end

function NookipediaAPI:FetchTopMainCharacters(count)
    -- Requires a predefined list of top main characters. Users may customize this list.
    local defaultTop = { "Tom Nook", "Isabelle", "Orville", "K.K. Slider", "Blathers", "Celeste", "Timmy", "Tommy", "Leif", "Resetti" }
    local names = {}
    local n = count or #defaultTop
    for i = 1, math.min(n, #defaultTop) do
        table.insert(names, defaultTop[i])
    end
    return self:FetchCharactersByNames(names)
end

return NookipediaAPI


