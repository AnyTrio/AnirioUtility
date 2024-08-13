--!strict
-- Script Template

-- Template by Panicks28

---------- Validate environment ----------
-- Validate the script's environment before running any code

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

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")

---------- Imports ----------

---------- Types ----------

---------- Instances ----------

---------- Variables ----------

---------- Local functions ----------
-- Define general functions here

---------- Event functions ----------
-- Functions that are directly connected by events or signals

---------- Set up function ----------
local function initSetUp()

end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

initSetUp()
