local Safezone = Safezone
local Zones = Safezone.Zones
local Collision = Safezone.Collision

local collisionEntities = {}
local lastCollisionUpdate = 0
local COLLISION_UPDATE_INTERVAL = Config.Performance.updateIntervals.collisionCheck
local COLLISION_RANGE = Config.CollisionSystem.range or 100.0
local COLLISION_RANGE_SQUARED = COLLISION_RANGE * COLLISION_RANGE
local vehicleWeaponsDisabled = {}
local ghostedVehicles = {}
local processedEntities = {}
local playersInZone = {}
local ghostedPlayers = {}
local vehiclesInZone = {}
local zoneMemberIds = {}
local lastVehicleZoneUpdate = 0
local VEHICLE_ZONE_UPDATE_INTERVAL = 200
local lastVehicleEnforce = 0
local VEHICLE_ENFORCE_INTERVAL = Config.Performance.updateIntervals.vehicleEnforce or 50
local lastPlayerUpdate = 0
local PLAYER_UPDATE_INTERVAL = Config.Performance.updateIntervals.playerCache or 600

local function SetEntityAlphaIfNeeded(entity, alpha, storage, storageKey)
    if not DoesEntityExist(entity) then
        return
    end

    if storage and storageKey then
        local stored = storage[storageKey]
        if stored then
            if stored.currentAlpha ~= alpha then
                SetEntityAlpha(entity, alpha, false)
                stored.currentAlpha = alpha
            end
            return
        end
    end

    if GetEntityAlpha(entity) ~= alpha then
        SetEntityAlpha(entity, alpha, false)
    end
end

local function ApplyPlayerAlpha(playerPed, serverId, alpha)
    if not DoesEntityExist(playerPed) or playerPed == Safezone.Player.ped then
        return
    end

    if not ghostedPlayers[serverId] then
        ghostedPlayers[serverId] = {
            ped = playerPed,
            currentAlpha = nil
        }
    else
        ghostedPlayers[serverId].ped = playerPed
    end

    SetEntityAlphaIfNeeded(playerPed, alpha, ghostedPlayers, serverId)
end

function Collision.RemovePlayerGhosting(serverId)
    if ghostedPlayers[serverId] then
        local playerPed = ghostedPlayers[serverId].ped
        if DoesEntityExist(playerPed) then
            ResetEntityAlpha(playerPed)
        end
        ghostedPlayers[serverId] = nil
    end
end

function Collision.SetZoneMembers(list)
    zoneMemberIds = {}
    if type(list) == 'table' then
        for _, serverId in ipairs(list) do
            zoneMemberIds[serverId] = true
        end
    end
end

function Collision.AddZoneMember(serverId)
    if serverId then
        zoneMemberIds[serverId] = true
    end
end

function Collision.RemoveZoneMember(serverId)
    if serverId then
        zoneMemberIds[serverId] = nil
    end
end

local function IsCoordsInCurrentZone(coords)
    local currentSafezone = Safezone.State.currentSafezone
    if not currentSafezone then
        return false
    end

    local processedZones = Zones.GetProcessedZones()
    local zoneCount = Zones.GetZoneCount()

    for i = 1, zoneCount do
        local zone = processedZones[i]
        if zone.name == currentSafezone.name then
            if zone.type == 'circle' then
                local distanceSquared = Zones.GetDistanceSquared(coords, zone.coords)
                if distanceSquared <= zone.radiusSquared and coords.z >= zone.minZ and coords.z <= zone.maxZ then
                    return true
                end
            elseif zone.type == 'polygon' then
                if coords.z >= zone.minZ and coords.z <= zone.maxZ and Zones.IsPointInPolygon(vector2(coords.x, coords.y), zone.points, zone.bounds) then
                    return true
                end
            end
            break
        end
    end

    return false
end

function Collision.UpdatePlayersInZone()
    if not Safezone.State.isInSafezone or not Safezone.State.currentSafezone then
        return
    end

    local ghost = Safezone.IsZoneGhostingEnabled(Safezone.State.currentSafezone)
    local desiredAlpha = Config.CollisionSystem.playerAlpha or 200
    local newPlayersInZone = {}
    local ghostedCount = 0

    for serverId in pairs(zoneMemberIds) do
        local player = GetPlayerFromServerId(serverId)
        if player ~= -1 then
            local playerPed = GetPlayerPed(player)
            if playerPed and playerPed ~= 0 and DoesEntityExist(playerPed) and playerPed ~= Safezone.Player.ped then
                newPlayersInZone[serverId] = {
                    ped = playerPed,
                    player = player
                }

                if ghost then
                    ApplyPlayerAlpha(playerPed, serverId, desiredAlpha)
                    ghostedCount = ghostedCount + 1
                elseif ghostedPlayers[serverId] then
                    Collision.RemovePlayerGhosting(serverId)
                end
            end
        end
    end

    for serverId in pairs(ghostedPlayers) do
        if not newPlayersInZone[serverId] then
            Collision.RemovePlayerGhosting(serverId)
        end
    end

    playersInZone = newPlayersInZone
    Safezone.Performance.playersGhosted = ghostedCount
    lastPlayerUpdate = GetGameTimer()
end

local function TrackVehicleInZone(vehicle)
    if not vehiclesInZone[vehicle] then
        vehiclesInZone[vehicle] = { currentAlpha = nil, invincible = false }
    end
end

local function RestoreVehicleZoneState(vehicle, data)
    if not DoesEntityExist(vehicle) then
        return
    end

    if data and data.invincible then
        SetEntityInvincible(vehicle, false)
        SetEntityCanBeDamaged(vehicle, true)
        SetVehicleTyresCanBurst(vehicle, true)
    end

    ResetEntityAlpha(vehicle)
end

local function RemoveVehicleFromZone(vehicle)
    local data = vehiclesInZone[vehicle]
    vehiclesInZone[vehicle] = nil
    RestoreVehicleZoneState(vehicle, data)
end

function Collision.EnforceVehiclesInZone()
    if not Safezone.State.isInSafezone or not Safezone.State.currentSafezone then
        return
    end

    local zone = Safezone.State.currentSafezone
    local invincible = Safezone.IsZoneVehicleInvincibilityEnabled(zone)
    local ghost = Safezone.IsZoneVehicleGhostingEnabled(zone)
    local noCollision = Safezone.IsZoneCollisionDisabled(zone)
    local desiredAlpha = Config.CollisionSystem.vehicleAlpha or 200

    local activeList = {}

    for vehicle, data in pairs(vehiclesInZone) do
        if DoesEntityExist(vehicle) then
            activeList[#activeList + 1] = vehicle

            if invincible and not data.invincible then
                SetEntityInvincible(vehicle, true)
                SetEntityCanBeDamaged(vehicle, false)
                SetVehicleTyresCanBurst(vehicle, false)
                data.invincible = true
            elseif not invincible and data.invincible then
                SetEntityInvincible(vehicle, false)
                SetEntityCanBeDamaged(vehicle, true)
                SetVehicleTyresCanBurst(vehicle, true)
                data.invincible = false
            end

            if ghost then
                if data.currentAlpha ~= desiredAlpha then
                    SetEntityAlpha(vehicle, desiredAlpha, false)
                    data.currentAlpha = desiredAlpha
                end
            elseif data.currentAlpha ~= nil then
                ResetEntityAlpha(vehicle)
                data.currentAlpha = nil
            end

        else
            vehiclesInZone[vehicle] = nil
        end
    end

    if noCollision then
        for i = 1, #activeList do
            for j = i + 1, #activeList do
                SetEntityNoCollisionEntity(activeList[i], activeList[j], true)
                SetEntityNoCollisionEntity(activeList[j], activeList[i], true)
            end
        end
    end
end

function Collision.UpdateVehiclesInZone()
    if not Safezone.State.isInSafezone or not Safezone.State.currentSafezone then
        return
    end

    local vehicles = GetGamePool('CVehicle')
    local newVehicles = {}

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and IsCoordsInCurrentZone(GetEntityCoords(vehicle)) then
            newVehicles[vehicle] = true
            TrackVehicleInZone(vehicle)
        end
    end

    local toRemove = {}
    for vehicle in pairs(vehiclesInZone) do
        if not newVehicles[vehicle] then
            toRemove[#toRemove + 1] = vehicle
        end
    end
    for _, vehicle in ipairs(toRemove) do
        RemoveVehicleFromZone(vehicle)
    end

    lastVehicleZoneUpdate = GetGameTimer()
end

local function UpdateCollisionEntities()
    local startTime = GetGameTimer()
    collisionEntities = {}
    local vehicleCount = 0
    local playerCoords = Safezone.Player.coords
    local disableVehWeapons = Safezone.State.currentSafezone and Safezone.State.currentSafezone.disableVehicleWeapons ~= false

    local vehicles = GetGamePool('CVehicle')

    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distanceSquared = Zones.GetDistanceSquared(playerCoords, vehicleCoords)

        if distanceSquared <= COLLISION_RANGE_SQUARED then
            vehicleCount = vehicleCount + 1
            collisionEntities[vehicle] = { coords = vehicleCoords }
            processedEntities[vehicle] = true

            if disableVehWeapons and DoesVehicleHaveWeapons(vehicle) then
                SetVehicleWeaponsDisabled(vehicle, true)
                vehicleWeaponsDisabled[vehicle] = true
            end
        end
    end

    Safezone.Performance.collisionUpdateTime = GetGameTimer() - startTime
    Safezone.Performance.vehiclesProcessed = vehicleCount
    lastCollisionUpdate = GetGameTimer()
end

function Collision.RestoreAllCollisions()
    Safezone.UpdatePlayerCache()
    local ped = Safezone.Player.ped

    for serverId in pairs(ghostedPlayers) do
        Collision.RemovePlayerGhosting(serverId)
    end
    playersInZone = {}
    zoneMemberIds = {}

    for entity in pairs(processedEntities) do
        if DoesEntityExist(entity) then
            ResetEntityAlpha(entity)
            if GetEntityType(entity) == 2 then
                SetVehicleWeaponsDisabled(entity, false)
            end
        end
    end

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        SetEntityInvincible(vehicle, false)
        SetEntityCanBeDamaged(vehicle, true)
        SetVehicleTyresCanBurst(vehicle, true)
        ResetEntityAlpha(vehicle)
        SetVehicleWeaponsDisabled(vehicle, false)
    end

    for vehicle, ghostData in pairs(vehiclesInZone) do
        if DoesEntityExist(vehicle) then
            if ghostData.invincible then
                SetEntityInvincible(vehicle, false)
                SetEntityCanBeDamaged(vehicle, true)
                SetVehicleTyresCanBurst(vehicle, true)
            end
            ResetEntityAlpha(vehicle)
        end
    end

    collisionEntities = {}
    vehicleWeaponsDisabled = {}
    ghostedVehicles = {}
    processedEntities = {}
    ghostedPlayers = {}
    playersInZone = {}
    vehiclesInZone = {}
    lastVehicleZoneUpdate = 0
    lastVehicleEnforce = 0

    if ped and DoesEntityExist(ped) then
        ResetEntityAlpha(ped)
    end
end

function Collision.StartCollisionSystem()
    CreateThread(function()
        local zone = Safezone.State.currentSafezone
        if not zone then return end

        if Safezone.IsZoneCollisionDisabled(zone) or Safezone.IsZoneGhostingEnabled(zone) then
            Safezone.ShowNotification(Translate('collision_mode_active'), 'primary')
        end

        local cacheRefreshInterval = Config.Performance.updateIntervals.playerCache or 600
        local alphaEnforceInterval = 250
        local movementResetInterval = 250
        local waitInterval = 0

        local lastCacheRefresh = 0
        local lastAlphaEnforce = 0
        local lastMovementReset = 0

        local desiredPlayerAlpha = Config.CollisionSystem.playerAlpha or 200

        while Safezone.State.isInSafezone do
            local currentTime = GetGameTimer()
            local ped = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(ped, false)
            local liveZone = Safezone.State.currentSafezone
            local isPlayerGhosting = Safezone.IsZoneGhostingEnabled(liveZone)
            local noCollision = Safezone.IsZoneCollisionDisabled(liveZone)

            if currentTime - lastCacheRefresh >= cacheRefreshInterval then
                Safezone.UpdatePlayerCache()
                lastCacheRefresh = currentTime
            end

            if currentTime - lastPlayerUpdate > PLAYER_UPDATE_INTERVAL then
                Collision.UpdatePlayersInZone()
            end

            if currentTime - lastCollisionUpdate > COLLISION_UPDATE_INTERVAL then
                UpdateCollisionEntities()
            end

            if currentTime - lastVehicleZoneUpdate > VEHICLE_ZONE_UPDATE_INTERVAL then
                Collision.UpdateVehiclesInZone()
            end

            if currentTime - lastVehicleEnforce >= VEHICLE_ENFORCE_INTERVAL then
                lastVehicleEnforce = currentTime
                Collision.EnforceVehiclesInZone()
            end

            local enforceAlpha = false
            if currentTime - lastAlphaEnforce >= alphaEnforceInterval then
                lastAlphaEnforce = currentTime
                enforceAlpha = true
            end

            if enforceAlpha then
                if isPlayerGhosting then
                    SetEntityAlphaIfNeeded(ped, desiredPlayerAlpha)
                elseif GetEntityAlpha(ped) ~= 255 then
                    ResetEntityAlpha(ped)
                end
            end

            for serverId, playerData in pairs(playersInZone) do
                local otherPed = playerData.ped
                if DoesEntityExist(otherPed) then
                    if enforceAlpha and isPlayerGhosting then
                        SetEntityAlphaIfNeeded(otherPed, desiredPlayerAlpha, ghostedPlayers, serverId)
                    end

                    if noCollision then
                        SetEntityNoCollisionEntity(ped, otherPed, true)
                        SetEntityNoCollisionEntity(otherPed, ped, true)
                        if myVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, otherPed, true)
                            SetEntityNoCollisionEntity(otherPed, myVeh, true)
                        end
                    end
                end
            end

            if noCollision then
                for vehicle in pairs(vehiclesInZone) do
                    if DoesEntityExist(vehicle) and vehicle ~= myVeh then
                        SetEntityNoCollisionEntity(ped, vehicle, true)
                        SetEntityNoCollisionEntity(vehicle, ped, true)
                        if myVeh ~= 0 then
                            SetEntityNoCollisionEntity(myVeh, vehicle, true)
                            SetEntityNoCollisionEntity(vehicle, myVeh, true)
                        end
                    end
                end
            end

            for entity in pairs(collisionEntities) do
                if not DoesEntityExist(entity) then
                    collisionEntities[entity] = nil
                    ghostedVehicles[entity] = nil
                    vehicleWeaponsDisabled[entity] = nil
                    processedEntities[entity] = nil
                end
            end

            if not IsPedInAnyVehicle(ped, false) and currentTime - lastMovementReset >= movementResetInterval then
                lastMovementReset = currentTime
                SetPedMoveRateOverride(ped, 1.0)
                ActivatePhysics(ped)
                SetEntityVelocity(ped, GetEntityVelocity(ped))
            end

            Wait(waitInterval)
        end
    end)
end

function Collision.StoreOriginalAlpha()
    Safezone.UpdatePlayerCache()
end

function Collision.Clear()
    collisionEntities = {}
    vehicleWeaponsDisabled = {}
    ghostedVehicles = {}
    processedEntities = {}
    ghostedPlayers = {}
    playersInZone = {}
    vehiclesInZone = {}
    zoneMemberIds = {}
    lastVehicleZoneUpdate = 0
    lastVehicleEnforce = 0
    lastCollisionUpdate = 0
    lastPlayerUpdate = 0
end

function Collision.GetCollisionEntities()
    return collisionEntities
end

function Collision.GetGhostedVehicles()
    return ghostedVehicles
end

function Collision.GetGhostedPlayers()
    return ghostedPlayers
end

function Collision.GetPlayersInZone()
    return playersInZone
end
