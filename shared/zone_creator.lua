local _res = GetCurrentResourceName()
local _is_server = IsDuplicityVersion()

Safezone = Safezone or {}

if not _is_server then
    Safezone.ZoneCreator = Safezone.ZoneCreator or {}
    local ZoneCreator = Safezone.ZoneCreator

    local _keys = {
        ["enter"] = 191,
        ["escape"] = 322,
        ["backspace"] = 177,
        ["tab"] = 37,
        ["arrowleft"] = 174,
        ["arrowright"] = 175,
        ["arrowup"] = 172,
        ["arrowdown"] = 173,
        ["space"] = 22,
        ["delete"] = 178,
        ["insert"] = 121,
        ["home"] = 213,
        ["end"] = 214,
        ["pageup"] = 10,
        ["pagedown"] = 11,
        ["leftcontrol"] = 36,
        ["leftshift"] = 21,
        ["leftalt"] = 19,
        ["numpad0"] = 108,
        ["numpad1"] = 117,
        ["numpad2"] = 118,
        ["numpad3"] = 60,
        ["numpad4"] = 107,
        ["numpad5"] = 110,
        ["numpad6"] = 109,
        ["numpad7"] = 119,
        ["numpad8"] = 111,
        ["numpad9"] = 112,
        ["numpad+"] = 96,
        ["numpad-"] = 97,
        ["numpadenter"] = 191,
        ["numpad."] = 110,
        ["f1"] = 288,
        ["f2"] = 289,
        ["f3"] = 170,
        ["f4"] = 168,
        ["f5"] = 166,
        ["f6"] = 167,
        ["f7"] = 314,
        ["f8"] = 169,
        ["f9"] = 56,
        ["f10"] = 57,
        ["a"] = 34,
        ["b"] = 29,
        ["c"] = 26,
        ["d"] = 30,
        ["e"] = 46,
        ["f"] = 49,
        ["g"] = 47,
        ["h"] = 74,
        ["i"] = 27,
        ["j"] = 36,
        ["k"] = 311,
        ["l"] = 182,
        ["m"] = 244,
        ["n"] = 249,
        ["o"] = 39,
        ["p"] = 199,
        ["q"] = 44,
        ["r"] = 45,
        ["s"] = 33,
        ["t"] = 245,
        ["u"] = 303,
        ["v"] = 0,
        ["w"] = 32,
        ["x"] = 73,
        ["y"] = 246,
        ["z"] = 20,
        ["mouse1"] = 24,
        ["mouse2"] = 25
    }
    local _flying_speeds = { base = 0.25, fast_multiplier = 3.0, slow_multiplier = 0.25 }

    local is_active = false
    local current_zone, all_zones, zone_index = {}, {}, 1
    local fly_speed = false
    local creator_context = nil
    local debug_preview = false
    local zone_settings = nil
    local cached_serialized = nil
    local selected_point = nil
    local return_pos = nil

    local function get_key(k)
        return _keys[k] or 0
    end

    local function rot_to_dir(rot)
        local rad_x, rad_z = math.rad(rot.x), math.rad(rot.z)
        local mult = math.abs(math.cos(rad_x))
        return vector3(-math.sin(rad_z) * mult, math.cos(rad_z) * mult, math.sin(rad_x))
    end

    local function get_aim_coord()
        local cam_rot = GetGameplayCamRot(2)
        local cam_pos = GetGameplayCamCoord()
        local direction = rot_to_dir(cam_rot)
        local dest = cam_pos + (direction * 300.0)
        local ray = StartShapeTestRay(cam_pos, dest, -1, PlayerPedId(), 0)
        local _, hit, end_pos = GetShapeTestResult(ray)
        return hit and end_pos or nil
    end

    local function fly_tick()
        local ped = PlayerPedId()
        local cam_rot = GetGameplayCamRot(2)

        SetEntityHeading(ped, cam_rot.z)

        DisableControlAction(0, get_key("w"))
        DisableControlAction(0, get_key("a"))
        DisableControlAction(0, get_key("s"))
        DisableControlAction(0, get_key("d"))
        DisableControlAction(0, get_key("q"))
        DisableControlAction(0, get_key("e"))
        DisableControlAction(0, get_key("leftshift"))
        DisableControlAction(0, get_key("leftcontrol"))
        DisableControlAction(0, get_key("g"))
        DisableControlAction(0, get_key("tab"))
        DisableControlAction(0, get_key("delete"))
        DisableControlAction(0, get_key("f"))
        DisableControlAction(0, get_key("x"))
        DisableControlAction(0, get_key("enter"))
        DisableControlAction(0, get_key("backspace"))

        local move_dir = vector3(0, 0, 0)
        local forward = rot_to_dir(cam_rot)
        local right = rot_to_dir(vector3(0, 0, cam_rot.z - 90))
        local up = vector3(0, 0, 1)

        if IsDisabledControlPressed(0, get_key("w")) then move_dir = move_dir + forward end
        if IsDisabledControlPressed(0, get_key("s")) then move_dir = move_dir - forward end
        if IsDisabledControlPressed(0, get_key("a")) then move_dir = move_dir - right end
        if IsDisabledControlPressed(0, get_key("d")) then move_dir = move_dir + right end
        if IsDisabledControlPressed(0, get_key("q")) then move_dir = move_dir + up end
        if IsDisabledControlPressed(0, get_key("e")) then move_dir = move_dir - up end

        fly_speed = _flying_speeds.base
        if IsDisabledControlPressed(0, get_key("leftshift")) then
            fly_speed = fly_speed * _flying_speeds.fast_multiplier
        elseif IsDisabledControlPressed(0, get_key("leftcontrol")) then
            fly_speed = fly_speed * _flying_speeds.slow_multiplier
        end

        if #(move_dir) > 0 then
            move_dir = move_dir / #(move_dir)
            SetEntityCoordsNoOffset(ped, GetEntityCoords(ped) + move_dir * fly_speed, true, true, true)
        end
    end

    local function draw_crosshair(x, y, z, size, r, g, b, a)
        local s = size or 0.3
        local h = z + 0.15
        DrawLine(x - s, y, h, x + s, y, h, r, g, b, a)
        DrawLine(x, y - s, h, x, y + s, h, r, g, b, a)
        DrawLine(x, y, h, x, y, h + s, r, g, b, a)
    end

    local function draw_text_3d(x, y, z, text)
        SetDrawOrigin(x, y, z, 0)
        SetTextFont(4)
        SetTextScale(0.35, 0.35)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(0.0, 0.0)
        ClearDrawOrigin()
    end

    local function draw_zone(points, r, g, b)
        if not points or #points == 0 then return end
        for i = 1, #points do
            local a = points[i]
            local bpt = points[i + 1] or points[1]
            if i == selected_point then
                DrawLine(a.x, a.y, a.z + 0.2, bpt.x, bpt.y, bpt.z + 0.2, 0, 255, 0, 255)
                draw_crosshair(a.x, a.y, a.z, 0.5, 0, 255, 0, 255)
                draw_text_3d(a.x, a.y, a.z + 0.5, '~g~[' .. tostring(i) .. ']~s~')
            else
                DrawLine(a.x, a.y, a.z + 0.2, bpt.x, bpt.y, bpt.z + 0.2, r, g, b, 255)
                draw_text_3d(a.x, a.y, a.z + 0.25, tostring(i))
            end
        end
    end

    local function serialize_points(points)
        local serialized = {}
        for i = 1, #points do
            serialized[i] = {
                x = points[i].x,
                y = points[i].y,
                z = points[i].z
            }
        end
        return serialized
    end

    local function send_polygon_nui_update()
        cached_serialized = serialize_points(current_zone)
        SendNUIMessage({
            action = 'updateCreatorOverlay',
            type = 'polygon',
            coordinates = cached_serialized,
            selectedPoint = selected_point
        })
    end

    local function stop_zone_creator(opts)
        if not is_active then return end

        opts = opts or {}

        local ped = PlayerPedId()
        SetEntityCollision(ped, true, true)
        if return_pos then
            SetEntityCoords(ped, return_pos.x, return_pos.y, return_pos.z, false, false, false, true)
        else
            local pos = GetEntityCoords(ped)
            local found, ground_z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, 0)
            if found then
                SetEntityCoords(ped, pos.x, pos.y, ground_z, false, false, false, false)
            end
        end
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        is_active = false
        fly_speed = false
        debug_preview = false
        zone_settings = nil
        cached_serialized = nil
        current_zone = {}
        selected_point = nil
        return_pos = nil

        SendNUIMessage({ action = 'hideCreatorOverlay' })

        local was_ui = creator_context == 'nui'
        if was_ui and not opts.silent then
            if opts.completed and opts.points then
                TriggerEvent('f5_safezones:polygonCreatorFinished', opts.points)
            else
                TriggerEvent('f5_safezones:polygonCreatorCancelled')
            end
        end

        creator_context = nil
    end

    local function start_zone_creator(context, initial_points, teleport_coords)
        if is_active then
            stop_zone_creator()
            return
        end

        creator_context = context or 'standalone'
        current_zone = initial_points or {}
        selected_point = nil
        is_active = true

        local ped = PlayerPedId()
        return_pos = GetEntityCoords(ped)
        if teleport_coords then
            SetEntityCoords(ped, teleport_coords.x, teleport_coords.y, teleport_coords.z + 1.0, false, false, false, true)
        end
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)

        if initial_points and #initial_points >= 3 then
            CreateThread(function()
                Wait(800)
                if not is_active then return end
                for i, pt in ipairs(current_zone) do
                    local found, gz = GetGroundZFor_3dCoord(pt.x, pt.y, 1000.0, false)
                    if found then
                        current_zone[i] = vector3(pt.x, pt.y, gz)
                    end
                end
                send_polygon_nui_update()
            end)
        end

        local init_coords = #current_zone > 0 and serialize_points(current_zone) or {}
        cached_serialized = #current_zone > 0 and init_coords or nil

        SendNUIMessage({
            action = 'showCreatorOverlay',
            type = 'polygon',
            coordinates = init_coords
        })

        CreateThread(function()
            while is_active do
                Wait(0)
                fly_tick()
                draw_zone(current_zone, 255, 255, 0)

                if debug_preview and #current_zone >= 3 and zone_settings and cached_serialized then
                    Safezone.Zones.RenderPreview({
                        type = 'polygon',
                        points = cached_serialized,
                        markerConfig = zone_settings.markerConfig,
                        minZ = zone_settings.minZ,
                        maxZ = zone_settings.maxZ,
                        infiniteHeight = zone_settings.infiniteHeight,
                        addRoof = zone_settings.addRoof
                    })
                end

                local aim = get_aim_coord()
                if aim then
                    if selected_point then
                        draw_crosshair(aim.x, aim.y, aim.z, 0.3, 0, 255, 0, 200)
                    else
                        draw_crosshair(aim.x, aim.y, aim.z, 0.3, 0, 200, 0, 200)
                    end
                end
            end
        end)

        CreateThread(function()
            while is_active do
                Wait(0)

                if IsDisabledControlJustPressed(0, get_key("tab")) then
                    if #current_zone > 0 then
                        if selected_point == nil then
                            selected_point = 1
                        else
                            selected_point = selected_point % #current_zone + 1
                        end
                        send_polygon_nui_update()
                    end

                elseif IsDisabledControlJustPressed(0, get_key("f")) then
                    local hit = get_aim_coord()
                    if hit then
                        if selected_point and selected_point <= #current_zone then
                            current_zone[selected_point] = hit
                        else
                            current_zone[#current_zone + 1] = hit
                            selected_point = nil
                        end
                        send_polygon_nui_update()
                    end

                elseif IsDisabledControlJustPressed(0, get_key("x")) then
                    if selected_point then
                        selected_point = nil
                        send_polygon_nui_update()
                    elseif #current_zone > 0 then
                        current_zone[#current_zone] = nil
                        send_polygon_nui_update()
                    end

                elseif IsDisabledControlJustPressed(0, get_key("delete")) then
                    if selected_point and selected_point <= #current_zone and #current_zone > 3 then
                        table.remove(current_zone, selected_point)
                        if selected_point > #current_zone then
                            selected_point = #current_zone
                        end
                        send_polygon_nui_update()
                    end

                elseif IsDisabledControlJustPressed(0, get_key("g")) then
                    debug_preview = not debug_preview

                elseif IsDisabledControlJustPressed(0, get_key("enter")) then
                    if #current_zone >= 3 then
                        if creator_context == 'nui' then
                            local serialized = serialize_points(current_zone)
                            stop_zone_creator({ completed = true, points = serialized })
                        else
                            local poly2d = {}
                            for i = 1, #current_zone do
                                poly2d[i] = vector2(current_zone[i].x, current_zone[i].y)
                            end
                            local default_name = ("zone_%d"):format(zone_index)
                            all_zones[#all_zones + 1] = { name = default_name, coords = current_zone, poly2d = poly2d }

                            TriggerEvent(_res .. ":zone_created", {
                                name = default_name,
                                zone = current_zone,
                                player = {
                                    source = GetPlayerServerId(PlayerId()),
                                    name = GetPlayerName(PlayerId())
                                }
                            })
                            print(Translate('creator_zone_saved'):format(default_name, #current_zone))

                            current_zone = {}
                            zone_index = zone_index + 1
                            selected_point = nil
                            send_polygon_nui_update()
                        end
                    else
                        print(Translate('creator_need_3_points'))
                    end

                elseif IsDisabledControlJustPressed(0, get_key("backspace")) then
                    stop_zone_creator()
                end
            end
        end)
    end

    ZoneCreator.StartFromNui = function(settings, existingPoints, teleportCoords)
        zone_settings = settings
        local points = nil
        if existingPoints and type(existingPoints) == 'table' and #existingPoints >= 3 then
            points = {}
            for i, pt in ipairs(existingPoints) do
                points[i] = vector3(tonumber(pt.x) or 0, tonumber(pt.y) or 0, tonumber(pt.z) or 0)
            end
        end
        local tp = nil
        if teleportCoords and tonumber(teleportCoords.x) and tonumber(teleportCoords.y) and tonumber(teleportCoords.z) then
            tp = { x = tonumber(teleportCoords.x), y = tonumber(teleportCoords.y), z = tonumber(teleportCoords.z) }
        end
        start_zone_creator('nui', points, tp)
    end

    ZoneCreator.IsActive = function()
        return is_active
    end

    ZoneCreator.Stop = function()
        if is_active then
            stop_zone_creator({ silent = true })
        end
    end

    RegisterNetEvent(_res .. ":create_zone", function()
        start_zone_creator('standalone')
    end)

    AddEventHandler("onResourceStop", function(res)
        if _res == res then
            stop_zone_creator({ silent = true })
        end
    end)

end
