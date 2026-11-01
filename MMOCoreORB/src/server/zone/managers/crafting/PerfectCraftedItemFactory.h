#ifndef PERFECTCRAFTEDITEMFACTORY_H_
#define PERFECTCRAFTEDITEMFACTORY_H_
#include "PerfectCraftingRecipe.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"


class PerfectCraftedItemFactory {
public:
	static bool grant(CreatureObject* recipient, const String& catalogId, String& error);
	static bool grant(CreatureObject* recipient, const String& catalogId, String& error, uint64 expectedGeneration);
	static void applyVisibleComponents(TangibleObject* prototype, ManufactureSchematic* schematic);
	static void applySkillMods(TangibleObject* prototype, DraftSchematic* draft);
	static void applyWeaponDots(TangibleObject* prototype, DraftSchematic* draft);
	static bool isAvailable(const String& catalogId);
#ifdef COMPILE_CORE3_TESTS
	static String gameplaySignatureForTesting(SceneObject* object);
#endif
	static uint64 getCatalogGeneration();
	// Runs on an engine Task worker after managers/templates have initialized.
	static void startAudit(ZoneServer* server);
	static bool audit(ZoneServer* server, const String& catalogPath, String& report);
	static bool auditEntry(ZoneServer* server, const String& catalogId, String& report);
	static TangibleObject* createForAudit(const String& catalogId, PerfectCraftingContext& context, String& error);
	static void applyAssemblyHooks(TangibleObject* prototype, DraftSchematic* draft,
		ManufactureSchematic* schematic);
};
#endif
