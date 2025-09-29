-- WA Universal ESP (Rayfield Module)
-- Put this file on GitHub and loadstring() it in your main Coc Hub.
-- Example: loadstring(game:HttpGet("https://raw.githubusercontent.com/YourName/CocHub/main/ESP.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ======================================
-- SETTINGS
-- ======================================
local Settings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,
    BoxESP = false,
    BoxStyle = "Corner", -- Corner | Full | ThreeD
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom", -- Bottom | Top | Center | Mouse
    HealthESP = false,
    HealthStyle = "Bar", -- Bar | Text | Both
    NameESP = false,
    Snaplines = false,
    ChamsEnabled = false,
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsTransparency = 0.5,
    MaxDistance = 1000,
    RefreshRate = 1/144,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5
}

local Colors = {
    Enemy = Color3.fromRGB(255,25,25),
    Ally = Color3.fromRGB(25,255,25),
    Health = Color3.fromRGB(0,255,0),
    Rainbow = nil
}

local Drawings = { ESP = {}, Skeleton = {} }
local Highlights = {}

-- ======================================
-- ESP FUNCTIONS
-- ======================================
local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, obj in pairs(esp) do
            if typeof(obj)=="table" then for _,o in pairs(obj) do o:Remove() end
            else obj:Remove() end
        end
        Drawings.ESP[player] = nil
    end
    if Highlights[player] then
        Highlights[player]:Destroy()
        Highlights[player] = nil
    end
    if Drawings.Skeleton[player] then
        for _, line in pairs(Drawings.Skeleton[player]) do line:Remove() end
        Drawings.Skeleton[player] = nil
    end
end

local function GetTracerOrigin()
    if Settings.TracerOrigin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif Settings.TracerOrigin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif Settings.TracerOrigin == "Center" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    elseif Settings.TracerOrigin == "Mouse" then
        return UserInputService:GetMouseLocation()
    end
    return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
end

local function CreateESP(player)
    if player == LocalPlayer then return end

    local box = {
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = Colors.Enemy
        line.Thickness = Settings.BoxThickness
    end

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = 1

    local health = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    for _, obj in pairs(health) do
        obj.Visible = false
        if obj.Filled ~= nil then obj.Filled = true end
        if obj.Text then obj.Text = "" end
    end

    local info = {
        Name = Drawing.new("Text")
    }
    info.Name.Visible = false
    info.Name.Center = true
    info.Name.Size = 14
    info.Name.Color = Colors.Enemy
    info.Name.Outline = true

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    Highlights[player] = highlight

    Drawings.ESP[player] = {
        Box = box,
        Tracer = tracer,
        Health = health,
        Info = info
    }
end

local function UpdateESP(player)
    if not Settings.Enabled then return end
    local esp = Drawings.ESP[player]
    if not esp then return end
    local character = player.Character
    if not character then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Health.Outline.Visible = false
        esp.Health.Fill.Visible = false
        esp.Health.Text.Visible = false
        esp.Info.Name.Visible = false
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChild("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    local pos, onscreen = Camera:WorldToViewportPoint(root.Position)
    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if not onscreen or distance > Settings.MaxDistance then return end
    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then return end

    local color = player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy

    -- Box
    if Settings.BoxESP then
        local size = character:GetExtentsSize()
        local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, size.Y/2, 0))
        local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, size.Y/2, 0))
        local boxHeight = bottom.Y - top.Y
        local boxWidth = boxHeight / 2
        esp.Box.Left.From = Vector2.new(top.X - boxWidth/2, top.Y)
        esp.Box.Left.To = Vector2.new(top.X - boxWidth/2, bottom.Y)
        esp.Box.Left.Color = color
        esp.Box.Left.Visible = true
        esp.Box.Right.From = Vector2.new(top.X + boxWidth/2, top.Y)
        esp.Box.Right.To = Vector2.new(top.X + boxWidth/2, bottom.Y)
        esp.Box.Right.Color = color
        esp.Box.Right.Visible = true
        esp.Box.Top.From = Vector2.new(top.X - boxWidth/2, top.Y)
        esp.Box.Top.To = Vector2.new(top.X + boxWidth/2, top.Y)
        esp.Box.Top.Color = color
        esp.Box.Top.Visible = true
        esp.Box.Bottom.From = Vector2.new(bottom.X - boxWidth/2, bottom.Y)
        esp.Box.Bottom.To = Vector2.new(bottom.X + boxWidth/2, bottom.Y)
        esp.Box.Bottom.Color = color
        esp.Box.Bottom.Visible = true
    else
        for _, line in pairs(esp.Box) do line.Visible = false end
    end

    -- Tracer
    if Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end

    -- Health
    if Settings.HealthESP then
        local hp, maxhp = hum.Health, hum.MaxHealth
        local hpPercent = hp/maxhp
        esp.Health.Outline.Size = Vector2.new(4, 100)
        esp.Health.Outline.Position = Vector2.new(pos.X - 40, pos.Y - 50)
        esp.Health.Outline.Visible = true
        esp.Health.Fill.Size = Vector2.new(4, 100 * hpPercent)
        esp.Health.Fill.Position = Vector2.new(pos.X - 40, pos.Y - 50 + 100 * (1-hpPercent))
        esp.Health.Fill.Color = Color3.fromRGB(255 - 255*hpPercent, 255*hpPercent, 0)
        esp.Health.Fill.Visible = true
        esp.Health.Text.Text = tostring(math.floor(hp)).." HP"
        esp.Health.Text.Position = Vector2.new(pos.X - 30, pos.Y)
        esp.Health.Text.Visible = Settings.HealthStyle ~= "Bar"
    else
        esp.Health.Outline.Visible = false
        esp.Health.Fill.Visible = false
        esp.Health.Text.Visible = false
    end

    -- Name
    if Settings.NameESP then
        esp.Info.Name.Text = player.DisplayName
        esp.Info.Name.Position = Vector2.new(pos.X, pos.Y - 50)
        esp.Info.Name.Color = color
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end

    -- Chams
    local highlight = Highlights[player]
    if highlight and Settings.ChamsEnabled then
        highlight.Parent = character
        highlight.FillColor = Settings.ChamsFillColor
        highlight.OutlineColor = Settings.ChamsOutlineColor
        highlight.FillTransparency = Settings.ChamsTransparency
        highlight.Enabled = true
    elseif highlight then
        highlight.Enabled = false
    end
end

-- ======================================
-- LOOP
-- ======================================
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not Drawings.ESP[player] then CreateESP(player) end
            UpdateESP(player)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)

-- ======================================
-- RAYFIELD UI
-- ======================================
local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("Universal ESP")

ESPTab:CreateToggle({ Name="Enable ESP", CurrentValue=false, Callback=function(v) Settings.Enabled=v end })
ESPTab:CreateToggle({ Name="Team Check", CurrentValue=false, Callback=function(v) Settings.TeamCheck=v end })
ESPTab:CreateToggle({ Name="Show Team", CurrentValue=false, Callback=function(v) Settings.ShowTeam=v end })
ESPTab:CreateToggle({ Name="Box ESP", CurrentValue=false, Callback=function(v) Settings.BoxESP=v end })
ESPTab:CreateDropdown({ Name="Box Style", Options={"Corner","Full","ThreeD"}, CurrentOption="Corner", Callback=function(v) Settings.BoxStyle=v end })
ESPTab:CreateSlider({ Name="Box Thickness", Range={1,5}, Increment=1, CurrentValue=1, Callback=function(v) Settings.BoxThickness=v end })
ESPTab:CreateToggle({ Name="Tracers", CurrentValue=false, Callback=function(v) Settings.TracerESP=v end })
ESPTab:CreateDropdown({ Name="Tracer Origin", Options={"Bottom","Top","Mouse","Center"}, CurrentOption="Bottom", Callback=function(v) Settings.TracerOrigin=v end })
ESPTab:CreateToggle({ Name="Health Bar", CurrentValue=false, Callback=function(v) Settings.HealthESP=v end })
ESPTab:CreateDropdown({ Name="Health Style", Options={"Bar","Text","Both"}, CurrentOption="Bar", Callback=function(v) Settings.HealthStyle=v end })
ESPTab:CreateToggle({ Name="Names", CurrentValue=false, Callback=function(v) Settings.NameESP=v end })
ESPTab:CreateToggle({ Name="Skeleton", CurrentValue=false, Callback=function(v) Settings.SkeletonESP=v end })
ESPTab:CreateSlider({ Name="Skeleton Thickness", Range={1,3}, Increment=1, CurrentValue=2, Callback=function(v) Settings.SkeletonThickness=v end })
ESPTab:CreateToggle({ Name="Chams", CurrentValue=false, Callback=function(v) Settings.ChamsEnabled=v end })
ESPTab:CreateColorPicker({ Name="Chams Fill", Color=Settings.ChamsFillColor, Callback=function(c) Settings.ChamsFillColor=c end })
ESPTab:CreateColorPicker({ Name="Chams Outline", Color=Settings.ChamsOutlineColor, Callback=function(c) Settings.ChamsOutlineColor=c end })
ESPTab:CreateSlider({ Name="Chams Transparency", Range={0,1}, Increment=0.05, CurrentValue=0.5, Callback=function(v) Settings.ChamsTransparency=v end })
ESPTab:CreateSlider({ Name="Max Distance", Range={100,5000}, Increment=100, CurrentValue=1000, Callback=function(v) Settings.MaxDistance=v end })

return { Settings = Settings, Colors = Colors }

