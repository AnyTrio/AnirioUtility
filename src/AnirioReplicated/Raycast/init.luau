--!strict
-- Raycast Utility Module

---------- Module ----------
local Raycast = {}

---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

---------- Variables ----------

local maxRayDistance = 10000

---------- Local functions ----------

local function getMousePosition(): Vector3?
    if not RunService:IsClient() then
        warn("getMousePosition() can only be called from the client!")
        return nil
    end

    -- Get local variables
    local Camera = workspace.CurrentCamera
    local Player = Players.LocalPlayer
    local Character = Player.Character

    -- Get viewport position
    local screenLocation = UserInputService:GetMouseLocation()

    -- Get ray
    local unitRay = Camera:ViewportPointToRay(screenLocation.X, screenLocation.Y)

    -- Prepare for raycast
    local raycastParams = RaycastParams.new()
    raycastParams:AddToFilter(Character:GetDescendants())
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Get world position
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * maxRayDistance, raycastParams)
    local worldPosition = (raycastResult and raycastResult.Position) or (unitRay.Origin + unitRay.Direction * maxRayDistance)

    -- Return position
    return worldPosition
end

---------- Module functions ----------

-- Get the ray-casted position of the client's mouse
function Raycast.getLocalMousePosition()
    return getMousePosition()
end

---------- Return module ----------
return Raycast
