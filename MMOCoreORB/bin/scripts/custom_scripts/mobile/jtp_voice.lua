-- jtp_voice — "The Hand's Voice", the Emperor's proxy who runs the dark
-- side of the Silent War (Jedi themepark, Act IV dark giver — dark
-- enclave council1, cell 3435650). Chassis: the stock Emperor's Hand
-- dressed appearance (mobile/faction/imperial/emperors_hand.lua) on the
-- house invulnerable-giver stat block (jtp_wanderer). Level 252 is
-- COSMETIC — the examine tier players expect of a Hand; the NPC is
-- INVULNERABLE and never fights.
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate).
-- The handler (jtpVoiceConvoHandler) lives with the screenplays and
-- hot-reloads freely.

jtpVoiceConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpVoiceConvoHandler",
	screens = {}
}

jtp_voice_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpVoiceConvoTemplate:addScreen(jtp_voice_init)

addConversationTemplate("jtpVoiceConvoTemplate", jtpVoiceConvoTemplate)

jtp_voice = Creature:new {
	customName = "The Hand's Voice",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 252,
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

	templates = { "object/mobile/dressed_emperors_hand_human_male_01.iff" },
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jtpVoiceConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(jtp_voice, "jtp_voice")
