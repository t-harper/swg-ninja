#ifndef PERFECTCRAFTINGRECIPE_H_
#define PERFECTCRAFTINGRECIPE_H_

#include "engine/engine.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include <chrono>
#include <map>
#include <set>
#include <vector>

struct PerfectIngredientChoice {
	int slotIndex = -1;
	String childId;
	int quantity = 0;
	bool omit = false;
};

struct PerfectCraftingRecipe {
	String id, kind, draftPath, targetTemplate, variantId, category, label;
	String sourceProfile, sourceSupport, qualitySignature, availability, reviveProfile;
	int variantIndex = -1;
	int powerupPrimaryIndex = -1;
	std::vector<int> powerupSecondaryIndices;
	bool expectedFactoryEligible = false;
	std::vector<String> professions;
	std::vector<PerfectIngredientChoice> ingredientChoices;
};

// One engine worker/transaction owns a context. Adapters MUST register every
// allocation immediately; no inventory transfer, persistence, or player mutation.
class PerfectCraftingContext {
	std::vector<ManagedReference<SceneObject*> > owned;
	std::set<SceneObject*> preparedCommit;
	size_t objectLimit = 16384;
	std::set<SceneObject*> retained;
	std::chrono::steady_clock::time_point deadline;
	PerfectCraftingContext* previous;
	static thread_local PerfectCraftingContext* active;
public:
	static constexpr size_t MAX_OBJECTS = 16384;
	static constexpr size_t MAX_SEMANTIC_BYTES = 16 * 1024 * 1024;
	static constexpr size_t MAX_DEPTH = 32;
	ZoneServer* server;
	String qualityRevision;
	String specialFingerprint;
	bool auditOnly;
	std::map<std::string, ManagedReference<TangibleObject*> > archetypes;
	std::map<std::string, String> semanticSignatures;
	explicit PerfectCraftingContext(ZoneServer* server, bool auditOnly = false);
	~PerfectCraftingContext();
	PerfectCraftingContext(const PerfectCraftingContext&) = delete;
	PerfectCraftingContext& operator=(const PerfectCraftingContext&) = delete;
	static PerfectCraftingContext* current() { return active; }
	SceneObject* create(const String& path);
	SceneObject* clone(SceneObject* object);
	void own(SceneObject* object);
	// Validate graph registration; foreign references are never implicitly adopted.
	void ownGraph(SceneObject* object);
	void checkpoint() const;
	void prepareReleaseGraph(SceneObject* object);
	void releasePreparedGraph() noexcept;
	void persistGraph(SceneObject* object);
	size_t allocationCount() const { return owned.size(); }
	size_t allocationLimit() const { return objectLimit; }
#ifdef COMPILE_CORE3_TESTS
	std::vector<ManagedReference<SceneObject*> > trackedObjectsForTesting() const { return owned; }
	// Forces the same real pre-allocation guard at a small limit for rollback
	// tests; it cannot raise the production ceiling.
	void setAllocationLimitForTesting(size_t limit) {
		if (limit <= MAX_OBJECTS && limit >= owned.size()) objectLimit = limit;
	}
#endif
};
#endif
