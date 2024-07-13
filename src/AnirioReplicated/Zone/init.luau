--!strict
-- Zone Class Module

-- Some inspirations from https://github.com/1ForeverHD/ZonePlus
-- TODO: add functionality for more instances (parts, containers, etc.)
-- TODO: more optimization (ex: minimize spatial query volumes (does this actually lead to improvement?))

---------- Module ----------
local Zone = {}
Zone.__index = Zone

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------- Imports ----------

local AnirioReplicated = script.Parent
local AnirioTable = require(AnirioReplicated.AnirioTable)
local PlayerUtility = require(AnirioReplicated.PlayerUtility)
local SpatialQuery = require(AnirioReplicated.SpatialQuery)

local Signal = require(ReplicatedStorage["Sleitnick's"].Signal)
local Trove = require(ReplicatedStorage["Sleitnick's"].Trove)

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

	_instanceDetectedState: {[Instance]: boolean}
}

-- Define module type
export type ZoneType = typeof(setmetatable({} :: ZoneData, Zone)) & {
	destroy: (self: ZoneType) -> (),
}

---------- Variables ----------

local playerParts: {BasePart} = {}
local playerPartNames = {"HumanoidRootPart"}

---------- Local functions ----------

local function updatePlayerParts()
	playerParts = PlayerUtility.getAllPlayerParts(playerPartNames)
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

function Zone.setEnabled(self: ZoneType, enabled: boolean)
	self._enabled = enabled
end

function Zone._addActualParts(self: ZoneType, objects: {BasePart})
	-- Add zone parts
	self._actualParts:insertAll(objects, nil, "BasePart")
end

function Zone._removeActualParts(self: ZoneType, objects: {BasePart})
	-- Remove zone parts
	self._actualParts:removeValues(objects, nil, "BasePart")
end

function Zone.addIndividualParts(self: ZoneType, parts: {BasePart})
	-- Add individual parts
	self._individualParts:insertAll(parts, nil, "BasePart")
end

function Zone.removeIndividualParts(self: ZoneType, parts: {BasePart})
	-- Remove individual parts
	self._individualParts:removeValues(parts, nil, "BasePart")
end

function Zone.addZoneHolder(self: ZoneType, holder: Instance)
	-- Validate new holder
	if self._holders:isValueStored(holder) then
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

function Zone.removeZoneHolder(self: ZoneType, holder: Instance)
	-- Validate existing holder
	if not self._holders:isValueStored(holder) then
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

function Zone.getContainedPlayers(self: ZoneType)
	return self._containedPlayers
end

-- Signals
-- Define signal handling here

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
