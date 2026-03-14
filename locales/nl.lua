Locales_nl = {
    -- Core messages
    enter_safezone = "Je bent een veilige zone binnengegaan. Geweld is niet toegestaan!",
    exit_safezone = "Je hebt de veilige zone verlaten. PvP is nu ingeschakeld.",
    debug_mode_all = "Debugmodus ingeschakeld - Alle zones worden weergegeven",
    debug_mode_inactive = "Debugmodus ingeschakeld - Inactieve zones worden weergegeven",
    debug_mode_active = "Debugmodus ingeschakeld - Actieve zones worden weergegeven",
    debug_mode_single = "Debugmodus ingeschakeld - Zone weergeven: %s (ID: %d)",
    debug_disabled = "Debugmodus uitgeschakeld",
    debug_zone_enabled = "Debugvisualisatie ingeschakeld: %s",
    debug_zone_disabled = "Debugvisualisatie uitgeschakeld: %s",
    debug_zone_default = "Debugvisualisatie teruggezet naar globale modus: %s",
    coords_copied = "Coördinaten gekopieerd naar klembord!",
    zone_created = "Zone aangemaakt: %s",
    zone_deleted = "Zone verwijderd: %s",

    -- Access and permissions
    access_denied = "Toegang geweigerd - beheerdersmachtigingen vereist",

    -- Zone creation errors
    invalid_zone_data = "Ongeldige zonegegevens opgegeven",
    zone_name_length = "De zonenaam moet tussen 3 en 50 tekens lang zijn",
    zone_name_exists = "Er bestaat al een zone met deze naam",
    polygon_min_points = "Een polygoon moet minstens 3 punten hebben",
    invalid_point_coords = "Ongeldige puntcoördinaten bij punt %s",
    coords_out_of_bounds = "Coördinaten liggen buiten de geldige wereldgrenzen",
    invalid_circle_coords = "Ongeldige cirkelcoördinaten opgegeven",
    polygon_creator_finished = "Polygoonpunten vastgelegd - adminpaneel wordt heropend",
    polygon_creator_cancelled = "Polygoonmaker geannuleerd",
    polygon_creator_invalid = "Kan polygoonpunten niet importeren",

    -- Circle creator
    circle_creator_finished = "Cirkelzone vastgelegd - adminpaneel wordt heropend",
    circle_creator_cancelled = "Cirkelmaker geannuleerd",
    circle_creator_invalid = "Kan cirkelgegevens niet importeren",

    -- Combat restrictions
    combat_disabled = "Gevechten zijn uitgeschakeld in veilige zones!",
    explosions_disabled = "Explosies zijn uitgeschakeld in de buurt van veilige zones!",
    vehicle_damage_disabled = "Voertuigschade is uitgeschakeld in veilige zones!",

    -- Collision system
    collision_mode_active = "Spookmodus geactiveerd - Je kunt door voertuigen heen bewegen",

    -- Zone management
    zone_deleted_notification = "De veilige zone waarin je je bevond is verwijderd",
    invalid_zone_id = "Ongeldig zone-ID",
    cannot_delete_config = "Configuratiezones kunnen niet worden verwijderd",
    zone_not_found = "Zone niet gevonden",
    zone_not_found_name = "Zone niet gevonden: %s",
    zone_not_found_id = "Zone met ID %s niet gevonden",
    zone_activation_enabled = "Zone %s geactiveerd",
    zone_activation_disabled = "Zone %s gedeactiveerd",
    zone_already_active = "Zone %s is al actief",
    zone_already_inactive = "Zone %s is al inactief",
    zones_activation_all_enabled = "Alle veilige zones geactiveerd",
    zones_activation_all_disabled = "Alle veilige zones gedeactiveerd",
    zones_already_active = "Alle veilige zones zijn al actief",
    zones_already_inactive = "Alle veilige zones zijn al inactief",
    no_zones_defined = "Geen veilige zones beschikbaar",

    -- Zone blip prefix
    safezone_prefix = "Veilige Zone - ",

    -- Startup messages
    startup_summary = "Geconfigureerd: %d | Aangepast: %d | Totaal: %d | Cirkel: %d | Polygoon: %d",
    startup_marker_types = "Markertypen: %s",
    startup_marker_types_none = "Markertypen: Geen",
    startup_custom_loaded = "%d aangepaste zonedefinitie(s) geladen uit %s",

    -- Coordinate display
    coords_current = "Huidige positie:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "INGESCHAKELD",
    disabled = "UITGESCHAKELD",
    yes = "JA",
    no = "NEE",
    unknown = "Onbekend",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~MIDDEN~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zone '%s' opgeslagen met %d punten.",
    creator_need_3_points = "Minstens 3 punten nodig om de zone op te slaan.",
    creator_circle_confirmed = "Cirkelzone bevestigd - Midden: %.2f, %.2f, %.2f | Straal: %.1f m",
    creator_circle_need_center = "Stel eerst een middelpunt in (druk op F)",

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
