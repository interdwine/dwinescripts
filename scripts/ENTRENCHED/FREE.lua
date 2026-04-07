local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- STATES
local highlightEnabled = false
local aimAssistEnabled = false
local hitboxEnabled = false
local aimSmoothing = 0.2
local aimFOV = 150
local hitboxScale = 1.5

-- STORAGE
local originalSizes = {}

-- TEAM CHECK
local function isEnemy(plr)
    if not LocalPlayer.Team or not plr.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

-- HIGHLIGHT
local function applyHighlight(char)
    if char:FindFirstChild("MyHighlight") then return end
    local h = Instance.new("Highlight")
    h.Name = "MyHighlight"
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.Parent = char
end

local function removeHighlight(char)
    local h = char:FindFirstChild("MyHighlight")
    if h then h:Destroy() end
end

-- HITBOX EXPANDER
local ATTACH_NAME = "_ExpandedHitboxAttach"

local limbNames = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm",
    "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot",
    "Torso", "Left Arm", "Right Arm",
    "Left Leg", "Right Leg"
}

local function getAttachOffsets(scale)
    return {
        Vector3.new( scale,  scale,  scale),
        Vector3.new(-scale,  scale,  scale),
        Vector3.new( scale, -scale,  scale),
        Vector3.new(-scale, -scale,  scale),
        Vector3.new( scale,  scale, -scale),
        Vector3.new(-scale,  scale, -scale),
        Vector3.new( scale, -scale, -scale),
        Vector3.new(-scale, -scale, -scale),
        Vector3.new(     0,  scale * 1.6, 0),
        Vector3.new(     0, -scale * 1.6, 0),
    }
end

local function injectHitboxAttachments(char)
    local offsets = getAttachOffsets(hitboxScale * 0.5)
    for _, limbName in ipairs(limbNames) do
        local limb = char:FindFirstChild(limbName)
        if limb and limb:IsA("BasePart") then
            for _, child in ipairs(limb:GetChildren()) do
                if child.Name == ATTACH_NAME then child:Destroy() end
            end
            for _, offset in ipairs(offsets) do
                local att = Instance.new("Attachment")
                att.Name = ATTACH_NAME
                att.Position = offset
                att.Parent = limb
            end
        end
    end
end

local function removeHitboxAttachments(char)
    if not char then return end
    for _, limbName in ipairs(limbNames) do
        local limb = char:FindFirstChild(limbName)
        if limb then
            for _, child in ipairs(limb:GetChildren()) do
                if child.Name == ATTACH_NAME then child:Destroy() end
            end
        end
    end
end

local function expandPartHitboxes(char)
    for _, limbName in ipairs(limbNames) do
        local limb = char:FindFirstChild(limbName)
        if limb and limb:IsA("BasePart") then
            if not originalSizes[limb] then
                originalSizes[limb] = limb.Size
            end
            limb.Size = originalSizes[limb] * hitboxScale
        end
    end
end

local function resetPartHitboxes(char)
    if not char then return end
    for _, limbName in ipairs(limbNames) do
        local limb = char:FindFirstChild(limbName)
        if limb and limb:IsA("BasePart") then
            if originalSizes[limb] then
                limb.Size = originalSizes[limb]
            end
        end
    end
end

local function applyHitbox(char)
    if not char or not char.Parent then return end
    injectHitboxAttachments(char)
    expandPartHitboxes(char)
end

local function removeHitbox(char)
    if not char then return end
    removeHitboxAttachments(char)
    resetPartHitboxes(char)
end

-- WALL CHECK
local function isVisible(targetHead)
    local localChar = LocalPlayer.Character
    local origin = Camera.CFrame.Position
    local direction = targetHead.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {}
    if localChar then
        for _, part in ipairs(localChar:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(excluded, part) end
        end
    end
    local targetChar = targetHead.Parent
    if targetChar then
        for _, part in ipairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then table.insert(excluded, part) end
        end
    end
    rayParams.FilterDescendantsInstances = excluded
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

-- GET CLOSEST VISIBLE ENEMY WITHIN FOV
local function getClosestEnemy()
    local closest = nil
    local closestDist = math.huge
    local screenCenter = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isEnemy(plr) then
            local char = plr.Character
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < aimFOV and dist < closestDist then
                        if isVisible(head) then
                            closestDist = dist
                            closest = head
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- AIM ASSIST LOOP
RunService.RenderStepped:Connect(function(dt)
    if not aimAssistEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local target = getClosestEnemy()
    if not target then return end
    local aimPos = target.Position + Vector3.new(0, -0.1, 0)
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, aimPos)
    local smoothFactor = math.clamp(aimSmoothing * (dt * 60), 0, 1)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothFactor)
end)

-- UPDATE ALL PLAYERS
local function updatePlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isEnemy(plr) then
            local char = plr.Character
            if highlightEnabled then applyHighlight(char) else removeHighlight(char) end
            if hitboxEnabled then applyHitbox(char) else removeHitbox(char) end
        end
    end
end

-- DEATH HOOK
local function hookDeath(plr)
    if not plr.Character then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            task.wait(0.1)
            removeHitbox(plr.Character)
            removeHighlight(plr.Character)
        end)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        updatePlayers()
        hookDeath(plr)
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        hookDeath(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            updatePlayers()
            hookDeath(plr)
        end)
    end
end

-- ========================
-- GUI
-- ========================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local FULL_HEIGHT = 330

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 255, 0, FULL_HEIGHT)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- TITLE BAR
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ENTRENCHED WW1 by Dwine"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 26, 0, 20)
minimizeBtn.Position = UDim2.new(1, -58, 0, 6)
minimizeBtn.Text = "—"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.TextSize = 13
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 20)
closeBtn.Position = UDim2.new(1, -28, 0, 6)
closeBtn.Text = "✕"
closeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- CONTENT
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -32)
content.Position = UDim2.new(0, 0, 0, 32)
content.BackgroundTransparency = 1
content.Parent = frame

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    frame.Size = minimized
        and UDim2.new(0, 255, 0, 32)
        or  UDim2.new(0, 255, 0, FULL_HEIGHT)
    minimizeBtn.Text = minimized and "□" or "—"
end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- DRAG
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- WIDGET FACTORIES
local buttonY = 8

local function createToggleButton(label, getter, setter)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 36)
    btn.Position = UDim2.new(0, 6, 0, buttonY)
    btn.BackgroundColor3 = Color3.fromRGB(55,55,55)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function refresh()
        local on = getter()
        btn.Text = label .. ":  " .. (on and "✔ ON" or "✘ OFF")
        btn.BackgroundColor3 = on
            and Color3.fromRGB(45,110,45)
            or  Color3.fromRGB(55,55,55)
    end

    btn.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
        updatePlayers()
    end)

    refresh()
    buttonY = buttonY + 44
end

local function createSlider(label, min, max, default, decimals, onChange)
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, -12, 0, 52)
    sf.Position = UDim2.new(0, 6, 0, buttonY)
    sf.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    sf.BorderSizePixel = 0
    sf.Parent = content
    Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.Position = UDim2.new(0, 8, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = sf

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 8)
    track.Position = UDim2.new(0, 8, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(60,60,60)
    track.BorderSizePixel = 0
    track.Parent = sf
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(75,150,75)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((default - min)/(max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local val = default
    local fmt = "%." .. decimals .. "f"
    local function updateLbl()
        lbl.Text = label .. ": " .. string.format(fmt, val)
    end
    updateLbl()

    local sliding = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp(
                (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                0, 1
            )
            val = min + (max - min) * rel
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            updateLbl()
            onChange(val)
        end
    end)

    buttonY = buttonY + 60
end

-- BUILD UI
createToggleButton("Highlight",
    function() return highlightEnabled end,
    function(v) highlightEnabled = v end)

createToggleButton("Expand Hitbox",
    function() return hitboxEnabled end,
    function(v) hitboxEnabled = v end)

createToggleButton("Aim Assist (Hold RMB)",
    function() return aimAssistEnabled end,
    function(v) aimAssistEnabled = v end)

createSlider("Hitbox Scale", 1.0, 5.0, hitboxScale, 1, function(v)
    hitboxScale = v
    if hitboxEnabled then updatePlayers() end
end)

createSlider("Aim Smooth", 0.01, 1.0, aimSmoothing, 2, function(v)
    aimSmoothing = v
end)

createSlider("FOV Radius", 50, 500, aimFOV, 0, function(v)
    aimFOV = v
end)

updatePlayers()
