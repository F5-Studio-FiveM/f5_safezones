Locales_tr = {
    -- Core messages
    enter_safezone = "Güvenli bölgeye girdiniz. Şiddet yasaktır!",
    exit_safezone = "Güvenli bölgeden ayrıldınız. PvP artık etkin.",
    debug_mode_all = "Hata ayıklama modu etkin - Tüm bölgeler gösteriliyor",
    debug_mode_inactive = "Hata ayıklama modu etkin - Etkin olmayan bölgeler gösteriliyor",
    debug_mode_active = "Hata ayıklama modu etkin - Etkin bölgeler gösteriliyor",
    debug_mode_single = "Hata ayıklama modu etkin - Bölge gösteriliyor: %s (ID: %d)",
    debug_disabled = "Hata ayıklama modu devre dışı",
    debug_zone_enabled = "Hata ayıklama görselleştirmesi etkinleştirildi: %s",
    debug_zone_disabled = "Hata ayıklama görselleştirmesi devre dışı bırakıldı: %s",
    debug_zone_default = "Hata ayıklama görselleştirmesi genel moda sıfırlandı: %s",
    coords_copied = "Koordinatlar panoya kopyalandı!",
    zone_created = "Bölge oluşturuldu: %s",
    zone_deleted = "Bölge silindi: %s",

    -- Access and permissions
    access_denied = "Erişim reddedildi - yönetici izinleri gerekli",

    -- Zone creation errors
    invalid_zone_data = "Geçersiz bölge verileri sağlandı",
    zone_name_length = "Bölge adı 3 ile 50 karakter arasında olmalıdır",
    zone_name_exists = "Bu isimde bir bölge zaten mevcut",
    polygon_min_points = "Çokgen en az 3 noktaya sahip olmalıdır",
    invalid_point_coords = "%s noktasında geçersiz nokta koordinatları",
    coords_out_of_bounds = "Koordinatlar geçerli dünya sınırları dışında",
    invalid_circle_coords = "Geçersiz daire koordinatları sağlandı",
    polygon_creator_finished = "Çokgen noktaları yakalandı - yönetici paneli yeniden açılıyor",
    polygon_creator_cancelled = "Çokgen oluşturucu iptal edildi",
    polygon_creator_invalid = "Çokgen noktaları içe aktarılamadı",

    -- Circle creator
    circle_creator_finished = "Daire bölgesi yakalandı - yönetici paneli yeniden açılıyor",
    circle_creator_cancelled = "Daire oluşturucu iptal edildi",
    circle_creator_invalid = "Daire verileri içe aktarılamadı",

    -- Combat restrictions
    combat_disabled = "Güvenli bölgelerde savaş devre dışı!",
    explosions_disabled = "Güvenli bölgeler yakınında patlamalar devre dışı!",
    vehicle_damage_disabled = "Güvenli bölgelerde araç hasarı devre dışı!",

    -- Collision system
    collision_mode_active = "Hayalet modu etkinleştirildi - Araçlardan geçebilirsiniz",

    -- Zone management
    zone_deleted_notification = "Bulunduğunuz güvenli bölge silindi",
    invalid_zone_id = "Geçersiz bölge ID'si",
    cannot_delete_config = "Yapılandırma bölgeleri silinemez",
    zone_not_found = "Bölge bulunamadı",
    zone_not_found_name = "Bölge bulunamadı: %s",
    zone_not_found_id = "ID'si %s olan bölge bulunamadı",
    zone_activation_enabled = "Bölge %s etkinleştirildi",
    zone_activation_disabled = "Bölge %s devre dışı bırakıldı",
    zone_already_active = "Bölge %s zaten etkin",
    zone_already_inactive = "Bölge %s zaten etkin değil",
    zones_activation_all_enabled = "Tüm güvenli bölgeler etkinleştirildi",
    zones_activation_all_disabled = "Tüm güvenli bölgeler devre dışı bırakıldı",
    zones_already_active = "Tüm güvenli bölgeler zaten etkin",
    zones_already_inactive = "Tüm güvenli bölgeler zaten etkin değil",
    no_zones_defined = "Kullanılabilir güvenli bölge yok",

    -- Zone blip prefix
    safezone_prefix = "Güvenli Bölge - ",

    -- Startup messages
    startup_summary = "Yapılandırılan: %d | Özel: %d | Toplam: %d | Daire: %d | Çokgen: %d",
    startup_marker_types = "İşaretçi türleri: %s",
    startup_marker_types_none = "İşaretçi türleri: Yok",
    startup_custom_loaded = "%s kaynağından %d özel bölge tanımı yüklendi",

    -- Coordinate display
    coords_current = "Mevcut konum:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "ETKİN",
    disabled = "DEVRE DIŞI",
    yes = "EVET",
    no = "HAYIR",
    unknown = "Bilinmiyor",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~MERKEZ~s~",
    creator_circle_distance_label = "~y~%.1f m~s~",
    creator_circle_radius_label = "~y~Y: %.1f m~s~",

    -- Creator (F8 console)
    creator_zone_saved = "'%s' bölgesi %d noktayla kaydedildi.",
    creator_need_3_points = "Bölgeyi kaydetmek için en az 3 nokta gerekli.",
    creator_circle_confirmed = "Daire bölgesi onaylandı - Merkez: %.2f, %.2f, %.2f | Yarıçap: %.1f m",
    creator_circle_need_center = "Önce bir merkez noktası belirleyin (F'ye basın)",

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
