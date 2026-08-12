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
local IsEntityDead = IsEntityDead

local isUIOpen = false
local lastPlayedSound = nil
local currentSoundId = -1
local currentGameBuild = 0
local isPlaying = false
local previewVehicle = nil
local vehicleRpmThread = nil
local vehicleThreadId = 0
local currentAudioBank = nil
local allowedSoundPairs = {}
local allowedVehicleAudio = {}

local function isFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function boundedString(value, maximumLength)
    if type(value) ~= "string" then return nil end
    local text = value:match("^%s*(.-)%s*$") or ""
    if text == "" or #text > maximumLength then return nil end
    return text
end

local function boundedNumber(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if not isFiniteNumber(number) then return fallback end
    return math.max(minimum, math.min(maximum, number))
end

local function debugLog(message)
    if Config.Debug then
        print(string.format("[cortex_soundtool] %s", message))
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

    bankName = boundedString(bankName, 96)
    if not bankName then return false end
    
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
    model = type(model) == "string" and boundedString(model, 64) or model
    if model == nil then return false end
    local hash = type(model) == "string" and joaat(model) or tonumber(model)
    if not hash or not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return false end
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
    
    local model = boundedString(modelName, 64) or "adder"
    local cleanAudioName = boundedString(audioName, 64)
    currentVehicleRpm = boundedNumber(rpm, 0.1, 0.99, 0.5)
    currentVehicleVolume = boundedNumber(volume, 0.1, 4.0, 1.0)
    
    debugLog(string.format("Starting vehicle audio - Model: %s, Audio: %s, RPM: %.0f%%, Volume: %.0f%%", 
        model, cleanAudioName or "default", currentVehicleRpm * 100, currentVehicleVolume * 100))
    
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
    
    if cleanAudioName then
        ForceVehicleEngineAudio(previewVehicle, cleanAudioName)
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
        cleanAudioName or model, currentVehicleRpm * 100, currentVehicleVolume * 100))
    
    return true
end

local function setVehicleRpm(rpm)
    currentVehicleRpm = boundedNumber(rpm, 0.1, 0.99, nil)
    if not currentVehicleRpm then return false end
    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetVehicleCurrentRpm(previewVehicle, currentVehicleRpm)
        return true
    end
    return false
end

local function setVehicleVolume(volume)
    currentVehicleVolume = boundedNumber(volume, 0.1, 4.0, nil)
    if not currentVehicleVolume then return false end
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
    soundName = boundedString(soundName, 96)
    if not soundName then
        debugLog("ERROR: Sound name is empty or nil")
        notify("~r~Error: Invalid sound name", true)
        return false
    end
    
    soundSet = boundedString(soundSet, 96)
    if not soundSet then
        debugLog("ERROR: Sound set is empty or nil")
        notify("~r~Error: Invalid sound set", true)
        return false
    end
    
    local soundVolume = boundedNumber(volume, 0.0, 4.0, boundedNumber(Config.DefaultVolume, 0.0, 4.0, 1.0))
    audioBank = audioBank == nil and nil or boundedString(audioBank, 96)
    
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
        if type(entry.sound) == "string" and type(entry.set) == "string" then
            allowedSoundPairs[entry.sound .. "\0" .. entry.set] = {
                bank = type(entry.bank) == "string" and entry.bank or nil,
            }
        end
        if not soundSetMap[entry.set] then
            soundSetMap[entry.set] = true
            table.insert(cachedSoundSets, entry.set)
        end
        
        if entry.category and not categoryMap[entry.category] then
            categoryMap[entry.category] = true
            table.insert(cachedCategoryList, entry.category)
        end
    end

    for _, category in ipairs((VehicleAudio and VehicleAudio.Categories) or {}) do
        for _, vehicle in ipairs(category.vehicles or {}) do
            if type(vehicle.model) == "string" and type(vehicle.audio) == "string" then
                allowedVehicleAudio[vehicle.model] = vehicle.audio
            end
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
    if type(data) ~= "table" then cb({ success = false, error = "invalid_payload" }) return end
    prepareData()
    local soundName = data.sound
    local soundSet = data.set
    local volume = data.volume or Config.DefaultVolume
    local audioBank = data.bank
    
    local pairKey = type(soundName) == "string" and type(soundSet) == "string" and (soundName .. "\0" .. soundSet) or nil
    local allowedSound = pairKey and allowedSoundPairs[pairKey] or nil
    local requestedBank = boundedString(audioBank, 96)
    local success = allowedSound ~= nil and requestedBank == allowedSound.bank
        and PlaySound(soundName, soundSet, nil, volume, requestedBank)
        or false
    
    cb({ success = success, playing = isPlaying })
end)

RegisterNUICallback("stopSound", function(data, cb)
    local stopped = stopCurrentSound()
    deletePreviewVehicle()
    cb({ success = stopped, playing = isPlaying })
end)

RegisterNUICallback("playVehicleAudio", function(data, cb)
    if type(data) ~= "table" then cb({ success = false, error = "invalid_payload" }) return end
    prepareData()
    local audioName = data.audio
    local modelName = data.model
    local rpm = data.rpm or 0.5
    local volume = data.volume or 1.0
    
    local expectedAudio = type(modelName) == "string" and allowedVehicleAudio[modelName] or nil
    local success = expectedAudio ~= nil and audioName == expectedAudio
        and playVehicleAudio(audioName, modelName, rpm, volume)
        or false
    
    cb({ success = success, playing = isPlaying })
end)

RegisterNUICallback("stopVehicleAudio", function(data, cb)
    stopVehicleAudio()
    cb({ success = true, playing = false })
end)

RegisterNUICallback("setVehicleRpm", function(data, cb)
    if type(data) ~= "table" then cb({ success = false, error = "invalid_payload" }) return end
    local rpm = data.rpm or 0.5
    local success = setVehicleRpm(rpm)
    cb({ success = success })
end)

RegisterNUICallback("setVehicleVolume", function(data, cb)
    if type(data) ~= "table" then cb({ success = false, error = "invalid_payload" }) return end
    local volume = data.volume or 1.0
    local success = setVehicleVolume(volume)
    cb({ success = success })
end)

RegisterNUICallback("copyToClipboard", function(data, cb)
    local text = type(data) == "table" and data.text or nil
    if type(text) ~= "string" or #text > 512 then
        cb({ success = false, error = "invalid_payload" })
        return
    end
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
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    
    currentGameBuild = GetGameBuildNumber() or 1604
    
    debugLog(string.format("Sound Tester loaded with %d sounds (Game Build: %d)", #Sounds, currentGameBuild))
    debugLog(string.format("Press %s to open UI, %s to replay last sound", Config.OpenKey, Config.ReplayKey))
end)

CreateThread(function()
    while true do
        if isUIOpen and IsEntityDead(PlayerPedId()) then
            closeUI()
        end
        Wait(isUIOpen and 500 or 1500)
    end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    isUIOpen = false
    SetNuiFocus(false, false)
    stopCurrentSound()
    deletePreviewVehicle()
end)

exports("PlaySound", PlaySound)

exports("GetLastPlayedSound", function()
    return lastPlayedSound
end)

exports("OpenUI", openUI)
exports("CloseUI", closeUI)
exports("ToggleUI", toggleUI)
