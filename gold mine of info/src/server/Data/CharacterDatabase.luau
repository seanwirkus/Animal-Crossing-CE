-- Character database to store Nookipedia character data
-- Loads from pre-fetched JSON file (no HTTP requests needed at runtime)
local HttpService = game:GetService("HttpService")
local CharacterDatabase = {}
CharacterDatabase.__index = CharacterDatabase

function CharacterDatabase.new()
	local self = setmetatable({}, CharacterDatabase)
	self._characters = {}
	self._loaded = false
	return self
end

function CharacterDatabase:LoadFromJSON(jsonString)
	if type(jsonString) ~= "string" then
		warn("[CharacterDatabase] Invalid JSON string provided")
		return false
	end
	
	local success, characterData = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success or type(characterData) ~= "table" then
		warn("[CharacterDatabase] Failed to parse character JSON")
		return false
	end
	
	for name, data in pairs(characterData) do
		self._characters[name] = data
	end
	
	self._loaded = true
	print("[CharacterDatabase] ✅ Loaded", self:GetCharacterCount(), "characters from JSON")
	return true
end

function CharacterDatabase:LoadCharacters(characterData)
	if type(characterData) ~= "table" then
		warn("[CharacterDatabase] Invalid character data provided")
		return false
	end
	
	for name, data in pairs(characterData) do
		self._characters[name] = data
	end
	
	self._loaded = true
	print("[CharacterDatabase] Loaded", self:GetCharacterCount(), "characters")
	return true
end

function CharacterDatabase:GetCharacter(name)
	if not name then return nil end
	return self._characters[name]
end

function CharacterDatabase:GetAllCharacters()
	return self._characters
end

function CharacterDatabase:GetCharacterCount()
	local count = 0
	for _ in pairs(self._characters) do
		count = count + 1
	end
	return count
end

function CharacterDatabase:IsLoaded()
	return self._loaded
end

function CharacterDatabase:GetCharacterInfo(name)
	local character = self:GetCharacter(name)
	if not character then
		return {
			name = name,
			species = "Unknown",
			personality = "Unknown",
			birthday = "Unknown",
			quote = "No quote available",
			description = "No description available"
		}
	end
	
	-- Extract useful info from Nookipedia data
	return {
		name = character.name or name,
		species = character.species or "Unknown",
		personality = character.personality or "Unknown",
		birthday = character.birthday or "Unknown",
		birthdayMonth = character.birthday_month or "Unknown",
		birthdayDay = character.birthday_day or "Unknown",
		quote = character.quote or character.phrase or "...",
		description = character.description or "A friendly character",
		gender = character.gender or "Unknown",
		image = character.image_url or character.photo_url or "",
		debut = character.debut or "Animal Crossing",
		-- Full data for advanced usage
		rawData = character
	}
end

return CharacterDatabase

