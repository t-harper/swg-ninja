-- jtp_sarov — "Master Sarov, the Fallen", the light line's Act V
-- redemption boss (Jedi themepark — Dantooine Jedi Temple ruins arena).
-- Chassis: dolac_dark_jedi_master's appearance and full heavy stat block
-- (mobile/quest/dathomir/dolac_dark_jedi_master.lua — the plan's named
-- donor: dark_jedi dressgroup, CL291, HAM 321k, armor 3, resists 90) on a
-- CONVERSABLE, non-attackable base.
--
-- INVULNERABILITY RAIL (deliberate deviation from a literal
-- options-INVULNERABLE bit): the base pvpBitmask is NONE — the package's
-- proven untargetable idiom (JtpTheaters invuln flag / stock
-- encounter.lua setNotAttackable both work by pvp bitmask 0). The
-- options-bitmask INVULNERABLE flag is deliberately ABSENT because it is
-- for never-fightable anchors (darth_vader_city_control) and would
-- survive the Q5.6L redemption-fight flip; Act V flips Sarov live with
-- setPvpStatusBitmask(AGGRESSIVE + ATTACKABLE + ENEMY) +
-- removeObjectFlag(AI_NOAIAGGRO) — the act3 Q3.7 arena idiom, which
-- requires the template to stay clear of options-INVULNERABLE. AIENABLED
-- stays on so the flipped fight has a working brain. creatureBitmask is
-- NONE (no KILLER/STALKER: he must never aggro a pilgrim mid-parley; the
-- flip presses him via setDefender).
--
-- Spawned ONLY per-player by JediParkAct5 through JtpTheaters:build
-- (which re-asserts pvp 0 + AI_NOAIAGGRO at spawn); never a world
-- fixture.
--
-- The conversation template is created HERE because the mobile tree is a
-- BOOT-ONLY include: convo templates must never re-register on
-- reloadscreenplays (addConversationTemplate errors on the duplicate —
-- see jtp_wanderer.lua for the rule). The handler (jtpSarovConvoHandler)
-- lives with the screenplays and hot-reloads freely.

jtpSarovConvoTemplate = ConvoTemplate:new {
	initialScreen = "init",
	templateType = "Lua",
	luaClassHandler = "jtpSarovConvoHandler",
	screens = {}
}

jtp_sarov_init = ConvoScreen:new {
	id = "init",
	leftDialog = "",
	stopConversation = "true",
	options = {}
}

jtpSarovConvoTemplate:addScreen(jtp_sarov_init)

addConversationTemplate("jtpSarovConvoTemplate", jtpSarovConvoTemplate)

jtp_sarov = Creature:new {
	customName = "Master Sarov, the Fallen",
	mobType = MOB_NPC,
	socialGroup = "dark_jedi",
	faction = "",
	level = 291,
	chanceHit = 27.25,
	damageMin = 1800,
	damageMax = 3310,
	baseXp = 27849,
	baseHAM = 321000,
	baseHAMmax = 392000,
	armor = 3,
	resists = {90,90,90,90,90,90,90,90,-1},
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
	optionsBitmask = AIENABLED + CONVERSABLE,
	diet = HERBIVORE,

	templates = { "dark_jedi" },
	lootGroups = {
		{
			groups = {
				{group = "holocron_light", chance = 2000000},
				{group = "power_crystals", chance = 3000000},
				{group = "melee_weapons", chance = 2000000},
				{group = "dark_jedi_common", chance = 3000000}
			}
		}
	},

	primaryWeapon = "dark_jedi_weapons_gen4",
	secondaryWeapon = "dark_jedi_weapons_ranged",
	conversationTemplate = "jtpSarovConvoTemplate",

	primaryAttacks = lightsabermaster,
	secondaryAttacks = forcepowermaster
}

CreatureTemplates:addCreatureTemplate(jtp_sarov, "jtp_sarov")
