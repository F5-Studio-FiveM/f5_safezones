Locales_es = {
    -- Core messages
    enter_safezone = "Has entrado en una zona segura. ¡No se permite la violencia!",
    exit_safezone = "Has salido de la zona segura. El PvP está habilitado.",
    debug_mode_all = "Modo depuración activado - Mostrando todas las zonas",
    debug_mode_inactive = "Modo depuración activado - Mostrando zonas inactivas",
    debug_mode_active = "Modo depuración activado - Mostrando zonas activas",
    debug_mode_single = "Modo depuración activado - Mostrando zona: %s (ID: %d)",
    debug_disabled = "Modo depuración desactivado",
    debug_zone_enabled = "Visualización de depuración activada: %s",
    debug_zone_disabled = "Visualización de depuración desactivada: %s",
    debug_zone_default = "Visualización de depuración restablecida al modo global: %s",
    coords_copied = "¡Coordenadas copiadas al portapapeles!",
    zone_created = "Zona creada: %s",
    zone_deleted = "Zona eliminada: %s",

    -- Access and permissions
    access_denied = "Acceso denegado - se requieren permisos de administrador",

    -- Zone creation errors
    invalid_zone_data = "Datos de zona proporcionados no válidos",
    zone_name_length = "El nombre de la zona debe tener entre 3 y 50 caracteres",
    zone_name_exists = "Ya existe una zona con este nombre",
    polygon_min_points = "El polígono debe tener al menos 3 puntos",
    invalid_point_coords = "Coordenadas de punto no válidas en el punto %s",
    coords_out_of_bounds = "Las coordenadas están fuera de los límites válidos del mundo",
    invalid_circle_coords = "Coordenadas de círculo proporcionadas no válidas",
    polygon_creator_finished = "Puntos del polígono capturados - reabriendo el panel de administración",
    polygon_creator_cancelled = "Creador de polígonos cancelado",
    polygon_creator_invalid = "Error al importar puntos del polígono",

    -- Circle creator
    circle_creator_finished = "Zona circular capturada - reabriendo el panel de administración",
    circle_creator_cancelled = "Creador de círculos cancelado",
    circle_creator_invalid = "Error al importar datos del círculo",

    -- Combat restrictions
    combat_disabled = "¡El combate está desactivado en las zonas seguras!",
    explosions_disabled = "¡Las explosiones están desactivadas cerca de las zonas seguras!",
    vehicle_damage_disabled = "¡El daño a vehículos está desactivado en las zonas seguras!",

    -- Collision system
    collision_mode_active = "Modo fantasma activado - Puedes atravesar vehículos",

    -- Zone management
    zone_deleted_notification = "La zona segura en la que estabas ha sido eliminada",
    invalid_zone_id = "ID de zona no válido",
    cannot_delete_config = "No se pueden eliminar las zonas de configuración",
    zone_not_found = "Zona no encontrada",
    zone_not_found_name = "Zona no encontrada: %s",
    zone_not_found_id = "Zona con ID %s no encontrada",
    zone_activation_enabled = "Zona %s activada",
    zone_activation_disabled = "Zona %s desactivada",
    zone_already_active = "La zona %s ya está activa",
    zone_already_inactive = "La zona %s ya está inactiva",
    zones_activation_all_enabled = "Todas las zonas seguras activadas",
    zones_activation_all_disabled = "Todas las zonas seguras desactivadas",
    zones_already_active = "Todas las zonas seguras ya están activas",
    zones_already_inactive = "Todas las zonas seguras ya están inactivas",
    no_zones_defined = "No hay zonas seguras disponibles",

    -- Zone blip prefix
    safezone_prefix = "Zona Segura - ",

    -- Startup messages
    startup_summary = "Configuradas: %d | Personalizadas: %d | Total: %d | Circulares: %d | Poligonales: %d",
    startup_marker_types = "Tipos de marcador: %s",
    startup_marker_types_none = "Tipos de marcador: Ninguno",
    startup_custom_loaded = "Se cargaron %d definición(es) de zona personalizada(s) desde %s",

    -- Coordinate display
    coords_current = "Posición actual:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "ACTIVADO",
    disabled = "DESACTIVADO",
    yes = "SÍ",
    no = "NO",
    unknown = "Desconocido",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~CENTRO~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zona '%s' guardada con %d puntos.",
    creator_need_3_points = "Se necesitan al menos 3 puntos para guardar la zona.",
    creator_circle_confirmed = "Zona circular confirmada - Centro: %.2f, %.2f, %.2f | Radio: %.1f m",
    creator_circle_need_center = "Establece un punto central primero (presiona F)",

    -- Creator notifications
    creator_notif_point_added = "Punto %d añadido",
    creator_notif_point_removed = "Último punto eliminado (%d restantes)",
    creator_notif_point_moved = "Punto %d movido",
    creator_notif_point_selected = "Punto %d seleccionado",
    creator_notif_point_deselected = "Punto deseleccionado",
    creator_notif_point_deleted = "Punto %d eliminado (%d restantes)",
    creator_notif_point_delete_min = "No se puede eliminar - se requieren mínimo 3 puntos",
    creator_notif_no_points = "No hay puntos para seleccionar",
    creator_notif_no_surface = "No se encontró superficie - apunta al suelo",
    creator_notif_need_3_confirm = "Se necesitan al menos 3 puntos para confirmar",
    creator_notif_debug_on = "Vista previa debug ACTIVADA",
    creator_notif_debug_off = "Vista previa debug DESACTIVADA",
    creator_notif_center_set = "Punto central establecido",
    creator_notif_center_reset = "Punto central restablecido",
    creator_notif_radius_set = "Radio establecido en %.1f m",
    creator_notif_need_center = "Primero establece el centro (F)",
}
