--[[
    Cloak V4 - Combat Testing Engine (Crash-Hardened)
    File: combat.lua
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local CombatModule = {
    TargetAssistEnabled = false,
    ClickValidationEnabled = false,
    FOVRadius = 120,
    Smoothing = 5,
    Connections = {},
    CurrentTarget = nil,
}

local function GetClosestTargetInFOV(camera, fov)
    local closestTarget = nil
    local shortestDistance = fov
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    local children = Workspace:GetChildren()
    for i = 1, #children do
        local obj = children[i]
        
        -- Yield every 50 parts scanned to avoid freezing dense maps
        if i % 50 == 0 then task.wait() end

        local isPlayer = Players:GetPlayerFromCharacter(obj)
        local isNPC = obj:FindFirstChildOfClass("Humanoid") and not isPlayer

        if (isPlayer and obj ~= LocalPlayer.Character) or isNPC then
            local head = obj:FindFirstChild("Head")
            local humanoid = obj:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (screenPos2D - mousePos).Magnitude

                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestTarget = head
                    end
                end
            end
        end
    end

    return closestTarget
end

function CombatModule:Init()
    local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
        if not self.TargetAssistEnabled then return end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        self.CurrentTarget = GetClosestTargetInFOV(camera, self.FOVRadius)
        if self.CurrentTarget and self.CurrentTarget:IsDescendantOf(Workspace) then
            local currentCamCFrame = camera.CFrame
            local targetPosition = self.CurrentTarget.Position
            local desiredCFrame = CFrame.new(currentCamCFrame.Position, targetPosition)

            local lerpFactor = math.clamp((1 / self.Smoothing) * (deltaTime * 60), 0.01, 1)
            camera.CFrame = currentCamCFrame:Lerp(desiredCFrame, lerpFactor)
        end
    end)
    table.insert(self.Connections, renderConn)

    local clickConn = Mouse.Button1Down:Connect(function()
        if not self.ClickValidationEnabled then return end

        local target = Mouse.Target
        if target then
            local character = target:FindFirstAncestorOfClass("Model")
            if character and character:FindFirstChildOfClass("Humanoid") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Cloak_Validation_Highlight"
                highlight.FillColor = Color3.fromRGB(0, 255, 102)
                highlight.FillTransparency = 0.5
                highlight.Parent = character

                task.delay(1, function()
                    if highlight and highlight.Parent then
                        highlight:Destroy()
                    end
                end)
            end
        end
    end)
    table.insert(self.Connections, clickConn)
end

function CombatModule:SetTargetAssistEnabled(state) self.TargetAssistEnabled = state end
function CombatModule:SetClickValidationEnabled(state) self.ClickValidationEnabled = state end
function CombatModule:SetFOV(val) self.FOVRadius = val end
function CombatModule:SetSmoothing(val) self.Smoothing = math.max(val, 1) end

function CombatModule:Destroy()
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)
end

return CombatModule