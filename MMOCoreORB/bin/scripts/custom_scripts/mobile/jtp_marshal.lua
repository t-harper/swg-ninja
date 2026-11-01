-- jtp_marshal — "Marshal Kessa", the Aurilia palisade marshal (Jedi
-- themepark, Act II Q2.5 wave-defense giver). Our OWN NPC — no stock
-- village NPC is reused or touched. Chassis: the fs_village captain's
-- appearance (dressed_fs_village_captain, per stock captain_sarguillo)
-- on the house invulnerable-giver stat block (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpMarshalConvoHandler) lives in acts/jtp_act2.lua and
-- hot-reloads freely.

jtpMarshalConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpMarshalConvoHandler",
	screens = {}
}

jtp_marshal_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpMarshalConvoTemplate:addScreen(jtp_marshal_init)

addConversationTemplate("jtpMarshalConvoTemplate", jtpMarshalConvoTemplate)

jtp_marshal = Creature:new {
	customName = "Marshal Kessa",
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

	templates = { "object/mobile/dressed_fs_village_captain.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpMarshalConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_marshal, "jtp_marshal")
