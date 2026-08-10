--[[
    Cloak V4 - Master Script
    File: init.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CloakV4 = {
    Version = "4.0.0",
    Active = false,
    Modules = {},
}

local BASE_URL = "https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/"

-- =========================================================================
-- EMBEDDED DYNAMIC UI LIBRARY FRAMEWORK
-- =========================================================================

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
    if self.ScreenGui then self.ScreenGui:Destroy() end
    table.clear(self.Tabs)

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

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.BackgroundColor3 = THEME.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = mainFrame

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

    if #UILib.Tabs == 0 then Select() end
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
            if callback then task.spawn(function() callback(state) end) end
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
            if callback then task.spawn(function() callback() end) end
        end)

        return btnFrame
    end

    return TabElements
end

function UILib:ToggleVisibility()
    task.spawn(function()
        self.Visible = not self.Visible
        if self.MainFrame then self.MainFrame.Visible = self.Visible end
    end)
end

function UILib:Destroy()
    task.spawn(function()
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end)
end

-- Right Shift Toggle Keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        UILib:ToggleVisibility()
    end
end)

-- =========================================================================
-- REMOTE MODULE LOADER
-- =========================================================================

local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName .. "?nocache=" .. tostring(os.time())
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    task.wait(0.1)

    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] Failed to HttpGet %s", fileName))
        return nil
    end

    task.wait(0.05)

    local compileSuccess, moduleChunk = pcall(function()
        return loadstring(rawCode)
    end)

    if not compileSuccess or type(moduleChunk) ~= "function" then
        warn(string.format("[Cloak V4 Error] Loadstring failed for %s: %s", fileName, tostring(moduleChunk)))
        return nil
    end

    local executeSuccess, loadedModule = pcall(moduleChunk)
    if not executeSuccess or loadedModule == nil then
        warn(string.format("[Cloak V4 Error] Runtime error in %s: %s", fileName, tostring(loadedModule)))
        return nil
    end

    return loadedModule
end

function CloakV4:Init()
    if self.Active then return end

    task.spawn(function()
        -- Load modules.lua dynamically
        local Modules = LoadRemoteModule("modules.lua")
        if not Modules then
            warn("[Cloak V4 Abort] Make sure 'modules.lua' is uploaded to your GitHub repository.")
            return
        end

        self.Active = true
        self.Modules = { Engine = Modules }

        -- Start Engine Runtimes
        Modules:Init()

        -- Build Window Instance
        local Window = UILib:CreateWindow("Cloak V4")

        -- TAB 1: COMBAT
        local CombatTab = Window:CreateTab("Combat")
        CombatTab:CreateToggle("Aimbot (CamLock)", false, function(s) Modules:ToggleAimbot(s) end)
        CombatTab:CreateSlider("Aimbot FOV", 30, 300, 120, function(v) Modules.State.AimbotFOV = v end)
        CombatTab:CreateSlider("Smoothness", 1, 20, 5, function(v) Modules.State.AimbotSmoothness = v end)
        CombatTab:CreateToggle("Triggerbot", false, function(s) Modules:ToggleTriggerbot(s) end)
        CombatTab:CreateToggle("FOV Circle Overlay", false, function(s) Modules.State.FOVCircle = s end)

        -- TAB 2: MOVEMENT
        local MovementTab = Window:CreateTab("Movement")
        MovementTab:CreateToggle("Sandbox Flight Engine", false, function(s) Modules:ToggleFly(s) end)
        MovementTab:CreateSlider("Flight Speed", 10, 200, 50, function(v) Modules.State.FlySpeed = v end)
        MovementTab:CreateToggle("Velocity WalkSpeed", false, function(s) Modules:ToggleSpeed(s) end)
        MovementTab:CreateSlider("WalkSpeed Value", 16, 150, 60, function(v) Modules.State.SpeedValue = v end)
        MovementTab:CreateToggle("Infinite Jump", false, function(s) Modules.State.InfiniteJump = s end)
        MovementTab:CreateToggle("Jump Power Modifier", false, function(s) Modules.State.JumpPower = s end)
        MovementTab:CreateSlider("Jump Power Value", 50, 300, 50, function(v) Modules.State.JumpPowerVal = v end)

        -- TAB 3: VISUALS
        local VisualsTab = Window:CreateTab("Visuals")
        VisualsTab:CreateToggle("Highlight ESP", false, function(s) Modules.State.EspEnabled = s Modules:RefreshVisualLoop() end)
        VisualsTab:CreateToggle("Solid Model Chams", false, function(s) Modules.State.ChamsEnabled = s Modules:RefreshVisualLoop() end)
        VisualsTab:CreateToggle("3D World Tracers", false, function(s) Modules.State.TracersEnabled = s Modules:RefreshVisualLoop() end)
        VisualsTab:CreateToggle("Fullbright Mode", false, function(s) Modules.State.Fullbright = s end)

        -- TAB 4: AUTOMATION
        local AutoTab = Window:CreateTab("Automation")
        AutoTab:CreateToggle("Auto-Greeting on Match End", false, function(s) Modules.State.AutoGreeting = s end)
        AutoTab:CreateButton("Trigger Manual Greeting Test", function() Modules:SendGreeting("GG! Thanks for testing Cloak V4.") end)

        -- TAB 5: SETTINGS
        local SettingsTab = Window:CreateTab("Settings")
        SettingsTab:CreateButton("Unload Cloak V4 Suite", function()
            CloakV4:Destroy()
        end)

        print("[Cloak V4] Suite fully initialized with 5 tabs.")
    end)
end

function CloakV4:Destroy()
    task.spawn(function()
        if self.Modules.Engine then pcall(function() self.Modules.Engine:Destroy() end) end
        UILib:Destroy()
        self.Active = false
        print("[Cloak V4] Suite unloaded cleanly.")
    end)
end

task.defer(function()
    CloakV4:Init()
end)

return CloakV4