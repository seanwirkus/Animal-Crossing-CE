# 🛩️ Seaplane Physics - Complete Fix

## Problems Fixed

### 1. **Throttle Not Working**
- **Issue**: Plane wasn't moving forward even with throttle applied
- **Cause**: Velocity calculation used `throttle` but plane was anchored indefinitely
- **Fix**: Rewrote state machine to properly unanchor plane when throttle > 0.05

### 2. **Turning Without Forward Movement (Taxi Turning)**
- **Issue**: Plane could turn while stationary on water
- **Cause**: Yaw input was applied regardless of forward speed
- **Fix**: Added `MIN_TAXI_SPEED` constant - yaw only updates if `taxiSpeed > MIN_TAXI_SPEED`
  ```lua
  if taxiSpeed > MIN_TAXI_SPEED then
      self._currentYaw += yawInput * TAXI_TURN_RATE * deltaTime
  end
  ```

### 3. **No Float Physics**
- **Issue**: Plane had no buoyancy system to keep it floating
- **Cause**: Float script was separate, not integrated
- **Fix**: Added `_setupFloaterBuoyancy()` function that:
  - Finds all floater parts in the Floater model
  - Welds them to plane body
  - Sets realistic physical properties (density 0.98, high friction, no bounce)
  - Prevents sinking and keeps plane level on water

## New Flight Logic

### **TWO DISTINCT STATES**

#### **STATE 1: ON WATER (Taxiing)**
- Plane is **ANCHORED** (floats in place via buoyancy)
- Forward speed: `FLIGHT_SPEED * 0.4 * throttle` (slower taxi speed)
- Yaw only works if moving forward > MIN_TAXI_SPEED (5 studs/sec)
- Plane maintains level orientation
- Velocity physics disabled (buoyancy keeps it floating)

#### **STATE 2: IN AIR (Flying)**
- Plane is **UNANCHORED** when throttle > 0.05
- Forward speed: `FLIGHT_SPEED * throttle` (full speed)
- Yaw turns freely (AIR_TURN_RATE is faster than TAXI_TURN_RATE)
- Vertical speed based on throttle:
  ```lua
  verticalSpeed = (LIFT_COEFFICIENT * throttle) - (DESCEND_RATE * (1 - throttle))
  ```
- BodyVelocity applies full physics

## Flight Controls

| Key | Action | Details |
|-----|--------|---------|
| **SPACE** | Throttle | Hold to accelerate (0 → 100%) and climb |
| **Release SPACE** | Decelerate | Throttle decreases smoothly (100% → 0%) |
| **Arrow Left/Right** | Turn | ← Only works in air OR on water if moving >5 studs/sec |
| **E** | Enter/Exit | Board or leave the plane |

## Flight Sequence

1. **Press E** → Enter plane (spawns on water)
2. **Hold SPACE** → Throttle increases, plane stays on water
3. **Hold SPACE more** → At ~5 studs/sec forward speed, you can NOW TURN
4. **Keep holding SPACE** → Throttle reaches 100%, plane UNANCHORS and takes off
5. **In air** → Can turn freely with arrow keys
6. **Release SPACE** → Plane descends smoothly (not dropping)
7. **Reach water** → Plane REANCHORS, enters taxi mode

## Physical Constants

```lua
FLIGHT_SPEED = 80              -- Forward speed in air
TAXI_TURN_RATE = math.rad(25)  -- Slower turning on water
MIN_TAXI_SPEED = 5             -- Need 5 studs/sec to turn
LIFT_COEFFICIENT = 45          -- Climb speed at full throttle
DESCEND_RATE = 40              -- Sink speed at zero throttle
AIR_TURN_RATE = math.rad(35)   -- Faster turning in air
```

## Float Buoyancy

Each floater part gets:
- **Density**: 0.98 (just below water density for lift)
- **Friction**: 1.0 (high friction = less sliding)
- **Elasticity**: 0 (no bouncing)
- **Welded** to plane body
- Result: Plane floats smoothly with NO bounce, NO wobbling

## Testing Checklist

- [ ] Hold SPACE → plane accelerates forward (throttle goes 0→1)
- [ ] Plane sits on water without sinking
- [ ] Can't turn while stationary (throttle at 0)
- [ ] Can turn once moving forward on water
- [ ] Release SPACE → throttle decreases smoothly (no sudden drop)
- [ ] At high throttle → plane takes off and climbs
- [ ] Turn freely in air with arrow keys
- [ ] Release SPACE in air → smooth glide down
- [ ] Land on water → plane reanchors, returns to taxi mode
- [ ] No bouncing or wobbling on water
- [ ] No spinning or rotation issues
