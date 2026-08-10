--[[
    Cloak V4 - Player Movement Debugging Engine (Crash-Hardened)
    File: movement.lua
--]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local MovementModule = {
    FlightEnabled = false,
    FlightSpeed = 50,
    SpeedEnabled = false,
    WalkSpeed = 32,
    Connections = {},
    KeysPressed = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false },
}

local function GetSafeCharacter()
    local char = LocalPlayer.Character
    if char and char:Parent() then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            return char, root, hum
        end
    end
    return nil, nil, nil
end

function MovementModule:Init()
    local inputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then self.KeysPressed.W = true end
        if input.KeyCode == Enum.KeyCode.A then self.KeysPressed.A = true end
        if input.KeyCode == Enum.KeyCode.S then self.KeysPressed.S = true end
        if input.KeyCode == Enum.KeyCode.D then self.KeysPressed.D = true end
        if input.KeyCode == Enum.KeyCode.Space then self.KeysPressed.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then self.KeysPressed.LeftShift = true end
    end)

    local inputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then self.KeysPressed.W = false end
        if input.KeyCode == Enum.KeyCode.A then self.KeysPressed.A = false end
        if input.KeyCode == Enum.KeyCode.S then self.KeysPressed.S = false end
        if input.KeyCode == Enum.KeyCode.D then self.KeysPressed.D = false end
        if input.KeyCode == Enum.KeyCode.Space then self.KeysPressed.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then self.KeysPressed.LeftShift = false end
    end)

    table.insert(self.Connections, inputBegan)
    table.insert(self.Connections, inputEnded)

    -- Bind flight velocity application to Heartbeat physics step (prevents RenderStepped crashes)
    local physicsConn = RunService.Heartbeat:Connect(function()
        local _, root, humanoid = GetSafeCharacter()

        if humanoid and self.SpeedEnabled then
            humanoid.WalkSpeed = self.WalkSpeed
        end

        if self.FlightEnabled and root and humanoid then
            local camera = Workspace.CurrentCamera
            if not camera then return end

            local moveVector = Vector3.zero
            local camCFrame = camera.CFrame

            if self.KeysPressed.W then moveVector += camCFrame.LookVector end
            if self.KeysPressed.S then moveVector -= camCFrame.LookVector end
            if self.KeysPressed.D then moveVector += camCFrame.RightVector end
            if self.KeysPressed.A then moveVector -= camCFrame.RightVector end
            if self.KeysPressed.Space then moveVector += Vector3.new(0, 1, 0) end
            if self.KeysPressed.LeftShift then moveVector -= Vector3.new(0, 1, 0) end

            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit * self.FlightSpeed
            end

            root.AssemblyLinearVelocity = moveVector
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end)
    table.insert(self.Connections, physicsConn)
end

function MovementModule:SetFlightEnabled(state)
    self.FlightEnabled = state
    task.defer(function()
        local _, root, humanoid = GetSafeCharacter()
        if not state and root and humanoid then
            root.AssemblyLinearVelocity = Vector3.zero
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end)
end

function MovementModule:SetFlightSpeed(speed)
    self.FlightSpeed = speed
end

function MovementModule:SetSpeedEnabled(state)
    self.SpeedEnabled = state
    if not state then
        task.defer(function()
            local _, _, humanoid = GetSafeCharacter()
            if humanoid then humanoid.WalkSpeed = 16 end
        end)
    end
end

function MovementModule:SetWalkSpeed(speed)
    self.WalkSpeed = speed
end

function MovementModule:Destroy()
    self:SetFlightEnabled(false)
    self:SetSpeedEnabled(false)

    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)
end

return MovementModule