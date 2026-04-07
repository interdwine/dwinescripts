local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- STATE
local ESP_ENABLED = false
local CRATE_ESP_ENABLED = false
local STRUCT_ESP_ENABLED = false
local SPEED_ENABLED = false
local SPEED_MULT = 1
local DEFAULT_SPEED = 16
local AIM_ENABLED = false
local INF_JUMP_ENABLED = false
local TP_ENABLED = false
local HITBOX_ENABLED = false
local HITBOX_SIZE = 5
local IS_MINIMIZED = false

-- COLORS
local COL_BG = Color3.fromRGB(0,0,0)
local COL_SURFACE = Color3.fromRGB(15,15,15)
local COL_ACCENT = Color3.fromRGB(0,255,100)
local COL_ORANGE = Color3.fromRGB(255,140,0)

-- HELPER
local function new(class, props, parent)
    local obj = Instance.new(class)
    if class:match("Text") then
        obj.Font = Enum.Font.Arcade
    end
    for k,v in pairs(props) do obj[k]=v end
    if parent then obj.Parent = parent end
    return obj
end

-- ================= TEAM CHECK =================
local function isEnemy(target)
    local myChar = player.Character
    if not myChar then return false end
    if target == myChar then return false end

    local function onSameTeam(a, b)
        if a:GetAttribute("Zombie") and b:GetAttribute("Zombie") then return true end
        if a:GetAttribute("Bandit") and b:GetAttribute("Bandit") then return true end
        if a:GetAttribute("Player") and b:GetAttribute("Player") then return true end
        return a == b
    end

    return not onSameTeam(myChar, target)
end

-- ================= ESP =================
local activeHighlights = {}

local function clearESP()
    for _, hl in pairs(activeHighlights) do
        if hl then hl:Destroy() end
    end
    activeHighlights = {}
end

local function applyCham(obj, color)
    if not obj or activeHighlights[obj] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
    hl.Parent = obj
    activeHighlights[obj] = hl
end

local function removeESPFor(obj)
    if activeHighlights[obj] then
        activeHighlights[obj]:Destroy()
        activeHighlights[obj] = nil
    end
end

RunService.RenderStepped:Connect(function()
    -- Player ESP (red)
    if ESP_ENABLED then
        local chars = workspace:FindFirstChild("Characters")
        if chars then
            for _, obj in pairs(chars:GetChildren()) do
                if obj ~= player.Character then
                    applyCham(obj, Color3.fromRGB(255,0,0))
                end
            end
        end
    end

    -- Crate ESP (orange)
    if CRATE_ESP_ENABLED then
        local crateFolder = workspace:FindFirstChild("Map")
        crateFolder = crateFolder and crateFolder:FindFirstChild("Assets")
        crateFolder = crateFolder and crateFolder:FindFirstChild("Crates")
        crateFolder = crateFolder and crateFolder:FindFirstChild("Default")
        if crateFolder then
            for _, obj in pairs(crateFolder:GetChildren()) do
                applyCham(obj, COL_ORANGE)
            end
        end
    end

    -- Structure ESP (orange)
    if STRUCT_ESP_ENABLED then
        local structs = workspace:FindFirstChild("Structures")
        if structs then
            for _, obj in pairs(structs:GetChildren()) do
                applyCham(obj, COL_ORANGE)
            end
        end
    end

    -- Dropped items ESP (blue)
    local drops = workspace:FindFirstChild("DroppedItems")
    if drops and ESP_ENABLED then
        for _, obj in pairs(drops:GetChildren()) do
            applyCham(obj, Color3.fromRGB(0,170,255))
        end
    end
end)

-- ================= HITBOX EXPANDER =================
local expandedParts = {}

local function expandHitboxes()
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end

    for _, char in pairs(chars:GetChildren()) do
        if char ~= player.Character and isEnemy(char) then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and not expandedParts[part] then
                    expandedParts[part] = part.Size
                    part.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
                    part.Transparency = 0.85
                end
            end
        end
    end
end

local function restoreHitboxes()
    for part, origSize in pairs(expandedParts) do
        if part and part.Parent then
            part.Size = origSize
            part.Transparency = part.Transparency
        end
    end
    expandedParts = {}
end

RunService.RenderStepped:Connect(function()
    if not HITBOX_ENABLED then return end
    expandHitboxes()
end)

-- ================= SPEED =================
RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = SPEED_ENABLED and (DEFAULT_SPEED * SPEED_MULT) or DEFAULT_SPEED
end)

-- ================= INF JUMP =================
local jumpConn
local function enableInfJump()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    jumpConn = UserInputService.JumpRequest:Connect(function()
        if INF_JUMP_ENABLED and hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

player.CharacterAdded:Connect(function()
    if INF_JUMP_ENABLED then enableInfJump() end
end)

-- ================= GUN CHECK =================
local function isHoldingGun()
    local char = player.Character
    if not char then return false end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("gun") or name:find("rifle") or name:find("pistol") then
                return true
            end
        end
    end
    return false
end

-- ================= AIM HELPER (HEAD TARGET) =================
local function getNearestHead()
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return nil end
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    for _, obj in pairs(chars:GetChildren()) do
        if obj ~= myChar then
            local head = obj:FindFirstChild("Head")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local dist = (head.Position - myRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not AIM_ENABLED then return end
    if not isHoldingGun() then return end
    local head = getNearestHead()
    if not head then return end
    camera.CFrame = camera.CFrame:Lerp(
        CFrame.new(camera.CFrame.Position, head.Position),
        0.15
    )
end)

-- ================= AUTO WALK TO CRATE =================
local NEAR_DISTANCE = 50

local function getNearestCrate()
    local crateFolder = workspace:FindFirstChild("Map")
    crateFolder = crateFolder and crateFolder:FindFirstChild("Assets")
    crateFolder = crateFolder and crateFolder:FindFirstChild("Crates")
    crateFolder = crateFolder and crateFolder:FindFirstChild("Default")
    if not crateFolder then return nil end

    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, closestDist = nil, math.huge
    for _, crate in pairs(crateFolder:GetChildren()) do
        local pos
        if crate:IsA("BasePart") then
            pos = crate.Position
        elseif crate:IsA("Model") then
            local prim = crate.PrimaryPart or crate:FindFirstChildOfClass("BasePart")
            if prim then pos = prim.Position end
        end
        if pos then
            local dist = (pos - myRoot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = {instance = crate, position = pos, distance = dist}
            end
        end
    end
    return closest
end

local function getFogCrate()
    local fog = workspace:FindFirstChild("Fog")
    if not fog then return nil end
    for _, obj in pairs(fog:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then return obj end
    end
    return nil
end

RunService.RenderStepped:Connect(function()
    if not TP_ENABLED then return end
    local myChar = player.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not hum then return end

    local nearest = getNearestCrate()
    if nearest then
        if nearest.distance <= NEAR_DISTANCE then
            hum.WalkSpeed = DEFAULT_SPEED * 3
            hum:MoveTo(nearest.position)
        else
            local fogCrate = getFogCrate()
            if fogCrate then
                local fogPos
                if fogCrate:IsA("BasePart") then
                    fogPos = fogCrate.Position
                elseif fogCrate:IsA("Model") then
                    local prim = fogCrate.PrimaryPart or fogCrate:FindFirstChildOfClass("BasePart")
                    if prim then fogPos = prim.Position end
                end
                if fogPos then
                    hum.WalkSpeed = DEFAULT_SPEED * 3
                    hum:MoveTo(fogPos)
                end
            end
        end
    else
        if not SPEED_ENABLED then hum.WalkSpeed = DEFAULT_SPEED end
    end
end)

-- ================= REMOVE CUTSCENE =================
local function removeCutscene()
    local names = {"Cutscene","CutScene","cutscene","CutsceneFolder","Cinematic","BlackBars"}
    for _, name in pairs(names) do
        local obj = workspace:FindFirstChild(name)
        if obj then obj:Destroy() end
        local guiObj = playerGui:FindFirstChild(name)
        if guiObj then guiObj:Destroy() end
    end
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("LocalScript") or obj:IsA("Script") then
            local n = obj.Name:lower()
            if n:find("cutscene") or n:find("cinematic") then
                obj:Destroy()
            end
        end
    end
    camera.CameraType = Enum.CameraType.Custom
end

-- ================= UI =================
local gui = new("ScreenGui",{ResetOnSpawn=false},playerGui)

local main = new("Frame",{
    Size=UDim2.new(0,340,0,380),
    Position=UDim2.new(0.5,-170,0.5,-190),
    BackgroundColor3=COL_BG
},gui)

local header = new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=COL_SURFACE},main)

new("TextLabel",{
    Size=UDim2.new(1,0,1,0),
    Text="STA by Dwine",
    TextColor3=COL_ACCENT,
    BackgroundTransparency=1
},header)

local minBtn = new("TextButton",{
    Size=UDim2.new(0,30,1,0),
    Position=UDim2.new(1,-30,0,0),
    Text="-",
    BackgroundColor3=COL_BG,
    TextColor3=COL_ACCENT
},header)

local content = new("Frame",{
    Size=UDim2.new(1,0,1,-30),
    Position=UDim2.new(0,0,0,30),
    BackgroundTransparency=1
},main)

minBtn.MouseButton1Click:Connect(function()
    IS_MINIMIZED = not IS_MINIMIZED
    content.Visible = not IS_MINIMIZED
    main.Size = IS_MINIMIZED and UDim2.new(0,340,0,30) or UDim2.new(0,340,0,380)
end)

-- TABS (4 tabs) - SMALLER TEXT
local tabs = new("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},content)

local pages = {
    Players = new("Frame",{Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,24),BackgroundTransparency=1},content),
    Tools   = new("Frame",{Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,24),BackgroundTransparency=1,Visible=false},content),
    TP      = new("Frame",{Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,24),BackgroundTransparency=1,Visible=false},content),
    Misc    = new("Frame",{Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,24),BackgroundTransparency=1,Visible=false},content),
}

local function switch(tab)
    for k,v in pairs(pages) do v.Visible = (k==tab) end
end

local function makeTab(name, xScale)
    local b = new("TextButton",{
        Size=UDim2.new(0.25,0,1,0),
        Position=UDim2.new(xScale,0,0,0),
        Text=name,
        BackgroundColor3=COL_SURFACE,
        TextColor3=COL_ACCENT,
        TextSize=11, -- SMALLER TEXT SIZE
        TextScaled=false
    },tabs)
    b.MouseButton1Click:Connect(function() switch(name) end)
end

makeTab("Players", 0)
makeTab("Tools",   0.25)
makeTab("TP",      0.5)
makeTab("Misc",    0.75)

-- ===================== PLAYERS PAGE =====================
local espBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,5),
    Text="PLAYER ESP: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Players)
espBtn.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    espBtn.Text = "PLAYER ESP: "..(ESP_ENABLED and "ON" or "OFF")
    if not ESP_ENABLED then clearESP() end
end)

-- Crate ESP button (MOVED TO PLAYERS TAB)
local crateEspBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,38),
    Text="CRATE ESP: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ORANGE
},pages.Players)
crateEspBtn.MouseButton1Click:Connect(function()
    CRATE_ESP_ENABLED = not CRATE_ESP_ENABLED
    crateEspBtn.Text = "CRATE ESP: "..(CRATE_ESP_ENABLED and "ON" or "OFF")
    if not CRATE_ESP_ENABLED then clearESP() end
end)

-- Structure ESP button (MOVED TO PLAYERS TAB)
local structEspBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,71),
    Text="STRUCT ESP: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ORANGE
},pages.Players)
structEspBtn.MouseButton1Click:Connect(function()
    STRUCT_ESP_ENABLED = not STRUCT_ESP_ENABLED
    structEspBtn.Text = "STRUCT ESP: "..(STRUCT_ESP_ENABLED and "ON" or "OFF")
    if not STRUCT_ESP_ENABLED then clearESP() end
end)

local speedBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,104),
    Text="SPEED: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Players)
speedBtn.MouseButton1Click:Connect(function()
    SPEED_ENABLED = not SPEED_ENABLED
    speedBtn.Text = "SPEED: "..(SPEED_ENABLED and "ON" or "OFF")
end)

-- Speed slider
local slider = new("TextButton",{
    Size=UDim2.new(0.9,0,0,18),
    Position=UDim2.new(0.05,0,0,136),
    BackgroundColor3=COL_SURFACE,
    Text=""
},pages.Players)
local fill = new("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=COL_ACCENT},slider)
local dragging = false
local function updateSlider(input)
    local ratio = math.clamp((input.Position.X - slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
    fill.Size = UDim2.new(ratio,0,1,0)
    SPEED_MULT = 1 + math.floor(ratio*9)
end
slider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true updateSlider(i) end end)

local infJumpBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,159),
    Text="INF JUMP: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Players)
infJumpBtn.MouseButton1Click:Connect(function()
    INF_JUMP_ENABLED = not INF_JUMP_ENABLED
    infJumpBtn.Text = "INF JUMP: "..(INF_JUMP_ENABLED and "ON" or "OFF")
    if INF_JUMP_ENABLED then
        enableInfJump()
    else
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    end
end)

local hitboxBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,192),
    Text="HITBOX EXPAND: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Players)
hitboxBtn.MouseButton1Click:Connect(function()
    HITBOX_ENABLED = not HITBOX_ENABLED
    hitboxBtn.Text = "HITBOX EXPAND: "..(HITBOX_ENABLED and "ON" or "OFF")
    if not HITBOX_ENABLED then restoreHitboxes() end
end)

-- Hitbox size slider
new("TextLabel",{
    Size=UDim2.new(0.9,0,0,16),
    Position=UDim2.new(0.05,0,0,224),
    Text="Hitbox Size: 5",
    TextColor3=COL_ACCENT,
    BackgroundTransparency=1,
    TextScaled=true,
    Name="HitboxLabel"
},pages.Players)
local hitboxLabel = pages.Players:FindFirstChild("HitboxLabel")

local hbSlider = new("TextButton",{
    Size=UDim2.new(0.9,0,0,18),
    Position=UDim2.new(0.05,0,0,243),
    BackgroundColor3=COL_SURFACE,
    Text=""
},pages.Players)
local hbFill = new("Frame",{Size=UDim2.new(0.1,0,1,0),BackgroundColor3=COL_ACCENT},hbSlider)
local hbDrag = false
local function updateHbSlider(input)
    local ratio = math.clamp((input.Position.X - hbSlider.AbsolutePosition.X)/hbSlider.AbsoluteSize.X,0,1)
    hbFill.Size = UDim2.new(ratio,0,1,0)
    HITBOX_SIZE = 2 + math.floor(ratio * 28)
    if hitboxLabel then hitboxLabel.Text = "Hitbox Size: "..HITBOX_SIZE end
    if HITBOX_ENABLED then restoreHitboxes() end
end
hbSlider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hbDrag=true updateHbSlider(i) end end)

-- ===================== TOOLS PAGE =====================
local aimBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,5),
    Text="AIM HELPER: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Tools)
aimBtn.MouseButton1Click:Connect(function()
    AIM_ENABLED = not AIM_ENABLED
    aimBtn.Text = "AIM HELPER: "..(AIM_ENABLED and "ON" or "OFF")
end)

-- ===================== TP PAGE =====================
new("TextLabel",{
    Size=UDim2.new(0.9,0,0,18),
    Position=UDim2.new(0.05,0,0,5),
    Text="Auto Walk to Crates",
    TextColor3=COL_ACCENT,
    BackgroundTransparency=1,
    TextScaled=true
},pages.TP)

local tpBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,26),
    Text="CRATE WALKER: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.TP)
tpBtn.MouseButton1Click:Connect(function()
    TP_ENABLED = not TP_ENABLED
    tpBtn.Text = "CRATE WALKER: "..(TP_ENABLED and "ON" or "OFF")
    if not TP_ENABLED then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and not SPEED_ENABLED then hum.WalkSpeed = DEFAULT_SPEED end
        end
    end
end)

-- Near distance label + slider
new("TextLabel",{
    Size=UDim2.new(0.9,0,0,16),
    Position=UDim2.new(0.05,0,0,59),
    Text="Near Dist: 50 studs",
    TextColor3=COL_ACCENT,
    BackgroundTransparency=1,
    TextScaled=true,
    Name="DistLabel"
},pages.TP)
local distLabel = pages.TP:FindFirstChild("DistLabel")

local distSlider = new("TextButton",{
    Size=UDim2.new(0.9,0,0,18),
    Position=UDim2.new(0.05,0,0,78),
    BackgroundColor3=COL_SURFACE,
    Text=""
},pages.TP)
local distFill = new("Frame",{Size=UDim2.new(0.25,0,1,0),BackgroundColor3=COL_ACCENT},distSlider)
local distDragging = false
local function updateDistSlider(input)
    local ratio = math.clamp((input.Position.X - distSlider.AbsolutePosition.X)/distSlider.AbsoluteSize.X,0,1)
    distFill.Size = UDim2.new(ratio,0,1,0)
    NEAR_DISTANCE = math.floor(ratio * 200) + 10
    if distLabel then distLabel.Text = "Near Dist: "..NEAR_DISTANCE.." studs" end
end
distSlider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then distDragging=true updateDistSlider(i) end end)

-- ===================== MISC PAGE =====================
new("TextLabel",{
    Size=UDim2.new(0.9,0,0,18),
    Position=UDim2.new(0.05,0,0,5),
    Text="Miscellaneous",
    TextColor3=COL_ACCENT,
    BackgroundTransparency=1,
    TextScaled=true
},pages.Misc)

local cutsceneBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,26),
    Text="REMOVE CUTSCENE",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Misc)
cutsceneBtn.MouseButton1Click:Connect(function()
    removeCutscene()
    cutsceneBtn.Text = "CUTSCENE REMOVED!"
    task.delay(2, function()
        cutsceneBtn.Text = "REMOVE CUTSCENE"
    end)
end)

-- Auto-remove cutscene toggle
local autoCutsceneEnabled = false
local autoCutsceneBtn = new("TextButton",{
    Size=UDim2.new(0.9,0,0,28),
    Position=UDim2.new(0.05,0,0,59),
    Text="AUTO SKIP: OFF",
    BackgroundColor3=COL_SURFACE,
    TextColor3=COL_ACCENT
},pages.Misc)
autoCutsceneBtn.MouseButton1Click:Connect(function()
    autoCutsceneEnabled = not autoCutsceneEnabled
    autoCutsceneBtn.Text = "AUTO SKIP: "..(autoCutsceneEnabled and "ON" or "OFF")
end)

workspace.ChildAdded:Connect(function(child)
    if not autoCutsceneEnabled then return end
    local n = child.Name:lower()
    if n:find("cutscene") or n:find("cinematic") or n:find("blackbar") then
        child:Destroy()
        camera.CameraType = Enum.CameraType.Custom
    end
end)

-- ================= GLOBAL INPUT HANDLERS =================
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then updateSlider(input) end
        if hbDrag then updateHbSlider(input) end
        if distDragging then updateDistSlider(input) end
        if draggingUI then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        hbDrag = false
        distDragging = false
        draggingUI = false
    end
end)

-- ================= DRAG =================
local draggingUI = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingUI = true
        dragStart = input.Position
        startPos = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingUI = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
