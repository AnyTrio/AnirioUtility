--!strict
-- General Zone Script

-- Runs "onEntered(player)" and "onExited(player)" in the module script referred by the "OnZoneEvents" object value
-- Plan: cache the events module

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local Zone = require(ReplicatedStorage["AnirioReplicated"].Zone)

local Trove = require(ReplicatedStorage["AnirioReplicated"].Packages.Trove)

---------- Variables ----------

local tagName = "GeneralZone"

local interactionContainerName = "Zone"
local eventsModuleObjectName = "OnZoneEvents"

local taggedObjectTroves: {[Instance]: Trove.Trove} = {}

---------- Local functions ----------
-- Define general functions here

local function setUpZone(taggedObject: Instance, zoneHolder: Instance, eventsModuleScript: ModuleScript)
	-- Get events module
	local zoneEvents = require(eventsModuleScript)

	-- Set up trove
	local trove = Trove.new()
	if taggedObjectTroves[taggedObject] then
		taggedObjectTroves[taggedObject]:Destroy()
	end
	taggedObjectTroves[taggedObject] = trove

	-- Initialize zone
	local zone = trove:Add(Zone.new())
	zone:addZoneHolder(zoneHolder)
	
	-- Make connections
	trove:Add(zone.playerEntered:Connect(function(player: Player)
		zoneEvents.onEntered(player)
	end))
	trove:Add(zone.playerExited:Connect(function(player: Player)
		zoneEvents.onExited(player)
	end))
end

---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onInstanceAdded(object: Instance)
	-- Validate containers
	local zoneHolder = object:FindFirstChild(interactionContainerName)
	if not zoneHolder then
		return
	end
	if not zoneHolder:FindFirstChildWhichIsA("BasePart") then
		return
	end

	-- Validate object value
	local eventsModuleObject = object:FindFirstChild(eventsModuleObjectName) :: ObjectValue
	local eventsModuleScript = eventsModuleObject and eventsModuleObject.Value :: ModuleScript
	if not eventsModuleScript then
		return
	end

	-- Set up zone
	setUpZone(object, zoneHolder, eventsModuleScript)
end

local function onInstanceRemoved(object: Instance)
	-- Clean up
	local trove = taggedObjectTroves[object]
	if trove then
		trove:Destroy()
		taggedObjectTroves[object] = nil
	end
end

---------- Set up function ----------
local function initSetUp()
	local tagged = CollectionService:GetTagged(tagName)
	task.defer(function()
		for _, object in tagged do
			onInstanceAdded(object)
		end
	end)
	CollectionService:GetInstanceAddedSignal(tagName):Connect(onInstanceAdded)
	CollectionService:GetInstanceRemovedSignal(tagName):Connect(onInstanceRemoved)
end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

initSetUp()
