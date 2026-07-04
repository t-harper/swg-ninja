-- pre9_stardust_schematics.lua — round-1 stardust craftables: 13
-- clothing drafts (jedi robes + nightsister line), mandalorian armor
-- segment, cortosis grenade. Shared draft/item templates resolve from
-- the ninja/assets tres via the r9 crc table (no addClientTemplate
-- needed — starports precedent). Groups granted via schematic_group
-- rows in pre9_jedi_r9; ODB seeding via custom_scripts crafting
-- schematics.lua.

object_draft_schematic_clothing_clothing_robe_jedi_light_s01_crafted_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_robe_jedi_light_s01_crafted.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_robe_jedi_light_s01_crafted_shared, "object/draft_schematic/clothing/shared_clothing_robe_jedi_light_s01_crafted.iff")

object_draft_schematic_clothing_clothing_robe_jedi_light_s01_crafted = object_draft_schematic_clothing_clothing_robe_jedi_light_s01_crafted_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Jedi Cloak (Light)",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/robe/robe_jedi_light_s01.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_robe_jedi_light_s01_crafted, "object/draft_schematic/clothing/clothing_robe_jedi_light_s01_crafted.iff")

object_draft_schematic_clothing_clothing_robe_jedi_dark_s01_crafted_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_robe_jedi_dark_s01_crafted.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_robe_jedi_dark_s01_crafted_shared, "object/draft_schematic/clothing/shared_clothing_robe_jedi_dark_s01_crafted.iff")

object_draft_schematic_clothing_clothing_robe_jedi_dark_s01_crafted = object_draft_schematic_clothing_clothing_robe_jedi_dark_s01_crafted_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Jedi Cloak (Dark)",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/robe/robe_jedi_dark_s01.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_robe_jedi_dark_s01_crafted, "object/draft_schematic/clothing/clothing_robe_jedi_dark_s01_crafted.iff")

object_draft_schematic_clothing_clothing_robe_jedi_padawan_crafted_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_robe_jedi_padawan_crafted.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_robe_jedi_padawan_crafted_shared, "object/draft_schematic/clothing/shared_clothing_robe_jedi_padawan_crafted.iff")

object_draft_schematic_clothing_clothing_robe_jedi_padawan_crafted = object_draft_schematic_clothing_clothing_robe_jedi_padawan_crafted_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Padawan Robe",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/robe/robe_jedi_padawan.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_robe_jedi_padawan_crafted, "object/draft_schematic/clothing/clothing_robe_jedi_padawan_crafted.iff")

object_draft_schematic_clothing_clothing_boots_nightsister_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_boots_nightsister.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_boots_nightsister_shared, "object/draft_schematic/clothing/shared_clothing_boots_nightsister.iff")

object_draft_schematic_clothing_clothing_boots_nightsister = object_draft_schematic_clothing_clothing_boots_nightsister_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Boots",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/boots/nightsister_boots.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_boots_nightsister, "object/draft_schematic/clothing/clothing_boots_nightsister.iff")

object_draft_schematic_clothing_clothing_dress_nightsister_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_dress_nightsister.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_dress_nightsister_shared, "object/draft_schematic/clothing/shared_clothing_dress_nightsister.iff")

object_draft_schematic_clothing_clothing_dress_nightsister = object_draft_schematic_clothing_clothing_dress_nightsister_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Dress",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/dress/nightsister_dress.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_dress_nightsister, "object/draft_schematic/clothing/clothing_dress_nightsister.iff")

object_draft_schematic_clothing_clothing_pants_nightsister_s01_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_pants_nightsister_s01.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_pants_nightsister_s01_shared, "object/draft_schematic/clothing/shared_clothing_pants_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_pants_nightsister_s01 = object_draft_schematic_clothing_clothing_pants_nightsister_s01_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Pants",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/pants/nightsister_pants_s01.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_pants_nightsister_s01, "object/draft_schematic/clothing/clothing_pants_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_pants_nightsister_s02_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_pants_nightsister_s02.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_pants_nightsister_s02_shared, "object/draft_schematic/clothing/shared_clothing_pants_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_pants_nightsister_s02 = object_draft_schematic_clothing_clothing_pants_nightsister_s02_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Leggings",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/pants/nightsister_pants_s02.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_pants_nightsister_s02, "object/draft_schematic/clothing/clothing_pants_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s01_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s01.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s01_shared, "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s01 = object_draft_schematic_clothing_clothing_shirt_nightsister_s01_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Blouse",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/shirt/nightsister_shirt_s01.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s01, "object/draft_schematic/clothing/clothing_shirt_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s02_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s02.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s02_shared, "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s02 = object_draft_schematic_clothing_clothing_shirt_nightsister_s02_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Top",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/shirt/nightsister_shirt_s02.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s02, "object/draft_schematic/clothing/clothing_shirt_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s03_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s03.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s03_shared, "object/draft_schematic/clothing/shared_clothing_shirt_nightsister_s03.iff")

object_draft_schematic_clothing_clothing_shirt_nightsister_s03 = object_draft_schematic_clothing_clothing_shirt_nightsister_s03_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Wrap",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/shirt/nightsister_shirt_s03.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_shirt_nightsister_s03, "object/draft_schematic/clothing/clothing_shirt_nightsister_s03.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s01_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s01.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s01_shared, "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s01 = object_draft_schematic_clothing_clothing_hat_nightsister_s01_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Headdress",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/hat/nightsister_hat_s01.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s01, "object/draft_schematic/clothing/clothing_hat_nightsister_s01.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s02_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s02.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s02_shared, "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s02 = object_draft_schematic_clothing_clothing_hat_nightsister_s02_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Cowl",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/hat/nightsister_hat_s02.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s02, "object/draft_schematic/clothing/clothing_hat_nightsister_s02.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s03_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s03.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s03_shared, "object/draft_schematic/clothing/shared_clothing_hat_nightsister_s03.iff")

object_draft_schematic_clothing_clothing_hat_nightsister_s03 = object_draft_schematic_clothing_clothing_hat_nightsister_s03_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Nightsister Veil",
	craftingToolTab = 8,
	complexity = 22,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_clothing.iff",
	xpType = "crafting_clothing_general",
	xp = 380,
	assemblySkill = "clothing_assembly",
	experimentingSkill = "clothing_experimentation",
	customizationSkill = "clothing_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_clothing_ingredients_n", "craft_clothing_ingredients_n"},
	ingredientTitleNames = {"fabric", "lining"},
	ingredientSlotType = {0, 0},
	resourceTypes = {"fiberplast", "hide"},
	resourceQuantities = {35, 20},
	contribution = {100, 100},
	targetTemplate = "object/tangible/wearables/hat/nightsister_hat_s03.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_clothing_clothing_hat_nightsister_s03, "object/draft_schematic/clothing/clothing_hat_nightsister_s03.iff")

-- Mandalorian armor segment: item inherits every stat from the stock
-- segment, swaps in the pack's shared template.
object_tangible_component_armor_armor_segment_mandalorian = object_tangible_component_armor_armor_segment:new {
	clientTemplateFileName = "object/tangible/component/armor/shared_armor_segment_mandalorian.iff",
	customObjectName = "Mandalorian Armor Segment",
}
ObjectTemplates:addTemplate(object_tangible_component_armor_armor_segment_mandalorian, "object/tangible/component/armor/armor_segment_mandalorian.iff")

object_draft_schematic_armor_armor_segment_mandalorian_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/armor/shared_armor_segment_mandalorian.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_armor_armor_segment_mandalorian_shared, "object/draft_schematic/armor/shared_armor_segment_mandalorian.iff")

object_draft_schematic_armor_armor_segment_mandalorian = object_draft_schematic_armor_armor_segment_mandalorian_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Mandalorian Armor Segment",
	craftingToolTab = 2,
	complexity = 25,
	size = 2,
	factoryCrateType = "object/factory/factory_crate_armor.iff",
	xpType = "crafting_clothing_armor",
	xp = 550,
	assemblySkill = "armor_assembly",
	experimentingSkill = "armor_experimentation",
	customizationSkill = "armor_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_armor_ingredients_n", "craft_armor_ingredients_n", "craft_armor_ingredients_n"},
	ingredientTitleNames = {"segment_frame", "plating", "binding"},
	ingredientSlotType = {0, 0, 0},
	resourceTypes = {"petrochem_inert", "aluminum", "metal_nonferrous"},
	resourceQuantities = {40, 35, 25},
	contribution = {100, 100, 100},
	targetTemplate = "object/tangible/component/armor/armor_segment_mandalorian.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_armor_armor_segment_mandalorian, "object/draft_schematic/armor/armor_segment_mandalorian.iff")

-- Cortosis grenade: inherits the fragmentation grenade combat shape,
-- energy damage + medium AP as the anti-armor/anti-saber flavor.
object_weapon_ranged_grenade_grenade_cortosis = object_weapon_ranged_grenade_grenade_fragmentation:new {
	clientTemplateFileName = "object/weapon/ranged/grenade/shared_grenade_cortosis.iff",
	customObjectName = "Cortosis Grenade",
	damageType = ENERGY,
	armorPiercing = MEDIUM,
	minDamage = 350,
	maxDamage = 620,
}
ObjectTemplates:addTemplate(object_weapon_ranged_grenade_grenade_cortosis, "object/weapon/ranged/grenade/grenade_cortosis.iff")

object_draft_schematic_munition_grenade_cortosis_shared = SharedDraftSchematicObjectTemplate:new {
	clientTemplateFileName = "object/draft_schematic/munition/shared_grenade_cortosis.iff"
}
ObjectTemplates:addClientTemplate(object_draft_schematic_munition_grenade_cortosis_shared, "object/draft_schematic/munition/shared_grenade_cortosis.iff")

object_draft_schematic_munition_grenade_cortosis = object_draft_schematic_munition_grenade_cortosis_shared:new {
	templateType = DRAFTSCHEMATIC,
	customObjectName = "Cortosis Grenade",
	craftingToolTab = 1,
	complexity = 24,
	size = 1,
	factoryCrateType = "object/factory/factory_crate_weapon.iff",
	xpType = "crafting_weapons_general",
	xp = 420,
	assemblySkill = "weapon_assembly",
	experimentingSkill = "weapon_experimentation",
	customizationSkill = "weapon_customization",
	customizationOptions = {},
	customizationStringNames = {},
	customizationDefaults = {},
	ingredientTemplateNames = {"craft_weapon_ingredients_n", "craft_weapon_ingredients_n", "craft_weapon_ingredients_n"},
	ingredientTitleNames = {"casing", "charge", "cortosis_lacing"},
	ingredientSlotType = {0, 0, 0},
	resourceTypes = {"steel", "metal", "copper"},
	resourceQuantities = {30, 25, 15},
	contribution = {100, 100, 100},
	targetTemplate = "object/weapon/ranged/grenade/grenade_cortosis.iff",
	additionalTemplates = {}
}
ObjectTemplates:addTemplate(object_draft_schematic_munition_grenade_cortosis, "object/draft_schematic/munition/grenade_cortosis.iff")