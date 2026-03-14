Safezone = Safezone or {}
Safezone.PlayerData = Safezone.PlayerData or {}

Safezone.Player = Safezone.Player or {
    ped = 0,
    coords = vector3(0, 0, 0),
    id = PlayerId()
}

Safezone.State = Safezone.State or {
    isInSafezone = false,
    currentSafezone = nil,
    createdBlips = {}
}

Safezone.Constants = Safezone.Constants or {
    cacheTimeout = 300000
}

Safezone.Performance = Safezone.Performance or {
    lastZoneCheck = 0,
    avgCheckTime = 0,
    checkCount = 0,
    frameTime = 0,
    markerRenderTime = 0,
    collisionUpdateTime = 0,
    vehiclesProcessed = 0,
    playersGhosted = 0
}

Safezone.Debug = Safezone.Debug or {}
Safezone.Debug.enabled = Safezone.Debug.enabled == nil and Config.DebugOptions.enabled or Safezone.Debug.enabled
Safezone.Debug.mode = Safezone.Debug.mode or 'all'
Safezone.Debug.zoneStates = Safezone.Debug.zoneStates or {}
Config.DebugOptions.enabled = Safezone.Debug.enabled

Safezone.Zones = Safezone.Zones or {}
Safezone.Collision = Safezone.Collision or {}
Safezone.UI = Safezone.UI or {}

local function isZoneInvincibilityEnabled(zone)
    if not zone then
        return false
    end

    if zone.enableInvincibility ~= nil then
        return zone.enableInvincibility ~= false
    end

    if zone.enableImmortality ~= nil then
        return zone.enableImmortality ~= false
    end

    return true
end

function Safezone.UpdatePlayerCache()
    Safezone.Player.ped = PlayerPedId()
    Safezone.Player.coords = GetEntityCoords(Safezone.Player.ped)
    Safezone.Player.id = PlayerId()
end

CreateThread(function()
    Framework.WaitForClientReady()

    Framework.OnPlayerLoaded(function()
        Safezone.PlayerData = Framework.GetPlayerData()
        Wait(2000)
        TriggerServerEvent('f5_safezones:requestZoneUpdate')
    end)

    if Framework.IsPlayerLoaded() then
        Safezone.PlayerData = Framework.GetPlayerData()
        Wait(2000)
        TriggerServerEvent('f5_safezones:requestZoneUpdate')
    end
end)

function Safezone.ShowNotification(message, notifType)
    if Framework.Notify then
        Framework.Notify(message, notifType)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentSubstringPlayerName(message)
        DrawNotification(false, true)
    end
end

RegisterNetEvent('f5_safezones:showNotification', function(message, notifType)
    Safezone.ShowNotification(message, notifType)
end)

RegisterNetEvent('f5_safezones:printToConsole', function(lines)
    if type(lines) == 'table' then
        for _, line in ipairs(lines) do
            print(line)
        end
    else
        print(lines)
    end
end)

function Safezone.InitializeSafezones()
    Safezone.Zones.CreateBlips()
    Safezone.StartSafezoneLoop()
end

function Safezone.StartSafezoneLoop()
    if Safezone.State.safezoneLoopActive then
        return
    end

    Safezone.State.safezoneLoopActive = true

    CreateThread(function()
        while true do
            local zoneCount = Safezone.Zones.GetZoneCount()
            if zoneCount > 0 then
                local startTime = GetGameTimer()
                Safezone.UpdatePlayerCache()
                local playerCoords = Safezone.Player.coords
                local foundZone = nil
                local closestDistance = math.huge
                local processedZones = Safezone.Zones.GetProcessedZones()
                local activeZoneName = Safezone.State.currentSafezone and Safezone.State.currentSafezone.name or nil

                if Safezone.State.isInSafezone and activeZoneName then
                    local activeProcessedZone = Safezone.Zones.GetProcessedZoneByName(activeZoneName)
                    if activeProcessedZone then
                        local inZone, distance = Safezone.Zones.IsPlayerInsideZone(playerCoords, activeProcessedZone)
                        if inZone then
                            foundZone = activeProcessedZone.originalZone
                            closestDistance = distance
                        end
                    end
                end

                if not foundZone then
                    for i = 1, zoneCount do
                        local zone = processedZones[i]

                        if not activeZoneName or zone.name ~= activeZoneName then
                            local inZone, distance = Safezone.Zones.IsPlayerInsideZone(playerCoords, zone)

                            if inZone and distance < closestDistance then
                                foundZone = zone.originalZone
                                closestDistance = distance
                            end
                        end
                    end
                end

                local checkTime = GetGameTimer() - startTime
                local performance = Safezone.Performance
                performance.checkCount = performance.checkCount + 1
                performance.avgCheckTime = (performance.avgCheckTime * (performance.checkCount - 1) + checkTime) / performance.checkCount
                performance.lastZoneCheck = checkTime

                if foundZone and not Safezone.State.isInSafezone then
                    Safezone.EnterSafezone(foundZone)
                elseif not foundZone and Safezone.State.isInSafezone then
                    Safezone.ExitSafezone()
                elseif foundZone and Safezone.State.isInSafezone and Safezone.State.currentSafezone and foundZone.name ~= Safezone.State.currentSafezone.name then
                    Safezone.ExitSafezone()
                    Wait(100)
                    Safezone.EnterSafezone(foundZone)
                elseif foundZone and Safezone.State.isInSafezone and Safezone.State.currentSafezone and foundZone ~= Safezone.State.currentSafezone then
                    Safezone.State.currentSafezone = foundZone
                end
            end

            Wait(Config.CheckInterval)
        end
    end)
end

function Safezone.EnterSafezone(zone)
    Safezone.State.isInSafezone = true
    Safezone.State.currentSafezone = zone
    Safezone.ShowNotification(Translate('enter_safezone'))
    TriggerServerEvent('f5_safezones:playerEnteredZone', zone.name)
    TriggerEvent('f5_safezones:enteredZone', zone)

    Safezone.UpdatePlayerCache()
    Safezone.Collision.StoreOriginalAlpha()

    if zone.enableGhosting ~= false then
        SetEntityAlpha(Safezone.Player.ped, Config.CollisionSystem.playerAlpha or 200, false)
    end

    Safezone.DisableWeapons()
    Safezone.StartSafezoneRestrictions()

    Safezone.Collision.StartCollisionSystem()

    TriggerServerEvent('f5_safezones:requestPlayersInZone', zone.name)
end

function Safezone.ExitSafezone()
    if not Safezone.State.isInSafezone then
        return
    end

    local zoneName = Safezone.State.currentSafezone and Safezone.State.currentSafezone.name or 'Unknown'
    Safezone.State.isInSafezone = false
    Safezone.State.currentSafezone = nil

    Safezone.ShowNotification(Translate('exit_safezone'))
    TriggerServerEvent('f5_safezones:playerExitedZone', zoneName)
    TriggerEvent('f5_safezones:exitedZone', zoneName)

    Safezone.UpdatePlayerCache()
    ResetEntityAlpha(Safezone.Player.ped)

    Safezone.Collision.RestoreAllCollisions()

    SetTimeout(500, function()
        if not Safezone.State.isInSafezone then
            Safezone.Collision.RestoreAllCollisions()
        end
    end)

    Safezone.EnableWeapons()
end

function Safezone.DisableWeapons()
    Safezone.UpdatePlayerCache()
    SetCurrentPedWeapon(Safezone.Player.ped, 'WEAPON_UNARMED', true)
    SetPlayerCanUseCover(Safezone.Player.id, false)
    SetPlayerCanDoDriveBy(Safezone.Player.id, false)
    DisablePlayerFiring(Safezone.Player.id, true)
end

function Safezone.EnableWeapons()
    SetPlayerCanUseCover(Safezone.Player.id, true)
    SetPlayerCanDoDriveBy(Safezone.Player.id, true)
    DisablePlayerFiring(Safezone.Player.id, false)
end

function Safezone.StartSafezoneRestrictions()
    CreateThread(function()
        local cacheInterval = Config.Performance.updateIntervals.playerCache or 600
        local weaponCheckInterval = Config.Performance.updateIntervals.weaponCheck or 250
        local invincibilityInterval = Config.Performance.updateIntervals.invincibility or 1000
        local vehicleProtectionInterval = Config.Performance.updateIntervals.vehicleProtection or 1000
        local waitInterval = 5

        local lastCacheUpdate = 0
        local lastWeaponCheck = 0
        local lastInvincibilityUpdate = 0
        local lastVehicleProtection = 0
        local lastVehicleWeaponUpdate = 0

        local playerInvincible = false
        local activeVehicle = 0
        local vehicleProtected = false
        local vehicleWeaponsDisabled = false

        local disableControls = {
            24, 25, 37, 47, 58, 140, 141, 142, 257, 263, 264
        }

        while Safezone.State.isInSafezone do
            local currentTime = GetGameTimer()
            local currentZone = Safezone.State.currentSafezone
            local invincibilityEnabled = isZoneInvincibilityEnabled(currentZone)

            for i = 0, 5 do
                for _, control in ipairs(disableControls) do
                    DisableControlAction(i, control, true)
                end
            end

            DisableControlAction(0, 114, true)
            DisableControlAction(0, 331, true)
            DisableControlAction(0, 99, true)
            DisableControlAction(0, 100, true)
            DisableControlAction(0, 357, true)

            if currentTime - lastCacheUpdate >= cacheInterval then
                Safezone.UpdatePlayerCache()
                lastCacheUpdate = currentTime
            end

            if currentTime - lastWeaponCheck >= weaponCheckInterval then
                lastWeaponCheck = currentTime
                local currentWeapon = GetSelectedPedWeapon(Safezone.Player.ped)
                if currentWeapon ~= 'WEAPON_UNARMED' then
                    SetCurrentPedWeapon(Safezone.Player.ped, 'WEAPON_UNARMED', true)
                end
            end

            if invincibilityEnabled then
                if (not playerInvincible) or (currentTime - lastInvincibilityUpdate >= invincibilityInterval) then
                    playerInvincible = true
                    lastInvincibilityUpdate = currentTime
                    SetEntityCanBeDamaged(Safezone.Player.ped, false)
                    SetEntityInvincible(Safezone.Player.ped, true)
                    SetPlayerInvincible(Safezone.Player.id, true)
                    ClearPedBloodDamage(Safezone.Player.ped)
                    ResetPedVisibleDamage(Safezone.Player.ped)
                    SetEntityProofs(Safezone.Player.ped, false, false, false, true, false, false, false, false)
                end
            elseif playerInvincible then
                playerInvincible = false
                SetEntityCanBeDamaged(Safezone.Player.ped, true)
                SetEntityInvincible(Safezone.Player.ped, false)
                SetPlayerInvincible(Safezone.Player.id, false)
                SetEntityProofs(Safezone.Player.ped, false, false, false, false, false, false, false, false)
            end

            local vehicle = GetVehiclePedIsIn(Safezone.Player.ped, false)
            if vehicle ~= 0 then
                if vehicle ~= activeVehicle then
                    activeVehicle = vehicle
                    vehicleProtected = false
                    vehicleWeaponsDisabled = false
                    lastVehicleWeaponUpdate = 0
                end

                if (not vehicleProtected) or (currentTime - lastVehicleProtection >= vehicleProtectionInterval) then
                    lastVehicleProtection = currentTime
                    vehicleProtected = true
                    SetEntityCanBeDamaged(vehicle, false)
                    SetEntityInvincible(vehicle, true)
                    SetVehicleCanBeVisiblyDamaged(vehicle, false)
                    SetVehicleEngineCanDegrade(vehicle, false)
                    SetVehicleTyresCanBurst(vehicle, false)
                end

                local shouldDisableWeapons = DoesVehicleHaveWeapons(vehicle) and (Safezone.State.currentSafezone and Safezone.State.currentSafezone.disableVehicleWeapons ~= false)
                if shouldDisableWeapons then
                    if (not vehicleWeaponsDisabled) or (currentTime - lastVehicleWeaponUpdate >= vehicleProtectionInterval) then
                        vehicleWeaponsDisabled = true
                        lastVehicleWeaponUpdate = currentTime
                        SetVehicleWeaponsDisabled(vehicle, true)
                        SetCurrentPedVehicleWeapon(Safezone.Player.ped, 'VEHICLE_WEAPON_PLAYER_BULLET')
                        DisableVehicleWeapon(vehicle, true, 'VEHICLE_WEAPON_PLAYER_BULLET', Safezone.Player.ped)
                    end
                elseif vehicleWeaponsDisabled then
                    SetVehicleWeaponsDisabled(vehicle, false)
                    vehicleWeaponsDisabled = false
                end
            else
                activeVehicle = 0
                vehicleProtected = false
                vehicleWeaponsDisabled = false
                lastVehicleWeaponUpdate = 0
            end

            Wait(waitInterval)
        end

        Safezone.RestorePlayerFromSafezoneMode()
    end)
end

function Safezone.RestorePlayerFromSafezoneMode()
    Safezone.UpdatePlayerCache()
    local ped = Safezone.Player.ped
    local id = Safezone.Player.id

    SetEntityCanBeDamaged(ped, true)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(id, false)
    SetPedCanRagdoll(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, true)
    SetEntityProofs(ped, false, false, false, false, false, false, false, false)

    SetPedConfigFlag(ped, 32, true)
    SetPedCanBeKnockedOffVehicle(ped, 0)
    SetPedCanBeDraggedOut(ped, true)
    SetPedSuffersCriticalHits(ped, true)

    SetPlayerCanBeHassledByGangs(id, true)
    SetPlayerVehicleDamageModifier(id, 1.0)
    SetPlayerWeaponDamageModifier(id, 1.0)
    SetPlayerMeleeWeaponDamageModifier(id, 1.0)

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetEntityCanBeDamaged(vehicle, true)
        SetEntityInvincible(vehicle, false)
        SetVehicleCanBeVisiblyDamaged(vehicle, true)
        SetVehicleEngineCanDegrade(vehicle, true)
        SetVehicleTyresCanBurst(vehicle, true)
        SetVehicleWeaponsDisabled(vehicle, false)
    end
end

RegisterNetEvent('f5_safezones:updateZones', function(zones)
    if not zones then
        return
    end

    Safezone.Zones.SetZones(zones)
    Safezone.InitializeSafezones()
end)

RegisterNetEvent('f5_safezones:receivePlayersInZone', function(playerList)
    if Safezone.State.isInSafezone and Safezone.State.currentSafezone then
        Safezone.Collision.UpdatePlayersInZone()
    end
end)

RegisterNetEvent('f5_safezones:playerEnteredSameZone', function()
    if Safezone.State.isInSafezone and Safezone.State.currentSafezone and Safezone.State.currentSafezone.enableGhosting ~= false then
        Safezone.Collision.UpdatePlayersInZone()
    end
end)

RegisterNetEvent('f5_safezones:entryRejected', function()
    if not Safezone.State.isInSafezone then
        return
    end

    Safezone.State.isInSafezone = false
    Safezone.State.currentSafezone = nil

    Safezone.UpdatePlayerCache()
    ResetEntityAlpha(Safezone.Player.ped)

    Safezone.Collision.RestoreAllCollisions()
    SetTimeout(500, function()
        if not Safezone.State.isInSafezone then
            Safezone.Collision.RestoreAllCollisions()
        end
    end)

    Safezone.EnableWeapons()
end)

RegisterNetEvent('f5_safezones:forceExitZone', function()
    Safezone.ExitSafezone()
end)

RegisterNetEvent('f5_safezones:playerLeftSameZone', function(serverId)
    if Safezone.State.isInSafezone then
        Safezone.Collision.RemovePlayerGhosting(serverId)
        Safezone.Collision.UpdatePlayersInZone()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    Safezone.UpdatePlayerCache()

    if Safezone.State.isInSafezone then
        Safezone.Collision.RestoreAllCollisions()

        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        if myVeh == 0 then
            myVeh = GetVehiclePedIsIn(myPed, true)
        end

        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            SetEntityNoCollisionEntity(vehicle, myPed, false)
            SetEntityNoCollisionEntity(myPed, vehicle, false)
            if myVeh ~= 0 and myVeh ~= vehicle then
                SetEntityNoCollisionEntity(vehicle, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, vehicle, false)
            end
            ResetEntityAlpha(vehicle)
            SetVehicleWeaponsDisabled(vehicle, false)
        end

        local activePlayers = GetActivePlayers()
        for _, player in ipairs(activePlayers) do
            if player ~= PlayerId() then
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    SetEntityNoCollisionEntity(myPed, ped, false)
                    SetEntityNoCollisionEntity(ped, myPed, false)
                    ResetEntityAlpha(ped)
                    local theirVeh = GetVehiclePedIsIn(ped, false)
                    if theirVeh ~= 0 and DoesEntityExist(theirVeh) then
                        SetEntityNoCollisionEntity(myPed, theirVeh, false)
                        SetEntityNoCollisionEntity(theirVeh, myPed, false)
                        if myVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, theirVeh, false)
                            SetEntityNoCollisionEntity(theirVeh, myVeh, false)
                        end
                    end
                end
            end
        end

        local peds = GetGamePool('CPed')
        for _, ped in ipairs(peds) do
            if ped ~= myPed and DoesEntityExist(ped) then
                SetEntityNoCollisionEntity(ped, myPed, false)
                SetEntityNoCollisionEntity(myPed, ped, false)
            end
        end

        local objects = GetGamePool('CObject')
        for _, obj in ipairs(objects) do
            if DoesEntityExist(obj) then
                SetEntityNoCollisionEntity(obj, myPed, false)
                SetEntityNoCollisionEntity(myPed, obj, false)
                if myVeh ~= 0 then
                    SetEntityNoCollisionEntity(obj, myVeh, false)
                    SetEntityNoCollisionEntity(myVeh, obj, false)
                end
            end
        end

        Safezone.RestorePlayerFromSafezoneMode()
    end

    Safezone.Zones.ClearBlips()
    Safezone.Zones.ClearCache()
    Safezone.Collision.Clear()
end)

exports('IsPlayerInSafezone', function()
    return Safezone.State.isInSafezone
end)

exports('GetCurrentSafezone', function()
    return Safezone.State.currentSafezone
end)

exports('GetAllZones', function()
    return Safezone.Zones.GetCurrentZones()
end)

exports('IsPlayerInGhostMode', function()
    return Safezone.State.isInSafezone and Safezone.State.currentSafezone and Safezone.State.currentSafezone.enableGhosting ~= false
end)

exports('GetPerformanceStats', function()
    return Safezone.Performance
end)

exports('IsDebugModeActive', function()
    return Safezone.Debug.enabled
end)

exports('GetLowestPointInZone', function(zoneName)
    return Safezone.Zones.GetLowestPointInZone(zoneName)
end)

exports('GetCollisionEntities', function()
    return Safezone.Collision.GetCollisionEntities()
end)

exports('GetGhostedVehicles', function()
    return Safezone.Collision.GetGhostedVehicles()
end)

exports('GetGhostedPlayers', function()
    return Safezone.Collision.GetGhostedPlayers()
end)

exports('GetPlayersInCurrentZone', function()
    return Safezone.Collision.GetPlayersInZone()
end)
