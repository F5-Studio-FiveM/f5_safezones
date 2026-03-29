local Safezone = Safezone
local Zones = Safezone.Zones
local UI = Safezone.UI

local nuiOpen = false
local expectingOpen = false
function UI.IsOpen()
    return nuiOpen
end
UI.PendingPolygonPoints = UI.PendingPolygonPoints or nil
UI.PendingCircleData = UI.PendingCircleData or nil

local function push_pending_polygon_points()
    if not UI.PendingPolygonPoints or not nuiOpen then
        return
    end

    SendNUIMessage({
        action = 'polygonCreatorResult',
        points = UI.PendingPolygonPoints
    })

    UI.PendingPolygonPoints = nil
end

local function push_pending_circle_data()
    if not UI.PendingCircleData or not nuiOpen then
        return
    end

    SendNUIMessage({
        action = 'circleCreatorResult',
        center = UI.PendingCircleData.center,
        radius = UI.PendingCircleData.radius
    })

    UI.PendingCircleData = nil
end

if Config.Commands.szcoords and Config.Commands.szcoords.active then
    RegisterCommand(Config.Commands.szcoords.name, function()
        TriggerServerEvent('f5_safezones:checkAdminCoords')
    end, false)
end

local function CopyToClipboard(text)
    SendNUIMessage({
        action = 'copyToClipboard',
        text = text
    })
end

RegisterNetEvent('f5_safezones:receiveAdminCoords', function(hasPermission)
    if not hasPermission then
        Safezone.ShowNotification(Translate('access_denied'), 'error')
        return
    end

    Safezone.UpdatePlayerCache()
    local coords = Safezone.Player.coords
    local heading = GetEntityHeading(Safezone.Player.ped)

    local coordsText = string.format(Translate('coords_display'), coords.x, coords.y, coords.z, heading)
    local coordsLua = string.format(Translate('coords_lua'), coords.x, coords.y, coords.z, heading)

    Safezone.ShowNotification('~g~' .. Translate('coords_current') .. '~n~~w~' .. coordsText)
    CopyToClipboard(coordsLua)
    Safezone.ShowNotification(Translate('coords_copied'))

    local englishDisplay = string.format('Position: %.2f, %.2f, %.2f | Heading: %.2f', coords.x, coords.y, coords.z, heading)
    local englishLua = string.format('Lua format: vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, heading)
    local englishJson = string.format('JSON format: {"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}', coords.x, coords.y, coords.z, heading)

    LogBlock('UI', 'Coordinate export', {
        englishDisplay,
        englishLua,
        englishJson
    })
end)

if Config.Commands.szdebug and Config.Commands.szdebug.active then
    RegisterCommand(Config.Commands.szdebug.name, function(_, args)
        local arg = args[1]
        local mode = nil
        local zoneId = nil

        if arg then
            local numArg = tonumber(arg)
            if numArg then
                zoneId = math.floor(numArg)
                mode = 'single'
            else
                mode = arg:lower()
            end
        end

        TriggerServerEvent('f5_safezones:checkDebugPermission', mode, nil, zoneId)
    end, false)
end

RegisterNetEvent('f5_safezones:toggleDebug', function(allowed, mode, forceEnable, zoneId)
    local currentMode = Safezone.Debug.mode or 'all'
    local normalizedMode = currentMode

    if type(mode) == 'string' then
        local lowerMode = mode:lower()
        if lowerMode == 'all' or lowerMode == 'inactive' or lowerMode == 'active' or lowerMode == 'single' then
            normalizedMode = lowerMode
        end
    end

    if not allowed then
        Safezone.ShowNotification(Translate('access_denied'), 'error')
        SendNUIMessage({
            action = 'debugStateChanged',
            enabled = Safezone.Debug.enabled,
            mode = Safezone.Debug.mode or 'all',
            states = Safezone.Debug.zoneStates,
            localeKey = 'notifications.debug_permission_denied',
            notificationType = 'error'
        })
        return
    end

    if normalizedMode == 'single' and type(zoneId) == 'number' then
        if Safezone.Debug.enabled and Safezone.Debug.mode == 'single' and Safezone.Debug.singleZoneId == zoneId then
            Safezone.Debug.enabled = false
            Safezone.Debug.mode = 'all'
            Safezone.Debug.singleZoneId = nil
            Config.DebugOptions.enabled = false
            Safezone.Debug.zoneStates = {}

            Zones.ForceMarkerUpdate()

            SendNUIMessage({
                action = 'debugStateChanged',
                enabled = false,
                mode = 'all',
                singleZoneId = nil,
                states = {},
                localeKey = 'notifications.debug_disabled',
                notificationType = 'primary'
            })
            return
        end

        local zoneExists = false
        local zoneName = nil
        local allZones = Zones.GetAllZones and Zones.GetAllZones() or {}

        for _, zone in pairs(allZones) do
            if zone.id == zoneId then
                zoneExists = true
                zoneName = zone.name
                break
            end
        end

        if not zoneExists then
            Safezone.ShowNotification(string.format(Translate('zone_not_found_id'), zoneId), 'error')
            return
        end

        Safezone.Debug.enabled = true
        Safezone.Debug.mode = 'single'
        Safezone.Debug.singleZoneId = zoneId
        Config.DebugOptions.enabled = true
        Safezone.Debug.zoneStates = {}

        Zones.ForceMarkerUpdate()

        SendNUIMessage({
            action = 'debugStateChanged',
            enabled = true,
            mode = 'single',
            singleZoneId = zoneId,
            states = Safezone.Debug.zoneStates,
            localeKey = 'notifications.debug_mode_single',
            notificationType = 'success'
        })
        return
    end

    local newState
    if type(forceEnable) == 'boolean' then
        newState = forceEnable
    else
        newState = not Safezone.Debug.enabled
    end

    Safezone.Debug.enabled = newState
    Config.DebugOptions.enabled = Safezone.Debug.enabled
    Safezone.Debug.zoneStates = {}
    Safezone.Debug.singleZoneId = nil

    if Safezone.Debug.enabled then
        Safezone.Debug.mode = normalizedMode or 'all'
    else
        Safezone.Debug.mode = Safezone.Debug.mode or 'all'
    end

    local messageKey
    if Safezone.Debug.enabled then
        local activeMode = Safezone.Debug.mode or 'all'
        if activeMode == 'inactive' then
            messageKey = 'debug_mode_inactive'
        elseif activeMode == 'active' then
            messageKey = 'debug_mode_active'
        else
            messageKey = 'debug_mode_all'
        end
    else
        messageKey = 'debug_disabled'
    end

    if not nuiOpen then
        Safezone.ShowNotification(Translate(messageKey), Safezone.Debug.enabled and 'success' or 'primary')
    end
    Zones.ForceMarkerUpdate()

    local uiLocaleKey
    if Safezone.Debug.enabled then
        if Safezone.Debug.mode == 'inactive' then
            uiLocaleKey = 'notifications.debug_mode_inactive'
        elseif Safezone.Debug.mode == 'active' then
            uiLocaleKey = 'notifications.debug_mode_active'
        else
            uiLocaleKey = 'notifications.debug_mode_all'
        end
    else
        uiLocaleKey = 'notifications.debug_mode_disabled'
    end

    SendNUIMessage({
        action = 'debugStateChanged',
        enabled = Safezone.Debug.enabled,
        mode = Safezone.Debug.mode or 'all',
        singleZoneId = Safezone.Debug.singleZoneId,
        states = Safezone.Debug.zoneStates,
        localeKey = uiLocaleKey,
        notificationType = Safezone.Debug.enabled and 'success' or 'primary'
    })
end)

if Config.Commands.szadmin and Config.Commands.szadmin.active then
    RegisterCommand(Config.Commands.szadmin.name, function()
        expectingOpen = true
        TriggerServerEvent('f5_safezones:requestAdminData', 'initial')
    end, false)
end

RegisterNetEvent('f5_safezones:receiveAdminData', function(zones, players, logs, logMetadata)
    if nuiOpen then
        SendNUIMessage({
            action = 'updateData',
            zones = zones,
            players = players,
            logs = logs,
            logMeta = logMetadata,
            debug = {
                enabled = Safezone.Debug.enabled,
                mode = Safezone.Debug.mode or 'all',
                singleZoneId = Safezone.Debug.singleZoneId,
                states = Safezone.Debug.zoneStates
            }
        })
        push_pending_polygon_points()
        push_pending_circle_data()
    elseif expectingOpen then
        expectingOpen = false
        UI.OpenAdminPanel(zones, players, logs, logMetadata)
    end
end)

function UI.OpenAdminPanel(zones, players, logs, logMetadata)
    if nuiOpen then
        return
    end

    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPanel',
        zones = zones,
        players = players,
        logs = logs,
        logMeta = logMetadata,
        debug = {
            enabled = Safezone.Debug.enabled,
            mode = Safezone.Debug.mode or 'all',
            singleZoneId = Safezone.Debug.singleZoneId,
            states = Safezone.Debug.zoneStates
        }
    })
    UI.StartAdminPanelUpdates()
    push_pending_polygon_points()
    push_pending_circle_data()
end

function UI.CloseAdminPanel()
    if not nuiOpen then
        return
    end

    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closePanel'
    })
    TriggerServerEvent('f5_safezones:adminPanelClosed')
end

RegisterNUICallback('closePanel', function(_, cb)
    UI.CloseAdminPanel()
    cb('ok')
end)

RegisterNUICallback('setCursor', function(data, cb)
    if not nuiOpen then
        cb('ok')
        return
    end
    SetNuiFocus(data.cursor, data.cursor)
    cb('ok')
end)

RegisterNUICallback('teleportToZone', function(data, cb)
    local coords = data.coords
    Safezone.UpdatePlayerCache()
    SetEntityCoords(Safezone.Player.ped, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
    cb('ok')
end)

RegisterNUICallback('manualRefresh', function(_, cb)
    TriggerServerEvent('f5_safezones:requestAdminData', 'manual')
    cb('ok')
end)

RegisterNUICallback('startPolygonCreator', function(data, cb)
    if not Safezone.ZoneCreator or not Safezone.ZoneCreator.StartFromNui then
        cb({ ok = false })
        return
    end

    if Safezone.ZoneCreator.IsActive and Safezone.ZoneCreator.IsActive() then
        cb({ ok = false })
        return
    end

    if Safezone.CircleCreator and Safezone.CircleCreator.IsActive and Safezone.CircleCreator.IsActive() then
        cb({ ok = false })
        return
    end

    if nuiOpen then
        UI.CloseAdminPanel()
    end

    Safezone.ZoneCreator.StartFromNui(data.zoneSettings, data.existingPoints, data.teleportCoords)
    cb({ ok = true })
end)

RegisterNUICallback('startCircleCreator', function(data, cb)
    if not Safezone.CircleCreator or not Safezone.CircleCreator.StartFromNui then
        cb({ ok = false })
        return
    end

    if Safezone.CircleCreator.IsActive and Safezone.CircleCreator.IsActive() then
        cb({ ok = false })
        return
    end

    if Safezone.ZoneCreator and Safezone.ZoneCreator.IsActive and Safezone.ZoneCreator.IsActive() then
        cb({ ok = false })
        return
    end

    if nuiOpen then
        UI.CloseAdminPanel()
    end

    Safezone.CircleCreator.StartFromNui(data.zoneSettings, data.existingCenter, data.existingRadius, data.teleportCoords)
    cb({ ok = true })
end)

RegisterNUICallback('createZone', function(data, cb)
    TriggerServerEvent('f5_safezones:createZone', data.zoneData)
    cb('ok')
    SetTimeout(2000, function()
        if nuiOpen then
            TriggerServerEvent('f5_safezones:requestAdminData', 'refresh')
        end
    end)
end)

RegisterNUICallback('updateZone', function(data, cb)
    TriggerServerEvent('f5_safezones:updateZone', data.zoneData)
    cb('ok')
    SetTimeout(2000, function()
        if nuiOpen then
            TriggerServerEvent('f5_safezones:requestAdminData', 'refresh')
        end
    end)
end)

RegisterNUICallback('deleteZone', function(data, cb)
    if data.zoneId then
        TriggerServerEvent('f5_safezones:deleteZone', data.zoneId)
    end
    cb('ok')
end)

RegisterNUICallback('toggleZoneMarker', function(data, cb)
    TriggerServerEvent('f5_safezones:toggleZoneMarker', data.zoneName)
    cb('ok')
end)

RegisterNUICallback('toggleZoneActivation', function(data, cb)
    TriggerServerEvent('f5_safezones:setZoneActivation', data.zoneName, data.activate)
    cb('ok')
end)

RegisterNUICallback('toggleAllZonesActivation', function(data, cb)
    TriggerServerEvent('f5_safezones:setAllZonesActivation', data.activate)
    cb('ok')
end)

RegisterNUICallback('toggleDebugZones', function(data, cb)
    local requestedMode = 'all'
    if data and type(data.mode) == 'string' then
        local lowerMode = data.mode:lower()
        if lowerMode == 'inactive' or lowerMode == 'active' or lowerMode == 'all' then
            requestedMode = lowerMode
        end
    end

    local enable
    if data and type(data.enable) == 'boolean' then
        enable = data.enable
    end

    TriggerServerEvent('f5_safezones:checkDebugPermission', requestedMode, enable)
    cb('ok')
end)

RegisterNUICallback('setZoneDebugState', function(data, cb)
    local zoneName = data and data.zoneName
    if type(zoneName) ~= 'string' or zoneName == '' then
        cb('ok')
        return
    end

    Safezone.Debug.zoneStates = Safezone.Debug.zoneStates or {}

    local requestedState = data and data.state
    if type(requestedState) == 'boolean' then
        Safezone.Debug.zoneStates[zoneName] = requestedState
    else
        Safezone.Debug.zoneStates[zoneName] = nil
        requestedState = nil
    end

    Zones.ForceMarkerUpdate()

    local messageKey
    local notifType = 'primary'
    if requestedState == nil then
        messageKey = 'debug_zone_default'
    elseif requestedState then
        messageKey = 'debug_zone_enabled'
        notifType = 'success'
    else
        messageKey = 'debug_zone_disabled'
    end

    SendNUIMessage({
        action = 'debugStateChanged',
        enabled = Safezone.Debug.enabled,
        mode = Safezone.Debug.mode or 'all',
        singleZoneId = Safezone.Debug.singleZoneId,
        states = Safezone.Debug.zoneStates
    })

    cb('ok')
end)

RegisterNUICallback('getPlayerCoordsForPoint', function(data, cb)
    Safezone.UpdatePlayerCache()
    SendNUIMessage({
        action = 'receivePlayerCoordsForPoint',
        coords = Safezone.Player.coords,
        pointIndex = data.pointIndex
    })
    cb('ok')
end)

RegisterNUICallback('getPlayerCoords', function(_, cb)
    Safezone.UpdatePlayerCache()
    SendNUIMessage({
        action = 'receivePlayerCoords',
        coords = {
            x = Safezone.Player.coords.x,
            y = Safezone.Player.coords.y,
            z = Safezone.Player.coords.z
        }
    })
    cb('ok')
end)

RegisterNetEvent('f5_safezones:receivePlayerCoords', function(coords)
    SendNUIMessage({
        action = 'receivePlayerCoords',
        coords = coords
    })
end)

RegisterNetEvent('f5_safezones:polygonCreatorFinished', function(points)
    if type(points) ~= 'table' or #points < 3 then
        Safezone.ShowNotification(Translate('polygon_creator_invalid'), 'error')
        expectingOpen = true
        TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
        return
    end

    UI.PendingPolygonPoints = points
    Safezone.ShowNotification(Translate('polygon_creator_finished'), 'success')
    expectingOpen = true
    TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
end)

RegisterNetEvent('f5_safezones:polygonCreatorCancelled', function()
    Safezone.ShowNotification(Translate('polygon_creator_cancelled'), 'primary')
    expectingOpen = true
    TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
end)

RegisterNetEvent('f5_safezones:circleCreatorFinished', function(data)
    if type(data) ~= 'table' or not data.center or not data.radius then
        Safezone.ShowNotification(Translate('circle_creator_invalid'), 'error')
        expectingOpen = true
        TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
        return
    end

    UI.PendingCircleData = {
        center = data.center,
        radius = data.radius
    }
    Safezone.ShowNotification(Translate('circle_creator_finished'), 'success')
    expectingOpen = true
    TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
end)

RegisterNetEvent('f5_safezones:circleCreatorCancelled', function()
    Safezone.ShowNotification(Translate('circle_creator_cancelled'), 'primary')
    expectingOpen = true
    TriggerServerEvent('f5_safezones:requestAdminData', 'creator')
end)

CreateThread(function()
    while true do
        if nuiOpen and IsControlJustPressed(0, 322) then
            UI.CloseAdminPanel()
        end
        Wait(100)
    end
end)

function UI.StartAdminPanelUpdates()
    CreateThread(function()
        while nuiOpen do
            TriggerServerEvent('f5_safezones:requestAdminData', 'refresh')
            Wait(5000)
        end
    end)
end
