Locales_pt = {
    -- Core messages
    enter_safezone = "Você entrou em uma zona segura. Violência não é permitida!",
    exit_safezone = "Você saiu da zona segura. O PvP está ativado.",
    debug_mode_all = "Modo de depuração ativado - Mostrando todas as zonas",
    debug_mode_inactive = "Modo de depuração ativado - Mostrando zonas inativas",
    debug_mode_active = "Modo de depuração ativado - Mostrando zonas ativas",
    debug_mode_single = "Modo de depuração ativado - Mostrando zona: %s (ID: %d)",
    debug_disabled = "Modo de depuração desativado",
    debug_zone_enabled = "Visualização de depuração ativada: %s",
    debug_zone_disabled = "Visualização de depuração desativada: %s",
    debug_zone_default = "Visualização de depuração redefinida para o modo global: %s",
    coords_copied = "Coordenadas copiadas para a área de transferência!",
    zone_created = "Zona criada: %s",
    zone_deleted = "Zona excluída: %s",

    -- Access and permissions
    access_denied = "Acesso negado - permissões de administrador necessárias",

    -- Zone creation errors
    invalid_zone_data = "Dados de zona fornecidos inválidos",
    zone_name_length = "O nome da zona deve ter entre 3 e 50 caracteres",
    zone_name_exists = "Já existe uma zona com este nome",
    polygon_min_points = "O polígono deve ter pelo menos 3 pontos",
    invalid_point_coords = "Coordenadas de ponto inválidas no ponto %s",
    coords_out_of_bounds = "As coordenadas estão fora dos limites válidos do mundo",
    invalid_circle_coords = "Coordenadas de círculo fornecidas inválidas",
    polygon_creator_finished = "Pontos do polígono capturados - reabrindo o painel de administração",
    polygon_creator_cancelled = "Criador de polígono cancelado",
    polygon_creator_invalid = "Falha ao importar pontos do polígono",

    -- Circle creator
    circle_creator_finished = "Zona circular capturada - reabrindo o painel de administração",
    circle_creator_cancelled = "Criador de círculo cancelado",
    circle_creator_invalid = "Falha ao importar dados do círculo",

    -- Combat restrictions
    combat_disabled = "O combate está desativado em zonas seguras!",
    explosions_disabled = "Explosões estão desativadas perto de zonas seguras!",
    vehicle_damage_disabled = "Danos a veículos estão desativados em zonas seguras!",

    -- Collision system
    collision_mode_active = "Modo fantasma ativado - Você pode atravessar veículos",

    -- Zone management
    zone_deleted_notification = "A zona segura em que você estava foi excluída",
    invalid_zone_id = "ID de zona inválido",
    cannot_delete_config = "Não é possível excluir zonas de configuração",
    zone_not_found = "Zona não encontrada",
    zone_not_found_name = "Zona não encontrada: %s",
    zone_not_found_id = "Zona com ID %s não encontrada",
    zone_activation_enabled = "Zona %s ativada",
    zone_activation_disabled = "Zona %s desativada",
    zone_already_active = "A zona %s já está ativa",
    zone_already_inactive = "A zona %s já está inativa",
    zones_activation_all_enabled = "Todas as zonas seguras ativadas",
    zones_activation_all_disabled = "Todas as zonas seguras desativadas",
    zones_already_active = "Todas as zonas seguras já estão ativas",
    zones_already_inactive = "Todas as zonas seguras já estão inativas",
    no_zones_defined = "Nenhuma zona segura disponível",

    -- Zone blip prefix
    safezone_prefix = "Zona Segura - ",

    -- Startup messages
    startup_summary = "Configuradas: %d | Personalizadas: %d | Total: %d | Circulares: %d | Poligonais: %d",
    startup_marker_types = "Tipos de marcador: %s",
    startup_marker_types_none = "Tipos de marcador: Nenhum",
    startup_custom_loaded = "%d definição(ões) de zona personalizada(s) carregada(s) de %s",

    -- Coordinate display
    coords_current = "Posição atual:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "ATIVADO",
    disabled = "DESATIVADO",
    yes = "SIM",
    no = "NÃO",
    unknown = "Desconhecido",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~CENTRO~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~R: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "Zona '%s' salva com %d pontos.",
    creator_need_3_points = "São necessários pelo menos 3 pontos para salvar a zona.",
    creator_circle_confirmed = "Zona circular confirmada - Centro: %.2f, %.2f, %.2f | Raio: %.1f m",
    creator_circle_need_center = "Defina um ponto central primeiro (pressione F)",

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
