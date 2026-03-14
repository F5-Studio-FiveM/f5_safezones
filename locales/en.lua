Locales_en = {
    -- Core messages
    enter_safezone = "You have entered a Safe zone. No violence allowed!",
    exit_safezone = "You have left the Safe zone. PvP is now enabled.",
    debug_mode_all = "Debug mode enabled - Showing all zones",
    debug_mode_inactive = "Debug mode enabled - Showing inactive zones",
    debug_mode_active = "Debug mode enabled - Showing active zones",
    debug_mode_single = "Debug mode enabled - Showing zone: %s (ID: %d)",
    debug_disabled = "Debug mode disabled",
    debug_zone_enabled = "Debug visualization enabled: %s",
    debug_zone_disabled = "Debug visualization disabled: %s",
    debug_zone_default = "Debug visualization reset to global mode: %s",
    coords_copied = "Coordinates copied to clipboard!",
    zone_created = "Zone created: %s",
    zone_deleted = "Zone deleted: %s",

    -- Access and permissions
    access_denied = "Access denied - admin permissions required",

    -- Zone creation errors
    invalid_zone_data = "Invalid zone data provided",
    zone_name_length = "Zone name must be between 3 and 50 characters",
    zone_name_exists = "Zone with this name already exists",
    polygon_min_points = "Polygon must have at least 3 points",
    invalid_point_coords = "Invalid point coordinates at point %s",
    coords_out_of_bounds = "Coordinates are outside the valid world bounds",
    invalid_circle_coords = "Invalid circle coordinates provided",
    polygon_creator_finished = "Polygon points captured - reopening the admin panel",
    polygon_creator_cancelled = "Polygon creator cancelled",
    polygon_creator_invalid = "Failed to import polygon points",

    -- Circle creator
    circle_creator_finished = "Circle zone captured - reopening the admin panel",
    circle_creator_cancelled = "Circle creator cancelled",
    circle_creator_invalid = "Failed to import circle data",

    -- Combat restrictions
    combat_disabled = "Combat is disabled in safe zones!",
    explosions_disabled = "Explosions are disabled near safe zones!",
    vehicle_damage_disabled = "Vehicle damage is disabled in safe zones!",

    -- Collision system
    collision_mode_active = "Ghost mode activated - You can phase through vehicles",

    -- Zone management
    zone_deleted_notification = "The safezone you were in has been deleted",
    invalid_zone_id = "Invalid zone ID",
    cannot_delete_config = "Cannot delete config zones",
    zone_not_found = "Zone not found",
    zone_not_found_name = "Zone not found: %s",
    zone_not_found_id = "Zone with ID %s not found",
    zone_activation_enabled = "Zone %s activated",
    zone_activation_disabled = "Zone %s deactivated",
    zone_already_active = "Zone %s is already active",
    zone_already_inactive = "Zone %s is already inactive",
    zones_activation_all_enabled = "All safezones activated",
    zones_activation_all_disabled = "All safezones deactivated",
    zones_already_active = "All safezones are already active",
    zones_already_inactive = "All safezones are already inactive",
    no_zones_defined = "No safezones available",

    -- Zone blip prefix
    safezone_prefix = "Safe Zone - ",

    -- Startup messages
    startup_summary = "Configured: %d | Custom: %d | Total: %d | Circle: %d | Polygon: %d",
    startup_marker_types = "Marker types: %s",
    startup_marker_types_none = "Marker types: None",
    startup_custom_loaded = "Loaded %d custom zone definition(s) from %s",

    -- Coordinate display
    coords_current = "Current Position:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "ENABLED",
    disabled = "DISABLED",
    yes = "YES",
    no = "NO",
    unknown = "Unknown",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~CENTER~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Saved zone '%s' with %d points.",
    creator_need_3_points = "Need at least 3 points to save zone.",
    creator_circle_confirmed = "Circle zone confirmed - Center: %.2f, %.2f, %.2f | Radius: %.1f m",
    creator_circle_need_center = "Set a center point first (press F)",

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
