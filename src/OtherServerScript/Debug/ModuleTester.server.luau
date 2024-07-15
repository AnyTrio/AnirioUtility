--!strict
-- Module Tester Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local AnirioTable = require(ReplicatedStorage["AnirioReplicated"].AnirioTable)
local CFrameUtility = require(ReplicatedStorage["AnirioReplicated"].CFrameUtility)

---------- Local functions ----------
-- Define general functions here

local function testAnirioTable()
	local stored = AnirioTable.new()
	print(table.unpack(stored._tableArray))
	stored:insertAll({1, 2, 3})
	print(table.unpack(stored._tableArray))
	stored:insertUnique({1, 2, 3, 4, 5, 4, 5})
	print(table.unpack(stored._tableArray))
	stored:removeValues({1, 2, 3})
	print(table.unpack(stored._tableArray))
	stored:removeValues({4, 5})
	print(table.unpack(stored._tableArray))
	print(table.unpack(stored:getArray()))
	stored:insertUnique({1, 1, 2, 3, 3, 3, 4, 5, 5})
	print(table.unpack(stored._tableArray))
	stored:insertAll({1, 2, 3, 4, 5})
	print(table.unpack(stored._tableArray))
	stored:removeValues({1, 1, 2, 2, 3, 4})
	print(table.unpack(stored._tableArray))
	stored:insertAll({1, 2, 3, 4, 5})
	print(table.unpack(stored._tableArray))
	stored:removeValues({1, 2, 3, 4, 5, 5})
	print(table.unpack(stored._tableArray))
	print(table.unpack(stored:getArray()))
end

local function testCFrameUtility()
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(2, 1, 4)
	part.Size *= 10
	-- part.Size = part.Size * 10
	part.Parent = workspace
	for i = 1, 3 do
		local x = (i == 1 and 1) or 0
		local y = (i == 2 and 1) or 0
		local z = (i == 3 and 1) or 0
		local upVector = Vector3.new(x, y, z)
		for j = 1, 100 do
			part.CFrame = CFrameUtility.getRandomUpright(part.Position, upVector)
			print(part.CFrame.UpVector)
			task.wait(0.05)
		end
	end
end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

testCFrameUtility()
