--!strict
-- Spatial Query Utility Module

-- A utility to expand and simplify spatial query operations
-- Automatically switches query type depending on the shape of each part

---------- Module ----------
local SpatialQuery = {}

---------- Types ----------

local PartShape: {[string]: PartShape} = {
	Block = "Block",
	Sphere = "Sphere",
	Others = "Others",
}
type PartShape = "Block" | "Sphere" | "Others"

---------- Local functions ----------

-- Get the shape of the part used for spatial queries
local function getPartQueryShape(part: BasePart): PartShape
	-- Find out the part shape
	local partShape: PartShape = PartShape.Others
	if part:IsA("Part") then
		if part.Shape == Enum.PartType.Block then
			partShape = PartShape.Block
		elseif part.Shape == Enum.PartType.Ball then
			partShape = PartShape.Sphere
		end
	end

	return partShape
end

-- Get whitelisted parts inside a part
local function getWhitelistedInSinglePart(spatialPart: BasePart, whitelisted: {BasePart}): {BasePart}
	-- Initialize overlap parameters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams:AddToFilter(whitelisted)

	-- Get estimated parts
	local estimatedParts = workspace:GetPartBoundsInBox(spatialPart.CFrame, spatialPart.Size, overlapParams)

	-- Prepare to get actual parts
	overlapParams.FilterDescendantsInstances = estimatedParts
	local partShape = getPartQueryShape(spatialPart)

	-- Get actual parts
	local actualParts: {BasePart} = {}
	if partShape == PartShape.Block then
		actualParts = estimatedParts
	elseif partShape == PartShape.Sphere then
		local radius = math.min(spatialPart.Size.X, spatialPart.Size.Y, spatialPart.Size.Z) / 2
		actualParts = workspace:GetPartBoundsInRadius(spatialPart.Position, radius, overlapParams)
	else
		actualParts = workspace:GetPartsInPart(spatialPart, overlapParams)
	end

	-- Return parts
	return actualParts
end

-- Get whitelisted parts inside multiple parts
local function getWhitelistedInParts(spatialParts: {BasePart}, whitelisted: {BasePart}): {BasePart}
	-- Initialize parts
	local partsTable: {BasePart} = {}
	local partFoundState: {[BasePart]: boolean?} = {}

	-- Get parts in multiple parts
	for _, spatialPart in spatialParts do
		-- Get parts in single part
		local singlePartsTable = getWhitelistedInSinglePart(spatialPart, whitelisted)

		-- Add parts to table
		for _, part in singlePartsTable do
			-- Validate unique part
			if partFoundState[part] then
				continue
			end
			partFoundState[part] = true

			-- Add part to table
			table.insert(partsTable, part)
		end

		-- Updated whitelisted
		local newWhitelisted = {}
		for _, part in whitelisted do
			-- Validate not found
			if partFoundState[part] then
				continue
			end

			-- Add to new whitelist
			table.insert(newWhitelisted, part)
		end
		whitelisted = newWhitelisted
	end

	-- Return parts
	return partsTable
end

---------- Module functions ----------

-- Perform a spatial query with multiple spatial parts and a whitelisted filter
function SpatialQuery.getWhitelistedInParts(spatialParts: {BasePart}, whitelisted: {BasePart}): {BasePart}
	return getWhitelistedInParts(spatialParts, whitelisted)
end

---------- Return module ----------
return SpatialQuery
