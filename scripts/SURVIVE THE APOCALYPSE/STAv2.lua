local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ============================================
-- LOCAL PLAYER
-- ============================================
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ============================================
-- LOAD WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ============================================
-- CONFIGURATION
-- ============================================
local espConfig = {
    textSize = 10,
    fillTransparency = 0.4,
    outlineTransparency = 0,
}

-- ============================================
-- FOLDERS
-- ============================================
local droppedItemsFolder = Workspace:FindFirstChild("DroppedItems")
local charactersFolder   = Workspace:FindFirstChild("Characters")
local structuresFolder   = Workspace:FindFirstChild("Structures")
local cratesFolder       = nil

pcall(function()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local assets = map:FindFirstChild("Assets")
        if assets then
            local crates = assets:FindFirstChild("Crates")
            if crates then
                cratesFolder = crates:FindFirstChild("Default")
            end
        end
    end
end)

-- ============================================
-- ITEM LISTS
-- ============================================
local gunNames = {
    "AK-47","M4A1","M16","SCAR-L","G36","AUG","FAMAS",
    "MP5","UMP45","P90","Vector","Mac-10",
    "M1911","Glock","Desert Eagle","Beretta","Revolver",
    "Remington 870","SPAS-12","Double Barrel",
    "M24","AWP","Barrett","Dragunov",
    "M249","RPK","MG42",
    "RPG","Grenade Launcher",
}

local meleeNames = {
    "Knife","Katana","Crowbar","Bat","Spiked Bat",
    "Hatchet","Fire Axe","Sledgehammer","Scythe",
    "Spear","Chainsaw","Riot Shield","Repair Hammer",
}

local medicalNames = {
    "Bandage","First Aid Kit","Medkit","Blood Bag",
    "Painkillers","Antibiotics","Adrenaline","Morphine",
}

local armorNames = {
    "Helmet","Vest","Body Armor","Riot Helmet",
    "Military Helmet","Tactical Vest","Heavy Armor",
}

local foodNames = {
    "Chips","Carrot","Bloxiade","Beans","MRE","Bloxy Cola",
    "Water Bottle","Soda","Energy Drink","Canned Food",
}

local resourceNames = {
    "Scrap","Metal","Wood","Battery","Fuel Can",
    "Electronics","Cloth","Rope","Duct Tape",
}

local mobNames = {
    "Zombie","Runner","Crawler","Brute","Spitter","Riot","Boss",
    "Walker","Infected","Mutant","Screamer","Stalker",
}

local structureNames = {
    "Wall","Door","Gate","Barricade","Turret","Generator",
    "Storage","Workbench","Medical Station","Tower",
}

-- ============================================
-- ESP STORAGE
-- ============================================
local espInstances = {
    players    = {},
    mobs       = {},
    items      = {},
    structures = {},
    crates     = {},
}

-- ============================================
-- STATE VARIABLES
-- ============================================
local Toggles    = {}
local Options    = {}
local connections = {}

-- Movement
local flyActive       = false
local flyBV, flyBG    = nil, nil
local autoSprintActive = false
local bhopActive      = false
local noclipLastCFrame = nil

-- Combat
local killAuraLastSwing   = 0
local killAuraConn        = nil
local killAuraCurrentTarget  = nil
local killAuraTargetDistance = nil
local killAuraIndicatorLine   = nil
local killAuraIndicatorCircle = nil
local aimbotConn    = nil
local aimbotTarget  = nil
local fovCircle     = nil
local hitboxExpandedParts = {}

-- Features
local antiAFKConn    = nil
local originalLighting = { stored = false }
local originalFog      = { stored = false }
local originalValues   = { walkSpeed = 16 }

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function getItemMainPart(item)
    if item.PrimaryPart then return item.PrimaryPart end
    for _, child in ipairs(item:GetDescendants()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function getDistanceColor(distance)
    if distance < 50  then return Color3.fromRGB(0, 255, 0)   end
    if distance < 150 then return Color3.fromRGB(255, 255, 0)  end
    return Color3.fromRGB(255, 100, 100)
end

local function getHealthColor(healthPercent)
    local r = math.clamp((1 - healthPercent) * 2, 0, 1)
    local g = math.clamp(healthPercent * 2, 0, 1)
    return Color3.new(r, g, 0)
end

local function isEnemy(target)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    if target == myChar then return false end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == target then return false end
    end
    return true
end

-- ============================================
-- ESP HELPERS
-- ============================================
local function createHighlight(target, fillColor, outlineColor)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = target
    hl.FillColor = fillColor
    hl.FillTransparency = espConfig.fillTransparency
    hl.OutlineColor = outlineColor
    hl.OutlineTransparency = espConfig.outlineTransparency
    hl.Parent = target
    return hl
end

local function createBillboard(target, adornee, labelText, textColor)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = target

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = bb

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = labelText
    nameLabel.TextColor3 = textColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = espConfig.textSize
    nameLabel.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0.2
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = espConfig.textSize - 2
    distLabel.Parent = frame

    return bb, nameLabel, distLabel
end

-- ============================================
-- PLAYER ESP
-- ============================================
local function createPlayerESP(player)
    if player == LocalPlayer then return end
    if espInstances.players[player] then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local espData = {}
    if Toggles.PlayerChams and Toggles.PlayerChams.Value then
        espData.Highlight = createHighlight(char, Color3.fromRGB(0, 100, 255), Color3.fromRGB(100, 180, 255))
    end
    if Toggles.PlayerNames and Toggles.PlayerNames.Value then
        espData.Billboard, espData.NameLabel, espData.DistLabel = createBillboard(
            char, root,
            player.DisplayName .. " (@" .. player.Name .. ")",
            Color3.fromRGB(150, 200, 255)
        )
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not player or not player.Parent then conn:Disconnect() return end
        local c = player.Character
        if not c or not c.Parent then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - r.Position).Magnitude
        local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
        local visible = dist <= maxDist
        if espData.Highlight then espData.Highlight.Enabled = visible end
        if espData.Billboard then
            espData.Billboard.Enabled = visible
            if espData.DistLabel then
                espData.DistLabel.Text = math.floor(dist) .. "m"
                espData.DistLabel.TextColor3 = getDistanceColor(dist)
            end
        end
    end)
    espData.Connection = conn
    espInstances.players[player] = espData
end

local function removePlayerESP(player)
    local esp = espInstances.players[player]
    if esp then
        if esp.Highlight  then esp.Highlight:Destroy()       end
        if esp.Billboard  then esp.Billboard:Destroy()       end
        if esp.Connection then esp.Connection:Disconnect()   end
        espInstances.players[player] = nil
    end
end

local function refreshPlayerESP()
    for player in pairs(espInstances.players) do removePlayerESP(player) end
    if not (Toggles.PlayerESP and Toggles.PlayerESP.Value) then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createPlayerESP(player)
        end
    end
end

-- ============================================
-- MOB ESP
-- ============================================
local function createMobESP(mob)
    if espInstances.mobs[mob] then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
    if not root then return end

    local espData = {}
    if Toggles.MobChams and Toggles.MobChams.Value then
        espData.Highlight = createHighlight(mob, Color3.fromRGB(255, 30, 30), Color3.fromRGB(255, 120, 120))
    end
    if Toggles.MobNames and Toggles.MobNames.Value then
        espData.Billboard, espData.NameLabel, espData.DistLabel = createBillboard(
            mob, root, mob.Name, Color3.fromRGB(255, 100, 100)
        )
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not mob or not mob.Parent then conn:Disconnect() return end
        local r = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
        if not r then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - r.Position).Magnitude
        local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
        local visible = dist <= maxDist
        if espData.Highlight then espData.Highlight.Enabled = visible end
        if espData.Billboard then
            espData.Billboard.Enabled = visible
            if espData.DistLabel then
                espData.DistLabel.Text = math.floor(dist) .. "m"
                espData.DistLabel.TextColor3 = getDistanceColor(dist)
            end
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum and espData.NameLabel then
                espData.NameLabel.Text = mob.Name .. " [" .. math.floor(hum.Health) .. "]"
            end
        end
    end)
    espData.Connection = conn
    espInstances.mobs[mob] = espData
end

local function removeMobESP(mob)
    local esp = espInstances.mobs[mob]
    if esp then
        if esp.Highlight  then esp.Highlight:Destroy()     end
        if esp.Billboard  then esp.Billboard:Destroy()     end
        if esp.Connection then esp.Connection:Disconnect() end
        espInstances.mobs[mob] = nil
    end
end

local function refreshMobESP()
    for mob in pairs(espInstances.mobs) do removeMobESP(mob) end
    if not (Toggles.MobESP and Toggles.MobESP.Value) then return end
    if not charactersFolder then return end
    local playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
    for _, child in ipairs(charactersFolder:GetChildren()) do
        if child:IsA("Model") and not playerChars[child] then
            createMobESP(child)
        end
    end
end

-- ============================================
-- ITEM ESP
-- ============================================
local function createItemESP(item, category, color)
    if espInstances.items[item] then return end
    local mainPart = getItemMainPart(item)
    if not mainPart then return end

    local espData = { category = category }
    if Toggles.ItemChams and Toggles.ItemChams.Value then
        espData.Highlight = createHighlight(item, color, Color3.new(1, 1, 1))
    end
    if Toggles.ItemNames and Toggles.ItemNames.Value then
        espData.Billboard, espData.NameLabel, espData.DistLabel = createBillboard(
            item, mainPart, "[" .. category .. "] " .. item.Name, color
        )
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not item or not item.Parent then conn:Disconnect() return end
        local part = getItemMainPart(item)
        if not part then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - part.Position).Magnitude
        local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
        local visible = dist <= maxDist
        if espData.Highlight then espData.Highlight.Enabled = visible end
        if espData.Billboard then
            espData.Billboard.Enabled = visible
            if espData.DistLabel then
                espData.DistLabel.Text = math.floor(dist) .. "m"
                espData.DistLabel.TextColor3 = getDistanceColor(dist)
            end
        end
    end)
    espData.Connection = conn
    espInstances.items[item] = espData
end

local function removeItemESP(item)
    local esp = espInstances.items[item]
    if esp then
        if esp.Highlight  then esp.Highlight:Destroy()     end
        if esp.Billboard  then esp.Billboard:Destroy()     end
        if esp.Connection then esp.Connection:Disconnect() end
        espInstances.items[item] = nil
    end
end

local function refreshItemESP()
    for item in pairs(espInstances.items) do removeItemESP(item) end
    if not droppedItemsFolder then return end
    for _, item in ipairs(droppedItemsFolder:GetChildren()) do
        if item:IsA("Model") then
            local name = item.Name
            if Toggles.GunESP      and Toggles.GunESP.Value      and table.find(gunNames,      name) then createItemESP(item, "Gun",      Color3.fromRGB(255, 50, 50))
            elseif Toggles.MeleeESP   and Toggles.MeleeESP.Value   and table.find(meleeNames,   name) then createItemESP(item, "Melee",   Color3.fromRGB(255, 165, 0))
            elseif Toggles.MedicalESP and Toggles.MedicalESP.Value and table.find(medicalNames, name) then createItemESP(item, "Medical", Color3.fromRGB(0, 255, 100))
            elseif Toggles.ArmorESP   and Toggles.ArmorESP.Value   and table.find(armorNames,   name) then createItemESP(item, "Armor",   Color3.fromRGB(0, 150, 255))
            elseif Toggles.FoodESP    and Toggles.FoodESP.Value    and table.find(foodNames,    name) then createItemESP(item, "Food",    Color3.fromRGB(150, 255, 50))
            elseif Toggles.ResourceESP and Toggles.ResourceESP.Value and table.find(resourceNames, name) then createItemESP(item, "Resource", Color3.fromRGB(0, 255, 255))
            end
        end
    end
end

-- ============================================
-- STRUCTURE ESP
-- ============================================
local function createStructureESP(structure)
    if espInstances.structures[structure] then return end
    local mainPart = structure.PrimaryPart or getItemMainPart(structure)
    if not mainPart then return end

    local espData = {}
    if Toggles.StructureChams and Toggles.StructureChams.Value then
        espData.Highlight = createHighlight(structure, Color3.fromRGB(0, 200, 150), Color3.fromRGB(100, 255, 200))
    end
    if Toggles.StructureNames and Toggles.StructureNames.Value then
        espData.Billboard, espData.NameLabel, espData.DistLabel = createBillboard(
            structure, mainPart, "[STRUCT] " .. structure.Name, Color3.fromRGB(0, 255, 200)
        )
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not structure or not structure.Parent then conn:Disconnect() return end
        local part = structure.PrimaryPart or getItemMainPart(structure)
        if not part then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - part.Position).Magnitude
        local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
        local visible = dist <= maxDist
        if espData.Highlight then espData.Highlight.Enabled = visible end
        if espData.Billboard then
            espData.Billboard.Enabled = visible
            if espData.DistLabel then
                espData.DistLabel.Text = math.floor(dist) .. "m"
                espData.DistLabel.TextColor3 = getDistanceColor(dist)
            end
        end
    end)
    espData.Connection = conn
    espInstances.structures[structure] = espData
end

local function removeStructureESP(structure)
    local esp = espInstances.structures[structure]
    if esp then
        if esp.Highlight  then esp.Highlight:Destroy()     end
        if esp.Billboard  then esp.Billboard:Destroy()     end
        if esp.Connection then esp.Connection:Disconnect() end
        espInstances.structures[structure] = nil
    end
end

local function refreshStructureESP()
    for s in pairs(espInstances.structures) do removeStructureESP(s) end
    if not (Toggles.StructureESP and Toggles.StructureESP.Value) then return end
    if not structuresFolder then return end
    for _, child in ipairs(structuresFolder:GetDescendants()) do
        if child:IsA("Model") then createStructureESP(child) end
    end
end

-- ============================================
-- CRATE ESP
-- ============================================
local function createCrateESP(crate)
    if espInstances.crates[crate] then return end
    local mainPart = crate:IsA("BasePart") and crate or getItemMainPart(crate)
    if not mainPart then return end

    local espData = {}
    espData.Highlight = createHighlight(crate, Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 200, 100))
    espData.Billboard, espData.NameLabel, espData.DistLabel = createBillboard(
        crate, mainPart, "[CRATE] " .. crate.Name, Color3.fromRGB(255, 140, 0)
    )

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not crate or not crate.Parent then conn:Disconnect() return end
        local part = crate:IsA("BasePart") and crate or getItemMainPart(crate)
        if not part then return end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local dist = (myRoot.Position - part.Position).Magnitude
        local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
        local visible = dist <= maxDist
        if espData.Highlight then espData.Highlight.Enabled = visible end
        if espData.Billboard then
            espData.Billboard.Enabled = visible
            if espData.DistLabel then
                espData.DistLabel.Text = math.floor(dist) .. "m"
                espData.DistLabel.TextColor3 = getDistanceColor(dist)
            end
        end
    end)
    espData.Connection = conn
    espInstances.crates[crate] = espData
end

local function removeCrateESP(crate)
    local esp = espInstances.crates[crate]
    if esp then
        if esp.Highlight  then esp.Highlight:Destroy()     end
        if esp.Billboard  then esp.Billboard:Destroy()     end
        if esp.Connection then esp.Connection:Disconnect() end
        espInstances.crates[crate] = nil
    end
end

local function refreshCrateESP()
    for c in pairs(espInstances.crates) do removeCrateESP(c) end
    if not (Toggles.CrateESP and Toggles.CrateESP.Value) then return end
    if not cratesFolder then return end
    for _, child in ipairs(cratesFolder:GetChildren()) do
        createCrateESP(child)
    end
end

-- ============================================
-- MOVEMENT FUNCTIONS
-- ============================================
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end
    humanoid.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = rootPart
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 9000
    flyBG.CFrame = Camera.CFrame
    flyBG.Parent = rootPart
    flyActive = true
end

local function stopFly()
    flyActive = false
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

local function startAutoSprint()
    if autoSprintActive then return end
    autoSprintActive = true
    pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end)
end

local function stopAutoSprint()
    if not autoSprintActive then return end
    autoSprintActive = false
    pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end)
end

-- ============================================
-- COMBAT FUNCTIONS
-- ============================================
local function expandHitboxes()
    if not charactersFolder then return end
    local myChar = LocalPlayer.Character
    for _, char in ipairs(charactersFolder:GetChildren()) do
        if char ~= myChar and isEnemy(char) then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and not hitboxExpandedParts[part] then
                    hitboxExpandedParts[part] = part.Size
                    local size = Options.HitboxSize and Options.HitboxSize.Value or 5
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = 0.85
                end
            end
        end
    end
end

local function restoreHitboxes()
    for part, origSize in pairs(hitboxExpandedParts) do
        if part and part.Parent then part.Size = origSize end
    end
    hitboxExpandedParts = {}
end

local function getNearestTarget(maxRange)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if not charactersFolder then return nil end
    local playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
    local nearest, nearestDist = nil, maxRange or math.huge
    for _, mob in ipairs(charactersFolder:GetChildren()) do
        if mob ~= char and not playerChars[mob] then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
            local mobHum  = mob:FindFirstChildOfClass("Humanoid")
            if mobRoot and mobHum and mobHum.Health > 0 then
                local dist = (mobRoot.Position - hrp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = mob
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ============================================
-- KILL AURA (FIXED)
-- ============================================
local weaponSwingSpeeds = {
    ["Knife"]        = 0.25,
    ["Katana"]       = 0.30,
    ["Crowbar"]      = 0.35,
    ["Chainsaw"]     = 0.35,
    ["Hatchet"]      = 0.40,
    ["Scythe"]       = 0.40,
    ["Spear"]        = 0.40,
    ["Bat"]          = 0.45,
    ["Spiked Bat"]   = 0.45,
    ["Riot Shield"]  = 0.50,
    ["Fire Axe"]     = 0.55,
    ["Sledgehammer"] = 0.60,
}

local function getWeaponSwingSpeed()
    local char = LocalPlayer.Character
    if not char then return 0.5 end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return 0.5 end
    local name = tool.Name
    if weaponSwingSpeeds[name] then return weaponSwingSpeeds[name] end
    for wName, speed in pairs(weaponSwingSpeeds) do
        if name:lower():find(wName:lower()) then return speed end
    end
    return 0.5
end

local function findTargetsInRange(range)
    local char = LocalPlayer.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    if not charactersFolder then return {} end

    local playerCharSet = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerCharSet[p.Character] = true end
    end

    local targets = {}
    local myPos   = hrp.Position

    for _, mob in ipairs(charactersFolder:GetChildren()) do
        if mob == char then continue end
        if playerCharSet[mob] then continue end
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        local mobHum = mob:FindFirstChildOfClass("Humanoid")
        if not mobHRP or not mobHum then continue end
        if mobHum.Health <= 0 then continue end
        local dist = (mobHRP.Position - myPos).Magnitude
        if dist <= range then
            table.insert(targets, {
                mob       = mob,
                dist      = dist,
                health    = mobHum.Health,
                maxHealth = mobHum.MaxHealth,
            })
        end
    end

    local priority = Options.KillAuraPriority and Options.KillAuraPriority.Value or "Nearest"
    if priority == "Nearest"    then table.sort(targets, function(a, b) return a.dist   < b.dist   end)
    elseif priority == "Lowest HP"  then table.sort(targets, function(a, b) return a.health < b.health end)
    elseif priority == "Highest HP" then table.sort(targets, function(a, b) return a.health > b.health end)
    end
    return targets
end

local function autoEquipWeapon()
    local char = LocalPlayer.Character
    if not char then return false end
    if char:FindFirstChildOfClass("Tool") then return true end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    local bestTool, bestSpeed = nil, math.huge
    for _, tool in ipairs(backpack:GetChildren()) do
        if not tool:IsA("Tool") then continue end
        if not (tool:FindFirstChild("Swing") or tool:FindFirstChild("HitTargets") or tool:FindFirstChild("RemoteClick")) then continue end
        local speed = weaponSwingSpeeds[tool.Name] or 0.5
        for wName, s in pairs(weaponSwingSpeeds) do
            if tool.Name:lower():find(wName:lower()) then speed = s break end
        end
        if speed < bestSpeed then bestSpeed = speed bestTool = tool end
    end
    if bestTool then
        pcall(function() bestTool.Parent = char end)
        return true
    end
    return false
end

local function stopKillAura()
    if killAuraConn then killAuraConn:Disconnect() killAuraConn = nil end
    killAuraLastSwing   = 0
    killAuraCurrentTarget  = nil
    killAuraTargetDistance = nil
    if killAuraIndicatorLine   then killAuraIndicatorLine.Visible   = false end
    if killAuraIndicatorCircle then killAuraIndicatorCircle.Visible = false end
    pcall(function() if setsimulationradius then setsimulationradius(50, 300) end end)
end

local function startKillAura()
    stopKillAura()

    -- Drawing indicators (safe pcall – Drawing may not exist on all executors)
    pcall(function()
        if not killAuraIndicatorLine then
            killAuraIndicatorLine           = Drawing.new("Line")
            killAuraIndicatorLine.Thickness = 1.5
            killAuraIndicatorLine.Color     = Color3.fromRGB(255, 55, 55)
            killAuraIndicatorLine.Transparency = 0.65
            killAuraIndicatorLine.Visible   = false
        end
        if not killAuraIndicatorCircle then
            killAuraIndicatorCircle           = Drawing.new("Circle")
            killAuraIndicatorCircle.Thickness = 1.5
            killAuraIndicatorCircle.Color     = Color3.fromRGB(255, 55, 55)
            killAuraIndicatorCircle.Transparency = 0.55
            killAuraIndicatorCircle.Filled    = false
            killAuraIndicatorCircle.Visible   = false
        end
    end)

    pcall(function() if setsimulationradius then setsimulationradius(1000, 1000) end end)

    killAuraConn = RunService.Heartbeat:Connect(function()
        -- Guard: bail immediately if the toggle was turned off
        if not (Toggles.KillAura and Toggles.KillAura.Value) then
            killAuraCurrentTarget = nil
            if killAuraIndicatorLine   then killAuraIndicatorLine.Visible   = false end
            if killAuraIndicatorCircle then killAuraIndicatorCircle.Visible = false end
            return
        end

        local ok, err = pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Auto-equip
            local tool = char:FindFirstChildOfClass("Tool")
            if not tool and Toggles.KillAuraAutoEquip and Toggles.KillAuraAutoEquip.Value then
                autoEquipWeapon()
                tool = char:FindFirstChildOfClass("Tool")
            end

            if not tool then
                killAuraCurrentTarget = nil
                if killAuraIndicatorLine   then killAuraIndicatorLine.Visible   = false end
                if killAuraIndicatorCircle then killAuraIndicatorCircle.Visible = false end
                return
            end

            local swing       = tool:FindFirstChild("Swing")
            local hitTargets  = tool:FindFirstChild("HitTargets")
            local remoteClick = tool:FindFirstChild("RemoteClick")

            local baseRange   = Options.KillAuraRange and Options.KillAuraRange.Value or 6
            local useExtended = Toggles.KillAuraExtendedRange and Toggles.KillAuraExtendedRange.Value
            local attackRange = useExtended and (baseRange + 2) or baseRange

            local targets = findTargetsInRange(attackRange)
            killAuraCurrentTarget  = targets[1] and targets[1].mob  or nil
            killAuraTargetDistance = targets[1] and targets[1].dist or nil

            -- Visual indicator
            local showIndicator = Toggles.KillAuraShowIndicator and Toggles.KillAuraShowIndicator.Value
            if showIndicator and killAuraCurrentTarget and killAuraIndicatorLine and killAuraIndicatorCircle then
                local tHRP = killAuraCurrentTarget:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    local sp, onScreen = Camera:WorldToViewportPoint(tHRP.Position)
                    if onScreen and sp.Z > 0 then
                        local vp     = Camera.ViewportSize
                        local center = Vector2.new(vp.X / 2, vp.Y)
                        local tgt    = Vector2.new(sp.X, sp.Y)
                        killAuraIndicatorLine.From    = center
                        killAuraIndicatorLine.To      = tgt
                        killAuraIndicatorLine.Visible = true
                        local radius = math.clamp(1200 / math.max(killAuraTargetDistance, 1), 8, 40)
                        killAuraIndicatorCircle.Position = tgt
                        killAuraIndicatorCircle.Radius   = radius
                        killAuraIndicatorCircle.Visible  = true
                    else
                        killAuraIndicatorLine.Visible   = false
                        killAuraIndicatorCircle.Visible = false
                    end
                end
            else
                if killAuraIndicatorLine   then killAuraIndicatorLine.Visible   = false end
                if killAuraIndicatorCircle then killAuraIndicatorCircle.Visible = false end
            end

            if #targets == 0 then return end

            -- Swing cooldown
            local weaponSpeed        = getWeaponSwingSpeed()
            local userSwingRate      = Options.KillAuraSwingRate and Options.KillAuraSwingRate.Value or weaponSpeed
            local effectiveSwingRate = math.max(weaponSpeed, userSwingRate)
            local now = tick()
            if now - killAuraLastSwing < effectiveSwingRate then return end

            -- Build mob list
            local mobModels = {}
            for _, t in ipairs(targets) do table.insert(mobModels, t.mob) end

            local attackSuccess = false

            if swing and hitTargets then
                local s1, e1 = pcall(function() swing:FireServer() end)
                if s1 then
                    killAuraLastSwing = now
                    attackSuccess = true
                    local s2, e2 = pcall(function() hitTargets:FireServer(mobModels) end)
                    if not s2 then warn("[KillAura] HitTargets error: " .. tostring(e2)) end
                else
                    warn("[KillAura] Swing error: " .. tostring(e1))
                end
            elseif remoteClick then
                local s, e = pcall(function() remoteClick:FireServer(targets[1].mob) end)
                attackSuccess = s
                if not s then warn("[KillAura] RemoteClick error: " .. tostring(e)) end
            end

            if attackSuccess and killAuraLastSwing ~= now then
                killAuraLastSwing = now
            end
        end)

        if not ok then warn("[KillAura] Frame error: " .. tostring(err)) end
    end)
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
local function enableFullbright()
    if not originalLighting.stored then
        originalLighting.Brightness    = Lighting.Brightness
        originalLighting.Ambient       = Lighting.Ambient
        originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        originalLighting.ClockTime     = Lighting.ClockTime
        originalLighting.FogEnd        = Lighting.FogEnd
        originalLighting.FogStart      = Lighting.FogStart
        originalLighting.GlobalShadows = Lighting.GlobalShadows
        originalLighting.stored        = true
    end
    Lighting.Brightness    = 2
    Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.ClockTime     = 14
    Lighting.FogEnd        = 100000
    Lighting.FogStart      = 0
    Lighting.GlobalShadows = false
end

local function disableFullbright()
    if originalLighting.stored then
        Lighting.Brightness    = originalLighting.Brightness
        Lighting.Ambient       = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ClockTime     = originalLighting.ClockTime
        Lighting.FogEnd        = originalLighting.FogEnd
        Lighting.FogStart      = originalLighting.FogStart
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
end

local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    antiAFKConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() antiAFKConn = nil end
end

-- ============================================
-- CREATE WINDUI WINDOW
-- ============================================
local Window = WindUI:CreateWindow({
    Title        = "STA",
    Icon         = "leaf",
    Author       = "Dwine",
    Folder       = "STA",
    Size         = UDim2.fromOffset(580, 460),
    Theme        = "Dark",
    SideBarWidth = 180,
    HasOutline   = true,
    KeySystem    = false,

    -- Native WindUI open/close pill button (replaces all custom toggle code)
    OpenButton = {
        Title           = "STA",
        Enabled         = true,
        Draggable       = true,
        OnlyMobile      = false,
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 2,
        Scale           = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#00DC50"),
            Color3.fromHex("#a855f7")
        ),
    },
})

Window:Tag({
    Title = "v2.1",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13, -- from 0 to 13
})

WindUI:Notify({
    Title    = "STA",
    Content  = "Script loaded successfully!",
    Duration = 5,
})

-- ============================================
-- TABS
-- ============================================
local Tabs = {
    ESP      = Window:Tab({ Title = "ESP",      Icon = "eye"       }),
    Combat   = Window:Tab({ Title = "Combat",   Icon = "swords"    }),
    Movement = Window:Tab({ Title = "Movement", Icon = "footprints" }),
	Misc     = Window:Tab({ Title = "Misc",     Icon = "settings"  }),
	Exploit  = Window:Tab({ Title = "Exploit",  Icon = "zap"        }),
}

-- ============================================
-- ESP TAB
-- ============================================
local ESPSettingsSection = Tabs.ESP:Section({ Title = "ESP Settings" })

ESPSettingsSection:Slider({
    Title = "Max Distance",
    Value = { Min = 100, Max = 2000, Default = 500 },
    Callback = function(value) Options.ESPMaxDistance = { Value = value } end,
})

ESPSettingsSection:Slider({
    Title = "Text Size",
    Value = { Min = 8, Max = 24, Default = 10 },
    Callback = function(value) espConfig.textSize = value end,
})

-- Player ESP
local PlayerESPSection = Tabs.ESP:Section({ Title = "Player ESP" })

PlayerESPSection:Toggle({
    Title = "Player ESP", Default = false,
    Callback = function(value) Toggles.PlayerESP = { Value = value } refreshPlayerESP() end,
})
PlayerESPSection:Toggle({
    Title = "Player Chams", Default = false,
    Callback = function(value) Toggles.PlayerChams = { Value = value } refreshPlayerESP() end,
})
PlayerESPSection:Toggle({
    Title = "Player Names", Default = false,
    Callback = function(value) Toggles.PlayerNames = { Value = value } refreshPlayerESP() end,
})

-- Mob ESP
local MobESPSection = Tabs.ESP:Section({ Title = "Mob ESP" })

MobESPSection:Toggle({
    Title = "Mob ESP", Default = false,
    Callback = function(value) Toggles.MobESP = { Value = value } refreshMobESP() end,
})
MobESPSection:Toggle({
    Title = "Mob Chams", Default = false,
    Callback = function(value) Toggles.MobChams = { Value = value } refreshMobESP() end,
})
MobESPSection:Toggle({
    Title = "Mob Names", Default = false,
    Callback = function(value) Toggles.MobNames = { Value = value } refreshMobESP() end,
})

-- Item ESP
local ItemESPSection = Tabs.ESP:Section({ Title = "Item ESP" })

ItemESPSection:Toggle({ Title = "Item Chams", Default = false,
    Callback = function(v) Toggles.ItemChams = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Item Names", Default = false,
    Callback = function(v) Toggles.ItemNames = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Gun ESP",      Default = false,
    Callback = function(v) Toggles.GunESP      = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Melee ESP",    Default = false,
    Callback = function(v) Toggles.MeleeESP    = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Medical ESP",  Default = false,
    Callback = function(v) Toggles.MedicalESP  = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Armor ESP",    Default = false,
    Callback = function(v) Toggles.ArmorESP    = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Food ESP",     Default = false,
    Callback = function(v) Toggles.FoodESP     = { Value = v } refreshItemESP() end })
ItemESPSection:Toggle({ Title = "Resource ESP", Default = false,
    Callback = function(v) Toggles.ResourceESP = { Value = v } refreshItemESP() end })

-- Structure & Crate ESP
local StructureESPSection = Tabs.ESP:Section({ Title = "Structures & Crates" })

StructureESPSection:Toggle({ Title = "Structure ESP",   Default = false,
    Callback = function(v) Toggles.StructureESP   = { Value = v } refreshStructureESP() end })
StructureESPSection:Toggle({ Title = "Structure Chams", Default = false,
    Callback = function(v) Toggles.StructureChams = { Value = v } refreshStructureESP() end })
StructureESPSection:Toggle({ Title = "Structure Names", Default = false,
    Callback = function(v) Toggles.StructureNames = { Value = v } refreshStructureESP() end })
StructureESPSection:Toggle({ Title = "Crate ESP",       Default = false,
    Callback = function(v) Toggles.CrateESP       = { Value = v } refreshCrateESP()     end })

-- ============================================
-- COMBAT TAB  (FIXED Kill Aura)
-- ============================================
local CombatSection = Tabs.Combat:Section({ Title = "Kill Aura" })

CombatSection:Toggle({
    Title   = "Kill Aura",
    Default = false,
    Callback = function(value)
        Toggles.KillAura = { Value = value }
        if value then
            startKillAura()
            WindUI:Notify({ Title = "Kill Aura", Content = "Enabled", Duration = 2 })
        else
            stopKillAura()
            WindUI:Notify({ Title = "Kill Aura", Content = "Disabled", Duration = 2 })
        end
    end,
})

CombatSection:Dropdown({
    Title  = "Target Priority",
    Values = { "Nearest", "Lowest HP", "Highest HP" },
    Default = 1,
    Callback = function(value)
        Options.KillAuraPriority = { Value = value }
    end,
})

CombatSection:Toggle({
    Title   = "Auto-Equip Weapon",
    Default = false,
    Callback = function(value) Toggles.KillAuraAutoEquip = { Value = value } end,
})

CombatSection:Toggle({
    Title   = "Show Target Indicator",
    Default = true,
    Callback = function(value) Toggles.KillAuraShowIndicator = { Value = value } end,
})

CombatSection:Toggle({
    Title   = "Extended Range (+2 studs)",
    Default = true,
    Callback = function(value) Toggles.KillAuraExtendedRange = { Value = value } end,
})

CombatSection:Slider({
    Title = "Base Range",
    Value = { Min = 1, Max = 20, Default = 6 },
    Callback = function(value) Options.KillAuraRange = { Value = value } end,
})

CombatSection:Slider({
    Title = "Swing Delay (s)",
    Value = { Min = 10, Max = 100, Default = 50 },  -- stored as /100 = 0.1–1.0
    Callback = function(value)
        Options.KillAuraSwingRate = { Value = value / 100 }
    end,
})

-- Aimbot
local AimbotSection = Tabs.Combat:Section({ Title = "Aimbot" })

AimbotSection:Toggle({
    Title = "Aimbot", Default = false,
    Callback = function(value) Toggles.Aimbot = { Value = value } end,
})
AimbotSection:Slider({
    Title = "Aimbot FOV",
    Value = { Min = 10, Max = 500, Default = 100 },
    Callback = function(value) Options.AimbotFOV = { Value = value } end,
})
AimbotSection:Slider({
    Title = "Aimbot Smoothness",
    Value = { Min = 0, Max = 100, Default = 30 },
    Callback = function(value) Options.AimbotSmoothness = { Value = value / 100 } end,
})

-- Hitbox
local HitboxSection = Tabs.Combat:Section({ Title = "Hitbox Expander" })

HitboxSection:Toggle({
    Title = "Hitbox Expander", Default = false,
    Callback = function(value)
        Toggles.HitboxExpander = { Value = value }
        if not value then restoreHitboxes() end
    end,
})
HitboxSection:Slider({
    Title = "Hitbox Size",
    Value = { Min = 2, Max = 30, Default = 5 },
    Callback = function(value)
        Options.HitboxSize = { Value = value }
        if Toggles.HitboxExpander and Toggles.HitboxExpander.Value then
            restoreHitboxes()
        end
    end,
})

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MovementSection = Tabs.Movement:Section({ Title = "Movement Hacks" })

MovementSection:Toggle({
    Title = "Speed Hack", Default = false,
    Callback = function(value)
        Toggles.SpeedHack = { Value = value }
        if not value then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = originalValues.walkSpeed end
            end
        end
    end,
})
MovementSection:Slider({
    Title = "Walk Speed",
    Value = { Min = 16, Max = 200, Default = 50 },
    Callback = function(value) Options.SpeedValue = { Value = value } end,
})
MovementSection:Toggle({
    Title = "Infinite Jump", Default = false,
    Callback = function(value) Toggles.InfJump = { Value = value } end,
})
MovementSection:Toggle({
    Title = "NoClip", Default = false,
    Callback = function(value) Toggles.NoClip = { Value = value } end,
})
MovementSection:Toggle({
    Title = "Fly", Default = false,
    Callback = function(value)
        Toggles.Fly = { Value = value }
        if value then startFly() else stopFly() end
    end,
})
MovementSection:Slider({
    Title = "Fly Speed",
    Value = { Min = 10, Max = 300, Default = 50 },
    Callback = function(value) Options.FlySpeed = { Value = value } end,
})
MovementSection:Toggle({
    Title = "Auto Sprint", Default = false,
    Callback = function(value)
        Toggles.AutoSprint = { Value = value }
        if value then startAutoSprint() else stopAutoSprint() end
    end,
})
MovementSection:Toggle({
    Title = "Bunny Hop", Default = false,
    Callback = function(value)
        Toggles.BunnyHop = { Value = value }
        bhopActive = value
    end,
})



-- ============================================
-- MISC TAB
-- ============================================
local UtilitySection = Tabs.Misc:Section({ Title = "Utilities" })

UtilitySection:Toggle({
    Title = "Anti-AFK", Default = true,
    Callback = function(value)
        Toggles.AntiAFK = { Value = value }
        if value then startAntiAFK() else stopAntiAFK() end
    end,
})
UtilitySection:Toggle({
    Title = "Fullbright", Default = false,
    Callback = function(value)
        Toggles.Fullbright = { Value = value }
        if value then enableFullbright() else disableFullbright() end
    end,
})
UtilitySection:Toggle({
    Title = "Remove Fog", Default = false,
    Callback = function(value)
        Toggles.RemoveFog = { Value = value }
        if value then
            if not originalFog.stored then
                originalFog.FogEnd   = Lighting.FogEnd
                originalFog.FogStart = Lighting.FogStart
                originalFog.stored   = true
            end
            Lighting.FogEnd   = 100000
            Lighting.FogStart = 0
        else
            if originalFog.stored then
                Lighting.FogEnd   = originalFog.FogEnd
                Lighting.FogStart = originalFog.FogStart
            end
        end
    end,
})
UtilitySection:Button({
    Title = "Server Hop",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})
UtilitySection:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

local FPSSection = Tabs.Misc:Section({ Title = "Performance" })

FPSSection:Slider({
    Title = "FPS Cap",
    Value = { Min = 30, Max = 360, Default = 60 },
    Callback = function(value)
        Options.FPSCap = { Value = value }
        if Toggles.FPSUnlock and Toggles.FPSUnlock.Value then
            pcall(function() if setfpscap then setfpscap(value) end end)
        end
    end,
})
FPSSection:Toggle({
    Title = "Unlock FPS", Default = false,
    Callback = function(value)
        Toggles.FPSUnlock = { Value = value }
        pcall(function()
            if setfpscap then
                setfpscap(value and (Options.FPSCap and Options.FPSCap.Value or 144) or 60)
            end
        end)
    end,
})

-- ============================================
-- EXPLOIT TAB  (NEW)
-- ============================================
 
-- ── Invincible ──────────────────────────────
local InvincibleSection = Tabs.Exploit:Section({ Title = "Invincible (Visual Only)" })
 
InvincibleSection:Toggle({
    Title   = "Invincible",
    Default = false,
    Callback = function(value)
        Toggles.Invincible = { Value = value }
        if value then
            startInvincible()
            WindUI:Notify({
                Title   = "Invincible",
                Content = "ON — health locked at max (client-side).\nNote: server-authoritative games may still process damage.",
                Duration = 4,
            })
        else
            stopInvincible()
            WindUI:Notify({ Title = "Invincible", Content = "OFF", Duration = 2 })
        end
    end,
})
 
-- ── Bring Pickup Item ────────────────────────
local BringPickupSection = Tabs.Exploit:Section({ Title = "Bring Pickup Item" })
 
BringPickupSection:Toggle({
    Title   = "Bring Pickup Item",
    Default = false,
    Callback = function(value)
        Toggles.BringPickupItem = { Value = value }
        if value then
            startBringPickup()
            WindUI:Notify({
                Title   = "Bring Pickup",
                Content = "Active — teleporting to items.\nUses 3 pickup methods in parallel.",
                Duration = 3,
            })
        else
            stopBringPickup()
            WindUI:Notify({ Title = "Bring Pickup", Content = "Stopped", Duration = 2 })
        end
    end,
})
 
BringPickupSection:Toggle({
    Title   = "All Items (not just weapons/medical)",
    Default = false,
    Callback = function(value)
        Toggles.BringAllPickup = { Value = value }
    end,
})
 
BringPickupSection:Label({ Title = "Default filter: Guns, Melee, Medical, Armor" })
BringPickupSection:Label({ Title = "Methods: PickUpItem remote + TouchInterest + ProximityPrompt" })
BringPickupSection:Label({ Title = "Auto-stops after 3 consecutive failures (backpack full)." })

-- ============================================
-- MAIN LOOPS
-- ============================================

-- Speed Hack
local speedConn = RunService.Stepped:Connect(function()
    if not (Toggles.SpeedHack and Toggles.SpeedHack.Value) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Options.SpeedValue and Options.SpeedValue.Value or 50 end
end)
table.insert(connections, speedConn)

-- NoClip
local noclipConn = RunService.Heartbeat:Connect(function()
    if not (Toggles.NoClip and Toggles.NoClip.Value) then
        noclipLastCFrame = nil
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)
table.insert(connections, noclipConn)

-- Fly
local flyConn = RunService.RenderStepped:Connect(function()
    if not (Toggles.Fly and Toggles.Fly.Value) or not flyActive then return end
    local char = LocalPlayer.Character
    if not char then stopFly() return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local speed = Options.FlySpeed and Options.FlySpeed.Value or 50
    local dir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W)          then dir = dir + Camera.CFrame.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.S)          then dir = dir - Camera.CFrame.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.A)          then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D)          then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.new(0, 1, 0)     end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.new(0, 1, 0)     end
    if dir.Magnitude > 0 then dir = dir.Unit end
    if flyBV then flyBV.Velocity = dir * speed end
    if flyBG then flyBG.CFrame   = Camera.CFrame end
end)
table.insert(connections, flyConn)

-- Infinite Jump
local jumpConn = UserInputService.JumpRequest:Connect(function()
    if Toggles.InfJump and Toggles.InfJump.Value then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)
table.insert(connections, jumpConn)

-- Bunny Hop
local bhopConn = RunService.RenderStepped:Connect(function()
    if not bhopActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.MoveDirection.Magnitude > 0.1 then
        if hum:GetState() == Enum.HumanoidStateType.Running then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
table.insert(connections, bhopConn)

-- Hitbox Expander
local hitboxConn = RunService.RenderStepped:Connect(function()
    if not (Toggles.HitboxExpander and Toggles.HitboxExpander.Value) then return end
    expandHitboxes()
end)
table.insert(connections, hitboxConn)

-- Aimbot
local aimbotLoopConn = RunService.RenderStepped:Connect(function()
    if not (Toggles.Aimbot and Toggles.Aimbot.Value) then return end
    local target = getNearestTarget(Options.AimbotFOV and Options.AimbotFOV.Value or 100)
    if not target then return end
    local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local smoothness = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 0.3
    local targetCF   = CFrame.lookAt(Camera.CFrame.Position, head.Position)
    Camera.CFrame    = Camera.CFrame:Lerp(targetCF, 1 - smoothness)
end)
table.insert(connections, aimbotLoopConn)

-- ============================================
-- FOLDER LISTENERS
-- ============================================
Players.PlayerAdded:Connect(function(player)
    if Toggles.PlayerESP and Toggles.PlayerESP.Value then
        player.CharacterAdded:Connect(function()
            task.wait(1)
            createPlayerESP(player)
        end)
    end
end)
Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

if charactersFolder then
    charactersFolder.ChildAdded:Connect(function(child)
        if Toggles.MobESP and Toggles.MobESP.Value then
            task.wait(0.2)
            local playerChars = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then playerChars[p.Character] = true end
            end
            if not playerChars[child] then createMobESP(child) end
        end
    end)
    charactersFolder.ChildRemoved:Connect(function(child)
        removeMobESP(child)
    end)
end

if droppedItemsFolder then
    droppedItemsFolder.ChildAdded:Connect(function(child)
        task.wait(0.2)
        local name = child.Name
        if     Toggles.GunESP      and Toggles.GunESP.Value      and table.find(gunNames,      name) then createItemESP(child, "Gun",      Color3.fromRGB(255, 50, 50))
        elseif Toggles.MeleeESP    and Toggles.MeleeESP.Value    and table.find(meleeNames,    name) then createItemESP(child, "Melee",    Color3.fromRGB(255, 165, 0))
        elseif Toggles.MedicalESP  and Toggles.MedicalESP.Value  and table.find(medicalNames,  name) then createItemESP(child, "Medical",  Color3.fromRGB(0, 255, 100))
        elseif Toggles.ArmorESP    and Toggles.ArmorESP.Value    and table.find(armorNames,    name) then createItemESP(child, "Armor",    Color3.fromRGB(0, 150, 255))
        elseif Toggles.FoodESP     and Toggles.FoodESP.Value     and table.find(foodNames,     name) then createItemESP(child, "Food",     Color3.fromRGB(150, 255, 50))
        elseif Toggles.ResourceESP and Toggles.ResourceESP.Value and table.find(resourceNames, name) then createItemESP(child, "Resource", Color3.fromRGB(0, 255, 255))
        end
    end)
    droppedItemsFolder.ChildRemoved:Connect(function(child)
        removeItemESP(child)
    end)
end

if structuresFolder then
    structuresFolder.DescendantAdded:Connect(function(child)
        if Toggles.StructureESP and Toggles.StructureESP.Value and child:IsA("Model") then
            task.wait(0.2)
            createStructureESP(child)
        end
    end)
    structuresFolder.DescendantRemoving:Connect(function(child)
        removeStructureESP(child)
    end)
end

if cratesFolder then
    cratesFolder.ChildAdded:Connect(function(child)
        if Toggles.CrateESP and Toggles.CrateESP.Value then
            task.wait(0.2)
            createCrateESP(child)
        end
    end)
    cratesFolder.ChildRemoved:Connect(function(child)
        removeCrateESP(child)
    end)
end

-- ============================================
-- CHARACTER HANDLERS
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 10)
    task.wait(0.5)
    if Toggles.Fly        and Toggles.Fly.Value        then startFly()        end
    if Toggles.AutoSprint and Toggles.AutoSprint.Value then startAutoSprint() end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if flyActive        then stopFly()        end
    if autoSprintActive then stopAutoSprint() end
end)

-- ============================================
-- INITIALIZATION
-- ============================================
startAntiAFK()

Options.ESPMaxDistance    = { Value = 500  }
Options.SpeedValue        = { Value = 50   }
Options.FlySpeed          = { Value = 50   }
Options.KillAuraRange     = { Value = 6    }
Options.KillAuraPriority  = { Value = "Nearest" }
Options.KillAuraSwingRate = { Value = 0.5  }
Options.AimbotFOV         = { Value = 100  }
Options.AimbotSmoothness  = { Value = 0.3  }
Options.HitboxSize        = { Value = 5    }
Options.FPSCap            = { Value = 144  }

-- Default toggle states (so the loops start in a known state)
Toggles.KillAura              = { Value = false }
Toggles.KillAuraAutoEquip     = { Value = false }
Toggles.KillAuraShowIndicator = { Value = true  }
Toggles.KillAuraExtendedRange = { Value = true  }
Toggles.BringPickupItem       = { Value = false }
Toggles.BringAllPickup        = { Value = false }
Toggles.Invincible            = { Value = false }

print("STA loaded successfully!")
