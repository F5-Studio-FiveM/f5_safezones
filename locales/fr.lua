Locales_fr = {
    -- Core messages
    enter_safezone = "Vous êtes entré dans une zone sécurisée. La violence est interdite !",
    exit_safezone = "Vous avez quitté la zone sécurisée. Le PvP est maintenant activé.",
    debug_mode_all = "Mode débogage activé - Affichage de toutes les zones",
    debug_mode_inactive = "Mode débogage activé - Affichage des zones inactives",
    debug_mode_active = "Mode débogage activé - Affichage des zones actives",
    debug_mode_single = "Mode débogage activé - Affichage de la zone : %s (ID : %d)",
    debug_disabled = "Mode débogage désactivé",
    debug_zone_enabled = "Visualisation de débogage activée : %s",
    debug_zone_disabled = "Visualisation de débogage désactivée : %s",
    debug_zone_default = "Visualisation de débogage réinitialisée au mode global : %s",
    coords_copied = "Coordonnées copiées dans le presse-papiers !",
    zone_created = "Zone créée : %s",
    zone_deleted = "Zone supprimée : %s",

    -- Access and permissions
    access_denied = "Accès refusé - permissions administrateur requises",

    -- Zone creation errors
    invalid_zone_data = "Données de zone fournies invalides",
    zone_name_length = "Le nom de la zone doit contenir entre 3 et 50 caractères",
    zone_name_exists = "Une zone avec ce nom existe déjà",
    polygon_min_points = "Le polygone doit avoir au moins 3 points",
    invalid_point_coords = "Coordonnées de point invalides au point %s",
    coords_out_of_bounds = "Les coordonnées sont en dehors des limites valides du monde",
    invalid_circle_coords = "Coordonnées de cercle fournies invalides",
    polygon_creator_finished = "Points du polygone capturés - réouverture du panneau d'administration",
    polygon_creator_cancelled = "Créateur de polygone annulé",
    polygon_creator_invalid = "Échec de l'importation des points du polygone",

    -- Circle creator
    circle_creator_finished = "Zone circulaire capturée - réouverture du panneau d'administration",
    circle_creator_cancelled = "Créateur de cercle annulé",
    circle_creator_invalid = "Échec de l'importation des données du cercle",

    -- Combat restrictions
    combat_disabled = "Le combat est désactivé dans les zones sécurisées !",
    explosions_disabled = "Les explosions sont désactivées près des zones sécurisées !",
    vehicle_damage_disabled = "Les dégâts aux véhicules sont désactivés dans les zones sécurisées !",

    -- Collision system
    collision_mode_active = "Mode fantôme activé - Vous pouvez traverser les véhicules",

    -- Zone management
    zone_deleted_notification = "La zone sécurisée dans laquelle vous étiez a été supprimée",
    invalid_zone_id = "ID de zone invalide",
    cannot_delete_config = "Impossible de supprimer les zones de configuration",
    zone_not_found = "Zone introuvable",
    zone_not_found_name = "Zone introuvable : %s",
    zone_not_found_id = "Zone avec l'ID %s introuvable",
    zone_activation_enabled = "Zone %s activée",
    zone_activation_disabled = "Zone %s désactivée",
    zone_already_active = "La zone %s est déjà active",
    zone_already_inactive = "La zone %s est déjà inactive",
    zones_activation_all_enabled = "Toutes les zones sécurisées activées",
    zones_activation_all_disabled = "Toutes les zones sécurisées désactivées",
    zones_already_active = "Toutes les zones sécurisées sont déjà actives",
    zones_already_inactive = "Toutes les zones sécurisées sont déjà inactives",
    no_zones_defined = "Aucune zone sécurisée disponible",

    -- Zone blip prefix
    safezone_prefix = "Zone Sécurisée - ",

    -- Startup messages
    startup_summary = "Configurées : %d | Personnalisées : %d | Total : %d | Cercle : %d | Polygone : %d",
    startup_marker_types = "Types de marqueurs : %s",
    startup_marker_types_none = "Types de marqueurs : Aucun",
    startup_custom_loaded = "%d définition(s) de zone personnalisée(s) chargée(s) depuis %s",

    -- Coordinate display
    coords_current = "Position actuelle :",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "ACTIVÉ",
    disabled = "DÉSACTIVÉ",
    yes = "OUI",
    no = "NON",
    unknown = "Inconnu",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~CENTRE~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R : %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zone '%s' sauvegardée avec %d points.",
    creator_need_3_points = "Au moins 3 points sont nécessaires pour sauvegarder la zone.",
    creator_circle_confirmed = "Zone circulaire confirmée - Centre : %.2f, %.2f, %.2f | Rayon : %.1f m",
    creator_circle_need_center = "Définissez d'abord un point central (appuyez sur F)",

    -- Creator notifications
    creator_notif_point_added = "Point %d ajouté",
    creator_notif_point_removed = "Dernier point supprimé (%d restants)",
    creator_notif_point_moved = "Point %d déplacé",
    creator_notif_point_selected = "Point %d sélectionné",
    creator_notif_point_deselected = "Point désélectionné",
    creator_notif_point_deleted = "Point %d supprimé (%d restants)",
    creator_notif_point_delete_min = "Impossible de supprimer - minimum 3 points requis",
    creator_notif_no_points = "Aucun point à sélectionner",
    creator_notif_no_surface = "Aucune surface trouvée - visez le sol",
    creator_notif_need_3_confirm = "Au moins 3 points nécessaires pour confirmer",
    creator_notif_debug_on = "Aperçu debug ACTIVÉ",
    creator_notif_debug_off = "Aperçu debug DÉSACTIVÉ",
    creator_notif_center_set = "Point central défini",
    creator_notif_center_reset = "Point central réinitialisé",
    creator_notif_radius_set = "Rayon défini à %.1f m",
    creator_notif_need_center = "D'abord définir le centre (F)",
}
