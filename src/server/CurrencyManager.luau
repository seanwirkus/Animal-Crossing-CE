--[[
    CurrencyManager.luau
    Server-side currency management for Bells and Nook Miles
    
    TODO: PHASE 1 - DAY 1 PRIORITY
    - Implement addBells(player, amount)
    - Implement removeBells(player, amount)
    - Implement getBells(player)
    - Implement addMiles(player, amount)
    - Implement getMiles(player)
    - Integrate with DataStore persistence
    - Add validation and error handling
    - Emit events to client for UI updates
    
    DEPENDS ON: DataStore integration in init.server.luau
    USED BY: FishingSystem, BugSystem, ShopManager, GamePassManager
]]

local CurrencyManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local currencyRemote = ReplicatedStorage:FindFirstChild("CurrencyEvent")
if not currencyRemote then
    currencyRemote = Instance.new("RemoteEvent")
    currencyRemote.Name = "CurrencyEvent"
    currencyRemote.Parent = ReplicatedStorage
end

type PlayerCurrencyState = {
    bells: number,
    miles: number,
    lifetimeEarned: number,
    lifetimeSpent: number,
}

local playerCurrency: { [number]: PlayerCurrencyState } = {}
local saveCallback: ((Player, PlayerCurrencyState) -> ())? = nil
local createDefaultState: (() -> PlayerCurrencyState)? = nil

local function ensureState(player: Player): PlayerCurrencyState
    local state = playerCurrency[player.UserId]
    if state then
        return state
    end

    local newState
    if createDefaultState then
        newState = createDefaultState()
    else
        newState = {
            bells = 0,
            miles = 0,
            lifetimeEarned = 0,
            lifetimeSpent = 0,
        }
    end

    playerCurrency[player.UserId] = newState
    return newState
end

local function fireUpdate(player: Player, action: string, payload)
    if currencyRemote then
        currencyRemote:FireClient(player, action, payload)
    end
end

local function persist(player: Player, state: PlayerCurrencyState)
    if saveCallback then
        local ok, err = pcall(saveCallback, player, state)
        if not ok then
            warn("[CurrencyManager] Failed to save currency for", player and player.Name or "<nil>", ":", err)
        end
    end
end

function CurrencyManager.configure(options)
    if options then
        if options.playerCurrencyTable then
            playerCurrency = options.playerCurrencyTable
        end
        if options.saveCallback then
            saveCallback = options.saveCallback
        end
        if options.createDefaultState then
            createDefaultState = options.createDefaultState
        end
    end
end

function CurrencyManager.registerPlayer(player: Player, state: PlayerCurrencyState)
    if not player then
        return
    end

    local userId = player.UserId
    if state then
        playerCurrency[userId] = state
    else
        playerCurrency[userId] = ensureState(player)
    end

    local currentState = playerCurrency[userId]
    fireUpdate(player, "UpdateBells", {
        bells = currentState.bells or 0,
        animate = false,
    })
    fireUpdate(player, "UpdateMiles", {
        miles = currentState.miles or 0,
        animate = false,
    })
end

function CurrencyManager.unregisterPlayer(player: Player)
    if not player then
        return
    end

    playerCurrency[player.UserId] = nil
end

function CurrencyManager.addBells(player: Player, amount: number): boolean
    if not player or typeof(amount) ~= "number" then
        warn("[CurrencyManager] addBells requires valid player and numeric amount")
        return false
    end

    if amount <= 0 then
        warn("[CurrencyManager] addBells requires positive amount -", amount)
        return false
    end

    local multiplier = CurrencyManager.getEarningMultiplier(player)
    local adjustedAmount = amount * multiplier
    local finalAmount = math.floor(adjustedAmount + 0.5)
    if finalAmount <= 0 then
        return false
    end

    local state = ensureState(player)
    state.bells = math.max(0, (state.bells or 0) + finalAmount)
    state.lifetimeEarned = math.max(0, (state.lifetimeEarned or 0) + finalAmount)

    fireUpdate(player, "UpdateBells", {
        bells = state.bells,
        delta = finalAmount,
        animate = true,
    })

    persist(player, state)

    return true
end

function CurrencyManager.removeBells(player: Player, amount: number): boolean
    if not player or typeof(amount) ~= "number" then
        warn("[CurrencyManager] removeBells requires valid player and numeric amount")
        return false
    end

    if amount <= 0 then
        warn("[CurrencyManager] removeBells requires positive amount -", amount)
        return false
    end

    local toRemove = math.floor(amount)
    if toRemove <= 0 then
        return false
    end

    local state = ensureState(player)
    local current = state.bells or 0
    if current < toRemove then
        warn("[CurrencyManager]", player.Name, "does not have enough bells (", current, "<", toRemove, ")")
        return false
    end

    state.bells = current - toRemove
    state.lifetimeSpent = math.max(0, (state.lifetimeSpent or 0) + toRemove)

    fireUpdate(player, "UpdateBells", {
        bells = state.bells,
        delta = -toRemove,
        animate = true,
    })

    persist(player, state)

    return true
end

function CurrencyManager.getBells(player: Player): number
    if not player then
        return 0
    end

    local state = playerCurrency[player.UserId]
    if not state then
        return 0
    end

    return state.bells or 0
end

function CurrencyManager.addMiles(player: Player, amount: number): boolean
    if not player or typeof(amount) ~= "number" then
        warn("[CurrencyManager] addMiles requires valid player and numeric amount")
        return false
    end

    if amount <= 0 then
        warn("[CurrencyManager] addMiles requires positive amount -", amount)
        return false
    end

    local delta = math.floor(amount)
    if delta <= 0 then
        return false
    end

    local state = ensureState(player)
    state.miles = math.max(0, (state.miles or 0) + delta)

    fireUpdate(player, "UpdateMiles", {
        miles = state.miles,
        delta = delta,
        animate = true,
    })

    persist(player, state)

    return true
end

function CurrencyManager.getMiles(player: Player): number
    if not player then
        return 0
    end

    local state = playerCurrency[player.UserId]
    if not state then
        return 0
    end

    return state.miles or 0
end

function CurrencyManager.getEarningMultiplier(_player: Player): number
    return 1.0
end

function CurrencyManager.getPlayerState(player: Player): PlayerCurrencyState?
    if not player then
        return nil
    end

    return playerCurrency[player.UserId]
end

return CurrencyManager
