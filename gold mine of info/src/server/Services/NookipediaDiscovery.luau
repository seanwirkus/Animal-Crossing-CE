-- Nookipedia discovery service: fetches Tom Nook, Isabelle, Orville and top main characters
-- using the API key provided by the user. Caches results for reuse during a session.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NookipediaAPI = require(ReplicatedStorage:WaitForChild("NookipediaAPI"))

local NookipediaDiscovery = {}
NookipediaDiscovery.__index = NookipediaDiscovery

function NookipediaDiscovery.new(apiKey)
    local self = setmetatable({}, NookipediaDiscovery)
    self._api = NookipediaAPI.new(apiKey or "")
    self._cache = nil
    return self
end

-- Merge two character result tables, preferring existing entries in baseTable
local function mergeCharacterTables(baseTable, additionalTable)
    local result = {}
    if baseTable then
        for k, v in pairs(baseTable) do
            result[k] = v
        end
    end
    if additionalTable then
        for k, v in pairs(additionalTable) do
            if not result[k] then
                result[k] = v
            end
        end
    end
    return result
end

-- Fetch a consolidated list of core characters and top 10 main characters
function NookipediaDiscovery:FetchAllCharacters()
    if self._cache then
        return self._cache
    end

    -- Core characters we want to guarantee data for
    local coreNames = { "Tom Nook", "Isabelle", "Orville" }
    local coreData = self._api:FetchCharactersByNames(coreNames) or {}

    -- Top 10 main characters (as defined in the API client)
    local topData = self._api:FetchTopMainCharacters(10) or {}

    local merged = mergeCharacterTables(coreData, topData)

    self._cache = merged
    return merged
end

-- Convenience accessor to trigger a fetch and return the table
function NookipediaDiscovery:GetAllCharacters()
    return self:FetchAllCharacters()
end

return NookipediaDiscovery


