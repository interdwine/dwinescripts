if not game:IsLoaded() then game.Loaded:Wait() end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
if not Rayfield then warn("Rayfield failed") return end

-- ─── Services ─────────────────────────────────────────────────────────────────
local RS           = game:GetService("ReplicatedStorage")
local Players      = game:GetService("Players")
local TeleportSvc  = game:GetService("TeleportService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local UserInput    = game:GetService("UserInputService")
local LP           = Players.LocalPlayer

-- ─── Remotes ──────────────────────────────────────────────────────────────────
local Events            = RS:WaitForChild("Events")
local ClaimCoins        = Events:WaitForChild("ClaimCoins")
local BeeShopEvent      = Events:WaitForChild("BeeShopHandler")
local BeeHandler        = Events:WaitForChild("BeeHandler")
local HammerEvent       = Events:WaitForChild("Hammer")
local HandleConveyor    = Events:WaitForChild("HandleConveyor")
local PurchaseConvEgg   = Events:WaitForChild("PurchaseConveyorEgg")
local SellAllFunc       = Events:WaitForChild("SellAll")
local EquipItemFunc     = Events:WaitForChild("EquipItem")

-- ─── Modules ──────────────────────────────────────────────────────────────────
local SharedConveyors = require(RS.Modules.Gameplay.Shared_Conveyors)
local SharedEggs      = require(RS.Modules.Gameplay.Shared_Eggs)
local DataAccess      = require(RS.Modules.Gameplay.DataAccess)

-- ─── Plots ────────────────────────────────────────────────────────────────────
local Plots = workspace:WaitForChild("Core"):WaitForChild("Scriptable"):WaitForChild("Plots")

-- ─── Egg Data ─────────────────────────────────────────────────────────────────
local EGG_DATA = {
    BasicEgg          = { Rarity = "Common",    AssetName = "Seedling Egg" },
    UncommonEgg       = { Rarity = "Uncommon",  AssetName = "Leafy Egg" },
    UncommonRareEgg   = { Rarity = "Rare",      AssetName = "Buzzing Egg" },
    RareEgg           = { Rarity = "Rare",      AssetName = "Icey Egg" },
    EpicEgg           = { Rarity = "Epic",      AssetName = "Blaze Egg" },
    MoreEpicEgg       = { Rarity = "Epic",      AssetName = "Crystal Egg" },
    LegendaryEgg      = { Rarity = "Legendary", AssetName = "Toxic Egg" },
    SecretEgg         = { Rarity = "Legendary", AssetName = "Prism Egg" },
    VoidEgg           = { Rarity = "Mythical",  AssetName = "Void Egg" },
    MysteryEgg        = { Rarity = "Secret",    AssetName = "Mystery Egg" },
    RadiantEgg        = { Rarity = "Mythical",  AssetName = "Radiant Egg" },
    PermafrostEgg     = { Rarity = "Mythical",  AssetName = "Permafrost Egg" },
    SolarEgg          = { Rarity = "Mythical",  AssetName = "Solar Egg" },
    FairyEgg          = { Rarity = "Divine",    AssetName = "Fairy Egg" },
    AlienEgg          = { Rarity = "Divine",    AssetName = "Alien Egg" },
    SnowyEgg          = { Rarity = "Epic",      AssetName = "Snowy Egg" },
    InspectorEgg      = { Rarity = "Premium",   AssetName = "Inspector Egg" },
    MeteorEgg         = { Rarity = "Premium",   AssetName = "Meteor Egg" },
    PumpkinEgg        = { Rarity = "Premium",   AssetName = "Pumpkin Egg" },
    BrainrotEgg       = { Rarity = "Premium",   AssetName = "Brainrot Egg" },
    ChristmasEgg      = { Rarity = "Premium",   AssetName = "Christmas Egg" },
    ArcadeEgg         = { Rarity = "Premium",   AssetName = "Arcade Egg" },
    EasterEgg         = { Rarity = "Premium",   AssetName = "Easter Egg" },
    ArcadeEggEvent    = { Rarity = "Premium",   AssetName = "Arcade Event Egg" },
    VIPEgg            = { Rarity = "Premium",   AssetName = "VIP Egg" },
    DualityEgg        = { Rarity = "Premium",   AssetName = "Duality Egg" },
    DualityEclipseEgg = { Rarity = "Premium",   AssetName = "Duality Eclipse Egg" },
    PlaytimeEgg       = { Rarity = "Premium",   AssetName = "Playtime Eggift" },
}

local RARITY_ORDER = {
    Any=0, Common=1, Uncommon=2, Rare=3, Epic=4,
    Legendary=5, Mythical=6, Secret=7, Divine=8, Premium=9
}
local EGG_DROPDOWN_OPTIONS = {"Any"}
local EGG_OPTION_TO_BASENAME = {}
local seen = {}
for baseName, data in pairs(EGG_DATA) do
    local label = data.Rarity .. " - " .. data.AssetName
    if not seen[label] then
        seen[label] = baseName
        table.insert(EGG_DROPDOWN_OPTIONS, label)
        EGG_OPTION_TO_BASENAME[label] = baseName
    end
end
table.sort(EGG_DROPDOWN_OPTIONS, function(a, b)
    if a == "Any" then return true end
    if b == "Any" then return false end
    local ra = (a:match("^([^%-]+)") or ""):gsub("%s","")
    local rb = (b:match("^([^%-]+)") or ""):gsub("%s","")
    return (RARITY_ORDER[ra] or 99) < (RARITY_ORDER[rb] or 99)
end)

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
    for _, plot in pairs(Plots:GetChildren()) do
        local owner = plot:GetAttribute("plotOwner") or plot:GetAttribute("Owner")
        if owner == LP.Name then return tostring(plot.Name) end
    end
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local dist, target = math.huge, "1"
        for _, plot in pairs(Plots:GetChildren()) do
            local part = plot:FindFirstChildOfClass("BasePart") or plot:FindFirstChild("Conveyor")
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < dist then dist = d; target = tostring(plot.Name) end
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

local function getClient()
    return LP:WaitForChild("PlayerScripts"):WaitForChild("Client")
end

-- ─── State ────────────────────────────────────────────────────────────────────
local State = {
    AutoClaim        = { enabled = false, cooldown = 5 },
    AutoBuyBee       = { enabled = false, rarity = "Common" },
    AutoHatch        = { enabled = false },
    AutoPickup       = { enabled = false, interval = 1 },
    AutoConvEgg      = { enabled = false, delay = 0.1, selectedOption = "Any" },
    AutoConveyor     = { enabled = false },
    AutoSell         = { enabled = false },
    AutoEaster       = { enabled = false },
    AutoArcadeOrb    = { enabled = false },
    AutoArcadeTicket = { enabled = false },
    AutoArcadeSpin   = { enabled = false },
    AutoNotifier     = { enabled = false },
    Fly              = { enabled = false },
    InfJump          = { enabled = false },
    ESPFlower        = { enabled = false },
    ESPPlayer        = { enabled = false },
    MyPlot           = "1",
    WalkSpeed        = 16,
}

-- ─── Window ───────────────────────────────────────────────────────────────────
-- No ToggleUIKeybind — mobile friendly via ShowText button only
local Window = Rayfield:CreateWindow({
    Name                   = "🐝 Bee Garden Auto Farm",
    LoadingTitle           = "Bee Garden Script",
    LoadingSubtitle        = "Loading...",
    Theme                  = "Default",
    ShowText               = "🐝 Open",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 1 — 💰 ECONOMY
-- ══════════════════════════════════════════════════════════════════════════════
local EconTab = Window:CreateTab("💰 Economy", 4483362458)

EconTab:CreateToggle({
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

EconTab:CreateSlider({
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

EconTab:CreateDivider()

EconTab:CreateToggle({
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

EconTab:CreateLabel("Auto Claim fires ClaimCoins. Auto Sell fires SellAll every 5s.")

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

BeesTab:CreateDivider()

BeesTab:CreateButton({
    Name     = "Equip Best Bees",
    Callback = function()
        pcall(function() BeeHandler:InvokeServer(getClient()) end)
        Rayfield:Notify({ Title="Bees", Content="Equipping best bees!", Duration=3 })
    end,
})

BeesTab:CreateButton({
    Name     = "Unequip All Bees",
    Callback = function()
        pcall(function() BeeHandler:InvokeServer(getClient()) end)
        Rayfield:Notify({ Title="Bees", Content="Unequipping all bees!", Duration=3 })
    end,
})

BeesTab:CreateLabel("Shop resets every 360s. Equip/Unequip uses BeeHandler:InvokeServer(Client).")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 3 — 🥚 EGGS
-- ══════════════════════════════════════════════════════════════════════════════
local EggTab = Window:CreateTab("🥚 Eggs", 4483362458)

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

EggTab:CreateDropdown({
    Name            = "Conveyor Egg Filter",
    Options         = EGG_DROPDOWN_OPTIONS,
    CurrentOption   = {"Any"},
    MultipleOptions = false,
    Flag            = "ConvEggDropdown",
    Callback        = function(sel)
        State.AutoConvEgg.selectedOption = sel[1] or "Any"
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
                            local shouldBuy = false
                            local option = State.AutoConvEgg.selectedOption
                            if option == "Any" then
                                shouldBuy = true
                            else
                                local baseName = egg:GetAttribute("baseName")
                                if baseName then
                                    local targetBase = EGG_OPTION_TO_BASENAME[option]
                                    if targetBase and baseName == targetBase then
                                        shouldBuy = true
                                    end
                                end
                            end
                            if shouldBuy then
                                pcall(function()
                                    PurchaseConvEgg:FireServer(egg.Name, State.MyPlot)
                                end)
                                task.wait(State.AutoConvEgg.delay or 0.1)
                            end
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
                            if not State.AutoHatch.enabled then break end
                            if item:GetAttribute("ItemType") == "Egg" then
                                local char = LP.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                local primaryPart = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                if hrp and primaryPart then
                                    hrp.CFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.2)
                                end
                                for _, desc in ipairs(item:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") and desc.ActionText == "Hatch" then
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
                                local char = LP.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                local primaryPart = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                if hrp and primaryPart then
                                    hrp.CFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.2)
                                end
                                for _, desc in ipairs(item:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") and desc.ActionText == "Skip" then
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

EggTab:CreateLabel("Filter by Rarity - AssetName. baseName attribute used to match eggs.")

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
        pcall(function() HammerEvent:FireServer(flower.Name) end)
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
        Rayfield:Notify({ Title="Conveyor", Content="Equipping " .. selectedConveyorKey, Duration=3 })
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
                    local unlocked = (data.ConveyorUpgrade and data.ConveyorUpgrade.UnlockedConveyors) or {}
                    local bestKey, bestPrice = nil, -1
                    if SharedConveyors and SharedConveyors.List then
                        for key, conv in pairs(SharedConveyors.List) do
                            if unlocked[key] and (conv.Price or 0) > bestPrice then
                                bestPrice = conv.Price or 0
                                bestKey   = key
                            end
                        end
                    end
                    if bestKey then safeFire(HandleConveyor, "equip", bestKey) end
                    task.wait(30)
                end
            end)
        end
    end,
})

ConveyorTab:CreateLabel("HandleConveyor:FireServer('equip', key). Equips best Queen Bee automatically.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 6 — 🎪 EVENTS
-- ══════════════════════════════════════════════════════════════════════════════
local EventTab = Window:CreateTab("🎪 Events", 4483362458)

EventTab:CreateSection("🐰 Easter")

EventTab:CreateToggle({
    Name         = "Auto Find Easter Eggs",
    CurrentValue = false,
    Flag         = "AutoEasterToggle",
    Callback     = function(val)
        State.AutoEaster.enabled = val
        if val then
            task.spawn(function()
                while State.AutoEaster.enabled do
                    local eventsFolder = workspace:FindFirstChild("Events")
                    if eventsFolder then
                        for _, obj in ipairs(eventsFolder:GetDescendants()) do
                            if not State.AutoEaster.enabled then break end
                            if obj:IsA("ProximityPrompt") and
                                (obj.ActionText:lower():find("easter") or
                                (obj.Parent and obj.Parent.Name:lower():find("easter"))) then
                                local char = LP.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                local part = obj.Parent
                                if hrp and part and part:IsA("BasePart") then
                                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.2)
                                end
                                pcall(fireproximityprompt, obj)
                                task.wait(0.3)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    end,
})

EventTab:CreateSection("🕹️ Arcade")

EventTab:CreateToggle({
    Name         = "Auto Collect Arcade Orbs",
    CurrentValue = false,
    Flag         = "AutoArcadeOrbToggle",
    Callback     = function(val)
        State.AutoArcadeOrb.enabled = val
        if val then
            task.spawn(function()
                while State.AutoArcadeOrb.enabled do
                    local eventsFolder  = workspace:FindFirstChild("Events")
                    local arcadeSpheres = eventsFolder and eventsFolder:FindFirstChild("ArcadeSpheres")
                    if arcadeSpheres then
                        for _, orb in ipairs(arcadeSpheres:GetChildren()) do
                            if not State.AutoArcadeOrb.enabled then break end
                            local char = LP.Character
                            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                            local part = orb:IsA("BasePart") and orb or orb:FindFirstChildOfClass("BasePart")
                            if hrp and part then
                                hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                task.wait(0.3)
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

EventTab:CreateToggle({
    Name         = "Auto Collect Arcade Tickets",
    CurrentValue = false,
    Flag         = "AutoArcadeTicketToggle",
    Callback     = function(val)
        State.AutoArcadeTicket.enabled = val
        if val then
            task.spawn(function()
                while State.AutoArcadeTicket.enabled do
                    local eventsFolder = workspace:FindFirstChild("Events")
                    if eventsFolder then
                        for _, obj in ipairs(eventsFolder:GetDescendants()) do
                            if not State.AutoArcadeTicket.enabled then break end
                            if obj.Name:lower():find("arcadeticket") or obj.Name:lower():find("arcade_ticket") then
                                local char = LP.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                                if hrp and part then
                                    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                    task.wait(0.2)
                                end
                                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                    or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
                                if prompt then
                                    pcall(fireproximityprompt, prompt)
                                    task.wait(0.2)
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

EventTab:CreateToggle({
    Name         = "Auto Arcade Machine Spin",
    CurrentValue = false,
    Flag         = "AutoArcadeSpinToggle",
    Callback     = function(val)
        State.AutoArcadeSpin.enabled = val
        if val then
            task.spawn(function()
                while State.AutoArcadeSpin.enabled do
                    local core       = workspace:FindFirstChild("Core")
                    local scriptable = core and core:FindFirstChild("Scriptable")
                    local others     = scriptable and scriptable:FindFirstChild("Others")
                    local machine    = others and others:FindFirstChild("ArcadeMachine")
                    local touchParts = scriptable and scriptable:FindFirstChild("TouchParts")
                    local proxPart   = touchParts and touchParts:FindFirstChild("ArcadeProximityPart")
                    local prompt     = proxPart and proxPart:FindFirstChild("ArcadePrompt")
                    if prompt then
                        local char = LP.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and machine then
                            local machinePart = machine:FindFirstChildOfClass("BasePart")
                            if machinePart then
                                hrp.CFrame = machinePart.CFrame + Vector3.new(0, 3, 4)
                                task.wait(0.3)
                            end
                        end
                        pcall(fireproximityprompt, prompt)
                        task.wait(4)
                    else
                        Rayfield:Notify({ Title="Arcade", Content="Machine not found or no tickets.", Duration=3 })
                        task.wait(5)
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

EventTab:CreateLabel("Arcade: collect 12 orbs for a ticket. Machine at Core.Scriptable.Others.ArcadeMachine.")

EventTab:CreateSection("🔔 Notifier")

EventTab:CreateToggle({
    Name         = "Auto Event Notifier",
    CurrentValue = false,
    Flag         = "AutoNotifierToggle",
    Callback     = function(val)
        State.AutoNotifier.enabled = val
        if val then
            task.spawn(function()
                local knownFolders = {}
                while State.AutoNotifier.enabled do
                    local eventsFolder = workspace:FindFirstChild("Events")
                    if eventsFolder then
                        for _, child in ipairs(eventsFolder:GetChildren()) do
                            if not knownFolders[child.Name] then
                                knownFolders[child.Name] = true
                                Rayfield:Notify({
                                    Title    = "🔔 Event Detected!",
                                    Content  = "New event folder: " .. child.Name,
                                    Duration = 8,
                                })
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
    end,
})

EventTab:CreateLabel("Watches workspace.Events for new folders and notifies you.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 7 — ⚡ PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("⚡ Player", 4483362458)

PlayerTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 500},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 16,
    Flag         = "WalkSpeedSlider",
    Callback     = function(val)
        State.WalkSpeed = val
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
        LP.CharacterAdded:Connect(function(c)
            local h = c:WaitForChild("Humanoid")
            h.WalkSpeed = State.WalkSpeed
        end)
    end,
})

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJumpToggle",
    Callback     = function(val)
        State.InfJump.enabled = val
    end,
})

local flyConn = nil
local flyBV   = nil

PlayerTab:CreateToggle({
    Name         = "Fly",
    CurrentValue = false,
    Flag         = "FlyToggle",
    Callback     = function(val)
        State.Fly.enabled = val
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if val and hrp then
            hum.PlatformStand = true
            flyBV = Instance.new("BodyVelocity")
            flyBV.Velocity = Vector3.new(0, 0, 0)
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Parent   = hrp
            flyConn = RunService.RenderStepped:Connect(function()
                if not State.Fly.enabled then
                    if flyBV then flyBV:Destroy() flyBV = nil end
                    if hum then hum.PlatformStand = false end
                    if flyConn then flyConn:Disconnect() flyConn = nil end
                    return
                end
                local cam   = workspace.CurrentCamera
                local speed = 50
                local dir   = Vector3.new(0, 0, 0)
                if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new(0,0,0)
            end)
        else
            State.Fly.enabled = false
            if flyBV then flyBV:Destroy() flyBV = nil end
            if flyConn then flyConn:Disconnect() flyConn = nil end
            if hum then hum.PlatformStand = false end
        end
    end,
})

UserInput.JumpRequest:Connect(function()
    if State.InfJump.enabled then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PlayerTab:CreateLabel("Fly: WASD to move, Space up, LCtrl down.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 8 — 🔍 ESP
-- ══════════════════════════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("🔍 ESP", 4483362458)

local espBillboards = {}

local function clearESP()
    for _, bb in pairs(espBillboards) do
        pcall(function() bb:Destroy() end)
    end
    espBillboards = {}
end

-- Small fixed-size billboard for ESP text
local function createBillboard(adornee, text, color)
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.new(0, 80, 0, 20) -- small fixed size
    bb.StudsOffset   = Vector3.new(0, 2.5, 0)
    bb.Adornee       = adornee
    bb.Parent        = game.CoreGui
    bb.LightInfluence = 0

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.Text                   = text
    label.TextColor3             = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 11 -- small fixed text size, NOT TextScaled
    label.TextScaled             = false
    label.Parent                 = bb

    table.insert(espBillboards, bb)
    return bb
end

-- Flower ESP
ESPTab:CreateToggle({
    Name         = "Flower ESP",
    CurrentValue = false,
    Flag         = "FlowerESPToggle",
    Callback     = function(val)
        State.ESPFlower.enabled = val
        if not val then clearESP() return end
        task.spawn(function()
            while State.ESPFlower.enabled do
                clearESP()
                for _, plot in ipairs(Plots:GetChildren()) do
                    local placedItems = plot:FindFirstChild("PlacedItems")
                    if placedItems then
                        for _, item in ipairs(placedItems:GetChildren()) do
                            if item:GetAttribute("ItemType") == "Flower" then
                                -- Read BaseName attribute directly from PlacedItems item
                                local flowerName = item:GetAttribute("BaseName")
                                    or item:GetAttribute("baseName")
                                    or "Unknown"
                                local part = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                if part then
                                    createBillboard(
                                        part,
                                        flowerName,
                                        Color3.fromRGB(255, 100, 200)
                                    )
                                end
                            end
                        end
                    end
                end
                task.wait(3)
            end
        end)
    end,
})

-- Player ESP
ESPTab:CreateToggle({
    Name         = "Player ESP",
    CurrentValue = false,
    Flag         = "PlayerESPToggle",
    Callback     = function(val)
        State.ESPPlayer.enabled = val
        if not val then clearESP() return end
        task.spawn(function()
            while State.ESPPlayer.enabled do
                clearESP()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LP then
                        local char = player.Character
                        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local dist  = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                            createBillboard(
                                hrp,
                                player.Name .. " " .. dist .. "m",
                                Color3.fromRGB(255, 220, 50)
                            )
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end,
})

ESPTab:CreateLabel("Flower ESP reads BaseName from PlacedItems. Player ESP shows distance.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 9 — 🏪 MISC
-- ══════════════════════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("🏪 Misc", 4483362458)

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
            local url       = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            local lowest, lowestPop = nil, math.huge
            local cursor, searched, maxPages = nil, 0, 3
            repeat
                local fullUrl = url .. (cursor and ("&cursor=" .. cursor) or "")
                local ok, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(fullUrl))
                end)
                if not ok or not result or not result.data then break end
                for _, server in ipairs(result.data) do
                    if server.id ~= currentId and type(server.playing) == "number"
                        and server.playing < lowestPop and server.playing > 0 then
                        lowestPop = server.playing
                        lowest    = server.id
                    end
                end
                cursor   = result.nextPageCursor
                searched = searched + 1
            until (not cursor) or searched >= maxPages
            if lowest then
                Rayfield:Notify({ Title="Server Hop", Content="Found server with " .. lowestPop .. " players. Joining...", Duration=3 })
                task.wait(1.5)
                TeleportSvc:TeleportToPlaceInstance(placeId, lowest, LP)
            else
                Rayfield:Notify({ Title="Server Hop", Content="No suitable server found.", Duration=3 })
            end
        end)
    end,
})

MiscTab:CreateLabel("Tap '🐝 Open' button on screen to reopen UI after closing.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 10 — ⛔ STOP ALL
-- ══════════════════════════════════════════════════════════════════════════════
local StopTab = Window:CreateTab("⛔ Stop All", 4483362458)

StopTab:CreateButton({
    Name     = "⛔ Disable All Features",
    Callback = function()
        for _, s in pairs(State) do
            if type(s) == "table" and s.enabled ~= nil then
                s.enabled = false
            end
        end
        clearESP()
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        Rayfield:Notify({ Title="Stopped", Content="All features disabled.", Duration=3 })
    end,
})

-- ─── Startup ──────────────────────────────────────────────────────────────────
Rayfield:Notify({
    Title    = "🐝 Bee Garden Script",
    Content  = "Loaded! Economy · Bees · Eggs · Flowers · Conveyor · Events · Player · ESP · Misc",
    Duration = 6,
    Image    = 4483362458,
})
