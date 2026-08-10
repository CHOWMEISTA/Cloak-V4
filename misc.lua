--[[
    Cloak V4 - Automation Tools (Crash-Hardened)
    File: misc.lua
--]]

local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MiscModule = {
    AutoGreetingEnabled = false,
    DefaultGreeting = "GG! Excellent match everyone.",
    Connections = {},
}

function MiscModule:Init()
    local matchStateConnection = Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
        task.spawn(function()
            local currentState = Workspace:GetAttribute("MatchState")
            if self.AutoGreetingEnabled and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
                self:SendGreeting(self.DefaultGreeting)
            end
        end)
    end)
    table.insert(self.Connections, matchStateConnection)
end

function MiscModule:SendGreeting(message)
    task.spawn(function()
        local phrase = message or self.DefaultGreeting

        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                generalChannel:SendAsync(phrase)
            end
        else
            local defaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultChatSystemChatEvents then
                local sayMessageRequest = defaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then
                    sayMessageRequest:FireServer(phrase, "All")
                end
            end
        end
    end)
end

function MiscModule:SetAutoGreetingEnabled(state) self.AutoGreetingEnabled = state end

function MiscModule:Destroy()
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)
end

return MiscModule