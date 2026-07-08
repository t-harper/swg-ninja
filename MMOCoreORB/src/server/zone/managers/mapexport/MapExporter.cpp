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
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/managers/resource/resourcespawner/ResourceSpawner.h"
#include "server/zone/managers/resource/resourcespawner/resourcemap/ResourceMap.h"

#include "server/zone/objects/resource/ResourceSpawn.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/objects/creature/CreatureObject.h"

#include "templates/SharedObjectTemplate.h"

#include "engine/util/json_utils.h"
#include "system/io/File.h"
#include "system/thread/ReadLocker.h"

#include <cstdio>
#include <unistd.h>
#include <ctime>

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
	int zoneCount = 0;

	try {
		// idempotent; cheap; covers a wiped/rotated export dir
		File::mkpath(exportDir + "/", 0755);
		File::mkpath(exportDir + "/resources/", 0755);

		cityCount = exportCities(gen);
		zoneCount = exportResources(gen);
		writeLiveManifest(gen);
	} catch (const Exception& e) {
		error("map export failed: " + e.getMessage());
	} catch (...) {
		error("map export failed: unknown exception");
	}

	running.set(false);

	uint64 elapsed = System::getMiliTime() - startMs;

	StringBuffer msg;
	msg << "map export done: " << cityCount << " cities, " << zoneCount
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

	String out = root.dump(2).c_str();

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

	String out = root.dump(2).c_str();

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
