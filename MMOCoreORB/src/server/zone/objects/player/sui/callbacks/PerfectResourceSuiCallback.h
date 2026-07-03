/*
 * PerfectResourceSuiCallback.h
 *
 * Character-builder chooser for perfect (all-applicable-stats-1000)
 * resources. Navigates the STATIC resource class tree via the perfect
 * list builders (recycled and statless classes filtered out); picking a
 * leaf class mints/reuses the never-in-shift singleton spawn, shows the
 * deed-style stat preview, and OK on the preview grants the resource.
 * Structure mirrors ResourceDeedSuiCallback minus the deed handling.
 */

#ifndef PERFECTRESOURCESUICALLBACK_H_
#define PERFECTRESOURCESUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/managers/resource/ResourceManager.h"
#include "server/zone/objects/resource/ResourceSpawn.h"

class PerfectResourceSuiCallback : public SuiCallback {
	String nodeName;
	int quantity;

public:
	PerfectResourceSuiCallback(ZoneServer* serv, const String& name, int qty) : SuiCallback(serv) {
		nodeName = name;
		quantity = qty;
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!sui->isListBox() || cancelPressed)
			return;

		SuiListBox* listBox = cast<SuiListBox*>( sui);

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return;

		bool backPressed = false;
		int index = -1;

		try {
			backPressed = Bool::valueOf(args->get(0).toString());
			index = Integer::valueOf(args->get(1).toString());
		} catch (Exception& e) {
			creature->error("Invalid parameters passed to PerfectResourceSuiCallback.");
			return;
		}

		ManagedReference<ResourceManager*> resourceManager = creature->getZoneServer()->getResourceManager();

		if (backPressed) {
			if (nodeName == "Resources" || nodeName == "Resource")
				return;

			listBox->removeAllMenuItems();

			nodeName = resourceManager->addPerfectParentNodeToListBox(listBox, nodeName);
		} else {
			// nodeName resolves to a spawn only while a stat preview is up;
			// OK there means "grant it".
			ManagedReference<ResourceSpawn*> spawn = resourceManager->getResourceSpawn(nodeName);

			if (spawn != nullptr) {
				resourceManager->givePlayerResource(creature, nodeName, quantity);
				return;
			}

			if (index >= 0 && index < listBox->getMenuSize()) {
				String choice = listBox->getMenuItemName(index);

				String perfectName = resourceManager->preparePerfectResource(choice);

				listBox->removeAllMenuItems();

				if (!perfectName.isEmpty()) {
					spawn = resourceManager->getResourceSpawn(perfectName);

					if (spawn != nullptr) {
						spawn->addStatsToDeedListBox(listBox);
						nodeName = perfectName;
					}
				} else {
					resourceManager->addPerfectNodeToListBox(listBox, choice);
					nodeName = choice;
				}
			}
		}

		ghost->addSuiBox(listBox);
		creature->sendMessage(listBox->generateMessage());
	}
};

#endif /* PERFECTRESOURCESUICALLBACK_H_ */
