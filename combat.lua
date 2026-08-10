--[[
    Cloak V4 - Combat Testing & Target Assistance Engine
    File: combat.lua
    Description: Provides camera-locking target tracking, FOV math, and click-validation debugging.
--]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local CombatModule = {
    TargetAssistEnabled = false,
    ClickValidationEnabled = false,
    FOVRadius = 120,
    Smoothing = 5,
    Connections = {},
    CurrentTarget = nil,
}

-- Target Acquisition helper
local function GetClosestTargetInFOV(fov)
    local closestTarget = nil
    local shortestDistance = fov
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, obj in ipairs(Workspace:GetChildren()) do
        local isPlayer = Players:GetPlayerFromCharacter(obj)
        local isNPC = obj:FindFirstChildOfClass("Humanoid") and not isPlayer

        if (isPlayer and obj ~= LocalPlayer.Character) or isNPC then
            local head = obj:FindFirstChild("Head")
            local humanoid = obj:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
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
    -- RenderStepped loop for smooth camera adjustment
    local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
        if not self.TargetAssistEnabled then return end

        self.CurrentTarget = GetClosestTargetInFOV(self.FOVRadius)
        if self.CurrentTarget then
            local currentCamCFrame = Camera.CFrame
            local targetPosition = self.CurrentTarget.Position
            local desiredCFrame = CFrame.new(currentCamCFrame.Position, targetPosition)

            -- Interpolated smoothing math
            local lerpFactor = math.clamp((1 / self.Smoothing) * (deltaTime * 60), 0.01, 1)
            Camera.CFrame = currentCamCFrame:Lerp(desiredCFrame, lerpFactor)
        end
    end)
    table.insert(self.Connections, renderConn)

    -- Click Validation Tool Logic
    local clickConn = Mouse.Button1Down:Connect(function()
        if not self.ClickValidationEnabled then return end

        local target = Mouse.Target
        if target then
            local character = target:FindFirstAncestorOfClass("Model")
            if character and character:FindFirstChildOfClass("Humanoid") then
                print("[Cloak V4 - Click Validation] Valid Entity Clicked:", character.Name, "| Target Part:", target.Name)

                -- Visual Selection Indicator
                local highlight = Instance.new("Highlight")
                highlight.Name = "Cloak_Validation_Highlight"
                highlight.FillColor = Color3.fromRGB(0, 255, 102)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.Parent = character

                task.delay(1, function()
                    highlight:Destroy()
                end)
            end
        end
    end)
    table.insert(self.Connections, clickConn)
end

function CombatModule:SetTargetAssistEnabled(state)
    self.TargetAssistEnabled = state
end

function CombatModule:SetClickValidationEnabled(state)
    self.ClickValidationEnabled = state
end

function CombatModule:SetFOV(val)
    self.FOVRadius = val
end

function CombatModule:SetSmoothing(val)
    self.Smoothing = math.max(val, 1)
end

function CombatModule:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    table.clear(self.Connections)
end

return CombatModule