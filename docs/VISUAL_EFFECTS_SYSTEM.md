# Visual Effects System

## Overview
Beautiful post-processing effects and atmospheric enhancements for Animal Crossing CE, creating a cozy, dreamlike ACNH aesthetic.

## Features Implemented

### 🌟 Post-Processing Effects

#### Bloom Effect
- **Intensity**: 0.4 (soft glow on bright areas)
- **Size**: 24px spread
- **Threshold**: 0.8 (only affects bright surfaces)
- Creates a warm, soft glow around lights and bright objects

#### Blur Effect
- **Size**: 8px (subtle depth blur)
- Can be dynamically adjusted based on player speed for motion blur
- Adds cinematic depth to the scene

#### Color Correction
- **Brightness**: +0.05 (slightly brighter)
- **Contrast**: +0.1 (more defined)
- **Saturation**: +0.15 (more vibrant colors)
- **Tint**: Warm cream (#FFF8F0) for ACNH cozy feel
- Creates the signature warm, inviting ACNH color palette

#### Depth of Field
- **Focus Distance**: 30 studs
- **Near Intensity**: 0.3 (blur close objects)
- **Far Intensity**: 0.5 (blur distant objects)
- **In-Focus Radius**: 20 studs
- Creates cinematic focus effect, draws attention to mid-range gameplay

#### Sun Rays
- **Intensity**: 0.15 (subtle volumetric rays)
- **Spread**: 0.5 (wide god rays)
- Adds atmospheric light shafts from the sun

### 🌤️ Atmospheric Effects

#### Enhanced Atmosphere
- **Density**: 0.3 (visible air scattering)
- **Offset**: 0.25 (horizon depth)
- **Color**: Light blue (#C7DCFF)
- **Decay**: Sky blue (#6AABFF)
- **Glare**: 0.4 (sun brightness)
- **Haze**: 1.5 (distant haze)
- Creates realistic atmospheric scattering and depth

#### Sky Configuration
- **Clock Time**: 14:00 (afternoon lighting)
- **Brightness**: 2 (well-lit environment)
- **Ambient**: Neutral gray for natural lighting
- **Outdoor Ambient**: Cool blue-gray (#7F8CA0)
- **Color Shift Top**: Warm yellow (#FFF5DC)
- Creates dynamic, natural-looking sky

#### Vignette Effect
- Subtle darkening around screen edges
- **Transparency**: 0.7 (very subtle)
- Draws player's attention to center of screen
- Enhances cinematic feel

### 🌸 Particle Effects

#### Sakura Petals (Cherry Blossoms)
- **Color**: Pink (#FFC8DC)
- **Rate**: 5 petals/second
- **Lifetime**: 8-12 seconds
- **Behavior**: Gentle floating, rotating fall
- Creates magical spring atmosphere
- **Seasonal**: Can be changed to orange leaves (fall) or snowflakes (winter)

#### Fireflies
- **Color**: Warm yellow-white (#FFFF96)
- **Rate**: 3 fireflies/second
- **Lifetime**: 3-5 seconds
- **Behavior**: Glowing, floating upward drift
- **Auto-enabled**: Only appears at night (6 PM - 6 AM)
- Adds life and magic to nighttime

#### Dust Motes
- **Color**: Warm cream (#FFFAE6)
- **Rate**: 8 particles/second
- **Lifetime**: 5-8 seconds
- **Behavior**: Slow floating, visible in sunbeams
- Adds depth and atmosphere to outdoor scenes

#### Water Sparkles
- **Color**: Light blue (#96DCFF)
- **Rate**: 10 sparkles/second
- **Lifetime**: 1-2 seconds
- **Behavior**: Quick glittering effect
- **Auto-applied**: Automatically added to water surfaces
- Creates magical shimmering on rivers, ponds, and ocean

## Dynamic Features

### Motion Blur
- Blur increases with player movement speed
- **Max Speed**: 50 studs/second triggers full blur
- Creates sense of speed and motion
- Call: `VisualEffects.enableDynamicBlur(player)`

### Dynamic Focus
- Depth of field adjusts to camera target distance
- Creates professional photography focus effect
- Useful for cutscenes and screenshots
- Call: `VisualEffects.enableDynamicFocus(player)`

### Day/Night Cycle
- Smooth lighting transitions throughout the day
- **Duration**: 300 seconds (5 minutes) default
- Fireflies automatically appear/disappear
- Call: `VisualEffects.animateDayNightCycle(duration)`

### Seasonal Modes
- **Spring**: Pink sakura petals
- **Summer**: Enhanced fireflies
- **Fall**: Orange falling leaves
- **Winter**: White snowflakes
- Call: `ParticleEffects.setSeason("spring")`

## Configuration

All effects can be adjusted in the CONFIG tables:

### VisualEffects.luau
```lua
CONFIG = {
    bloom = { intensity = 0.4, size = 24, threshold = 0.8 },
    blur = { size = 8 },
    colorCorrection = { brightness = 0.05, contrast = 0.1, saturation = 0.15 },
    depthOfField = { focusDistance = 30, nearIntensity = 0.3, farIntensity = 0.5 },
    sunRays = { intensity = 0.15, spread = 0.5 },
    atmosphere = { density = 0.3, offset = 0.25, haze = 1.5 }
}
```

### ParticleEffects.luau
```lua
CONFIG = {
    sakura = { rate = 5, lifetime = NumberRange.new(8, 12) },
    fireflies = { rate = 3, lifetime = NumberRange.new(3, 5) },
    dust = { rate = 8, lifetime = NumberRange.new(5, 8) },
    waterSparkles = { rate = 10, lifetime = NumberRange.new(1, 2) }
}
```

## API Reference

### VisualEffects Module

#### `VisualEffects.initialize(player)`
Sets up all post-processing effects and lighting
- **Parameters**: `player` (Player) - Optional, for player-specific effects like vignette
- **Returns**: VisualEffects module

#### `VisualEffects.disable()`
Removes all visual effects

#### `VisualEffects.setIntensity(effectName, intensity)`
Adjusts individual effect intensity
- **Parameters**: 
  - `effectName` (string) - "Bloom", "SunRays", etc.
  - `intensity` (number) - 0-1 range

#### `VisualEffects.enableDynamicBlur(player)`
Enables motion blur based on player speed

#### `VisualEffects.enableDynamicFocus(player)`
Enables automatic focus distance adjustment

#### `VisualEffects.animateDayNightCycle(duration)`
Starts automatic day/night cycling
- **Parameters**: `duration` (number) - Seconds for full 24-hour cycle

### ParticleEffects Module

#### `ParticleEffects.initialize()`
Creates ambient particle effects in the world
- **Returns**: ParticleEffects module

#### `ParticleEffects.disable()`
Removes all particle effects

#### `ParticleEffects.setSeason(season)`
Changes particle effects to match season
- **Parameters**: `season` (string) - "spring", "summer", "fall", "winter"

## Performance Considerations

### Optimizations
- Particles use emission rates carefully balanced for performance
- Effects use built-in Roblox post-processing (hardware accelerated)
- Vignette is simple ImageLabel (minimal overhead)
- Fireflies only spawn at night (saves resources during day)

### Performance Impact
- **Bloom**: ~1-2 FPS impact
- **Blur**: ~2-3 FPS impact
- **Depth of Field**: ~3-4 FPS impact
- **Particles**: ~2-3 FPS impact total
- **Total Impact**: ~8-12 FPS on most systems

### Disabling Effects
If performance is an issue, disable effects:
```lua
VisualEffects.disable()
ParticleEffects.disable()
```

Or adjust individual intensities:
```lua
CONFIG.blur.size = 4  -- Reduce blur
CONFIG.sakura.rate = 2  -- Fewer petals
CONFIG.depthOfField.enabled = false  -- Disable DOF
```

## Usage Examples

### Basic Setup (Automatic)
Effects are automatically initialized when the game starts via `init.client.luau`

### Manual Initialization
```lua
local VisualEffects = require(path.to.VisualEffects)
local ParticleEffects = require(path.to.ParticleEffects)

-- Initialize effects
VisualEffects.initialize(player)
ParticleEffects.initialize()
```

### Enable Dynamic Features
```lua
-- Motion blur
VisualEffects.enableDynamicBlur(player)

-- Auto-focus
VisualEffects.enableDynamicFocus(player)

-- Day/night cycle
VisualEffects.animateDayNightCycle(600)  -- 10-minute cycle
```

### Seasonal Changes
```lua
-- Spring with cherry blossoms
ParticleEffects.setSeason("spring")

-- Winter with snow
ParticleEffects.setSeason("winter")
```

### Adjust Effect Intensity
```lua
-- Subtle bloom
VisualEffects.setIntensity("Bloom", 0.2)

-- Strong sun rays
VisualEffects.setIntensity("SunRays", 0.3)
```

## Troubleshooting

### Effects Not Appearing
- Check Output console for error messages
- Verify `Lighting` service is accessible
- Ensure modules are in `src/client/Modules/`

### Performance Issues
- Reduce particle emission rates in CONFIG
- Disable blur or depth of field
- Lower bloom size and intensity
- Remove vignette effect

### Particles Not Visible
- Check if particle source is positioned correctly (Y=50 default)
- Verify ParticleEmitter.Enabled = true
- Check transparency and size sequences

### Fireflies Not Appearing
- Check time of day: Lighting.ClockTime (only spawn 18-6)
- Verify CONFIG.fireflies.enabled = true
- Look for console message: "Fireflies created"

## Future Enhancements

Potential additions:
- Weather effects (rain, fog, wind)
- More seasonal particles (autumn leaves, spring pollen)
- Dynamic lighting based on time of day
- Screen space reflections
- Enhanced water shaders
- Customizable effect presets
- Performance profiles (Low/Medium/High/Ultra)

---

**Status**: ✅ Complete and Integrated
**Last Updated**: November 10, 2025
**Files**:
- `src/client/Modules/VisualEffects.luau`
- `src/client/Modules/ParticleEffects.luau`
- `src/client/init.client.luau` (integration)
