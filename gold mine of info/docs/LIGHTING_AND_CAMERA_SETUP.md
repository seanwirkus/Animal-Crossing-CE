# 🎨 Animal Crossing Lighting & Camera Setup

## Overview

Recreate the **warm, dreamy, cozy visual style** of Animal Crossing: New Horizons with proper FOV, shaders, and atmospheric effects.

---

## 🎮 Quick Setup (Copy-Paste Method)

### Step 1: Open Roblox Studio
1. Open your ACNH Roblox place
2. Go to **StarterPlayer** → **StarterCharacterScripts**
3. Right-click → **Insert Object** → **LocalScript**
4. Name it "ACNHLightingScript"

### Step 2: Copy the Script
1. Open the file: `ACNH_LIGHTING_SCRIPT.lua`
2. **Copy ALL the code** (Cmd+A, Cmd+C)
3. **Paste into the LocalScript** in Studio
4. **Run the game** (F5)

### Step 3: Enjoy!
You should immediately see:
- Warmer, dreamier lighting
- Soft shadows
- Bloom glow on bright objects
- Proper camera angle
- Cozy atmosphere

---

## 🎨 Visual Features

### Camera Settings
- **FOV: 70°** - Wider field of view like AC:NH
- **Distance: 10-20 studs** - Closer for intimacy
- **Angle: Slight top-down** - Camera offset +2.5Y
- **Smooth following** - Natural character tracking

### Lighting (Warm & Dreamy)
- **Ambient:** Soft blue-gray (150, 170, 180)
- **Outdoor Ambient:** Bright warm (200, 210, 220)
- **Brightness: 2.5** - Cheerful and inviting
- **Color Shift:**
  - Bottom (ground): Warm reflection (200, 180, 160)
  - Top (sky): Cool tint (200, 220, 255)
- **Exposure: +0.3** - Slightly overexposed for dreamy feel
- **Soft shadows** - ShadowSoftness 0.5

### Atmospheric Effects

#### 1. Bloom Effect ✨
- Creates soft glow around bright objects
- Intensity: 1.0
- Size: 24 (wide spread)
- Threshold: 0.8 (only bright objects)
- **Result:** Dreamy, magical feel

#### 2. Color Correction 🎨
- Saturation: +0.2 (more vivid colors)
- Contrast: +0.1 (soft contrast)
- Tint: Warm cream (255, 250, 245)
- Brightness: +0.1
- **Result:** Warm, inviting tones

#### 3. Sun Rays ☀️
- God rays through trees
- Intensity: 0.2 (subtle)
- Spread: 0.1 (tight beams)
- **Result:** Magical forest feel

#### 4. Depth of Field 📷
- Focus Distance: 25 studs
- In-Focus Radius: 20 studs
- Near Blur: 0.2 (subtle)
- Far Blur: 0.4 (soft background)
- **Result:** Cinematic, dreamy blur

#### 5. Atmosphere 🌫️
- Density: 0.3 (light, airy)
- Color: Light blue sky (199, 220, 255)
- Decay: Soft blue horizon (106, 142, 192)
- Glare: 0.5 (sun glare)
- Haze: 1.5 (soft horizon)
- **Result:** Beautiful sky gradient

#### 6. Sky ☁️
- Sun Angular Size: 15 (larger sun)
- Moon Angular Size: 11
- Star Count: 3000 (beautiful nights)
- Celestial Bodies: Shown
- **Result:** Realistic day/night cycle

---

## 🌅 Dynamic Lighting (Time of Day)

### Sunrise/Sunset (Golden Hour)
- **Ambient:** Warm orange (255, 180, 120)
- **Outdoor:** Golden (255, 160, 100)
- **Brightness:** 2.0
- **Sun Rays:** 0.25 intensity
- **Feel:** Warm, romantic, cozy

### Daytime (Cheerful)
- **Ambient:** Soft blue-gray (150, 170, 180)
- **Outdoor:** Bright warm (200, 210, 220)
- **Brightness:** 2.5
- **Sun Rays:** 0.2 intensity
- **Feel:** Bright, inviting, energetic

### Nighttime (Calm)
- **Ambient:** Cool blue (80, 90, 120)
- **Outdoor:** Dark blue (60, 70, 100)
- **Brightness:** 0.8
- **Sun Rays:** 0 (no sun)
- **Feel:** Calm, peaceful, stars visible

### Transitions
- **Duration:** 3 seconds
- **Easing:** Sine InOut (smooth)
- **All effects:** Tween smoothly between states

---

## 🎯 Comparison: Before vs After

### Before (Default Roblox):
- Harsh white lighting
- Strong shadows
- Flat colors
- No atmosphere
- Standard FOV (70 but feels different)
- Cold, clinical feel

### After (AC:NH Style):
- Warm, soft lighting ☀️
- Gentle shadows
- Saturated, vivid colors 🎨
- Dreamy bloom and blur ✨
- Proper AC camera angle 📷
- Cozy, inviting atmosphere 🏝️

---

## 🔧 Advanced Customization

### Make It Even Warmer:
```lua
-- In the script, change:
colorCorrection.TintColor = Color3.fromRGB(255, 240, 220)  -- More orange
Lighting.ColorShift_Bottom = Color3.fromRGB(255, 200, 150)  -- Warmer ground
```

### Make It More Dreamy (More Bloom):
```lua
-- In the script, change:
bloom.Intensity = 1.5  -- Stronger glow (was 1.0)
bloom.Threshold = 0.6  -- More objects glow (was 0.8)
```

### Stronger Depth of Field (Blur):
```lua
-- In the script, change:
depthOfField.FarIntensity = 0.7  -- More background blur (was 0.4)
depthOfField.NearIntensity = 0.4  -- More foreground blur (was 0.2)
```

### Adjust Camera Distance:
```lua
-- In the script, change:
player.CameraMaxZoomDistance = 25  -- Further out (was 20)
player.CameraMinZoomDistance = 5  -- Closer in (was 10)
```

---

## 📋 Complete Settings Reference

```lua
-- CAMERA
FieldOfView = 70
MaxZoomDistance = 20
MinZoomDistance = 10
CameraOffset = Vector3.new(0, 2.5, 0)

-- LIGHTING
Ambient = Color3.fromRGB(150, 170, 180)
OutdoorAmbient = Color3.fromRGB(200, 210, 220)
Brightness = 2.5
ColorShift_Bottom = Color3.fromRGB(200, 180, 160)
ColorShift_Top = Color3.fromRGB(200, 220, 255)
ExposureCompensation = 0.3
GlobalShadows = true
Technology = ShadowMap
ShadowSoftness = 0.5
ClockTime = 14 (2 PM)
GeographicLatitude = 0

-- BLOOM
Intensity = 1.0
Size = 24
Threshold = 0.8

-- COLOR CORRECTION
Saturation = 0.2
Contrast = 0.1
TintColor = Color3.fromRGB(255, 250, 245)
Brightness = 0.1

-- SUN RAYS
Intensity = 0.2
Spread = 0.1

-- DEPTH OF FIELD
FocusDistance = 25
InFocusRadius = 20
NearIntensity = 0.2
FarIntensity = 0.4

-- ATMOSPHERE
Density = 0.3
Offset = 0.5
Color = Color3.fromRGB(199, 220, 255)
Decay = Color3.fromRGB(106, 142, 192)
Glare = 0.5
Haze = 1.5

-- SKY
SunAngularSize = 15
MoonAngularSize = 11
StarCount = 3000
```

---

## 🎬 Time-Specific Presets

### Perfect for Screenshots:

**Golden Hour (Sunset):**
```lua
Lighting.ClockTime = 17.5  -- 5:30 PM
-- Warm orange tones, long shadows, beautiful!
```

**Midday (Bright & Cheerful):**
```lua
Lighting.ClockTime = 12  -- Noon
-- Maximum brightness, perfect for showing off builds
```

**Blue Hour (Dusk):**
```lua
Lighting.ClockTime = 19  -- 7 PM
-- Cool blue tones, stars starting to appear
```

**Starry Night:**
```lua
Lighting.ClockTime = 23  -- 11 PM
-- Dark with 3000 visible stars, magical!
```

---

## 🌈 Color Palette (AC:NH Official Colors)

### Primary Colors:
- **Grass Green:** RGB(124, 180, 76)
- **Sky Blue:** RGB(199, 220, 255)
- **Sand Beige:** RGB(255, 224, 153)
- **Wood Brown:** RGB(101, 67, 33)
- **Water Blue:** RGB(100, 150, 255)

### Accent Colors:
- **Sunset Orange:** RGB(255, 160, 100)
- **Leaf Green:** RGB(150, 180, 140)
- **Bell Gold:** RGB(255, 200, 50)
- **Cream:** RGB(250, 245, 235)

---

## ✅ Checklist

After applying the script, you should see:

- ✅ Warmer overall lighting (less harsh)
- ✅ Soft, blurry background (depth of field)
- ✅ Glowing effect on bright objects (bloom)
- ✅ More saturated, vivid colors
- ✅ Softer shadows (not pitch black)
- ✅ Beautiful sky gradient
- ✅ Sun rays through trees
- ✅ Proper camera angle (slight top-down)
- ✅ Cozy, inviting atmosphere
- ✅ Looks like Animal Crossing! 🏝️

---

## 🚀 Testing

1. Run game with script applied
2. Walk around your island
3. Notice the soft, warm lighting
4. Look at the sky - see the gradient
5. Look at bright objects - see the glow
6. Look into distance - see soft blur
7. Watch sunset (change ClockTime to 17-19)
8. See golden orange warmth!

---

## 📊 Performance Notes

All effects are **optimized** for Roblox:
- Bloom: Low performance impact
- Color Correction: Negligible impact
- Atmosphere: Built-in, optimized
- Depth of Field: Slight impact (can disable if needed)
- Sun Rays: Low impact

**Recommended for:** All devices (mobile, PC, console)

---

## Status

✅ **COMPLETE AND READY TO USE**

Copy `ACNH_LIGHTING_SCRIPT.lua` into a LocalScript in StarterCharacterScripts and you're done! Instant Animal Crossing visual style! 🎨

**Implementation Date:** October 22, 2025  
**Based on:** AC:NH visual reference  
**Effects Used:** 6 (Bloom, Color Correction, Sun Rays, DOF, Atmosphere, Sky)

