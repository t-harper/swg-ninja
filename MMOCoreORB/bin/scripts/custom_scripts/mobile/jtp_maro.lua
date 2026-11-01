-- jtp_maro — "Keeper Maro", Act III+ light enclave giver (Jedi themepark,
-- "Knight of Embers"). Posted in the Light Enclave trainingroom (yavin4
-- cell 8525441). Chassis: the light_jedi dressgroup's old human trainer
-- appearance on the house invulnerable-giver stat block (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpMaroConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpMaroConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpMaroConvoHandler",
	screens = {}
}

jtp_maro_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpMaroConvoTemplate:addScreen(jtp_maro_init)

addConversationTemplate("jtpMaroConvoTemplate", jtpMaroConvoTemplate)

jtp_maro = Creature:new {
	customName = "Keeper Maro",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 80,
	chanceHit = 0.39,
	damageMin = 290,
	damageMax = 300,
	baseXp = 0,
	baseHAM = 8400,
	baseHAMmax = 10200,
	armor = 0,
	resists = {-1,-1,-1,-1,-1,-1,-1,-1,-1},
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	pvpBitmask = NONE,
	creatureBitmask = NONE,
	optionsBitmask = INVULNERABLE + CONVERSABLE,
	diet = HERBIVORE,

	templates = { "object/mobile/dressed_jedi_trainer_old_human_male_01.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpMaroConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_maro, "jtp_maro")
