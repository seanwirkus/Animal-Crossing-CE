--[[
	IslandGen/Util.luau
	Utility functions for island generation (RNG, math, collision)
]]

local Util = {}

-- Deterministic RNG from seed
function Util.rng(seed)
	local state = seed or 1
	return function(min, max)
		state = (1103515245 * state + 12345) % 2^31
		if not min then return state end
		if not max then return (state % max) + 1 end
		return min + (state % (max - min + 1))
	end
end

function Util.clamp01(x) return math.max(0, math.min(1, x)) end
function Util.lerp(a,b,t) return a + (b-a)*t end

-- keep inside a circle (with margin)
function Util.clampToRadius(v3, maxR)
	local r = (Vector2.new(v3.X, v3.Z)).Magnitude
	if r > maxR then
		local s = maxR/r
		return Vector3.new(v3.X*s, v3.Y, v3.Z*s)
	end
	return v3
end

return Util
