--[[
    Cloak V4 - Automation & Visual Diagnostics
    File: misc.lua
--]]

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MiscModule = {
    AutoGreetingEnabled = false,
    DefaultGreeting = "GG! Excellent match everyone.",
    
    -- Visual Features
    ESPEnabled = false,
    TracersEnabled = false,
    UseTeamColors = true,
    FullbrightEnabled = false,

    Tracers = {},
    Connections = {},

    DefaultLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
    },
}

local function GetPlayerColor(player)
    if MiscModule.UseTeamColors and player.Team and player.TeamColor then
        return player.TeamColor.Color
    end
    return Color3.fromRGB(0, 255, 102)
end

local function CreateTracer(player)
    if player == LocalPlayer or MiscModule.Tracers[player] or not Drawing then return end

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = GetPlayerColor(player)
    line.Thickness = 1.5
    line.Transparency = 1

    MiscModule.Tracers[player] = line
end

local function RemoveTracer(player)
    if MiscModule.Tracers[player] then
        pcall(function() MiscModule.Tracers[player]:Remove() end)
        MiscModule.Tracers[player] = nil
    end
end

function MiscModule:Init()
    -- Match State Signal Event Listeners
    local matchStateConnection = Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
        task.spawn(function()
            local currentState = Workspace:GetAttribute("MatchState")
            if self.AutoGreetingEnabled and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
                self:SendGreeting(self.DefaultGreeting)
            end
        end)
    end)
    table.insert(self.Connections, matchStateConnection)

    -- Fullbright Listeners
    local function EnforceFullbright()
        if not self.FullbrightEnabled then return end
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 12
    end

    table.insert(self.Connections, Lighting:GetPropertyChangedSignal("Ambient"):Connect(EnforceFullbright))
    table.insert(self.Connections, Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(EnforceFullbright))
    table.insert(self.Connections, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(EnforceFullbright))

    -- RenderStepped Loop for Tracers & ESP Team Color Updates
    local renderConn = RunService.RenderStepped:Connect(function()
        local viewportSize = Camera.ViewportSize

        if self.TracersEnabled and Drawing then
            local originPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)

            for player, line in pairs(self.Tracers) do
                local char = player.Character
                if char and char:Parent() then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")

                    if root and hum and hum.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            line.From = originPos
                            line.To = Vector2.new(screenPos.X, screenPos.Y)
                            line.Color = GetPlayerColor(player)
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            for _, line in pairs(self.Tracers) do
                line.Visible = false
            end
        end

        if self.ESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local highlight = player.Character:FindFirstChild("Cloak_ESP_Highlight")
                    if highlight then
                        highlight.FillColor = GetPlayerColor(player)
                    end
                end
            end
        end
    end)
    table.insert(self.Connections, renderConn)

    -- Player Hooks
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then CreateTracer(player) end
    end

    table.insert(self.Connections, Players.PlayerAdded:Connect(function(player) CreateTracer(player) end))
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player) RemoveTracer(player) end))
end

function MiscModule:SendGreeting(message)
    task.spawn(function()
        local phrase = message or self.DefaultGreeting

        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                pcall(function() generalChannel:SendAsync(phrase) end)
            end
        else
            local defaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultChatSystemChatEvents then
                local sayMessageRequest = defaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then
                    pcall(function() sayMessageRequest:FireServer(phrase, "All") end)
                end
            end
        end
    end)
end

function MiscModule:SetESPEnabled(state)
    task.spawn(function()
        self.ESPEnabled = state
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("Cloak_ESP_Highlight")
                if state then
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "Cloak_ESP_Highlight"
                        highlight.FillColor = GetPlayerColor(player)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.6
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                    end
                else
                    if highlight then highlight:Destroy() end
                end
            end
        end
    end)
end

function MiscModule:SetFullbrightEnabled(state)
    task.spawn(function()
        self.FullbrightEnabled = state
        if state then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 12
        else
            Lighting.Ambient = self.DefaultLighting.Ambient
            Lighting.OutdoorAmbient = self.DefaultLighting.OutdoorAmbient
            Lighting.ClockTime = self.DefaultLighting.ClockTime
        end
    end)
end

function MiscModule:SetTracersEnabled(state) task.spawn(function() self.TracersEnabled = state end) end
function MiscModule:SetUseTeamColors(state) task.spawn(function() self.UseTeamColors = state end) end
function MiscModule:SetAutoGreetingEnabled(state) task.spawn(function() self.AutoGreetingEnabled = state end) end

function MiscModule:Destroy()
    task.spawn(function()
        self:SetESPEnabled(false)
        self:SetFullbrightEnabled(false)
        self.TracersEnabled = false

        for player, _ in pairs(self.Tracers) do
            RemoveTracer(player)
        end

        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)
    end)
end

return MiscModule