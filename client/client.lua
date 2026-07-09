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

function Safezone.IsZoneInvincibilityEnabled(zone)
    if not zone then
        return false
    end

    if zone.enableInvincibility ~= nil then
        return zone.enableInvincibility ~= false
    end

    return true
end

function Safezone.IsZoneVehicleInvincibilityEnabled(zone)
    if not zone then
        return false
    end

    if zone.enableVehicleInvincibility ~= nil then
        return zone.enableVehicleInvincibility ~= false
    end

    return true
end

function Safezone.IsZoneVehicleGhostingEnabled(zone)
    if not zone then
        return false
    end

    if zone.enableVehicleGhosting ~= nil then
        return zone.enableVehicleGhosting ~= false
    end

    return false
end

function Safezone.IsZoneGhostingEnabled(zone)
    if not zone then
        return false
    end

    return zone.enableGhosting == true
end

function Safezone.IsZoneCollisionDisabled(zone)
    if not zone then
        return false
    end

    return zone.collisionDisabled ~= false
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

local function applyJobOverrides(zone)
    local jo = zone.jobOverrides
    if not jo or not jo.enabled then
        return zone
    end

    if not jo.jobs or #jo.jobs == 0 then
        return zone
    end

    local playerJob = Framework.GetPlayerJob and Framework.GetPlayerJob() or { name = 'unemployed', grade = 0 }
    local jobName = (playerJob.name or 'unemployed'):lower()
    local jobGrade = tonumber(playerJob.grade) or 0

    for _, entry in ipairs(jo.jobs) do
        if entry.name == jobName and jobGrade >= (entry.minGrade or 0) then
            local overridden = {}
            for k, v in pairs(zone) do
                overridden[k] = v
            end
            overridden.enableInvincibility = entry.enableInvincibility
            overridden.enableVehicleInvincibility = entry.enableVehicleInvincibility
            overridden.enableVehicleGhosting = entry.enableVehicleGhosting
            overridden.enableGhosting = entry.enableGhosting
            overridden.disableVehicleWeapons = entry.disableVehicleWeapons
            overridden._disableWeapons = entry.disableWeapons
            overridden._originalZone = zone
            return overridden
        end
    end

    return zone
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
                elseif foundZone and Safezone.State.isInSafezone and Safezone.State.currentSafezone and foundZone ~= (Safezone.State.currentSafezone._originalZone or Safezone.State.currentSafezone) then
                    local currentOriginal = Safezone.State.currentSafezone._originalZone or Safezone.State.currentSafezone
                    if Safezone.IsZoneCollisionDisabled(foundZone) ~= Safezone.IsZoneCollisionDisabled(currentOriginal) then
                        Safezone.ExitSafezone()
                        Wait(100)
                        Safezone.EnterSafezone(foundZone)
                    else
                        Safezone.State.currentSafezone = applyJobOverrides(foundZone)
                    end
                end
            end

            Wait(Config.CheckInterval)
        end
    end)
end

function Safezone.EnterSafezone(zone)
    zone = applyJobOverrides(zone)

    Safezone.State.isInSafezone = true
    Safezone.State.currentSafezone = zone
    Safezone.ShowNotification(Translate('enter_safezone'))
    TriggerServerEvent('f5_safezones:playerEnteredZone', zone.name)
    TriggerEvent('f5_safezones:enteredZone', zone)

    Safezone.UpdatePlayerCache()
    Safezone.Collision.StoreOriginalAlpha()

    if Safezone.IsZoneGhostingEnabled(zone) then
        SetEntityAlpha(Safezone.Player.ped, Config.CollisionSystem.playerAlpha or 200, false)
    else
        ResetEntityAlpha(Safezone.Player.ped)
    end

    if Safezone.IsZoneInvincibilityEnabled(zone) then
        SetEntityInvincible(Safezone.Player.ped, true)
        SetPlayerInvincible(Safezone.Player.ped, true)
        SetEntityCanBeDamaged(Safezone.Player.ped, false)
    end

    if zone._disableWeapons ~= false then
        Safezone.DisableWeapons()
    end

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
        local vehicleProtectionInterval = Config.Performance.updateIntervals.vehicleProtection or 1000
        local waitInterval = 5

        local lastCacheUpdate = 0
        local lastWeaponCheck = 0
        local lastVehicleWeaponUpdate = 0

        local activeVehicle = 0
        local vehicleWeaponsDisabled = false

        local disableControls = {
            24, 25, 37, 47, 58, 140, 141, 142, 257, 263, 264
        }

        while Safezone.State.isInSafezone do
            local currentTime = GetGameTimer()
            local currentZone = Safezone.State.currentSafezone
            local invincibilityEnabled = Safezone.IsZoneInvincibilityEnabled(currentZone)
            local weaponsDisabled = not currentZone or currentZone._disableWeapons ~= false

            if weaponsDisabled then
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
            end

            if currentTime - lastCacheUpdate >= cacheInterval then
                Safezone.UpdatePlayerCache()
                lastCacheUpdate = currentTime
            end

            if weaponsDisabled and currentTime - lastWeaponCheck >= weaponCheckInterval then
                lastWeaponCheck = currentTime
                local currentWeapon = GetSelectedPedWeapon(Safezone.Player.ped)
                if currentWeapon ~= 'WEAPON_UNARMED' then
                    SetCurrentPedWeapon(Safezone.Player.ped, 'WEAPON_UNARMED', true)
                end
            end

            if invincibilityEnabled then
                SetEntityInvincible(Safezone.Player.ped, true)
                SetEntityCanBeDamaged(Safezone.Player.ped, false)
                SetPlayerInvincible(Safezone.Player.ped, true)
            else
                SetEntityInvincible(Safezone.Player.ped, false)
                SetPlayerInvincible(Safezone.Player.ped, false)
                SetEntityCanBeDamaged(Safezone.Player.ped, true)
            end

            local vehicle = GetVehiclePedIsIn(Safezone.Player.ped, false)
            if vehicle ~= 0 then
                if vehicle ~= activeVehicle then
                    activeVehicle = vehicle
                    vehicleWeaponsDisabled = false
                    lastVehicleWeaponUpdate = 0
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

    SetEntityInvincible(ped, false)
    SetEntityCanBeDamaged(ped, true)
    SetPlayerInvincible(ped, false)

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleWeaponsDisabled(vehicle, false)
    end
end

RegisterNetEvent('f5_safezones:updateZones', function(zones)
    if not zones then
        return
    end

    Safezone.Zones.SetZones(zones)
    Safezone.InitializeSafezones()
    Safezone.Zones.ForceMarkerUpdate()
end)

RegisterNetEvent('f5_safezones:receivePlayersInZone', function(playerList)
    if Safezone.State.isInSafezone and Safezone.State.currentSafezone then
        Safezone.Collision.SetZoneMembers(playerList)
        Safezone.Collision.UpdatePlayersInZone()
    end
end)

RegisterNetEvent('f5_safezones:playerEnteredSameZone', function(serverId)
    if Safezone.State.isInSafezone and Safezone.State.currentSafezone then
        Safezone.Collision.AddZoneMember(serverId)
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

AddEventHandler('f5_safezones:onJobUpdate', function()
    if Safezone.State.isInSafezone and Safezone.State.currentSafezone then
        local originalZone = Safezone.State.currentSafezone._originalZone or Safezone.State.currentSafezone
        local previousGhosting = Safezone.IsZoneGhostingEnabled(Safezone.State.currentSafezone)
        Safezone.State.currentSafezone = applyJobOverrides(originalZone)
        local newGhosting = Safezone.IsZoneGhostingEnabled(Safezone.State.currentSafezone)

        if previousGhosting ~= newGhosting then
            Safezone.UpdatePlayerCache()
            if newGhosting then
                SetEntityAlpha(Safezone.Player.ped, Config.CollisionSystem.playerAlpha or 200, false)
            else
                ResetEntityAlpha(Safezone.Player.ped)
            end
        end
    end
end)

RegisterNetEvent('f5_safezones:playerLeftSameZone', function(serverId)
    if Safezone.State.isInSafezone then
        Safezone.Collision.RemoveZoneMember(serverId)
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

        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            SetEntityInvincible(vehicle, false)
            SetEntityCanBeDamaged(vehicle, true)
            SetVehicleTyresCanBurst(vehicle, true)
            ResetEntityAlpha(vehicle)
            SetVehicleWeaponsDisabled(vehicle, false)
        end

        local activePlayers = GetActivePlayers()
        for _, player in ipairs(activePlayers) do
            if player ~= PlayerId() then
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    ResetEntityAlpha(ped)
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
    return Safezone.State.isInSafezone and Safezone.State.currentSafezone and Safezone.IsZoneCollisionDisabled(Safezone.State.currentSafezone)
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
