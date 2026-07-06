local Safezone = Safezone
local Zones = Safezone.Zones

local currentZones = {}
local inactiveZones = {}
local processedZones = {}
local processedInactiveZones = {}
local zoneCount = 0
local lowestPointCache = {}
local markersToRender = {}
local debugMarkers = {}
local lastMarkerUpdate = 0
local MARKER_UPDATE_INTERVAL = Config.Performance.updateIntervals.markerList
local DEFAULT_RENDER_DISTANCE = (Config.DefaultMarker and Config.DefaultMarker.renderDistance) or 150.0
local processedZoneLookup = {}

local function IsPointInPolygon(point, polygon, bounds)
    if bounds then
        if point.x < bounds.minX or point.x > bounds.maxX or point.y < bounds.minY or point.y > bounds.maxY then
            return false
        end
    end

    local x, y = point.x, point.y
    local inside = false
    local p1x, p1y = polygon[1].x, polygon[1].y
    local n = #polygon

    for i = 1, n do
        local p2x, p2y = polygon[i % n + 1].x, polygon[i % n + 1].y

        if ((p1y > y) ~= (p2y > y)) and (x < (p2x - p1x) * (y - p1y) / (p2y - p1y) + p1x) then
            inside = not inside
        end

        p1x, p1y = p2x, p2y
    end

    return inside
end

local function CalculatePolygonBounds(points)
    local minX, maxX = points[1].x, points[1].x
    local minY, maxY = points[1].y, points[1].y

    for i = 2, #points do
        local point = points[i]
        minX = math.min(minX, point.x)
        maxX = math.max(maxX, point.x)
        minY = math.min(minY, point.y)
        maxY = math.max(maxY, point.y)
    end

    return {
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
        centerX = (minX + maxX) / 2,
        centerY = (minY + maxY) / 2
    }
end

function Zones.GetDistanceSquared(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return dx * dx + dy * dy + dz * dz
end

local function PointInTriangle(px, py, ax, ay, bx, by, cx, cy)
    local d1 = (px - cx) * (ay - cy) - (ax - cx) * (py - cy)
    local d2 = (px - ax) * (by - ay) - (bx - ax) * (py - ay)
    local d3 = (px - bx) * (cy - by) - (cx - bx) * (py - by)
    return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))
end

local triangulationCache = {}

local function TriangulatePolygon(points)
    local keyParts = {}
    for i, p in ipairs(points) do
        keyParts[i] = string.format('%.2f,%.2f', p.x, p.y)
    end
    local cacheKey = table.concat(keyParts, '_')
    if triangulationCache[cacheKey] then
        return triangulationCache[cacheKey]
    end

    local n = #points
    if n < 3 then return {} end

    local indices = {}
    for i = 1, n do indices[i] = i end

    local area = 0
    for i = 1, n do
        local j = i % n + 1
        area = area + (points[indices[i]].x * points[indices[j]].y - points[indices[j]].x * points[indices[i]].y)
    end
    if area > 0 then
        local rev = {}
        for i = n, 1, -1 do rev[n - i + 1] = indices[i] end
        indices = rev
    end

    local triangles = {}
    local remaining = n
    local curr = 1
    local attempts = 0

    while remaining > 3 do
        if attempts > remaining * 2 then break end

        local prev = ((curr - 2) % remaining) + 1
        local ci = ((curr - 1) % remaining) + 1
        local next = (curr % remaining) + 1

        local a = points[indices[prev]]
        local b = points[indices[ci]]
        local c = points[indices[next]]

        local cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

        if cross < 0 then
            local is_ear = true
            for i = 1, remaining do
                if i ~= prev and i ~= ci and i ~= next then
                    if PointInTriangle(points[indices[i]].x, points[indices[i]].y, a.x, a.y, b.x, b.y, c.x, c.y) then
                        is_ear = false
                        break
                    end
                end
            end

            if is_ear then
                triangles[#triangles + 1] = { indices[prev], indices[ci], indices[next] }
                table.remove(indices, ci)
                remaining = remaining - 1
                attempts = 0
                if ci > remaining then curr = 1 else curr = ci end
            else
                curr = curr + 1
                attempts = attempts + 1
            end
        else
            curr = curr + 1
            attempts = attempts + 1
        end

        if curr > remaining then curr = 1 end
    end

    if remaining == 3 then
        triangles[#triangles + 1] = { indices[1], indices[2], indices[3] }
    end

    triangulationCache[cacheKey] = triangles
    return triangles
end

local function GetLowestPointInCircle(coords, radius)
    local cacheKey = string.format('circle_%.2f_%.2f_%.0f', coords.x, coords.y, radius)
    local cacheEntry = lowestPointCache[cacheKey]

    if cacheEntry and (GetGameTimer() - cacheEntry.timestamp < Safezone.Constants.cacheTimeout) then
        return cacheEntry.z
    end

    local lowestZ = coords.z
    local radiusStep = radius / 3

    for r = 0, radius, radiusStep do
        local circumferencePoints = r == 0 and 1 or math.floor(2 * math.pi * r / 2)

        for i = 0, circumferencePoints - 1 do
            local angle = (2 * math.pi * i) / circumferencePoints
            local x = coords.x + (r * math.cos(angle))
            local y = coords.y + (r * math.sin(angle))

            local retval, groundZ = GetGroundZFor_3dCoord(x, y, coords.z + 100.0, false)
            if retval and groundZ < lowestZ then
                lowestZ = groundZ
            end
        end
    end

    lowestPointCache[cacheKey] = {
        z = lowestZ,
        timestamp = GetGameTimer()
    }

    return lowestZ
end

local function GetLowestPointInPolygon(points, minZ, maxZ)
    local keyParts = {}
    for i, point in ipairs(points) do
        keyParts[i] = string.format('%.2f,%.2f', point.x, point.y)
    end
    local cacheKey = 'polygon_' .. table.concat(keyParts, '_')
    local cacheEntry = lowestPointCache[cacheKey]

    if cacheEntry and (GetGameTimer() - cacheEntry.timestamp < Safezone.Constants.cacheTimeout) then
        return cacheEntry.z
    end

    local lowestZ = maxZ

    local minX, maxX = points[1].x, points[1].x
    local minY, maxY = points[1].y, points[1].y

    for _, point in ipairs(points) do
        minX = math.min(minX, point.x)
        maxX = math.max(maxX, point.x)
        minY = math.min(minY, point.y)
        maxY = math.max(maxY, point.y)
    end

    local width = maxX - minX
    local height = maxY - minY
    local area = width * height
    local stepSize = math.max(2.0, math.min(10.0, math.sqrt(area) / 20))

    local x = minX
    while x <= maxX do
        local y = minY
        while y <= maxY do
            if IsPointInPolygon(vector2(x, y), points) then
                local retval, groundZ = GetGroundZFor_3dCoord(x, y, maxZ + 100.0, false)
                if retval and groundZ < lowestZ then
                    lowestZ = groundZ
                end
            end
            y = y + stepSize
        end
        x = x + stepSize
    end

    for _, point in ipairs(points) do
        local retval, groundZ = GetGroundZFor_3dCoord(point.x, point.y, maxZ + 100.0, false)
        if retval and groundZ < lowestZ then
            lowestZ = groundZ
        end
    end

    lowestPointCache[cacheKey] = {
        z = lowestZ,
        timestamp = GetGameTimer()
    }

    return lowestZ
end

local function BuildMarkerConfig(markerConfig)
    local config = markerConfig or {}

    return {
        type = config.type or (Config.DefaultMarker and Config.DefaultMarker.type) or 1,
        color = config.color or (Config.DefaultMarker and Config.DefaultMarker.color) or { r = 0, g = 255, b = 0, a = 100 },
        scale = config.scale or (Config.DefaultMarker and Config.DefaultMarker.scale),
        height = config.height or (Config.DefaultMarker and Config.DefaultMarker.height) or 30.0,
        bobbing = config.bobbing or (Config.DefaultMarker and Config.DefaultMarker.bobbing),
        pulsing = config.pulsing or (Config.DefaultMarker and Config.DefaultMarker.pulsing),
        rotating = config.rotating or (Config.DefaultMarker and Config.DefaultMarker.rotating),
        colorShift = config.colorShift or (Config.DefaultMarker and Config.DefaultMarker.colorShift),
        autoLevel = config.autoLevel ~= false,
        pulseSpeed = config.pulseSpeed or (Config.DefaultMarker and Config.DefaultMarker.pulseSpeed),
        bobHeight = config.bobHeight or (Config.DefaultMarker and Config.DefaultMarker.bobHeight),
        rotationSpeed = config.rotationSpeed or (Config.DefaultMarker and Config.DefaultMarker.rotationSpeed),
        wallColor = config.wallColor or (Config.PolygonMarker and Config.PolygonMarker.wallColor),
        groundColor = config.groundColor or (Config.PolygonMarker and Config.PolygonMarker.groundColor),
        wallHeight = config.wallHeight or config.height or (Config.PolygonMarker and Config.PolygonMarker.wallHeight) or 30.0,
        pulseEffect = config.pulseEffect or (Config.PolygonMarker and Config.PolygonMarker.pulseEffect),
        gradientEffect = config.gradientEffect ~= false,
        insideOpacity = config.insideOpacity or (Config.PolygonMarker and Config.PolygonMarker.insideOpacity) or 0.8,
        drawCeiling = config.drawCeiling ~= false,
        cornerBeams = config.cornerBeams ~= false
    }
end

local function ProcessZoneDefinition(zone)
    if not zone then
        return nil
    end

    local processedZone = nil

    if zone.type == 'circle' and zone.coords and zone.radius then
        local coords = zone.coords
        if type(coords) == 'table' then
            coords = vector3(coords.x, coords.y, coords.z)
        end

        processedZone = {
            id = zone.id,
            name = zone.name,
            type = 'circle',
            coords = coords,
            radiusSquared = zone.radius * zone.radius,
            radius = zone.radius,
            minZ = zone.minZ or (zone.infiniteHeight and -1000 or coords.z - 50),
            maxZ = zone.maxZ or (zone.infiniteHeight and 1000 or coords.z + 150),
            infiniteHeight = zone.infiniteHeight,
            showMarker = zone.showMarker,
            originalZone = zone,
            renderDistance = zone.renderDistance
        }
    elseif zone.type == 'polygon' and zone.points then
        local bounds = CalculatePolygonBounds(zone.points)

        processedZone = {
            id = zone.id,
            name = zone.name,
            type = 'polygon',
            points = zone.points,
            minZ = zone.infiniteHeight and -1000 or (zone.minZ or -50),
            maxZ = zone.infiniteHeight and 1000 or (zone.maxZ or 150),
            infiniteHeight = zone.infiniteHeight,
            center = vector2(bounds.centerX, bounds.centerY),
            bounds = bounds,
            showMarker = zone.showMarker,
            renderDistance = zone.renderDistance,
            originalZone = zone
        }
    end

    if not processedZone then
        return nil
    end

    processedZone.markerConfig = BuildMarkerConfig(zone.markerConfig)

    return processedZone
end

local function ProcessZoneCollection(sourceZones)
    local processed = {}
    local lookup = {}
    local count = 0

    for i = 1, #sourceZones do
        local processedZone = ProcessZoneDefinition(sourceZones[i])
        if processedZone then
            count = count + 1
            processed[count] = processedZone

            if processedZone.name then
                lookup[processedZone.name] = processedZone
            end
        end
    end

    return processed, lookup, count
end

local function ProcessZones()
    local processed, lookup, count = ProcessZoneCollection(currentZones)

    processedZones = processed
    processedZoneLookup = lookup
    zoneCount = count

    Log('ZONE', 'Processed %d zone definition(s) for rendering', zoneCount)
end

local function ProcessInactiveDebugZones()
    if #inactiveZones == 0 then
        processedInactiveZones = {}
        return
    end

    local processed = ProcessZoneCollection(inactiveZones)
    processedInactiveZones = processed
end

local function GetZoneRenderDistance(zone, forDebug)
    if forDebug and Safezone.Debug and Safezone.Debug.enabled then
        return 10000.0
    end

    if zone.renderDistance then
        return zone.renderDistance
    end

    return DEFAULT_RENDER_DISTANCE
end

local function DetermineLOD(distance)
    if not distance or distance == math.huge then
        return 'low'
    end

    if distance < Config.Performance.lodDistances.medium then
        return 'high'
    end

    return 'low'
end

local function EvaluateZoneForRendering(zone, playerCoords, forDebug)
    local renderDistance = GetZoneRenderDistance(zone, forDebug)
    local distance = math.huge

    if zone.type == 'circle' then
        local distanceSquared = Zones.GetDistanceSquared(playerCoords, zone.coords)
        local distanceToCenter = math.sqrt(distanceSquared)
        distance = math.max(0.0, distanceToCenter - zone.radius)
    elseif zone.type == 'polygon' then
        local bounds = zone.bounds
        if bounds then
            local inside = IsPointInPolygon(vector2(playerCoords.x, playerCoords.y), zone.points, bounds)
            if inside then
                distance = 0.0
            else
                local centerDist = #(vector2(playerCoords.x, playerCoords.y) - zone.center)
                local approxRadius = math.max(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY) / 2
                distance = math.max(0.0, centerDist - approxRadius)
            end
        end
    end

    local shouldRender = distance < renderDistance
    return shouldRender, distance, renderDistance
end

local function GetZoneDebugState(zone)
    if not zone then
        return nil
    end

    local states = Safezone.Debug and Safezone.Debug.zoneStates
    if not states then
        return nil
    end

    if zone.name and states[zone.name] ~= nil then
        return states[zone.name]
    end

    if zone.originalZone and zone.originalZone.name and states[zone.originalZone.name] ~= nil then
        return states[zone.originalZone.name]
    end

    return nil
end

local function ZoneMatchesDebugFilter(zone)
    local mode = Safezone.Debug and Safezone.Debug.mode or 'all'
    local reference = zone.originalZone or zone

    if mode == 'single' then
        local targetId = Safezone.Debug.singleZoneId
        if targetId then
            local zoneId = zone.id or (zone.originalZone and zone.originalZone.id)
            return zoneId == targetId
        end
        return false
    end

    if mode == 'inactive' then
        return reference.isActive == false
    elseif mode == 'active' then
        return reference.isActive ~= false
    end

    return true
end

function Zones.SetZones(zones)
    zones = zones or {}

    local activeZones = {}
    local inactiveList = {}
    local activeCount = 0
    local inactiveCount = 0
    local zoneLookup = {}

    for i = 1, #zones do
        local zone = zones[i]
        if zone then
            if zone.name then
                zoneLookup[zone.name] = true
            end
            if zone.isActive == false then
                inactiveCount = inactiveCount + 1
                inactiveList[inactiveCount] = zone
            else
                activeCount = activeCount + 1
                activeZones[activeCount] = zone
            end
        end
    end

    if Safezone.Debug and Safezone.Debug.zoneStates then
        for name in pairs(Safezone.Debug.zoneStates) do
            if not zoneLookup[name] then
                Safezone.Debug.zoneStates[name] = nil
            end
        end
    end

    currentZones = activeZones
    inactiveZones = inactiveList
    ProcessZones()
    ProcessInactiveDebugZones()
    Zones.ClearBlips()
    lowestPointCache = {}

    if Safezone and Safezone.State and Safezone.State.isInSafezone and Safezone.State.currentSafezone then
        local activeZone = Zones.GetProcessedZoneByName(Safezone.State.currentSafezone.name)
        if not activeZone then
            Safezone.ExitSafezone()
        end
    end
end

function Zones.GetZoneCount()
    return zoneCount
end

function Zones.GetProcessedZones()
    return processedZones
end

function Zones.GetProcessedZoneByName(name)
    return processedZoneLookup and name and processedZoneLookup[name] or nil
end

function Zones.GetCurrentZones()
    return currentZones
end

function Zones.GetAllZones()
    local allZones = {}
    for _, zone in ipairs(processedZones) do
        allZones[#allZones + 1] = zone
    end
    for _, zone in ipairs(processedInactiveZones) do
        allZones[#allZones + 1] = zone
    end
    return allZones
end

local function ParseHexColor(hexString)
    if type(hexString) == 'number' then
        return hexString
    end
    if type(hexString) == 'string' then
        if hexString:sub(1, 2) == '0x' or hexString:sub(1, 2) == '0X' then
            return tonumber(hexString)
        end
        if hexString:sub(1, 1) == '#' then
            return 2
        end
    end
    return 2
end

local function HexToRGB(hexString)
    if type(hexString) ~= 'string' then return 245, 166, 35 end

    local hex = hexString

    if hex:sub(1, 2) == '0x' or hex:sub(1, 2) == '0X' then
        hex = hex:sub(3, 8)
    end

    hex = hex:gsub('#', '')

    if #hex >= 6 then
        return tonumber(hex:sub(1, 2), 16) or 0,
               tonumber(hex:sub(3, 4), 16) or 166,
               tonumber(hex:sub(5, 6), 16) or 35
    end
    return 245, 166, 35
end

local BLIP_COLOR_MAP = {
    [0] = {255, 255, 255},
    [1] = {224, 50, 50},
    [2] = {114, 204, 114},
    [3] = {93, 182, 229},
    [4] = {255, 255, 255},
    [5] = {240, 200, 80},
    [6] = {194, 80, 80},
    [7] = {156, 110, 175},
    [8] = {255, 123, 196},
    [9] = {247, 159, 123},
    [10] = {178, 144, 132},
    [11] = {141, 206, 167},
    [12] = {113, 169, 175},
    [13] = {211, 209, 231},
    [14] = {144, 127, 153},
    [15] = {106, 196, 191},
    [16] = {214, 196, 153},
    [17] = {234, 142, 80},
    [18] = {152, 203, 234},
    [19] = {178, 98, 135},
    [20] = {144, 142, 122},
    [21] = {166, 117, 94},
    [22] = {175, 168, 168},
    [23] = {232, 142, 155},
    [24] = {187, 214, 91},
    [25] = {12, 123, 86},
    [26] = {123, 196, 255},
    [27] = {171, 60, 230},
    [28] = {206, 169, 13},
    [29] = {71, 99, 143},
    [30] = {42, 166, 185},
    [38] = {93, 182, 229},
    [40] = {93, 182, 229},
    [42] = {240, 200, 80},
    [43] = {93, 182, 229},
    [44] = {224, 50, 50},
    [46] = {114, 204, 114},
    [47] = {93, 182, 229},
    [48] = {255, 123, 196},
    [49] = {93, 182, 229},
    [50] = {240, 200, 80},
    [51] = {240, 200, 80},
    [52] = {240, 200, 80},
    [53] = {255, 123, 196},
    [54] = {247, 159, 123},
    [55] = {224, 50, 50},
    [56] = {240, 200, 80},
    [57] = {240, 200, 80},
    [58] = {93, 182, 229},
    [59] = {93, 182, 229},
    [60] = {224, 50, 50},
    [61] = {240, 200, 80},
    [62] = {240, 200, 80},
    [63] = {93, 182, 229},
    [64] = {240, 200, 80},
    [65] = {240, 200, 80},
    [66] = {93, 182, 229},
    [67] = {114, 204, 114},
    [68] = {114, 204, 114},
    [69] = {93, 182, 229},
    [70] = {42, 166, 185},
    [71] = {114, 204, 114},
    [72] = {42, 166, 185},
    [73] = {114, 204, 114},
    [74] = {42, 166, 185},
    [75] = {42, 166, 185},
    [76] = {240, 200, 80},
    [77] = {240, 200, 80},
    [78] = {224, 50, 50},
    [79] = {114, 204, 114},
    [80] = {114, 204, 114},
    [81] = {42, 166, 185},
    [82] = {224, 50, 50},
    [83] = {171, 60, 230},
    [84] = {93, 182, 229},
    [85] = {42, 166, 185},
}

local function FindClosestBlipColor(r, g, b)
    local closestId = 2
    local closestDist = math.huge

    for id, rgb in pairs(BLIP_COLOR_MAP) do
        local dr = r - rgb[1]
        local dg = g - rgb[2]
        local db = b - rgb[3]
        local dist = dr*dr + dg*dg + db*db

        if dist < closestDist then
            closestDist = dist
            closestId = id
        end
    end

    return closestId
end

local function GetBlipColorFromHex(hexString)
    local r, g, b = HexToRGB(hexString)
    return FindClosestBlipColor(r, g, b)
end

local function CreateCircleBlip(zone)
    local coords = zone.coords
    local blipSprite = zone.blipSprite or 84
    local blipColor = ParseHexColor(zone.blipColor) or 2

    local showCenterBlip = zone.showCenterBlip ~= false
    local blipAlpha = zone.blipAlpha or 180
    local blipScale = zone.blipScale or 0.8
    local blipShortRange = zone.blipShortRange == true
    local blipHiddenOnLegend = zone.blipHiddenOnLegend == true
    local blipHighDetail = zone.blipHighDetail ~= false

    local showZoneOutline = zone.showZoneOutline ~= false
    local circleCoverageType = zone.circleCoverageType or 'full'
    local outlineRadius = zone.outlineRadius or 1.2
    local outlineSpacing = zone.outlineSpacing or 6.0
    local outlineAlpha = zone.outlineAlpha or 160
    local outlineColor = zone.outlineColor or '#F5A623'

    local outlineStrokeEnabled = zone.outlineStrokeEnabled ~= false
    local strokeRadius = zone.strokeRadius or 1.5
    local strokeColor = zone.strokeColor or '#FFFFFF'
    local strokeAlpha = zone.strokeAlpha or 220

    if showCenterBlip then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, blipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipScale)
        SetBlipColour(blip, blipColor)
        SetBlipAlpha(blip, blipAlpha)
        SetBlipAsShortRange(blip, blipShortRange)
        SetBlipHighDetail(blip, blipHighDetail)
        if blipHiddenOnLegend then
            SetBlipHiddenOnLegend(blip, true)
        end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(zone.blipName or zone.name)
        EndTextCommandSetBlipName(blip)
        Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = blip
    end

    if showZoneOutline then
        local outlineColorId = GetBlipColorFromHex(outlineColor)
        local strokeColorId = GetBlipColorFromHex(strokeColor)

        if circleCoverageType == 'full' then
            local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, zone.radius + 0.0)
            SetBlipHighDetail(radiusBlip, true)
            SetBlipColour(radiusBlip, outlineColorId)
            SetBlipAlpha(radiusBlip, outlineAlpha)
            Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = radiusBlip
        else
            local numPoints = math.max(12, math.floor((2 * math.pi * zone.radius) / outlineSpacing))

            for i = 1, numPoints do
                local angle = (i / numPoints) * 2 * math.pi
                local px = coords.x + math.cos(angle) * zone.radius
                local py = coords.y + math.sin(angle) * zone.radius
                local pz = coords.z

                if outlineStrokeEnabled then
                    local strokeBlip = AddBlipForRadius(px, py, pz, outlineRadius * strokeRadius)
                    SetBlipHighDetail(strokeBlip, true)
                    SetBlipColour(strokeBlip, strokeColorId)
                    SetBlipAlpha(strokeBlip, strokeAlpha)
                    Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = strokeBlip
                end

                local dotBlip = AddBlipForRadius(px, py, pz, outlineRadius)
                SetBlipHighDetail(dotBlip, true)
                SetBlipColour(dotBlip, outlineColorId)
                SetBlipAlpha(dotBlip, outlineAlpha)
                Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = dotBlip
            end
        end
    end
end

local function CreatePolygonBlip(zone)
    local blipSprite = zone.blipSprite or 84
    local blipColor = ParseHexColor(zone.blipColor) or 2

    local showCenterBlip = zone.showCenterBlip ~= false
    local blipAlpha = zone.blipAlpha or 180
    local blipScale = zone.blipScale or 0.8
    local blipShortRange = zone.blipShortRange == true
    local blipHiddenOnLegend = zone.blipHiddenOnLegend == true
    local blipHighDetail = zone.blipHighDetail ~= false

    local showZoneOutline = zone.showZoneOutline ~= false
    local outlineDotRadius = zone.outlineRadius or 1.2
    local outlineSpacing = zone.outlineSpacing or 6.0
    local outlineAlpha = zone.outlineAlpha or 160
    local outlineColor = zone.outlineColor or '#F5A623'

    local outlineStrokeEnabled = zone.outlineStrokeEnabled ~= false
    local strokeRadiusMultiplier = zone.strokeRadius or 1.5
    local strokeAlpha = zone.strokeAlpha or 220
    local strokeColor = zone.strokeColor or '#FFFFFF'

    local coords = zone.blipCoords

    if not coords and zone.bounds then
        coords = vector3(zone.bounds.centerX, zone.bounds.centerY, (zone.minZ + zone.maxZ) / 2)
    elseif not coords and zone.points and #zone.points > 0 then
        local centerX, centerY = 0, 0
        for _, point in ipairs(zone.points) do
            centerX = centerX + point.x
            centerY = centerY + point.y
        end
        centerX = centerX / #zone.points
        centerY = centerY / #zone.points
        coords = vector3(centerX, centerY, (zone.minZ + zone.maxZ) / 2)
    end

    if not coords then
        Log('ERROR', 'Cannot create blip for polygon zone "%s" - no coordinates', zone.name or 'Unknown')
        return
    end

    if showCenterBlip then
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, blipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipScale)
        SetBlipColour(blip, blipColor)
        SetBlipAlpha(blip, blipAlpha)
        SetBlipAsShortRange(blip, blipShortRange)
        SetBlipHighDetail(blip, blipHighDetail)
        if blipHiddenOnLegend then
            SetBlipHiddenOnLegend(blip, true)
        end
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.blipName or zone.name)
        EndTextCommandSetBlipName(blip)
        Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = blip
    end

    if showZoneOutline and zone.points then
        local numPoints = #zone.points
        local strokeRadius = outlineDotRadius * strokeRadiusMultiplier
        local outlineColorId = GetBlipColorFromHex(outlineColor)
        local strokeColorId = GetBlipColorFromHex(strokeColor)

        for j = 1, numPoints do
            local p1 = zone.points[j]
            local p2 = zone.points[(j % numPoints) + 1]
            local distance = math.sqrt((p2.x - p1.x)^2 + (p2.y - p1.y)^2)
            local numCircles = math.max(2, math.floor(distance / outlineSpacing))

            for k = 0, numCircles do
                local t = k / numCircles
                local x = p1.x + (p2.x - p1.x) * t
                local y = p1.y + (p2.y - p1.y) * t

                if outlineStrokeEnabled then
                    local strokeBlip = AddBlipForRadius(x, y, coords.z, strokeRadius)
                    SetBlipHighDetail(strokeBlip, true)
                    SetBlipColour(strokeBlip, strokeColorId)
                    SetBlipAlpha(strokeBlip, strokeAlpha)
                    Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = strokeBlip
                end

                local edgeBlip = AddBlipForRadius(x, y, coords.z, outlineDotRadius)
                SetBlipHighDetail(edgeBlip, true)
                SetBlipColour(edgeBlip, outlineColorId)
                SetBlipAlpha(edgeBlip, outlineAlpha)
                Safezone.State.createdBlips[#Safezone.State.createdBlips + 1] = edgeBlip
            end
        end
    end
end

function Zones.CreateBlips()
    for i = 1, #currentZones do
        local zone = currentZones[i]
        if zone.showBlip then
            if zone.type == "circle" then
                CreateCircleBlip(zone)
            elseif zone.type == "polygon" then
                CreatePolygonBlip(zone)
            end
        end
    end
end

function Zones.ClearBlips()
    for i = 1, #Safezone.State.createdBlips do
        if DoesBlipExist(Safezone.State.createdBlips[i]) then
            RemoveBlip(Safezone.State.createdBlips[i])
        end
    end
    Safezone.State.createdBlips = {}
end

local function GetLowestZonePoint(zone)
    if zone.type == 'circle' then
        return GetLowestPointInCircle(zone.coords, zone.radius)
    elseif zone.type == 'polygon' then
        return GetLowestPointInPolygon(zone.points, zone.minZ, zone.maxZ)
    end
    return zone.coords and zone.coords.z or 0
end

function Zones.GetLowestPointInZone(zoneName)
    for i = 1, zoneCount do
        local zone = processedZones[i]
        if zone.name == zoneName then
            return GetLowestZonePoint(zone)
        end
    end
    return nil
end

function Zones.ClearCache()
    lowestPointCache = {}
    markersToRender = {}
    debugMarkers = {}
    processedZones = {}
    processedInactiveZones = {}
    currentZones = {}
    inactiveZones = {}
    zoneCount = 0
    processedZoneLookup = {}
end

function Zones.IsPointInPolygon(point, polygon, bounds)
    return IsPointInPolygon(point, polygon, bounds)
end

local function EvaluatePlayerPositionInZone(playerCoords, zone)
    if not zone then
        return false, math.huge
    end

    if zone.type == 'circle' then
        local distanceSquared = Zones.GetDistanceSquared(playerCoords, zone.coords)
        if distanceSquared <= zone.radiusSquared and playerCoords.z >= zone.minZ and playerCoords.z <= zone.maxZ then
            return true, math.sqrt(distanceSquared)
        end
    elseif zone.type == 'polygon' then
        if playerCoords.z >= zone.minZ and playerCoords.z <= zone.maxZ then
            local inPolygon = IsPointInPolygon(vector2(playerCoords.x, playerCoords.y), zone.points, zone.bounds)
            if inPolygon then
                local distance = #(vector2(playerCoords.x, playerCoords.y) - zone.center)
                return true, distance
            end
        end
    end

    return false, math.huge
end

function Zones.IsPlayerInsideZone(playerCoords, zone)
    return EvaluatePlayerPositionInZone(playerCoords, zone)
end

function Zones.ForceMarkerUpdate()
    lastMarkerUpdate = 0
end

local function HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return r, g, b
end

local function DrawText3DStatic(x, y, z, text, scale, offsetY)
    offsetY = offsetY or 0
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry('STRING')
    SetTextCentre(true)
    SetTextOutline()
    AddTextComponentString(text)
    DrawText(0.0, offsetY)
    ClearDrawOrigin()
end

local function CalculateMarkerEffects(markerConfig, currentTime)
    local effects = {
        color = table.clone(markerConfig.color),
        scale = table.clone(markerConfig.scale or {
            x = 1.0,
            y = 1.0,
            z = 1.0
        }),
        rotation = 0,
        zOffset = 0
    }

    if markerConfig.pulsing then
        local pulse = math.sin(currentTime * 0.001 * markerConfig.pulseSpeed) * 0.3 + 0.7
        effects.color.a = math.floor((markerConfig.color.a or 100) * pulse)
    end

    if markerConfig.bobbing then
        effects.zOffset = math.sin(currentTime * 0.002) * markerConfig.bobHeight
    end

    if markerConfig.rotating then
        effects.rotation = (currentTime * 0.1 * markerConfig.rotationSpeed) % 360
    end

    if markerConfig.colorShift then
        local hue = (currentTime * 0.0005) % 1.0
        local r, g, b = HSVToRGB(hue, 0.7, 1.0)
        effects.color.r = math.floor(r * 255)
        effects.color.g = math.floor(g * 255)
        effects.color.b = math.floor(b * 255)
    end

    return effects
end

local function DrawEnhancedCircleMarker(zone, _, currentTime)
    local coords = zone.coords
    local markerConfig = zone.markerConfig
    local effects = CalculateMarkerEffects(markerConfig, currentTime)

    local markerZ = coords.z
    if markerConfig.autoLevel then
        markerZ = GetLowestZonePoint(zone) - 0.5
    end

    markerZ = markerZ + effects.zOffset
    local markerHeight = markerConfig.height or 30.0

    local internalType = markerConfig.type or 1
    local nativeMarkerType = (Config.MarkerTypeMapping and Config.MarkerTypeMapping[internalType]) or internalType

    if internalType == 6 then

        local centerX, centerY = coords.x, coords.y
        local baseZ = markerZ

        local radius = zone.radius

        local domeHeight = markerHeight

        local color = effects.color
        local r, g, b, a = color.r, color.g, color.b, color.a

        local horizontalSegments = 24
        local verticalSegments = 12

        local hStep = (2 * math.pi) / horizontalSegments
        local vStep = (math.pi / 2) / verticalSegments

        for v = 0, verticalSegments - 1 do
            local phi1 = v * vStep
            local phi2 = (v + 1) * vStep

            local z1 = baseZ + (math.sin(phi1) * domeHeight)
            local z2 = baseZ + (math.sin(phi2) * domeHeight)
            local r1 = math.cos(phi1) * radius
            local r2 = math.cos(phi2) * radius

            for h = 0, horizontalSegments - 1 do
                local theta1 = h * hStep
                local theta2 = (h + 1) * hStep

                local x1 = centerX + (math.cos(theta1) * r1)
                local y1 = centerY + (math.sin(theta1) * r1)

                local x2 = centerX + (math.cos(theta2) * r1)
                local y2 = centerY + (math.sin(theta2) * r1)

                local x3 = centerX + (math.cos(theta1) * r2)
                local y3 = centerY + (math.sin(theta1) * r2)

                local x4 = centerX + (math.cos(theta2) * r2)
                local y4 = centerY + (math.sin(theta2) * r2)

                DrawPoly(x1, y1, z1, x2, y2, z1, x4, y4, z2, r, g, b, a)
                DrawPoly(x1, y1, z1, x4, y4, z2, x3, y3, z2, r, g, b, a)

                DrawPoly(x4, y4, z2, x2, y2, z1, x1, y1, z1, r, g, b, a)
                DrawPoly(x3, y3, z2, x4, y4, z2, x1, y1, z1, r, g, b, a)
            end
        end
    else
        DrawMarker(nativeMarkerType, coords.x, coords.y, markerZ, 0.0, 0.0, 0.0, 0.0, 0.0, effects.rotation,
            zone.radius * 2.0 * effects.scale.x, zone.radius * 2.0 * effects.scale.y, markerHeight * effects.scale.z,
            effects.color.r, effects.color.g, effects.color.b, effects.color.a, markerConfig.bobbing,
            false, 2, markerConfig.rotating, nil, nil, false)
    end
end

local function DrawEnhancedPolygon(zone, markerData, currentTime)
    local points = zone.points
    local minZ = zone.minZ
    local markerConfig = zone.markerConfig
    local effects = CalculateMarkerEffects(markerConfig, currentTime)

    local wallColor = markerConfig.wallColor
    local groundColor = markerConfig.groundColor

    if markerConfig.colorShift then
        wallColor = effects.color
        groundColor = {
            r = effects.color.r,
            g = effects.color.g,
            b = effects.color.b,
            a = math.floor((markerConfig.groundColor.a or 30) * (effects.color.a / 100))
        }
    elseif markerConfig.pulseEffect then
        local pulse = math.sin(currentTime * 0.001 * markerConfig.pulseSpeed) * 0.3 + 0.7
        wallColor = {
            r = markerConfig.wallColor.r,
            g = markerConfig.wallColor.g,
            b = markerConfig.wallColor.b,
            a = math.floor(markerConfig.wallColor.a * pulse)
        }
        groundColor = {
            r = markerConfig.groundColor.r,
            g = markerConfig.groundColor.g,
            b = markerConfig.groundColor.b,
            a = math.floor(markerConfig.groundColor.a * pulse)
        }
    end

    local wallHeight
    if zone.infiniteHeight then
        wallHeight = 150.0
    else
        wallHeight = zone.maxZ - zone.minZ
    end

    local shouldDrawRoof = zone.originalZone and zone.originalZone.addRoof

    local centerX, centerY = 0, 0
    for _, point in ipairs(points) do
        centerX = centerX + point.x
        centerY = centerY + point.y
    end
    centerX = centerX / #points
    centerY = centerY / #points

    local rotatedPoints = {}
    if markerConfig.rotating then
        local angleRad = math.rad(effects.rotation)
        local cosAngle = math.cos(angleRad)
        local sinAngle = math.sin(angleRad)

        for i, point in ipairs(points) do
            local translatedX = point.x - centerX
            local translatedY = point.y - centerY

            local rotatedX = translatedX * cosAngle - translatedY * sinAngle
            local rotatedY = translatedX * sinAngle + translatedY * cosAngle

            rotatedPoints[i] = {
                x = rotatedX + centerX,
                y = rotatedY + centerY
            }
        end
    else
        for i, point in ipairs(points) do
            rotatedPoints[i] = {x = point.x, y = point.y}
        end
    end

    local adjustedPoints = {}
    local baseMinZ, baseMaxZ

    if markerConfig.autoLevel then
        local lowestZ = GetLowestZonePoint(zone)
        baseMinZ = lowestZ - 0.5 + effects.zOffset
        baseMaxZ = lowestZ - 0.5 + wallHeight + effects.zOffset

        for i, point in ipairs(rotatedPoints) do
            adjustedPoints[i] = {
                x = point.x,
                y = point.y,
                minZ = baseMinZ,
                maxZ = baseMaxZ
            }
        end
    else
        baseMinZ = minZ + effects.zOffset
        baseMaxZ = minZ + wallHeight + effects.zOffset

        for i, point in ipairs(rotatedPoints) do
            adjustedPoints[i] = {
                x = point.x,
                y = point.y,
                minZ = baseMinZ,
                maxZ = baseMaxZ
            }
        end
    end

    for i = 1, #adjustedPoints do
        local p1 = adjustedPoints[i]
        local p2 = adjustedPoints[i % #adjustedPoints + 1]

        DrawLine(p1.x, p1.y, p1.minZ, p1.x, p1.y, p1.maxZ, wallColor.r, wallColor.g, wallColor.b, wallColor.a)
        DrawLine(p1.x, p1.y, p1.minZ, p2.x, p2.y, p2.minZ, wallColor.r, wallColor.g, wallColor.b, wallColor.a)
        DrawLine(p1.x, p1.y, p1.maxZ, p2.x, p2.y, p2.maxZ, wallColor.r, wallColor.g, wallColor.b, wallColor.a)

        if markerConfig.gradientEffect and markerData.lod ~= 'low' then
            local steps = 10
            for h = 0, steps do
                local height = p1.minZ + (wallHeight * (h / steps))
                local gradAlpha = math.floor(wallColor.a * (1 - h / (steps * 2)))
                DrawLine(p1.x, p1.y, height, p2.x, p2.y, height, wallColor.r, wallColor.g, wallColor.b, gradAlpha)
            end
        end

        DrawPoly(p1.x, p1.y, p1.minZ, p2.x, p2.y, p2.minZ, p2.x, p2.y, p2.maxZ, wallColor.r, wallColor.g, wallColor.b, wallColor.a)
        DrawPoly(p1.x, p1.y, p1.minZ, p2.x, p2.y, p2.maxZ, p1.x, p1.y, p1.maxZ, wallColor.r, wallColor.g, wallColor.b, wallColor.a)

        local insideAlpha = math.floor(wallColor.a * (markerConfig.insideOpacity or 0.8))
        DrawPoly(p2.x, p2.y, p2.maxZ, p2.x, p2.y, p2.minZ, p1.x, p1.y, p1.minZ, wallColor.r, wallColor.g, wallColor.b, insideAlpha)
        DrawPoly(p1.x, p1.y, p1.maxZ, p2.x, p2.y, p2.maxZ, p1.x, p1.y, p1.minZ, wallColor.r, wallColor.g, wallColor.b, insideAlpha)
    end

    if #adjustedPoints >= 3 then
        local tris = TriangulatePolygon(points)

        for _, tri in ipairs(tris) do
            local a = adjustedPoints[tri[1]]
            local b = adjustedPoints[tri[2]]
            local c = adjustedPoints[tri[3]]

            DrawPoly(a.x, a.y, a.minZ, b.x, b.y, b.minZ, c.x, c.y, c.minZ, groundColor.r, groundColor.g, groundColor.b, groundColor.a)
            DrawPoly(c.x, c.y, c.minZ, b.x, b.y, b.minZ, a.x, a.y, a.minZ, groundColor.r, groundColor.g, groundColor.b, math.floor(groundColor.a * 0.7))
        end

        if shouldDrawRoof and markerData.lod ~= 'low' then
            local ceilingZ = baseMaxZ
            local roofAlphaOuter = math.min(255, math.floor(groundColor.a * 1.5))
            local roofAlphaInner = math.min(255, math.floor(groundColor.a * 1.2))
            for _, tri in ipairs(tris) do
                local a = adjustedPoints[tri[1]]
                local b = adjustedPoints[tri[2]]
                local c = adjustedPoints[tri[3]]

                DrawPoly(a.x, a.y, ceilingZ, b.x, b.y, ceilingZ, c.x, c.y, ceilingZ, groundColor.r, groundColor.g, groundColor.b, roofAlphaOuter)
                DrawPoly(c.x, c.y, ceilingZ, b.x, b.y, ceilingZ, a.x, a.y, ceilingZ, groundColor.r, groundColor.g, groundColor.b, roofAlphaInner)
            end
        end
    end

    if markerConfig.cornerBeams and markerData.lod ~= 'low' then
        for _, point in ipairs(adjustedPoints) do
            DrawLine(point.x, point.y, point.minZ, point.x, point.y, point.maxZ, wallColor.r, wallColor.g, wallColor.b, math.floor(wallColor.a * 1.5))
        end
    end
end

function Zones.RenderPreview(data)
    if not data or not data.type then return end

    local mc = BuildMarkerConfig(data.markerConfig)

    if not mc.wallColor then
        mc.wallColor = { r = mc.color.r, g = mc.color.g, b = mc.color.b, a = math.floor((mc.color.a or 100) * 0.5) }
    end
    if not mc.groundColor then
        mc.groundColor = { r = mc.color.r, g = mc.color.g, b = mc.color.b, a = math.floor((mc.color.a or 100) * 0.3) }
    end
    local currentTime = GetGameTimer()
    local markerData = { lod = 'high' }

    if data.type == 'polygon' then
        if not data.points or #data.points < 3 then return end

        local lowestZ = 9999.0
        for _, p in ipairs(data.points) do
            if p.z and p.z < lowestZ then lowestZ = p.z end
        end
        if lowestZ == 9999.0 then lowestZ = 0 end

        local zone = {
            type = 'polygon',
            points = data.points,
            minZ = data.minZ or lowestZ,
            maxZ = data.maxZ or (lowestZ + (mc.wallHeight or 30.0)),
            infiniteHeight = data.infiniteHeight or false,
            markerConfig = mc,
            showMarker = true,
            originalZone = { addRoof = data.addRoof or false }
        }

        DrawEnhancedPolygon(zone, markerData, currentTime)

    elseif data.type == 'circle' then
        if not data.center or not data.radius then return end

        local zone = {
            type = 'circle',
            coords = vector3(data.center.x, data.center.y, data.center.z),
            radius = data.radius,
            minZ = data.minZ or (data.center.z - 50),
            maxZ = data.maxZ or (data.center.z + 150),
            infiniteHeight = data.infiniteHeight or false,
            markerConfig = mc,
            showMarker = true,
            originalZone = {}
        }

        DrawEnhancedCircleMarker(zone, markerData, currentTime)
    end
end

CreateThread(function()
    local lastCacheCleanup = 0

    while true do
        local sleep = 1000
        local currentTime = GetGameTimer()

        if currentTime - lastCacheCleanup > 60000 then
            lastCacheCleanup = currentTime
            for key, data in pairs(lowestPointCache) do
                if currentTime - data.timestamp > Safezone.Constants.cacheTimeout then
                    lowestPointCache[key] = nil
                end
            end
        end

        if currentTime - lastMarkerUpdate > MARKER_UPDATE_INTERVAL then
            markersToRender = {}
            debugMarkers = {}

            local debugEnabled = Safezone.Debug and Safezone.Debug.enabled
            local hasManualDebugState = false

            if Safezone.Debug and Safezone.Debug.zoneStates then
                for _, value in pairs(Safezone.Debug.zoneStates) do
                    if value ~= nil then
                        hasManualDebugState = true
                        break
                    end
                end
            end

            if zoneCount > 0 or ((debugEnabled or hasManualDebugState) and #processedInactiveZones > 0) then
                Safezone.UpdatePlayerCache()
                local playerCoords = Safezone.Player.coords
                local activeZoneName = nil
                if Safezone.State and Safezone.State.isInSafezone and Safezone.State.currentSafezone then
                    activeZoneName = Safezone.State.currentSafezone.name
                end

                for i = 1, zoneCount do
                    local zone = processedZones[i]
                    if zone then
                        local manualState = GetZoneDebugState(zone)
                        local forceDebug = manualState == true
                        local suppressDebug = manualState == false
                        local matchesMode = debugEnabled and ZoneMatchesDebugFilter(zone)
                        local debugMatches = forceDebug or (matchesMode and not suppressDebug)

                        local skipMarkers = activeZoneName and zone.name ~= activeZoneName

                        if skipMarkers and not debugMatches then
                            goto continue
                        end

                        local shouldRender, distance, zoneRenderDist = EvaluateZoneForRendering(zone, playerCoords, false)
                        local lod = DetermineLOD(distance)
                        local markerData = nil

                        if not skipMarkers then
                            local canRenderMarker = zone.showMarker and (not zone.originalZone or zone.originalZone.isActive ~= false)
                            if canRenderMarker and shouldRender then
                                markerData = {
                                    zone = zone,
                                    distance = distance,
                                    lod = lod
                                }
                                markersToRender[#markersToRender + 1] = markerData

                                if debugEnabled or forceDebug then
                                    Log('ZONE', 'Adding zone %s to render queue at %.1f units', zone.name or 'Unknown', distance)
                                end
                            elseif (debugEnabled or forceDebug) and zone.showMarker and not shouldRender then
                                Log('ZONE', 'Skipping zone %s (distance %.1f exceeds render range %.1f)', zone.name or 'Unknown',
                                    distance or -1, zoneRenderDist)
                            end
                        end

                        if debugMatches then
                            local _, debugDistance = EvaluateZoneForRendering(zone, playerCoords, true)
                            local debugLod = DetermineLOD(debugDistance)
                            local debugMarkerData = {
                                zone = zone,
                                distance = debugDistance,
                                lod = debugLod,
                                forceDebug = forceDebug or nil
                            }
                            debugMarkers[#debugMarkers + 1] = debugMarkerData
                        end

                        ::continue::
                    end
                end

                if (debugEnabled or hasManualDebugState) and (#processedInactiveZones > 0) then
                    local mode = Safezone.Debug.mode or 'all'
                    if mode == 'inactive' or mode == 'all' then
                        for i = 1, #processedInactiveZones do
                            local zone = processedInactiveZones[i]
                            if zone then
                                local manualState = GetZoneDebugState(zone)
                                local forceDebug = manualState == true
                                local suppressDebug = manualState == false
                                local matches = forceDebug or ((debugEnabled and ZoneMatchesDebugFilter(zone)) and not suppressDebug)

                                if matches then
                                    local shouldRender, distance, zoneRenderDist = EvaluateZoneForRendering(zone, playerCoords, true)
                                    if shouldRender then
                                        local lod = DetermineLOD(distance)
                                        debugMarkers[#debugMarkers + 1] = {
                                            zone = zone,
                                            distance = distance,
                                            lod = lod,
                                            forceDebug = forceDebug or nil
                                        }
                                    elseif debugEnabled or forceDebug then
                                        Log('ZONE', 'Skipping zone %s (distance %.1f exceeds render range %.1f)', zone.name or 'Unknown',
                                            distance or -1, zoneRenderDist)
                                    end
                                end
                            end
                        end
                    end
                end

                if #markersToRender > 1 then
                    table.sort(markersToRender, function(a, b)
                        return a.distance > b.distance
                    end)
                end

                if #debugMarkers > 1 then
                    table.sort(debugMarkers, function(a, b)
                        return a.distance > b.distance
                    end)
                end
            end

            lastMarkerUpdate = currentTime
        end

        if #markersToRender > 0 or #debugMarkers > 0 then
            sleep = 0
            local renderStart = GetGameTimer()

            for i = 1, #markersToRender do
                local markerData = markersToRender[i]
                local zone = markerData.zone

                if zone.type == 'circle' then
                    DrawEnhancedCircleMarker(zone, markerData, currentTime)
                elseif zone.type == 'polygon' then
                    DrawEnhancedPolygon(zone, markerData, currentTime)
                end
            end

            local hasForceDebugMarkers = false
            for i = 1, #debugMarkers do
                if debugMarkers[i].forceDebug then
                    hasForceDebugMarkers = true
                    break
                end
            end

            if Safezone.Debug.enabled or hasForceDebugMarkers then
                for i = 1, #debugMarkers do
                    local markerData = debugMarkers[i]
                    if not Safezone.Debug.enabled and not markerData.forceDebug then
                        goto continueDebug
                    end

                    local zone = markerData.zone
                    local originalConfig = zone.markerConfig
                    zone.markerConfig = table.clone(originalConfig)
                    zone.markerConfig.color = Config.DebugOptions.markerColor
                    zone.markerConfig.wallColor = Config.DebugOptions.markerColor
                    zone.markerConfig.groundColor = {
                        r = Config.DebugOptions.markerColor.r,
                        g = Config.DebugOptions.markerColor.g,
                        b = Config.DebugOptions.markerColor.b,
                        a = math.floor(Config.DebugOptions.markerColor.a * 0.5)
                    }

                    if zone.type == 'circle' then
                        DrawEnhancedCircleMarker(zone, markerData, currentTime)
                    elseif zone.type == 'polygon' then
                        DrawEnhancedPolygon(zone, markerData, currentTime)
                    end

                    zone.markerConfig = originalConfig

                    if Config.DebugOptions.showZoneInfo then
                        local textCoords = zone.type == 'circle' and zone.coords or vector3(zone.center.x, zone.center.y, (zone.minZ + zone.maxZ) / 2)
                        local zoneId = zone.id or (zone.originalZone and zone.originalZone.id) or '?'
                        local displayText = string.format('#%s %s', zoneId, zone.name)
                        DrawText3DStatic(textCoords.x, textCoords.y, textCoords.z + 2, displayText, 0.4, 0.0)

                        if Config.DebugOptions.showCoordinates then
                            local coordText = zone.type == 'circle'
                                and string.format('X: %.1f  Y: %.1f  Z: %.1f', zone.coords.x, zone.coords.y, zone.coords.z)
                                or string.format('Points: %d', #zone.points)
                            DrawText3DStatic(textCoords.x, textCoords.y, textCoords.z + 2, coordText, 0.3, 0.025)

                            local zoneHeight = zone.maxZ - zone.minZ
                            local heightText = string.format('Height: %.1fm (%.1f - %.1f)', zoneHeight, zone.minZ, zone.maxZ)
                            DrawText3DStatic(textCoords.x, textCoords.y, textCoords.z + 2, heightText, 0.3, 0.05)
                        end
                    end

                    ::continueDebug::
                end
            end

            Safezone.Performance.markerRenderTime = GetGameTimer() - renderStart
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('f5_safezones:zoneMarkerToggled', function(zoneName, showMarker)
    for i = 1, #currentZones do
        if currentZones[i].name:lower() == zoneName:lower() then
            currentZones[i].showMarker = showMarker
            ProcessZones()
            lastMarkerUpdate = 0
            return
        end
    end
end)

RegisterNetEvent('f5_safezones:zoneActivationChanged', function(zoneName, isActive)
    if not zoneName then
        return
    end

    if not isActive and Safezone.State.isInSafezone and Safezone.State.currentSafezone and
        Safezone.State.currentSafezone.name == zoneName then
        Safezone.ExitSafezone()
    end

    if not Safezone.UI.IsOpen() then
        local message = isActive and string.format(Translate('zone_activation_enabled'), zoneName)
            or string.format(Translate('zone_activation_disabled'), zoneName)
        Safezone.ShowNotification(message, isActive and 'success' or 'primary')
    end
    Zones.ForceMarkerUpdate()
end)

RegisterNetEvent('f5_safezones:zonesActivationBulkChanged', function(isActive)
    if not isActive and Safezone.State.isInSafezone then
        Safezone.ExitSafezone()
    end

    if not Safezone.UI.IsOpen() then
        local message = isActive and Translate('zones_activation_all_enabled') or Translate('zones_activation_all_disabled')
        Safezone.ShowNotification(message, isActive and 'success' or 'primary')
    end
    Zones.ForceMarkerUpdate()
end)

if Config.Commands.sztoggle and Config.Commands.sztoggle.active then
    RegisterCommand(Config.Commands.sztoggle.name, function(_, args)
        if not args[1] then
            print('^1[Safezones]^0 Usage: /' .. Config.Commands.sztoggle.name .. ' <zone_id>')
            print('^3[Safezones]^0 Use /listsafezones to see zone IDs')
            return
        end
        local zoneId = args[1]
        TriggerServerEvent('f5_safezones:toggleZoneMarker', zoneId)
    end, false)
end

if Config.Commands.debugrender and Config.Commands.debugrender.active then
    RegisterCommand(Config.Commands.debugrender.name, function()
        Safezone.Debug.enabled = not Safezone.Debug.enabled
        if Safezone.Debug.enabled then
            Log('COMMAND', 'Render distance debug mode enabled')
            Log('COMMAND', 'Watching console for zone distance calculations')
        else
            Log('COMMAND', 'Render distance debug mode disabled')
        end
    end, false)
end

if Config.Commands.setrenderdist and Config.Commands.setrenderdist.active then
    RegisterCommand(Config.Commands.setrenderdist.name, function(_, args)
        if #args < 2 then
            print('^1[Safezones]^0 Usage: /' .. Config.Commands.setrenderdist.name .. ' <zone_id> <distance>')
            print('^3[Safezones]^0 Example: /' .. Config.Commands.setrenderdist.name .. ' 1 200')
            print('^3[Safezones]^0 Use /listsafezones to see zone IDs')
            return
        end

        local zoneId = tonumber(args[1])
        local distance = tonumber(args[2])

        if not zoneId then
            print('^1[Safezones]^0 Invalid zone ID. Must be a number.')
            return
        end

        if not distance then
            print('^1[Safezones]^0 Invalid distance. Must be a number.')
            return
        end

        local found = false
        for i = 1, #processedZones do
            if processedZones[i].id == zoneId then
                processedZones[i].renderDistance = distance
                print(string.format('^2[Safezones]^0 Set render distance for #%d "%s" to %dm', zoneId, processedZones[i].name, distance))
                found = true
                break
            end
        end

        if not found then
            print('^1[Safezones]^0 Zone with ID ' .. zoneId .. ' not found.')
            print('^3[Safezones]^0 Use /listsafezones to see available zones and their IDs')
        end
    end, false)
end
