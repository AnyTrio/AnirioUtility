--!strict
-- Character Utility Module

---------- Module ----------
local Character = {}

---------- Services ----------

local Players = game:GetService("Players")

---------- Local functions ----------

local function getAndValidateCharacterFromPart(part: BasePart): Model?
	-- Validate part
	if not part:IsA("BasePart") then
		return nil
	end
	
	-- Validate character
	local character = part.Parent
	if not (character and character:IsA("Model")) then
		return nil
	end

	-- Validate humanoid
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return nil
	end

	-- Return
	return character
end

---------- Module functions ----------

-- Retrieve a character model from a children part; fail if the model doesn't have a Humanoid
function Character.fromPart(part: BasePart): Model?
	return getAndValidateCharacterFromPart(part)
end

-- Retrieve the Player object from a character model
function Character.getPlayer(character: Model?): Player?
	local player: Player?
	player = character and Players:GetPlayerFromCharacter(character)
	return player
end

---------- Return module ----------
return Character
