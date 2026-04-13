if not game:IsLoaded() then game.Loaded:Wait() end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
if not Rayfield then warn("Rayfield failed") return end

-- ─── Services ─────────────────────────────────────────────────────────────────
local RS          = game:GetService("ReplicatedStorage")
local Players     = game:GetService("Players")
local TeleportSvc = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP          = Players.LocalPlayer

-- ─── Remotes ──────────────────────────────────────────────────────────────────
local Events          = RS:WaitForChild("Events")
local ClaimCoins      = Events:WaitForChild("ClaimCoins")
local BeeShopEvent    = Events:WaitForChild("BeeShopHandler")
local HammerEvent     = Events:WaitForChild("Hammer")
local HandleConveyor  = Events:WaitForChild("HandleConveyor")
local PurchaseConvEgg = Events:WaitForChild("PurchaseConveyorEgg")
local SellAllFunc     = Events:WaitForChild("SellAll")
local EquipItemFunc   = Events:WaitForChild("EquipItem")

-- ─── Modules ──────────────────────────────────────────────────────────────────
local SharedConveyors = require(RS.Modules.Gameplay.Shared_Conveyors)
local DataAccess      = require(RS.Modules.Gameplay.DataAccess)

-- ─── Plots ────────────────────────────────────────────────────────────────────
local Plots = workspace:WaitForChild("Core"):WaitForChild("Scriptable"):WaitForChild("Plots")

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getPlot()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, plot in ipairs(Plots:GetChildren()) do
        local bp = plot:FindFirstChildOfClass("BasePart") or plot:FindFirstChild("BuildPart")
        if bp then
            local lp   = bp.CFrame:PointToObjectSpace(hrp.Position)
            local half = bp.Size / 2
            if math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z then
                return plot
            end
        end
    end
    return nil
end

local function getMyPlotId()
    -- Try attribute first
    for _, plot in pairs(Plots:GetChildren()) do
        local owner = plot:GetAttribute("plotOwner") or plot:GetAttribute("Owner")
        if owner == LP.Name then
            return tostring(plot.Name)
        end
    end
    -- Fallback: closest plot by distance
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local dist, target = math.huge, "1"
        for _, plot in pairs(Plots:GetChildren()) do
            local part = plot:FindFirstChildOfClass("BasePart") or plot:FindFirstChild("Conveyor")
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < dist then
                    dist   = d
                    target = tostring(plot.Name)
                end
            end
        end
        return target
    end
    return "1"
end

local function getPlacedItems()
    local plot = getPlot()
    return plot and plot:FindFirstChild("PlacedItems")
end

local function getClientData()
    local ok, data = pcall(function() return DataAccess:GetData() end)
    return ok and data or {}
end

local function safeFire(remote, a, b)
    if not remote then return end
    pcall(function() remote:FireServer(a, b) end)
end

local function safeInvoke(remote)
    if not remote then return end
    pcall(function() remote:InvokeServer() end)
end

local function equipHammer()
    pcall(function()
        local client = LP:WaitForChild("PlayerScripts"):WaitForChild("Client")
        EquipItemFunc:InvokeServer(client)
    end)
end

-- ─── State ────────────────────────────────────────────────────────────────────
local State = {
    AutoClaim    = { enabled = false, cooldown = 5 },
    AutoBuyBee   = { enabled = false, rarity = "Common" },
    AutoHatch    = { enabled = false },
    AutoPickup   = { enabled = false, interval = 1 },
    AutoConvEgg  = { enabled = false, delay = 0.1 },
    AutoConveyor = { enabled = false },
    AutoSell     = { enabled = false },
    MyPlot       = "1",
}

-- ─── Window ───────────────────────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name                   = "🐝 Bee Garden Auto Farm",
    LoadingTitle           = "Bee Garden Script",
    LoadingSubtitle        = "Loading...",
    Theme                  = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 1 — 💰 COINS
-- ══════════════════════════════════════════════════════════════════════════════
local CoinsTab = Window:CreateTab("💰 Coins", 4483362458)

CoinsTab:CreateToggle({
    Name         = "Auto Claim Coins",
    CurrentValue = false,
    Flag         = "AutoClaimToggle",
    Callback     = function(val)
        State.AutoClaim.enabled = val
        if val then
            task.spawn(function()
                while State.AutoClaim.enabled do
                    safeFire(ClaimCoins, "Collect_Coins")
                    task.wait(State.AutoClaim.cooldown)
                end
            end)
        end
    end,
})

CoinsTab:CreateSlider({
    Name         = "Claim Cooldown (seconds)",
    Range        = {1, 60},
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 5,
    Flag         = "ClaimCooldown",
    Callback     = function(val)
        State.AutoClaim.cooldown = val
    end,
})

CoinsTab:CreateToggle({
    Name         = "Auto Sell All Flowers",
    CurrentValue = false,
    Flag         = "AutoSellToggle",
    Callback     = function(val)
        State.AutoSell.enabled = val
        if val then
            task.spawn(function()
                while State.AutoSell.enabled do
                    safeInvoke(SellAllFunc)
                    task.wait(5)
                end
            end)
        end
    end,
})

CoinsTab:CreateLabel("Auto Claim fires ClaimCoins. Auto Sell fires SellAll:InvokeServer().")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — 🐝 BEES
-- ══════════════════════════════════════════════════════════════════════════════
local BeesTab = Window:CreateTab("🐝 Bees", 4483362458)

local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}

BeesTab:CreateDropdown({
    Name            = "Target Rarity to Buy",
    Options         = RARITIES,
    CurrentOption   = {"Common"},
    MultipleOptions = false,
    Flag            = "BeeRarityDropdown",
    Callback        = function(sel)
        State.AutoBuyBee.rarity = sel[1] or "Common"
    end,
})

BeesTab:CreateToggle({
    Name         = "Auto Buy Bee",
    CurrentValue = false,
    Flag         = "AutoBuyBeeToggle",
    Callback     = function(val)
        State.AutoBuyBee.enabled = val
        if val then
            task.spawn(function()
                while State.AutoBuyBee.enabled do
                    local raritySlotMap = {
                        Common=1, Uncommon=2, Rare=3, Epic=4,
                        Legendary=5, Mythical=6, Secret=7
                    }
                    local base = raritySlotMap[State.AutoBuyBee.rarity]
                    if base then
                        safeFire(BeeShopEvent, "Purchase", {
                            slotIndex = (base * 2) - 1,
                            quantity  = 1,
                        })
                    end
                    task.wait(1.5)
                end
            end)
        end
    end,
})

BeesTab:CreateLabel("Shop resets every 360s. Fires BeeShopHandler Purchase with slotIndex.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 3 — 🥚 EGGS & HATCH
-- ══════════════════════════════════════════════════════════════════════════════
local EggTab = Window:CreateTab("🥚 Eggs & Hatch", 4483362458)

EggTab:CreateButton({
    Name     = "Auto-Detect My Plot",
    Callback = function()
        State.MyPlot = getMyPlotId()
        Rayfield:Notify({
            Title    = "Plot Detected",
            Content  = "Targeting Plot: " .. State.MyPlot,
            Duration = 3,
        })
    end,
})

EggTab:CreateSlider({
    Name         = "Buy Delay (seconds)",
    Range        = {0.1, 10},
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = 0.1,
    Flag         = "ConvEggDelay",
    Callback     = function(val)
        State.AutoConvEgg.delay = val
    end,
})

EggTab:CreateToggle({
    Name         = "Auto Buy Conveyor Eggs",
    CurrentValue = false,
    Flag         = "AutoBuyConvEggToggle",
    Callback     = function(val)
        State.AutoConvEgg.enabled = val
        if val then
            task.spawn(function()
                -- Auto detect plot on start if not already set
                if State.MyPlot == "1" then
                    State.MyPlot = getMyPlotId()
                end

                Rayfield:Notify({
                    Title    = "Conveyor Eggs",
                    Content  = "Starting on plot: " .. State.MyPlot,
                    Duration = 3,
                })

                while State.AutoConvEgg.enabled do
                    local plotFolder = Plots:FindFirstChild(State.MyPlot)
                    local eggsFolder = plotFolder and plotFolder:FindFirstChild("Eggs")

                    if eggsFolder then
                        for _, egg in pairs(eggsFolder:GetChildren()) do
                            if not State.AutoConvEgg.enabled then break end
                            -- Fire with egg.Name (server-assigned GUID) and plot ID string
                            pcall(function()
                                PurchaseConvEgg:FireServer(egg.Name, State.MyPlot)
                            end)
                            task.wait(State.AutoConvEgg.delay or 0.1)
                        end
                    end

                    task.wait(State.AutoConvEgg.delay or 0.1)
                end
            end)
        end
    end,
})

EggTab:CreateDivider()

EggTab:CreateToggle({
    Name         = "Auto Hatch Eggs",
    CurrentValue = false,
    Flag         = "AutoHatchToggle",
    Callback     = function(val)
        State.AutoHatch.enabled = val
        if val then
            task.spawn(function()
                while State.AutoHatch.enabled do
                    local placedItems = getPlacedItems()
                    if placedItems then
                        for _, item in ipairs(placedItems:GetChildren()) do
                            if item:GetAttribute("ItemType") == "Egg" then
                                for _, desc in ipairs(item:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt")
                                        and desc.ActionText == "Hatch" then
                                        pcall(fireproximityprompt, desc)
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

EggTab:CreateToggle({
    Name         = "Auto Skip All Eggs",
    CurrentValue = false,
    Flag         = "AutoSkipEggToggle",
    Callback     = function(val)
        if val then
            task.spawn(function()
                while val do
                    local placedItems = getPlacedItems()
                    if placedItems then
                        for _, item in ipairs(placedItems:GetChildren()) do
                            if item:GetAttribute("ItemType") == "Egg" then
                                for _, desc in ipairs(item:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt")
                                        and desc.ActionText == "Skip" then
                                        pcall(fireproximityprompt, desc)
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

EggTab:CreateLabel("Click Auto-Detect first. Fires PurchaseConveyorEgg(egg.Name, plotId) per egg.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 4 — 🌸 FLOWERS
-- ══════════════════════════════════════════════════════════════════════════════
local FlowersTab = Window:CreateTab("🌸 Flowers", 4483362458)

local function pickupFlowers()
    local plot = getPlot()
    if not plot then return end
    local placedItems = plot:FindFirstChild("PlacedItems")
    if not placedItems then return end

    local flowers = {}
    for _, item in ipairs(placedItems:GetChildren()) do
        if item:GetAttribute("ItemType") == "Flower" then
            table.insert(flowers, item)
        end
    end
    if #flowers == 0 then return end

    equipHammer()
    task.wait(0.3)

    for _, flower in ipairs(flowers) do
        pcall(function()
            HammerEvent:FireServer(flower.Name)
        end)
        task.wait(0.1)
    end
end

FlowersTab:CreateToggle({
    Name         = "Auto Pickup Flowers",
    CurrentValue = false,
    Flag         = "AutoPickupToggle",
    Callback     = function(val)
        State.AutoPickup.enabled = val
        if val then
            task.spawn(function()
                while State.AutoPickup.enabled do
                    pickupFlowers()
                    task.wait(State.AutoPickup.interval)
                end
            end)
        end
    end,
})

FlowersTab:CreateSlider({
    Name         = "Pickup Interval (seconds)",
    Range        = {0.5, 10},
    Increment    = 0.5,
    Suffix       = "s",
    CurrentValue = 1,
    Flag         = "PickupInterval",
    Callback     = function(val)
        State.AutoPickup.interval = val
    end,
})

FlowersTab:CreateLabel("EquipItem:InvokeServer(Client) then Hammer:FireServer(flower.Name) per flower.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 5 — 👑 CONVEYOR
-- ══════════════════════════════════════════════════════════════════════════════
local ConveyorTab = Window:CreateTab("👑 Conveyor", 4483362458)

local CONVEYOR_LIST = {}
if SharedConveyors and SharedConveyors.List then
    for key, data in pairs(SharedConveyors.List) do
        table.insert(CONVEYOR_LIST, (data.Name or key) .. " [" .. key .. "]")
    end
    table.sort(CONVEYOR_LIST)
else
    CONVEYOR_LIST = {
        "Baby Queen [Queen1]","Mother Queen [Queen2]","Royal Queen [Queen3]",
        "Grand Queen [Queen4]","Empress Queen [Queen5]",
        "Arcane Queen [Queen6]","Eternal Queen [Queen7]"
    }
end

local selectedConveyorKey = "Queen1"

ConveyorTab:CreateDropdown({
    Name            = "Select Queen Conveyor",
    Options         = CONVEYOR_LIST,
    CurrentOption   = {CONVEYOR_LIST[1] or "Baby Queen [Queen1]"},
    MultipleOptions = false,
    Flag            = "ConveyorDropdown",
    Callback        = function(sel)
        local key = (sel[1] or ""):match("%[(.-)%]")
        selectedConveyorKey = key or "Queen1"
    end,
})

ConveyorTab:CreateButton({
    Name     = "Equip Selected Conveyor",
    Callback = function()
        safeFire(HandleConveyor, "equip", selectedConveyorKey)
        Rayfield:Notify({
            Title    = "Conveyor",
            Content  = "Equipping " .. selectedConveyorKey,
            Duration = 3,
        })
    end,
})

ConveyorTab:CreateToggle({
    Name         = "Auto Equip Best Unlocked Conveyor",
    CurrentValue = false,
    Flag         = "AutoConveyorToggle",
    Callback     = function(val)
        State.AutoConveyor.enabled = val
        if val then
            task.spawn(function()
                while State.AutoConveyor.enabled do
                    local data     = getClientData()
                    local unlocked = (data.ConveyorUpgrade
                        and data.ConveyorUpgrade.UnlockedConveyors) or {}
                    local bestKey, bestPrice = nil, -1
                    if SharedConveyors and SharedConveyors.List then
                        for key, conv in pairs(SharedConveyors.List) do
                            if unlocked[key] and (conv.Price or 0) > bestPrice then
                                bestPrice = conv.Price or 0
                                bestKey   = key
                            end
                        end
                    end
                    if bestKey then
                        safeFire(HandleConveyor, "equip", bestKey)
                    end
                    task.wait(30)
                end
            end)
        end
    end,
})

ConveyorTab:CreateLabel("HandleConveyor:FireServer('equip', key). Equips best Queen Bee automatically.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 6 — 🏪 MISC
-- ══════════════════════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("🏪 Misc", 4483362458)

MiscTab:CreateButton({
    Name     = "Show UI",
    Callback = function()
        Rayfield:ShowAndHide()
    end,
})

MiscTab:CreateButton({
    Name     = "Rejoin Server",
    Callback = function()
        Rayfield:Notify({ Title="Rejoin", Content="Rejoining...", Duration=2 })
        task.wait(1)
        TeleportSvc:Teleport(game.PlaceId, LP)
    end,
})

MiscTab:CreateButton({
    Name     = "Find Low Pop Server",
    Callback = function()
        Rayfield:Notify({ Title="Server Hop", Content="Searching for low pop server...", Duration=2 })
        task.spawn(function()
            local placeId   = game.PlaceId
            local currentId = game.JobId
            local url       = "https://games.roblox.com/v1/games/"
                .. placeId
                .. "/servers/Public?sortOrder=Asc&limit=100"

            local lowest    = nil
            local lowestPop = math.huge
            local cursor    = nil
            local searched  = 0
            local maxPages  = 3

            repeat
                local fullUrl = url
                if cursor then
                    fullUrl = fullUrl .. "&cursor=" .. cursor
                end

                local ok, result = pcall(function()
                    return HttpService:JSONDecode(
                        game:HttpGet(fullUrl)
                    )
                end)

                if not ok or not result or not result.data then break end

                for _, server in ipairs(result.data) do
                    if server.id ~= currentId
                        and type(server.playing) == "number"
                        and server.playing < lowestPop
                        and server.playing > 0 then
                        lowestPop = server.playing
                        lowest    = server.id
                    end
                end

                cursor   = result.nextPageCursor
                searched = searched + 1
            until (not cursor) or searched >= maxPages

            if lowest then
                Rayfield:Notify({
                    Title    = "Server Hop",
                    Content  = "Found server with " .. lowestPop .. " players. Joining...",
                    Duration = 3,
                })
                task.wait(1.5)
                TeleportSvc:TeleportToPlaceInstance(placeId, lowest, LP)
            else
                Rayfield:Notify({
                    Title    = "Server Hop",
                    Content  = "No suitable server found.",
                    Duration = 3,
                })
            end
        end)
    end,
})

MiscTab:CreateLabel("Show UI toggles Rayfield. Rejoin & Server Hop use TeleportService.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 7 — ⛔ STOP ALL
-- ══════════════════════════════════════════════════════════════════════════════
local StopTab = Window:CreateTab("⛔ Stop All", 4483362458)

StopTab:CreateButton({
    Name     = "⛔ Disable All Features",
    Callback = function()
        for _, s in pairs(State) do
            if type(s) == "table" then s.enabled = false end
        end
        Rayfield:Notify({
            Title   = "Stopped",
            Content = "All features disabled.",
            Duration = 3,
        })
    end,
})

-- ─── Startup Notification ─────────────────────────────────────────────────────
Rayfield:Notify({
    Title    = "🐝 Bee Garden Script",
    Content  = "Loaded! Coins · Bees · Eggs · Flowers · Conveyor · Misc",
    Duration = 5,
    Image    = 4483362458,
})
