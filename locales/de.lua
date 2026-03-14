Locales_de = {
    -- Core messages
    enter_safezone = "Du hast eine Sicherheitszone betreten. Gewalt ist verboten!",
    exit_safezone = "Du hast die Sicherheitszone verlassen. PvP ist jetzt aktiviert.",
    debug_mode_all = "Debug-Modus aktiviert - Alle Zonen werden angezeigt",
    debug_mode_inactive = "Debug-Modus aktiviert - Inaktive Zonen werden angezeigt",
    debug_mode_active = "Debug-Modus aktiviert - Aktive Zonen werden angezeigt",
    debug_mode_single = "Debug-Modus aktiviert - Zone wird angezeigt: %s (ID: %d)",
    debug_disabled = "Debug-Modus deaktiviert",
    debug_zone_enabled = "Debug-Visualisierung aktiviert: %s",
    debug_zone_disabled = "Debug-Visualisierung deaktiviert: %s",
    debug_zone_default = "Debug-Visualisierung auf globalen Modus zurückgesetzt: %s",
    coords_copied = "Koordinaten in die Zwischenablage kopiert!",
    zone_created = "Zone erstellt: %s",
    zone_deleted = "Zone gelöscht: %s",

    -- Access and permissions
    access_denied = "Zugriff verweigert - Administratorrechte erforderlich",

    -- Zone creation errors
    invalid_zone_data = "Ungültige Zonendaten angegeben",
    zone_name_length = "Der Zonenname muss zwischen 3 und 50 Zeichen lang sein",
    zone_name_exists = "Eine Zone mit diesem Namen existiert bereits",
    polygon_min_points = "Ein Polygon muss mindestens 3 Punkte haben",
    invalid_point_coords = "Ungültige Punktkoordinaten bei Punkt %s",
    coords_out_of_bounds = "Koordinaten liegen außerhalb der gültigen Weltgrenzen",
    invalid_circle_coords = "Ungültige Kreiskoordinaten angegeben",
    polygon_creator_finished = "Polygonpunkte erfasst - Admin-Panel wird erneut geöffnet",
    polygon_creator_cancelled = "Polygon-Ersteller abgebrochen",
    polygon_creator_invalid = "Polygonpunkte konnten nicht importiert werden",

    -- Circle creator
    circle_creator_finished = "Kreiszone erfasst - Admin-Panel wird erneut geöffnet",
    circle_creator_cancelled = "Kreis-Ersteller abgebrochen",
    circle_creator_invalid = "Kreisdaten konnten nicht importiert werden",

    -- Combat restrictions
    combat_disabled = "Kampf ist in Sicherheitszonen deaktiviert!",
    explosions_disabled = "Explosionen sind in der Nähe von Sicherheitszonen deaktiviert!",
    vehicle_damage_disabled = "Fahrzeugschaden ist in Sicherheitszonen deaktiviert!",

    -- Collision system
    collision_mode_active = "Geistermodus aktiviert - Du kannst durch Fahrzeuge hindurchgehen",

    -- Zone management
    zone_deleted_notification = "Die Sicherheitszone, in der du warst, wurde gelöscht",
    invalid_zone_id = "Ungültige Zonen-ID",
    cannot_delete_config = "Konfigurationszonen können nicht gelöscht werden",
    zone_not_found = "Zone nicht gefunden",
    zone_not_found_name = "Zone nicht gefunden: %s",
    zone_not_found_id = "Zone mit ID %s nicht gefunden",
    zone_activation_enabled = "Zone %s aktiviert",
    zone_activation_disabled = "Zone %s deaktiviert",
    zone_already_active = "Zone %s ist bereits aktiv",
    zone_already_inactive = "Zone %s ist bereits inaktiv",
    zones_activation_all_enabled = "Alle Sicherheitszonen aktiviert",
    zones_activation_all_disabled = "Alle Sicherheitszonen deaktiviert",
    zones_already_active = "Alle Sicherheitszonen sind bereits aktiv",
    zones_already_inactive = "Alle Sicherheitszonen sind bereits inaktiv",
    no_zones_defined = "Keine Sicherheitszonen verfügbar",

    -- Zone blip prefix
    safezone_prefix = "Sicherheitszone - ",

    -- Startup messages
    startup_summary = "Konfiguriert: %d | Benutzerdefiniert: %d | Gesamt: %d | Kreis: %d | Polygon: %d",
    startup_marker_types = "Markertypen: %s",
    startup_marker_types_none = "Markertypen: Keine",
    startup_custom_loaded = "%d benutzerdefinierte Zonendefinition(en) aus %s geladen",

    -- Coordinate display
    coords_current = "Aktuelle Position:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "AKTIVIERT",
    disabled = "DEAKTIVIERT",
    yes = "JA",
    no = "NEIN",
    unknown = "Unbekannt",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~MITTE~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zone '%s' mit %d Punkten gespeichert.",
    creator_need_3_points = "Mindestens 3 Punkte erforderlich, um die Zone zu speichern.",
    creator_circle_confirmed = "Kreiszone bestätigt - Mitte: %.2f, %.2f, %.2f | Radius: %.1f m",
    creator_circle_need_center = "Zuerst einen Mittelpunkt setzen (F drücken)",

    -- Creator notifications
    creator_notif_point_added = "Punkt %d hinzugefügt",
    creator_notif_point_removed = "Letzter Punkt entfernt (%d übrig)",
    creator_notif_point_moved = "Punkt %d verschoben",
    creator_notif_point_selected = "Punkt %d ausgewählt",
    creator_notif_point_deselected = "Punkt abgewählt",
    creator_notif_point_deleted = "Punkt %d gelöscht (%d übrig)",
    creator_notif_point_delete_min = "Löschen nicht möglich - mindestens 3 Punkte erforderlich",
    creator_notif_no_points = "Keine Punkte zum Auswählen",
    creator_notif_no_surface = "Keine Oberfläche gefunden - auf den Boden zielen",
    creator_notif_need_3_confirm = "Mindestens 3 Punkte zum Bestätigen erforderlich",
    creator_notif_debug_on = "Debug-Vorschau AN",
    creator_notif_debug_off = "Debug-Vorschau AUS",
    creator_notif_center_set = "Mittelpunkt gesetzt",
    creator_notif_center_reset = "Mittelpunkt zurückgesetzt",
    creator_notif_radius_set = "Radius auf %.1f m gesetzt",
    creator_notif_need_center = "Zuerst Mittelpunkt setzen (F)",
}
