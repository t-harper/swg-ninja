-- jtp_dask — "Overseer Dask", Act III+ dark enclave giver (Jedi themepark,
-- "Knight of Shadows"). Posted in the Dark Enclave arenahall (yavin4
-- cell 3435636). Chassis: the dark_jedi dressgroup's human male
-- appearance on the house invulnerable-giver stat block (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpDaskConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpDaskConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpDaskConvoHandler",
	screens = {}
}

jtp_dask_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpDaskConvoTemplate:addScreen(jtp_dask_init)

addConversationTemplate("jtpDaskConvoTemplate", jtpDaskConvoTemplate)

jtp_dask = Creature:new {
	customName = "Overseer Dask",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 90,
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

	templates = { "object/mobile/dressed_dark_jedi_human_male_01.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpDaskConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_dask, "jtp_dask")
