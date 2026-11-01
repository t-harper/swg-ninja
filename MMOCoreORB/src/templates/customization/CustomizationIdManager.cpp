/*
 * CustomizationIdManager.cpp
 *
 *  Created on: 29/03/2012
 *      Author: victor
 */

#include "CustomizationIdManager.h"
#include "templates/datatables/DataTableIff.h"

CustomizationIdManager::CustomizationIdManager() {
	setLoggingName("CustomizationIdManager");
}

void CustomizationIdManager::loadHairAssetsSkillMods(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		HairAssetData* data = new HairAssetData();
		data->readObject(dataTable.getRow(i));

		// Key by (hair server template + server player template). A single hair
		// object template can be shared by multiple species (e.g. custom species
		// reusing stock human/singing_mountain_clan hairs); keying by the hair
		// template alone would let the last species row clobber all the others,
		// causing PlayerCreationManager::addHair / ImageDesignManager to reject
		// the hair as "not compatible" for every species but the last one loaded.
		// '\n' is a safe separator: it never appears in a template path.
		hairAssetSkillMods.put(data->getServerTemplate() + "\n" + data->getServerPlayerTemplate(), data);

		debug() << "adding " << data->getServerTemplate() << " for " << data->getServerPlayerTemplate();
	}

	info() << "loaded " << paletteColumns.size() << " hair assets";
}

void CustomizationIdManager::loadAllowBald(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		String species;
		bool val;

		DataTableRow* row = dataTable.getRow(i);

		row->getValue(0, species);
		row->getValue(1, val);

		allowBald.put(String::hashCode("object/creature/player/" + species + ".iff"), val);
	}

	info() << "loaded " << allowBald.size() << " allow bald species data";
}

void CustomizationIdManager::loadPaletteColumns(IffStream* iffStream) {
	DataTableIff dataTable;
	dataTable.readObject(iffStream);

	for (int i = 0; i < dataTable.getTotalRows(); ++i) {
		PaletteData* data = new PaletteData();
		data->readObject(dataTable.getRow(i));

		paletteColumns.put(data->getName(), data);

		debug() << "adding " << data->getName();
	}

	info() << "loaded " << paletteColumns.size() << " palette columns";
}

void CustomizationIdManager::readObject(IffStream* iffStream) {
	iffStream->openForm('CIDM');
	iffStream->openForm('0001');

	Chunk* data = iffStream->openChunk('DATA');

	while (data->hasData()) {
		int id = data->readShort();
		String var;
		data->readString(var);

		customizationIds.put(var, id);
		reverseIds.put(id, var);
	}

	iffStream->closeChunk('DATA');

	iffStream->closeForm('0001');
	iffStream->closeForm('CIDM');

	info() << "loaded " << customizationIds.size() << " customization ids";
}

