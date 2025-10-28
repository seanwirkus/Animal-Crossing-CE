--[[
	NPCWalker - Handles NPC patrol route following
	NPCs walk smoothly along defined waypoints at constant speed
]]

local RunService = game:GetService("RunService")

local NPCWalker = {}
NPCWalker.__index = NPCWalker

-- Configuration
local CONFIG = {
        WALK_SPEED = 10,              -- Studs per second
        WAYPOINT_TOLERANCE = 5,       -- Distance to reach waypoint
        TURN_SPEED = 0.1,             -- Rotation smoothness
        WAYPOINT_PAUSE = 0.1,         -- Seconds to pause at each waypoint
}

function NPCWalker.new(npcModel, waypoints)
	local self = setmetatable({}, NPCWalker)
	
	self._npcModel = npcModel
	self._waypoints = waypoints or {}
	self._currentWaypointIndex = 1
	self._isWalking = false
        self._humanoidRootPart = npcModel.PrimaryPart or npcModel:FindFirstChildOfClass("BasePart")
        self._heartbeatConnection = nil
        self._waypointPauseRemaining = 0

        return self
end

--[[
	Start patrol route
]]
function NPCWalker:StartPatrol()
        if self._isWalking then
                return
        end

        self._isWalking = true
        self._heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
                self:_patrolStep(deltaTime)
        end)
end

--[[
	Stop patrol
]]
function NPCWalker:StopPatrol()
        self._isWalking = false
        if self._heartbeatConnection then
                self._heartbeatConnection:Disconnect()
                self._heartbeatConnection = nil
        end
end

--[[
	Update waypoints mid-patrol
]]
function NPCWalker:SetWaypoints(waypoints)
        self._waypoints = waypoints or {}
        self._currentWaypointIndex = 1
        self._waypointPauseRemaining = 0
end

--[[
        Main patrol loop
]]
function NPCWalker:_patrolStep(deltaTime)
        if not (self._isWalking and self._humanoidRootPart) then
                self:StopPatrol()
                return
        end

        if #self._waypoints == 0 then
                self:StopPatrol()
                return
        end

        if self._waypointPauseRemaining > 0 then
                self._waypointPauseRemaining -= deltaTime
                if self._waypointPauseRemaining > 0 then
                        return
                end
                self._waypointPauseRemaining = 0
        end

        local targetWaypoint = self._waypoints[self._currentWaypointIndex]
        if not targetWaypoint then
                -- Loop back to start
                self._currentWaypointIndex = 1
                targetWaypoint = self._waypoints[1]
        end

        if not targetWaypoint then
                self:StopPatrol()
                return
        end

        local currentPos = self._humanoidRootPart.Position
        local offset = targetWaypoint - currentPos
        local distance = offset.Magnitude

        if distance < CONFIG.WAYPOINT_TOLERANCE then
                self._currentWaypointIndex += 1
                self._waypointPauseRemaining = CONFIG.WAYPOINT_PAUSE
                return
        end

        local direction = distance > 0 and offset.Unit or Vector3.zero
        local moveDistance = CONFIG.WALK_SPEED * deltaTime
        local stepDistance = math.min(moveDistance, distance)
        local newPos = currentPos + direction * stepDistance

        if self._humanoidRootPart.CanCollide then
                self._humanoidRootPart.CFrame = CFrame.new(newPos) * CFrame.lookAt(newPos, targetWaypoint)
        end
end

--[[
	Get current position
]]
function NPCWalker:GetPosition()
	if self._humanoidRootPart then
		return self._humanoidRootPart.Position
	end
	return nil
end

--[[
	Get current waypoint index
]]
function NPCWalker:GetCurrentWaypointIndex()
	return self._currentWaypointIndex
end

return NPCWalker
