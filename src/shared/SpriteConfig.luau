local SpriteConfig = {
    -- Main item spritesheet
    SHEET_ASSET = "rbxassetid://79857338226248",
    COLUMNS = 21,
    ROWS = 24,
    
    -- Sprite dimensions (direct values)
    SPRITE_SIZE = 33.6667, 
    PADDING = 8.9,  -- Reduced padding to compensate for larger sprite
    
    -- Outer padding around the edges of the spritesheet (individual control)
    OUTER_PADDING_LEFT = 6,
    OUTER_PADDING_RIGHT = 5,
    OUTER_PADDING_TOP = 4.5,
    OUTER_PADDING_BOTTOM = 11,
    
    -- DIY Recipe icons spritesheet
    DIY_SHEET_ASSET = "rbxassetid://97942095241212",
    DIY_COLUMNS = 26,
    DIY_ROWS = 23,
    DIY_SPRITE_SIZE = 33.6667,  -- Each icon is 36px × 36px
    DIY_PADDING = 6,  -- Padding between icons (will need fine-tuning)
    
    -- DIY outer padding (individual control for precise alignment)
    DIY_OUTER_PADDING_LEFT = 0,
    DIY_OUTER_PADDING_RIGHT = 5,
    DIY_OUTER_PADDING_TOP = 4.5,
    DIY_OUTER_PADDING_BOTTOM = 0,
}

local function round(value: number): number
    return math.floor(value + 0.5)
end

SpriteConfig.DEFAULT_SPRITE_SIZE = SpriteConfig.SPRITE_SIZE
SpriteConfig.DEFAULT_IMAGE_RECT_SIZE = Vector2.new(
    SpriteConfig.SPRITE_SIZE,
    SpriteConfig.SPRITE_SIZE
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

    -- Calculate sprite position using fixed dimensions
    -- Each cell = SPRITE_SIZE + PADDING
    -- Starting position = OUTER_PADDING (L/T)
    local cellWidth = SpriteConfig.SPRITE_SIZE + SpriteConfig.PADDING
    local cellHeight = SpriteConfig.SPRITE_SIZE + SpriteConfig.PADDING
    
    local offsetX = SpriteConfig.OUTER_PADDING_LEFT + col * cellWidth
    local offsetY = SpriteConfig.OUTER_PADDING_TOP + row * cellHeight

    local offset = Vector2.new(
        round(offsetX),
        round(offsetY)
    )

    local rectSize = Vector2.new(SpriteConfig.SPRITE_SIZE, SpriteConfig.SPRITE_SIZE)

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

-- Apply DIY recipe icon sprite
function SpriteConfig.applyDIYIcon(imageObject: Instance?, recipeIndex: number?)
    if not imageObject then
        return false
    end

    if not imageObject:IsA("ImageLabel") and not imageObject:IsA("ImageButton") then
        return false
    end

    if typeof(recipeIndex) ~= "number" then
        return false
    end

    local integerIndex = math.floor(recipeIndex)
    if integerIndex < 1 or integerIndex > SpriteConfig.DIY_COLUMNS * SpriteConfig.DIY_ROWS then
        return false
    end

    local zeroBased = integerIndex - 1
    local col = zeroBased % SpriteConfig.DIY_COLUMNS
    local row = math.floor(zeroBased / SpriteConfig.DIY_COLUMNS)

    -- Calculate DIY icon position using fixed dimensions with individual outer padding
    local cellWidth = SpriteConfig.DIY_SPRITE_SIZE + SpriteConfig.DIY_PADDING
    local cellHeight = SpriteConfig.DIY_SPRITE_SIZE + SpriteConfig.DIY_PADDING
    
    local offsetX = SpriteConfig.DIY_OUTER_PADDING_LEFT + col * cellWidth
    local offsetY = SpriteConfig.DIY_OUTER_PADDING_TOP + row * cellHeight

    local offset = Vector2.new(round(offsetX), round(offsetY))
    local rectSize = Vector2.new(SpriteConfig.DIY_SPRITE_SIZE, SpriteConfig.DIY_SPRITE_SIZE)

    imageObject.Image = SpriteConfig.DIY_SHEET_ASSET
    imageObject.ImageRectOffset = offset
    imageObject.ImageRectSize = rectSize
    return true
end

return SpriteConfig
