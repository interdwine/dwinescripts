--// TEv1 - Auto Collect (WindUI Auto-Detect)
--// Author: Dwine

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Window
local Window = WindUI:CreateWindow({
    Title = "TEv1",
    Icon = "leaf",
    Author = "Dwine",
    Folder = "TEv1_Config",
    Size = UDim2.new(0, 300, 0, 200),
    Transparent = true,
    Theme = "Dark",
})

-- ════════════════════════════════
-- 🔍 AUTO-DETECT TAB METHOD
-- ════════════════════════════════

local function createTab(win, config)
    if win.CreateTab then
        return win:CreateTab(config)
    elseif win.Tab then
        return win:Tab(config)
    else
        warn("WindUI Tab method not found")
        return nil
    end
end

local AutoFarmTab = createTab(Window, {
    Title = "AutoFarm",
    Icon = "zap"
})

-- ════════════════════════════════
-- 🔍 AUTO-DETECT TOGGLE METHOD
-- ════════════════════════════════

local function createToggle(tab, config)
    if tab.CreateToggle then
        return tab:CreateToggle(config)
    elseif tab.Toggle then
        return tab:Toggle(config)
    else
        warn("WindUI Toggle method not found")
        return nil
    end
end

-- State
local collectEnabled = false
local COLLECT_INTERVAL = 1

if AutoFarmTab then
    createToggle(AutoFarmTab, {
        Title = "Auto Collect (100 Only)",
        Value = false,
        Callback = function(state)
            collectEnabled = state
        end
    })
end

-- ════════════════════════════════
-- GAME LOGIC (UNCHANGED CORE)
-- ════════════════════════════════

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local FARM_NAMES = {
    ["Apple Farm"] = true, ["Bakery"] = true, ["Bank"] = true,
    ["Bush Farm"] = true, ["Carrot Farm"] = true, ["Copper Mine"] = true,
    ["Diamond Mine"] = true, ["Fishing Pond"] = true, ["Flower Farm"] = true,
    ["Gold Mine"] = true, ["Market"] = true, ["Sheep Farm"] = true,
    ["Silver Mine"] = true, ["Smithy"] = true, ["Super Farm"] = true,
    ["Tomato Farm"] = true, ["Tree Farm"] = true, ["Wheat Farm"] = true,
}

local function getPlotCenter(plot)
    local part = plot:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position
end

local function findPlayerPlot()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local plots = workspace:WaitForChild("Plots")
    local closest, dist = nil, math.huge

    for _, plot in ipairs(plots:GetChildren()) do
        local center = getPlotCenter(plot)
        if center then
            local d = (root.Position - center).Magnitude
            if d < dist then
                dist = d
                closest = plot
            end
        end
    end

    if dist <= 500 then
        return closest
    end
end

local function isFarmFull(prompt)
    local txt = prompt.ObjectText or ""
    local nums = {}

    for n in txt:gmatch("%d+") do
        table.insert(nums, tonumber(n))
    end

    if #nums == 0 then return true end
    if #nums >= 2 then return nums[1] >= 100 end
    return nums[1] >= 100
end

local function collectAllFarms(plot)
    local folder = plot:FindFirstChild("Buildings")
    if not folder then return end

    for _, building in ipairs(folder:GetChildren()) do
        for farmName in pairs(FARM_NAMES) do
            if building.Name:find(farmName, 1, true) then
                local prompt = building:FindFirstChild("CollectPrompt", true)
                if prompt and prompt:IsA("ProximityPrompt") then
                    if isFarmFull(prompt) then
                        local old = prompt.MaxActivationDistance
                        prompt.MaxActivationDistance = 999999
                        fireproximityprompt(prompt)
                        task.defer(function()
                            prompt.MaxActivationDistance = old
                        end)
                        task.wait(0.05)
                    end
                end
                break
            end
        end
    end
end

-- Loop
task.spawn(function()
    while true do
        task.wait(COLLECT_INTERVAL)

        if collectEnabled then
            local plot = findPlayerPlot()
            if plot then
                pcall(collectAllFarms, plot)
            end
        end
    end
end)

-- ════════════════════════════════
-- 📱 MOBILE MINIMIZE BUTTON
-- ════════════════════════════════

local CoreGui = game:GetService("CoreGui")

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
toggleBtn.Text = "UI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Visible = false
toggleBtn.Parent = CoreGui

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)

-- Detect minimize safely (some versions don't support it)
if Window.SetMinimizedCallback then
    Window:SetMinimizedCallback(function(state)
        toggleBtn.Visible = state
    end)
end

toggleBtn.MouseButton1Click:Connect(function()
    if Window.Toggle then
        Window:Toggle()
    end
end)
