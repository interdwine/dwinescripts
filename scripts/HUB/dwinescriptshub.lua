local successUI, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not successUI or not WindUI then
    warn("[DWScript] WindUI failed to load!")
    return
end

--// Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local placeId = game.PlaceId

--// Script Map
local HUB = {
    [3678761576] = {
        name = "ENTRENCHED WW1",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/ENTRENCHED/FREE.lua" },
        }
    },
	[111549685046284] = {
        name = "Blue Lock Card Battles",
        scripts = {
            { label = "FREE", url = "loadstring(game:HttpGet("https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/BLBC/BLBCv1.lua"))()" },
        }
    },
    [90148635862803] = {
        name = "SURVIVE THE APOCALYPSE",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/SURVIVE%20THE%20APOCALYPSE/STAv2.lua" },
        }
    },
    [140270923132362] = {
        name = "TINY EMPIRES",
        scripts = {
            { label = "FREE", url = "https://raw.githubusercontent.com/interdwine/dwinescripts/refs/heads/main/scripts/TINY%20EMPIRES/TE.lua" },
        }
    },
}

--// Create Window (latest API)
local Window = WindUI:CreateWindow({
    Title = "DWScript Hub",
	Icon = "door-open",
    Author = "Dwine",
    Folder = "DWScript",
    Size = UDim2.fromOffset(520, 200),
    Theme = "Dark",
    Transparent = false
})

Window:OnDestroy(function()
    -- This function runs when the window is destroyed
    WindUI:Notification({
        Title = "DWScript Hub",
        Content = "Window has been destroyed.",
        Duration = 3
    })
end)
-- Add a tag
Window:Tag({
    Title = "v1",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13
})

if not Window then
    WindUI:Notification({
        Title = "DWScript Hub",
        Content = "Window creation failed!",
        Duration = 4
    })
    return
end

--// Games Tab
local Tab = Window:Tab({
    Title = "Games",
    Icon = "gamepad"
})

--// Section inside Games Tab
local Section = Tab:Section({
    Title = "Available Scripts"
})

--// Script Executor (Destroys UI after successful execution)
local function runScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local loadedFunc = loadstring(result)
        if loadedFunc then
            local ran, err = pcall(loadedFunc)
            if ran then
                WindUI:Notification({
                    Title = "DWScript",
                    Content = "Script executed successfully!",
                    Duration = 3
                })
                -- Destroy the entire UI after running the script
                if Window and Window.Destroy then
                    Window:Destroy()
                end
            else
                WindUI:Notification({
                    Title = "DWScript Error",
                    Content = err,
                    Duration = 3
                })
            end
        else
            WindUI:Notification({
                Title = "DWScript Error",
                Content = "loadstring failed!",
                Duration = 3
            })
        end
    else
        WindUI:Notification({
            Title = "DWScript Error",
            Content = "HTTP fetch failed!",
            Duration = 3
        })
    end
end

--// Add all games as buttons
for id, data in pairs(HUB) do
    for _, scriptData in pairs(data.scripts) do
        Section:Button({
            Title = data.name .. " [" .. scriptData.label .. "]",
            Desc = "Execute this script",
            Callback = function()
                runScript(scriptData.url)
            end
        })
    end
end

--// Notify on hub load
WindUI:Notify({
    Title = "DWScript Hub",
    Content = "Hub loaded successfully!",
    Duration = 4
})
