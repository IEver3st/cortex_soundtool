local PlaySoundFrontend = PlaySoundFrontend
local PlaySoundFromCoord = PlaySoundFromCoord
local GetSoundId = GetSoundId
local ReleaseSoundId = ReleaseSoundId
local StopSound = StopSound
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local SetNuiFocus = SetNuiFocus
local SendNUIMessage = SendNUIMessage
local GetGameBuildNumber = GetGameBuildNumber
local CreateVehicle = CreateVehicle
local DeleteEntity = DeleteEntity
local SetEntityVisible = SetEntityVisible
local SetEntityCollision = SetEntityCollision
local FreezeEntityPosition = FreezeEntityPosition
local SetVehicleEngineOn = SetVehicleEngineOn
local ForceVehicleEngineAudio = ForceVehicleEngineAudio
local SetVehicleCurrentRpm = SetVehicleCurrentRpm
local DoesEntityExist = DoesEntityExist
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local NetworkSetEntityInvisibleToNetwork = NetworkSetEntityInvisibleToNetwork
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SetVehicleHasBeenOwnedByPlayer = SetVehicleHasBeenOwnedByPlayer
local SetVehicleNeedsToBeHotwired = SetVehicleNeedsToBeHotwired
local SetVehicleIsConsideredByPlayer = SetVehicleIsConsideredByPlayer
local SetEntityAlpha = SetEntityAlpha
local SetEntityLocallyInvisible = SetEntityLocallyInvisible
local SetEntityCoords = SetEntityCoords
local RequestScriptAudioBank = RequestScriptAudioBank
local ReleaseScriptAudioBank = ReleaseScriptAudioBank

local isUIOpen = false
local lastPlayedSound = nil
local currentSoundId = -1
local currentGameBuild = 0
local isPlaying = false
local previewVehicle = nil
local vehicleRpmThread = nil
local vehicleThreadId = 0
local currentAudioBank = nil

local function debugLog(message)
    if Config.Debug then
        print(string.format("[es_soundtester] %s", message))
    end
end

local function notify(message, isError)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function releaseCurrentAudioBank()
    if currentAudioBank then
        ReleaseScriptAudioBank(currentAudioBank)
        debugLog("Released audio bank: " .. currentAudioBank)
        currentAudioBank = nil
    end
end

local function loadAudioBank(bankName, timeout)
    if not bankName or bankName == "" then
        return true
    end
    
    if currentAudioBank == bankName then
        return true
    end
    
    releaseCurrentAudioBank()
    
    timeout = timeout or 2000
    local start = GetGameTimer()
    
    while not RequestScriptAudioBank(bankName, false) do
        if GetGameTimer() - start > timeout then
            debugLog("ERROR: Failed to load audio bank: " .. bankName)
            return false
        end
        Wait(10)
    end
    
    currentAudioBank = bankName
    debugLog("Loaded audio bank: " .. bankName)
    return true
end

local function stopCurrentSound()
    if currentSoundId ~= -1 then
        StopSound(currentSoundId)
        ReleaseSoundId(currentSoundId)
        currentSoundId = -1
        isPlaying = false
        debugLog("Stopped current sound")
        releaseCurrentAudioBank()
        return true
    end
    releaseCurrentAudioBank()
    return false
end

local function deletePreviewVehicle()
    vehicleThreadId = vehicleThreadId + 1
    vehicleRpmThread = nil
    
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetVehicleEngineOn(previewVehicle, false, true, false)
        SetEntityAsMissionEntity(previewVehicle, true, true)
        DeleteEntity(previewVehicle)
        previewVehicle = nil
        debugLog("Deleted preview vehicle")
    end
end

local function stopVehicleAudio()
    deletePreviewVehicle()
    isPlaying = false
    SendNUIMessage({ type = "vehicleStopped" })
    debugLog("Stopped vehicle audio")
end

local function requestModel(model, timeout)
    local hash = type(model) == "string" and joaat(model) or model
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local start = GetGameTimer()
    timeout = timeout or 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() - start > timeout then
            return false
        end
        Wait(0)
    end
    return true
end

local currentVehicleRpm = 0.5
local currentVehicleVolume = 1.0
local vehicleBaseCoords = nil

local function getVehicleDistance(volume)
    local baseDistance = 5.0
    local minDistance = 1.0
    local maxDistance = 15.0
    
    local distance = baseDistance / volume
    return math.max(minDistance, math.min(maxDistance, distance))
end

local function playVehicleAudio(audioName, modelName, rpm, volume)
    stopCurrentSound()
    deletePreviewVehicle()
    
    local model = modelName or "adder"
    currentVehicleRpm = math.min(0.99, rpm or 0.5)
    currentVehicleVolume = volume or 1.0
    
    debugLog(string.format("Starting vehicle audio - Model: %s, Audio: %s, RPM: %.0f%%, Volume: %.0f%%", 
        model, audioName or "default", currentVehicleRpm * 100, currentVehicleVolume * 100))
    
    if not requestModel(model, 5000) then
        debugLog("ERROR: Failed to load vehicle model: " .. model)
        notify("~r~Failed to load vehicle model", true)
        return false
    end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local zOffset = getVehicleDistance(currentVehicleVolume)
    
    vehicleBaseCoords = vector3(coords.x, coords.y, coords.z)
    previewVehicle = CreateVehicle(joaat(model), coords.x, coords.y, coords.z - zOffset, 0.0, false, false)
    
    if not previewVehicle or previewVehicle == 0 then
        debugLog("ERROR: Failed to create preview vehicle")
        notify("~r~Failed to create preview vehicle", true)
        SetModelAsNoLongerNeeded(joaat(model))
        return false
    end
    
    SetEntityVisible(previewVehicle, false, false)
    SetEntityCollision(previewVehicle, false, false)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleCanBeVisiblyDamaged(previewVehicle, false)
    FreezeEntityPosition(previewVehicle, true)
    SetEntityAlpha(previewVehicle, 0, false)
    SetEntityLocallyInvisible(previewVehicle)
    NetworkSetEntityInvisibleToNetwork(previewVehicle, true)
    SetVehicleHasBeenOwnedByPlayer(previewVehicle, true)
    SetVehicleNeedsToBeHotwired(previewVehicle, false)
    SetVehicleIsConsideredByPlayer(previewVehicle, false)
    
    if audioName and audioName ~= "" then
        ForceVehicleEngineAudio(previewVehicle, audioName)
    end
    
    SetVehicleEngineOn(previewVehicle, true, true, false)
    SetVehicleCurrentRpm(previewVehicle, currentVehicleRpm)
    
    SetModelAsNoLongerNeeded(joaat(model))
    
    isPlaying = true
    
    vehicleThreadId = vehicleThreadId + 1
    vehicleRpmThread = true
    local veh = previewVehicle
    local myThreadId = vehicleThreadId
    local startTime = GetGameTimer()
    
    CreateThread(function()
        Wait(50)
        while vehicleRpmThread and myThreadId == vehicleThreadId and veh and DoesEntityExist(veh) do
            if GetGameTimer() - startTime > (Config.VehiclePreviewDuration or 4000) then
                stopVehicleAudio()
                break
            end
            
            SetVehicleEngineOn(veh, true, true, false)
            SetVehicleCurrentRpm(veh, currentVehicleRpm)
            Wait(0)
        end
    end)
    
    debugLog(string.format("Vehicle audio started: %s (RPM: %.0f%%, Volume: %.0f%%)", 
        audioName or model, currentVehicleRpm * 100, currentVehicleVolume * 100))
    
    return true
end

local function setVehicleRpm(rpm)
    currentVehicleRpm = math.max(0.1, math.min(0.99, rpm))
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetVehicleCurrentRpm(previewVehicle, currentVehicleRpm)
        return true
    end
    return false
end

local function setVehicleVolume(volume)
    currentVehicleVolume = math.max(0.1, math.min(4.0, volume))
    if previewVehicle and DoesEntityExist(previewVehicle) and vehicleBaseCoords then
        local zOffset = getVehicleDistance(currentVehicleVolume)
        FreezeEntityPosition(previewVehicle, false)
        SetEntityCoords(previewVehicle, vehicleBaseCoords.x, vehicleBaseCoords.y, vehicleBaseCoords.z - zOffset, false, false, false, false)
        FreezeEntityPosition(previewVehicle, true)
        debugLog(string.format("Set vehicle volume to: %.0f%% (distance: %.1f)", currentVehicleVolume * 100, zOffset))
        return true
    end
    return false
end

local function getSoundDistance(volume)
    local baseDistance = 3.0
    local minDistance = 0.1
    local maxDistance = 25.0
    
    if volume <= 0 then
        return maxDistance
    end
    
    local distance = baseDistance / volume
    return math.max(minDistance, math.min(maxDistance, distance))
end

function PlaySound(soundName, soundSet, atPosition, volume, audioBank)
    if not soundName or soundName == "" then
        debugLog("ERROR: Sound name is empty or nil")
        notify("~r~Error: Invalid sound name", true)
        return false
    end
    
    if not soundSet or soundSet == "" then
        debugLog("ERROR: Sound set is empty or nil")
        notify("~r~Error: Invalid sound set", true)
        return false
    end
    
    local soundVolume = volume or Config.DefaultVolume
    soundVolume = math.max(0.0, math.min(4.0, soundVolume))
    
    stopCurrentSound()
    
    if audioBank and audioBank ~= "" then
        if not loadAudioBank(audioBank) then
            notify("~y~Warning: Could not load audio bank", false)
        end
    end
    
    currentSoundId = GetSoundId()
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local zOffset = getSoundDistance(soundVolume)
    
    PlaySoundFromCoord(currentSoundId, soundName, coords.x, coords.y, coords.z - zOffset, soundSet, false, 0, false)
    
    lastPlayedSound = {
        sound = soundName,
        set = soundSet,
        volume = soundVolume,
        bank = audioBank
    }
    
    isPlaying = true
    debugLog(string.format("Played sound: %s from set: %s (volume: %.0f%%, distance: %.1f)%s", soundName, soundSet, soundVolume * 100, zOffset, audioBank and (" [bank: " .. audioBank .. "]") or ""))
    
    return true
end

local function replayLastSound()
    if not lastPlayedSound then
        notify("~y~No sound has been played yet", false)
        debugLog("Replay requested but no sound has been played")
        return false
    end
    
    return PlaySound(lastPlayedSound.sound, lastPlayedSound.set, nil, lastPlayedSound.volume, lastPlayedSound.bank)
end

-- Pre-computed data for UI optimization
local cachedSoundSets = {}
local cachedCategoryList = {}
local dataLoaded = false

local function prepareData()
    if dataLoaded then return end
    
    local soundSetMap = {}
    local categoryMap = {}
    
    for _, entry in ipairs(Sounds) do
        if not soundSetMap[entry.set] then
            soundSetMap[entry.set] = true
            table.insert(cachedSoundSets, entry.set)
        end
        
        if entry.category and not categoryMap[entry.category] then
            categoryMap[entry.category] = true
            table.insert(cachedCategoryList, entry.category)
        end
    end
    
    table.sort(cachedSoundSets)
    table.sort(cachedCategoryList)
    dataLoaded = true
end

local function openUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    currentGameBuild = GetGameBuildNumber() or 1604
    prepareData()
    
    -- Send visibility message immediately
    SendNUIMessage({
        type = "open",
        currentBuild = currentGameBuild,
        sounds = Sounds,
        soundSets = cachedSoundSets,
        categories = cachedCategoryList,
        buildInfo = BuildInfo,
        lastPlayed = lastPlayedSound,
        vehicleAudio = VehicleAudio and VehicleAudio.Categories or {}
    })
    
    debugLog(string.format("UI opened (Game Build: %d)", currentGameBuild))
end

local function closeUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    
    stopCurrentSound()
    deletePreviewVehicle()
    
    -- Reset vehicle state
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and DoesEntityExist(veh) then
        SetVehicleDamageModifier(veh, 1.0)
        SetVehicleEngineCanDegrade(veh, true)
        SetVehicleEngineOn(veh, true, true, false)
    end
    
    SendNUIMessage({
        type = "close"
    })
    
    debugLog("UI closed")
end

local function toggleUI()
    if isUIOpen then
        closeUI()
    else
        openUI()
    end
end

RegisterNUICallback("close", function(data, cb)
    closeUI()
    cb({})
end)

RegisterNUICallback("playSound", function(data, cb)
    local soundName = data.sound
    local soundSet = data.set
    local volume = data.volume or Config.DefaultVolume
    local audioBank = data.bank
    
    local success = PlaySound(soundName, soundSet, nil, volume, audioBank)
    
    cb({ success = success, playing = isPlaying })
end)

RegisterNUICallback("stopSound", function(data, cb)
    local stopped = stopCurrentSound()
    deletePreviewVehicle()
    cb({ success = stopped, playing = isPlaying })
end)

RegisterNUICallback("playVehicleAudio", function(data, cb)
    local audioName = data.audio
    local modelName = data.model
    local rpm = data.rpm or 0.5
    local volume = data.volume or 1.0
    
    local success = playVehicleAudio(audioName, modelName, rpm, volume)
    
    cb({ success = success, playing = isPlaying })
end)

RegisterNUICallback("stopVehicleAudio", function(data, cb)
    stopVehicleAudio()
    cb({ success = true, playing = false })
end)

RegisterNUICallback("setVehicleRpm", function(data, cb)
    local rpm = data.rpm or 0.5
    local success = setVehicleRpm(rpm)
    cb({ success = success })
end)

RegisterNUICallback("setVehicleVolume", function(data, cb)
    local volume = data.volume or 1.0
    local success = setVehicleVolume(volume)
    cb({ success = success })
end)

RegisterNUICallback("copyToClipboard", function(data, cb)
    debugLog(string.format("Copied to clipboard: %s", data.text or ""))
    cb({})
end)

RegisterCommand("soundtester", function()
    toggleUI()
end, false)

RegisterKeyMapping("soundtester", "Open Sound Tester", "keyboard", Config.OpenKey)

RegisterCommand("soundtester_replay", function()
    replayLastSound()
end, false)

RegisterKeyMapping("soundtester_replay", "Replay Last Sound", "keyboard", Config.ReplayKey)

RegisterCommand("playsound", function(source, args)
    if #args < 2 then
        notify("~y~Usage: /playsound <soundName> <soundSet>", false)
        return
    end
    
    local soundName = args[1]
    local soundSet = args[2]
    
    PlaySound(soundName, soundSet)
end, false)

CreateThread(function()
    while true do
        if isUIOpen then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and DoesEntityExist(veh) then
                -- Automatically turn engine back on and prevent stalling
                SetVehicleEngineCanDegrade(veh, false)
                
                if not GetIsVehicleEngineRunning(veh) or GetVehicleEngineHealth(veh) < 700.0 then
                    SetVehicleEngineHealth(veh, 1000.0)
                    SetVehiclePetrolTankHealth(veh, 1000.0)
                    SetVehicleOilLevel(veh, 5.0)
                    SetVehicleEngineOn(veh, true, true, false)
                end
                
                -- Scale back damage
                SetVehicleDamageModifier(veh, Config.VehicleDamageMultiplier or 0.1)
                
                -- Optional: Keep it clean while testing
                if Config.VehicleDamageMultiplier == 0 then
                    SetVehicleBodyHealth(veh, 1000.0)
                    SetVehicleFixed(veh)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    
    currentGameBuild = GetGameBuildNumber() or 1604
    
    debugLog(string.format("Sound Tester loaded with %d sounds (Game Build: %d)", #Sounds, currentGameBuild))
    debugLog(string.format("Press %s to open UI, %s to replay last sound", Config.OpenKey, Config.ReplayKey))
end)

exports("PlaySound", PlaySound)

exports("GetLastPlayedSound", function()
    return lastPlayedSound
end)

exports("OpenUI", openUI)
exports("CloseUI", closeUI)
exports("ToggleUI", toggleUI)
