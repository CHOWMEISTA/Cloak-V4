--[[
    Cloak V4 - Combat, Target Assistance & Hitbox Engine
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
    
    -- FOV Circle Drawing
    FOVCircleEnabled = false,
    FOVCircle = nil,

    -- Hitbox Expansion
    HitboxExpandEnabled = false,
    HitboxSize = 10,
    HitboxTransparency = 0.7,
    OriginalSizes = {},

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

        if i % 25 == 0 then task.wait() end

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
    -- Initialize FOV Circle Object
    if Drawing then
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Thickness = 1.5
        circle.NumSides = 64
        circle.Radius = self.FOVRadius
        circle.Color = Color3.fromRGB(0, 255, 102)
        circle.Filled = false
        circle.Transparency = 0.8
        self.FOVCircle = circle
    end

    -- Throttled Target Scanner
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
            task.wait(0.1)
        end
    end)

    -- Heartbeat Physics Loop (Hitbox Expansion Engine)
    local heartbeatConn = RunService.Heartbeat:Connect(function()
        if self.HitboxExpandEnabled then
            local players = Players:GetPlayers()
            for i = 1, #players do
                local player = players[i]
                if player ~= LocalPlayer and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")

                    if root and hum and hum.Health > 0 then
                        if not self.OriginalSizes[root] then
                            self.OriginalSizes[root] = root.Size
                        end

                        root.Size = Vector3.new(self.HitboxSize, self.HitboxSize, self.HitboxSize)
                        root.Transparency = self.HitboxTransparency
                        root.Color = (player.Team and player.TeamColor) and player.TeamColor.Color or Color3.fromRGB(0, 255, 102)
                        root.Material = Enum.Material.ForceField
                        root.CanCollide = false
                    end
                end
            end
        end
    end)
    table.insert(self.Connections, heartbeatConn)

    -- RenderStepped Frame Hook (Camera Lock & FOV Circle Render)
    local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
        local camera = Workspace.CurrentCamera
        if not camera then return end

        -- FOV Overlay Rendering
        if self.FOVCircle and Drawing then
            if self.FOVCircleEnabled then
                local viewportSize = camera.ViewportSize
                self.FOVCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                self.FOVCircle.Radius = self.FOVRadius
                self.FOVCircle.Visible = true
            else
                self.FOVCircle.Visible = false
            end
        end

        -- Camera Lock Movement
        if self.TargetAssistEnabled and self.CurrentTarget and self.CurrentTarget:IsDescendantOf(Workspace) then
            local currentCamCFrame = camera.CFrame
            local targetPosition = self.CurrentTarget.Position
            local desiredCFrame = CFrame.new(currentCamCFrame.Position, targetPosition)

            local lerpFactor = math.clamp((1 / self.Smoothing) * (deltaTime * 60), 0.01, 1)
            camera.CFrame = currentCamCFrame:Lerp(desiredCFrame, lerpFactor)
        end
    end)
    table.insert(self.Connections, renderConn)

    -- Click Validation Tool
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
                        if highlight and highlight.Parent then highlight:Destroy() end
                    end)
                end
            end
        end)
    end)
    table.insert(self.Connections, clickConn)
end

function CombatModule:SetTargetAssistEnabled(state) task.spawn(function() self.TargetAssistEnabled = state end) end
function CombatModule:SetClickValidationEnabled(state) task.spawn(function() self.ClickValidationEnabled = state end) end
function CombatModule:SetFOV(val) task.spawn(function() self.FOVRadius = val end) end
function CombatModule:SetSmoothing(val) task.spawn(function() self.Smoothing = math.max(val, 1) end) end
function CombatModule:SetFOVCircleEnabled(state) task.spawn(function() self.FOVCircleEnabled = state end) end

function CombatModule:SetHitboxEnabled(state)
    task.spawn(function()
        self.HitboxExpandEnabled = state
        if not state then
            for root, originalSize in pairs(self.OriginalSizes) do
                if root and root.Parent then
                    root.Size = originalSize
                    root.Transparency = 1
                end
            end
            table.clear(self.OriginalSizes)
        end
    end)
end

function CombatModule:SetHitboxSize(val) task.spawn(function() self.HitboxSize = val end) end
function CombatModule:SetHitboxTransparency(val) task.spawn(function() self.HitboxTransparency = val end) end

function CombatModule:Destroy()
    task.spawn(function()
        self.TargetAssistEnabled = false
        self.ClickValidationEnabled = false
        self.HitboxExpandEnabled = false
        self.FOVCircleEnabled = false

        if self.FOVCircle then
            pcall(function() self.FOVCircle:Remove() end)
            self.FOVCircle = nil
        end

        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)
    end)
end

return CombatModule