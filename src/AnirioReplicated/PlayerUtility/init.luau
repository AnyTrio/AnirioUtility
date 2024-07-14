--!strict
-- Player Utility Module

-- A utility to provide more features to the Players service
-- Includes CharacterAdded and Removing signals/events for all players, which simplifies connections

---------- Module ----------
local PlayerUtility = {}

---------- Services ----------

local Players = game:GetService("Players")

---------- Imports ----------

local AnirioReplicated = script.Parent
local Character = require(AnirioReplicated.Character)

local Packages = AnirioReplicated["Packages"] or AnirioReplicated.Parent["Packages"] or AnirioReplicated
local Signal = require(Packages.Signal)

---------- Module variables ----------

-- Fires when any player's character spawns or respawns
PlayerUtility.CharacterAdded = Signal.new() :: Signal.Signal<Player, Model>

-- Fires right before any player's character is removed
PlayerUtility.CharacterRemoving = Signal.new() :: Signal.Signal<Player, Model>

---------- Local functions ----------

-- Get players from character model parts
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

-- Get parts of a given player's character model with names specified by `includePartNames`
local function getSinglePlayerParts(player: Player, includePartNames: {string}?): {BasePart}
	-- Validate character
	local character = player.Character
	if not character then
		return {}
	end

	-- Set up part names state
	local ignoreName = (includePartNames == nil)
	local findName: {[string]: boolean} = {}
	if not ignoreName then
		for _, name in includePartNames do
			-- Validate string
			if not (typeof(name) == "string") then
				continue
			end

			-- Set name state
			findName[name] = true
		end
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

-- Get parts by calling `getSinglePlayerParts()` for all players with the same argument
local function getAllPlayerParts(includePartNames: {string}?): {BasePart}
	-- Initialize parts
	local partsTable: {BasePart} = {}

	-- Get parts in all players
	for _, player in Players:GetPlayers() do
		-- Get parts in player
		local singlePartsTable = getSinglePlayerParts(player, includePartNames)

		-- Add parts to table
		for _, part in singlePartsTable do
			table.insert(partsTable, part)
		end
	end

	-- Return parts
	return partsTable
end

---------- Event functions ----------

-- Connect the player's character signals to the utility's signal
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

-- Get the `BasePart` children of a player's character model
function PlayerUtility.getParts(player: Player, includePartNames: {string}?): {BasePart}
	return getSinglePlayerParts(player, includePartNames)
end

-- Get the `BasePart` children of all players current character models
function PlayerUtility.getAllPlayerParts(includePartNames: {string}?): {BasePart}
	return getAllPlayerParts(includePartNames)
end

---------- Calling / connecting functions ----------

Players.PlayerAdded:Connect(onPlayerAdded)

---------- Return module ----------
return PlayerUtility
