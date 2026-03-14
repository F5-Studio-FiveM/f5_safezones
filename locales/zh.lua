Locales_zh = {
    -- Core messages
    enter_safezone = "你已进入安全区。禁止暴力行为！",
    exit_safezone = "你已离开安全区。PvP 现已启用。",
    debug_mode_all = "调试模式已启用 - 显示所有区域",
    debug_mode_inactive = "调试模式已启用 - 显示未激活区域",
    debug_mode_active = "调试模式已启用 - 显示已激活区域",
    debug_mode_single = "调试模式已启用 - 显示区域: %s (ID: %d)",
    debug_disabled = "调试模式已禁用",
    debug_zone_enabled = "调试可视化已启用: %s",
    debug_zone_disabled = "调试可视化已禁用: %s",
    debug_zone_default = "调试可视化已重置为全局模式: %s",
    coords_copied = "坐标已复制到剪贴板！",
    zone_created = "区域已创建: %s",
    zone_deleted = "区域已删除: %s",

    -- Access and permissions
    access_denied = "访问被拒绝 - 需要管理员权限",

    -- Zone creation errors
    invalid_zone_data = "提供的区域数据无效",
    zone_name_length = "区域名称必须在 3 到 50 个字符之间",
    zone_name_exists = "已存在同名区域",
    polygon_min_points = "多边形必须至少有 3 个点",
    invalid_point_coords = "第 %s 点的坐标无效",
    coords_out_of_bounds = "坐标超出有效世界范围",
    invalid_circle_coords = "提供的圆形坐标无效",
    polygon_creator_finished = "多边形点已捕获 - 正在重新打开管理面板",
    polygon_creator_cancelled = "多边形创建器已取消",
    polygon_creator_invalid = "无法导入多边形点",

    -- Circle creator
    circle_creator_finished = "圆形区域已捕获 - 正在重新打开管理面板",
    circle_creator_cancelled = "圆形创建器已取消",
    circle_creator_invalid = "无法导入圆形数据",

    -- Combat restrictions
    combat_disabled = "安全区内禁止战斗！",
    explosions_disabled = "安全区附近禁止爆炸！",
    vehicle_damage_disabled = "安全区内禁止车辆损伤！",

    -- Collision system
    collision_mode_active = "幽灵模式已激活 - 你可以穿过车辆",

    -- Zone management
    zone_deleted_notification = "你所在的安全区已被删除",
    invalid_zone_id = "无效的区域 ID",
    cannot_delete_config = "无法删除配置区域",
    zone_not_found = "未找到区域",
    zone_not_found_name = "未找到区域: %s",
    zone_not_found_id = "未找到 ID 为 %s 的区域",
    zone_activation_enabled = "区域 %s 已激活",
    zone_activation_disabled = "区域 %s 已停用",
    zone_already_active = "区域 %s 已处于激活状态",
    zone_already_inactive = "区域 %s 已处于未激活状态",
    zones_activation_all_enabled = "所有安全区已激活",
    zones_activation_all_disabled = "所有安全区已停用",
    zones_already_active = "所有安全区已处于激活状态",
    zones_already_inactive = "所有安全区已处于未激活状态",
    no_zones_defined = "没有可用的安全区",

    -- Zone blip prefix
    safezone_prefix = "安全区 - ",

    -- Startup messages
    startup_summary = "已配置: %d | 自定义: %d | 总计: %d | 圆形: %d | 多边形: %d",
    startup_marker_types = "标记类型: %s",
    startup_marker_types_none = "标记类型: 无",
    startup_custom_loaded = "从 %s 加载了 %d 个自定义区域定义",

    -- Coordinate display
    coords_current = "当前位置:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "已启用",
    disabled = "已禁用",
    yes = "是",
    no = "否",
    unknown = "未知",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~中心~s~",
    creator_circle_distance_label = "~y~%.1f 米~s~",
    creator_circle_radius_label = "~y~半径: %.1f 米~s~",

    -- Creator (F8 console)
    creator_zone_saved = "已保存区域 '%s'，共 %d 个点。",
    creator_need_3_points = "至少需要 3 个点才能保存区域。",
    creator_circle_confirmed = "圆形区域已确认 - 中心: %.2f, %.2f, %.2f | 半径: %.1f 米",
    creator_circle_need_center = "请先设置中心点（按 F）",

    -- Creator notifications
    creator_notif_point_added = "Point %d added",
    creator_notif_point_removed = "Last point removed (%d remaining)",
    creator_notif_point_moved = "Point %d moved",
    creator_notif_point_selected = "Point %d selected",
    creator_notif_point_deselected = "Point deselected",
    creator_notif_point_deleted = "Point %d deleted (%d remaining)",
    creator_notif_point_delete_min = "Cannot delete - minimum 3 points required",
    creator_notif_no_points = "No points to select",
    creator_notif_no_surface = "No surface found - aim at the ground",
    creator_notif_need_3_confirm = "Need at least 3 points to confirm",
    creator_notif_debug_on = "Debug preview ON",
    creator_notif_debug_off = "Debug preview OFF",
    creator_notif_center_set = "Center point set",
    creator_notif_center_reset = "Center point reset",
    creator_notif_radius_set = "Radius set to %.1f m",
    creator_notif_need_center = "Set center point first (F)",
}
