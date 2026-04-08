local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Window = WindUI:CreateWindow({
    Title = "BLCBv1",
    Icon = "layout-dashboard",
    Author = "Dwine",
    Folder = "BLCBv1",
    Size = UDim2.fromOffset(580, 460),
    ToggleKey = Enum.KeyCode.RightShift,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
})

Window:EditOpenButton({
    Title = "Open BLCBv1",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "v1.0",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 4,
})

-- ==================== AUTO FARM TAB ====================
local Tab = Window:Tab({
    Title = "Auto Farm",
    Icon = "zap",
})

local autoClaimActive = false

Tab:Toggle({
    Title = "Auto Claim",
    Desc = "Claim Cards",
    Icon = "circle-check",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoClaimActive = state
        if state then
            task.spawn(function()
                while autoClaimActive do
                    pcall(function()
                        game:GetService("ReplicatedStorage").Claim_Remote:FireServer("CLAIM", {})
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tab:Divider()

local autoCardMoneyActive = false

-- Helper: check if a base belongs to the local player
local function isMyBase(base)
    local ownerVal = base:FindFirstChild("Owner")
    if ownerVal and ownerVal:IsA("StringValue") then
        return ownerVal.Value == LocalPlayer.Name
    end
    return false
end

Tab:Toggle({
    Title = "Auto Claim Card Money",
    Desc = "Only collects money from YOUR bases",
    Icon = "coins",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        autoCardMoneyActive = state
        if state then
            task.spawn(function()
                while autoCardMoneyActive do
                    local char = LocalPlayer.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local originalCFrame = root.CFrame
                            local foundAny = false

                            for i = 1, 8 do
                                if not autoCardMoneyActive then break end

                                local base = workspace:FindFirstChild("Base" .. i)
                                if base then
                                    -- Only proceed if this base is owned by us
                                    if isMyBase(base) then
                                        foundAny = true
                                        for slot = 1, 5 do
                                            if not autoCardMoneyActive then break end

                                            local cardSlot = base:FindFirstChild("CardSlot" .. slot)
                                            if cardSlot then
                                                local cashPart = cardSlot:FindFirstChild("Cashpart")
                                                if cashPart and cashPart:IsA("BasePart") then
                                                    root.CFrame = CFrame.new(
                                                        cashPart.Position + Vector3.new(0, 2, 0)
                                                    )
                                                    task.wait()
                                                    task.wait()
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- Return to original position after visiting all owned bases
                            if root and root.Parent then
                                root.CFrame = originalCFrame
                            end

                            -- Notify once if no owned base was found this cycle
                            if not foundAny then
                                WindUI:Notify({
                                    Title = "No Base Found",
                                    Content = "You don't own any base right now.",
                                    Duration = 3,
                                    Icon = "alert-triangle",
                                })
                                -- Wait longer before retrying so notif isn't spammed
                                task.wait(5)
                                continue
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end
})

Tab:Divider()

-- ==================== PLAYER TAB ====================
local Tab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local infJumpConn
Tab:Toggle({
    Title = "Inf Jump",
    Desc = "Jump infinitely in the air",
    Icon = "chevrons-up",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if state then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            if infJumpConn then
                infJumpConn:Disconnect()
                infJumpConn = nil
            end
        end
    end
})

local currentSpeed = 16
Tab:Slider({
    Title = "Walk Speed",
    Desc = "Set your walk speed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 250,
        Default = 16,
    },
    Callback = function(value)
        currentSpeed = value
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = value
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = currentSpeed
end)

Tab:Divider()

local espActive = false
local espBillboards = {}

local function clearESP()
    for _, bb in pairs(espBillboards) do
        if bb and bb.Parent then bb:Destroy() end
    end
    espBillboards = {}
end

local function createESP()
    clearESP()
    for i = 1, 8 do
        local base = workspace:FindFirstChild("Base" .. i)
        if base then
            local ownerVal = base:FindFirstChild("Owner")
            local teamOVRVal = base:FindFirstChild("TEAMOVR")
            local owner = ownerVal and ownerVal.Value or "?"
            local teamOVR = teamOVRVal and teamOVRVal.Value or "?"
            -- Highlight your own base differently
            local isOwned = ownerVal and ownerVal.Value == LocalPlayer.Name

            local attachPart = base:FindFirstChildWhichIsA("BasePart", true)
            if attachPart then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ESP_Base" .. i
                bb.Size = UDim2.new(0, 220, 0, 65)
                bb.StudsOffset = Vector3.new(0, 5, 0)
                bb.AlwaysOnTop = true
                bb.Parent = attachPart

                local label = Instance.new("TextLabel")
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 0.4
                -- Green tint for your base, blue for others
                label.BackgroundColor3 = isOwned
                    and Color3.fromRGB(10, 30, 10)
                    or Color3.fromRGB(10, 10, 30)
                label.TextColor3 = isOwned
                    and Color3.fromRGB(100, 255, 130)
                    or Color3.fromRGB(100, 200, 255)
                label.Font = Enum.Font.GothamBold
                label.TextScaled = true
                label.Text = (isOwned and "★ " or "") ..
                    "Base" .. i .. " | " .. owner ..
                    "\nTEAM OVR: " .. teamOVR
                label.Parent = bb
                Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

                table.insert(espBillboards, bb)
            end
        end
    end
end

Tab:Toggle({
    Title = "ESP Bases",
    Desc = "Show Owner and TeamOVR. Your base is highlighted green.",
    Icon = "eye",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        espActive = state
        if state then
            createESP()
            task.spawn(function()
                while espActive do
                    createESP()
                    task.wait(2)
                end
            end)
        else
            clearESP()
        end
    end
})

Tab:Divider()

-- ==================== TP TAB ====================
local Tab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})

Tab:Button({
    Title = "TP to Base",
    Desc = "Teleport to your base",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").BaseTeleport_Remote:FireServer()
        end)
    end
})

Tab:Button({
    Title = "TP to Shop",
    Desc = "Teleport to the shop",
    Callback = function()
        pcall(function()
            game:GetService("ReplicatedStorage").ShopTeleport_Remote:FireServer()
        end)
    end
})

Tab:Section({
    Title = "Quick Base Teleport",
    Box = false,
    Opened = true,
})

for i = 1, 8 do
    Tab:Button({
        Title = "Go to Base " .. i,
        Desc = "TP directly to Base" .. i,
        Callback = function()
            local base = workspace:FindFirstChild("Base" .. i)
            if base then
                local part = base:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local char = LocalPlayer.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                        end
                    end
                end
            else
                WindUI:Notify({
                    Title = "Not Found",
                    Content = "Base" .. i .. " not found in Workspace.",
                    Duration = 2,
                    Icon = "alert-triangle",
                })
            end
        end
    })
end

-- ==================== MISC TAB ====================
local Tab = Window:Tab({
    Title = "Misc",
    Icon = "settings",
})

Tab:Section({
    Title = "Server",
    Box = false,
    Opened = true,
})

Tab:Button({
    Title = "Rejoin Server",
    Desc = "Reconnects you to the same game",
    Icon = "refresh-cw",
    Callback = function()
        WindUI:Notify({
            Title = "Rejoining...",
            Content = "Reconnecting to the server.",
            Duration = 3,
            Icon = "refresh-cw",
        })
        task.wait(1)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
})

Tab:Button({
    Title = "Low Server Hop",
    Desc = "Finds and joins the server with fewest players",
    Icon = "wifi-low",
    Callback = function()
        WindUI:Notify({
            Title = "Searching...",
            Content = "Looking for a low population server.",
            Duration = 3,
            Icon = "loader",
        })
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local placeId = game.PlaceId
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"

            local success, result = pcall(function()
                return HttpService:GetAsync(url)
            end)

            if not success then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to fetch server list.",
                    Duration = 4,
                    Icon = "alert-triangle",
                })
                return
            end

            local data
            pcall(function()
                data = HttpService:JSONDecode(result)
            end)

            if not data or not data.data then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Could not parse server list.",
                    Duration = 4,
                    Icon = "alert-triangle",
                })
                return
            end

            local bestServer = nil
            local lowestPlayers = math.huge

            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId then
                    local playing = server.playing or 0
                    if playing < lowestPlayers then
                        lowestPlayers = playing
                        bestServer = server
                    end
                end
            end

            if bestServer then
                WindUI:Notify({
                    Title = "Server Found!",
                    Content = "Joining server with " .. lowestPlayers .. " player(s).",
                    Duration = 3,
                    Icon = "check",
                })
                task.wait(1.5)
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
                end)
            else
                WindUI:Notify({
                    Title = "No Server Found",
                    Content = "Could not find a different low server.",
                    Duration = 3,
                    Icon = "alert-triangle",
                })
            end
        end)
    end
})

Tab:Divider()

Tab:Section({
    Title = "About",
    Box = false,
    Opened = true,
})

Tab:Paragraph({
    Title = "BLCBv1",
    Desc = "Auto Farm | Player | Teleport | Misc\nMade for Blue Lock Card Battles.",
})
