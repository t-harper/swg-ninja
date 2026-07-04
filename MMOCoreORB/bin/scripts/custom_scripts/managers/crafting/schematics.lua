-- pre9 local: DraftSchematic object seeding for custom schematics.
-- SchematicMap creates a persistent DraftSchematic (draftschematics ODB)
-- for any entry here not already in the database — a schematic_group.iff
-- row alone does NOT create the object (boot log: "Loaded N schematics
-- from scripts/custom_scripts/managers/crafting/schematics.lua").
schematics = {
	{path="object/draft_schematic/structure/city/starport_corellia.iff"},
	{path="object/draft_schematic/structure/city/starport_naboo.iff"},
	{path="object/draft_schematic/structure/city/starport_tatooine.iff"},
	{path="object/draft_schematic/clothing/clothing_robe_jedi_light_s01_crafted.iff"},
	{path="object/draft_schematic/clothing/clothing_robe_jedi_dark_s01_crafted.iff"},
	{path="object/draft_schematic/clothing/clothing_robe_jedi_padawan_crafted.iff"},
	{path="object/draft_schematic/clothing/clothing_boots_nightsister.iff"},
	{path="object/draft_schematic/clothing/clothing_dress_nightsister.iff"},
	{path="object/draft_schematic/clothing/clothing_pants_nightsister_s01.iff"},
	{path="object/draft_schematic/clothing/clothing_pants_nightsister_s02.iff"},
	{path="object/draft_schematic/clothing/clothing_shirt_nightsister_s01.iff"},
	{path="object/draft_schematic/clothing/clothing_shirt_nightsister_s02.iff"},
	{path="object/draft_schematic/clothing/clothing_shirt_nightsister_s03.iff"},
	{path="object/draft_schematic/clothing/clothing_hat_nightsister_s01.iff"},
	{path="object/draft_schematic/clothing/clothing_hat_nightsister_s02.iff"},
	{path="object/draft_schematic/clothing/clothing_hat_nightsister_s03.iff"},
	{path="object/draft_schematic/armor/armor_segment_mandalorian.iff"},
	{path="object/draft_schematic/munition/grenade_cortosis.iff"},
}
