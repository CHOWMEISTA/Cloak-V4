--[[
    Cloak V4 - Automation Tools (Freeze-Proof)
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
    -- Completely event-driven: zero polling loops
    local matchStateConnection = Workspace:GetAttributeChangedSignal("MatchState"):Connect(function()
        task.spawn(function()
            local currentState = Workspace:GetAttribute("MatchState")
            if self.AutoGreetingEnabled and (currentState == "Ended" or currentState == "Finished" or currentState == "GameOver") then
                self:SendGreeting(self.DefaultGreeting)
            end
        end)
    end)
    table.insert(self.Connections, matchStateConnection)

    local repConnection = ReplicatedStorage:GetAttributeChangedSignal("Winner"):Connect(function()
        task.spawn(function()
            if self.AutoGreetingEnabled then
                self:SendGreeting(self.DefaultGreeting)
            end
        end)
    end)
    table.insert(self.Connections, repConnection)
end

function MiscModule:SendGreeting(message)
    task.spawn(function()
        local phrase = message or self.DefaultGreeting

        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                pcall(function()
                    generalChannel:SendAsync(phrase)
                end)
            end
        else
            local defaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if defaultChatSystemChatEvents then
                local sayMessageRequest = defaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then
                    pcall(function()
                        sayMessageRequest:FireServer(phrase, "All")
                    end)
                end
            end
        end
    end)
end

function MiscModule:SetAutoGreetingEnabled(state)
    task.spawn(function() self.AutoGreetingEnabled = state end)
end

function MiscModule:Destroy()
    task.spawn(function()
        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)
    end)
end

return MiscModule