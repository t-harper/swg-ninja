-- pre9_trainer_mandalorian — trainer for the Mandalorian multi-master
-- path (r23). Open to all; the 250-point Foundling novice cost is the
-- only gate (mirrors pre9_trainer_jedi). Shape cloned from the jedi
-- trainer; commando-trainer appearances read as a mercenary drill
-- instructor. The conversation template is created here because the
-- mobile tree is a BOOT-ONLY include: convo templates must never
-- re-register on reloadscreenplays (addConversationTemplate would
-- error on the duplicate).
--
-- The generic trainer conversation uses stock @skill_teacher: strings
-- (client-side, already shipped), so no new convo STF is needed.

createTrainerConversationTemplate("mandalorianTrainerConvoTemplate", "trainer_mandalorian")

pre9_trainer_mandalorian = Creature:new {
	customName = "Rana Ordo (a Mandalorian trainer)",
	mobType = MOB_NPC,
	socialGroup = "",
	faction = "",
	level = 100,
	chanceHit = 0.39,
	damageMin = 290,
	damageMax = 300,
	baseXp = 2914,
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

	templates = {
		"object/mobile/dressed_commando_trainer_human_male_01.iff",
		"object/mobile/dressed_commando_trainer_rodian_male_01.iff",
		"object/mobile/dressed_commando_trainer_trandoshan_male_01.iff"
	},
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "mandalorianTrainerConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(pre9_trainer_mandalorian, "pre9_trainer_mandalorian")
