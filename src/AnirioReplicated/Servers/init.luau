--!strict
-- Servers Utility Module

-- A utility to simplify teleporting players between places and servers
-- Automates various aspects of TeleportService and TeleportAsync

-- Note: Contains both server & client-sided code --> put in Replicated Storage
-- Plan: Support for teleporting to an old reserved server and to a specific server

---------- Module ----------
local Servers = {}

---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

---------- Instances ----------

local ServersRemoteEvent = script.ServersRemoteEvent

---------- Variables ----------

local _isServer = RunService:IsServer()

local _attemptLimit = 5
local _retryDelaySeconds = 1
local _floodDelaySeconds = 15

---------- Server-sided local functions ----------

-- Adapted from https://create.roblox.com/docs/projects/teleporting#handling-failed-teleports
local function safeTeleport(placeId: number, players: {Player}, teleportOptions: TeleportOptions): (boolean, any)
	-- Function variables
	local attempts = 0
	local success: boolean, result: any

	-- Try teleporting
	repeat
		success, result = pcall(function()
			return TeleportService:TeleportAsync(placeId, players, teleportOptions)
		end)
		attempts += 1
		if not success then
			task.wait(_retryDelaySeconds)
		end
	until success or attempts >= _attemptLimit

	-- Report failure
	if not success then
		warn(result)
	end

	-- Return
	return success, result
end

-- Adapted from https://create.roblox.com/docs/projects/teleporting#handling-failed-teleports
local function onTeleportInitFailed(player: Player, teleportResult: Enum.TeleportResult, errorMessage: string, placeId: number, teleportOptions: TeleportOptions)
	-- Handle different failures
	if teleportResult == Enum.TeleportResult.Flooded then
		task.wait(_floodDelaySeconds)
	elseif teleportResult == Enum.TeleportResult.Failure then
		task.wait(_retryDelaySeconds)
	else
		local errorString = `Invalid teleport [{teleportResult.Name}]: {errorMessage}`
		error(errorString)
	end

	-- Retry teleport
	safeTeleport(placeId, {player}, teleportOptions)
end

-- Fire an event to the client to set the teleport gui
local function setTeleportGui(playersTable: {Player}, teleportGui: ScreenGui?)
	-- Validate teleport gui
	if not teleportGui then
		return
	end

	-- Fire remote events to players
	for _, player in playersTable do
		ServersRemoteEvent:FireClient(player, "SetTeleportGui", teleportGui)
	end

	-- Small delay after firing
	task.wait(0.3)
end

-- Teleport players to a newly reserved server
local function teleportToNewReserveServer(placeId: number, players: {Player}, teleportGui: ScreenGui?)
	if not _isServer then
		warn("teleportToNewReserveServer() can only be called from the server!")
		return
	end

	-- Set teleport gui
	setTeleportGui(players, teleportGui)

	-- Set teleport options
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ShouldReserveServer = true

	-- Teleport
	safeTeleport(placeId, players, teleportOptions)
end

-- Teleport players to a place using default teleport options
local function teleport(placeId: number, players: {Player}, teleportGui: ScreenGui?)
	if not _isServer then
		warn("teleportToNewReserveServer() can only be called from the server!")
		return
	end

	-- Set teleport gui
	setTeleportGui(players, teleportGui)

	-- Set teleport options
	local teleportOptions = Instance.new("TeleportOptions")

	-- Teleport
	safeTeleport(placeId, players, teleportOptions)
end

---------- Client-sided local functions ----------

-- Set the client's teleport gui to the given `ScreenGui`
local function clientOnSetTeleportGui(teleportGui: ScreenGui)
	-- Validate gui
	if not (teleportGui and teleportGui:IsA("ScreenGui")) then
		return
	end

	-- Set teleport gui (this function only works on client)
	TeleportService:SetTeleportGui(teleportGui)

	-- Validate player gui
	local playerGui = Players.LocalPlayer.PlayerGui
	if not playerGui then
		return
	end

	-- Parent teleport gui
	teleportGui.Parent = playerGui
end

---------- Client-sided event functions ----------

-- Call different functions depending on the string sent
local function onClientEvent(mode: string, ...: any)
	-- Handle modes
	if mode == "SetTeleportGui" then
		clientOnSetTeleportGui(...)
	end
end

---------- Module functions ----------

-- Teleport players to a place in a newly reserved server
function Servers.teleportNewReserve(placeId: number, players: {Player}, teleportGui: ScreenGui)
	teleportToNewReserveServer(placeId, players, teleportGui)
end

-- Teleport players to a place
function Servers.teleportNormal(placeId: number, players: {Player}, teleportGui: ScreenGui)
	teleport(placeId, players, teleportGui)
end

---------- Calling / connecting functions ----------

if _isServer then
	TeleportService.TeleportInitFailed:Connect(onTeleportInitFailed)
else
	ServersRemoteEvent.OnClientEvent:Connect(onClientEvent)
end

---------- Return module ----------
return Servers
