local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Script map: [PlaceId] = { name, scripts = { {label, url} } }
local HUB = {
    [3678761576] = {
        name = "ENTRECHED WW1",
        scripts = {
            { label = "FREE",  url = "https://raw.githubusercontent.com/interdwine/dbscript/refs/heads/main/ENT.lua" },
        }
    },
    [606849621] = {
        name = "SOON",
        scripts = {
            { label = "Fruit ESP",  url = "https://raw.githubusercontent.com/YourRepo/scripts/main/bloxfruits_esp.lua" },
        }
    },
    [2788229376] = {
        name = "SOON",
        scripts = {
            { label = "Auto Hatch", url = "https://raw.githubusercontent.com/YourRepo/scripts/main/petsimx_hatch.lua" },
        }
    },
}

local placeId = game.PlaceId
local gameData = HUB[placeId] or { name = "Unknown Game #" .. placeId, scripts = {} }

-- Colors
local BG       = Color3.fromRGB(8, 8, 8)
local SURFACE  = Color3.fromRGB(11, 11, 11)
local BORDER   = Color3.fromRGB(28, 58, 28)
local GREEN    = Color3.fromRGB(39, 174, 96)
local DKGREEN  = Color3.fromRGB(26, 90, 26)
local DKGREEN2 = Color3.fromRGB(20, 42, 20)
local WHITE    = Color3.fromRGB(255, 255, 255)

-- Helper: create instance
local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- Helper: load & execute script from URL
local function execScript(url, statusLabel)
    statusLabel.Text = "Injecting..."
    task.spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and result then
            local ok2, err = pcall(loadstring(result))
            if ok2 then
                statusLabel.Text = "Injected successfully"
            else
                statusLabel.Text = "Runtime error"
                warn("[Dwine] Runtime error:", err)
            end
        else
            statusLabel.Text = "Failed to fetch"
            warn("[Dwine] Fetch failed:", result)
        end
    end)
end

-- Build GUI
local screenGui = new("ScreenGui", {
    Name = "DwineHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- Main frame
local mainFrame = new("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 280, 0, 0), -- height auto via layout
    Position = UDim2.new(0.5, -140, 0.5, -160),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, screenGui)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, mainFrame)
new("UIStroke", { Color = BORDER, Thickness = 1 }, mainFrame)

-- Drag logic
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Layout
local layout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 0),
}, mainFrame)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    mainFrame.Size = UDim2.new(0, 280, 0, layout.AbsoluteContentSize.Y)
end)

-- Title bar
local titleBar = new("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = SURFACE,
    BorderSizePixel = 0,
    LayoutOrder = 0,
}, mainFrame)
new("UIStroke", { Color = BORDER, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, titleBar)

new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "DWINE'S SCRIPTS (FREE",
    TextColor3 = GREEN,
    Font = Enum.Font.Code,
    TextSize = 11,
    LetterSpacing = 3,
    TextXAlignment = Enum.TextXAlignment.Center,
}, titleBar)

-- Close button
local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -28, 0.5, -12),
    BackgroundTransparency = 1,
    Text = "×",
    TextColor3 = DKGREEN,
    Font = Enum.Font.Code,
    TextSize = 16,
}, titleBar)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Body padding frame
local body = new("Frame", {
    Name = "Body",
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    LayoutOrder = 1,
}, mainFrame)
new("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
}, body)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, body)

-- Section label helper
local function sectionLabel(text, order, parent)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = DKGREEN,
        Font = Enum.Font.Code,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
    }, parent)
    return lbl
end

-- Detected game box
sectionLabel("DETECTED GAME", 0, body)

local gameBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = SURFACE,
    BorderSizePixel = 0,
    LayoutOrder = 1,
}, body)
new("UICorner", { CornerRadius = UDim.new(0, 4) }, gameBox)
new("UIStroke", { Color = BORDER, Thickness = 1 }, gameBox)

-- Pulse dot
local pulseDot = new("Frame", {
    Size = UDim2.new(0, 7, 0, 7),
    Position = UDim2.new(0, 9, 0.5, -3),
    BackgroundColor3 = GREEN,
    BorderSizePixel = 0,
}, gameBox)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pulseDot)

-- Pulse tween
task.spawn(function()
    while pulseDot and pulseDot.Parent do
        TweenService:Create(pulseDot, TweenInfo.new(0.7), { BackgroundTransparency = 0.75 }):Play()
        task.wait(0.7)
        TweenService:Create(pulseDot, TweenInfo.new(0.7), { BackgroundTransparency = 0 }):Play()
        task.wait(0.7)
    end
end)

new("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1,
    Text = gameData.name,
    TextColor3 = GREEN,
    Font = Enum.Font.Code,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, gameBox)

new("TextLabel", {
    Size = UDim2.new(0, 70, 1, 0),
    Position = UDim2.new(1, -74, 0, 0),
    BackgroundTransparency = 1,
    Text = "#" .. placeId,
    TextColor3 = DKGREEN,
    Font = Enum.Font.Code,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Right,
}, gameBox)

-- Scripts label
sectionLabel("SCRIPTS", 2, body)

-- Script buttons
local selectedScript = nil
local statusLabel

for i, s in ipairs(gameData.scripts) do
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = SURFACE,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 2 + i,
    }, body)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    local stroke = new("UIStroke", { Color = DKGREEN2, Thickness = 1 }, btn)

    new("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        BackgroundTransparency = 1,
        Text = s.label,
        TextColor3 = GREEN,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)

    local tag = new("TextLabel", {
        Size = UDim2.new(0, 34, 0, 16),
        Position = UDim2.new(1, -42, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(11, 30, 11),
        BorderSizePixel = 0,
        Text = "FREE",
        TextColor3 = DKGREEN,
        Font = Enum.Font.Code,
        TextSize = 8,
    }, btn)
    new("UICorner", { CornerRadius = UDim.new(0, 3) }, tag)
    new("UIStroke", { Color = BORDER, Thickness = 1 }, tag)

    btn.MouseButton1Click:Connect(function()
        -- deselect all
        for _, c in ipairs(body:GetChildren()) do
            if c:IsA("TextButton") then
                local st = c:FindFirstChildOfClass("UIStroke")
                if st then st.Color = DKGREEN2 end
                c.BackgroundColor3 = SURFACE
            end
        end
        stroke.Color = GREEN
        btn.BackgroundColor3 = Color3.fromRGB(14, 22, 14)
        selectedScript = s
        if statusLabel then statusLabel.Text = "Selected: " .. s.label end
    end)
end

-- Divider
local divider = new("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = DKGREEN2,
    BorderSizePixel = 0,
    LayoutOrder = 20,
}, body)

-- Execute button
local execBtn = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = SURFACE,
    BorderSizePixel = 0,
    Text = "EXECUTE SCRIPT",
    TextColor3 = GREEN,
    Font = Enum.Font.Code,
    TextSize = 9,
    LetterSpacing = 2,
    AutoButtonColor = false,
    LayoutOrder = 21,
}, body)
new("UICorner", { CornerRadius = UDim.new(0, 5) }, execBtn)
new("UIStroke", { Color = GREEN, Thickness = 1 }, execBtn)

execBtn.MouseEnter:Connect(function()
    execBtn.BackgroundColor3 = Color3.fromRGB(16, 32, 16)
end)
execBtn.MouseLeave:Connect(function()
    execBtn.BackgroundColor3 = SURFACE
end)

-- Status bar
local statusFrame = new("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundColor3 = SURFACE,
    BorderSizePixel = 0,
    LayoutOrder = 22,
}, body)
new("UIStroke", { Color = DKGREEN2, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, statusFrame)

statusLabel = new("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Idle",
    TextColor3 = DKGREEN,
    Font = Enum.Font.Code,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
}, statusFrame)

new("TextLabel", {
    Size = UDim2.new(0, 36, 1, 0),
    Position = UDim2.new(1, -38, 0, 0),
    BackgroundTransparency = 1,
    Text = "v2.4",
    TextColor3 = Color3.fromRGB(20, 42, 20),
    Font = Enum.Font.Code,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Right,
}, statusFrame)

-- Execute logic
execBtn.MouseButton1Click:Connect(function()
    if not selectedScript then
        statusLabel.Text = "No script selected"
        return
    end
    execScript(selectedScript.url, statusLabel)
end)

print("[Dwine] Hub loaded | Game:", gameData.name, "| PlaceId:", placeId)
