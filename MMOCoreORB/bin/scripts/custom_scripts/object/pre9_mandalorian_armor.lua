-- pre9_mandalorian_armor.lua — make the 10 Mandalorian wearable armor
-- pieces craftable by a MASTER ARMORSMITH and learnable from the
-- character-builder frog's "Mandalorian * Schematic" loot items.
--
-- Three parts (all override stock via last-wins addTemplate):
--   A. Wearable stat overrides: adopt COMPOSITE's protection profile +10%
--      (capped at the engine's 80 unsliced cap), and add COMPOSITE's armor
--      experimental block so the pieces craft like composite. The +10% END
--      PRODUCT bump is the crafted-protection lever only: armor_effectiveness
--      experimentalMax 40 -> 44 (special stays carried by electricity=80).
--      certificationsRequired = {} to match pre9_armor_certs.lua (so a master
--      armorsmith can wear what they craft).
--   B. Draft schematics: EXACT clones of the stock composite armor piece
--      drafts (identical resources / quantities / levels / complexity /
--      experimentation) with only targetTemplate repointed at the Mandalorian
--      wearable. craftingToolTab 2 (armor), armor_assembly/experimentation.
--      Shared draft IFFs + crc + craftArmorPersonalGroupF membership ship in
--      pre9_jedi (build_tre.py); ODB seeding in custom_scripts/managers/
--      crafting/schematics.lua.
--   C. Loot-schematic wiring: each death_watch_mandalorian_*_schematic gets
--      templateType LOOTSCHEMATIC + the learn radial, requiredSkill =
--      crafting_armorsmith_master, targetDraftSchematic = the armor draft,
--      targetUseCount = 5. (boots loot schematic -> shoes draft/wearable.)
--
-- NB the jetpack loot schematic is intentionally NOT wired (it is not one of
-- the 10 wearable armor pieces).

-- =====================================================================
-- A. Wearable stat overrides — composite protection +10% (capped 80).
-- Mutate-in-place + re-register (pre9_armor_certs.lua pattern) so the
-- stock playerRaces / appearance / slots are PRESERVED; only the armor
-- stat fields change. certificationsRequired -> {} keeps them wearable by
-- a master armorsmith (consistent with pre9_armor_certs.lua).
-- =====================================================================

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_belt.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_belt.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 50
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 53
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "OQ", "SR", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_belt.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_l.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_l.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 50
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 53
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_l.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_r.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_r.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 50
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 53
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_r.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_l.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_l.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 50
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 53
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "OQ", "SR", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_l.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_r.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_r.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 50
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 53
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "OQ", "SR", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_r.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_chest_plate.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_chest_plate.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 233
		_t.actionEncumbrance = 96
		_t.mindEncumbrance = 50
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 250, 66, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 150, 39, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_chest_plate.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_gloves.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_gloves.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 59
		_t.actionEncumbrance = 58
		_t.mindEncumbrance = 62
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_gloves.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_helmet.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_helmet.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 45
		_t.actionEncumbrance = 48
		_t.mindEncumbrance = 286
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 22, 300, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 13, 180, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_helmet.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_leggings.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_leggings.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 94
		_t.actionEncumbrance = 180
		_t.mindEncumbrance = 56
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "OQ", "SR", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 75, 175, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 45, 105, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_leggings.iff")
	end
end

do
	local _t = ObjectTemplates[crcString("object/tangible/wearables/armor/mandalorian/armor_mandalorian_shoes.iff")]
	if _t == nil then
		print("pre9_mandalorian_armor: MISSING wearable object/tangible/wearables/armor/mandalorian/armor_mandalorian_shoes.iff")
	else
		_t.objectMenuComponent = "ArmorObjectMenuComponent"
		_t.certificationsRequired = {}
		_t.vulnerability = STUN + LIGHTSABER
		_t.specialResists = ELECTRICITY
		_t.rating = LIGHT
		_t.healthEncumbrance = 75
		_t.actionEncumbrance = 96
		_t.mindEncumbrance = 78
		_t.maxCondition = 40000
		_t.kinetic = 80
		_t.energy = 80
		_t.electricity = 80
		_t.stun = 33
		_t.blast = 80
		_t.heat = 80
		_t.cold = 80
		_t.acid = 80
		_t.lightSaber = 0
		_t.numberExperimentalProperties = {1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 1}
		_t.experimentalProperties = {"XX", "XX", "XX", "XX", "OQ", "SR", "OQ", "UT", "MA", "OQ", "MA", "OQ", "MA", "OQ", "XX", "XX", "OQ", "SR", "XX"}
		_t.experimentalWeights = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
		_t.experimentalGroupTitles = {"null", "null", "null", "exp_durability", "exp_quality", "exp_resistance", "exp_durability", "exp_durability", "exp_durability", "null", "null", "exp_resistance", "null"}
		_t.experimentalSubGroupTitles = {"null", "null", "sockets", "hit_points", "armor_effectiveness", "armor_integrity", "armor_health_encumbrance", "armor_action_encumbrance", "armor_mind_encumbrance", "armor_rating", "armor_special_type", "armor_special_effectiveness", "armor_special_integrity"}
		_t.experimentalMin = {0, 0, 0, 1000, 1, 30000, 25, 44, 25, 1, 0, 0, 0}
		_t.experimentalMax = {0, 0, 0, 1000, 44, 50000, 15, 26, 15, 1, 0, 0, 0}
		_t.experimentalPrecision = {0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0}
		_t.experimentalCombineType = {0, 0, 4, 1, 1, 1, 1, 1, 1, 4, 4, 4, 1}
		ObjectTemplates:addTemplate(_t, "object/tangible/wearables/armor/mandalorian/armor_mandalorian_shoes.iff")
	end
end

-- =====================================================================
-- B. Draft schematics — EXACT composite piece-draft clones
-- =====================================================================

object_draft_schematic_armor_shared_armor_mandalorian_belt = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_belt.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_belt, "object/draft_schematic/armor/shared_armor_mandalorian_belt.iff")

object_draft_schematic_armor_armor_mandalorian_belt = object_draft_schematic_armor_shared_armor_mandalorian_belt:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Belt",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_belt.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_belt, "object/draft_schematic/armor/armor_mandalorian_belt.iff")

object_draft_schematic_armor_shared_armor_mandalorian_bicep_l = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_bicep_l.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_bicep_l, "object/draft_schematic/armor/shared_armor_mandalorian_bicep_l.iff")

object_draft_schematic_armor_armor_mandalorian_bicep_l = object_draft_schematic_armor_shared_armor_mandalorian_bicep_l:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Left Bicep",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_l.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_bicep_l, "object/draft_schematic/armor/armor_mandalorian_bicep_l.iff")

object_draft_schematic_armor_shared_armor_mandalorian_bicep_r = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_bicep_r.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_bicep_r, "object/draft_schematic/armor/shared_armor_mandalorian_bicep_r.iff")

object_draft_schematic_armor_armor_mandalorian_bicep_r = object_draft_schematic_armor_shared_armor_mandalorian_bicep_r:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Right Bicep",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bicep_r.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_bicep_r, "object/draft_schematic/armor/armor_mandalorian_bicep_r.iff")

object_draft_schematic_armor_shared_armor_mandalorian_bracer_l = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_bracer_l.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_bracer_l, "object/draft_schematic/armor/shared_armor_mandalorian_bracer_l.iff")

object_draft_schematic_armor_armor_mandalorian_bracer_l = object_draft_schematic_armor_shared_armor_mandalorian_bracer_l:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Left Bracer",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_l.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_bracer_l, "object/draft_schematic/armor/armor_mandalorian_bracer_l.iff")

object_draft_schematic_armor_shared_armor_mandalorian_bracer_r = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_bracer_r.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_bracer_r, "object/draft_schematic/armor/shared_armor_mandalorian_bracer_r.iff")

object_draft_schematic_armor_armor_mandalorian_bracer_r = object_draft_schematic_armor_shared_armor_mandalorian_bracer_r:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Right Bracer",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_bracer_r.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_bracer_r, "object/draft_schematic/armor/armor_mandalorian_bracer_r.iff")

object_draft_schematic_armor_shared_armor_mandalorian_chest_plate = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_chest_plate.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_chest_plate, "object/draft_schematic/armor/shared_armor_mandalorian_chest_plate.iff")

object_draft_schematic_armor_armor_mandalorian_chest_plate = object_draft_schematic_armor_shared_armor_mandalorian_chest_plate:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Chest Plate",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 650,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {100, 100, 50, 60, 50, 40, 4, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_chest_plate.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_chest_plate, "object/draft_schematic/armor/armor_mandalorian_chest_plate.iff")

object_draft_schematic_armor_shared_armor_mandalorian_gloves = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_gloves.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_gloves, "object/draft_schematic/armor/shared_armor_mandalorian_gloves.iff")

object_draft_schematic_armor_armor_mandalorian_gloves = object_draft_schematic_armor_shared_armor_mandalorian_gloves:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Gloves",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 250,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {25, 25, 15, 10, 10, 10, 1, 2, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_gloves.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_gloves, "object/draft_schematic/armor/armor_mandalorian_gloves.iff")

object_draft_schematic_armor_shared_armor_mandalorian_helmet = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_helmet.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_helmet, "object/draft_schematic/armor/shared_armor_mandalorian_helmet.iff")

object_draft_schematic_armor_armor_mandalorian_helmet = object_draft_schematic_armor_shared_armor_mandalorian_helmet:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Helmet",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 550,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {70, 70, 35, 40, 30, 30, 3, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_helmet.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_helmet, "object/draft_schematic/armor/armor_mandalorian_helmet.iff")

object_draft_schematic_armor_shared_armor_mandalorian_leggings = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_leggings.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_leggings, "object/draft_schematic/armor/shared_armor_mandalorian_leggings.iff")

object_draft_schematic_armor_armor_mandalorian_leggings = object_draft_schematic_armor_shared_armor_mandalorian_leggings:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Pants",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 550,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {70, 70, 35, 40, 30, 30, 3, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_leggings.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_leggings, "object/draft_schematic/armor/armor_mandalorian_leggings.iff")

object_draft_schematic_armor_shared_armor_mandalorian_shoes = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_mandalorian_shoes.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_shared_armor_mandalorian_shoes, "object/draft_schematic/armor/shared_armor_mandalorian_shoes.iff")

object_draft_schematic_armor_armor_mandalorian_shoes = object_draft_schematic_armor_shared_armor_mandalorian_shoes:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Boots",
	craftingToolTab = 2,
	complexity = 45,
	size = 4,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_armor",
	xp = 420,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {2},
	customizationStringNames = {"/private/index_color_1"},
	customizationDefaults = {0},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"auxilary_coverage", "body", "liner", "hardware_and_attachments", "binding_and_reinforcement", "padding", "armor", "load_bearing_harness", "reinforcement"},
	ingredientSlotType = {0, 0, 0, 0, 0, 0, 1, 1, 1},
	resourceTypes = {"ore_intrusive", "fuel_petrochem_solid_known", "fiberplast_naboo", "aluminum", "copper_beyrllius", "hide_wooly", "object/tangible/component/armor/shared_armor_segment_composite.iff", "object/tangible/component/clothing/shared_synthetic_cloth.iff", "object/tangible/component/clothing/shared_reinforced_fiber_panels.iff"},
	resourceQuantities = {50, 50, 25, 30, 20, 20, 2, 1, 1},
	contribution = {100, 100, 100, 100, 100, 100, 100, 100, 100},
	targetTemplate = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_shoes.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_mandalorian_shoes, "object/draft_schematic/armor/armor_mandalorian_shoes.iff")

-- =====================================================================
-- C. Loot-schematic wiring — frog schematics learn the armor drafts
-- =====================================================================

object_tangible_loot_loot_schematic_death_watch_mandalorian_belt_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_belt_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_belt.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_belt_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_belt_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_bicep_l_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_bicep_l_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_bicep_l.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_bicep_l_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_bicep_l_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_bicep_r_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_bicep_r_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_bicep_r.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_bicep_r_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_bicep_r_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_boots_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_boots_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_shoes.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_boots_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_boots_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_bracer_l_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_bracer_l_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_bracer_l.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_bracer_l_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_bracer_l_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_bracer_r_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_bracer_r_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_bracer_r.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_bracer_r_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_bracer_r_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_chest_plate_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_chest_plate_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_chest_plate.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_chest_plate_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_chest_plate_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_gloves_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_gloves_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_gloves.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_gloves_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_gloves_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_helmet_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_helmet_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_helmet.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_helmet_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_helmet_schematic.iff")

object_tangible_loot_loot_schematic_death_watch_mandalorian_leggings_schematic = object_tangible_loot_loot_schematic_shared_death_watch_mandalorian_leggings_schematic:new {
	templateType = LOOTSCHEMATIC,
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/armor/armor_mandalorian_leggings.iff",
	targetUseCount = 5
}
ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_death_watch_mandalorian_leggings_schematic, "object/tangible/loot/loot_schematic/death_watch_mandalorian_leggings_schematic.iff")

print("pre9_mandalorian_armor: 10 wearables (composite+10%), 10 armor drafts, 10 loot schematics wired to crafting_armorsmith_master")
