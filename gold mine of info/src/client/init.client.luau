--[[
	Client Init - Animal Crossing client initialization
	Simple client-side entry point
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Simple component manager
local SimpleComponentManager = require(script.Controllers.SimpleComponentManager)

-- UI Controller System
local UIController = require(script.Controllers.UIController)

-- Debug system (for testing)
local UIControllerDebug = require(script.Controllers.UIControllerDebug)

-- Initialize the component system
SimpleComponentManager.OnStart()

-- Initialize the dynamic UI controller system
local uiController = UIController.new()

-- Initialize debug system
local debugSystem = UIControllerDebug.new()

print("[Client] Animal Crossing client initialized!")
print("[Client] Press E to open inventory")
print("[Client] Press F10 to debug GUIs")
print("[Client] Press F11 to test inventory")