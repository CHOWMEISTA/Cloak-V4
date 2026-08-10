--[[
    Cloak V4 - Master Unified Framework & Engine Suite
    Features: Matrix/Vape V4 Dark Interface (uilib.lua style) with integrated
              Combat, Movement, Visual Render, and Automation Engine Modules.
--]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Clean up previous execution traces
if gethui then
    local oldGui = gethui():FindFirstChild("CloakV4_UI")
    if oldGui then oldGui:Destroy() end
else
    local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CloakV4_UI")
    if oldGui then oldGui:Destroy() end
end

-- ==========================================
-- 1. CUSTOM MATRIX / VAPE V4 UI FRAMEWORK
-- ==========================================

local UILib = {
    ScreenGui = nil,
    MainFrame = nil,
    Visible = true,
    Tabs = {},
}

local THEME = {
    Background = Color3.fromRGB(18, 18, 18),
    Sidebar = Color3.fromRGB(14, 14, 14),
    Card = Color3.fromRGB(24, 24, 24),
    Accent = Color3.fromRGB(0, 255, 102),
    Text = Color3.fromRGB(240, 240, 240),
    TextMuted = Color3.fromRGB(130, 130, 130),
    CornerRadius = UDim.new(0, 4),
}

local function CreateCorner(parent)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = THEME.CornerRadius
    corner.Parent = parent
    return corner
end

function UILib:CreateWindow(titleText)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CloakV4_UI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self.ScreenGui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 620, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -310, 0.5, -200)
    mainFrame.BackgroundColor3 = THEME.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    CreateCorner(mainFrame)
    self.MainFrame = mainFrame

    -- Accent Border
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.BackgroundColor3 = THEME.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = mainFrame

    -- Sidebar Area
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, -3)
    sidebar.Position = UDim2.new(0, 0, 0, 3)
    sidebar.BackgroundColor3 = THEME.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = THEME.Accent
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = sidebar

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Size = UDim2.new(1, -10, 1, -55)
    tabScroll.Position = UDim2.new(0, 5, 0, 50)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 2
    tabScroll.ScrollBarImageColor3 = THEME.Accent
    tabScroll.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.Parent = tabScroll

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -170, 1, -13)
    contentArea.Position = UDim2.new(0, 165, 0, 8)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    -- Dragging Logic
    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            task.spawn(function()
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end)
        end
    end)

    self.TabScroll = tabScroll
    self.ContentArea = contentArea

    return self
end

function UILib:CreateTab(tabName)
    local pageScroll = Instance.new("ScrollingFrame")
    pageScroll.Name = tabName .. "_Page"
    pageScroll.Size = UDim2.new(1, 0, 1, 0)
    pageScroll.BackgroundTransparency = 1
    pageScroll.BorderSizePixel = 0
    pageScroll.ScrollBarThickness = 3
    pageScroll.ScrollBarImageColor3 = THEME.Accent
    pageScroll.Visible = false
    pageScroll.Parent = self.ContentArea

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = pageScroll

    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName .. "_TabButton"
    tabButton.Size = UDim2.new(1, -4, 0, 32)
    tabButton.BackgroundColor3 = THEME.Card
    tabButton.BorderSizePixel = 0
    tabButton.Text = "  " .. tabName
    tabButton.TextColor3 = THEME.TextMuted
    tabButton.TextSize = 13
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.AutoButtonColor = false
    tabButton.Parent = self.TabScroll
    CreateCorner(tabButton)

    local tabObj = { Page = pageScroll, Button = tabButton }

    local function Select()
        task.spawn(function()
            for _, t in pairs(UILib.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = THEME.Card
                t.Button.TextColor3 = THEME.TextMuted
            end
            pageScroll.Visible = true
            tabButton.BackgroundColor3 = THEME.Accent
            tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        end)
    end

    tabButton.MouseButton1Click:Connect(Select)

    if #UILib.Tabs == 0 then
        Select()
    end

    table.insert(UILib.Tabs, tabObj)

    local TabElements = {}

    function TabElements:CreateToggle(label, defaultState, callback)
        local state = defaultState or false
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, -6, 0, 36)
        toggleFrame.BackgroundColor3 = THEME.Card
        toggleFrame.Parent = pageScroll
        CreateCorner(toggleFrame)

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -60, 1, 0)
        textLabel.Position = UDim2.new(0, 12, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = label
        textLabel.TextColor3 = THEME.Text
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = toggleFrame

        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 36, 0, 18)
        switch.Position = UDim2.new(1, -48, 0.5, -9)
        switch.BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(40, 40, 40)
        switch.Text = ""
        switch.Parent = toggleFrame
        CreateCorner(switch)

        switch.MouseButton1Click:Connect(function()
            state = not state
            switch.BackgroundColor3 = state and THEME.Accent or Color3.fromRGB(40, 40, 40)
            if callback then
                task.spawn(function() callback(state) end)
            end
        end)

        return toggleFrame
    end

    function TabElements:CreateSlider(label, min, max, defaultVal, callback)
        local value = math.clamp(defaultVal or min, min, max)
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, -6, 0, 46)
        sliderFrame.BackgroundColor3 = THEME.Card
        sliderFrame.Parent = pageScroll
        CreateCorner(sliderFrame)

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.7, 0, 0, 20)
        textLabel.Position = UDim2.new(0, 12, 0, 4)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = label
        textLabel.TextColor3 = THEME.Text
        textLabel.TextSize = 13
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Parent = sliderFrame

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0.3, -12, 0, 20)
        valLabel.Position = UDim2.new(0.7, 0, 0, 4)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(value)
        valLabel.TextColor3 = THEME.Accent
        valLabel.TextSize = 13
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = sliderFrame

        local track = Instance.new("TextButton")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 30)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        track.Text = ""
        track.Parent = sliderFrame
        CreateCorner(track)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        CreateCorner(fill)

        local sliding = false
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
        end)
        track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                task.spawn(function()
                    local mathPos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * mathPos)
                    valLabel.Text = tostring(value)
                    fill.Size = UDim2.new(mathPos, 0, 1, 0)
                    if callback then callback(value) end
                end)
            end
        end)

        return sliderFrame
    end

    function TabElements:CreateButton(label, callback)
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(1, -6, 0, 36)
        btnFrame.BackgroundColor3 = THEME.Card
        btnFrame.Parent = pageScroll
        CreateCorner(btnFrame)

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = label
        button.TextColor3 = THEME.Text
        button.TextSize = 13
        button.Font = Enum.Font.GothamMedium
        button.Parent = btnFrame

        button.MouseButton1Click:Connect(function()
            if callback then
                task.spawn(function() callback() end)
            end
        end)

        return btnFrame
    end

    return TabElements
end

function UILib:ToggleVisibility()
    task.spawn(function()
        self.Visible = not self.Visible
        if self.MainFrame then
            self.MainFrame.Visible = self.Visible
        end
    end)
end

function UILib:Destroy()
    task.spawn(function()
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end)
end

-- Global Menu Hotkey Binding (Right Shift)[cite: 1]
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        UILib:ToggleVisibility()
    end
end)

-- ==========================================
-- 2. INTEGRATED FEATURE MODULE ENGINES
-- ==========================================

local Connections = {}
local State = {
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
}

local FlyBV = nil
local VisualContainer = Instance.new("Folder", CoreGui)
VisualContainer.Name = "CloakRenderStore"

local FOVCircleObj = nil
if Drawing then
    local circle = Drawing.new("Circle")
    circle.Visible = false
    circle.Thickness = 1.5
    circle.NumSides = 64
    circle.Color = Color3.fromRGB(0, 255, 102)
    circle.Filled = false
    circle.Transparency = 0.8
    FOVCircleObj = circle
end

-- ------------------------------------------
-- MOVEMENT MODULES
-- ------------------------------------------

local function UpdateFlyState(enabled)
    State.Fly = enabled
    if Connections.Fly then Connections.Fly:Disconnect() end
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    if not enabled then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBV.Velocity = Vector3.zero
    FlyBV.Parent = hrp

    Connections.Fly = RunService.RenderStepped:Connect(function()
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or not Camera then return end

        local speed = State.FlySpeed
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

        FlyBV.Velocity = vel
    end)
end

local function UpdateSpeedState(enabled)
    State.Speed = enabled
    if Connections.Speed then Connections.Speed:Disconnect() end
    if not enabled then return end

    Connections.Speed = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            hrp.Velocity = Vector3.new(hum.MoveDirection.X * State.SpeedValue, hrp.Velocity.Y, hum.MoveDirection.Z * State.SpeedValue)
        end
    end)
end

-- Infinite Jump Hook
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Jump Power Loop
RunService.Heartbeat:Connect(function()
    if State.JumpPower then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.UseJumpPower then
                hum.JumpPower = State.JumpPowerVal
            else
                hum.JumpHeight = State.JumpPowerVal * 0.14
            end
        end
    end
end)

-- ------------------------------------------
-- COMBAT MODULES
-- ------------------------------------------

local function GetClosestTarget()
    local closest, shortest = nil, State.AimbotFOV
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

local function UpdateAimbotState(enabled)
    State.Aimbot = enabled
    if Connections.Aimbot then Connections.Aimbot:Disconnect() end
    if not enabled then return end

    Connections.Aimbot = RunService.RenderStepped:Connect(function(dt)
        local targetPosition = GetClosestTarget()
        if targetPosition then
            local lerpFactor = math.clamp((1 / State.AimbotSmoothness) * (dt * 60), 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPosition), lerpFactor)
        end
    end)
end

local function UpdateTriggerbotState(enabled)
    State.Triggerbot = enabled
    if Connections.Trigger then Connections.Trigger:Disconnect() end
    if not enabled then return end

    Connections.Trigger = RunService.RenderStepped:Connect(function()
        local target = Mouse.Target
        if target and target.Parent then
            local enemy = Players:GetPlayerFromCharacter(target.Parent)
            if enemy and enemy ~= LocalPlayer then
                if mouse1click then mouse1click() end
            end
        end
    end)
end

-- ------------------------------------------
-- VISUAL & LIGHTING RENDER MODULES
-- ------------------------------------------

local function UpdateVisuals()
    VisualContainer:ClearAllChildren()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local playerColor = (p.Team and p.TeamColor) and p.TeamColor.Color or Color3.fromRGB(0, 255, 102)

                -- Box Highlight ESP
                if State.EspEnabled then
                    local box = Instance.new("Highlight", VisualContainer)
                    box.Adornee = char
                    box.FillTransparency = 0.6
                    box.FillColor = playerColor
                    box.OutlineColor = Color3.fromRGB(255, 255, 255)
                end

                -- Solid Model Chams
                if State.ChamsEnabled then
                    local cham = Instance.new("Highlight", VisualContainer)
                    cham.Adornee = char
                    cham.FillColor = Color3.fromRGB(255, 0, 100)
                    cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end

                -- Bottom Screen Line Tracers
                if State.TracersEnabled then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local line = Instance.new("LineHandleAdornment", VisualContainer)
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

local function RefreshVisualLoop()
    if Connections.RenderLoop then Connections.RenderLoop:Disconnect() end
    if State.EspEnabled or State.ChamsEnabled or State.TracersEnabled then
        Connections.RenderLoop = RunService.RenderStepped:Connect(UpdateVisuals)
    else
        VisualContainer:ClearAllChildren()
    end
end

-- FOV Circle & Fullbright Loop
RunService.RenderStepped:Connect(function()
    if FOVCircleObj then
        if State.FOVCircle then
            local vp = Camera.ViewportSize
            FOVCircleObj.Position = Vector2.new(vp.X / 2, vp.Y / 2)
            FOVCircleObj.Radius = State.AimbotFOV
            FOVCircleObj.Visible = true
        else
            FOVCircleObj.Visible = false
        end
    end

    if State.Fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 12
    end
end)

-- ------------------------------------------
-- AUTOMATION MODULES
-- ------------------------------------------

local function SendGreeting(text)
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

Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
    local currentState = Workspace:GetAttribute("MatchState")
    if State.AutoGreeting and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
        SendGreeting("GG! Excellent match everyone.")
    end
end)

-- ==========================================
-- 3. INTERFACE BUILDER & MODULE BINDINGS
-- ==========================================

local Window = UILib:CreateWindow("Cloak V4")

-- TAB 1: COMBAT
local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateToggle("Aimbot (CamLock)", false, function(s) UpdateAimbotState(s) end)
CombatTab:CreateSlider("Aimbot FOV", 30, 300, 120, function(v) State.AimbotFOV = v end)
CombatTab:CreateSlider("Smoothness", 1, 20, 5, function(v) State.AimbotSmoothness = v end)
CombatTab:CreateToggle("Triggerbot", false, function(s) UpdateTriggerbotState(s) end)
CombatTab:CreateToggle("FOV Circle Overlay", false, function(s) State.FOVCircle = s end)

-- TAB 2: MOVEMENT
local MovementTab = Window:CreateTab("Movement")
MovementTab:CreateToggle("Sandbox Flight Engine", false, function(s) UpdateFlyState(s) end)
MovementTab:CreateSlider("Flight Speed", 10, 200, 50, function(v) State.FlySpeed = v end)
MovementTab:CreateToggle("Velocity WalkSpeed", false, function(s) UpdateSpeedState(s) end)
MovementTab:CreateSlider("WalkSpeed Value", 16, 150, 60, function(v) State.SpeedValue = v end)
MovementTab:CreateToggle("Infinite Jump", false, function(s) State.InfiniteJump = s end)
MovementTab:CreateToggle("Jump Power Modifier", false, function(s) State.JumpPower = s end)
MovementTab:CreateSlider("Jump Power Value", 50, 300, 50, function(v) State.JumpPowerVal = v end)

-- TAB 3: VISUALS
local VisualsTab = Window:CreateTab("Visuals")
VisualsTab:CreateToggle("Highlight ESP", false, function(s) State.EspEnabled = s RefreshVisualLoop() end)
VisualsTab:CreateToggle("Solid Model Chams", false, function(s) State.ChamsEnabled = s RefreshVisualLoop() end)
VisualsTab:CreateToggle("3D World Tracers", false, function(s) State.TracersEnabled = s RefreshVisualLoop() end)
VisualsTab:CreateToggle("Fullbright Mode", false, function(s) State.Fullbright = s end)

-- TAB 4: AUTOMATION
local AutoTab = Window:CreateTab("Automation")
AutoTab:CreateToggle("Auto-Greeting on Match End", false, function(s) State.AutoGreeting = s end)
AutoTab:CreateButton("Trigger Manual Greeting Test", function() SendGreeting("GG! Thanks for testing Cloak V4.") end)

-- TAB 5: SETTINGS
local SettingsTab = Window:CreateTab("Settings")
SettingsTab:CreateButton("Unload Cloak V4 Suite", function()
    if Connections.Fly then Connections.Fly:Disconnect() end
    if Connections.Speed then Connections.Speed:Disconnect() end
    if Connections.Aimbot then Connections.Aimbot:Disconnect() end
    if Connections.Trigger then Connections.Trigger:Disconnect() end
    if Connections.RenderLoop then Connections.RenderLoop:Disconnect() end
    if FlyBV then FlyBV:Destroy() end
    if FOVCircleObj then pcall(function() FOVCircleObj:Remove() end) end
    VisualContainer:Destroy()
    UILib:Destroy()
    print("[Cloak V4] Unloaded cleanly.")
end)

print("Cloak V4 Suite Fully Loaded. Press [Right Shift] to toggle visibility.")