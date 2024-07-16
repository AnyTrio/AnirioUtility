--!strict
-- CFrame Utility Module

-- A utility to perform common and complex CFrame calculations
-- Uses include turning and tilting parts upright

---------- Module ----------
local CFrameUtility = {}

---------- Variables ----------

local random = Random.new()

---------- Local functions ----------

local function canCross(vector1: Vector3, vector2: Vector3): boolean
	return math.abs(vector1.Unit:Dot(vector2.Unit)) < 0.9999
end

local function getRandomCFrame(_position: Vector3): CFrame
	-- Set up position
	local position = _position or Vector3.zero

	-- Get random look and up vectors
	local randomLookVector = random:NextUnitVector()
	local randomUpVector = random:NextUnitVector()
	while not canCross(randomLookVector, randomUpVector) do
		randomUpVector = random:NextUnitVector()
	end

	-- Generate CFrame
	local randomCFrame = CFrame.lookAlong(position, randomLookVector, randomUpVector)
	randomCFrame = randomCFrame:Orthonormalize()
	return randomCFrame
end

local function getRandomUprightCFrame(position: Vector3, _upVector: Vector3?): CFrame
	-- Set up vector
	local modelUpVector = _upVector or Vector3.yAxis
	modelUpVector = modelUpVector.Unit

	-- Get random look vector
	local randomLookVector = random:NextUnitVector()
	while not canCross(modelUpVector, randomLookVector) do
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

local function getStandUprightCFrame(originalCFrame: CFrame, _upVector: Vector3?): CFrame
	-- Made with help from cozywitchcraft and heksi

	-- Set up vector
	local modelUpVector = _upVector or Vector3.yAxis
	modelUpVector = modelUpVector.Unit

	-- Check vertical look vector
	if not canCross(originalCFrame.LookVector, modelUpVector) then
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

local function getTiltUprightCFrame(originalCFrame: CFrame, _upVector: Vector3?): CFrame
	-- Set up vector
	local modelUpVector = _upVector or Vector3.yAxis
	modelUpVector = modelUpVector.Unit

	-- Check vertical look vector
	if not canCross(originalCFrame.LookVector, modelUpVector) then
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

-- Get a `CFrame` with a psuedorandom orientation
function CFrameUtility.getRandom(position: Vector3?): CFrame
	return getRandomCFrame(position)
end

-- Get a random upright `CFrame` with the specified up vector
function CFrameUtility.getRandomUpright(position: Vector3, upVector: Vector3?): CFrame
	return getRandomUprightCFrame(position, upVector)
end

-- Get the upright `CFrame` with the `UpVector` equals to the given up vector
function CFrameUtility.getStandUpright(originalCFrame: CFrame, upVector: Vector3?): CFrame
	return getStandUprightCFrame(originalCFrame, upVector)
end

-- Get the upright `CFrame` without changing its `LookVector`
function CFrameUtility.getTiltUpright(originalCFrame: CFrame, upVector: Vector3?): CFrame
	return getTiltUprightCFrame(originalCFrame, upVector)
end

-- Get the relative rotation between two `CFrame` after equating the `UpVector`
function CFrameUtility.getMonaxialJoint(mainCFrame: CFrame, otherCFrame: CFrame): CFrame
	return getMonaxialJointCFrame(mainCFrame, otherCFrame)
end

---------- Return module ----------
return CFrameUtility
