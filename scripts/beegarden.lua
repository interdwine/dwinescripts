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
local Workspace    = game:GetService("Workspace")

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

-- ══════════════════════════════════════════════════════════════════════════════
-- CONNECTION MANAGEMENT SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local ConnectionManager = {
    _connections = {},
    _threads = {}
}

function ConnectionManager:Register(name, connection)
    if self._connections[name] then
        pcall(function() self._connections[name]:Disconnect() end)
    end
    self._connections[name] = connection
end

function ConnectionManager:RegisterThread(name, thread)
    self._threads[name] = thread
end

function ConnectionManager:Cleanup(name)
    if self._connections[name] then
        pcall(function() self._connections[name]:Disconnect() end)
        self._connections[name] = nil
    end
    if self._threads[name] then
        self._threads[name] = nil
    end
end

function ConnectionManager:CleanupAll()
    for name, conn in pairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    self._threads = {}
end

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTE THROTTLING SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local RemoteThrottle = {
    _lastCalls = {},
    _failureCounts = {}
}

function RemoteThrottle:CanFire(remoteName, cooldown)
    local lastCall = self._lastCalls[remoteName] or 0
    local now = os.clock()
    
    local failures = self._failureCounts[remoteName] or 0
    if failures > 3 then
        cooldown = cooldown * (1 + failures * 0.5)
    end
    
    if now - lastCall < cooldown then
        return false
    end
    
    self._lastCalls[remoteName] = now
    return true
end

function RemoteThrottle:RecordSuccess(remoteName)
    self._failureCounts[remoteName] = 0
end

function RemoteThrottle:RecordFailure(remoteName)
    self._failureCounts[remoteName] = (self._failureCounts[remoteName] or 0) + 1
end

-- ─── Enhanced Safe Remote Functions ───────────────────────────────────────────
local function safeFire(remote, ...)
    if not remote then return false end
    local args = {...}
    local success = false
    pcall(function()
        remote:FireServer(unpack(args))
        success = true
    end)
    return success
end

local function safeFireThrottled(remoteName, remote, cooldown, ...)
    if not remote then return false end
    if not RemoteThrottle:CanFire(remoteName, cooldown) then
        return false
    end
    
    local args = {...}
    local success = false
    pcall(function()
        remote:FireServer(unpack(args))
        success = true
        RemoteThrottle:RecordSuccess(remoteName)
    end)
    
    if not success then
        RemoteThrottle:RecordFailure(remoteName)
    end
    return success
end

local function safeInvoke(remote)
    if not remote then return end
    pcall(function() remote:InvokeServer() end)
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local PlotCache = {}

local function getPlot()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local pos = hrp.Position
    local cacheKey = string.format("%d,%d,%d", math.floor(pos.X/10), math.floor(pos.Y/10), math.floor(pos.Z/10))
    
    if PlotCache[cacheKey] and PlotCache[cacheKey].Parent then
        return PlotCache[cacheKey]
    end
    
    for _, plot in ipairs(Plots:GetChildren()) do
        local bp = plot:FindFirstChildOfClass("BasePart") or plot:FindFirstChild("BuildPart")
        if bp then
            local lp   = bp.CFrame:PointToObjectSpace(hrp.Position)
            local half = bp.Size / 2
            if math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z then
                PlotCache[cacheKey] = plot
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

local function equipHammer()
    pcall(function()
        local client = LP:WaitForChild("PlayerScripts"):WaitForChild("Client")
        EquipItemFunc:InvokeServer(client)
    end)
end

local function getClient()
    return LP:WaitForChild("PlayerScripts"):WaitForChild("Client")
end

local function fireProximityPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    
    local success = false
    pcall(function()
        if prompt.Enabled then
            fireproximityprompt(prompt)
            success = true
        end
    end)
    
    if not success then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
            success = true
        end)
    end
    
    return success
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
    Fly              = { enabled = false },
    InfJump          = { enabled = false },
    ESPFlower        = { enabled = false },
    ESPPlayer        = { enabled = false },
    MyPlot           = "1",
    WalkSpeed        = 16,
}

-- ─── Window ───────────────────────────────────────────────────────────────────
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
            ConnectionManager:Cleanup("AutoClaim")
            local thread = task.spawn(function()
                while State.AutoClaim.enabled do
                    safeFireThrottled("ClaimCoins", ClaimCoins, State.AutoClaim.cooldown, "Collect_Coins")
                    task.wait(State.AutoClaim.cooldown)
                end
            end)
            ConnectionManager:RegisterThread("AutoClaim", thread)
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
            ConnectionManager:Cleanup("AutoSell")
            local thread = task.spawn(function()
                while State.AutoSell.enabled do
                    safeInvoke(SellAllFunc)
                    task.wait(5)
                end
            end)
            ConnectionManager:RegisterThread("AutoSell", thread)
        end
    end,
})



-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — 🐝 BEES
-- ══════════════════════════════════════════════════════════════════════════════
local BeesTab = Window:CreateTab("🐝 Bees", 4483362458)

local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}

BeesTab:CreateDropdown({
    Name            = "Target Rarity to Buy",
    Options         = RARITIES,
    CurrentOption   = {"Common"},
    MultipleOptions = true,
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
            ConnectionManager:Cleanup("AutoBuyBee")
            local thread = task.spawn(function()
                while State.AutoBuyBee.enabled do
                    local raritySlotMap = {
                        Common=1, Uncommon=2, Rare=3, Epic=4,
                        Legendary=5, Mythical=6, Secret=7
                    }
                    local base = raritySlotMap[State.AutoBuyBee.rarity]
                    if base then
                        local success = safeFireThrottled("BeeShop", BeeShopEvent, 1.5, "Purchase", {
                            slotIndex = (base * 2) - 1,
                            quantity  = 1,
                        })
                        if success then
                            task.wait(1.5)
                        else
                            task.wait(5)
                        end
                    else
                        task.wait(1.5)
                    end
                end
            end)
            ConnectionManager:RegisterThread("AutoBuyBee", thread)
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
    MultipleOptions = true,
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
            ConnectionManager:Cleanup("AutoConvEgg")
            
            if State.MyPlot == "1" then
                State.MyPlot = getMyPlotId()
                Rayfield:Notify({
                    Title    = "Conveyor Eggs",
                    Content  = "Auto-detected plot: " .. State.MyPlot,
                    Duration = 3,
                })
            end
            
            local thread = task.spawn(function()
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
                                safeFireThrottled("PurchaseConvEgg", PurchaseConvEgg, State.AutoConvEgg.delay, egg.Name, State.MyPlot)
                                task.wait(State.AutoConvEgg.delay or 0.1)
                            end
                        end
                    end
                    task.wait(State.AutoConvEgg.delay or 0.1)
                end
            end)
            ConnectionManager:RegisterThread("AutoConvEgg", thread)
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
            ConnectionManager:Cleanup("AutoHatch")
            local thread = task.spawn(function()
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
                                        fireProximityPrompt(desc)
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoHatch", thread)
        end
    end,
})

EggTab:CreateToggle({
    Name         = "Auto Skip All Eggs",
    CurrentValue = false,
    Flag         = "AutoSkipEggToggle",
    Callback     = function(val)
        if val then
            ConnectionManager:Cleanup("AutoSkipEgg")
            local thread = task.spawn(function()
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
                                        fireProximityPrompt(desc)
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoSkipEgg", thread)
        end
    end,
})



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
        safeFireThrottled("Hammer", HammerEvent, 0.1, flower.Name)
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
            ConnectionManager:Cleanup("AutoPickup")
            local thread = task.spawn(function()
                while State.AutoPickup.enabled do
                    pickupFlowers()
                    task.wait(State.AutoPickup.interval)
                end
            end)
            ConnectionManager:RegisterThread("AutoPickup", thread)
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

FlowersTab:CreateLabel("Equip Shovel First then on this")

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
            ConnectionManager:Cleanup("AutoConveyor")
            local thread = task.spawn(function()
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
                    if bestKey then 
                        safeFireThrottled("HandleConveyor", HandleConveyor, 2, "equip", bestKey)
                    end
                    task.wait(30)
                end
            end)
            ConnectionManager:RegisterThread("AutoConveyor", thread)
        end
    end,
})



-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 6 — 🎪 EVENTS (FIXED ARCADE ORB AND TICKET)
-- ══════════════════════════════════════════════════════════════════════════════
local EventTab = Window:CreateTab("🎪 Events", 4483362458)

-- Automatic Event Notifier (always on - no toggle)
task.spawn(function()
    local knownFolders = {}
    local knownEggs = {}
    
    while true do
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
        
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:match("^EasterEgg_") and not knownEggs[obj.Name] then
                knownEggs[obj.Name] = true
                Rayfield:Notify({
                    Title    = "🥚 Easter Egg Spawned!",
                    Content  = obj.Name .. " has appeared!",
                    Duration = 5,
                })
            end
        end
        
        task.wait(3)
    end
end)

EventTab:CreateSection("🐰 Easter Egg Hunter")

EventTab:CreateToggle({
    Name         = "Auto Collect Easter Eggs",
    CurrentValue = false,
    Flag         = "AutoEasterToggle",
    Callback     = function(val)
        State.AutoEaster.enabled = val
        if val then
            ConnectionManager:Cleanup("AutoEaster")
            local thread = task.spawn(function()
                local collectedEggs = {}
                
                while State.AutoEaster.enabled do
                    local foundEgg = false
                    local targetPrompt = nil
                    local targetPosition = nil
                    
                    -- METHOD 1: Check ReplicatedStorage.Storage.EventPreset.Easter.EggSpawns
                    local easterStorage = RS:FindFirstChild("Storage")
                    if easterStorage then
                        local eventPreset = easterStorage:FindFirstChild("EventPreset")
                        if eventPreset then
                            local easter = eventPreset:FindFirstChild("Easter")
                            if easter then
                                local eggSpawns = easter:FindFirstChild("EggSpawns")
                                if eggSpawns then
                                    for _, spawnPart in ipairs(eggSpawns:GetChildren()) do
                                        if not State.AutoEaster.enabled then break end
                                        
                                        local prompt = spawnPart:FindFirstChildOfClass("ProximityPrompt")
                                        if prompt and prompt.Enabled then
                                            local eggId = spawnPart.Name .. "_" .. (prompt:GetAttribute("EggId") or "0")
                                            if not collectedEggs[eggId] then
                                                targetPrompt = prompt
                                                targetPosition = spawnPart:IsA("BasePart") and spawnPart.Position or spawnPart:GetPivot().Position
                                                foundEgg = true
                                                collectedEggs[eggId] = true
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- METHOD 2: Check workspace for EasterEgg_ models
                    if not foundEgg then
                        for _, obj in ipairs(workspace:GetChildren()) do
                            if not State.AutoEaster.enabled then break end
                            
                            if obj.Name:match("^EasterEgg_") and obj:IsA("Model") then
                                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                if not prompt then
                                    for _, desc in ipairs(obj:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then
                                            prompt = desc
                                            break
                                        end
                                    end
                                end
                                
                                if prompt and prompt.Enabled then
                                    local eggId = obj.Name
                                    if not collectedEggs[eggId] then
                                        targetPrompt = prompt
                                        local primaryPart = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                                        targetPosition = primaryPart and primaryPart.Position
                                        foundEgg = true
                                        collectedEggs[eggId] = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- METHOD 3: Check for any proximity prompts with "Easter" or "Egg" in text
                    if not foundEgg then
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if not State.AutoEaster.enabled then break end
                            
                            if obj:IsA("ProximityPrompt") then
                                local actionText = obj.ActionText:lower()
                                local objName = obj.Parent and obj.Parent.Name:lower() or ""
                                
                                if (actionText:find("easter") or actionText:find("egg") or 
                                    objName:find("easter") or objName:find("egg")) and obj.Enabled then
                                    
                                    local eggId = obj.Parent and obj.Parent:GetFullName() or tostring(obj)
                                    if not collectedEggs[eggId] then
                                        targetPrompt = obj
                                        local part = obj.Parent
                                        if part and part:IsA("BasePart") then
                                            targetPosition = part.Position
                                        elseif part and part:IsA("Model") then
                                            local primary = part.PrimaryPart or part:FindFirstChildOfClass("BasePart")
                                            targetPosition = primary and primary.Position
                                        end
                                        foundEgg = true
                                        collectedEggs[eggId] = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    -- If we found an egg, teleport and collect it
                    if foundEgg and targetPrompt and targetPosition then
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
                            task.wait(0.3)
                            
                            local success = false
                            for attempt = 1, 5 do
                                if not State.AutoEaster.enabled then break end
                                
                                success = fireProximityPrompt(targetPrompt)
                                if success then
                                    Rayfield:Notify({
                                        Title = "🥚 Egg Collected!",
                                        Content = "Successfully collected egg!",
                                        Duration = 2,
                                    })
                                    task.wait(0.5)
                                    break
                                end
                                task.wait(0.2)
                            end
                            
                            if not success then
                                pcall(function()
                                    local collectRemote = RS:FindFirstChild("CollectEgg") or 
                                                         RS:FindFirstChild("EasterCollect")
                                    if not collectRemote then
                                        local eventsFolder = RS:FindFirstChild("Events")
                                        if eventsFolder then
                                            collectRemote = eventsFolder:FindFirstChild("CollectEasterEgg")
                                        end
                                    end
                                    if collectRemote then
                                        collectRemote:FireServer(targetPrompt)
                                    end
                                end)
                            end
                        end
                    end
                    
                    if #collectedEggs > 100 then
                        collectedEggs = {}
                    end
                    
                    task.wait(foundEgg and 0.5 or 2)
                end
            end)
            ConnectionManager:RegisterThread("AutoEaster", thread)
        else
            ConnectionManager:Cleanup("AutoEaster")
        end
    end,
})



EventTab:CreateSection("🕹️ Arcade")

-- Auto Collect Arcade Orbs (FIXED)
EventTab:CreateToggle({
    Name         = "Auto Collect Arcade Orbs",
    CurrentValue = false,
    Flag         = "AutoArcadeOrbToggle",
    Callback     = function(val)
        State.AutoArcadeOrb.enabled = val
        if val then
            ConnectionManager:Cleanup("AutoArcadeOrb")
            local thread = task.spawn(function()
                local collectedOrbs = {}
                
                while State.AutoArcadeOrb.enabled do
                    -- Path: workspace.Events.Arcade.ArcadeSpheres
                    local eventsFolder = workspace:FindFirstChild("Events")
                    local arcade = eventsFolder and eventsFolder:FindFirstChild("Arcade")
                    local arcadeSpheres = arcade and arcade:FindFirstChild("ArcadeSpheres")
                    
                    if arcadeSpheres then
                        for _, orb in ipairs(arcadeSpheres:GetChildren()) do
                            if not State.AutoArcadeOrb.enabled then break end
                            
                            -- Check if orb is named "ArcadeOrb" or similar
                            if orb.Name:lower():find("orb") and not collectedOrbs[orb] then
                                local char = LP.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                local part = orb:IsA("BasePart") and orb or orb:FindFirstChildOfClass("BasePart")
                                
                                if hrp and part and part.Parent then
                                    -- Teleport to orb
                                    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                    task.wait(0.2)
                                    
                                    -- Touch the orb to collect it
                                    firetouchinterest(part, hrp, 0)
                                    firetouchinterest(part, hrp, 1)
                                    
                                    collectedOrbs[orb] = true
                                    Rayfield:Notify({
                                        Title = "🔮 Orb Collected!",
                                        Content = "Orbs collected: " .. #collectedOrbs .. "/10",
                                        Duration = 1.5,
                                    })
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                    
                    -- Clear collected orbs table periodically to prevent memory buildup
                    if #collectedOrbs > 50 then
                        collectedOrbs = {}
                    end
                    
                    task.wait(0.5)
                end
            end)
            ConnectionManager:RegisterThread("AutoArcadeOrb", thread)
        end
    end,
})

-- Auto Collect Arcade Tickets (FIXED)
EventTab:CreateToggle({
    Name         = "Auto Collect Arcade Tickets",
    CurrentValue = false,
    Flag         = "AutoArcadeTicketToggle",
    Callback     = function(val)
        State.AutoArcadeTicket.enabled = val
        if val then
            ConnectionManager:Cleanup("AutoArcadeTicket")
            local thread = task.spawn(function()
                local collectedTickets = {}
                
                while State.AutoArcadeTicket.enabled do
                    local eventsFolder = workspace:FindFirstChild("Events")
                    local arcade = eventsFolder and eventsFolder:FindFirstChild("Arcade")
                    
                    if arcade then
                        -- Look for ticket models or parts
                        for _, obj in ipairs(arcade:GetDescendants()) do
                            if not State.AutoArcadeTicket.enabled then break end
                            
                            -- Check for ticket by name
                            local objName = obj.Name:lower()
                            if (objName:find("ticket") or objName:find("arcadeticket")) and not collectedTickets[obj] then
                                
                                -- Find proximity prompt
                                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                if not prompt and obj.Parent then
                                    prompt = obj.Parent:FindFirstChildOfClass("ProximityPrompt")
                                end
                                
                                if prompt and prompt.Enabled then
                                    local char = LP.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                                    
                                    if hrp and part then
                                        -- Teleport to ticket
                                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                        task.wait(0.3)
                                        
                                        -- Fire proximity prompt
                                        local success = fireProximityPrompt(prompt)
                                        if success then
                                            collectedTickets[obj] = true
                                            Rayfield:Notify({
                                                Title = "🎫 Ticket Collected!",
                                                Content = "Arcade ticket claimed!",
                                                Duration = 2,
                                            })
                                            task.wait(0.5)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Also check workspace directly for any ticket prompts
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if not State.AutoArcadeTicket.enabled then break end
                        
                        if obj:IsA("ProximityPrompt") then
                            local actionText = obj.ActionText:lower()
                            local objName = obj.Parent and obj.Parent.Name:lower() or ""
                            
                            if (actionText:find("ticket") or objName:find("ticket")) and obj.Enabled then
                                if not collectedTickets[obj] then
                                    local char = LP.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                    local part = obj.Parent
                                    
                                    if hrp and part and part:IsA("BasePart") then
                                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                                        task.wait(0.3)
                                        
                                        local success = fireProximityPrompt(obj)
                                        if success then
                                            collectedTickets[obj] = true
                                            Rayfield:Notify({
                                                Title = "🎫 Ticket Collected!",
                                                Content = "Arcade ticket claimed!",
                                                Duration = 2,
                                            })
                                            task.wait(0.5)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Clear collected tickets periodically
                    if #collectedTickets > 20 then
                        collectedTickets = {}
                    end
                    
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoArcadeTicket", thread)
        end
    end,
})

-- Auto Arcade Machine Spin (FIXED)
EventTab:CreateToggle({
    Name         = "Auto Arcade Machine Spin",
    CurrentValue = false,
    Flag         = "AutoArcadeSpinToggle",
    Callback     = function(val)
        State.AutoArcadeSpin.enabled = val
        if val then
            ConnectionManager:Cleanup("AutoArcadeSpin")
            local thread = task.spawn(function()
                while State.AutoArcadeSpin.enabled do
                    local core = workspace:FindFirstChild("Core")
                    local scriptable = core and core:FindFirstChild("Scriptable")
                    local others = scriptable and scriptable:FindFirstChild("Others")
                    local machine = others and others:FindFirstChild("ArcadeMachine")
                    
                    -- Find the spin prompt
                    local prompt = nil
                    if machine then
                        prompt = machine:FindFirstChildOfClass("ProximityPrompt")
                        if not prompt then
                            for _, desc in ipairs(machine:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") then
                                    prompt = desc
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Alternative path: TouchParts
                    if not prompt then
                        local touchParts = scriptable and scriptable:FindFirstChild("TouchParts")
                        local proxPart = touchParts and touchParts:FindFirstChild("ArcadeProximityPart")
                        prompt = proxPart and proxPart:FindFirstChild("ArcadePrompt")
                    end
                    
                    if prompt and prompt.Enabled then
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local targetPos = nil
                            if machine then
                                local machinePart = machine:FindFirstChildOfClass("BasePart") or machine.PrimaryPart
                                if machinePart then
                                    targetPos = machinePart.Position + Vector3.new(0, 3, 4)
                                end
                            elseif prompt.Parent and prompt.Parent:IsA("BasePart") then
                                targetPos = prompt.Parent.Position + Vector3.new(0, 3, 2)
                            end
                            
                            if targetPos then
                                hrp.CFrame = CFrame.new(targetPos)
                                task.wait(0.3)
                            end
                        end
                        
                        local success = fireProximityPrompt(prompt)
                        if success then
                            Rayfield:Notify({
                                Title = "🎰 Arcade Spin!",
                                Content = "Machine activated!",
                                Duration = 2,
                            })
                        end
                        task.wait(4)
                    else
                        task.wait(2)
                    end
                    
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoArcadeSpin", thread)
        end
    end,
})



-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 7 — ⚡ PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("⚡ Player", 4483362458)

-- ─── Walk Speed (Heartbeat) ───────────────────────────────────────────────────
local walkSpeedConn = nil

PlayerTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 500},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 16,
    Flag         = "WalkSpeedSlider",
    Callback     = function(val)
        State.WalkSpeed = val
        -- Disconnect old heartbeat if exists
        if walkSpeedConn then
            walkSpeedConn:Disconnect()
            walkSpeedConn = nil
        end
        if val > 16 then
            walkSpeedConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = State.WalkSpeed
                end
            end)
        else
            -- Reset to default
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

-- ─── Infinite Jump ────────────────────────────────────────────────────────────
local jumpConn = nil

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJumpToggle",
    Callback     = function(val)
        State.InfJump.enabled = val

        -- Always disconnect first
        if jumpConn then
            jumpConn:Disconnect()
            jumpConn = nil
        end

        if val then
            jumpConn = UserInput.JumpRequest:Connect(function()
                local char = LP.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum and State.InfJump.enabled then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end,
})

-- ─── Fly ──────────────────────────────────────────────────────────────────────
local flyConn = nil
local flyActive = false
local flySpeed = 1
local bg = nil
local bv = nil

local function stopFly()
    flyActive = false
    State.Fly.enabled = false
    
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    
    if bg then
        bg:Destroy()
        bg = nil
    end
    if bv then
        bv:Destroy()
        bv = nil
    end
    
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Flying, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
        if char:FindFirstChild("Animate") then
            char.Animate.Disabled = false
        end
    end
end

local function startFly()
    local char = LP.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    flyActive = true
    State.Fly.enabled = true
    
    -- Disable all humanoid states
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    
    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = true
    end
    
    -- Stop all animations
    for _, v in ipairs(hum:GetPlayingAnimationTracks()) do
        v:AdjustSpeed(0)
    end
    
    -- Movement using TranslateBy (works with mobile joystick)
    local hb = RunService.Heartbeat
    flyConn = hb:Connect(function()
        if not flyActive then return end
        
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not h then
            stopFly()
            return
        end
        
        -- Use TranslateBy for movement (works with MoveDirection from mobile joystick)
        if h.MoveDirection.Magnitude > 0 then
            for i = 1, flySpeed do
                c:TranslateBy(h.MoveDirection * 0.5) -- Reduced multiplier for smoother movement
            end
        end
        
        -- Handle vertical movement with Space and LeftControl
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local verticalMove = 0
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then
                verticalMove = 2
            elseif UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
                verticalMove = -2
            end
            if verticalMove ~= 0 then
                c:TranslateBy(Vector3.new(0, verticalMove, 0) * 0.3)
            end
        end
    end)
    
    return true
end

PlayerTab:CreateToggle({
    Name         = "Fly",
    CurrentValue = false,
    Flag         = "FlyToggle",
    Callback     = function(val)
        if val then
            stopFly() -- Clean up any existing fly first
            
            if not LP.Character then
                LP.CharacterAdded:Wait()
            end
            
            local success = startFly()
            if not success then
                Rayfield:Notify({
                    Title = "Fly Error",
                    Content = "Failed to start fly. Try again.",
                    Duration = 2,
                })
            else
                Rayfield:Notify({
                    Title = "Fly Enabled",
                    Content = "Use joystick/WASD to move. Space/LCtrl for up/down.",
                    Duration = 3,
                })
            end
        else
            stopFly()
        end
    end,
})

-- Fly Speed Control
PlayerTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {1, 10},
    Increment    = 1,
    Suffix       = "x",
    CurrentValue = 1,
    Flag         = "FlySpeedSlider",
    Callback     = function(val)
        flySpeed = val
    end,
})

-- Handle character respawn
LP.CharacterAdded:Connect(function(char)
    if flyActive then
        stopFly()
        task.wait(0.5)
        startFly()
    end
end)

-- Clean up on death
LP.CharacterRemoving:Connect(function()
    if flyActive then
        stopFly()
    end
end)



-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 8 — 🔍 ESP
-- ══════════════════════════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("🔍 ESP", 4483362458)

local espBillboards = {}
local flowerESP = {}
local playerESP = {}

local function clearESP()
    for _, bb in pairs(espBillboards) do
        pcall(function() bb:Destroy() end)
    end
    espBillboards = {}
    flowerESP = {}
    playerESP = {}
end

local function createBillboard(adornee, text, color)
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.new(0, 80, 0, 20)
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
    label.TextSize               = 11
    label.TextScaled             = false
    label.Parent                 = bb

    table.insert(espBillboards, bb)
    return bb
end

ESPTab:CreateToggle({
    Name         = "Flower ESP",
    CurrentValue = false,
    Flag         = "FlowerESPToggle",
    Callback     = function(val)
        State.ESPFlower.enabled = val
        if not val then
            for _, bb in pairs(flowerESP) do
                pcall(function() bb:Destroy() end)
            end
            flowerESP = {}
            return
        end
        
        ConnectionManager:Cleanup("FlowerESP")
        local thread = task.spawn(function()
            while State.ESPFlower.enabled do
                local currentFlowers = {}
                
                for _, plot in ipairs(Plots:GetChildren()) do
                    local placedItems = plot:FindFirstChild("PlacedItems")
                    if placedItems then
                        for _, item in ipairs(placedItems:GetChildren()) do
                            if item:GetAttribute("ItemType") == "Flower" then
                                local part = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                if part then
                                    local flowerName = item:GetAttribute("BaseName") or item:GetAttribute("baseName") or "Unknown"
                                    currentFlowers[part] = flowerName
                                end
                            end
                        end
                    end
                end
                
                for part, bb in pairs(flowerESP) do
                    if not currentFlowers[part] then
                        pcall(function() bb:Destroy() end)
                        flowerESP[part] = nil
                    end
                end
                
                for part, name in pairs(currentFlowers) do
                    if not flowerESP[part] then
                        flowerESP[part] = createBillboard(part, name, Color3.fromRGB(255, 100, 200))
                        table.insert(espBillboards, flowerESP[part])
                    end
                end
                
                task.wait(1)
            end
        end)
        ConnectionManager:RegisterThread("FlowerESP", thread)
    end,
})

ESPTab:CreateToggle({
    Name         = "Player ESP",
    CurrentValue = false,
    Flag         = "PlayerESPToggle",
    Callback     = function(val)
        State.ESPPlayer.enabled = val
        if not val then
            for _, bb in pairs(playerESP) do
                pcall(function() bb:Destroy() end)
            end
            playerESP = {}
            return
        end
        
        ConnectionManager:Cleanup("PlayerESP")
        local thread = task.spawn(function()
            while State.ESPPlayer.enabled do
                local currentPlayers = {}
                
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LP then
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
                            currentPlayers[hrp] = {name = player.Name, dist = dist}
                        end
                    end
                end
                
                for hrp, bb in pairs(playerESP) do
                    if not currentPlayers[hrp] then
                        pcall(function() bb:Destroy() end)
                        playerESP[hrp] = nil
                    else
                        local data = currentPlayers[hrp]
                        local label = bb:FindFirstChildOfClass("TextLabel")
                        if label then
                            label.Text = data.name .. " " .. data.dist .. "m"
                        end
                    end
                end
                
                for hrp, data in pairs(currentPlayers) do
                    if not playerESP[hrp] then
                        playerESP[hrp] = createBillboard(hrp, data.name .. " " .. data.dist .. "m", Color3.fromRGB(255, 220, 50))
                        table.insert(espBillboards, playerESP[hrp])
                    end
                end
                
                task.wait(0.5)
            end
        end)
        ConnectionManager:RegisterThread("PlayerESP", thread)
    end,
})


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
        
        ConnectionManager:CleanupAll()
        
        clearESP()
        
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end
        
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        
        Rayfield:Notify({ Title="Stopped", Content="All features disabled.", Duration=3 })
    end,
})

-- ─── Startup ──────────────────────────────────────────────────────────────────
Rayfield:Notify({
    Title    = "🐝 Bee Garden Script by Dwine",
    Content  = "Loaded! Economy · Bees · Eggs · Flowers · Conveyor · Events · Player · ESP · Misc",
    Duration = 6,
    Image    = 4483362458,
})

