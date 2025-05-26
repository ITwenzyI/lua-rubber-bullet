local smgHitCount = {}       -- Stores hit count per player
local lastHitTime = 0        -- Cooldown for hits
local isRagdolled = false    -- Prevents multiple ragdolls during animation

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- Check if the player is shooting with an SMG
        if IsPedShooting(PlayerPedId()) then
            local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)

            -- If it's an SMG, reduce the damage to 0
            if weaponHash == GetHashKey('WEAPON_SMG') then
                SetPlayerWeaponDamageModifier(PlayerId(), -3.0)
            else
                SetPlayerWeaponDamageModifier(PlayerId(), 1.0) -- Reset to default value
            end
        end
    end
end)

RegisterNetEvent('smgHit')
AddEventHandler('smgHit', function()
    local playerPed = PlayerPedId()
    local playerId = PlayerId()

    -- If the player is already ragdolled, don't count further hits
    if isRagdolled then
        return
    end

    if not smgHitCount[playerId] then
        smgHitCount[playerId] = 0
    end

    smgHitCount[playerId] = smgHitCount[playerId] + 1

    if smgHitCount[playerId] >= 7 then
        -- Show notification (only once per ragdoll effect)
        TriggerEvent("notifications", "#4287F5", "Rubber Bullet", "You are incapacitated for a short time.", 5000)
        TriggerEvent("notifications", "#4287F5", "Rubber Bullet", "You were hit by a rubber bullet!", 5000)

        -- Trigger ragdoll effect
        isRagdolled = true
        SetPedToRagdoll(playerPed, 10000, 10000, 0, true, true, false)

        -- Activate blurred vision
        TriggerScreenblurFadeIn(1.0)
        Citizen.Wait(10000) -- 10 seconds of blurred vision
        TriggerScreenblurFadeOut(1.0)

        smgHitCount[playerId] = 0 -- Reset hit count

        -- Cooldown before hits are counted again
        Citizen.Wait(5000) -- 5 seconds of immunity
        isRagdolled = false
    end
end)

-- Event for hit detection with cooldown
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10) -- Short wait to prevent multiple triggers
        local playerPed = PlayerPedId()

        if HasEntityBeenDamagedByWeapon(playerPed, GetHashKey('WEAPON_SMG'), 0) then
            local currentTime = GetGameTimer()

            if currentTime - lastHitTime > 100 then -- 100ms cooldown
                lastHitTime = currentTime
                ClearEntityLastDamageEntity(playerPed)
                TriggerEvent('smgHit')
            end
        end
    end
end)
