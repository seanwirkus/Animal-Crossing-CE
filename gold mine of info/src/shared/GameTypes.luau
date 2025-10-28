--[[
	GameTypes Module - Type Definitions for ACNH Roblox
	
	Contains all type aliases and interfaces used throughout the game
	Uses Luau's type system for type safety
]]

export type Player = {
	UserId: number,
	Name: string,
	Character: Model?,
}

export type ItemStack = {
	itemId: string,
	quantity: number,
	maxStack: number,
}

export type Inventory = {
	slots: { [string]: ItemStack },
	maxSlots: number,
	totalItems: number,
}

export type EconomySnapshot = {
	bells: number,
	miles: number,
	debt: number,
	savings: number,
}

export type VillagerData = {
	id: string,
	displayName: string,
	personality: string,
	species: string,
	birthday: string,
	catchphrase: string,
	nookipediaImageUrl: string?,
	nookipediaIconUrl: string?,
}

export type IslandTemplate = {
	id: string,
	displayName: string,
	description: string,
	vibe: string,
	weatherPreference: string,
	timeOfDayBonus: string,
	features: { string },
	startingResources: { [string]: number },
	startingBells: number,
	startingMiles: number,
}

export type QuestData = {
	id: string,
	title: string,
	description: string,
	rewards: {
		bells: number,
		miles: number,
		items: { [string]: number }?,
	},
	progress: number,
	maxProgress: number,
	completed: boolean,
}

export type FurnitureItem = {
	id: string,
	category: string,
	size: Vector3,
	cost: number,
	description: string,
}

export type HomeStatus = {
	level: string,
	rooms: number,
	expansion: number,
	totalCost: number,
	furniture: { [string]: FurnitureItem },
}

export type ApiResponse<T> = {
	success: boolean,
	data: T?,
	error: {
		type: string,
		message: string,
	}?,
	timestamp: number,
}

export type ClockState = {
	hour: number,
	minute: number,
	day: number,
	month: number,
	year: number,
	season: string,
	timeOfDay: string,
}

export type LogEntry = {
	level: string,
	module: string,
	message: string,
	data: any?,
	timestamp: number,
}

return {}
