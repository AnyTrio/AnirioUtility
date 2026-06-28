--!strict

-- Spatial Query

-- A utility to expand and simplify spatial query operations
-- Automatically switches query type depending on the shape of each part


---------- Types ----------

type PartShape = "Block" | "Sphere" | "Others"


---------- Constants ----------

local Constants = {}

Constants.partShape = {
    Block = "Block",
    Sphere = "Sphere",
    Others = "Others",
} :: {[string]: PartShape}

table.freeze(Constants)


---------- Local functions ----------

local getPartQueryShape
local getInstanceArray
local arrayToSet

local getPartsInSinglePart
local getPartsInParts

local getWhitelistedInParts


----- Helper functions -----

--- Gets the shape of the part used for spatial queries
getPartQueryShape = function(part: BasePart): PartShape
    -- Find out the part shape
    local partShape: PartShape = Constants.partShape.Others
    if part:IsA("Part") then
        if part.Shape == Enum.PartType.Block then
            partShape = Constants.partShape.Block
        elseif part.Shape == Enum.PartType.Ball then
            partShape = Constants.partShape.Sphere
        end
    end

    return partShape
end

--- Gets valid `Instance` values from the given array
getInstanceArray = function(array: {any}): {Instance}
    local result = {}
    for _, object in array do
        if typeof(object) == "Instance" then
            table.insert(result, object)
        end
    end
    return result
end

--- Converts array of values to a value-exists dictionary.
arrayToSet = function<T>(array: {T}): {[T]: true?}
    local result = {} :: {[T]: true?}
    for _, value in array do
        result[value] = true
    end
    return result
end


----- Spatial query -----

--[[
Performs a spatial query efficiently depending on the shape of the spatial part.
@param worldRoot The world root used for querying.
@param spatialParts List of parts used for querying.
@param desiredOverlapParams The spatial query parameters.
@return An array of parts overlapping the spatial part.
]]
getPartsInSinglePart = function(worldRoot: WorldRoot, spatialPart: BasePart, desiredOverlapParams: OverlapParams): {BasePart}
    -- Clone overlap params
    local newOverlapParams = OverlapParams.new()
    newOverlapParams.CollisionGroup = desiredOverlapParams.CollisionGroup
    newOverlapParams.ExcludeInstances = desiredOverlapParams.ExcludeInstances
    newOverlapParams.IncludeInstances = desiredOverlapParams.IncludeInstances
    newOverlapParams.MaxParts = desiredOverlapParams.MaxParts
    newOverlapParams.RespectCanCollide = desiredOverlapParams.RespectCanCollide
    newOverlapParams.Tolerance = desiredOverlapParams.Tolerance

    -- Clone legacy properties
    newOverlapParams.FilterDescendantsInstances = desiredOverlapParams.FilterDescendantsInstances
    newOverlapParams.FilterType = desiredOverlapParams.FilterType

    -- Get estimated parts
    local extentsCFrame = spatialPart.ExtentsCFrame
    local extentsSize = spatialPart.ExtentsSize
    local estimatedParts = worldRoot:GetPartBoundsInBox(extentsCFrame, extentsSize, newOverlapParams)

    -- Prepare to get actual parts
    newOverlapParams.IncludeInstances = getInstanceArray(estimatedParts)
    local partShape = getPartQueryShape(spatialPart)

    -- Get actual parts
    local actualParts: {BasePart} = {}
    if partShape == Constants.partShape.Block then
        actualParts = estimatedParts
    elseif partShape == Constants.partShape.Sphere then
        local radius = math.min(extentsSize.X, extentsSize.Y, extentsSize.Z) / 2
        actualParts = worldRoot:GetPartBoundsInRadius(extentsCFrame.Position, radius, newOverlapParams)
    else
        actualParts = worldRoot:GetPartsInPart(spatialPart, newOverlapParams)
    end

    -- Return parts
    return actualParts
end

--[[
Performs a spatial query with one or more spatial parts.
@param worldRoot The world root used for querying.
@param spatialParts List of parts used for querying.
@param desiredOverlapParams The spatial query parameters.
@return An array of parts overlapping the spatial parts.
]]
getPartsInParts = function(worldRoot: WorldRoot, spatialParts: {BasePart}, desiredOverlapParams: OverlapParams): {BasePart}
    -- Initialize parts
    local part_foundState = {} :: {[BasePart]: true?}
    local part_isSpatial = arrayToSet(spatialParts)
    local result = {} :: {BasePart}

    -- Get parts in multiple parts
    for _, spatialPart in spatialParts do
        -- Get parts in single part
        local singlePartsTable = getPartsInSinglePart(worldRoot, spatialPart, desiredOverlapParams)

        -- Add unique parts to table
        for _, part in singlePartsTable do
            -- Validate not spatial
            if part_isSpatial[part] then
                continue
            end

            -- Validate unique part
            if part_foundState[part] then
                continue
            end
            part_foundState[part] = true

            -- Add part to table
            table.insert(result, part)
        end
    end

    -- Return parts
    return result
end


----- UX spatial query -----

--[[
Performs a spatial query with one or more spatial parts and a whitelist (inclusion) filter.
@param spatialParts List of parts used for querying.
@param whitelistedAncestors List of instances included in the query. The descendants of each are also included. Default includes all.
@param collisionGroup The collision group used for querying. Default is `"Default"`.
@param worldRoot The world root used for querying. Default is `workspace`.
@return An array of whitelisted parts overlapping the spatial parts.
]]
getWhitelistedInParts = function(spatialParts: {BasePart}, whitelistedAncestors: {Instance}?, collisionGroup: string?, worldRoot: WorldRoot?): {BasePart}
    -- Initialize overlap parameters
    local overlapParams = OverlapParams.new()
    overlapParams.CollisionGroup = collisionGroup or "Default"
    if whitelistedAncestors then
        overlapParams.IncludeInstances = whitelistedAncestors
    end

    -- Return parts
    return getPartsInParts(worldRoot or workspace, spatialParts, overlapParams)
end


---------- Module ----------

local Module = {}


----- Module fields -----

Module.getPartsInParts = getPartsInParts
Module.getWhitelistedInParts = getWhitelistedInParts


---------- Return module ----------

table.freeze(Module)
return Module
