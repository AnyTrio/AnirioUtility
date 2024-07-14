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

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

testAnirioTable()
