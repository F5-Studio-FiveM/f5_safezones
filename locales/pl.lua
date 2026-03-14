Locales_pl = {
    -- Core messages
    enter_safezone = "Wszedłeś do strefy bezpiecznej. Przemoc jest zabroniona!",
    exit_safezone = "Opuściłeś strefę bezpieczną. PvP jest teraz włączone.",
    debug_mode_all = "Tryb debugowania włączony - Wyświetlanie wszystkich stref",
    debug_mode_inactive = "Tryb debugowania włączony - Wyświetlanie nieaktywnych stref",
    debug_mode_active = "Tryb debugowania włączony - Wyświetlanie aktywnych stref",
    debug_mode_single = "Tryb debugowania włączony - Wyświetlanie strefy: %s (ID: %d)",
    debug_disabled = "Tryb debugowania wyłączony",
    debug_zone_enabled = "Wizualizacja debugowania włączona: %s",
    debug_zone_disabled = "Wizualizacja debugowania wyłączona: %s",
    debug_zone_default = "Wizualizacja debugowania zresetowana do trybu globalnego: %s",
    coords_copied = "Współrzędne skopiowane do schowka!",
    zone_created = "Strefa utworzona: %s",
    zone_deleted = "Strefa usunięta: %s",

    -- Access and permissions
    access_denied = "Brak dostępu - wymagane uprawnienia administratora",

    -- Zone creation errors
    invalid_zone_data = "Podano nieprawidłowe dane strefy",
    zone_name_length = "Nazwa strefy musi mieć od 3 do 50 znaków",
    zone_name_exists = "Strefa o tej nazwie już istnieje",
    polygon_min_points = "Wielokąt musi mieć co najmniej 3 punkty",
    invalid_point_coords = "Nieprawidłowe współrzędne w punkcie %s",
    coords_out_of_bounds = "Współrzędne są poza prawidłowymi granicami świata",
    invalid_circle_coords = "Podano nieprawidłowe współrzędne koła",
    polygon_creator_finished = "Punkty wielokąta przechwycone - ponowne otwieranie panelu admina",
    polygon_creator_cancelled = "Kreator wielokąta anulowany",
    polygon_creator_invalid = "Nie udało się zaimportować punktów wielokąta",

    -- Circle creator
    circle_creator_finished = "Strefa kołowa przechwycona - ponowne otwieranie panelu admina",
    circle_creator_cancelled = "Kreator koła anulowany",
    circle_creator_invalid = "Nie udało się zaimportować danych koła",

    -- Combat restrictions
    combat_disabled = "Walka jest wyłączona w strefach bezpiecznych!",
    explosions_disabled = "Eksplozje są wyłączone w pobliżu stref bezpiecznych!",
    vehicle_damage_disabled = "Uszkodzenia pojazdów są wyłączone w strefach bezpiecznych!",

    -- Collision system
    collision_mode_active = "Tryb ducha aktywowany - Możesz przenikać przez pojazdy",

    -- Zone management
    zone_deleted_notification = "Strefa bezpieczna, w której byłeś, została usunięta",
    invalid_zone_id = "Nieprawidłowy identyfikator strefy",
    cannot_delete_config = "Nie można usunąć stref konfiguracyjnych",
    zone_not_found = "Nie znaleziono strefy",
    zone_not_found_name = "Nie znaleziono strefy: %s",
    zone_not_found_id = "Nie znaleziono strefy o ID %s",
    zone_activation_enabled = "Strefa %s aktywowana",
    zone_activation_disabled = "Strefa %s dezaktywowana",
    zone_already_active = "Strefa %s jest już aktywna",
    zone_already_inactive = "Strefa %s jest już nieaktywna",
    zones_activation_all_enabled = "Wszystkie strefy bezpieczne aktywowane",
    zones_activation_all_disabled = "Wszystkie strefy bezpieczne dezaktywowane",
    zones_already_active = "Wszystkie strefy bezpieczne są już aktywne",
    zones_already_inactive = "Wszystkie strefy bezpieczne są już nieaktywne",
    no_zones_defined = "Brak dostępnych stref bezpiecznych",

    -- Zone blip prefix
    safezone_prefix = "Strefa Bezpieczna - ",

    -- Startup messages
    startup_summary = "Skonfigurowane: %d | Własne: %d | Łącznie: %d | Kołowe: %d | Wielokątne: %d",
    startup_marker_types = "Typy znaczników: %s",
    startup_marker_types_none = "Typy znaczników: Brak",
    startup_custom_loaded = "Załadowano %d własną(e) definicję stref z %s",

    -- Coordinate display
    coords_current = "Aktualna pozycja:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "WŁĄCZONE",
    disabled = "WYŁĄCZONE",
    yes = "TAK",
    no = "NIE",
    unknown = "Nieznane",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~ŚRODEK~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zapisano strefę '%s' z %d punktami.",
    creator_need_3_points = "Potrzeba co najmniej 3 punktów, aby zapisać strefę.",
    creator_circle_confirmed = "Strefa kołowa potwierdzona - Środek: %.2f, %.2f, %.2f | Promień: %.1f m",
    creator_circle_need_center = "Najpierw ustaw punkt środkowy (naciśnij F)",

    -- Creator notifications
    creator_notif_point_added = "Dodano punkt %d",
    creator_notif_point_removed = "Usunięto ostatni punkt (pozostało %d)",
    creator_notif_point_moved = "Przesunięto punkt %d",
    creator_notif_point_selected = "Zaznaczono punkt %d",
    creator_notif_point_deselected = "Odznaczono punkt",
    creator_notif_point_deleted = "Usunięto punkt %d (pozostało %d)",
    creator_notif_point_delete_min = "Nie można usunąć - wymagane minimum 3 punkty",
    creator_notif_no_points = "Brak punktów do zaznaczenia",
    creator_notif_no_surface = "Nie znaleziono powierzchni - celuj w ziemię",
    creator_notif_need_3_confirm = "Potrzeba co najmniej 3 punktów do potwierdzenia",
    creator_notif_debug_on = "Podgląd debug WŁĄCZONY",
    creator_notif_debug_off = "Podgląd debug WYŁĄCZONY",
    creator_notif_center_set = "Ustawiono punkt środkowy",
    creator_notif_center_reset = "Zresetowano punkt środkowy",
    creator_notif_radius_set = "Promień ustawiony na %.1f m",
    creator_notif_need_center = "Najpierw ustaw środek (F)",
}
