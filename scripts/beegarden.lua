-- Bee Garden Auto Farm - WindUI Edition (Complete)
if not game:IsLoaded() then game.Loaded:Wait() end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then warn("WindUI failed") return end

-- ─── Services ─────────────────────────────────────────────────────────────────
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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
    local function getModelPosition(model)
    if not model then return nil end
    if model:IsA("Model") then
        local primary = model.PrimaryPart
        if primary then return primary.Position end
        local part = model:FindFirstChildOfClass("BasePart")
        if part then return part.Position end
    elseif model:IsA("BasePart") then
        return model.Position
    end
    return nil
end

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tweenTo(position)
    if not position then return false end
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetPos = position + Vector3.new(0, 3, 0)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    task.wait(0.6)
    return true
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
    AutoEasterEgg   = false,
    AutoSnowflake   = false,
    AutoMeteoron    = false,
    MyPlot           = "1",
    WalkSpeed        = 16,   
}

-- ══════════════════════════════════════════════════════════════════════════════
-- WINDOW CREATION
-- ══════════════════════════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "🐝 Bee Garden",
    Icon = "bee",
    Author = "by Dwine",
    Folder = "BeeGarden",
    Size = UDim2.fromOffset(650, 480),
    MinSize = Vector2.new(560, 400),
    MaxSize = Vector2.new(850, 600),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function() end,
    },
})

Window:EditOpenButton({
    Title = "🐝 Open",
    Icon = "bee",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FFD700"),
        Color3.fromHex("FFA500")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "v1.0.0",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 6,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 1 — 💰 ECONOMY
-- ══════════════════════════════════════════════════════════════════════════════
local Tab = Window:Tab({ Title = "Economy", Icon = "coins" })

Tab:Section({ Title = "Auto Claim", Opened = true })

Tab:Toggle({
    Title = "Auto Claim Coins",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        State.AutoClaim.enabled = v
        if v then
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
                                WindUI:Notify({ Title = "💰 Coins Claimed!", Content = "Honey Pot was at " .. fillPercentage .. "%", Duration = 2, Icon = "check-circle" })
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
    end
})

Tab:Slider({
    Title = "Claim at Percentage",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 80 },
    Callback = function(v) State.AutoClaim.threshold = v end
})

Tab:Slider({
    Title = "Check Interval",
    Step = 1,
    Value = { Min = 1, Max = 30, Default = 5 },
    Callback = function(v) State.AutoClaim.checkInterval = v end
})

Tab:Divider()

Tab:Button({
    Title = "Check Honey Pot Status",
    Desc = "View current fill and coins",
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
                local fill = honeyPot:GetAttribute("FillPercentage") or 0
                local max = honeyPot:GetAttribute("MaxCapacity") or 0
                local cur = honeyPot:GetAttribute("CurrentCoins") or 0
                WindUI:Notify({ Title = "🍯 Honey Pot", Content = string.format("Fill: %d%% | Coins: %d/%d", fill, cur, max), Duration = 5, Icon = "info" })
            else
                WindUI:Notify({ Title = "❌ Error", Content = "Honey Pot not found on your plot!", Duration = 3, Icon = "alert-triangle" })
            end
        end
    end
})

Tab:Button({
    Title = "💰 Claim Now",
    Desc = "Force claim coins",
    Callback = function()
        safeFire(ClaimCoins, "Collect_Coins")
        WindUI:Notify({ Title = "💰 Claiming", Content = "Attempting to claim coins...", Duration = 2, Icon = "coins" })
    end
})

Tab:Divider()

Tab:Toggle({
    Title = "Auto Sell All Flowers",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        State.AutoSell.enabled = v
        if v then
            ConnectionManager:Cleanup("AutoSell")
            local thread = task.spawn(function()
                while State.AutoSell.enabled do
                    safeInvoke(SellAllFunc)
                    task.wait(5)
                end
            end)
            ConnectionManager:RegisterThread("AutoSell", thread)
        end
    end
})

Tab:Paragraph({ Title = "Auto Claim checks Honey Pot FillPercentage and claims once when threshold is reached.", Desc = "" })

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 2 — 🐝 BEES
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Bees", Icon = "bug" })

Tab:Dropdown({
    Title = "Target Rarity to Buy",
    Values = BEE_RARITIES,
    Value = {"Common"},
    Multi = true,
    AllowNone = false,
    Callback = function(sel)
        State.AutoBuyBee.selectedRarities = sel
        local count = #sel
        WindUI:Notify({ Title = "Bee Rarities", Content = "Selected " .. count .. " rarit" .. (count==1 and "y" or "ies"), Duration = 2, Icon = "check" })
    end
})

Tab:Toggle({
    Title = "Auto Buy Bee",
    Type = "Checkbox",
    Value = false,
    Callback = function(v)
        State.AutoBuyBee.enabled = v
        if v then
            ConnectionManager:Cleanup("AutoBuyBee")
            local thread = task.spawn(function()
                local raritySlotMap = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythical=6, Secret=7 }
                while State.AutoBuyBee.enabled do
                    for _, rarity in ipairs(State.AutoBuyBee.selectedRarities) do
                        if not State.AutoBuyBee.enabled then break end
                        local base = raritySlotMap[rarity]
                        if base then
                            local success = safeFireThrottled("BeeShop_"..rarity, BeeShopEvent, 1.5, "Purchase", { slotIndex = (base*2)-1, quantity = 1 })
                            if success then
                                WindUI:Notify({ Title = "🐝 Bee Purchased", Content = "Bought "..rarity.." bee!", Duration = 1.5, Icon = "shopping-cart" })
                            end
                            task.wait(1.5)
                        end
                    end
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoBuyBee", thread)
        end
    end
})

Tab:Divider()

Tab:Button({
    Title = "Equip Best Bees",
    Callback = function()
        pcall(function() BeeHandler:InvokeServer(getClient()) end)
        WindUI:Notify({ Title = "Bees", Content = "Equipping best bees!", Duration = 3, Icon = "zap" })
    end
})

Tab:Button({
    Title = "Unequip All Bees",
    Callback = function()
        pcall(function() BeeHandler:InvokeServer(getClient()) end)
        WindUI:Notify({ Title = "Bees", Content = "Unequipping all bees!", Duration = 3, Icon = "zap-off" })
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 3 — 🥚 EGGS
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Eggs", Icon = "egg" })

Tab:Button({
    Title = "Auto-Detect My Plot",
    Callback = function()
        State.MyPlot = getMyPlotId()
        WindUI:Notify({ Title = "Plot Detected", Content = "Targeting Plot: "..State.MyPlot, Duration = 3, Icon = "map-pin" })
    end
})

Tab:Dropdown({
    Title = "Conveyor Egg Filter",
    Values = EGG_DROPDOWN_OPTIONS,
    Value = {"Any"},
    Multi = true,
    Callback = function(sel)
        State.AutoConvEgg.selectedOptions = sel
        WindUI:Notify({ Title = "Egg Filters", Content = "Selected "..#sel.." filter(s)", Duration = 2 })
    end
})

Tab:Slider({
    Title = "Buy Delay (seconds)",
    Step = 0.1,
    Value = { Min = 0.1, Max = 10, Default = 0.1 },
    Callback = function(v) State.AutoConvEgg.delay = v end
})

Tab:Toggle({
    Title = "Auto Buy Conveyor Eggs",
    Value = false,
    Callback = function(v)
        State.AutoConvEgg.enabled = v
        if v then
            ConnectionManager:Cleanup("AutoConvEgg")
            if State.MyPlot == "1" then
                State.MyPlot = getMyPlotId()
            end
            local thread = task.spawn(function()
                while State.AutoConvEgg.enabled do
                    local plotFolder = Plots:FindFirstChild(State.MyPlot)
                    local eggsFolder = plotFolder and plotFolder:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in pairs(eggsFolder:GetChildren()) do
                            if not State.AutoConvEgg.enabled then break end
                            local shouldBuy = false
                            for _, opt in ipairs(State.AutoConvEgg.selectedOptions) do
                                if opt == "Any" then shouldBuy = true; break end
                            end
                            if not shouldBuy then
                                local baseName = egg:GetAttribute("baseName")
                                if baseName then
                                    for _, opt in ipairs(State.AutoConvEgg.selectedOptions) do
                                        local targetBase = EGG_OPTION_TO_BASENAME[opt]
                                        if targetBase and baseName == targetBase then shouldBuy = true; break end
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
    end
})

Tab:Divider()

Tab:Toggle({
    Title = "Auto Hatch Eggs",
    Value = false,
    Callback = function(v)
        State.AutoHatch.enabled = v
        if v then
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
                                if item:GetAttribute("ItemType") == "Egg" then
                                    local prompt = nil
                                    for _, desc in ipairs(item:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then prompt = desc; break end
                                    end
                                    if prompt and prompt:GetAttribute("PromptType") == "egg_ready" then
                                        local char = LP.Character
                                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                        local primaryPart = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                        if hrp and primaryPart then
                                            hrp.CFrame = primaryPart.CFrame + Vector3.new(0,3,0)
                                            task.wait(0.3)
                                            if fireProximityPrompt(prompt) then
                                                WindUI:Notify({ Title = "🥚 Egg Hatched!", Content = "Egg is ready and hatched!", Duration = 2 })
                                            end
                                            task.wait(0.5)
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
    end
})

Tab:Toggle({
    Title = "Auto Skip All Eggs",
    Value = false,
    Callback = function(v)
        if v then
            ConnectionManager:Cleanup("AutoSkipEgg")
            local thread = task.spawn(function()
                while v do
                    local placedItems = getPlacedItems()
                    if placedItems then
                        for _, item in ipairs(placedItems:GetChildren()) do
                            if item:GetAttribute("ItemType") == "Egg" then
                                local char = LP.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                local primaryPart = item.PrimaryPart or item:FindFirstChildOfClass("BasePart")
                                if hrp and primaryPart then
                                    hrp.CFrame = primaryPart.CFrame + Vector3.new(0,3,0)
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
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 4 — 🌸 FLOWERS
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Flowers", Icon = "flower" })

Tab:Dropdown({
    Title = "Select Flowers to Pickup",
    Values = FLOWER_OPTIONS,
    Value = {"Any"},
    Multi = true,
    Callback = function(sel)
        State.AutoPickup.selectedFlowers = sel
        WindUI:Notify({ Title = "Flower Filter", Content = "Selected "..#sel.." flower type(s)", Duration = 2 })
    end
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
        if sel == "Any" then pickupAny = true; break end
    end
    
    for _, item in ipairs(placedItems:GetChildren()) do
        if item:GetAttribute("ItemType") == "Flower" then
            local baseName = item:GetAttribute("BaseName") or item:GetAttribute("baseName") or "Unknown"
            local shouldPickup = pickupAny
            if not shouldPickup then
                for _, sel in ipairs(selectedFlowers) do
                    if baseName == sel then shouldPickup = true; break end
                end
            end
            if shouldPickup then table.insert(flowers, item) end
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

Tab:Toggle({
    Title = "Auto Pickup Flowers",
    Value = false,
    Callback = function(v)
        State.AutoPickup.enabled = v
        if v then
            ConnectionManager:Cleanup("AutoPickup")
            local thread = task.spawn(function()
                while State.AutoPickup.enabled do
                    pickupFlowers()
                    task.wait(State.AutoPickup.interval)
                end
            end)
            ConnectionManager:RegisterThread("AutoPickup", thread)
        end
    end
})

Tab:Slider({
    Title = "Pickup Interval (seconds)",
    Step = 0.5,
    Value = { Min = 0.5, Max = 10, Default = 1 },
    Callback = function(v) State.AutoPickup.interval = v end
})

Tab:Paragraph({ Title = "Total: " .. #FLOWER_LIST .. " flower types available", Desc = "" })

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 5 — 👑 CONVEYOR
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Conveyor", Icon = "crown" })

local selectedConveyorKey = "Queen1"

Tab:Dropdown({
    Title = "Select Queen Conveyor",
    Values = CONVEYOR_LIST,
    Value = {CONVEYOR_LIST[1] or "Baby Queen [Queen1]"},
    Multi = false,
    Callback = function(sel)
        local key = (sel[1] or ""):match("%[(.-)%]")
        selectedConveyorKey = key or "Queen1"
    end
})

Tab:Button({
    Title = "Equip Selected Conveyor",
    Callback = function()
        safeFire(HandleConveyor, "equip", selectedConveyorKey)
        WindUI:Notify({ Title = "Conveyor", Content = "Equipping "..selectedConveyorKey, Duration = 3 })
    end
})

Tab:Toggle({
    Title = "Auto Equip Best Unlocked Conveyor",
    Value = false,
    Callback = function(v)
        State.AutoConveyor.enabled = v
        if v then
            ConnectionManager:Cleanup("AutoConveyor")
            local thread = task.spawn(function()
                while State.AutoConveyor.enabled do
                    local data = getClientData()
                    local unlocked = (data.ConveyorUpgrade and data.ConveyorUpgrade.UnlockedConveyors) or {}
                    local bestKey, bestPrice = nil, -1
                    if SharedConveyors and SharedConveyors.List then
                        for key, conv in pairs(SharedConveyors.List) do
                            if unlocked[key] and (conv.Price or 0) > bestPrice then
                                bestPrice = conv.Price or 0
                                bestKey = key
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
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 6 — ⚡ PLAYER
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Player", Icon = "user" })

local walkSpeedConn = nil

Tab:Slider({
    Title = "Walk Speed",
    Step = 1,
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(v)
        State.WalkSpeed = v
        if walkSpeedConn then walkSpeedConn:Disconnect(); walkSpeedConn = nil end
        if v > 16 then
            walkSpeedConn = RunService.Heartbeat:Connect(function()
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = State.WalkSpeed end
            end)
        else
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

local jumpConn = nil

Tab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        State.InfJump.enabled = v
        if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
        if v then
            jumpConn = UserInput.JumpRequest:Connect(function()
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and State.InfJump.enabled then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
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

Tab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(v)
        if v then
            stopFly()
            if not LP.Character then LP.CharacterAdded:Wait() end
            startFly()
        else
            stopFly()
        end
    end
})

Tab:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = 1 },
    Callback = function(v) flySpeed = v end
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
Tab = Window:Tab({ Title = "ESP", Icon = "eye" })

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

Tab:Toggle({
    Title = "Flower ESP",
    Value = false,
    Callback = function(v)
        State.ESPFlower.enabled = v
        if not v then
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
    end
})

Tab:Toggle({
    Title = "Player ESP",
    Value = false,
    Callback = function(v)
        State.ESPPlayer.enabled = v
        if not v then
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
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 8 — 🚀 TELEPORT (Auto Collect)
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Teleport", Icon = "map-pinned" })

-- Auto Easter Egg
Tab:Section({ Title = "Easter Egg", Opened = true })
Tab:Toggle({
    Title = "Auto Collect Easter Eggs",
    Value = false,
    Callback = function(v)
        State.AutoEasterEgg = v
        if v then
            ConnectionManager:Cleanup("AutoEasterEgg")
            local thread = task.spawn(function()
                local collected = {}
                while State.AutoEasterEgg do
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if not State.AutoEasterEgg then break end
                        local name = obj.Name
                        if name:match("^EasterEgg_%d+$") and name ~= "EasterEgg_HoneyPot" then
                            if not collected[obj] then
                                -- 检查 Pivot 位置，Y 不能为负
                                local pos = obj:GetPivot().Position
                                if pos.Y >= -1 then
                                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                    if not prompt then
                                        for _, desc in ipairs(obj:GetDescendants()) do
                                            if desc:IsA("ProximityPrompt") then prompt = desc; break end
                                        end
                                    end
                                    if prompt and prompt.Enabled then
                                        tweenTo(pos)
                                        fireProximityPrompt(prompt)
                                        collected[obj] = true
                                        WindUI:Notify({ Title = "🥚 Easter Egg", Content = "Collected "..name, Duration = 1.5, Icon = "egg" })
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
            ConnectionManager:RegisterThread("AutoEasterEgg", thread)
        end
    end
})

-- Auto Snowflake
Tab:Section({ Title = "Snowflake", Opened = true })
Tab:Toggle({
    Title = "Auto Collect Snowflakes",
    Value = false,
    Callback = function(v)
        State.AutoSnowflake = v
        if v then
            ConnectionManager:Cleanup("AutoSnowflake")
            local thread = task.spawn(function()
                local collected = {}
                while State.AutoSnowflake do
                    local folder = workspace:FindFirstChild("SnowflakePickup")
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if not State.AutoSnowflake then break end
                            if not collected[obj] then
                                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                if not prompt then
                                    for _, desc in ipairs(obj:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then prompt = desc; break end
                                    end
                                end
                                if prompt and prompt.Enabled then
                                    local pos = getModelPosition(obj)
                                    if pos then
                                        tweenTo(pos)
                                        fireProximityPrompt(prompt)
                                        collected[obj] = true
                                        WindUI:Notify({ Title = "❄️ Snowflake", Content = "Collected", Duration = 1.5, Icon = "snowflake" })
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            ConnectionManager:RegisterThread("AutoSnowflake", thread)
        end
    end
})

-- Auto Meteoron
Tab:Section({ Title = "Meteoron", Opened = true })
Tab:Toggle({
    Title = "Auto Collect Meteorons",
    Value = false,
    Callback = function(v)
        State.AutoMeteoron = v
        if v then
            ConnectionManager:Cleanup("AutoMeteoron")
            local thread = task.spawn(function()
                local collected = {}
                while State.AutoMeteoron do
                    local folder = workspace:FindFirstChild("MeteoronPickup")
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if not State.AutoMeteoron then break end
                            if not collected[obj] then
                                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                                if not prompt then
                                    for _, desc in ipairs(obj:GetDescendants()) do
                                        if desc:IsA("ProximityPrompt") then prompt = desc; break end
                                    end
                                end
                                if prompt and prompt.Enabled then
                                    local pos = getModelPosition(obj)
                                    if pos then
                                        tweenTo(pos)
                                        fireProximityPrompt(prompt)
                                        collected[obj] = true
                                        WindUI:Notify({ Title = "☄️ Meteoron", Content = "Collected", Duration = 1.5, Icon = "meteor" })
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            ConnectionManager:RegisterThread("AutoMeteoron", thread)
        end
    end
})



-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 9 — 🏪 MISC
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Server", Icon = "map-pin" })

Tab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportSvc:Teleport(game.PlaceId, LP)
    end
})

Tab:Button({
    Title = "Find Low Pop Server",
    Callback = function()
        WindUI:Notify({ Title = "Server Hop", Content = "Searching...", Duration = 2 })
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
                WindUI:Notify({ Title = "Server Hop", Content = "Found server with " .. lowestPop .. " players. Joining...", Duration = 3 })
                task.wait(1.5)
                TeleportSvc:TeleportToPlaceInstance(placeId, lowest, LP)
            else
                WindUI:Notify({ Title = "Server Hop", Content = "No suitable server found.", Duration = 3 })
            end
        end)
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- TAB 10 — ⛔ STOP ALL
-- ══════════════════════════════════════════════════════════════════════════════
Tab = Window:Tab({ Title = "Stop", Icon = "octagon" })

Tab:Button({
    Title = "⛔ Disable All Features",
    Color = "Red",
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
        WindUI:Notify({ Title = "Stopped", Content = "All features disabled.", Duration = 3, Icon = "check-circle" })
    end
})

-- ─── Startup ──────────────────────────────────────────────────────────────────
WindUI:Notify({
    Title = "🐝 Bee Garden",
    Content = "Loaded! Use the floating button to open/close.",
    Duration = 5,
    Icon = "bee",
})
