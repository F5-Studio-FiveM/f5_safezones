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
local ghostedEntities = {}
local processedEntities = {}
local playersInZone = {}
local ghostedPlayers = {}
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

local function ApplyPlayerGhosting(playerPed, serverId)
    if not DoesEntityExist(playerPed) or playerPed == Safezone.Player.ped then
        return
    end

    if not ghostedPlayers[serverId] then
        ghostedPlayers[serverId] = {
            ped = playerPed,
            originalAlpha = GetEntityAlpha(playerPed) == 0 and 255 or GetEntityAlpha(playerPed),
            originalVehicleAlpha = nil,
            currentAlpha = nil,
            currentVehicleAlpha = nil
        }
    else
        ghostedPlayers[serverId].ped = playerPed
    end

    local desiredAlpha = Config.CollisionSystem.playerAlpha or 200
    SetEntityAlphaIfNeeded(playerPed, desiredAlpha, ghostedPlayers, serverId)
    SetEntityNoCollisionEntity(Safezone.Player.ped, playerPed, true)
    SetEntityNoCollisionEntity(playerPed, Safezone.Player.ped, true)

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        if not ghostedPlayers[serverId].originalVehicleAlpha then
            ghostedPlayers[serverId].originalVehicleAlpha = GetEntityAlpha(vehicle) == 0 and 255 or GetEntityAlpha(vehicle)
        end

        local desiredVehicleAlpha = Config.CollisionSystem.vehicleAlpha or 200
        if ghostedPlayers[serverId].currentVehicleAlpha ~= desiredVehicleAlpha then
            SetEntityAlpha(vehicle, desiredVehicleAlpha, false)
            ghostedPlayers[serverId].currentVehicleAlpha = desiredVehicleAlpha
        end
        SetEntityNoCollisionEntity(Safezone.Player.ped, vehicle, true)
        SetEntityNoCollisionEntity(vehicle, Safezone.Player.ped, true)

        local myVehicle = GetVehiclePedIsIn(Safezone.Player.ped, false)
        if myVehicle ~= 0 then
            SetEntityNoCollisionEntity(myVehicle, vehicle, true)
            SetEntityNoCollisionEntity(vehicle, myVehicle, true)
            SetEntityNoCollisionEntity(myVehicle, playerPed, true)
            SetEntityNoCollisionEntity(playerPed, myVehicle, true)
        end
    end
end

function Collision.RemovePlayerGhosting(serverId)
    if ghostedPlayers[serverId] then
        local data = ghostedPlayers[serverId]
        local playerPed = data.ped

        if DoesEntityExist(playerPed) then
            if data.originalAlpha then
                SetEntityAlpha(playerPed, data.originalAlpha, false)
            else
                ResetEntityAlpha(playerPed)
            end

            SetEntityNoCollisionEntity(Safezone.Player.ped, playerPed, false)
            SetEntityNoCollisionEntity(playerPed, Safezone.Player.ped, false)

            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                if data.originalVehicleAlpha then
                    SetEntityAlpha(vehicle, data.originalVehicleAlpha, false)
                else
                    ResetEntityAlpha(vehicle)
                end

                SetEntityNoCollisionEntity(Safezone.Player.ped, vehicle, false)
                SetEntityNoCollisionEntity(vehicle, Safezone.Player.ped, false)

                local myVehicle = GetVehiclePedIsIn(Safezone.Player.ped, false)
                if myVehicle ~= 0 then
                    SetEntityNoCollisionEntity(myVehicle, vehicle, false)
                    SetEntityNoCollisionEntity(vehicle, myVehicle, false)
                    SetEntityNoCollisionEntity(myVehicle, playerPed, false)
                    SetEntityNoCollisionEntity(playerPed, myVehicle, false)
                end
            end
        end

        ghostedPlayers[serverId] = nil
    end
end

local function IsPlayerInCurrentZone(playerPed)
    local currentSafezone = Safezone.State.currentSafezone
    if not currentSafezone then
        return false
    end

    local playerCoords = GetEntityCoords(playerPed)
    local processedZones = Zones.GetProcessedZones()
    local zoneCount = Zones.GetZoneCount()

    for i = 1, zoneCount do
        local zone = processedZones[i]
        if zone.name == currentSafezone.name then
            if zone.type == 'circle' then
                local distanceSquared = Zones.GetDistanceSquared(playerCoords, zone.coords)
                if distanceSquared <= zone.radiusSquared and playerCoords.z >= zone.minZ and playerCoords.z <= zone.maxZ then
                    return true
                end
            elseif zone.type == 'polygon' then
                if playerCoords.z >= zone.minZ and playerCoords.z <= zone.maxZ and Zones.IsPointInPolygon(vector2(playerCoords.x, playerCoords.y), zone.points, zone.bounds) then
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

    local activePlayers = GetActivePlayers()
    local newPlayersInZone = {}
    local ghostedCount = 0

    for _, player in ipairs(activePlayers) do
        if player ~= PlayerId() then
            local playerPed = GetPlayerPed(player)
            local serverId = GetPlayerServerId(player)

            if DoesEntityExist(playerPed) and serverId then
                if IsPlayerInCurrentZone(playerPed) then
                    newPlayersInZone[serverId] = {
                        ped = playerPed,
                        player = player
                    }

                    if Safezone.State.currentSafezone.enableGhosting ~= false then
                        ApplyPlayerGhosting(playerPed, serverId)
                        ghostedCount = ghostedCount + 1
                    end
                end
            end
        end
    end

    for serverId, _ in pairs(ghostedPlayers) do
        if not newPlayersInZone[serverId] then
            Collision.RemovePlayerGhosting(serverId)
        end
    end

    playersInZone = newPlayersInZone
    Safezone.Performance.playersGhosted = ghostedCount
    lastPlayerUpdate = GetGameTimer()
end

local function UpdateCollisionEntities()
    local startTime = GetGameTimer()
    collisionEntities = {}
    local vehicleCount = 0
    local playerCoords = Safezone.Player.coords

    local vehicles = GetGamePool('CVehicle')

    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distanceSquared = Zones.GetDistanceSquared(playerCoords, vehicleCoords)

        if distanceSquared <= COLLISION_RANGE_SQUARED then
            local isPlayerVehicle = false
            for _, playerData in pairs(playersInZone) do
                if GetVehiclePedIsIn(playerData.ped, false) == vehicle then
                    isPlayerVehicle = true
                    break
                end
            end

            if not isPlayerVehicle then
                vehicleCount = vehicleCount + 1
                collisionEntities[vehicle] = {
                    coords = vehicleCoords,
                    model = GetEntityModel(vehicle),
                    driver = GetPedInVehicleSeat(vehicle, -1),
                    hasWeapons = DoesVehicleHaveWeapons(vehicle),
                    originalAlpha = GetEntityAlpha(vehicle) == 0 and 255 or GetEntityAlpha(vehicle)
                }

                processedEntities[vehicle] = true

                if collisionEntities[vehicle].hasWeapons and (Safezone.State.currentSafezone and Safezone.State.currentSafezone.disableVehicleWeapons ~= false) then
                    SetVehicleWeaponsDisabled(vehicle, true)
                    vehicleWeaponsDisabled[vehicle] = true
                end
            end
        end
    end

    local peds = GetGamePool('CPed')

    for _, ped in ipairs(peds) do
        if ped ~= Safezone.Player.ped and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distanceSquared = Zones.GetDistanceSquared(playerCoords, pedCoords)

            if distanceSquared <= COLLISION_RANGE_SQUARED then
                collisionEntities[ped] = {
                    coords = pedCoords,
                    isPed = true,
                    originalAlpha = GetEntityAlpha(ped) == 0 and 255 or GetEntityAlpha(ped)
                }

                processedEntities[ped] = true
            end
        end
    end

    Safezone.Performance.collisionUpdateTime = GetGameTimer() - startTime
    Safezone.Performance.vehiclesProcessed = vehicleCount
    lastCollisionUpdate = GetGameTimer()
end

local function DisableCollisionWithEntity(entity, data)
    if not DoesEntityExist(entity) then
        return
    end

    if GetEntityType(entity) == 2 then
        SetEntityNoCollisionEntity(entity, Safezone.Player.ped, true)
        SetEntityNoCollisionEntity(Safezone.Player.ped, entity, true)

        local myVehicle = GetVehiclePedIsIn(Safezone.Player.ped, false)
        if myVehicle ~= 0 and myVehicle ~= entity then
            SetEntityNoCollisionEntity(entity, myVehicle, true)
            SetEntityNoCollisionEntity(myVehicle, entity, true)
        end

        ghostedEntities[entity] = ghostedEntities[entity] or {
            originalAlpha = data and data.originalAlpha,
            currentAlpha = nil
        }
        SetEntityAlphaIfNeeded(entity, Config.CollisionSystem.vehicleAlpha or 200, ghostedEntities, entity)
        ghostedVehicles[entity] = true
    elseif GetEntityType(entity) == 1 and entity ~= Safezone.Player.ped then
        SetEntityNoCollisionEntity(entity, Safezone.Player.ped, true)
        SetEntityNoCollisionEntity(Safezone.Player.ped, entity, true)
        ghostedEntities[entity] = ghostedEntities[entity] or {
            originalAlpha = data and data.originalAlpha,
            currentAlpha = nil
        }
    end
end

local function RestoreCollisionWithEntity(entity)
    if not DoesEntityExist(entity) then
        return
    end

    if GetEntityType(entity) == 2 or (GetEntityType(entity) == 1 and entity ~= Safezone.Player.ped) then
        SetEntityNoCollisionEntity(entity, Safezone.Player.ped, false)
    end

    ResetEntityAlpha(entity)
    ghostedVehicles[entity] = nil

    if ghostedEntities[entity] then
        ghostedEntities[entity] = nil
    end

    if vehicleWeaponsDisabled[entity] then
        SetVehicleWeaponsDisabled(entity, false)
        vehicleWeaponsDisabled[entity] = nil
    end
end

function Collision.RestoreAllCollisions()
    Safezone.UpdatePlayerCache()
    local ped = Safezone.Player.ped
    local myVeh = GetVehiclePedIsIn(ped, false)
    if myVeh == 0 then
        myVeh = GetVehiclePedIsIn(ped, true)
    end

    for serverId, _ in pairs(ghostedPlayers) do
        Collision.RemovePlayerGhosting(serverId)
    end
    playersInZone = {}

    for entity, ghostData in pairs(ghostedEntities) do
        if DoesEntityExist(entity) then
            SetEntityNoCollisionEntity(entity, ped, false)
            SetEntityNoCollisionEntity(ped, entity, false)
            if myVeh ~= 0 then
                SetEntityNoCollisionEntity(entity, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, entity, false)
            end
            if ghostData.originalAlpha then
                SetEntityAlpha(entity, ghostData.originalAlpha, false)
            else
                ResetEntityAlpha(entity)
            end
            if GetEntityType(entity) == 2 and vehicleWeaponsDisabled[entity] then
                SetVehicleWeaponsDisabled(entity, false)
            end
        end
    end

    for entity, _ in pairs(processedEntities) do
        if DoesEntityExist(entity) then
            SetEntityNoCollisionEntity(entity, ped, false)
            SetEntityNoCollisionEntity(ped, entity, false)
            if myVeh ~= 0 then
                SetEntityNoCollisionEntity(entity, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, entity, false)
            end
            ResetEntityAlpha(entity)
            if GetEntityType(entity) == 2 then
                SetVehicleWeaponsDisabled(entity, false)
            end
        end
    end

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(Safezone.Player.coords - vehicleCoords)
        if distance < (COLLISION_RANGE * 2) then
            SetEntityNoCollisionEntity(vehicle, ped, false)
            SetEntityNoCollisionEntity(ped, vehicle, false)
            if myVeh ~= 0 and myVeh ~= vehicle then
                SetEntityNoCollisionEntity(vehicle, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, vehicle, false)
            end
            ResetEntityAlpha(vehicle)
            SetVehicleWeaponsDisabled(vehicle, false)
        end
    end

    local peds = GetGamePool('CPed')
    for _, p in ipairs(peds) do
        if p ~= ped and DoesEntityExist(p) then
            SetEntityNoCollisionEntity(p, ped, false)
            SetEntityNoCollisionEntity(ped, p, false)
            if myVeh ~= 0 then
                SetEntityNoCollisionEntity(p, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, p, false)
            end
        end
    end

    local objects = GetGamePool('CObject')
    for _, obj in ipairs(objects) do
        if DoesEntityExist(obj) then
            SetEntityNoCollisionEntity(obj, ped, false)
            SetEntityNoCollisionEntity(ped, obj, false)
            if myVeh ~= 0 then
                SetEntityNoCollisionEntity(obj, myVeh, false)
                SetEntityNoCollisionEntity(myVeh, obj, false)
            end
        end
    end

    collisionEntities = {}
    vehicleWeaponsDisabled = {}
    ghostedVehicles = {}
    ghostedEntities = {}
    processedEntities = {}
    ghostedPlayers = {}
    playersInZone = {}

    if ped and DoesEntityExist(ped) then
        ResetEntityAlpha(ped)
    end
    if myVeh ~= 0 and DoesEntityExist(myVeh) then
        ResetEntityAlpha(myVeh)
    end
end

local function PreventVehicleDamage()
    SetEntityProofs(Safezone.Player.ped, false, false, false, true, false, false, false, false)
    SetPedCanRagdoll(Safezone.Player.ped, false)
    SetPedCanRagdollFromPlayerImpact(Safezone.Player.ped, false)
    SetPedConfigFlag(Safezone.Player.ped, 32, false)
    SetPedCanBeKnockedOffVehicle(Safezone.Player.ped, 1)
    SetPedCanBeDraggedOut(Safezone.Player.ped, false)
    SetPedSuffersCriticalHits(Safezone.Player.ped, false)

    if IsPedRagdoll(Safezone.Player.ped) then
        SetPedToRagdoll(Safezone.Player.ped, 1, 1, 0, false, false, false)
    end
end

function Collision.StartCollisionSystem()
    CreateThread(function()
        local zone = Safezone.State.currentSafezone
        if not zone then return end

        local isFullGhost = zone.collisionDisabled == true
        local isPlayerGhosting = zone.enableGhosting ~= false

        if isFullGhost or isPlayerGhosting then
            Safezone.ShowNotification(Translate('collision_mode_active'), 'primary')
        end

        local cacheRefreshInterval = Config.Performance.updateIntervals.playerCache or 600
        local alphaEnforceInterval = 250
        local damageProtectionInterval = 300
        local movementResetInterval = 250
        local waitInterval = 5

        local lastCacheRefresh = 0
        local lastAlphaEnforce = 0
        local lastDamageProtection = 0
        local lastMovementReset = 0

        local desiredPlayerAlpha = Config.CollisionSystem.playerAlpha or 200

        while Safezone.State.isInSafezone do
            local currentTime = GetGameTimer()
            local ped = PlayerPedId()

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

            if isPlayerGhosting or isFullGhost then
                local enforceAlpha = false
                if currentTime - lastAlphaEnforce >= alphaEnforceInterval then
                    lastAlphaEnforce = currentTime
                    enforceAlpha = true
                    SetEntityAlphaIfNeeded(ped, desiredPlayerAlpha)
                end

                for serverId, playerData in pairs(playersInZone) do
                    if DoesEntityExist(playerData.ped) then
                        if enforceAlpha then
                            SetEntityAlphaIfNeeded(playerData.ped, desiredPlayerAlpha, ghostedPlayers, serverId)
                        end
                        SetEntityNoCollisionEntity(ped, playerData.ped, true)
                        SetEntityNoCollisionEntity(playerData.ped, ped, true)

                        local theirVeh = GetVehiclePedIsIn(playerData.ped, false)
                        if theirVeh ~= 0 and DoesEntityExist(theirVeh) then
                            SetEntityNoCollisionEntity(ped, theirVeh, true)
                            SetEntityNoCollisionEntity(theirVeh, ped, true)
                            local myVeh = GetVehiclePedIsIn(ped, false)
                            if myVeh ~= 0 and myVeh ~= theirVeh then
                                SetEntityNoCollisionEntity(myVeh, theirVeh, true)
                                SetEntityNoCollisionEntity(theirVeh, myVeh, true)
                            end
                        end
                    end
                end
            end

            for entity, data in pairs(collisionEntities) do
                if DoesEntityExist(entity) then
                    if isFullGhost then
                        DisableCollisionWithEntity(entity, data)

                        if GetEntityType(entity) == 2 then
                            local vehicleCoords = GetEntityCoords(entity)
                            local distance = #(Safezone.Player.coords - vehicleCoords)
                            if distance < 5.0 then
                                SetEntityAlphaIfNeeded(entity, 150, ghostedEntities, entity)
                            end
                        end
                    end
                else
                    collisionEntities[entity] = nil
                    ghostedVehicles[entity] = nil
                    vehicleWeaponsDisabled[entity] = nil
                    ghostedEntities[entity] = nil
                    processedEntities[entity] = nil
                end
            end

            if isFullGhost then
                local myVeh = GetVehiclePedIsIn(ped, false)
                local objects = GetGamePool('CObject')
                for _, obj in ipairs(objects) do
                    if DoesEntityExist(obj) and not IsEntityAttachedToEntity(ped, obj) then
                        local objCoords = GetEntityCoords(obj)
                        local dist = #(Safezone.Player.coords - objCoords)
                        if dist < COLLISION_RANGE then
                            SetEntityNoCollisionEntity(ped, obj, true)
                            SetEntityNoCollisionEntity(obj, ped, true)
                            if myVeh ~= 0 then
                                SetEntityNoCollisionEntity(myVeh, obj, true)
                                SetEntityNoCollisionEntity(obj, myVeh, true)
                            end
                        end
                    end
                end
            end

            local preventDamage = zone and zone.preventVehicleDamage ~= false
            local applyDamageProtection = false

            if preventDamage and currentTime - lastDamageProtection >= damageProtectionInterval then
                lastDamageProtection = currentTime
                PreventVehicleDamage()
                applyDamageProtection = true
            end

            if not IsPedInAnyVehicle(ped, false) and currentTime - lastMovementReset >= movementResetInterval then
                lastMovementReset = currentTime
                SetPedMoveRateOverride(ped, 1.0)
                SetPlayerControl(Safezone.Player.id, true, 0)
                ActivatePhysics(ped)
                SetEntityVelocity(ped, GetEntityVelocity(ped))
            end

            if preventDamage and applyDamageProtection then
                SetEntityProofs(ped, false, false, false, true, false, false, false, false)
                SetPlayerCanBeHassledByGangs(Safezone.Player.id, false)
                SetPlayerVehicleDamageModifier(Safezone.Player.id, 0.0)
                SetPlayerWeaponDamageModifier(Safezone.Player.id, 0.0)
                SetPlayerMeleeWeaponDamageModifier(Safezone.Player.id, 0.0)
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
    ghostedEntities = {}
    processedEntities = {}
    ghostedPlayers = {}
    playersInZone = {}
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

RegisterNetEvent('f5_safezones:syncCollisionRequest', function(targetPlayer)
    if Safezone.State.isInSafezone then
        TriggerServerEvent('f5_safezones:syncCollisionResponse', targetPlayer, true)
    end
end)

RegisterNetEvent('f5_safezones:applyCollisionSync', function(sourcePlayer)
    if Safezone.State.isInSafezone then
        local sourcePed = GetPlayerPed(GetPlayerFromServerId(sourcePlayer))
        if sourcePed and DoesEntityExist(sourcePed) then
            SetEntityNoCollisionEntity(Safezone.Player.ped, sourcePed, true)
            SetEntityNoCollisionEntity(sourcePed, Safezone.Player.ped, true)
        end
    end
end)
