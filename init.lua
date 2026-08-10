--[[
    Cloak V4 - Dynamic Remote Bootstrapper (Fully Consolidated)
    File: init.lua
    Repository: https://raw.githubusercontent.com/CHOWMEISTA/Cloak-V4/refs/heads/main/
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

local function LoadRemoteModule(fileName)
    local fullUrl = BASE_URL .. fileName
    print(string.format("[Cloak V4] Fetching remote file: %s...", fileName))

    task.wait(0.2)

    local httpSuccess, rawCode = pcall(function()
        return game:HttpGet(fullUrl)
    end)

    if not httpSuccess or type(rawCode) ~= "string" or #rawCode == 0 then
        warn(string.format("[Cloak V4 Error] Failed to HttpGet %s from: %s", fileName, fullUrl))
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

    print(string.format("[Cloak V4] Successfully loaded %s", fileName))
    return loadedModule
end

function CloakV4:Init()
    if self.Active then return end

    task.spawn(function()
        -- Load modules sequentially
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

        -- Build Expanded Window
        local Window = UILib:CreateWindow("Cloak V4")

        -- ---------------------------------------------------------------------
        -- TAB 1: COMBAT
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
        -- TAB 2: HITBOXES
        -- ---------------------------------------------------------------------
        local HitboxTab = Window:CreateTab("Hitboxes")

        HitboxTab:CreateToggle("Expand Target Hitboxes", false, function(state)
            Combat:SetHitboxEnabled(state)
        end)

        HitboxTab:CreateSlider("Hitbox Scale", 2, 35, 10, function(val)
            Combat:SetHitboxSize(val)
        end)

        HitboxTab:CreateSlider("Hitbox Transparency %", 0, 10, 7, function(val)
            Combat:SetHitboxTransparency(val / 10)
        end)

        -- ---------------------------------------------------------------------
        -- TAB 3: MOVEMENT
        -- ---------------------------------------------------------------------
        local MovementTab = Window:CreateTab("Movement")

        MovementTab:CreateToggle("Sandbox Flight Engine", false, function(state)
            Movement:SetFlightEnabled(state)
        end)

        MovementTab:CreateSlider("Flight Speed", 10, 200, 50, function(val)
            Movement:SetFlightSpeed(val)
        end)

        MovementTab:CreateToggle("WalkSpeed Multiplier", false, function(state)
            Movement:SetSpeedEnabled(state)
        end)

        MovementTab:CreateSlider("WalkSpeed Value", 16, 150, 32, function(val)
            Movement:SetWalkSpeed(val)
        end)

        MovementTab:CreateToggle("Infinite Jump", false, function(state)
            Movement:SetInfiniteJumpEnabled(state)
        end)

        MovementTab:CreateToggle("Jump Power Modifier", false, function(state)
            Movement:SetJumpPowerEnabled(state)
        end)

        MovementTab:CreateSlider("Jump Power Value", 50, 300, 50, function(val)
            Movement:SetJumpPower(val)
        end)

        -- ---------------------------------------------------------------------
        -- TAB 4: VISUALS
        -- ---------------------------------------------------------------------
        local VisualsTab = Window:CreateTab("Visuals")

        VisualsTab:CreateToggle("Entity Highlight (ESP)", false, function(state)
            Misc:SetESPEnabled(state)
        end)

        VisualsTab:CreateToggle("Snap Tracers", false, function(state)
            Misc:SetTracersEnabled(state)
        end)

        VisualsTab:CreateToggle("Use Team Colors", true, function(state)
            Misc:SetUseTeamColors(state)
        end)

        VisualsTab:CreateToggle("FOV Circle Overlay", false, function(state)
            Combat:SetFOVCircleEnabled(state)
        end)

        VisualsTab:CreateToggle("Fullbright Mode", false, function(state)
            Misc:SetFullbrightEnabled(state)
        end)

        -- ---------------------------------------------------------------------
        -- TAB 5: AUTOMATION
        -- ---------------------------------------------------------------------
        local AutoTab = Window:CreateTab("Automation")

        AutoTab:CreateToggle("Auto-Greeting on Match End", false, function(state)
            Misc:SetAutoGreetingEnabled(state)
        end)

        AutoTab:CreateButton("Trigger Manual Greeting Test", function()
            Misc:SendGreeting("GG! Thanks for testing Cloak V4.")
        end)

        -- Hotkey Binding
        local toggleConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                task.spawn(function()
                    Window:ToggleVisibility()
                end)
            end
        end)
        table.insert(self.Connections, toggleConnection)

        -- Start runtimes asynchronously
        task.spawn(function() Combat:Init() end)
        task.wait(0.1)
        task.spawn(function() Movement:Init() end)
        task.wait(0.1)
        task.spawn(function() Misc:Init() end)

        print("[Cloak V4] Suite fully initialized with 5 expanded tabs.")
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