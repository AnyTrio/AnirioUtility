--!strict
-- Player Utility Module

---------- Module ----------
local PlayerUtility = {}

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local AnirioReplicated = script.Parent
local Character = require(AnirioReplicated.Character)

local Signal = require(ReplicatedStorage["Sleitnick's"].Signal)

---------- Module variables ----------

PlayerUtility.CharacterAdded = Signal.new() :: Signal.Signal<Player, Model>
PlayerUtility.CharacterRemoving = Signal.new() :: Signal.Signal<Player, Model>

---------- Local functions ----------

local function getPlayersFromParts(partsTable: {BasePart}): {Player}
	-- Initialize players
	local players: {Player} = {}
	local playerFoundState: {[Player]: boolean?} = {}

	-- Get players in the table
	for _, part in partsTable do
		-- Validate the player the part belongs to
		local character = Character.fromPart(part)
		local player = Character.getPlayer(character)
		if not (player and player:IsA("Player")) then
			continue
		end

		-- Validate unique player
		if playerFoundState[player] then
			continue
		end
		playerFoundState[player] = true

		-- Add player to table
		table.insert(players, player)
	end

	-- Return
	return players
end

local function getSinglePlayerParts(player: Player, partNames: {string}): {BasePart}
	-- Validate character
	local character = player.Character
	if not character then
		return {}
	end

	-- Set up part names state
	local ignoreName = (#partNames == 0)
	local findName: {[string]: boolean} = {}
	for _, name in partNames do
		-- Validate string
		if not (typeof(name) == "string") then
			continue
		end

		-- Set name state
		findName[name] = true
	end

	-- Initialize parts
	local partsTable: {BasePart} = {}

	-- Get parts in character
	for _, object in character:GetChildren() do
		-- Validate part
		if not object:IsA("BasePart") then
			continue
		end

		-- Validate part name
		if not (ignoreName or findName[object.Name]) then
			continue
		end

		-- Add part to table
		table.insert(partsTable, object)
	end

	-- Return parts
	return partsTable
end

local function getAllPlayerParts(partNames: {string}): {BasePart}
	-- Initialize parts
	local partsTable: {BasePart} = {}

	-- Get parts in all players
	for _, player in Players:GetPlayers() do
		-- Get parts in player
		local singlePartsTable = getSinglePlayerParts(player, partNames)

		-- Add parts to table
		table.move(singlePartsTable, 1, #singlePartsTable, #partsTable + 1, partsTable)
	end

	-- Return parts
	return partsTable
end

---------- Event functions ----------

local function onPlayerAdded(player: Player)
	if player.Character then
		task.defer(function()
			PlayerUtility.CharacterAdded:Fire(player, player.Character)
		end)
	end
	player.CharacterAdded:Connect(function(character: Model)
		PlayerUtility.CharacterAdded:Fire(player, character)
	end)
	player.CharacterRemoving:Connect(function(character: Model)
		PlayerUtility.CharacterRemoving:Fire(player, character)
	end)
end

---------- Module functions ----------

-- Get players from a mix of character parts and other parts
function PlayerUtility.fromCharacterParts(parts: {BasePart}): {Player}
	return getPlayersFromParts(parts)
end

-- Get the base-part children of a player's character model
function PlayerUtility.getParts(player: Player, partNames: {string}): {BasePart}
	return getSinglePlayerParts(player, partNames)
end

-- Get the base-part children of the character models of all players currently in the server
function PlayerUtility.getAllPlayerParts(partNames: {string}): {BasePart}
	return getAllPlayerParts(partNames)
end

---------- Calling / connecting functions ----------

Players.PlayerAdded:Connect(onPlayerAdded)

---------- Return module ----------
return PlayerUtility
