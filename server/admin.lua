local Server = SafezoneServer
Server.Admin = Server.Admin or {}
local Admin = Server.Admin
local Logging = Server.Logging

Admin.panelSessions = Admin.panelSessions or {}

function Admin.IsPlayerAdmin(playerId)
    local acePermissions = Config.AdminPermissions or {
        'command', 'command.tx', 'txadmin', 'admin', 'moderator',
        'group.admin', 'group.moderator', 'safezones.admin', 'f5_safezones.admin'
    }

    for _, permission in ipairs(acePermissions) do
        if IsPlayerAceAllowed(playerId, permission) then
            return true
        end
    end

    if Framework.IsAdmin and Framework.IsAdmin(playerId) then
        return true
    end

    return false
end

function IsPlayerAdmin(playerId)
    return Admin.IsPlayerAdmin(playerId)
end

RegisterNetEvent('f5_safezones:checkDebugPermission', function(mode, enable, zoneId)
    local src = source

    local normalizedMode = nil
    local normalizedZoneId = nil

    if type(mode) == 'string' then
        local lowerMode = mode:lower()
        if lowerMode == 'all' or lowerMode == 'inactive' or lowerMode == 'active' or lowerMode == 'single' then
            normalizedMode = lowerMode
        end
    end

    if normalizedMode == 'single' and type(zoneId) == 'number' then
        normalizedZoneId = math.floor(zoneId)
    end

    local normalizedEnable = nil
    if type(enable) == 'boolean' then
        normalizedEnable = enable
    end

    if Admin.IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:toggleDebug', src, true, normalizedMode, normalizedEnable, normalizedZoneId)

        local playerName = GetPlayerName(src)
        local modeStr = normalizedMode or 'toggle'
        if normalizedMode == 'single' and normalizedZoneId then
            modeStr = 'single (ID: ' .. normalizedZoneId .. ')'
        end
        Log('ADMIN', 'Granted debug mode toggle access to %s (ID %d) | Mode: %s | Force: %s', playerName, src,
            modeStr, tostring(normalizedEnable))
    else
        TriggerClientEvent('f5_safezones:toggleDebug', src, false, normalizedMode, normalizedEnable, normalizedZoneId)
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Unauthorized debug toggle attempt', {
                details = {
                    mode = normalizedMode or 'toggle',
                    zoneId = normalizedZoneId
                }
            }, 'SECURITY')
        end
    end
end)

RegisterNetEvent('f5_safezones:checkAdminCoords', function()
    local src = source

    local hasPermission = Admin.IsPlayerAdmin(src)

    TriggerClientEvent('f5_safezones:receiveAdminCoords', src, hasPermission)

    local playerName = GetPlayerName(src) or Translate('unknown')
    if hasPermission then
        local playerPed = GetPlayerPed(src)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        heading = heading + 0.0

        Log('ADMIN', '%s (ID %d) requested coordinate export', playerName, src)
        Log('DATA', 'Position: %.2f, %.2f, %.2f | Heading: %.2f', coords.x, coords.y, coords.z, heading)
        Log('DATA', 'Lua format: vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading)
        Log('DATA', 'JSON format: {"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}', coords.x, coords.y, coords.z, heading)
    else
        Log('ADMIN', 'Denied coordinate export for %s (ID %d)', playerName, src)
        if Logging then
            Logging:LogAdminAction(src, 'security:denied', 'Denied coordinate export request', {
                details = {
                    playerName = playerName
                }
            }, 'SECURITY')
        end
    end
end)

RegisterNetEvent('f5_safezones:requestAdminData', function(requestType)
    local src = source
    local playerKey = tonumber(src) or src
    local normalizedRequest = type(requestType) == 'string' and requestType:lower() or nil

    if not Admin.IsPlayerAdmin(src) then
        TriggerClientEvent('f5_safezones:showNotification', src, Translate('access_denied'),
            'error')
        if Logging then
            Logging:LogAdminAction(playerKey, 'security:denied', 'Rejected admin panel data request', {
                details = {
                    request = 'admin_data'
                }
            }, 'SECURITY')
        end
        return
    end

    local zonesData = Server.Zones.GetAllZones()

    local playersData = {}
    for playerId, info in pairs(Server.playersInSafezones) do
        if GetPlayerName(playerId) then
            table.insert(playersData, {
                playerId = playerId,
                playerName = info.playerName or GetPlayerName(playerId),
                zoneName = info.zoneName,
                enteredAt = info.enteredAt
            })
        else
            Server.playersInSafezones[playerId] = nil
        end
    end

    local logs, metadata = {}, {}
    if Logging then
        logs, metadata = Logging.GetEntries()

        if normalizedRequest == 'initial' then
            local now = os.time()
            Admin.panelSessions[playerKey] = {
                isOpen = true,
                lastOpen = now
            }
        elseif normalizedRequest == 'refresh' then
            local session = Admin.panelSessions[playerKey]
            if session then
                session.lastRefresh = os.time()
            end
        end
    end

    TriggerClientEvent('f5_safezones:receiveAdminData', src, zonesData, playersData, logs, metadata)
end)

RegisterNetEvent('f5_safezones:adminPanelClosed', function()
    local src = source
    local playerKey = tonumber(src) or src
    Admin.panelSessions[playerKey] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    local playerKey = tonumber(src) or src
    Admin.panelSessions[playerKey] = nil
end)

if Config.Commands.listsafezones and Config.Commands.listsafezones.active then
    RegisterCommand(Config.Commands.listsafezones.name, function(source, args, rawCommand)
        local src = source
        local filter = args[1] and args[1]:lower() or 'all'

        if filter ~= 'all' and filter ~= 'config' and filter ~= 'custom' then
            if src == 0 then
                print('^1[Safezones]^0 Invalid filter. Use: all, config, custom')
            else
                TriggerClientEvent('f5_safezones:printToConsole', src, {
                    '^1[Safezones]^0 Invalid filter. Use: all, config, custom'
                })
            end
            return
        end

        local allZones = Server.Zones.GetAllZones()
        local filteredZones = {}

        for _, zone in ipairs(allZones) do
            if filter == 'all' then
                filteredZones[#filteredZones + 1] = zone
            elseif filter == 'config' and not zone.isCustom then
                filteredZones[#filteredZones + 1] = zone
            elseif filter == 'custom' and zone.isCustom then
                filteredZones[#filteredZones + 1] = zone
            end
        end

        local playerTotal = 0
        for _ in pairs(Server.playersInSafezones) do
            playerTotal = playerTotal + 1
        end

        local lines = {}
        lines[#lines + 1] = '^2=== SAFEZONE LIST (' .. filter:upper() .. ') ===^0'
        lines[#lines + 1] = string.format('^3Total:^0 %d zones (Config: %d | Custom: %d) | ^3Players in zones:^0 %d',
            #allZones, #Config.Safezones, #Server.customZones, playerTotal)
        lines[#lines + 1] = ''

        for i, zone in ipairs(filteredZones) do
            local playerCount = 0
            local playersInZone = {}

            for playerId, info in pairs(Server.playersInSafezones) do
                if info.zoneName == zone.name then
                    playerCount = playerCount + 1
                    playersInZone[#playersInZone + 1] = {
                        id = playerId,
                        name = info.playerName or GetPlayerName(playerId) or 'Unknown'
                    }
                end
            end

            local zoneTag = zone.isCustom and '^5[Custom]^0' or '^6[Config]^0'
            local activeTag = zone.isActive and '^2[Active]^0' or '^1[Inactive]^0'
            local zoneId = zone.id or '?'
            lines[#lines + 1] = string.format('^3#%s^0 %s %s %s', zoneId, zone.name, zoneTag, activeTag)

            if zone.type == 'circle' then
                local coords = zone.coords or {x = 0, y = 0, z = 0}
                lines[#lines + 1] = string.format('    ^7Type:^0 Circle | ^7Radius:^0 %.1fm | ^7Height:^0 %.1fm',
                    zone.radius or 0, (zone.maxZ or 0) - (zone.minZ or 0))
                lines[#lines + 1] = string.format('    ^7Coords:^0 %.2f, %.2f, %.2f', coords.x, coords.y, coords.z)
            elseif zone.type == 'polygon' then
                lines[#lines + 1] = string.format('    ^7Type:^0 Polygon | ^7Points:^0 %d | ^7Height:^0 %.1fm',
                    zone.points and #zone.points or 0, (zone.maxZ or 0) - (zone.minZ or 0))
            end

            local markerName = 'Default'
            if zone.markerConfig and zone.markerConfig.type then
                markerName = Config.MarkerTypes[zone.markerConfig.type] or 'Unknown'
            end
            lines[#lines + 1] = string.format('    ^7Marker:^0 %s | ^7Visible:^0 %s | ^7Render Dist:^0 %sm',
                markerName,
                zone.showMarker ~= false and 'Yes' or 'No',
                tostring(zone.renderDistance or 150))

            if playerCount > 0 then
                lines[#lines + 1] = string.format('    ^7Players inside (%d):^0', playerCount)
                for _, player in ipairs(playersInZone) do
                    lines[#lines + 1] = string.format('      - %s (ID: %d)', player.name, player.id)
                end
            end

            lines[#lines + 1] = ''
        end

        if #filteredZones == 0 then
            lines[#lines + 1] = '^1No zones found with filter: ' .. filter .. '^0'
        end

        lines[#lines + 1] = '^2=== END OF LIST ===^0'

        if src == 0 then
            for _, line in ipairs(lines) do
                print(line)
            end
        else
            if not Admin.IsPlayerAdmin(src) then
                TriggerClientEvent('f5_safezones:printToConsole', src, {'^1[Safezones]^0 Access denied.'})
                return
            end
            TriggerClientEvent('f5_safezones:printToConsole', src, lines)
        end
    end, true)
end
