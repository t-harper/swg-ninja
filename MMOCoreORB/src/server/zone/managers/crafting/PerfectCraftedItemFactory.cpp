#include "PerfectCraftedItemFactory.h"
#include "PerfectCraftingSpecialAdapter.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "server/zone/managers/crafting/ComponentMap.h"
#include "server/zone/managers/crafting/schematicmap/SchematicMap.h"
#include "server/zone/managers/object/ObjectManager.h"
#include "server/zone/objects/factorycrate/FactoryCrate.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ResourceSlot.h"
#include "server/zone/objects/tangible/deed/droid/DroidDeed.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/wearables/WearableContainerObject.h"
#include "server/zone/objects/tangible/powerup/PowerupObject.h"
#include "server/zone/objects/tangible/pharmaceutical/RevivePack.h"
#ifdef COMPILE_CORE3_TESTS
#include "tests/PerfectFactoryRuntimeAcceptance.h"
#endif
#include <cstdlib>
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "templates/customization/AssetCustomizationManagerTemplate.h"
#include "templates/params/RangedIntCustomizationVariable.h"
#include "system/security/Crypto.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <fstream>
#include <memory>
#include <limits>
#include <mutex>
#include <stdexcept>

namespace {
using Json = nlohmann::json;
thread_local Json* auditDiagnostics = nullptr;
struct AuditDiagnosticScope {
	Json* previous;
	explicit AuditDiagnosticScope(Json& output) : previous(auditDiagnostics) { auditDiagnostics = &output; }
	~AuditDiagnosticScope() { auditDiagnostics = previous; }
};
std::string diagnosticValue(const Json& value) {
	if (value.is_object()) return "object(" + std::to_string(value.size()) + ")";
	if (value.is_array()) return "array(" + std::to_string(value.size()) + ")";
	std::string result = value.dump();
	if (result.size() > 256) result = result.substr(0, 256) + "...";
	return result;
}
void appendDifferences(const Json& before, const Json& after, Json& differences, const std::string& path = "") {
	if (differences.size() >= 32 || before == after) return;
	if (before.is_object() && after.is_object()) {
		std::set<std::string> keys;
		for (auto it = before.begin(); it != before.end(); ++it) keys.insert(it.key());
		for (auto it = after.begin(); it != after.end(); ++it) keys.insert(it.key());
		for (const auto& key : keys) {
			if (differences.size() >= 32) break;
			if (before.contains(key) && after.contains(key)) appendDifferences(before[key], after[key], differences, path + "/" + key);
			else differences.push_back({{"path", (path + "/" + key).substr(0, 1024)},
				{"before", before.contains(key) ? diagnosticValue(before[key]) : "<missing>"},
				{"after", after.contains(key) ? diagnosticValue(after[key]) : "<missing>"}});
		}
	} else if (before.is_array() && after.is_array() && before.size() == after.size()) {
		for (size_t i = 0; i < before.size() && differences.size() < 32; ++i)
			appendDifferences(before[i], after[i], differences, path + "/" + std::to_string(i));
	} else differences.push_back({{"path", path.substr(0, 1024)}, {"before", diagnosticValue(before)}, {"after", diagnosticValue(after)}});
}
Json differences(const Json& before, const Json& after) {
	Json result = Json::array(); appendDifferences(before, after, result); return result;
}
std::string key(const String& value) { return value.toCharArray(); }
void require(bool valid, const std::string& error) { if (!valid) throw std::runtime_error(error); }
struct Entry {
	PerfectCraftingRecipe recipe;
	String semanticHash, rejection;
	bool verified = false;
};
struct Registry {
	std::map<std::string, Entry> entries;
	String revision, sourceFingerprint;
	uint64 generation = 0;
};
std::mutex registryMutex;
std::shared_ptr<const Registry> registry;
std::atomic<uint64> nextGeneration{0};
std::atomic<bool> auditRunning{false};
std::atomic<unsigned> activeGrants{0};
std::set<uint64> recipients;
std::shared_ptr<const Registry> snapshot() {
	std::lock_guard<std::mutex> lock(registryMutex);
	return registry;
}

// Enumerate ownership that is not represented by ordinary containment as well.
std::vector<SceneObject*> children(SceneObject* object) {
	std::vector<SceneObject*> result;
	for (int i = 0; i < object->getSlottedObjectsSize(); ++i) {
		auto child = object->getSlottedObject(i);
		if (child != nullptr) result.push_back(child);
	}
	for (int i = 0; i < object->getContainerObjectsSize(); ++i) {
		auto child = object->getContainerObject(i);
		if (child != nullptr) result.push_back(child);
	}
	auto worldChildren = object->getChildObjects();
	for (int i = 0; i < worldChildren->size(); ++i)
		if (worldChildren->get(i) != nullptr) result.push_back(worldChildren->get(i));
	if (object->isDroidDeedObject()) {
		auto deed = cast<DroidDeed*>(object);
		auto modules = deed->getModules();
		HashTableIterator<String, ManagedReference<DroidComponent*> > it = modules->iterator();
		while (it.hasNext()) { auto module = it.getNextValue(); if (module != nullptr) result.push_back(module.get()); }
	}
	return result;
}
void collectGraph(SceneObject* object, std::set<SceneObject*>& seen) {
	if (object == nullptr || !seen.insert(object).second) return;
	for (auto child : children(object)) collectGraph(child, seen);
}

// Effective gameplay values are serialized by the actual concrete IDL classes.
// Spatial, ownership and persistence metadata is excluded; owned references are
// replaced by independent child semantics, never by object IDs.
void validateSemanticNumbers(const Json& value, size_t depth = 0, const std::string& path = "") {
	require(depth <= PerfectCraftingContext::MAX_DEPTH * 3, "Gameplay data nesting exceeds ceiling");
	if (value.is_number_float() && !std::isfinite(value.get<double>())) {
		if (auditDiagnostics != nullptr) (*auditDiagnostics)["nonfinite"] = {{"path", path.substr(0, 2048)},
			{"value", std::isnan(value.get<double>()) ? "NaN" : "Infinity"}};
		require(false, "Nonfinite concrete gameplay value");
	}
	if (value.is_object()) {
		for (auto it = value.begin(); it != value.end(); ++it) validateSemanticNumbers(it.value(), depth + 1, path + "/" + it.key());
	} else if (value.is_array()) {
		for (size_t i = 0; i < value.size(); ++i) validateSemanticNumbers(value[i], depth + 1, path + "/" + std::to_string(i));
	}
}
Json gameplay(SceneObject* object, size_t depth = 0, size_t* semanticBytes = nullptr, bool expanded = false) {
	size_t localBytes = 0;
	if (semanticBytes == nullptr) semanticBytes = &localBytes;
	require(depth <= PerfectCraftingContext::MAX_DEPTH * 3, "semantic graph too deep");
	Json value;
	object->writeJSON(value);
	value.erase("ManagedObject"); value.erase("DistributedObject"); value.erase("TreeEntry");
	if (value.contains("SceneObject")) {
		auto& scene = value["SceneObject"];
		// DataObjectComponent::parent is the owning SceneObject backreference;
		// clones correctly get new IDs while component gameplay state is retained.
		if (scene.contains("dataObjectComponent") && scene["dataObjectComponent"].is_object())
			scene["dataObjectComponent"].erase("parent");
		for (const char* field : {"zone", "direction", "movementCounter", "objectName", "customName",
			"childObjects", "slottedObjects", "containerObjects", "originalObjectID", "objectActiveSessions",
			"containerPermissions", "containmentType", "forceSend"}) scene.erase(field);
	}
	if (value.contains("TangibleObject")) {
		auto& tano = value["TangibleObject"];
		// AutoDeltaSet iteration order can change during binary roundtrip.
		// Membership is the visible-component state; preserve every CRC.
		if (tano.contains("visibleComponents") && tano["visibleComponents"].is_object() &&
			tano["visibleComponents"].contains("set") && tano["visibleComponents"]["set"].is_array()) {
			auto& members = tano["visibleComponents"]["set"];
			std::sort(members.begin(), members.end());
		}
		for (const char* field : {"craftersName", "craftersID", "objectSerial", "conditionDamage",
			"unmitigatedDamage", "defenderList", "activeAreas"}) tano.erase(field);
	}
	if (value.contains("DroidDeed")) value["DroidDeed"].erase("modules");
	if (value.contains("LightObject")) {
		auto& light = value["LightObject"];
		// A stored, unburnt light uses lifespanSeconds. Its constructor timestamp
		// is inert: first placement starts a fresh timer in updateLifespan().
		// Keep active expiry timestamps and all meaningful duration/state fields.
		if (light.value("firstUpdate", false) && !light.value("burntOut", true)) {
			light.erase("creationMili");
			light.erase("lifespan");
		}
	}
	std::vector<std::pair<std::string, SceneObject*> > edges;
	VectorMap<String, ManagedReference<SceneObject*> > slots;
	object->getSlottedObjects(slots);
	for (int i = 0; i < slots.size(); ++i) {
		auto child = slots.elementAt(i).getValue();
		if (child != nullptr) edges.emplace_back("slot:" + key(slots.elementAt(i).getKey()), child.get());
	}
	for (int i = 0; i < object->getContainerObjectsSize(); ++i)
		edges.emplace_back("container", object->getContainerObject(i));
	auto worldChildren = object->getChildObjects();
	for (int i = 0; i < worldChildren->size(); ++i) edges.emplace_back("child", worldChildren->get(i));
	if (object->isDroidDeedObject()) {
		auto modules = cast<DroidDeed*>(object)->getModules();
		HashTableIterator<String, ManagedReference<DroidComponent*> > it = modules->iterator();
		while (it.hasNext()) {
			String name; ManagedReference<DroidComponent*> module;
			it.getNextKeyAndValue(name, module);
			if (module != nullptr) edges.emplace_back("module:" + key(name), module.get());
		}
	}
	std::vector<std::pair<std::string, std::string> > descendants;
	std::vector<std::pair<std::string, Json> > expandedChildren;
	for (const auto& edge : edges) {
		if (edge.second == nullptr) continue;
		auto semantic = gameplay(edge.second, depth + 1, semanticBytes, expanded);
		if (expanded) expandedChildren.emplace_back(edge.first, std::move(semantic));
		else descendants.emplace_back(edge.first, key(Crypto::SHA256Hash(String(semantic.dump().c_str()))));
	}
	std::sort(descendants.begin(), descendants.end());
	if (expanded) {
		std::sort(expandedChildren.begin(), expandedChildren.end(), [](const auto& a, const auto& b) {
			return a.first == b.first ? a.second.dump() < b.second.dump() : a.first < b.first;
		});
		value["ownedChildren"] = expandedChildren;
	} else value["ownedChildren"] = descendants;
	validateSemanticNumbers(value, 0, object->getObjectTemplate() == nullptr ? "<no-template>" : key(object->getObjectTemplate()->getFullTemplateString()));
	*semanticBytes += value.dump().size();
	require(*semanticBytes <= PerfectCraftingContext::MAX_SEMANTIC_BYTES, "Gameplay graph exceeds semantic byte ceiling");
	return value;
}

std::shared_ptr<Registry> loadRegistry(const String& path) {
	Lua lua;
	lua.init();
	require(lua.runFile(path), "Cannot read perfect factory catalog");
	LuaObject table = lua.getGlobalObject("PerfectFactoryCatalog");
	require(table.isValidTable() && table.getIntField("schemaVersion") == 1, "Invalid catalog schema");
	auto result = std::make_shared<Registry>();
	result->revision = table.getStringField("qualityRevision");
	result->sourceFingerprint = table.getStringField("sourceFingerprint");
	require(!result->revision.isEmpty() && !result->sourceFingerprint.isEmpty(), "Missing catalog fingerprint");
	LuaObject entries = table.getObjectField("entries");
	require(entries.isValidTable(), "Missing catalog entries");
	for (int i = 1; i <= entries.getTableSize(); ++i) {
		LuaObject source = entries.getObjectAt(i);
		require(source.isValidTable(), "Invalid catalog entry");
		PerfectCraftingRecipe recipe;
		recipe.id = source.getStringField("id"); recipe.kind = source.getStringField("kind");
		recipe.draftPath = source.getStringField("draftPath"); recipe.targetTemplate = source.getStringField("targetTemplate");
		recipe.variantIndex = source.getIntField("variantIndex"); recipe.variantId = source.getStringField("variantId");
		recipe.reviveProfile = source.getStringField("reviveProfile");
		recipe.powerupPrimaryIndex = source.getIntField("powerupPrimaryIndex", -1);
		LuaObject secondaryIndices = source.getObjectField("powerupSecondaryIndices");
		if (secondaryIndices.isValidTable())
			for (int k = 1; k <= secondaryIndices.getTableSize(); ++k) recipe.powerupSecondaryIndices.push_back(secondaryIndices.getIntAt(k));
		secondaryIndices.pop();
		recipe.sourceProfile = source.getStringField("sourceProfile"); recipe.qualitySignature = source.getStringField("qualitySignature");
		recipe.label = source.getStringField("label"); recipe.category = source.getStringField("category");
		recipe.availability = source.getStringField("availability");
		LuaObject provenance = source.getObjectField("provenance");
		if (provenance.isValidTable()) recipe.sourceSupport = provenance.getStringField("sourceSupport");
		provenance.pop();
		recipe.expectedFactoryEligible = source.getBooleanField("expectedFactoryEligible");
		const std::string id = key(recipe.id);
		require(id.size() > 2 && (id.substr(0, 2) == "r_" || id.substr(0, 2) == "i_") &&
			id.find_first_not_of("0123456789abcdef", 2) == std::string::npos, "Invalid compact catalog id");
		require(!recipe.targetTemplate.isEmpty() && !recipe.qualitySignature.isEmpty(), "Missing recipe target/signature");
		LuaObject professions = source.getObjectField("professions");
		for (int j = 1; j <= professions.getTableSize(); ++j) recipe.professions.push_back(professions.getStringAt(j));
		professions.pop();
		LuaObject choices = source.getObjectField("ingredientChoices");
		std::set<int> slots;
		for (int j = 1; j <= choices.getTableSize(); ++j) {
			LuaObject choice = choices.getObjectAt(j);
			PerfectIngredientChoice item;
			item.slotIndex = choice.getIntField("slotIndex"); item.quantity = choice.getIntField("quantity");
			item.omit = choice.getBooleanField("omit"); item.childId = choice.getStringField("childId");
			require(item.slotIndex >= 0 && slots.insert(item.slotIndex).second, "Duplicate/negative ingredient slot");
			require(item.omit ? item.childId.isEmpty() : !item.childId.isEmpty(), "Invalid omitted ingredient");
			recipe.ingredientChoices.push_back(item); choice.pop();
		}
		choices.pop(); source.pop();
		Entry entry; entry.recipe = recipe;
		require(result->entries.emplace(id, entry).second, "Duplicate catalog id");
	}
	entries.pop(); table.pop();
	require(!result->entries.empty(), "Empty perfect factory catalog");
	return result;
}

struct PlanCost { uint64 objects = 0; size_t depth = 0; };
PlanCost plan(const Registry& data, const std::string& id, std::set<std::string>& stack,
	std::map<std::string, PlanCost>& memo) {
	auto cached = memo.find(id); if (cached != memo.end()) return cached->second;
	auto entry = data.entries.find(id); require(entry != data.entries.end(), "Unknown dependency " + id);
	require(stack.size() < PerfectCraftingContext::MAX_DEPTH && stack.insert(id).second, "Recipe cycle/depth " + id);
	PlanCost cost; cost.objects = 4; cost.depth = 1;
	for (const auto& choice : entry->second.recipe.ingredientChoices) {
		if (choice.omit) continue;
		require(choice.quantity > 0, "Nonpositive ingredient quantity");
		auto sub = plan(data, key(choice.childId), stack, memo);
		require(sub.objects <= PerfectCraftingContext::MAX_OBJECTS / static_cast<uint64>(choice.quantity), "Recipe expansion overflow");
		uint64 extra = sub.objects * choice.quantity;
		require(cost.objects <= PerfectCraftingContext::MAX_OBJECTS - extra, "Recipe exceeds allocation ceiling");
		cost.objects += extra;
		cost.depth = std::max(cost.depth, sub.depth + 1);
	}
	stack.erase(id); memo.emplace(id, cost); return cost;
}

TangibleObject* build(const Registry& data, const std::string& id, PerfectCraftingContext& context, Json* identityOutput = nullptr) {
	context.checkpoint();
	auto cached = context.archetypes.find(id);
	if (cached != context.archetypes.end()) return cached->second;
	auto found = data.entries.find(id); require(found != data.entries.end(), "Unknown recipe " + id);
	const auto& recipe = found->second.recipe;
	auto object = context.create(recipe.targetTemplate);
	require(object != nullptr && object->isTangibleObject(), "Non-tangible output " + id);
	auto prototype = cast<TangibleObject*>(object);
	Locker lock(prototype);
	// Normal CraftingSession creates class-specific children before assembly.
	// Weapon/station overrides create their slotted inventories even zoneless.
	prototype->createChildObjects();
	context.ownGraph(prototype);
	Json identity;
	identity["revision"] = key(data.revision);
	identity["recipe"] = key(recipe.qualitySignature);
	identity["target"] = key(recipe.targetTemplate);
	identity["variant"] = key(recipe.variantId);
	identity["profile"] = key(recipe.sourceProfile);
	identity["sourceSupport"] = key(recipe.sourceSupport);
	identity["reviveProfile"] = key(recipe.reviveProfile);
	identity["powerupPrimaryIndex"] = recipe.powerupPrimaryIndex;
	identity["powerupSecondaryIndices"] = recipe.powerupSecondaryIndices;
	String special, error;
	if (recipe.kind == "recipe") {
		require(recipe.sourceProfile == "recipe.normal100", "Unsupported recipe quality policy");
		auto draftObject = context.create(recipe.draftPath);
		auto draft = dynamic_cast<DraftSchematic*>(draftObject);
		require(draft != nullptr && draft->isValidDraftSchematic(), "Invalid runtime draft " + id);
		auto templ = draft->getDraftSchematicTemplate();
		uint32 target = draft->getTanoCRC();
		if (recipe.variantIndex >= 0) {
			require(recipe.variantIndex < templ->getTemplateListSize(), "Invalid additional-template index");
			target = templ->getTemplate(recipe.variantIndex).replaceAll("shared_", "").hashCode();
		}
		require(target == recipe.targetTemplate.hashCode(), "Draft/output mismatch " + id);
		auto schematic = draft->createManufactureSchematic().castTo<ManufactureSchematic*>();
		context.own(schematic);
		require(schematic != nullptr && schematic->initializeGeneratedIngredientSlots(), "Cannot initialize generated slots");
		require(schematic->allowFactoryRun() == recipe.expectedFactoryEligible, "Catalog/runtime factory eligibility mismatch");
		require(!prototype->isShipComponentRepairKit(), "Ship repair kit has no normal component-slot mapping provider");
		auto values = schematic->getCraftingValues();
		values->setManufactureSchematic(schematic);
		std::map<int, const PerfectIngredientChoice*> choices;
		for (const auto& choice : recipe.ingredientChoices) {
			require(choice.slotIndex < schematic->getSlotCount(), "Catalog ingredient index out of range");
			choices.emplace(choice.slotIndex, &choice);
		}
		for (int i = 0; i < schematic->getSlotCount(); ++i) {
			auto slot = schematic->getSlot(i);
			require(slot != nullptr && slot->getQuantityNeeded() > 0, "Invalid runtime ingredient slot");
			if (slot->isResourceSlot()) {
				require(choices.count(i) == 0, "Component choice for resource slot");
				cast<ResourceSlot*>(slot)->setGeneratedQuality();
				continue;
			}
			auto selection = choices.find(i);
			require(selection != choices.end(), "Missing explicit component choice " + id + ":" + std::to_string(i));
			const auto& choice = *selection->second;
			if (choice.omit) { require(slot->isOptional(), "Required ingredient omitted"); continue; }
			require(choice.quantity == slot->getQuantityNeeded(), "Ingredient quantity differs from runtime draft");
			auto input = build(data, key(choice.childId), context);
			identity["ingredients"].push_back({{"slot", i}, {"quantity", choice.quantity},
				{"semantic", key(context.semanticSignatures.at(key(choice.childId)))}});
			auto satchel = prototype->getCraftedComponentsSatchel(true);
			require(satchel != nullptr, "Cannot create generated ingredient satchel");
			context.ownGraph(satchel);
			for (int unit = 0; unit < choice.quantity; ++unit) {
				auto clone = cast<TangibleObject*>(context.clone(input));
				require(clone != nullptr, "Cannot clone ingredient unit");
				clone->setUseCount(0, false);
				require(satchel->transferObject(clone, -1, false), "Cannot retain generated ingredient");
				auto componentSlot = cast<ComponentSlot*>(slot);
				if (!componentSlot->addGeneratedIngredient(clone)) {
					if (auditDiagnostics != nullptr) {
						auto runtimeSlot = draft->getDraftSlot(i);
						auto loaded = clone->getObjectTemplate();
						auto previous = componentSlot->getPrototype();
						(*auditDiagnostics)["ingredientFailure"] = {{"recipeId", id}, {"slotIndex", i},
							{"childId", key(choice.childId)}, {"targetTemplate", key(data.entries.at(key(choice.childId)).recipe.targetTemplate)},
							{"loadedTemplate", loaded == nullptr ? "" : key(loaded->getFullTemplateString())},
							{"runtimePredicate", key(runtimeSlot->getResourceType())}, {"slotType", runtimeSlot->getSlotType()},
							{"quantity", slot->getQuantityNeeded()}, {"filledQuantity", slot->getSlotQuantity()}, {"unitIndex", unit},
							{"useCount", clone->getUseCount()}, {"persistent", clone->isPersistent()},
							{"serialPresent", !clone->getSerialNumber().isEmpty()},
							{"derivedFrom", loaded != nullptr && loaded->isDerivedFrom(runtimeSlot->getResourceType())},
							{"requiresIdentical", slot->requiresIdentical()},
							{"serialMatches", previous == nullptr || previous->getSerialNumber() == clone->getSerialNumber()}};
					}
					require(false, "Generated ingredient incompatible with runtime slot");
				}
			}
			require(slot->isFull(), "Generated component slot not full");
		}
		if (schematic->getLabratory() == DraftSchematicObjectTemplate::GENETIC_LAB) {
			bool finalized = PerfectCraftingSpecialAdapter::finalizeGenetic(recipe, prototype, schematic, context, special, error);
			require(finalized, id + ": " + key(error));
		} else {
			require(context.server->getCraftingManager()->setPerfectCraftingValues(prototype, schematic), "Unsupported crafting laboratory");
			// Prevent first-update socket RNG/player dependence. Only socket-capable
			// recipes receive the legitimate maximum; normal crafting is unchanged.
			if (prototype->isWearableObject() && values->hasExperimentalAttribute("sockets") && values->getCurrentValue("sockets") >= 0)
				cast<WearableObject*>(prototype)->setMaxSockets(WearableObject::MAXSOCKETS);
			if (prototype->isWearableContainerObject() && values->hasExperimentalAttribute("sockets") && values->getCurrentValue("sockets") >= 0)
				cast<WearableContainerObject*>(prototype)->setMaxSockets(WearableContainerObject::MAXSOCKETS);
			if (auto powerup = dynamic_cast<PowerupObject*>(prototype)) {
				Vector<int> secondary;
				for (int index : recipe.powerupSecondaryIndices) secondary.add(index);
				require(powerup->setPerfectCraftingValues(values, recipe.powerupPrimaryIndex, &secondary), "Invalid normal powerup selection");
			} else if (auto revive = dynamic_cast<RevivePack*>(prototype)) {
				require(recipe.reviveProfile == "healing-max" || recipe.reviveProfile == "wounds-max", "Missing or invalid normal revive split profile");
				float power = values->getCurrentValue("power");
				require(values->hasExperimentalAttribute("power") && std::isfinite(power) && power > 0 && power < static_cast<float>(std::numeric_limits<int>::max()), "Revive recipe lacks a valid normal power contribution");
				revive->setPerfectCraftingValues(values, recipe.reviveProfile == "wounds-max");
			} else {
				require(recipe.reviveProfile.isEmpty(), "Revive split profile applied to a non-revive item");
				prototype->updateCraftingValues(values, true);
			}
		}
		PerfectCraftedItemFactory::applyAssemblyHooks(prototype, draft, schematic);
		prototype->setComplexity(schematic->getComplexity());
		for (int i = 0; i < values->getTotalExperimentalAttributes(); ++i) {
			String attribute = values->getAttribute(i);
			float current = values->getCurrentValue(attribute), minimum = values->getMinValue(attribute), maximum = values->getMaxValue(attribute);
			require(std::isfinite(current) && std::isfinite(minimum) && std::isfinite(maximum) &&
				std::isfinite(values->getCurrentPercentage(attribute)) && std::isfinite(values->getMaxPercentage(attribute)), "Nonfinite crafting value");
			if (!values->isHidden(attribute))
				require(std::fabs(values->getCurrentPercentage(attribute) - values->getMaxPercentage(attribute)) <= 0.0001f, "Experimentation did not reach its normal cap");
			identity["bounds"][key(attribute)] = {minimum, maximum, values->getCurrentPercentage(attribute),
				values->getMaxPercentage(attribute), current, static_cast<float>(values->getCombineType(attribute))};
		}
	} else {
		bool initialized = PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, special, error);
		require(initialized, id + ": " + key(error));
	}
	context.ownGraph(prototype);
	identity["special"] = key(special);
	identity["gameplay"] = gameplay(prototype);
	std::string serialized = identity.dump();
	require(serialized.size() <= PerfectCraftingContext::MAX_SEMANTIC_BYTES, "Semantic record exceeds size ceiling");
	if (identityOutput != nullptr) *identityOutput = identity;
	String digest = Crypto::SHA256Hash(String(serialized.c_str()));
	String serial = "(pf1-" + digest.subString(0, 32) + ")";
	prototype->setSerialNumber(serial);
	String maker = "SWG Ninja";
	prototype->setCraftersName(maker);
	prototype->setCustomObjectName(recipe.label, false);
	context.semanticSignatures[id] = digest;
	context.archetypes[id] = prototype;
	return prototype;
}

FactoryCrate* wrap(TangibleObject* prototype, PerfectCraftingContext& context) {
	String crateType;
	auto crate = prototype->createFactoryCrate(1000, crateType, true, true);
	require(crate != nullptr, "Could not create delivery crate");
	context.ownGraph(crate);
	require(crate->isValidFactoryCrate(), "Output has unsupported direct container contents");
	crate->setUseCount(1000, false);
	require(crate->getMaxCapacity() == 1000 && crate->getUseCount() == 1000, "Delivery crate count/capacity mismatch");
	return crate;
}
}

thread_local PerfectCraftingContext* PerfectCraftingContext::active = nullptr;
PerfectCraftingContext::PerfectCraftingContext(ZoneServer* server, bool auditOnly)
	: deadline(std::chrono::steady_clock::now() + std::chrono::seconds(45)), previous(active), server(server), auditOnly(auditOnly) {
	owned.reserve(MAX_OBJECTS + 1);
	active = this;
}
PerfectCraftingContext::~PerfectCraftingContext() {
	// Roots first, recording descendants before specialized destruction clears
	// module maps. Request-owned references keep addresses alive during cleanup.
	std::set<SceneObject*> destroyed;
	std::set<SceneObject*> allocated;
	try {
		for (const auto& item : owned) allocated.insert(item.get());
		for (const auto& item : owned) {
			auto object = item.get();
			if (object == nullptr || retained.count(object)) continue;
			Locker lock(object);
			for (int i = object->getSlottedObjectsSize() - 1; i >= 0; --i)
				if (!allocated.count(object->getSlottedObject(i))) object->removeSlottedObject(i);
			for (int i = object->getContainerObjectsSize() - 1; i >= 0; --i)
				if (!allocated.count(object->getContainerObject(i))) object->removeFromContainerObjects(i);
			auto worldChildren = object->getChildObjects();
			for (int i = worldChildren->size() - 1; i >= 0; --i)
				if (!allocated.count(worldChildren->get(i))) worldChildren->remove(i);
			if (object->isDroidDeedObject()) {
				auto modules = cast<DroidDeed*>(object)->getModules();
				std::vector<String> borrowed;
				HashTableIterator<String, ManagedReference<DroidComponent*> > it = modules->iterator();
				while (it.hasNext()) {
					String name; ManagedReference<DroidComponent*> module;
					it.getNextKeyAndValue(name, module);
					if (!allocated.count(module.get())) borrowed.push_back(name);
				}
				for (const auto& name : borrowed) modules->remove(name);
			}
		}
	} catch (...) {
		// Avoid recursive destruction of potentially borrowed references after
		// an exceptional cleanup failure (including allocation exhaustion).
		Logger::console.error("Perfect factory ownership cleanup failed; manual audit required");
		active = previous;
		return;
	}
	for (auto& reference : owned) {
		auto object = reference.get();
		if (object == nullptr || retained.count(object) || destroyed.count(object)) continue;
		try {
			collectGraph(object, destroyed);
			Locker lock(object);
			object->destroyObjectFromWorld(false);
			object->destroyObjectFromDatabase(true);
		} catch (...) { Logger::console.error("Perfect factory allocation cleanup failed; audit required"); }
	}
	active = previous;
}
void PerfectCraftingContext::checkpoint() const {
	if (server != nullptr) require(!server->isServerShuttingDown() && !server->isServerOffline(), "Server is shutting down or offline");
	require(owned.size() <= objectLimit, "Generated allocation ceiling exceeded");
	require(std::chrono::steady_clock::now() < deadline, "Generated request deadline exceeded");
}
void PerfectCraftingContext::own(SceneObject* object) {
	if (object == nullptr) return;
	for (const auto& item : owned) if (item.get() == object) return;
	// ObjectManager checks the ceiling before allocating. Reserved storage makes
	// registration itself nonallocating and does not throw after construction.
	owned.push_back(object);
}
SceneObject* PerfectCraftingContext::create(const String& path) {
	checkpoint();
	auto object = server->createObject(path.hashCode(), "sceneobjects", 0);
	own(object);
	require(object != nullptr, "Unable to create " + key(path));
	return object;
}
SceneObject* PerfectCraftingContext::clone(SceneObject* object) {
	checkpoint();
	auto clone = ObjectManager::instance()->cloneObject(object, true);
	ownGraph(clone);
	std::set<SceneObject*> sourceGraph, cloneGraph;
	collectGraph(object, sourceGraph); collectGraph(clone, cloneGraph);
	for (auto child : cloneGraph) require(!sourceGraph.count(child), "Clone shares owned state with its source");
	return clone;
}
void PerfectCraftingContext::ownGraph(SceneObject* object) {
	if (object == nullptr) return;
	std::set<SceneObject*> graph;
	collectGraph(object, graph);
	for (auto item : graph) {
		bool registered = false;
		for (const auto& ownedItem : owned) if (ownedItem.get() == item) { registered = true; break; }
		require(registered, "Generated graph references an allocation not owned by this request");
	}
}
void PerfectCraftingContext::prepareReleaseGraph(SceneObject* object) {
	preparedCommit.clear();
	collectGraph(object, preparedCommit);
}
void PerfectCraftingContext::releasePreparedGraph() noexcept { retained.swap(preparedCommit); }
void PerfectCraftingContext::persistGraph(SceneObject* object) {
	std::set<SceneObject*> graph;
	collectGraph(object, graph);
	for (auto item : graph) {
		checkpoint();
		uint64 originalID = item->getObjectID();
		ObjectManager::instance()->persistObject(item, 2, "sceneobjects");
		require(item->getObjectID() == originalID, "Generated object changed namespace while persisting");
	}
	for (auto item : graph) ObjectManager::instance()->updatePersistentObject(item);
}

#ifdef COMPILE_CORE3_TESTS
String PerfectCraftedItemFactory::gameplaySignatureForTesting(SceneObject* object) {
	return Crypto::SHA256Hash(String(gameplay(object).dump().c_str()));
}
#endif

bool PerfectCraftedItemFactory::isAvailable(const String& id) {
	auto data = snapshot(); if (!data) return false;
	auto entry = data->entries.find(key(id)); return entry != data->entries.end() && entry->second.verified;
}
uint64 PerfectCraftedItemFactory::getCatalogGeneration() { auto data = snapshot(); return data ? data->generation : 0; }

bool PerfectCraftedItemFactory::grant(CreatureObject* recipient, const String& id, String& error) {
	return grant(recipient, id, error, 0);
}
bool PerfectCraftedItemFactory::grant(CreatureObject* recipient, const String& id, String& error, uint64 expectedGeneration) {
	if (recipient == nullptr) { error = "Missing recipient."; return false; }
	const uint64 recipientID = recipient->getObjectID();
	{
		std::lock_guard<std::mutex> guard(registryMutex);
		if (activeGrants.load() >= 2 || !recipients.insert(recipientID).second) { error = "A factory crate request is already running. Please try again shortly."; return false; }
		++activeGrants;
	}
	struct Admission { uint64 id; ~Admission() { std::lock_guard<std::mutex> guard(registryMutex); recipients.erase(id); --activeGrants; } } admission{recipientID};
	try {
		auto data = snapshot(); require(data != nullptr, "Factory catalog validation is pending.");
		require(expectedGeneration == 0 || data->generation == expectedGeneration, "Factory catalog changed; please reopen the terminal.");
		auto entry = data->entries.find(key(id));
		require(entry != data->entries.end() && entry->second.verified, "This factory product is not currently verified.");
		PerfectCraftingContext context(recipient->getZoneServer());
		context.qualityRevision = data->revision;
		std::set<std::string> stack; std::map<std::string, PlanCost> memo;
		plan(*data, key(id), stack, memo);
		auto prototype = build(*data, key(id), context);
		require(context.semanticSignatures.at(key(id)) == entry->second.semanticHash, "Factory product changed since validation.");
		auto crate = wrap(prototype, context);
		auto inventory = recipient->getSlottedObject("inventory");
		require(inventory != nullptr, "Missing inventory.");
		Locker lock(inventory, recipient);
		String reason;
		require(!inventory->isContainerFullRecursive() && inventory->canAddObject(crate, -1, reason) == 0, "Your inventory cannot hold this factory crate.");
		// Hold publication lock through attachment so a dialog cannot commit against
		// a catalog invalidated between its generation check and transfer.
		std::unique_lock<std::mutex> publicationGuard(registryMutex);
		require(registry == data, "Factory catalog changed; please reopen the terminal.");
		context.checkpoint();
		context.prepareReleaseGraph(crate);
		context.persistGraph(crate);
		require(inventory->transferObject(crate, -1, false), "Failed to transfer the factory crate.");
		// Ownership commits at attachment. A notification failure must not revoke
		// an already delivered object and cannot delete preexisting inventory.
		context.releasePreparedGraph();
		publicationGuard.unlock();
		try { inventory->broadcastObject(crate, true); } catch (...) { }
		return true;
	} catch (const std::exception& failure) { error = failure.what(); }
	catch (const Exception& failure) { error = failure.getMessage(); }
	catch (...) { error = "Factory crate generation failed."; }
	return false;
}

TangibleObject* PerfectCraftedItemFactory::createForAudit(const String& id, PerfectCraftingContext& context, String& error) {
	try {
		require(context.auditOnly && PerfectCraftingContext::current() == &context, "Audit creation requires its active audit-only context");
		auto data = snapshot(); require(data != nullptr, "No catalog loaded");
		context.qualityRevision = data->revision;
		std::set<std::string> stack; std::map<std::string, PlanCost> memo;
		plan(*data, key(id), stack, memo);
		return build(*data, key(id), context);
	} catch (const std::exception& failure) { error = failure.what(); }
	catch (const Exception& failure) { error = failure.getMessage(); }
	catch (...) { error = "Audit product generation failed"; }
	return nullptr;
}

bool PerfectCraftedItemFactory::auditEntry(ZoneServer* server, const String& id, String& report) {
	try {
		auto data = snapshot(); require(data != nullptr, "No catalog loaded");
		PerfectCraftingContext context(server, true); context.qualityRevision = data->revision;
		std::set<std::string> stack; std::map<std::string, PlanCost> memo;
		plan(*data, key(id), stack, memo);
		auto prototype = build(*data, key(id), context);
		wrap(prototype, context);
		report = context.semanticSignatures.at(key(id)); return true;
	} catch (const std::exception& failure) { report = failure.what(); }
	catch (const Exception& failure) { report = failure.getMessage(); }
	catch (...) { report = "Unexpected catalog audit failure"; }
	return false;
}

namespace {
struct AuditState {
	ManagedReference<ZoneServer*> server;
	std::shared_ptr<Registry> data;
	std::map<std::string, Entry>::iterator cursor;
	Json evidence;
	std::map<std::string, String> serials;
	size_t verified = 0, completed = 0, diagnosticBytes = 0;
	AuditState(ZoneServer* server, const String& path) : server(server), data(loadRegistry(path)), cursor(data->entries.begin()) {
		evidence["sourceFingerprint"] = key(data->sourceFingerprint);
		evidence["qualityRevision"] = key(data->revision);
	}
};
void auditOne(AuditState& state) {
	auto& item = *state.cursor++;
	auto& entry = item.second;
	Json diagnostic = Json::object();
	AuditDiagnosticScope diagnosticScope(diagnostic);
	try {
		String hashes[2];
		Json identities[2], states[2];
		for (int pass = 0; pass < 2; ++pass) {
			PerfectCraftingContext context(state.server, true); context.qualityRevision = state.data->revision;
			std::set<std::string> stack; std::map<std::string, PlanCost> memo;
			auto cost = plan(*state.data, item.first, stack, memo);
			auto prototype = build(*state.data, item.first, context, &identities[pass]);
			auto crate = wrap(prototype, context);
			hashes[pass] = context.semanticSignatures.at(item.first);
			auto extracted = context.clone(crate->getPrototype());
			if (gameplay(prototype).dump() != gameplay(extracted).dump()) {
				diagnostic["cloneDifferences"] = differences(gameplay(prototype, 0, nullptr, true), gameplay(extracted, 0, nullptr, true));
				require(false, "Clone changes gameplay state");
			}
			states[pass] = gameplay(prototype, 0, nullptr, true);
			state.evidence["entries"][item.first]["objects"] = context.allocationCount();
			state.evidence["entries"][item.first]["depth"] = cost.depth;
		}
		if (hashes[0] != hashes[1]) {
			diagnostic["repeatDifferences"] = differences(states[0], states[1]);
			diagnostic["identityDifferences"] = differences(identities[0], identities[1]);
			require(false, "Repeated generation is nondeterministic");
		}
		std::string serial = key(hashes[0].subString(0, 32));
		auto prior = state.serials.find(serial);
		require(prior == state.serials.end() || prior->second == hashes[0], "Batch serial collision");
		state.serials[serial] = hashes[0]; entry.semanticHash = hashes[0]; entry.verified = true; ++state.verified;
	} catch (const std::exception& failure) { entry.rejection = failure.what(); }
	catch (const Exception& failure) { entry.rejection = failure.getMessage(); }
	catch (...) { entry.rejection = "Unexpected generation failure"; }
	if (!diagnostic.empty()) {
		const auto bytes = diagnostic.dump().size();
		if (bytes <= 65536 && state.diagnosticBytes + bytes <= PerfectCraftingContext::MAX_SEMANTIC_BYTES) {
			state.diagnosticBytes += bytes;
			state.evidence["entries"][item.first]["diagnostics"] = std::move(diagnostic);
		} else state.evidence["entries"][item.first]["diagnosticsTruncated"] = true;
	}
	state.evidence["entries"][item.first]["availability"] = entry.verified ? "verified" : "rejected";
	state.evidence["entries"][item.first]["reason"] = key(entry.rejection);
	state.evidence["entries"][item.first]["sourceProfile"] = key(entry.recipe.sourceProfile);
	state.evidence["entries"][item.first]["sourceSupport"] = key(entry.recipe.sourceSupport);
	state.evidence["entries"][item.first]["semanticHash"] = key(entry.semanticHash);
	++state.completed;
}
String publishAudit(AuditState& state) {
	state.data->generation = ++nextGeneration;
	state.evidence["generation"] = state.data->generation; state.evidence["verified"] = state.verified;
	state.evidence["total"] = state.data->entries.size();
	{ std::ofstream output("log/perfect-factory-audit.json"); output << state.evidence.dump(2) << '\n'; }
	{ std::lock_guard<std::mutex> guard(registryMutex); registry = state.data; }
	return "Perfect factory audit: " + String::valueOf(state.verified) + "/" + String::valueOf(state.data->entries.size()) + " verified";
}
void auditBatch(const std::shared_ptr<AuditState>& state) {
	try {
		if (state->server->isServerShuttingDown() || state->server->isServerOffline()) { auditRunning = false; return; }
		// Separate Tasks also separate engine transactions, bounding the retained
		// deleted/dirty-object journal for the full registry audit.
		for (int i = 0; i < 8 && state->cursor != state->data->entries.end(); ++i) auditOne(*state);
		if (state->cursor == state->data->entries.end()) {
			Logger::console.info(true) << publishAudit(*state);
			auditRunning = false;
#ifdef COMPILE_CORE3_TESTS
			const char* fixture = std::getenv("SWG_PERFECT_FACTORY_ACCEPTANCE");
			if (fixture != nullptr && *fixture != '\0')
				runPerfectFactoryRuntimeAcceptance(state->server, String(fixture));
#endif
			return;
		}
		if (state->completed % 128 == 0)
			Logger::console.info(true) << "Perfect factory audit progress " << state->completed << "/" << state->data->entries.size();
		Core::getTaskManager()->executeTask([state]() { auditBatch(state); }, "PerfectFactoryCatalogAuditBatch");
	} catch (...) {
		Logger::console.error("Perfect factory catalog audit interrupted; catalog remains unavailable");
		auditRunning = false;
	}
}
}

bool PerfectCraftedItemFactory::audit(ZoneServer* server, const String& path, String& report) {
	try {
		// Synchronous API for bounded test catalogs. Production uses worker batches.
		AuditState state(server, path);
		while (state.cursor != state.data->entries.end()) auditOne(state);
		report = publishAudit(state);
		return state.verified == state.data->entries.size();
	} catch (const std::exception& failure) { report = failure.what(); }
	catch (const Exception& failure) { report = failure.getMessage(); }
	catch (...) { report = "Unable to load perfect factory catalog"; }
	return false;
}
void PerfectCraftedItemFactory::startAudit(ZoneServer* server) {
	if (auditRunning.exchange(true)) return;
	ManagedReference<ZoneServer*> reference = server;
	Core::getTaskManager()->executeTask([reference]() {
		try {
			auto state = std::make_shared<AuditState>(reference, "scripts/custom_scripts/managers/crafting/perfect_factory_catalog.lua");
			auditBatch(state);
		} catch (...) {
			Logger::console.error("Could not load perfect factory catalog; products remain unavailable");
			auditRunning = false;
		}
	}, "PerfectFactoryCatalogAudit");
}
