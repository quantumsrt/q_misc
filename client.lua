local soundBank = "audiodirectory/custom_sounds"
local soundSet = "special_soundset"
local scriptNames = {
    "u_attack_01", "u_attack_02", "u_attack_03", "u_attack_04", "u_attack_05",
    "u_attack_06", "u_attack_07", "u_attack_08", "u_attack_09", "u_attack_10",
    "u_attack_11", "u_attack_12", "u_attack_13", "u_attack_14", "u_attack_15",
    "u_attack_16", "u_attack_17", "u_death_01", "u_death_02", "u_death_03",
    "u_idle_01", "u_idle_02", "u_idle_03"
}

local npcSoundTimers = {}
local soundRadius = 50.0  -- Adjust this value to change the radius within which NPCs will emit sounds

-- Function to get a random sound name
local function GetRandomSound()
    return scriptNames[math.random(#scriptNames)]
end

-- Function to check if an NPC is alive
local function IsNPCAlive(ped)
    return not IsEntityDead(ped)
end

-- Function to play sound from an NPC
local function PlayNPCSound(ped)
    if not IsNPCAlive(ped) then return end

    local soundId = GetSoundId()
    local soundName = GetRandomSound()
    PlaySoundFromEntity(soundId, soundName, ped, soundSet, 0, 0)
    
    -- Set up a thread to check the NPC's health and stop the sound if they die
    Citizen.CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            Citizen.Wait(100)
        end
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end)
end

-- Main loop to handle NPC sounds
Citizen.CreateThread(function()
    -- Load the audio bank
    while not RequestScriptAudioBank(soundBank, false) do 
        Citizen.Wait(100) 
    end
    print('Audio bank loaded')

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Get all peds in the area
        local peds = GetGamePool('CPed')

        for _, ped in ipairs(peds) do
            if ped ~= playerPed and IsNPCAlive(ped) then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)

                if distance <= soundRadius then
                    local pedNetId = NetworkGetNetworkIdFromEntity(ped)

                    -- Check if it's time for this NPC to potentially play a sound
                    if not npcSoundTimers[pedNetId] or GetGameTimer() > npcSoundTimers[pedNetId] then
                        -- Random chance to play sound and random delay
                        if math.random() < 0.3 then  -- 30% chance to play sound
                            local delay = math.random(1000, 3000)  -- 1 to 3 second delay
                            SetTimeout(delay, function()
                                if DoesEntityExist(ped) and IsNPCAlive(ped) then
                                    PlayNPCSound(ped)
                                end
                            end)
                        end

                        -- Set next potential sound time (3-6 seconds from now)
                        npcSoundTimers[pedNetId] = GetGameTimer() + math.random(3000, 6000)
                    end
                end
            end
        end

        Citizen.Wait(1000)  -- Check every second
    end
end)

-- Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Release the audio bank
    ReleaseNamedScriptAudioBank(soundBank)
    print('Audio bank released')
end)