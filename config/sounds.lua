--[[
    cortex_soundtool Sound Database
    
    Enhanced version with comprehensive GTA V sound library.
    Loads 2,204+ sounds from JSON database with automatic categorization.
    
    Build Version Reference:
    - 1604: Arena War (Base FiveM support)
    - 2060: Los Santos Summer Special
    - 2189: Cayo Perico Heist
    - 2372: Los Santos Tuners
    - 2545: The Contract
    - 2612: Expanded & Enhanced
    - 2699: The Criminal Enterprise
    - 2802: Los Santos Drug Wars
    - 2944: San Andreas Mercenaries
    - 3095: The Chop Shop
    - 3258: Bottom Dollar Bounties
    - 3407: Agents of Sabotage
]]

Sounds = {}
Categories = {}
SoundSets = {}

local resourceName = GetCurrentResourceName()

local function categorizeSoundSet(soundSet)
    if not soundSet then return "Other" end
    local set = string.upper(soundSet)
    
    if set:find("HUD_FRONTEND") then return "HUD & Frontend" end
    if set:find("HUD_AWARDS") then return "Awards" end
    if set:find("HUD_MINI") then return "Mini-Games" end
    if set:find("DLC_") or set:find("dlc_") then return "DLC" end
    if set:find("GTAO_") then return "GTAO" end
    if set:find("MP_") then return "Multiplayer" end
    if set:find("FBI_HEIST") then return "Heists" end
    if set:find("PHONE") or set:find("Phone") then return "Phone" end
    if set:find("WASTED") then return "Wasted" end
    if set:find("PLAYER_SWITCH") then return "Player Switch" end
    if set:find("VEHICLES") or set:find("VEHICLE") then return "Vehicles" end
    if set:find("WEAPON") or set:find("GUN") then return "Weapons" end
    if set:find("AMBIENT") then return "Ambient" end
    if set:find("MUSIC") or set:find("RADIO") then return "Music" end
    if set:find("SPEECH") or set:find("VOICE") then return "Speech" end
    if set:find("CASINO") then return "Casino" end
    if set:find("BIKER") then return "Bikers" end
    if set:find("EXEC") then return "Executive" end
    if set:find("ARENA") then return "Arena War" end
    if set:find("SMUGGLER") then return "Smugglers" end
    if set:find("GUNRUNNING") then return "Gunrunning" end
    if set:find("DOOMSDAY") then return "Doomsday" end
    if set:find("AFTER_HOURS") or set:find("AFTERHOURS") or set:find("CLUB") then return "After Hours" end
    
    return "Other"
end

local function getBuildFromCategory(category)
    if category == "After Hours" then return 1604 end
    if category == "Arena War" then return 1604 end
    if category == "Casino" then return 2060 end
    if category == "Heists" then return 1604 end
    if category == "Bikers" then return 1604 end
    if category == "Executive" then return 1604 end
    if category == "Gunrunning" then return 1604 end
    if category == "Smugglers" then return 1604 end
    if category == "Doomsday" then return 1604 end
    return 1604
end

local function loadSoundDatabase()
    local jsonData = LoadResourceFile(resourceName, "config/sounds_database.json")
    if not jsonData then
        print("[cortex_soundtool] ERROR: Could not load sounds_database.json")
        return false
    end
    
    local success, sounds = pcall(function()
        return json.decode(jsonData)
    end)
    
    if not success or not sounds then
        print("[cortex_soundtool] ERROR: Failed to parse sounds_database.json")
        return false
    end
    
    local categoryCounts = {}
    local setList = {}
    
    for _, sound in ipairs(sounds) do
        local audioName = sound.AudioName
        local audioRef = sound.AudioRef
        
        -- Skip invalid entries where AudioRef is "0" (not a valid soundset)
        if audioName and audioRef and audioRef ~= "0" and audioRef ~= "" then
            local category = categorizeSoundSet(audioRef)
            
            table.insert(Sounds, {
                sound = audioName,
                set = audioRef,
                category = category,
                build = getBuildFromCategory(category),
                bank = nil
            })
            
            categoryCounts[category] = (categoryCounts[category] or 0) + 1
            
            if not setList[audioRef] then
                setList[audioRef] = true
                table.insert(SoundSets, audioRef)
            end
        end
    end
    
    for category, count in pairs(categoryCounts) do
        table.insert(Categories, {
            name = category,
            build = getBuildFromCategory(category),
            count = count
        })
 end
    
    table.sort(Sounds, function(a, b)
        return a.sound < b.sound
    end)
    
    table.sort(Categories, function(a, b)
        return a.name < b.name
    end)
    
    table.sort(SoundSets)
    
    print(string.format("[cortex_soundtool] Loaded %d sounds across %d categories with %d unique sound sets", 
        #Sounds, #Categories, #SoundSets))
    
    return true
end

BuildInfo = {
    [1604] = { name = "Arena War", date = "December 2018" },
    [2060] = { name = "Los Santos Summer Special", date = "August 2020" },
    [2189] = { name = "Cayo Perico Heist", date = "December 2020" },
    [2372] = { name = "Los Santos Tuners", date = "July 2021" },
    [2545] = { name = "The Contract", date = "December 2021" },
    [2612] = { name = "Expanded & Enhanced", date = "March 2022" },
    [2699] = { name = "The Criminal Enterprise", date = "July 2022" },
    [2802] = { name = "Los Santos Drug Wars", date = "December 2022" },
    [2944] = { name = "San Andreas Mercenaries", date = "June 2023" },
    [3095] = { name = "The Chop Shop", date = "December 2023" },
    [3258] = { name = "Bottom Dollar Bounties", date = "June 2024" },
    [3407] = { name = "Agents of Sabotage", date = "December 2024" },
}

loadSoundDatabase()
