--[[
    Cloak V4 - Master Bootstrapper (Schema Driven)
    File: init.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local CloakV4 = {
    Version = "4.0.0",
    Active = false,
    Modules = {},
    Connections = {},
}

local BASE_URL = "https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/"

local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    task.wait(0.15)

    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] Failed to HttpGet %s", fileName))
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
        warn(string.format("[Cloak V4 Error] Runtime execution error in %s: %s", fileName, tostring(loadedModule)))
        return nil
    end

    return loadedModule
end

function CloakV4:Init()
    if self.Active then return end

    task.spawn(function()
        -- 1. Load GUI Manager first
        local GUI = LoadRemoteModule("gui.lua")
        if not GUI then warn("[Cloak V4 Abort] gui.lua failed to load.") return end
        task.wait(0.15)

        -- 2. Load Engine Modules
        local Combat = LoadRemoteModule("combat.lua")
        local Movement = LoadRemoteModule("movement.lua")
        local Misc = LoadRemoteModule("misc.lua")

        self.Active = true
        self.Modules = { GUI = GUI, Combat = Combat, Movement = Movement, Misc = Misc }

        -- 3. Initialize Window
        GUI:CreateWindow("Cloak V4")

        -- ---------------------------------------------------------------------
        -- HOW TO ADD TABS & MODULES EASY:
        -- ---------------------------------------------------------------------

        -- TAB 1: COMBAT
        if Combat then
            local CombatTab = GUI:CreateTab("Combat")
            CombatTab:AddToggle("Target Assist (CamLock)", false, function(s) Combat:SetTargetAssistEnabled(s) end)
            CombatTab:AddSlider("Target FOV", 30, 300, 120, function(v) Combat:SetFOV(v) end)
            CombatTab:AddSlider("Smoothness", 1, 20, 5, function(v) Combat:SetSmoothing(v) end)
            CombatTab:AddToggle("Click Validation Tool", false, function(s) Combat:SetClickValidationEnabled(s) end)
            CombatTab:AddToggle("FOV Circle Overlay", false, function(s) Combat:SetFOVCircleEnabled(s) end)

            -- TAB 2: HITBOXES
            local HitboxTab = GUI:CreateTab("Hitboxes")
            HitboxTab:AddToggle("Expand Target Hitboxes", false, function(s) Combat:SetHitboxEnabled(s) end)
            HitboxTab:AddSlider("Hitbox Scale", 2, 35, 10, function(v) Combat:SetHitboxSize(v) end)
            HitboxTab:AddSlider("Hitbox Transparency %", 0, 10, 7, function(v) Combat:SetHitboxTransparency(v / 10) end)
        end

        -- TAB 3: MOVEMENT
        if Movement then
            local MovementTab = GUI:CreateTab("Movement")
            MovementTab:AddToggle("Sandbox Flight Engine", false, function(s) Movement:SetFlightEnabled(s) end)
            MovementTab:AddSlider("Flight Speed", 10, 200, 50, function(v) Movement:SetFlightSpeed(v) end)
            MovementTab:AddToggle("WalkSpeed Multiplier", false, function(s) Movement:SetSpeedEnabled(s) end)
            MovementTab:AddSlider("WalkSpeed Value", 16, 150, 32, function(v) Movement:SetWalkSpeed(v) end)
            MovementTab:AddToggle("Infinite Jump", false, function(s) Movement:SetInfiniteJumpEnabled(s) end)
            MovementTab:AddToggle("Jump Power Modifier", false, function(s) Movement:SetJumpPowerEnabled(s) end)
            MovementTab:AddSlider("Jump Power Value", 50, 300, 50, function(v) Movement:SetJumpPower(v) end)
        end

        -- TAB 4: VISUALS
        if Misc then
            local VisualsTab = GUI:CreateTab("Visuals")
            VisualsTab:AddToggle("Entity Highlight (ESP)", false, function(s) Misc:SetESPEnabled(s) end)
            VisualsTab:AddToggle("Snap Tracers", false, function(s) Misc:SetTracersEnabled(s) end)
            VisualsTab:AddToggle("Use Team Colors", true, function(s) Misc:SetUseTeamColors(s) end)
            VisualsTab:AddToggle("Fullbright Mode", false, function(s) Misc:SetFullbrightEnabled(s) end)

            -- TAB 5: AUTOMATION
            local AutoTab = GUI:CreateTab("Automation")
            AutoTab:AddToggle("Auto-Greeting on Match End", false, function(s) Misc:SetAutoGreetingEnabled(s) end)
            AutoTab:AddButton("Trigger Manual Greeting Test", function() Misc:SendGreeting("GG! Thanks for testing Cloak V4.") end)
        end

        -- EXAMPLE: TO ADD A NEW TAB (e.g. Settings Tab), JUST DO THIS:
        local SettingsTab = GUI:CreateTab("Settings")
        SettingsTab:AddButton("Unload Suite", function()
            CloakV4:Destroy()
        end)

        -- Hotkey Binding (RightShift)
        local toggleConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                GUI:ToggleVisibility()
            end
        end)
        table.insert(self.Connections, toggleConnection)

        -- Initialize child runtimes safely
        if Combat and Combat.Init then task.spawn(function() Combat:Init() end) end
        if Movement and Movement.Init then task.spawn(function() Movement:Init() end) end
        if Misc and Misc.Init then task.spawn(function() Misc:Init() end) end

        print("[Cloak V4] Suite fully initialized with gui.lua interface engine.")
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
        if self.Modules.GUI then pcall(function() self.Modules.GUI:Destroy() end) end

        self.Active = false
        print("[Cloak V4] Suite shut down.")
    end)
end

task.defer(function()
    CloakV4:Init()
end)

return CloakV4