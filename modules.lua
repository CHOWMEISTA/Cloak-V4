--[[
    Cloak V4 - Feature Module Engines
    File: modules.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
--]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local Modules = {
    Connections = {},
    State = {
        Fly = false,
        FlySpeed = 50,
        Speed = false,
        SpeedValue = 60,
        InfiniteJump = false,
        JumpPower = false,
        JumpPowerVal = 50,
        Aimbot = false,
        AimbotFOV = 120,
        AimbotSmoothness = 5,
        Triggerbot = false,
        EspEnabled = false,
        ChamsEnabled = false,
        TracersEnabled = false,
        FOVCircle = false,
        Fullbright = false,
        AutoGreeting = false,
    },
    FlyBV = nil,
    VisualContainer = nil,
    FOVCircleObj = nil,
}

function Modules:Init()
    local container = CoreGui:FindFirstChild("CloakRenderStore")
    if not container then
        container = Instance.new("Folder")
        container.Name = "CloakRenderStore"
        container.Parent = CoreGui
    end
    self.VisualContainer = container

    if Drawing and not self.FOVCircleObj then
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Thickness = 1.5
        circle.NumSides = 64
        circle.Color = Color3.fromRGB(0, 255, 102)
        circle.Filled = false
        circle.Transparency = 0.8
        self.FOVCircleObj = circle
    end

    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if self.State.InfiniteJump then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    table.insert(self.Connections, jumpConn)

    local heartbeatConn = RunService.Heartbeat:Connect(function()
        if self.State.JumpPower then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.UseJumpPower then
                    hum.JumpPower = self.State.JumpPowerVal
                else
                    hum.JumpHeight = self.State.JumpPowerVal * 0.14
                end
            end
        end
    end)
    table.insert(self.Connections, heartbeatConn)

    local renderConn = RunService.RenderStepped:Connect(function()
        if self.FOVCircleObj then
            if self.State.FOVCircle then
                local vp = Camera.ViewportSize
                self.FOVCircleObj.Position = Vector2.new(vp.X / 2, vp.Y / 2)
                self.FOVCircleObj.Radius = self.State.AimbotFOV
                self.FOVCircleObj.Visible = true
            else
                self.FOVCircleObj.Visible = false
            end
        end

        if self.State.Fullbright then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 12
        end
    end)
    table.insert(self.Connections, renderConn)

    local matchConn = Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
        local currentState = Workspace:GetAttribute("MatchState")
        if self.State.AutoGreeting and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
            self:SendGreeting("GG! Excellent match everyone.")
        end
    end)
    table.insert(self.Connections, matchConn)
end

-- -------------------------------------------------------------------------
-- MOVEMENT METHODS
-- -------------------------------------------------------------------------

function Modules:ToggleFly(enabled)
    self.State.Fly = enabled
    if self.Connections.Fly then self.Connections.Fly:Disconnect() end
    if self.FlyBV then self.FlyBV:Destroy() self.FlyBV = nil end
    if not enabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    self.FlyBV = Instance.new("BodyVelocity")
    self.FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    self.FlyBV.Velocity = Vector3.zero
    self.FlyBV.Parent = hrp

    self.Connections.Fly = RunService.RenderStepped:Connect(function()
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or not Camera then return end

        local speed = self.State.FlySpeed
        local vel = Vector3.zero

        if hum.MoveDirection.Magnitude > 0 then
            local camCF = Camera.CFrame
            local localDir = camCF:VectorToObjectSpace(hum.MoveDirection)
            vel = camCF:VectorToWorldSpace(localDir) * speed
        end

        local verticalY = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
            verticalY = speed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then 
            verticalY = -speed
        end

        if verticalY ~= 0 then
            vel = Vector3.new(vel.X, verticalY, vel.Z)
        end

        self.FlyBV.Velocity = vel
    end)
end

function Modules:ToggleSpeed(enabled)
    self.State.Speed = enabled
    if self.Connections.Speed then self.Connections.Speed:Disconnect() end
    if not enabled then return end

    self.Connections.Speed = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.Velocity = Vector3.new(hum.MoveDirection.X * self.State.SpeedValue, hrp.Velocity.Y, hum.MoveDirection.Z * self.State.SpeedValue)
        end
    end)
end

-- -------------------------------------------------------------------------
-- COMBAT METHODS
-- -------------------------------------------------------------------------

local function GetClosestTarget(fov)
    local closest, shortest = nil, fov
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = head.Position
                    end
                end
            end
        end
    end
    return closest
end

function Modules:ToggleAimbot(enabled)
    self.State.Aimbot = enabled
    if self.Connections.Aimbot then self.Connections.Aimbot:Disconnect() end
    if not enabled then return end

    self.Connections.Aimbot = RunService.RenderStepped:Connect(function(dt)
        local targetPosition = GetClosestTarget(self.State.AimbotFOV)
        if targetPosition then
            local lerpFactor = math.clamp((1 / self.State.AimbotSmoothness) * (dt * 60), 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), lerpFactor)
        end
    end)
end

function Modules:ToggleTriggerbot(enabled)
    self.State.Triggerbot = enabled
    if self.Connections.Trigger then self.Connections.Trigger:Disconnect() end
    if not enabled then return end

    self.Connections.Trigger = RunService.RenderStepped:Connect(function()
        local target = Mouse.Target
        if target and target.Parent then
            local enemy = Players:GetPlayerFromCharacter(target.Parent)
            if enemy and enemy ~= LocalPlayer then
                if mouse1click then mouse1click() end
            end
        end
    end)
end

-- -------------------------------------------------------------------------
-- VISUAL RENDER METHODS
-- -------------------------------------------------------------------------

function Modules:UpdateVisuals()
    if not self.VisualContainer then return end
    self.VisualContainer:ClearAllChildren()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local playerColor = (p.Team and p.TeamColor) and p.TeamColor.Color or Color3.fromRGB(0, 255, 102)

                if self.State.EspEnabled then
                    local box = Instance.new("Highlight", self.VisualContainer)
                    box.Adornee = char
                    box.FillTransparency = 0.6
                    box.FillColor = playerColor
                    box.OutlineColor = Color3.fromRGB(255, 255, 255)
                end

                if self.State.ChamsEnabled then
                    local cham = Instance.new("Highlight", self.VisualContainer)
                    cham.Adornee = char
                    cham.FillColor = Color3.fromRGB(255, 0, 100)
                    cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end

                if self.State.TracersEnabled then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local line = Instance.new("LineHandleAdornment", self.VisualContainer)
                        line.Length = (Camera.CFrame.Position - hrp.Position).Magnitude
                        line.Thickness = 2
                        line.Color3 = playerColor
                        line.Adornee = Camera
                        line.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
                    end
                end
            end
        end
    end
end

function Modules:RefreshVisualLoop()
    if self.Connections.RenderLoop then self.Connections.RenderLoop:Disconnect() end
    if self.State.EspEnabled or self.State.ChamsEnabled or self.State.TracersEnabled then
        self.Connections.RenderLoop = RunService.RenderStepped:Connect(function()
            self:UpdateVisuals()
        end)
    else
        if self.VisualContainer then
            self.VisualContainer:ClearAllChildren()
        end
    end
end

-- -------------------------------------------------------------------------
-- AUTOMATION & UTILITY
-- -------------------------------------------------------------------------

function Modules:SendGreeting(text)
    task.spawn(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then pcall(function() channel:SendAsync(text) end) end
        else
            local defaultEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultEvents then
                local sayReq = defaultEvents:FindFirstChild("SayMessageRequest")
                if sayReq then pcall(function() sayReq:FireServer(text, "All") end) end
            end
        end
    end)
end

function Modules:Destroy()
    if self.Connections.Fly then self.Connections.Fly:Disconnect() end
    if self.Connections.Speed then self.Connections.Speed:Disconnect() end
    if self.Connections.Aimbot then self.Connections.Aimbot:Disconnect() end
    if self.Connections.Trigger then self.Connections.Trigger:Disconnect() end
    if self.Connections.RenderLoop then self.Connections.RenderLoop:Disconnect() end

    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.Connections)

    if self.FlyBV then self.FlyBV:Destroy() end
    if self.FOVCircleObj then pcall(function() self.FOVCircleObj:Remove() end) end
    if self.VisualContainer then self.VisualContainer:Destroy() end
end

return Modules