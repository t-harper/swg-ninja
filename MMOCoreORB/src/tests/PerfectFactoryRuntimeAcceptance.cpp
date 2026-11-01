#include "PerfectFactoryRuntimeAcceptance.h"
#include "conf/ConfigManager.h"
#include "server/zone/managers/crafting/PerfectCraftedItemFactory.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/Zone.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/resource/resourcespawner/resourcetree/ResourceTree.h"
#include "server/zone/managers/frs/FrsGmEditor.h"
#include "server/zone/managers/frs/FrsManager.h"
#include "server/zone/managers/frs/FrsRank.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/tangible/component/lightsaber/LightsaberCrystalComponent.h"
#include "server/zone/objects/tangible/deed/droid/DroidDeed.h"
#include "server/zone/objects/tangible/misc/LightObject.h"
#include "templates/params/OptionBitmask.h"
#include "server/zone/objects/installation/factory/FactoryObject.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ResourceSlot.h"
#include "system/security/Crypto.h"
#include "templates/faction/Factions.h"
#include <algorithm>
#include <fstream>
#include <map>
#include <set>
#include <stdexcept>
#include <thread>
#include <vector>

namespace {
using Json = nlohmann::json;
void need(bool value, const std::string& message) { if (!value) throw std::runtime_error(message); }
std::string str(const String& s) { return s.toCharArray(); }
Json read(const std::string& path) {
	std::ifstream input(path); need(input.good(), "Cannot read acceptance input " + path);
	Json value; input >> value; return value;
}
void write(const std::string& path, const Json& value) {
	std::ofstream output(path); need(output.good(), "Cannot write acceptance evidence");
	output << value.dump(2) << '\n'; output.flush(); need(output.good(), "Evidence write failed");
}
std::vector<std::pair<std::string, SceneObject*> > children(SceneObject* object) {
	std::vector<std::pair<std::string, SceneObject*> > result;
	VectorMap<String, ManagedReference<SceneObject*> > slots;
	object->getSlottedObjects(slots);
	for (int i = 0; i < slots.size(); ++i) {
		auto child = slots.elementAt(i).getValue();
		if (child != nullptr) result.emplace_back("slot:" + str(slots.elementAt(i).getKey()), child.get());
	}
	for (int i = 0; i < object->getContainerObjectsSize(); ++i) {
		auto child = object->getContainerObject(i);
		if (child != nullptr) result.emplace_back("container", child);
	}
	auto world = object->getChildObjects();
	for (int i = 0; i < world->size(); ++i)
		if (world->get(i) != nullptr) result.emplace_back("child", world->get(i));
	if (object->isDroidDeedObject()) {
		auto modules = cast<DroidDeed*>(object)->getModules();
		HashTableIterator<String, ManagedReference<DroidComponent*> > it = modules->iterator();
		while (it.hasNext()) {
			String name; ManagedReference<DroidComponent*> module;
			it.getNextKeyAndValue(name, module);
			if (module != nullptr) result.emplace_back("module:" + str(name), module.get());
		}
	}
	return result;
}
void graph(SceneObject* object, std::set<uint64>& ids) {
	if (object == nullptr || !ids.insert(object->getObjectID()).second) return;
	for (auto child : children(object)) graph(child.second, ids);
}
Json semantics(SceneObject* object, unsigned depth = 0) {
	need(depth < 100, "Acceptance graph too deep");
	Json value; object->writeJSON(value);
	for (const char* base : {"ManagedObject", "DistributedObject", "TreeEntry"}) value.erase(base);
	if (value.contains("SceneObject")) {
		auto& s = value["SceneObject"];
		for (const char* field : {"zone", "direction", "movementCounter", "objectName", "customName", "childObjects", "slottedObjects", "containerObjects", "originalObjectID", "objectActiveSessions", "containerPermissions", "containmentType", "forceSend"}) s.erase(field);
		// DataObjectComponent::writeJSON includes its owning object's ID.
		// Copies must own independent objects while retaining component state.
		if (s.contains("dataObjectComponent") && s["dataObjectComponent"].is_object())
			s["dataObjectComponent"].erase("parent");
	}
	if (value.contains("TangibleObject")) {
		auto& s = value["TangibleObject"];
		for (const char* field : {"craftersName", "craftersID", "objectSerial", "conditionDamage", "unmitigatedDamage", "defenderList", "activeAreas"}) s.erase(field);
		if (s.contains("visibleComponents") && s["visibleComponents"].is_object()) {
			auto& visible = s["visibleComponents"];
			if (visible.contains("set") && visible["set"].is_array())
				std::sort(visible["set"].begin(), visible["set"].end());
		}
	}
	if (value.contains("DroidDeed")) value["DroidDeed"].erase("modules");
	if (value.contains("LightObject")) {
		auto& light = value["LightObject"];
		if (light.value("firstUpdate", false) && !light.value("burntOut", true)) {
			light.erase("creationMili"); light.erase("lifespan");
		}
	}
	std::vector<std::pair<std::string, std::string> > descendants;
	for (auto child : children(object)) descendants.emplace_back(child.first, semantics(child.second, depth + 1).dump());
	std::sort(descendants.begin(), descendants.end());
	for (const auto& child : descendants) value["ownedChildren"].push_back({child.first, child.second});
	return value;
}
String digest(SceneObject* object) { return Crypto::SHA256Hash(String(semantics(object).dump().c_str())); }
std::set<uint64> inventoryIds(SceneObject* inventory) {
	std::set<uint64> ids;
	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) ids.insert(inventory->getContainerObject(i)->getObjectID());
	return ids;
}
std::vector<ManagedReference<SceneObject*> > newItems(SceneObject* inventory, const std::set<uint64>& before) {
	std::vector<ManagedReference<SceneObject*> > items;
	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		auto object = inventory->getContainerObject(i);
		if (!before.count(object->getObjectID())) items.push_back(object);
	}
	return items;
}
void discard(SceneObject* object) {
	Locker lock(object); object->destroyObjectFromWorld(false); object->destroyObjectFromDatabase(true);
}
struct Product {
	String id, path, draft, kind, category, reviveProfile;
	std::vector<String> professions;
	std::vector<PerfectIngredientChoice> choices;
};
std::map<std::string, Product> products(const String& path) {
	Lua lua; lua.init(); need(lua.runFile(path), "Acceptance catalog unreadable");
	auto root = lua.getGlobalObject("PerfectFactoryCatalog");
	auto rows = root.getObjectField("entries");
	std::map<std::string, Product> result;
	for (int i = 1; i <= rows.getTableSize(); ++i) {
		auto row = rows.getObjectAt(i); Product p;
		p.id = row.getStringField("id"); p.kind = row.getStringField("kind"); p.path = row.getStringField("targetTemplate");
		p.draft = row.getStringField("draftPath"); p.category = row.getStringField("category");
		p.reviveProfile = row.getStringField("reviveProfile");
		auto profs = row.getObjectField("professions");
		for (int j = 1; j <= profs.getTableSize(); ++j) p.professions.push_back(profs.getStringAt(j));
		profs.pop(); auto choices = row.getObjectField("ingredientChoices");
		for (int j = 1; j <= choices.getTableSize(); ++j) {
			auto c = choices.getObjectAt(j); PerfectIngredientChoice choice;
			choice.slotIndex = c.getIntField("slotIndex"); choice.quantity = c.getIntField("quantity");
			choice.childId = c.getStringField("childId"); choice.omit = c.getBooleanField("omit");
			p.choices.push_back(choice); c.pop();
		}
		choices.pop(); row.pop(); result.emplace(str(p.id), p);
	}
	rows.pop(); root.pop(); return result;
}
FactoryCrate* give(CreatureObject* player, const String& id) {
	auto inventory = player->getSlottedObject("inventory"); auto before = inventoryIds(inventory);
	String error;
	const bool granted = PerfectCraftedItemFactory::grant(player, id, error, PerfectCraftedItemFactory::getCatalogGeneration());
	need(granted, str(error));
	auto added = newItems(inventory, before); need(added.size() == 1 && added[0]->isFactoryCrate(), "Grant did not add exactly one crate");
	auto crate = cast<FactoryCrate*>(added[0].get());
	need(crate->getUseCount() == 1000 && crate->getMaxCapacity() == 1000 && crate->isValidFactoryCrate(), "Maximum crate validation failed");
	return crate;
}
Json crystalStats(LightsaberCrystalComponent* crystal) {
	return {crystal->getDamage(), crystal->getForceCost(), crystal->getSacHealth(), crystal->getSacAction(),
		crystal->getSacMind(), crystal->getAttackSpeed(), crystal->getWoundChance()};
}

void exerciseProduct(ZoneServer* server, CreatureObject* player, const Product& product, Json& result, Json& retained,
	std::set<std::string>& retainedGroups) {
	auto inventory = player->getSlottedObject("inventory"); const auto before = inventoryIds(inventory);
	auto crate = give(player, product.id); auto prototype = crate->getPrototype();
	const String original = digest(prototype), serial = prototype->getSerialNumber();
	Json extractionExpected = semantics(prototype);
	if (prototype->getIsCraftedEnhancedItem()) {
		// Ordinary extraction restores its display magic counter and yellow bit.
		// Preserve and compare every other option bit and all gameplay fields.
		auto& tangible = extractionExpected["TangibleObject"];
		const int magic = tangible.at("magicBits").get<int>();
		tangible["magicBits"] = magic + 1;
		if (magic == 0) tangible["optionsBitmask"] = tangible.at("optionsBitmask").get<uint32>() | OptionBitmask::YELLOW;
	}
	need(!serial.isEmpty(), "Perfect prototype serial missing");
	const int doses = prototype->getUseCount();
	std::set<uint64> firstGraph; graph(prototype, firstGraph);
	std::vector<ManagedReference<TangibleObject*> > extracted;
	for (int i = 0; i < 2; ++i) {
		auto prior = inventoryIds(inventory);
		need(crate->extractObjectToInventory(player), "Ordinary crate extraction failed");
		auto items = newItems(inventory, prior);
		need(items.size() == 1 && items[0]->isTangibleObject(), "Extraction did not add one tangible");
		auto item = cast<TangibleObject*>(items[0].get());
		need(item->getSerialNumber() == serial && item->getUseCount() == doses, "Extraction lost serial/natural doses");
		need(semantics(item) == extractionExpected, "Ordinary extraction changed concrete gameplay data/options outside its normal magic display update");
		std::set<uint64> ids; graph(item, ids);
		for (auto id : ids) need(!firstGraph.count(id), "Extracted graph shares ownership with another prototype");
		firstGraph.insert(ids.begin(), ids.end()); extracted.push_back(item);
	}
	need(crate->getUseCount() == 998, "Two extractions did not leave998");
	auto priorSplit = inventoryIds(inventory);
	{ Locker lock(crate); crate->split(400); }
	auto splitItems = newItems(inventory, priorSplit);
	need(splitItems.size() == 1 && splitItems[0]->isFactoryCrate(), "Ordinary crate split failed");
	auto split = cast<FactoryCrate*>(splitItems[0].get());
	need(crate->getUseCount() == 598 && split->getUseCount() == 400, "Split did not conserve998");
	need(split->getMaxCapacity() == crate->getMaxCapacity(), "Split lost the source crate capacity");
	need(split->getPrototype()->getSerialNumber() == serial && digest(split->getPrototype()) == original, "Split altered prototype");
	if (str(product.path).find("frn_all_light") != std::string::npos)
		std::this_thread::sleep_for(std::chrono::milliseconds(25));
	auto repeat = give(player, product.id);
	need(repeat->getSerialNumber() == serial && digest(repeat->getPrototype()) == original, "Later grant incompatible with original batch");
	result["serial"] = str(serial); result["naturalUses"] = doses; result["ownedObjectsAcrossExtracts"] = firstGraph.size();
	result["extractSplitRepeat"] = true;
	if (extracted[0]->isLightsaberCrystalObject()) {
		auto crystal = cast<LightsaberCrystalComponent*>(extracted[0].get());
		auto stats = crystalStats(crystal); crystal->tuneCrystal(player); crystal->validateCrystalStats();
		need(crystalStats(crystal) == stats, "Tuning/validation rerolled legitimate normal crystal endpoints");
		result["tunedCrystalStable"] = true;
	}
	// Force a partial ordinary deep clone through the scoped allocation guard.
	if (children(prototype).size() > 0) {
		const String sourceBefore = digest(prototype);
		std::vector<ManagedReference<SceneObject*> > failedAllocations;
		bool rejected = false;
		{
			PerfectCraftingContext context(server, true);
			std::set<uint64> sourceIds; graph(prototype, sourceIds);
			context.setAllocationLimitForTesting(sourceIds.size() - 1);
			try { context.clone(prototype); } catch (...) { rejected = true; }
			need(rejected, "Allocation-limit clone failure was not exercised");
			failedAllocations = context.trackedObjectsForTesting();
		}
		need(!failedAllocations.empty(), "Clone failed before any staged allocation");
		for (auto object : failedAllocations)
			need(object->_isMarkedForDeletion() && !object->isPersistent(), "Failed clone left a newly allocated object alive/persistent");
		need(digest(prototype) == sourceBefore, "Failed clone damaged borrowed original graph");
		for (auto id : firstGraph) {
			auto object = server->getObject(id);
			need(object != nullptr && !object->_isMarkedForDeletion(), "Failed clone deleted an original/module");
		}
		result["partialCloneSourcePreserved"] = true;
	}
	// Keep representative concrete classes for restart without filling the
	// character's inventory merely because many profession aliases were tested.
	std::string group = "ordinary";
	if (prototype->isDroidDeedObject()) group = "droid";
	else if (str(product.path).find("/deed/pet_deed/") != std::string::npos) group = "pet";
	else if (prototype->isLightsaberCrystalObject()) group = "crystal:" + std::to_string(prototype->getServerObjectCRC());
	else if (str(product.path).find("dna_template") != std::string::npos) group = "genetic";
	else if (product.kind == "dna") group = "dna";
	else if (str(product.path).find("/medicine/") != std::string::npos) group = "medicine";
	else if (str(product.path).find("crafted_saber") != std::string::npos) group = "saber";
	else if (str(product.path).find("/crafting/station/") != std::string::npos) group = "station";
	else if (dynamic_cast<LightObject*>(prototype.get()) != nullptr) group = "light";
	std::set<uint64> keep;
	// Every exercised profile gets a real extracted-item cold-reload check.
	retained.push_back({{"id", extracted[0]->getObjectID()}, {"catalogId", str(product.id)},
		{"digest", str(digest(extracted[0]))}, {"serial", str(serial)}});
	keep.insert(extracted[0]->getObjectID());
	if (retainedGroups.insert(group).second) {
		retained.push_back({{"id", split->getObjectID()}, {"catalogId", str(product.id)},
			{"digest", str(digest(split))}, {"serial", str(serial)}, {"count", 400}});
		keep.insert(split->getObjectID());
	}
	for (auto item : newItems(inventory, before)) if (!keep.count(item->getObjectID())) discard(item);
}

void factoryRefill(ZoneServer* server, CreatureObject* player, const std::map<std::string, Product>& catalog, Json& report) {
	// This real Tailor draft requires an identical Synthetic Cloth component
	// plus fiberplast; the cloth recipe's optional tissue has no legal provider.
	const String draftPath = "object/draft_schematic/clothing/clothing_shirt_casual_16.iff";
	const Product* selected = nullptr;
	auto chosen = catalog.find("r_c5b83573a204f231b3f15fdab5aa3853");
	if (chosen != catalog.end()) selected = &chosen->second;
	need(selected != nullptr && selected->draft == draftPath && PerfectCraftedItemFactory::isAvailable(selected->id), "Factory chain product unavailable");
	need(selected->id == "r_c5b83573a204f231b3f15fdab5aa3853" && selected->choices.size() == 1 &&
		!selected->choices[0].omit && selected->choices[0].slotIndex == 0 && selected->choices[0].quantity == 1 &&
		selected->choices[0].childId == "r_492dce111f933d31341975c36de8db31", "Factory fixture no longer selects the required identical cloth chain");
	String error;
	String componentSerial, componentKey;
	ManagedReference<SceneObject*> holder;
	ManagedReference<TangibleObject*> output;
	ManagedReference<FactoryObject*> factory;
	ManagedReference<ManufactureSchematic*> schematic;
	struct ResourceInput { ManagedReference<ResourceSpawn*> spawn; int quantity; int slotIndex; };
	std::vector<ResourceInput> resources;
	auto manager = server->getResourceManager();
	ResourceTree resourceTree(manager->getResourceSpawner());
	ManagedReference<DraftSchematic*> resourcePattern = new DraftSchematic();
	resourcePattern->loadTemplateData(TemplateManager::instance()->getTemplate(draftPath.hashCode()));
	need(resourcePattern->getDraftSlotCount() == 2 &&
		resourcePattern->getDraftSlot(0)->getSlotType() == IngredientSlot::IDENTICALSLOT &&
		resourcePattern->getDraftSlot(0)->getResourceType() == "object/tangible/component/clothing/shared_synthetic_cloth.iff" &&
		resourcePattern->getDraftSlot(0)->getQuantity() == 1 &&
		resourcePattern->getDraftSlot(1)->getSlotType() == IngredientSlot::RESOURCESLOT &&
		resourcePattern->getDraftSlot(1)->getResourceType() == "fiberplast" && resourcePattern->getDraftSlot(1)->getQuantity() == 30,
		"Loaded factory fixture no longer requires identical cloth and real fiberplast");
	for (int i = 0; i < resourcePattern->getDraftSlotCount(); ++i) {
		auto slot = resourcePattern->getDraftSlot(i); if (slot->getSlotType() != IngredientSlot::RESOURCESLOT) continue;
		auto entry = resourceTree.getEntry(slot->getResourceType());
		need(entry != nullptr && !entry->hasChildren() && !entry->isRecycled() &&
			entry->getAttributeCount() > 0 && entry->isType(slot->getResourceType()), "Loaded resource tree supplied no legal matching leaf");
		String name = manager->preparePerfectResource(entry->getType());
		need(!name.isEmpty(), "Normal perfect-resource provider returned no spawn name");
		auto spawn = manager->getResourceSpawn(name);
		need(spawn != nullptr && spawn->isPersistent() && !spawn->_isMarkedForDeletion() &&
			spawn->getType() == entry->getType() && spawn->isType(slot->getResourceType()),
			"Real perfect resource must be persistent outside generation context");
		need(slot->getQuantity() > 0 && slot->getQuantity() <= static_cast<uint32>(INT_MAX), "Invalid real resource quantity");
		resources.push_back({spawn, static_cast<int>(slot->getQuantity()), i});
	}
	{
	PerfectCraftingContext context(server, true);
	output = PerfectCraftedItemFactory::createForAudit(selected->id, context, error); need(output != nullptr, str(error));
	auto draft = cast<DraftSchematic*>(context.create(draftPath));
	schematic = draft->createManufactureSchematic().castTo<ManufactureSchematic*>(); context.own(schematic);
	need(schematic->initializeGeneratedIngredientSlots(), "Factory acceptance slots unavailable");
	for (const auto& resource : resources) {
		auto slot = schematic->getSlot(resource.slotIndex);
		auto container = resource.spawn->createResource(slot->getQuantityNeeded()); context.ownGraph(container);
		need(container != nullptr && cast<ResourceSlot*>(slot)->add(player, nullptr, container.get()), "Ordinary resource insertion failed");
		need(slot->isFull(), "Actual resource slot not filled");
	}
	for (const auto& choice : selected->choices) {
		if (choice.omit) continue;
		auto ingredient = PerfectCraftedItemFactory::createForAudit(choice.childId, context, error); need(ingredient != nullptr, str(error));
		componentSerial = ingredient->getSerialNumber(); componentKey = String::valueOf(ingredient->getServerObjectCRC());
		auto slot = schematic->getSlot(choice.slotIndex); need(!slot->isResourceSlot(), "Expected component-only factory chain");
		for (int unit = 0; unit < choice.quantity; ++unit) {
			auto clone = cast<TangibleObject*>(context.clone(ingredient)); clone->setUseCount(0, false);
			need(cast<ComponentSlot*>(slot)->addGeneratedIngredient(clone), "Factory blueprint component mismatch");
		}
	}
	schematic->setPrototype(output); schematic->setManufactureLimit(3);
	need(schematic->getBlueprintSize() == 2 && schematic->getFactoryCrateSize() > 0, "Factory blueprint omitted real fiberplast or identical Synthetic Cloth");
	int componentEntries = 0, resourceEntries = 0;
	for (int i = 0; i < schematic->getBlueprintSize(); ++i) {
		auto entry = schematic->getBlueprintEntry(i);
		if (entry->getType() == "component") {
			++componentEntries;
			need(entry->needsIdentical() && !componentSerial.isEmpty() && entry->getSerial() == componentSerial &&
				entry->getKey() == componentKey && entry->getQuantity() == 1, "Factory blueprint lost identical cloth serial/key/quantity");
		} else if (entry->getType() == "resource") {
			++resourceEntries;
			need(resources.size() == 1 && entry->getKey() == resources[0].spawn->getName() && entry->getQuantity() == 30,
				"Factory blueprint lost real fiberplast spawn/quantity");
		} else need(false, "Unexpected factory blueprint ingredient type");
	}
	need(componentEntries == 1 && resourceEntries == 1, "Factory blueprint ingredient types changed");
	factory = cast<FactoryObject*>(context.create("object/installation/manufacture/clothing_factory.iff"));
	factory->createChildObjects(); context.ownGraph(factory);
	need(factory->transferObject(schematic, -1, false), "Factory could not accept real manufacture schematic");
	// Maintenance is pre-funded only in this disposable fixture; normal object
	// production and BlueprintEntry consumption remain the actual server code.
	factory->setSurplusMaintenance(10000000); factory->setSurplusPower(10000000);
	// Keep the factory and the schematic's separately referenced draft/prototype
	// in a disposable persistent holder. Generation ends before normal production.
	holder = context.create("object/tangible/hopper/crafting_station_hopper/crafting_station_ingredient_hopper_large.iff");
	holder->setContainerVolumeLimit(10000);
	need(holder->transferObject(factory, -1, false) && holder->transferObject(output, -1, false) &&
		holder->transferObject(draft, -1, false), "Cannot retain disposable factory fixture graph");
	context.ownGraph(holder);
	context.prepareReleaseGraph(holder); context.persistGraph(holder); context.releasePreparedGraph();
	}
	need(PerfectCraftingContext::current() == nullptr, "Normal factory production must run outside generated context");
	// Ordinary depletion removes ingredients through their resolved world zone.
	// Use a real private ground-zone root, as normal placed factories do.
	auto zone = server->getZone("corellia");
	need(zone != nullptr && !zone->isSpaceZone(), "Private factory requires a loaded ground zone");
	holder->initializePosition(7000, zone->getHeight(7000, 7000), 7000);
	need(zone->transferObject(holder, -1, false), "Private factory holder could not enter the real zone");
	auto input = factory->getSlottedObject("ingredient_hopper");
	auto hopper = factory->getSlottedObject("output_hopper"); need(input != nullptr && hopper != nullptr, "Factory hoppers absent");
	need(holder->getZone() == zone && factory->getZone() == zone && input->getZone() == zone && hopper->getZone() == zone,
		"Factory fixture has unresolved world containment");
	Json consumedIds = Json::array();
	for (int pass = 0; pass < 2; ++pass) {
		report["lastPass"] = pass;
		need(input->getContainerObjectsSize() == 0, "A consumed stack remained before the next refill");
		std::vector<ManagedReference<FactoryCrate*> > crates;
		std::vector<ManagedReference<ResourceContainer*> > resourceContainers;
		for (const auto& resource : resources) {
			need(resource.spawn->isPersistent() && !resource.spawn->_isMarkedForDeletion(), "Resource source was destroyed with generation setup");
			auto container = resource.spawn->createResource(resource.quantity);
			need(container != nullptr && input->transferObject(container, -1, false), "Real resource refill could not enter hopper");
			resourceContainers.push_back(container);
		}
		for (const auto& choice : selected->choices) {
			if (choice.omit) continue;
			// A new request/context proves later independently generated ingredient
			// batches satisfy the same already-created identical-ingredient blueprint.
			ManagedReference<FactoryCrate*> crate;
			{
				PerfectCraftingContext fresh(server, true);
				auto ingredient = PerfectCraftedItemFactory::createForAudit(choice.childId, fresh, error); need(ingredient != nullptr, str(error));
				String type;
				crate = ingredient->createFactoryCrate(1000, type, true, true); fresh.ownGraph(crate);
				need(crate != nullptr, "Fresh component crate creation failed");
				crate->setUseCount(choice.quantity, false);
				fresh.prepareReleaseGraph(crate); fresh.persistGraph(crate); fresh.releasePreparedGraph();
			}
			need(crate != nullptr && input->transferObject(crate, -1, false), "Refill could not enter ingredient hopper");
			crates.push_back(crate);
		}
		need(PerfectCraftingContext::current() == nullptr, "A generation scope leaked into normal manufacture");
		{
			Locker factoryLock(factory);
			need(factory->startFactory(), "Real factory refused recipe");
			auto pending = factory->getPendingTask("createFactoryObject"); if (pending != nullptr) pending->cancel();
			try { factory->createNewObject(); }
			catch (...) { if (pending != nullptr) pending->cancel(); throw; }
			if (pending != nullptr) pending->cancel();
		}
		need(schematic->getManufactureLimit() == 2 - pass, "Factory did not consume one manufacture run");
		need(hopper->getContainerObjectsSize() == 1, "Factory output missing");
		auto crate = hopper->getContainerObject(0).castTo<FactoryCrate*>();
		need(crate != nullptr && crate->getUseCount() == pass + 1, "Factory did not produce/stack real output");
		need(crate->getSerialNumber() == output->getSerialNumber(), "Factory changed crafted serial");
		need(crate->isPersistent() && crate->getPrototype()->isPersistent(), "Ordinary production did not persist output/prototype");
		for (auto consumed : crates) {
			report["lastComponentAfter"] = {{"id", consumed->getObjectID()}, {"count", consumed->getUseCount()},
				{"deleted", consumed->_isMarkedForDeletion()}, {"persistent", consumed->isPersistent()}};
			need(consumed->getUseCount() == 0 && consumed->_isMarkedForDeletion() && !consumed->isPersistent() &&
				!inventoryIds(input).count(consumed->getObjectID()), "Factory did not consume and remove required component batch");
			consumedIds.push_back(consumed->getObjectID());
		}
		for (auto consumed : resourceContainers) {
			need(consumed->getQuantity() == 0 && consumed->_isMarkedForDeletion() && !consumed->isPersistent() &&
				!inventoryIds(input).count(consumed->getObjectID()), "Factory did not consume and remove required resource quantity");
			consumedIds.push_back(consumed->getObjectID());
		}
		need(input->getContainerObjectsSize() == 0, "Normal factory left consumed ingredients in its hopper");
	}
	{ Locker factoryLock(factory); if (factory->isActive()) factory->handleOperateToggle(player); }
	auto produced = hopper->getContainerObject(0).castTo<FactoryCrate*>();
	report = {{"draft", str(draftPath)}, {"manufactured", 2}, {"freshRefillMatched", true}, {"normalFactoryEligible", true},
		{"catalogId", str(selected->id)}, {"componentId", str(selected->choices[0].childId)}, {"componentSerial", str(componentSerial)},
		{"resourceType", str(resources[0].spawn->getType())}, {"resourceName", str(resources[0].spawn->getName())}, {"resourceQuantity", 30},
		{"consumedIds", consumedIds}, {"ordinaryWorldContainment", true},
		{"factoryId", factory->getObjectID()}, {"holderId", holder->getObjectID()}, {"crateId", produced->getObjectID()},
		{"outputDigest", str(digest(produced))}, {"normalContext", true}};
	write("log/perfect-factory-manufacturing-retained.json", report);
}

Json playerSkills(CreatureObject* player) {
	Vector<String> skills; player->getSkillList()->getStringList(skills);
	std::vector<std::string> result;
	for (int i = 0; i < skills.size(); ++i) result.push_back(str(skills.get(i)));
	std::sort(result.begin(), result.end()); return result;
}
Json playerPermissions(CreatureObject* player) {
	auto permissions = player->getPlayerObject()->getPermissionGroups();
	std::vector<std::string> result;
	for (int i = 0; i < permissions->size(); ++i) result.push_back(str(permissions->get(i)));
	std::sort(result.begin(), result.end()); return result;
}
ManagedReference<CreatureObject*> frsActor(ZoneServer* server, uint64 id, int level) {
	need(level > 6 && level <= 15, "Private FRS fixture must identify a verified GM permission level");
	auto actor = server->getObject(id).castTo<CreatureObject*>();
	need(actor != nullptr && actor->isPlayerCreature(), "Private GM fixture character missing");
	// The offline world loader does not execute the account-login permission
	// hook. Reproduce that normal hook using the cloned SQL account's level.
	server->getPlayerManager()->updatePermissionLevel(actor, level);
	need(FrsGmEditor::isAuthorized(actor), "Normal account-permission hook did not initialize GM abilities");
	return actor;
}
void exerciseFrs(ZoneServer* server, CreatureObject* scratch, const Json& fixture, Json& report) {
	report = {{"stage", "authorize-and-check-rank-boundaries"}};
	const int permissionLevel = fixture.at("frsActorAdminLevel").get<int>();
	auto gm = frsActor(server, fixture.at("frsActorId").get<uint64>(), permissionLevel);
	CreatureObject* actor = gm.get();
	Locker gmLock(actor, scratch);
	auto target = server->getObject(fixture.at("frsTargetId").get<uint64>()).castTo<CreatureObject*>();
	need(target != nullptr && target != actor && actor != scratch, "FRS acceptance requires separate GM, ordinary actor and target");
	need(!FrsGmEditor::isAuthorized(scratch), "Ordinary scratch fixture unexpectedly has GM privilege");
	auto manager = server->getFrsManager();
	need(manager != nullptr, "FRS manager absent");
	for (int council : {1, 2}) {
		for (int invalidRank : {INT_MIN, -1, 0, 12, INT_MAX})
			need(manager->getFrsRank(council, invalidRank) == nullptr,
				"FRS rank lookup accepted an invalid roster index");
		for (int rank : {1, 11}) {
			auto row = manager->getFrsRank(council, rank);
			need(row != nullptr && row->getRank() == rank, "FRS valid boundary roster missing");
		}
	}
	report["rankLookupBoundaries"] = true;
	Vector<String> initialSkills;
	target->getSkillList()->getStringList(initialSkills);
	auto targetInventory = target->getSlottedObject("inventory");
	const auto initialInventory = inventoryIds(targetInventory);
	String error;
	const int oldTargetXp = target->getPlayerObject()->getExperience("force_rank_xp");
	need(!FrsGmEditor::setExactXp(scratch, target, 22222, error) &&
		target->getPlayerObject()->getExperience("force_rank_xp") == oldTargetXp, "Ordinary player could mutate FRS XP");
	auto expect = [&](bool value) { need(value, str(error)); };
	const int oldSelfXp = actor->getPlayerObject()->getExperience("force_rank_xp");
	report["stage"] = "self-exact-xp";
	expect(FrsGmEditor::setExactXp(actor, actor, 12345, error));
	need(actor->getPlayerObject()->getExperience("force_rank_xp") == 12345, "GM self XP edit was multiplied or capped");
	expect(FrsGmEditor::setExactXp(actor, actor, oldSelfXp, error));
	auto state = [&]() { FrsGmEditorState value; expect(FrsGmEditor::readState(actor, target, value, error)); return value; };
	auto member = [&](int council, int rank) {
		auto row = server->getFrsManager()->getFrsRank(council, rank);
		need(row != nullptr, "Real FRS rank roster absent"); Locker lock(row);
		return row->isOnPlayerList(target->getObjectID());
	};
	expect(FrsGmEditor::setExactXp(actor, target, 12345, error));
	need(state().xp == 12345, "FRS exact XP was multiplied or capped");
	report["stage"] = "light-rank-0";
	expect(FrsGmEditor::setCouncilAndRank(actor, target, 1, 0, error));
	need(state().rank == 0 && state().xp == 12345 && target->hasSkill("force_rank_light_novice"),
		"Real rank0 enrollment failed");
	report["stage"] = "light-rank-11";
	expect(FrsGmEditor::setCouncilAndRank(actor, target, 1, 11, error));
	auto light = state();
	need(light.council == 1 && light.rank == 11 && light.xp == 12345 && light.jediState == 4 &&
		light.faction == Factions::FACTIONREBEL && light.factionStatus == FactionStatus::OVERT,
		"Light GM enrollment/rank/XP state inconsistent");
	need(member(1, 11) && target->hasSkill("force_rank_light_novice"), "Light membership/skills not synchronized");
	report["stage"] = "switch-light-11-to-dark-3";
	expect(FrsGmEditor::setCouncilAndRank(actor, target, 2, 3, error));
	auto dark = state();
	need(dark.council == 2 && dark.rank == 3 && dark.xp == 12345 && dark.jediState == 8 &&
		dark.faction == Factions::FACTIONIMPERIAL && dark.factionStatus == FactionStatus::OVERT,
		"Dark GM switch state inconsistent");
	need(!member(1, 11) && member(2, 3) && !target->hasSkill("force_rank_light_novice") &&
		target->hasSkill("force_rank_dark_novice"), "Council switch left old roster/skill membership");
	expect(FrsGmEditor::setExactXp(actor, target, 0, error));
	need(state().xp == 0 && state().rank == 3, "Low exact XP silently changed GM rank");
	expect(FrsGmEditor::setExactXp(actor, target, 1000000, error));
	need(state().xp == 1000000, "Above-cap GM exact XP was silently clamped");
	expect(FrsGmEditor::setExactXp(actor, target, INT_MAX, error));
	report["stage"] = "ordinary-xp-overflow-boundary";
	report["overflowXpBefore"] = state().xp;
	report["overflowNormalCap"] = state().normalXpCap;
	report["overflowManagerWouldSkip"] = target->getPlayerObject()->hasCappedExperience("force_rank_xp");
	server->getFrsManager()->adjustFrsExperience(target, 1, false);
	need(state().xp == state().normalXpCap && state().rank == 3,
		"Ordinary FRS gain overflowed an exact INT_MAX total rather than applying the normal cap");
	expect(FrsGmEditor::setExactXp(actor, target, 1000000, error));
	need(!FrsGmEditor::setExactXp(actor, target, -1, error), "Negative XP accepted");
	need(!FrsGmEditor::setCouncilAndRank(actor, target, 2, 12, error), "Out-of-range rank accepted");
	need(state().xp == 1000000 && state().rank == 3, "Invalid FRS edits changed state");
	const auto level = actor->getPlayerObject()->getAdminLevel();
	actor->getPlayerObject()->setAdminLevel(0);
	const bool rejected = !FrsGmEditor::setExactXp(actor, target, 22222, error);
	actor->getPlayerObject()->setAdminLevel(level);
	need(rejected && state().xp == 1000000, "Revoked GM privilege did not prevent mutation");
	report["stage"] = "remove-dark-council";
	expect(FrsGmEditor::setCouncilAndRank(actor, target, 0, -1, error));
	need(state().council == 0 && state().rank == -1 && state().xp == 1000000 && !member(2, 3) &&
		!target->hasSkill("force_rank_dark_novice"), "None council failed to remove membership while retaining XP");
	report["stage"] = "final-light-rank-6";
	expect(FrsGmEditor::setCouncilAndRank(actor, target, 1, 6, error));
	expect(FrsGmEditor::setExactXp(actor, target, 12345, error));
	auto final = state(); need(final.rank == 6 && final.xp == 12345 && member(1, 6), "Final GM-selected low-XP rank not retained");
	std::set<int> actualRanks;
	for (const auto& skill : playerSkills(target)) {
		const String name(skill.get<std::string>().c_str());
		if (!name.beginsWith("force_rank_")) continue;
		const int rank = server->getFrsManager()->getSkillRank(name, final.council);
		need(rank >= 0 && rank <= final.rank, "Final FRS state has an incorrect council/rank skill");
		actualRanks.insert(rank);
	}
	for (int rank = 0; rank <= final.rank; ++rank) need(actualRanks.count(rank), "Final FRS state is missing a rank skill");
	need(target->getPlayerObject()->hasPermissionGroup("LightEnclaveRank6"), "Final FRS rank permission missing");
	for (int rank = 0; rank <= 11; ++rank) {
		need(!target->getPlayerObject()->hasPermissionGroup("DarkEnclaveRank" + String::valueOf(rank)), "Old Dark council permission survived switching");
		if (rank > final.rank)
			need(!target->getPlayerObject()->hasPermissionGroup("LightEnclaveRank" + String::valueOf(rank)), "Higher old Light rank permission survived demotion");
	}
	for (int i = 0; i < initialSkills.size(); ++i) {
		const String& skill = initialSkills.get(i);
		if (!skill.beginsWith("force_rank_") && !skill.beginsWith("force_title_jedi_"))
			need(target->hasSkill(skill), "FRS editor removed an unrelated skill");
	}
	need(inventoryIds(targetInventory) == initialInventory, "FRS editor altered existing inventory");
	report = {{"actorId", actor->getObjectID()}, {"actorAdminLevel", permissionLevel},
		{"rankLookupBoundaries", true},
		{"ordinaryPlayerDenied", true}, {"selfExactXpVerified", true},
		{"targetId", target->getObjectID()}, {"council", final.council}, {"rank", final.rank},
		{"xp", final.xp}, {"jediState", final.jediState}, {"faction", final.faction},
		{"factionStatus", final.factionStatus}, {"skills", playerSkills(target)}, {"permissions", playerPermissions(target)},
		{"normalXpCap", final.normalXpCap}, {"exactZeroAndAboveCap", true}, {"revokedPrivilegeDenied", true},
		{"councilRostersAndSkillsSynchronized", true}, {"unrelatedSkillsAndInventoryPreserved", true}};
	write("log/frs-gm-runtime-retained.json", report);
}

void auditCoverage(const std::map<std::string, Product>& catalog, const Json& fixture, Json& report) {
	const auto audit = read("log/perfect-factory-audit.json");
	need(audit.at("total").get<size_t>() == catalog.size() && audit.at("entries").size() == catalog.size(),
		"Native audit did not cover the complete current catalog");
	const auto approved = fixture.value("approvedRejections", Json::object());
	std::set<std::string> allDrafts, allTargets, verifiedDrafts, verifiedTargets;
	Json semanticHashes = Json::object();
	Json unexplained = Json::object();
	for (const auto& pair : catalog) {
		const auto& p = pair.second;
		if (p.kind == "recipe") { allDrafts.insert(str(p.draft)); allTargets.insert(str(p.path)); }
		const auto& row = audit.at("entries").at(pair.first);
		if (row.at("availability") == "verified") {
			semanticHashes[pair.first] = row.at("semanticHash");
			if (p.kind == "recipe") { verifiedDrafts.insert(str(p.draft)); verifiedTargets.insert(str(p.path)); }
		} else if (!approved.contains(pair.first) || approved.at(pair.first) != row.at("reason")) {
			unexplained[pair.first] = row.at("reason");
		}
	}
	std::set<std::string> missingDrafts, missingTargets;
	std::set_difference(allDrafts.begin(), allDrafts.end(), verifiedDrafts.begin(), verifiedDrafts.end(), std::inserter(missingDrafts, missingDrafts.end()));
	std::set_difference(allTargets.begin(), allTargets.end(), verifiedTargets.begin(), verifiedTargets.end(), std::inserter(missingTargets, missingTargets.end()));
	const auto excludedDrafts = fixture.value("sourceExceptionDrafts", std::set<std::string>());
	const auto excludedTargets = fixture.value("sourceExceptionTargets", std::set<std::string>());
	need(allDrafts.size() == 1795 && allTargets.size() == 2012, "Current source recipe/output coverage is incomplete");
	const bool complete = unexplained.empty() && missingDrafts == excludedDrafts && missingTargets == excludedTargets;
	report = {{"total", catalog.size()}, {"verified", audit.at("verified")}, {"sourceFingerprint", audit.at("sourceFingerprint")}, {"unexplained", unexplained},
		{"allDrafts", allDrafts.size()}, {"allTargets", allTargets.size()}, {"verifiedDrafts", verifiedDrafts.size()},
		{"verifiedTargets", verifiedTargets.size()}, {"missingDrafts", missingDrafts}, {"missingTargets", missingTargets},
		{"semanticHashDigest", str(Crypto::SHA256Hash(String(semanticHashes.dump().c_str())))}, {"complete", complete}};
	need(fixture.value("diagnostic", false) || complete, "Complete catalog coverage gate failed; see unexplained rejections/source exceptions");
}

void exerciseRollback(ZoneServer* server, CreatureObject* player, const String& id, Json& report, Json& allRollbackIds) {
	auto inventory = player->getSlottedObject("inventory");
	const auto before = inventoryIds(inventory);
	const int originalLimit = inventory->getContainerVolumeLimit();
	inventory->setContainerVolumeLimit(0);
	String error;
	const bool refused = !PerfectCraftedItemFactory::grant(player, id, error);
	inventory->setContainerVolumeLimit(originalLimit);
	need(refused && inventoryIds(inventory) == before, "Inventory rejection altered inventory or granted a crate");
	Json rollbackIds = Json::array();
	for (int phase = 0; phase < 2; ++phase) {
		std::vector<ManagedReference<SceneObject*> > staged;
		bool injected = false;
		try {
			PerfectCraftingContext context(server, true);
			auto prototype = PerfectCraftedItemFactory::createForAudit(id, context, error); need(prototype != nullptr, str(error));
			String type; auto crate = prototype->createFactoryCrate(1000, type, true, true); context.ownGraph(crate);
			need(crate != nullptr, "Rollback fixture could not create crate");
			staged = context.trackedObjectsForTesting();
			if (phase == 0) {
				// Exercise caught cleanup with a genuinely partial persistent journal.
				ObjectManager::instance()->persistObject(staged.front(), 2, "sceneobjects");
				need(staged.front()->isPersistent(), "Partial persistence fixture was not persistent");
			} else {
				context.persistGraph(crate);
				need(crate->isPersistent() && prototype->isPersistent(), "Full staged graph not persistent before fault");
			}
			injected = true;
			throw std::runtime_error("Acceptance injected failure before inventory attachment");
		} catch (const std::runtime_error&) { need(injected, "Rollback setup failed before injected fault"); }
		need(!staged.empty(), "Rollback test retained no journal evidence");
		for (auto object : staged) {
			need(object->_isMarkedForDeletion() && !object->isPersistent(), "Caught failure retained a persistent staged allocation");
			rollbackIds.push_back(object->getObjectID());
		}
		need(inventoryIds(inventory) == before, "Staging rollback touched preexisting inventory");
	}
	for (auto id : before) need(!server->getObject(id)->_isMarkedForDeletion(), "Rollback deleted a preexisting inventory item");
	for (const auto& value : rollbackIds) allRollbackIds.push_back(value);
	write("log/perfect-factory-rollback-retained.json", allRollbackIds);
	report = {{"inventoryRefusedWithoutMutation", true}, {"partialPersistentJournalRemoved", true},
		{"fullPersistentGraphRemovedBeforeAttachment", true}, {"checkedAllocations", rollbackIds.size()}};
}
}

void runPerfectFactoryRuntimeAcceptance(ZoneServer* server, const String& fixturePath) {
	Json evidence; evidence["passed"] = false;
	std::string output = "log/perfect-factory-runtime-acceptance.json";
	try {
		need(ConfigManager::instance()->getDBHost() == "audit-db", "Acceptance refuses any live SQL endpoint");
		auto fixture = read(str(fixturePath));
		need(fixture.value("disposable", false) && fixture.value("galaxy", 0) == 4 && server->getGalaxyID() == 4,
			"Acceptance requires explicit disposable galaxy4 fixture");
		output = fixture.value("output", output); const auto phase = fixture.value("phase", std::string("create"));
		evidence["phase"] = phase;
		auto player = server->getObject(fixture.at("playerId").get<uint64>()).castTo<CreatureObject*>();
		need(player != nullptr && player->isPlayerCreature(), "Disposable scratch player unavailable");
		Locker lock(player); auto inventory = player->getSlottedObject("inventory"); need(inventory != nullptr, "Scratch inventory absent");
		auto catalog = products(String(fixture.at("catalogPath").get<std::string>().c_str()));
		auditCoverage(catalog, fixture, evidence["catalogCoverage"]);
		if (phase == "reload") {
			auto creation = read("log/perfect-factory-runtime-create.json");
			need(creation.at("catalogCoverage").at("sourceFingerprint") == evidence["catalogCoverage"]["sourceFingerprint"], "Reload content differs from creation acceptance");
			need(creation.at("catalogCoverage").at("semanticHashDigest") == evidence["catalogCoverage"]["semanticHashDigest"],
				"Fresh generation changed semantic hashes/batch identity after cold restart");
			need(fixture.value("diagnostic", false) || creation.value("passed", false), "Creation phase did not pass the complete acceptance gate");
			auto retained = read("log/perfect-factory-runtime-retained.json");
			for (const auto& item : retained) {
				auto object = server->getObject(item.at("id").get<uint64>());
				need(object != nullptr && object->isTangibleObject(), "Retained real object missing after cold reload");
				need(str(digest(object)) == item.at("digest").get<std::string>(), "Concrete object/children changed after cold reload");
				need(str(cast<TangibleObject*>(object.get())->getSerialNumber()) == item.at("serial").get<std::string>(), "Serial changed on reload");
				if (item.contains("count")) need(cast<FactoryCrate*>(object.get())->getUseCount() == item["count"].get<int>(), "Crate count changed on reload");
			}
			auto manufactured = read("log/perfect-factory-manufacturing-retained.json");
			auto produced = server->getObject(manufactured.at("crateId").get<uint64>()).castTo<FactoryCrate*>();
			need(produced != nullptr && produced->getUseCount() == 2 && produced->isPersistent() &&
				str(digest(produced)) == manufactured.at("outputDigest").get<std::string>(), "Ordinary factory output failed cold reload");
			evidence["ordinaryFactoryColdReload"] = true;
			for (const auto& id : manufactured.at("consumedIds"))
				need(server->getObject(id.get<uint64>()) == nullptr, "Consumed factory ingredient survived cold reload");
			auto rollback = read("log/perfect-factory-rollback-retained.json");
			for (const auto& id : rollback) need(server->getObject(id.get<uint64>()) == nullptr, "A failed staged object survived cold restart");
			evidence["rollbackAbsentAfterColdReload"] = true;
			auto frs = read("log/frs-gm-runtime-retained.json");
			auto target = server->getObject(frs.at("targetId").get<uint64>()).castTo<CreatureObject*>();
			need(target != nullptr, "FRS target missing on cold reload"); String error; FrsGmEditorState state;
			auto gm = frsActor(server, frs.at("actorId").get<uint64>(), frs.at("actorAdminLevel").get<int>());
			// Normal membership verification is separate from the XP/debt check,
			// which may later demote the deliberately below-minimum GM rank.
			server->getFrsManager()->validatePlayerData(target);
			const bool readOk = FrsGmEditor::readState(gm, target, state, error); need(readOk, str(error));
			need(state.council == frs.at("council").get<int>() && state.rank == frs.at("rank").get<int>() &&
				state.xp == frs.at("xp").get<int>() && state.jediState == frs.at("jediState").get<int>() &&
				state.faction == frs.at("faction").get<uint32>() && state.factionStatus == frs.at("factionStatus").get<int>(), "FRS exact GM state changed on cold reload");
			need(playerSkills(target) == frs.at("skills") && playerPermissions(target) == frs.at("permissions"),
				"FRS skills/permissions changed after cold reload and normal membership verification");
			auto roster = server->getFrsManager()->getFrsRank(state.council, state.rank);
			{ Locker lock(roster); need(roster->isOnPlayerList(target->getObjectID()), "FRS membership lost on cold reload"); }
			evidence["frsColdReload"] = true;
			evidence["reloadedObjects"] = retained.size();
			evidence["passed"] = evidence["catalogCoverage"]["complete"].get<bool>() && creation.value("passed", false) && !fixture.value("diagnostic", false);
		} else {
			std::set<std::string> coverage, ids;
			for (const auto& pair : catalog) {
				const auto& p = pair.second; if (!PerfectCraftedItemFactory::isAvailable(p.id)) continue;
				bool choose = coverage.insert("kind:" + str(p.kind)).second;
				for (const auto& prof : p.professions) choose = coverage.insert("profession:" + str(prof)).second || choose;
				for (const char* special : {"/deed/pet_deed/", "/food/", "/medicine/", "/component/armor/", "/lightsaber/", "/crafting/station/", "frn_all_light"})
					if (str(p.path).find(special) != std::string::npos) choose = coverage.insert(special).second || choose;
				if (!p.reviveProfile.isEmpty()) choose = coverage.insert("revive:" + str(p.reviveProfile)).second || choose;
				for (const char* module : {"struct_maint_module_3.iff", "playback_module.iff", "harvest_module.iff"})
					if (p.path == String("object/tangible/component/droid/") + module) choose = coverage.insert(module).second || choose;
				if (choose) ids.insert(pair.first);
			}
			if (fixture.contains("representativeIds")) for (const auto& id : fixture["representativeIds"]) {
				const auto key = id.get<std::string>();
				if (fixture.value("diagnostic", false) && (catalog.count(key) == 0 || !PerfectCraftedItemFactory::isAvailable(catalog.at(key).id))) continue;
				need(catalog.count(key) != 0 && PerfectCraftedItemFactory::isAvailable(catalog.at(key).id), "Required representative unavailable: " + key);
				ids.insert(key);
			}
			need(!ids.empty(), "No verified products to test");
			Json retained = Json::array(); std::set<std::string> retainedGroups;
			for (const auto& id : ids) exerciseProduct(server, player, catalog.at(id), evidence["products"][id], retained, retainedGroups);
			factoryRefill(server, player, catalog, evidence["factory"]);
			exerciseFrs(server, player, fixture, evidence["frs"]);
			Json rollbackIds = Json::array();
			exerciseRollback(server, player, catalog.at(*ids.begin()).id, evidence["rollback"]["basic"], rollbackIds);
			const String droidId(fixture.at("specialRollbackId").get<std::string>().c_str());
			if (!fixture.value("diagnostic", false) || PerfectCraftedItemFactory::isAvailable(droidId))
				exerciseRollback(server, player, droidId, evidence["rollback"]["droid"], rollbackIds);
			// A stale callback must fail before creating or attaching inventory.
			auto before = inventoryIds(inventory); String error;
			need(!PerfectCraftedItemFactory::grant(player, catalog.at(*ids.begin()).id, error,
				PerfectCraftedItemFactory::getCatalogGeneration() + 1), "Stale-generation grant accepted");
			need(inventoryIds(inventory) == before, "Rejected grant altered existing inventory");
			write("log/perfect-factory-runtime-retained.json", retained);
			evidence["coverage"] = coverage; evidence["retainedForColdReload"] = retained.size();
			evidence["staleGrantPreservedInventory"] = true;
			evidence["passed"] = evidence["catalogCoverage"]["complete"].get<bool>() && !fixture.value("diagnostic", false);
		}
	} catch (const std::exception& error) { evidence["error"] = error.what(); }
	catch (const Exception& error) {
		evidence["error"] = str(error.getMessage());
		StackTrace trace(error.getStackTrace());
		evidence["nativeStack"] = str(trace.toStringData()).substr(0, 16384);
	}
	catch (...) { evidence["error"] = "Unexpected native acceptance failure"; }
	try {
		write(output, evidence);
		if (evidence.value("phase", std::string()) == "create") write("log/perfect-factory-runtime-create.json", evidence);
	} catch (...) { Logger::console.error("Could not write perfect factory acceptance evidence"); }
	Logger::console.info(true) << "Perfect factory runtime acceptance: " << (evidence["passed"].get<bool>() ? "PASS" : "FAIL");
}
