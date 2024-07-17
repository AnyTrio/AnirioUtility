--!strict
-- Module Tester Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------- Imports ----------

local AnirioTable = require(ReplicatedStorage["AnirioReplicated"].AnirioTable)
local CFrameUtility = require(ReplicatedStorage["AnirioReplicated"].CFrameUtility)
local Character = require(ReplicatedStorage["AnirioReplicated"].Character)
local PlayerUtility = require(ReplicatedStorage["AnirioReplicated"].PlayerUtility)
local Timer = require(ReplicatedStorage["AnirioReplicated"].Timer)

local Signal = require(ReplicatedStorage["AnirioReplicated"].Signal)

---------- Local functions ----------
-- Define general functions here

local function testAnirioTable()
	local stored = AnirioTable.new()
	print(table.unpack(stored._tableArray))
	--
	stored:insertAll({1, 2, 3})
	print(table.unpack(stored._tableArray))
	-- 1 2 3
	print(stored:compareTableChanges({1, 1, 2, 2, 4, 5}))
	-- {1, 2, 4, 5} {3}
	stored:insertUnique({1, 2, 3, 4, 5, 4, 5})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5
	print(stored:getValueState(1), stored:getValueState(2), stored:getValueState(3), stored:getValueState(-1), stored:getValueState(0))
	-- 1 1 1 0 0
	stored:removeValues({1, 2, 3})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5
	stored:removeValues({4, 5})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5
	print(table.unpack(stored:getArray()))
	--
	stored:insertUnique({1, 1, 2, 3, 3, 3, 4, 5, 5})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5
	print(stored:contains(1), stored:contains(2), stored:contains(3), stored:contains(4), stored:contains(5), stored:contains(6), stored:contains(-1))
	-- true true true true true false false
	stored:insertAll({1, 2, 3, 4, 5})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5 1 2 3 4 5
	print(stored:getValueState(1), stored:getValueState(2), stored:getValueState(3), stored:getValueState(-1), stored:getValueState(0))
	-- 2 2 2 0 0
	print(stored._tableValueState)
	-- {[1]: 2, [2]: 2, [3]: 2, [4]: 2, [5]: 2}
	stored:removeValues({1, 1, 2, 2, 3, 4})
	print(table.unpack(stored._tableArray))
	-- 1 2 3 4 5 1 2 3 4 5
	print(stored:getValueState(1), stored:getValueState(2), stored:getValueState(3), stored:getValueState(4), stored:getValueState(5))
	-- 0, 0, 1, 1, 2
	print(stored:contains(1), stored:contains(2), stored:contains(3), stored:contains(4), stored:contains(5), stored:contains(6), stored:contains(-1))
	-- false false true true true false false
	print("the following prints might contain nil holes")
	-- the following prints might contain "nil holes"
	print(stored._tableValueState)
	-- {[3]: 1, [4]: 1, [5]: 2}
	stored:insertAll({1, 2, 3, 4, 5})
	print(table.unpack(stored._tableArray))
	-- 5 3 4 5 1 2 3 4 5
	stored:removeValues({1, 2, 3, 4, 5, 5})
	print(table.unpack(stored._tableArray))
	-- 5 3 4 5 1 2 3 4 5
	print(stored:getArray())
	-- {3, 4, 5}
	print(stored._tableValueState)
	-- {[3]: 1, [4]: 1, [5]: 1}
	stored:insertAll({"a", "ab", "abacaba"})
	print(table.unpack(stored._tableArray))
	-- 3, 4, 5, a, ab, abacaba
	print(stored._tableValueState)
	-- {[3]: 1, [4]: 1, [5]: 1, a: 1, ab: 1, abacaba: 1}
	stored:removeValues({"a", "abacaba"})
	print(table.unpack(stored._tableArray))
	-- 3, 4, 5, ab
	print(stored._tableValueState)
	-- {[3]: 1, [4]: 1, [5]: 1, a: 1, ab: 1, abacaba: 1}
	print(stored:contains("a"), stored:contains("ab"), stored:contains("abacaba"))
	-- false, true, false
	print(stored._tableValueState)
	-- {[3]: 1, [4]: 1, [5]: 1, ab: 1}
end

local function testCFrameUtility()
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(2, 1, 4)
	part.Size = part.Size * 10
	part.Parent = workspace
	for i = 1, 512 do
		local cframe = CFrameUtility.getRandom(part.Position)
		if true then
			local p = part:Clone()
			p.CFrame = cframe
			p.Parent = workspace
		end
	end
	for i = 1, 3 do
		local x = (i == 1 and 1) or 0
		local y = (i == 2 and 1) or 0
		local z = (i == 3 and 1) or 0
		local upVector = Vector3.new(x, y, z)
		for j = 1, 256 do
			local cframe = CFrameUtility.getRandomUpright(part.Position, upVector)
			print(cframe.UpVector)
			if false then
				part.CFrame = cframe
				task.wait(0.05)
			end
		end
	end
	local random = Random.new()
	for i = 1, 3 do
		print(`i: {i}`)
		local upVector = random:NextUnitVector()
		for j = 1, 256 do
			local cframe = CFrameUtility.getRandomUpright(part.Position, upVector)
			print(cframe.UpVector:FuzzyEq(upVector))
			if false then
				part.CFrame = cframe
				task.wait(0.05)
			end
		end
	end
	for i = 1, 3 do
		print(`i: {i}`)
		local x = (i == 1 and 1) or 0
		local y = (i == 2 and 1) or 0
		local z = (i == 3 and 1) or 0
		local upVector = Vector3.new(x, y, z)
		for j = 1, 256 do
			local randomUpVector = random:NextUnitVector()
			local randomCFrame = CFrameUtility.getRandomUpright(part.Position, randomUpVector)
			local cframe = CFrameUtility.getStandUpright(randomCFrame, upVector)
			print(cframe.UpVector:FuzzyEq(upVector))
			if false then
				part.CFrame = randomCFrame
				task.wait(0.15)
				part.CFrame = cframe
				task.wait(0.3)
			end
		end
	end
	for i = 1, 3 do
		print(`i: {i}`)
		local x = (i == 1 and 1) or 0
		local y = (i == 2 and 1) or 0
		local z = (i == 3 and 1) or 0
		local upVector = Vector3.new(x, y, z)
		for j = 1, 256 do
			local randomUpVector = random:NextUnitVector()
			local randomCFrame = CFrameUtility.getRandomUpright(part.Position, randomUpVector)
			local cframe = CFrameUtility.getTiltUpright(randomCFrame, upVector)
			print(cframe.LookVector:FuzzyEq(randomCFrame.LookVector))
			if false then
				part.CFrame = randomCFrame
				task.wait(0.15)
				part.CFrame = cframe
				task.wait(0.3)
			end
		end
	end
	for i = 1, 3 do
		print(`i: {i}`)
		for j = 1, 256 do
			local randomUpVector = random:NextUnitVector()
			randomUpVector = Vector3.yAxis
			local randomCFrame1 = CFrameUtility.getRandomUpright(part.Position, randomUpVector)
			local randomRotation = CFrameUtility.getRandomUpright(part.Position, randomUpVector).Rotation
			randomUpVector = random:NextUnitVector()
			local randomCFrame2 = randomCFrame1:ToWorldSpace(randomRotation)
			randomCFrame2 = CFrameUtility.getStandUpright(randomCFrame2, randomUpVector)
			local jointCFrame = CFrameUtility.getMonaxialJoint(randomCFrame1, randomCFrame2)

			-- Get the relative rotation between upright cframes (this is what `getMonaxialJoint()` does)
			local uprightCFrame = CFrameUtility.getStandUpright(randomCFrame2, randomCFrame1.UpVector)
			local uprightRotation = randomCFrame1.Rotation:ToObjectSpace(uprightCFrame.Rotation)

			assert(jointCFrame.LookVector:FuzzyEq(uprightRotation.LookVector))
			assert(jointCFrame.UpVector:FuzzyEq(uprightRotation.UpVector))
			assert(jointCFrame.RightVector:FuzzyEq(uprightRotation.RightVector))
		end
	end
	print("Completed")
end

local function testCharacter()
	for i = 1, 100 do
		local humanoidRootParts = PlayerUtility.getAllPlayerParts({"HumanoidRootPart"})
		if #humanoidRootParts > 0 then
			print("Found HumanoidRootPart:", #humanoidRootParts)
			local character = Character.fromPart(humanoidRootParts[1])
			print("1st character:", character)
			print("Player:", Character.getPlayer(character))
		end
		task.wait(1)
	end
end

local function testPlayerUtility()
	PlayerUtility.CharacterAdded:Connect(function(player: Player, character: Model)
		print("Character added for", player, character)
		print("Parts:", PlayerUtility.getParts(player))
	end)
	PlayerUtility.CharacterRemoving:Connect(function(player: Player, character: Model)
		print("Character removing for", player, character)
	end)
	for i = 1, 100 do
		local humanoidRootParts = PlayerUtility.getAllPlayerParts({"HumanoidRootPart"})
		if #humanoidRootParts > 0 then
			print("Found HumanoidRootPart:", #humanoidRootParts)
			print("Players from parts:", table.unpack(PlayerUtility.fromCharacterParts(humanoidRootParts)))
		end
		task.wait(1)
	end
end

local function testRaycast()

end

local function testServers()

end

local function testSpatialQuery()

end

local function testTimer()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://142376088"
	sound.Parent = workspace

	local timer = Timer.new(1 / (138 / 60) * 4)
	timer:setAllowDrift(false)
	timer:setTimeFunction(function()
		return sound.TimePosition
	end)
	timer:setUpdateSignal(RunService.Heartbeat)

	local connection: Signal.Connection
	connection = timer.ticked:Connect(function(totalTicks: number, signalTicks: number)
		-- Calculate delta
		local delta = math.sign(signalTicks)
		if delta == 0 then
			delta = 1
		end

		-- Go through all ticks
		for tick = totalTicks - signalTicks + delta, totalTicks, delta do
			print(`Tick: {tick}`)
			-- print(`TickTime: {timer:getElapsedTime()}`)
			if math.abs(tick) == 10 then
				-- Won't work when running
				timer:start()
				timer:unpause()
			end
			if math.abs(tick) == 20 then
				-- Pausing
				timer:pause()
				-- task.wait(2)
				timer:unpause()
			end
			if math.abs(tick) >= 101 then
				connection:Disconnect()
				return
			end
		end
	end)

	task.wait(0.5)
	timer:start(false)
	sound:Play()
end

local function testZone()

end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

testSpatialQuery()
