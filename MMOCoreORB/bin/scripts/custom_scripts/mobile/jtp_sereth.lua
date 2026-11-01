-- jtp_sereth — "Envoy Sereth", the Nightsisters' envoy (Jedi themepark,
-- Act III dark line ally). WORLD SPAWN ONLY, on the stronghold approach
-- outside the Nightsister Stronghold — the stronghold interior and its
-- themepark are never touched. Chassis: the nightsister spell weaver
-- appearance on the house invulnerable-giver stat block (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpSerethConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpSerethConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpSerethConvoHandler",
	screens = {}
}

jtp_sereth_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpSerethConvoTemplate:addScreen(jtp_sereth_init)

addConversationTemplate("jtpSerethConvoTemplate", jtpSerethConvoTemplate)

jtp_sereth = Creature:new {
	customName = "Envoy Sereth",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 107,
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

	templates = { "object/mobile/dressed_dathomir_nightsister_spellweaver.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpSerethConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_sereth, "jtp_sereth")
