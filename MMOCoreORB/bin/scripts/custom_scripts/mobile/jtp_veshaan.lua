-- jtp_veshaan — "Sister Veshaan", the Singing Mountain Clan's witch ally
-- (Jedi themepark, Act III light line; the dark line's Act VI boss uses a
-- separate combat template later). Posted in the SMC stronghold
-- meditation cell (dathomir cell 2665883, shared with the stock Zideera
-- mission giver — our copy is a pure talk-target). Chassis: the Drakka
-- Judarrl quest appearance on the house invulnerable-giver stat block
-- (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpVeshaanConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpVeshaanConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpVeshaanConvoHandler",
	screens = {}
}

jtp_veshaan_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpVeshaanConvoTemplate:addScreen(jtp_veshaan_init)

addConversationTemplate("jtpVeshaanConvoTemplate", jtpVeshaanConvoTemplate)

jtp_veshaan = Creature:new {
	customName = "Sister Veshaan",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 100,
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

	templates = { "object/mobile/dressed_drakka_judarrl.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpVeshaanConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_veshaan, "jtp_veshaan")
