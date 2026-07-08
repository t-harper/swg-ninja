/*
	pre9 local: Interactive Planet Map exporter (task W1/CPP-exporter).

	In-server module that periodically snapshots live world data — player
	cities + their civic structures, and the resource spawn catalog +
	per-planet density grids — and writes it as JSON under bin/exports/map/
	for the external map webapp to consume.

	This is a read-only observer: it never mutates game state. It runs on a
	task worker (MapExportTask) on a fixed interval, and can be triggered
	on demand from the server console via the "exportmap" command.
*/

#ifndef MAPEXPORTER_H_
#define MAPEXPORTER_H_

#include "engine/engine.h"
#include "engine/core/Task.h"

namespace server {
namespace zone {
	class ZoneServer;
}
}

using namespace server::zone;

class MapExporter : public Singleton<MapExporter>, public Object, public Logger {
	ManagedReference<ZoneServer*> zoneServer;

	// config (Core3.MapExport.*)
	bool enabled;
	int intervalMin;
	int gridResolution;

	bool initialized;

	// output directory relative to the server working dir (== bin/)
	String exportDir;

	// single-flight guard shared by the periodic task and the console command
	AtomicBoolean running;

	// re-sample gate: per-zone signature of the active spawn set. When a
	// zone's signature is unchanged since the last run its (expensive)
	// density-grid file is not rewritten. Global signature gates the catalog.
	VectorMap<String, uint32> lastZoneSignature;
	uint32 lastCatalogSignature;

	// manifest bookkeeping: relative filename -> last gen / size in bytes
	VectorMap<String, uint64> fileGen;
	VectorMap<String, uint64> fileSize;

	// the recurring export task, kept alive across fires
	Reference<Task*> exportTask;

public:
	MapExporter();
	~MapExporter();

	// Called once at startup with the running ZoneServer. Reads config and
	// creates the export directory. Safe to call from the init thread.
	void initialize(ZoneServer* server);

	// Creates + schedules the recurring MapExportTask (first run after
	// IntervalMin). No-op if disabled.
	void scheduleFirstRun();

	// One full export pass. Single-flight guarded and fully try/caught — it
	// never throws into the task pool. Intended to run on a task worker.
	void exportAll();

	bool isEnabled() const {
		return enabled;
	}

	int getIntervalMin() const {
		return intervalMin;
	}

private:
	// returns the number of cities written
	int exportCities(uint64 gen);

	// returns the number of per-zone resource files (re)written
	int exportResources(uint64 gen);

	void writeLiveManifest(uint64 gen);

	// Atomic write: <fileName>.tmp in the same dir, fflush + fsync, then
	// rename over the final name. Records gen/size for the manifest.
	bool writeFileAtomic(const String& fileName, const String& content, uint64 gen);

	// order-independent change signature helper (fmix32 over String::hashCode)
	static uint32 mixNameHash(const String& s);

	// standard RFC4648 base64 (with '=' padding) so the webapp's atob() can
	// decode the grid cells. (The engine BinaryData encoder is non-standard.)
	static String base64Encode(const uint8* data, int length);

	// classify a civic structure into a coarse kind for the map legend
	static String structureKind(const String& templatePath, uint32 gameObjectType);
};

#endif /* MAPEXPORTER_H_ */
