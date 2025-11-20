# ACNH Color Palette Reference
**Extracted from Reference RBXMX Files**

Generated: November 19, 2025

## Overview
This document contains a comprehensive analysis of all Color3 RGB values used in the Animal Crossing CE reference GUI files. These colors represent the authentic ACNH UI aesthetic and should be used throughout the project for consistency.

---

## Primary ACNH Color Palette

### Background Colors

#### 1. **Cream/Beige Main Background** (Most Important)
- **Usage**: Primary frame backgrounds, main UI panels
- **Files**: InventoryGUI, starterGUI, RecipesInventory
- **Decimal**: `(1.0, 0.984, 0.906)`
- **Byte**: `(255, 251, 231)`
- **Hex**: `#FFFBE7`
- **Luau**: `Color3.fromRGB(255, 251, 231)`
- **Frequency**: 6 occurrences
- **Context**: This is THE signature ACNH cream/beige color used for main backgrounds

#### 2. **Light Cream Background**
- **Usage**: Alternate backgrounds, lighter panels
- **Decimal**: `(0.996, 0.984, 0.914)`
- **Byte**: `(254, 251, 233)`
- **Hex**: `#FEFBE9`
- **Luau**: `Color3.fromRGB(254, 251, 233)`
- **Frequency**: 2 occurrences

#### 3. **Off-White Accent**
- **Usage**: Text backgrounds, secondary panels
- **Decimal**: `(0.973, 0.957, 0.910)`
- **Byte**: `(248, 244, 232)`
- **Hex**: `#F8F4E8`
- **Luau**: `Color3.fromRGB(248, 244, 232)`
- **Frequency**: 6 occurrences

#### 4. **Tan/Light Brown Background**
- **Usage**: Recipe info backgrounds, secondary sections
- **Decimal**: `(0.904, 0.865, 0.727)`
- **Byte**: `(231, 221, 185)`
- **Hex**: `#E7DDB9`
- **Luau**: `Color3.fromRGB(231, 221, 185)`
- **Frequency**: 4 occurrences

### Text Colors

#### 1. **Dark Brown Text** (Primary Text Color)
- **Usage**: Main text, labels, descriptions
- **Decimal**: `(0.522, 0.353, 0.145)`
- **Byte**: `(133, 90, 37)`
- **Hex**: `#855A25`
- **Luau**: `Color3.fromRGB(133, 90, 37)`
- **Frequency**: 20 occurrences (MOST USED TEXT COLOR)
- **Context**: This is the standard ACNH brown text color

#### 2. **Medium Brown Text**
- **Usage**: Secondary text, UI elements
- **Decimal**: `(0.541, 0.482, 0.400)`
- **Byte**: `(138, 123, 102)`
- **Hex**: `#8A7B66`
- **Luau**: `Color3.fromRGB(138, 123, 102)`
- **Frequency**: 11 occurrences

#### 3. **Darker Brown Text**
- **Usage**: Borders, strokes, accents
- **Decimal**: `(0.298, 0.235, 0.200)`
- **Byte**: `(76, 60, 51)`
- **Hex**: `#4C3C33`
- **Luau**: `Color3.fromRGB(76, 60, 51)`
- **Frequency**: 14 occurrences

#### 4. **Light Tan Text**
- **Usage**: Labels, UI indicators
- **Decimal**: `(0.820, 0.776, 0.600)`
- **Byte**: `(209, 198, 153)`
- **Hex**: `#D1C699`
- **Luau**: `Color3.fromRGB(209, 198, 153)`
- **Frequency**: 8 occurrences

### Accent Colors

#### 1. **Orange/Gold Accent** (Primary Accent)
- **Usage**: Buttons, highlights, active states, Nook Shopping menu
- **Decimal**: `(0.992, 0.576, 0.012)`
- **Byte**: `(253, 147, 3)`
- **Hex**: `#FD9303`
- **Luau**: `Color3.fromRGB(253, 147, 3)`
- **Frequency**: 15 occurrences (SECOND MOST COMMON COLOR)
- **Context**: Signature ACNH orange/gold for buttons and highlights

#### 2. **Bright Orange Accent**
- **Usage**: Additional accent color
- **Decimal**: `(0.988, 0.647, 0.0)`
- **Byte**: `(252, 165, 0)`
- **Hex**: `#FCA500`
- **Luau**: `Color3.fromRGB(252, 165, 0)`
- **Frequency**: 3 occurrences

#### 3. **Yellow/Gold Star**
- **Usage**: Stars, special indicators
- **Decimal**: `(0.980, 0.820, 0.169)`
- **Byte**: `(250, 209, 43)`
- **Hex**: `#FAD12B`
- **Luau**: `Color3.fromRGB(250, 209, 43)`
- **Frequency**: 14 occurrences

#### 4. **Teal/Turquoise** (Alternate Accent)
- **Usage**: Active states, selections
- **Decimal**: `(0.510, 0.835, 0.733)`
- **Byte**: `(130, 213, 187)`
- **Hex**: `#82D5BB`
- **Luau**: `Color3.fromRGB(130, 213, 187)`
- **Frequency**: 4 occurrences

### Border/Stroke Colors

#### 1. **Medium Brown Border**
- **Usage**: UI strokes, borders
- **Decimal**: `(0.533, 0.357, 0.141)`
- **Byte**: `(136, 91, 36)`
- **Hex**: `#885B24`
- **Luau**: `Color3.fromRGB(136, 91, 36)`
- **Frequency**: 10 occurrences

#### 2. **Dark Brown Border**
- **Usage**: Stronger borders, emphasis
- **Decimal**: `(0.529, 0.353, 0.137)`
- **Byte**: `(135, 90, 35)`
- **Hex**: `#875A23`
- **Luau**: `Color3.fromRGB(135, 90, 35)`
- **Frequency**: 3 occurrences

### Neutral Colors

#### 1. **Pure Black**
- **Usage**: Borders, shadows, text outlines
- **Decimal**: `(0.0, 0.0, 0.0)`
- **Byte**: `(0, 0, 0)`
- **Hex**: `#000000`
- **Luau**: `Color3.fromRGB(0, 0, 0)`
- **Frequency**: 78 occurrences (MOST COMMON)
- **Context**: Used extensively for borders (BorderSizePixel=0 means invisible)

#### 2. **Pure White**
- **Usage**: Icons, highlights, overlays
- **Decimal**: `(1.0, 1.0, 1.0)`
- **Byte**: `(255, 255, 255)`
- **Hex**: `#FFFFFF`
- **Luau**: `Color3.fromRGB(255, 255, 255)`
- **Frequency**: 73 occurrences (SECOND MOST COMMON)

---

## Complete Color Frequency Analysis

### Top 10 Most Used Colors

1. **Black** `(0, 0, 0)` - 78 uses
2. **White** `(255, 255, 255)` - 73 uses
3. **Dark Brown Text** `(133, 90, 37)` - 20 uses
4. **Orange Accent** `(253, 147, 3)` - 15 uses
5. **Darker Brown** `(76, 60, 51)` - 14 uses
6. **Yellow/Gold** `(250, 209, 43)` - 14 uses
7. **Medium Brown** `(138, 123, 102)` - 11 uses
8. **Brown Border** `(136, 91, 36)` - 10 uses
9. **Light Tan** `(209, 198, 153)` - 8 uses
10. **Cream Background** `(255, 251, 231)` - 6 uses

---

## Usage by UI Element Type

### Frame BackgroundColor3
- **Primary**: `Color3.fromRGB(255, 251, 231)` - Cream/beige
- **Secondary**: `Color3.fromRGB(248, 244, 232)` - Off-white
- **Tertiary**: `Color3.fromRGB(231, 221, 185)` - Tan

### TextLabel TextColor3
- **Primary**: `Color3.fromRGB(133, 90, 37)` - Dark brown
- **Secondary**: `Color3.fromRGB(209, 198, 153)` - Light tan
- **Accent**: `Color3.fromRGB(248, 244, 232)` - Off-white (on dark backgrounds)

### TextLabel TextStrokeColor3
- **Standard**: `Color3.fromRGB(0, 0, 0)` - Black
- **With Transparency**: TextStrokeTransparency = 0.8

### UIStroke Color
- **Primary**: `Color3.fromRGB(133, 90, 37)` - Dark brown
- **Secondary**: `Color3.fromRGB(136, 91, 36)` - Medium brown

### ImageLabel ImageColor3
- **Neutral**: `Color3.fromRGB(255, 255, 255)` - White (no tint)
- **Brown Tint**: `Color3.fromRGB(138, 123, 102)` - Medium brown
- **Dark Tint**: `Color3.fromRGB(76, 60, 51)` - Darker brown

### Button BackgroundColor3
- **Active/Hover**: `Color3.fromRGB(253, 147, 3)` - Orange
- **Default**: `Color3.fromRGB(255, 251, 231)` - Cream
- **Secondary**: `Color3.fromRGB(252, 165, 0)` - Bright orange

### BorderColor3
- **Standard**: `Color3.fromRGB(0, 0, 0)` - Black
- **Note**: Most borders have `BorderSizePixel = 0` (invisible)

---

## Color Patterns by File

### InventoryGUI.rbxmx
- **Main Background**: `(255, 251, 231)` - Cream
- **Text**: `(133, 90, 37)` - Dark brown
- **Strokes**: `(136, 91, 36)` - Medium brown
- **Icons**: `(255, 255, 255)` - White

### starterGUI(as-of-10.26).rbxmx
- **Contains Multiple GUIs**:
  - Inventory
  - Crafting
  - Item Browser
  - Recipes
- **Consistent use of**:
  - Cream backgrounds `(255, 251, 231)`
  - Dark brown text `(133, 90, 37)`
  - Orange accents `(253, 147, 3)`

### RecipesInventory.rbxmx
- **Background**: `(255, 251, 231)` - Cream
- **Recipe Cards**: `(231, 221, 185)` - Tan
- **Icons**: Medium brown tints
- **Stars**: Gold/yellow `(250, 209, 43)`

### DialogueGUI.rbxmx
- **Minimalist design**
- **Stroke**: Purple accent `(151, 71, 255)` - Special case for dialogue

---

## Recommended Color Constants

### For Luau Implementation

```lua
local ACNHColors = {
    -- Backgrounds
    CREAM_BACKGROUND = Color3.fromRGB(255, 251, 231),      -- Primary
    LIGHT_CREAM = Color3.fromRGB(254, 251, 233),           -- Alternate
    OFF_WHITE = Color3.fromRGB(248, 244, 232),             -- Secondary
    TAN_BACKGROUND = Color3.fromRGB(231, 221, 185),        -- Tertiary
    
    -- Text
    DARK_BROWN_TEXT = Color3.fromRGB(133, 90, 37),        -- Primary text
    MEDIUM_BROWN_TEXT = Color3.fromRGB(138, 123, 102),    -- Secondary text
    DARKER_BROWN = Color3.fromRGB(76, 60, 51),            -- Emphasis
    LIGHT_TAN_TEXT = Color3.fromRGB(209, 198, 153),       -- Labels
    
    -- Accents
    ORANGE_ACCENT = Color3.fromRGB(253, 147, 3),          -- Primary accent
    BRIGHT_ORANGE = Color3.fromRGB(252, 165, 0),          -- Secondary accent
    YELLOW_GOLD = Color3.fromRGB(250, 209, 43),           -- Stars, special
    TEAL_ACCENT = Color3.fromRGB(130, 213, 187),          -- Alternate accent
    
    -- Borders & Strokes
    MEDIUM_BROWN_BORDER = Color3.fromRGB(136, 91, 36),    -- Primary border
    DARK_BROWN_BORDER = Color3.fromRGB(135, 90, 35),      -- Secondary border
    
    -- Neutrals
    BLACK = Color3.fromRGB(0, 0, 0),                      -- Borders, shadows
    WHITE = Color3.fromRGB(255, 255, 255),                -- Icons, highlights
}
```

---

## Design Guidelines

### Backgrounds
1. **Always use cream** `(255, 251, 231)` as the primary background
2. Layer lighter colors `(248, 244, 232)` on top for depth
3. Use tan `(231, 221, 185)` for content sections within frames

### Text
1. **Always use dark brown** `(133, 90, 37)` for primary text
2. Use lighter tan `(209, 198, 153)` for secondary info
3. Add subtle text strokes for readability: black @ 0.8 transparency

### Buttons & Interactivity
1. Use **orange** `(253, 147, 3)` for active/hover states
2. Cream background for default state
3. Consider teal `(130, 213, 187)` for alternate interactions

### Borders & Strokes
1. Use UIStroke with brown colors, not BorderSizePixel
2. Typical thickness: 2-4 pixels
3. Always set `BorderSizePixel = 0` on frames

### Icons & Images
1. Keep ImageColor3 as white `(255, 255, 255)` for no tint
2. Apply brown tints `(138, 123, 102)` for UI harmony
3. Use darker brown `(76, 60, 51)` for shadows/depth

---

## Color Relationships

### Complementary Pairs
- **Cream + Dark Brown**: Classic ACNH combination
- **Orange + Cream**: Active/inactive states
- **Teal + Cream**: Alternate accent scheme

### Tonal Progressions
**Brown Scale** (light to dark):
1. `(209, 198, 153)` - Light tan
2. `(138, 123, 102)` - Medium brown
3. `(136, 91, 36)` - Brown border
4. `(133, 90, 37)` - Dark brown text
5. `(76, 60, 51)` - Darker brown

**Cream Scale** (light to dark):
1. `(254, 251, 233)` - Lightest cream
2. `(255, 251, 231)` - Primary cream
3. `(248, 244, 232)` - Off-white
4. `(231, 221, 185)` - Tan

---

## Notes & Observations

### Color Value Format
- Roblox XML stores colors as **decimal 0-1 range**
- Convert to byte (0-255) by multiplying by 255
- Some files had malformed values (e.g., `255.0` instead of `1.0`)

### BorderSizePixel Usage
- **78 occurrences of black borders** but most have `BorderSizePixel=0`
- Modern approach: Use UIStroke instead of borders
- Reference files follow this pattern extensively

### Consistency Across Files
- Cream background `(255, 251, 231)` is consistent
- Dark brown text `(133, 90, 37)` is the standard
- Orange accent `(253, 147, 3)` appears in all interactive elements

### Special Cases
- **DialogueGUI**: Uses purple stroke `(151, 71, 255)` - dialogue-specific
- **Stars/Ratings**: Gold/yellow `(250, 209, 43)` or `(245, 186, 0)`
- **NookPhone**: Additional orange variations for branding

---

## File Analysis Summary

### Successfully Analyzed
- ✅ InventoryGUI.rbxmx
- ✅ starterGUI(as-of-10.26).rbxmx
- ✅ DialogueGUI.rbxmx
- ✅ RecipesInventory.rbxmx
- ✅ ACNH-fx.rbxmx (no colors)
- ✅ TomNook.rbxmx (minimal - 1 white color)
- ✅ sza.rbxmx (no colors)

### Could Not Parse (Binary Format)
- ❌ NookPhoneGUI.rbxm (binary)
- ❌ NookShoppingGUI.rbxm (binary)

---

## Conclusion

The ACNH color palette is remarkably consistent across all reference files:

**Core Palette**:
- 🟡 Cream background `(255, 251, 231)`
- 🟤 Dark brown text `(133, 90, 37)`
- 🟠 Orange accent `(253, 147, 3)`
- ⚫ Black borders (mostly invisible)
- ⚪ White icons

This palette creates the warm, friendly, approachable aesthetic that defines Animal Crossing's UI. Always reference these exact values for authentic ACNH styling.

**Current Project Colors** (from copilot-instructions.md):
- Cream/beige backgrounds: `Color3.fromRGB(255, 251, 231)` ✅ CORRECT
- Brown titles: `Color3.fromRGB(120, 100, 80)` ❌ Should be `(133, 90, 37)`
- Teal accents: `Color3.fromRGB(4, 175, 166)` ⚠️ Reference uses `(130, 213, 187)`

**Recommended Updates**:
1. Update brown title color to `(133, 90, 37)` for authenticity
2. Consider using orange `(253, 147, 3)` as primary accent instead of teal
3. Use teal `(130, 213, 187)` sparingly for alternate interactions
