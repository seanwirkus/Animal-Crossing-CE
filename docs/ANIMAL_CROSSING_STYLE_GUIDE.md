inra# 🎨 Animal Crossing Style Guide

## Overview
This comprehensive style guide ensures all GUI elements in Animal Crossing CE maintain the cozy, warm, and inviting aesthetic of the Animal Crossing: New Horizons game. Every visual component should feel like it belongs in the same universe.

## 🎯 Core Principles

### 1. **Cozy & Warm Atmosphere**
- **Target Vibe**: Playful, handmade, slightly chunky UI with soft colors and rounded corners
- **Avoid**: Flat corporate SaaS style, harsh neon gamer aesthetics
- **Inspiration**: Handcrafted wooden signs, soft pastel palettes, gentle animations

### 2. **Consistent Visual Language**
- All surfaces use large border radius (20-36px)
- Thick borders (2-3px) mimic AC's chunky dialog boards
- Subtle drop shadows with brown/black tints
- Friendly sans-serif typography (Gotham font family)

---

## 🎨 Color Palette (Updated from Reference RBXMX Files)

### Primary Backgrounds
- **ACNH Cream**: `#FFFBE7` / `Color3.fromRGB(255, 251, 231)` - **PRIMARY** background (6 uses in reference)
- **Tan Background**: `#E7DDB9` / `Color3.fromRGB(231, 221, 185)` - Content sections, secondary backgrounds
- **Off-White**: `#FCFAF2` - Alternative dialog backgrounds
- **White**: `#FFFFFF` / `Color3.fromRGB(255, 255, 255)` - Icons, clean accents (73 uses)

### ACNH Authentic Browns & Text
- **ACNH Dark Brown**: `#855A25` / `Color3.fromRGB(133, 90, 37)` - **PRIMARY TEXT** (20 uses in reference files) ⭐
- **Darker Brown**: `#4C3C33` / `Color3.fromRGB(76, 60, 51)` - Emphasis text
- **Light Tan Text**: `#D1C699` / `Color3.fromRGB(209, 198, 153)` - Labels, secondary text (10 uses)
- **Pure Black**: `#000000` / `Color3.fromRGB(0, 0, 0)` - Borders, strokes (78 uses)

### ACNH Authentic Accents
- **ACNH Orange**: `#FD9303` / `Color3.fromRGB(253, 147, 3)` - **PRIMARY ACCENT** (15 uses - buttons, highlights) ⭐
- **ACNH Teal**: `#82D5BB` / `Color3.fromRGB(130, 213, 187)` - Selected states (4 uses)
- **ACNH Yellow/Gold**: `#FAD12B` / `Color3.fromRGB(250, 209, 43)` - Stars, special indicators

### Nature & UI Elements
- **Leaf Green**: `#9CCC65` / `Color3.fromRGB(156, 204, 101)` - Success states
- **Sky Blue**: `#81D4FA` - Progress indicators
- **Notification Red**: `#F44336` - Errors, warnings

### Debug/Development Colors
- **Dark Grey**: `#282828` / `Color3.fromRGB(40, 40, 40)` - Debug GUI backgrounds (to be replaced with ACNH cream)
- **Medium Grey**: `#646464` / `Color3.fromRGB(100, 100, 100)` - Debug scrollbars (to be replaced with brown)

---

## 📐 Spacing & Layout

### Spacing Scale (Pixels)
- **xs**: 4px - Tight spacing
- **sm**: 8px - Small gaps
- **md**: 12px - Standard gaps
- **lg**: 16px - Large gaps
- **xl**: 24px - Extra large gaps
- **xxl**: 32px - Maximum gaps

### Layout Principles
- **Centered Content**: Main panels centered on screen
- **Generous Whitespace**: Ample padding around content
- **Predictable Alignment**: Text and controls align on consistent axes
- **Responsive Design**: Scales appropriately across screen sizes

---

## 🔘 Border Radius

### Size Categories
- **Small**: 8px - Small elements (buttons, badges)
- **Medium**: 16px - Standard elements (cards, inputs)
- **Large**: 24px - Main panels, dialogs
- **X-Large**: 32px - Large containers
- **XX-Large**: 36px - Special elements, hero content

---

## 🌟 Shadows

### Shadow Types
- **Small**: 0px 2px 4px with 30% brown/black tint
- **Medium**: 0px 4px 8px with 25% brown/black tint
- **Large**: 0px 6px 12px with 20% brown/black tint

---

## 📝 Typography

### Font Family
- **Primary**: Gotham (main UI font)
- **Secondary**: Gotham Medium (medium weight)
- **Bold**: Gotham Bold (strong emphasis)
- **Black**: Gotham Black (maximum emphasis)

### Text Sizes
- **xsmall**: 12px - Small labels
- **small**: 14px - Body text minimum
- **medium**: 16px - Standard body text
- **large**: 18px - Large body text
- **xlarge**: 20px - Subtitles
- **xxlarge**: 24px - Titles
- **xxxlarge**: 32px - Hero text

### Text Treatment
- **Subtle Stroke**: 80% transparency white stroke for readability
- **No All-Caps**: Prefer Title Case or Sentence case
- **Friendly Tone**: Warm, approachable language

---

## 🎮 Interactive Elements

### Button States
All buttons must have these states:
- **Default**: Soft background, gentle outline
- **Hover**: Slightly brighter/darker tint, subtle scale
- **Pressed**: Darker tint, inner shadow effect
- **Disabled**: Lower opacity, reduced contrast

### Primary Buttons (AC Dialog Choices)
- Background: Button Brown (`#795548`)
- Text: Light (`#FFFFFF`)
- Corner Radius: Medium (16px)
- Hover: Lighter brown tint
- Pressed: Darker brown tint

### Secondary Buttons
- Background: Eggshell (`#F0EDE4`)
- Border: Button Brown (`#795548`) 2px
- Text: Button Brown (`#795548`)
- Corner Radius: Medium (16px)
- Hover: Cream background
- Pressed: Warm Yellow background

### Close Buttons
- Background: Notification Red (`#F44336`)
- Text: Light (`#FFFFFF`) "✕"
- Size: 32x32px
- Corner Radius: Small (8px)
- Hover: Darker red
- Pressed: Even darker red

---

## 📋 Component Guidelines

### Dialog Panels
- **Background**: Off-White with 5% transparency
- **Border**: Bell Gold, 3px thickness
- **Corner Radius**: Large (24px)
- **Shadow**: Large with brown tint
- **Padding**: Generous internal spacing

### Loading Screens
- **Background**: Sky Blue gradient
- **Progress Bars**: Sky Blue fill on Eggshell background
- **Corner Radius**: Medium (16px)
- **Animations**: Slow, relaxing (3-8 second cycles)
- **Tips**: Display in cozy rounded containers

### HUD Elements
- **Background**: Eggshell with Light Brown borders
- **Corner Radius**: Medium (16px)
- **Shadow**: Small with brown tint
- **Positioning**: Edges of screen, non-intrusive

### Toast Notifications
- **Background**: Eggshell
- **Border**: Light Brown, 2px
- **Corner Radius**: Medium (16px)
- **Shadow**: Medium with brown tint
- **Animation**: Slide in/out from screen edges

### Inventory Panel Reference (from `InventoryGUI.rbxmx`)
- **Root Frame (`InventoryFrame`)**: Centered container sized at 75% width × 50% height, background `Color3.fromRGB(255, 251, 231)` with a large 25% `UICorner` for the softened silhouette; side padding handled by outer `UIPadding` (10% left/right) to keep the panel floating inside the safe area.
- **Items Region (`InventoryItems`)**: Full-size transparent frame hosting the slot grid; inner padding is `15%` on all sides ensuring generous breathing room before the slots begin.
- **Slot Template (`ItemSlotTemplate`)**: Square 100×100px base with background `Color3.fromRGB(238, 226, 204)` (`#EEE2CC`), zero border, full (`1, 0`) `UICorner` for circular slots, and internal `ItemIcon` image sized to fill. Item counts live in a `TextLabel` anchored bottom-right (`Position = UDim2.new(1, 0, 1, 0)`, `TextXAlignment = Right`) with white stroke for readability.
- **Slot Layout (`UIGridLayout`)**: `CellSize = UDim2.new(0, 36, 0, 36)` and `CellPadding = UDim2.new(0, 25, 0, 25)`, `FillDirectionMaxCells = 10` to enforce a single 10-slot row. Start corner from top-left, horizontal alignment left, behavior matches the classic ACNH strip of icons.
- **Stats Bar (`StatsBar`)**: Sits under the slot region inside the same container. Contains two angled frames: `MilesCount` (teal `Color3.fromRGB(130, 213, 187)`, rotation 3°) and `BellsCount` (golden `Color3.fromRGB(190, 167, 69)`, rotation 3°). Each frame has a white `UIStroke` (3px) plus `UICorner` (full round). Labels use SourceSansPro Bold at 36px with `TextXAlignment = Right` and white text.
- **Currency Icons**: Each stats frame has an `ImageLabel` (Nook Miles badge `rbxassetid://102758508019146`, Bells bag `rbxassetid://95347480098172`) pinned near the left edge with transparent backgrounds. Keep the images roughly 50×49px and let them overlap the frames slightly for the playful look.
- **Layout Manager (`UIListLayout` inside Stats)**: Horizontal alignment centered, zero padding, ensuring Miles and Bells cards sit side-by-side while respecting their rotations.

### Speaker Name Tags (Dialog)
- **Background**: Warm Yellow
- **Text**: Button Brown
- **Corner Radius**: Small (8px)
- **Shadow**: Small with brown tint
- **Position**: Overlapping dialog top border

---

## 🎬 Animation Guidelines

### Timing
- **Slow & Relaxing**: 0.3-0.5 seconds for state changes
- **No Jittery Motion**: Smooth easing curves (Back, Quad, Cubic)
- **Consistent Pacing**: All similar interactions use same timing

### Loading Animations
- **Plane Flight**: 8-second loop with banking and bobbing
- **Progress Bars**: Smooth fill animation
- **Button States**: 0.15-0.2 second transitions

### Screen Transitions
- **Fade In**: 0.35 seconds with Back easing
- **Fade Out**: 0.25 seconds with Quad easing
- **Panel Entry**: Scale + fade with Back easing

---

## 📱 Responsive Design

### Breakpoints
- **Mobile**: < 760px width
- **Tablet**: 760-1180px width
- **Desktop**: > 1180px width

### Scaling Rules
- **Text**: Maintains readability, scales with container
- **Spacing**: Proportional to screen size
- **Touch Targets**: Minimum 44px on mobile
- **Layout**: Reflows appropriately for screen size

---

## ✅ Quality Checklist

Before finalizing any GUI:

### Visual Consistency
- [ ] Colors from approved palette only
- [ ] Border radius follows size guidelines
- [ ] Shadows use correct brown/black tints
- [ ] Typography matches specifications

### Interactive Elements
- [ ] All buttons have hover/press/disabled states
- [ ] Close buttons are consistently styled
- [ ] Focus states are clearly indicated
- [ ] Touch targets meet minimum sizes

### Performance
- [ ] Animations don't cause layout thrashing
- [ ] No heavy particle effects or high-frequency animations
- [ ] Efficient rendering (avoid excessive DOM depth)

### Accessibility
- [ ] Sufficient color contrast ratios
- [ ] Text remains readable at all sizes
- [ ] Interactive elements are clearly distinguishable
- [ ] Keyboard navigation supported where applicable

### AC Feel
- [ ] Does this feel like it belongs in Animal Crossing?
- [ ] Warm, inviting, and cozy atmosphere maintained?
- [ ] Animations feel gentle and relaxing?
- [ ] Overall aesthetic matches the game's visual language?

---

## 🔧 Implementation

### Theme System
All styling is centralized in `src/client/Modules/Theme.lua` and accessed via `ThemeProvider.lua`. Use these utilities:

```lua
local ThemeProvider = require(script.Parent.ThemeProvider)

-- Get colors
local backgroundColor = ThemeProvider.getColor("offWhite")

-- Apply styling
ThemeProvider.styleFrame(frame, {
    backgroundColor = "eggshell",
    cornerRadius = "large",
    shadow = "medium"
})

-- Create themed components
local dialogPanel = ThemeProvider.createDialogPanel(parent)
local primaryButton = ThemeProvider.createPrimaryButton(parent, "Continue")
local closeButton = ThemeProvider.createCloseButton(parent)
```

### Documentation Integration
Reference this style guide in all relevant MD files:
- GUI component documentation
- Implementation guides
- Design decision documentation

---

## 📚 References

- **Animal Crossing: New Horizons** - Primary visual inspiration
- **Material Design** - Touch target guidelines
- **iOS Human Interface Guidelines** - Responsive design principles
- **WCAG 2.1** - Accessibility standards

---

*This style guide ensures every GUI element in Animal Crossing CE feels like a natural part of the game's warm, welcoming world. All new UI components must adhere to these guidelines, and existing components should be updated to match.*
