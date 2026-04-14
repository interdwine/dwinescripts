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

-- ══════════════════════════════════════════════════════════════════════════════
-- DATA SECTION
-- ══════════════════════════════════════════════════════════════════════════════

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

-- ─── Bee Rarities ─────────────────────────────────────────────────────────────
local BEE_RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}

-- ─── Complete Flower List ─────────────────────────────────────────────────────
local FLOWER_LIST = {
    -- Common (9)
    "Daisy", "Camellia", "Iris", "Pansy", "Tulip", "Thistle", "Snowdrop", "Pinkbells", "Lobelia",
    -- Uncommon (12)
    "Cornflower", "Lily", "Pomeflower", "Succulent", "BellFlower", "ZombeeFlower", "SpiderLilly", "CrystalizedPetal", "Patapim", "Snowpuff", "TetrisFlower", "EggBell",
    -- Rare (11)
    "Dandelion", "Sunflower", "Cactus", "Frostbloom", "Voidbloom", "UnicornPetunia", "Ballerina", "Mistletoe", "PixelDaisy", "EasterBamboo", "IcecapBloom",
    -- Epic (17)
    "KittyTowerFlower", "Nuzwat", "Orchid", "ZebraFlower", "Whitenight", "CyberFlower", "EmberSpark", "Sahur", "MeanFlower", "HappySunflower", "PastelRose", "BorealBell", "RadianceLily", "WinterRose", "EclipseBloom", "LanternPlant", "RedEye",
    -- Legendary (17)
    "Glacierheart", "Rose", "DesertWildFlower", "BugEater", "Ghostflower", "IvoryIris", "OceanBloom", "Assassino", "Gingerbread", "Sword", "Nightshade", "PolarSpire", "Lightbloom", "Hellebore", "MoonlaceOrchid", "FairyTulip", "MushroomSpore",
    -- Mythical (24)
    "CrystalDaisy", "GlowBerry", "DragonFlower", "Bamboo", "Snapdragon", "CrimsonWidow", "Crystalflower", "BubbleLotus", "Bombardiro", "SixSeven", "HackerFlower", "HappyBunny", "Elf", "ShimmeringLichen", "Sunpetal", "HaloOrchid", "FrostLily", "HollyBloom", "NebulaRose", "SolarIris", "FairyWings", "StarBell", "JellyPads", "Monsterbloom",
    -- Secret (9)
    "TwilightAmarilis", "FrostburnRose", "DarkflareRose", "Gleamblossom", "PoinsettiaBlossom", "Starpetal", "FairyQueentessa", "UfoFlower", "TriEye",
    -- Premium (28)
    "Trallalero", "LaVaca", "StrawberryElephant", "Reindeer", "Santa", "SnowyTree", "StarfallFlower", "DualityFlower", "DualityRose", "DualityDuskbloom", "DualityEclipse", "Flamepetal", "BlazeburstLotus", "Beenspector", "PacmanFlower", "NyanCat", "GlitchFlower", "Mafioso", "RedStar", "MeteorFlower", "Ghostleaf", "MantisReaper", "GrayScale", "CellShade", "SleepyBunny", "EasterBunny", "SpringBlossom", "AdminEye",
    -- Divine (14)
    "Sunfloris", "Rosaris", "Helios", "Lunaris", "Aetheris", "Noctyra", "Jellythys", "Cybaris", "Venomyx", "Stellaris", "Coreflare", "Frostwyrm", "Cryonix", "Pyronis",
    -- Premium Divine (6)
    "Verdantis", "Infernyx", "Velkrya", "Draconyx", "Aracnid", "Paradoxys"
}

-- Sort flower list
table.sort(FLOWER_LIST)

-- ─── Build Dropdown Options ───────────────────────────────────────────────────
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

local FLOWER_OPTIONS = {"Any"}
for _, flower in ipairs(FLOWER_LIST) do
    table.insert(FLOWER_OPTIONS, flower)
end

-- ─── Conveyor List ────────────────────────────────────────────────────────────
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

-- ══════════════════════════════════════════════════════════════════════════════
-- SYSTEMS
-- ══════════════════════════════════════════════════════════════════════════════

-- ─── Connection Management System ─────────────────────────────────────────────
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

-- ─── Remote Throttling System ─────────────────────────────────────────────────
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

-- ─── Safe Remote Functions ────────────────────────────────────────────────────
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

-- ─── Helper Functions ─────────────────────────────────────────────────────────
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
    AutoClaim        = { enabled = false, threshold = 80, checkInterval = 5 },
    AutoBuyBee       = { enabled = false, selectedRarities = {"Common"} },
    AutoHatch        = { enabled = false },
    AutoPickup       = { enabled = false, interval = 1, selectedFlowers = {"Any"} },
    AutoConvEgg      = { enabled = false, delay = 0.1, selectedOptions = {"Any"} },
    AutoConveyor     = { enabled = false },
    AutoSell         = { enabled = false },
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
    LoadingSubtitle        = "Loading by Dwine...",
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

-- Auto Claim when Honey Pot reaches percentage
EconTab:CreateToggle({
    Name         = "Auto Claim Coins",
    CurrentValue = false,
    Flag         = "AutoClaimToggle",
    Callback     = function(val)
        State.AutoClaim.enabled = val
        if val then
            ConnectionManager:Cleanup("AutoClaim")
            local thread = task.spawn(function()
                local lastClaimed = false
                
                while State.AutoClaim.enabled do
                    local myPlotId = State.MyPlot
                    if myPlotId == "1" then
                        myPlotId = getMyPlotId()
                        State.MyPlot = myPlotId
                    end
                    
                    local plot = Plots:FindFirstChild(myPlotId)
                    if plot then
                        local honeyPot = plot:FindFirstChild("HoneyPot")
                        if honeyPot then
                            local fillPercentage = honeyPot:GetAttribute("FillPercentage") or 0
                            
                            if fillPercentage >= State.AutoClaim.threshold and not lastClaimed then
                                safeFireThrottled("ClaimCoins", ClaimCoins, 2, "Collect_Coins")
                                Rayfield:Notify({
                                    Title = "💰 Coins Claimed!",
                                    Content = "Honey Pot was at " .. fillPercentage .. "%",
                                    Duration = 2,
                                })
                                lastClaimed = true
                            elseif fillPercentage < State.AutoClaim.threshold then
                                lastClaimed = false
                            end
                        end
                    end
                    
                    task.wait(State.AutoClaim.checkInterval)
                end
            end)
            ConnectionManager:RegisterThread("AutoClaim", thread)
        end
    end,
})

EconTab:CreateSlider({
    Name         = "Claim at Percentage",
    Range        = {1, 100},
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = 80,
    Flag         = "ClaimThreshold",
    Callback     = function(val)
        State.AutoClaim.threshold = val
    end,
})

EconTab:CreateSlider({
    Name         = "Check Interval",
    Range        = {1, 30},
    Increment    = 1,
    Suffix       = "s",
    CurrentValue = 5,
    Flag         = "ClaimCheckInterval",
    Callback     = function(val)
        State.AutoClaim.checkInterval = val
    end,
})

EconTab:CreateDivider()

EconTab:CreateButton({
    Name     = "Check Honey Pot Status",
    Callback = function()
        local myPlotId = State.MyPlot
        if myPlotId == "1" then
            myPlotId = getMyPlotId()
            State.MyPlot = myPlotId
        end
        
        local plot = Plots:FindFirstChild(myPlotId)
        if plot then
            local honeyPot = plot:FindFirstChild("HoneyPot")
            if honeyPot then
                local fillPercentage = honeyPot:GetAttribute("FillPercentage") or 0
                local maxCapacity = honeyPot:GetAttribute("MaxCapacity") or 0
                local currentCoins = honeyPot:GetAttribute("CurrentCoins") or 0
                
                Rayfield:Notify({
                    Title = "🍯 Honey Pot Status",
                    Content = string.format("Fill: %d%% | Coins: %d/%d", fillPercentage, currentCoins, maxCapacity),
                    Duration = 5,
                })
            else
                Rayfield:Notify({
                    Title = "❌ Error",
                    Content = "Honey Pot not found on your plot!",
                    Duration = 3,
                })
            end
        end
    end,
})

EconTab:CreateButton({
    Name     = "💰 Claim Now",
    Callback = function()
        safeFire(ClaimCoins, "Collect_Coins")
        Rayfield:Notify({
            Title = "💰 Claiming",
            Content = "Attempting to claim coins...",
            Duration = 2,
        })
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

EconTab:CreateLabel("Auto Claim checks Honey Pot FillPercentage and claims once when threshold is reached.")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — 🐝 BEES
-- ══════════════════════════════════════════════════════════════════════════════
local BeesTab = Window:CreateTab("🐝 Bees", 4483362458)

BeesTab:CreateDropdown({
    Name            = "Target Rarity to Buy",
    Options         = BEE_RARITIES,
    CurrentOption   = {"Common"},
    MultipleOptions = true,
    Flag            = "BeeRarityDropdown",
    Callback        = function(sel)
        State.AutoBuyBee.selectedRarities = sel or {"Common"}
        local count = #State.AutoBuyBee.selectedRarities
        Rayfield:Notify({
            Title = "Bee Rarities",
            Content = "Selected " .. count .. " rarit" .. (count == 1 and "y" or "ies"),
            Duration = 2,
        })
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
                local raritySlotMap = {
                    Common=1, Uncommon=2, Rare=3, Epic=4,
                    Legendary=5, Mythical=6, Secret=7
                }
                
                while State.AutoBuyBee.enabled do
                    local selectedRarities = State.AutoBuyBee.selectedRarities
                    
                    if selectedRarities and #selectedRarities > 0 then
                        for _, rarity in ipairs(selectedRarities) do
                            if not State.AutoBuyBee.enabled then break end
                            
                            local base = raritySlotMap[rarity]
                            if base then
                                local success = safeFireThrottled("BeeShop_" .. rarity, BeeShopEvent, 1.5, "Purchase", {
                                    slotIndex = (base * 2) - 1,
                                    quantity  = 1,
                                })
                                
                                if success then
                                    Rayfield:Notify({
                                        Title = "🐝 Bee Purchased",
                                        Content = "Bought " .. rarity .. " bee!",
                                        Duration = 1.5,
                                    })
                                end
                                task.wait(1.5)
                            end
                        end
                    else
                        task.wait(2)
                    end
                    task.wait(1)
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
        State.AutoConvEgg.selectedOptions = sel or {"Any"}
        local count = #State.AutoConvEgg.selectedOptions
        Rayfield:Notify({
            Title = "Egg Filters",
            Content = "Selected " .. count .. " filter" .. (count == 1 and "" or "s"),
            Duration = 2,
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
                        local selectedOptions = State.AutoConvEgg.selectedOptions or {"Any"}
                        
                        for _, egg in pairs(eggsFolder:GetChildren()) do
                            if not State.AutoConvEgg.enabled then break end
                            
                            local shouldBuy = false
                            
                            for _, option in ipairs(selectedOptions) do
                                if option == "Any" then
                                    shouldBuy = true
                                    break
                                end
                            end
                            
                            if not shouldBuy then
                                local baseName = egg:GetAttribute("baseName")
                                if baseName then
                                    for _, option in ipairs(selectedOptions) do
                                        local targetBase = EGG_OPTION_TO_BASENAME[option]
                                        if targetBase and baseName == targetBase then
                                            shouldBuy = true
                                            break
                                        end
                                    end
                                end
                            end
                            
                            if shouldBuy then
                                safeFireThrottled("PurchaseConvEgg", PurchaseConvEgg, State.AutoConvEgg.delay, egg.Name, State.MyPlot)
                                task.wait(State.AutoConvEgg.delay or 0.1)
                            end
                        end
                    end
                    task.wait(State.AutoConvEgg.delay or 0.5)
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
                    local myPlotId = State.MyPlot
                    if myPlotId == "1" then
                        myPlotId = getMyPlotId()
                        State.MyPlot = myPlotId
                    end
                    
                    local plot = Plots:FindFirstChild(myPlotId)
                    if plot then
                        local placedItems = plot:FindFirstChild("PlacedItems")
                        if placedItems then
                            for _, item in ipairs(placedItems:GetChildren()) do
                                if not State.AutoHatch.enabled then break end
                                
                                -- Check if item is an Egg
                                if item:GetAttribute("ItemType") == "Egg" then
                                    -- Find ProximityPrompt and check PromptType
                                    local prompt = nil
                                    for _, desc in ipairs(item:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then
                                            prompt = desc
                                            break
                                        end
                                    end
                                    
                                    -- Only hatch if PromptType is "egg_ready"
                                    if prompt then
                                        local promptType = prompt:GetAttribute("PromptType")
                                        if promptType == "egg_ready" then
                                            local char = LP.Character
                                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                            local primaryPart = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                            
                                            if hrp and primaryPart then
                                                -- Teleport to egg
                                                hrp.CFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
                                                task.wait(0.3)
                                                
                                                -- Fire the prompt
                                                if fireProximityPrompt(prompt) then
                                                    Rayfield:Notify({
                                                        Title = "🥚 Egg Hatched!",
                                                        Content = "Egg is ready and hatched!",
                                                        Duration = 2,
                                                    })
                                                end
                                                task.wait(0.5)
                                            end
                                        end
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

FlowersTab:CreateDropdown({
    Name            = "Select Flowers to Pickup",
    Options         = FLOWER_OPTIONS,
    CurrentOption   = {"Any"},
    MultipleOptions = true,
    Flag            = "FlowerDropdown",
    Callback        = function(sel)
        State.AutoPickup.selectedFlowers = sel or {"Any"}
        local count = #State.AutoPickup.selectedFlowers
        Rayfield:Notify({
            Title = "Flower Filter",
            Content = "Selected " .. count .. " flower type" .. (count == 1 and "" or "s"),
            Duration = 2,
        })
    end,
})

local function pickupFlowers()
    local plot = getPlot()
    if not plot then return end
    local placedItems = plot:FindFirstChild("PlacedItems")
    if not placedItems then return end
    
    local flowers = {}
    local selectedFlowers = State.AutoPickup.selectedFlowers or {"Any"}
    local pickupAny = false
    
    for _, sel in ipairs(selectedFlowers) do
        if sel == "Any" then
            pickupAny = true
            break
        end
    end
    
    for _, item in ipairs(placedItems:GetChildren()) do
        if item:GetAttribute("ItemType") == "Flower" then
            local baseName = item:GetAttribute("BaseName") or item:GetAttribute("baseName") or "Unknown"
            
            local shouldPickup = pickupAny
            if not shouldPickup then
                for _, sel in ipairs(selectedFlowers) do
                    if baseName == sel then
                        shouldPickup = true
                        break
                    end
                end
            end
            
            if shouldPickup then
                table.insert(flowers, item)
            end
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

FlowersTab:CreateLabel("Total: " .. #FLOWER_LIST .. " flower types available")

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 5 — 👑 CONVEYOR
-- ══════════════════════════════════════════════════════════════════════════════
local ConveyorTab = Window:CreateTab("👑 Conveyor", 4483362458)

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
-- TAB 6 — ⚡ PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("⚡ Player", 4483362458)

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
        if walkSpeedConn then
            walkSpeedConn:Disconnect()
            walkSpeedConn = nil
        end
        if val > 16 then
            walkSpeedConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = State.WalkSpeed end
            end)
        else
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

local jumpConn = nil

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJumpToggle",
    Callback     = function(val)
        State.InfJump.enabled = val
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

local flyConn = nil
local flyActive = false
local flySpeed = 1

local function stopFly()
    flyActive = false
    State.Fly.enabled = false
    
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            for _, state in ipairs({
                Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
                Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
                Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
                Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
                Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
                Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
                Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
                Enum.HumanoidStateType.Swimming
            }) do
                hum:SetStateEnabled(state, true)
            end
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
    
    for _, state in ipairs({
        Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
        Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
        Enum.HumanoidStateType.Swimming
    }) do
        hum:SetStateEnabled(state, false)
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    
    if char:FindFirstChild("Animate") then
        char.Animate.Disabled = true
    end
    
    for _, v in ipairs(hum:GetPlayingAnimationTracks()) do
        v:AdjustSpeed(0)
    end
    
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyActive then return end
        
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not h then stopFly(); return end
        
        if h.MoveDirection.Magnitude > 0 then
            for i = 1, flySpeed do
                c:TranslateBy(h.MoveDirection * 0.5)
            end
        end
        
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
            stopFly()
            if not LP.Character then LP.CharacterAdded:Wait() end
            startFly()
        else
            stopFly()
        end
    end,
})

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

LP.CharacterAdded:Connect(function()
    if flyActive then stopFly(); task.wait(0.5); startFly() end
end)

LP.CharacterRemoving:Connect(function()
    if flyActive then stopFly() end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 7 — 🔍 ESP
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
            for _, bb in pairs(flowerESP) do pcall(function() bb:Destroy() end) end
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
                                    currentFlowers[part] = item:GetAttribute("BaseName") or item:GetAttribute("baseName") or "Unknown"
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
            for _, bb in pairs(playerESP) do pcall(function() bb:Destroy() end) end
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
-- TAB 8 — 🏪 MISC
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
        Rayfield:Notify({ Title="Server Hop", Content="Searching...", Duration=2 })
        task.spawn(function()
            local placeId, currentId = game.PlaceId, game.JobId
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            local lowest, lowestPop = nil, math.huge
            local cursor, searched, maxPages = nil, 0, 3
            
            repeat
                local fullUrl = url .. (cursor and ("&cursor=" .. cursor) or "")
                local ok, result = pcall(function() return HttpService:JSONDecode(game:HttpGet(fullUrl)) end)
                if not ok or not result or not result.data then break end
                
                for _, server in ipairs(result.data) do
                    if server.id ~= currentId and type(server.playing) == "number" and server.playing < lowestPop and server.playing > 0 then
                        lowestPop, lowest = server.playing, server.id
                    end
                end
                cursor, searched = result.nextPageCursor, searched + 1
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
-- TAB 9 — ⛔ STOP ALL
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
        stopFly()
        if walkSpeedConn then walkSpeedConn:Disconnect(); walkSpeedConn = nil end
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false; hum.WalkSpeed = 16 end
        
        Rayfield:Notify({ Title="Stopped", Content="All features disabled.", Duration=3 })
    end,
})

-- ─── Startup ──────────────────────────────────────────────────────────────────
Rayfield:Notify({
    Title    = "🐝 Bee Garden Script by Dwine",
    Content  = "Loaded! Economy · Bees · Eggs · Flowers · Conveyor · Player · ESP · Misc",
    Duration = 6,
    Image    = 4483362458,
})
