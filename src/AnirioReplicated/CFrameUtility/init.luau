--!strict
-- CFrame Utility Module

-- A utility to perform common and complex CFrame calculations
-- Uses include turning and tilting parts upright

---------- Module ----------
local CFrameUtility = {}

---------- Variables ----------

local random = Random.new()

---------- Local functions ----------

local function getRandomUprightCFrame(position: Vector3, modelUpVector: Vector3?): CFrame
	-- Set up vector
	if not modelUpVector then
		modelUpVector = Vector3.yAxis
	end
	modelUpVector = modelUpVector.Unit

	-- Get random look vector
	local randomLookVector = random:NextUnitVector()
	while math.abs(randomLookVector:Dot(modelUpVector)) >= 0.9999 do
		randomLookVector = random:NextUnitVector()
	end

	-- Find orthogonal vectors
	local rightVector = randomLookVector:Cross(modelUpVector).Unit

	-- Generate CFrame
	local uprightCFrame = CFrame.fromMatrix(
		position,
		rightVector,
		modelUpVector
	)
	uprightCFrame = uprightCFrame:Orthonormalize()
	return uprightCFrame
end

local function getStandUprightCFrame(originalCFrame: CFrame, modelUpVector: Vector3?): CFrame
	-- Made with help from cozywitchcraft and heksi

	-- Set up vector
	if not modelUpVector then
		modelUpVector = Vector3.yAxis
	end
	modelUpVector = modelUpVector.Unit

	-- Check vertical look vector
	if math.abs(originalCFrame.LookVector.Unit:Dot(modelUpVector)) >= 0.9999 then
		-- Return random
		return getRandomUprightCFrame(originalCFrame.Position, modelUpVector)
	else
		-- Find orthogonal vectors
		local rightVector = originalCFrame.LookVector:Cross(modelUpVector).Unit

		-- Generate CFrame
		local uprightCFrame = CFrame.fromMatrix(
			originalCFrame.Position,
			rightVector,
			modelUpVector
		)
		uprightCFrame = uprightCFrame:Orthonormalize()
		return uprightCFrame
	end
end

local function getTiltUprightCFrame(originalCFrame: CFrame, modelUpVector: Vector3?): CFrame
	-- Set up vector
	if not modelUpVector then
		modelUpVector = Vector3.yAxis
	end
	modelUpVector = modelUpVector.Unit

	-- Check vertical look vector
	if math.abs(originalCFrame.LookVector.Unit:Dot(modelUpVector)) >= 0.9999 then
		-- Return original
		return originalCFrame
	else
		-- Find orthogonal vectors
		local rightVector = originalCFrame.LookVector:Cross(modelUpVector).Unit
		local upVector = rightVector:Cross(originalCFrame.LookVector).Unit

		-- Generate CFrame
		local tiltUprightCFrame = CFrame.fromMatrix(
			originalCFrame.Position,
			rightVector,
			upVector
		)
		tiltUprightCFrame = tiltUprightCFrame:Orthonormalize()
		return tiltUprightCFrame
	end
end

local function getMonaxialJointCFrame(mainCFrame: CFrame, otherCFrame: CFrame): CFrame
	-- Find relative rotation CFrame
	local standUprightCFrame = getStandUprightCFrame(otherCFrame, mainCFrame.UpVector)
	local jointCFrame = mainCFrame.Rotation:ToObjectSpace(standUprightCFrame.Rotation)
	return jointCFrame
end

---------- Module functions ----------

-- Get a random upright `CFrame` with the specified up vector
function CFrameUtility.getRandomUpright(position: Vector3, modelUpVector: Vector3?): CFrame
	return getRandomUprightCFrame(position, modelUpVector)
end

-- Get the upright `CFrame` with the `UpVector` equals to the given up vector
function CFrameUtility.getStandUpright(originalCFrame: CFrame, modelUpVector: Vector3?): CFrame
	return getStandUprightCFrame(originalCFrame, modelUpVector)
end

-- Get the upright `CFrame` without changing its `LookVector`
function CFrameUtility.getTiltUpright(originalCFrame: CFrame, modelUpVector: Vector3?): CFrame
	return getTiltUprightCFrame(originalCFrame, modelUpVector)
end

-- Get the relative rotation between two `CFrame` after equating the `UpVector`
function CFrameUtility.getMonaxialJoint(mainCFrame: CFrame, otherCFrame: CFrame): CFrame
	return getMonaxialJointCFrame(mainCFrame, otherCFrame)
end

---------- Return module ----------
return CFrameUtility
