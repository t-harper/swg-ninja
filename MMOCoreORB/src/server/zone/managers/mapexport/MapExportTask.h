/*
	pre9 local: recurring driver for the Interactive Planet Map exporter.

	Self-rescheduling Task (the RankMaintenanceTask idiom): run() performs a
	full export then re-arms itself at IntervalMin, so passes never overlap.
	The heavy single-flight protection lives in MapExporter::exportAll(), so
	an on-demand "exportmap" console run and this periodic run can never race.
	Runs on the shared "slowQueue" like ResourceShiftTask so it does not tie
	up a general worker.
*/

#ifndef MAPEXPORTTASK_H_
#define MAPEXPORTTASK_H_

#include "engine/core/Task.h"

#include "MapExporter.h"

class MapExportTask : public Task {
public:
	MapExportTask() {
		setCustomTaskQueue("slowQueue");
	}

	void run() {
		MapExporter* exporter = MapExporter::instance();

		if (exporter == nullptr || !exporter->isEnabled())
			return; // disabled -> stop rescheduling

		exporter->exportAll();

		int intervalMin = exporter->getIntervalMin();

		if (intervalMin < 1)
			intervalMin = 5;

		reschedule((uint64) intervalMin * 60 * 1000);
	}
};

#endif /* MAPEXPORTTASK_H_ */
