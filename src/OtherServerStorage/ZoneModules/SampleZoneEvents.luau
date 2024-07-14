--!strict
-- Sample Zone Events Module

-- Plan: change the place id

---------- Module ----------
local ZoneEvents = {}

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local AnirioTable = require(ReplicatedStorage["AnirioReplicated"].AnirioTable)
local Servers = require(ReplicatedStorage["AnirioReplicated"].Servers)
local TimerUtility = require(ReplicatedStorage["AnirioReplicated"].Timer)

local Trove = require(ReplicatedStorage["AnirioReplicated"].Packages.Trove)

---------- Variables ----------

local timerTrove: Trove.Trove? = nil
local timer: TimerUtility.TimerType? = nil
local _countdownSeconds = 5

local _maxPlayers = 4

local _placeId = 0
local _players: AnirioTable.TableType<Player> = AnirioTable.new()
local _teleportGui = ReplicatedStorage["StoredGuis"].EmptyScreenGui

---------- Local functions ----------

local function clearZone()
	if timerTrove then
		timerTrove:Destroy()
	end
	timerTrove = nil
	timer = nil
	_players:clear()
end

local function teleportPlayers()
	local zonePlayers = table.clone(_players:getArray())
	task.defer(function()
		Servers.teleportNewReserve(_placeId, zonePlayers, _teleportGui)
	end)
	clearZone()
end

local function createNewTimer()
	-- Set up trove
	if timerTrove then
		timerTrove:Destroy()
	end
	local trove = Trove.new()
	timerTrove = trove

	-- Create new timer
	if timer then
		timer:destroy()
	end
	local newTimer = trove:Add(TimerUtility.new(_countdownSeconds))
	timer = newTimer

	-- Set up countdown (one tick)
	newTimer.ticked:Once(teleportPlayers)
end

local function startTimer()
	-- Validate timer
	if not timer then
		return
	end

	-- Start timer
	timer:start(false)
end

---------- Module functions ----------

function ZoneEvents.onEntered(player: Player)
	-- Validate max players
	if #_players:getArray() >= _maxPlayers then
		return
	end

	-- Validate unique player
	if _players:contains(player) then
		return
	end

	-- Create new timer if none
	local isNewTimer = false
	if not timer then
		isNewTimer = true
		clearZone()
		createNewTimer()
	end

	-- Add player
	_players:insertAll({player})

	-- Start timer if new
	if isNewTimer then
		startTimer()
	end
end

function ZoneEvents.onExited(player: Player)
	-- Validate stored player
	if not _players:contains(player) then
		return
	end

	-- Remove player
	_players:removeValues({player})

	-- Clear timer if no players in zone
	if #_players:getArray() == 0 then
		clearZone()
	end
end

---------- Return ----------
return ZoneEvents
