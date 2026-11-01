-- jtp_vheress_emissary — "Adjunct Vheress", the Empire's shadow-recruitment
-- emissary (Jedi themepark, Act II giver — Massassi warroom; the rival of
-- the whole park, first glimpsed on the Kenobi trail in Act I). Chassis:
-- the dark_initiate quest NPC's appearance (dressed_feral_force_wielder,
-- per stock mobile/quest/dantooine/dark_initiate.lua) on the house
-- invulnerable-giver stat block (jtp_wanderer). No faction — she is here
-- on the Emperor's quiet business, not the Empire's public one.
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpVheressConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpVheressConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpVheressConvoHandler",
	screens = {}
}

jtp_vheress_emissary_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpVheressConvoTemplate:addScreen(jtp_vheress_emissary_init)

addConversationTemplate("jtpVheressConvoTemplate", jtpVheressConvoTemplate)

jtp_vheress_emissary = Creature:new {
	customName = "Adjunct Vheress",
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

	templates = { "object/mobile/dressed_feral_force_wielder.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpVheressConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_vheress_emissary, "jtp_vheress_emissary")
