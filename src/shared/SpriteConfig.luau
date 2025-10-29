local SpriteConfig = {
    SHEET_ASSET = "rbxassetid://102758508019146",
    COLUMNS = 21,
    ROWS = 24,
    TILE = 73.2,  -- 36.6 * 2 for 2x resolution
    INNER = Vector2.new(12, 12),  -- 6 * 2
    OUTER = Vector2.new(8, 8),    -- 4 * 2
    BLEED_FIX = 0.5,  -- 0.25 * 2
}

local function round(value: number): number
    return math.floor(value + 0.5)
end

SpriteConfig.DEFAULT_SPRITE_SIZE = round(SpriteConfig.TILE - SpriteConfig.BLEED_FIX * 2)
SpriteConfig.DEFAULT_IMAGE_RECT_SIZE = Vector2.new(
    SpriteConfig.DEFAULT_SPRITE_SIZE,
    SpriteConfig.DEFAULT_SPRITE_SIZE
)

local function validateIndex(index: number?): number?
    if typeof(index) ~= "number" then
        return nil
    end

    local integerIndex = math.floor(index)
    if integerIndex < 1 or integerIndex > SpriteConfig.COLUMNS * SpriteConfig.ROWS then
        return nil
    end

    return integerIndex
end

function SpriteConfig.getSpriteRect(index: number?)
    local resolvedIndex = validateIndex(index)
    if not resolvedIndex then
        return nil, nil
    end

    local zeroBased = resolvedIndex - 1
    local col = zeroBased % SpriteConfig.COLUMNS
    local row = math.floor(zeroBased / SpriteConfig.COLUMNS)

    local offsetX = SpriteConfig.OUTER.X + col * (SpriteConfig.TILE + SpriteConfig.INNER.X)
    local offsetY = SpriteConfig.OUTER.Y + row * (SpriteConfig.TILE + SpriteConfig.INNER.Y)

    local offset = Vector2.new(
        round(offsetX + SpriteConfig.BLEED_FIX),
        round(offsetY + SpriteConfig.BLEED_FIX)
    )

    local sizeValue = SpriteConfig.DEFAULT_SPRITE_SIZE
    local rectSize = Vector2.new(sizeValue, sizeValue)

    return offset, rectSize
end

function SpriteConfig.getIndexFromGrid(column: number?, row: number?)
    if typeof(column) ~= "number" or typeof(row) ~= "number" then
        return nil
    end

    local colIndex = math.floor(column)
    local rowIndex = math.floor(row)

    if colIndex < 0 or colIndex >= SpriteConfig.COLUMNS then
        return nil
    end

    if rowIndex < 0 or rowIndex >= SpriteConfig.ROWS then
        return nil
    end

    return rowIndex * SpriteConfig.COLUMNS + colIndex + 1
end

function SpriteConfig.applySprite(imageObject: Instance?, spriteIndex: number?)
    if not imageObject then
        return false
    end

    if not imageObject:IsA("ImageLabel") and not imageObject:IsA("ImageButton") then
        return false
    end

    local offset, size = SpriteConfig.getSpriteRect(spriteIndex)
    if not offset or not size then
        return false
    end

    imageObject.Image = SpriteConfig.SHEET_ASSET
    imageObject.ImageRectOffset = offset
    imageObject.ImageRectSize = size
    return true
end

return SpriteConfig
