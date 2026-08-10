--[[
    Cloak V4 - Combat Engine (Freeze-Proof)
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
    LastTargetScan = 0,
}

-- Asynchronous, step-throttled target acquisition
local function GetClosestTargetInFOV(camera, fov)
    local closestTarget = nil
    local shortestDistance = fov
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    local children = Workspace:GetChildren()
    for i = 1, #children do
        local obj = children[i]

        -- Yield every 25 elements to completely eliminate workspace iteration locks
        if i % 25 == 0 then
            task.wait()
        end

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
    -- Dedicated background thread for target scanning (throttled to 10 Hz)
    task.spawn(function()
        while true do
            if self.TargetAssistEnabled then
                local camera = Workspace.CurrentCamera
                if camera then
                    self.CurrentTarget = GetClosestTargetInFOV(camera, self.FOVRadius)
                end
            else
                self.CurrentTarget = nil
            end
            task.wait(0.1) -- 100ms throttle between scan sweeps
        end
    end)

    -- Ultra-lightweight frame hook for CFrame interpolation (No iteration loops inside!)
    local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
        if not self.TargetAssistEnabled or not self.CurrentTarget then return end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        if self.CurrentTarget:IsDescendantOf(Workspace) then
            local currentCamCFrame = camera.CFrame
            local targetPosition = self.CurrentTarget.Position
            local desiredCFrame = CFrame.new(currentCamCFrame.Position, targetPosition)

            local lerpFactor = math.clamp((1 / self.Smoothing) * (deltaTime * 60), 0.01, 1)
            camera.CFrame = currentCamCFrame:Lerp(desiredCFrame, lerpFactor)
        else
            self.CurrentTarget = nil
        end
    end)
    table.insert(self.Connections, renderConn)

    -- Event-based Click Validation
    local clickConn = Mouse.Button1Down:Connect(function()
        if not self.ClickValidationEnabled then return end

        task.spawn(function()
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
    end)
    table.insert(self.Connections, clickConn)
end

function CombatModule:SetTargetAssistEnabled(state)
    task.spawn(function() self.TargetAssistEnabled = state end)
end

function CombatModule:SetClickValidationEnabled(state)
    task.spawn(function() self.ClickValidationEnabled = state end)
end

function CombatModule:SetFOV(val)
    task.spawn(function() self.FOVRadius = val end)
end

function CombatModule:SetSmoothing(val)
    task.spawn(function() self.Smoothing = math.max(val, 1) end)
end

function CombatModule:Destroy()
    task.spawn(function()
        self.TargetAssistEnabled = false
        self.ClickValidationEnabled = false
        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)
    end)
end

return CombatModule