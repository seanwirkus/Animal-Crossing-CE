local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage.Data)

local LocalContentRepository = {}
LocalContentRepository.__index = LocalContentRepository

export type LocalContentRepository = {
	GetItem: (LocalContentRepository, string) -> any?,
	GetCharacter: (LocalContentRepository, string) -> any?,
	GetAllItems: (LocalContentRepository) -> { any },
	GetAllCharacters: (LocalContentRepository) -> { any },
	SearchItems: (LocalContentRepository, string) -> { any },
	SearchCharacters: (LocalContentRepository, string) -> { any },
	_initialize: (LocalContentRepository) -> (),
	_loadItems: (LocalContentRepository) -> (),
	_loadCharacters: (LocalContentRepository) -> (),
	_items: { [string]: any },
	_characters: { [string]: any }
}

local singleton: LocalContentRepository? = nil

local function toKey(name: string?): string
	if not name or name == "" then
		return ""
	end

	local cleaned = string.lower(name)
	cleaned = cleaned:gsub("[^%w]+", "_")
	return cleaned
end

local function shallowCopy<T>(source: T): T
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	-- Luau typechecker sees empty table as {} so we cast
	return copy :: any
end

local function ensureArrayCopy<T>(list: { T }?): { T }
	if not list then
		return {}
	end

	local copy = table.create(#list)
	for index, value in ipairs(list) do
		copy[index] = value
	end

	return copy
end

function LocalContentRepository.new(): LocalContentRepository
	if singleton then
		return singleton
	end

	local self = setmetatable({}, LocalContentRepository)

	self._villagers = {}
	self._villagerByKey = {}

	self._itemsById = {}
	self._itemsByKey = {}
	self._categories = {}

	self:_indexVillagers(Data.Villagers)
	self:_indexItems(Data.Items)
	self:_indexItems(Data.GeneratedItems)

	singleton = self
	return self
end

function LocalContentRepository:_indexVillagers(villagersModule)
	for id, villager in pairs(villagersModule or {}) do
		local entry = shallowCopy(villager)
		entry.id = entry.id or id
		table.insert(self._villagers, entry)

		local directKey = toKey(entry.id)
		if directKey ~= "" then
			self._villagerByKey[directKey] = entry
		end

		local nameKey = toKey(entry.displayName)
		if nameKey ~= "" then
			self._villagerByKey[nameKey] = entry
		end
	end
end

function LocalContentRepository:_indexItems(itemsModule)
	for id, item in pairs(itemsModule or {}) do
		local entry = shallowCopy(item)
		entry.id = entry.id or id
		entry.category = entry.category or "Misc"

		local existing = self._itemsById[entry.id]
		if existing then
			for key, value in pairs(entry) do
				if existing[key] == nil and value ~= nil then
					existing[key] = value
				end
			end
		else
			self._itemsById[entry.id] = entry

			local key = toKey(entry.name or entry.displayName or entry.id)
			if key ~= "" then
				self._itemsByKey[key] = entry
			end
			local idKey = toKey(entry.id)
			if idKey ~= "" then
				self._itemsByKey[idKey] = entry
			end

			self._categories[entry.category] = self._categories[entry.category] or {}
			table.insert(self._categories[entry.category], entry)
		end
	end
end

function LocalContentRepository:GetVillagers(filters: { [string]: any }?)
	local results = {}

	for _, villager in ipairs(self._villagers) do
		table.insert(results, villager)
	end

	if not filters then
		return results
	end

	local filtered = {}
	for _, villager in ipairs(results) do
		local include = true

		if filters.name then
			local wanted = string.lower(filters.name)
			local displayName = string.lower(villager.displayName or villager.id or "")
			if not displayName:find(wanted, 1, true) then
				include = false
			end
		end

		if include and filters.species then
			include = string.lower(villager.species or "") == string.lower(filters.species)
		end

		if include and filters.personality then
			include = string.lower(villager.personality or "") == string.lower(filters.personality)
		end

		if include then
			table.insert(filtered, villager)
		end
	end

	return filtered
end

function LocalContentRepository:GetVillagerByName(name: string?): {}?
	if not name then
		return nil
	end

	return self._villagerByKey[toKey(name)]
end

function LocalContentRepository:GetItemById(id: string?): {}?
	if not id then
		return nil
	end

	return self._itemsById[id]
end

function LocalContentRepository:GetItemByName(name: string?): {}?
	if not name then
		return nil
	end

	return self._itemsByKey[toKey(name)]
end

function LocalContentRepository:GetItemsByCategory(category: string?): { {} }
	if not category then
		return {}
	end

	return ensureArrayCopy(self._categories[category])
end

function LocalContentRepository:GetAllItems()
	return self._itemsById
end

return LocalContentRepository

