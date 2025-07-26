--== Einstellungen ==--
local SETTINGS = {
    SilentAim    = false,             -- Startzustand Silent Aim
    Prediction   = 0.165,             -- Vorhersage für bewegliche Ziele
    FOV          = 50,                -- Sichtfeldradius
    Target       = nil,               -- momentan gewähltes Ziel
    Keys = {
        ToggleMenu   = Enum.KeyCode.T,
        SelectTarget = Enum.KeyCode.E,
        ToggleSilent = Enum.KeyCode.R,
    }
}

--== Services ==--
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

--== Hilfsfunktionen ==--
-- Prüft, ob ein Spieler als Ziel taugt (nicht downed, nicht sich selbst usw.)
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

-- Sucht den nächsten gültigen Spieler im FOV
local function getClosest()
    local cam    = workspace.CurrentCamera
    local pos    = cam.CFrame.Position
    local look   = cam.CFrame.LookVector
    local best   = nil
    local bestAngle = math.rad(SETTINGS.FOV)
    for _, pl in ipairs(Players:GetPlayers()) do
        if isValidTarget(pl) then
            local head = pl.Character.Head
            local predicted = head.Position + head.Velocity * SETTINGS.Prediction
            local dir = (predicted - pos).Unit
            local angle = math.acos(look:Dot(dir))
            if angle < bestAngle then
                bestAngle = angle
                best = pl
            end
        end
    end
    return best
end

--== GUI erstellen ==--
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

--== FOV‑Kreis zeichnen ==--
local circle = Drawing.new("Circle")
circle.Thickness  = 2
circle.NumSides   = 100
circle.Radius     = SETTINGS.FOV
circle.Color      = Color3.fromRGB(255, 80, 80)
circle.Filled     = false
circle.Visible    = true

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Mouse.X, Mouse.Y)
    circle.Radius   = SETTINGS.FOV
end)

--== Tasten‑Ereignisse ==--
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == SETTINGS.Keys.ToggleMenu then
        frame.Visible = not frame.Visible
    elseif input.KeyCode == SETTINGS.Keys.SelectTarget then
        local pl = getClosest()
        SETTINGS.Target = pl
        targetLabel.Text = "Target: " .. (pl and pl.Name or "None")
    elseif input.KeyCode == SETTINGS.Keys.ToggleSilent then
        SETTINGS.SilentAim = not SETTINGS.SilentAim
        silentLabel.Text = "Silent Aim: " .. (SETTINGS.SilentAim and "ON" or "OFF")
    end
end)

--== Silent Aim Hook ==--
-- Basierend auf der Silent‑Aimlock‑Technik für DaHood :contentReference[oaicite:0]{index=0}
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt,false)
mt.__index = newcclosure(function(t,k)
    if t:IsA("Mouse") and (k=="Hit" or k=="Target")
       and SETTINGS.SilentAim
       and isValidTarget(SETTINGS.Target) then

        local head = SETTINGS.Target.Character:FindFirstChild("Head")
        if head then
            local predictedCF = head.CFrame + head.Velocity * SETTINGS.Prediction
            if k=="Hit" then
                return predictedCF
            else -- k=="Target"
                return head
            end
        end
    end
    return oldIndex(t,k)
end)
setreadonly(mt,true)

print("Silent Aim for DaHood loaded. Menü mit [T], Zielwahl mit [E], Toggle Silent mit [R].")
