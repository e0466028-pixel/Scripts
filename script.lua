-- language: Lua, file: universal_v16.lua
-- developer: SOfkatok42
-- key: qweqaz42

print("[Lokeii] start")

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local VALID_KEY = "qweqaz42"

local function getGuiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local ok2 = pcall(function()
            local f = Instance.new("Frame"); f.Parent = cg; f:Destroy(); return true
        end)
        if ok2 then return cg end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then pg = Instance.new("PlayerGui"); pg.Parent = LP end
    return pg
end
local GUI_PARENT = getGuiParent()

-- ============================================================
-- ЗВУК
-- ============================================================
local SHOT_IDS = {"rbxassetid://9114727096","rbxassetid://1243750634","rbxassetid://131886985"}
local akSound = nil
local function playShot()
    if not akSound or not akSound.Parent then
        akSound = Instance.new("Sound")
        akSound.Volume = 1.8
        akSound.Parent = workspace.CurrentCamera
        for _, id in ipairs(SHOT_IDS) do
            local ok = pcall(function() akSound.SoundId = id end)
            if ok and akSound.SoundId ~= "" then break end
        end
    end
    if akSound then
        akSound.PlaybackSpeed = 0.9 + math.random() * 0.1
        akSound.TimePosition = 0
        akSound:Play()
    end
end

-- ============================================================
-- ТРАССЕР
-- ============================================================
local function spawnTracer(fromPos, toPos)
    local dist = (toPos - fromPos).Magnitude
    if dist < 1 then return end
    local t = Instance.new("Part")
    t.Anchored = true; t.CanCollide = false; t.CanQuery = false
    t.Material = Enum.Material.Neon
    t.Color = Color3.fromRGB(255, 100, 200)
    t.Size = Vector3.new(0.15, 0.15, dist)
    t.CFrame = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -dist/2)
    t.Parent = workspace
    TweenService:Create(t, TweenInfo.new(0.15), {Transparency=1, Size=Vector3.new(0.02,0.02,dist)}):Play()
    Debris:AddItem(t, 0.2)
end

-- ============================================================
-- МОДЕЛЬ АК — Scale 0.08
-- ============================================================
local currentBarrel = nil

local function buildAK()
    local tool = Instance.new("Tool")
    tool.Name = "AK-47"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.GripForward = Vector3.new(0,0,-1)
    tool.GripRight = Vector3.new(1,0,0)
    tool.GripUp = Vector3.new(0,1,0)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2,0.2,0.2)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Parent = tool

    local gunPart = Instance.new("Part")
    gunPart.Name = "AKMesh"
    gunPart.Size = Vector3.new(0.5,0.5,0.5)
    gunPart.Transparency = 0
    gunPart.CanCollide = false
    gunPart.Massless = true
    gunPart.Parent = tool

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://477006495"
    mesh.TextureId = "rbxassetid://477006525"
    mesh.Scale = Vector3.new(0.08, 0.08, 0.08)
    mesh.Parent = gunPart

    local w = Instance.new("WeldConstraint")
    w.Part0 = handle
    w.Part1 = gunPart
    w.Parent = handle

    currentBarrel = gunPart
    return tool
end

local function giveAK()
    local char = LP.Character
    if not char then return end
    local bp = LP:FindFirstChildOfClass("Backpack") or char
    if bp:FindFirstChild("AK-47") or char:FindFirstChild("AK-47") then return end
    local tool = buildAK()
    tool.Parent = bp
    tool.Equipped:Connect(function()
        tool:SetAttribute("Lokeii_AK", true)
    end)
end

-- ============================================================
-- ФЛИНГ
-- ============================================================
local flinging = false
local function SkidFlingCharacter(targetChar)
    if flinging then return end
    if not targetChar then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not root then return end
    local thum = targetChar:FindFirstChildOfClass("Humanoid")
    local troot = thum and thum.RootPart
    if not troot then return end
    if thum.Sit then return end
    flinging = true
    local mySavedCFrame = root.CFrame
    local myParts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false; table.insert(myParts, p) end
    end
    local SPIN_SPEED = 1200
    local FLING_VELOCITY = 3000
    local FLING_UP = 15000
    local MAX_SPIN_TIME = 0.6
    local MAX_ATTEMPTS = 6
    local flung = false
    for attempt = 1, MAX_ATTEMPTS do
        local angle = 0
        local startTime = tick()
        repeat
            task.wait(0.01)
            angle = angle + SPIN_SPEED * 0.01
            local offset = Vector3.new(math.cos(math.rad(angle))*0.8, 0, math.sin(math.rad(angle))*0.8)
            root.CFrame = CFrame.new(troot.Position + offset) * CFrame.Angles(0, math.rad(angle), 0)
            root.Velocity = Vector3.new(FLING_VELOCITY, FLING_UP, FLING_VELOCITY)
            root.RotVelocity = Vector3.new(0, FLING_VELOCITY * 3, 0)
            if troot.Velocity.Magnitude > 200 or troot.AssemblyLinearVelocity.Magnitude > 200 then
                flung = true; break
            end
        until tick() > startTime + MAX_SPIN_TIME
        if flung then break end
    end
    task.wait(0.3)
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = mySavedCFrame
    for _, p in ipairs(myParts) do if p and p.Parent then p.CanCollide = true end end
    local antiStart = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - antiStart > 1 then if conn then conn:Disconnect() end return end
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        if r.AssemblyLinearVelocity.Magnitude > 30 or r.AssemblyAngularVelocity.Magnitude > 30 then
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.Velocity = Vector3.zero
            r.RotVelocity = Vector3.zero
            r.CFrame = mySavedCFrame
        end
    end)
    task.delay(1.2, function() if conn then conn:Disconnect() end flinging = false end)
end

local function getNearestCharacter()
    local char = LP.Character
    local myroot = char and char:FindFirstChild("HumanoidRootPart")
    if not myroot then return nil end
    local best, bd = nil, 100
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local c = p.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - myroot.Position).Magnitude
                if d < bd then best, bd = c, d end
            end
        end
    end
    return best
end

-- ============================================================
-- СТРЕЛЬБА
-- ============================================================
local function getMuzzlePos()
    if currentBarrel and currentBarrel.Parent then
        return currentBarrel.Position + currentBarrel.CFrame.LookVector * 0.5
    end
    local char = LP.Character
    if char and char:FindFirstChild("Head") then return char.Head.Position end
    return workspace.CurrentCamera.CFrame.Position
end

local function shoot()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local cam = workspace.CurrentCamera
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    params.IgnoreWater = true
    local result = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 2000, params)
    local endPos = result and result.Position or (cam.CFrame.Position + cam.CFrame.LookVector * 2000)
    playShot()
    spawnTracer(getMuzzlePos(), endPos)
    if not result then return end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model then return end
    if not model:FindFirstChildOfClass("Humanoid") then
        local up = model.Parent
        if up and up:IsA("Model") and up:FindFirstChildOfClass("Humanoid") then model = up end
    end
    if not model:FindFirstChildOfClass("Humanoid") then return end
    if model ~= char then SkidFlingCharacter(model) end
end

-- ============================================================
-- МЕНЮ
-- ============================================================
print("[Lokeii] creating menu")

local gui = Instance.new("ScreenGui")
gui.Name = "Lokeii_Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = GUI_PARENT

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 300)
main.Position = UDim2.new(0, 40, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = main
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 80, 200); stroke.Thickness = 1.5; stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
header.BorderSizePixel = 0
header.Parent = main
local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 12); hc.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 24)
title.Position = UDim2.new(0, 14, 0, 8)
title.BackgroundTransparency = 1
title.Text = "TT DREi"
title.TextColor3 = Color3.fromRGB(255, 150, 220)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -70, 0, 16)
subtitle.Position = UDim2.new(0, 14, 0, 32)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Разработчик: SOfkatok42"
subtitle.TextColor3 = Color3.fromRGB(200, 180, 240)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -62, 0, 8)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 90)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.AutoButtonColor = false
minBtn.Parent = header
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 6); mc.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 80)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 230, 245)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = closeBtn

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -60)
body.Position = UDim2.new(0, 0, 0, 60)
body.BackgroundTransparency = 1
body.Parent = main

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1, -24, 0, 86)
keyFrame.Position = UDim2.new(0, 12, 0, 12)
keyFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = body
local kfc = Instance.new("UICorner"); kfc.CornerRadius = UDim.new(0, 8); kfc.Parent = keyFrame
local kfs = Instance.new("UIStroke"); kfs.Color = Color3.fromRGB(255, 80, 200); kfs.Thickness = 1; kfs.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, -20, 0, 18)
keyTitle.Position = UDim2.new(0, 10, 0, 6)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "Key System"
keyTitle.TextColor3 = Color3.fromRGB(255, 150, 220)
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 13
keyTitle.TextXAlignment = Enum.TextXAlignment.Left
keyTitle.Parent = keyFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -100, 0, 32)
keyInput.Position = UDim2.new(0, 10, 0, 30)
keyInput.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
keyInput.BorderSizePixel = 0
keyInput.PlaceholderText = "Ключ..."
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(240, 240, 245)
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 100, 150)
keyInput.Font = Enum.Font.Gotham
keyInput.TextSize = 14
keyInput.ClearTextOnFocus = false
keyInput.Parent = keyFrame
local kic = Instance.new("UICorner"); kic.CornerRadius = UDim.new(0, 6); kic.Parent = keyInput

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0, 80, 0, 32)
submitBtn.Position = UDim2.new(1, -90, 0, 30)
submitBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 200)
submitBtn.Text = "Войти"
submitBtn.TextColor3 = Color3.new(1,1,1)
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextSize = 13
submitBtn.AutoButtonColor = false
submitBtn.Parent = keyFrame
local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 6); sbc.Parent = submitBtn

local errorLabel = Instance.new("TextLabel")
errorLabel.Size = UDim2.new(1, -20, 0, 16)
errorLabel.Position = UDim2.new(0, 10, 0, 66)
errorLabel.BackgroundTransparency = 1
errorLabel.Text = ""
errorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
errorLabel.Font = Enum.Font.Gotham
errorLabel.TextSize = 11
errorLabel.TextXAlignment = Enum.TextXAlignment.Left
errorLabel.Parent = keyFrame

local buttonsCreated = false
local giveBtn, flingBtn

local function createButtons()
    if buttonsCreated then return end
    buttonsCreated = true

    giveBtn = Instance.new("TextButton")
    giveBtn.Size = UDim2.new(1, -24, 0, 46)
    giveBtn.Position = UDim2.new(0, 12, 0, 110)
    giveBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 120)
    giveBtn.Text = "Взять калашников"
    giveBtn.TextColor3 = Color3.new(1,1,1)
    giveBtn.Font = Enum.Font.GothamBold
    giveBtn.TextSize = 15
    giveBtn.AutoButtonColor = false
    giveBtn.Parent = body
    local gc = Instance.new("UICorner"); gc.CornerRadius = UDim.new(0, 8); gc.Parent = giveBtn

    flingBtn = Instance.new("TextButton")
    flingBtn.Size = UDim2.new(1, -24, 0, 46)
    flingBtn.Position = UDim2.new(0, 12, 0, 168)
    flingBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 180)
    flingBtn.Text = "Флинг ближайшего"
    flingBtn.TextColor3 = Color3.new(1,1,1)
    flingBtn.Font = Enum.Font.GothamBold
    flingBtn.TextSize = 15
    flingBtn.AutoButtonColor = false
    flingBtn.Parent = body
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 8); fc.Parent = flingBtn

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -24, 0, 40)
    hint.Position = UDim2.new(0, 12, 0, 226)
    hint.BackgroundTransparency = 1
    hint.Text = "АК в руки → ЛКМ/тап по игроку.\nФлинг уносит цель, ты остаёшься."
    hint.TextColor3 = Color3.fromRGB(170, 150, 210)
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Parent = body

    giveBtn.MouseButton1Click:Connect(giveAK)
    flingBtn.MouseButton1Click:Connect(function()
        local t = getNearestCharacter()
        if t then SkidFlingCharacter(t) end
    end)
end

submitBtn.MouseButton1Click:Connect(function()
    if keyInput.Text == VALID_KEY then
        errorLabel.Text = ""
        keyFrame:Destroy()
        createButtons()
    else
        errorLabel.Text = "Неверный ключ"
        keyInput.Text = ""
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 300, 0, 60) or UDim2.new(0, 300, 0, 300)
end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
       and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local char = LP.Character
    if not char then return end
    local ak = char:FindFirstChild("AK-47")
    if ak and ak:GetAttribute("Lokeii_AK") then shoot() end
end)

print("[Lokeii] menu created ok")
