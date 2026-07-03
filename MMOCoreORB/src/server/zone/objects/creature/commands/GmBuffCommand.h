/*
 * GmBuffCommand.h — pre9 local GM tool.
 *
 * /gmbuff <character|self> [strength]
 *
 * Applies the standard character-builder enhancement set (the frog's
 * "Enhance Character": 6 medical attribute buffs + 3 performance buffs)
 * to the named ONLINE player, with every buff amount multiplied by
 * <strength> (default 1, clamped 0.1 - 1000). Privileged (staff) only.
 */

#ifndef GMBUFFCOMMAND_H_
#define GMBUFFCOMMAND_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "QueueCommand.h"

class GmBuffCommand : public QueueCommand {
public:
	GmBuffCommand(const String& name, ZoneProcessServer* server)
			: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr || !ghost->isPrivileged()) {
			creature->sendSystemMessage("/gmbuff is a staff command.");
			return INSUFFICIENTPERMISSION;
		}

		String targetName;
		float strength = 1.f;

		try {
			UnicodeTokenizer args(arguments);
			args.getStringToken(targetName);

			if (args.hasMoreTokens())
				strength = args.getFloatToken();
		} catch (Exception& e) {
			creature->sendSystemMessage("SYNTAX: /gmbuff <character|self> [strength]");
			return INVALIDPARAMETERS;
		}

		if (strength < 0.1f)
			strength = 0.1f;
		else if (strength > 1000.f)
			strength = 1000.f;

		ManagedReference<PlayerManager*> playerManager = server->getZoneServer()->getPlayerManager();
		ManagedReference<CreatureObject*> targetPlayer = nullptr;

		if (targetName.toLowerCase() == "self")
			targetPlayer = creature;
		else
			targetPlayer = playerManager->getPlayer(targetName);

		if (targetPlayer == nullptr) {
			creature->sendSystemMessage("/gmbuff: player '" + targetName + "' is not online.");
			return INVALIDTARGET;
		}

		ObjectController* controller = creature->getZoneServer()->getObjectController();
		controller->logAdminCommand(creature, this, target, arguments);

		if (targetPlayer != creature) {
			Locker crossLocker(targetPlayer, creature);
			playerManager->enhanceCharacterScaled(targetPlayer, strength);
		} else {
			playerManager->enhanceCharacterScaled(targetPlayer, strength);
		}

		StringBuffer msg;
		msg << "/gmbuff: enhanced " << targetPlayer->getFirstName() << " at " << strength << "x strength.";
		creature->sendSystemMessage(msg.toString());

		return SUCCESS;
	}
};

#endif /* GMBUFFCOMMAND_H_ */
