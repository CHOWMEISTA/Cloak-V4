--[[
    Cloak V4 - Automation & Match Event Tools
    File: misc.lua
    Description: Monitors game state signals or chat output to automate round end events.
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
    -- Monitor Workspace/ReplicatedStorage state attributes for match end signals
    local matchStateConnection = Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
        local currentState = Workspace:GetAttribute("MatchState")
        if self.AutoGreetingEnabled and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
            self:SendGreeting(self.DefaultGreeting)
        end
    end)
    table.insert(self.Connections, matchStateConnection)

    -- Monitor ReplicatedStorage match status attribute if present
    local repConnection = ReplicatedStorage:GetAttributeChangedSignal("Winner"):Connect(function()
        if self.AutoGreetingEnabled then
            self:SendGreeting(self.DefaultGreeting)
        end
    end)
    table.insert(self.Connections, repConnection)
end

function MiscModule:SendGreeting(message)
    local phrase = message or self.DefaultGreeting

    -- Modern TextChatService implementation
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            generalChannel:SendAsync(phrase)
        end
    else
        -- Legacy Chat fallback
        local defaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChatSystemChatEvents then
            local sayMessageRequest = defaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if sayMessageRequest then
                sayMessageRequest:FireServer(phrase, "All")
            end
        end
    end

    print("[Cloak V4 - Auto-Greeting] Dispatched message:", phrase)
end

function MiscModule:SetAutoGreetingEnabled(state)
    self.AutoGreetingEnabled = state
end

function MiscModule:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    table.clear(self.Connections)
end

return MiscModule