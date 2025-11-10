--[[
	CutsceneManager.luau
	
	Handles cinematic sequences with camera control, character focus, transitions,
	and orchestration. Used for onboarding, special events, and story moments.
	
	Features:
	- Camera movement and tweening
	- Character/object focus
	- Fade in/out transitions
	- Sequence chaining
	- Background music control
	
	Usage:
		local cutscene = CutsceneManager.new()
		cutscene:startSequence({
			{type = "fade", direction = "out", duration = 1},
			{type = "camera", target = workspace.TomNook.Head, duration = 2},
			{type = "dialogue", text = "Welcome!", speaker = "Tom Nook"},
			{type = "fade", direction = "in", duration = 1}
		})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local CutsceneManager = {}
CutsceneManager.__index = CutsceneManager

-- Active cutscene state
local _activeCutscene = nil

function CutsceneManager.new()
	local self = setmetatable({}, CutsceneManager)
	
	self.player = Players.LocalPlayer
	self.camera = workspace.CurrentCamera
	self.originalCameraType = self.camera.CameraType
	self.originalCameraSubject = self.camera.CameraSubject
	
	-- Fade GUI
	self.fadeGui = nil
	self.fadeFrame = nil
	
	-- Sequence state
	self.isPlaying = false
	self.currentSequence = nil
	self.currentStep = 0
	self.onComplete = nil
	
	-- Camera tweens
	self._currentCameraTween = nil
	
	print("[CutsceneManager] ✅ Initialized")
	
	return self
end

--[[
	Create fade overlay GUI (black screen for transitions)
]]
function CutsceneManager:_createFadeGui()
	if self.fadeGui then return end
	
	local playerGui = self.player:WaitForChild("PlayerGui")
	
	-- Create fade overlay
	self.fadeGui = Instance.new("ScreenGui")
	self.fadeGui.Name = "CutsceneFade"
	self.fadeGui.DisplayOrder = 1000 -- On top of everything
	self.fadeGui.ResetOnSpawn = false
	self.fadeGui.IgnoreGuiInset = true
	
	self.fadeFrame = Instance.new("Frame")
	self.fadeFrame.Name = "FadeFrame"
	self.fadeFrame.Size = UDim2.new(1, 0, 1, 0)
	self.fadeFrame.Position = UDim2.new(0, 0, 0, 0)
	self.fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.fadeFrame.BackgroundTransparency = 1 -- Start invisible
	self.fadeFrame.BorderSizePixel = 0
	self.fadeFrame.Parent = self.fadeGui
	
	self.fadeGui.Parent = playerGui
	
	print("[CutsceneManager] ✅ Created fade GUI")
end

--[[
	Fade screen to/from black
	@param direction "in" (to black) or "out" (from black to clear)
	@param duration Seconds to complete fade
	@return Promise-like (yields until complete)
]]
function CutsceneManager:fade(direction: string, duration: number)
	self:_createFadeGui()
	
	local targetTransparency = direction == "in" and 0 or 1
	
	print(string.format("[CutsceneManager] 🎬 Fading %s over %.1fs", direction, duration))
	
	local tween = TweenService:Create(
		self.fadeFrame,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{BackgroundTransparency = targetTransparency}
	)
	
	tween:Play()
	tween.Completed:Wait()
	
	print(string.format("[CutsceneManager] ✅ Fade %s complete", direction))
end

--[[
	Move camera to focus on a target (Part, Model, CFrame, or Vector3)
	@param target The target to focus on
	@param duration Seconds to complete movement
	@param offset Optional CFrame offset from target
]]
function CutsceneManager:focusCamera(target: Instance | CFrame | Vector3, duration: number, offset: CFrame?)
	-- Set camera to Scriptable mode
	self.camera.CameraType = Enum.CameraType.Scriptable
	
	-- Calculate target CFrame
	local targetCFrame: CFrame
	
	if typeof(target) == "Instance" then
		if target:IsA("BasePart") then
			targetCFrame = target.CFrame
		elseif target:IsA("Model") then
			targetCFrame = target:GetPivot()
		else
			warn("[CutsceneManager] ❌ Invalid target type:", target.ClassName)
			return
		end
	elseif typeof(target) == "CFrame" then
		targetCFrame = target
	elseif typeof(target) == "Vector3" then
		targetCFrame = CFrame.new(target)
	else
		warn("[CutsceneManager] ❌ Invalid target type:", typeof(target))
		return
	end
	
	-- Apply offset (e.g., move camera back a bit, look from angle)
	if offset then
		targetCFrame = targetCFrame * offset
	else
		-- Default: pull back 5 studs on Z axis
		targetCFrame = targetCFrame * CFrame.new(0, 2, 5)
	end
	
	print(string.format("[CutsceneManager] 🎥 Focusing camera on target over %.1fs", duration))
	
	-- Cancel any existing tween
	if self._currentCameraTween then
		self._currentCameraTween:Cancel()
	end
	
	-- Tween camera to target
	self._currentCameraTween = TweenService:Create(
		self.camera,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{CFrame = targetCFrame}
	)
	
	self._currentCameraTween:Play()
	self._currentCameraTween.Completed:Wait()
	
	print("[CutsceneManager] ✅ Camera focus complete")
end

--[[
	Reset camera back to player control
]]
function CutsceneManager:resetCamera()
	-- Cancel any running tweens
	if self._currentCameraTween then
		self._currentCameraTween:Cancel()
		self._currentCameraTween = nil
	end
	
	-- Restore original camera settings
	self.camera.CameraType = self.originalCameraType
	self.camera.CameraSubject = self.originalCameraSubject
	
	print("[CutsceneManager] ✅ Camera reset to player control")
end

--[[
	Wait for a duration (for sequencing)
	@param duration Seconds to wait
]]
function CutsceneManager:wait(duration: number)
	print(string.format("[CutsceneManager] ⏱️ Waiting %.1fs", duration))
	task.wait(duration)
end

--[[
	Play a cutscene sequence
	@param sequence Array of steps {type, ...params}
	@param onComplete Callback when sequence finishes
	
	Step types:
	- {type = "fade", direction = "in"/"out", duration = 1}
	- {type = "camera", target = Part, duration = 2, offset = CFrame}
	- {type = "wait", duration = 1}
	- {type = "dialogue", text = "...", speaker = "..."}
	- {type = "callback", func = function() end}
	- {type = "reset"} - Reset camera to player
	
	Example:
		cutscene:startSequence({
			{type = "fade", direction = "in", duration = 1},
			{type = "camera", target = workspace.TomNook.Head, duration = 2},
			{type = "wait", duration = 0.5},
			{type = "dialogue", text = "Welcome!", speaker = "Tom Nook"},
			{type = "fade", direction = "out", duration = 1},
			{type = "reset"}
		})
]]
function CutsceneManager:startSequence(sequence: {{[string]: any}}, onComplete: (() -> ())?)
	if self.isPlaying then
		warn("[CutsceneManager] ⚠️ Cutscene already playing - cannot start new sequence")
		return
	end
	
	self.isPlaying = true
	self.currentSequence = sequence
	self.currentStep = 0
	self.onComplete = onComplete
	
	_activeCutscene = self
	
	print(string.format("[CutsceneManager] 🎬 Starting sequence with %d steps", #sequence))
	
	-- Run sequence in coroutine
	task.spawn(function()
		for i, step in ipairs(sequence) do
			self.currentStep = i
			print(string.format("[CutsceneManager] 📍 Step %d/%d: %s", i, #sequence, step.type))
			
			if step.type == "fade" then
				self:fade(step.direction or "in", step.duration or 1)
				
			elseif step.type == "camera" then
				self:focusCamera(step.target, step.duration or 2, step.offset)
				
			elseif step.type == "wait" then
				self:wait(step.duration or 1)
				
			elseif step.type == "dialogue" then
				-- Dialogue integration (requires DialogueGUI module)
				print(string.format("[CutsceneManager] 💬 Dialogue: %s - '%s'", step.speaker or "???", step.text or ""))
				-- TODO: Integrate with DialogueGUI module
				
			elseif step.type == "callback" then
				if step.func and type(step.func) == "function" then
					local success, err = pcall(step.func)
					if not success then
						warn("[CutsceneManager] ❌ Callback error:", err)
					end
				end
				
			elseif step.type == "reset" then
				self:resetCamera()
				
			else
				warn("[CutsceneManager] ⚠️ Unknown step type:", step.type)
			end
		end
		
		-- Sequence complete
		self.isPlaying = false
		self.currentSequence = nil
		self.currentStep = 0
		_activeCutscene = nil
		
		print("[CutsceneManager] ✅ Sequence complete!")
		
		if self.onComplete then
			self.onComplete()
		end
	end)
end

--[[
	Stop the current cutscene (emergency stop)
]]
function CutsceneManager:stop()
	if not self.isPlaying then return end
	
	print("[CutsceneManager] ⛔ Stopping cutscene")
	
	self.isPlaying = false
	self.currentSequence = nil
	self.currentStep = 0
	_activeCutscene = nil
	
	-- Reset camera
	self:resetCamera()
	
	-- Clear fade
	if self.fadeGui then
		self.fadeGui:Destroy()
		self.fadeGui = nil
		self.fadeFrame = nil
	end
end

--[[
	Check if a cutscene is currently playing
]]
function CutsceneManager.isPlaying(): boolean
	return _activeCutscene ~= nil
end

--[[
	Cleanup
]]
function CutsceneManager:destroy()
	self:stop()
	
	if self.fadeGui then
		self.fadeGui:Destroy()
	end
	
	print("[CutsceneManager] 🗑️ Destroyed")
end

return CutsceneManager
