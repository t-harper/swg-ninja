-- pre9_species.lua — 20 new playable species (community mod port).
-- Shared templates + server templates adapted to the current
-- component schema (groundZoneComponent/spaceZoneComponent).
-- Client half ships in swgninja_species_r1.tre + pre9_jedi_r8.tre
-- (merged crc table, species_ skills, skl_n/skl_d strings).

--Added Races
--Hutt male
object_creature_player_shared_hutt_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_hutt_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_hutt_male, "object/creature/player/shared_hutt_male.iff")

--Hutt female
object_creature_player_shared_hutt_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_hutt_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_hutt_female, "object/creature/player/shared_hutt_female.iff")

--Nautolan male
object_creature_player_shared_nautolan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nautolan_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_nautolan_male, "object/creature/player/shared_nautolan_male.iff")

--Togruta female
object_creature_player_shared_togruta_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_togruta_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_togruta_female, "object/creature/player/shared_togruta_female.iff")

--Chiss female
object_creature_player_shared_chiss_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chiss_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_chiss_female, "object/creature/player/shared_chiss_female.iff")

--Chiss male
object_creature_player_shared_chiss_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chiss_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_chiss_male, "object/creature/player/shared_chiss_male.iff")

--Devaronian male
object_creature_player_shared_devaronian_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_devaronian_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_devaronian_male, "object/creature/player/shared_devaronian_male.iff")

--Gran male
object_creature_player_shared_gran_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gran_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_gran_male, "object/creature/player/shared_gran_male.iff")

--Ishi Tib male
object_creature_player_shared_ishi_tib_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_ishi_tib_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_ishi_tib_male, "object/creature/player/shared_ishi_tib_male.iff")

--Nightsister female
object_creature_player_shared_nightsister_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nightsister_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_nightsister_female, "object/creature/player/shared_nightsister_female.iff")

--Nikto male
object_creature_player_shared_nikto_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nikto_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_nikto_male, "object/creature/player/shared_nikto_male.iff")

--Quarren male
object_creature_player_shared_quarren_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_quarren_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_quarren_male, "object/creature/player/shared_quarren_male.iff")

--SMC female
object_creature_player_shared_smc_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_smc_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_smc_female, "object/creature/player/shared_smc_female.iff")

--Weequay male
object_creature_player_shared_weequay_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_weequay_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_weequay_male, "object/creature/player/shared_weequay_male.iff")

--Aqualish female
object_creature_player_shared_aqualish_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_aqualish_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_aqualish_female, "object/creature/player/shared_aqualish_female.iff")

--Aqualish male
object_creature_player_shared_aqualish_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_aqualish_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_aqualish_male, "object/creature/player/shared_aqualish_male.iff")

--Bith female
object_creature_player_shared_bith_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_bith_female.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_bith_female, "object/creature/player/shared_bith_female.iff")

--Bith male
object_creature_player_shared_bith_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_bith_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_bith_male, "object/creature/player/shared_bith_male.iff")

--Gotal male
object_creature_player_shared_gotal_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gotal_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_gotal_male, "object/creature/player/shared_gotal_male.iff")

--Talz male
object_creature_player_shared_talz_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_talz_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_talz_male, "object/creature/player/shared_talz_male.iff")


object_creature_player_aqualish_female = object_creature_player_shared_aqualish_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_aqualish", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_aqualish_female, "object/creature/player/aqualish_female.iff")

object_creature_player_aqualish_male = object_creature_player_shared_aqualish_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_aqualish", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_aqualish_male, "object/creature/player/aqualish_male.iff")

object_creature_player_bith_female = object_creature_player_shared_bith_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_bith", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_bith_female, "object/creature/player/bith_female.iff")

object_creature_player_bith_male = object_creature_player_shared_bith_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_bith", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_bith_male, "object/creature/player/bith_male.iff")

object_creature_player_chiss_female = object_creature_player_shared_chiss_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_chiss", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_chiss_female, "object/creature/player/chiss_female.iff")

object_creature_player_chiss_male = object_creature_player_shared_chiss_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_chiss", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_chiss_male, "object/creature/player/chiss_male.iff")

object_creature_player_devaronian_male = object_creature_player_shared_devaronian_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_devaronian", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_devaronian_male, "object/creature/player/devaronian_male.iff")

object_creature_player_gotal_male = object_creature_player_shared_gotal_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_gotal", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_gotal_male, "object/creature/player/gotal_male.iff")

object_creature_player_gran_male = object_creature_player_shared_gran_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_gran", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_gran_male, "object/creature/player/gran_male.iff")

object_creature_player_hutt_female = object_creature_player_shared_hutt_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_hutt", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_hutt_female, "object/creature/player/hutt_female.iff")

object_creature_player_hutt_male = object_creature_player_shared_hutt_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_hutt", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_hutt_male, "object/creature/player/hutt_male.iff")

object_creature_player_ishi_tib_male = object_creature_player_shared_ishi_tib_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_ishi_tib", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_ishi_tib_male, "object/creature/player/ishi_tib_male.iff")

object_creature_player_nautolan_male = object_creature_player_shared_nautolan_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_nautolan", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_nautolan_male, "object/creature/player/nautolan_male.iff")

object_creature_player_nightsister_female = object_creature_player_shared_nightsister_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_nightsister", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_nightsister_female, "object/creature/player/nightsister_female.iff")

object_creature_player_nikto_male = object_creature_player_shared_nikto_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_nikto", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_nikto_male, "object/creature/player/nikto_male.iff")

object_creature_player_quarren_male = object_creature_player_shared_quarren_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_quarren", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_quarren_male, "object/creature/player/quarren_male.iff")

object_creature_player_smc_female = object_creature_player_shared_smc_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_smc", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_smc_female, "object/creature/player/smc_female.iff")

object_creature_player_talz_male = object_creature_player_shared_talz_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_talz", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_talz_male, "object/creature/player/talz_male.iff")

object_creature_player_togruta_female = object_creature_player_shared_togruta_female:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_togruta", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_togruta_female, "object/creature/player/togruta_female.iff")

object_creature_player_weequay_male = object_creature_player_shared_weequay_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
		
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_weequay", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_weequay_male, "object/creature/player/weequay_male.iff")

--Gungan male (pre9 addition 2026-07-07 — client half ships in
--swgninja_species_r2.tre + pre9_jedi_r22.tre; rides the stock NPC
--appearance/gungan_m.sat, whose gungan.skt is bone-compatible with
--all_b so stock clothing/armor renders; species int 0 in the shared
--iff so the client wearable gate treats it as human, and
--getCustomSpeciesBaseRace maps it to human_male server-side)
object_creature_player_shared_gungan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gungan_male.iff"}
ObjectTemplates:addClientTemplate(object_creature_player_shared_gungan_male, "object/creature/player/shared_gungan_male.iff")

object_creature_player_gungan_male = object_creature_player_shared_gungan_male:new {
	baseHAM = { 100, 100, 100, 100, 100, 100, 100, 100, 100 },
	gameObjectType = 1033,
	groundZoneComponent = "PlayerZoneComponent",
	spaceZoneComponent = "PlayerSpaceZoneComponent",
	objectMenuComponent = "PlayerObjectMenuComponent",
	containerComponent = "PlayerContainerComponent",
	pvpStatusBitmask = PLAYER,
	templateType = PLAYERCREATURE,
	childObjects = {
		{templateFile = "object/tangible/inventory/character_inventory.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/datapad/character_datapad.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/player/player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/bank/character_bank.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/tangible/mission_bag/mission_bag.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4},
		{templateFile = "object/weapon/melee/unarmed/unarmed_default_player.iff", x = 0, z = 0, y = 0, ox = 0, oy = 0, oz = 0, ow = 0, cellid = -1, containmentType = 4}
	},
	defaultLanguage = 1,
	startingItems = { },
	startingSkills = { "species_gungan", "social_language_basic_comprehend", "social_language_basic_speak" }
}

ObjectTemplates:addTemplate(object_creature_player_gungan_male, "object/creature/player/gungan_male.iff")
