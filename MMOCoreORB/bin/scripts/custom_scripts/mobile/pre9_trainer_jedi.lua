-- pre9_trainer_jedi — the pre-publish-9 Jedi trainer (open-to-all unlock:
-- teaches the legacy jedi_padawan tree; the 250-point novice cost is the
-- only gate). Shape cloned from scripts/mobile/trainer/trainer_1hsword.lua;
-- conversation reuses the stock jediTrainerConvoTemplate (type
-- trainer_jedi -> @jedi_trainer: strings; no stock NPC uses it).

pre9_trainer_jedi = Creature:new {
	customName = "Vokara (a Jedi trainer)",
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
		"object/mobile/dressed_fs_trainer.iff"
	},
	lootGroups = {},

	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	conversationTemplate = "jediTrainerConvoTemplate",

	primaryAttacks = {},
	secondaryAttacks = { }
}

CreatureTemplates:addCreatureTemplate(pre9_trainer_jedi, "pre9_trainer_jedi")
