export type ItemStack = {
    id: string,
    count: number,
    metadata: {[string]: any}?,
    createdAt: number?,
}

export type InventorySlot = {
    index: number,
    stack: ItemStack?,
    locked: boolean?,
    maxStack: number?,
    tags: {string}?,
}

export type InventorySnapshot = {
    id: string?,
    dataset: string?,
    maxSlots: number,
    slots: {InventorySlot},
    version: string?,
    updatedAt: number?,
    source: string?,
}

export type LegacySlot = {
    slot: number?,
    itemId: string?,
    amount: number?,
    data: {[string]: any}?,
}

export type LegacySnapshot = {
    inventory: {LegacySlot}?,
    capacity: number?,
    updatedAt: number?,
    version: string?,
}

export type InventoryDiff = {
    added: {InventorySlot},
    removed: {InventorySlot},
    updated: {InventorySlot},
    metadata: {[string]: any}?,
}

return {}
