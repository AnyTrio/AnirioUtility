--!strict
-- Position Teleporters Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
    return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local Character = require(ReplicatedStorage["AnirioReplicated"].Character)

local Trove = require(ReplicatedStorage["Sleitnick's"].Trove)

---------- Variables ----------

local tagName = "PositionTeleporters"

local interactionContainerName = "Teleporters"
local destinationContainerName = "Destinations"

local taggedObjectTroves: {[Instance]: Trove.Trove} = {}
local interactionTroves: {[BasePart]: Trove.Trove} = {}

---------- Local functions ----------
-- Define general functions here

local function getRandomElement<T>(source: {T}): T
    local index = math.random(1, #source)
    return source[index]
end

local function onTeleporterPartAdded(part: BasePart, destinations: Instance)
    -- Set up trove
    local trove = Trove.new()
    if interactionTroves[part] then
        interactionTroves[part]:Destroy()
    end
    interactionTroves[part] = trove

    -- Make connections
    trove:Add(part.Touched:Connect(function(otherPart: BasePart)
        -- Validate character
        local character = Character.fromPart(otherPart)
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
        if not (character and humanoidRootPart) then
            return
        end

        -- Get a destination
        local baseParts: {BasePart} = {}
        for _, object in destinations:GetChildren() do
            if object:IsA("BasePart") then
                table.insert(baseParts, object)
            end
        end
        local destination: BasePart = getRandomElement(baseParts)

        -- Position teleport character
        local finalCFrame = CFrame.new(destination.CFrame.Position) * humanoidRootPart.CFrame.Rotation
        character:PivotTo(finalCFrame)
    end))
end

local function onTeleporterPartRemoved(part: BasePart)
    -- Clean up
    local trove = interactionTroves[part]
    if trove then
        trove:Destroy()
        interactionTroves[part] = nil
    end
end

local function setUpTeleporter(taggedObject: Instance, teleporters: Instance, destinations: Instance)
    -- Hide destinations
    for _, object in destinations:GetChildren() do
        if object:IsA("BasePart") then
            object.Transparency = 1
        end
    end

    -- Set up trove
    local trove = Trove.new()
    if taggedObjectTroves[taggedObject] then
        taggedObjectTroves[taggedObject]:Destroy()
    end
    taggedObjectTroves[taggedObject] = trove

    -- Make connections
    do
        local children = teleporters:GetChildren()
        task.defer(function()
            for _, object in children do
                -- Validate base part
                if not object:IsA("BasePart") then
                    continue
                end
                onTeleporterPartAdded(object, destinations)
            end
        end)
    end
    trove:Add(teleporters.ChildAdded:Connect(function(child: Instance)
        if not child:IsA("BasePart") then
            return
        end
        onTeleporterPartAdded(child, destinations)
    end))
    trove:Add(teleporters.ChildRemoved:Connect(function(child: Instance)
        if not child:IsA("BasePart") then
            return
        end
        onTeleporterPartRemoved(child)
    end))
end

---------- Event functions ----------
-- Functions that are directly connected by events or signals

local function onInstanceAdded(object: Instance)
    -- Validate containers
    local teleporters = object:FindFirstChild(interactionContainerName)
    local destinations = object:FindFirstChild(destinationContainerName)
    if not (teleporters and destinations) then
        return
    end
    if not (teleporters:FindFirstChildWhichIsA("BasePart") and destinations:FindFirstChildWhichIsA("BasePart")) then
        return
    end

    -- Set up teleporter
    setUpTeleporter(object, teleporters, destinations)
end

local function onInstanceRemoved(object: Instance)
    -- Clean up
    local trove = taggedObjectTroves[object]
    if trove then
        trove:Destroy()
        taggedObjectTroves[object] = nil
    end
end

---------- Set up function ----------
local function initSetUp()
    local tagged = CollectionService:GetTagged(tagName)
    task.defer(function()
        for _, object in tagged do
            onInstanceAdded(object)
        end
    end)
    CollectionService:GetInstanceAddedSignal(tagName):Connect(onInstanceAdded)
    CollectionService:GetInstanceRemovedSignal(tagName):Connect(onInstanceRemoved)
end

---------- Calling / connecting functions ----------
-- Connect functions to events and signals, then call set up functions

initSetUp()
