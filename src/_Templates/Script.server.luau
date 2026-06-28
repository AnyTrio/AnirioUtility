--!strict

-- Script Template

-- Template by Panicks28


---------- Validate environment ----------

local RunService = game:GetService("RunService")

-- For certain plugin scripts
if not RunService:IsEdit() then
	return
end


---------- Validate container ----------
-- Validate the script's container before running any code

-- For tools
if script:FindFirstAncestorWhichIsA("StarterPack") then
	return
end

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

-- Player scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")

---------- Imports ----------

---------- Types ----------

---------- Constants ----------

---------- Globals ----------

---------- Local functions ----------

----- Event functions -----

----- Main -----

local function main()

end

---------- Calling function ----------

main()
