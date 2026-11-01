#include "gtest/gtest.h"
#include "server/zone/objects/manufactureschematic/craftingvalues/CraftingValues.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ResourceSlot.h"
#include "server/zone/managers/crafting/PerfectCraftedItemFactory.h"

TEST(PerfectCraftingValues, MaximumMeansBestEndpointIncludingReversedRanges) {
	CraftingValues values;
	values.addExperimentalAttribute("damage", "quality", 10, 100, 0, false, 0);
	values.addExperimentalAttribute("speed", "quality", 5, 1, 2, false, 0);
	values.addExperimentalAttribute("fixed", "", 20, 20, 0, true, 0);
	values.setCurrentPercentage("damage", 1, 1);
	values.setCurrentPercentage("speed", 1, 1);
	values.recalculateValues(true);
	EXPECT_FLOAT_EQ(100, values.getCurrentValue("damage"));
	EXPECT_FLOAT_EQ(1, values.getCurrentValue("speed"));
	EXPECT_FLOAT_EQ(20, values.getCurrentValue("fixed"));
}
TEST(PerfectCraftingValues, GeneticFinalizationPreservesDerivedHiddenResistance) {
	CraftingValues values;
	values.addExperimentalAttribute("power", "quality", 1, 1000, 0, false, 0);
	values.addExperimentalAttribute("resist", "resists", -99, 60, 0, true, 0);
	values.setCurrentPercentage("power", .75f, .75f);
	values.setCurrentValue("resist", 47);
	values.recalculateValues(false);
	EXPECT_FLOAT_EQ(750.25f, values.getCurrentValue("power"));
	EXPECT_FLOAT_EQ(47, values.getCurrentValue("resist"));
}
TEST(PerfectCraftingValues, GeneratedResourceInputsAreExplicitAndDoNotAlterOrdinarySlots) {
	ResourceSlot ordinary, generated;
	ordinary.setQuantityNeeded(30);
	generated.setQuantityNeeded(30);
	EXPECT_FALSE(ordinary.isFull());
	EXPECT_FALSE(ordinary.hasGeneratedQuality());
	generated.setGeneratedQuality();
	EXPECT_TRUE(generated.isFull());
	EXPECT_TRUE(generated.hasGeneratedQuality());
	EXPECT_FALSE(ordinary.hasGeneratedQuality());
	EXPECT_EQ(nullptr, generated.getCurrentSpawn());
}
TEST(PerfectCraftingValues, UnknownCatalogIdsNeverBecomeAvailable) {
	EXPECT_FALSE(PerfectCraftedItemFactory::isAvailable("r_not_in_the_catalog"));
}

#include "conf/ConfigManager.h"
#include "templates/manager/DataArchiveStore.h"
#include "templates/manager/TemplateManager.h"
#include "server/zone/managers/crafting/labratories/ResourceLabratory.h"
#include "server/zone/objects/tangible/component/Component.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"

TEST(PerfectCraftingPipeline, LoadedBarrelDraftReachesRealResourceEndpoints) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	auto draftTemplate = templates->getTemplate(String("object/draft_schematic/weapon/component/blaster_pistol_barrel.iff").hashCode());
	ASSERT_NE(nullptr, draftTemplate);
	ManagedReference<DraftSchematic*> draft = new DraftSchematic();
	draft->loadTemplateData(draftTemplate);
	ASSERT_TRUE(draft->isValidDraftSchematic());
	ManagedReference<ManufactureSchematic*> schematic = new ManufactureSchematic();
	schematic->setDraftSchematic(draft);
	ASSERT_TRUE(schematic->initializeGeneratedIngredientSlots());
	EXPECT_FALSE(schematic->initializeGeneratedIngredientSlots());
	for (int i = 0; i < schematic->getSlotCount(); ++i) {
		auto resource = dynamic_cast<ResourceSlot*>(schematic->getSlot(i));
		ASSERT_NE(nullptr, resource);
		EXPECT_FALSE(resource->isFull());
		resource->setGeneratedQuality();
	}
	ManagedReference<Component*> prototype = new Component();
	auto targetTemplate = templates->getTemplate(draft->getTanoCRC());
	ASSERT_NE(nullptr, targetTemplate);
	prototype->loadTemplateData(targetTemplate);
	// Unit harness has no ORB ZoneProcessServer; fresh maps suffice for the
	// first concrete crafting update. Full lifecycle is covered by runtime acceptance.
	auto values = schematic->getCraftingValues();
	values->setManufactureSchematic(schematic);
	ResourceLabratory lab;
	lab.setPerfectCraftingValues(prototype, schematic);
	int varied = 0, rawDifferences = 0;
	for (int i = 0; i < values->getTotalExperimentalAttributes(); ++i) {
		String name = values->getAttribute(i);
		if (values->getMinValue(name) == values->getMaxValue(name) || values->getMaxPercentage(name) == 0) continue;
		++varied;
		EXPECT_FLOAT_EQ(1.f, values->getCurrentPercentage(name));
		EXPECT_FLOAT_EQ(values->getMaxValue(name), values->getCurrentValue(name));
		if (prototype->getAttributeValue(name) != values->getCurrentValue(name)) ++rawDifferences;
	}
	EXPECT_GT(varied, 0);
	EXPECT_GT(rawDifferences, 0) << "Raw template creation must not be mistaken for a fully crafted component";
	prototype->updateCraftingValues(values, true);
	for (int i = 0; i < values->getTotalExperimentalAttributes(); ++i) {
		String name = values->getAttribute(i);
		if (name == "xp" || name == "complexity" || name == "useCount") continue;
		EXPECT_FLOAT_EQ(values->getCurrentValue(name), prototype->getAttributeValue(name));
	}
	// Ingredient insertion enforces one normalized unit, template compatibility,
	// serial equality and capacity; it cannot silently eat a delivery dose stack.
	ComponentSlot slot;
	slot.setContentType(targetTemplate->getFullTemplateString());
	slot.setQuantityNeeded(2);
	slot.setIdentical(true);
	String serial = "(perfect-test-a)";
	prototype->setSerialNumber(serial);
	prototype->setUseCount(5, false);
	EXPECT_FALSE(slot.addGeneratedIngredient(prototype));
	prototype->setUseCount(0, false);
	EXPECT_TRUE(slot.addGeneratedIngredient(prototype));
	EXPECT_FALSE(slot.addGeneratedIngredient(prototype));
	ManagedReference<Component*> other = new Component();
	other->loadTemplateData(targetTemplate);

	String different = "(perfect-test-b)";
	other->setSerialNumber(different);
	EXPECT_FALSE(slot.addGeneratedIngredient(other));
	other->setSerialNumber(serial);
	EXPECT_TRUE(slot.addGeneratedIngredient(other));
	EXPECT_TRUE(slot.isFull());
	EXPECT_FALSE(slot.addGeneratedIngredient(other));
}

#include "server/zone/objects/tangible/powerup/PowerupObject.h"

TEST(PerfectCraftingPipeline, PowerupSelectionKeepsNormalStrengthProgressionAndRejectsDuplicates) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	auto target = templates->getTemplate(String("object/tangible/powerup/weapon/ranged_scope.iff").hashCode());
	ASSERT_NE(nullptr, target);
	ManagedReference<PowerupObject*> powerup = new PowerupObject();
	powerup->loadTemplateData(target);
	CraftingValues values;
	values.addExperimentalAttribute("effect", "effectiveness", 1, 100, 0, false, 0);
	values.setCurrentPercentage("effect", 1, 1);
	values.recalculateValues(true);
	Vector<int> secondary;
	secondary.add(0); secondary.add(1); secondary.add(2);
	ASSERT_TRUE(powerup->setPerfectCraftingValues(&values, 0, &secondary));
	EXPECT_EQ(100, powerup->getUses());
	EXPECT_FLOAT_EQ(PowerupObject::MAXPRIMARY / 100.f, powerup->getPowerupStat("maxRangeAccuracy"));
	EXPECT_FLOAT_EQ(PowerupObject::MAXSECONDARY / 100.f, powerup->getPowerupStat("attackSpeed"));
	EXPECT_FLOAT_EQ(PowerupObject::MAXSECONDARY / 200.f, powerup->getPowerupStat("woundsRatio"));
	EXPECT_FLOAT_EQ(PowerupObject::MAXSECONDARY / 400.f, powerup->getPowerupStat("actionAttackCost"));
	secondary.set(2, 0);
	EXPECT_FALSE(powerup->setPerfectCraftingValues(&values, 0, &secondary));
	EXPECT_FALSE(powerup->setPerfectCraftingValues(&values, 999, &secondary));
	// Validation fails before mutating an already finalized result.
	EXPECT_FLOAT_EQ(PowerupObject::MAXPRIMARY / 100.f, powerup->getPowerupStat("maxRangeAccuracy"));
}

#include "server/zone/objects/tangible/misc/LightObject.h"

TEST(PerfectCraftingPipeline, DelayedNewLightsShareIdentityWithoutChangingTheirLifetime) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	auto target = templates->getTemplate(String("object/tangible/furniture/all/frn_all_lamp_desk_s01.iff").hashCode());
	ASSERT_NE(nullptr, target);
	ManagedReference<LightObject*> first = new LightObject();
	first->initializeContainerObjectsMap();
	first->loadTemplateData(target);
	first->calculateLifespan(25);
	nlohmann::json before; first->writeJSON(before);
	Thread::sleep(20);
	ManagedReference<LightObject*> second = new LightObject();
	second->initializeContainerObjectsMap();
	second->loadTemplateData(target);
	second->calculateLifespan(25);
	nlohmann::json after; second->writeJSON(after);
	ASSERT_NE(before["LightObject"]["creationMili"], after["LightObject"]["creationMili"]);
	EXPECT_EQ(25 * 86400, after["LightObject"]["lifespanSeconds"]);
	EXPECT_EQ(PerfectCraftedItemFactory::gameplaySignatureForTesting(first),
		PerfectCraftedItemFactory::gameplaySignatureForTesting(second)) << before.dump() << "\n" << after.dump();
	// Semantic normalization never rewrites actual lifetime data.
	nlohmann::json unchanged; second->writeJSON(unchanged);
	EXPECT_EQ(after["LightObject"], unchanged["LightObject"]);
	second->calculateLifespan(24);
	EXPECT_NE(PerfectCraftedItemFactory::gameplaySignatureForTesting(first),
		PerfectCraftedItemFactory::gameplaySignatureForTesting(second));
	second->calculateLifespan(25);
	second->setBurntOut(true);
	EXPECT_NE(PerfectCraftedItemFactory::gameplaySignatureForTesting(first),
		PerfectCraftedItemFactory::gameplaySignatureForTesting(second));
}

#include "server/zone/objects/tangible/tool/recycle/RecycleToolContainerComponent.h"

TEST(PerfectCraftingPipeline, RecyclerInsertionKeepsInternalSlotsAndOwnerlessVolumeSafe) {
	ManagedReference<RecycleTool*> recycler = new RecycleTool();
	recycler->initializeContainerObjectsMap();
	ManagedReference<TangibleObject*> item = new TangibleObject();
	item->initializeContainerObjectsMap();
	item->setUseCount(7, false);
	RecycleToolContainerComponent callback;
	// The ordinary transfer path calls the callback for internal slot4 too.
	item->setContainmentType(4);
	EXPECT_EQ(0, callback.notifyObjectInserted(recycler, item));
	EXPECT_EQ(7, item->getUseCount());
	EXPECT_FALSE(item->_isMarkedForDeletion());
	// -1 is represented by the uint32 accessor. It must still take the normal
	// volume path, whose task must safely reject a missing player owner.
	item->setContainmentType(static_cast<uint32>(-1));
	EXPECT_EQ(0, callback.notifyObjectInserted(recycler, item));
	RecycleResourceTask directTask(recycler, item);
	EXPECT_NO_THROW(directTask.run());
	EXPECT_EQ(7, item->getUseCount());
	EXPECT_FALSE(item->_isMarkedForDeletion());
}

#include "server/zone/managers/crafting/PerfectCraftingRecipe.h"
#include "server/zone/objects/tangible/Container.h"

namespace {
class GeneratedContainerModeProbe : public ContainerImplementation {
public:
	bool usesDelayedLoading() const { return containerObjects.hasDelayedLoadOperationMode(); }
};
}
TEST(PerfectCraftingPipeline, GeneratedContainerPolicyIsScopedAndPreservesOrdinaryLoading) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	auto target = templates->getTemplate(String("object/tangible/hopper/crafting_station_hopper/crafting_station_ingredient_hopper_large.iff").hashCode());
	ASSERT_NE(nullptr, target);
	GeneratedContainerModeProbe ordinary;
	ordinary.loadTemplateData(target);
	EXPECT_TRUE(ordinary.usesDelayedLoading());
	{
		PerfectCraftingContext context(nullptr, true);
		GeneratedContainerModeProbe generated;
		generated.loadTemplateData(target);
		EXPECT_FALSE(generated.usesDelayedLoading());
	}
	GeneratedContainerModeProbe laterOrdinary;
	laterOrdinary.loadTemplateData(target);
	EXPECT_TRUE(laterOrdinary.usesDelayedLoading());
}

#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/tangible/components/droid/DroidMaintenanceModuleDataComponent.h"
#include "server/zone/objects/tangible/components/droid/DroidPlaybackModuleDataComponent.h"
#include "server/zone/objects/tangible/components/droid/DroidHarvestModuleDataComponent.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/objects/tangible/consumable/Consumable.h"
#include "server/zone/objects/tangible/pharmaceutical/RevivePack.h"

TEST(PerfectCraftingPipeline, LoadedModuleReloadRetainsCapacityTracksAndHarvestDefaults) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	for (auto fixture : {std::make_pair("struct_maint_module_3", "struct_module"), std::make_pair("playback_module", "module_count"), std::make_pair("harvest_module", "harvest_power")}) {
		auto target = templates->getTemplate((String("object/tangible/component/droid/") + fixture.first + ".iff").hashCode());
		ASSERT_NE(nullptr, target);
		ManagedReference<DroidComponent*> source = new DroidComponent();
		source->initializeContainerObjectsMap(); source->loadTemplateData(target);
		auto module = dynamic_cast<BaseDroidModuleComponent*>(source->getDataObjectComponent()->get());
		ASSERT_NE(nullptr, module); module->setParent(source);
		CraftingValues values;
		values.addExperimentalAttribute(fixture.second, "quality", 6, 6, 0, false, 0);
		values.recalculateValues(true);
		source->updateCraftingValues(&values, true);
		if (String(fixture.second) == "harvest_power") {
			ASSERT_TRUE(source->hasKey("harvest_interest"));
			ASSERT_TRUE(source->hasKey("harvest_active"));
		}
		// The production clone lifecycle reloads typed module state from the
		// owning Component property maps. Repeat that exact module boundary.
		module->initializeTransientMembers();
		nlohmann::json before; module->writeJSON(before);
		module->initializeTransientMembers();
		nlohmann::json after; module->writeJSON(after);
		EXPECT_EQ(before, after);
		ObjectOutputStream output; ASSERT_TRUE(module->toBinaryStream(&output));
		ObjectInputStream input; output.copy(&input, 0); input.reset();
		ManagedReference<DroidComponent*> restored = new DroidComponent();
		restored->initializeContainerObjectsMap(); restored->loadTemplateData(target);
		auto restoredModule = dynamic_cast<BaseDroidModuleComponent*>(restored->getDataObjectComponent()->get());
		ASSERT_NE(nullptr, restoredModule); restoredModule->setParent(restored);
		restored->updateCraftingValues(&values, true);
		ASSERT_TRUE(restoredModule->parseFromBinaryStream(&input));
		restoredModule->initializeTransientMembers();
		nlohmann::json reloaded; restoredModule->writeJSON(reloaded);
		EXPECT_EQ(after, reloaded);
		source->_setObjectID(1001); restored->_setObjectID(1002);
		EXPECT_EQ(PerfectCraftedItemFactory::gameplaySignatureForTesting(source), PerfectCraftedItemFactory::gameplaySignatureForTesting(restored));
		if (String(fixture.second) == "struct_module") { EXPECT_EQ(6, after["maxStructures"]); }
		if (String(fixture.second) == "module_count") { EXPECT_EQ(6, after["totalTracks"]); }
		if (String(fixture.second) == "harvest_power") {
			EXPECT_TRUE(source->hasKey("harvest_interest"));
			EXPECT_TRUE(source->hasKey("harvest_active"));
			EXPECT_FLOAT_EQ(0, source->getAttributeValue("harvest_interest"));
			EXPECT_FLOAT_EQ(0, source->getAttributeValue("harvest_active"));
			EXPECT_FLOAT_EQ(6, source->getAttributeValue("harvest_power"));
			EXPECT_TRUE(source->getAttributeHidden("harvest_interest"));
			EXPECT_TRUE(source->getAttributeHidden("harvest_active"));
		}
	}
}

TEST(PerfectCraftingPipeline, InitializedFieldsAndSetOrderPreserveMeaningfulGameplay) {
	ConfigManager::instance()->loadConfigData();
	DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
	auto templates = TemplateManager::instance();
	if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
	auto target = templates->getTemplate(String("object/tangible/component/food/ingredient_carbosyrup.iff").hashCode());
	ASSERT_NE(nullptr, target);
	ManagedReference<Consumable*> ingredient = new Consumable();
	ingredient->initializeContainerObjectsMap(); ingredient->loadTemplateData(target);
	nlohmann::json food; ingredient->writeJSON(food);
	EXPECT_EQ(0, food["Consumable"]["newNutrition"]);
	ManagedReference<WeaponObject*> first = new WeaponObject(), second = new WeaponObject();
	first->initializeContainerObjectsMap(); second->initializeContainerObjectsMap();
	EXPECT_EQ(0, first->getBladeColor()); EXPECT_EQ(0, second->getBladeColor());
	auto weaponTemplate = templates->getTemplate(String("object/weapon/ranged/pistol/pistol_dl44.iff").hashCode());
	ASSERT_NE(nullptr, weaponTemplate);
	first->loadTemplateData(weaponTemplate); second->loadTemplateData(weaponTemplate);
	first->addVisibleComponent(111, false); first->addVisibleComponent(222, false);
	second->addVisibleComponent(222, false); second->addVisibleComponent(111, false);
	EXPECT_EQ(PerfectCraftedItemFactory::gameplaySignatureForTesting(first), PerfectCraftedItemFactory::gameplaySignatureForTesting(second));
	second->addVisibleComponent(333, false);
	EXPECT_NE(PerfectCraftedItemFactory::gameplaySignatureForTesting(first), PerfectCraftedItemFactory::gameplaySignatureForTesting(second));
	second->removeVisibleComponent(333, false);
	second->setBladeColor(4);
	EXPECT_NE(PerfectCraftedItemFactory::gameplaySignatureForTesting(first), PerfectCraftedItemFactory::gameplaySignatureForTesting(second));
}

TEST(PerfectCraftingPipeline, ReviveProfilesReachAttainableEndpointsAndRetainNormalBudgets) {
	ManagedReference<RevivePack*> healing = new RevivePack(), wounds = new RevivePack(), ordinary = new RevivePack();
	CraftingValues values;
	values.addExperimentalAttribute("power", "power", 101.5, 101.5, 2, false, 0);
	values.addExperimentalAttribute("charges", "charges", 10, 10, 0, false, 0);
	values.addExperimentalAttribute("skillmodmin", "skill", 30, 30, 0, false, 0);
	values.recalculateValues(true);
	healing->setPerfectCraftingValues(&values, false);
	wounds->setPerfectCraftingValues(&values, true);
	EXPECT_FLOAT_EQ(50.75, healing->getActionWoundHealed());
	EXPECT_FLOAT_EQ(50.75, healing->getMindWoundHealed());
	EXPECT_FLOAT_EQ(100.75, wounds->getActionWoundHealed());
	EXPECT_FLOAT_EQ(88.75, wounds->getMindWoundHealed());
	for (auto pack : {healing.get(), wounds.get()}) {
		EXPECT_EQ(10, pack->getUseCount());
		EXPECT_FLOAT_EQ(203, pack->getHealthWoundHealed());
		EXPECT_FLOAT_EQ(0, pack->getHealthHealed());
		EXPECT_FLOAT_EQ(203, pack->getActionWoundHealed() + pack->getActionHealed());
		EXPECT_FLOAT_EQ(152.25, pack->getMindWoundHealed() + pack->getMindHealed());
	}
	bool varied = false;
	float previous = -1;
	for (int i = 0; i < 32; ++i) {
		ordinary->updateCraftingValues(&values, true);
		float action = ordinary->getActionWoundHealed();
		EXPECT_GE(action, healing->getActionWoundHealed());
		EXPECT_LE(action, wounds->getActionWoundHealed());
		EXPECT_GE(ordinary->getMindWoundHealed(), healing->getMindWoundHealed());
		EXPECT_LE(ordinary->getMindWoundHealed(), wounds->getMindWoundHealed());
		if (previous >= 0 && action != previous) varied = true;
		previous = action;
	}
	EXPECT_TRUE(varied);
}
