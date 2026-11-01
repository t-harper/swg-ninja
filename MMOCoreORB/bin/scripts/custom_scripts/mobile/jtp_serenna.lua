-- jtp_serenna — "Serenna Vale", light emissary of the Ember Circle
-- (Jedi themepark, Act II giver — Massassi warroom, later acts' light
-- handler). Chassis: the light_jedi dressgroup's twi'lek female trainer
-- appearance on the house invulnerable-giver stat block (jtp_wanderer).
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpSerennaConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpSerennaConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpSerennaConvoHandler",
	screens = {}
}

jtp_serenna_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpSerennaConvoTemplate:addScreen(jtp_serenna_init)

addConversationTemplate("jtpSerennaConvoTemplate", jtpSerennaConvoTemplate)

jtp_serenna = Creature:new {
	customName = "Serenna Vale",
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

	templates = { "object/mobile/dressed_jedi_trainer_twilek_female_01.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpSerennaConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_serenna, "jtp_serenna")
