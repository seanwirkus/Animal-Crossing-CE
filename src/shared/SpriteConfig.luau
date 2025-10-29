local SpriteConfig = {
    SHEET_ASSET = "rbxassetid://102758508019146",
    COLUMNS = 21,
    ROWS = 24,
    TILE = 73.2,  -- 36.6 * 2 for 2x resolution
    INNER = Vector2.new(12, 12),  -- 6 * 2
    OUTER = Vector2.new(8, 8),    -- 4 * 2
    BLEED_FIX = 0.5,  -- 0.25 * 2
}

function SpriteConfig.getSpriteRect(index)
    if not index or typeof(index) ~= "number" then
        return nil, nil
    end

    local zeroBased = index - 1
    local col = zeroBased % SpriteConfig.COLUMNS
    local row = math.floor(zeroBased / SpriteConfig.COLUMNS)
    local offsetX = SpriteConfig.OUTER.X + col * (SpriteConfig.TILE + SpriteConfig.INNER.X)
    local offsetY = SpriteConfig.OUTER.Y + row * (SpriteConfig.TILE + SpriteConfig.INNER.Y)
    local size = SpriteConfig.TILE - SpriteConfig.BLEED_FIX * 2

    local offset = Vector2.new(math.floor(offsetX + SpriteConfig.BLEED_FIX + 0.5), math.floor(offsetY + SpriteConfig.BLEED_FIX + 0.5))
    local rectSize = Vector2.new(math.floor(size + 0.5), math.floor(size + 0.5))

    return offset, rectSize
end

return SpriteConfig
