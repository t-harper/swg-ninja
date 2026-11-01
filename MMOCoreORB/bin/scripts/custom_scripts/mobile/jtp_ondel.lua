-- jtp_ondel — "Archivist Ondel", the last librarian of the Dantooine
-- enclave's library (Jedi themepark, Act I-VI pilgrimage keeper). Chassis:
-- the stock record-keeper appearance on the jtp_wanderer invulnerable-giver
-- stat block. Posted inside the damprock cave (building 8535537) by
-- JediParkAct1:start().
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpOndelConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpOndelConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpOndelConvoHandler",
	screens = {}
}

jtp_ondel_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpOndelConvoTemplate:addScreen(jtp_ondel_init)

addConversationTemplate("jtpOndelConvoTemplate", jtpOndelConvoTemplate)

jtp_ondel = Creature:new {
	customName = "Archivist Ondel",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 12,
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

	templates = { "object/mobile/theme_park_record_keeper_imperial.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpOndelConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_ondel, "jtp_ondel")
