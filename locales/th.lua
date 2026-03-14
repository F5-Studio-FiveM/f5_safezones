Locales_th = {
    -- Core messages
    enter_safezone = "คุณได้เข้าสู่เขตปลอดภัย ห้ามใช้ความรุนแรง!",
    exit_safezone = "คุณได้ออกจากเขตปลอดภัย PvP เปิดใช้งานแล้ว",
    debug_mode_all = "เปิดโหมดดีบัก - แสดงโซนทั้งหมด",
    debug_mode_inactive = "เปิดโหมดดีบัก - แสดงโซนที่ไม่ได้ใช้งาน",
    debug_mode_active = "เปิดโหมดดีบัก - แสดงโซนที่ใช้งานอยู่",
    debug_mode_single = "เปิดโหมดดีบัก - แสดงโซน: %s (ID: %d)",
    debug_disabled = "ปิดโหมดดีบัก",
    debug_zone_enabled = "เปิดการแสดงผลดีบัก: %s",
    debug_zone_disabled = "ปิดการแสดงผลดีบัก: %s",
    debug_zone_default = "รีเซ็ตการแสดงผลดีบักเป็นโหมดทั่วไป: %s",
    coords_copied = "คัดลอกพิกัดไปยังคลิปบอร์ดแล้ว!",
    zone_created = "สร้างโซนแล้ว: %s",
    zone_deleted = "ลบโซนแล้ว: %s",

    -- Access and permissions
    access_denied = "การเข้าถึงถูกปฏิเสธ - ต้องการสิทธิ์ผู้ดูแลระบบ",

    -- Zone creation errors
    invalid_zone_data = "ข้อมูลโซนที่ให้มาไม่ถูกต้อง",
    zone_name_length = "ชื่อโซนต้องมีความยาวระหว่าง 3 ถึง 50 ตัวอักษร",
    zone_name_exists = "มีโซนที่ใช้ชื่อนี้อยู่แล้ว",
    polygon_min_points = "รูปหลายเหลี่ยมต้องมีอย่างน้อย 3 จุด",
    invalid_point_coords = "พิกัดจุดไม่ถูกต้องที่จุด %s",
    coords_out_of_bounds = "พิกัดอยู่นอกขอบเขตโลกที่ถูกต้อง",
    invalid_circle_coords = "พิกัดวงกลมที่ให้มาไม่ถูกต้อง",
    polygon_creator_finished = "จับจุดรูปหลายเหลี่ยมแล้ว - กำลังเปิดแผงผู้ดูแลอีกครั้ง",
    polygon_creator_cancelled = "ยกเลิกตัวสร้างรูปหลายเหลี่ยม",
    polygon_creator_invalid = "ไม่สามารถนำเข้าจุดรูปหลายเหลี่ยมได้",

    -- Circle creator
    circle_creator_finished = "จับโซนวงกลมแล้ว - กำลังเปิดแผงผู้ดูแลอีกครั้ง",
    circle_creator_cancelled = "ยกเลิกตัวสร้างวงกลม",
    circle_creator_invalid = "ไม่สามารถนำเข้าข้อมูลวงกลมได้",

    -- Combat restrictions
    combat_disabled = "การต่อสู้ถูกปิดใช้งานในเขตปลอดภัย!",
    explosions_disabled = "การระเบิดถูกปิดใช้งานใกล้เขตปลอดภัย!",
    vehicle_damage_disabled = "ความเสียหายของยานพาหนะถูกปิดใช้งานในเขตปลอดภัย!",

    -- Collision system
    collision_mode_active = "เปิดโหมดผี - คุณสามารถทะลุผ่านยานพาหนะได้",

    -- Zone management
    zone_deleted_notification = "เขตปลอดภัยที่คุณอยู่ถูกลบแล้ว",
    invalid_zone_id = "ID โซนไม่ถูกต้อง",
    cannot_delete_config = "ไม่สามารถลบโซนการกำหนดค่าได้",
    zone_not_found = "ไม่พบโซน",
    zone_not_found_name = "ไม่พบโซน: %s",
    zone_not_found_id = "ไม่พบโซนที่มี ID %s",
    zone_activation_enabled = "เปิดใช้งานโซน %s แล้ว",
    zone_activation_disabled = "ปิดใช้งานโซน %s แล้ว",
    zone_already_active = "โซน %s เปิดใช้งานอยู่แล้ว",
    zone_already_inactive = "โซน %s ปิดใช้งานอยู่แล้ว",
    zones_activation_all_enabled = "เปิดใช้งานเขตปลอดภัยทั้งหมดแล้ว",
    zones_activation_all_disabled = "ปิดใช้งานเขตปลอดภัยทั้งหมดแล้ว",
    zones_already_active = "เขตปลอดภัยทั้งหมดเปิดใช้งานอยู่แล้ว",
    zones_already_inactive = "เขตปลอดภัยทั้งหมดปิดใช้งานอยู่แล้ว",
    no_zones_defined = "ไม่มีเขตปลอดภัยที่พร้อมใช้งาน",

    -- Zone blip prefix
    safezone_prefix = "เขตปลอดภัย - ",

    -- Startup messages
    startup_summary = "กำหนดค่า: %d | กำหนดเอง: %d | ทั้งหมด: %d | วงกลม: %d | หลายเหลี่ยม: %d",
    startup_marker_types = "ประเภทเครื่องหมาย: %s",
    startup_marker_types_none = "ประเภทเครื่องหมาย: ไม่มี",
    startup_custom_loaded = "โหลด %d คำจำกัดความโซนที่กำหนดเองจาก %s",

    -- Coordinate display
    coords_current = "ตำแหน่งปัจจุบัน:",
    coords_display = "X: %.2f, Y: %.2f, Z: %.2f, H: %.2f",
    coords_lua = "vector4(%.2f, %.2f, %.2f, %.2f)",
    coords_json = '{"x": %.2f, "y": %.2f, "z": %.2f, "h": %.2f}',

    -- Status messages
    enabled = "เปิดใช้งาน",
    disabled = "ปิดใช้งาน",
    yes = "ใช่",
    no = "ไม่",
    unknown = "ไม่ทราบ",

    -- Creator (3D world labels)
    creator_circle_center_label = "~g~จุดศูนย์กลาง~s~",
    creator_circle_distance_label = "~y~%.1f ม.~s~",
    creator_circle_radius_label = "~y~ร: %.1f ม.~s~",

    -- Creator (F8 console)
    creator_zone_saved = "บันทึกโซน '%s' ด้วย %d จุด",
    creator_need_3_points = "ต้องมีอย่างน้อย 3 จุดเพื่อบันทึกโซน",
    creator_circle_confirmed = "ยืนยันโซนวงกลม - จุดศูนย์กลาง: %.2f, %.2f, %.2f | รัศมี: %.1f ม.",
    creator_circle_need_center = "ตั้งจุดศูนย์กลางก่อน (กด F)",

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
