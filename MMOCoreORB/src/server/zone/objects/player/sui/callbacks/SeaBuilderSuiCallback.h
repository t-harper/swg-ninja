/*
 * SeaBuilderSuiCallback.h
 *
 * Character-builder generator for clothing skill-enhancing attachments
 * (SEAs). The player picks skill mods from the lootable clothing
 * attachment list one at a time (each at +25) with OK; the top
 * "[ Create ... ]" row mints a clothing attachment
 * (object/tangible/gem/clothing.iff) carrying every chosen mod. Pairs
 * with the local WearableObjectImplementation change that applies ALL
 * mods on an attachment (stock applied only the best one); the
 * wearable-side guard bounds useful mods at 6, so selection caps there.
 *
 * Arg layout note: this box has NO "other" button, so a SuiListBox
 * returns the selected row in args[0] (with an other button it would
 * shift to args[1] — reading args[1] here was the original bug that made
 * every pick resolve to row 0 = "aim").
 */

#ifndef SEABUILDERSUICALLBACK_H_
#define SEABUILDERSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/attachment/Attachment.h"
#include "server/zone/managers/loot/LootManager.h"

class SeaBuilderSuiCallback : public SuiCallback {
	Vector<String> allMods;
	Vector<String> chosenMods;
	bool armorMode;

public:
	static const int MAXMODS = 6;

	SeaBuilderSuiCallback(ZoneServer* serv, bool armor = false) : SuiCallback(serv) {
		armorMode = armor;

		LootManager* lootManager = serv->getLootManager();

		if (lootManager != nullptr) {
			if (armorMode)
				lootManager->getLootableArmorAttachmentMods(allMods);
			else
				lootManager->getLootableClothingAttachmentMods(allMods);
		}
	}

	bool isArmorMode() const {
		return armorMode;
	}

	const Vector<String>* getAllMods() const {
		return &allMods;
	}

	const Vector<String>* getChosenMods() const {
		return &chosenMods;
	}

	static void populate(SuiListBox* listBox, const Vector<String>& all, const Vector<String>& chosen, bool armor = false) {
		listBox->setPromptTitle(armor ? "Armor Attachment Builder" : "Clothing Attachment Builder");

		StringBuffer prompt;
		prompt << "Select a skill mod and press OK to add it at +25 (up to "
		       << MAXMODS << " per attachment). Choose the [ Create ] row when done.\n\nChosen ("
		       << chosen.size() << "/" << MAXMODS << "): ";

		if (chosen.size() == 0) {
			prompt << "none";
		} else {
			for (int i = 0; i < chosen.size(); ++i) {
				if (i > 0)
					prompt << ", ";
				prompt << chosen.get(i);
			}
		}

		listBox->setPromptText(prompt.toString());

		if (chosen.size() > 0)
			listBox->addMenuItem("[ Create attachment with " + String::valueOf(chosen.size()) + " mod(s) ]");

		if (chosen.size() < MAXMODS) {
			for (int i = 0; i < all.size(); ++i) {
				const String& mod = all.get(i);

				if (!chosen.contains(mod))
					listBox->addMenuItem(mod);
			}
		}
	}

	void run(CreatureObject* creature, SuiBox* sui, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!sui->isListBox() || cancelPressed)
			return;

		SuiListBox* listBox = cast<SuiListBox*>( sui);

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return;

		int index = -1;

		try {
			index = Integer::valueOf(args->get(0).toString());
		} catch (Exception& e) {
			creature->error("Invalid parameters passed to SeaBuilderSuiCallback.");
			return;
		}

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		String choice = listBox->getMenuItemName(index);

		if (choice.beginsWith("[ Create attachment")) {
			createAttachment(creature);
			return;
		}

		if (!chosenMods.contains(choice) && chosenMods.size() < MAXMODS)
			chosenMods.add(choice);

		listBox->removeAllMenuItems();
		populate(listBox, allMods, chosenMods, armorMode);

		ghost->addSuiBox(listBox);
		creature->sendMessage(listBox->generateMessage());
	}

private:
	void createAttachment(CreatureObject* creature) {
		if (chosenMods.size() == 0) {
			creature->sendSystemMessage("You did not choose any skill mods.");
			return;
		}

		ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

		if (inventory == nullptr || inventory->isContainerFullRecursive()) {
			creature->sendSystemMessage("Your inventory is full.");
			return;
		}

		ZoneServer* zserv = creature->getZoneServer();

		String templatePath = armorMode ? "object/tangible/gem/armor.iff" : "object/tangible/gem/clothing.iff";
		ManagedReference<SceneObject*> object = zserv->createObject(templatePath.hashCode(), 1);

		if (object == nullptr || !object->isAttachment()) {
			if (object != nullptr) {
				Locker locker(object);
				object->destroyObjectFromDatabase(true);
			}

			creature->sendSystemMessage("Failed to create the attachment.");
			return;
		}

		Attachment* attachment = cast<Attachment*>( object.get());

		Locker locker(object);

		VectorMap<String, int>* skillMods = attachment->getSkillMods();

		for (int i = 0; i < chosenMods.size(); ++i) {
			skillMods->put(chosenMods.get(i), 25);
		}

		if (inventory->transferObject(object, -1, true)) {
			inventory->broadcastObject(object, true);
			creature->sendSystemMessage("Attachment created with " + String::valueOf(chosenMods.size()) + " skill mod(s) at +25.");
		} else {
			object->destroyObjectFromDatabase(true);
			creature->sendSystemMessage("Failed to transfer the attachment to your inventory.");
		}
	}
};

#endif /* SEABUILDERSUICALLBACK_H_ */
