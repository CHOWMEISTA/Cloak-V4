--[[
    Cloak V4 - Dynamic Remote Bootstrapper (Crash-Hardened)
    File: init.lua
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CloakV4 = {
    Version = "4.0.0",
    Active = false,
    Modules = {},
    Connections = {},
}

local BASE_URL = "https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/"

-- Safe Remote Module Loader with Execution Yielding
local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    -- Intentional yield to prevent network thread starvation
    task.wait(0.05)

    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] HttpGet failed for %s", fileName))
        return nil
    end

    local compileSuccess, moduleChunk = pcall(function()
        return loadstring(rawCode)
    end)

    if not compileSuccess or type(moduleChunk) ~= "function" then
        warn(string.format("[Cloak V4 Error] Loadstring failed for %s: %s", fileName, tostring(moduleChunk)))
        return nil
    end

    -- Delay chunk execution slightly to allow engine service initialization
    task.wait(0.1)

    local executeSuccess, loadedModule = pcall(moduleChunk)
    if not executeSuccess or loadedModule == nil then
        warn(string.format("[Cloak V4 Error] Execution error in %s: %s", fileName, tostring(loadedModule)))
        return nil
    end

    return loadedModule
end

function CloakV4:Init()
    if self.Active then return end

    -- Wrap whole initialization in task.spawn to keep calling executor context alive
    task.spawn(function()
        local UILib = LoadRemoteModule("uilib.lua")
        if not UILib then warn("[Cloak V4 Abort] uilib.lua failed.") return end

        local Combat = LoadRemoteModule("combat.lua")
        if not Combat then warn("[Cloak V4 Abort] combat.lua failed.") return end

        local Movement = LoadRemoteModule("movement.lua")
        if not Movement then warn("[Cloak V4 Abort] movement.lua failed.") return end

        local Misc = LoadRemoteModule("misc.lua")
        if not Misc then warn("[Cloak V4 Abort] misc.lua failed.") return end

        self.Active = true
        self.Modules = { UILib = UILib, Combat = Combat, Movement = Movement, Misc = Misc }

        -- Build Interface
        local Window = UILib:CreateWindow("Cloak V4")

        -- Combat Tab
        local CombatTab = Window:CreateTab("Combat")
        CombatTab:CreateToggle("Target Assist (CamLock)", false, function(s) Combat:SetTargetAssistEnabled(s) end)
        CombatTab:CreateSlider("Target FOV", 30, 300, 120, function(v) Combat:SetFOV(v) end)
        CombatTab:CreateSlider("Smoothness", 1, 20, 5, function(v) Combat:SetSmoothing(v) end)
        CombatTab:CreateToggle("Click Validation Tool", false, function(s) Combat:SetClickValidationEnabled(s) end)

        -- Movement Tab
        local MovementTab = Window:CreateTab("Movement")
        MovementTab:CreateToggle("Sandbox Flight Engine", false, function(s) Movement:SetFlightEnabled(s) end)
        MovementTab:CreateSlider("Flight Speed", 10, 200, 50, function(v) Movement:SetFlightSpeed(v) end)
        MovementTab:CreateToggle("Speed Multiplier", false, function(s) Movement:SetSpeedEnabled(s) end)
        MovementTab:CreateSlider("WalkSpeed Multiplier", 16, 120, 32, function(v) Movement:SetWalkSpeed(v) end)

        -- Automation Tab
        local MiscTab = Window:CreateTab("Automation")
        MiscTab:CreateToggle("Auto-Greeting on Match End", false, function(s) Misc:SetAutoGreetingEnabled(s) end)
        MiscTab:CreateButton("Trigger Manual Greeting Test", function() Misc:SendGreeting("GG! Thanks for testing Cloak V4.") end)

        -- Hotkey Binding
        local toggleConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                Window:ToggleVisibility()
            end
        end)
        table.insert(self.Connections, toggleConnection)

        -- Safely initialize child runtimes asynchronously
        task.defer(function() Combat:Init() end)
        task.defer(function() Movement:Init() end)
        task.defer(function() Misc:Init() end)

        print("[Cloak V4] Suite fully loaded and active.")
    end)
end

function CloakV4:Destroy()
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)

    if self.Modules.Combat then self.Modules.Combat:Destroy() end
    if self.Modules.Movement then self.Modules.Movement:Destroy() end
    if self.Modules.Misc then self.Modules.Misc:Destroy() end
    if self.Modules.UILib then self.Modules.UILib:Destroy() end

    self.Active = false
end

task.defer(function()
    CloakV4:Init()
end)

return CloakV4