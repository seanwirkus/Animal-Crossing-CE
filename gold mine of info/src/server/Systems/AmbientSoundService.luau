local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

type AmbientState = {
	hour: number,
	isDaytime: boolean,
	weather: string,
}

local AmbientSoundService = {}
AmbientSoundService.__index = AmbientSoundService

-- Sound configuration by hour
local AMBIENT_SOUNDS = {
	-- Daytime (6-18) - birds, insects, wind
	Day = {
		volume = 0.3,
		soundIds = {
			"rbxassetid://1837050779", -- Bird chirping
			"rbxassetid://1837050780", -- Wind
		},
	},
	-- Evening (18-22) - crickets, frogs, wind down
	Evening = {
		volume = 0.25,
		soundIds = {
			"rbxassetid://1837050781", -- Cricket chirping
			"rbxassetid://1837050782", -- Frog croaking
		},
	},
	-- Night (22-6) - peaceful night sounds
	Night = {
		volume = 0.2,
		soundIds = {
			"rbxassetid://1837050783", -- Night insects
			"rbxassetid://1837050784", -- Owl hooting (rare)
		},
	},
}

-- Background music by hour (like Animal Crossing)
local BACKGROUND_MUSIC = {
	[6] = "Morning",
	[7] = "Morning",
	[8] = "Morning",
	[9] = "Morning",
	[10] = "Daytime", -- Peak daytime
	[11] = "Daytime",
	[12] = "Daytime",
	[13] = "Afternoon",
	[14] = "Afternoon",
	[15] = "Afternoon",
	[16] = "Afternoon",
	[17] = "Evening",
	[18] = "Evening",
	[19] = "Evening",
	[20] = "Night",
	[21] = "Night",
	[22] = "Night",
	[23] = "Night",
	[0] = "Night",
	[1] = "Night",
	[2] = "Night",
	[3] = "Night",
	[4] = "Night",
	[5] = "Morning",
}

function AmbientSoundService.new()
	local self = setmetatable({}, AmbientSoundService)
	
	self._ambientFolder = Instance.new("Folder")
	self._ambientFolder.Name = "AmbientSounds"
	self._ambientFolder.Parent = workspace
	
	self._currentHour = -1
	self._currentMusicTrack = nil
	self._ambientPlaying = false
	self._destroyed = false
	
	return self
end

function AmbientSoundService:Start(clock)
	if self._heartbeatConn then
		return
	end
	
	self._clock = clock
	
	-- Listen to hour changes from clock
	if clock and clock._hourChanged then
		self._hourConn = clock._hourChanged.Event:Connect(function(hour)
			self:_onHourChanged(hour)
		end)
	end
	
	print("[AmbientSoundService] Started and listening to clock")
end

function AmbientSoundService:_onHourChanged(hour)
	if self._destroyed then
		return
	end
	
	print(("[AmbientSoundService] Hour changed to: %d"):format(hour))
	
	-- Update background music
	self:_updateBackgroundMusic(hour)
	
	-- Update ambient sounds
	self:_updateAmbientSounds(hour)
end

function AmbientSoundService:_updateBackgroundMusic(hour)
	local musicTrack = BACKGROUND_MUSIC[hour]
	if musicTrack == self._currentMusicTrack then
		return
	end
	
	self._currentMusicTrack = musicTrack
	print(("[AmbientSoundService] Switching to %s music at hour %d"):format(musicTrack or "?", hour))
	
	-- Fade out old music
	for _, sound in self._ambientFolder:GetChildren() do
		if sound:IsA("Sound") and sound.Name == "BackgroundMusic" then
			sound:Destroy()
		end
	end
	
	-- Create new music sound (would be played from asset manager in real implementation)
	-- For now, this is a placeholder that would integrate with actual music files
end

function AmbientSoundService:_updateAmbientSounds(hour)
	-- Determine sound category
	local soundType = "Day"
	if hour >= 6 and hour < 18 then
		soundType = "Day"
	elseif hour >= 18 and hour < 22 then
		soundType = "Evening"
	else
		soundType = "Night"
	end
	
	print(("[AmbientSoundService] Ambient sound type: %s"):format(soundType))
	-- Ambient sounds would be managed here
	-- For now this is a framework ready for sound implementation
end

function AmbientSoundService:Destroy()
	if self._destroyed then
		return
	end
	
	self._destroyed = true
	
	if self._hourConn then
		self._hourConn:Disconnect()
		self._hourConn = nil
	end
	
	if self._ambientFolder then
		self._ambientFolder:Destroy()
	end
	
	print("[AmbientSoundService] Destroyed")
end

return AmbientSoundService
