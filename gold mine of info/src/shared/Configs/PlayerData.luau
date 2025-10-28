--[[
	PlayerData - Animal Crossing player data structure
	Based on the template but customized for AC gameplay
]]

export type Currency = "bells" | "miles" | "nook_miles"

export type PlayerBalance = {
	bells: number,
	miles: number,
	nook_miles: number,
}

export type IslandData = {
	name: string,
	theme: string,
	resident_services: boolean,
	museum: boolean,
	shop: boolean,
}

export type PlayerInventory = {
	[number]: {
		item_id: string,
		quantity: number,
	}
}

export type PlayerData = {
	balance: PlayerBalance,
	island: IslandData,
	inventory: PlayerInventory,
	level: number,
	experience: number,
	last_login: number,
}

return {}
