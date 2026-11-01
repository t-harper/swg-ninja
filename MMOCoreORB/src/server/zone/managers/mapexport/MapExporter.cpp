/*
	pre9 local: Interactive Planet Map exporter (task W1/CPP-exporter).
	See MapExporter.h for the overview.

	Coordinate frame: everything is emitted in the same world XY frame the game
	samples resource density in, i.e. SceneObject::getWorldPositionX()/Y() and
	Zone::getMinX()..getMaxX() / getMinY()..getMaxY(). This is the same frame the
	survey code uses (ResourceSpawner::sendSurvey -> getDensityAt(zone, posX,
	posY)) and the same frame CityRegion centers use, so cities, civic structures
	and resource grids all line up on the map.
*/

#include "MapExporter.h"
#include "MapExportTask.h"

#include "conf/ConfigManager.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/Zone.h"

#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/player/PlayerManager.h" // pre9 local (swg-stats): online list
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/resource/resourcespawner/ResourceSpawner.h"
#include "server/zone/managers/resource/resourcespawner/resourcemap/ResourceMap.h"

#include "server/zone/objects/resource/ResourceSpawn.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h" // pre9 local (swg-stats): lots

#include "templates/SharedObjectTemplate.h"

#include "engine/util/json_utils.h"
#include "engine/db/IndexDatabase.h"         // pre9 local (swg-stats): IndexDatabaseIterator (zone-keyed structure index)
#include "server/zone/managers/structure/StructureManager.h" // pre9 local (swg-stats): createSubIndex()
#include "server/zone/managers/object/ObjectManager.h"       // pre9 local (swg-stats): memory-only owner lookup
#include "system/io/File.h"
#include "system/thread/ReadLocker.h"

#include <cstdio>
#include <cmath>
#include <vector>
#include <exception>
#include <unistd.h>
#include <ctime>

namespace {
	// pre9 local (2026-09-04, swg-stats): one exported player structure. All
	// fields are snapshotted under the structure's own read lock; the owner
	// name is resolved afterwards with no lock held.
	struct ExportedStructure {
		uint64 oid = 0;
		String planet;
		String templatePath;
		String kind;
		String name;
		uint64 ownerId = 0;
		int lots = 0;
		int maint = 0;
		int maintRate = 0;
		bool civic = false;
		bool residence = false;
		uint64 cityOid = 0;
		float x = 0.f;
		float y = 0.f;
	};

	// one decimal is plenty for a map marker / a credits figure
	inline double round1(double v) {
		return std::round(v * 10.0) / 10.0;
	}
}

MapExporter::MapExporter() : Logger("MapExporter") {
	enabled = true;
	intervalMin = 5;
	gridResolution = 64;
	initialized = false;
	lastCatalogSignature = 0;

	exportDir = "exports/map";

	setLogging(true);
	setGlobalLogging(true);

	lastZoneSignature.setNullValue(0);
	lastZoneSignature.setAllowOverwriteInsertPlan();

	fileGen.setNullValue(0);
	fileGen.setAllowOverwriteInsertPlan();

	fileSize.setNullValue(0);
	fileSize.setAllowOverwriteInsertPlan();

	// pre9 local (swg-stats)
	ownerNameCache.setAllowOverwriteInsertPlan();
	ownerLotsMaxCache.setNullValue(0);
	ownerLotsMaxCache.setAllowOverwriteInsertPlan();
}

MapExporter::~MapExporter() {
}

void MapExporter::initialize(ZoneServer* server) {
	zoneServer = server;

	ConfigManager* cfg = ConfigManager::instance();

	enabled = cfg->getBool("Core3.MapExport.Enabled", true);
	intervalMin = cfg->getInt("Core3.MapExport.IntervalMin", 5);
	gridResolution = cfg->getInt("Core3.MapExport.GridResolution", 64);

	if (intervalMin < 1)
		intervalMin = 5;

	// clamp grid resolution to something sane (n*n bytes per resource per zone)
	if (gridResolution < 8)
		gridResolution = 8;

	if (gridResolution > 256)
		gridResolution = 256;

	File::mkpath(exportDir + "/", 0755);
	File::mkpath(exportDir + "/resources/", 0755);

	initialized = true;

	info(true) << "initialized (enabled=" << (enabled ? "true" : "false")
			   << ", intervalMin=" << intervalMin << ", grid=" << gridResolution
			   << ", dir=" << exportDir << ")";
}

void MapExporter::scheduleFirstRun() {
	if (!enabled)
		return;

	if (exportTask == nullptr)
		exportTask = new MapExportTask();

	uint64 delay = (uint64) intervalMin * 60 * 1000;

	exportTask->schedule(delay);

	info(true) << "first map export scheduled in " << intervalMin << " minute(s)";
}

void MapExporter::exportAll() {
	if (!enabled || !initialized)
		return;

	ManagedReference<ZoneServer*> server = zoneServer;

	if (server == nullptr || server->isServerShuttingDown())
		return;

	// single-flight: skip if a pass (periodic or manual) is already running
	if (!running.compareAndSet(false, true)) {
		info("map export already in flight; skipping this pass");
		return;
	}

	uint64 startMs = System::getMiliTime();
	uint64 gen = startMs;

	int cityCount = 0;
	int structureCount = 0; // pre9 local (swg-stats)
	int onlineCount = 0;    // pre9 local (swg-stats)
	int zoneCount = 0;

	try {
		// idempotent; cheap; covers a wiped/rotated export dir
		File::mkpath(exportDir + "/", 0755);
		File::mkpath(exportDir + "/resources/", 0755);

		cityCount = exportCities(gen);
		structureCount = exportStructures(gen); // pre9 local (swg-stats)
		onlineCount = exportOnline(gen);        // pre9 local (swg-stats)
		zoneCount = exportResources(gen);
		writeLiveManifest(gen);
	} catch (const Exception& e) {
		error("map export failed: " + e.getMessage());
	} catch (const std::exception& e) {
		error(String("map export failed: ") + e.what()); // pre9 local (swg-stats)
	} catch (...) {
		error("map export failed: unknown exception");
	}

	running.set(false);

	uint64 elapsed = System::getMiliTime() - startMs;

	StringBuffer msg;
	msg << "map export done: " << cityCount << " cities, " << structureCount
		<< " structures, " << onlineCount << " online, " << zoneCount
		<< " resource zones, in " << elapsed << "ms";
	info(true) << msg.toString();
}

int MapExporter::exportCities(uint64 gen) {
	CityManager* cityManager = zoneServer->getCityManager();

	if (cityManager == nullptr)
		return 0;

	// Snapshot the city references under the CityManager lock, then work off
	// the copy so we never hold the manager lock during per-object lookups.
	Vector<ManagedReference<CityRegion*> > cities;
	cityManager->getCitiesSnapshot(cities);

	nlohmann::json citiesArray = nlohmann::json::array();

	for (int i = 0; i < cities.size(); ++i) {
		ManagedReference<CityRegion*> city = cities.get(i);

		if (city == nullptr)
			continue;

		// stable identifier; read without a lock (avoid any lock-upgrade path)
		uint64 oid = city->getObjectID();

		String planet;
		String name;
		int rank = 0;
		String spec;
		float x = 0.f, y = 0.f, radius = 0.f;
		uint64 mayorId = 0;

		Vector<ManagedReference<StructureObject*> > civicStructures;

		// read the city's scalar fields + snapshot its civic structure refs
		// under a read lock on the city (not the manager).
		{
			ReadLocker clock(city);

			Zone* zone = city->getZone();

			if (zone != nullptr)
				planet = zone->getZoneName();

			name = city->getCityRegionName();
			rank = city->getCityRank();
			spec = city->getCitySpecialization();
			x = city->getPositionX();
			y = city->getPositionY();
			radius = city->getRadius();
			mayorId = city->getMayorID();

			int count = city->getStructuresCount();

			for (int s = 0; s < count; ++s) {
				StructureObject* structure = city->getCivicStructure(s);

				if (structure != nullptr)
					civicStructures.add(structure);
			}
		}

		// skip space / instanced zones (defensive; player cities are ground)
		if (planet.isEmpty() || planet.beginsWith("space_"))
			continue;

		// mayor first name — looked up WITHOUT holding the city lock
		String mayorName;

		if (mayorId != 0) {
			ManagedReference<SceneObject*> mayor = zoneServer->getObject(mayorId);

			if (mayor != nullptr && mayor->isPlayerCreature()) {
				CreatureObject* creo = mayor.castTo<CreatureObject*>();

				if (creo != nullptr)
					mayorName = creo->getFirstName();
			}
		}

		nlohmann::json cityJson = nlohmann::json::object();

		// oids are uint64 -> emit as strings so JS doesn't lose precision
		cityJson["oid"] = String::valueOf(oid).toCharArray();
		cityJson["planet"] = planet.toCharArray();
		cityJson["name"] = name.toCharArray(); // raw @stf ref or custom name; frontend resolves
		cityJson["rank"] = rank;
		cityJson["spec"] = spec.toCharArray();
		cityJson["x"] = x;
		cityJson["y"] = y;
		cityJson["r"] = radius;
		cityJson["mayorId"] = String::valueOf(mayorId).toCharArray();
		cityJson["mayor"] = mayorName.toCharArray();

		nlohmann::json civicArray = nlohmann::json::array();

		for (int s = 0; s < civicStructures.size(); ++s) {
			StructureObject* structure = civicStructures.get(s);

			if (structure == nullptr)
				continue;

			// exclude residences (they are not civic, but be defensive)
			BuildingObject* building = structure->asBuildingObject();

			if (building != nullptr && building->isResidence())
				continue;

			SharedObjectTemplate* tmpl = structure->getObjectTemplate();
			String templatePath = (tmpl != nullptr) ? tmpl->getFullTemplateString() : String("");
			uint32 got = structure->getGameObjectType();

			nlohmann::json civic = nlohmann::json::object();
			civic["oid"] = String::valueOf(structure->getObjectID()).toCharArray();
			civic["t"] = templatePath.toCharArray();
			civic["x"] = structure->getWorldPositionX();
			civic["y"] = structure->getWorldPositionY();
			civic["kind"] = structureKind(templatePath, got).toCharArray();

			civicArray.push_back(civic);
		}

		cityJson["civic"] = civicArray;

		citiesArray.push_back(cityJson);
	}

	nlohmann::json root = nlohmann::json::object();
	root["gen"] = gen;
	root["count"] = citiesArray.size();
	root["cities"] = citiesArray;

	String out = root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace).c_str(); // pre9 local (swg-stats): never throw on a bad UTF-8 byte in a player-entered name

	// cities are cheap: always rewrite
	writeFileAtomic("cities.json", out, gen);

	return (int) citiesArray.size();
}

int MapExporter::exportResources(uint64 gen) {
	ManagedReference<ResourceManager*> resourceManager = zoneServer->getResourceManager();

	if (resourceManager == nullptr)
		return 0;

	ResourceSpawner* spawner = resourceManager->getResourceSpawner();

	if (spawner == nullptr)
		return 0;

	ResourceMap* resourceMap = spawner->getResourceMap();

	if (resourceMap == nullptr)
		return 0;

	// Phase 1: snapshot the active spawn references under the ResourceManager
	// read lock. shiftResources() takes a WRITE lock on the manager before
	// mutating the map, so this serializes us against a shift restructuring it.
	Vector<ManagedReference<ResourceSpawn*> > spawns;

	{
		ReadLocker rlock(resourceManager);

		for (int i = 0; i < resourceMap->size(); ++i) {
			ManagedReference<ResourceSpawn*> spawn = resourceMap->get(i);

			if (spawn != nullptr && spawn->inShift())
				spawns.add(spawn);
		}
	}

	const int n = gridResolution;

	// per-zone buckets of ready-to-serialize resource objects
	nlohmann::json zoneBuckets = nlohmann::json::object();

	// per-zone change signature (XOR of mixed name hashes -> order independent)
	VectorMap<String, uint32> zoneSig;
	zoneSig.setNullValue(0);
	zoneSig.setAllowOverwriteInsertPlan();

	// zone bounds cache
	VectorMap<String, float> zoneMinX, zoneMaxX, zoneMinY, zoneMaxY;
	zoneMinX.setAllowOverwriteInsertPlan();
	zoneMaxX.setAllowOverwriteInsertPlan();
	zoneMinY.setAllowOverwriteInsertPlan();
	zoneMaxY.setAllowOverwriteInsertPlan();

	nlohmann::json catalog = nlohmann::json::array();
	uint32 catalogSig = 0;

	int presentGrids = 0;

	// Phase 2: build the catalog + sample grids. Each spawn is read under its
	// own read lock so a concurrent shift cannot rewrite its spawnMaps mid-read.
	for (int s = 0; s < spawns.size(); ++s) {
		ManagedReference<ResourceSpawn*> spawn = spawns.get(s);

		if (spawn == nullptr)
			continue;

		ReadLocker slock(spawn);

		String name = spawn->getName();
		String type = spawn->getType();

		// classes: up to 8 slots as [ [class, stfClass], ... ]
		nlohmann::json classes = nlohmann::json::array();

		for (int c = 0; c < 8; ++c) {
			String cl = spawn->getClass(c);

			if (cl.isEmpty())
				continue;

			nlohmann::json pair = nlohmann::json::array();
			pair.push_back(cl.toCharArray());
			pair.push_back(spawn->getStfClass(c).toCharArray());
			classes.push_back(pair);
		}

		// attributes: up to 12 slots as { attrName: value (0-1000) }
		nlohmann::json attrs = nlohmann::json::object();

		for (int a = 0; a < 12; ++a) {
			String attr;
			int val = spawn->getAttributeAndValue(attr, a);

			if (!attr.isEmpty())
				attrs[attr.toCharArray()] = val;
		}

		// zones this spawn currently occupies (ground only)
		nlohmann::json zoneNames = nlohmann::json::array();
		Vector<String> zonesForSpawn;

		int mapSize = spawn->getSpawnMapSize();

		for (int z = 0; z < mapSize; ++z) {
			String zn = spawn->getSpawnMapZone(z);

			if (zn.isEmpty() || zn.beginsWith("space_"))
				continue;

			zonesForSpawn.add(zn);
			zoneNames.push_back(zn.toCharArray());
		}

		// catalog entry (always)
		nlohmann::json cat = nlohmann::json::object();
		cat["name"] = name.toCharArray();
		cat["type"] = type.toCharArray();
		cat["classes"] = classes;
		cat["attrs"] = attrs;
		cat["zoneRestriction"] = spawn->getZoneRestriction().toCharArray();
		cat["surveyToolType"] = spawn->getSurveyToolType();
		cat["containerCRC"] = spawn->getContainerCRC();
		cat["zones"] = zoneNames;
		catalog.push_back(cat);

		catalogSig ^= mixNameHash(name);

		// sample each occupied zone's density grid
		for (int z = 0; z < zonesForSpawn.size(); ++z) {
			String zn = zonesForSpawn.get(z);

			float minX = 0.f, maxX = 0.f, minY = 0.f, maxY = 0.f;

			if (!zoneMinX.contains(zn)) {
				Zone* zone = zoneServer->getZone(zn);

				if (zone == nullptr)
					continue;

				minX = zone->getMinX();
				maxX = zone->getMaxX();
				minY = zone->getMinY();
				maxY = zone->getMaxY();

				zoneMinX.put(zn, minX);
				zoneMaxX.put(zn, maxX);
				zoneMinY.put(zn, minY);
				zoneMaxY.put(zn, maxY);
			} else {
				minX = zoneMinX.get(zn);
				maxX = zoneMaxX.get(zn);
				minY = zoneMinY.get(zn);
				maxY = zoneMaxY.get(zn);
			}

			float spanX = maxX - minX;
			float spanY = maxY - minY;

			// n*n bytes, row-major. row 0 == minimum-Y edge; row index increases
			// with world Y (northward). col 0 == minimum-X edge; col index
			// increases with world X (eastward). Sampled at cell centers.
			uint8* cells = new uint8[n * n];
			int nonZero = 0;
			float observedMax = 0.f;

			for (int row = 0; row < n; ++row) {
				float wy = minY + ((row + 0.5f) / (float) n) * spanY;

				for (int col = 0; col < n; ++col) {
					float wx = minX + ((col + 0.5f) / (float) n) * spanX;

					// getDensityAt is pure math and already clamps negatives to 0
					float d = spawn->getDensityAt(zn, wx, wy);

					if (d < 0.f)
						d = 0.f;

					if (d > 1.f)
						d = 1.f;

					if (d > observedMax)
						observedMax = d;

					int b = (int) (d * 255.f + 0.5f);

					if (b > 255)
						b = 255;

					if (b > 0)
						nonZero++;

					cells[row * n + col] = (uint8) b;
				}
			}

			// skip resources whose entire grid is 0 (not really present here)
			if (nonZero == 0) {
				delete[] cells;
				continue;
			}

			String b64 = base64Encode(cells, n * n);
			delete[] cells;

			nlohmann::json res = nlohmann::json::object();
			res["name"] = name.toCharArray();
			res["type"] = type.toCharArray();
			res["classes"] = classes;
			res["attrs"] = attrs;

			nlohmann::json params = nlohmann::json::object();
			nlohmann::json bbox = nlohmann::json::object();
			bbox["minX"] = minX;
			bbox["maxX"] = maxX;
			bbox["minY"] = minY;
			bbox["maxY"] = maxY;
			params["bbox"] = bbox;
			params["densityMax"] = observedMax; // observed peak of the sampled grid
			res["params"] = params;

			res["cells"] = b64.toCharArray();

			zoneBuckets[zn.toCharArray()].push_back(res);

			uint32 cur = zoneSig.contains(zn) ? zoneSig.get(zn) : 0;
			zoneSig.put(zn, cur ^ mixNameHash(name));

			presentGrids++;
		}
	}

	// catalog: rewrite only when the active set changed (or first run)
	if (catalogSig != lastCatalogSignature || !fileGen.contains("resources-catalog.json")) {
		nlohmann::json catRoot = nlohmann::json::object();
		catRoot["gen"] = gen;
		catRoot["count"] = catalog.size();
		catRoot["resources"] = catalog;

		String catOut = catRoot.dump().c_str();

		if (writeFileAtomic("resources-catalog.json", catOut, gen))
			lastCatalogSignature = catalogSig;
	}

	// per-zone density files: rewrite only zones whose spawn set changed
	int zonesWithData = 0;
	int filesWritten = 0;

	for (auto it = zoneBuckets.begin(); it != zoneBuckets.end(); ++it) {
		String zn = it.key().c_str();
		nlohmann::json& resArray = it.value();

		zonesWithData++;

		String fileName = "resources/" + zn + ".json";

		uint32 sig = zoneSig.contains(zn) ? zoneSig.get(zn) : 0;
		bool changed = !lastZoneSignature.contains(zn) || lastZoneSignature.get(zn) != sig;

		// unchanged and already on disk -> keep the previous file + manifest entry
		if (!changed && fileGen.contains(fileName))
			continue;

		nlohmann::json root = nlohmann::json::object();
		root["planet"] = zn.toCharArray();
		root["gen"] = gen;

		nlohmann::json grid = nlohmann::json::object();
		grid["n"] = n;
		grid["min"] = zoneMinX.contains(zn) ? zoneMinX.get(zn) : -8192.f;
		grid["max"] = zoneMaxX.contains(zn) ? zoneMaxX.get(zn) : 8192.f;
		grid["rowOrder"] = "y-ascending"; // row 0 = min-Y edge, rows increase with world Y
		grid["colOrder"] = "x-ascending"; // col 0 = min-X edge, cols increase with world X
		root["grid"] = grid;

		root["resources"] = resArray;

		String out = root.dump().c_str();

		if (writeFileAtomic(fileName, out, gen)) {
			lastZoneSignature.put(zn, sig);
			filesWritten++;
		}
	}

	StringBuffer msg;
	msg << "resources: " << spawns.size() << " active spawns, " << presentGrids
		<< " grids, " << zonesWithData << " zones (" << filesWritten << " files rewritten)";
	info(true) << msg.toString();

	return zonesWithData;
}

/*
	pre9 local (2026-09-04, swg-stats): structures.json

	Every player-owned structure in the galaxy. Source of truth is the
	zone-keyed "playerstructuresindex" walked per loaded zone (the same walk
	StructureManager::loadPlayerStructures() does at boot, so the objects are
	already resident and getObject() is a memory lookup). Locking discipline:
	  - the Berkeley cursor is closed BEFORE the first object lookup;
	  - each structure's fields are read under ITS OWN ReadLocker only;
	  - owner lookups (name / max lots) happen afterwards with no structure
	    lock held; getTotalOwnedStructureCount() takes a short Locker on the
	    PlayerObject, which is the only write lock this pass ever takes and it
	    is never nested inside another lock.
	Never mutates game state; per-object try/catch so one bad object cannot
	abort the pass.
*/
int MapExporter::exportStructures(uint64 gen) {
	// Phase 1: enumerate the oids of every structure that belongs to a zone
	// THIS galaxy has loaded, via the zone-keyed secondary index
	// ("playerstructuresindex") -- the exact walk
	// StructureManager::loadPlayerStructures() does at boot, so every oid we
	// get back is already resident and getObject() is a memory lookup.
	// (Walking the primary database's raw keys instead could hand us a
	// structure on a zone this galaxy never enabled; getObject() would then
	// deserialize it on this thread and fire its load-time side effects.)
	// Keys only: no value blob is ever deserialized here, and the cursor is
	// closed before the first object lookup.
	Vector<uint64> oids;

	{
		StructureManager* structureManager = StructureManager::instance();
		IndexDatabase* index = (structureManager != nullptr) ? structureManager->createSubIndex() : nullptr;

		if (index == nullptr) {
			error("map export: playerstructures index unavailable");
			return 0;
		}

		berkeley::CursorConfig config;
		config.setReadUncommitted(true);

		int zoneCount = zoneServer->getZoneCount();

		for (int z = 0; z < zoneCount; ++z) {
			Zone* zone = zoneServer->getZone(z);

			if (zone == nullptr)
				continue;

			String zoneName = zone->getZoneName();

			if (zoneName.isEmpty())
				continue;

			uint64 zoneHash = zoneName.hashCode();

			try {
				IndexDatabaseIterator iterator(index, config);
				uint64 objectID = 0;

				if (iterator.setKeyAndGetValue(zoneHash, objectID, nullptr)) {
					oids.add(objectID);

					while (iterator.getNextKeyAndValue(zoneHash, objectID, nullptr))
						oids.add(objectID);
				}
			} catch (const Exception& e) {
				error("map export: playerstructures index walk failed for " + zoneName + ": " + e.getMessage());
			} catch (...) {
				error("map export: playerstructures index walk failed for " + zoneName + ": unknown exception");
			}
		}
	}

	// std::vector: engine Vector<E> requires a Serializable element type
	std::vector<ExportedStructure> records;

	// per-owner aggregate, insertion-ordered so the output is stable run to run
	Vector<uint64> ownerOrder;
	VectorMap<uint64, int> ownerLots;
	VectorMap<uint64, int> ownerCount;
	ownerLots.setNullValue(0);
	ownerLots.setAllowOverwriteInsertPlan();
	ownerCount.setNullValue(0);
	ownerCount.setAllowOverwriteInsertPlan();

	int skipped = 0;

	// Phase 2: snapshot each structure under its own read lock.
	for (int i = 0; i < oids.size(); ++i) {
		uint64 oid = oids.get(i);

		try {
			ManagedReference<SceneObject*> obj = zoneServer->getObject(oid);

			if (obj == nullptr || !obj->isStructureObject()) {
				skipped++;
				continue;
			}

			// destroyed (redeeded / decayed) but not yet purged from the object
			// database -- the persistence cycle drops the record minutes later;
			// the game already treats it as gone (lots freed), so must we
			if (obj->_isMarkedForDeletion()) {
				skipped++;
				continue;
			}

			StructureObject* structure = obj.castTo<StructureObject*>();

			if (structure == nullptr) {
				skipped++;
				continue;
			}

			ExportedStructure rec;
			rec.oid = oid;

			bool cityHall = false;
			bool camp = false;

			{
				ReadLocker slock(structure);

				Zone* zone = structure->getZoneUnsafe();

				if (zone != nullptr)
					rec.planet = zone->getZoneName();

				SharedObjectTemplate* tmpl = structure->getObjectTemplate();

				if (tmpl != nullptr)
					rec.templatePath = tmpl->getFullTemplateString();

				rec.name = structure->getCustomObjectName().toString();
				rec.x = structure->getWorldPositionX();
				rec.y = structure->getWorldPositionY();
				rec.ownerId = structure->getOwnerObjectID();
				rec.lots = structure->getLotSize();
				rec.maint = structure->getSurplusMaintenance();
				rec.maintRate = (int) structure->getMaintenanceRate();
				rec.civic = structure->isCivicStructure();
				cityHall = (tmpl != nullptr) && structure->isCityHall();
				camp = (tmpl != nullptr) && structure->isCampStructure();

				// weak ref -> only its oid is needed; no lock on the city.
				// NPC (client) city regions also tag objects that enter them
				// but never appear in cities.json, so only player cities count.
				ManagedReference<CityRegion*> city = structure->getCityRegion().get();

				if (city != nullptr && !city->isClientRegion())
					rec.cityOid = city->getObjectID();

				BuildingObject* building = structure->asBuildingObject();

				if (building != nullptr)
					rec.residence = building->isResidence();
			}

			// a structure with no zone is not in the world (mid-destroy, or on a
			// zone this galaxy no longer loads)
			if (rec.planet.isEmpty()) {
				skipped++;
				continue;
			}

			rec.kind = playerStructureKind(rec.templatePath);

			// runtime type beats the path heuristic where it is unambiguous
			if (cityHall)
				rec.kind = "cityhall";
			else if (camp)
				rec.kind = "camp";

			if (rec.ownerId != 0) {
				if (!ownerLots.contains(rec.ownerId))
					ownerOrder.add(rec.ownerId);

				ownerLots.put(rec.ownerId, ownerLots.get(rec.ownerId) + rec.lots);
				ownerCount.put(rec.ownerId, ownerCount.get(rec.ownerId) + 1);
			}

			records.push_back(rec);
		} catch (const Exception& e) {
			skipped++;
			error("map export: structure " + String::valueOf(oid) + " skipped: " + e.getMessage());
		} catch (const std::exception& e) {
			skipped++;
			error(String("map export: structure ") + String::valueOf(oid) + " skipped: " + e.what());
		} catch (...) {
			skipped++;
			error("map export: structure " + String::valueOf(oid) + " skipped: unknown exception");
		}
	}

	// Phase 3: resolve owners (name, max lots) with NO structure lock held.
	// Resident owners (online, or still cached by the object manager) are a
	// memory lookup; an offline owner is deserialized from the object database
	// AT MOST ONCE per process lifetime (same cost as a /tell to an offline
	// player) and then served from ownerNameCache/ownerLotsMaxCache, so the
	// 5-minute pass never re-loads garbage-collected players. Unknown /
	// non-player owners are emitted with name "" (negative-cached too).
	VectorMap<uint64, String> ownerNames;
	ownerNames.setAllowOverwriteInsertPlan();

	nlohmann::json playersArray = nlohmann::json::array();

	for (int i = 0; i < ownerOrder.size(); ++i) {
		uint64 ownerId = ownerOrder.get(i);

		String ownerName;
		int lotsMax = 0;
		int owned = ownerCount.get(ownerId);
		bool resolved = false;

		try {
			// memory-only lookup (DOBObjectManager::getObject has no database fallback)
			Reference<DistributedObject*> resident = ObjectManager::instance()->getObject(ownerId);
			ManagedReference<SceneObject*> ownerObj = (resident != nullptr) ? dynamic_cast<SceneObject*>(resident.get()) : nullptr;

			if (ownerObj == nullptr && !ownerNameCache.contains(ownerId)) {
				// never seen since boot: load once from the object database
				ownerObj = zoneServer->getObject(ownerId);
			}

			if (ownerObj != nullptr && ownerObj->isPlayerCreature()) {
				CreatureObject* creo = ownerObj.castTo<CreatureObject*>();

				if (creo != nullptr) {
					ownerName = creo->getFirstName();

					ManagedReference<PlayerObject*> ghost = creo->getPlayerObject();

					if (ghost != nullptr)
						lotsMax = ghost->getMaximumLots();

					resolved = true;
				}
			}
		} catch (const Exception& e) {
			error("map export: owner " + String::valueOf(ownerId) + " lookup failed: " + e.getMessage());
		} catch (const std::exception& e) {
			error(String("map export: owner ") + String::valueOf(ownerId) + " lookup failed: " + e.what());
		} catch (...) {
			error("map export: owner " + String::valueOf(ownerId) + " lookup failed: unknown exception");
		}

		if (resolved) {
			ownerNameCache.put(ownerId, ownerName);
			ownerLotsMaxCache.put(ownerId, lotsMax);
		} else if (ownerNameCache.contains(ownerId)) {
			ownerName = ownerNameCache.get(ownerId);
			lotsMax = ownerLotsMaxCache.get(ownerId);
		} else {
			// missing / non-player owner: remember that so it is not retried every pass
			ownerNameCache.put(ownerId, ownerName);
			ownerLotsMaxCache.put(ownerId, 0);
		}

		ownerNames.put(ownerId, ownerName);

		nlohmann::json player = nlohmann::json::object();
		player["oid"] = String::valueOf(ownerId).toCharArray();
		player["name"] = ownerName.toCharArray();
		player["lotsMax"] = lotsMax;
		player["lotsUsed"] = ownerLots.get(ownerId);
		player["structures"] = owned;

		playersArray.push_back(player);
	}

	// Phase 4: serialize
	nlohmann::json structuresArray = nlohmann::json::array();

	for (size_t i = 0; i < records.size(); ++i) {
		const ExportedStructure& rec = records[i];

		nlohmann::json sj = nlohmann::json::object();

		// oids are uint64 -> strings so JS doesn't lose precision
		sj["oid"] = String::valueOf(rec.oid).toCharArray();
		sj["planet"] = rec.planet.toCharArray();
		sj["x"] = round1(rec.x);
		sj["y"] = round1(rec.y);
		sj["t"] = rec.templatePath.toCharArray();
		sj["kind"] = rec.kind.toCharArray();
		sj["name"] = rec.name.toCharArray();
		sj["ownerId"] = String::valueOf(rec.ownerId).toCharArray();

		String ownerName;

		if (ownerNames.contains(rec.ownerId))
			ownerName = ownerNames.get(rec.ownerId);

		sj["owner"] = ownerName.toCharArray();
		sj["lots"] = rec.lots;
		sj["maint"] = (double) rec.maint;
		sj["maintRate"] = rec.maintRate;
		sj["civic"] = rec.civic;

		if (rec.cityOid != 0)
			sj["cityOid"] = String::valueOf(rec.cityOid).toCharArray();

		sj["residence"] = rec.residence;

		structuresArray.push_back(sj);
	}

	nlohmann::json root = nlohmann::json::object();
	root["gen"] = gen;
	root["count"] = structuresArray.size();
	root["structures"] = structuresArray;
	root["players"] = playersArray;

	String out = root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace).c_str(); // pre9 local (swg-stats): never throw on a bad UTF-8 byte in a player-entered name

	writeFileAtomic("structures.json", out, gen);

	StringBuffer msg;
	msg << "structures: " << oids.size() << " keys in playerstructures, " << structuresArray.size()
		<< " exported, " << playersArray.size() << " owners, " << skipped << " skipped";
	info(true) << msg.toString();

	return (int) structuresArray.size();
}

/*
	pre9 local (2026-09-04, swg-stats): online.json

	Names + planet of every connected character, from
	PlayerManager::getOnlinePlayerList() (a snapshot taken under the online
	map mutex, released before we touch any creature). No coordinates on
	purpose: the swg-map server must never serve this file publicly.
*/
int MapExporter::exportOnline(uint64 gen) {
	PlayerManager* playerManager = zoneServer->getPlayerManager();

	if (playerManager == nullptr)
		return 0;

	Vector<uint64> onlineIds = playerManager->getOnlinePlayerList();

	nlohmann::json playersArray = nlohmann::json::array();

	for (int i = 0; i < onlineIds.size(); ++i) {
		uint64 oid = onlineIds.get(i);

		try {
			ManagedReference<SceneObject*> obj = zoneServer->getObject(oid);

			if (obj == nullptr || !obj->isPlayerCreature())
				continue;

			CreatureObject* creo = obj.castTo<CreatureObject*>();

			if (creo == nullptr)
				continue;

			String name;
			String planet;

			{
				ReadLocker clock(creo);

				name = creo->getFirstName();

				// resolves through the parent chain (inside a building / ship)
				Zone* zone = creo->getZoneUnsafe();

				if (zone != nullptr)
					planet = zone->getZoneName();
			}

			if (name.isEmpty())
				continue;

			nlohmann::json pj = nlohmann::json::object();
			pj["oid"] = String::valueOf(oid).toCharArray();
			pj["name"] = name.toCharArray();
			pj["planet"] = planet.toCharArray();

			playersArray.push_back(pj);
		} catch (const Exception& e) {
			error("map export: online player " + String::valueOf(oid) + " skipped: " + e.getMessage());
		} catch (const std::exception& e) {
			error(String("map export: online player ") + String::valueOf(oid) + " skipped: " + e.what());
		} catch (...) {
			error("map export: online player " + String::valueOf(oid) + " skipped: unknown exception");
		}
	}

	nlohmann::json root = nlohmann::json::object();
	root["gen"] = gen;
	root["count"] = playersArray.size();
	root["players"] = playersArray;

	String out = root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace).c_str(); // pre9 local (swg-stats): never throw on a bad UTF-8 byte in a player-entered name

	writeFileAtomic("online.json", out, gen);

	return (int) playersArray.size();
}

void MapExporter::writeLiveManifest(uint64 gen) {
	nlohmann::json root = nlohmann::json::object();
	root["gen"] = gen;

	nlohmann::json files = nlohmann::json::object();

	for (int i = 0; i < fileGen.size(); ++i) {
		String fn = fileGen.elementAt(i).getKey();

		if (fn == "live-manifest.json")
			continue; // don't list the manifest in itself

		nlohmann::json entry = nlohmann::json::object();
		entry["gen"] = fileGen.get(fn);
		entry["size"] = fileSize.contains(fn) ? fileSize.get(fn) : (uint64) 0;

		files[fn.toCharArray()] = entry;
	}

	root["files"] = files;

	String out = root.dump(2, ' ', false, nlohmann::json::error_handler_t::replace).c_str(); // pre9 local (swg-stats): never throw on a bad UTF-8 byte in a player-entered name

	writeFileAtomic("live-manifest.json", out, gen);
}

bool MapExporter::writeFileAtomic(const String& fileName, const String& content, uint64 gen) {
	String finalPath = exportDir + "/" + fileName;
	String tmpPath = finalPath + ".tmp";

	FILE* fp = fopen(tmpPath.toCharArray(), "wb");

	if (fp == nullptr) {
		error("map export: cannot open " + tmpPath + " for writing");
		return false;
	}

	int len = content.length();
	bool ok = true;

	if (len > 0) {
		size_t written = fwrite(content.toCharArray(), 1, (size_t) len, fp);
		ok = ((int) written == len);
	}

	fflush(fp);
	::fsync(fileno(fp)); // durable before the rename
	fclose(fp);

	if (!ok) {
		error("map export: short write to " + tmpPath);
		std::remove(tmpPath.toCharArray());
		return false;
	}

#ifdef PLATFORM_WIN
	std::remove(finalPath.toCharArray());
#endif

	if (std::rename(tmpPath.toCharArray(), finalPath.toCharArray()) != 0) {
		error("map export: rename failed for " + finalPath);
		std::remove(tmpPath.toCharArray());
		return false;
	}

	fileGen.put(fileName, gen);
	fileSize.put(fileName, (uint64) len);

	return true;
}

uint32 MapExporter::mixNameHash(const String& s) {
	// fmix32 finalizer over String::hashCode() -> good avalanche for XOR sigs
	uint32 h = (uint32) s.hashCode();
	h ^= h >> 16;
	h *= 0x7feb352dU;
	h ^= h >> 15;
	h *= 0x846ca68bU;
	h ^= h >> 16;
	return h;
}

String MapExporter::base64Encode(const uint8* data, int length) {
	static const char tbl[] =
			"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	if (length <= 0)
		return String("");

	int outLen = 4 * ((length + 2) / 3);
	char* buf = new char[outLen + 1];
	int p = 0;
	int i = 0;

	for (; i + 2 < length; i += 3) {
		uint32 nn = ((uint32) data[i] << 16) | ((uint32) data[i + 1] << 8) | (uint32) data[i + 2];
		buf[p++] = tbl[(nn >> 18) & 63];
		buf[p++] = tbl[(nn >> 12) & 63];
		buf[p++] = tbl[(nn >> 6) & 63];
		buf[p++] = tbl[nn & 63];
	}

	int rem = length - i;

	if (rem == 1) {
		uint32 nn = (uint32) data[i] << 16;
		buf[p++] = tbl[(nn >> 18) & 63];
		buf[p++] = tbl[(nn >> 12) & 63];
		buf[p++] = '=';
		buf[p++] = '=';
	} else if (rem == 2) {
		uint32 nn = ((uint32) data[i] << 16) | ((uint32) data[i + 1] << 8);
		buf[p++] = tbl[(nn >> 18) & 63];
		buf[p++] = tbl[(nn >> 12) & 63];
		buf[p++] = tbl[(nn >> 6) & 63];
		buf[p++] = '=';
	}

	buf[p] = '\0';

	String result(buf, p);

	delete[] buf;

	return result;
}

String MapExporter::structureKind(const String& templatePath, uint32 gameObjectType) {
	String t = templatePath.toLowerCase();

	if (t.contains("cityhall") || t.contains("city_hall"))
		return "cityhall";

	if (t.contains("cloning"))
		return "cloning";

	if (t.contains("hospital") || t.contains("medcenter") || t.contains("medical_center"))
		return "hospital";

	if (t.contains("cantina"))
		return "cantina";

	if (t.contains("shuttleport") || t.contains("starport") || t.contains("shuttle") || t.contains("travel"))
		return "shuttleport";

	if (t.contains("guild"))
		return "guildhall";

	if (t.contains("bank"))
		return "bank";

	if (t.contains("theater") || t.contains("theatre"))
		return "theater";

	if (t.contains("garage") || t.contains("vehicle"))
		return "garage";

	return "other";
}

/*
	pre9 local (2026-09-04, swg-stats): contract classification for player
	structures. Ordered substring rules over the lower-cased server template
	path (docs/CONTRACT.md in ~/code/swg-stats). "cityhall" is accepted next
	to the contract's "city_hall" because Core3 city halls are
	object/building/player/city/cityhall_<planet>.iff.
*/
String MapExporter::playerStructureKind(const String& templatePath) {
	String t = templatePath.toLowerCase();

	if (t.contains("city_hall") || t.contains("cityhall"))
		return "cityhall";

	if (t.contains("guild_hall") || t.contains("guildhall"))
		return "guildhall";

	if (t.contains("player/city/"))
		return "civic";

	if (t.contains("building/player/")
			&& (t.contains("cloning") || t.contains("bank") || t.contains("shuttleport")
				|| t.contains("garage") || t.contains("cantina") || t.contains("theater")
				|| t.contains("hospital") || t.contains("medical")))
		return "civic";

	if (t.contains("harvester") || t.contains("mining"))
		return "harvester";

	if (t.contains("factory"))
		return "factory";

	if (t.contains("generator") || t.contains("power"))
		return "generator";

	if (t.contains("camp"))
		return "camp";

	if (t.contains("hq_") || t.contains("faction_perk") || t.contains("military"))
		return "gcw";

	if (t.contains("building/player/"))
		return "house";

	return "other";
}
