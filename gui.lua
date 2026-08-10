--[[
    Cloak V4 - Dedicated GUI Framework & Layout Engine
    File: gui.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local GUI = {
    ScreenGui = nil,
    MainFrame = nil,
    Visible = true,
    Tabs = {},
    CurrentTab = nil,
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

function GUI:CreateWindow(titleText)
    -- Clean up previous GUI if re-injected
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end

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

    -- Top Accent Bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.BackgroundColor3 = THEME.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Parent = mainFrame

    -- Sidebar Container
    local sidebar = Instance.new("Frame")
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

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -170, 1, -13)
    contentArea.Position = UDim2.new(0, 165, 0, 8)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    -- Dragging Mechanics
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

    self.TabContainer = tabContainer
    self.ContentArea = contentArea

    return self
end

function GUI:CreateTab(tabName)
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = tabName .. "_Page"
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 3
    tabScroll.ScrollBarImageColor3 = THEME.Accent
    tabScroll.Visible = false
    tabScroll.Parent = self.ContentArea

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = tabScroll

    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, 0, 0, 32)
    tabButton.BackgroundColor3 = THEME.Card
    tabButton.BorderSizePixel = 0
    tabButton.Text = "  " .. tabName
    tabButton.TextColor3 = THEME.TextMuted
    tabButton.TextSize = 13
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.AutoButtonColor = false
    tabButton.Parent = self.TabContainer
    CreateCorner(tabButton)

    local tabObj = { Page = tabScroll, Button = tabButton }

    local function Select()
        task.spawn(function()
            for _, t in pairs(GUI.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = THEME.Card
                t.Button.TextColor3 = THEME.TextMuted
            end
            tabScroll.Visible = true
            tabButton.BackgroundColor3 = THEME.Accent
            tabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            GUI.CurrentTab = tabObj
        end)
    end

    tabButton.MouseButton1Click:Connect(Select)

    if #GUI.Tabs == 0 then
        Select()
    end

    table.insert(GUI.Tabs, tabObj)

    -- Tab Control Builder
    local TabElements = {}

    function TabElements:AddToggle(label, defaultState, callback)
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

    function TabElements:AddSlider(label, min, max, defaultVal, callback)
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

    function TabElements:AddButton(label, callback)
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
            if callback then
                task.spawn(function() callback() end)
            end
        end)

        return btnFrame
    end

    return TabElements
end

function GUI:ToggleVisibility()
    task.spawn(function()
        self.Visible = not self.Visible
        if self.MainFrame then
            self.MainFrame.Visible = self.Visible
        end
    end)
end

function GUI:Destroy()
    task.spawn(function()
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end)
end

return GUI