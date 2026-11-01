#ifndef PERFECTCRAFTINGSPECIALADAPTER_H_
#define PERFECTCRAFTINGSPECIALADAPTER_H_
#include "PerfectCraftingRecipe.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"

// Task4 owns this class's .cpp and its specialized implementation files.
// initialize handles kind loot/fixed/crystal/dna on a NEW transient prototype.
// fingerprint binds loaded source bounds and selected deterministic outcomes.
class PerfectCraftingSpecialAdapter {
public:
	static bool initialize(const PerfectCraftingRecipe& recipe, TangibleObject* prototype,
		PerfectCraftingContext& context, String& fingerprint, String& error);
	// Called for GENETIC_LAB after the five real ingredient slots are populated.
	// Owns normal DNA-dependent lab initialization and deterministic finalization;
	// preserve hidden resist values and use actual genetic caps, not global1.0.
	static bool finalizeGenetic(const PerfectCraftingRecipe& recipe, TangibleObject* prototype,
		ManufactureSchematic* schematic, PerfectCraftingContext& context,
		String& fingerprint, String& error);
};
#endif
