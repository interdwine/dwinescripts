local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Script map
local HUB = {
    [3678761576] = {
        name = "ENTRENCHED WW1",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/ENTRENCHED/FREE.lua" },
        }
        
    [90148635862803] = {
        name = "SURVIVE THE APOCALYPSE",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/SURVIVE%20THE%20APOCALYPSE/STAFREE.lua" },
        }
    [9140270923132362] = {
        name = "TINY EMPIRES",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/TINY%20EMPIRES/TE.lua" },
        }
    },
}

local placeId = game.PlaceId
local isSupported = HUB[placeId] ~= nil
local gameData = HUB[placeId] or { name = "Game Not Supported", scripts = {} }

-- Colors
local COL_AMOLED   = Color3.fromRGB(0, 0, 0)
local COL_SURFACE  = Color3.fromRGB(10, 10, 10)
local COL_BORDER   = Color3.fromRGB(28, 58, 28)
local COL_NEON     = Color3.fromRGB(57, 255, 20) -- Neon Green
local COL_RED      = Color3.fromRGB(180, 50, 50)

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local screenGui = new("ScreenGui", { Name = "DwineHub", ResetOnSpawn = false }, playerGui)

-- Execution Logic
local function runScript(url, btn)
    local originalText = btn.Text
    btn.Text = "EXECUTING..."
    task.spawn(function()
        local success, result = pcall(function() return game:HttpGet(url) end)
        if success then
            local loadedFunc = loadstring(result)
            if loadedFunc then
                local ran, runErr = pcall(loadedFunc)
                if ran then
                    btn.Text = "SUCCESS!"
                    task.wait(0.5) 
                    screenGui:Destroy() 
                else
                    btn.Text = "RUNTIME ERR"
                    task.wait(2)
                    btn.Text = originalText
                end
            else
                btn.Text = "LOADSTRING ERR"
                task.wait(2)
                btn.Text = originalText
            end
        else
            btn.Text = "SCRIPT NOT FOUND"
            task.wait(2)
            btn.Text = originalText
        end
    end)
end

-- Main Window (Box style)
local mainFrame = new("Frame", {
    Size = UDim2.new(0, 320, 0, 180),
    Position = UDim2.new(0.5, -160, 0.5, -90),
    BackgroundColor3 = COL_AMOLED,
    BorderSizePixel = 0,
}, screenGui)

new("UIStroke", { Color = COL_BORDER, Thickness = 1.5 }, mainFrame)

local layout = new("UIListLayout", { 
    SortOrder = Enum.SortOrder.LayoutOrder, 
    Padding = UDim.new(0, 0),
    HorizontalAlignment = Enum.HorizontalAlignment.Center 
}, mainFrame)

-- Title (Minecraft Style)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 45),
    Text = "DWINE'S SCRIPTS",
    TextColor3 = COL_NEON,
    Font = Enum.Font.Arcade, -- Pixelated/Minecraft style
    TextSize = 16,
    BackgroundTransparency = 1,
}, mainFrame)

-- Detected Game Box
local gameBox = new("Frame", {
    Size = UDim2.new(0.9, 0, 0, 35),
    BackgroundColor3 = COL_SURFACE,
    BorderSizePixel = 0,
}, mainFrame)
new("UIStroke", { Color = COL_BORDER, Thickness = 1, Transparency = 0.5 }, gameBox)

if isSupported then
    local pulseDot = new("Frame", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 12, 0.5, -4),
        BackgroundColor3 = COL_NEON,
        BorderSizePixel = 0
    }, gameBox)
    task.spawn(function()
        while pulseDot and pulseDot.Parent do
            TweenService:Create(pulseDot, TweenInfo.new(0.8), { BackgroundTransparency = 0.7 }):Play()
            task.wait(0.8)
            TweenService:Create(pulseDot, TweenInfo.new(0.8), { BackgroundTransparency = 0 }):Play()
            task.wait(0.8)
        end
    end)
else
    new("TextLabel", {
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 12, 0.5, -4),
        Text = "X",
        TextColor3 = COL_RED,
        Font = Enum.Font.Arcade,
        TextSize = 14,
        BackgroundTransparency = 1,
    }, gameBox)
end

new("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 30, 0, 0),
    Text = gameData.name,
    TextColor3 = isSupported and COL_NEON or COL_RED,
    Font = Enum.Font.Arcade,
    TextSize = 12,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
}, gameBox)

-- Spacer
new("Frame", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1 }, mainFrame)

-- Execute Button (Minecraft Style + Blue highlight fix)
local selectedScript = gameData.scripts[1]
local execBtn = new("TextButton", {
    Size = UDim2.new(0.9, 0, 0, 40),
    BackgroundColor3 = COL_SURFACE,
    Text = "EXECUTE",
    TextColor3 = isSupported and COL_NEON or COL_BORDER,
    Font = Enum.Font.Arcade,
    TextSize = 12, 
    AutoButtonColor = false,
    SelectionImageObject = new("Frame", { BackgroundTransparency = 1 }), -- Fixes blue highlight
}, mainFrame)

new("UIStroke", { 
    Color = COL_BORDER, 
    Thickness = 1.2,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
}, execBtn)

execBtn.MouseButton1Click:Connect(function()
    if isSupported and selectedScript then
        runScript(selectedScript.url, execBtn)
    else
        execBtn.Text = "UNSUPPORTED"
        task.wait(1)
        execBtn.Text = "EXECUTE"
    end
end)

-- Dragging Logic
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
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
