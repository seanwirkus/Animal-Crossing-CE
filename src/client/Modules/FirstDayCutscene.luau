--[[
	FirstDayCutscene.luau

	The "what now?" moment right after onboarding finishes.

	Onboarding used to just end and leave the player standing there. This plays a
	short cinematic that:
	  1. Letterboxes + tours the island landmarks (Resident Services, the DIY
	     workbench, the beach/airport) with the camera.
	  2. Has Isabelle walk the player through the core gameplay loop in dialogue:
	     gather -> craft -> complete quests -> earn Bells & Miles -> upgrade.
	  3. Hands control back, reveals the on-screen Objective Tracker, and opens
	     the quest log so the player knows exactly what to do next.

	It only plays once per session (and onboarding itself only runs once for new
	players, so returning players never see it).

	Usage:
		local FirstDayCutscene = require(script.Parent.FirstDayCutscene)
		FirstDayCutscene.play()
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CutsceneManager = require(script.Parent.CutsceneManager)

local FirstDayCutscene = {
    _hasPlayed = false,
}

-- Landmark names to tour, in priority order. The cutscene focuses on whichever
-- of these actually exist in the world and skips the rest, so it stays robust
-- even if the island layout changes.
local LANDMARK_CANDIDATES = {
    { names = { "ResidentServices", "TownSquare", "Plaza" }, offset = CFrame.new(0, 14, 26) },
    { names = { "DIYWorkBench", "DIYWorkbench", "Workbench" }, offset = CFrame.new(0, 6, 12) },
    { names = { "NookPlaneDelivery", "Airport", "Dock" }, offset = CFrame.new(0, 10, 20) },
    { names = { "TentHouse" }, offset = CFrame.new(0, 8, 16) },
}

local DIALOGUE = {
    {
        speaker = "Isabelle",
        text = "There you are! Welcome to your brand-new island home. I'm Isabelle, and I'll help you settle in!",
    },
    {
        speaker = "Isabelle",
        text = "Every day on the island follows a simple rhythm. Let me show you the ropes!",
    },
    {
        speaker = "Isabelle",
        text = "First, gather materials — chop trees with your axe, hit rocks, and shake branches and fruit loose.",
    },
    {
        speaker = "Isabelle",
        text = "Then head to a DIY Workbench to craft tools, furniture, and decorations from what you've collected.",
    },
    {
        speaker = "Isabelle",
        text = "Fish at the water's edge and catch bugs with your net — they sell for plenty of Bells!",
    },
    {
        speaker = "Isabelle",
        text = "Complete the quests in your NookPhone to earn Bells and Nook Miles. Spend Bells at the shop and on inventory upgrades!",
    },
    {
        speaker = "Isabelle",
        text = "That's the loop: gather, craft, complete quests, and make your island your own. I've opened your quest log to get you started!",
    },
}

-- Find the first existing instance matching any of the candidate names.
local function findLandmark(names: { string })
    for _, name in ipairs(names) do
        local found = Workspace:FindFirstChild(name, true)
        if found and (found:IsA("Model") or found:IsA("BasePart")) then
            return found
        end
    end
    return nil
end

-- Reveal the objective tracker (if present) and open the quest log so the
-- player's next steps are obvious the moment the cutscene ends.
local function revealNextSteps()
    local tracker = rawget(_G, "ObjectiveTracker")
    if tracker and tracker.show then
        pcall(function()
            tracker:show()
        end)
    end

    local guiManager = rawget(_G, "GUIManager")
    if guiManager and guiManager.showGUI then
        pcall(function()
            guiManager:showGUI("QuestGUI")
        end)
    end
end

--[[
	Play the first-day cutscene. Safe to call more than once — it no-ops after
	the first run in a session.
	@param onComplete optional callback fired after the cutscene finishes
]]
function FirstDayCutscene.play(onComplete: (() -> ())?)
    if FirstDayCutscene._hasPlayed then
        print("[FirstDayCutscene] Already played this session - skipping")
        if onComplete then
            onComplete()
        end
        return
    end
    FirstDayCutscene._hasPlayed = true

    print("[FirstDayCutscene] 🎬 Starting first-day cinematic")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)

    local cutscene = CutsceneManager.new()

    -- Build the sequence: open on the player, then interleave landmark camera
    -- moves with Isabelle's dialogue beats.
    local sequence = {
        { type = "fade", direction = "in", duration = 1 },
        { type = "letterbox", show = true, duration = 0.6 },
    }

    -- Opening shot on the player's character
    if rootPart then
        table.insert(sequence, { type = "camera", target = rootPart, duration = 2, offset = CFrame.new(6, 4, 10) })
    end
    table.insert(sequence, { type = "fade", direction = "out", duration = 1 })

    -- Collect the landmarks that actually exist this session
    local landmarks = {}
    for _, candidate in ipairs(LANDMARK_CANDIDATES) do
        local instance = findLandmark(candidate.names)
        if instance then
            table.insert(landmarks, { instance = instance, offset = candidate.offset })
        end
    end

    -- Weave dialogue with camera moves. Each dialogue beat gets a backdrop:
    -- a landmark if we have one, otherwise we linger on the player.
    for index, beat in ipairs(DIALOGUE) do
        local landmark = landmarks[((index - 1) % math.max(1, #landmarks)) + 1]
        if landmark then
            table.insert(sequence, {
                type = "camera",
                target = landmark.instance,
                duration = 2.2,
                offset = landmark.offset,
            })
        elseif rootPart then
            table.insert(sequence, {
                type = "camera",
                target = rootPart,
                duration = 2,
                offset = CFrame.new(8, 5, 12),
            })
        end
        table.insert(sequence, { type = "dialogue", speaker = beat.speaker, text = beat.text })
    end

    -- Wrap up: retract bars, fade through black, hand control back.
    table.insert(sequence, { type = "fade", direction = "in", duration = 0.8 })
    table.insert(sequence, { type = "letterbox", show = false, duration = 0.5 })
    table.insert(sequence, { type = "reset" })
    table.insert(sequence, { type = "fade", direction = "out", duration = 0.8 })

    cutscene:startSequence(sequence, function()
        print("[FirstDayCutscene] ✅ Complete - revealing next steps")
        revealNextSteps()
        if onComplete then
            onComplete()
        end
    end)
end

return FirstDayCutscene
