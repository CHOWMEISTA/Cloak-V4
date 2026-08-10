--[[
    Cloak V4 - Custom UI Library Framework
    File: uilib.lua
    Description: Matrix/Vape V4 dark-themed interface built strictly with standard ScreenGui elements.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local UILib = {
    ScreenGui = nil,
    MainFrame = nil,
    Visible = true,
}

-- Theme Constants
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
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CloakV4_UI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Protect GUI if executor environment permits, otherwise fallback to PlayerGui
    if gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    self.ScreenGui = screenGui

    -- Main Container Window
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 380)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
    mainFrame.BackgroundColor3 = THEME.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    CreateCorner(mainFrame)
    self.MainFrame = mainFrame

    -- Accent Top Bar
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.BackgroundColor3 = THEME.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = mainFrame

    -- Sidebar Container
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 160, 1, -3)
    sidebar.Position = UDim2.new(0, 0, 0, 3)
    sidebar.BackgroundColor3 = THEME.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    -- Watermark/Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = THEME.Accent
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = sidebar

    -- Sidebar Layout
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -10, 1, -55)
    tabContainer.Position = UDim2.new(0, 5, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = sidebar

    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 6)
    tabListLayout.Parent = tabContainer

    -- Content Viewport
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -170, 1, -13)
    contentArea.Position = UDim2.new(0, 165, 0, 8)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    -- Dragging Logic
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    -- Window Methods
    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
    }

    function WindowObj:CreateTab(tabName)
        local tabScroll = Instance.new("ScrollingFrame")
        tabScroll.Name = tabName .. "_Page"
        tabScroll.Size = UDim2.new(1, 0, 1, 0)
        tabScroll.BackgroundTransparency = 1
        tabScroll.BorderSizePixel = 0
        tabScroll.ScrollBarThickness = 3
        tabScroll.ScrollBarImageColor3 = THEME.Accent
        tabScroll.Visible = false
        tabScroll.Parent = contentArea

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = tabScroll

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingRight = UDim.new(0, 6)
        pagePadding.Parent = tabScroll

        -- Tab Button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "_Button"
        tabButton.Size = UDim2.new(1, 0, 0, 32)
        tabButton.BackgroundColor3 = THEME.Card
        tabButton.BorderSizePixel = 0
        tabButton.Text = "  " .. tabName
        tabButton.TextColor3 = THEME.TextMuted
        tabButton.TextSize = 13
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabContainer
        CreateCorner(tabButton)

        local tabObj = { Page = tabScroll, Button = tabButton }

        local function Select()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {
                    BackgroundColor3 = THEME.Card,
                    TextColor3 = THEME.TextMuted,
                }):Play()
            end
            tabScroll.Visible = true
            TweenService:Create(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = THEME.Accent,
                TextColor3 = Color3.fromRGB(0, 0, 0),
            }):Play()
            WindowObj.CurrentTab = tabObj
        end

        tabButton.MouseButton1Click:Connect(Select)

        if #WindowObj.Tabs == 0 then
            Select()
        end

        table.insert(WindowObj.Tabs, tabObj)

        -- Element Factory
        local TabElements = {}

        function TabElements:CreateToggle(label, defaultState, callback)
            local state = defaultState or false

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Size = UDim2.new(1, 0, 0, 36)
            toggleFrame.BackgroundColor3 = THEME.Card
            toggleFrame.Parent = tabScroll
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
            switch.AutoButtonColor = false
            switch.Parent = toggleFrame
            CreateCorner(switch)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch
            CreateCorner(knob)

            local function Toggle()
                state = not state
                local switchColor = state and THEME.Accent or Color3.fromRGB(40, 40, 40)
                local knobPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)

                TweenService:Create(switch, TweenInfo.new(0.15), { BackgroundColor3 = switchColor }):Play()
                TweenService:Create(knob, TweenInfo.new(0.15), { Position = knobPos }):Play()

                task.spawn(callback, state)
            end

            switch.MouseButton1Click:Connect(Toggle)
            return toggleFrame
        end

        function TabElements:CreateSlider(label, min, max, defaultVal, callback)
            local value = math.clamp(defaultVal or min, min, max)

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, 0, 0, 46)
            sliderFrame.BackgroundColor3 = THEME.Card
            sliderFrame.Parent = tabScroll
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
            track.AutoButtonColor = false
            track.Parent = sliderFrame
            CreateCorner(track)

            local fill = Instance.new("Frame")
            local rel = (value - min) / (max - min)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            fill.BackgroundColor3 = THEME.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            CreateCorner(fill)

            local sliding = false

            local function UpdateSlider(input)
                local mathPos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * mathPos)
                valLabel.Text = tostring(value)
                TweenService:Create(fill, TweenInfo.new(0.05), { Size = UDim2.new(mathPos, 0, 1, 0) }):Play()
                task.spawn(callback, value)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    UpdateSlider(input)
                end
            end)

            track.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)

            return sliderFrame
        end

        function TabElements:CreateButton(label, callback)
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.new(1, 0, 0, 36)
            btnFrame.BackgroundColor3 = THEME.Card
            btnFrame.Parent = tabScroll
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
                TweenService:Create(btnFrame, TweenInfo.new(0.1), { BackgroundColor3 = THEME.Accent }):Play()
                task.wait(0.1)
                TweenService:Create(btnFrame, TweenInfo.new(0.2), { BackgroundColor3 = THEME.Card }):Play()
                task.spawn(callback)
            end)

            return btnFrame
        end

        return TabElements
    end

    function UILib:ToggleVisibility()
        self.Visible = not self.Visible
        self.MainFrame.Visible = self.Visible
    end

    return WindowObj
end

function UILib:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

return UILib