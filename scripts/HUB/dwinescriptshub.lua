local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Script map: [PlaceId] = { name, scripts = { {label, url} } }
local HUB = {
    [3678761576] = {
        name = "ENTRENCHED WW1",
        scripts = {
            { label = "FREE VERSION", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/ENTRENCHED/FREE.lua" },
        }
    },
}

local placeId = game.PlaceId
local gameData = HUB[placeId] or { name = "Game Not Supported #" .. placeId, scripts = {} }

-- Exact Design Colors
local COL_BG       = Color3.fromRGB(11, 12, 11)
local COL_SURFACE  = Color3.fromRGB(13, 15, 13)
local COL_BORDER   = Color3.fromRGB(28, 58, 28)
local COL_BRGREEN  = Color3.fromRGB(39, 174, 96)
local COL_DKGREEN  = Color3.fromRGB(26, 90, 26)

-- Helper: create instance
local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- ScreenGui
local screenGui = new("ScreenGui", { Name = "DwineHub", ResetOnSpawn = false }, playerGui)

-- --- THE EXECUTION LOGIC (WITH AUTO-CLOSE) ---
local function runScript(url, btn)
    local originalText = btn.Text
    btn.Text = "EXECUTING..."
    
    task.spawn(function()
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)

        if success then
            local loadedFunc, err = loadstring(result)
            if loadedFunc then
                local ran, runErr = pcall(loadedFunc)
                if ran then
                    btn.Text = "SUCCESS!"
                    task.wait(0.5) 
                    screenGui:Destroy() -- "Kills" the GUI after success
                else
                    btn.Text = "RUNTIME ERR"
                    warn("Script Error: " .. tostring(runErr))
                    task.wait(2)
                    btn.Text = originalText
                end
            else
                btn.Text = "LOADSTRING ERR"
                warn("Your executor does not support loadstring or the script is invalid.")
                task.wait(2)
                btn.Text = originalText
            end
        else
            btn.Text = "SCRIPT NOT FOUND"
            warn("Could not download script.")
            task.wait(2)
            btn.Text = originalText
        end
    end)
end

-- Main Window
local mainFrame = new("Frame", {
    Size = UDim2.new(0, 320, 0, 180),
    Position = UDim2.new(0.5, -160, 0.5, -90),
    BackgroundColor3 = COL_BG,
    BorderSizePixel = 0,
}, screenGui)

new("UICorner", { CornerRadius = UDim.new(0, 10) }, mainFrame)
new("UIStroke", { Color = COL_BORDER, Thickness = 1.5 }, mainFrame)

local layout = new("UIListLayout", { 
    SortOrder = Enum.SortOrder.LayoutOrder, 
    Padding = UDim.new(0, 0),
    HorizontalAlignment = Enum.HorizontalAlignment.Center 
}, mainFrame)

-- Title
local title = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40),
    Text = "DWINE'S SCRIPTS",
    TextColor3 = COL_DKGREEN,
    Font = Enum.Font.Code,
    TextSize = 14,
    BackgroundTransparency = 1,
    LayoutOrder = 0
}, mainFrame)

-- Detected Game Box
local gameBox = new("Frame", {
    Size = UDim2.new(0.9, 0, 0, 35),
    BackgroundColor3 = COL_SURFACE,
    BorderSizePixel = 0,
    LayoutOrder = 1
}, mainFrame)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, gameBox)
new("UIStroke", { Color = COL_BORDER, Thickness = 1, Transparency = 0.5 }, gameBox)

local pulseDot = new("Frame", {
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(0, 12, 0.5, -4),
    BackgroundColor3 = COL_BRGREEN,
    BorderSizePixel = 0
}, gameBox)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pulseDot)

new("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 30, 0, 0),
    Text = gameData.name,
    TextColor3 = COL_BRGREEN,
    Font = Enum.Font.Code,
    TextSize = 10,
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left
}, gameBox)

-- Dot Pulse Animation
task.spawn(function()
    while pulseDot and pulseDot.Parent do
        TweenService:Create(pulseDot, TweenInfo.new(0.8), { BackgroundTransparency = 0.7 }):Play()
        task.wait(0.8)
        TweenService:Create(pulseDot, TweenInfo.new(0.8), { BackgroundTransparency = 0 }):Play()
        task.wait(0.8)
    end
end)

-- Spacer
new("Frame", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, LayoutOrder = 2 }, mainFrame)

-- Execute Button
local selectedScript = gameData.scripts[1]
local execBtn = new("TextButton", {
    Size = UDim2.new(0.9, 0, 0, 45),
    BackgroundColor3 = COL_SURFACE,
    Text = "EXECUTE",
    TextColor3 = COL_BRGREEN,
    Font = Enum.Font.Code,
    TextSize = 12,
    AutoButtonColor = false,
    LayoutOrder = 3
}, mainFrame)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, execBtn)
new("UIStroke", { Color = COL_BORDER, Thickness = 1.2 }, execBtn)

execBtn.MouseButton1Click:Connect(function()
    if selectedScript then
        runScript(selectedScript.url, execBtn)
    else
        execBtn.Text = "NO SCRIPT FOUND"
        task.wait(1)
        execBtn.Text = "EXECUTE FREE"
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
