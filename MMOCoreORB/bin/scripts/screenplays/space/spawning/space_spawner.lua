SpaceSpawnerScreenPlay = ScreenPlay:new {
	numberOfActs = 1,

	screenplayName = "SpaceSpawnerScreenPlay",

	spaceZone = "",

	SPAWN_NO_DELAY = false,

	SERVER_STARTUP_MIN = 120, -- Delay in seconds for spawns to start during server startup
	SERVER_STARTUP_MAX = 300,

	SPAWN_RETRY_SECONDS = 30,
	SPAWN_RETRY_LIMIT = 3,

	--[[
	Spawn Types - from ShipFlag.h

	SHIP_AI_GUARD_PATROL - For ships that patrol a specific area in a spherical pattern where they will have a min range and max range to stay within
		used for ships in patrol around a point or object such as a space station.
	SHIP_AI_RANDOM_PATROL - Default method for patrolling. Randomly generates points around its home location.alignas
	SHIP_AI_FIXED_PATROL - For ships that have specific set of patrol points assigned to them and will only navigate to those points.alignas
	]]

	shipSpawns = {
	},

	squadronsShips = {
		squad_bestine_pirates = {SHIP_SQUADRON_FORM_WALL, {"bestine_pirate", "bestine_pirate"}},
		squad_bh_target_escort_1 = {SHIP_SQUADRON_FORM_WEDGE, {"bh_target_guard", "bh_target_guard", "bh_target_guard"}},
		squad_bh_target_escort_2 = {SHIP_SQUADRON_FORM_WEDGE, {"bh_target_guard_elite", "bh_target_guard", "bh_target_guard_elite"}},
		squad_bwing_standard_ace = {SHIP_SQUADRON_FORM_WALL, {"reb_bwing_tier2", "reb_bwing_tier2", "reb_bwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"}},
		squad_blacklight_pirate_naboo_quest = {SHIP_SQUADRON_FORM_WEDGE, {"blacklight_pirate_fighter_quest", "blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3"}},
		squad_corvette_blockade_run = {SHIP_SQUADRON_FORM_LINE, {"reb_gunboat_tier5", "reb_bwing_tier4", "reb_bwing_tier4", "reb_awing_tier4", "reb_awing_tier4"}},
		squad_corvette_convoy_imp = {SHIP_SQUADRON_FORM_WEDGE, {"imp_corellian_corvette_tier4", "imp_imperial_gunboat_tier5", "imp_imperial_gunboat_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5", "imp_tie_aggressor_tier5", "imp_tie_aggressor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5"}},
		squad_corvette_convoy_reb = {SHIP_SQUADRON_FORM_WEDGE, {"reb_corellian_corvette_tier4", "reb_gunboat_tier5", "reb_gunboat_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_bwing_tier5", "reb_bwing_tier5"}},
		squad_dath_deathmarked_mercenary = {SHIP_SQUADRON_FORM_WEDGE, {"dath_deathmarked_mercenary", "dath_deathmarked_mercenary"}},
		squad_dath_freelance_killer = {SHIP_SQUADRON_FORM_WALL, {"dath_freelance_killer_tier4", "dath_freelance_killer_tier4", "dath_freelance_killer_tier4"}},
		squad_dath_witchblood_clan = {SHIP_SQUADRON_FORM_LINE, {"dath_witchblood_clan_soldier_tier4", "dath_witchblood_clan_soldier_tier4", "dath_witchblood_clan_soldier_tier4", "dath_witchblood_clan_soldier_tier4"}},
		squad_hutt_skiffs = {SHIP_SQUADRON_FORM_WALL, {"hutt_pirate_s01_tier2", "hutt_pirate_s01_tier2"}},
		squad_hutt_skiffs_tier1 = {SHIP_SQUADRON_FORM_WALL, {"hutt_pirate_s01_tier1", "hutt_pirate_s01_tier1"}},
		squad_imperial_destroyer = {SHIP_SQUADRON_FORM_LINE, {"imp_decimator_tier3", "imp_tie_bomber_tier3", "imp_tie_bomber_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"}},
		squad_imperial_fleet = {SHIP_SQUADRON_FORM_LINE, {"imp_imperial_gunboat_tier4", "imp_decimator_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"}},
		squad_kessel_imperial_attack = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_aggressor_tier5", "imp_tie_aggressor_tier5", "imp_tie_interceptor_tier5"}},
		squad_kessel_loot_gunboat_solo_imp = {SHIP_SQUADRON_FORM_WALL, {"imp_imperial_kessel_lootboat_tier5"}},
		squad_kessel_loot_gunboat_solo_reb = {SHIP_SQUADRON_FORM_WALL, {"reb_kessel_lootboat_tier5"}},
		squad_kessel_lootship_w1_imp = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_kessel_lootboat_tier5", "imp_tie_advanced_tier5"}},
		squad_kessel_lootship_w1_reb = {SHIP_SQUADRON_FORM_WEDGE, {"reb_kessel_lootboat_tier5", "reb_xwing_tier5"}},
		squad_kessel_lootship_w2_imp = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_kessel_lootboat_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5"}},
		squad_kessel_lootship_w2_reb = {SHIP_SQUADRON_FORM_WEDGE, {"reb_kessel_lootboat_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_kessel_lootship_w2b_imp = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_kessel_lootboat_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5"}},
		squad_kessel_lootship_w2b_reb = {SHIP_SQUADRON_FORM_WEDGE, {"reb_kessel_lootboat_tier5", "reb_awing_tier5", "reb_awing_tier5"}},
		squad_kessel_lootship_w2_and_w2b_imp = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_kessel_lootboat_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_imperial_kessel_lootboat_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5"}},
		squad_kessel_lootship_w2_and_w2b_reb = {SHIP_SQUADRON_FORM_WEDGE, {"reb_kessel_lootboat_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_kessel_lootboat_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_kessel_pirate_attack = {SHIP_SQUADRON_FORM_WALL, {"hutt_fighter_s01_tier5", "hutt_fighter_s01_tier5", "hutt_pirate_s02_tier5"}},
		squad_kessel_pirate_attack_imp = {SHIP_SQUADRON_FORM_WALL, {"corsair_raider_tier5", "corsair_raider_tier5", "corsair_manowar_tier5"}},
		squad_kessel_pirate_attack_reb = {SHIP_SQUADRON_FORM_WALL, {"blacksun_fighter_s01_tier5", "blacksun_fighter_s01_tier5", "blacksun_ace_s04_tier5"}},
		squad_kessel_rebel_attack = {SHIP_SQUADRON_FORM_WEDGE, {"reb_xwing_tier5", "reb_xwing_tier5", "reb_bwing_tier5"}},
		squad_mining_freighter_nym = {SHIP_SQUADRON_FORM_WALL, {"freighterlight_mining_nym", "nym_enforcer_tier2", "nym_enforcer_tier2"}},
		squad_naboo_boss = {SHIP_SQUADRON_FORM_WALL, {"obsidian_torpedo_boss", "penumbra_omen_fighter_tier2", "penumbra_omen_fighter_tier2", "penumbra_omen_fighter_tier2", "penumbra_omen_eliminator_tier2", "penumbra_omen_eliminator_tier2"}},
		squad_nym_fighter_wing = {SHIP_SQUADRON_FORM_WEDGE, {"nym_cannon_ship_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2"}},
		squad_plyr_cmd_bmbr_advanced = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber", "player_command_tie_bomber"}},
		squad_plyr_cmd_bmbr_advanced_tier1 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier2", "player_command_tie_bomber_tier2", "escort_tie_interceptor_tier2", "escort_tie_interceptor_tier2", "escort_tie_interceptor_tier2", "escort_tie_interceptor_tier2"}},
		squad_plyr_cmd_bmbr_advanced_tier2 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier3", "player_command_tie_bomber_tier3", "escort_tie_interceptor_tier3", "escort_tie_interceptor_tier3", "escort_tie_interceptor_tier3", "escort_tie_interceptor_tier3"}},
		squad_plyr_cmd_bmbr_advanced_tier3 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier4", "player_command_tie_bomber_tier4", "escort_tie_interceptor_tier4", "escort_tie_interceptor_tier4", "escort_tie_interceptor_tier4", "escort_tie_interceptor_tier4"}},
		squad_plyr_cmd_bmbr_advanced_tier4 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5"}},
		squad_plyr_cmd_bmbr_advanced_tier5 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5"}},
		squad_plyr_cmd_bmbr_basic = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber", "escort_tie_basic_tier2", "escort_tie_basic_tier2"}},
		squad_plyr_cmd_bmbr_basic_tier1 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier2", "escort_tie_basic_tier2", "escort_tie_basic_tier2"}},
		squad_plyr_cmd_bmbr_basic_tier2 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier3", "escort_tie_basic_tier3", "escort_tie_basic_tier3"}},
		squad_plyr_cmd_bmbr_basic_tier3 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier4", "escort_tie_basic_tier4", "escort_tie_basic_tier4"}},
		squad_plyr_cmd_bmbr_basic_tier4 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "escort_tie_basic_tier5", "escort_tie_basic_tier5"}},
		squad_plyr_cmd_bmbr_basic_tier5 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "escort_tie_basic_tier5", "escort_tie_basic_tier5"}},
		squad_plyr_cmd_bmbr_escort_advanced = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced", "escort_tie_advanced"}},
		squad_plyr_cmd_bmbr_escort_advanced_tier1 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced_tier1", "escort_tie_advanced_tier1"}},
		squad_plyr_cmd_bmbr_escort_advanced_tier2 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced_tier2", "escort_tie_advanced_tier2"}},
		squad_plyr_cmd_bmbr_escort_advanced_tier3 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced_tier3", "escort_tie_advanced_tier3"}},
		squad_plyr_cmd_bmbr_escort_advanced_tier4 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced_tier4", "escort_tie_advanced_tier4"}},
		squad_plyr_cmd_bmbr_escort_advanced_tier5 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced_tier5", "escort_tie_advanced_tier5"}},
		squad_plyr_cmd_bmbr_escort_advanced_plus = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_advanced", "escort_tie_advanced", "escort_tie_advanced", "escort_tie_advanced"}},
		squad_plyr_cmd_bmbr_escort_basic = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic", "escort_tie_basic"}},
		squad_plyr_cmd_bmbr_escort_basic_tier1 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic_tier1", "escort_tie_basic_tier1"}},
		squad_plyr_cmd_bmbr_escort_basic_tier2 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic_tier2", "escort_tie_basic_tier2"}},
		squad_plyr_cmd_bmbr_escort_basic_tier3 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic_tier3", "escort_tie_basic_tier3"}},
		squad_plyr_cmd_bmbr_escort_basic_tier4 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic_tier4", "escort_tie_basic_tier4"}},
		squad_plyr_cmd_bmbr_escort_basic_tier5 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic_tier5", "escort_tie_basic_tier5"}},
		squad_plyr_cmd_bmbr_escort_basic_plus = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_basic", "escort_tie_basic", "escort_tie_basic", "escort_tie_basic"}},
		squad_plyr_cmd_bmbr_escort_interceptor = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor", "escort_tie_interceptor"}},
		squad_plyr_cmd_bmbr_escort_interceptor_tier1 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor_tier1", "escort_tie_interceptor_tier1"}},
		squad_plyr_cmd_bmbr_escort_interceptor_tier2 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor_tier2", "escort_tie_interceptor_tier2"}},
		squad_plyr_cmd_bmbr_escort_interceptor_tier3 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor_tier3", "escort_tie_interceptor_tier3"}},
		squad_plyr_cmd_bmbr_escort_interceptor_tier4 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor_tier4", "escort_tie_interceptor_tier4"}},
		squad_plyr_cmd_bmbr_escort_interceptor_tier5 = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor_tier5", "escort_tie_interceptor_tier5"}},
		squad_plyr_cmd_bmbr_escort_interceptor_plus = {SHIP_SQUADRON_FORM_LINE, {"escort_tie_interceptor", "escort_tie_interceptor", "escort_tie_interceptor", "escort_tie_interceptor"}},
		squad_plyr_cmd_bmbr_extreme = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber", "player_command_tie_bomber", "player_command_tie_bomber", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2"}},
		squad_plyr_cmd_bmbr_extreme_tier1 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier2", "player_command_tie_bomber_tier2", "player_command_tie_bomber_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2", "escort_tie_advanced_tier2"}},
		squad_plyr_cmd_bmbr_extreme_tier2 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier3", "player_command_tie_bomber_tier3", "player_command_tie_bomber_tier3", "escort_tie_advanced_tier3", "escort_tie_advanced_tier3", "escort_tie_advanced_tier3", "escort_tie_advanced_tier3", "escort_tie_advanced_tier3", "escort_tie_advanced_tier3"}},
		squad_plyr_cmd_bmbr_extreme_tier3 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier4", "player_command_tie_bomber_tier4", "player_command_tie_bomber_tier4", "escort_tie_advanced_tier4", "escort_tie_advanced_tier4", "escort_tie_advanced_tier4", "escort_tie_advanced_tier4", "escort_tie_advanced_tier4", "escort_tie_advanced_tier4"}},
		squad_plyr_cmd_bmbr_extreme_tier4 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5"}},
		squad_plyr_cmd_bmbr_extreme_tier5 = {SHIP_SQUADRON_FORM_LINE, {"player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "player_command_tie_bomber_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5", "escort_tie_advanced_tier5"}},
		squad_rebel_station_1 = {SHIP_SQUADRON_FORM_WALL, {"reb_corellian_corvette_tier4", "reb_ywing_tier5", "reb_ywing_tier5", "reb_ywing_tier5", "reb_ywing_tier5", "reb_ywing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5"}},
		squad_rebel_station_2 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_corellian_corvette_tier4", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_rebel_station_3 = {SHIP_SQUADRON_FORM_LINE, {"reb_gunboat_tier5", "reb_gunboat_tier5", "reb_gunboat_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_rebel_station_4 = {SHIP_SQUADRON_FORM_LINE, {"reb_gunboat_tier5", "reb_gunboat_tier5", "reb_gunboat_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_z95_tier5", "reb_z95_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_rebel_station_5 = {SHIP_SQUADRON_FORM_LINE, {"reb_ykl37r_tier5", "reb_ykl37r_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_bwing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5"}},
		squad_rebel_testing_droids = {SHIP_SQUADRON_FORM_WEDGE, {"rebel_droid_training_ship_tier3", "rebel_droid_training_ship_tier3", "rebel_droid_training_ship_tier3", "rebel_droid_training_ship_tier3", "rebel_droid_training_ship_tier3"}},
		squad_stardestroyer_1 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_fighter_tier5", "imp_tie_fighter_tier5", "imp_tie_fighter_tier5", "imp_tie_fighter_tier5"}},
		squad_stardestroyer_2 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier5", "imp_imperial_gunboat_tier5", "imp_imperial_gunboat_tier5", "imp_tie_bomber_tier5", "imp_tie_advanced_tier5", "imp_tie_advanced_tier5", "imp_tie_oppressor_tier5", "imp_tie_advanced_tier5", "imp_tie_advanced_tier5", "imp_tie_advanced_tier5"}},
		squad_stardestroyer_3 = {SHIP_SQUADRON_FORM_LINE, {"imp_imperial_gunboat_tier5", "imp_imperial_gunboat_tier5", "imp_imperial_gunboat_tier5", "imp_tie_bomber_tier5", "imp_tie_bomber_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5", "imp_tie_oppressor_tier5"}},
		squad_stardestroyer_4 = {SHIP_SQUADRON_FORM_LINE, {"imp_decimator_tier5", "imp_lambda_shuttle_tier5", "imp_decimator_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5", "imp_tie_interceptor_tier5"}},
		squad_stardestroyer_5 = {SHIP_SQUADRON_FORM_LINE, {"imp_imperial_gunboat_tier5", "imp_lambda_shuttle_tier5", "imp_decimator_tier5", "imp_tie_bomber_tier5", "imp_tie_bomber_tier5", "imp_tie_bomber_tier5", "imp_tie_bomber_tier5", "imp_tie_aggressor_tier5", "imp_tie_aggressor_tier5", "imp_tie_aggressor_tier5"}},
		squad_test = {SHIP_SQUADRON_FORM_WEDGE, {"xwing", "awing", "awing", "awing", "awing", "awing", "awing"}},
		squad_tie_advanced_ace = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_advanced_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_aggressor_ace = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_aggressor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_bomber_tier4 = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_bomber_tier4", "imp_tie_bomber_tier4", "imp_tie_bomber_tier4"}},
		squad_tie_bomber_ace = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_bomber_tier3", "imp_tie_bomber_tier3", "imp_tie_bomber_tier3"}},
		squad_tie_bomber_average = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_bomber_tier3", "imp_tie_bomber_tier2", "imp_tie_bomber_tier2"}},
		squad_tie_bomber_rookie = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_bomber_tier2", "imp_tie_bomber_tier2", "imp_tie_bomber_tier2"}},
		squad_tie_bomberwithguard_tier4 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_bomberwithguard_ace = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"}},
		squad_tie_bomberwithguard_average = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier3", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_bomberwithguard_rookie = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_bomberwithguard_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_tie_interceptor_tier4 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4"}},
		squad_tie_interceptor_ace = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3"}},
		squad_tie_interceptor_average = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"}},
		squad_tie_interceptor_rookie = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2"}},
		squad_tie_mix_tier4 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_mix_ace = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"}},
		squad_tie_mix_average = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier3", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_mix_ace_average = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier3", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"}},
		squad_tie_mix_rookie = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_mix_tier1 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_interceptor_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_tie_oppressor_ace = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_oppressor_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_standard_tier4 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4"}},
		squad_tie_standard_ace = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3"}},
		squad_tie_standard_average = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_fighter_tier3", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_standard_rookie = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_tie_standard_tier1 = {SHIP_SQUADRON_FORM_WALL, {"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_valarian_fighter_rookie_big = {SHIP_SQUADRON_FORM_WEDGE, {"valarian_fighter_rookie", "valarian_fighter_rookie", "valarian_fighter_rookie", "valarian_fighter_rookie", "valarian_fighter_rookie"}},
		squad_valarian_fighter_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"valarian_bomber_tier1", "valarian_fighter_tier1", "valarian_fighter_tier1"}},
		squad_valarian_fighter_rookie_small = {SHIP_SQUADRON_FORM_WEDGE, {"valarian_bomber_tier2", "valarian_fighter_tier2", "valarian_fighter_tier2"}},
		squad_valarian_leader_rookie = {SHIP_SQUADRON_FORM_WEDGE, {"valarian_gunship_average", "valarian_fighter_rookie", "valarian_fighter_rookie"}},
		squad_viopa_rebel_1 = {SHIP_SQUADRON_FORM_WALL, {"viopa_mission_1_shuttle", "vortex_mission_4_guard", "vortex_mission_4_guard"}},
		squad_viopa_rebel_4 = {SHIP_SQUADRON_FORM_WEDGE, {"viopa_mission_4_freighter", "kuat_fighter", "kuat_fighter", "kuat_fighter", "kuat_fighter", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_vortex_mission_4 = {SHIP_SQUADRON_FORM_WALL, {"vortex_mission_4_shuttle", "vortex_mission_4_guard", "vortex_mission_4_guard", "vortex_mission_4_guard"}},
		squad_xwing_small_average = {SHIP_SQUADRON_FORM_WALL, {"reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"}},
		squad_xwing_standard_rookie = {SHIP_SQUADRON_FORM_WEDGE, {"reb_ywing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2"}},
		squad_xwing_standard_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_ywing_tier1", "reb_xwing_tier1", "reb_xwing_tier1", "reb_xwing_tier1", "reb_xwing_tier1"}},
		squad_yavin_rebel_2 = {SHIP_SQUADRON_FORM_WALL, {"yavin_mission_2_shuttle", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_yavin_rebel_3 = {SHIP_SQUADRON_FORM_WALL, {"yavin_mission_3_shuttle", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"}},
		squad_hutt_tatooine_1 = {SHIP_SQUADRON_FORM_LINE, {"hutt_pirate_s01_tier1", "hutt_pirate_s01_tier1", "hutt_bomber_s01_tier1", "hutt_fighter_s01_tier1", "hutt_fighter_s01_tier1", "hutt_fighter_s01_tier1"}},
		squad_imperial_naboo_1 = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_advanced_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_naboo_2 = {SHIP_SQUADRON_FORM_LINE, {"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_naboo_3 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_advanced_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_naboo_4 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_tatooine_1 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_lambda_shuttle_tier1", "imp_tie_bomber_tier1_tatooine", "imp_tie_fighter_tier1_tatooine", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1_tatooine"}},
		squad_imperial_tatooine_2 = {SHIP_SQUADRON_FORM_LINE, {"imp_lambda_shuttle_tier1", "imp_tie_interceptor_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_tatooine_3 = {SHIP_SQUADRON_FORM_WALL, {"imp_lambda_shuttle_tier1", "imp_tie_bomber_tier1", "imp_tie_interceptor_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_imperial_tatooine_4 = {SHIP_SQUADRON_FORM_WALL, {"imp_lambda_shuttle_tier1", "imp_tie_advanced_tier1", "imp_tie_interceptor_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"}},
		squad_rebel_corellia_1 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier1", "reb_z95_tier1", "reb_z95_tier1"}},
		squad_rebel_corellia_2 = {SHIP_SQUADRON_FORM_WALL, {"reb_ywing_tier2", "reb_z95_tier2", "reb_z95_tier1", "reb_z95_tier1", "reb_z95_tier1"}},
		squad_rebel_corellia_3 = {SHIP_SQUADRON_FORM_LINE, {"reb_xwing_tier2", "reb_z95_tier2", "reb_z95_tier1", "reb_z95_tier1", "reb_z95_tier1"}},
		squad_rebel_corellia_4 = {SHIP_SQUADRON_FORM_WALL, {"reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier1", "reb_z95_tier1", "reb_z95_tier1"}},
		squad_rebel_lok_1 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_ywing_tier4", "reb_ywing_tier4", "reb_ywing_tier4", "reb_ywing_tier4"}},
		squad_rebel_lok_2 = {SHIP_SQUADRON_FORM_WALL, {"reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4", "reb_xwing_tier4"}},
		squad_rebel_lok_3 = {SHIP_SQUADRON_FORM_LINE, {"reb_z95_tier4", "reb_z95_tier4", "reb_z95_tier4", "reb_z95_tier4"}},
		squad_rebel_lok_4 = {SHIP_SQUADRON_FORM_WALL, {"reb_ywing_tier4", "reb_z95_tier4", "reb_xwing_tier4"}},
		squad_rebel_dantooine_1 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_awing_tier5", "reb_bwing_tier5", "reb_z95_tier5", "reb_z95_tier5"}},
		squad_rebel_dantooine_2 = {SHIP_SQUADRON_FORM_WALL, {"reb_ywing_tier5", "reb_ywing_tier5", "reb_ywing_tier5"}},
		squad_rebel_dantooine_3 = {SHIP_SQUADRON_FORM_WALL, {"reb_xwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5", "reb_xwing_tier5"}},
		squad_rebel_dantooine_4 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5", "reb_awing_tier5"}},
		squad_boss_corellia_imperial_major_gek = {SHIP_SQUADRON_FORM_WEDGE, {"imperial_major_gek", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_interceptor_tier1", "imp_tie_interceptor_tier1", "imp_tie_interceptor_tier1"}},
		squad_po_mcannon_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"po_mcannon_tier2", "bestine_pirate_tier1", "bestine_pirate_tier1", "bestine_pirate_tier1"}},
		squad_vsin_starbomber_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"vsin_starbomber_tier2", "bestine_pirate_tier1", "bestine_pirate_tier1", "bestine_pirate_tier1"}},
		squad_poi_quest_hutts = {SHIP_SQUADRON_FORM_WEDGE, {"hutt_assassin_s01_tier1", "hutt_assassin_s01_tier1", "hutt_bomber_s01_tier1_tatooine", "hutt_bomber_s01_tier1_tatooine", "hutt_fighter_s01_tier1", "hutt_fighter_s01_tier1", "hutt_fighter_s01_tier1"}},
		squad_civilian_traffic_light = {SHIP_SQUADRON_FORM_WALL, {"ep3_merc_cruiser", "ep3_merc_freighter", "ep3_merc_cruiser"}},
		squad_civilian_traffic_heavy = {SHIP_SQUADRON_FORM_WALL, {"civilian_science_transport_tier1", "civshuttle", "civilian_science_transport_tier1", "civshuttle"}},
		squad_gotal_bandits = {SHIP_SQUADRON_FORM_LINE, {"ep3_gotal_bandit", "ep3_gotal_bandit", "ep3_gotal_bandit", "ep3_gotal_bandit_ace"}},
		squad_chiss_poachers = {SHIP_SQUADRON_FORM_WEDGE, {"ep3_chiss_poacher", "ep3_chiss_poacher", "ep3_chiss_poacher_ace"}},
		squad_rodian_protectors = {SHIP_SQUADRON_FORM_WEDGE, {"ep3_rodian_protector_fighter", "ep3_rodian_protector_fighter", "ep3_rodian_protector_fighter", "ep3_rodian_protector_ace"}},
		squad_trandoshan_fighters = {SHIP_SQUADRON_FORM_WALL, {"ep3_trandoshan_fighter", "ep3_trandoshan_fighter", "ep3_trandoshan_fighter"}},
		squad_wookiee_resistance_fighters = {SHIP_SQUADRON_FORM_WEDGE, {"ep3_wookiee_resistance_commander", "ep3_wookiee_resistance_fighter", "ep3_wookiee_resistance_fighter", "ep3_wookiee_resistance_fighter"}},
		squad_independent_slaver_fighters = {SHIP_SQUADRON_FORM_WEDGE, {"ep3_independent_slaver_fighter", "ep3_independent_slaver_fighter", "ep3_independent_slaver_fighter", "ep3_independent_slaver_bomber"}},
		squad_e3_tie_mix_interceptor = {SHIP_SQUADRON_FORM_WALL, {"e3_imp_tie_interceptor_tier4", "e3_imp_tie_fighter_tier4", "e3_imp_tie_fighter_tier4"}},
		squad_e3_tie_mix_advanced = {SHIP_SQUADRON_FORM_WALL, {"e3_imp_tie_advanced_tier4", "e3_imp_tie_interceptor_tier4", "e3_imp_tie_interceptor_tier4"}},
		squad_e3_tie_standard = {SHIP_SQUADRON_FORM_LINE, {"e3_imp_tie_fighter_tier4", "e3_imp_tie_fighter_tier4", "e3_imp_tie_fighter_tier4"}},
		squad_e3_lambda = {SHIP_SQUADRON_FORM_WALL, {"e3_imp_lambda_shuttle_tier4", "e3_imp_tie_interceptor_tier4", "e3_imp_tie_interceptor_tier4"}},
		squad_capital_ship_convoy_nym = {SHIP_SQUADRON_FORM_WALL, {"nym_gunship_tier5", "nym_capital_ship_tier5", "nym_lieutenant_tier5", "nym_cannon_ship_tier5", "nym_yt1300_tier5", "nym_bomber_tier5", "nym_fighter_tier5"}},
		squad_yt1300_tier_5_convoy_nym = {SHIP_SQUADRON_FORM_WEDGE, {"nym_yt1300_tier5", "nym_yt1300_tier5", "nym_lieutenant_tier5", "nym_bomber_tier5", "nym_enforcer_tier5", "nym_blastboat_tier5"}},
		squad_nym_tier5_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_bomber_tier5", "nym_bomber_tier5", "nym_bomber_tier5", "nym_enforcer_tier5", "nym_enforcer_tier5", "nym_enforcer_tier5"}},
		squad_nym_gunboat_tier5_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_gunship_tier5", "nym_cannon_ship_tier5", "nym_lieutenant_tier5"}},
		squad_nym_gunboat_tier5_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_gunship_tier5", "nym_yt1300_tier5", "nym_lieutenant_tier5"}},
		squad_nym_gunboat_tier5_patrol_03 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_patrol_craft_tier5", "nym_lieutenant_tier5"}},
		squad_yt1300_tier_4_convoy_nym = {SHIP_SQUADRON_FORM_WALL, {"nym_yt1300_tier4", "nym_yt1300_tier4", "nym_lieutenant_tier4", "nym_bomber_tier4", "nym_enforcer_tier4", "nym_blastboat_tier4"}},
		squad_nym_tier4_patrol = {SHIP_SQUADRON_FORM_WEDGE, {"nym_bomber_tier4", "nym_bomber_tier4", "nym_enforcer_tier4", "nym_enforcer_tier4"}},
		squad_nym_gunboat_tier4_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_gunship_tier4", "nym_cannon_ship_tier4", "nym_lieutenant_tier4"}},
		squad_nym_gunboat_tier4_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_gunship_tier4", "nym_yt1300_tier4", "nym_lieutenant_tier4"}},
		squad_nym_gunboat_tier4_patrol_03 = {SHIP_SQUADRON_FORM_WEDGE, {"nym_patrol_craft_tier4", "nym_lieutenant_tier4"}},
		squad_droid_tier5 = {SHIP_SQUADRON_FORM_WEDGE, {"rogue_droid_tier5_boss", "rogue_droid_alpha_tier5", "rogue_droid_defender_tier5", "rogue_droid_fighter_tier5", "rogue_droid_scrapper_tier5", "rogue_droid_tier5_boss", "rogue_droid_alpha_tier5", "rogue_droid_defender_tier5", "rogue_droid_fighter_tier5", "rogue_droid_scrapper_tier5"}},
		squad_droid_tier4 = {SHIP_SQUADRON_FORM_WEDGE, {"rogue_droid_tier4_boss", "rogue_droid_alpha_tier4", "rogue_droid_defender_tier4", "rogue_droid_fighter_tier4", "rogue_droid_scrapper_tier4", "rogue_droid_tier4_boss", "rogue_droid_alpha_tier4", "rogue_droid_defender_tier4", "rogue_droid_fighter_tier4", "rogue_droid_scrapper_tier4"}},
		squad_droid_tier3 = {SHIP_SQUADRON_FORM_WEDGE, {"rogue_droid_tier3_boss", "rogue_droid_alpha_tier3", "rogue_droid_defender_tier3", "rogue_droid_fighter_tier3", "rogue_droid_scrapper_tier3", "rogue_droid_tier3_boss", "rogue_droid_alpha_tier3", "rogue_droid_defender_tier3", "rogue_droid_fighter_tier3", "rogue_droid_scrapper_tier3"}},
		squad_droid_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"rogue_droid_tier2_boss", "rogue_droid_alpha_tier2", "rogue_droid_defender_tier2", "rogue_droid_fighter_tier2", "rogue_droid_scrapper_tier2", "rogue_droid_tier2_boss", "rogue_droid_alpha_tier2", "rogue_droid_defender_tier2", "rogue_droid_fighter_tier2", "rogue_droid_scrapper_tier2"}},
		squad_droid_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"rogue_droid_tier1_boss", "rogue_droid_alpha_tier1", "rogue_droid_defender_tier1", "rogue_droid_fighter_tier1", "rogue_droid_scrapper_tier1", "rogue_droid_alpha_tier1", "rogue_droid_defender_tier1", "rogue_droid_fighter_tier1", "rogue_droid_scrapper_tier1"}},
		squad_blacksun_capital_convoy = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier5", "blacksun_dark_eclipse_tier5", "blacksun_yt1300_tier5", "blacksun_bomber_ace_s04_tier5", "blacksun_bomber_s01_tier5", "blacksun_aggressor_tier5", "blacksun_marauder_tier5", "blacksun_fighter_s03_tier5", "blacksun_heavy_fighter_tier5", "blacksun_medium_fighter_tier5"}},
		squad_blacksun_tier5_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier5", "blacksun_yt1300_tier5", "blacksun_bomber_ace_s04_tier5", "blacksun_bomber_s01_tier5", "blacksun_aggressor_tier5", "blacksun_marauder_tier5", "blacksun_fighter_s03_tier5", "blacksun_heavy_fighter_tier5", "blacksun_medium_fighter_tier5"}},
		squad_blacksun_tier5_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier5", "blacksun_bomber_ace_s04_tier5", "blacksun_bomber_s01_tier5", "blacksun_aggressor_tier5", "blacksun_marauder_tier5", "blacksun_fighter_s03_tier5", "blacksun_heavy_fighter_tier5", "blacksun_medium_fighter_tier5"}},
		squad_blacksun_tier5_patrol_03 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_bomber_ace_s04_tier5", "blacksun_bomber_s01_tier5", "blacksun_aggressor_tier5", "blacksun_marauder_tier5", "blacksun_fighter_s03_tier5", "blacksun_heavy_fighter_tier5", "blacksun_medium_fighter_tier5", "blacksun_medium_fighter_tier5"}},
		squad_blacksun_tier4_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier4", "blacksun_yt1300_tier4", "blacksun_bomber_s03_tier4", "blacksun_bomber_s01_tier4", "blacksun_aggressor_tier4", "blacksun_marauder_tier4", "blacksun_fighter_s03_tier4", "blacksun_medium_fighter_tier4"}},
		squad_blacksun_tier4_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier4", "blacksun_bomber_s03_tier4", "blacksun_bomber_s01_tier4", "blacksun_aggressor_tier4", "blacksun_marauder_tier4", "blacksun_fighter_s03_tier4", "blacksun_medium_fighter_tier4"}},
		squad_blacksun_tier4_patrol_03 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_bomber_ace_s04_tier4", "blacksun_bomber_s01_tier4", "blacksun_aggressor_tier4", "blacksun_marauder_tier4", "blacksun_fighter_s03_tier4", "blacksun_medium_fighter_tier4", "blacksun_medium_fighter_tier4"}},
		squad_rebel_gunboat_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_gunboat_tier1", "reb_bwing_tier1", "reb_awing_tier1", "reb_xwing_tier1", "reb_ywing_tier1", "reb_z95_tier1"}},
		squad_rebel_gunboat_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_gunboat_tier2", "reb_bwing_tier2", "reb_awing_tier2", "reb_xwing_tier2", "reb_ywing_tier2", "reb_z95_tier2"}},
		squad_rebel_gunboat_tier3 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_gunboat_tier3", "reb_bwing_tier3", "reb_awing_tier3", "reb_xwing_tier3", "reb_ywing_tier3", "reb_z95_tier3"}},
		squad_rebel_gunboat_tier4 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_gunboat_tier4", "reb_bwing_tier4", "reb_awing_tier4", "reb_xwing_tier4", "reb_ywing_tier4", "reb_z95_tier4"}},
		squad_rebel_gunboat_tier5 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_gunboat_tier5", "reb_bwing_tier5", "reb_awing_tier5", "reb_xwing_tier5", "reb_ywing_tier5", "reb_z95_tier5"}},
		squad_rebel_smuggler_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_smuggler_yt1300_tier2", "reb_awing_tier2", "reb_xwing_tier2", "reb_ywing_tier2"}},
		squad_rebel_smuggler_tier3 = {SHIP_SQUADRON_FORM_WEDGE, {"rebel_smuggler_tier3", "reb_awing_tier3", "reb_xwing_tier3", "reb_ywing_tier3"}},
		squad_rebel_smuggler_tier4 = {SHIP_SQUADRON_FORM_WEDGE, {"yt1300_rebel_freighter", "reb_awing_tier4", "reb_xwing_tier4", "reb_ywing_tier4"}},
		squad_rebel_smuggler_tier5 = {SHIP_SQUADRON_FORM_WEDGE, {"reb_awing_tier5", "reb_xwing_tier5", "reb_ywing_tier5"}},
		squad_imperial_tier1_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier1", "imp_lambda_shuttle_tier1", "imp_tie_fighter_tier1", "imp_tie_interceptor_tier1", "imp_tie_bomber_tier1", "imp_tie_advanced_tier1"}},
		squad_imperial_tier1_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier1", "imp_lambda_shuttle_tier1", "imp_tie_oppressor_tier1", "imp_tie_interceptor_tier1", "imp_tie_aggressor_tier1", "imp_tie_advanced_tier1"}},
		squad_imperial_tier2_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier2", "imp_lambda_shuttle_tier2", "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_bomber_tier2", "imp_tie_advanced_tier2"}},
		squad_imperial_tier2_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier2", "imp_lambda_shuttle_tier2", "imp_tie_oppressor_tier2", "imp_tie_interceptor_tier2", "imp_tie_aggressor_tier2", "imp_tie_advanced_tier2"}},
		squad_imperial_tier3_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier3", "imp_lambda_shuttle_tier3", "imp_tie_fighter_tier3", "imp_tie_interceptor_tier3", "imp_tie_bomber_tier3", "imp_tie_advanced_tier3"}},
		squad_imperial_tier3_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier3", "imp_lambda_shuttle_tier3", "imp_tie_oppressor_tier3", "imp_tie_interceptor_tier3", "imp_tie_aggressor_tier3", "imp_tie_advanced_tier3"}},
		squad_imperial_tier4_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier4", "imp_lambda_shuttle_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_bomber_tier4", "imp_tie_advanced_tier4"}},
		squad_imperial_tier4_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier4", "imp_lambda_shuttle_tier4", "imp_tie_oppressor_tier4", "imp_tie_interceptor_tier4", "imp_tie_aggressor_tier4", "imp_tie_advanced_tier4"}},
		squad_imperial_tier5_patrol_01 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier5", "imp_lambda_shuttle_tier5", "imp_tie_fighter_tier5", "imp_tie_interceptor_tier5", "imp_tie_bomber_tier5", "imp_tie_advanced_tier5"}},
		squad_imperial_tier5_patrol_02 = {SHIP_SQUADRON_FORM_WEDGE, {"imp_imperial_gunboat_tier5", "imp_lambda_shuttle_tier5", "imp_tie_oppressor_tier5", "imp_tie_interceptor_tier5", "imp_tie_aggressor_tier5", "imp_tie_advanced_tier5"}},
		squad_blacksun_tier1_gunship_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier1", "blacksun_fighter_s01_tier1", "blacksun_marauder_tier1"}},
		squad_blacksun_tier1_gunship_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier1", "blacksun_marauder_tier1", "blacksun_bomber_s01_tier2", "blacksun_marauder_tier1"}},
		squad_blacksun_tier2_gunship_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier2", "blacksun_fighter_s01_tier2", "blacksun_marauder_tier2"}},
		squad_blacksun_tier2_gunship_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier2", "blacksun_marauder_tier2", "blacksun_bomber_s01_tier3", "blacksun_marauder_tier2"}},
		squad_blacksun_tier3_gunship_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier3", "blacksun_dune_lizard_tier3", "blacksun_heavy_fighter_tier3", "blacksun_fighter_s01_tier3", "blacksun_marauder_tier3"}},
		squad_blacksun_tier3_gunship_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier3", "blacksun_marauder_tier3", "blacksun_heavy_fighter_tier3", "blacksun_bomber_s01_tier4", "blacksun_marauder_tier3"}},
		squad_blacksun_tier4_gunship_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier4", "blacksun_fighter_s01_tier4", "blacksun_marauder_tier4"}},
		squad_blacksun_tier4_gunship_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier4", "blacksun_marauder_tier4", "blacksun_bomber_s01_tier5", "blacksun_marauder_tier4"}},
		squad_blacksun_tier5_gunship_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier5", "blacksun_heavy_fighter_tier5", "blacksun_fighter_s01_tier5", "blacksun_marauder_tier5"}},
		squad_blacksun_tier5_gunship_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_gunship_tier5", "blacksun_marauder_tier5", "blacksun_heavy_fighter_tier5", "blacksun_bomber_s01_tier6", "blacksun_marauder_tier5"}},
		squad_blacksun_tier1_smuggler_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier1", "blacksun_fighter_s01_tier1", "blacksun_marauder_tier1"}},
		squad_blacksun_tier1_smuggler_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier1", "blacksun_marauder_tier1", "blacksun_bomber_s01_tier2", "blacksun_marauder_tier1"}},
		squad_blacksun_tier2_smuggler_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier2", "blacksun_fighter_s01_tier2", "blacksun_marauder_tier2"}},
		squad_blacksun_tier2_smuggler_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier2", "blacksun_marauder_tier2", "blacksun_bomber_s01_tier3", "blacksun_marauder_tier2"}},
		squad_blacksun_tier3_smuggler_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier3", "blacksun_dune_lizard_tier3", "blacksun_heavy_fighter_tier3", "blacksun_fighter_s01_tier3", "blacksun_marauder_tier3"}},
		squad_blacksun_tier3_smuggler_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier3", "blacksun_marauder_tier3", "blacksun_heavy_fighter_tier3", "blacksun_bomber_s01_tier4", "blacksun_marauder_tier3"}},
		squad_blacksun_tier4_smuggler_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier4", "blacksun_fighter_s01_tier4", "blacksun_marauder_tier4"}},
		squad_blacksun_tier4_smuggler_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier4", "blacksun_marauder_tier4", "blacksun_bomber_s01_tier5", "blacksun_marauder_tier4"}},
		squad_blacksun_tier5_smuggler_01 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier5", "blacksun_heavy_fighter_tier5", "blacksun_fighter_s01_tier5", "blacksun_marauder_tier5"}},
		squad_blacksun_tier5_smuggler_02 = {SHIP_SQUADRON_FORM_WEDGE, {"blacksun_yt1300_tier5", "blacksun_marauder_tier5", "blacksun_heavy_fighter_tier5", "blacksun_bomber_s01_tier5", "blacksun_marauder_tier5"}},
		squad_capital_ship_convoy_hidden_daggers = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier5", "hiddendaggers_capital_ship_tier5", "hiddendaggers_bomber_tier5", "hiddendaggers_bomber_tier5", "hidden_daggers_executioner_tier5", "hidden_daggers_executioner_tier5"}},
		squad_hidden_daggers_smuggler_tier1 = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier1", "hiddendaggers_bomber_tier1", "hiddendaggers_bomber_tier1", "hidden_daggers_executioner_tier1", "hidden_daggers_executioner_tier1", "hidden_daggers_executioner_tier1"}},
		squad_hidden_daggers_gunboat_tier1 = {SHIP_SQUADRON_FORM_WALL, {"hidden_daggers_gunship_tier1", "hiddendaggers_bomber_tier1", "hiddendaggers_bomber_tier1", "hidden_daggers_executioner_tier1", "hidden_daggers_executioner_tier1", "hidden_daggers_executioner_tier1"}},
		squad_hidden_daggers_smuggler_tier2 = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier2", "hiddendaggers_bomber_tier2", "hiddendaggers_bomber_tier2", "hidden_daggers_executioner_tier2", "hidden_daggers_executioner_tier2", "hidden_daggers_executioner_tier2"}},
		squad_hidden_daggers_gunboat_tier2 = {SHIP_SQUADRON_FORM_WALL, {"hidden_daggers_gunship_tier2", "hiddendaggers_bomber_tier2", "hiddendaggers_bomber_tier2", "hidden_daggers_executioner_tier2", "hidden_daggers_executioner_tier2", "hidden_daggers_executioner_tier2"}},
		squad_hidden_daggers_smuggler_tier3 = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier3", "hiddendaggers_bomber_tier3", "hiddendaggers_bomber_tier3", "hidden_daggers_executioner_tier3", "hidden_daggers_executioner_tier3", "hidden_daggers_executioner_tier3"}},
		squad_hidden_daggers_gunboat_tier3 = {SHIP_SQUADRON_FORM_WALL, {"hidden_daggers_gunship_tier3", "hiddendaggers_bomber_tier3", "hiddendaggers_bomber_tier3", "hidden_daggers_executioner_tier3", "hidden_daggers_executioner_tier3", "hidden_daggers_executioner_tier3"}},
		squad_hidden_daggers_smuggler_tier4 = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier4", "hiddendaggers_bomber_tier4", "hiddendaggers_bomber_tier4", "hidden_daggers_executioner_tier4", "hidden_daggers_executioner_tier4", "hidden_daggers_executioner_tier4"}},
		squad_hidden_daggers_gunboat_tier4 = {SHIP_SQUADRON_FORM_WALL, {"hidden_daggers_gunship_tier4", "hiddendaggers_bomber_tier4", "hiddendaggers_bomber_tier4", "hidden_daggers_executioner_tier4", "hidden_daggers_executioner_tier4", "hidden_daggers_executioner_tier4"}},
		squad_hidden_daggers_smuggler_tier5 = {SHIP_SQUADRON_FORM_WALL, {"hiddendaggers_smuggler_tier5", "hiddendaggers_bomber_tier5", "hiddendaggers_bomber_tier5", "hidden_daggers_executioner_tier5", "hidden_daggers_executioner_tier5", "hidden_daggers_executioner_tier5"}},
		squad_hidden_daggers_gunboat_tier5 = {SHIP_SQUADRON_FORM_WALL, {"hidden_daggers_gunship_tier5", "hiddendaggers_bomber_tier5", "hiddendaggers_bomber_tier5", "hidden_daggers_executioner_tier5", "hidden_daggers_executioner_tier5", "hidden_daggers_executioner_tier5"}},
		squad_capital_ship_convoy_void_wing = {SHIP_SQUADRON_FORM_WALL, {"void_wing_yt1300_tier5", "void_wing_capital_ship_tier5", "void_wing_dune_lizard_tier5", "void_wing_bomber_tier5", "void_wing_bomber_tier5"}},
		squad_void_wing_smuggler_tier1 = {SHIP_SQUADRON_FORM_WEDGE, {"void_wing_yt1300_tier1", "void_wing_dune_lizard_tier1", "void_wing_bomber_tier1", "void_wing_bomber_tier1", "void_wing_dune_lizard_tier1"}},
		squad_void_wing_smuggler_tier2 = {SHIP_SQUADRON_FORM_WEDGE, {"void_wing_yt1300_tier2", "void_wing_dune_lizard_tier2", "void_wing_bomber_tier2", "void_wing_bomber_tier2", "void_wing_dune_lizard_tier2"}},
		squad_void_wing_smuggler_tier3 = {SHIP_SQUADRON_FORM_WEDGE, {"void_wing_yt1300_tier3", "void_wing_dune_lizard_tier3", "void_wing_bomber_tier3", "void_wing_bomber_tier3", "void_wing_dune_lizard_tier3"}},
		squad_void_wing_smuggler_tier4 = {SHIP_SQUADRON_FORM_WEDGE, {"void_wing_yt1300_tier4", "void_wing_dune_lizard_tier4", "void_wing_bomber_tier4", "void_wing_bomber_tier4", "void_wing_dune_lizard_tier4"}},
		squad_void_wing_smuggler_tier5 = {SHIP_SQUADRON_FORM_WEDGE, {"void_wing_yt1300_tier5", "void_wing_dune_lizard_tier5", "void_wing_bomber_tier5", "void_wing_bomber_tier5", "void_wing_dune_lizard_tier5"}},
		squad_black_guard_tier9 = {SHIP_SQUADRON_FORM_WEDGE, {"blackguard_patrol_heavy", "blackguard_patrol_light", "blackguard_patrol_light", "blackguard_patrol_medium", "blackguard_patrol_medium"}},
	}
}

registerScreenPlay("SpaceSpawnerScreenPlay", false)

function SpaceSpawnerScreenPlay:start()
	if (not isZoneEnabled(self.spaceZone)) then
		return
	end

	local randomDelay = getRandomNumber(self.SERVER_STARTUP_MIN, self.SERVER_STARTUP_MAX)

	if (self.SPAWN_NO_DELAY) then
		randomDelay = 20
	end

	createEvent(randomDelay * 1000, self.screenplayName, "populateSpawns", nil, "")
end

function SpaceSpawnerScreenPlay:populateSpawns()
	local shipSpawns = self.shipSpawns

	if (#shipSpawns < 1) then
		return
	end

	--print("Spawning Screenplay: " .. self.screenplayName .. " Total Zone Spawners = " .. #shipSpawns)

	for i = 1, #shipSpawns, 1 do
		local spawnTable = shipSpawns[i]

		local totalSpawns = spawnTable.totalSpawns
		local spawnPatrolType = spawnTable.patrolType
		local spawnType = spawnTable.spawnType
		local minRespawn = spawnTable.minRespawn
		local maxRespawn = spawnTable.maxRespawn
		local randomDelay = getRandomNumber(minRespawn, maxRespawn)

		if (self.SPAWN_NO_DELAY) then
			randomDelay = 2
		end

		-- Spawn a squadron
		if (spawnType == SHIP_SPAWN_SQUADRON) then
			for j = 1, totalSpawns, 1 do
				--print(self.screenplayName .. " Spawn #" .. i .. " -- Spawn Name: " .. spawnTable.spawnName .. " Total Spawns: " .. totalSpawns .. " Spawn Type: " .. spawnType .. " Spawn Time in (s): " .. (randSpawn* j))

				createEvent((randomDelay * j) * 1000, self.screenplayName, "spawnShipSquadron", nil, tostring(i))
			end
		else
			-- Spawn the single ships
			for j = 1, totalSpawns, 1 do
				--print(self.screenplayName .. " Spawn #" .. i .. " -- Spawn Name: " .. spawnTable.spawnName .. " Total Spawns: " .. totalSpawns .. " Spawn Type: " .. spawnType .. " Spawn Time in (s): " .. (randSpawn* j))

				createEvent((randomDelay * j) * 1000, self.screenplayName, "spawnShipAgent", nil, tostring(i))
			end
		end
	end
end

-- Attempts travel in the event argument, not screenplay fields: Lua states are
-- per worker, whereas Director shared memory is shared by all callbacks.
local function spawnAttempt(argument)
	local index, attempt = string.match(argument, "^(%d+):?(%d*)$")
	return tonumber(index), tonumber(attempt) or 0
end

function SpaceSpawnerScreenPlay:scheduleSpawnRetry(callback, argument, attempt, pAnchor)
	if (attempt >= self.SPAWN_RETRY_LIMIT) then
		Logger:log(self.screenplayName .. " -- Spawn retries exhausted for " .. argument, LT_ERROR)
		return
	end

	createEvent(self.SPAWN_RETRY_SECONDS * 1000, self.screenplayName, callback, pAnchor, argument .. ":" .. tostring(attempt + 1))
end

function SpaceSpawnerScreenPlay:configurePatrol(pShipAgent, spawnTable, destinationCallback)
	local agent = ShipAiAgent(pShipAgent)
	local patrolType = spawnTable.patrolType

	if (patrolType == SHIP_AI_FIXED_PATROL or patrolType == SHIP_AI_SINGLE_PATROL_ROTATION) then
		agent:setFixedPatrol()
		self:assignFixedPatrolpoints(pShipAgent, spawnTable.patrolsToAssign, spawnTable.fixedPatrolPoints)

		if (patrolType == SHIP_AI_SINGLE_PATROL_ROTATION) then
			agent:setSinglePatrolRotation()

			-- Only the leader owns completion; followers inherit the same patrol
			-- mode so an engine-promoted leader can finish the convoy's route.
			if (destinationCallback ~= nil) then
				createObserver(DESTINATIONREACHED, self.screenplayName, destinationCallback, pShipAgent)
			end
		end
	elseif (patrolType == SHIP_AI_GUARD_PATROL) then
		agent:setMinimumGuardPatrol(spawnTable.minPatrol)
		agent:setMaximumGuardPatrol(spawnTable.maxPatrol)
		agent:setGuardPatrol()
	else
		agent:setRandomPatrol()
	end
end

function SpaceSpawnerScreenPlay:rememberSpawnerShip(pShipAgent, tableNum, cohortID)
	local agentID = SceneObject(pShipAgent):getObjectID()
	writeData(agentID .. ":SpawnerIndex:", tableNum)
	writeStringData(agentID .. ":SpawnerName:", self.shipSpawns[tableNum].spawnName)

	if (cohortID ~= nil) then
		writeData(agentID .. ":SpawnerSquadron:", cohortID)
	end
end

function SpaceSpawnerScreenPlay:forgetSpawnerShip(agentID)
	deleteData(agentID .. ":SpawnerIndex:")
	deleteStringData(agentID .. ":SpawnerName:")
	deleteData(agentID .. ":SpawnerSquadron:")
end

function SpaceSpawnerScreenPlay:dropSpawnObservers(pShipAgent)
	dropObserver(SHIPDESTROYED, self.screenplayName, "staticShipDestroyed", pShipAgent)
	dropObserver(SHIPDESTROYED, self.screenplayName, "squadronShipDestroyed", pShipAgent)
	dropObserver(DESTINATIONREACHED, self.screenplayName, "shipDestinationReached", pShipAgent)
	dropObserver(DESTINATIONREACHED, self.screenplayName, "squadronDestinationReached", pShipAgent)
end

function SpaceSpawnerScreenPlay:departure(pShipAgent)
	ShipObject(pShipAgent):setHyperspacing(true)
	local location = ShipObject(pShipAgent):getSpawnPointInFrontOfShip(1000, 5000)
	SceneObject(pShipAgent):setPosition(location[1], location[2], location[3])
	createEvent(1000, "SpaceHelpers", "delayedDestroyShipAgent", pShipAgent, "")
end

function SpaceSpawnerScreenPlay:spawnLocation(spawnTable)
	local distance = getRandomNumber(spawnTable.minSpawnDistance, spawnTable.maxSpawnDistance)
	local theta = math.random() * 2 * math.pi
	local phi = math.acos(1 - 2 * math.random())
	return spawnTable.x + distance * math.sin(phi) * math.cos(theta),
		spawnTable.z + distance * math.cos(phi),
		spawnTable.y + distance * math.sin(phi) * math.sin(theta)
end

function SpaceSpawnerScreenPlay:spawnShipAgent(pNil, indexString)
	local tableNum, attempt = spawnAttempt(indexString)
	local spawnTable = self.shipSpawns[tableNum]
	local shipName = spawnTable.shipSpawns[getRandomNumber(#spawnTable.shipSpawns)]
	local x, z, y = self:spawnLocation(spawnTable)
	local pShipAgent = spawnShipAgent(shipName, self.spaceZone, x, z, y)

	if (pShipAgent == nil) then
		Logger:log(self.screenplayName .. " -- Failed to spawn Ship Agent: " .. shipName, LT_ERROR)
		self:scheduleSpawnRetry("spawnShipAgent", tostring(tableNum), attempt, nil)
		return
	end

	ShipAiAgent(pShipAgent):setDespawnOnNoPlayerInRange(false)
	self:rememberSpawnerShip(pShipAgent, tableNum)
	createObserver(SHIPDESTROYED, self.screenplayName, "staticShipDestroyed", pShipAgent)
	self:configurePatrol(pShipAgent, spawnTable, "shipDestinationReached")
end

function SpaceSpawnerScreenPlay:squadronKey(cohortID)
	return self.screenplayName .. ":Squadron:" .. tostring(cohortID) .. ":"
end

function SpaceSpawnerScreenPlay:forgetSquadron(cohortID)
	local key = self:squadronKey(cohortID)
	deleteData(key .. "active")
	deleteData(key .. "index")
	deleteData(key .. "leader")
	deleteStringVectorSharedMemory(key .. "members")
end

function SpaceSpawnerScreenPlay:clearSquadronRegistrations(cohortID)
	local key = self:squadronKey(cohortID)
	local members = readStringVectorSharedMemory(key .. "members")
	writeData(key .. "active", 0)
	local survivingShips = {}
	for _, value in ipairs(members) do
		local memberID = tonumber(value)
		if (memberID > 0) then
			local pShip = getSceneObject(memberID)
			self:forgetSpawnerShip(memberID)
			if (pShip ~= nil) then
				self:dropSpawnObservers(pShip)
				if (not ShipObject(pShip):isShipDestroyed()) then
					table.insert(survivingShips, pShip)
				end
			end
		end
	end
	self:forgetSquadron(cohortID)
	return survivingShips
end

function SpaceSpawnerScreenPlay:findSquadronLeader(cohortID)
	local leader, leaderID = nil, nil
	for _, value in ipairs(readStringVectorSharedMemory(self:squadronKey(cohortID) .. "members")) do
		local agentID = tonumber(value)
		local pAgent = getSceneObject(agentID)
		if (pAgent ~= nil and readData(agentID .. ":SpawnerIndex:") > 0 and not ShipObject(pAgent):isShipDestroyed()) then
			-- SquadronObserver promotes in insertion order. OIDs are allocated in
			-- that order, even if an optional commander only succeeds on retry.
			if (leaderID == nil or agentID < leaderID) then
				leader, leaderID = pAgent, agentID
			end
		end
	end
	return leader
end

function SpaceSpawnerScreenPlay:fillSquadron(tableNum, members, cohortID)
	local spawnTable = self.shipSpawns[tableNum]
	local spawnList = spawnTable.shipSpawns
	local squadron = self.squadronsShips[spawnList[1]]
	local templates = {}
	if (#spawnList > 1) then
		table.insert(templates, spawnList[#spawnList])
	end
	for _, template in ipairs(squadron[2]) do
		table.insert(templates, template)
	end

	local pLeader = cohortID ~= nil and self:findSquadronLeader(cohortID) or nil
	local x, z, y = self:spawnLocation(spawnTable)
	local missing = false

	for slot, template in ipairs(templates) do
		-- Keep a successful slot's ID even after its ship dies: a failed-spawn
		-- retry must never resurrect an already-created (then killed) member.
		if (tonumber(members[slot] or "0") == 0) then
			local pShip = spawnShipAgent(template, self.spaceZone, x, z, y)
			if (pShip == nil) then
				members[slot] = "0"
				missing = true
				Logger:log(self.screenplayName .. " -- Squadron Ship Failed to Spawn: " .. template, LT_ERROR)
			else
				local agentID = SceneObject(pShip):getObjectID()
				members[slot] = tostring(agentID)
				local isLeader = pLeader == nil

				if (isLeader) then
					pLeader = pShip
					ShipAiAgent(pShip):createSquadron(squadron[1])
					cohortID = agentID
					local key = self:squadronKey(cohortID)
					writeData(key .. "active", 1)
					writeData(key .. "index", tableNum)
					writeData(key .. "leader", agentID)
				else
					ShipAiAgent(pShip):assignToSquadron(pLeader)
				end

				ShipAiAgent(pShip):setDespawnOnNoPlayerInRange(false)
				self:rememberSpawnerShip(pShip, tableNum, cohortID)
				createObserver(SHIPDESTROYED, self.screenplayName, "squadronShipDestroyed", pShip)
				self:configurePatrol(pShip, spawnTable, isLeader and "squadronDestinationReached" or nil)
			end
		end
	end

	if (cohortID ~= nil) then
		writeStringVectorSharedMemory(self:squadronKey(cohortID) .. "members", members)
	end
	return cohortID, pLeader, missing
end

function SpaceSpawnerScreenPlay:spawnShipSquadron(pNil, indexString)
	local tableNum, attempt = spawnAttempt(indexString)
	local cohortID, pLeader, missing = self:fillSquadron(tableNum, {}, nil)

	if (missing) then
		if (cohortID == nil) then
			self:scheduleSpawnRetry("spawnShipSquadron", tostring(tableNum), attempt, nil)
		else
			self:scheduleSpawnRetry("retrySquadronMembers", tostring(cohortID), attempt, pLeader)
		end
	end
end

function SpaceSpawnerScreenPlay:retrySquadronMembers(pAnchor, argument)
	local cohortID, attempt = spawnAttempt(argument)
	local key = self:squadronKey(cohortID)
	if (readData(key .. "active") ~= 1) then
		return
	end

	local pLeader = self:findSquadronLeader(cohortID)
	if (pLeader == nil) then
		return -- last-member destruction owns replacement and state cleanup
	end

	if (pAnchor == nil or SceneObject(pAnchor):getObjectID() ~= SceneObject(pLeader):getObjectID()) then
		-- ScreenPlayTask locks its object. Re-anchor on a surviving leader if
		-- the old anchor died; stale weak task pointers must not clone a fleet.
		createEvent(1, self.screenplayName, "retrySquadronMembers", pLeader, argument)
		return
	end

	local tableNum = readData(key .. "index")
	local members = readStringVectorSharedMemory(key .. "members")
	local _, _, missing = self:fillSquadron(tableNum, members, cohortID)
	if (missing) then
		self:scheduleSpawnRetry("retrySquadronMembers", tostring(cohortID), attempt, pLeader)
	end
end

function SpaceSpawnerScreenPlay:assignFixedPatrolpoints(pShipAgent, totalToAdd, patrolPoints)
	if (pShipAgent == nil or patrolPoints == nil or #patrolPoints == 0 or totalToAdd == nil or totalToAdd <= 0) then
		return
	end

	local count = math.min(totalToAdd, #patrolPoints)
	local startPoint = getRandomNumber(1, #patrolPoints - count + 1)
	for index = startPoint, startPoint + count - 1 do
		ShipAiAgent(pShipAgent):addFixedPatrolPoint(patrolPoints[index], false)
	end
end

function SpaceSpawnerScreenPlay:staticShipDestroyed(pShipAgent, pKillerShip)
	if (pShipAgent == nil or not SceneObject(pShipAgent):isShipAiAgent()) then
		return 1
	end
	local agentID = SceneObject(pShipAgent):getObjectID()
	local tableNum = readData(agentID .. ":SpawnerIndex:")
	local spawnTable = self.shipSpawns[tableNum]
	if (spawnTable == nil) then
		return 1 -- duplicate/queued callback after cleanup
	end

	self:forgetSpawnerShip(agentID)
	self:dropSpawnObservers(pShipAgent)
	createEvent(getRandomNumber(spawnTable.minRespawn, spawnTable.maxRespawn) * 1000, self.screenplayName, "spawnShipAgent", nil, tostring(tableNum))
	return 1
end

function SpaceSpawnerScreenPlay:squadronShipDestroyed(pShipAgent, pKillerShip, squadronSize)
	if (pShipAgent == nil or not SceneObject(pShipAgent):isShipAiAgent()) then
		return 1
	end

	local agentID = SceneObject(pShipAgent):getObjectID()
	local tableNum = readData(agentID .. ":SpawnerIndex:")
	local cohortID = readData(agentID .. ":SpawnerSquadron:")
	local key = self:squadronKey(cohortID)
	local spawnTable = self.shipSpawns[tableNum]
	if (spawnTable == nil or readData(key .. "active") ~= 1) then
		return 1
	end

	self:forgetSpawnerShip(agentID)
	self:dropSpawnObservers(pShipAgent)

	-- Engine counts identify the last member; don't maintain a racy Lua
	-- decrement shared by destruction callbacks on different ships.
	if (squadronSize > 1) then
		if (readData(key .. "leader") == agentID) then
			local pLeader = self:findSquadronLeader(cohortID)
			if (pLeader ~= nil) then
				writeData(key .. "leader", SceneObject(pLeader):getObjectID())
				if (spawnTable.patrolType == SHIP_AI_SINGLE_PATROL_ROTATION) then
					createObserver(DESTINATIONREACHED, self.screenplayName, "squadronDestinationReached", pLeader)
				end
			end
		end
		return 1
	end

	self:clearSquadronRegistrations(cohortID)
	createEvent(getRandomNumber(spawnTable.minRespawn, spawnTable.maxRespawn) * 1000, self.screenplayName, "spawnShipSquadron", nil, tostring(tableNum))
	return 1
end

function SpaceSpawnerScreenPlay:shipDestinationReached(pShipAgent)
	if (pShipAgent == nil or ShipObject(pShipAgent):isShipDestroyed()) then
		return 1
	end
	local agentID = SceneObject(pShipAgent):getObjectID()
	local tableNum = readData(agentID .. ":SpawnerIndex:")
	local spawnTable = self.shipSpawns[tableNum]
	if (spawnTable == nil) then
		return 1
	end

	self:forgetSpawnerShip(agentID)
	self:dropSpawnObservers(pShipAgent)
	self:departure(pShipAgent)
	createEvent(getRandomNumber(spawnTable.minRespawn, spawnTable.maxRespawn) * 1000, self.screenplayName, "spawnShipAgent", nil, tostring(tableNum))
	return 1
end

function SpaceSpawnerScreenPlay:squadronDestinationReached(pLeadShipAgent)
	if (pLeadShipAgent == nil or ShipObject(pLeadShipAgent):isShipDestroyed()) then
		return 1
	end

	local agentID = SceneObject(pLeadShipAgent):getObjectID()
	local cohortID = readData(agentID .. ":SpawnerSquadron:")
	local key = self:squadronKey(cohortID)
	local tableNum = readData(agentID .. ":SpawnerIndex:")
	local spawnTable = self.shipSpawns[tableNum]
	if (spawnTable == nil or readData(key .. "active") ~= 1 or readData(key .. "leader") ~= agentID) then
		return 1
	end

	-- A live leader owns this callback. Last-member destruction cannot race
	-- it while that leader remains in the engine's squadron. Invalidate all
	-- registrations and observers before moving/removing any of the ships.
	local departures = self:clearSquadronRegistrations(cohortID)

	for _, pShip in ipairs(departures) do
		self:departure(pShip)
	end
	createEvent(getRandomNumber(spawnTable.minRespawn, spawnTable.maxRespawn) * 1000, self.screenplayName, "spawnShipSquadron", nil, tostring(tableNum))
	return 1
end
