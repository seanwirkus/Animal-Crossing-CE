--[[
	IslandGen/WaterSpline.luau
	Carves spline-based rivers and ponds into terrain
]]

local Terrain = workspace.Terrain
local Config  = require(script.Parent.Config)
local Util    = require(script.Parent.Util)

local WaterSpline = {}

local function catmullRom(p0,p1,p2,p3,t)
	local t2,t3 = t*t, t*t*t
	return (p1*2 + (-p0+p2)*t + (2*p0-5*p1+4*p2-p3)*t2 + (-p0+3*p1-3*p2+p3)*t3)*0.5
end

local function carveCylinder(a, b, radius)
	local mid = (a+b)*0.5
	local len = (b-a).Magnitude
	local cf  = CFrame.lookAt(mid, b)
	Terrain:FillCylinder(cf, len, radius, Enum.Material.Water)
	-- soften banks with sand
	Terrain:FillCylinder(cf, len, radius+2, Enum.Material.Sand)
end

local function generateControls(seed)
	local rng = Util.rng(seed or 1)
	local n   = rng(Config.RIVER_MIN_POINTS, Config.RIVER_MAX_POINTS)
	local pts = {}

	for i=1,n do
		-- lay broadly east<->west but allow meander
		local t = i/n
		local x = Util.lerp(-Config.ISLAND_RADIUS*0.85, Config.ISLAND_RADIUS*0.85, t)
		local z = (rng(0,1000)/1000 - 0.5) * 2 * Config.ISLAND_RADIUS * 0.25
		z = z + math.sin(t*math.pi*2)*Config.ISLAND_RADIUS*Config.RIVER_MEANDER*0.25
		local p = Util.clampToRadius(Vector3.new(x, Config.WATER_LEVEL, z), Config.ISLAND_RADIUS*0.9)
		table.insert(pts, p)
	end
	return pts
end

local function carveSpline(points, radius, detail)
	detail = detail or 14
	if #points < 4 then return end
	for i=2,#points-2 do
		for j=0,detail-1 do
			local t1 = j/detail
			local t2 = (j+1)/detail
			local a  = catmullRom(points[i-1],points[i],points[i+1],points[i+2], t1)
			local b  = catmullRom(points[i-1],points[i],points[i+1],points[i+2], t2)
			carveCylinder(a, b, radius)
		end
		Terrain:FillBall(points[i], radius+2, Enum.Material.Sand) -- widen nodes slightly
	end
end

local function placePonds(seed)
	local rng = Util.rng(seed or 1)
	local cmin, cmax = table.unpack(Config.POND_COUNT_RANGE)
	local ponds = rng(cmin, cmax)
	for _=1,ponds do
		local ang = (rng(0,1000)/1000) * math.pi*2
		local rad = Config.ISLAND_RADIUS * (0.2 + (rng(0,1000)/1000)*0.55)
		local pos = Vector3.new(math.cos(ang)*rad, Config.WATER_LEVEL, math.sin(ang)*rad)
		local rmin, rmax = table.unpack(Config.POND_RADIUS_RANGE)
		local r = rng(rmin, rmax)
		Terrain:FillBall(pos, r, Enum.Material.Water)
		Terrain:FillBall(pos, r+2, Enum.Material.Sand)
	end
end

function WaterSpline.Generate(seed)
	local controls = generateControls(seed)
	carveSpline(controls, Config.RIVER_BANK_RADIUS, 16)
	placePonds(seed and seed+77 or 77)
	return controls
end

return WaterSpline
