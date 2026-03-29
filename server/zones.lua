local Server = SafezoneServer
Server.Zones = Server.Zones or {}
local Zones = Server.Zones
local Logging = Server.Logging

Zones.stateDirty = Zones.stateDirty or false
Zones.idCounter = 0
Zones.idLookup = {}

local function tableCount(tbl)
    if type(tbl) ~= 'table' then
        return 0
    end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

local function normalizeZoneName(name)
    if not name or type(name) ~= 'string' then
        return nil
    end
    local trimmed = name:match('^%s*(.-)%s*$')
    if not trimmed or #trimmed == 0 then
        return nil
    end
    return trimmed
end

local function parseBoolean(value, default)
    if value == nil then
        return default
    end

    if type(value) == 'boolean' then
        return value
    end

    if type(value) == 'number' then
        if value == 0 then
            return false
        end
        if value == 1 then
            return true
        end
        return value ~= 0
    end

    if type(value) == 'string' then
        local normalized = value:lower()
        if normalized == 'false' or normalized == '0' or normalized == 'off' or normalized == 'no' then
            return false
        end
        if normalized == 'true' or normalized == '1' or normalized == 'on' or normalized == 'yes' then
            return true
        end
    end

    return default
end

local function validateJobOverrides(data)
    if type(data) ~= 'table' then
        return { enabled = false, jobs = {} }
    end

    local jobs = {}
    if type(data.jobs) == 'table' then
        for _, job in ipairs(data.jobs) do
            if type(job) == 'table' and type(job.name) == 'string' and #job.name > 0 then
                table.insert(jobs, {
                    name = job.name:lower():gsub('%s+', ''),
                    minGrade = math.max(0, math.floor(tonumber(job.minGrade) or 0)),
                    enableInvincibility = parseBoolean(job.enableInvincibility, true),
                    enableGhosting = parseBoolean(job.enableGhosting, true),
                    preventVehicleDamage = parseBoolean(job.preventVehicleDamage, true),
                    disableVehicleWeapons = parseBoolean(job.disableVehicleWeapons, true),
                    disableWeapons = parseBoolean(job.disableWeapons, true)
                })
            end
        end
    end

    return {
        enabled = parseBoolean(data.enabled, false),
        jobs = jobs
    }
end

local function normalizeInvincibilityOption(zoneData)
    if type(zoneData) ~= 'table' then
        return
    end

    local invincibility = zoneData.enableInvincibility
    if invincibility == nil and zoneData.enableImmortality ~= nil then
        invincibility = zoneData.enableImmortality
    end

    zoneData.enableInvincibility = parseBoolean(invincibility, true)
    zoneData.enableImmortality = nil
end

function Zones.LoadZoneStates()
    Server.zoneActivationStates = Server.zoneActivationStates or {}

    local file = io.open(Server.Paths.zoneStateFile, 'r')
    if file then
        local content = file:read('*all')
        file:close()

        if content and content ~= '' then
            local success, data = pcall(json.decode, content)
            if success and type(data) == 'table' then
                Server.zoneActivationStates = data
            else
                Log('ERROR', 'Failed to decode zone state file, recreating defaults')
                Server.zoneActivationStates = {}
                Zones.stateDirty = true
            end
        end
    else
        Log('INFO', 'Zone state file not found, creating new one with defaults')
        Server.zoneActivationStates = {}
        Zones.stateDirty = true
    end

    if Zones.stateDirty then
        Zones.SaveZoneStates()
    end
end

function Zones.SaveZoneStates()
    local file = io.open(Server.Paths.zoneStateFile, 'w')
    if file then
        file:write(json.encode(Server.zoneActivationStates or {}, { indent = true }))
        file:close()
        Zones.stateDirty = false
        Log('INFO', 'Persisted %d zone activation state(s) to zone_states.json', tableCount(Server.zoneActivationStates or {}))
        return true
    else
        Log('ERROR', 'Failed to persist zone activation states to disk')
    end
    return false
end

function Zones.EnsureZoneActivationState(zoneName)
    zoneName = normalizeZoneName(zoneName)
    if not zoneName then
        return
    end

    if Server.zoneActivationStates[zoneName] == nil then
        Server.zoneActivationStates[zoneName] = true
        Zones.stateDirty = true
    end
end

local function isZoneActive(zoneName)
    zoneName = normalizeZoneName(zoneName)
    if not zoneName then
        return true
    end

    local state = Server.zoneActivationStates[zoneName]
    if state == nil then
        return true
    end
    return state ~= false
end

function Zones.LoadCustomZones()
    local file = io.open(Server.Paths.zonesFile, 'r')
    if file then
        local content = file:read('*all')
        file:close()

        if content and content ~= '' then
            local success, zones = pcall(json.decode, content)
            if success and zones then
                Server.customZones = {}
                for i, zone in ipairs(zones) do
                    if Zones.ValidateZone(zone) then
                        Zones.EnsureZoneActivationState(zone.name)
                        normalizeInvincibilityOption(zone)
                        table.insert(Server.customZones, zone)

                        if zone.showMarker ~= nil then
                            Server.zoneMarkerStates[zone.name] = zone.showMarker
                        end
                    else
                        Log('ERROR', 'Skipping invalid custom zone entry at index %d', i)
                    end
                end
            else
                Log('ERROR', 'Failed to decode custom zones file, recreating from backup data')
                Server.customZones = {}
                Zones.SaveCustomZones()
            end
        end
    else
        Log('ERROR', 'Custom zones file not found, creating a new template file')
        Server.customZones = {}
        Zones.SaveCustomZones()
    end
end

function Zones.ValidateZone(zone)
    if not zone then
        return false
    end
    if type(zone) ~= 'table' then
        return false
    end
    normalizeInvincibilityOption(zone)
    if not zone.name or type(zone.name) ~= 'string' or #zone.name < 3 then
        return false
    end
    if not zone.type or (zone.type ~= 'circle' and zone.type ~= 'polygon') then
        return false
    end

    if zone.type == 'circle' then
        if not zone.coords then
            return false
        end
        if not zone.coords.x or not zone.coords.y or not zone.coords.z then
            return false
        end
        if type(zone.coords.x) ~= 'number' or type(zone.coords.y) ~= 'number' or type(zone.coords.z) ~= 'number' then
            return false
        end
        if not zone.radius or type(zone.radius) ~= 'number' or zone.radius < 10 or zone.radius > 500 then
            return false
        end
    elseif zone.type == 'polygon' then
        if not zone.points or type(zone.points) ~= 'table' or #zone.points < 3 then
            return false
        end
        for _, point in ipairs(zone.points) do
            if not point.x or not point.y then
                return false
            end
            if type(point.x) ~= 'number' or type(point.y) ~= 'number' then
                return false
            end
        end
        if not zone.minZ or not zone.maxZ then
            return false
        end
        if type(zone.minZ) ~= 'number' or type(zone.maxZ) ~= 'number' then
            return false
        end
        if zone.minZ >= zone.maxZ then
            return false
        end
    end

    if zone.markerConfig then
        if zone.markerConfig.type and (type(zone.markerConfig.type) ~= 'number' or not Config.MarkerTypes[zone.markerConfig.type]) then
            zone.markerConfig.type = Config.DefaultMarker.type
        end

        if zone.markerConfig.color then
            local c = zone.markerConfig.color
            if not c.r or not c.g or not c.b then
                zone.markerConfig.color = Config.DefaultMarker.color
            else
                c.r = math.max(0, math.min(255, c.r))
                c.g = math.max(0, math.min(255, c.g))
                c.b = math.max(0, math.min(255, c.b))
                c.a = c.a and math.max(0, math.min(255, c.a)) or 100
            end
        end
    end

    return true
end

function Zones.SaveCustomZones()
    if Server.zoneSaveTimer then
        ClearTimeout(Server.zoneSaveTimer)
        Server.zoneSaveTimer = nil
    end

    Server.zoneSaveTimer = SetTimeout(1000, function()
        local success = Zones.PerformZoneSave()
        if success then
            TriggerClientEvent('f5_safezones:updateZones', -1, Zones.GetAllZones())
        end
        Server.zoneSaveTimer = nil
    end)
end

function Zones.PerformZoneSave()
    local backupPath = Server.Paths.zonesFile .. '.backup'
    local currentFile = io.open(Server.Paths.zonesFile, 'r')
    if currentFile then
        local currentContent = currentFile:read('*all')
        currentFile:close()

        local backupFile = io.open(backupPath, 'w')
        if backupFile then
            backupFile:write(currentContent)
            backupFile:close()
        end
    end

    local file = io.open(Server.Paths.zonesFile, 'w')
    if file then
        for _, zone in ipairs(Server.customZones) do
            normalizeInvincibilityOption(zone)
        end

        local jsonString = json.encode(Server.customZones, {
            indent = true
        })
        file:write(jsonString)
        file:close()

        Log('SUCCESS', 'Persisted %d custom zone(s) to zones.json', #Server.customZones)
        return true
    else
        Log('ERROR', 'Failed to write zones.json, attempting to restore last backup')

        local backupFile = io.open(backupPath, 'r')
        if backupFile then
            local backupContent = backupFile:read('*all')
            backupFile:close()

            local restoreFile = io.open(Server.Paths.zonesFile, 'w')
            if restoreFile then
                restoreFile:write(backupContent)
                restoreFile:close()
                Log('SUCCESS', 'Restored zones.json from backup copy')
            end
        end

        return false
    end
end

function Zones.GetAllZones()
    local allZones = {}
    local currentId = 1
    Zones.idLookup = {}

    for i, zone in ipairs(Config.Safezones) do
        local zoneCopy = {}
        for k, v in pairs(zone) do
            if type(v) == 'table' then
                zoneCopy[k] = table.clone(v)
            else
                zoneCopy[k] = v
            end
        end

        zoneCopy.id = currentId
        zoneCopy.isCustom = false

        Zones.EnsureZoneActivationState(zoneCopy.name)
        zoneCopy.isActive = isZoneActive(zoneCopy.name)
        normalizeInvincibilityOption(zoneCopy)

        if Server.zoneMarkerStates[zone.name] ~= nil then
            zoneCopy.showMarker = Server.zoneMarkerStates[zone.name]
        end

        if zone.markerPreset and Config.MarkerPresets[zone.markerPreset] then
            local base = zoneCopy.markerConfig or {}
            local preset = Config.MarkerPresets[zone.markerPreset]
            for k, v in pairs(preset) do
                base[k] = v
            end
            zoneCopy.markerConfig = base
        end

        if zoneCopy.coords then
            zoneCopy.coords = {
                x = tonumber(zoneCopy.coords.x) or 0.0,
                y = tonumber(zoneCopy.coords.y) or 0.0,
                z = tonumber(zoneCopy.coords.z) or 0.0
            }
        end

        Zones.idLookup[currentId] = zoneCopy
        table.insert(allZones, zoneCopy)
        currentId = currentId + 1
    end

    for i, zone in ipairs(Server.customZones) do
        local zoneCopy = {}
        for k, v in pairs(zone) do
            if type(v) == 'table' then
                zoneCopy[k] = table.clone(v)
            else
                zoneCopy[k] = v
            end
        end

        zoneCopy.id = currentId
        zoneCopy.isCustom = true
        zoneCopy.customIndex = i

        Zones.EnsureZoneActivationState(zoneCopy.name)
        zoneCopy.isActive = isZoneActive(zoneCopy.name)
        normalizeInvincibilityOption(zoneCopy)

        if Server.zoneMarkerStates[zone.name] ~= nil then
            zoneCopy.showMarker = Server.zoneMarkerStates[zone.name]
        end

        if zoneCopy.coords then
            zoneCopy.coords = {
                x = tonumber(zoneCopy.coords.x) or 0.0,
                y = tonumber(zoneCopy.coords.y) or 0.0,
                z = tonumber(zoneCopy.coords.z) or 0.0
            }
        end

        if zoneCopy.blipCoords then
            zoneCopy.blipCoords = vector3(tonumber(zoneCopy.blipCoords.x) or 0.0,
                tonumber(zoneCopy.blipCoords.y) or 0.0, tonumber(zoneCopy.blipCoords.z) or 0.0)
        end

        Zones.idLookup[currentId] = zoneCopy
        table.insert(allZones, zoneCopy)
        currentId = currentId + 1
    end

    Zones.idCounter = currentId - 1

    if Zones.stateDirty then
        Zones.SaveZoneStates()
    end

    return allZones
end

function Zones.GetZoneById(id)
    local numId = tonumber(id)
    if not numId then return nil end
    return Zones.idLookup[numId]
end

RegisterNetEvent('f5_safezones:requestZoneUpdate', function()
    local src = source
    TriggerClientEvent('f5_safezones:updateZones', src, Zones.GetAllZones())
end)

RegisterNetEvent('f5_safezones:createZone', function(zoneData)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'),
            'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized zone creation attempt', {
                details = {
                    request = 'create_zone',
                    zoneName = zoneData and zoneData.name
                }
            }, 'SECURITY')
        end
        return
    end

    if not zoneData then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('invalid_zone_data'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - invalid data', {
                details = {
                    reason = 'invalid_data'
                }
            }, 'ZONE')
        end
        return
    end

    zoneData.name = string.gsub(tostring(zoneData.name or ''), '[^%w%s%-_]', '')
    if #zoneData.name < 3 or #zoneData.name > 50 then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_name_length'),
            'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - invalid name length', {
                details = {
                    reason = 'invalid_name',
                    zoneName = zoneData.name
                }
            }, 'ZONE')
        end
        return
    end

    local allZones = Zones.GetAllZones()
    for _, zone in ipairs(allZones) do
        if zone.name:lower() == zoneData.name:lower() then
            TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_name_exists'), 'error')
            if Logging then
                Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - duplicate name', {
                    details = {
                        reason = 'duplicate_name',
                        zoneName = zoneData.name
                    }
                }, 'ZONE')
            end
            return
        end
    end

    local invincibilityInput = zoneData.enableInvincibility
    if invincibilityInput == nil and zoneData.enableImmortality ~= nil then
        invincibilityInput = zoneData.enableImmortality
    end

    local newZone = {
        name = zoneData.name,
        type = zoneData.type or 'circle',
        showBlip = zoneData.showBlip == true,
        showMarker = zoneData.showMarker == true,
        blipName = zoneData.blipName and tostring(zoneData.blipName) or (Translate('safezone_prefix') .. zoneData.name),
        blipSprite = tonumber(zoneData.blipSprite) or 84,
        blipColor = zoneData.blipColor or '0xF5A623FF',

        showCenterBlip = zoneData.showCenterBlip ~= false,
        blipAlpha = tonumber(zoneData.blipAlpha) or 180,
        blipScale = tonumber(zoneData.blipScale) or 0.8,
        blipShortRange = zoneData.blipShortRange == true,
        blipHiddenOnLegend = zoneData.blipHiddenOnLegend == true,
        blipHighDetail = zoneData.blipHighDetail ~= false,

        showZoneOutline = zoneData.showZoneOutline ~= false,
        outlineRadius = tonumber(zoneData.outlineRadius) or 1.2,
        outlineSpacing = tonumber(zoneData.outlineSpacing) or 6.0,
        outlineAlpha = tonumber(zoneData.outlineAlpha) or 160,
        outlineColor = zoneData.outlineColor or '#F5A623',

        outlineStrokeEnabled = zoneData.outlineStrokeEnabled ~= false,
        strokeRadius = tonumber(zoneData.strokeRadius) or 1.5,
        strokeColor = zoneData.strokeColor or '#FFFFFF',
        strokeAlpha = tonumber(zoneData.strokeAlpha) or 220,

        circleCoverageType = zoneData.circleCoverageType or 'full',

        enableInvincibility = parseBoolean(invincibilityInput, true),
        enableGhosting = zoneData.enableGhosting ~= false,
        preventVehicleDamage = zoneData.preventVehicleDamage ~= false,
        disableVehicleWeapons = zoneData.disableVehicleWeapons ~= false,
        collisionDisabled = zoneData.collisionDisabled == true,
        createdBy = GetPlayerName(src),
        createdAt = os.time(),
        renderDistance = tonumber(zoneData.renderDistance) or 150.0,
        jobOverrides = validateJobOverrides(zoneData.jobOverrides)
    }

    if zoneData.markerConfig then
        newZone.markerConfig = {
            type = tonumber(zoneData.markerConfig.type) or Config.DefaultMarker.type,
            color = {
                r = math.floor(tonumber(zoneData.markerConfig.color.r) or 0),
                g = math.floor(tonumber(zoneData.markerConfig.color.g) or 255),
                b = math.floor(tonumber(zoneData.markerConfig.color.b) or 136),
                a = math.floor(tonumber(zoneData.markerConfig.alpha) or 100)
            },
            height = tonumber(zoneData.markerConfig.height) or Config.DefaultMarker.height or 30.0,
            bobbing = zoneData.markerConfig.bobbing == true,
            pulsing = zoneData.markerConfig.pulsing == true,
            rotating = zoneData.markerConfig.rotating == true,
            colorShift = zoneData.markerConfig.colorShift == true,
            autoLevel = zoneData.markerConfig.autoLevel ~= false,
            pulseSpeed = tonumber(zoneData.markerConfig.pulseSpeed) or Config.DefaultMarker.pulseSpeed,
            bobHeight = tonumber(zoneData.markerConfig.bobHeight) or Config.DefaultMarker.bobHeight,
            rotationSpeed = tonumber(zoneData.markerConfig.rotationSpeed) or Config.DefaultMarker.rotationSpeed
        }

        if zoneData.type == 'polygon' and zoneData.markerConfig then
            newZone.markerConfig.wallColor = newZone.markerConfig.color
            newZone.markerConfig.groundColor = {
                r = newZone.markerConfig.color.r,
                g = newZone.markerConfig.color.g,
                b = newZone.markerConfig.color.b,
                a = math.floor(newZone.markerConfig.color.a * 0.5)
            }
            newZone.markerConfig.pulseEffect = zoneData.markerConfig.pulsing
            newZone.markerConfig.gradientEffect = Config.PolygonMarker.gradientEffect ~= false
            newZone.markerConfig.cornerBeams = Config.PolygonMarker.cornerBeams ~= false
        end
    end

    if zoneData.type == 'polygon' then
        if not zoneData.points or type(zoneData.points) ~= 'table' or #zoneData.points < 3 then
            TriggerClientEvent('f5_safezones:showNotification', src, Translate('polygon_min_points'),
                'error')
            if Logging then
                Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - insufficient polygon points', {
                    details = {
                        reason = 'polygon_points'
                    }
                }, 'ZONE')
            end
            return
        end

        local points = {}
        for i, point in ipairs(zoneData.points) do
            local x = tonumber(point.x)
            local y = tonumber(point.y)

            if not x or not y then
                TriggerClientEvent('f5_safezones:showNotification', src,
                    string.format(Translate('invalid_point_coords'), i), 'error')
                if Logging then
                    Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - invalid polygon coordinates', {
                        details = {
                            reason = 'invalid_point',
                            index = i
                        }
                    }, 'ZONE')
                end
                return
            end

            if x < -8000 or x > 8000 or y < -8000 or y > 8000 then
                TriggerClientEvent('f5_safezones:showNotification', src,
                    Translate('coords_out_of_bounds'), 'error')
                if Logging then
                    Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - polygon coordinates out of bounds', {
                        details = {
                            reason = 'coords_out_of_bounds'
                        }
                    }, 'ZONE')
                end
                return
            end

            table.insert(points, vector2(x, y))
        end

        newZone.points = points
        newZone.minZ = tonumber(zoneData.minZ) or -200.0
        newZone.maxZ = tonumber(zoneData.maxZ) or 800.0
        newZone.addRoof = zoneData.addRoof == true
        newZone.infiniteHeight = zoneData.infiniteHeight == true
    else
        if not zoneData.coords or not zoneData.coords.x or not zoneData.coords.y or not zoneData.coords.z then
            TriggerClientEvent('f5_safezones:showNotification', src, Translate('invalid_circle_coords'),
                'error')
            if Logging then
                Logging:LogAdminAction(src, 'zone:create', 'Zone creation failed - invalid circle coordinates', {
                    details = {
                        reason = 'invalid_circle_coords'
                    }
                }, 'ZONE')
            end
            return
        end

        newZone.coords = {
            x = tonumber(zoneData.coords.x) or 0.0,
            y = tonumber(zoneData.coords.y) or 0.0,
            z = tonumber(zoneData.coords.z) or 0.0
        }

        newZone.radius = tonumber(zoneData.radius) or 50.0
        newZone.height = tonumber(zoneData.height) or 50.0

        if zoneData.customMinZ or zoneData.customMaxZ then
            newZone.minZ = tonumber(zoneData.customMinZ) or (newZone.coords.z - 50)
            newZone.maxZ = tonumber(zoneData.customMaxZ) or (newZone.coords.z + 150)
            newZone.infiniteHeight = false
        else
            if zoneData.useGroundHeight then
                newZone.minZ = newZone.coords.z - 5
                newZone.maxZ = newZone.coords.z + newZone.height
            else
                newZone.minZ = newZone.coords.z - 50
                newZone.maxZ = newZone.coords.z + 150
            end
            newZone.infiniteHeight = false
        end
    end

    normalizeInvincibilityOption(newZone)

    table.insert(Server.customZones, newZone)

    Server.zoneActivationStates[newZone.name] = true
    Zones.SaveZoneStates()

    Zones.SaveCustomZones()

    TriggerClientEvent('f5_safezones:showNotification', src, string.format(Translate('zone_created'), newZone.name),
        'success')

    local playerName = GetPlayerName(src)
    local markerName = newZone.markerConfig and Config.MarkerTypes[newZone.markerConfig.type] or 'Unknown'
    Log('ADMIN', 'Admin %s (ID %d) created zone "%s" (%s, marker %s)', playerName, src, newZone.name, newZone.type,
        markerName)

    if Logging then
        Logging:LogAdminAction(src, 'zone:create', string.format('Created zone "%s"', newZone.name),
            Logging.AppendZoneContext({
                details = {
                    marker = markerName,
                    createdAt = newZone.createdAt
                }
            }, newZone), 'ZONE')
    end

    TriggerEvent('f5_safezones:zoneCreated', {
        admin = src,
        adminName = playerName,
        zone = newZone
    })
end)

RegisterNetEvent('f5_safezones:updateZone', function(zoneData)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized zone update attempt', {
                details = {
                    request = 'update_zone',
                    zoneName = zoneData and zoneData.name
                }
            }, 'SECURITY')
        end
        return
    end

    if not zoneData or not zoneData.id or not zoneData.originalName then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('invalid_zone_data'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - invalid data', {
                details = {
                    reason = 'invalid_data'
                }
            }, 'ZONE')
        end
        return
    end

    local zoneIndex = nil
    local oldZone = nil

    for i, zone in ipairs(Server.customZones) do
        if zone.name == zoneData.originalName then
            zoneIndex = i
            oldZone = zone
            break
        end
    end

    if not zoneIndex then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_not_found'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - zone not found', {
                details = {
                    reason = 'not_found',
                    zoneName = zoneData.originalName
                }
            }, 'ZONE')
        end
        return
    end

    zoneData.name = string.gsub(tostring(zoneData.name or ''), '[^%w%s%-_]', '')
    if #zoneData.name < 3 or #zoneData.name > 50 then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_name_length'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - invalid name length', {
                details = {
                    reason = 'invalid_name',
                    zoneName = zoneData.name
                }
            }, 'ZONE')
        end
        return
    end

    if zoneData.name ~= zoneData.originalName then
        local allZones = Zones.GetAllZones()
        for _, zone in ipairs(allZones) do
            if zone.name:lower() == zoneData.name:lower() then
                TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_name_exists'), 'error')
                if Logging then
                    Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - duplicate name', {
                        details = {
                            reason = 'duplicate_name',
                            zoneName = zoneData.name
                        }
                    }, 'ZONE')
                end
                return
            end
        end
    end

    local updateInvincibilityInput = zoneData.enableInvincibility
    if updateInvincibilityInput == nil and zoneData.enableImmortality ~= nil then
        updateInvincibilityInput = zoneData.enableImmortality
    end

    local updatedZone = {
        name = zoneData.name,
        type = zoneData.type or 'circle',
        showBlip = zoneData.showBlip == true,
        showMarker = zoneData.showMarker == true,
        blipName = zoneData.blipName and tostring(zoneData.blipName) or (Translate('safezone_prefix') .. zoneData.name),
        blipSprite = tonumber(zoneData.blipSprite) or oldZone.blipSprite or 84,
        blipColor = zoneData.blipColor or oldZone.blipColor or '0xF5A623FF',

        showCenterBlip = zoneData.showCenterBlip ~= false,
        blipAlpha = tonumber(zoneData.blipAlpha) or oldZone.blipAlpha or 180,
        blipScale = tonumber(zoneData.blipScale) or oldZone.blipScale or 0.8,
        blipShortRange = zoneData.blipShortRange == true,
        blipHiddenOnLegend = zoneData.blipHiddenOnLegend == true,
        blipHighDetail = zoneData.blipHighDetail ~= false,

        showZoneOutline = zoneData.showZoneOutline ~= false,
        outlineRadius = tonumber(zoneData.outlineRadius) or oldZone.outlineRadius or 1.2,
        outlineSpacing = tonumber(zoneData.outlineSpacing) or oldZone.outlineSpacing or 6.0,
        outlineAlpha = tonumber(zoneData.outlineAlpha) or oldZone.outlineAlpha or 160,
        outlineColor = zoneData.outlineColor or oldZone.outlineColor or '#F5A623',

        outlineStrokeEnabled = zoneData.outlineStrokeEnabled ~= false,
        strokeRadius = tonumber(zoneData.strokeRadius) or oldZone.strokeRadius or 1.5,
        strokeColor = zoneData.strokeColor or oldZone.strokeColor or '#FFFFFF',
        strokeAlpha = tonumber(zoneData.strokeAlpha) or oldZone.strokeAlpha or 220,

        circleCoverageType = zoneData.circleCoverageType or oldZone.circleCoverageType or 'full',

        enableInvincibility = parseBoolean(updateInvincibilityInput, true),
        enableGhosting = zoneData.enableGhosting ~= false,
        preventVehicleDamage = zoneData.preventVehicleDamage ~= false,
        disableVehicleWeapons = zoneData.disableVehicleWeapons ~= false,
        collisionDisabled = zoneData.collisionDisabled == true,
        createdBy = oldZone.createdBy or 'Unknown',
        createdAt = oldZone.createdAt or os.time(),
        updatedBy = GetPlayerName(src),
        updatedAt = os.time(),
        renderDistance = tonumber(zoneData.renderDistance) or oldZone.renderDistance or 150.0,
        jobOverrides = validateJobOverrides(zoneData.jobOverrides)
    }

    if zoneData.markerConfig then
        updatedZone.markerConfig = {
            type = tonumber(zoneData.markerConfig.type) or Config.DefaultMarker.type,
            color = {
                r = math.floor(tonumber(zoneData.markerConfig.color.r) or 0),
                g = math.floor(tonumber(zoneData.markerConfig.color.g) or 255),
                b = math.floor(tonumber(zoneData.markerConfig.color.b) or 136),
                a = math.floor(tonumber(zoneData.markerConfig.alpha) or 100)
            },
            height = tonumber(zoneData.markerConfig.height) or Config.DefaultMarker.height or 30.0,
            bobbing = zoneData.markerConfig.bobbing == true,
            pulsing = zoneData.markerConfig.pulsing == true,
            rotating = zoneData.markerConfig.rotating == true,
            colorShift = zoneData.markerConfig.colorShift == true,
            autoLevel = zoneData.markerConfig.autoLevel ~= false,
            pulseSpeed = tonumber(zoneData.markerConfig.pulseSpeed) or Config.DefaultMarker.pulseSpeed,
            bobHeight = tonumber(zoneData.markerConfig.bobHeight) or Config.DefaultMarker.bobHeight,
            rotationSpeed = tonumber(zoneData.markerConfig.rotationSpeed) or Config.DefaultMarker.rotationSpeed
        }

        if zoneData.type == 'circle' then
            updatedZone.markerConfig.height = tonumber(zoneData.markerConfig.height) or Config.DefaultMarker.height
        end

        if zoneData.type == 'polygon' then
            updatedZone.markerConfig.wallColor = updatedZone.markerConfig.color
            updatedZone.markerConfig.groundColor = {
                r = updatedZone.markerConfig.color.r,
                g = updatedZone.markerConfig.color.g,
                b = updatedZone.markerConfig.color.b,
                a = math.floor(updatedZone.markerConfig.color.a * 0.5)
            }
            updatedZone.markerConfig.pulseEffect = zoneData.markerConfig.pulsing
            updatedZone.markerConfig.gradientEffect = Config.PolygonMarker.gradientEffect ~= false
            updatedZone.markerConfig.cornerBeams = Config.PolygonMarker.cornerBeams ~= false
        end
    end

    if zoneData.type == 'polygon' then
        if not zoneData.points or type(zoneData.points) ~= 'table' or #zoneData.points < 3 then
            TriggerClientEvent('f5_safezones:showNotification', src, Translate('polygon_min_points'), 'error')
            if Logging then
                Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - insufficient polygon points', {
                    details = {
                        reason = 'polygon_points'
                    }
                }, 'ZONE')
            end
            return
        end

        local points = {}
        for i, point in ipairs(zoneData.points) do
            local x = tonumber(point.x)
            local y = tonumber(point.y)

            if not x or not y then
                TriggerClientEvent('f5_safezones:showNotification', src,
                    string.format(Translate('invalid_point_coords'), i), 'error')
                if Logging then
                    Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - invalid polygon coordinates', {
                        details = {
                            reason = 'invalid_point',
                            index = i
                        }
                    }, 'ZONE')
                end
                return
            end

            table.insert(points, vector2(x, y))
        end

        updatedZone.points = points
        updatedZone.minZ = tonumber(zoneData.minZ) or oldZone.minZ or -200.0
        updatedZone.maxZ = tonumber(zoneData.maxZ) or oldZone.maxZ or 800.0
        updatedZone.addRoof = zoneData.addRoof == true
        updatedZone.infiniteHeight = zoneData.infiniteHeight == true
    else
        if not zoneData.coords or not zoneData.coords.x or not zoneData.coords.y or not zoneData.coords.z then
            TriggerClientEvent('f5_safezones:showNotification', src, Translate('invalid_circle_coords'), 'error')
            if Logging then
                Logging:LogAdminAction(src, 'zone:update', 'Zone update failed - invalid circle coordinates', {
                    details = {
                        reason = 'invalid_circle_coords'
                    }
                }, 'ZONE')
            end
            return
        end

        updatedZone.coords = {
            x = tonumber(zoneData.coords.x) or 0.0,
            y = tonumber(zoneData.coords.y) or 0.0,
            z = tonumber(zoneData.coords.z) or 0.0
        }

        updatedZone.radius = tonumber(zoneData.radius) or oldZone.radius or 50.0
        updatedZone.height = tonumber(zoneData.height) or oldZone.height or 50.0

        if zoneData.customMinZ or zoneData.customMaxZ then
            updatedZone.minZ = tonumber(zoneData.customMinZ) or (updatedZone.coords.z - 50)
            updatedZone.maxZ = tonumber(zoneData.customMaxZ) or (updatedZone.coords.z + 150)
            updatedZone.infiniteHeight = false
        else
            if zoneData.useGroundHeight then
                updatedZone.minZ = updatedZone.coords.z - 5
                updatedZone.maxZ = updatedZone.coords.z + updatedZone.height
            else
                updatedZone.minZ = updatedZone.coords.z - 50
                updatedZone.maxZ = updatedZone.coords.z + 150
            end
            updatedZone.infiniteHeight = false
        end
    end

    normalizeInvincibilityOption(updatedZone)

    Server.customZones[zoneIndex] = updatedZone

    if zoneData.name ~= zoneData.originalName then
        for playerId, info in pairs(Server.playersInSafezones) do
            if info.zoneName == zoneData.originalName then
                Server.playersInSafezones[playerId].zoneName = zoneData.name
            end
        end
    end

    Zones.SaveCustomZones()

    local playerName = GetPlayerName(src)
    local updatedMarker = updatedZone.markerConfig and Config.MarkerTypes[updatedZone.markerConfig.type] or 'Unknown'
    Log('ADMIN', 'Admin %s (ID %d) updated zone "%s" to "%s" (Type: %s, Marker: %s)', playerName, src,
        zoneData.originalName, updatedZone.name, updatedZone.type, updatedMarker)

    TriggerEvent('f5_safezones:zoneUpdated', {
        admin = src,
        adminName = playerName,
        oldZone = oldZone,
        newZone = updatedZone
    })

    if Logging then
        Logging:LogAdminAction(src, 'zone:update', string.format('Updated zone "%s"', updatedZone.name),
            Logging.AppendZoneContext({
                details = {
                    originalName = zoneData.originalName,
                    updatedAt = updatedZone.updatedAt,
                    marker = updatedMarker
                }
            }, updatedZone), 'ZONE')
    end
end)

RegisterNetEvent('f5_safezones:deleteZone', function(zoneId)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'),
            'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized zone deletion attempt', {
                details = {
                    request = 'delete_zone',
                    zoneId = zoneId
                }
            }, 'SECURITY')
        end
        return
    end

    if not zoneId or type(zoneId) ~= 'string' then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('invalid_zone_id'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:delete', 'Zone deletion failed - invalid identifier', {
                details = {
                    reason = 'invalid_id',
                    zoneId = zoneId
                }
            }, 'ZONE')
        end
        return
    end

    local zoneType, zoneIndex = zoneId:match('(%w+)_(%d+)')
    if zoneType ~= 'custom' then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('cannot_delete_config'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:delete', 'Zone deletion failed - config zone', {
                details = {
                    reason = 'config_zone',
                    zoneId = zoneId
                }
            }, 'ZONE')
        end
        return
    end

    zoneIndex = tonumber(zoneIndex)
    if not zoneIndex or not Server.customZones[zoneIndex] then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_not_found'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:delete', 'Zone deletion failed - zone not found', {
                details = {
                    reason = 'not_found',
                    zoneId = zoneId
                }
            }, 'ZONE')
        end
        return
    end

    local zoneName = Server.customZones[zoneIndex].name
    local zoneData = Server.customZones[zoneIndex]

    local playersInZone = {}
    for playerId, info in pairs(Server.playersInSafezones) do
        if info.zoneName == zoneName then
            table.insert(playersInZone, playerId)
        end
    end

    for _, playerId in ipairs(playersInZone) do
        Server.playersInSafezones[playerId] = nil
        TriggerClientEvent('f5_safezones:showNotification', playerId,
            Translate('zone_deleted_notification'), 'error')
    end

    Server.zoneMarkerStates[zoneName] = nil
    Server.zoneActivationStates[zoneName] = nil

    table.remove(Server.customZones, zoneIndex)

    Zones.SaveCustomZones()
    Zones.SaveZoneStates()

    TriggerClientEvent('f5_safezones:showNotification', src, string.format(Translate('zone_deleted'), zoneName),
        'success')

    local playerName = GetPlayerName(src)
    Log('ADMIN', 'Admin %s (ID %d) deleted zone "%s" affecting %d player(s)', playerName, src, zoneName,
        #playersInZone)

    TriggerEvent('f5_safezones:zoneDeleted', {
        admin = src,
        adminName = playerName,
        zone = zoneData,
        playersAffected = #playersInZone
    })

    if Logging then
        Logging:LogAdminAction(src, 'zone:delete', string.format('Deleted zone "%s"', zoneName),
            Logging.AppendZoneContext({
                details = {
                    playersAffected = #playersInZone
                }
            }, zoneData), 'ZONE')
    end
end)

RegisterNetEvent('f5_safezones:toggleZoneMarker', function(zoneIdentifier)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'),
            'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized marker toggle attempt', {
                details = {
                    request = 'toggle_marker',
                    zoneIdentifier = zoneIdentifier
                }
            }, 'SECURITY')
        end
        return
    end

    local found = false
    local updatedZoneName
    local updatedState
    local updatedZone
    local allZones = Zones.GetAllZones()

    local zoneId = tonumber(zoneIdentifier)

    for _, zone in ipairs(allZones) do
        local match = false
        if zoneId then
            match = (zone.id == zoneId)
        else
            match = (zone.name:lower() == zoneIdentifier:lower())
        end

        if match then
            local currentState = zone.showMarker
            Server.zoneMarkerStates[zone.name] = not currentState

            if zone.isCustom and zone.customIndex then
                Server.customZones[zone.customIndex].showMarker = not currentState
                Zones.SaveCustomZones()
            end

            TriggerClientEvent('f5_safezones:zoneMarkerToggled', -1, zone.name, not currentState)

            found = true
            updatedZoneName = zone.name
            updatedState = not currentState
            updatedZone = zone
            break
        end
    end

    if not found then
        local errMsg = zoneId and string.format(Translate('zone_not_found_id'), zoneId) or string.format(Translate('zone_not_found_name'), zoneIdentifier)
        TriggerClientEvent('f5_safezones:printToConsole', src, {'^1[Safezones]^0 ' .. errMsg})
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_marker', 'Zone marker toggle failed - zone not found', {
                details = {
                    zoneIdentifier = zoneIdentifier
                }
            }, 'ZONE')
        end
        return
    end

    TriggerClientEvent('f5_safezones:printToConsole', src, {
        string.format('^2[Safezones]^0 Marker for zone #%d "%s" is now %s',
            updatedZone.id, updatedZoneName, updatedState and '^2VISIBLE^0' or '^1HIDDEN^0')
    })

    if Logging then
        Logging:LogAdminAction(src, 'zone:toggle_marker', string.format('Toggled marker for "%s"', updatedZoneName or zoneIdentifier),
            Logging.AppendZoneContext({
                details = {
                    newState = updatedState == true
                }
            }, updatedZone), 'ZONE')
    end
end)

RegisterNetEvent('f5_safezones:setZoneActivation', function(zoneName, activate)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized zone activation attempt', {
                details = {
                    request = 'set_activation',
                    zoneName = zoneName,
                    activate = activate
                }
            }, 'SECURITY')
        end
        return
    end

    if not zoneName or type(zoneName) ~= 'string' then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('zone_not_found'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_activation', 'Zone activation failed - invalid name', {
                details = {
                    reason = 'invalid_name'
                }
            }, 'ZONE')
        end
        return
    end

    local allZones = Zones.GetAllZones()
    local targetZone = nil

    for _, zone in ipairs(allZones) do
        if zone.name:lower() == zoneName:lower() then
            targetZone = zone
            break
        end
    end

    if not targetZone then
        TriggerClientEvent('f5_safezones:showNotification', src, string.format(Translate('zone_not_found_name'), zoneName), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_activation', 'Zone activation failed - zone not found', {
                details = {
                    zoneName = zoneName
                }
            }, 'ZONE')
        end
        return
    end

    local desiredState
    if type(activate) == 'boolean' then
        desiredState = activate
    else
        desiredState = not isZoneActive(targetZone.name)
    end

    local currentlyActive = isZoneActive(targetZone.name)
    if desiredState == currentlyActive then
        TriggerClientEvent('f5_safezones:showNotification', src,
            desiredState and string.format(Translate('zone_already_active'), targetZone.name)
            or string.format(Translate('zone_already_inactive'), targetZone.name),
            'primary')
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_activation', 'Zone activation skipped - already in desired state', {
                details = {
                    zoneName = targetZone.name,
                    desiredState = desiredState
                }
            }, 'ZONE')
        end
        return
    end

    Server.zoneActivationStates[targetZone.name] = desiredState
    Zones.SaveZoneStates()

    local playerName = GetPlayerName(src)
    Log('ADMIN', 'Admin %s (ID %d) %s zone "%s"', playerName, src, desiredState and 'activated' or 'deactivated', targetZone.name)

    TriggerClientEvent('f5_safezones:zoneActivationChanged', -1, targetZone.name, desiredState)
    TriggerClientEvent('f5_safezones:updateZones', -1, Zones.GetAllZones())

    if Logging then
        Logging:LogAdminAction(src, 'zone:toggle_activation', string.format('%s zone "%s"', desiredState and 'Activated' or 'Deactivated',
            targetZone.name), Logging.AppendZoneContext({
            details = {
                newState = desiredState
            }
        }, targetZone), 'ZONE')
    end
end)

RegisterNetEvent('f5_safezones:setAllZonesActivation', function(activate)
    local src = source

    if not IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized bulk zone activation attempt', {
                details = {
                    request = 'set_all_activation',
                    activate = activate
                }
            }, 'SECURITY')
        end
        return
    end

    local allZones = Zones.GetAllZones()
    if #allZones == 0 then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('no_zones_defined'), 'error')
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_activation_all', 'Bulk activation failed - no zones defined', nil, 'ZONE')
        end
        return
    end

    local desiredState
    if type(activate) == 'boolean' then
        desiredState = activate
    else
        desiredState = false
        for _, zone in ipairs(allZones) do
            if not isZoneActive(zone.name) then
                desiredState = true
                break
            end
        end
    end

    local changedZones = {}
    for _, zone in ipairs(allZones) do
        if isZoneActive(zone.name) ~= desiredState then
            Server.zoneActivationStates[zone.name] = desiredState
            changedZones[#changedZones + 1] = zone.name
        end
    end

    if #changedZones == 0 then
        TriggerClientEvent('f5_safezones:showNotification', src,
            desiredState and Translate('zones_already_active') or Translate('zones_already_inactive'), 'primary')
        if Logging then
            Logging:LogAdminAction(src, 'zone:toggle_activation_all', 'Bulk activation skipped - already desired state', {
                details = {
                    desiredState = desiredState
                }
            }, 'ZONE')
        end
        return
    end

    Zones.SaveZoneStates()

    local playerName = GetPlayerName(src)
    Log('ADMIN', 'Admin %s (ID %d) set activation state for %d zone(s) to %s', playerName, src, #changedZones,
        desiredState and 'active' or 'inactive')

    TriggerClientEvent('f5_safezones:zonesActivationBulkChanged', -1, desiredState, changedZones)
    TriggerClientEvent('f5_safezones:updateZones', -1, Zones.GetAllZones())

    if Logging then
        Logging:LogAdminAction(src, 'zone:toggle_activation_all', string.format('%s %d zone(s)', desiredState and 'Activated' or 'Deactivated',
            #changedZones), {
            details = {
                affectedZones = changedZones,
                newState = desiredState
            }
        }, 'ZONE')
    end
end)
