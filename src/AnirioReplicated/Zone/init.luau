--!strict
-- Zone Class Module

-- A class to set up zones which detect things entering and exiting
-- Some inspirations from 1ForeverHD's ZonePlus

-- Plan: Add functionality for more instances (parts, containers, etc.)
-- Plan: More optimization (ex: minimize spatial query volumes (does this actually lead to improvement?))

---------- Module ----------
local Zone = {}
Zone.__index = Zone

---------- Services ----------

local RunService = game:GetService("RunService")

---------- Imports ----------

local AnirioReplicated = script.Parent
local AnirioTable = require(AnirioReplicated.AnirioTable)
local PlayerUtility = require(AnirioReplicated.PlayerUtility)
local SpatialQuery = require(AnirioReplicated.SpatialQuery)

local Packages = AnirioReplicated
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)

---------- Types ----------

-- Define module data with potential properties
type ZoneData = {
	-- Declare properties here
	_trove: Trove.Trove,
	_enabled: boolean,

	playerEntered: Signal.Signal<Player>,
	playerExited: Signal.Signal<Player>,

	_actualParts: AnirioTable.TableType<BasePart>,

	_individualParts: AnirioTable.TableType<BasePart>,

	_holders: AnirioTable.TableType<Instance>,
	_holderTrove: {[Instance]: Trove.Trove},

	_containedPlayers: AnirioTable.TableType<Player>,

	_instanceDetectedState: {[Instance]: boolean},
}

-- Define module type
export type ZoneType = typeof(setmetatable({} :: ZoneData, Zone)) & {
	destroy: (self: ZoneType) -> (),
}

---------- Variables ----------

local playerParts: {BasePart} = {}
local playerPartNames = {"HumanoidRootPart"}

---------- Local functions ----------

-- Update the stored array of player parts
local function updatePlayerParts()
	playerParts = PlayerUtility.getAllPlayerParts(playerPartNames)
end

-- Get the table with all duplicates removed
local function removeDuplicates(table: {any})
	local newTable = AnirioTable.new()
	newTable:insertUnique(table)
	return newTable:getArray()
end

---------- Module functions ----------

-- Constructor
function Zone.new(): ZoneType
	-- New object
	local self = setmetatable({} :: ZoneData, Zone) :: ZoneType

	-- Attributes
	-- Initialize attributes here

	local trove = Trove.new()

	self._trove = trove
	self._enabled = true

	self.playerEntered = trove:Add(Signal.new())
	self.playerExited = trove:Add(Signal.new())

	self._actualParts = trove:Add(AnirioTable.new())

	self._individualParts = trove:Add(AnirioTable.new())

	self._holders = trove:Add(AnirioTable.new())
	self._holderTrove = {}

	self._containedPlayers = trove:Add(AnirioTable.new())

	self._instanceDetectedState = {}

	-- Methods
	-- Call methods to set up the object here

	self:_setUpSignals()

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- Set whether the zone is enabled
function Zone.setEnabled(self: ZoneType, enabled: boolean)
	self._enabled = enabled
end

-- (Internal) Add multiple `BasePart` to the zone
function Zone._addActualParts(self: ZoneType, objects: {BasePart})
	-- Add zone parts
	self._actualParts:insertAll(objects, nil, "BasePart")
end

-- (Internal) Remove multiple `BasePart` from the zone
function Zone._removeActualParts(self: ZoneType, objects: {BasePart})
	-- Remove zone parts
	self._actualParts:removeValues(objects, nil, "BasePart")
end

-- Add individual parts to the zone; individual parts are stored separately from holder parts
function Zone.addIndividualParts(self: ZoneType, parts: {BasePart})
	-- Add individual parts
	for _, part in parts do
		-- Check new individual part
		if not self._individualParts:contains(part) then
			self._individualParts:insertAll({part}, nil, "BasePart")
			self._actualParts:insertAll({part}, nil, "BasePart")
		end
	end
end

-- Remove individual parts from the zone
function Zone.removeIndividualParts(self: ZoneType, parts: {BasePart})
	-- Remove duplicate parts from given parts
	parts = removeDuplicates(parts)

	-- Remove individual parts
	for _, part in parts do
		-- Check stored individual part
		if self._individualParts:contains(part) then
			self._actualParts:removeValues({part}, nil, "BasePart")
		end
	end
	self._individualParts:removeValues(parts, nil, "BasePart")
end

-- Add a holder to the zone; all descendant `BasePart` are considered part of the zone
function Zone.addZoneHolder(self: ZoneType, holder: Instance)
	-- Validate new holder
	if self._holders:contains(holder) then
		warn("Holder already added to zone!")
		return
	end

	-- Add holder
	self._holders:insertAll({holder})

	-- Add descendants
	do
		local descendants = holder:GetDescendants()
		task.defer(function()
			-- Add base part descendants
			local baseParts: {BasePart} = {}
			for _, descendant in descendants do
				if descendant:IsA("BasePart") then
					table.insert(baseParts, descendant)
				end
			end
			self:_addActualParts(baseParts)
		end)
	end

	-- Set up trove
	local trove = Trove.new()

	if self._holderTrove[holder] then
		self._holderTrove[holder]:Destroy()
	end
	self._holderTrove[holder] = trove

	-- Make connections
	trove:Add(holder.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			self:_addActualParts({descendant})
		end
	end))
	trove:Add(holder.DescendantRemoving:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			self:_removeActualParts({descendant})
		end
	end))
end

-- Remove a holder from the zone
function Zone.removeZoneHolder(self: ZoneType, holder: Instance)
	-- Validate existing holder
	if not self._holders:contains(holder) then
		warn("Holder isn't added to zone!")
		return
	end

	-- Remove holder
	self._holders:removeValues({holder})

	-- Clean up
	local trove = self._holderTrove[holder]
	if trove then
		trove:Destroy()
		self._holderTrove[holder] = nil
	end

	-- Remove descendants
	do
		local descendants = holder:GetDescendants()
		task.defer(function()
			-- Remove base part descendants
			local baseParts: {BasePart} = {}
			for _, descendant in descendants do
				if descendant:IsA("BasePart") then
					table.insert(baseParts, descendant)
				end
			end
			self:_removeActualParts(baseParts)
		end)
	end
end

-- Get
-- Define get methods here

-- Get players currently detected by the zone
function Zone.getContainedPlayers(self: ZoneType)
	return self._containedPlayers:getArray()
end

-- Signals
-- Define signal handling here

-- Set up signals
function Zone._setUpSignals(self: ZoneType)
	-- Update player parts
	updatePlayerParts()

	-- Player entered / exited
	self._trove:Add(RunService.Heartbeat:Connect(function()
		-- Get players in zone
		local detectedPlayers: {Player} = {}
		if self._enabled then
			detectedPlayers = PlayerUtility.fromCharacterParts(SpatialQuery.getWhitelistedInParts(self._actualParts:getArray(), playerParts))
		end

		-- Get entered and exited players
		local added, removed = self._containedPlayers:compareTableChanges(detectedPlayers)

		-- Update contained players
		self._containedPlayers:insertAll(added)
		self._containedPlayers:removeValues(removed)

		-- Fire entered signals
		for _, player in added do
			self.playerEntered:Fire(player)
		end

		-- Fire exited signals
		for _, player in removed do
			self.playerExited:Fire(player)
		end
	end))
end

-- Clean up
-- Define cleanup methods here

-- Clean up the object
function Zone.destroy(self: ZoneType)
	for _, trove in self._holderTrove do
		trove:Destroy()
	end
	table.clear(self._holderTrove)
	table.clear(self._instanceDetectedState)

	self._trove:Destroy()
end

---------- Calling / connecting functions ----------

PlayerUtility.CharacterAdded:Connect(updatePlayerParts)
PlayerUtility.CharacterRemoving:Connect(updatePlayerParts)

---------- Return module ----------
return Zone
