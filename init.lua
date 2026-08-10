--[[
    Cloak V4 - Dynamic Remote Bootstrapper
    File: init.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Global Framework Object
local CloakV4 = {
    Version = "4.0.0",
    Active = false,
    Modules = {},
    Connections = {},
}

-- Base Repository Mapping
local BASE_URL = "https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/"

-- Module File Definitions
local MODULE_FILES = {
    "uilib.lua",
    "combat.lua",
    "movement.lua",
    "misc.lua"
}

-- Safe Remote Module Loader
local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    -- 1. HTTP Request
    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] Failed to HttpGet %s from: %s", fileName, fullUrl))
        return nil
    end

    -- 2. Code Compilation
    local compileSuccess, moduleChunk = pcall(function()
        return loadstring(rawCode)
    end)

    if not compileSuccess or type(moduleChunk) ~= "function" then
        warn(string.format("[Cloak V4 Error] Failed to compile %s: %s", fileName, tostring(moduleChunk)))
        return nil
    end

    -- 3. Module Execution
    local executeSuccess, loadedModule = pcall(moduleChunk)

    if not executeSuccess or loadedModule == nil then
        warn(string.format("[Cloak V4 Error] Runtime error while executing %s: %s", fileName, tostring(loadedModule)))
        return nil
    end

    print(string.format("[Cloak V4] Successfully loaded %s", fileName))
    return loadedModule
end

function CloakV4:Init()
    if self.Active then return end

    -- ---------------------------------------------------------------------
    -- SEQUENTIAL MODULE LOADING
    -- ---------------------------------------------------------------------
    
    -- Step 1: Must load UI Library framework first
    local UILib = LoadRemoteModule("uilib.lua")
    if not UILib then
        warn("[Cloak V4 Error] Failed to load uilib.lua. Halting boot sequence.")
        return
    end

    -- Step 2: Load feature engine modules sequentially
    local Combat = LoadRemoteModule("combat.lua")
    if not Combat then
        warn("[Cloak V4 Error] Failed to load combat.lua. Halting boot sequence.")
        return
    end

    local Movement = LoadRemoteModule("movement.lua")
    if not Movement then
        warn("[Cloak V4 Error] Failed to load movement.lua. Halting boot sequence.")
        return
    end

    local Misc = LoadRemoteModule("misc.lua")
    if not Misc then
        warn("[Cloak V4 Error] Failed to load misc.lua. Halting boot sequence.")
        return
    end

    self.Active = true

    -- Bind module references
    self.Modules.UILib = UILib
    self.Modules.Combat = Combat
    self.Modules.Movement = Movement
    self.Modules.Misc = Misc

    -- Initialize UI Instance
    local Window = UILib:CreateWindow("Cloak V4")

    -- ---------------------------------------------------------------------
    -- COMBAT TAB
    -- ---------------------------------------------------------------------
    local CombatTab = Window:CreateTab("Combat")

    CombatTab:CreateToggle("Target Assist (CamLock)", false, function(state)
        Combat:SetTargetAssistEnabled(state)
    end)

    CombatTab:CreateSlider("Target FOV", 30, 300, 120, function(val)
        Combat:SetFOV(val)
    end)

    CombatTab:CreateSlider("Smoothness", 1, 20, 5, function(val)
        Combat:SetSmoothing(val)
    end)

    CombatTab:CreateToggle("Click Validation Tool", false, function(state)
        Combat:SetClickValidationEnabled(state)
    end)

    -- ---------------------------------------------------------------------
    -- MOVEMENT TAB
    -- ---------------------------------------------------------------------
    local MovementTab = Window:CreateTab("Movement")

    MovementTab:CreateToggle("Sandbox Flight Engine", false, function(state)
        Movement:SetFlightEnabled(state)
    end)

    MovementTab:CreateSlider("Flight Speed", 10, 200, 50, function(val)
        Movement:SetFlightSpeed(val)
    end)

    MovementTab:CreateToggle("Speed Multiplier", false, function(state)
        Movement:SetSpeedEnabled(state)
    end)

    MovementTab:CreateSlider("WalkSpeed Multiplier", 16, 120, 32, function(val)
        Movement:SetWalkSpeed(val)
    end)

    -- ---------------------------------------------------------------------
    -- AUTOMATION TAB
    -- ---------------------------------------------------------------------
    local MiscTab = Window:CreateTab("Automation")

    MiscTab:CreateToggle("Auto-Greeting on Match End", false, function(state)
        Misc:SetAutoGreetingEnabled(state)
    end)

    MiscTab:CreateButton("Trigger Manual Greeting Test", function()
        Misc:SendGreeting("GG! Thanks for testing Cloak V4.")
    end)

    -- ---------------------------------------------------------------------
    -- HOTKEY BINDING (RightShift to Toggle Panel)
    -- ---------------------------------------------------------------------
    local toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Window:ToggleVisibility()
        end
    end)
    table.insert(self.Connections, toggleConnection)

    -- Initialize engine runtimes
    Combat:Init()
    Movement:Init()
    Misc:Init()

    print("[Cloak V4] Suite fully booted and initialized.")
end

function CloakV4:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    table.clear(self.Connections)

    if self.Modules.Combat then self.Modules.Combat:Destroy() end
    if self.Modules.Movement then self.Modules.Movement:Destroy() end
    if self.Modules.Misc then self.Modules.Misc:Destroy() end
    if self.Modules.UILib then self.Modules.UILib:Destroy() end

    self.Active = false
    print("[Cloak V4] Suite shut down.")
end

-- Defer execution to run on next frame safety window
task.defer(function()
    CloakV4:Init()
end)

return CloakV4