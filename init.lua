--[[
    Cloak V4 - Dynamic Remote Bootstrapper (Freeze-Proof)
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

-- Safe Remote Module Loader with GC Breathers
local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    -- Explicit thread yield to let the task scheduler breathe
    task.wait(0.2)

    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] HttpGet failed for %s", fileName))
        return nil
    end

    task.wait(0.1)

    local compileSuccess, moduleChunk = pcall(function()
        return loadstring(rawCode)
    end)

    if not compileSuccess or type(moduleChunk) ~= "function" then
        warn(string.format("[Cloak V4 Error] Loadstring failed for %s: %s", fileName, tostring(moduleChunk)))
        return nil
    end

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

    -- Fully decouple the bootstrap sequence onto its own isolated green thread
    task.spawn(function()
        local UILib = LoadRemoteModule("uilib.lua")
        if not UILib then warn("[Cloak V4 Abort] uilib.lua failed.") return end
        task.wait(0.2)

        local Combat = LoadRemoteModule("combat.lua")
        if not Combat then warn("[Cloak V4 Abort] combat.lua failed.") return end
        task.wait(0.2)

        local Movement = LoadRemoteModule("movement.lua")
        if not Movement then warn("[Cloak V4 Abort] movement.lua failed.") return end
        task.wait(0.2)

        local Misc = LoadRemoteModule("misc.lua")
        if not Misc then warn("[Cloak V4 Abort] misc.lua failed.") return end
        task.wait(0.2)

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
                task.spawn(function()
                    Window:ToggleVisibility()
                end)
            end
        end)
        table.insert(self.Connections, toggleConnection)

        -- Initialize child modules in isolated green threads with staggering
        task.spawn(function() Combat:Init() end)
        task.wait(0.1)
        task.spawn(function() Movement:Init() end)
        task.wait(0.1)
        task.spawn(function() Misc:Init() end)

        print("[Cloak V4] Suite fully loaded and active.")
    end)
end

function CloakV4:Destroy()
    task.spawn(function()
        for _, conn in ipairs(self.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(self.Connections)

        if self.Modules.Combat then pcall(function() self.Modules.Combat:Destroy() end) end
        if self.Modules.Movement then pcall(function() self.Modules.Movement:Destroy() end) end
        if self.Modules.Misc then pcall(function() self.Modules.Misc:Destroy() end) end
        if self.Modules.UILib then pcall(function() self.Modules.UILib:Destroy() end) end

        self.Active = false
        print("[Cloak V4] Clean shutdown complete.")
    end)
end

task.defer(function()
    CloakV4:Init()
end)

return CloakV4