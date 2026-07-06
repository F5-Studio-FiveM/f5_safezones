SafezoneServer = SafezoneServer or {}
local Server = SafezoneServer
Server.playersInSafezones = Server.playersInSafezones or {}
Server.zoneMarkerStates = Server.zoneMarkerStates or {}
Server.zoneActivationStates = Server.zoneActivationStates or {}
Server.customZones = Server.customZones or {}
Server.zoneSaveTimer = Server.zoneSaveTimer or nil
Server.Paths = Server.Paths or {}
Server.Paths.zonesFile = Server.Paths.zonesFile or (GetResourcePath(GetCurrentResourceName()) .. '/data/zones.json')
Server.Paths.zoneStateFile = Server.Paths.zoneStateFile or (GetResourcePath(GetCurrentResourceName()) .. '/data/zone_states.json')

local function waitForModuleReady(checkFn)
    while not checkFn() do
        Wait(0)
    end
end

CreateThread(function()
    waitForModuleReady(function()
        return Server.Zones and Server.Zones.LoadCustomZones
    end)

    Framework.WaitForServerReady()

    Wait(1000)
    Server.Zones.LoadZoneStates()
    Server.Zones.LoadCustomZones()
end)

CreateThread(function()
    waitForModuleReady(function()
        return Server.Zones and Server.Zones.GetAllZones
    end)

    Wait(2000)

    local configZoneCount = #Config.Safezones
    local customZoneCount = #Server.customZones
    local totalZones = configZoneCount + customZoneCount

    local circleCount = 0
    local polygonCount = 0
    local markerTypes = {}

    for _, zone in ipairs(Config.Safezones) do
        if zone.type == 'polygon' then
            polygonCount = polygonCount + 1
        else
            circleCount = circleCount + 1
        end

        if zone.markerConfig and zone.markerConfig.type then
            markerTypes[zone.markerConfig.type] = (markerTypes[zone.markerConfig.type] or 0) + 1
        end
    end

    for _, zone in ipairs(Server.customZones) do
        if zone.type == 'polygon' then
            polygonCount = polygonCount + 1
        else
            circleCount = circleCount + 1
        end

        if zone.markerConfig and zone.markerConfig.type then
            markerTypes[zone.markerConfig.type] = (markerTypes[zone.markerConfig.type] or 0) + 1
        end
    end

    Log('INIT', Translate('startup_summary'), configZoneCount, customZoneCount, totalZones, circleCount, polygonCount)

    if next(markerTypes) then
        local markerLines = {}
        for typeId, count in pairs(markerTypes) do
            markerLines[#markerLines + 1] = string.format('Type %s (%d)', Config.MarkerTypes[typeId] or 'Unknown', count)
        end
        table.sort(markerLines)
        Log('DATA', Translate('startup_marker_types'), table.concat(markerLines, ', '))
    else
        Log('DATA', Translate('startup_marker_types_none'))
    end

    local zonesFileName = Server.Paths.zonesFile and Server.Paths.zonesFile:match('([^/\\]+)$') or 'zones.json'
    Log('SUCCESS', Translate('startup_custom_loaded'), customZoneCount, zonesFileName)

    Log('INIT', 'Safezone banner completed')
end)
