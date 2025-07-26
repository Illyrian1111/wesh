-- Silent Aim Script für DaHood mit 100% Treffer und zentriertem FOV-Kreis

-- Services
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Camera           = workspace.CurrentCamera

-- Einstellungen
local SETTINGS = {
    SilentAim    = false,      -- Startzustand
    Prediction   = 0.165,      -- Vorhersage
    FOV          = 50,         -- Radius des FOV-Kreises
    Target       = nil,        -- aktuell gewähltes Ziel
    Keys = {
        ToggleMenu   = Enum.KeyCode.T,
        SelectTarget = Enum.KeyCode.E,
        ToggleSilent = Enum.KeyCode.R,
    },
}

-- Prüft, ob ein Spieler als Ziel taugt
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if not head then return false end
    local effects = char:FindFirstChild("BodyEffects")
    if effects and effects:FindFirstChild("K.O") and effects["K.O"].Value then
        return false
    end
    if char:FindFirstChild("GRABBING_CONSTRAINT") then
        return false
    end
    return true
end

-- Findet den nächsten gültigen Spieler im FOV
local function getClosest()
    local camPos  = Camera.CFrame.Position
    local camDir  = Camera.CFrame.LookVector
    local bestPl, bestAngle = nil, math.rad(SETTINGS.FOV)
    for _, pl in ipairs(Players:GetPlayers()) do
        if isValidTarget(pl) then
            local head = pl.Character.Head
            local predicted = head.Position + head.Velocity * SETTINGS.Prediction
            local dir = (predicted - camPos).Unit
            local angle = math.acos(camDir:Dot(dir))
            if angle < bestAngle then
                bestAngle, bestPl = angle, pl
            end
        end
    end
    return bestPl
end

-- GUI erstellen
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "SilentAimGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 90)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "Silent Aim Menu"

local silentLabel = Instance.new("TextLabel", frame)
silentLabel.Position = UDim2.new(0, 5, 0, 25)
silentLabel.Size = UDim2.new(1, -10, 0, 20)
silentLabel.BackgroundTransparency = 1
silentLabel.TextColor3 = Color3.new(1,1,1)
silentLabel.Font = Enum.Font.Gotham
silentLabel.TextSize = 14
silentLabel.Text = "Silent Aim: OFF"

local targetLabel = Instance.new("TextLabel", frame)
targetLabel.Position = UDim2.new(0, 5, 0, 50)
targetLabel.Size = UDim2.new(1, -10, 0, 20)
targetLabel.BackgroundTransparency = 1
targetLabel.TextColor3 = Color3.new(1,1,1)
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 14
targetLabel.Text = "Target: None"

-- FOV-Kreis in der Bildschirmmitte
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness    = 2
fovCircle.NumSides     = 100
fovCircle.Radius       = SETTINGS.FOV
fovCircle.Color        = Color3.fromRGB(255, 80, 80)
fovCircle.Filled       = false
fovCircle.Visible      = true

RunService.RenderStepped:Connect(function()
    local center = Camera.ViewportSize * 0.5
    fovCircle.Position = Vector2.new(center.X, center.Y)
end)

-- Tasten-Eingaben
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == SETTINGS.Keys.ToggleMenu then
        frame.Visible = not frame.Visible
    elseif input.KeyCode == SETTINGS.Keys.SelectTarget then
        SETTINGS.Target = getClosest()
        targetLabel.Text = "Target: " .. (SETTINGS.Target and SETTINGS.Target.Name or "None")
    elseif input.KeyCode == SETTINGS.Keys.ToggleSilent then
        SETTINGS.SilentAim = not SETTINGS.SilentAim
        silentLabel.Text = "Silent Aim: " .. (SETTINGS.SilentAim and "ON" or "OFF")
    end
end)

-- Namecall-Hook für 100% Silent Aim
local mt          = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}
    if method == "FireServer"
       and SETTINGS.SilentAim
       and isValidTarget(SETTINGS.Target)
       and typeof(args[1]) == "CFrame" then

        local head = SETTINGS.Target.Character:FindFirstChild("Head")
        if head then
            args[1] = head.CFrame + head.Velocity * SETTINGS.Prediction
        end
    end
    return oldNamecall(self, unpack(args))
end)

setreadonly(mt, true)

print("Silent Aim geladen! [T]=Menu [E]=Select Target [R]=Toggle Silent")
