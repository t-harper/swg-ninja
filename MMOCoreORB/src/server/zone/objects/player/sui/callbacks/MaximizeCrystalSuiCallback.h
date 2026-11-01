/*
 * MaximizeCrystalSuiCallback.h
 *
 * pre9 local: GM-only dropdown to maximize a lightsaber crystal's stats with a
 * chosen flat damage bump (+30 / +300 / +3000). Opened from the crystal's
 * "Maximize Stats (GM)" staff radial. Applies to any stat-bearing crystal
 * (color == 31 -> krayt dragon pearls AND power crystals).
 */

#ifndef MAXIMIZECRYSTALSUICALLBACK_H_
#define MAXIMIZECRYSTALSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/component/lightsaber/LightsaberCrystalComponent.h"

class MaximizeCrystalSuiCallback : public SuiCallback {
public:
	MaximizeCrystalSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (server == nullptr || server->isServerLoading())
			return;

		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || cancelPressed)
			return;

		if (!player->isPlayerCreature())
			return;

		// GM-only: re-check privilege in the callback so a crafted client
		// packet can never trigger the maximize on a non-staff account.
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr || !ghost->isPrivileged())
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		ManagedReference<SceneObject*> obj = listBox->getUsingObject().get();

		if (obj == nullptr)
			return;

		LightsaberCrystalComponent* crystal = cast<LightsaberCrystalComponent*>(obj.get());

		if (crystal == nullptr)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		int damageBonus = 0;

		switch (index) {
		case 0:
			damageBonus = 30;
			break;
		case 1:
			damageBonus = 300;
			break;
		case 2:
			damageBonus = 3000;
			break;
		default:
			return;
		}

		Locker locker(crystal, player);

		crystal->maximizeStats(player, damageBonus);
	}
};

#endif /* MAXIMIZECRYSTALSUICALLBACK_H_ */
