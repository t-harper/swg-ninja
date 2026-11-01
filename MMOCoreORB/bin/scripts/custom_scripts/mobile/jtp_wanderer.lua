-- jtp_wanderer — "The Wanderer", mentor-courier of the Ember Circle
-- (Jedi themepark, Act 0-II giver). Chassis: the village old man's
-- hooded-elder appearance on the house invulnerable-giver stat block.
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpWandererConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpWandererConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpWandererConvoHandler",
	screens = {}
}

jtp_wanderer_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpWandererConvoTemplate:addScreen(jtp_wanderer_init)

addConversationTemplate("jtpWandererConvoTemplate", jtpWandererConvoTemplate)

jtp_wanderer = Creature:new {
	customName = "The Wanderer",
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

	templates = { "object/mobile/dressed_fs_village_oldman.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpWandererConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_wanderer, "jtp_wanderer")
