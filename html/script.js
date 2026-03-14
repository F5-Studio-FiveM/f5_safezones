'use strict';

window.resourceName = window.resourceName || 'f5_safezones';

const SZ = {
    selectedLanguage: "en",
    Locales: {},

    state: {
        zones: [],
        players: [],
        selectedZone: null,
        currentView: 'zones',
        searchQuery: '',
        mapLoaded: false,
        zoneCreationType: 'circle',
        polygonCreationMode: 'manual',
        circleCreationMode: 'manual',
        currentFilter: 'all',
        isCreatingZone: false,
        isEditingZone: false,
        editingZone: null,
        pendingEditContext: null,
        debugEnabled: false,
        debugMode: 'all',
        singleZoneId: null,
        zoneDebugStates: {},
        logs: [],
        logMeta: {
            categories: {},
            actions: {},
            retentionDays: 7,
            ui: {}
        },
        logFilters: {
            search: '',
            category: 'all',
            action: 'all',
            admin: 'all',
            outcome: 'all',
            from: '',
            to: ''
        }
    },

    mapState: {
        canvas: null,
        ctx: null,
        images: {},
        currentStyle: 'atlas',
        zoom: 1,
        minZoom: 0.5,
        maxZoom: 8,
        offsetX: 0,
        offsetY: 0,
        isDragging: false,
        dragStartX: 0,
        dragStartY: 0,
        hoveredZone: null,
        measureMode: false,
        measurePoints: [],
        showGrid: false,
        animationFrame: null,
        highlightedZone: null,
        allImagesLoaded: false,
        loadingProgress: 0,
        prerenderedMaps: {},
        imageLoadStates: {
            atlas: { loaded: false, progress: 0 },
            road: { loaded: false, progress: 0 },
            satellite: { loaded: false, progress: 0 }
        }
    },

    confirmState: {
        resolve: null
    },

    GAME_BOUNDS: {
        minX: -5665,
        maxX: 6690,
        minY: -4055,
        maxY: 8425
    },

    MAP_SIZE: 8192,
    ZOOM_SPEED: 0.1,
    DEBOUNCE_DELAY: 300,
    THROTTLE_DELAY: 16,

    elements: {}
};

SZ.logging = {
    enabled: true,
    categories: {
        INIT:   true,
        UI:     true,
        NUI:    true,
        MAP:    false,
        ZONE:   true,
        DATA:   true,
        LOCALE: true,
        BLIP:   false
    },
    levels: {
        info:  true,
        warn:  true,
        error: true
    },
    maxEntries: 200,
    history: []
};


function Log(category, level, ...args) {
    const cfg = SZ.logging;
    if (!cfg.enabled) return;

    category = (category || 'GENERAL').toUpperCase();
    level    = (level || 'info').toLowerCase();

    if (cfg.categories[category] === false) return;
    if (cfg.levels[level] === false) return;

    const timestamp = new Date().toISOString();
    const prefix    = `[${timestamp}] [${category}] [${level.toUpperCase()}]`;

    const consoleFn = level === 'error' ? console.error
                    : level === 'warn'  ? console.warn
                    : console.log;

    consoleFn(prefix, ...args);

    const entry = { timestamp, category, level, message: args.map(a => {
        if (a instanceof Error) return a.message;
        if (typeof a === 'object') { try { return JSON.stringify(a); } catch { return String(a); } }
        return String(a);
    }).join(' ') };

    cfg.history.push(entry);
    if (cfg.history.length > cfg.maxEntries) {
        cfg.history.shift();
    }
}


function LogSeparator(label) {
    if (!SZ.logging.enabled) return;
    const line = '—'.repeat(40);
    if (label) {
        console.log(`${line} ${label} ${line}`);
    } else {
        console.log(line + line);
    }
}


function LogBlock(category, level, header, data) {
    const cfg = SZ.logging;
    if (!cfg.enabled) return;

    category = (category || 'GENERAL').toUpperCase();
    level    = (level || 'info').toLowerCase();

    if (cfg.categories[category] === false) return;
    if (cfg.levels[level] === false) return;

    const timestamp = new Date().toISOString();
    const consoleFn = level === 'error' ? console.error
                    : level === 'warn'  ? console.warn
                    : console.log;

    consoleFn(`[${timestamp}] [${category}] [${level.toUpperCase()}] === ${header} ===`);
    if (data && typeof data === 'object') {
        for (const [key, value] of Object.entries(data)) {
            consoleFn(`  ${key}: ${typeof value === 'object' ? JSON.stringify(value) : value}`);
        }
    }
}

const DEBUG_MODES = ['all', 'inactive', 'active', 'single'];

const BLIP_IMAGE_DATA = {
    0:'radar_higher.gif',1:'radar_level.png',2:'radar_lower.gif',3:'radar_police_ped.gif',4:'radar_wanted_radius.png',5:'radar_area_blip.png',6:'radar_centre.png',7:'radar_north.png',8:'radar_waypoint.png',9:'radar_radius_blip.png',10:'radar_radius_outline_blip.png',11:'radar_weapon_higher.gif',12:'radar_weapon_lower.gif',13:'radar_higher_ai.gif',14:'radar_lower_ai.gif',15:'radar_police_heli_spin.gif',16:'radar_police_plane_move.png',27:'radar_mp_crew.png',28:'radar_mp_friendlies.png',36:'radar_cable_car.png',37:'radar_activities.png',38:'radar_raceflag.png',40:'radar_safehouse.png',41:'radar_police.gif',42:'radar_police_chase.gif',43:'radar_police_heli.png',44:'radar_bomb_a.png',47:'radar_snitch.png',48:'radar_planning_locations.png',50:'radar_crim_carsteal.png',51:'radar_crim_drugs.png',52:'radar_crim_holdups.png',54:'radar_crim_player.png',56:'radar_cop_patrol.png',57:'radar_cop_player.png',58:'radar_crim_wanted.png',59:'radar_heist.png',60:'radar_police_station.png',61:'radar_hospital.png',62:'radar_assassins_mark.png',63:'radar_elevator.png',64:'radar_helicopter.png',66:'radar_random_character.png',67:'radar_security_van.png',68:'radar_tow_truck.png',70:'radar_illegal_parking.png',71:'radar_barber.png',72:'radar_car_mod_shop.png',73:'radar_clothes_store.png',75:'radar_tattoo.png',76:'radar_armenian_family.png',77:'radar_lester_family.png',78:'radar_michael_family.png',79:'radar_trevor_family.png',80:'radar_jewelry_heist.png',82:'radar_drag_race_finish.png',84:'radar_rampage.png',85:'radar_vinewood_tours.png',86:'radar_lamar_family.png',88:'radar_franklin_family.png',89:'radar_chinese_strand.png',90:'radar_flight_school.png',91:'radar_eye_sky.png',92:'radar_air_hockey.png',93:'radar_bar.png',94:'radar_base_jump.png',95:'radar_basketball.png',96:'radar_biolab_heist.png',99:'radar_cabaret_club.png',100:'radar_car_wash.png',102:'radar_comedy_club.png',103:'radar_darts.png',104:'radar_docks_heist.png',105:'radar_fbi_heist.png',106:'radar_fbi_officers_strand.png',107:'radar_finale_bank_heist.png',108:'radar_financier_strand.png',109:'radar_golf.png',110:'radar_gun_shop.png',111:'radar_internet_cafe.png',112:'radar_michael_family_exile.png',113:'radar_nice_house_heist.png',114:'radar_random_female.png',115:'radar_random_male.png',118:'radar_rural_bank_heist.png',119:'radar_shooting_range.png',120:'radar_solomon_strand.png',121:'radar_strip_club.png',122:'radar_tennis.png',123:'radar_trevor_family_exile.png',124:'radar_michael_trevor_family.png',126:'radar_triathlon.png',127:'radar_off_road_racing.png',128:'radar_gang_cops.png',129:'radar_gang_mexicans.png',130:'radar_gang_bikers.png',133:'radar_snitch_red.png',134:'radar_crim_cuff_keys.png',135:'radar_cinema.png',136:'radar_music_venue.png',137:'radar_police_station_blue.png',138:'radar_airport.png',139:'radar_crim_saved_vehicle.png',140:'radar_weed_stash.png',141:'radar_hunting.png',142:'radar_pool.png',143:'radar_objective_blue.png',144:'radar_objective_green.png',145:'radar_objective_red.png',146:'radar_objective_yellow.png',147:'radar_arms_dealing.png',148:'radar_mp_friend.png',149:'radar_celebrity_theft.png',150:'radar_weapon_assault_rifle.png',151:'radar_weapon_bat.png',152:'radar_weapon_grenade.png',153:'radar_weapon_health.png',154:'radar_weapon_knife.png',155:'radar_weapon_molotov.png',156:'radar_weapon_pistol.png',157:'radar_weapon_rocket.png',158:'radar_weapon_shotgun.png',159:'radar_weapon_smg.png',160:'radar_weapon_sniper.png',161:'radar_mp_noise.gif',162:'radar_poi.png',163:'radar_passive.png',164:'radar_usingmenu.png',171:'radar_gang_cops_partner.png',173:'radar_weapon_minigun.png',175:'radar_weapon_armour.png',176:'radar_property_takeover.png',177:'radar_gang_mexicans_highlight.png',178:'radar_gang_bikers_highlight.png',179:'radar_triathlon_cycling.png',180:'radar_triathlon_swimming.png',181:'radar_property_takeover_bikers.png',182:'radar_property_takeover_cops.png',183:'radar_property_takeover_vagos.png',184:'radar_camera.png',185:'radar_centre_red.png',186:'radar_handcuff_keys_bikers.png',187:'radar_handcuff_keys_vagos.png',188:'radar_handcuffs_closed_bikers.png',189:'radar_handcuffs_closed_vagos.png',192:'radar_camera_badger.png',193:'radar_camera_facade.png',194:'radar_camera_ifruit.png',197:'radar_yoga.png',198:'radar_taxi.png',205:'radar_shrink.png',206:'radar_epsilon.png',207:'radar_financier_strand_grey.png',208:'radar_trevor_family_grey.png',209:'radar_trevor_family_red.png',210:'radar_franklin_family_grey.png',211:'radar_franklin_family_blue.png',212:'radar_franklin_a.png',213:'radar_franklin_b.png',214:'radar_franklin_c.png',225:'radar_gang_vehicle.png',226:'radar_gang_vehicle_bikers.png',227:'radar_gang_vehicle_cops.png',228:'radar_gang_vehicle_vagos.png',229:'radar_guncar.png',230:'radar_driving_bikers.png',231:'radar_driving_cops.png',232:'radar_driving_vagos.png',233:'radar_gang_cops_highlight.png',234:'radar_shield_bikers.png',235:'radar_shield_cops.png',236:'radar_shield_vagos.png',237:'radar_custody_bikers.png',238:'radar_custody_vagos.png',251:'radar_arms_dealing_air.png',252:'radar_playerstate_arrested.png',253:'radar_playerstate_custody.png',254:'radar_playerstate_driving.png',255:'radar_playerstate_keyholder.png',256:'radar_playerstate_partner.png',262:'radar_ztype.png',263:'radar_stinger.png',264:'radar_packer.png',265:'radar_monroe.png',266:'radar_fairground.png',267:'radar_property.png',268:'radar_gang_highlight.png',269:'radar_altruist.png',270:'radar_ai.png',271:'radar_on_mission.png',272:'radar_cash_pickup.png',273:'radar_chop.png',274:'radar_dead.png',275:'radar_territory_locked.png',276:'radar_cash_lost.png',277:'radar_cash_vagos.png',278:'radar_cash_cops.png',279:'radar_hooker.png',280:'radar_friend.png',281:'radar_mission_2to4.png',282:'radar_mission_2to8.png',283:'radar_mission_2to12.png',284:'radar_mission_2to16.png',285:'radar_custody_dropoff.png',286:'radar_onmission_cops.png',287:'radar_onmission_lost.png',288:'radar_onmission_vagos.png',289:'radar_crim_carsteal_cops.png',290:'radar_crim_carsteal_bikers.png',291:'radar_crim_carsteal_vagos.png',292:'radar_band_strand.png',293:'radar_simeon_family.png',294:'radar_mission_1.png',295:'radar_mission_2.png',296:'radar_friend_darts.png',297:'radar_friend_comedyclub.png',298:'radar_friend_cinema.png',299:'radar_friend_tennis.png',300:'radar_friend_stripclub.png',301:'radar_friend_livemusic.png',302:'radar_friend_golf.png',303:'radar_bounty_hit.png',304:'radar_ugc_mission.png',305:'radar_horde.png',306:'radar_cratedrop.png',307:'radar_plane_drop.png',308:'radar_sub.png',309:'radar_race.png',310:'radar_deathmatch.png',311:'radar_arm_wrestling.png',312:'radar_mission_1to2.png',313:'radar_shootingrange_gunshop.png',314:'radar_race_air.png',315:'radar_race_land.png',316:'radar_race_sea.png',317:'radar_tow.png',318:'radar_garbage.png',319:'radar_drill.png',320:'radar_spikes.png',321:'radar_firetruck.png',322:'radar_minigun2.png',323:'radar_bugstar.png',324:'radar_submarine.png',325:'radar_chinook.png',326:'radar_getaway_car.png',327:'radar_mission_bikers_1.png',328:'radar_mission_bikers_1to2.png',329:'radar_mission_bikers_2.png',330:'radar_mission_bikers_2to4.png',331:'radar_mission_bikers_2to8.png',332:'radar_mission_bikers_2to12.png',333:'radar_mission_bikers_2to16.png',334:'radar_mission_cops_1.png',335:'radar_mission_cops_1to2.png',336:'radar_mission_cops_2.png',337:'radar_mission_cops_2to4.png',338:'radar_mission_cops_2to8.png',339:'radar_mission_cops_2to12.png',340:'radar_mission_cops_2to16.png',341:'radar_mission_vagos_1.png',342:'radar_mission_vagos_1to2.png',343:'radar_mission_vagos_2.png',344:'radar_mission_vagos_2to4.png',345:'radar_mission_vagos_2to8.png',346:'radar_mission_vagos_2to12.png',347:'radar_mission_vagos_2to16.png',348:'radar_gang_bike.png',349:'radar_gas_grenade.png',350:'radar_property_for_sale.png',351:'radar_gang_attack_package.png',352:'radar_martin_madrazzo.png',353:'radar_enemy_heli_spin.gif',354:'radar_boost.png',355:'radar_devin.png',356:'radar_dock.png',357:'radar_garage.png',358:'radar_golf_flag.png',359:'radar_hangar.png',360:'radar_helipad.png',361:'radar_jerry_can.png',362:'radar_mask.png',363:'radar_heist_prep.png',364:'radar_incapacitated.png',365:'radar_spawn_point_pickup.png',366:'radar_boilersuit.png',367:'radar_completed.png',368:'radar_rockets.png',369:'radar_garage_for_sale.png',370:'radar_helipad_for_sale.png',371:'radar_dock_for_sale.png',372:'radar_hangar_for_sale.png',373:'radar_placeholder_6.png',374:'radar_business.png',375:'radar_business_for_sale.png',376:'radar_race_bike.png',377:'radar_parachute.png',378:'radar_team_deathmatch.png',379:'radar_race_foot.png',380:'radar_vehicle_deathmatch.png',381:'radar_barry.png',382:'radar_dom.png',383:'radar_maryann.png',384:'radar_cletus.png',385:'radar_josh.png',386:'radar_minute.png',387:'radar_omega.png',388:'radar_tonya.png',389:'radar_paparazzo.png',390:'radar_aim.png',391:'radar_cratedrop_background.png',392:'radar_green_and_net_player1.png',393:'radar_green_and_net_player2.png',394:'radar_green_and_net_player3.png',395:'radar_green_and_friendly.png',396:'radar_net_player1_and_net_player2.png',397:'radar_net_player1_and_net_player3.png',398:'radar_creator.png',399:'radar_creator_direction.png',400:'radar_abigail.png',401:'radar_blimp.png',402:'radar_repair.png',403:'radar_testosterone.png',404:'radar_dinghy.png',405:'radar_fanatic.png',407:'radar_info_icon.png',408:'radar_capture_the_flag.png',409:'radar_last_team_standing.png',410:'radar_boat.png',411:'radar_capture_the_flag_base.png',412:'radar_mp_crew.png',413:'radar_capture_the_flag_outline.png',414:'radar_capture_the_flag_base_nobag.png',415:'radar_weapon_jerrycan.png',416:'radar_rp.png',417:'radar_level_inside.png',418:'radar_bounty_hit_inside.png',419:'radar_capture_the_usaflag.png',420:'radar_capture_the_usaflag_outline.png',421:'radar_tank.png',422:'radar_player_heli.gif',423:'radar_player_plane.png',424:'radar_player_jet.png',425:'radar_centre_stroke.png',426:'radar_player_guncar.png',427:'radar_player_boat.png',428:'radar_mp_heist.png',429:'radar_temp_1.png',430:'radar_temp_2.png',431:'radar_temp_3.png',432:'radar_temp_4.png',433:'radar_temp_5.png',434:'radar_temp_6.png',435:'radar_race_stunt.png',436:'radar_hot_property.png',437:'radar_urbanwarfare_versus.png',438:'radar_king_of_the_castle.png',439:'radar_player_king.png',440:'radar_dead_drop.png',441:'radar_penned_in.png',442:'radar_beast.png',443:'radar_edge_pointer.png',444:'radar_edge_crosstheline.png',445:'radar_mp_lamar.png',446:'radar_bennys.png',447:'radar_corner_number_1.png',448:'radar_corner_number_2.png',449:'radar_corner_number_3.png',450:'radar_corner_number_4.png',451:'radar_corner_number_5.png',452:'radar_corner_number_6.png',453:'radar_corner_number_7.png',454:'radar_corner_number_8.png',455:'radar_yacht.png',456:'radar_finders_keepers.png',457:'radar_assault_package.png',458:'radar_hunt_the_boss.png',459:'radar_sightseer.png',460:'radar_turreted_limo.png',461:'radar_belly_of_the_beast.png',462:'radar_yacht_location.png',463:'radar_pickup_beast.png',464:'radar_pickup_zoned.png',465:'radar_pickup_random.png',466:'radar_pickup_slow_time.png',467:'radar_pickup_swap.png',468:'radar_pickup_thermal.png',469:'radar_pickup_weed.png',470:'radar_weapon_railgun.png',471:'radar_seashark.png',472:'radar_pickup_hidden.png',473:'radar_warehouse.png',474:'radar_warehouse_for_sale.png',475:'radar_office.png',476:'radar_office_for_sale.png',477:'radar_truck.png',478:'radar_contraband.png',479:'radar_trailer.png',480:'radar_vip.png',481:'radar_cargobob.png',482:'radar_area_outline_blip.png',483:'radar_pickup_accelerator.png',484:'radar_pickup_ghost.png',485:'radar_pickup_detonator.png',486:'radar_pickup_bomb.png',487:'radar_pickup_armoured.png',488:'radar_stunt.png',489:'radar_weapon_lives.png',490:'radar_stunt_premium.png',491:'radar_adversary.png',492:'radar_biker_clubhouse.png',493:'radar_biker_caged_in.png',494:'radar_biker_turf_war.png',495:'radar_biker_joust.png',496:'radar_production_weed.png',497:'radar_production_crack.png',498:'radar_production_fake_id.png',499:'radar_production_meth.png',500:'radar_production_money.png',501:'radar_package.png',502:'radar_capture_1.png',503:'radar_capture_2.png',504:'radar_capture_3.png',505:'radar_capture_4.png',506:'radar_capture_5.png',507:'radar_capture_6.png',508:'radar_capture_7.png',509:'radar_capture_8.png',510:'radar_capture_9.png',511:'radar_capture_10.png',512:'radar_quad.png',513:'radar_bus.png',514:'radar_drugs_package.png',515:'radar_pickup_jump.png',516:'radar_adversary_4.png',517:'radar_adversary_8.png',518:'radar_adversary_10.png',519:'radar_adversary_12.png',520:'radar_adversary_16.png',521:'radar_laptop.png',522:'radar_pickup_deadline.png',523:'radar_sports_car.png',524:'radar_warehouse_vehicle.png',525:'radar_reg_papers.png',526:'radar_police_station_dropoff.png',527:'radar_junkyard.png',528:'radar_ex_vech_1.png',529:'radar_ex_vech_2.png',530:'radar_ex_vech_3.png',531:'radar_ex_vech_4.png',532:'radar_ex_vech_5.png',533:'radar_ex_vech_6.png',534:'radar_ex_vech_7.png',535:'radar_target_a.png',536:'radar_target_b.png',537:'radar_target_c.png',538:'radar_target_d.png',539:'radar_target_e.png',540:'radar_target_f.png',541:'radar_target_g.png',542:'radar_target_h.png',543:'radar_jugg.png',544:'radar_pickup_repair.png',545:'radar_steeringwheel.png',546:'radar_trophy.png',547:'radar_pickup_rocket_boost.png',548:'radar_pickup_homing_rocket.png',549:'radar_pickup_machinegun.png',550:'radar_pickup_parachute.png',551:'radar_pickup_time_5.png',552:'radar_pickup_time_10.png',553:'radar_pickup_time_15.png',554:'radar_pickup_time_20.png',555:'radar_pickup_time_30.png',556:'radar_supplies.png',557:'radar_property_bunker.png',558:'radar_gr_wvm_1.png',559:'radar_gr_wvm_2.png',560:'radar_gr_wvm_3.png',561:'radar_gr_wvm_4.png',562:'radar_gr_wvm_5.png',563:'radar_gr_wvm_6.png',564:'radar_gr_covert_ops.png',565:'radar_adversary_bunker.png',566:'radar_gr_moc_upgrade.png',567:'radar_gr_w_upgrade.png',568:'radar_sm_cargo.png',569:'radar_sm_hangar.png',570:'radar_tf_checkpoint.png',571:'radar_race_tf.png',572:'radar_sm_wp1.png',573:'radar_sm_wp2.png',574:'radar_sm_wp3.png',575:'radar_sm_wp4.png',576:'radar_sm_wp5.png',577:'radar_sm_wp6.png',578:'radar_sm_wp7.png',579:'radar_sm_wp8.png',580:'radar_sm_wp9.png',581:'radar_sm_wp10.png',582:'radar_sm_wp11.png',583:'radar_sm_wp12.png',584:'radar_sm_wp13.png',585:'radar_sm_wp14.png',586:'radar_nhp_bag.png',587:'radar_nhp_chest.png',588:'radar_nhp_orbit.png',589:'radar_nhp_veh1.png',590:'radar_nhp_base.png',591:'radar_nhp_overlay.png',592:'radar_nhp_turret.png',593:'radar_nhp_mg_firewall.png',594:'radar_nhp_mg_node.png',595:'radar_nhp_wp1.png',596:'radar_nhp_wp2.png',597:'radar_nhp_wp3.png',598:'radar_nhp_wp4.png',599:'radar_nhp_wp5.png',600:'radar_nhp_wp6.png',601:'radar_nhp_wp7.png',602:'radar_nhp_wp8.png',603:'radar_nhp_wp9.png',604:'radar_nhp_cctv.png',605:'radar_nhp_starterpack.png',606:'radar_nhp_turret_console.png',607:'radar_nhp_mg_mir_rotate.png',608:'radar_nhp_mg_mir_static.png',609:'radar_nhp_mg_proxy.png',610:'radar_acsr_race_target.png',611:'radar_acsr_race_hotring.png',612:'radar_acsr_wp1.png',613:'radar_acsr_wp2.png',614:'radar_bat_club_property.png',615:'radar_bat_cargo.png',616:'radar_bat_truck.png',617:'radar_bat_hack_jewel.png',618:'radar_bat_hack_gold.png',619:'radar_bat_keypad.png',620:'radar_bat_hack_target.png',621:'radar_pickup_dtb_health.png',622:'radar_pickup_dtb_blast_increase.png',623:'radar_pickup_dtb_blast_decrease.png',624:'radar_pickup_dtb_bomb_increase.png',625:'radar_pickup_dtb_bomb_decrease.png',626:'radar_bat_rival_club.png',627:'radar_bat_drone.png',628:'radar_bat_cash_reg.png',629:'radar_cctv.png',630:'radar_bat_assassinate.png',631:'radar_bat_pbus.png',632:'radar_bat_wp1.png',633:'radar_bat_wp2.png',634:'radar_bat_wp3.png',635:'radar_bat_wp4.png',636:'radar_bat_wp5.png',637:'radar_bat_wp6.png',638:'radar_blimp_2.png',639:'radar_oppressor_2.png',640:'radar_bat_wp7.png',641:'radar_arena_series.png',642:'radar_arena_premium.png',643:'radar_arena_workshop.png',644:'radar_race_wars.png',645:'radar_arena_turret.png',646:'radar_arena_rc_car.png',647:'radar_arena_rc_workshop.png',648:'radar_arena_trap_fire.png',649:'radar_arena_trap_flip.png',650:'radar_arena_trap_sea.png',651:'radar_arena_trap_turn.png',652:'radar_arena_trap_pit.png',653:'radar_arena_trap_mine.png',654:'radar_arena_trap_bomb.png',655:'radar_arena_trap_wall.png',656:'radar_arena_trap_brd.png',657:'radar_arena_trap_sbrd.png',658:'radar_arena_bruiser.png',659:'radar_arena_brutus.png',660:'radar_arena_cerberus.png',661:'radar_arena_deathbike.png',662:'radar_arena_dominator.png',663:'radar_arena_impaler.png',664:'radar_arena_imperator.png',665:'radar_arena_issi.png',666:'radar_arena_sasquatch.png',667:'radar_arena_scarab.png',668:'radar_arena_slamvan.png',669:'radar_arena_zr380.png',670:'radar_ap.png',671:'radar_comic_store.png',672:'radar_cop_car.png',673:'radar_rc_time_trials.png',674:'radar_king_of_the_hill.png',675:'radar_king_of_the_hill_teams.png',676:'radar_rucksack.png',677:'radar_shipping_container.png',678:'radar_agatha.png',679:'radar_casino.png',680:'radar_casino_table_games.png',681:'radar_casino_wheel.png',682:'radar_casino_concierge.png',683:'radar_casino_chips.png',684:'radar_casino_horse_racing.png',685:'radar_adversary_featured.png',686:'radar_roulette_1.png',687:'radar_roulette_2.png',688:'radar_roulette_3.png',689:'radar_roulette_4.png',690:'radar_roulette_5.png',691:'radar_roulette_6.png',692:'radar_roulette_7.png',693:'radar_roulette_8.png',694:'radar_roulette_9.png',695:'radar_roulette_10.png',696:'radar_roulette_11.png',697:'radar_roulette_12.png',698:'radar_roulette_13.png',699:'radar_roulette_14.png',700:'radar_roulette_15.png',701:'radar_roulette_16.png',702:'radar_roulette_17.png',703:'radar_roulette_18.png',704:'radar_roulette_19.png',705:'radar_roulette_20.png',706:'radar_roulette_21.png',707:'radar_roulette_22.png',708:'radar_roulette_23.png',709:'radar_roulette_24.png',710:'radar_roulette_25.png',711:'radar_roulette_26.png',712:'radar_roulette_27.png',713:'radar_roulette_28.png',714:'radar_roulette_29.png',715:'radar_roulette_30.png',716:'radar_roulette_31.png',717:'radar_roulette_32.png',718:'radar_roulette_33.png',719:'radar_roulette_34.png',720:'radar_roulette_35.png',721:'radar_roulette_36.png',722:'radar_roulette_0.png',723:'radar_roulette_00.png',724:'radar_limo.png',725:'radar_weapon_alien.png',726:'radar_race_open_wheel.png',727:'radar_rappel.png',728:'radar_swap_car.png',729:'radar_scuba_gear.png',730:'radar_cpanel_1.png',731:'radar_cpanel_2.png',732:'radar_cpanel_3.png',733:'radar_cpanel_4.png',734:'radar_snow_truck.png',735:'radar_buggy_1.png',736:'radar_buggy_2.png',737:'radar_zhaba.png',738:'radar_gerald.png',739:'radar_ron.png',740:'radar_arcade.png',741:'radar_drone_controls.png',742:'radar_rc_tank.png',743:'radar_stairs.png',744:'radar_camera_2.png',745:'radar_winky.png',746:'radar_mini_sub.png',747:'radar_kart_retro.png',748:'radar_kart_modern.png',749:'radar_military_quad.png',750:'radar_military_truck.png',751:'radar_ship_wheel.png',752:'radar_ufo.png',753:'radar_seasparrow2.png',754:'radar_dinghy2.png',755:'radar_patrol_boat.png',756:'radar_retro_sports_car.png',757:'radar_squadee.png',758:'radar_folding_wing_jet.png',759:'radar_valkyrie2.png',760:'radar_sub2.png',761:'radar_bolt_cutters.png',762:'radar_rappel_gear.png',763:'radar_keycard.png',764:'radar_password.png',765:'radar_island_heist_prep.png',766:'radar_island_party.png',767:'radar_control_tower.png',768:'radar_underwater_gate.png',769:'radar_power_switch.png',770:'radar_compound_gate.png',771:'radar_rappel_point.png',772:'radar_keypad.png',773:'radar_sub_controls.png',774:'radar_sub_periscope.png',775:'radar_sub_missile.png',776:'radar_painting.png',777:'radar_car_meet.png',778:'radar_car_test_area.png',779:'radar_auto_shop_property.png',780:'radar_docks_export.png',781:'radar_prize_car.png',782:'radar_test_car.png',783:'radar_car_robbery_board.png',784:'radar_car_robbery_prep.png',785:'radar_street_race_series.png',786:'radar_pursuit_series.png',787:'radar_car_meet_organiser.png',788:'radar_securoserv.png',789:'radar_bounty_collectibles.png',790:'radar_movie_collectibles.png',791:'radar_trailer_ramp.png',792:'radar_race_organiser.png',793:'radar_chalkboard_list.png',794:'radar_export_vehicle.png',795:'radar_train.png',796:'radar_heist_diamond.png',797:'radar_heist_doomsday.png',798:'radar_heist_island.png',799:'radar_slamvan2.png',800:'radar_crusader.png',801:'radar_construction_outfit.png',802:'radar_overlay_jammed.png',803:'radar_heist_island_unavailable.png',804:'radar_heist_diamond_unavailable.png',805:'radar_heist_doomsday_unavailable.png',806:'radar_placeholder_7.png',807:'radar_placeholder_8.png',808:'radar_placeholder_9.png',809:'radar_featured_series.png',810:'radar_vehicle_for_sale.png',811:'radar_van_keys.png',812:'radar_suv_service.png',813:'radar_security_contract.png',814:'radar_safe.png',815:'radar_ped_r.png',816:'radar_ped_e.png',817:'radar_payphone.png',818:'radar_patriot3.png',819:'radar_music_studio.png',820:'radar_jubilee.png',821:'radar_granger2.png',822:'radar_explosive_charge.png',823:'radar_deity.png',824:'radar_d_champion.png',825:'radar_buffalo4.png',826:'radar_agency.png',827:'radar_biker_bar.png',828:'radar_simeon_overlay.png',829:'radar_junk_skydive.png',830:'radar_luxury_car_showroom.png',831:'radar_car_showroom.png',832:'radar_car_showroom_simeon.png',833:'radar_flaming_skull.png',834:'radar_weapon_ammo.png',835:'radar_community_series.png',836:'radar_cayo_series.png',837:'radar_clubhouse_contract.png',838:'radar_agent_ulp.png',839:'radar_acid.png',840:'radar_acid_lab.png',841:'radar_dax_overlay.png',842:'radar_dead_drop_package.png',843:'radar_downtown_cab.png',844:'radar_gun_van.png',845:'radar_stash_house.png',846:'radar_tractor.png',847:'radar_warehouse_juggalo.png',848:'radar_warehouse_juggalo_dax.png',849:'radar_weapon_crowbar.png',850:'radar_duffel_bag.png',851:'radar_oil_tanker.png',852:'radar_acid_lab_tent.png',853:'radar_van_burrito.png',854:'radar_acid_boost.png',855:'radar_ped_gang_leader.png',856:'radar_multistorey_garage.png',857:'radar_seized_asset_sales.png',858:'radar_cayo_attrition.png',859:'radar_bicycle.png',860:'radar_bicycle_trial.png',861:'radar_raiju.png',862:'radar_conada2.png',863:'radar_overlay_ready_for_sell.png',864:'radar_overlay_missing_supplies.png',865:'radar_streamer216.png',866:'radar_signal_jammer.png',867:'radar_salvage_yard.png',868:'radar_robbery_prep_equipment.png',869:'radar_robbery_prep_overlay.png',870:'radar_yusuf.png',871:'radar_vincent.png',872:'radar_vinewood_garage.png',873:'radar_lstb.png',874:'radar_cctv_workstation.png',875:'radar_hacking_device.png',876:'radar_race_drag.png',877:'radar_race_drift.png',878:'radar_casino_prep.png',879:'radar_planning_wall.png',880:'radar_weapon_crate.png',881:'radar_weapon_snowball.png',882:'radar_train_signals_green.png',883:'radar_train_signals_red.png',884:'radar_office_transporter.png',885:'radar_yankton_survival.png',886:'radar_daily_bounty.png',887:'radar_bounty_target.png',888:'radar_filming_schedule.png',889:'radar_pizza_this.png',890:'radar_aircraft_carrier.png',891:'radar_weapon_emp.png',892:'radar_maude_eccles.png',893:'radar_bail_bonds_office.png',894:'radar_weapon_emp_mine.png',895:'radar_zombie_disease.png',896:'radar_zombie_proximity.png',897:'radar_zombie_fire.png',898:'radar_animal_possessed.png',899:'radar_mobile_phone.png',900:'radar_garment_factory.png',901:'radar_garment_factory_for_sale.png',902:'radar_garment_factory_equipment.png',903:'radar_field_hangar.png',904:'radar_field_hangar_for_sale.png',905:'radar_cargobob_ch53.png',906:'radar_chopper_lift_ammo.png',907:'radar_chopper_lift_armor.png',908:'radar_chopper_lift_explosives.png',909:'radar_chopper_lift_upgrade.png',910:'radar_chopper_lift_weapon.png',911:'radar_cargo_ship.png',912:'radar_submarine_missile.png',913:'radar_propeller_engine.png',914:'radar_shark.png',915:'radar_fast_travel.png',916:'radar_plane_duster2.png',917:'radar_plane_titan2.png',918:'radar_collectible.png',919:'radar_field_hangar_discount.png',920:'radar_garment_factory_discount.png',921:'radar_weapon_gusenberg_sweeper.png'
};

const blipImageCache = new Map();

function getBlipImageUrl(id) {
    if (blipImageCache.has(id)) return blipImageCache.get(id);
    const filename = BLIP_IMAGE_DATA[id];
    if (filename) {
        const url = `https://docs.fivem.net/blips/${filename}`;
        blipImageCache.set(id, url);
        return url;
    }
    return 'https://docs.fivem.net/blips/radar_level.png';
}

function getBlipDisplayName(filename) {
    return filename
        .replace('radar_', '')
        .replace(/\.(png|gif)$/, '')
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
}

const BLIP_SPRITES = Object.keys(BLIP_IMAGE_DATA).map(id => ({
    id: parseInt(id),
    name: getBlipDisplayName(BLIP_IMAGE_DATA[id]),
    img: BLIP_IMAGE_DATA[id]
})).sort((a, b) => a.id - b.id);




const BLIP_COLORS = [
    { id: 0, name: 'White', hex: '#f0f0f0' },
    { id: 1, name: 'Red', hex: '#f44336' },
    { id: 2, name: 'Green', hex: '#4caf50' },
    { id: 3, name: 'Blue', hex: '#2196f3' },
    { id: 4, name: 'White 2', hex: '#ffffff' },
    { id: 5, name: 'Yellow', hex: '#ffeb3b' },
    { id: 6, name: 'Light Red', hex: '#ff5252' },
    { id: 7, name: 'Violet', hex: '#9c27b0' },
    { id: 8, name: 'Pink', hex: '#e91e63' },
    { id: 9, name: 'Light Orange', hex: '#ffab40' },
    { id: 10, name: 'Light Brown', hex: '#8d6e63' },
    { id: 11, name: 'Light Green', hex: '#8bc34a' },
    { id: 12, name: 'Light Blue', hex: '#03a9f4' },
    { id: 13, name: 'Very Light Purple', hex: '#ce93d8' },
    { id: 14, name: 'Dark Purple', hex: '#7b1fa2' },
    { id: 15, name: 'Cyan', hex: '#00bcd4' },
    { id: 16, name: 'Light Yellow', hex: '#fff59d' },
    { id: 17, name: 'Orange', hex: '#ff9800' },
    { id: 18, name: 'Light Blue 2', hex: '#4fc3f7' },
    { id: 19, name: 'Dark Pink', hex: '#ad1457' },
    { id: 20, name: 'Dark Yellow', hex: '#f9a825' },
    { id: 21, name: 'Dark Orange', hex: '#e65100' },
    { id: 22, name: 'Light Gray', hex: '#bdbdbd' },
    { id: 23, name: 'Light Pink', hex: '#f8bbd9' },
    { id: 24, name: 'Lemon Green', hex: '#cddc39' },
    { id: 25, name: 'Forest Green', hex: '#388e3c' },
    { id: 26, name: 'Electric Blue', hex: '#448aff' },
    { id: 27, name: 'Bright Purple', hex: '#d500f9' },
    { id: 28, name: 'Dark Yellow 2', hex: '#ffc107' },
    { id: 29, name: 'Dark Blue', hex: '#1565c0' },
    { id: 30, name: 'Dark Cyan', hex: '#0097a7' },
    { id: 31, name: 'Light Brown 2', hex: '#a1887f' },
    { id: 32, name: 'Very Light Blue', hex: '#81d4fa' },
    { id: 33, name: 'Light Yellow Green', hex: '#dce775' },
    { id: 34, name: 'Light Pink 2', hex: '#f48fb1' },
    { id: 35, name: 'Light Red 2', hex: '#ef9a9a' },
    { id: 36, name: 'Beige', hex: '#d7ccc8' },
    { id: 37, name: 'White 3', hex: '#fafafa' },
    { id: 38, name: 'Gold', hex: '#ffd700' },
    { id: 39, name: 'Orange 2', hex: '#ff6d00' },
    { id: 40, name: 'Brilliant Rose', hex: '#ff4081' },
    { id: 41, name: 'Red 2', hex: '#c62828' },
    { id: 42, name: 'Medium Gray', hex: '#9e9e9e' },
    { id: 43, name: 'Dark Gray', hex: '#616161' },
    { id: 44, name: 'Very Dark Gray', hex: '#424242' },
    { id: 45, name: 'Black', hex: '#212121' },
    { id: 46, name: 'Charcoal', hex: '#37474f' },
    { id: 47, name: 'Teal', hex: '#009688' },
    { id: 48, name: 'Light Red Orange', hex: '#ff8a65' },
    { id: 49, name: 'Light Teal', hex: '#4db6ac' },
    { id: 50, name: 'Olive', hex: '#827717' },
    { id: 51, name: 'Amber', hex: '#ffca28' },
    { id: 52, name: 'Deep Purple', hex: '#512da8' },
    { id: 53, name: 'Indigo', hex: '#3f51b5' },
    { id: 54, name: 'Light Indigo', hex: '#7986cb' },
    { id: 55, name: 'Light Brown 3', hex: '#bcaaa4' },
    { id: 56, name: 'Plum', hex: '#673ab7' },
    { id: 57, name: 'Salmon', hex: '#ff7043' },
    { id: 58, name: 'Seafoam', hex: '#26a69a' },
    { id: 59, name: 'Aquamarine', hex: '#00e5ff' },
    { id: 60, name: 'Deep Orange', hex: '#dd2c00' },
    { id: 61, name: 'Coral', hex: '#ff5722' },
    { id: 62, name: 'Turquoise', hex: '#00bfa5' },
    { id: 63, name: 'Dark Red', hex: '#b71c1c' },
    { id: 64, name: 'Brown Red', hex: '#6d4c41' },
    { id: 65, name: 'Green 2', hex: '#2e7d32' },
    { id: 66, name: 'Lime', hex: '#76ff03' },
    { id: 67, name: 'Light Lime', hex: '#b2ff59' },
    { id: 68, name: 'Greenish Yellow', hex: '#eeff41' },
    { id: 69, name: 'Light Cyan', hex: '#84ffff' },
    { id: 70, name: 'Light Blue 3', hex: '#40c4ff' },
    { id: 71, name: 'Light Purple', hex: '#e040fb' },
    { id: 72, name: 'Pinkish Red', hex: '#f50057' },
    { id: 73, name: 'Light Salmon', hex: '#ff8a80' },
    { id: 74, name: 'Teal 2', hex: '#26c6da' },
    { id: 75, name: 'Green Yellow', hex: '#aeea00' },
    { id: 76, name: 'Greenish Blue', hex: '#18ffff' },
    { id: 77, name: 'Magenta', hex: '#ea80fc' },
    { id: 78, name: 'Light Magenta', hex: '#ff80ab' },
    { id: 79, name: 'Bright Yellow', hex: '#ffff00' },
    { id: 80, name: 'Blue 2', hex: '#304ffe' },
    { id: 81, name: 'Hot Pink', hex: '#ff1744' },
    { id: 82, name: 'Ice Blue', hex: '#64ffda' },
    { id: 83, name: 'Electric Purple', hex: '#7c4dff' },
    { id: 84, name: 'Neon Green', hex: '#00e676' },
    { id: 85, name: 'Mint', hex: '#69f0ae' }
];

SZ.Localization = {
    async loadLocales(lang) {
        const tryUrl = `locales/${lang}.json`;
        try {
            const res = await fetch(tryUrl);
            if (!res.ok) throw new Error(`Not found ${tryUrl}`);
            SZ.Locales = await res.json();
            SZ.selectedLanguage = lang;
            localStorage.setItem('gz_locale', lang);
            Log('LOCALE', 'info', `Locale "${lang}" loaded successfully`);
        } catch (err) {
            Log('LOCALE', 'warn', 'Locale load failed, trying fallback:', err.message);
            const fallbackUrl = `locales/en.json`;
            try {
                const res = await fetch(fallbackUrl);
                SZ.Locales = await res.json();
                SZ.selectedLanguage = 'en';
            } catch (fallbackErr) {
                Log('LOCALE', 'error', 'Failed to load fallback locale:', fallbackErr);
            }
        }
    },

    t(key, params = {}) {
        const keys = key.split('.');
        let value = SZ.Locales;

        for (const k of keys) {
            if (value && value[k]) {
                value = value[k];
            } else {
                Log('LOCALE', 'warn', `Translation key not found: ${key}`);
                return key;
            }
        }

        if (typeof value === 'string') {
            return value.replace(/{(\w+)}/g, (match, param) => {
                return params[param] !== undefined ? params[param] : match;
            });
        }

        return value;
    },

    updateUI() {
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            element.textContent = this.t(key);
        });

        document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
            const key = element.getAttribute('data-i18n-placeholder');
            element.placeholder = this.t(key);
        });

        document.querySelectorAll('[data-i18n-title]').forEach(element => {
            const key = element.getAttribute('data-i18n-title');
            element.title = this.t(key);
        });

        updateDynamicTranslations();
    },
};

const debounce = (func, wait) => {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
};

const throttle = (func, limit) => {
    let inThrottle;
    return function (...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
};

function formatCoordinate(value) {
    return parseFloat(value).toFixed(2);
}

function getPolygonCenter(points) {
    let x = 0, y = 0;
    for (const point of points) {
        x += point.x;
        y += point.y;
    }
    return { x: x / points.length, y: y / points.length };
}

function getResourceName() {
    if (window.resourceName) {
        return window.resourceName;
    }
    
    const urlMatch = window.location.href.match(/https?:\/\/([^\/]+)\//);
    if (urlMatch && urlMatch[1] !== 'localhost') {
        return urlMatch[1];
    }
    
    if (window.invokeNative) {
        try {
            return window.invokeNative('getCurrentResourceName') || 'f5_safezones';
        } catch (e) {
            Log('NUI', 'warn', 'Cannot get resource name via invokeNative:', e);
        }
    }
    
    return 'f5_safezones';
}

async function sendNUI(action, data = {}) {
    const isFiveM = window.invokeNative || window.GetParentResourceName;
    
    if (!isFiveM) {
        Log('NUI', 'info', `NUI Mock: ${action}`, data);
        return true;
    }
    
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);
        
        const response = await fetch(`https://${getResourceName()}/${action}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data),
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);

        if (!response.ok) {
            Log('NUI', 'warn', `NUI response not OK for ${action}: ${response.status}`);
            return false;
        }

        try {
            const result = await response.json();
            return result;
        } catch {
            Log('NUI', 'warn', `NUI response for ${action} was not valid JSON, treating as success`);
            return true;
        }
    } catch (error) {
        if (error.name === 'AbortError') {
            Log('NUI', 'warn', `NUI timeout for ${action}`);
        } else {
            Log('NUI', 'warn', `NUI failed for ${action}: ${error.message}`);
        }
        return false;
    }
}

function copyToClipboard(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);

    try {
        textarea.select();
        document.execCommand('copy');
        return true;
    } catch (err) {
        Log('UI', 'error', SZ.Localization.t('errors.clipboard_error'), err);
        return false;
    } finally {
        document.body.removeChild(textarea);
    }
}

async function confirmDialog(title, message, options = {}) {
    return new Promise((resolve) => {
        SZ.confirmState.resolve = resolve;

        const modal = document.getElementById('confirmModal');
        const titleEl = document.getElementById('confirmTitle');
        const messageEl = document.getElementById('confirmMessage');
        const okBtn = document.getElementById('confirmOk');

        titleEl.textContent = title;
        messageEl.textContent = message;

        if (options.okText) {
            okBtn.textContent = options.okText;
        } else {
            okBtn.textContent = SZ.Localization.t('confirm.confirm');
        }

        if (options.isDanger) {
            okBtn.className = 'btn btn-danger';
        } else {
            okBtn.className = 'btn btn-primary';
        }

        modal.classList.remove('hidden');
    });
}

document.addEventListener('DOMContentLoaded', async () => {
    Log('INIT', 'info', 'Initializing Safezone Control Center v2.0');

    initializeElements();

    startAdvancedMapPreloading();

    const savedLang = localStorage.getItem('gz_locale') || 'en';

    await SZ.Localization.loadLocales(savedLang);

    SZ.Localization.updateUI();

    initializeEventListeners();
    initializeMap();
    initAllSliderFills();
    startClock();
    Log('INIT', 'info', 'Initialization complete');
});

function startAdvancedMapPreloading() {
    Log('MAP', 'info', 'Starting advanced map preloading...');
    
    createMapLoadingIndicator();
    
    const mapStyles = ['atlas', 'road', 'satellite'];
    const loadPromises = mapStyles.map(style => preloadMapImage(style));
    
    Promise.all(loadPromises).then(() => {
        Log('MAP', 'info', 'All maps preloaded successfully');
        SZ.mapState.allImagesLoaded = true;
        hideMapLoadingIndicator();
        
        prerenderMapsToCache();
    }).catch(error => {
        Log('MAP', 'error', 'Error preloading maps:', error);
        hideMapLoadingIndicator();
    });
}

function preloadMapImage(style) {
    return new Promise((resolve, reject) => {
        if (SZ.mapState.images[style]) {
            resolve(SZ.mapState.images[style]);
            return;
        }
        
        const img = new Image();
        const startTime = performance.now();
        
        img.crossOrigin = 'anonymous';
        
        const xhr = new XMLHttpRequest();
        xhr.open('GET', `maps/${style}.${style === 'atlas' ? 'png' : 'jpg'}`, true);
        xhr.responseType = 'blob';
        
        xhr.onprogress = (e) => {
            if (e.lengthComputable) {
                const progress = (e.loaded / e.total) * 100;
                SZ.mapState.imageLoadStates[style].progress = progress;
                updateMapLoadingProgress();
            }
        };
        
        xhr.onload = () => {
            if (xhr.status === 200) {
                const blob = xhr.response;
                const objectUrl = URL.createObjectURL(blob);
                
                img.onload = () => {
                    const loadTime = performance.now() - startTime;
                    Log('MAP', 'info', `Map ${style} loaded in ${loadTime.toFixed(2)}ms`);
                    
                    SZ.mapState.images[style] = img;
                    SZ.mapState.imageLoadStates[style].loaded = true;
                    SZ.mapState.imageLoadStates[style].progress = 100;
                    
                    URL.revokeObjectURL(objectUrl);
                    
                    updateMapLoadingProgress();
                    resolve(img);
                };
                
                img.onerror = () => {
                    Log('MAP', 'error', `Failed to load map: ${style}`);
                    reject(new Error(`Failed to load map: ${style}`));
                };
                
                img.src = objectUrl;
            } else {
                Log('MAP', 'error', `Map XHR failed for ${style}: HTTP ${xhr.status}`);
                reject(new Error(`Failed to load map: ${style} - Status: ${xhr.status}`));
            }
        };

        xhr.onerror = () => {
            Log('MAP', 'error', `Network error loading map: ${style}`);
            reject(new Error(`Network error loading map: ${style}`));
        };
        
        xhr.send();
    });
}

function createMapLoadingIndicator() {
    const indicator = document.createElement('div');
    indicator.id = 'mapLoadingIndicator';
    indicator.style.cssText = `
        position: fixed;
        bottom: 20px;
        left: 20px;
        background: var(--bg-tertiary);
        border: 1px solid var(--border-color);
        border-radius: var(--radius-md);
        padding: 16px 20px;
        display: flex;
        align-items: center;
        gap: 12px;
        z-index: 1000;
        transition: all var(--transition-base);
        opacity: 0;
        transform: translateY(20px);
    `;
    
    indicator.innerHTML = `
        <div class="loading-spinner" style="
            width: 20px;
            height: 20px;
            border: 2px solid var(--border-color);
            border-top-color: var(--primary);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        "></div>
        <div>
            <div style="font-size: 13px; color: var(--text-primary); margin-bottom: 4px;" data-i18n="map.loading">Loading maps...</div>
            <div style="display: flex; align-items: center; gap: 8px;">
                <div style="
                    width: 150px;
                    height: 4px;
                    background: var(--bg-secondary);
                    border-radius: 2px;
                    overflow: hidden;
                ">
                    <div id="mapLoadingProgressBar" style="
                        width: 0%;
                        height: 100%;
                        background: var(--primary);
                        transition: width 0.3s ease;
                    "></div>
                </div>
                <span id="mapLoadingProgressText" style="
                    font-size: 11px;
                    color: var(--text-muted);
                    min-width: 35px;
                ">0%</span>
            </div>
        </div>
    `;
    
    const style = document.createElement('style');
    style.textContent = `
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
    `;
    document.head.appendChild(style);
    
    document.body.appendChild(indicator);
    
    requestAnimationFrame(() => {
        indicator.style.opacity = '1';
        indicator.style.transform = 'translateY(0)';
    });
}

function updateMapLoadingProgress() {
    const states = SZ.mapState.imageLoadStates;
    const totalProgress = (states.atlas.progress + states.road.progress + states.satellite.progress) / 3;
    
    const progressBar = document.getElementById('mapLoadingProgressBar');
    const progressText = document.getElementById('mapLoadingProgressText');
    
    if (progressBar && progressText) {
        progressBar.style.width = `${totalProgress}%`;
        progressText.textContent = `${Math.round(totalProgress)}%`;
    }
    
    SZ.mapState.loadingProgress = totalProgress;
}

function hideMapLoadingIndicator() {
    const indicator = document.getElementById('mapLoadingIndicator');
    if (indicator) {
        indicator.style.opacity = '0';
        indicator.style.transform = 'translateY(20px)';
        setTimeout(() => indicator.remove(), 300);
    }
}

function prerenderMapsToCache() {
    Log('MAP', 'info', 'Prerendering maps to cache...');
    
    const styles = ['atlas', 'road', 'satellite'];
    
    styles.forEach(style => {
        const img = SZ.mapState.images[style];
        if (!img) return;
        
        const offscreenCanvas = document.createElement('canvas');
        offscreenCanvas.width = SZ.MAP_SIZE;
        offscreenCanvas.height = SZ.MAP_SIZE;
        const offscreenCtx = offscreenCanvas.getContext('2d', {
            alpha: false,
            desynchronized: true,
            willReadFrequently: false
        });
        
        offscreenCtx.imageSmoothingEnabled = true;
        offscreenCtx.imageSmoothingQuality = 'high';
        
        offscreenCtx.drawImage(img, 0, 0, SZ.MAP_SIZE, SZ.MAP_SIZE);
        
        SZ.mapState.prerenderedMaps[style] = offscreenCanvas;
        
        Log('MAP', 'info', `Prerendered ${style} map to cache`);
    });
}

function initializeElements() {
    const ids = [
        'app', 'closeBtn', 'currentTime', 'totalZonesHeader', 'activePlayersHeader',
        'zoneSearch', 'createZoneBtn', 'refreshBtn', 'zoneForm', 'createZoneForm',
        'zoneName', 'zoneRadius', 'radiusRange', 'coordX', 'coordY', 'coordZ',
        'useCurrentLocation', 'blipName', 'showBlip', 'showMarker', 'cancelCreate',
        'mapCanvas', 'zoomIn', 'zoomOut', 'resetView', 'toggleGrid',
        'toggleMeasure', 'mapSearch', 'zoomLevel', 'cursorCoords', 'zoneTooltip',
        'totalZonesAnalytics', 'activePlayers', 'activeZones',
        'playersTableBody', 'zoneModal',
        'modalZoneName', 'modalZoneType', 'modalZoneCoords', 'modalZoneRadius',
        'modalZonePlayers', 'modalPlayersList', 'teleportToZone', 'deleteZone', 'cloneZoneAttributes',
        'closeModal', 'notifications', 'markerConfigSection', 'confirmModal',
        'confirmTitle', 'confirmMessage', 'confirmOk', 'confirmCancel',
        'markerColor', 'markerColorBtn', 'markerColorPreview', 'markerColorHex', 'markerColorNative',
        'markerColorModal', 'markerColorModalClose',
        'markerPickerSwatch', 'markerHexDisplay', 'markerRgbDisplay', 'markerNativeDisplay',
        'markerPickerNative', 'markerPickerHexInput',
        'markerSliderR', 'markerSliderG', 'markerSliderB',
        'markerValueR', 'markerValueG', 'markerValueB',
        'markerPickerCancel', 'markerPickerConfirm',
        'markerAlpha', 'markerAlphaValue',
        'markerHeight', 'markerHeightValue', 'pulseSpeed', 'pulseSpeedValue',
        'bobHeight', 'bobHeightValue', 'rotationSpeed', 'rotationSpeedValue',
        'addPolygonPoint', 'polygonPointInputs', 'minZ', 'maxZ',
        'polygonManualModeBtn', 'polygonCreatorModeBtn', 'startPolygonCreatorBtn',
        'circleManualModeBtn', 'circleCreatorModeBtn', 'startCircleCreatorBtn', 'circleManualInputs',
        'infiniteHeight', 'circleMinZ', 'circleMaxZ', 'heightInputs',
        'infiniteHeightPolygon', 'heightInputsPolygon', 'polygonAddRoof', 'zonesList', 'zonesEmpty',
        'clearSearch', 'totalZoneStat', 'customZoneStat', 'activeZoneStat',
        'totalPlayersStat', 'filterAllCount', 'filterConfigCount', 'filterCustomCount',
        'filterActiveCount', 'fabCreateZone', 'emptyCreateBtn', 'zonesSidebar', 'zonesMain',
        'editZone', 'editingZoneId', 'editingZoneName',
        'renderDistance', 'renderDistanceRange', 'renderDistanceContainer',
        'toggleAllZonesBtn', 'toggleAllZonesLabel', 'debugAllZonesBtn', 'debugInactiveZonesBtn',
        'debugActiveZonesBtn',
        'logsSearch', 'logsCategoryFilter', 'logsActionFilter', 'logsAdminFilter',
        'logsOutcomeFilter', 'logsFromDate', 'logsToDate', 'logsTableBody',
        'logsEmpty', 'logsRetentionLabel', 'logsRefresh',
        'blipConfigSection', 'blipSpriteBtn', 'blipColorBtn', 'blipSprite', 'blipColor',
        'blipSpritePreview', 'blipSpriteId', 'blipSpriteName',
        'blipColorPreview', 'blipColorHex', 'blipColorNative',
        'blipSpriteModal', 'blipColorModal', 'blipSpriteGrid',
        'blipSpriteSearch', 'blipSpriteModalClose', 'blipColorModalClose',
        'colorPickerSwatch', 'colorHexDisplay', 'colorRgbDisplay', 'colorNativeDisplay',
        'colorPickerNative', 'colorPickerHexInput',
        'colorSliderR', 'colorSliderG', 'colorSliderB',
        'colorValueR', 'colorValueG', 'colorValueB',
        'colorPickerCancel', 'colorPickerConfirm',
        'showCenterBlip', 'centerBlipContent',
        'blipAlpha', 'blipAlphaValue', 'blipScale', 'blipScaleValue',
        'blipShortRange', 'blipHiddenOnLegend', 'blipHighDetail',
        'showZoneOutline', 'outlineBlipContent', 'circleCoverageSection', 'circleCoverageType',
        'outlineRadius', 'outlineRadiusValue', 'outlineSpacing', 'outlineSpacingValue',
        'outlineAlpha', 'outlineAlphaValue', 'outlineColor', 'outlineColorHex',
        'outlineStrokeEnabled', 'strokeSettings',
        'strokeRadius', 'strokeRadiusValue', 'strokeAlpha', 'strokeAlphaValue',
        'strokeColorBtn', 'strokeColorPreview', 'strokeColorHex', 'strokeColorNative', 'strokeColor',
        'strokeColorModal', 'strokeColorModalClose',
        'strokePickerSwatch', 'strokeHexDisplay', 'strokeRgbDisplay', 'strokeNativeDisplay',
        'strokePickerNative', 'strokePickerHexInput',
        'strokeSliderR', 'strokeSliderG', 'strokeSliderB',
        'strokeValueR', 'strokeValueG', 'strokeValueB',
        'strokePickerCancel', 'strokePickerConfirm',
        'outlineColorBtn', 'outlineColorPreview', 'outlineColorHex', 'outlineColorNative', 'outlineColorModal',
        'outlineColorModalClose', 'outlinePickerSwatch', 'outlineHexDisplay', 'outlineRgbDisplay', 'outlineNativeDisplay',
        'outlinePickerNative', 'outlinePickerHexInput',
        'outlineSliderR', 'outlineSliderG', 'outlineSliderB',
        'outlineValueR', 'outlineValueG', 'outlineValueB',
        'outlinePickerCancel', 'outlinePickerConfirm'
    ];

    ids.forEach(id => {
        SZ.elements[id] = document.getElementById(id);
    });

    const missingElements = ids.filter(id => !SZ.elements[id]);
    Log('INIT', 'info', `Cached ${ids.length - missingElements.length}/${ids.length} DOM elements`);
    if (missingElements.length > 0) {
        Log('INIT', 'warn', `Missing DOM elements: ${missingElements.join(', ')}`);
    }
}

function updateDynamicTranslations() {
    if (!SZ.elements || Object.keys(SZ.elements).length === 0) {
        Log('UI', 'warn', 'Elements not initialized yet, skipping dynamic translations update');
        return;
    }

    if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
        renderZones();
        updateZoneStats();
    } else if (SZ.state.currentView === 'analytics') {
        updateAnalytics();
    } else if (SZ.state.currentView === 'logs') {
        renderLogs();
    }

    populateLogFilters();
    updateLogsRetentionLabel();
}

function handleToggleMarker() {
    if (!SZ.state.selectedZone) {
        Log('ZONE', 'warn', 'Toggle marker called without zone selected');
        return;
    }
    Log('ZONE', 'info', `Toggling marker for zone: "${SZ.state.selectedZone.name}"`);
    sendNUI('toggleZoneMarker', { zoneName: SZ.state.selectedZone.name });
    showNotification(SZ.Localization.t('notifications.toggling_marker', { name: SZ.state.selectedZone.name }), 'info');
}

function updateSliderFill(input) {
    const min = parseFloat(input.min) || 0;
    const max = parseFloat(input.max) || 100;
    const val = parseFloat(input.value) || 0;
    const pct = ((val - min) / (max - min)) * 100;
    input.style.background = `linear-gradient(to right, var(--primary) 0%, var(--primary) ${pct}%, rgba(255,255,255,0.08) ${pct}%, rgba(255,255,255,0.08) 100%)`;
}

function refreshAllSliderFills() {
    document.querySelectorAll('.f-slider__track, .blip-slider, .range-input input[type="range"]').forEach(input => {
        updateSliderFill(input);
    });
}

function initAllSliderFills() {
    document.querySelectorAll('.f-slider__track, .blip-slider, .range-input input[type="range"]').forEach(input => {
        updateSliderFill(input);
        input.addEventListener('input', () => updateSliderFill(input));
    });
}

function initializeEventListeners() {
    Log('INIT', 'info', 'Initializing event listeners');
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.addEventListener('click', () => switchView(btn.dataset.view));
    });

    SZ.elements.closeBtn.addEventListener('click', async () => await closePanel());

    SZ.elements.createZoneBtn.addEventListener('click', showCreateForm);
    SZ.elements.cancelCreate.addEventListener('click', hideCreateForm);
    SZ.elements.refreshBtn.addEventListener('click', async () => await refreshData());
    SZ.elements.createZoneForm.addEventListener('submit', handleCreateZone);
    SZ.elements.useCurrentLocation.addEventListener('click', useCurrentLocation);

    if (SZ.elements.polygonManualModeBtn && SZ.elements.polygonCreatorModeBtn) {
        SZ.elements.polygonManualModeBtn.addEventListener('click', () => setPolygonCreationMode('manual'));
        SZ.elements.polygonCreatorModeBtn.addEventListener('click', () => setPolygonCreationMode('creator'));
    }

    if (SZ.elements.startPolygonCreatorBtn) {
        SZ.elements.startPolygonCreatorBtn.addEventListener('click', async () => {
            setPolygonCreationMode('creator');
            SZ.state.pendingEditContext = null;
            if (SZ.state.isEditingZone && SZ.state.editingZone) {
                SZ.state.pendingEditContext = {
                    zone: SZ.state.editingZone,
                    zoneId: document.getElementById('editingZoneId').value,
                    originalName: document.getElementById('editingZoneName').value
                };
            }
            const existingPoints = collectExistingPolygonPoints();
            let teleportCoords = null;
            if (SZ.state.isEditingZone && SZ.state.editingZone) {
                const zone = SZ.state.editingZone;
                if (zone.points && zone.points.length >= 3) {
                    const center = getPolygonCenter(zone.points);
                    teleportCoords = { x: center.x, y: center.y, z: (zone.minZ + zone.maxZ) / 2 };
                }
            }
            const result = await sendNUI('startPolygonCreator', {
                zoneSettings: collectZoneSettings(),
                existingPoints: existingPoints,
                teleportCoords: teleportCoords
            });
            if (result && result.ok) {
                Log('ZONE', 'info', 'Polygon creator started successfully');
                showNotification(SZ.Localization.t('notifications.polygon_creator_starting'), 'info');
            } else {
                Log('ZONE', 'warn', 'Polygon creator failed to start', result);
                showNotification(SZ.Localization.t('notifications.polygon_creator_failed'), 'error');
                setPolygonCreationMode('manual');
                SZ.state.pendingEditContext = null;
            }
        });
    }

    if (SZ.elements.circleManualModeBtn && SZ.elements.circleCreatorModeBtn) {
        SZ.elements.circleManualModeBtn.addEventListener('click', () => setCircleCreationMode('manual'));
        SZ.elements.circleCreatorModeBtn.addEventListener('click', () => setCircleCreationMode('creator'));
    }

    if (SZ.elements.startCircleCreatorBtn) {
        SZ.elements.startCircleCreatorBtn.addEventListener('click', async () => {
            setCircleCreationMode('creator');
            SZ.state.pendingEditContext = null;
            if (SZ.state.isEditingZone && SZ.state.editingZone) {
                SZ.state.pendingEditContext = {
                    zone: SZ.state.editingZone,
                    zoneId: document.getElementById('editingZoneId').value,
                    originalName: document.getElementById('editingZoneName').value
                };
            }
            const existingCircle = collectExistingCircleData();
            const payload = { zoneSettings: collectZoneSettings() };
            if (existingCircle) {
                payload.existingCenter = existingCircle.center;
                payload.existingRadius = existingCircle.radius;
            }
            if (SZ.state.isEditingZone && SZ.state.editingZone && SZ.state.editingZone.coords) {
                payload.teleportCoords = SZ.state.editingZone.coords;
            }
            const result = await sendNUI('startCircleCreator', payload);
            if (result && result.ok) {
                Log('ZONE', 'info', 'Circle creator started successfully');
                showNotification(SZ.Localization.t('notifications.circle_creator_starting'), 'info');
            } else {
                Log('ZONE', 'warn', 'Circle creator failed to start', result);
                showNotification(SZ.Localization.t('notifications.circle_creator_failed'), 'error');
                setCircleCreationMode('manual');
                SZ.state.pendingEditContext = null;
            }
        });
    }

    if (SZ.elements.toggleAllZonesBtn) {
        SZ.elements.toggleAllZonesBtn.addEventListener('click', handleToggleAllZones);
    }

    document.querySelectorAll('[data-debug-mode]').forEach(button => {
        button.addEventListener('click', () => handleDebugButtonClick(button.dataset.debugMode));
    });

    if (SZ.elements.logsRefresh) {
        SZ.elements.logsRefresh.addEventListener('click', async () => await refreshData());
    }

    if (SZ.elements.logsSearch) {
        SZ.elements.logsSearch.addEventListener('input', debounce(handleLogsSearch, SZ.DEBOUNCE_DELAY));
    }

    ['logsCategoryFilter', 'logsActionFilter', 'logsAdminFilter', 'logsOutcomeFilter'].forEach(id => {
        const element = SZ.elements[id];
        if (element) {
            element.addEventListener('change', handleLogsFilterChange);
        }
    });

    if (SZ.elements.logsFromDate) {
        SZ.elements.logsFromDate.addEventListener('change', (event) => setLogFilter('from', event.target.value || ''));
    }

    if (SZ.elements.logsToDate) {
        SZ.elements.logsToDate.addEventListener('change', (event) => setLogFilter('to', event.target.value || ''));
    }

    if (SZ.elements.fabCreateZone) {
        SZ.elements.fabCreateZone.addEventListener('click', showCreateForm);
    }
    if (SZ.elements.emptyCreateBtn) {
        SZ.elements.emptyCreateBtn.addEventListener('click', showCreateForm);
    }

    document.querySelectorAll('.type-btn').forEach(btn => {
        btn.addEventListener('click', () => selectZoneType(btn.dataset.type));
    });

    if (SZ.elements.addPolygonPoint) {
        SZ.elements.addPolygonPoint.addEventListener('click', addPolygonPoint);
    }

    SZ.elements.zoneSearch.addEventListener('input', debounce(handleSearch, SZ.DEBOUNCE_DELAY));
    SZ.elements.mapSearch.addEventListener('input', debounce(handleMapSearch, SZ.DEBOUNCE_DELAY));

    if (SZ.elements.clearSearch) {
        SZ.elements.clearSearch.addEventListener('click', () => {
            SZ.elements.zoneSearch.value = '';
            SZ.state.searchQuery = '';
            renderZones();
        });
    }

    document.querySelectorAll('.filter-option').forEach(option => {
        option.addEventListener('click', () => {
            if (SZ.state.isCreatingZone) {
                hideCreateForm();
            }

            document.querySelectorAll('.filter-option').forEach(o => o.classList.remove('active'));
            option.classList.add('active');
            SZ.state.currentFilter = option.dataset.filter;
            renderZones();
        });
    });

    SZ.elements.radiusRange.addEventListener('input', (e) => {
        SZ.elements.zoneRadius.value = e.target.value;
    });

    SZ.elements.zoneRadius.addEventListener('input', (e) => {
        SZ.elements.radiusRange.value = e.target.value;
        updateSliderFill(SZ.elements.radiusRange);
    });

    SZ.elements.showMarker.addEventListener('change', (e) => {
        toggleMarkerConfig(e.target.checked);
    });

    SZ.elements.showBlip.addEventListener('change', (e) => {
        toggleBlipConfig(e.target.checked);
    });

    if (SZ.elements.blipSpriteBtn) {
        SZ.elements.blipSpriteBtn.addEventListener('click', () => openBlipModal('sprite'));
    }
    if (SZ.elements.blipColorBtn) {
        SZ.elements.blipColorBtn.addEventListener('click', () => openBlipModal('color'));
    }
    if (SZ.elements.blipSpriteModalClose) {
        SZ.elements.blipSpriteModalClose.addEventListener('click', () => closeBlipModal('sprite'));
    }
    if (SZ.elements.blipColorModalClose) {
        SZ.elements.blipColorModalClose.addEventListener('click', () => closeBlipModal('color'));
    }
    if (SZ.elements.blipSpriteSearch) {
        SZ.elements.blipSpriteSearch.addEventListener('input', debounce(() => filterBlipGrid('sprite'), 150));
    }

    blipColorPicker.setupListeners();
    outlineColorPicker.setupListeners();
    strokeColorPicker.setupListeners();

    if (SZ.elements.blipSpriteModal) {
        SZ.elements.blipSpriteModal.addEventListener('click', (e) => {
            if (e.target === SZ.elements.blipSpriteModal) closeBlipModal('sprite');
        });
    }


    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const colorModalOpen = SZ.elements.blipColorModal?.classList.contains('active');
            const spriteModalOpen = SZ.elements.blipSpriteModal?.classList.contains('active');
            const outlineColorModalOpen = SZ.elements.outlineColorModal?.classList.contains('active');
            const strokeColorModalOpen = SZ.elements.strokeColorModal?.classList.contains('active');
            const markerColorModalOpen = SZ.elements.markerColorModal?.classList.contains('active');

            if (markerColorModalOpen) {
                e.stopImmediatePropagation();
                e.preventDefault();
                markerColorPicker.cancel();
                return;
            }

            if (strokeColorModalOpen) {
                e.stopImmediatePropagation();
                e.preventDefault();
                strokeColorPicker.cancel();
                return;
            }

            if (outlineColorModalOpen) {
                e.stopImmediatePropagation();
                e.preventDefault();
                outlineColorPicker.cancel();
                return;
            }

            if (colorModalOpen) {
                e.stopImmediatePropagation();
                e.preventDefault();
                blipColorPicker.cancel();
                return;
            }

            if (spriteModalOpen) {
                e.stopImmediatePropagation();
                e.preventDefault();
                closeBlipModal('sprite');
                return;
            }
        }
    }, true);

    SZ.elements.infiniteHeight.addEventListener('change', (e) => {
        const isInfinite = e.target.checked;

        SZ.elements.circleMinZ.disabled = isInfinite;
        SZ.elements.circleMaxZ.disabled = isInfinite;

        if (isInfinite) {
            SZ.elements.heightInputs.classList.add('disabled');
            SZ.elements.heightInputs.style.opacity = '0.5';
            SZ.elements.heightInputs.style.pointerEvents = 'none';
        } else {
            SZ.elements.heightInputs.classList.remove('disabled');
            SZ.elements.heightInputs.style.opacity = '1';
            SZ.elements.heightInputs.style.pointerEvents = 'auto';
        }
    });

    if (SZ.elements.infiniteHeightPolygon) {
        SZ.elements.infiniteHeightPolygon.addEventListener('change', (e) => {
            const isInfinite = e.target.checked;

            SZ.elements.minZ.disabled = isInfinite;
            SZ.elements.maxZ.disabled = isInfinite;

            if (isInfinite) {
                SZ.elements.heightInputsPolygon.classList.add('disabled');
                SZ.elements.heightInputsPolygon.style.opacity = '0.5';
                SZ.elements.heightInputsPolygon.style.pointerEvents = 'none';
            } else {
                SZ.elements.heightInputsPolygon.classList.remove('disabled');
                SZ.elements.heightInputsPolygon.style.opacity = '1';
                SZ.elements.heightInputsPolygon.style.pointerEvents = 'auto';
                updatePolygonMinMaxZ();
            }
        });
    }
    
    if (SZ.elements.renderDistanceRange) {
        SZ.elements.renderDistanceRange.addEventListener("input", (e) => {
            SZ.elements.renderDistance.value = e.target.value;
        });
    }
    
    if (SZ.elements.renderDistance) {
        SZ.elements.renderDistance.addEventListener("input", (e) => {
            SZ.elements.renderDistanceRange.value = e.target.value;
            updateSliderFill(SZ.elements.renderDistanceRange);
        });
    }


    if (SZ.elements.showCenterBlip) {
        SZ.elements.showCenterBlip.addEventListener('change', (e) => {
            const content = SZ.elements.centerBlipContent;
            if (content) {
                content.style.display = e.target.checked ? 'block' : 'none';
                content.style.opacity = e.target.checked ? '1' : '0.5';
            }
        });
    }

    if (SZ.elements.showZoneOutline) {
        SZ.elements.showZoneOutline.addEventListener('change', (e) => {
            const content = SZ.elements.outlineBlipContent;
            if (content) {
                content.style.display = e.target.checked ? 'block' : 'none';
                content.style.opacity = e.target.checked ? '1' : '0.5';
            }
        });
    }

    if (SZ.elements.blipAlpha) {
        SZ.elements.blipAlpha.addEventListener('input', (e) => {
            if (SZ.elements.blipAlphaValue) {
                SZ.elements.blipAlphaValue.textContent = e.target.value;
            }
        });
    }

    if (SZ.elements.blipScale) {
        SZ.elements.blipScale.addEventListener('input', (e) => {
            if (SZ.elements.blipScaleValue) {
                SZ.elements.blipScaleValue.textContent = e.target.value;
            }
        });
    }

    if (SZ.elements.outlineRadius) {
        SZ.elements.outlineRadius.addEventListener('input', (e) => {
            if (SZ.elements.outlineRadiusValue) {
                SZ.elements.outlineRadiusValue.textContent = e.target.value;
            }
        });
    }

    if (SZ.elements.outlineSpacing) {
        SZ.elements.outlineSpacing.addEventListener('input', (e) => {
            if (SZ.elements.outlineSpacingValue) {
                SZ.elements.outlineSpacingValue.textContent = e.target.value;
            }
        });
    }

    if (SZ.elements.outlineAlpha) {
        SZ.elements.outlineAlpha.addEventListener('input', (e) => {
            if (SZ.elements.outlineAlphaValue) {
                SZ.elements.outlineAlphaValue.textContent = e.target.value;
            }
        });
    }

    if (SZ.elements.outlineColor) {
        SZ.elements.outlineColor.addEventListener('input', (e) => {
            if (SZ.elements.outlineColorHex) {
                SZ.elements.outlineColorHex.textContent = e.target.value.toUpperCase();
            }
        });
    }

    if (SZ.elements.outlineStrokeEnabled) {
        SZ.elements.outlineStrokeEnabled.addEventListener('change', (e) => {
            const strokeSettings = SZ.elements.strokeSettings;
            if (strokeSettings) {
                if (e.target.checked) {
                    strokeSettings.classList.remove('disabled');
                    strokeSettings.style.opacity = '1';
                    strokeSettings.style.pointerEvents = 'auto';
                } else {
                    strokeSettings.classList.add('disabled');
                    strokeSettings.style.opacity = '0.5';
                    strokeSettings.style.pointerEvents = 'none';
                }
            }
        });
    }

    if (SZ.elements.strokeRadius) {
        SZ.elements.strokeRadius.addEventListener('input', (e) => {
            if (SZ.elements.strokeRadiusValue) {
                SZ.elements.strokeRadiusValue.textContent = e.target.value + 'x';
            }
        });
    }

    if (SZ.elements.strokeColor) {
        SZ.elements.strokeColor.addEventListener('input', (e) => {
            if (SZ.elements.strokeColorHex) {
                SZ.elements.strokeColorHex.textContent = e.target.value.toUpperCase();
            }
        });
    }

    if (SZ.elements.strokeAlpha) {
        SZ.elements.strokeAlpha.addEventListener('input', (e) => {
            if (SZ.elements.strokeAlphaValue) {
                SZ.elements.strokeAlphaValue.textContent = e.target.value;
            }
        });
    }

    document.querySelectorAll('.coverage-type-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.coverage-type-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            if (SZ.elements.circleCoverageType) {
                SZ.elements.circleCoverageType.value = btn.dataset.coverage;
            }
        });
    });

    SZ.elements.zoomIn.addEventListener('click', () => zoomMap(1));
    SZ.elements.zoomOut.addEventListener('click', () => zoomMap(-1));
    SZ.elements.resetView.addEventListener('click', resetMapView);
    SZ.elements.toggleGrid.addEventListener('click', toggleGrid);
    SZ.elements.toggleMeasure.addEventListener('click', toggleMeasureMode);

    document.querySelectorAll('.map-style').forEach(btn => {
        btn.addEventListener('click', () => changeMapStyleOptimized(btn.dataset.style));
    });

    SZ.elements.closeModal.addEventListener('click', closeZoneModal);
    SZ.elements.teleportToZone.addEventListener('click', handleTeleport);
    SZ.elements.deleteZone.addEventListener('click', handleDeleteZone);

    if (SZ.elements.cloneZoneAttributes) {
        SZ.elements.cloneZoneAttributes.addEventListener('click', handleCloneZoneAttributes);
    }

    const editZoneBtn = document.getElementById('editZone');
    if (editZoneBtn) {
        editZoneBtn.addEventListener('click', handleEditZone);
    }
    const toggleMarkerBtn = document.createElement('button');
    toggleMarkerBtn.className = 'btn btn-secondary';
    toggleMarkerBtn.id = 'toggleZoneMarker';
    toggleMarkerBtn.innerHTML = `
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M1 21L21 3M1 21L9 13L13 17L21 9V3M21 3H15" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span data-i18n="modal.toggle_marker">${SZ.Localization.t('modal.toggle_marker')}</span>
    `;
    toggleMarkerBtn.addEventListener('click', handleToggleMarker);

    const modalActions = document.querySelector('.modal-actions');
    if (modalActions && !document.getElementById('toggleZoneMarker')) {
        modalActions.insertBefore(toggleMarkerBtn, modalActions.firstChild);
    }

    SZ.elements.zoneModal.addEventListener('click', (e) => {
        if (e.target === SZ.elements.zoneModal) closeZoneModal();
    });

    SZ.elements.confirmOk.addEventListener('click', () => {
        SZ.elements.confirmModal.classList.add('hidden');
        if (SZ.confirmState.resolve) {
            SZ.confirmState.resolve(true);
            SZ.confirmState.resolve = null;

        }
    });

    SZ.elements.confirmCancel.addEventListener('click', () => {
        SZ.elements.confirmModal.classList.add('hidden');
        if (SZ.confirmState.resolve) {
            SZ.confirmState.resolve(false);
            SZ.confirmState.resolve = null;

        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!SZ.elements.confirmModal.classList.contains('hidden')) {
                SZ.elements.confirmModal.classList.add('hidden');
                if (SZ.confirmState.resolve) {
                    SZ.confirmState.resolve(false);
                    SZ.confirmState.resolve = null;
        
                }
            } else if (!SZ.elements.zoneModal.classList.contains('hidden')) {
                closeZoneModal();
            } else if (!SZ.elements.zoneForm.classList.contains('hidden')) {
                hideCreateForm();
            } else {
                closePanel().catch(err => Log('UI', 'warn', 'Error closing panel:', err));
            }
        }
    });

    markerColorPicker.setupListeners();

    SZ.elements.markerAlpha.addEventListener('input', (e) => {
        SZ.elements.markerAlphaValue.textContent = e.target.value;
    });

    SZ.elements.markerHeight.addEventListener('input', (e) => {
        SZ.elements.markerHeightValue.textContent = e.target.value + 'm';
    });

    SZ.elements.pulseSpeed.addEventListener('input', (e) => {
        SZ.elements.pulseSpeedValue.textContent = e.target.value + 'x';
    });

    SZ.elements.bobHeight.addEventListener('input', (e) => {
        SZ.elements.bobHeightValue.textContent = e.target.value + 'm';
    });

    SZ.elements.rotationSpeed.addEventListener('input', (e) => {
        SZ.elements.rotationSpeedValue.textContent = e.target.value + 'x';
    });

    document.querySelectorAll('.marker-type-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.marker-type-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
        });
    });

    updateDebugButtons();

    if (SZ.elements.zonesList) {
        SZ.elements.zonesList.addEventListener('click', (e) => {
            const btn = e.target.closest('[data-action]');
            if (!btn) return;
            const zoneName = btn.dataset.zone;
            if (!zoneName) return;
            switch (btn.dataset.action) {
                case 'details': showZoneDetails(zoneName); break;
                case 'teleport': handleQuickTeleport(zoneName); break;
                case 'toggle-marker': handleQuickToggleMarker(zoneName); break;
                case 'toggle-activation': handleToggleZoneActivation(zoneName); break;
            }
        });

        SZ.elements.zonesList.addEventListener('change', (e) => {
            const input = e.target.closest('[data-debug-zone]');
            if (input) handleZoneDebugToggle(input.dataset.debugZone, input);
        });
    }

    if (SZ.elements.blipSpriteGrid) {
        SZ.elements.blipSpriteGrid.addEventListener('click', (e) => {
            const item = e.target.closest('.blip-item');
            if (!item) return;
            const id = parseInt(item.dataset.spriteId);
            const name = item.dataset.spriteName;
            if (!isNaN(id) && name) selectBlipSprite(id, name);
        });
    }

    initializeAnalyticsListeners();
}

function toggleMarkerConfig(show) {
    if (show) {
        SZ.elements.markerConfigSection.classList.remove('disabled');

        const markerTypeSection = document.querySelector('.marker-type-grid')?.parentElement;
        if (markerTypeSection) {
            markerTypeSection.classList.toggle('hidden', SZ.state.zoneCreationType === 'polygon');
        }
    } else {
        SZ.elements.markerConfigSection.classList.add('disabled');
    }
}

function toggleBlipConfig(show) {
    if (SZ.elements.blipConfigSection) {
        if (show) {
            SZ.elements.blipConfigSection.classList.remove('disabled');
        } else {
            SZ.elements.blipConfigSection.classList.add('disabled');
        }
    }
}

function initializeBlipGrids() {
    if (SZ.elements.blipSpriteGrid) {
        renderBlipSpriteGrid(BLIP_SPRITES);
    }
}

const blipImageAttempts = {};

function handleBlipImageError(img, name, id) {
    const key = `${id}_${name}`;
    if (!blipImageAttempts[key]) {
        blipImageAttempts[key] = 0;
    }
    blipImageAttempts[key]++;

    const attempt = blipImageAttempts[key];

    if (BLIP_IMAGE_DATA[id]) {
        const mappedFile = BLIP_IMAGE_DATA[id];
        if (attempt === 1) {
            if (mappedFile.endsWith('.png')) {
                img.src = `https://docs.fivem.net/blips/${mappedFile.replace('.png', '.gif')}`;
            } else if (mappedFile.endsWith('.gif')) {
                img.src = `https://docs.fivem.net/blips/${mappedFile.replace('.gif', '.png')}`;
            }
            return;
        }
    }

    if (attempt <= 3) {
        const imgName = name.toLowerCase().replace(/[^a-z0-9]/g, '_').replace(/_+/g, '_').replace(/^_|_$/g, '');
        const formats = ['png', 'gif'];
        const format = formats[(attempt - 1) % formats.length];
        img.src = `https://docs.fivem.net/blips/radar_${imgName}.${format}`;
    } else {
        img.src = 'https://docs.fivem.net/blips/radar_level.png';
        img.onerror = null;
        delete blipImageAttempts[key];
    }
}

function renderBlipSpriteGrid(sprites) {
    if (!SZ.elements.blipSpriteGrid) return;

    const currentSprite = parseInt(SZ.elements.blipSprite?.value) || 84;

    SZ.elements.blipSpriteGrid.innerHTML = sprites.map(sprite => {
        const imgUrl = getBlipImageUrl(sprite.id);
        return `
            <div class="blip-item ${sprite.id === currentSprite ? 'selected' : ''}"
                 data-sprite-id="${sprite.id}"
                 data-sprite-name="${sprite.name}">
                <img src="${imgUrl}"
                     alt="${sprite.name}"
                     data-blip-id="${sprite.id}"
                     onerror="handleBlipImageError(this, '${sprite.name.replace(/'/g, "\\'")}', ${sprite.id})">
                <span class="blip-item-id">${sprite.id}</span>
            </div>
        `;
    }).join('');
}

function createColorPicker(config) {
    const defaultRgb = hexToRgb(config.defaultHex) || { r: 0, g: 0, b: 0 };
    const state = { r: defaultRgb.r, g: defaultRgb.g, b: defaultRgb.b, tempColor: null };

    function el(name) { return SZ.elements[config.elements[name]]; }

    function updateDisplay() {
        const { r, g, b } = state;
        const hex = rgbToHex(r, g, b);
        const native = rgbToNativeHex(r, g, b);
        if (el('swatch')) el('swatch').style.backgroundColor = hex;
        if (el('hexDisplay')) el('hexDisplay').textContent = hex;
        if (el('rgbDisplay')) el('rgbDisplay').textContent = `RGB(${r}, ${g}, ${b})`;
        if (el('nativeDisplay')) el('nativeDisplay').textContent = native;
        if (el('nativeInput')) el('nativeInput').value = hex;
        if (el('hexInput')) el('hexInput').value = hex;
        if (el('sliderR')) el('sliderR').value = r;
        if (el('sliderG')) el('sliderG').value = g;
        if (el('sliderB')) el('sliderB').value = b;
        if (el('valueR')) el('valueR').textContent = r;
        if (el('valueG')) el('valueG').textContent = g;
        if (el('valueB')) el('valueB').textContent = b;
    }

    function initFromCurrent() {
        const currentHex = el('initHex')?.textContent || config.defaultHex;
        const rgb = hexToRgb(currentHex);
        if (rgb) { state.r = rgb.r; state.g = rgb.g; state.b = rgb.b; }
        state.tempColor = { r: state.r, g: state.g, b: state.b };
        updateDisplay();
    }

    function openModal() {
        if (el('modal')) { el('modal').classList.add('active'); initFromCurrent(); }
    }

    function closeModal() {
        if (el('modal')) el('modal').classList.remove('active');
    }

    function selectColor() {
        const hex = rgbToHex(state.r, state.g, state.b);
        const native = rgbToNativeHex(state.r, state.g, state.b);
        if (el('targetValue')) el('targetValue').value = native;
        if (el('targetHex')) el('targetHex').textContent = hex;
        if (el('targetNative')) el('targetNative').textContent = native;
        if (el('targetPreview')) el('targetPreview').style.backgroundColor = hex;
        closeModal();
    }

    function confirm() { selectColor(); }

    function cancel() {
        if (state.tempColor) { state.r = state.tempColor.r; state.g = state.tempColor.g; state.b = state.tempColor.b; }
        closeModal();
    }

    function setValue(colorValue) {
        let hexColor = config.defaultHex;
        if (colorValue) {
            if (typeof colorValue === 'string') {
                if (colorValue.startsWith('0x')) hexColor = '#' + colorValue.slice(2, 8);
                else if (colorValue.startsWith('#')) hexColor = colorValue;
            }
        }
        const rgb = hexToRgb(hexColor);
        if (rgb) {
            state.r = rgb.r; state.g = rgb.g; state.b = rgb.b;
            const native = rgbToNativeHex(rgb.r, rgb.g, rgb.b);
            if (el('targetValue')) el('targetValue').value = native;
            if (el('targetHex')) el('targetHex').textContent = hexColor.toUpperCase();
            if (el('targetNative')) el('targetNative').textContent = native;
            if (el('targetPreview')) el('targetPreview').style.backgroundColor = hexColor;
        }
    }

    function resetToDefault() {
        const rgb = hexToRgb(config.defaultHex);
        if (rgb) { state.r = rgb.r; state.g = rgb.g; state.b = rgb.b; }
    }

    function setupListeners() {
        if (el('nativeInput')) {
            el('nativeInput').addEventListener('input', (e) => {
                const rgb = hexToRgb(e.target.value);
                if (rgb) { state.r = rgb.r; state.g = rgb.g; state.b = rgb.b; updateDisplay(); }
            });
        }
        if (el('hexInput')) {
            el('hexInput').addEventListener('input', (e) => {
                let value = e.target.value;
                if (!value.startsWith('#')) value = '#' + value;
                const rgb = hexToRgb(value);
                if (rgb) { state.r = rgb.r; state.g = rgb.g; state.b = rgb.b; updateDisplay(); }
            });
        }
        ['R', 'G', 'B'].forEach(ch => {
            const slider = el('slider' + ch);
            if (slider) {
                slider.addEventListener('input', (e) => { state[ch.toLowerCase()] = parseInt(e.target.value); updateDisplay(); });
            }
        });
        if (el('confirmBtn')) el('confirmBtn').addEventListener('click', confirm);
        if (el('cancelBtn')) el('cancelBtn').addEventListener('click', cancel);
        if (el('modal')) el('modal').addEventListener('click', (e) => { if (e.target === el('modal')) cancel(); });
        if (el('openBtn')) el('openBtn').addEventListener('click', openModal);
        if (el('closeBtn')) el('closeBtn').addEventListener('click', cancel);
    }

    return { state, updateDisplay, initFromCurrent, openModal, closeModal, selectColor, confirm, cancel, setValue, resetToDefault, setupListeners };
}

const blipColorPicker = createColorPicker({
    defaultHex: '#F5A623',
    elements: {
        swatch: 'colorPickerSwatch', hexDisplay: 'colorHexDisplay', rgbDisplay: 'colorRgbDisplay',
        nativeDisplay: 'colorNativeDisplay', nativeInput: 'colorPickerNative', hexInput: 'colorPickerHexInput',
        sliderR: 'colorSliderR', sliderG: 'colorSliderG', sliderB: 'colorSliderB',
        valueR: 'colorValueR', valueG: 'colorValueG', valueB: 'colorValueB',
        modal: 'blipColorModal', initHex: 'blipColorHex',
        targetValue: 'blipColor', targetHex: 'blipColorHex', targetNative: 'blipColorNative', targetPreview: 'blipColorPreview',
        confirmBtn: 'colorPickerConfirm', cancelBtn: 'colorPickerCancel'
    }
});

const outlineColorPicker = createColorPicker({
    defaultHex: '#F5A623',
    elements: {
        swatch: 'outlinePickerSwatch', hexDisplay: 'outlineHexDisplay', rgbDisplay: 'outlineRgbDisplay',
        nativeDisplay: 'outlineNativeDisplay', nativeInput: 'outlinePickerNative', hexInput: 'outlinePickerHexInput',
        sliderR: 'outlineSliderR', sliderG: 'outlineSliderG', sliderB: 'outlineSliderB',
        valueR: 'outlineValueR', valueG: 'outlineValueG', valueB: 'outlineValueB',
        modal: 'outlineColorModal', initHex: 'outlineColorHex',
        targetValue: 'outlineColor', targetHex: 'outlineColorHex', targetNative: 'outlineColorNative', targetPreview: 'outlineColorPreview',
        confirmBtn: 'outlinePickerConfirm', cancelBtn: 'outlinePickerCancel',
        openBtn: 'outlineColorBtn', closeBtn: 'outlineColorModalClose'
    }
});

const strokeColorPicker = createColorPicker({
    defaultHex: '#FFFFFF',
    elements: {
        swatch: 'strokePickerSwatch', hexDisplay: 'strokeHexDisplay', rgbDisplay: 'strokeRgbDisplay',
        nativeDisplay: 'strokeNativeDisplay', nativeInput: 'strokePickerNative', hexInput: 'strokePickerHexInput',
        sliderR: 'strokeSliderR', sliderG: 'strokeSliderG', sliderB: 'strokeSliderB',
        valueR: 'strokeValueR', valueG: 'strokeValueG', valueB: 'strokeValueB',
        modal: 'strokeColorModal', initHex: 'strokeColorHex',
        targetValue: 'strokeColor', targetHex: 'strokeColorHex', targetNative: 'strokeColorNative', targetPreview: 'strokeColorPreview',
        confirmBtn: 'strokePickerConfirm', cancelBtn: 'strokePickerCancel',
        openBtn: 'strokeColorBtn', closeBtn: 'strokeColorModalClose'
    }
});

const markerColorPicker = createColorPicker({
    defaultHex: '#F5A623',
    elements: {
        swatch: 'markerPickerSwatch', hexDisplay: 'markerHexDisplay', rgbDisplay: 'markerRgbDisplay',
        nativeDisplay: 'markerNativeDisplay', nativeInput: 'markerPickerNative', hexInput: 'markerPickerHexInput',
        sliderR: 'markerSliderR', sliderG: 'markerSliderG', sliderB: 'markerSliderB',
        valueR: 'markerValueR', valueG: 'markerValueG', valueB: 'markerValueB',
        modal: 'markerColorModal', initHex: 'markerColorHex',
        targetValue: 'markerColor', targetHex: 'markerColorHex', targetNative: 'markerColorNative', targetPreview: 'markerColorPreview',
        confirmBtn: 'markerPickerConfirm', cancelBtn: 'markerPickerCancel',
        openBtn: 'markerColorBtn', closeBtn: 'markerColorModalClose'
    }
});

function rgbToHex(r, g, b) {
    return '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('').toUpperCase();
}

function hexToRgb(hex) {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

function rgbToNativeHex(r, g, b, a = 255) {
    return '0x' + [r, g, b, a].map(x => x.toString(16).padStart(2, '0')).join('').toUpperCase();
}


function openBlipModal(type) {
    if (type === 'sprite' && SZ.elements.blipSpriteModal) {
        SZ.elements.blipSpriteModal.classList.add('active');
        SZ.elements.blipSpriteSearch.value = '';
        renderBlipSpriteGrid(BLIP_SPRITES);
        SZ.elements.blipSpriteSearch.focus();
    } else if (type === 'color') {
        blipColorPicker.openModal();
    }
}

function closeBlipModal(type) {
    if (type === 'sprite' && SZ.elements.blipSpriteModal) {
        SZ.elements.blipSpriteModal.classList.remove('active');
    } else if (type === 'color') {
        blipColorPicker.closeModal();
    }
}

function filterBlipGrid(type) {
    if (type === 'sprite') {
        const query = (SZ.elements.blipSpriteSearch?.value || '').toLowerCase();
        const filtered = BLIP_SPRITES.filter(s =>
            s.name.toLowerCase().includes(query) ||
            s.id.toString().includes(query)
        );
        renderBlipSpriteGrid(filtered);
    }
}

function selectBlipSprite(id, name) {
    if (SZ.elements.blipSprite) SZ.elements.blipSprite.value = id;
    if (SZ.elements.blipSpriteId) SZ.elements.blipSpriteId.textContent = id;
    if (SZ.elements.blipSpriteName) SZ.elements.blipSpriteName.textContent = name;

    if (SZ.elements.blipSpritePreview) {
        SZ.elements.blipSpritePreview.src = getBlipImageUrl(id);
        SZ.elements.blipSpritePreview.onerror = function() {
            handleBlipImageError(this, name, id);
        };
    }

    closeBlipModal('sprite');
}

function setOutlineColorPickerValue(colorValue) { outlineColorPicker.setValue(colorValue); }
function setStrokeColorPickerValue(colorValue) { strokeColorPicker.setValue(colorValue); }

function setBlipPickerValues(spriteId, colorValue) {
    const sprite = BLIP_SPRITES.find(s => s.id === spriteId) || BLIP_SPRITES.find(s => s.id === 84);
    if (sprite) {
        selectBlipSprite(sprite.id, sprite.name);
    }

    if (colorValue) {
        let hexColor = '#F5A623';
        if (typeof colorValue === 'string') {
            if (colorValue.startsWith('0x')) {
                hexColor = '#' + colorValue.slice(2, 8);
            } else if (colorValue.startsWith('#')) {
                hexColor = colorValue;
            }
        } else if (typeof colorValue === 'number') {
            const color = BLIP_COLORS.find(c => c.id === colorValue);
            if (color) {
                hexColor = color.hex;
            }
        }

        const rgb = hexToRgb(hexColor);
        if (rgb) {
            blipColorPicker.state.r = rgb.r;
            blipColorPicker.state.g = rgb.g;
            blipColorPicker.state.b = rgb.b;

            const nativeHex = rgbToNativeHex(rgb.r, rgb.g, rgb.b);
            if (SZ.elements.blipColor) SZ.elements.blipColor.value = nativeHex;
            if (SZ.elements.blipColorHex) SZ.elements.blipColorHex.textContent = hexColor.toUpperCase();
            if (SZ.elements.blipColorNative) SZ.elements.blipColorNative.textContent = nativeHex;
            if (SZ.elements.blipColorPreview) SZ.elements.blipColorPreview.style.backgroundColor = hexColor;
        }
    }
}

function switchView(view) {
    Log('UI', 'info', `Switching view to: ${view}`);
    SZ.state.currentView = view;

    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.view === view);
    });

    document.querySelectorAll('.view').forEach(v => {
        v.classList.toggle('active', v.id === `${view}View`);
    });

    const app = SZ.elements.app;
    if (view === 'zones' && (SZ.state.isCreatingZone || SZ.state.isEditingZone)) {
        app.classList.add('form-active');
        if (SZ.elements.zonesSidebar) SZ.elements.zonesSidebar.style.display = 'none';
        if (SZ.elements.zonesList) SZ.elements.zonesList.style.display = 'none';
        if (SZ.elements.zonesEmpty) SZ.elements.zonesEmpty.style.display = 'none';
    } else {
        app.classList.remove('form-active');
    }
    if (view === 'map') {
        app.classList.add('map-expanded');
    } else {
        app.classList.remove('map-expanded');
    }

    if (view === 'map' && SZ.state.mapLoaded) {
        setTimeout(() => {
            resizeCanvas();
            renderMapOptimized();
        }, 300);
    }

    if (view === 'analytics') {
        updateAnalytics();
    } else if (view === 'logs') {
        renderLogs();
    }
}

function startClock() {
    if (SZ._clockInterval) {
        clearInterval(SZ._clockInterval);
        SZ._clockInterval = null;
    }

    const updateTime = () => {
        if (SZ.elements.currentTime) {
            const now = new Date();
            SZ.elements.currentTime.textContent = now.toTimeString().split(' ')[0];
        }
    };

    updateTime();
    SZ._clockInterval = setInterval(updateTime, 1000);
}

function handleSearch() {
    const query = SZ.elements.zoneSearch.value.toLowerCase();
    SZ.state.searchQuery = query;
    renderZones();
}

function setLogsData(logs, meta) {
    Log('DATA', 'info', `Processing logs data: ${Array.isArray(logs) ? logs.length : 0} entries`);
    const normalizedMeta = {
        categories: (meta && meta.categories) || {},
        actions: (meta && meta.actions) || {},
        retentionDays: typeof (meta && meta.retentionDays) === 'number' ? meta.retentionDays : 7,
        ui: (meta && meta.ui) || {}
    };

    const highlightMap = (normalizedMeta.ui && normalizedMeta.ui.highlightCategories) || {};
    const sourceEntries = Array.isArray(logs) ? logs : [];

    SZ.state.logMeta = normalizedMeta;
    SZ.state.logs = sourceEntries.map((entry) => {
        const context = entry.context || {};
        const admin = context.admin || {};
        const zone = context.zone || null;
        const details = context.details || context.payload || null;
        const outcome = context.outcome || null;
        const epochSeconds = typeof entry.epoch === 'number' ? entry.epoch : null;

        let date = null;
        if (epochSeconds && !Number.isNaN(epochSeconds)) {
            date = new Date(epochSeconds * 1000);
        } else if (entry.timestamp) {
            const parsed = Date.parse(entry.timestamp);
            if (!Number.isNaN(parsed)) {
                date = new Date(parsed);
            }
        }

        const adminName = admin.name || 'Unknown';
        const adminId = typeof admin.id !== 'undefined' ? admin.id : null;
        const adminFilterValue = adminId !== null ? String(adminId) : adminName.toLowerCase();
        const adminLabel = adminId !== null ? `${adminName} (#${adminId})` : adminName;

        return {
            raw: entry,
            context,
            category: entry.category || 'GENERAL',
            action: entry.action || 'general',
            message: entry.message || '',
            timestamp: entry.timestamp,
            epoch: epochSeconds,
            date,
            admin,
            adminLabel,
            adminFilterValue,
            zone,
            details,
            outcome,
            identifiers: Array.isArray(admin.identifiers) ? admin.identifiers : [],
            highlight: highlightMap[entry.category] || null
        };
    });

    populateLogFilters();
    updateLogsRetentionLabel();

    if (SZ.elements.logsSearch) {
        SZ.elements.logsSearch.value = SZ.state.logFilters.search;
    }
    if (SZ.elements.logsFromDate) {
        SZ.elements.logsFromDate.value = SZ.state.logFilters.from || '';
    }
    if (SZ.elements.logsToDate) {
        SZ.elements.logsToDate.value = SZ.state.logFilters.to || '';
    }

    if (SZ.state.currentView === 'logs') {
        renderLogs();
    }
}

function updateLogsRetentionLabel() {
    if (!SZ.elements.logsRetentionLabel) {
        return;
    }

    const days = SZ.state.logMeta.retentionDays || 7;
    if (SZ.Localization && typeof SZ.Localization.t === 'function') {
        SZ.elements.logsRetentionLabel.textContent = SZ.Localization.t('logs.retention', { days });
    } else {
        SZ.elements.logsRetentionLabel.textContent = `Retention: ${days} days`;
    }
}

function addSelectOption(select, value, label) {
    const option = document.createElement('option');
    option.value = value;
    option.textContent = label;
    select.appendChild(option);
}

function populateLogFilters() {
    const categories = Object.keys(SZ.state.logMeta.categories || {}).filter(key => SZ.state.logMeta.categories[key]);
    categories.sort();

    const actions = Object.keys(SZ.state.logMeta.actions || {}).filter(key => SZ.state.logMeta.actions[key]);
    actions.sort();

    const adminSelect = SZ.elements.logsAdminFilter;
    const categorySelect = SZ.elements.logsCategoryFilter;
    const actionSelect = SZ.elements.logsActionFilter;

    if (categorySelect) {
        const current = SZ.state.logFilters.category || 'all';
        categorySelect.innerHTML = '';
        addSelectOption(categorySelect, 'all', SZ.Localization.t('logs.filters.category_all'));
        categories.forEach(category => {
            const label = SZ.Localization.t(`logs.categories.${category}`) || category;
            addSelectOption(categorySelect, category, label);
        });
        if (!categories.includes(current)) {
            SZ.state.logFilters.category = 'all';
        }
        categorySelect.value = SZ.state.logFilters.category;
    }

    if (actionSelect) {
        const currentAction = SZ.state.logFilters.action || 'all';
        actionSelect.innerHTML = '';
        addSelectOption(actionSelect, 'all', SZ.Localization.t('logs.filters.action_all'));
        actions.forEach(action => {
            const label = SZ.Localization.t(`logs.actions.${action}`) || action;
            addSelectOption(actionSelect, action, label);
        });
        if (!actions.includes(currentAction)) {
            SZ.state.logFilters.action = 'all';
        }
        actionSelect.value = SZ.state.logFilters.action;
    }

    if (adminSelect) {
        const adminEntries = new Map();
        for (const entry of SZ.state.logs || []) {
            if (entry.adminFilterValue) {
                adminEntries.set(entry.adminFilterValue, entry.adminLabel || entry.adminFilterValue);
            }
        }

        const sortedAdmins = Array.from(adminEntries.entries()).sort((a, b) => a[1].localeCompare(b[1]));
        const currentAdmin = SZ.state.logFilters.admin || 'all';
        adminSelect.innerHTML = '';
        addSelectOption(adminSelect, 'all', SZ.Localization.t('logs.filters.admin_all'));
        sortedAdmins.forEach(([value, label]) => {
            addSelectOption(adminSelect, value, label);
        });
        if (!adminEntries.has(currentAdmin)) {
            SZ.state.logFilters.admin = 'all';
        }
        adminSelect.value = SZ.state.logFilters.admin;
    }

    if (SZ.elements.logsOutcomeFilter) {
        SZ.elements.logsOutcomeFilter.value = SZ.state.logFilters.outcome || 'all';
    }
}

function setLogFilter(key, value) {
    if (!SZ.state.logFilters) {
        SZ.state.logFilters = {};
    }

    let normalizedValue;
    if (key === 'search' || key === 'from' || key === 'to') {
        normalizedValue = value || '';
    } else {
        normalizedValue = value || 'all';
    }
    if (SZ.state.logFilters[key] === normalizedValue) {
        return;
    }

    SZ.state.logFilters[key] = normalizedValue;
    renderLogs();
}

function handleLogsSearch(event) {
    setLogFilter('search', event.target.value || '');
}

function handleLogsFilterChange(event) {
    const { id, value } = event.target;
    if (!id) {
        return;
    }

    switch (id) {
        case 'logsCategoryFilter':
            setLogFilter('category', value || 'all');
            break;
        case 'logsActionFilter':
            setLogFilter('action', value || 'all');
            break;
        case 'logsAdminFilter':
            setLogFilter('admin', value || 'all');
            break;
        case 'logsOutcomeFilter':
            setLogFilter('outcome', value || 'all');
            break;
        default:
            break;
    }
}

function renderLogs() {
    if (!SZ.elements.logsTableBody) {
        return;
    }

    const tbody = SZ.elements.logsTableBody;
    const emptyState = SZ.elements.logsEmpty;
    const filters = SZ.state.logFilters || {};
    const search = (filters.search || '').toLowerCase().trim();
    const categoryFilter = filters.category || 'all';
    const actionFilter = filters.action || 'all';
    const adminFilter = filters.admin || 'all';
    const outcomeFilter = filters.outcome || 'all';

    let fromTime = filters.from ? new Date(`${filters.from}T00:00:00`).getTime() : null;
    fromTime = Number.isNaN(fromTime) ? null : fromTime;
    let toTime = filters.to ? new Date(`${filters.to}T23:59:59`).getTime() : null;
    toTime = Number.isNaN(toTime) ? null : toTime;

    if (fromTime && toTime && fromTime > toTime) {
        const swap = fromTime;
        fromTime = toTime;
        toTime = swap;
    }

    const filtered = (SZ.state.logs || []).filter((entry) => {
        const epochMs = entry.date ? entry.date.getTime() : (entry.epoch ? entry.epoch * 1000 : null);

        if (fromTime && (epochMs === null || epochMs < fromTime)) {
            return false;
        }
        if (toTime && (epochMs === null || epochMs > toTime)) {
            return false;
        }

        if (categoryFilter !== 'all' && entry.category !== categoryFilter) {
            return false;
        }

        if (actionFilter !== 'all' && entry.action !== actionFilter) {
            return false;
        }

        if (adminFilter !== 'all' && entry.adminFilterValue !== adminFilter) {
            return false;
        }

        if (outcomeFilter !== 'all') {
            const hasOutcome = entry.outcome && typeof entry.outcome.success === 'boolean';
            const outcomeState = hasOutcome ? (entry.outcome.success ? 'success' : 'failure') : 'none';
            if (outcomeFilter === 'success' && outcomeState !== 'success') {
                return false;
            }
            if (outcomeFilter === 'failure' && outcomeState !== 'failure') {
                return false;
            }
        }

        if (search) {
            const haystack = [
                entry.category,
                entry.action,
                entry.message,
                entry.adminLabel,
                entry.zone && entry.zone.name,
                entry.zone && entry.zone.type,
                entry.zone && entry.zone.isCustom ? 'custom' : ''
            ];

            if (entry.details && typeof entry.details === 'object') {
                haystack.push(JSON.stringify(entry.details));
            }

            if (entry.outcome && typeof entry.outcome.success === 'boolean') {
                haystack.push(entry.outcome.success ? 'success' : 'failure');
            }

            entry.identifiers.forEach(identifier => {
                if (identifier && identifier.type && identifier.value) {
                    haystack.push(`${identifier.type}:${identifier.value}`);
                }
            });

            const matchesSearch = haystack.some(value => (value || '').toString().toLowerCase().includes(search));
            if (!matchesSearch) {
                return false;
            }
        }

        return true;
    }).sort((a, b) => {
        const aTime = a.date ? a.date.getTime() : (a.epoch ? a.epoch * 1000 : 0);
        const bTime = b.date ? b.date.getTime() : (b.epoch ? b.epoch * 1000 : 0);
        return bTime - aTime;
    });

    tbody.innerHTML = '';

    if (!filtered.length) {
        if (emptyState) {
            emptyState.classList.remove('hidden');
        }
        return;
    }

    if (emptyState) {
        emptyState.classList.add('hidden');
    }

    const fragment = document.createDocumentFragment();

    filtered.forEach((entry) => {
        const row = document.createElement('tr');

        const timeCell = document.createElement('td');
        const timeWrapper = document.createElement('div');
        timeWrapper.className = 'log-time';
        const timeText = document.createElement('span');
        if (entry.date && !Number.isNaN(entry.date.getTime())) {
            timeText.textContent = entry.date.toLocaleTimeString();
            const dateSpan = document.createElement('span');
            dateSpan.className = 'log-date';
            dateSpan.textContent = entry.date.toLocaleDateString();
            timeWrapper.appendChild(timeText);
            timeWrapper.appendChild(dateSpan);
        } else {
            timeText.textContent = entry.timestamp || '-';
            timeWrapper.appendChild(timeText);
        }
        timeCell.appendChild(timeWrapper);
        row.appendChild(timeCell);

        const categoryCell = document.createElement('td');
        const categoryBadge = document.createElement('span');
        categoryBadge.className = 'log-category';
        const categoryLabel = SZ.Localization.t(`logs.categories.${entry.category}`) || entry.category;
        categoryBadge.textContent = categoryLabel;
        if (entry.highlight) {
            applyCategoryColor(categoryBadge, entry.highlight);
        }
        categoryCell.appendChild(categoryBadge);
        row.appendChild(categoryCell);

        const actionCell = document.createElement('td');
        actionCell.textContent = SZ.Localization.t(`logs.actions.${entry.action}`) || entry.action;
        row.appendChild(actionCell);

        const adminCell = document.createElement('td');
        adminCell.className = 'log-admin';

        const adminInfo = document.createElement('div');
        adminInfo.className = 'admin-info';
        adminInfo.textContent = entry.adminLabel;
        if (entry.admin && typeof entry.admin.id !== 'undefined') {
            const idBadge = document.createElement('span');
            idBadge.className = 'admin-id-badge';
            idBadge.textContent = `#${entry.admin.id}`;
            adminInfo.appendChild(idBadge);
        }
        adminCell.appendChild(adminInfo);

        if (entry.admin) {
            const identifiersRow = document.createElement('div');
            identifiersRow.className = 'admin-identifiers';

            const steamChip = document.createElement('span');
            steamChip.className = 'id-chip id-chip-steam';
            if (entry.admin.hasSteam === false || entry.admin.steam === 'NO_STEAM') {
                steamChip.classList.add('id-chip-missing');
                steamChip.innerHTML = `<span class="id-label">STEAM</span><span class="id-value">${SZ.Localization.t('logs.details.na')}</span>`;
            } else {
                steamChip.innerHTML = `<span class="id-label">STEAM</span><span class="id-value">${entry.admin.steam}</span>`;
            }
            identifiersRow.appendChild(steamChip);

            const discordChip = document.createElement('span');
            discordChip.className = 'id-chip id-chip-discord';
            if (entry.admin.hasDiscord === false || entry.admin.discord === 'NO_DISCORD') {
                discordChip.classList.add('id-chip-missing');
                discordChip.innerHTML = `<span class="id-label">DISCORD</span><span class="id-value">${SZ.Localization.t('logs.details.na')}</span>`;
            } else {
                discordChip.innerHTML = `<span class="id-label">DISCORD</span><span class="id-value">${entry.admin.discord}</span>`;
            }
            identifiersRow.appendChild(discordChip);

            const licenseChip = document.createElement('span');
            licenseChip.className = 'id-chip id-chip-license';
            if (entry.admin.hasLicense === false || entry.admin.license === 'NO_LICENSE') {
                licenseChip.classList.add('id-chip-missing');
                licenseChip.innerHTML = `<span class="id-label">LICENSE</span><span class="id-value">${SZ.Localization.t('logs.details.na')}</span>`;
            } else {
                licenseChip.innerHTML = `<span class="id-label">LICENSE</span><span class="id-value">${entry.admin.license}</span>`;
            }
            identifiersRow.appendChild(licenseChip);

            adminCell.appendChild(identifiersRow);
        }
        row.appendChild(adminCell);

        const messageCell = document.createElement('td');
        messageCell.className = 'log-message';
        messageCell.textContent = entry.message;
        row.appendChild(messageCell);

        const detailsCell = document.createElement('td');
        const detailsWrapper = document.createElement('div');
        detailsWrapper.className = 'log-details';

        if (entry.zone && entry.zone.name) {
            detailsWrapper.appendChild(createLogChip(SZ.Localization.t('logs.details.zone'), entry.zone.name));
        }
        if (entry.zone && entry.zone.type) {
            detailsWrapper.appendChild(createLogChip(SZ.Localization.t('logs.details.type'), entry.zone.type));
        }
        if (entry.zone && typeof entry.zone.isCustom === 'boolean') {
            detailsWrapper.appendChild(createLogChip(SZ.Localization.t('logs.details.custom'), entry.zone.isCustom ? SZ.Localization.t('logs.details.yes') : SZ.Localization.t('logs.details.no')));
        }

        if (entry.details && typeof entry.details === 'object') {
            Object.entries(entry.details).forEach(([key, value]) => {
                if (value === null || value === undefined) {
                    return;
                }
                const formattedValue = typeof value === 'object' ? JSON.stringify(value) : value;
                detailsWrapper.appendChild(createLogChip(capitalizeLabel(key), formattedValue));
            });
        }

        if (entry.context && entry.context.position) {
            const pos = entry.context.position;
            if (typeof pos === 'object') {
                const components = ['x', 'y', 'z', 'heading'].map(axis => {
                    if (typeof pos[axis] === 'number') {
                        return `${axis.toUpperCase()}:${pos[axis].toFixed(2)}`;
                    }
                    return null;
                }).filter(Boolean);
                if (components.length) {
                    detailsWrapper.appendChild(createLogChip(SZ.Localization.t('logs.details.position'), components.join(' ')));
                }
            }
        }

        if (entry.outcome && typeof entry.outcome.success === 'boolean') {
            const outcomeChip = createLogChip(SZ.Localization.t('logs.details.outcome'), entry.outcome.success ? SZ.Localization.t('logs.details.success') : SZ.Localization.t('logs.details.failure'));
            outcomeChip.classList.add(entry.outcome.success ? 'success' : 'failure');
            if (entry.outcome.reason) {
                outcomeChip.title = entry.outcome.reason;
            }
            detailsWrapper.appendChild(outcomeChip);
        }

        entry.identifiers.forEach(identifier => {
            if (!identifier || !identifier.type || !identifier.value) {
                return;
            }
            detailsWrapper.appendChild(createLogChip(identifier.type.toUpperCase(), formatIdentifier(identifier.value)));
        });

        if (!detailsWrapper.childNodes.length) {
            detailsWrapper.textContent = SZ.Localization.t('logs.no_details');
        }

        detailsCell.appendChild(detailsWrapper);
        row.appendChild(detailsCell);

        fragment.appendChild(row);
    });

    tbody.appendChild(fragment);
}

function createLogChip(label, value) {
    const chip = document.createElement('span');
    chip.className = 'log-chip';
    const labelElement = document.createElement('strong');
    labelElement.textContent = `${label}:`;
    const valueElement = document.createElement('span');
    valueElement.className = 'log-chip-value';
    const normalizedValue = value === undefined || value === null ? '' : String(value);
    valueElement.textContent = normalizedValue;
    valueElement.title = normalizedValue;
    chip.appendChild(labelElement);
    chip.appendChild(valueElement);
    return chip;
}

function formatIdentifier(identifier) {
    return String(identifier);
}

function capitalizeLabel(label) {
    return label.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase());
}

function applyCategoryColor(element, color) {
    if (!element || !color) {
        return;
    }

    element.style.border = `1px solid ${color}`;
    element.style.color = color;
    element.style.backgroundColor = hexToRgba(color, 0.18);
}

function hexToRgba(color, alpha) {
    if (typeof color !== 'string') {
        return color;
    }

    if (color.startsWith('#')) {
        let hex = color.slice(1);
        if (hex.length === 3) {
            hex = hex.split('').map((char) => char + char).join('');
        }
        const numeric = parseInt(hex, 16);
        if (Number.isNaN(numeric)) {
            return color;
        }
        const r = (numeric >> 16) & 255;
        const g = (numeric >> 8) & 255;
        const b = numeric & 255;
        return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }

    return color;
}
function setPolygonCreationMode(mode) {
    const normalized = mode === 'creator' ? 'creator' : 'manual';
    SZ.state.polygonCreationMode = normalized;

    document.querySelectorAll('.polygon-mode-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === normalized);
    });

    document.querySelectorAll('.polygon-mode-content').forEach(content => {
        content.classList.toggle('hidden', content.dataset.mode !== normalized);
    });
}

function setCircleCreationMode(mode) {
    const normalized = mode === 'creator' ? 'creator' : 'manual';
    SZ.state.circleCreationMode = normalized;

    const circleManualBtn = SZ.elements.circleManualModeBtn;
    const circleCreatorBtn = SZ.elements.circleCreatorModeBtn;

    if (circleManualBtn) {
        circleManualBtn.classList.toggle('active', normalized === 'manual');
    }
    if (circleCreatorBtn) {
        circleCreatorBtn.classList.toggle('active', normalized === 'creator');
    }

    document.querySelectorAll('.circle-mode-content').forEach(content => {
        content.classList.toggle('hidden', content.dataset.mode !== normalized);
    });

    if (SZ.elements.circleManualInputs) {
        SZ.elements.circleManualInputs.classList.toggle('hidden', normalized === 'creator');
    }
}

function showCreateForm(defaultType) {
    const zoneType = defaultType === 'polygon' ? 'polygon' : 'circle';
    Log('ZONE', 'info', `Opening zone creation form (type: ${zoneType})`);

    if (_hideFormTimeout) {
        clearTimeout(_hideFormTimeout);
        _hideFormTimeout = null;
    }
    _hideFormId++;

    SZ.state.isCreatingZone = true;
    SZ.elements.zoneForm.classList.remove('hidden');
    SZ.elements.zoneForm.classList.remove('form-hiding');
    SZ.elements.zoneForm.style.animation = 'none';
    SZ.elements.zoneForm.offsetHeight;
    SZ.elements.zoneForm.style.animation = '';
    SZ.elements.zoneName.focus();

    requestAnimationFrame(() => refreshAllSliderFills());

    const app = document.getElementById('app');
    if (app) app.classList.add('form-active');

    if (SZ.elements.fabCreateZone) {
        SZ.elements.fabCreateZone.style.display = 'none';
    }

    if (SZ.elements.zonesSidebar) {
        SZ.elements.zonesSidebar.style.display = 'none';
    }
    if (SZ.elements.zonesList) {
        SZ.elements.zonesList.style.display = 'none';
    }
    if (SZ.elements.zonesEmpty) {
        SZ.elements.zonesEmpty.style.display = 'none';
    }

    selectZoneType(zoneType);

    if (zoneType === 'polygon') {
        setPolygonCreationMode(SZ.state.polygonCreationMode || 'manual');
        setCircleCreationMode('manual');
    } else {
        setPolygonCreationMode('manual');
        setCircleCreationMode(SZ.state.circleCreationMode || 'manual');
    }

    toggleMarkerConfig(SZ.elements.showMarker.checked);

    toggleBlipConfig(SZ.elements.showBlip.checked);
    setBlipPickerValues(84, 25);
    resetBlipConfigSettings();
    updateCoverageSectionVisibility(zoneType);
    initializeBlipGrids();
}

let _hideFormTimeout = null;
let _hideFormId = 0;

function hideCreateForm() {
    Log('ZONE', 'info', 'Closing zone creation/edit form');
    SZ.state.isCreatingZone = false;
    SZ.state.isEditingZone = false;
    SZ.state.editingZone = null;

    if (_hideFormTimeout) {
        clearTimeout(_hideFormTimeout);
        _hideFormTimeout = null;
    }

    const thisHideId = ++_hideFormId;

    SZ.elements.zoneForm.classList.add('form-hiding');

    let finished = false;
    const finishHide = () => {
        if (finished || thisHideId !== _hideFormId) return;
        finished = true;

        SZ.elements.zoneForm.classList.add('hidden');
        SZ.elements.zoneForm.classList.remove('form-hiding');

        SZ.elements.createZoneForm.reset();
        SZ.elements.radiusRange.value = 50;
        clearPolygonPoints();

        document.getElementById('editingZoneId').value = '';
        document.getElementById('editingZoneName').value = '';

        const formTitle = document.querySelector('.zone-form h3');
        if (formTitle) {
            formTitle.textContent = SZ.Localization.t('form.create_title');
        }

        const submitBtn = document.querySelector('#createZoneForm button[type="submit"]');
        if (submitBtn) {
            const submitSpan = submitBtn.querySelector('span');
            if (submitSpan) {
                submitSpan.textContent = SZ.Localization.t('form.create');
            }
        }

        if (SZ.elements.fabCreateZone) {
            SZ.elements.fabCreateZone.style.display = 'flex';
        }

        if (SZ.elements.zonesSidebar) {
            SZ.elements.zonesSidebar.style.display = 'flex';
        }
        if (SZ.elements.zonesList) {
            SZ.elements.zonesList.style.display = '';
        }
        if (SZ.elements.zonesEmpty) {
            SZ.elements.zonesEmpty.style.display = '';
        }

        renderZones();

        SZ.state.zoneCreationType = 'circle';
        setPolygonCreationMode('manual');
        setCircleCreationMode('manual');
        document.querySelectorAll('.type-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.type === 'circle');
        });
        document.querySelectorAll('.circle-options').forEach(el => {
            el.style.display = 'block';
        });
        document.querySelectorAll('.polygon-options').forEach(el => {
            el.style.display = 'none';
        });
    };

    const app = document.getElementById('app');
    if (app) app.classList.remove('form-active');

    SZ.elements.zoneForm.addEventListener('animationend', finishHide, { once: true });

    _hideFormTimeout = setTimeout(() => {
        _hideFormTimeout = null;
        if (SZ.elements.zoneForm.classList.contains('form-hiding')) {
            finishHide();
        }
    }, 350);
}

function selectZoneType(type) {
    SZ.state.zoneCreationType = type;

    if (type === 'polygon') {
        setPolygonCreationMode(SZ.state.polygonCreationMode || 'manual');
    }

    document.querySelectorAll('.type-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.type === type);
    });

    document.querySelectorAll('.circle-options').forEach(el => {
        el.style.display = type === 'circle' ? 'block' : 'none';
    });

    document.querySelectorAll('.polygon-options').forEach(el => {
        el.style.display = type === 'polygon' ? 'block' : 'none';
    });

    const markerTypeSection = document.querySelector('.marker-type-grid')?.parentElement;
    if (markerTypeSection) {
        if (type === 'polygon') {
            markerTypeSection.style.display = 'none';
        } else {
            markerTypeSection.style.display = 'block';
            
            const activeMarkerBtn = document.querySelector('.marker-type-btn.active');
            if (!activeMarkerBtn) {
                const firstMarkerBtn = document.querySelector('.marker-type-btn');
                if (firstMarkerBtn) {
                    firstMarkerBtn.classList.add('active');
                }
            }
        }
    }

    if (type === 'polygon') {
        initializePolygonPoints();
    }

    updateCoverageSectionVisibility(type);
}

function initializePolygonPoints() {
    clearPolygonPoints();

    for (let i = 0; i < 3; i++) {
        addPolygonPoint();
    }
}

function addPolygonPoint() {
    if (!SZ.elements.polygonPointInputs) {
        Log('ZONE', 'error', 'polygonPointInputs element not found');
        return;
    }

    const container = SZ.elements.polygonPointInputs;
    const index = container.children.length;

    const pointRow = document.createElement('div');
    pointRow.className = 'point-input-row';
    pointRow.innerHTML = `
        <div class="point-number">${index + 1}</div>
        <div class="point-content">
            <div class="point-coords-group">
                <input type="number" class="coord-input" placeholder="${SZ.Localization.t('form.x_coordinate')}" step="0.01" data-index="${index}" data-coord="x">
                <input type="number" class="coord-input" placeholder="${SZ.Localization.t('form.y_coordinate')}" step="0.01" data-index="${index}" data-coord="y">
                <input type="number" class="coord-input" placeholder="${SZ.Localization.t('form.z_coordinate')}" step="0.01" data-index="${index}" data-coord="z">
            </div>
            <div class="point-controls">
                <button type="button" class="btn btn-secondary btn-use-location" data-index="${index}" title="${SZ.Localization.t('form.use_current_location')}">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                        <path d="M12 2C6.48 2 2 6.48 2 12S6.48 22 12 22 22 17.52 22 12 17.52 2 12 2ZM12 20C7.58 20 4 16.42 4 12S7.58 4 12 4 20 7.58 20 12 16.42 20 12 20Z" fill="currentColor"/>
                        <circle cx="12" cy="12" r="3" fill="currentColor"/>
                    </svg>
                    ${SZ.Localization.t('form.use_current_location')}
                </button>
                <button type="button" class="btn btn-icon btn-copy-coords" data-index="${index}" title="${SZ.Localization.t('form.copy_coordinates')}">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                        <rect x="9" y="9" width="13" height="13" rx="2" stroke="currentColor" stroke-width="2"/>
                        <path d="M5 15H4C2.89543 15 2 14.1046 2 13V4C2 2.89543 2.89543 2 4 2H13C14.1046 2 15 2.89543 15 4V5" stroke="currentColor" stroke-width="2"/>
                    </svg>
                </button>
                <button type="button" class="btn btn-icon btn-remove-point" ${index < 3 ? 'disabled' : ''} title="${SZ.Localization.t('form.remove_point')}">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                        <path d="M18 6L6 18M6 6L18 18" stroke="currentColor" stroke-width="2"/>
                    </svg>
                </button>
            </div>
        </div>
    `;

    container.appendChild(pointRow);

    pointRow.querySelector('.btn-use-location').addEventListener('click', function () {
        sendNUI('getPlayerCoordsForPoint', { pointIndex: this.dataset.index });
    });

    pointRow.querySelector('.btn-copy-coords').addEventListener('click', function () {
        const idx = this.dataset.index;
        const xInput = container.querySelector(`input[data-index="${idx}"][data-coord="x"]`);
        const yInput = container.querySelector(`input[data-index="${idx}"][data-coord="y"]`);
        const zInput = container.querySelector(`input[data-index="${idx}"][data-coord="z"]`);

        if (xInput.value && yInput.value && zInput.value) {
            const coordText = `vector3(${formatCoordinate(xInput.value)}, ${formatCoordinate(yInput.value)}, ${formatCoordinate(zInput.value)})`;
            if (copyToClipboard(coordText)) {
                showNotification(SZ.Localization.t('notifications.coords_copied'), 'success');
            }
        } else {
            showNotification(SZ.Localization.t('notifications.enter_coords'), 'error');
        }
    });

    pointRow.querySelector('.btn-remove-point').addEventListener('click', function () {
        removePolygonPoint(index);
    });

    const inputs = pointRow.querySelectorAll('.coord-input');
    inputs.forEach(input => {
        input.addEventListener('input', updatePolygonMinMaxZ);
    });
}

function updatePolygonMinMaxZ() {
    const infiniteHeightPolygon = document.getElementById('infiniteHeightPolygon');
    if (infiniteHeightPolygon && infiniteHeightPolygon.checked) {
        return;
    }

    const container = SZ.elements.polygonPointInputs;
    const zInputs = container.querySelectorAll('input[data-coord="z"]');

    let minZ = Infinity;
    let maxZ = -Infinity;
    let hasValidZ = false;

    zInputs.forEach(input => {
        const value = parseFloat(input.value);
        if (!isNaN(value)) {
            hasValidZ = true;
            minZ = Math.min(minZ, value);
            maxZ = Math.max(maxZ, value);
        }
    });

    if (hasValidZ) {
        SZ.elements.minZ.value = formatCoordinate(minZ - 2);
        SZ.elements.maxZ.value = formatCoordinate(maxZ + 2);
    }
}

function removePolygonPoint(indexToRemove) {
    const container = SZ.elements.polygonPointInputs;
    const rows = container.querySelectorAll('.point-input-row');

    if (rows.length <= 3) {
        showNotification(SZ.Localization.t('notifications.polygon_min_points'), 'error');
        return;
    }

    rows[indexToRemove].remove();

    container.querySelectorAll('.point-input-row').forEach((row, idx) => {
        row.querySelector('.point-number').textContent = idx + 1;
        row.querySelectorAll('input').forEach(input => {
            input.dataset.index = idx;
        });
        row.querySelectorAll('button').forEach(btn => {
            if (btn.dataset.index !== undefined) {
                btn.dataset.index = idx;
            }
            if (btn.classList.contains('btn-remove-point')) {
                btn.disabled = idx < 3;
            }
        });
    });

    updatePolygonMinMaxZ();
}

function clearPolygonPoints() {
    if (SZ.elements.polygonPointInputs) {
        SZ.elements.polygonPointInputs.innerHTML = '';
    }
}

function applyCreatorPointsToForm(points) {
    clearPolygonPoints();
    points.forEach((point, index) => {
        addPolygonPoint();
        const row = SZ.elements.polygonPointInputs?.children[index];
        if (!row) return;
        const xInput = row.querySelector('input[data-coord="x"]');
        const yInput = row.querySelector('input[data-coord="y"]');
        const zInput = row.querySelector('input[data-coord="z"]');
        if (xInput) xInput.value = formatCoordinate(typeof point.x === 'number' ? point.x : 0);
        if (yInput) yInput.value = formatCoordinate(typeof point.y === 'number' ? point.y : 0);
        if (zInput) zInput.value = formatCoordinate(typeof point.z === 'number' ? point.z : 0);
    });
    updatePolygonMinMaxZ();
}

function restoreEditContext() {
    const ctx = SZ.state.pendingEditContext;
    if (!ctx) return;
    SZ.state.pendingEditContext = null;

    SZ.state.isEditingZone = true;
    SZ.state.editingZone = ctx.zone;
    document.getElementById('editingZoneId').value = ctx.zoneId;
    document.getElementById('editingZoneName').value = ctx.originalName;

    loadZoneDataToForm(ctx.zone);

    const formTitle = document.querySelector('.zone-form h3');
    if (formTitle) formTitle.textContent = SZ.Localization.t('form.edit_title');
    const submitBtn = document.querySelector('#createZoneForm button[type="submit"]');
    if (submitBtn) submitBtn.textContent = SZ.Localization.t('form.update');
}

function applyPolygonCreatorPoints(points) {
    if (!Array.isArray(points) || points.length < 3) {
        Log('ZONE', 'warn', `Polygon creator returned insufficient points: ${Array.isArray(points) ? points.length : 'not array'}`);
        showNotification(SZ.Localization.t('notifications.polygon_min_points'), 'error');
        SZ.state.pendingEditContext = null;
        return;
    }
    Log('ZONE', 'info', `Applying ${points.length} polygon creator points`);

    if (SZ.elements.zoneForm.classList.contains('hidden')) {
        showCreateForm('polygon');
    } else {
        selectZoneType('polygon');
    }

    const hadEditContext = !!SZ.state.pendingEditContext;
    if (hadEditContext) {
        restoreEditContext();
    }

    applyCreatorPointsToForm(points);

    setPolygonCreationMode('manual');
    showNotification(SZ.Localization.t('notifications.polygon_creator_imported', { count: points.length }), 'success');
}

function applyCircleCreatorData(center, radius) {
    if (!center || typeof radius !== 'number') {
        Log('ZONE', 'warn', `Circle creator returned invalid data: center=${!!center}, radius=${typeof radius}`);
        showNotification(SZ.Localization.t('notifications.circle_creator_invalid'), 'error');
        SZ.state.pendingEditContext = null;
        return;
    }
    Log('ZONE', 'info', `Applying circle creator data: center=(${center.x?.toFixed(1)}, ${center.y?.toFixed(1)}, ${center.z?.toFixed(1)}), radius=${radius.toFixed(1)}`);

    if (SZ.elements.zoneForm.classList.contains('hidden')) {
        showCreateForm('circle');
    } else {
        selectZoneType('circle');
    }

    const hadEditContext = !!SZ.state.pendingEditContext;
    if (hadEditContext) {
        restoreEditContext();
    }

    if (SZ.elements.coordX) SZ.elements.coordX.value = formatCoordinate(center.x);
    if (SZ.elements.coordY) SZ.elements.coordY.value = formatCoordinate(center.y);
    if (SZ.elements.coordZ) SZ.elements.coordZ.value = formatCoordinate(center.z);

    const clampedRadius = Math.max(10, Math.min(500, Math.round(radius)));
    if (SZ.elements.zoneRadius) SZ.elements.zoneRadius.value = clampedRadius;
    if (SZ.elements.radiusRange) {
        SZ.elements.radiusRange.value = clampedRadius;
        updateSliderFill(SZ.elements.radiusRange);
    }

    if (!hadEditContext) {
        if (SZ.elements.circleMinZ) SZ.elements.circleMinZ.value = formatCoordinate(center.z - 50);
        if (SZ.elements.circleMaxZ) SZ.elements.circleMaxZ.value = formatCoordinate(center.z + 150);
    }

    setCircleCreationMode('manual');
    showNotification(SZ.Localization.t('notifications.circle_creator_imported', { radius: clampedRadius }), 'success');
}

function useCurrentLocation() {
    Log('NUI', 'info', 'Requesting current player coordinates');
    sendNUI('getPlayerCoords');
}

function collectExistingPolygonPoints() {
    const container = SZ.elements.polygonPointInputs;
    if (!container) return null;
    const rows = container.querySelectorAll('.point-input-row');
    if (rows.length < 3) return null;
    const points = [];
    for (let i = 0; i < rows.length; i++) {
        const x = parseFloat(rows[i].querySelector('input[data-coord="x"]')?.value);
        const y = parseFloat(rows[i].querySelector('input[data-coord="y"]')?.value);
        const z = parseFloat(rows[i].querySelector('input[data-coord="z"]')?.value);
        if (isNaN(x) || isNaN(y)) return null;
        points.push({ x, y, z: isNaN(z) ? 0 : z });
    }
    return points.length >= 3 ? points : null;
}

function collectExistingCircleData() {
    const x = parseFloat(SZ.elements.coordX?.value);
    const y = parseFloat(SZ.elements.coordY?.value);
    const z = parseFloat(SZ.elements.coordZ?.value);
    const radius = parseFloat(SZ.elements.zoneRadius?.value);
    if (isNaN(x) || isNaN(y) || isNaN(z) || isNaN(radius)) return null;
    return { center: { x, y, z }, radius };
}

function collectZoneSettings() {
    const isPolygon = SZ.state.zoneCreationType === 'polygon';
    const markerType = isPolygon ? 1 : (document.querySelector('.marker-type-btn.active')?.dataset.markerType ? parseInt(document.querySelector('.marker-type-btn.active').dataset.markerType) : 1);
    const mc = buildMarkerConfig(markerType);
    const showMarker = document.getElementById('showMarker')?.checked || false;

    if (mc.color && mc.alpha !== undefined) {
        mc.color.a = mc.alpha;
    }
    if (mc.color) {
        mc.wallColor = mc.wallColor || { r: mc.color.r, g: mc.color.g, b: mc.color.b, a: Math.floor((mc.alpha || 100) * 0.5) };
        mc.groundColor = mc.groundColor || { r: mc.color.r, g: mc.color.g, b: mc.color.b, a: Math.floor((mc.alpha || 100) * 0.3) };
    }

    const settings = {
        showMarker,
        markerConfig: mc,
        infiniteHeight: false,
        addRoof: false
    };

    if (isPolygon) {
        const infH = document.getElementById('infiniteHeightPolygon');
        settings.infiniteHeight = infH ? infH.checked : false;
        const addRoof = document.getElementById('polygonAddRoof');
        settings.addRoof = addRoof ? addRoof.checked : false;
        if (!settings.infiniteHeight && SZ.elements.minZ && SZ.elements.maxZ) {
            const minZVal = parseFloat(SZ.elements.minZ.value);
            const maxZVal = parseFloat(SZ.elements.maxZ.value);
            if (!isNaN(minZVal)) settings.minZ = minZVal;
            if (!isNaN(maxZVal)) settings.maxZ = maxZVal;
        }
    } else {
        const infH = document.getElementById('infiniteHeight');
        settings.infiniteHeight = infH ? infH.checked : false;
        if (!settings.infiniteHeight && SZ.elements.circleMinZ && SZ.elements.circleMaxZ) {
            const minZVal = parseFloat(SZ.elements.circleMinZ.value);
            const maxZVal = parseFloat(SZ.elements.circleMaxZ.value);
            if (!isNaN(minZVal)) settings.minZ = minZVal;
            if (!isNaN(maxZVal)) settings.maxZ = maxZVal;
        }
    }

    return settings;
}

function buildMarkerConfig(type) {
    const markerHex = (SZ.elements.markerColorHex?.textContent || '#F5A623').trim();
    const markerRgb = hexToRgb(markerHex) || { r: 245, g: 166, b: 35 };
    return {
        type,
        color: markerRgb,
        alpha: parseInt(SZ.elements.markerAlpha.value),
        height: parseFloat(SZ.elements.markerHeight.value),
        bobbing: document.getElementById('markerBobbing')?.checked || false,
        pulsing: document.getElementById('markerPulsing')?.checked || false,
        rotating: document.getElementById('markerRotating')?.checked || false,
        colorShift: document.getElementById('markerColorShift')?.checked || false,
        autoLevel: document.getElementById('markerAutoLevel')?.checked || false,
        pulseSpeed: parseFloat(SZ.elements.pulseSpeed.value),
        bobHeight: parseFloat(SZ.elements.bobHeight.value),
        rotationSpeed: parseFloat(SZ.elements.rotationSpeed.value)
    };
}

async function handleCreateZone(e) {
    e.preventDefault();

    const formData = {
        name: SZ.elements.zoneName.value.trim(),
        type: SZ.state.zoneCreationType,
        blipName: SZ.elements.blipName.value.trim() || `Safe Zone - ${SZ.elements.zoneName.value}`,
        showBlip: SZ.elements.showBlip.checked,
        showMarker: SZ.elements.showMarker.checked,
        blipSprite: parseInt(SZ.elements.blipSprite?.value) || 84,
        blipColor: SZ.elements.blipColor?.value || '0xF5A623FF',

        showCenterBlip: SZ.elements.showCenterBlip?.checked ?? true,
        blipAlpha: parseInt(SZ.elements.blipAlpha?.value) || 180,
        blipScale: parseFloat(SZ.elements.blipScale?.value) || 0.8,
        blipShortRange: SZ.elements.blipShortRange?.checked ?? false,
        blipHiddenOnLegend: SZ.elements.blipHiddenOnLegend?.checked ?? false,
        blipHighDetail: SZ.elements.blipHighDetail?.checked ?? true,

        showZoneOutline: SZ.elements.showZoneOutline?.checked ?? true,
        outlineRadius: parseFloat(SZ.elements.outlineRadius?.value) || 1.2,
        outlineSpacing: parseFloat(SZ.elements.outlineSpacing?.value) || 6.0,
        outlineAlpha: parseInt(SZ.elements.outlineAlpha?.value) || 160,
        outlineColor: SZ.elements.outlineColor?.value || '#F5A623',

        outlineStrokeEnabled: SZ.elements.outlineStrokeEnabled?.checked ?? true,
        strokeRadius: parseFloat(SZ.elements.strokeRadius?.value) || 1.5,
        strokeColor: SZ.elements.strokeColor?.value || '#FFFFFF',
        strokeAlpha: parseInt(SZ.elements.strokeAlpha?.value) || 220,

        circleCoverageType: SZ.elements.circleCoverageType?.value || 'full'
    };

    const isEditing = SZ.state.isEditingZone;
    const editingZoneId = document.getElementById('editingZoneId').value;
    const originalZoneName = document.getElementById('editingZoneName').value;

    if (isEditing) {
        formData.id = editingZoneId;
        formData.originalName = originalZoneName;
    }

    if (SZ.state.zoneCreationType === 'circle') {
        formData.radius = parseFloat(SZ.elements.zoneRadius.value);
        formData.coords = {
            x: parseFloat(SZ.elements.coordX.value),
            y: parseFloat(SZ.elements.coordY.value),
            z: parseFloat(SZ.elements.coordZ.value)
        };

        if (isNaN(formData.coords.x) || isNaN(formData.coords.y) || isNaN(formData.coords.z)) {
            Log('ZONE', 'warn', 'Zone creation failed: invalid circle coordinates', formData.coords);
            showNotification(SZ.Localization.t('notifications.invalid_coordinates'), 'error');
            return;
        }

        if (SZ.elements.infiniteHeight.checked) {
            formData.infiniteHeight = true;
        } else {
            formData.minZ = parseFloat(SZ.elements.circleMinZ.value);
            formData.maxZ = parseFloat(SZ.elements.circleMaxZ.value);
        }

        formData.enableInvincibility = document.getElementById('circle-enable-invincibility').checked;
        formData.enableGhosting = document.getElementById('circle-enable-ghosting').checked;
        formData.preventVehicleDamage = document.getElementById('circle-prevent-vehicle-damage').checked;
        formData.disableVehicleWeapons = document.getElementById('circle-disable-vehicle-weapons').checked;
        formData.collisionDisabled = document.getElementById('circle-collision-disabled').checked;
    } else {
        const container = SZ.elements.polygonPointInputs;
        const rows = container.querySelectorAll('.point-input-row');
        const points = [];

        for (let i = 0; i < rows.length; i++) {
            const xInput = rows[i].querySelector(`input[data-coord="x"]`);
            const yInput = rows[i].querySelector(`input[data-coord="y"]`);

            const x = parseFloat(xInput.value);
            const y = parseFloat(yInput.value);

            if (isNaN(x) || isNaN(y)) {
                Log('ZONE', 'warn', `Zone creation failed: invalid polygon point ${i + 1}`);
                showNotification(SZ.Localization.t('notifications.invalid_point', { index: i + 1 }), 'error');
                return;
            }

            points.push({ x, y });
        }

        if (points.length < 3) {
            Log('ZONE', 'warn', `Zone creation failed: only ${points.length} polygon points (minimum 3)`);
            showNotification(SZ.Localization.t('notifications.polygon_min_points'), 'error');
            return;
        }

        formData.points = points;

        if (SZ.elements.infiniteHeightPolygon.checked) {
            formData.infiniteHeight = true;
        } else {
            formData.minZ = parseFloat(SZ.elements.minZ.value);
            formData.maxZ = parseFloat(SZ.elements.maxZ.value);
        }

        if (!formData.infiniteHeight && formData.minZ >= formData.maxZ) {
            Log('ZONE', 'warn', `Zone creation failed: invalid Z bounds (minZ: ${formData.minZ}, maxZ: ${formData.maxZ})`);
            showNotification(SZ.Localization.t('notifications.invalid_z_bounds'), 'error');
            return;
        }

        formData.enableInvincibility = document.getElementById('polygon-enable-invincibility').checked;
        formData.enableGhosting = document.getElementById('polygon-enable-ghosting').checked;
        formData.preventVehicleDamage = document.getElementById('polygon-prevent-vehicle-damage').checked;
        formData.disableVehicleWeapons = document.getElementById('polygon-disable-vehicle-weapons').checked;
        formData.collisionDisabled = document.getElementById('polygon-collision-disabled').checked;

        formData.addRoof = SZ.elements.polygonAddRoof ? SZ.elements.polygonAddRoof.checked : false;
    }

    if (formData.showMarker) {
        const markerType = SZ.state.zoneCreationType === 'polygon'
            ? 1
            : (document.querySelector('.marker-type-btn.active')?.dataset.markerType
                ? parseInt(document.querySelector('.marker-type-btn.active').dataset.markerType) : 1);

        formData.markerConfig = buildMarkerConfig(markerType);
    }
    if (SZ.elements.renderDistance) {
        formData.renderDistance = parseFloat(SZ.elements.renderDistance.value) || 150;
    } else {
        formData.renderDistance = 150;
    }

    if (isEditing) {
        Log('ZONE', 'info', `Updating zone: "${formData.name}" (type: ${formData.type})`);
        sendNUI('updateZone', { zoneData: formData });
        showNotification(SZ.Localization.t('notifications.zone_updated'), 'success');
    } else {
        Log('ZONE', 'info', `Creating zone: "${formData.name}" (type: ${formData.type})`);
        sendNUI('createZone', { zoneData: formData });
    }

    hideCreateForm();
}

function updateZoneStats() {
    const zones = SZ.state.zones;
    const players = SZ.state.players;

    if (SZ.elements.totalZoneStat) {
        SZ.elements.totalZoneStat.textContent = zones.length;
    }

    const customCount = zones.filter(z => z.isCustom).length;
    if (SZ.elements.customZoneStat) {
        SZ.elements.customZoneStat.textContent = customCount;
    }

    const activeZones = new Set(players.map(p => p.zoneName)).size;
    if (SZ.elements.activeZoneStat) {
        SZ.elements.activeZoneStat.textContent = activeZones;
    }

    if (SZ.elements.totalPlayersStat) {
        SZ.elements.totalPlayersStat.textContent = players.length;
    }

    if (SZ.elements.filterAllCount) {
        SZ.elements.filterAllCount.textContent = zones.length;
    }
    if (SZ.elements.filterConfigCount) {
        SZ.elements.filterConfigCount.textContent = zones.filter(z => !z.isCustom).length;
    }
    if (SZ.elements.filterCustomCount) {
        SZ.elements.filterCustomCount.textContent = customCount;
    }
    if (SZ.elements.filterActiveCount) {
        SZ.elements.filterActiveCount.textContent = zones.filter(z =>
            players.some(p => p.zoneName === z.name)
        ).length;
    }

    updateQuickActions();
}

function updateQuickActions() {
    const toggleBtn = SZ.elements.toggleAllZonesBtn;

    if (toggleBtn) {
        const hasZones = SZ.state.zones.length > 0;
        if (!hasZones) {
            if (SZ.elements.toggleAllZonesLabel) {
                SZ.elements.toggleAllZonesLabel.textContent = SZ.Localization.t('zones.actions.toggle_all');
            }
            toggleBtn.disabled = true;
            toggleBtn.classList.remove('btn-danger');
            toggleBtn.classList.add('btn-secondary');
            toggleBtn.dataset.activate = 'true';
        } else {
            toggleBtn.disabled = false;

            const anyInactive = SZ.state.zones.some(zone => zone.isActive === false);
            const label = anyInactive
                ? SZ.Localization.t('zones.actions.activate_all')
                : SZ.Localization.t('zones.actions.deactivate_all');

            if (SZ.elements.toggleAllZonesLabel) {
                SZ.elements.toggleAllZonesLabel.textContent = label;
            }

            toggleBtn.classList.toggle('btn-danger', !anyInactive);
            toggleBtn.classList.toggle('btn-secondary', anyInactive);
            toggleBtn.dataset.activate = anyInactive ? 'true' : 'false';
        }
    }

    updateDebugButtons();
}

function normalizeDebugMode(mode) {
    if (typeof mode !== 'string') {
        return 'all';
    }

    const lower = mode.toLowerCase();
    return DEBUG_MODES.includes(lower) ? lower : 'all';
}

function setZoneDebugStates(states) {
    if (states && typeof states === 'object' && !Array.isArray(states)) {
        SZ.state.zoneDebugStates = { ...states };
    } else {
        SZ.state.zoneDebugStates = {};
    }
}

function zoneMatchesDebugMode(zone) {
    if (!zone) {
        return false;
    }

    const mode = SZ.state.debugMode;

    if (mode === 'single') {
        return zone.id == SZ.state.singleZoneId;
    }

    if (mode === 'inactive') {
        return zone.isActive === false;
    }

    if (mode === 'active') {
        return zone.isActive !== false;
    }

    return true;
}

function computeZoneDebugState(zone) {
    const states = SZ.state.zoneDebugStates || {};
    const zoneName = zone && typeof zone.name === 'string' ? zone.name : null;
    const manual = zoneName ? states[zoneName] : undefined;
    const matchesMode = zoneMatchesDebugMode(zone);
    const effective = manual !== undefined ? manual : (SZ.state.debugEnabled && matchesMode);

    return {
        manual,
        matchesMode,
        effective
    };
}

function getZoneDebugStatusText(debugState) {
    if (debugState.manual === true) {
        return SZ.Localization.t('zones.actions.debug_manual_on');
    }

    if (debugState.manual === false) {
        return SZ.Localization.t('zones.actions.debug_manual_off');
    }

    if (SZ.state.debugEnabled) {
        if (debugState.matchesMode) {
            return SZ.Localization.t('zones.actions.debug_status_on');
        }
        return SZ.Localization.t('zones.actions.debug_status_filtered');
    }

    return SZ.Localization.t('zones.actions.debug_status_disabled');
}

function applyDebugState(debugState) {
    if (debugState) {
        if (typeof debugState.enabled === 'boolean') {
            SZ.state.debugEnabled = debugState.enabled;
        }

        const newMode = typeof debugState.mode === 'string' ? debugState.mode : 'all';
        SZ.state.debugMode = normalizeDebugMode(newMode);

        if (debugState.singleZoneId !== undefined && debugState.singleZoneId !== null) {
            SZ.state.singleZoneId = debugState.singleZoneId;
        } else {
            SZ.state.singleZoneId = null;
        }

        if (debugState.states !== undefined) {
            setZoneDebugStates(debugState.states);
        }
    }

    updateDebugButtons();
}

function updateDebugButtons() {
    const buttons = document.querySelectorAll('[data-debug-mode]');
    if (!buttons.length) {
        return;
    }

    buttons.forEach(button => {
        const mode = normalizeDebugMode(button.dataset.debugMode);
        const isActive = SZ.state.debugEnabled && SZ.state.debugMode === mode;
        button.classList.toggle('is-active', isActive);
        button.setAttribute('aria-pressed', isActive ? 'true' : 'false');
    });
}

async function handleDebugButtonClick(mode) {
    const normalizedMode = normalizeDebugMode(mode);
    const isActive = SZ.state.debugEnabled && SZ.state.debugMode === normalizedMode;
    const enable = !isActive;

    const notifKey = enable
        ? `notifications.debug_enabling_${normalizedMode}`
        : 'notifications.debug_disabling';

    showNotification(SZ.Localization.t(notifKey), enable ? 'info' : 'warning');

    try {
        const success = await sendNUI('toggleDebugZones', { mode: normalizedMode, enable });
        if (!success) {
            Log('ZONE', 'warn', `toggleDebugZones request failed for mode: ${normalizedMode}`);
        }
    } catch (error) {
        Log('ZONE', 'warn', 'Error sending toggleDebugZones request:', error);
    }
}

function updateSelectedZoneReference() {
    if (!SZ.state.selectedZone) {
        return;
    }

    const updatedZone = SZ.state.zones.find(z => z.name === SZ.state.selectedZone.name);
    if (updatedZone) {
        SZ.state.selectedZone = updatedZone;
    }
}

function refreshActivationUI() {
    updateZoneStats();

    if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
        renderZones();
    } else if (SZ.state.currentView === 'map' && SZ.state.mapLoaded) {
        renderMapOptimized();
    } else if (SZ.state.currentView === 'analytics') {
        updateAnalytics();
    }

    updateSelectedZoneReference();
}

function setAllZonesActivationState(isActive) {
    const normalizedState = !!isActive;
    let hasChanged = false;

    const updatedZones = SZ.state.zones.map(zone => {
        const currentState = zone.isActive !== false;
        if (currentState === normalizedState) {
            return zone;
        }

        hasChanged = true;
        return { ...zone, isActive: normalizedState };
    });

    if (hasChanged) {
        Log('ZONE', 'info', `Bulk zone state change: all zones set to ${normalizedState ? 'active' : 'inactive'}`);
        SZ.state.zones = updatedZones;
        updateSelectedZoneReference();
    }

    return hasChanged;
}

function setZoneActivationState(zoneName, isActive) {
    const normalizedState = !!isActive;
    const zoneIndex = SZ.state.zones.findIndex(z => z.name === zoneName);

    if (zoneIndex === -1) {
        Log('ZONE', 'warn', `setZoneActivationState: zone "${zoneName}" not found`);
        return false;
    }

    const currentZone = SZ.state.zones[zoneIndex];
    const currentState = currentZone.isActive !== false;

    if (currentState === normalizedState) {
        return false;
    }

    const updatedZone = { ...currentZone, isActive: normalizedState };
    const updatedZones = [...SZ.state.zones];
    updatedZones[zoneIndex] = updatedZone;

    SZ.state.zones = updatedZones;

    if (SZ.state.selectedZone && SZ.state.selectedZone.name === zoneName) {
        SZ.state.selectedZone = updatedZone;
    }

    return true;
}

function renderZones() {
    if (!SZ.elements.zonesList) {
        Log('ZONE', 'warn', 'zonesList element not found');
        return;
    }

    if (SZ.state.isCreatingZone) {
        return;
    }

    let filteredZones = SZ.state.zones.filter(zone =>
        zone.name.toLowerCase().includes(SZ.state.searchQuery)
    );

    switch (SZ.state.currentFilter) {
        case 'config':
            filteredZones = filteredZones.filter(z => !z.isCustom);
            break;
        case 'custom':
            filteredZones = filteredZones.filter(z => z.isCustom);
            break;
        case 'active':
            filteredZones = filteredZones.filter(z =>
                SZ.state.players.some(p => p.zoneName === z.name)
            );
            break;
    }

    if (filteredZones.length === 0) {
        SZ.elements.zonesList.style.display = 'none';
        if (SZ.elements.zonesEmpty) {
            SZ.elements.zonesEmpty.classList.remove('hidden');
        }
        return;
    }

    SZ.elements.zonesList.style.display = 'grid';
    if (SZ.elements.zonesEmpty) {
        SZ.elements.zonesEmpty.classList.add('hidden');
    }

    const fragment = document.createDocumentFragment();

    filteredZones.forEach((zone, index) => {
        const card = createZoneItem(zone, index);
        fragment.appendChild(card);
    });

    SZ.elements.zonesList.innerHTML = '';
    SZ.elements.zonesList.appendChild(fragment);
}

function createZoneDebugToggle(zone, index, debugState) {
    const toggle = document.createElement('label');
    const classes = ['zone-debug-toggle'];
    if (debugState.effective) {
        classes.push('is-active');
    }
    toggle.className = classes.join(' ');
    toggle.setAttribute('data-zone', zone.name);

    const inputId = `zone-debug-toggle-${index}`;
    const statusText = getZoneDebugStatusText(debugState);
    const checkedAttr = debugState.effective ? ' checked' : '';

    toggle.innerHTML = `
        <div class="zone-debug-toggle__text">
            <span class="zone-debug-toggle__label">${SZ.Localization.t('zones.actions.debug_visualization')}</span>
            <span class="zone-debug-toggle__status">${statusText}</span>
        </div>
        <div class="zone-debug-toggle__switch">
            <input type="checkbox" id="${inputId}" class="zone-debug-toggle__input"${checkedAttr} data-debug-zone="${zone.name.replace(/&/g, '&amp;').replace(/"/g, '&quot;')}">
            <span class="zone-debug-toggle__slider" aria-hidden="true"></span>
        </div>
    `;

    return toggle;
}

function createZoneItem(zone, index) {
    const div = document.createElement('div');
    const isActive = zone.isActive !== false;
    const cardClasses = ['zone-item'];
    if (zone.isCustom) {
        cardClasses.push('custom');
    }
    if (!isActive) {
        cardClasses.push('inactive');
    }
    const debugState = computeZoneDebugState(zone);
    if (debugState.effective) {
        cardClasses.push('debug-active');
    }
    div.className = cardClasses.join(' ');

    const players = SZ.state.players.filter(p => p.zoneName === zone.name);
    const playerCount = players.length;

    const header = document.createElement('div');
    header.className = 'zone-item-header';
    const zoneIdDisplay = zone.id !== undefined ? `#${zone.id}` : '';
    header.innerHTML = `
        <div class="zone-item-title">
            <h3 class="zone-item-name"><span class="zone-id">${zoneIdDisplay}</span> ${zone.name}</h3>
            <div class="zone-item-badges">
                <span class="zone-badge ${zone.isCustom ? 'custom' : 'config'}">
                    ${zone.isCustom ? SZ.Localization.t('zones.custom_badge') : SZ.Localization.t('zones.config_badge')}
                </span>
                <span class="zone-status-pill ${isActive ? 'active' : 'inactive'}">
                    ${isActive ? SZ.Localization.t('zones.status.active') : SZ.Localization.t('zones.status.inactive')}
                </span>
            </div>
        </div>
        <div class="zone-item-meta">
            <div class="zone-meta-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                    ${zone.type === 'polygon' ?
            '<path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" stroke-width="2"/>' :
            '<circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>'
        }
                </svg>
                <span>${zone.type === 'polygon' ? SZ.Localization.t('zones.zone_type.polygon') : SZ.Localization.t('zones.zone_type.circle')}</span>
            </div>
            ${zone.showMarker !== undefined ? `
                <div class="zone-meta-item">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                        <path d="M21 10C21 17 12 23 12 23S3 17 3 10A9 9 0 0112 1A9 9 0 0121 10Z" stroke="currentColor" stroke-width="2"/>
                    </svg>
                    <span>${zone.showMarker ? SZ.Localization.t('tooltip.visible') : SZ.Localization.t('tooltip.hidden')}</span>
                </div>
            ` : ''}
        </div>
    `;

    header.appendChild(createZoneDebugToggle(zone, index, debugState));

    const body = document.createElement('div');
    body.className = 'zone-item-body';

    const stats = document.createElement('div');
    stats.className = 'zone-item-stats';

    if (zone.type === 'polygon') {
        stats.innerHTML = `
            <div class="zone-stat">
                <span class="zone-stat-value">${zone.points.length}</span>
                <span class="zone-stat-label">${SZ.Localization.t('zones.details.polygon_points', { count: zone.points.length }).split(' ')[1]}</span>
            </div>
            <div class="zone-stat">
                <span class="zone-stat-value">${formatCoordinate(zone.maxZ - zone.minZ)}</span>
                <span class="zone-stat-label">${SZ.Localization.t('zones.details.height')}</span>
            </div>
            <div class="zone-stat">
                <span class="zone-stat-value">${playerCount}</span>
                <span class="zone-stat-label">${SZ.Localization.t('app.players')}</span>
            </div>
        `;
    } else {
        const coordX = zone.coords ? formatCoordinate(zone.coords.x) : '0.00';
        const coordY = zone.coords ? formatCoordinate(zone.coords.y) : '0.00';

        stats.innerHTML = `
            <div class="zone-stat">
                <span class="zone-stat-value">${zone.radius}m</span>
                <span class="zone-stat-label">${SZ.Localization.t('zones.details.radius')}</span>
            </div>
            <div class="zone-stat">
                <span class="zone-stat-value">${coordX}, ${coordY}</span>
                <span class="zone-stat-label">${SZ.Localization.t('zones.details.location')}</span>
            </div>
            <div class="zone-stat">
                <span class="zone-stat-value">${playerCount}</span>
                <span class="zone-stat-label">${SZ.Localization.t('app.players')}</span>
            </div>
        `;
    }

    body.appendChild(stats);

    const playersSection = document.createElement('div');
    playersSection.className = 'zone-item-players';

    const playersHeader = document.createElement('div');
    playersHeader.className = 'zone-players-header';
    playersHeader.innerHTML = `
        <span class="zone-players-title">${SZ.Localization.t('modal.players_in_zone')}</span>
        <span class="zone-players-count ${playerCount > 0 ? 'active' : ''}">${playerCount}</span>
    `;
    playersSection.appendChild(playersHeader);

    const playersList = document.createElement('div');
    playersList.className = 'zone-players-list';

    if (!isActive) {
        playersList.innerHTML = `<div class="zone-players-empty">${SZ.Localization.t('zones.status.inactive')}</div>`;
    } else if (playerCount > 0) {
        players.slice(0, 3).forEach(player => {
            const chip = document.createElement('div');
            chip.className = 'zone-player-chip';
            chip.innerHTML = `
                <div class="zone-player-avatar">${player.playerName[0]}</div>
                <span>${player.playerName}</span>
            `;
            playersList.appendChild(chip);
        });

        if (playerCount > 3) {
            const moreChip = document.createElement('div');
            moreChip.className = 'zone-player-chip';
            moreChip.innerHTML = `<span>${SZ.Localization.t('zones.players_more', { count: playerCount - 3 })}</span>`;
            playersList.appendChild(moreChip);
        }
    } else {
        playersList.innerHTML = `<div class="zone-players-empty">${SZ.Localization.t('modal.no_players')}</div>`;
    }

    playersSection.appendChild(playersList);
    body.appendChild(playersSection);

    const actions = document.createElement('div');
    actions.className = 'zone-item-actions';
    const escapedName = zone.name.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
    actions.innerHTML = `
        <button class="zone-action-btn" data-action="details" data-zone="${escapedName}">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M1 12S5 4 12 4S23 12 23 12S19 20 12 20S1 12 1 12Z" stroke="currentColor" stroke-width="2"/>
                <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
            </svg>
            <span>${SZ.Localization.t('zones.actions.view_details')}</span>
        </button>
        <button class="zone-action-btn" data-action="teleport" data-zone="${escapedName}">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M21 10C21 17 12 23 12 23S3 17 3 10A9 9 0 0112 1A9 9 0 0121 10Z" stroke="currentColor" stroke-width="2"/>
            </svg>
            <span>${SZ.Localization.t('zones.actions.teleport')}</span>
        </button>
        ${zone.showMarker !== undefined ? `
            <button class="zone-action-btn" data-action="toggle-marker" data-zone="${escapedName}">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <path d="M21 10C21 17 12 23 12 23S3 17 3 10A9 9 0 0112 1A9 9 0 0121 10Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    <circle cx="12" cy="10" r="3" stroke="currentColor" stroke-width="2"/>
                    ${!zone.showMarker ? '<path d="M4 20L20 4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>' : ''}
                </svg>
                <span>${SZ.Localization.t('zones.actions.toggle_marker')}</span>
            </button>
        ` : ''}
        <button class="zone-action-btn ${isActive ? 'zone-action-btn--danger' : 'zone-action-btn--success'}" data-action="toggle-activation" data-zone="${escapedName}">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M12 2V12" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/>
                <path d="M16.24 7.76a6 6 0 11-8.49 0" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
            <span>${isActive ? SZ.Localization.t('zones.actions.deactivate_zone') : SZ.Localization.t('zones.actions.activate_zone')}</span>
        </button>
    `;

    div.appendChild(header);
    div.appendChild(body);
    div.appendChild(actions);

    return div;
}

function handleToggleAllZones() {
    if (SZ.elements.toggleAllZonesBtn && SZ.elements.toggleAllZonesBtn.disabled) {
        return;
    }

    let shouldActivate = SZ.state.zones.some(zone => zone.isActive === false);
    if (SZ.elements.toggleAllZonesBtn && SZ.elements.toggleAllZonesBtn.dataset.activate) {
        shouldActivate = SZ.elements.toggleAllZonesBtn.dataset.activate === 'true';
    }

    const stateChanged = setAllZonesActivationState(shouldActivate);
    if (stateChanged) {
        refreshActivationUI();
    } else {
        updateQuickActions();
    }

    Log('ZONE', 'info', `Toggling all zones: activate=${shouldActivate}`);
    sendNUI('toggleAllZonesActivation', { activate: shouldActivate });

    const notifKey = shouldActivate ? 'notifications.activating_all' : 'notifications.deactivating_all';
    showNotification(SZ.Localization.t(notifKey), shouldActivate ? 'success' : 'warning');
}

window.handleToggleZoneActivation = function (zoneName) {
    const zone = SZ.state.zones.find(z => z.name === zoneName);
    if (!zone) {
        Log('ZONE', 'warn', `Toggle activation failed: zone "${zoneName}" not found`);
        showNotification(SZ.Localization.t('notifications.zone_not_found'), 'error');
        return;
    }

    const shouldActivate = zone.isActive === false;
    Log('ZONE', 'info', `Toggling zone activation: "${zoneName}" -> ${shouldActivate ? 'active' : 'inactive'}`);

    const stateChanged = setZoneActivationState(zoneName, shouldActivate);
    if (stateChanged) {
        refreshActivationUI();
    } else {
        updateQuickActions();
    }

    sendNUI('toggleZoneActivation', { zoneName, activate: shouldActivate });

    const notifKey = shouldActivate ? 'notifications.activating_zone' : 'notifications.deactivating_zone';
    showNotification(SZ.Localization.t(notifKey, { name: zoneName }), shouldActivate ? 'success' : 'warning');
};

window.handleQuickTeleport = function (zoneName) {
    const zone = SZ.state.zones.find(z => z.name === zoneName);
    if (!zone) {
        Log('ZONE', 'warn', `Quick teleport failed: zone "${zoneName}" not found`);
        return;
    }

    if (zone.isActive === false) {
        Log('ZONE', 'warn', `Quick teleport: zone "${zoneName}" is inactive`);
        showNotification(SZ.Localization.t('notifications.zone_inactive', { name: zoneName }), 'warning');
        return;
    }

    let coords;
    if (zone.type === 'polygon') {
        const center = getPolygonCenter(zone.points);
        const centerZ = (zone.minZ + zone.maxZ) / 2;
        coords = { x: center.x, y: center.y, z: centerZ };
    } else if (zone.coords) {
        coords = zone.coords;
    }

    if (coords) {
        Log('ZONE', 'info', `Teleporting to zone "${zoneName}": ${coords.x?.toFixed(1)}, ${coords.y?.toFixed(1)}, ${coords.z?.toFixed(1)}`);
        sendNUI('teleportToZone', { coords, zoneName });
        showNotification(SZ.Localization.t('notifications.teleporting'), 'success');
    } else {
        Log('ZONE', 'warn', `Quick teleport: no coords for zone "${zoneName}"`);
    }
};

window.handleQuickToggleMarker = function (zoneName) {
    Log('ZONE', 'info', `Quick toggle marker for zone: "${zoneName}"`);
    sendNUI('toggleZoneMarker', { zoneName });
    showNotification(SZ.Localization.t('notifications.toggling_marker', { name: zoneName }), 'info');
};

window.handleZoneDebugToggle = async function (zoneName, inputEl) {
    if (!inputEl) {
        return;
    }

    const zone = SZ.state.zones.find(z => z.name === zoneName);
    const desiredState = inputEl.checked;

    if (!zone) {
        showNotification(SZ.Localization.t('notifications.zone_not_found'), 'error');
        if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
            renderZones();
        }
        return;
    }

    const debugState = computeZoneDebugState(zone);
    const baseline = SZ.state.debugEnabled && debugState.matchesMode;
    const payloadState = desiredState === baseline ? null : desiredState;

    inputEl.disabled = true;

    const success = await sendNUI('setZoneDebugState', { zoneName, state: payloadState });

    inputEl.disabled = false;

    if (!success) {
        inputEl.checked = debugState.effective;
        showNotification(SZ.Localization.t('notifications.debug_zone_toggle_failed', { name: zoneName }), 'error');
        return;
    }

    if (!SZ.state.zoneDebugStates) {
        SZ.state.zoneDebugStates = {};
    }

    if (payloadState === null || payloadState === undefined) {
        delete SZ.state.zoneDebugStates[zoneName];
    } else {
        SZ.state.zoneDebugStates[zoneName] = payloadState;
    }

    const updatedState = computeZoneDebugState(zone);
    inputEl.checked = updatedState.effective;

    const notifKey = desiredState ? 'notifications.debug_zone_enabled' : 'notifications.debug_zone_disabled';
    showNotification(SZ.Localization.t(notifKey, { name: zoneName }), desiredState ? 'success' : 'info');

    if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
        renderZones();
    }
};

window.showZoneDetails = function (zoneName) {
    const zone = SZ.state.zones.find(z => z.name === zoneName);
    if (!zone) {
        Log('ZONE', 'warn', `showZoneDetails: zone "${zoneName}" not found`);
        showNotification(SZ.Localization.t('notifications.zone_not_found'), 'error');
        return;
    }

    SZ.state.selectedZone = zone;

    const players = SZ.state.players.filter(p => p.zoneName === zone.name);

    const zoneIdPrefix = zone.id !== undefined ? `#${zone.id} ` : '';
    SZ.elements.modalZoneName.textContent = zoneIdPrefix + zone.name;
    SZ.elements.modalZoneType.textContent = `${zone.isCustom ? SZ.Localization.t('zones.custom_badge') : SZ.Localization.t('zones.config_badge')} ${zone.type === 'polygon' ? SZ.Localization.t('zones.zone_type.polygon') : SZ.Localization.t('zones.zone_type.circle')}`;

    if (zone.type === 'polygon') {
        const center = getPolygonCenter(zone.points);
        const centerZ = (zone.minZ + zone.maxZ) / 2;

        SZ.elements.modalZoneCoords.textContent = `${SZ.Localization.t('modal.center')}: ${formatCoordinate(center.x)}, ${formatCoordinate(center.y)}, ${formatCoordinate(centerZ)}`;
        SZ.elements.modalZoneRadius.textContent = SZ.Localization.t('modal.polygon_info', { count: zone.points.length, height: formatCoordinate(zone.maxZ - zone.minZ) });

        zone.coords = zone.blipCoords || { x: center.x, y: center.y, z: centerZ };
    } else if (zone.coords) {
        SZ.elements.modalZoneCoords.textContent = `${formatCoordinate(zone.coords.x)}, ${formatCoordinate(zone.coords.y)}, ${formatCoordinate(zone.coords.z)}`;
        SZ.elements.modalZoneRadius.textContent = `${zone.radius}m`;
    } else {
        SZ.elements.modalZoneCoords.textContent = SZ.Localization.t('modal.na');
        SZ.elements.modalZoneRadius.textContent = SZ.Localization.t('modal.na');
    }

    SZ.elements.modalZonePlayers.textContent = players.length;

    const editBtn = document.getElementById('editZone');
    if (editBtn) {
        editBtn.classList.toggle('hidden', !zone.isCustom);
    }
    SZ.elements.deleteZone.classList.toggle('hidden', !zone.isCustom);

    renderModalPlayers(players);

    SZ.elements.zoneModal.classList.remove('hidden');
};

function renderModalPlayers(players) {
    const container = SZ.elements.modalPlayersList;

    if (players.length === 0) {
        container.innerHTML = `<p style="text-align: center; color: var(--text-muted);">${SZ.Localization.t('modal.no_players')}</p>`;
        return;
    }

    container.innerHTML = players.map(player => {
        const time = formatTime(Date.now() / 1000 - player.enteredAt);
        return `
            <div class="player-item">
                <div class="player-info">
                    <div class="player-avatar">${player.playerName[0]}</div>
                    <div class="player-details">
                        <div class="player-name">${player.playerName}</div>
                        <div class="player-id">${SZ.Localization.t('modal.player_id', { id: player.playerId })}</div>
                    </div>
                </div>
                <div class="player-time">${time}</div>
            </div>
        `;
    }).join('');
}

function closeZoneModal() {
    SZ.elements.zoneModal.classList.add('hidden');
    SZ.state.selectedZone = null;
}

function handleTeleport() {
    if (!SZ.state.selectedZone) {
        Log('ZONE', 'warn', 'Teleport called without zone selected');
        return;
    }
    if (!SZ.state.selectedZone.coords) {
        Log('ZONE', 'warn', `Teleport failed: zone "${SZ.state.selectedZone.name}" has no coordinates`);
        return;
    }

    const coords = {
        x: parseFloat(SZ.state.selectedZone.coords.x),
        y: parseFloat(SZ.state.selectedZone.coords.y),
        z: parseFloat(SZ.state.selectedZone.coords.z)
    };

    Log('ZONE', 'info', `Teleporting to zone "${SZ.state.selectedZone.name}": ${coords.x.toFixed(1)}, ${coords.y.toFixed(1)}, ${coords.z.toFixed(1)}`);
    sendNUI('teleportToZone', {
        coords: coords,
        zoneName: SZ.state.selectedZone.name
    });
    closeZoneModal();
    showNotification(SZ.Localization.t('notifications.teleporting'), 'success');
}

async function handleDeleteZone() {
    if (!SZ.state.selectedZone || !SZ.state.selectedZone.isCustom) {
        Log('ZONE', 'warn', 'Delete zone called without valid custom zone selected');
        return;
    }

    const confirmed = await confirmDialog(
        SZ.Localization.t('confirm.delete_title'),
        SZ.Localization.t('confirm.delete_message', { name: SZ.state.selectedZone.name }),
        { okText: SZ.Localization.t('confirm.delete_button'), isDanger: true }
    );

    if (confirmed) {
        Log('ZONE', 'info', `Deleting zone: "${SZ.state.selectedZone.name}" (customIndex: ${SZ.state.selectedZone.customIndex})`);
        sendNUI('deleteZone', { zoneId: `custom_${SZ.state.selectedZone.customIndex}` });
        closeZoneModal();
    }
}

function handleCloneZoneAttributes() {
    if (!SZ.state.selectedZone) {
        Log('ZONE', 'warn', 'Clone zone attributes called without zone selected');
        return;
    }
    Log('ZONE', 'info', `Cloning attributes from zone: "${SZ.state.selectedZone.name}"`);

    const zone = SZ.state.selectedZone;

    SZ.state.clonedZoneData = {
        type: zone.type,
        blipName: zone.blipName || '',
        showBlip: zone.showBlip !== false,
        blipSprite: zone.blipSprite !== undefined ? zone.blipSprite : 84,
        blipColor: zone.blipColor !== undefined ? zone.blipColor : 25,
        showCenterBlip: zone.showCenterBlip !== false,
        blipAlpha: zone.blipAlpha !== undefined ? zone.blipAlpha : 180,
        blipScale: zone.blipScale !== undefined ? zone.blipScale : 0.8,
        blipShortRange: zone.blipShortRange === true,
        blipHiddenOnLegend: zone.blipHiddenOnLegend === true,
        blipHighDetail: zone.blipHighDetail !== false,
        showZoneOutline: zone.showZoneOutline !== false,
        outlineRadius: zone.outlineRadius,
        outlineSpacing: zone.outlineSpacing,
        outlineAlpha: zone.outlineAlpha,
        outlineColor: zone.outlineColor,
        outlineStrokeEnabled: zone.outlineStrokeEnabled,
        strokeRadius: zone.strokeRadius,
        strokeAlpha: zone.strokeAlpha,
        strokeColor: zone.strokeColor,
        circleCoverageType: zone.circleCoverageType,
        showMarker: zone.showMarker !== false,
        markerConfig: zone.markerConfig ? { ...zone.markerConfig } : null,
        enableInvincibility: zone.enableInvincibility !== undefined ? zone.enableInvincibility : (zone.enableImmortality !== false),
        enableGhosting: zone.enableGhosting !== false,
        preventVehicleDamage: zone.preventVehicleDamage !== false,
        disableVehicleWeapons: zone.disableVehicleWeapons !== false,
        collisionDisabled: zone.collisionDisabled === true,
        infiniteHeight: zone.infiniteHeight === true,
        radius: zone.radius,
        addRoof: zone.addRoof === true
    };

    closeZoneModal();

    showCreateFormWithClonedData();

    showNotification(SZ.Localization.t('notifications.zone_attributes_cloned'), 'success');
}

function showCreateFormWithClonedData() {
    const clonedData = SZ.state.clonedZoneData;
    if (!clonedData) {
        Log('ZONE', 'warn', 'showCreateFormWithClonedData called but no cloned data available');
        showCreateForm();
        return;
    }
    Log('ZONE', 'info', `Opening form with cloned data (type: ${clonedData.type})`);

    showCreateForm(clonedData.type);

    const formTitle = document.querySelector('.zone-form h3');
    if (formTitle) {
        formTitle.textContent = SZ.Localization.t('form.clone_title');
    }

    SZ.elements.blipName.value = '';
    SZ.elements.zoneName.value = '';
    SZ.elements.showBlip.checked = clonedData.showBlip;
    SZ.elements.showMarker.checked = clonedData.showMarker;

    setBlipPickerValues(clonedData.blipSprite, clonedData.blipColor);

    toggleBlipConfig(clonedData.showBlip);

    if (SZ.elements.showCenterBlip) {
        SZ.elements.showCenterBlip.checked = clonedData.showCenterBlip;
        if (SZ.elements.centerBlipContent) {
            SZ.elements.centerBlipContent.classList.toggle('disabled', !clonedData.showCenterBlip);
        }
    }

    if (SZ.elements.blipAlpha) {
        SZ.elements.blipAlpha.value = clonedData.blipAlpha;
        if (SZ.elements.blipAlphaValue) SZ.elements.blipAlphaValue.textContent = clonedData.blipAlpha;
    }

    if (SZ.elements.blipScale) {
        SZ.elements.blipScale.value = clonedData.blipScale;
        if (SZ.elements.blipScaleValue) SZ.elements.blipScaleValue.textContent = clonedData.blipScale;
    }

    if (SZ.elements.blipShortRange) SZ.elements.blipShortRange.checked = clonedData.blipShortRange;
    if (SZ.elements.blipHiddenOnLegend) SZ.elements.blipHiddenOnLegend.checked = clonedData.blipHiddenOnLegend;
    if (SZ.elements.blipHighDetail) SZ.elements.blipHighDetail.checked = clonedData.blipHighDetail;

    if (SZ.elements.showZoneOutline) {
        SZ.elements.showZoneOutline.checked = clonedData.showZoneOutline;
        if (SZ.elements.outlineBlipContent) {
            SZ.elements.outlineBlipContent.classList.toggle('disabled', !clonedData.showZoneOutline);
        }
    }

    if (clonedData.outlineRadius !== undefined && SZ.elements.outlineRadius) {
        SZ.elements.outlineRadius.value = clonedData.outlineRadius;
        if (SZ.elements.outlineRadiusValue) SZ.elements.outlineRadiusValue.textContent = clonedData.outlineRadius;
    }

    if (clonedData.outlineSpacing !== undefined && SZ.elements.outlineSpacing) {
        SZ.elements.outlineSpacing.value = clonedData.outlineSpacing;
        if (SZ.elements.outlineSpacingValue) SZ.elements.outlineSpacingValue.textContent = clonedData.outlineSpacing;
    }

    if (clonedData.outlineAlpha !== undefined && SZ.elements.outlineAlpha) {
        SZ.elements.outlineAlpha.value = clonedData.outlineAlpha;
        if (SZ.elements.outlineAlphaValue) SZ.elements.outlineAlphaValue.textContent = clonedData.outlineAlpha;
    }

    if (clonedData.circleCoverageType && SZ.elements.circleCoverageType) {
        SZ.elements.circleCoverageType.value = clonedData.circleCoverageType;
    }

    if (clonedData.type === 'circle') {
        if (clonedData.radius) {
            SZ.elements.zoneRadius.value = clonedData.radius;
            SZ.elements.radiusRange.value = clonedData.radius;
        }

        SZ.elements.infiniteHeight.checked = clonedData.infiniteHeight;

        const circleInvincibility = document.getElementById('circle-enable-invincibility');
        const circleGhosting = document.getElementById('circle-enable-ghosting');
        const circleVehicleDamage = document.getElementById('circle-prevent-vehicle-damage');
        const circleVehicleWeapons = document.getElementById('circle-disable-vehicle-weapons');
        const circleCollision = document.getElementById('circle-collision-disabled');

        if (circleInvincibility) circleInvincibility.checked = clonedData.enableInvincibility;
        if (circleGhosting) circleGhosting.checked = clonedData.enableGhosting;
        if (circleVehicleDamage) circleVehicleDamage.checked = clonedData.preventVehicleDamage;
        if (circleVehicleWeapons) circleVehicleWeapons.checked = clonedData.disableVehicleWeapons;
        if (circleCollision) circleCollision.checked = clonedData.collisionDisabled;

        SZ.elements.coordX.value = '';
        SZ.elements.coordY.value = '';
        SZ.elements.coordZ.value = '';
    } else {
        SZ.elements.infiniteHeightPolygon.checked = clonedData.infiniteHeight;

        if (SZ.elements.polygonAddRoof) {
            SZ.elements.polygonAddRoof.checked = clonedData.addRoof;
        }

        const polygonInvincibility = document.getElementById('polygon-enable-invincibility');
        const polygonGhosting = document.getElementById('polygon-enable-ghosting');
        const polygonVehicleDamage = document.getElementById('polygon-prevent-vehicle-damage');
        const polygonVehicleWeapons = document.getElementById('polygon-disable-vehicle-weapons');
        const polygonCollision = document.getElementById('polygon-collision-disabled');

        if (polygonInvincibility) polygonInvincibility.checked = clonedData.enableInvincibility;
        if (polygonGhosting) polygonGhosting.checked = clonedData.enableGhosting;
        if (polygonVehicleDamage) polygonVehicleDamage.checked = clonedData.preventVehicleDamage;
        if (polygonVehicleWeapons) polygonVehicleWeapons.checked = clonedData.disableVehicleWeapons;
        if (polygonCollision) polygonCollision.checked = clonedData.collisionDisabled;

        clearPolygonPoints();
        initializePolygonPoints();
    }

    if (clonedData.showMarker && clonedData.markerConfig) {
        const mc = clonedData.markerConfig;

        if (clonedData.type === 'circle') {
            document.querySelectorAll('.marker-type-btn').forEach(btn => {
                btn.classList.toggle('active', parseInt(btn.dataset.markerType) === mc.type);
            });
        }

        if (mc.color) {
            const hexColor = `#${('0' + mc.color.r.toString(16)).slice(-2)}${('0' + mc.color.g.toString(16)).slice(-2)}${('0' + mc.color.b.toString(16)).slice(-2)}`.toUpperCase();
            markerColorPicker.setValue(hexColor);
        }

        if (mc.alpha !== undefined) {
            SZ.elements.markerAlpha.value = mc.alpha;
            SZ.elements.markerAlphaValue.textContent = mc.alpha;
        }

        if (mc.height !== undefined) {
            SZ.elements.markerHeight.value = mc.height;
            SZ.elements.markerHeightValue.textContent = mc.height + 'm';
        }

        const markerBobbing = document.getElementById('markerBobbing');
        const markerPulsing = document.getElementById('markerPulsing');
        const markerRotating = document.getElementById('markerRotating');
        const markerColorShift = document.getElementById('markerColorShift');
        const markerAutoLevel = document.getElementById('markerAutoLevel');

        if (markerBobbing) markerBobbing.checked = mc.bobbing || false;
        if (markerPulsing) markerPulsing.checked = mc.pulsing || false;
        if (markerRotating) markerRotating.checked = mc.rotating || false;
        if (markerColorShift) markerColorShift.checked = mc.colorShift || false;
        if (markerAutoLevel) markerAutoLevel.checked = mc.autoLevel || false;

        if (mc.pulseSpeed !== undefined && SZ.elements.pulseSpeed) {
            SZ.elements.pulseSpeed.value = mc.pulseSpeed;
            if (SZ.elements.pulseSpeedValue) SZ.elements.pulseSpeedValue.textContent = mc.pulseSpeed;
        }

        if (mc.bobHeight !== undefined && SZ.elements.bobHeight) {
            SZ.elements.bobHeight.value = mc.bobHeight;
            if (SZ.elements.bobHeightValue) SZ.elements.bobHeightValue.textContent = mc.bobHeight + 'm';
        }

        if (mc.rotationSpeed !== undefined && SZ.elements.rotationSpeed) {
            SZ.elements.rotationSpeed.value = mc.rotationSpeed;
            if (SZ.elements.rotationSpeedValue) SZ.elements.rotationSpeedValue.textContent = mc.rotationSpeed;
        }
    }

    toggleMarkerConfig(clonedData.showMarker);

    SZ.state.clonedZoneData = null;
}

async function handleEditZone() {
    if (!SZ.state.selectedZone || !SZ.state.selectedZone.isCustom) {
        Log('ZONE', 'warn', 'Edit zone called without valid custom zone selected');
        return;
    }
    Log('ZONE', 'info', `Editing zone: "${SZ.state.selectedZone.name}"`);

    const zone = SZ.state.selectedZone;
    SZ.state.isEditingZone = true;
    SZ.state.editingZone = zone;

    closeZoneModal();

    showCreateForm(zone.type);

    document.getElementById('editingZoneId').value = zone.id;
    document.getElementById('editingZoneName').value = zone.name;

    const formTitle = document.querySelector('.zone-form h3');
    if (formTitle) {
        formTitle.textContent = SZ.Localization.t('form.edit_title');
    }

    const submitBtn = document.querySelector('#createZoneForm button[type="submit"]');
    if (submitBtn) {
        submitBtn.textContent = SZ.Localization.t('form.update');
    }

    loadZoneDataToForm(zone);
}

function loadBlipConfigSettings(zone) {
    if (SZ.elements.showCenterBlip) {
        const isEnabled = zone.showCenterBlip !== false;
        SZ.elements.showCenterBlip.checked = isEnabled;
        if (SZ.elements.centerBlipContent) {
            SZ.elements.centerBlipContent.classList.toggle('disabled', !isEnabled);
        }
    }

    if (SZ.elements.blipAlpha) {
        const alpha = zone.blipAlpha !== undefined ? zone.blipAlpha : 180;
        SZ.elements.blipAlpha.value = alpha;
        if (SZ.elements.blipAlphaValue) SZ.elements.blipAlphaValue.textContent = alpha;
    }

    if (SZ.elements.blipScale) {
        const scale = zone.blipScale !== undefined ? zone.blipScale : 0.8;
        SZ.elements.blipScale.value = scale;
        if (SZ.elements.blipScaleValue) SZ.elements.blipScaleValue.textContent = scale;
    }

    if (SZ.elements.blipShortRange) {
        SZ.elements.blipShortRange.checked = zone.blipShortRange === true;
    }

    if (SZ.elements.blipHiddenOnLegend) {
        SZ.elements.blipHiddenOnLegend.checked = zone.blipHiddenOnLegend === true;
    }

    if (SZ.elements.blipHighDetail) {
        SZ.elements.blipHighDetail.checked = zone.blipHighDetail !== false;
    }

    if (SZ.elements.showZoneOutline) {
        const isEnabled = zone.showZoneOutline !== false;
        SZ.elements.showZoneOutline.checked = isEnabled;
        if (SZ.elements.outlineBlipContent) {
            SZ.elements.outlineBlipContent.classList.toggle('disabled', !isEnabled);
        }
    }

    if (SZ.elements.outlineRadius) {
        const radius = zone.outlineRadius !== undefined ? zone.outlineRadius : 1.2;
        SZ.elements.outlineRadius.value = radius;
        if (SZ.elements.outlineRadiusValue) SZ.elements.outlineRadiusValue.textContent = radius;
    }

    if (SZ.elements.outlineSpacing) {
        const spacing = zone.outlineSpacing !== undefined ? zone.outlineSpacing : 6.0;
        SZ.elements.outlineSpacing.value = spacing;
        if (SZ.elements.outlineSpacingValue) SZ.elements.outlineSpacingValue.textContent = spacing;
    }

    if (SZ.elements.outlineAlpha) {
        const alpha = zone.outlineAlpha !== undefined ? zone.outlineAlpha : 160;
        SZ.elements.outlineAlpha.value = alpha;
        if (SZ.elements.outlineAlphaValue) SZ.elements.outlineAlphaValue.textContent = alpha;
    }

    setOutlineColorPickerValue(zone.outlineColor || '#F5A623');

    if (SZ.elements.outlineStrokeEnabled) {
        SZ.elements.outlineStrokeEnabled.checked = zone.outlineStrokeEnabled !== false;
        const strokeSettings = SZ.elements.strokeSettings;
        if (strokeSettings) {
            if (zone.outlineStrokeEnabled !== false) {
                strokeSettings.classList.remove('disabled');
                strokeSettings.style.opacity = '1';
                strokeSettings.style.pointerEvents = 'auto';
            } else {
                strokeSettings.classList.add('disabled');
                strokeSettings.style.opacity = '0.5';
                strokeSettings.style.pointerEvents = 'none';
            }
        }
    }

    if (SZ.elements.strokeRadius) {
        const radius = zone.strokeRadius !== undefined ? zone.strokeRadius : 1.5;
        SZ.elements.strokeRadius.value = radius;
        if (SZ.elements.strokeRadiusValue) SZ.elements.strokeRadiusValue.textContent = radius + 'x';
    }

    setStrokeColorPickerValue(zone.strokeColor || '#FFFFFF');

    if (SZ.elements.strokeAlpha) {
        const alpha = zone.strokeAlpha !== undefined ? zone.strokeAlpha : 220;
        SZ.elements.strokeAlpha.value = alpha;
        if (SZ.elements.strokeAlphaValue) SZ.elements.strokeAlphaValue.textContent = alpha;
    }

    if (SZ.elements.circleCoverageType) {
        const coverageType = zone.circleCoverageType || 'full';
        SZ.elements.circleCoverageType.value = coverageType;
        document.querySelectorAll('.coverage-type-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.coverage === coverageType);
        });
    }

    updateCoverageSectionVisibility(zone.type);
}

function updateCoverageSectionVisibility(zoneType) {
    const circleCoverageSection = SZ.elements.circleCoverageSection;
    if (circleCoverageSection) {
        circleCoverageSection.style.display = zoneType === 'circle' ? 'block' : 'none';
    }
}

function resetBlipConfigSettings() {
    if (SZ.elements.showCenterBlip) {
        SZ.elements.showCenterBlip.checked = true;
        const content = SZ.elements.centerBlipContent;
        if (content) content.style.display = 'block';
    }

    if (SZ.elements.blipAlpha) {
        SZ.elements.blipAlpha.value = 180;
        if (SZ.elements.blipAlphaValue) SZ.elements.blipAlphaValue.textContent = '180';
    }

    if (SZ.elements.blipScale) {
        SZ.elements.blipScale.value = 0.8;
        if (SZ.elements.blipScaleValue) SZ.elements.blipScaleValue.textContent = '0.8';
    }

    if (SZ.elements.blipShortRange) SZ.elements.blipShortRange.checked = false;
    if (SZ.elements.blipHiddenOnLegend) SZ.elements.blipHiddenOnLegend.checked = false;
    if (SZ.elements.blipHighDetail) SZ.elements.blipHighDetail.checked = true;

    if (SZ.elements.showZoneOutline) {
        SZ.elements.showZoneOutline.checked = true;
        const content = SZ.elements.outlineBlipContent;
        if (content) content.style.display = 'block';
    }

    if (SZ.elements.outlineRadius) {
        SZ.elements.outlineRadius.value = 1.2;
        if (SZ.elements.outlineRadiusValue) SZ.elements.outlineRadiusValue.textContent = '1.2';
    }

    if (SZ.elements.outlineSpacing) {
        SZ.elements.outlineSpacing.value = 6.0;
        if (SZ.elements.outlineSpacingValue) SZ.elements.outlineSpacingValue.textContent = '6.0';
    }

    if (SZ.elements.outlineAlpha) {
        SZ.elements.outlineAlpha.value = 160;
        if (SZ.elements.outlineAlphaValue) SZ.elements.outlineAlphaValue.textContent = '160';
    }

    if (SZ.elements.outlineColor) {
        SZ.elements.outlineColor.value = '0xF5A623FF';
        if (SZ.elements.outlineColorHex) SZ.elements.outlineColorHex.textContent = '#F5A623';
        if (SZ.elements.outlineColorNative) SZ.elements.outlineColorNative.textContent = '0xF5A623FF';
        if (SZ.elements.outlineColorPreview) SZ.elements.outlineColorPreview.style.backgroundColor = '#F5A623';
    }
    outlineColorPicker.resetToDefault();

    if (SZ.elements.outlineStrokeEnabled) {
        SZ.elements.outlineStrokeEnabled.checked = true;
        const strokeSettings = SZ.elements.strokeSettings;
        if (strokeSettings) {
            strokeSettings.classList.remove('disabled');
            strokeSettings.style.opacity = '1';
            strokeSettings.style.pointerEvents = 'auto';
        }
    }

    if (SZ.elements.strokeRadius) {
        SZ.elements.strokeRadius.value = 1.5;
        if (SZ.elements.strokeRadiusValue) SZ.elements.strokeRadiusValue.textContent = '1.5x';
    }

    if (SZ.elements.strokeColor) {
        SZ.elements.strokeColor.value = '0xFFFFFFFF';
        if (SZ.elements.strokeColorHex) SZ.elements.strokeColorHex.textContent = '#FFFFFF';
        if (SZ.elements.strokeColorNative) SZ.elements.strokeColorNative.textContent = '0xFFFFFFFF';
        if (SZ.elements.strokeColorPreview) SZ.elements.strokeColorPreview.style.backgroundColor = '#FFFFFF';
    }
    strokeColorPicker.resetToDefault();

    if (SZ.elements.strokeAlpha) {
        SZ.elements.strokeAlpha.value = 220;
        if (SZ.elements.strokeAlphaValue) SZ.elements.strokeAlphaValue.textContent = '220';
    }

    if (SZ.elements.circleCoverageType) {
        SZ.elements.circleCoverageType.value = 'full';
        document.querySelectorAll('.coverage-type-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.coverage === 'full');
        });
    }
}

function loadZoneDataToForm(zone) {
    SZ.elements.zoneName.value = zone.name;
    SZ.elements.blipName.value = zone.blipName || `Safe Zone - ${zone.name}`;
    SZ.elements.showBlip.checked = zone.showBlip !== false;
    SZ.elements.showMarker.checked = zone.showMarker !== false;

    const blipSprite = zone.blipSprite !== undefined ? zone.blipSprite : 84;
    const blipColor = zone.blipColor !== undefined ? zone.blipColor : 25;
    setBlipPickerValues(blipSprite, blipColor);

    toggleBlipConfig(zone.showBlip !== false);

    loadBlipConfigSettings(zone);

    selectZoneType(zone.type);

    if (zone.type === 'circle') {
        SZ.elements.zoneRadius.value = zone.radius;
        SZ.elements.radiusRange.value = zone.radius;
        SZ.elements.coordX.value = formatCoordinate(zone.coords.x);
        SZ.elements.coordY.value = formatCoordinate(zone.coords.y);
        SZ.elements.coordZ.value = formatCoordinate(zone.coords.z);

        const infiniteHeight = zone.infiniteHeight === true;
        SZ.elements.infiniteHeight.checked = infiniteHeight;

        if (!infiniteHeight) {
            SZ.elements.circleMinZ.value = formatCoordinate(zone.minZ || -50);
            SZ.elements.circleMaxZ.value = formatCoordinate(zone.maxZ || 150);
        }

        const circleInvincibilityEnabled = zone.enableInvincibility !== undefined
            ? zone.enableInvincibility !== false
            : zone.enableImmortality !== false;
        document.getElementById('circle-enable-invincibility').checked = circleInvincibilityEnabled;
        document.getElementById('circle-enable-ghosting').checked = zone.enableGhosting !== false;
        document.getElementById('circle-prevent-vehicle-damage').checked = zone.preventVehicleDamage !== false;
        document.getElementById('circle-disable-vehicle-weapons').checked = zone.disableVehicleWeapons !== false;
        document.getElementById('circle-collision-disabled').checked = zone.collisionDisabled === true;
    } else {
        clearPolygonPoints();

        zone.points.forEach((point, index) => {
            addPolygonPoint();
            const container = SZ.elements.polygonPointInputs;
            const xInput = container.querySelector(`input[data-index="${index}"][data-coord="x"]`);
            const yInput = container.querySelector(`input[data-index="${index}"][data-coord="y"]`);
            const zInput = container.querySelector(`input[data-index="${index}"][data-coord="z"]`);

            if (xInput) xInput.value = formatCoordinate(point.x);
            if (yInput) yInput.value = formatCoordinate(point.y);
            if (zInput) zInput.value = formatCoordinate(point.z || zone.minZ || 0);
        });

        const infiniteHeight = zone.infiniteHeight === true;
        SZ.elements.infiniteHeightPolygon.checked = infiniteHeight;

        if (!infiniteHeight) {
            SZ.elements.minZ.value = formatCoordinate(zone.minZ);
            SZ.elements.maxZ.value = formatCoordinate(zone.maxZ);
        }

        const polygonInvincibilityEnabled = zone.enableInvincibility !== undefined
            ? zone.enableInvincibility !== false
            : zone.enableImmortality !== false;
        document.getElementById('polygon-enable-invincibility').checked = polygonInvincibilityEnabled;
        document.getElementById('polygon-enable-ghosting').checked = zone.enableGhosting !== false;
        document.getElementById('polygon-prevent-vehicle-damage').checked = zone.preventVehicleDamage !== false;
        document.getElementById('polygon-disable-vehicle-weapons').checked = zone.disableVehicleWeapons !== false;
        document.getElementById('polygon-collision-disabled').checked = zone.collisionDisabled === true;

        if (SZ.elements.polygonAddRoof) {
            SZ.elements.polygonAddRoof.checked = zone.addRoof === true;
        }
    }

    if (zone.showMarker && zone.markerConfig) {
        const mc = zone.markerConfig;

        if (zone.type === 'circle') {
            document.querySelectorAll('.marker-type-btn').forEach(btn => {
                btn.classList.toggle('active', parseInt(btn.dataset.markerType) === mc.type);
            });
        }

        const hexColor = `#${('0' + mc.color.r.toString(16)).slice(-2)}${('0' + mc.color.g.toString(16)).slice(-2)}${('0' + mc.color.b.toString(16)).slice(-2)}`.toUpperCase();
        markerColorPicker.setValue(hexColor);

        SZ.elements.markerAlpha.value = mc.alpha || 100;
        SZ.elements.markerAlphaValue.textContent = mc.alpha || 100;
        SZ.elements.markerHeight.value = mc.height || 30;
        SZ.elements.markerHeightValue.textContent = (mc.height || 30) + 'm';

        const markerBobbing = document.getElementById('markerBobbing');
        if (markerBobbing) markerBobbing.checked = mc.bobbing || false;
        
        const markerPulsing = document.getElementById('markerPulsing');
        if (markerPulsing) markerPulsing.checked = mc.pulsing || false;
        
        const markerRotating = document.getElementById('markerRotating');
        if (markerRotating) markerRotating.checked = mc.rotating || false;
        
        const markerColorShift = document.getElementById('markerColorShift');
        if (markerColorShift) markerColorShift.checked = mc.colorShift || false;
        
        const markerAutoLevel = document.getElementById('markerAutoLevel');
        if (markerAutoLevel) markerAutoLevel.checked = mc.autoLevel !== false;

        SZ.elements.pulseSpeed.value = mc.pulseSpeed || 2;
        SZ.elements.pulseSpeedValue.textContent = (mc.pulseSpeed || 2) + 'x';
        SZ.elements.bobHeight.value = mc.bobHeight || 0.5;
        SZ.elements.bobHeightValue.textContent = (mc.bobHeight || 0.5) + 'm';
        SZ.elements.rotationSpeed.value = mc.rotationSpeed || 1;
        SZ.elements.rotationSpeedValue.textContent = (mc.rotationSpeed || 1) + 'x';
    }

    if (SZ.elements.renderDistance) {
        const renderDist = zone.renderDistance || 150;
        SZ.elements.renderDistance.value = renderDist;
        SZ.elements.renderDistanceRange.value = Math.min(renderDist, 5000);
    }

    toggleMarkerConfig(zone.showMarker);
}

function initializeMap() {
    Log('MAP', 'info', 'Initializing map canvas');
    SZ.mapState.canvas = SZ.elements.mapCanvas;
    if (!SZ.mapState.canvas) {
        Log('MAP', 'error', 'Map canvas element not found');
        return;
    }
    SZ.mapState.ctx = SZ.mapState.canvas.getContext('2d', {
        alpha: false,
        desynchronized: true,
        willReadFrequently: false
    });

    resizeCanvas();

    const checkImagesLoaded = setInterval(() => {
        if (SZ.mapState.allImagesLoaded) {
            clearInterval(checkImagesLoaded);
            SZ.state.mapLoaded = true;
            renderMapOptimized();
        }
    }, 100);

    initializeMapControls();
}

function resizeCanvas() {
    const container = SZ.mapState.canvas.parentElement;
    const rect = container.getBoundingClientRect();

    const app = document.getElementById('app');
    const style = window.getComputedStyle(app);
    const transform = style.transform;

    let scale = 1;
    if (transform && transform !== 'none') {
        const matrix = transform.match(/matrix\((.+)\)/);
        if (matrix) {
            const values = matrix[1].split(', ');
            scale = parseFloat(values[0]);
        }
    }

    SZ.mapState.canvas.width = rect.width;
    SZ.mapState.canvas.height = rect.height;
    SZ.mapState.appScale = scale;

    const dpr = window.devicePixelRatio || 1;
    if (dpr > 1) {
        SZ.mapState.canvas.width *= dpr;
        SZ.mapState.canvas.height *= dpr;
        SZ.mapState.ctx.scale(dpr, dpr);
    }
}

window.addEventListener('resize', debounce(() => {
    if (SZ.state.currentView === 'map' && SZ.state.mapLoaded) {
        resizeCanvas();
        renderMapOptimized();
    }
}, 200));

function changeMapStyleOptimized(style) {
    const previousStyle = SZ.mapState.currentStyle;

    if (previousStyle === style) return;
    Log('MAP', 'info', `Changing map style: ${previousStyle} -> ${style}`);
    
    SZ.mapState.currentStyle = style;

    document.querySelectorAll('.map-style').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.style === style);
    });

    renderMapOptimized();
}

function initializeMapControls() {
    const canvas = SZ.mapState.canvas;

    canvas.addEventListener('wheel', throttle((e) => {
        e.preventDefault();
        const delta = e.deltaY > 0 ? -1 : 1;
        const pos = eventToCanvas(e);
        zoomAtPoint(pos.x, pos.y, delta);
    }, SZ.THROTTLE_DELAY));

    canvas.addEventListener('mousedown', (e) => {
        if (e.button === 0) {
            SZ.mapState.isDragging = true;
            SZ.mapState.dragStartX = e.clientX;
            SZ.mapState.dragStartY = e.clientY;
            canvas.style.cursor = 'grabbing';
        }
    });

    canvas.addEventListener('mousemove', throttle((e) => {
        const pos = eventToCanvas(e);

        if (SZ.mapState.isDragging) {
            const dx = e.clientX - SZ.mapState.dragStartX;
            const dy = e.clientY - SZ.mapState.dragStartY;

            SZ.mapState.offsetX += dx;
            SZ.mapState.offsetY += dy;

            SZ.mapState.dragStartX = e.clientX;
            SZ.mapState.dragStartY = e.clientY;

            renderMapOptimized();
        } else {
            updateCursorCoords(pos.x, pos.y);
            checkHoveredZone(pos.x, pos.y, e.clientX, e.clientY);
        }
    }, SZ.THROTTLE_DELAY));

    canvas.addEventListener('mouseup', () => {
        SZ.mapState.isDragging = false;
        canvas.style.cursor = 'grab';
    });

    canvas.addEventListener('mouseleave', () => {
        SZ.mapState.isDragging = false;
        canvas.style.cursor = 'grab';
        hideTooltip();
    });

    let lastTouchDistance = 0;

    canvas.addEventListener('touchstart', (e) => {
        if (e.touches.length === 1) {
            SZ.mapState.isDragging = true;
            SZ.mapState.dragStartX = e.touches[0].clientX;
            SZ.mapState.dragStartY = e.touches[0].clientY;
        } else if (e.touches.length === 2) {
            const dx = e.touches[0].clientX - e.touches[1].clientX;
            const dy = e.touches[0].clientY - e.touches[1].clientY;
            lastTouchDistance = Math.sqrt(dx * dx + dy * dy);
        }
    });

    canvas.addEventListener('touchmove', throttle((e) => {
        e.preventDefault();

        if (e.touches.length === 1 && SZ.mapState.isDragging) {
            const dx = e.touches[0].clientX - SZ.mapState.dragStartX;
            const dy = e.touches[0].clientY - SZ.mapState.dragStartY;

            SZ.mapState.offsetX += dx;
            SZ.mapState.offsetY += dy;

            SZ.mapState.dragStartX = e.touches[0].clientX;
            SZ.mapState.dragStartY = e.touches[0].clientY;

            renderMapOptimized();
        } else if (e.touches.length === 2) {
            const dx = e.touches[0].clientX - e.touches[1].clientX;
            const dy = e.touches[0].clientY - e.touches[1].clientY;
            const distance = Math.sqrt(dx * dx + dy * dy);

            if (lastTouchDistance > 0) {
                const scale = distance / lastTouchDistance;
                zoomMap(scale > 1 ? 1 : -1);
            }

            lastTouchDistance = distance;
        }
    }, SZ.THROTTLE_DELAY));

    canvas.addEventListener('touchend', () => {
        SZ.mapState.isDragging = false;
        lastTouchDistance = 0;
    });
}

function renderMapOptimized() {
    const ctx = SZ.mapState.ctx;
    const canvas = SZ.mapState.canvas;

    ctx.fillStyle = '#0a0f0f';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();

    ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.scale(SZ.mapState.zoom, SZ.mapState.zoom);
    ctx.translate(SZ.mapState.offsetX / SZ.mapState.zoom, SZ.mapState.offsetY / SZ.mapState.zoom);

    const prerenderedMap = SZ.mapState.prerenderedMaps[SZ.mapState.currentStyle];
    if (prerenderedMap) {
        ctx.drawImage(prerenderedMap, -SZ.MAP_SIZE / 2, -SZ.MAP_SIZE / 2);
    } else {
        const img = SZ.mapState.images[SZ.mapState.currentStyle];
        if (img) {
            ctx.drawImage(img, -SZ.MAP_SIZE / 2, -SZ.MAP_SIZE / 2, SZ.MAP_SIZE, SZ.MAP_SIZE);
        } else {
            drawFallbackMap(ctx);
        }
    }

    if (SZ.mapState.showGrid) {
        drawGrid(ctx);
    }

    drawZones(ctx);

    if (SZ.mapState.measureMode && SZ.mapState.measurePoints.length > 0) {
        drawMeasureLine(ctx);
    }

    ctx.restore();

    SZ.elements.zoomLevel.textContent = SZ.Localization.t('map.zoom_level', { level: Math.round(SZ.mapState.zoom * 100) + '%' });
}


function drawFallbackMap(ctx) {
    ctx.fillStyle = '#1a2323';
    ctx.fillRect(-SZ.MAP_SIZE / 2, -SZ.MAP_SIZE / 2, SZ.MAP_SIZE, SZ.MAP_SIZE);

    ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
    ctx.lineWidth = 2;

    const gridSize = SZ.MAP_SIZE / 16;
    for (let i = -8; i <= 8; i++) {
        ctx.beginPath();
        ctx.moveTo(i * gridSize, -SZ.MAP_SIZE / 2);
        ctx.lineTo(i * gridSize, SZ.MAP_SIZE / 2);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(-SZ.MAP_SIZE / 2, i * gridSize);
        ctx.lineTo(SZ.MAP_SIZE / 2, i * gridSize);
        ctx.stroke();
    }
}

function drawGrid(ctx) {
    ctx.strokeStyle = 'rgba(48,48,48, 0.3)';
    ctx.lineWidth = 3 / SZ.mapState.zoom;

    const gridSize = 500;
    const startX = Math.floor(-SZ.MAP_SIZE / 2 / gridSize) * gridSize;
    const endX = Math.ceil(SZ.MAP_SIZE / 2 / gridSize) * gridSize;

    for (let x = startX; x <= endX; x += gridSize) {
        ctx.beginPath();
        ctx.moveTo(x, -SZ.MAP_SIZE / 2);
        ctx.lineTo(x, SZ.MAP_SIZE / 2);
        ctx.stroke();
    }

    for (let y = startX; y <= endX; y += gridSize) {
        ctx.beginPath();
        ctx.moveTo(-SZ.MAP_SIZE / 2, y);
        ctx.lineTo(SZ.MAP_SIZE / 2, y);
        ctx.stroke();
    }
}

function drawZones(ctx) {
    SZ.state.zones.forEach(zone => {
        if (zone.type === 'polygon') {
            drawPolygonZone(ctx, zone);
        } else if (zone.coords) {
            drawCircleZone(ctx, zone);
        }
    });

    if (SZ.mapState.highlightedZone && !SZ.mapState.animationFrame) {
        SZ.mapState.animationFrame = requestAnimationFrame(() => {
            SZ.mapState.animationFrame = null;
            renderMapOptimized();
        });
    }
}

function drawCircleZone(ctx, zone) {
    const mapCoords = gameToMapCoords(zone.coords.x, zone.coords.y);
    const x = mapCoords.x - SZ.MAP_SIZE / 2;
    const y = mapCoords.y - SZ.MAP_SIZE / 2;
    const radius = (zone.radius / ((SZ.GAME_BOUNDS.maxX - SZ.GAME_BOUNDS.minX) / SZ.MAP_SIZE));

    const hasPlayers = SZ.state.players.some(p => p.zoneName === zone.name);

    const isHighlighted = SZ.mapState.highlightedZone && SZ.mapState.highlightedZone.name === zone.name;

    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);

    if (isHighlighted) {
        const pulse = Math.sin(Date.now() / 200) * 0.3 + 0.7;
        ctx.fillStyle = `rgba(0, 212, 255, ${0.3 * pulse})`;
        ctx.strokeStyle = '#F97316';
        ctx.lineWidth = 4 / SZ.mapState.zoom;
    } else if (hasPlayers) {
        ctx.fillStyle = 'rgba(255, 68, 68, 0.2)';
        ctx.strokeStyle = '#ff4444';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    } else if (zone.isCustom) {
        ctx.fillStyle = 'rgba(255, 136, 0, 0.2)';
        ctx.strokeStyle = '#ff8800';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    } else {
        ctx.fillStyle = 'rgba(245, 166, 35, 0.2)';
        ctx.strokeStyle = '#F5A623';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    }

    ctx.fill();
    ctx.stroke();

    if (SZ.mapState.zoom > 0.8) {
        const labelText = zone.id !== undefined ? `#${zone.id} ${zone.name}` : zone.name;
        drawZoneLabel(ctx, labelText, x, y, hasPlayers);
    }
}

function drawPolygonZone(ctx, zone) {
    if (!zone.points || zone.points.length < 3) return;

    const mapPoints = zone.points.map(point => {
        const mapCoord = gameToMapCoords(point.x, point.y);
        return {
            x: mapCoord.x - SZ.MAP_SIZE / 2,
            y: mapCoord.y - SZ.MAP_SIZE / 2
        };
    });

    const hasPlayers = SZ.state.players.some(p => p.zoneName === zone.name);

    const isHighlighted = SZ.mapState.highlightedZone && SZ.mapState.highlightedZone.name === zone.name;

    ctx.beginPath();
    ctx.moveTo(mapPoints[0].x, mapPoints[0].y);
    for (let i = 1; i < mapPoints.length; i++) {
        ctx.lineTo(mapPoints[i].x, mapPoints[i].y);
    }
    ctx.closePath();

    const gradient = ctx.createRadialGradient(
        mapPoints[0].x, mapPoints[0].y, 0,
        mapPoints[0].x, mapPoints[0].y, 200 / SZ.mapState.zoom
    );

    if (isHighlighted) {
        const pulse = Math.sin(Date.now() / 200) * 0.3 + 0.7;
        gradient.addColorStop(0, `rgba(0, 212, 255, ${0.4 * pulse})`);
        gradient.addColorStop(1, `rgba(0, 212, 255, ${0.1 * pulse})`);
        ctx.fillStyle = gradient;
        ctx.strokeStyle = '#F97316';
        ctx.lineWidth = 4 / SZ.mapState.zoom;
        ctx.shadowBlur = 20 / SZ.mapState.zoom;
        ctx.shadowColor = '#F97316';
    } else if (hasPlayers) {
        gradient.addColorStop(0, 'rgba(255, 68, 68, 0.3)');
        gradient.addColorStop(1, 'rgba(255, 68, 68, 0.1)');
        ctx.fillStyle = gradient;
        ctx.strokeStyle = '#ff4444';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    } else if (zone.isCustom) {
        gradient.addColorStop(0, 'rgba(255, 136, 0, 0.3)');
        gradient.addColorStop(1, 'rgba(255, 136, 0, 0.1)');
        ctx.fillStyle = gradient;
        ctx.strokeStyle = '#ff8800';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    } else {
        gradient.addColorStop(0, 'rgba(245, 166, 35, 0.3)');
        gradient.addColorStop(1, 'rgba(245, 166, 35, 0.1)');
        ctx.fillStyle = gradient;
        ctx.strokeStyle = '#F5A623';
        ctx.lineWidth = 2 / SZ.mapState.zoom;
    }

    ctx.fill();
    ctx.stroke();
    ctx.shadowBlur = 0;

    if (SZ.mapState.zoom > 1.5) {
        ctx.fillStyle = ctx.strokeStyle;
        for (const point of mapPoints) {
            ctx.beginPath();
            ctx.arc(point.x, point.y, 3 / SZ.mapState.zoom, 0, Math.PI * 2);
            ctx.fill();
        }
    }

    if (SZ.mapState.zoom > 0.8) {
        const center = getPolygonCenter(mapPoints);

        const labelText = zone.id !== undefined ? `#${zone.id} ${zone.name}` : zone.name;
        drawZoneLabel(ctx, labelText, center.x, center.y, hasPlayers);

        if (SZ.mapState.showGrid) {
            ctx.font = `${10 / SZ.mapState.zoom}px Inter`;
            ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
            ctx.fillText(SZ.Localization.t('map.polygon_label', { count: zone.points.length }), center.x, center.y - 20 / SZ.mapState.zoom);
        }
    }
}

function drawZoneLabel(ctx, name, x, y, hasPlayers) {
    ctx.font = `${14 / SZ.mapState.zoom}px Inter`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    ctx.strokeStyle = '#000000';
    ctx.lineWidth = 3 / SZ.mapState.zoom;
    ctx.strokeText(name, x, y);

    ctx.fillStyle = '#ffffff';
    ctx.fillText(name, x, y);

    if (hasPlayers) {
        const playerCount = SZ.state.players.filter(p => p.zoneName === name).length;
        ctx.font = `${12 / SZ.mapState.zoom}px Inter`;

        ctx.strokeStyle = '#000000';
        ctx.lineWidth = 3 / SZ.mapState.zoom;
        ctx.strokeText(`${playerCount} ${SZ.Localization.t('app.players').toLowerCase()}`, x, y + 20 / SZ.mapState.zoom);

        ctx.fillStyle = '#ff4444';
        ctx.fillText(`${playerCount} ${SZ.Localization.t('app.players').toLowerCase()}`, x, y + 20 / SZ.mapState.zoom);
    }
}

function drawMeasureLine(ctx) {
    if (SZ.mapState.measurePoints.length === 0) return;

    const zoom = SZ.mapState.zoom;
    const dash = [6 / zoom, 6 / zoom];
    const measurePoints = SZ.mapState.measurePoints;

    const drawPath = (strokeStyle, lineWidth) => {
        ctx.strokeStyle = strokeStyle;
        ctx.lineWidth = lineWidth;
        ctx.setLineDash(dash);
        ctx.beginPath();
        measurePoints.forEach((point, index) => {
            if (index === 0) {
                ctx.moveTo(point.x, point.y);
            } else {
                ctx.lineTo(point.x, point.y);
            }
        });
        ctx.stroke();
    };

    drawPath('rgba(0, 0, 0, 0.9)', 4 / zoom);
    drawPath('#ff3b30', 2.5 / zoom);

    ctx.setLineDash([]);

    measurePoints.forEach(point => {
        ctx.beginPath();
        ctx.fillStyle = '#ff3b30';
        ctx.strokeStyle = 'rgba(0, 0, 0, 0.9)';
        ctx.lineWidth = 2 / zoom;
        ctx.arc(point.x, point.y, 6 / zoom, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
    });

    if (measurePoints.length === 2) {
        const [p1, p2] = measurePoints;
        const distance = calculateDistance(p1, p2);

        const midX = (p1.x + p2.x) / 2;
        const midY = (p1.y + p2.y) / 2;

        const fontSize = 16 / zoom;
        const label = `${formatCoordinate(distance)}m`;

        ctx.font = `bold ${fontSize}px Inter`;
        ctx.textAlign = 'center';
        ctx.lineJoin = 'round';

        ctx.strokeStyle = 'rgba(0, 0, 0, 0.9)';
        ctx.lineWidth = 4 / zoom;
        ctx.strokeText(label, midX, midY - 12 / zoom);

        ctx.fillStyle = '#ff3b30';
        ctx.fillText(label, midX, midY - 12 / zoom);
    }
}

function gameToMapCoords(gameX, gameY) {
    const normalizedX = (gameX - SZ.GAME_BOUNDS.minX) / (SZ.GAME_BOUNDS.maxX - SZ.GAME_BOUNDS.minX);
    const normalizedY = 1 - ((gameY - SZ.GAME_BOUNDS.minY) / (SZ.GAME_BOUNDS.maxY - SZ.GAME_BOUNDS.minY));

    return {
        x: normalizedX * SZ.MAP_SIZE,
        y: normalizedY * SZ.MAP_SIZE
    };
}

function mapToGameCoords(mapX, mapY) {
    const normalizedX = mapX / SZ.MAP_SIZE;
    const normalizedY = 1 - (mapY / SZ.MAP_SIZE);

    const gameX = normalizedX * (SZ.GAME_BOUNDS.maxX - SZ.GAME_BOUNDS.minX) + SZ.GAME_BOUNDS.minX;
    const gameY = normalizedY * (SZ.GAME_BOUNDS.maxY - SZ.GAME_BOUNDS.minY) + SZ.GAME_BOUNDS.minY;

    return { x: gameX, y: gameY };
}

function eventToCanvas(e) {
    const canvas = SZ.mapState.canvas;
    const rect = canvas.getBoundingClientRect();
    return {
        x: (e.clientX - rect.left) * (canvas.width / rect.width),
        y: (e.clientY - rect.top) * (canvas.height / rect.height)
    };
}

function screenToMap(canvasX, canvasY) {
    const canvas = SZ.mapState.canvas;
    const x = (canvasX - canvas.width / 2 - SZ.mapState.offsetX) / SZ.mapState.zoom;
    const y = (canvasY - canvas.height / 2 - SZ.mapState.offsetY) / SZ.mapState.zoom;
    return { x, y };
}

function zoomMap(direction) {
    const canvas = SZ.mapState.canvas;
    zoomAtPoint(canvas.width / 2, canvas.height / 2, direction);
}

function zoomAtPoint(canvasX, canvasY, direction) {
    const canvas = SZ.mapState.canvas;
    const oldZoom = SZ.mapState.zoom;

    const worldX = (canvasX - canvas.width / 2 - SZ.mapState.offsetX) / oldZoom;
    const worldY = (canvasY - canvas.height / 2 - SZ.mapState.offsetY) / oldZoom;

    const zoomFactor = direction > 0 ? 1 + SZ.ZOOM_SPEED : 1 - SZ.ZOOM_SPEED;
    SZ.mapState.zoom = Math.max(SZ.mapState.minZoom, Math.min(SZ.mapState.maxZoom, oldZoom * zoomFactor));

    SZ.mapState.offsetX = canvasX - worldX * SZ.mapState.zoom - canvas.width / 2;
    SZ.mapState.offsetY = canvasY - worldY * SZ.mapState.zoom - canvas.height / 2;

    renderMapOptimized();
}

function resetMapView() {
    SZ.mapState.zoom = 1;
    SZ.mapState.offsetX = 0;
    SZ.mapState.offsetY = 0;
    renderMapOptimized();
}

function toggleGrid() {
    SZ.mapState.showGrid = !SZ.mapState.showGrid;
    SZ.elements.toggleGrid.classList.toggle('active', SZ.mapState.showGrid);
    renderMapOptimized();
}

function toggleMeasureMode() {
    SZ.mapState.measureMode = !SZ.mapState.measureMode;
    SZ.mapState.measurePoints = [];
    SZ.elements.toggleMeasure.classList.toggle('active', SZ.mapState.measureMode);

    if (SZ.mapState.measureMode) {
        SZ.mapState.canvas.style.cursor = 'crosshair';
        SZ.mapState.canvas.addEventListener('click', handleMeasureClick);
    } else {
        SZ.mapState.canvas.style.cursor = 'grab';
        SZ.mapState.canvas.removeEventListener('click', handleMeasureClick);
    }

    renderMapOptimized();
}

function handleMeasureClick(e) {
    const pos = eventToCanvas(e);
    const mapPoint = screenToMap(pos.x, pos.y);

    if (SZ.mapState.measurePoints.length >= 2) {
        SZ.mapState.measurePoints = [];
    }

    SZ.mapState.measurePoints.push(mapPoint);
    renderMapOptimized();
}

function calculateDistance(p1, p2) {
    const gameP1 = mapToGameCoords(p1.x + SZ.MAP_SIZE / 2, p1.y + SZ.MAP_SIZE / 2);
    const gameP2 = mapToGameCoords(p2.x + SZ.MAP_SIZE / 2, p2.y + SZ.MAP_SIZE / 2);

    const dx = gameP2.x - gameP1.x;
    const dy = gameP2.y - gameP1.y;

    return Math.sqrt(dx * dx + dy * dy);
}


function updateCursorCoords(screenX, screenY) {
    const mapPoint = screenToMap(screenX, screenY);
    const gameCoords = mapToGameCoords(mapPoint.x + SZ.MAP_SIZE / 2, mapPoint.y + SZ.MAP_SIZE / 2);

    SZ.elements.cursorCoords.textContent = SZ.Localization.t('map.cursor_position', {
        x: formatCoordinate(gameCoords.x),
        y: formatCoordinate(gameCoords.y)
    });
}

function checkHoveredZone(canvasX, canvasY, screenX, screenY) {
    const mapPoint = screenToMap(canvasX, canvasY);
    const gameCoords = mapToGameCoords(mapPoint.x + SZ.MAP_SIZE / 2, mapPoint.y + SZ.MAP_SIZE / 2);

    let hoveredZone = null;

    for (const zone of SZ.state.zones) {
        if (zone.type === 'polygon') {
            if (isPointInPolygon(gameCoords, zone.points)) {
                hoveredZone = zone;
                break;
            }
        } else if (zone.coords) {
            const dx = zone.coords.x - gameCoords.x;
            const dy = zone.coords.y - gameCoords.y;
            const distance = Math.sqrt(dx * dx + dy * dy);

            if (distance <= zone.radius) {
                hoveredZone = zone;
                break;
            }
        }
    }

    if (hoveredZone !== SZ.mapState.hoveredZone) {
        SZ.mapState.hoveredZone = hoveredZone;

        if (hoveredZone) {
            showTooltip(screenX, screenY, hoveredZone);
        } else {
            hideTooltip();
        }
    } else if (hoveredZone) {
        updateTooltipPosition(screenX, screenY);
    }
}

function isPointInPolygon(point, polygon) {
    let inside = false;

    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
        const xi = polygon[i].x, yi = polygon[i].y;
        const xj = polygon[j].x, yj = polygon[j].y;

        const intersect = ((yi > point.y) !== (yj > point.y))
            && (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi);

        if (intersect) inside = !inside;
    }

    return inside;
}

function showTooltip(x, y, zone) {
    const tooltip = SZ.elements.zoneTooltip;
    const players = SZ.state.players.filter(p => p.zoneName === zone.name);

    const zoneIdPrefix = zone.id !== undefined ? `#${zone.id} ` : '';
    document.getElementById('tooltipTitle').textContent = zoneIdPrefix + zone.name;

    let tooltipContent = `<p>${SZ.Localization.t('tooltip.type', {
        type: `${zone.isCustom ? SZ.Localization.t('zones.custom_badge') : SZ.Localization.t('zones.config_badge')} ${zone.type === 'polygon' ? SZ.Localization.t('zones.zone_type.polygon') : SZ.Localization.t('zones.zone_type.circle')}`
    })}</p>`;

    if (zone.type === 'polygon') {
        tooltipContent += `<p>${SZ.Localization.t('tooltip.points', { count: zone.points.length })}</p>`;
        tooltipContent += `<p>${SZ.Localization.t('tooltip.height', { height: formatCoordinate(zone.maxZ - zone.minZ) })}</p>`;
    } else {
        tooltipContent += `<p>${SZ.Localization.t('tooltip.radius', { radius: zone.radius })}</p>`;
    }

    tooltipContent += `<p>${SZ.Localization.t('tooltip.players', { count: players.length })}</p>`;

    if (zone.showMarker !== undefined) {
        tooltipContent += `<p>${SZ.Localization.t('tooltip.marker', {
            status: zone.showMarker ? SZ.Localization.t('tooltip.visible') : SZ.Localization.t('tooltip.hidden')
        })}</p>`;
    }

    document.getElementById('tooltipContent').innerHTML = tooltipContent;

    tooltip.classList.remove('hidden');
    updateTooltipPosition(x, y);
}

function updateTooltipPosition(x, y) {
    const tooltip = SZ.elements.zoneTooltip;
    const offset = 15;

    tooltip.style.left = `${x + offset}px`;
    tooltip.style.top = `${y + offset}px`;

    const tooltipRect = tooltip.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    if (tooltipRect.right > viewportWidth) {
        tooltip.style.left = `${x - tooltipRect.width - offset}px`;
    }

    if (tooltipRect.bottom > viewportHeight) {
        tooltip.style.top = `${y - tooltipRect.height - offset}px`;
    }
}

function hideTooltip() {
    SZ.elements.zoneTooltip.classList.add('hidden');
    SZ.mapState.hoveredZone = null;
}

function handleMapSearch() {
    const query = SZ.elements.mapSearch.value.toLowerCase();

    if (!query) return;

    const zone = SZ.state.zones.find(z => z.name.toLowerCase().includes(query));

    if (zone) {
        let mapCoords;

        if (zone.type === 'polygon') {
            const center = getPolygonCenter(zone.points);
            mapCoords = gameToMapCoords(center.x, center.y);
        } else if (zone.coords) {
            mapCoords = gameToMapCoords(zone.coords.x, zone.coords.y);
        } else {
            showNotification(SZ.Localization.t('notifications.zone_not_found'), 'error');
            return;
        }

        SZ.mapState.offsetX = -(mapCoords.x - SZ.MAP_SIZE / 2) * SZ.mapState.zoom;
        SZ.mapState.offsetY = -(mapCoords.y - SZ.MAP_SIZE / 2) * SZ.mapState.zoom;

        if (SZ.mapState.zoom < 2) {
            SZ.mapState.zoom = 2;
            SZ.mapState.offsetX = -(mapCoords.x - SZ.MAP_SIZE / 2) * SZ.mapState.zoom;
            SZ.mapState.offsetY = -(mapCoords.y - SZ.MAP_SIZE / 2) * SZ.mapState.zoom;
        }

        SZ.mapState.highlightedZone = zone;

        setTimeout(() => {
            SZ.mapState.highlightedZone = null;
            renderMapOptimized();
        }, 3000);

        renderMapOptimized();
        showNotification(SZ.Localization.t('notifications.found_zone', { name: zone.name }), 'success');
    } else {
        showNotification(SZ.Localization.t('notifications.zone_not_found'), 'error');
    }
}

SZ.animateTimers = SZ.animateTimers || {};
SZ.analyticsState = SZ.analyticsState || {
    sortColumn: 'name',
    sortDirection: 'asc',
    searchQuery: '',
    zoneFilter: '',
    updateInterval: null
};

function updateAnalytics() {
    updateAnalyticsStats();
    updateDistributionChart();
    updateTopZonesList();
    updatePlayersTable();
    updateZoneFilterOptions();
}

function updateAnalyticsStats() {
    const totalZones = SZ.state.zones.length;
    const totalZonesEl = document.getElementById('totalZonesAnalytics');
    const totalZonesStart = totalZonesEl ? parseInt(totalZonesEl.textContent) || 0 : 0;
    animateValue('totalZonesAnalytics', totalZonesStart, totalZones, 1000);

    const activePlayers = SZ.state.players.length;
    const activePlayersEl = document.getElementById('activePlayers');
    const activePlayersStart = activePlayersEl ? parseInt(activePlayersEl.textContent) || 0 : 0;
    animateValue('activePlayers', activePlayersStart, activePlayers, 1000);

    const activeZones = new Set(SZ.state.players.map(p => p.zoneName)).size;
    const activeZonesEl = document.getElementById('activeZones');
    const activeZonesStart = activeZonesEl ? parseInt(activeZonesEl.textContent) || 0 : 0;
    animateValue('activeZones', activeZonesStart, activeZones, 1000);

    const progressPercent = totalZones > 0 ? (activeZones / totalZones) * 100 : 0;
    const progressBar = document.getElementById('activeZonesProgress');
    if (progressBar) {
        progressBar.style.width = progressPercent + '%';
    }

    const progressText = document.querySelector('.active-zones-card .progress-text');
    if (progressText) {
        progressText.textContent = `${activeZones}/${totalZones}`;
    }

}

function animateValue(elementId, start, end, duration) {
    const element = document.getElementById(elementId);
    if (!element) return;

    if (SZ.animateTimers[elementId]) {
        cancelAnimationFrame(SZ.animateTimers[elementId]);
    }

    const range = end - start;
    if (range === 0) { element.textContent = end; return; }

    const startTime = performance.now();
    function step(now) {
        const elapsed = now - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const current = start + range * progress;
        element.textContent = Math.round(current);
        if (progress < 1) {
            SZ.animateTimers[elementId] = requestAnimationFrame(step);
        } else {
            element.textContent = end;
            SZ.animateTimers[elementId] = null;
        }
    }
    SZ.animateTimers[elementId] = requestAnimationFrame(step);
}

function updateDistributionChart() {
    const canvas = document.getElementById('zoneDistributionChart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');

    const distribution = {};
    let totalPlayers = 0;

    SZ.state.zones.forEach(zone => {
        const playerCount = SZ.state.players.filter(p => p.zoneName === zone.name).length;
        if (playerCount > 0) {
            distribution[zone.name] = playerCount;
            totalPlayers += playerCount;
        }
    });

    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;

    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    let radius = Math.min(centerX, centerY) - 20;
    radius = Math.max(radius, 10);
    const innerRadius = radius * 0.6;

    let currentAngle = -Math.PI / 2;
    const colors = ['#F5A623', '#F97316', '#ff8800', '#ff4444', '#aa00ff', '#ffaa00'];
    let colorIndex = 0;

    Object.entries(distribution).forEach(([zoneName, count]) => {
        const percentage = count / totalPlayers;
        const angle = percentage * Math.PI * 2;

        ctx.fillStyle = colors[colorIndex % colors.length];
        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + angle);
        ctx.arc(centerX, centerY, innerRadius, currentAngle + angle, currentAngle, true);
        ctx.closePath();
        ctx.fill();

        currentAngle += angle;
        colorIndex++;
    });

    const legendContainer = document.getElementById('distributionLegend');
    if (legendContainer) {
        legendContainer.innerHTML = '';
        colorIndex = 0;

        Object.entries(distribution).forEach(([zoneName, count]) => {
            const percentage = ((count / totalPlayers) * 100).toFixed(1);
            const legendItem = document.createElement('div');
            legendItem.className = 'distribution-legend-item';
            legendItem.innerHTML = `
                <span class="distribution-legend-color" style="background: ${colors[colorIndex % colors.length]}"></span>
                <span class="distribution-legend-label">${zoneName}</span>
                <span class="distribution-legend-value">${percentage}%</span>
            `;
            legendContainer.appendChild(legendItem);
            colorIndex++;
        });
    }
}

function updateTopZonesList() {
    const container = document.getElementById('topZonesList');
    if (!container) return;

    const zoneActivity = {};
    SZ.state.zones.forEach(zone => {
        const playerCount = SZ.state.players.filter(p => p.zoneName === zone.name).length;
        if (playerCount > 0) {
            zoneActivity[zone.name] = playerCount;
        }
    });

    const sortedZones = Object.entries(zoneActivity)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);

    if (sortedZones.length === 0) {
        container.innerHTML = `<p style="text-align: center; color: var(--text-muted);">${SZ.Localization.t('analytics.no_active_zones')}</p>`;
        return;
    }

    const maxPlayers = sortedZones[0][1];

    container.innerHTML = sortedZones.map(([zoneName, playerCount], index) => {
        const percentage = (playerCount / maxPlayers) * 100;
        const rankClass = index === 0 ? 'gold' : index === 1 ? 'silver' : index === 2 ? 'bronze' : '';

        return `
            <div class="top-zone-item">
                <div class="zone-rank ${rankClass}">${index + 1}</div>
                <div class="zone-info">
                    <div class="zone-name">${zoneName}</div>
                    <div class="zone-player-count">${playerCount} ${SZ.Localization.t('app.players').toLowerCase()}</div>
                </div>
                <div class="zone-bar-wrapper">
                    <div class="zone-bar-fill" style="width: ${percentage}%"></div>
                </div>
            </div>
        `;
    }).join('');
}

function updatePlayersTable() {
    const tbody = document.getElementById('playersTableBody');
    const emptyState = document.getElementById('tableEmptyState');
    if (!tbody) return;

    let filteredPlayers = SZ.state.players.filter(player => {
        const matchesSearch = !SZ.analyticsState.searchQuery ||
            player.playerName.toLowerCase().includes(SZ.analyticsState.searchQuery.toLowerCase()) ||
            player.playerId.toString().includes(SZ.analyticsState.searchQuery);

        const matchesZone = !SZ.analyticsState.zoneFilter ||
            player.zoneName === SZ.analyticsState.zoneFilter;

        return matchesSearch && matchesZone;
    });

    filteredPlayers.sort((a, b) => {
        let compareValue = 0;

        switch (SZ.analyticsState.sortColumn) {
            case 'id':
                compareValue = a.playerId - b.playerId;
                break;
            case 'name':
                compareValue = a.playerName.localeCompare(b.playerName);
                break;
            case 'zone':
                compareValue = a.zoneName.localeCompare(b.zoneName);
                break;
            case 'time':
                compareValue = (Date.now() / 1000 - a.enteredAt) - (Date.now() / 1000 - b.enteredAt);
                break;
        }

        return SZ.analyticsState.sortDirection === 'asc' ? compareValue : -compareValue;
    });

    if (filteredPlayers.length === 0) {
        tbody.style.display = 'none';
        if (emptyState) {
            emptyState.classList.remove('hidden');
        }
        return;
    }

    tbody.style.display = '';
    if (emptyState) {
        emptyState.classList.add('hidden');
    }

    tbody.innerHTML = filteredPlayers.map(player => {
        const time = formatTime(Date.now() / 1000 - player.enteredAt);
        const zone = SZ.state.zones.find(z => z.name === player.zoneName);
        const zoneType = zone ? zone.type : 'circle';

        return `
            <tr>
                <td class="player-id-cell">${player.playerId}</td>
                <td class="player-name-cell">
                    <div class="player-avatar-small">${player.playerName[0]}</div>
                    <span class="player-name-text">${player.playerName}</span>
                </td>
                <td class="zone-name-cell">
                    <svg class="zone-type-icon" viewBox="0 0 24 24" fill="none">
                        ${zoneType === 'polygon' ?
                '<path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" stroke-width="2"/>' :
                '<circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>'
            }
                    </svg>
                    ${player.zoneName}
                </td>
                <td class="time-cell">${time}</td>
                <td>
                    <span class="status-badge active">
                        <span class="status-indicator"></span>
                        ${SZ.Localization.t('zones.status.active')}
                    </span>
                </td>
            </tr>
        `;
    }).join('');
}

function updateZoneFilterOptions() {
    const select = document.getElementById('zoneFilter');
    if (!select) return;

    const currentValue = select.value;

    const activeZones = [...new Set(SZ.state.players.map(p => p.zoneName))];

    select.innerHTML = `
        <option value="">${SZ.Localization.t('analytics.all_zones')}</option>
        ${activeZones.map(zoneName => `
            <option value="${zoneName}">${zoneName}</option>
        `).join('')}
    `;

    select.value = currentValue;
}

function initializeAnalyticsListeners() {
    const refreshBtn = document.getElementById('refreshAnalytics');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', async () => {
            await refreshData();
        });
    }

    const playerSearch = document.getElementById('playerSearch');
    if (playerSearch) {
        playerSearch.addEventListener('input', debounce((e) => {
            SZ.analyticsState.searchQuery = e.target.value;
            updatePlayersTable();
        }, 300));
    }

    const zoneFilter = document.getElementById('zoneFilter');
    if (zoneFilter) {
        zoneFilter.addEventListener('change', (e) => {
            SZ.analyticsState.zoneFilter = e.target.value;
            updatePlayersTable();
        });
    }

    document.querySelectorAll('.analytics-players-table th.sortable').forEach(th => {
        th.addEventListener('click', () => {
            const column = th.dataset.sort;

            if (SZ.analyticsState.sortColumn === column) {
                SZ.analyticsState.sortDirection = SZ.analyticsState.sortDirection === 'asc' ? 'desc' : 'asc';
            } else {
                SZ.analyticsState.sortColumn = column;
                SZ.analyticsState.sortDirection = 'asc';
            }

            document.querySelectorAll('.analytics-players-table th.sortable').forEach(header => {
                header.classList.remove('active', 'desc');
            });

            th.classList.add('active');
            if (SZ.analyticsState.sortDirection === 'desc') {
                th.classList.add('desc');
            }

            updatePlayersTable();
        });
    });

    SZ.analyticsState.updateInterval = setInterval(() => {
        if (SZ.state.currentView === 'analytics') {
            updateAnalytics();
        }
    }, 1000);
}

function formatTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);

    if (hours > 0) {
        return SZ.Localization.t('time.hours', { hours, minutes });
    } else if (minutes > 0) {
        return SZ.Localization.t('time.minutes', { minutes, seconds: secs });
    } else {
        return SZ.Localization.t('time.seconds', { seconds: secs });
    }
}

function showNotification(message, type = 'info') {
    if (!SZ.elements.notifications) {
        Log('UI', 'warn', 'Notifications container not found');
        return;
    }

    const notification = document.createElement('div');
    notification.className = `notification ${type}`;

    const icons = {
        success: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>',
        error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>',
        warning: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>',
        info: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>'
    };

    const icon = icons[type] || icons.info;

    notification.innerHTML = `
        <div class="notification-icon">${icon}</div>
        <div class="notification-content">
            <div class="notification-message">${message}</div>
        </div>
    `;

    SZ.elements.notifications.appendChild(notification);

    requestAnimationFrame(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateX(0)';
    });

    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

async function refreshData() {
    Log('DATA', 'info', 'Manual data refresh requested');
    showNotification(SZ.Localization.t('notifications.refreshing'), 'info');
    
    try {
        const success = await sendNUI('manualRefresh');
        if (!success) {
            Log('DATA', 'warn', 'Manual refresh request failed');
        }
    } catch (error) {
        Log('DATA', 'warn', 'Error during refresh:', error);
    }
}

let _closePanelTimeout = null;

async function closePanel() {
    Log('UI', 'info', 'Closing panel');
    hideCreatorOverlay();

    if (_hideFormTimeout) {
        clearTimeout(_hideFormTimeout);
        _hideFormTimeout = null;
    }
    _hideFormId++;
    SZ.state.isCreatingZone = false;
    SZ.state.isEditingZone = false;
    SZ.state.editingZone = null;
    if (SZ.elements.zoneForm) {
        SZ.elements.zoneForm.classList.add('hidden');
        SZ.elements.zoneForm.classList.remove('form-hiding');
    }
    if (SZ.elements.fabCreateZone) {
        SZ.elements.fabCreateZone.style.display = 'flex';
    }
    if (SZ.elements.zonesSidebar) {
        SZ.elements.zonesSidebar.style.display = 'flex';
    }
    if (SZ.elements.zonesList) {
        SZ.elements.zonesList.style.display = '';
    }
    if (SZ.elements.zonesEmpty) {
        SZ.elements.zonesEmpty.style.display = '';
    }

    if (SZ.analyticsState && SZ.analyticsState.updateInterval) {
        clearInterval(SZ.analyticsState.updateInterval);
        SZ.analyticsState.updateInterval = null;
    }
    if (SZ._clockInterval) {
        clearInterval(SZ._clockInterval);
        SZ._clockInterval = null;
    }

    const app = document.getElementById('app');
    app.classList.remove('form-active');
    app.classList.add('hidden');

    try {
        await sendNUI('closePanel');
    } catch (error) {
        Log('UI', 'warn', 'Could not notify backend about panel close:', error);
    }

    if (_closePanelTimeout) {
        clearTimeout(_closePanelTimeout);
    }
    _closePanelTimeout = setTimeout(() => {
        _closePanelTimeout = null;
        if (app.classList.contains('hidden')) {
            app.style.display = 'none';
        }
    }, 500);
}

window.addEventListener('message', (event) => {
    const { action, ...data } = event.data;
    if (action) {
        Log('NUI', 'info', `NUI message received: ${action}`);
    }

    switch (action) {
        case 'openPanel':
            handleOpenPanel(data.zones, data.players, data.debug, data.logs, data.logMeta);
            break;

        case 'updateData':
            handleUpdateData(data.zones, data.players, data.debug, data.logs, data.logMeta);
            break;

        case 'closePanel':
            closePanel().catch(err => Log('UI', 'warn', 'Error closing panel:', err));
            break;

        case 'receivePlayerCoords':
            handlePlayerCoords(data.coords);
            break;

        case 'receivePlayerCoordsForPoint':
            handlePolygonPointCoords(data.coords, data.pointIndex);
            break;

        case 'polygonCreatorResult':
            applyPolygonCreatorPoints(data.points || []);
            break;

        case 'circleCreatorResult':
            applyCircleCreatorData(data.center, data.radius);
            break;

        case 'copyToClipboard':
            copyToClipboard(data.text);
            break;

        case 'debugStateChanged':
            applyDebugState({ enabled: data.enabled, mode: data.mode, singleZoneId: data.singleZoneId, states: data.states });
            if (data.localeKey) {
                const notifType = data.notificationType || (data.enabled ? 'success' : 'info');
                showNotification(SZ.Localization.t(data.localeKey), notifType);
            }
            if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
                renderZones();
            }
            break;

        case 'debugStatesUpdated':
            if (data.states !== undefined) {
                setZoneDebugStates(data.states);
            }
            if (typeof data.enabled === 'boolean') {
                SZ.state.debugEnabled = data.enabled;
            }
            if (typeof data.mode === 'string') {
                SZ.state.debugMode = normalizeDebugMode(data.mode);
            }
            if (data.singleZoneId !== undefined) {
                SZ.state.singleZoneId = data.singleZoneId;
            }
            updateDebugButtons();
            if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
                renderZones();
            }
            break;

        case 'showCreatorOverlay':
            showCreatorOverlay(data);
            break;

        case 'updateCreatorOverlay':
            updateCreatorOverlay(data);
            break;

        case 'hideCreatorOverlay':
            hideCreatorOverlay();
            break;

        default:
            if (action) {
                Log('NUI', 'warn', `Unknown NUI action received: ${action}`);
            }
            break;
    }
});

function handleOpenPanel(zones, players, debugState, logs, logMeta) {
    hideCreatorOverlay();
    if (_closePanelTimeout) {
        clearTimeout(_closePanelTimeout);
        _closePanelTimeout = null;
    }
    if (_hideFormTimeout) {
        clearTimeout(_hideFormTimeout);
        _hideFormTimeout = null;
    }
    _hideFormId++;
    SZ.state.isCreatingZone = false;
    SZ.state.isEditingZone = false;
    SZ.state.editingZone = null;
    if (SZ.elements.zoneForm) {
        SZ.elements.zoneForm.classList.add('hidden');
        SZ.elements.zoneForm.classList.remove('form-hiding');
    }
    if (SZ.elements.fabCreateZone) {
        SZ.elements.fabCreateZone.style.display = 'flex';
    }
    if (SZ.elements.zonesSidebar) {
        SZ.elements.zonesSidebar.style.display = 'flex';
    }
    if (SZ.elements.zonesList) {
        SZ.elements.zonesList.style.display = '';
    }
    if (SZ.elements.zonesEmpty) {
        SZ.elements.zonesEmpty.style.display = '';
    }

    Log('NUI', 'info', `Panel opened with ${(zones || []).length} zones, ${(players || []).length} players`);
    SZ.state.zones = zones || [];
    SZ.state.players = players || [];
    setLogsData(logs, logMeta);

    const app = document.getElementById('app');
    app.style.display = 'flex';
    app.classList.remove('hidden');

    applyDebugState(debugState);
    updateHeaderStats();
    updateZoneStats();
    renderZones();

    if (SZ.state.currentView === 'map' && SZ.state.mapLoaded) {
        renderMapOptimized();
    } else if (SZ.state.currentView === 'analytics') {
        updateAnalytics();
    } else if (SZ.state.currentView === 'logs') {
        renderLogs();
    }

    sendNUI('setCursor', { cursor: true });
    startClock();
}

function handleUpdateData(zones, players, debugState, logs, logMeta) {
    Log('DATA', 'info', `Data updated: ${(zones || []).length} zones, ${(players || []).length} players`);
    SZ.state.zones = zones || [];
    SZ.state.players = players || [];
    setLogsData(logs, logMeta);

    applyDebugState(debugState);
    updateHeaderStats();
    updateZoneStats();

    if (SZ.state.currentView === 'zones' && !SZ.state.isCreatingZone) {
        renderZones();
    } else if (SZ.state.currentView === 'map' && SZ.state.mapLoaded) {
        renderMapOptimized();
    } else if (SZ.state.currentView === 'analytics') {
        updateAnalytics();
    } else if (SZ.state.currentView === 'logs') {
        renderLogs();
    }
}

function handlePlayerCoords(coords) {
    if (!coords) {
        Log('NUI', 'warn', 'Received empty player coords');
        return;
    }

    SZ.elements.coordX.value = formatCoordinate(coords.x);
    SZ.elements.coordY.value = formatCoordinate(coords.y);
    SZ.elements.coordZ.value = formatCoordinate(coords.z);

    showNotification(SZ.Localization.t('notifications.coords_updated'), 'success');
}

function handlePolygonPointCoords(coords, pointIndex) {
    if (!coords) {
        Log('NUI', 'warn', `Received empty coords for polygon point ${pointIndex}`);
        return;
    }

    const container = SZ.elements.polygonPointInputs;
    const xInput = container.querySelector(`input[data-index="${pointIndex}"][data-coord="x"]`);
    const yInput = container.querySelector(`input[data-index="${pointIndex}"][data-coord="y"]`);
    const zInput = container.querySelector(`input[data-index="${pointIndex}"][data-coord="z"]`);

    if (xInput && yInput && zInput) {
        xInput.value = formatCoordinate(coords.x);
        yInput.value = formatCoordinate(coords.y);
        zInput.value = formatCoordinate(coords.z);
        showNotification(SZ.Localization.t('notifications.point_coords_updated', { index: parseInt(pointIndex) + 1 }), 'success');

        updatePolygonMinMaxZ();
    }
}

function updateHeaderStats() {
    if (!SZ.elements.totalZonesHeader || !SZ.elements.activePlayersHeader) {
        Log('UI', 'warn', 'Header elements not yet initialized');
        return;
    }

    SZ.elements.totalZonesHeader.textContent = SZ.state.zones.length;
    SZ.elements.activePlayersHeader.textContent = SZ.state.players.length;
}

let _creatorState = { type: null, phase: 1, selectedPoint: null };

function showCreatorOverlay(data) {
    const overlay = document.getElementById('creatorOverlay');
    if (!overlay) return;
    _creatorState.type = data.type;
    _creatorState.phase = data.phase || 1;
    _creatorState.selectedPoint = null;
    overlay.classList.remove('hidden');
    renderCreatorControls(data.type, _creatorState.phase);
    renderCreatorSidePanel(data.type, _creatorState.phase, data.coordinates, data.zoneInfo);
}

function updateCreatorOverlay(data) {
    const overlay = document.getElementById('creatorOverlay');
    if (!overlay || overlay.classList.contains('hidden')) return;
    if (data.type) _creatorState.type = data.type;
    if (data.phase !== undefined) _creatorState.phase = data.phase;
    const prevSelected = _creatorState.selectedPoint;
    if (data.selectedPoint !== undefined) _creatorState.selectedPoint = data.selectedPoint;
    const t = _creatorState.type;
    const p = _creatorState.phase;
    const selectionChanged = prevSelected !== _creatorState.selectedPoint;
    if (data.phase !== undefined || selectionChanged) renderCreatorControls(t, p);
    renderCreatorSidePanel(t, p, data.coordinates, data.zoneInfo);
}

function hideCreatorOverlay() {
    const overlay = document.getElementById('creatorOverlay');
    if (!overlay) return;
    overlay.classList.add('hidden');
    _creatorState.type = null;
    _creatorState.phase = 1;
    _creatorState.selectedPoint = null;
}

function renderCreatorControls(type, phase) {
    const bar = document.getElementById('creatorControlsBar');
    if (!bar) return;

    let controls = [];
    const base = [
        { label: SZ.Localization.t('creator.controls.movement'), key: 'W A S D' },
        { label: SZ.Localization.t('creator.controls.up_down'), key: 'Q E' },
        { label: SZ.Localization.t('creator.controls.slow'), key: 'CTRL' },
        { label: SZ.Localization.t('creator.controls.speed'), key: 'SHIFT' }
    ];

    if (type === 'polygon') {
        if (_creatorState.selectedPoint) {
            controls = [
                ...base,
                { label: SZ.Localization.t('creator.controls.move_point'), key: 'F' },
                { label: SZ.Localization.t('creator.controls.next_point'), key: 'TAB' },
                { label: SZ.Localization.t('creator.controls.delete_point'), key: 'DEL', danger: true },
                { label: SZ.Localization.t('creator.controls.deselect'), key: 'X' },
                { label: SZ.Localization.t('creator.controls.debug'), key: 'G' },
                { label: SZ.Localization.t('creator.controls.complete'), key: 'ENTER' },
                { label: SZ.Localization.t('creator.controls.exit'), key: 'BACKSPACE', danger: true }
            ];
        } else {
            controls = [
                ...base,
                { label: SZ.Localization.t('creator.controls.add_coordinate'), key: 'F' },
                { label: SZ.Localization.t('creator.controls.remove_coordinate'), key: 'X', danger: true },
                { label: SZ.Localization.t('creator.controls.select_point'), key: 'TAB' },
                { label: SZ.Localization.t('creator.controls.debug'), key: 'G' },
                { label: SZ.Localization.t('creator.controls.complete'), key: 'ENTER' },
                { label: SZ.Localization.t('creator.controls.exit'), key: 'BACKSPACE', danger: true }
            ];
        }
    } else if (type === 'circle') {
        if (phase === 1) {
            controls = [
                ...base,
                { label: SZ.Localization.t('creator.controls.set_center'), key: 'F' },
                { label: SZ.Localization.t('creator.controls.debug'), key: 'G' },
                { label: SZ.Localization.t('creator.controls.exit'), key: 'BACKSPACE', danger: true }
            ];
        } else {
            controls = [
                ...base,
                { label: SZ.Localization.t('creator.controls.adjust_radius'), key: 'SCROLL' },
                { label: SZ.Localization.t('creator.controls.radius_to_cursor'), key: 'R' },
                { label: SZ.Localization.t('creator.controls.reset_center'), key: 'X', danger: true },
                { label: SZ.Localization.t('creator.controls.debug'), key: 'G' },
                { label: SZ.Localization.t('creator.controls.confirm'), key: 'ENTER' },
                { label: SZ.Localization.t('creator.controls.exit'), key: 'BACKSPACE', danger: true }
            ];
        }
    }

    bar.innerHTML = controls.map(c =>
        `<div class="creator-control-item"><span class="creator-control-label">${c.label}</span><span class="creator-control-key${c.danger ? ' key-danger' : ''}">${c.key}</span></div>`
    ).join('');
}

function renderCreatorSidePanel(type, phase, coordinates, zoneInfo) {
    const header = document.getElementById('creatorSidePanelHeader');
    const body = document.getElementById('creatorSidePanelBody');
    const footer = document.getElementById('creatorSidePanelFooter');
    if (!header || !body || !footer) return;

    const keySpan = (k) => `<span class="key-ref">${k}</span>`;

    if (type === 'polygon') {
        header.innerHTML = `<svg viewBox="0 0 24 24" fill="none"><path d="M21 10C21 17 12 23 12 23S3 17 3 10A9 9 0 0112 1A9 9 0 0121 10Z" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="10" r="3" stroke="currentColor" stroke-width="2"/></svg><span>${SZ.Localization.t('creator.panel.coordinates_header')}</span>`;

        if (coordinates && coordinates.length > 0) {
            const sel = _creatorState.selectedPoint;
            body.innerHTML = coordinates.map((c, i) => {
                const isSelected = sel === (i + 1);
                return `<div class="creator-coord-item${isSelected ? ' selected' : ''}"><span class="creator-coord-badge${isSelected ? ' selected' : ''}">${i + 1}</span><span class="creator-coord-text">${c.x.toFixed(2)}, ${c.y.toFixed(2)}, ${c.z.toFixed(2)}</span></div>`;
            }).join('');
            if (sel && body.children[sel - 1]) {
                body.children[sel - 1].scrollIntoView({ block: 'nearest' });
            } else {
                body.scrollTop = body.scrollHeight;
            }
        } else {
            body.innerHTML = `<div class="creator-empty-state">${SZ.Localization.t('creator.panel.no_coordinates')}</div>`;
        }

        if (_creatorState.selectedPoint) {
            footer.innerHTML = SZ.Localization.t('creator.panel.footer_selected_hint', { index: _creatorState.selectedPoint });
        } else {
            footer.innerHTML = SZ.Localization.t('creator.panel.footer_remove_hint', { key_x: keySpan('X') });
        }

    } else if (type === 'circle') {
        header.innerHTML = `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/><path d="M12 16V12M12 8H12.01" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg><span>${SZ.Localization.t('creator.panel.zone_info_header')}</span>`;

        if (zoneInfo && zoneInfo.center) {
            body.innerHTML = `<div class="creator-info-row"><span class="creator-info-label">${SZ.Localization.t('creator.panel.center_label')}</span><span class="creator-info-value">${zoneInfo.center.x.toFixed(2)}, ${zoneInfo.center.y.toFixed(2)}, ${zoneInfo.center.z.toFixed(2)}</span></div><div class="creator-info-row"><span class="creator-info-label">${SZ.Localization.t('creator.panel.radius_label')}</span><span class="creator-info-value">${zoneInfo.radius.toFixed(1)} m</span></div>`;
            footer.innerHTML = SZ.Localization.t('creator.panel.footer_adjust_radius', { key_scroll: keySpan('SCROLL'), key_r: keySpan('R') });
        } else {
            body.innerHTML = `<div class="creator-empty-state">${SZ.Localization.t('creator.panel.no_center')}</div><div class="creator-empty-state">${SZ.Localization.t('creator.panel.set_center_hint')}</div>`;
            footer.innerHTML = SZ.Localization.t('creator.panel.footer_set_center', { key_f: keySpan('F') });
        }
    }
}

window.SZ = SZ;
