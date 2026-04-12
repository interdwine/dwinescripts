-- Bee Garden Hub v4.0 - Correct remotes & structure

local ok_rayfield, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok_rayfield then warn("Rayfield failed: " .. tostring(Rayfield)) return end

-- Services
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

-- ========================
-- EXACT REMOTES (from decompile)
-- ========================
-- Coins:    Events.ClaimCoins:FireServer("Collect_Coins")
-- Egg:      Events.PurchaseConveyorEgg:FireServer(GUID, slotIndex)
-- Bee Shop: Events.BeeShopHandler:FireServer("Purchase", {slotIndex=N, quantity=1})
-- AutoBuy:  Events.BeeShopHandler:FireServer("ToggleAutoBuy", {rarity="Common"})

local Events = ReplicatedStorage:WaitForChild("Events", 10)

-- ========================
-- CONFIG
-- ========================
local Config = {
    AutoCollect        = false,
    CollectInterval    = 1,
    Notification       = true,

    -- Bee Shop slots (1-based, shop has multiple slots)
    AutoBuyShopBee     = false,
    ShopSlotIndex      = 1,        -- which slot to buy from
    ShopBeeInterval    = 3,

    -- Conveyor eggs (slide on belt, hatch into FLOWERS)
    AutoBuyEgg         = false,
    EggSlotIndex       = "2",      -- conveyor slot string (from decompile)
    EggBuyInterval     = 2,

    -- Queen / Conveyor upgrade
    AutoBuyQueen       = false,
    SelectedQueen      = "Queen1",
    QueenBuyInterval   = 5,
}

-- ========================
-- HELPERS
-- ========================
local function FormatNumber(n)
    if n >= 1e12 then return string.format("%.2fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n/1e3)
    else return tostring(n) end
end

local function FormatTime(s)
    s = math.max(0, math.floor(s))
    return string.format("%d:%02d", math.floor(s/60), s%60)
end

local function Notify(title, content, duration)
    if not Config.Notification then return end
    pcall(function()
        Rayfield:Notify({ Title=title, Content=content, Duration=duration or 2 })
    end)
end

local function SafeFire(remoteName, ...)
    local args = {...}
    local ok, err = pcall(function()
        local r = Events:FindFirstChild(remoteName)
        if r then r:FireServer(table.unpack(args)) end
    end)
    return ok
end

-- ========================
-- BEE DATA (Bee Shop sells these)
-- ========================
local BeeData = {
    { Key="DaisyBee",            Name="Daisy Bee",            Rarity="Common",    Income=0.2 },
    { Key="CamelliaBee",         Name="Camellia Bee",         Rarity="Common",    Income=0.3 },
    { Key="IrisBee",             Name="Iris Bee",             Rarity="Common",    Income=0.4 },
    { Key="PansyBee",            Name="Pansy Bee",            Rarity="Common",    Income=0.5 },
    { Key="TulipBee",            Name="Tulip Bee",            Rarity="Common",    Income=0.6 },
    { Key="ThistleBee",          Name="Thistle Bee",          Rarity="Common",    Income=0.7 },
    { Key="SnowdropBee",         Name="Snowdrop Bee",         Rarity="Common",    Income=0.8 },
    { Key="PinkbellsBee",        Name="Pinkbells Bee",        Rarity="Common",    Income=0.9 },
    { Key="LobeliaBee",          Name="Lobelia Bee",          Rarity="Common",    Income=1.0 },
    { Key="CornflowerBee",       Name="Cornflower Bee",       Rarity="Uncommon",  Income=1.2 },
    { Key="LilyBee",             Name="Lily Bee",             Rarity="Uncommon",  Income=1.35 },
    { Key="PomeflowerBee",       Name="Pomeflower Bee",       Rarity="Uncommon",  Income=1.5 },
    { Key="SucculentBee",        Name="Succulent Bee",        Rarity="Uncommon",  Income=1.65 },
    { Key="BellFlowerBee",       Name="Bellflower Bee",       Rarity="Uncommon",  Income=1.8 },
    { Key="ZombeeFlowerBee",     Name="Zombee Bee",           Rarity="Uncommon",  Income=1.9 },
    { Key="SpiderLillyBee",      Name="Spider Lilly Bee",     Rarity="Uncommon",  Income=2.0 },
    { Key="DandelionBee",        Name="Dandelion Bee",        Rarity="Rare",      Income=2.1 },
    { Key="SunflowerBee",        Name="Sunflower Bee",        Rarity="Rare",      Income=2.3 },
    { Key="CactusBee",           Name="Cactus Bee",           Rarity="Rare",      Income=2.5 },
    { Key="UnicornPetuniaBee",   Name="Unicorn Bee",          Rarity="Rare",      Income=2.7 },
    { Key="NuzwatBee",           Name="Nuzwat Bee",           Rarity="Epic",      Income=3.1 },
    { Key="CyberFlowerBee",      Name="Cyber Bee",            Rarity="Epic",      Income=3.3 },
    { Key="OrchidBee",           Name="Orchid Bee",           Rarity="Epic",      Income=3.5 },
    { Key="RoseBee",             Name="Rose Bee",             Rarity="Legendary", Income=4.1 },
    { Key="BugEaterBee",         Name="Bug Eater Bee",        Rarity="Legendary", Income=4.3 },
    { Key="DesertWildFlowerBee", Name="Desert Bee",           Rarity="Legendary", Income=4.4 },
    { Key="GhostflowerBee",      Name="Ghost Bee",            Rarity="Legendary", Income=4.6 },
    { Key="KittyTowerFlowerBee", Name="Kitty Bee",            Rarity="Legendary", Income=4.7 },
    { Key="IvoryIrisBee",        Name="Ivory Iris Bee",       Rarity="Legendary", Income=4.9 },
    { Key="SnowdrifterBee",      Name="Snowdrifter Bee",      Rarity="Legendary", Income=5.1 },
    { Key="GlowBerryBee",        Name="Glowberry Bee",        Rarity="Mythical",  Income=5.4 },
    { Key="DragonFlowerBee",     Name="Dragon Bee",           Rarity="Mythical",  Income=5.6 },
    { Key="BambooBee",           Name="Bamboo Bee",           Rarity="Mythical",  Income=5.8 },
    { Key="SnapdragonBee",       Name="Snapdragon Bee",       Rarity="Mythical",  Income=6.0 },
    { Key="CrimsonWidowBee",     Name="Crimson Bee",          Rarity="Mythical",  Income=6.2 },
    { Key="FrostbitBee",         Name="Frostbit Bee",         Rarity="Mythical",  Income=6.4 },
    { Key="TwilightAmarilisBee", Name="Twilight Bee",         Rarity="Secret",    Income=7.2 },
    { Key="FrostburnRoseBee",    Name="Frostburn Bee",        Rarity="Secret",    Income=7.6 },
    { Key="FairyQueentessaBee",  Name="Fairy Queentessa Bee", Rarity="Secret",    Income=9.0 },
    { Key="TriEyeBee",           Name="Tri Eye Bee",          Rarity="Secret",    Income=11.0 },
    { Key="TrallaleroBee",       Name="Trallalero Bee",       Rarity="Premium",   Income=7.0 },
    { Key="LaVacaBee",           Name="LaVaca Bee",           Rarity="Premium",   Income=8.0 },
    { Key="ArachnidBee",         Name="Arachnid Bee",         Rarity="Divine",    Income=30.0 },
}

-- ========================
-- FLOWER DATA (Eggs on conveyor hatch into these)
-- ========================
local FlowerData = {
    { Key="Daisy",            Name="Daisy",             Rarity="Common",    PerSecond=2 },
    { Key="Camellia",         Name="Camellia",          Rarity="Common",    PerSecond=3 },
    { Key="Iris",             Name="Iris",              Rarity="Common",    PerSecond=5 },
    { Key="Pansy",            Name="Pansy",             Rarity="Common",    PerSecond=15 },
    { Key="Tulip",            Name="Tulip",             Rarity="Common",    PerSecond=17 },
    { Key="Thistle",          Name="Thistle",           Rarity="Common",    PerSecond=30 },
    { Key="Snowdrop",         Name="Snowdrop",          Rarity="Common",    PerSecond=35 },
    { Key="Pinkbells",        Name="Pinkbells",         Rarity="Common",    PerSecond=75 },
    { Key="Lobelia",          Name="Lobelia",           Rarity="Common",    PerSecond=100 },
    { Key="Cornflower",       Name="Cornflower",        Rarity="Uncommon",  PerSecond=20 },
    { Key="Lily",             Name="Lily",              Rarity="Uncommon",  PerSecond=25 },
    { Key="Pomeflower",       Name="Pomeflower",        Rarity="Uncommon",  PerSecond=50 },
    { Key="Succulent",        Name="Succulent",         Rarity="Uncommon",  PerSecond=100 },
    { Key="BellFlower",       Name="Bell Flower",       Rarity="Uncommon",  PerSecond=150 },
    { Key="ZombeeFlower",     Name="Zombie Flower",     Rarity="Uncommon",  PerSecond=200 },
    { Key="SpiderLilly",      Name="Spider Lilly",      Rarity="Uncommon",  PerSecond=300 },
    { Key="CrystalizedPetal", Name="Crystalized Petal", Rarity="Uncommon",  PerSecond=200 },
    { Key="Dandelion",        Name="Dandelion",         Rarity="Rare",      PerSecond=75 },
    { Key="Sunflower",        Name="Sunflower",         Rarity="Rare",      PerSecond=150 },
    { Key="Cactus",           Name="Cactus",            Rarity="Rare",      PerSecond=200 },
    { Key="UnicornPetunia",   Name="Unicorn Petunia",   Rarity="Rare",      PerSecond=420 },
    { Key="Frostbloom",       Name="Pink Bloom",        Rarity="Rare",      PerSecond=300 },
    { Key="Voidbloom",        Name="Void Bloom",        Rarity="Rare",      PerSecond=350 },
    { Key="IcecapBloom",      Name="Icecap Bloom",      Rarity="Rare",      PerSecond=350 },
    { Key="KittyTowerFlower", Name="Kitty Tower",       Rarity="Epic",      PerSecond=100 },
    { Key="Nuzwat",           Name="Nuzwat",            Rarity="Epic",      PerSecond=200 },
    { Key="ZebraFlower",      Name="Zebra Flower",      Rarity="Epic",      PerSecond=400 },
    { Key="Orchid",           Name="Orchid",            Rarity="Epic",      PerSecond=300 },
    { Key="CyberFlower",      Name="Cyber Flower",      Rarity="Epic",      PerSecond=550 },
    { Key="Whitenight",       Name="White Nocturne",    Rarity="Epic",      PerSecond=450 },
    { Key="EmberSpark",       Name="Ember Spark",       Rarity="Epic",      PerSecond=700 },
    { Key="RadianceLily",     Name="Radiance Lily",     Rarity="Epic",      PerSecond=850 },
    { Key="BorealBell",       Name="Boreal Bell",       Rarity="Epic",      PerSecond=700 },
    { Key="Rose",             Name="Rose",              Rarity="Legendary", PerSecond=500 },
    { Key="Glacierheart",     Name="Glacier Heart",     Rarity="Legendary", PerSecond=300 },
    { Key="DesertWildFlower", Name="Desert Wild Flower",Rarity="Legendary", PerSecond=550 },
    { Key="BugEater",         Name="Bug Eater",         Rarity="Legendary", PerSecond=700 },
    { Key="Ghostflower",      Name="Ghost Iris",        Rarity="Legendary", PerSecond=850 },
    { Key="IvoryIris",        Name="Ivory Iris",        Rarity="Legendary", PerSecond=1500 },
    { Key="OceanBloom",       Name="Ocean Bloom",       Rarity="Legendary", PerSecond=900 },
    { Key="Lightbloom",       Name="Lightbloom",        Rarity="Legendary", PerSecond=1100 },
    { Key="Hellebore",        Name="Hellebore",         Rarity="Legendary", PerSecond=1265 },
    { Key="PolarSpire",       Name="Polar Spire",       Rarity="Legendary", PerSecond=1250 },
    { Key="CrystalDaisy",     Name="Crystal Daisy",     Rarity="Mythical",  PerSecond=800 },
    { Key="GlowBerry",        Name="Glow Berry",        Rarity="Mythical",  PerSecond=1000 },
    { Key="DragonFlower",     Name="Dragon Flower",     Rarity="Mythical",  PerSecond=1200 },
    { Key="Bamboo",           Name="Bamboo",            Rarity="Mythical",  PerSecond=1750 },
    { Key="Snapdragon",       Name="Snapdragon",        Rarity="Mythical",  PerSecond=2400 },
    { Key="CrimsonWidow",     Name="Crimson Widow",     Rarity="Mythical",  PerSecond=2800 },
    { Key="Sunpetal",         Name="Sunpetal",          Rarity="Mythical",  PerSecond=1500 },
    { Key="HaloOrchid",       Name="Halo Orchid",       Rarity="Mythical",  PerSecond=1550 },
    { Key="FrostLily",        Name="Frost Lily",        Rarity="Mythical",  PerSecond=1725 },
    { Key="HollyBloom",       Name="Holly Bloom",       Rarity="Mythical",  PerSecond=1785 },
    { Key="ShimmeringLichen", Name="Shimmering Lichen", Rarity="Mythical",  PerSecond=1750 },
    { Key="NebulaRose",       Name="Nebula Rose",       Rarity="Mythical",  PerSecond=2100 },
    { Key="SolarIris",        Name="Solar Iris",        Rarity="Mythical",  PerSecond=2200 },
    { Key="TwilightAmarilis", Name="Twilight Amarilis", Rarity="Secret",    PerSecond=1800 },
    { Key="FrostburnRose",    Name="Frostburn Rose",    Rarity="Secret",    PerSecond=5000 },
    { Key="DarkflareRose",    Name="Darkflare Rose",    Rarity="Secret",    PerSecond=2000 },
    { Key="Gleamblossom",     Name="Gleamblossom",      Rarity="Secret",    PerSecond=2300 },
    { Key="Starpetal",        Name="Starpetal",         Rarity="Secret",    PerSecond=3200 },
    { Key="FairyQueentessa",  Name="Fairy Queentessa",  Rarity="Secret",    PerSecond=3700 },
    { Key="UfoFlower",        Name="UFO Flower",        Rarity="Secret",    PerSecond=4500 },
    { Key="TriEye",           Name="Tri Eye",           Rarity="Secret",    PerSecond=4300 },
    { Key="Sunfloris",        Name="Sunfloris",         Rarity="Divine",    PerSecond=20000 },
    { Key="Rosaris",          Name="Rosaris",           Rarity="Divine",    PerSecond=22000 },
    { Key="Helios",           Name="Helios",            Rarity="Divine",    PerSecond=24000 },
    { Key="Lunaris",          Name="Lunaris",           Rarity="Divine",    PerSecond=26000 },
}

-- ========================
-- QUEEN DATA
-- ========================
local QueenData = {
    { Key="Queen1",  Name="Baby Queen",    Rarity="Common",    Price=0 },
    { Key="Queen2",  Name="Mother Queen",  Rarity="Common",    Price=50000 },
    { Key="Queen3",  Name="Royal Queen",   Rarity="Uncommon",  Price=500000 },
    { Key="Queen4",  Name="Void Queen",    Rarity="Uncommon",  Price=5000000 },
    { Key="Queen5",  Name="Frozen Queen",  Rarity="Rare",      Price=50000000 },
    { Key="Queen6",  Name="Rainbow Queen", Rarity="Rare",      Price=150000000 },
    { Key="Queen7",  Name="Disco Queen",   Rarity="Epic",      Price=500000000 },
    { Key="Queen8",  Name="Dragon Queen",  Rarity="Epic",      Price=2500000000 },
    { Key="Queen9",  Name="Santa Queen",   Rarity="Legendary", Price=5000000000 },
    { Key="Queen91", Name="Eclipse Queen", Rarity="Legendary", Price=15000000000 },
    { Key="Queen92", Name="Fairy Queen",   Rarity="Mythical",  Price=100000000000 },
    { Key="Queen93", Name="Alien Queen",   Rarity="Mythical",  Price=500000000000 },
}

-- ========================
-- LIVE SHOP SLOT TRACKER
-- Reads actual BeeShop GUI slots in real time
-- ========================
local LiveShopSlots = {}  -- { [slotIndex] = { beeId, rarity, stock, price, income } }

local function ReadLiveShopSlots()
    local slots = {}
    pcall(function()
        local gui = LocalPlayer.PlayerGui:WaitForChild("Main", 3)
        if not gui then return end
        local beeShopFrame = gui:FindFirstChild("Frames", true)
        if not beeShopFrame then return end
        local shopFrame = beeShopFrame:FindFirstChild("BeeShop")
        if not shopFrame then return end
        local list = shopFrame:FindFirstChild("List")
        if not list then return end

        local idx = 0
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("StockItem") then
                idx = idx + 1
                local mf = child:FindFirstChild("MainFrame")
                if mf then
                    local beeName = ""
                    local rarity  = ""
                    local stock   = 0
                    local price   = ""
                    local income  = ""

                    local itemName = mf:FindFirstChild("ItemName")
                    if itemName then beeName = itemName.Text end

                    local rarityLbl = mf:FindFirstChild("Rarity")
                    if rarityLbl then rarity = rarityLbl.Text end

                    local stockLbl = mf:FindFirstChild("Stock")
                    if stockLbl then
                        stock = tonumber(stockLbl.Text:match("%d+")) or 0
                    end

                    local priceFrame = mf:FindFirstChild("PriceFrame")
                    if priceFrame then
                        local amt = priceFrame:FindFirstChild("Amount")
                        if amt then price = amt.Text end
                    end

                    local beeFrame = mf:FindFirstChild("BeeFrame")
                    if beeFrame then
                        local inc = beeFrame:FindFirstChild("Income")
                        if inc then income = inc.Text end
                    end

                    slots[idx] = {
                        slotIndex = idx,
                        beeName   = beeName,
                        rarity    = rarity,
                        stock     = stock,
                        price     = price,
                        income    = income,
                    }
                end
            end
        end
    end)
    LiveShopSlots = slots
    return slots
end

-- Read restock timer from actual GUI label (from decompile: v_u_11 = Timer label)
local function ReadRestockTimer()
    local remaining = nil
    pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("Main")
        if not gui then return end
        -- Path: Main > Frames > BeeShop > BottomFrame > Timer
        local frames = gui:FindFirstChild("Frames")
        if not frames then return end
        local beeShop = frames:FindFirstChild("BeeShop")
        if not beeShop then return end
        local bottom = beeShop:FindFirstChild("BottomFrame")
        if not bottom then return end
        local timer = bottom:FindFirstChild("Timer")
        if not timer then return end
        -- Text format: "Restocks in: M:SS"
        local m, s = timer.Text:match("(%d+):(%d+)")
        if m and s then
            remaining = tonumber(m)*60 + tonumber(s)
        end
    end)
    return remaining
end

-- ========================
-- ACTION FUNCTIONS
-- ========================
local function CollectCoins()
    SafeFire("ClaimCoins", "Collect_Coins")
    Notify("🪙 Coins Collected!", "Auto collect fired.", 2)
end

-- Bee Shop: buy from a specific slot index
-- Exact remote: BeeShopHandler:FireServer("Purchase", {slotIndex=N, quantity=1})
local function BuyShopSlot(slotIndex)
    SafeFire("BeeShopHandler", "Purchase", {
        slotIndex = slotIndex,
        quantity  = 1,
    })
end

-- Conveyor Egg: slides on belt, hatches into a FLOWER (not bee!)
-- Exact remote: PurchaseConveyorEgg:FireServer(GUID, slotString)
local function BuyConveyorEgg(slotStr)
    local guid = ""
    pcall(function()
        guid = HttpService:GenerateGUID(false)
    end)
    SafeFire("PurchaseConveyorEgg", guid, slotStr)
end

-- Toggle Auto-Buy rarity in Bee Shop
local function ToggleAutoBuyRarity(rarity)
    SafeFire("BeeShopHandler", "ToggleAutoBuy", { rarity = rarity })
end

-- Buy Queen/Conveyor upgrade
local function BuyConveyor(key)
    SafeFire("BuyConveyor", key)
end

-- ========================
-- LOOKUP HELPERS
-- ========================
local function GetBeeNames()
    local t = {} for _,b in ipairs(BeeData) do table.insert(t, b.Name) end return t
end

local function GetFlowerNames()
    local t = {} for _,f in ipairs(FlowerData) do table.insert(t, f.Name) end return t
end

local function GetQueenNames()
    local t = {} for _,q in ipairs(QueenData) do table.insert(t, q.Name) end return t
end

local function GetQueenKeyByName(name)
    for _,q in ipairs(QueenData) do if q.Name==name then return q.Key end end
end

-- ========================
-- BUILD RAYFIELD WINDOW
-- ========================
local Window = Rayfield:CreateWindow({
    Name = "🐝 Bee Garden Hub v4.0",
    LoadingTitle = "Bee Garden Hub",
    LoadingSubtitle = "Correct remotes. Clean build.",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BeeGardenHub",
        FileName = "Config40",
    },
    KeySystem = false,
})

-- ========================
-- TAB 1: AUTO FARM (Coins)
-- ========================
local FarmTab = Window:CreateTab("🌸 Auto Farm", "flower")
FarmTab:CreateSection("Coin Collection")

FarmTab:CreateToggle({
    Name = "Auto Collect Coins",
    CurrentValue = false, Flag = "AutoCollect",
    Callback = function(v)
        Config.AutoCollect = v
        Notify(v and "✅ Auto Collect ON" or "⛔ Auto Collect OFF", "", 2)
    end,
})

FarmTab:CreateSlider({
    Name = "Collect Interval (s)",
    Range = {1, 30}, Increment = 1, Suffix = "s",
    CurrentValue = 1, Flag = "CollectInterval",
    Callback = function(v) Config.CollectInterval = v end,
})

FarmTab:CreateToggle({
    Name = "Show Notifications",
    CurrentValue = true, Flag = "ShowNotif",
    Callback = function(v) Config.Notification = v end,
})

FarmTab:CreateButton({
    Name = "Collect Coins Now",
    Callback = function() CollectCoins() end,
})

FarmTab:CreateSection("Status")
local farmLabel = FarmTab:CreateLabel("Status: Idle")

-- ========================
-- TAB 2: BEE SHOP
-- Reads LIVE slots from GUI, buys by slot index
-- Remote: BeeShopHandler:FireServer("Purchase", {slotIndex=N, quantity=1})
-- ========================
local ShopTab = Window:CreateTab("🛒 Bee Shop", "shopping-cart")
ShopTab:CreateSection("Live Shop Slots")
ShopTab:CreateLabel("Reads real slot data from the BeeShop GUI.")
ShopTab:CreateLabel("Slot index = position in the shop list (1, 2, 3...)")

local shopSlotsLabel = ShopTab:CreateLabel("🔄 Press Refresh to load slots...")
local shopRestockLabel = ShopTab:CreateLabel("⏱️ Restock: --")

ShopTab:CreateButton({
    Name = "🔄 Refresh Shop Slots",
    Callback = function()
        local slots = ReadLiveShopSlots()
        local count = 0
        for _ in pairs(slots) do count = count + 1 end

        if count == 0 then
            shopSlotsLabel:Set("⚠️ No slots found. Open the Bee Shop in-game first!")
            Notify("⚠️ No Slots", "Open the Bee Shop UI in-game, then refresh.", 4)
        else
            local lines = {}
            for i, slot in pairs(slots) do
                table.insert(lines, string.format(
                    "Slot %d: %s [%s] Stock:%d Price:%s Income:%s",
                    i, slot.beeName, slot.rarity, slot.stock, slot.price, slot.income
                ))
            end
            shopSlotsLabel:Set("✅ " .. count .. " slots loaded. Check notifications.")
            for _, line in ipairs(lines) do
                Notify("🛒 Slot", line, 4)
            end
        end

        local restock = ReadRestockTimer()
        if restock then
            shopRestockLabel:Set("⏱️ Restock in: " .. FormatTime(restock))
        end
    end,
})

ShopTab:CreateSection("Auto Buy by Slot Index")
ShopTab:CreateLabel("Set which slot number to auto buy from (check slot list above).")

ShopTab:CreateSlider({
    Name = "Shop Slot Index",
    Range = {1, 10}, Increment = 1,
    CurrentValue = 1, Flag = "ShopSlotIndex",
    Callback = function(v) Config.ShopSlotIndex = v end,
})

ShopTab:CreateToggle({
    Name = "Auto Buy Bee Shop Slot",
    CurrentValue = false, Flag = "AutoBuyShopBee",
    Callback = function(v)
        Config.AutoBuyShopBee = v
        Notify(v and "✅ Shop Auto Buy ON" or "⛔ Shop Auto Buy OFF",
               v and "Buying slot " .. Config.ShopSlotIndex or "", 2)
    end,
})

ShopTab:CreateSlider({
    Name = "Shop Buy Interval (s)",
    Range = {1, 30}, Increment = 1, Suffix = "s",
    CurrentValue = 3, Flag = "ShopBeeInterval",
    Callback = function(v) Config.ShopBeeInterval = v end,
})

ShopTab:CreateButton({
    Name = "Buy Shop Slot Once",
    Callback = function()
        BuyShopSlot(Config.ShopSlotIndex)
        Notify("🛒 Fired!", "Bought slot " .. Config.ShopSlotIndex, 2)
    end,
})

ShopTab:CreateSection("Auto-Buy by Rarity (Game Feature)")
ShopTab:CreateLabel("Toggles the game's built-in Auto-Buy for a rarity tier.")

local rarityOptions = {"Common","Uncommon","Rare","Epic","Legendary","Mythical","Secret"}
local selectedAutoBuyRarity = "Common"

ShopTab:CreateDropdown({
    Name = "Toggle Rarity Auto-Buy",
    Options = rarityOptions,
    CurrentOption = {"Common"},
    MultipleOptions = false,
    Flag = "AutoBuyRarity",
    Callback = function(v)
        selectedAutoBuyRarity = type(v)=="table" and v[1] or v
    end,
})

ShopTab:CreateButton({
    Name = "Toggle Selected Rarity",
    Callback = function()
        ToggleAutoBuyRarity(selectedAutoBuyRarity)
        Notify("🔀 Toggled", "Auto-buy rarity: " .. selectedAutoBuyRarity, 2)
    end,
})

ShopTab:CreateSection("Bee Reference (sorted by income)")
local sortedBees = {}
for _,b in ipairs(BeeData) do table.insert(sortedBees, b) end
table.sort(sortedBees, function(a,b) return a.Income < b.Income end)
for _,b in ipairs(sortedBees) do
    ShopTab:CreateLabel(string.format("[%s] %s | +%.1f%%/s income", b.Rarity, b.Name, b.Income))
end

-- ========================
-- TAB 3: CONVEYOR EGGS
-- Eggs slide on the conveyor belt and hatch into FLOWERS
-- Remote: PurchaseConveyorEgg:FireServer(GUID, slotIndex)
-- ========================
local EggTab = Window:CreateTab("🥚 Conveyor Eggs", "package")
EggTab:CreateSection("How It Works")
EggTab:CreateLabel("🔄 The conveyor belt moves eggs past you.")
EggTab:CreateLabel("🥚 Click an egg to buy it — it hatches into a FLOWER.")
EggTab:CreateLabel("🌸 Flowers are placed in your garden for passive income.")
EggTab:CreateLabel("Remote: PurchaseConveyorEgg(GUID, slotIndex)")

EggTab:CreateSection("Auto Buy Conveyor Egg")

ShopTab:CreateLabel("Slot index matches position on the belt (usually '1' to '5').")

EggTab:CreateSlider({
    Name = "Conveyor Slot Index",
    Range = {1, 10}, Increment = 1,
    CurrentValue = 2, Flag = "EggSlotIndex",
    Callback = function(v) Config.EggSlotIndex = tostring(v) end,
})

EggTab:CreateToggle({
    Name = "Auto Buy Conveyor Egg",
    CurrentValue = false, Flag = "AutoBuyEgg",
    Callback = function(v)
        Config.AutoBuyEgg = v
        Notify(v and "✅ Auto Buy Egg ON" or "⛔ Auto Buy Egg OFF",
               v and "Buying slot " .. Config.EggSlotIndex or "", 2)
    end,
})

EggTab:CreateSlider({
    Name = "Egg Buy Interval (s)",
    Range = {1, 30}, Increment = 1, Suffix = "s",
    CurrentValue = 2, Flag = "EggBuyInterval",
    Callback = function(v) Config.EggBuyInterval = v end,
})

EggTab:CreateButton({
    Name = "Buy Egg Once (Current Slot)",
    Callback = function()
        BuyConveyorEgg(Config.EggSlotIndex)
        Notify("🥚 Egg Fired!", "Slot: " .. Config.EggSlotIndex, 2)
    end,
})

EggTab:CreateSection("Flower Reference (what eggs hatch into)")
local sortedFlowers = {}
for _,f in ipairs(FlowerData) do table.insert(sortedFlowers, f) end
table.sort(sortedFlowers, function(a,b) return a.PerSecond < b.PerSecond end)
for _,f in ipairs(sortedFlowers) do
    EggTab:CreateLabel(string.format("[%s] %s | 🌿 %d/s", f.Rarity, f.Name, f.PerSecond))
end

-- ========================
-- TAB 4: AUTO BUY QUEEN
-- Remote: BuyConveyor(key)
-- ========================
local QueenTab = Window:CreateTab("👑 Auto Buy Queen", "crown")
QueenTab:CreateSection("Conveyor / Queen Upgrade")

local queenDropdown = QueenTab:CreateDropdown({
    Name = "Select Queen",
    Options = GetQueenNames(),
    CurrentOption = {"Baby Queen"},
    MultipleOptions = false,
    Flag = "SelectedQueen",
    Callback = function(v)
        local name = type(v)=="table" and v[1] or v
        Config.SelectedQueen = GetQueenKeyByName(name) or "Queen1"
        Notify("👑 Queen Selected", name, 2)
    end,
})

QueenTab:CreateToggle({
    Name = "Auto Buy Queen",
    CurrentValue = false, Flag = "AutoBuyQueen",
    Callback = function(v)
        Config.AutoBuyQueen = v
        Notify(v and "✅ Auto Buy Queen ON" or "⛔ Auto Buy Queen OFF", "", 2)
    end,
})

QueenTab:CreateSlider({
    Name = "Queen Buy Interval (s)",
    Range = {1, 60}, Increment = 1, Suffix = "s",
    CurrentValue = 5, Flag = "QueenInterval",
    Callback = function(v) Config.QueenBuyInterval = v end,
})

QueenTab:CreateButton({
    Name = "Buy Selected Queen Once",
    Callback = function()
        BuyConveyor(Config.SelectedQueen)
        Notify("👑 Fired!", "Bought: " .. Config.SelectedQueen, 2)
    end,
})

QueenTab:CreateSection("All Queens")
for _,q in ipairs(QueenData) do
    QueenTab:CreateLabel(string.format("[%s] %s — %s", q.Rarity, q.Name, FormatNumber(q.Price)))
end

-- ========================
-- TAB 5: BEE INFO
-- ========================
local BeeInfoTab = Window:CreateTab("🐝 Bee Info", "info")
BeeInfoTab:CreateSection("All Bees by Income")
for _,b in ipairs(sortedBees) do
    BeeInfoTab:CreateLabel(string.format(
        "[%s] %s\n    Income: +%.1f%%/s",
        b.Rarity, b.Name, b.Income
    ))
end

-- ========================
-- TAB 6: FLOWER INFO
-- ========================
local FlowerInfoTab = Window:CreateTab("🌸 Flower Info", "leaf")
FlowerInfoTab:CreateSection("All Flowers (Egg Hatches) by Income")
FlowerInfoTab:CreateLabel("These are what conveyor eggs hatch into when placed in garden.")
for _,f in ipairs(sortedFlowers) do
    FlowerInfoTab:CreateLabel(string.format(
        "[%s] %s\n    Garden Income: %d/s",
        f.Rarity, f.Name, f.PerSecond
    ))
end

-- ========================
-- TAB 7: STATS
-- ========================
local StatsTab = Window:CreateTab("📊 Stats", "bar-chart")

StatsTab:CreateSection("Top 5 Bees by Income")
local top5b = {} for _,b in ipairs(BeeData) do table.insert(top5b,b) end
table.sort(top5b, function(a,b) return a.Income > b.Income end)
for i=1,math.min(5,#top5b) do
    local b=top5b[i]
    StatsTab:CreateLabel(string.format("#%d %s — +%.1f%%/s [%s]", i, b.Name, b.Income, b.Rarity))
end

StatsTab:CreateSection("Top 5 Flowers by Garden Income")
local top5f = {} for _,f in ipairs(FlowerData) do table.insert(top5f,f) end
table.sort(top5f, function(a,b) return a.PerSecond > b.PerSecond end)
for i=1,math.min(5,#top5f) do
    local f=top5f[i]
    StatsTab:CreateLabel(string.format("#%d %s — %d/s [%s]", i, f.Name, f.PerSecond, f.Rarity))
end

-- ========================
-- TAB 8: SETTINGS
-- ========================
local SettingsTab = Window:CreateTab("⚙️ Settings", "settings")
SettingsTab:CreateSection("Script Info")
SettingsTab:CreateLabel("🐝 Bee Garden Hub v4.0")
SettingsTab:CreateLabel("Fixed: Correct remotes, live shop reader, egg→flower clarified")
SettingsTab:CreateLabel("BeeShopHandler | PurchaseConveyorEgg | ClaimCoins | BuyConveyor")

SettingsTab:CreateSection("Actions")
SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function() Rayfield:Destroy() end,
})

-- ========================
-- MAIN LOOP
-- ========================
local timers = {
    collect  = 0,
    shop     = 0,
    egg      = 0,
    queen    = 0,
    restock  = 0,
}

RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Auto Collect Coins
    if Config.AutoCollect and (now - timers.collect) >= Config.CollectInterval then
        timers.collect = now
        CollectCoins()
        pcall(function() farmLabel:Set("🪙 Last Collect: " .. os.date("%H:%M:%S")) end)
    end

    -- Auto Buy Bee Shop Slot
    -- Fires: BeeShopHandler:FireServer("Purchase", {slotIndex=N, quantity=1})
    if Config.AutoBuyShopBee and (now - timers.shop) >= Config.ShopBeeInterval then
        timers.shop = now
        BuyShopSlot(Config.ShopSlotIndex)
    end

    -- Auto Buy Conveyor Egg (hatches into flower)
    -- Fires: PurchaseConveyorEgg:FireServer(GUID, slotIndex)
    if Config.AutoBuyEgg and (now - timers.egg) >= Config.EggBuyInterval then
        timers.egg = now
        BuyConveyorEgg(Config.EggSlotIndex)
    end

    -- Auto Buy Queen
    if Config.AutoBuyQueen and (now - timers.queen) >= Config.QueenBuyInterval then
        timers.queen = now
        BuyConveyor(Config.SelectedQueen)
    end

    -- Restock timer live update (reads directly from GUI label)
    if (now - timers.restock) >= 1 then
        timers.restock = now
        pcall(function()
            local t = ReadRestockTimer()
            if t and shopRestockLabel then
                shopRestockLabel:Set("⏱️ Restock in: " .. FormatTime(t))
            end
        end)
    end
end)

Rayfield:Notify({
    Title = "🐝 Bee Garden Hub v4.0",
    Content = "Loaded! Correct remotes. Eggs hatch into Flowers. Bee Shop reads live slots.",
    Duration = 5,
})
