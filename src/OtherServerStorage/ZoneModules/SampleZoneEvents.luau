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
local Timer = require(ReplicatedStorage["AnirioReplicated"].Timer)

local Trove = require(ReplicatedStorage["AnirioReplicated"].Packages.Trove)

---------- Variables ----------

local _teleportFunction = Servers.teleportNewReserve
local _countdownSeconds = 5

local timerTrove = Trove.new()
local timer: Timer.TimerType? = nil

local _maxPlayers = 4

local _placeId = 0
local _players: AnirioTable.TableType<Player> = AnirioTable.new()
local _teleportGui = ReplicatedStorage["StoredGuis"].EmptyScreenGui

---------- Local functions ----------

local function clearZone()
	timerTrove:Destroy()
	timer = nil
	_players:clear()
end

local function teleportPlayers()
	local zonePlayers = table.clone(_players:getArray())
	task.defer(function()
		_teleportFunction(_placeId, zonePlayers, _teleportGui)
	end)
	clearZone()
end

local function createNewTimer()
	-- Clear trove
	timerTrove:Destroy()

	-- Create new timer
	if timer then
		timer:destroy()
	end
	local newTimer = timerTrove:Add(Timer.new(_countdownSeconds))
	timer = newTimer

	-- Set up countdown (one tick)
	timerTrove:Add(newTimer.ticked:Once(teleportPlayers))
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

	-- Check if there's an existing timer
	local isNewTimer = false
	if not timer then
		isNewTimer = true

		-- Clear players
		clearZone()

		-- Create new timer
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
