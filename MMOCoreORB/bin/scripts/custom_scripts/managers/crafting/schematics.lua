-- pre9 local: DraftSchematic object seeding for custom schematics.
-- SchematicMap creates a persistent DraftSchematic (draftschematics ODB)
-- for any entry here not already in the database — a schematic_group.iff
-- row alone does NOT create the object (boot log: "Loaded N schematics
-- from scripts/custom_scripts/managers/crafting/schematics.lua").
schematics = {
	{path="object/draft_schematic/structure/city/starport_corellia.iff"},
	{path="object/draft_schematic/structure/city/starport_naboo.iff"},
	{path="object/draft_schematic/structure/city/starport_tatooine.iff"},
}
