# Responsive UI Guide

This document explains the cross-platform responsive UI system implemented for the ACNH Roblox game.

## Overview

The UI has been updated to work seamlessly across:
- **Desktop** (PC/Mac with mouse & keyboard)
- **Mobile** (Phones & tablets with touch)
- **Console** (Xbox, PlayStation with gamepad)

## Key Changes

### 1. Scale-Based Sizing

All major UI elements now use `UDim2.fromScale()` instead of fixed pixel sizes:

```lua
-- Before (fixed pixels)
headerFrame.Size = UDim2.new(0, 400, 0, 60)

-- After (scale-based with constraints)
headerFrame.Size = UDim2.fromScale(0.3, 0.08)
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(300, 50)
sizeConstraint.MaxSize = Vector2.new(500, 80)
```

### 2. Size Constraints

Every UI panel now has min/max size constraints to ensure readability:

| UI Element | Min Size (Mobile) | Max Size (Desktop) |
|------------|------------------|-------------------|
| Island Header | 300×50 | 500×80 |
| Clock Widget | 200×100 | 350×150 |
| Bells Display | 140×50 | 220×80 |
| Miles Display | 140×50 | 220×80 |
| Quest Board | 500×400 | 900×650 |
| Dialogue Panel | 400×120 | 800×200 |

### 3. Text Size Constraints

All scaled text now has `UITextSizeConstraint` to maintain readability:

```lua
islandLabel.TextScaled = true
local textConstraint = Instance.new("UITextSizeConstraint")
textConstraint.MaxTextSize = 28
textConstraint.MinTextSize = 14
```

### 4. ResponsiveUI Utility Module

A new shared module provides helper functions for responsive design:

**Location:** `src/shared/ResponsiveUI.luau`

**Key Functions:**
- `getDeviceType()` - Detect Mobile/Console/Desktop
- `getScreenInsets()` - Get safe areas (avoiding notches)
- `responsiveSize()` - Calculate size based on viewport
- `safePosition()` - Position within safe areas
- `addConstraints()` - Add size/aspect ratio constraints
- `createMobileButton()` - Create touch-friendly buttons (88×88 minimum)

## Responsive Breakpoints

The UI adapts based on viewport width:

- **Mobile Portrait**: < 768px width
  - Single column layouts
  - Larger touch targets (88×88)
  - Bottom-anchored UI
  
- **Mobile Landscape / Tablet**: 768px - 1280px width
  - Two-column layouts where appropriate
  - Medium-sized UI elements
  
- **Desktop**: > 1280px width
  - Multi-column layouts
  - Maximum size constraints applied
  - Optimized for mouse precision

## Touch-Friendly Design

### Button Sizes
All interactive elements meet minimum touch target size:
- **Minimum**: 88×88 pixels (iOS/Android guidelines)
- **Optimal**: 110×110 pixels for primary actions

### Spacing
- Minimum 16px padding between touch targets
- 20px safe area margins from screen edges

### Feedback
- `AutoButtonColor = true` for visual feedback
- Haptic feedback on mobile (when available)

## Testing Checklist

When testing UI changes, verify on:

1. **Desktop (PC/Mac)**
   - [ ] 1920×1080 (Full HD)
   - [ ] 2560×1440 (2K)
   - [ ] 3840×2160 (4K)

2. **Mobile Phones**
   - [ ] 375×667 (iPhone SE)
   - [ ] 390×844 (iPhone 13)
   - [ ] 414×896 (iPhone 11 Pro Max)
   - [ ] 360×640 (Android Small)

3. **Tablets**
   - [ ] 768×1024 (iPad)
   - [ ] 1024×1366 (iPad Pro)
   - [ ] 800×1280 (Android Tablet)

4. **Console**
   - [ ] 1920×1080 (Xbox/PlayStation)
   - [ ] Gamepad navigation works
   - [ ] Safe area respected (TV overscan)

## Best Practices

### DO ✅
- Use `UDim2.fromScale()` for primary sizing
- Always add `UISizeConstraint` with min/max values
- Use `TextScaled = true` with `UITextSizeConstraint`
- Test on multiple device sizes
- Keep touch targets >= 88×88
- Use safe area insets for screen edges

### DON'T ❌
- Don't use fixed pixel sizes without constraints
- Don't assume specific screen dimensions
- Don't place UI too close to screen edges
- Don't make text smaller than 12px
- Don't ignore device type differences

## Example: Creating a Responsive Panel

```lua
local ResponsiveUI = require(ReplicatedStorage.Shared.ResponsiveUI)

-- Create frame with scale-based size
local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.5, 0.3)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)

-- Add size constraints
ResponsiveUI.addConstraints(panel, {
    minSize = Vector2.new(400, 250),
    maxSize = Vector2.new(800, 500),
    aspectRatio = 16/9
})

-- Create responsive text
local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(1, 0.2)
title.TextScaled = true
title.Parent = panel

ResponsiveUI.addConstraints(title, {
    textScaled = true
})
```

## Platform-Specific Adaptations

### Mobile
- Larger UI elements (1.2x scale)
- Bottom-anchored controls
- Swipe gestures where appropriate
- Auto-hide keyboard when tapping UI

### Console
- D-pad/analog stick navigation
- Button prompts (A, B, X, Y)
- Highlight selected UI element
- Larger cursor/selection indicators

### Desktop
- Keyboard shortcuts displayed
- Hover effects
- Precise mouse targeting
- Efficient use of screen space

## Future Enhancements

Planned improvements:
1. Dynamic font scaling based on device DPI
2. Landscape/portrait orientation detection
3. Gamepad UI selection system
4. Voice chat UI for console/mobile
5. Accessibility options (high contrast, large text)

## Resources

- [Roblox UI Best Practices](https://create.roblox.com/docs/ui/best-practices)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design Touch Targets](https://material.io/design/usability/accessibility.html#layout-and-typography)
- [Xbox UI Guidelines](https://docs.microsoft.com/en-us/gaming/xbox-live/features/general/ui-guidelines/)

---

**Last Updated:** January 2025
**Version:** 1.0
