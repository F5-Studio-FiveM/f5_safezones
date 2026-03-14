Locales_ar = {
    -- Core messages
    enter_safezone = "لقد دخلت منطقة آمنة. العنف ممنوع!",
    exit_safezone = "لقد غادرت المنطقة الآمنة. القتال الآن مفعّل.",
    debug_mode_all = "وضع التصحيح مفعّل - عرض جميع المناطق",
    debug_mode_inactive = "وضع التصحيح مفعّل - عرض المناطق غير النشطة",
    debug_mode_active = "وضع التصحيح مفعّل - عرض المناطق النشطة",
    debug_mode_single = "وضع التصحيح مفعّل - عرض المنطقة: %s (المعرف: %d)",
    debug_disabled = "تم تعطيل وضع التصحيح",
    debug_zone_enabled = "تم تفعيل عرض التصحيح: %s",
    debug_zone_disabled = "تم تعطيل عرض التصحيح: %s",
    debug_zone_default = "تمت إعادة عرض التصحيح إلى الوضع العام: %s",
    coords_copied = "تم نسخ الإحداثيات إلى الحافظة!",
    zone_created = "تم إنشاء المنطقة: %s",
    zone_deleted = "تم حذف المنطقة: %s",

    -- Access and permissions
    access_denied = "تم رفض الوصول - مطلوب صلاحيات المسؤول",

    -- Zone creation errors
    invalid_zone_data = "بيانات المنطقة المقدمة غير صالحة",
    zone_name_length = "يجب أن يكون اسم المنطقة بين 3 و 50 حرفًا",
    zone_name_exists = "توجد منطقة بهذا الاسم بالفعل",
    polygon_min_points = "يجب أن يحتوي المضلع على 3 نقاط على الأقل",
    invalid_point_coords = "إحداثيات غير صالحة عند النقطة %s",
    coords_out_of_bounds = "الإحداثيات خارج حدود العالم الصالحة",
    invalid_circle_coords = "إحداثيات الدائرة المقدمة غير صالحة",
    polygon_creator_finished = "تم التقاط نقاط المضلع - إعادة فتح لوحة الإدارة",
    polygon_creator_cancelled = "تم إلغاء منشئ المضلع",
    polygon_creator_invalid = "فشل في استيراد نقاط المضلع",

    -- Circle creator
    circle_creator_finished = "تم التقاط منطقة الدائرة - إعادة فتح لوحة الإدارة",
    circle_creator_cancelled = "تم إلغاء منشئ الدائرة",
    circle_creator_invalid = "فشل في استيراد بيانات الدائرة",

    -- Combat restrictions
    combat_disabled = "القتال معطّل في المناطق الآمنة!",
    explosions_disabled = "الانفجارات معطّلة بالقرب من المناطق الآمنة!",
    vehicle_damage_disabled = "أضرار المركبات معطّلة في المناطق الآمنة!",

    -- Collision system
    collision_mode_active = "تم تفعيل وضع الشبح - يمكنك المرور عبر المركبات",

    -- Zone management
    zone_deleted_notification = "تم حذف المنطقة الآمنة التي كنت فيها",
    invalid_zone_id = "معرف المنطقة غير صالح",
    cannot_delete_config = "لا يمكن حذف مناطق الإعدادات",
    zone_not_found = "المنطقة غير موجودة",
    zone_not_found_name = "المنطقة غير موجودة: %s",
    zone_not_found_id = "المنطقة ذات المعرف %s غير موجودة",
    zone_activation_enabled = "تم تفعيل المنطقة %s",
    zone_activation_disabled = "تم تعطيل المنطقة %s",
    zone_already_active = "المنطقة %s نشطة بالفعل",
    zone_already_inactive = "المنطقة %s غير نشطة بالفعل",
    zones_activation_all_enabled = "تم تفعيل جميع المناطق الآمنة",
    zones_activation_all_disabled = "تم تعطيل جميع المناطق الآمنة",
    zones_already_active = "جميع المناطق الآمنة نشطة بالفعل",
    zones_already_inactive = "جميع المناطق الآمنة غير نشطة بالفعل",
    no_zones_defined = "لا توجد مناطق آمنة متاحة",

    -- Zone blip prefix
    safezone_prefix = "منطقة آمنة - ",

    -- Startup messages
    startup_summary = "مُعدّة: %d | مخصصة: %d | الإجمالي: %d | دائرية: %d | مضلعة: %d",
    startup_marker_types = "أنواع العلامات: %s",
    startup_marker_types_none = "أنواع العلامات: لا يوجد",
    startup_custom_loaded = "تم تحميل %d تعريف(ات) منطقة مخصصة من %s",

    -- Coordinate display
    coords_current = "الموقع الحالي:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "مفعّل",
    disabled = "معطّل",
    yes = "نعم",
    no = "لا",
    unknown = "غير معروف",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~المركز~s~",
    creator_circle_distance_label = "~y~%.1f م~s~",
    creator_circle_radius_label = "~y~نق: %.1f م~s~",

    -- Creator (F8 console)
    creator_zone_saved = "تم حفظ المنطقة '%s' بعدد %d نقطة.",
    creator_need_3_points = "يلزم 3 نقاط على الأقل لحفظ المنطقة.",
    creator_circle_confirmed = "تم تأكيد منطقة الدائرة - المركز: %.2f, %.2f, %.2f | نصف القطر: %.1f م",
    creator_circle_need_center = "حدد نقطة المركز أولاً (اضغط F)",

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
