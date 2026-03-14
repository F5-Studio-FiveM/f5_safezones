local _res = GetCurrentResourceName()
local _is_server = IsDuplicityVersion()

Safezone = Safezone or {}

if not _is_server then
    Safezone.CircleCreator = Safezone.CircleCreator or {}
    local CircleCreator = Safezone.CircleCreator

    local _keys = {
        ["enter"] = 191,
        ["escape"] = 322,
        ["backspace"] = 177,
        ["tab"] = 37,
        ["space"] = 22,
        ["delete"] = 178,
        ["leftcontrol"] = 36,
        ["leftshift"] = 21,
        ["leftalt"] = 19,
        ["f"] = 49,
        ["g"] = 47,
        ["x"] = 73,
        ["r"] = 45,
        ["q"] = 44,
        ["e"] = 46,
        ["w"] = 32,
        ["a"] = 34,
        ["s"] = 33,
        ["d"] = 30,
        ["mouse1"] = 24,
        ["mouse2"] = 25,
        ["scrollup"] = 96,
        ["scrolldown"] = 97
    }

    local _flying_speeds = { base = 0.25, fast_multiplier = 3.0, slow_multiplier = 0.25 }

    local is_active = false
    local fly_speed = false
    local creator_context = nil

    local center_point = nil
    local current_radius = 50.0
    local min_radius = 0.1
    local max_radius = 500.0
    local radius_step = 5.0

    local debug_preview = false
    local zone_settings = nil

    local center_marker_color = { r = 0, g = 255, b = 0, a = 200 }
    local radius_marker_color = { r = 0, g = 200, b = 255, a = 150 }
    local preview_line_color = { r = 255, g = 255, b = 0, a = 255 }

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
        DisableControlAction(0, get_key("f"))
        DisableControlAction(0, get_key("x"))
        DisableControlAction(0, get_key("r"))
        DisableControlAction(0, get_key("enter"))
        DisableControlAction(0, get_key("backspace"))
        DisableControlAction(0, get_key("scrollup"))
        DisableControlAction(0, get_key("scrolldown"))

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

    local function get_circle_phase()
        return center_point and 2 or 1
    end

    local function get_circle_zone_info()
        if not center_point then return nil end
        return {
            center = { x = center_point.x, y = center_point.y, z = center_point.z },
            radius = current_radius
        }
    end

    local function send_circle_nui_update()
        SendNUIMessage({
            action = 'updateCreatorOverlay',
            type = 'circle',
            phase = get_circle_phase(),
            zoneInfo = get_circle_zone_info()
        })
    end

    local function draw_circle_outline(cx, cy, cz, radius, r, g, b, a, segments)
        segments = segments or 36
        local angle_step = (2 * math.pi) / segments

        for i = 0, segments - 1 do
            local angle1 = i * angle_step
            local angle2 = (i + 1) * angle_step

            local x1 = cx + math.cos(angle1) * radius
            local y1 = cy + math.sin(angle1) * radius
            local x2 = cx + math.cos(angle2) * radius
            local y2 = cy + math.sin(angle2) * radius

            DrawLine(x1, y1, cz + 0.2, x2, y2, cz + 0.2, r, g, b, a)
        end
    end

    local function draw_radius_lines(cx, cy, cz, radius, r, g, b, a, count)
        count = count or 8
        local angle_step = (2 * math.pi) / count

        for i = 0, count - 1 do
            local angle = i * angle_step
            local ex = cx + math.cos(angle) * radius
            local ey = cy + math.sin(angle) * radius
            DrawLine(cx, cy, cz + 0.2, ex, ey, cz + 0.2, r, g, b, a)
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

    local function stop_circle_creator(opts)
        if not is_active then return end

        opts = opts or {}

        local ped = PlayerPedId()
        SetEntityCollision(ped, true, true)
        local pos = GetEntityCoords(ped)
        local found, ground_z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, 0)
        if found then
            SetEntityCoords(ped, pos.x, pos.y, ground_z, false, false, false, false)
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

        SendNUIMessage({ action = 'hideCreatorOverlay' })

        local was_ui = creator_context == 'nui'
        if was_ui and not opts.silent then
            if opts.completed and opts.center and opts.radius then
                TriggerEvent('f5_safezones:circleCreatorFinished', {
                    center = {
                        x = opts.center.x,
                        y = opts.center.y,
                        z = opts.center.z
                    },
                    radius = opts.radius
                })
            else
                TriggerEvent('f5_safezones:circleCreatorCancelled')
            end
        end

        center_point = nil
        current_radius = 50.0
        creator_context = nil
    end

    local function start_circle_creator(context, initial_center, initial_radius)
        if is_active then
            stop_circle_creator()
            return
        end

        creator_context = context or 'standalone'
        center_point = initial_center or nil
        current_radius = initial_radius or 50.0
        is_active = true

        local ped = PlayerPedId()
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)

        local initial_phase = center_point and 2 or 1
        SendNUIMessage({
            action = 'showCreatorOverlay',
            type = 'circle',
            phase = initial_phase,
            zoneInfo = center_point and get_circle_zone_info() or nil
        })

        CreateThread(function()
            while is_active do
                Wait(0)
                fly_tick()

                local aim = get_aim_coord()

                if aim then
                    if not center_point then
                        draw_crosshair(aim.x, aim.y, aim.z, 0.4,
                            center_marker_color.r, center_marker_color.g, center_marker_color.b, center_marker_color.a)
                        draw_text_3d(aim.x, aim.y, aim.z + 0.8, Translate('creator_circle_center_label'))
                    else
                        draw_crosshair(aim.x, aim.y, aim.z, 0.25,
                            preview_line_color.r, preview_line_color.g, preview_line_color.b, 200)

                        local dist = #(vector2(aim.x, aim.y) - vector2(center_point.x, center_point.y))
                        DrawLine(center_point.x, center_point.y, center_point.z + 0.2,
                            aim.x, aim.y, aim.z + 0.2,
                            preview_line_color.r, preview_line_color.g, preview_line_color.b, preview_line_color.a)
                        draw_text_3d(aim.x, aim.y, aim.z + 0.8, Translate('creator_circle_distance_label'):format(dist))
                    end
                end

                if center_point then
                    DrawMarker(1, center_point.x, center_point.y, center_point.z + 15.0,
                        0, 0, 0, 0, 0, 0, 1.0, 1.0, 30.0,
                        center_marker_color.r, center_marker_color.g, center_marker_color.b, 100,
                        false, false, 2, false, nil, nil, false)

                    draw_crosshair(center_point.x, center_point.y, center_point.z, 0.5,
                        center_marker_color.r, center_marker_color.g, center_marker_color.b, center_marker_color.a)

                    draw_circle_outline(center_point.x, center_point.y, center_point.z,
                        current_radius,
                        radius_marker_color.r, radius_marker_color.g, radius_marker_color.b, radius_marker_color.a,
                        48)

                    draw_radius_lines(center_point.x, center_point.y, center_point.z,
                        current_radius,
                        255, 255, 255, 100, 8)

                    local edge_x = center_point.x + current_radius
                    local edge_y = center_point.y
                    draw_text_3d(edge_x, edge_y, center_point.z + 1.0, Translate('creator_circle_radius_label'):format(current_radius))

                    draw_text_3d(center_point.x, center_point.y, center_point.z + 2.0, Translate('creator_circle_center_label'))

                    if debug_preview and zone_settings then
                        Safezone.Zones.RenderPreview({
                            type = 'circle',
                            center = { x = center_point.x, y = center_point.y, z = center_point.z },
                            radius = current_radius,
                            markerConfig = zone_settings.markerConfig,
                            minZ = zone_settings.minZ,
                            maxZ = zone_settings.maxZ,
                            infiniteHeight = zone_settings.infiniteHeight
                        })
                    end
                end
            end
        end)

        CreateThread(function()
            while is_active do
                Wait(0)

                if IsDisabledControlJustPressed(0, get_key("f")) and not center_point then
                    local hit = get_aim_coord()
                    if hit then
                        center_point = hit
                        send_circle_nui_update()
                    end

                elseif IsDisabledControlJustPressed(0, get_key("x")) and center_point then
                    center_point = nil
                    send_circle_nui_update()

                elseif IsDisabledControlJustPressed(0, get_key("g")) then
                    debug_preview = not debug_preview

                elseif IsDisabledControlJustPressed(0, get_key("r")) and center_point then
                    local hit = get_aim_coord()
                    if hit then
                        local dist = #(vector2(hit.x, hit.y) - vector2(center_point.x, center_point.y))
                        dist = math.max(min_radius, math.min(max_radius, dist))
                        current_radius = dist
                        send_circle_nui_update()
                    end

                elseif center_point then
                    if IsDisabledControlJustPressed(0, get_key("scrollup")) then
                        local step = radius_step
                        if IsDisabledControlPressed(0, get_key("leftshift")) then
                            step = step * 5
                        elseif IsDisabledControlPressed(0, get_key("leftcontrol")) then
                            step = step * 0.2
                        end
                        current_radius = math.min(max_radius, current_radius + step)
                        send_circle_nui_update()
                    end

                    if IsDisabledControlJustPressed(0, get_key("scrolldown")) then
                        local step = radius_step
                        if IsDisabledControlPressed(0, get_key("leftshift")) then
                            step = step * 5
                        elseif IsDisabledControlPressed(0, get_key("leftcontrol")) then
                            step = step * 0.2
                        end
                        current_radius = math.max(min_radius, current_radius - step)
                        send_circle_nui_update()
                    end
                end

                if IsDisabledControlJustPressed(0, get_key("enter")) then
                    if center_point and current_radius >= min_radius then
                        print(Translate('creator_circle_confirmed'):format(
                            center_point.x, center_point.y, center_point.z, current_radius))
                        stop_circle_creator({ completed = true, center = center_point, radius = current_radius })
                    else
                        print(Translate('creator_circle_need_center'))
                    end

                elseif IsDisabledControlJustPressed(0, get_key("backspace")) then
                    stop_circle_creator()
                end
            end
        end)
    end

    CircleCreator.Start = function(context)
        start_circle_creator(context or 'standalone')
    end

    CircleCreator.StartFromNui = function(settings, existingCenter, existingRadius)
        zone_settings = settings
        local center = nil
        if existingCenter then
            local cx = tonumber(existingCenter.x)
            local cy = tonumber(existingCenter.y)
            local cz = tonumber(existingCenter.z)
            if cx and cy and cz then
                center = vector3(cx, cy, cz)
            end
        end
        start_circle_creator('nui', center, tonumber(existingRadius) or 50.0)
    end

    CircleCreator.IsActive = function()
        return is_active
    end

    CircleCreator.Stop = function()
        if is_active then
            stop_circle_creator({ silent = true })
        end
    end

    CircleCreator.GetData = function()
        if center_point then
            return {
                center = { x = center_point.x, y = center_point.y, z = center_point.z },
                radius = current_radius
            }
        end
        return nil
    end

    RegisterNetEvent(_res .. ":create_circle_zone", function()
        start_circle_creator('standalone')
    end)

    AddEventHandler("onResourceStop", function(res)
        if _res == res then
            stop_circle_creator({ silent = true })
        end
    end)
end
