--[[
    Cloak V4 - Player Movement Debugging Engine
    File: movement.lua
    Description: Provides WASD+Space/Shift sandbox flight navigation and WalkSpeed control.
--]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MovementModule = {
    FlightEnabled = false,
    FlightSpeed = 50,
    SpeedEnabled = false,
    WalkSpeed = 32,
    Connections = {},
    KeysPressed = { W = false, A = false, S = false, D = false, Space = false, LeftShift = false },
    LinearVelocity = nil,
    Attachment = nil,
}

local function GetRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function MovementModule:Init()
    -- Key bindings tracking for Flight movement
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

    -- Primary Flight & Speed Multiplier Physics Loop
    local renderConn = RunService.RenderStepped:Connect(function(deltaTime)
        local root = GetRootPart()
        local humanoid = GetHumanoid()

        -- WalkSpeed Modifier Loop
        if humanoid then
            if self.SpeedEnabled then
                humanoid.WalkSpeed = self.WalkSpeed
            else
                if humanoid.WalkSpeed == self.WalkSpeed then
                    humanoid.WalkSpeed = 16
                end
            end
        end

        -- Flight Engine Logic
        if self.FlightEnabled and root then
            local moveVector = Vector3.zero
            local camCFrame = Camera.CFrame

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
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end
    end)
    table.insert(self.Connections, renderConn)
end

function MovementModule:SetFlightEnabled(state)
    self.FlightEnabled = state
    local root = GetRootPart()
    local humanoid = GetHumanoid()

    if not state and root then
        root.AssemblyLinearVelocity = Vector3.zero
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end

function MovementModule:SetFlightSpeed(speed)
    self.FlightSpeed = speed
end

function MovementModule:SetSpeedEnabled(state)
    self.SpeedEnabled = state
    if not state then
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

function MovementModule:SetWalkSpeed(speed)
    self.WalkSpeed = speed
end

function MovementModule:Destroy()
    self:SetFlightEnabled(false)
    self:SetSpeedEnabled(false)

    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    table.clear(self.Connections)
end

return MovementModule