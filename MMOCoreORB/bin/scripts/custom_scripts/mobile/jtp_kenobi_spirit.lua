-- jtp_kenobi_spirit — the apparition of the dead hermit (Jedi themepark,
-- Act I flagship scene, cell 3565386 ONLY). Chassis: the hero-of-Tatooine
-- hermit's appearance (dressed_hermit_of_tatooine) at level 100,
-- INVULNERABLE + CONVERSABLE — a presence, not an encounter. Spawned and
-- despawned per-player by JediParkAct1:stageApparition; never a world
-- fixture.
--
-- The conversation template is created HERE (boot-only mobile tree; see
-- jtp_wanderer.lua for the rule). The handler (jtpKenobiConvoHandler)
-- lives with the screenplays and hot-reloads freely.

jtpKenobiConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpKenobiConvoHandler",
	screens = {}
}

jtp_kenobi_spirit_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpKenobiConvoTemplate:addScreen(jtp_kenobi_spirit_init)

addConversationTemplate("jtpKenobiConvoTemplate", jtpKenobiConvoTemplate)

jtp_kenobi_spirit = Creature:new {
	customName = "Spirit of Ben Kenobi",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 100,
	chanceHit = 1,
	damageMin = 645,
	damageMax = 1000,
	baseXp = 0,
	baseHAM = 24000,
	baseHAMmax = 30000,
	armor = 0,
	resists = {0,0,0,0,0,0,0,0,-1},
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

	templates = { "object/mobile/dressed_hermit_of_tatooine.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpKenobiConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_kenobi_spirit, "jtp_kenobi_spirit")
