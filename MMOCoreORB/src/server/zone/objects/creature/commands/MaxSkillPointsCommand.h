/*
 * MaxSkillPointsCommand.h — pre9 local GM tool.
 *
 * /maxSkillPoints <character|self> <amount>
 *
 * Sets the target ONLINE player's per-character skill point pool
 * (PlayerObject.maxSkillPoints, pre9 local field) and adjusts their
 * available points by the difference. Clamped 250 - 5000. The wallet
 * self-repair in SkillManager recomputes against this pool on every
 * skill change. Privileged (staff) only.
 *
 * NOTE: the client skill window displays a compiled-in /250 maximum;
 * the server is authoritative and training beyond 250 works — the
 * client's "available" number simply goes negative cosmetically.
 */

#ifndef MAXSKILLPOINTSCOMMAND_H_
#define MAXSKILLPOINTSCOMMAND_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "QueueCommand.h"

class MaxSkillPointsCommand : public QueueCommand {
public:
	MaxSkillPointsCommand(const String& name, ZoneProcessServer* server)
			: QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr || !ghost->isPrivileged()) {
			creature->sendSystemMessage("/maxSkillPoints is a staff command.");
			return INSUFFICIENTPERMISSION;
		}

		String targetName;
		int amount = 0;

		try {
			UnicodeTokenizer args(arguments);
			args.getStringToken(targetName);
			amount = args.getIntToken();
		} catch (Exception& e) {
			creature->sendSystemMessage("SYNTAX: /maxSkillPoints <character|self> <amount 250-5000>");
			return INVALIDPARAMETERS;
		}

		if (amount < 250)
			amount = 250;
		else if (amount > 5000)
			amount = 5000;

		ManagedReference<PlayerManager*> playerManager = server->getZoneServer()->getPlayerManager();
		ManagedReference<CreatureObject*> targetPlayer = nullptr;

		if (targetName.toLowerCase() == "self")
			targetPlayer = creature;
		else
			targetPlayer = playerManager->getPlayer(targetName);

		if (targetPlayer == nullptr) {
			creature->sendSystemMessage("/maxSkillPoints: player '" + targetName + "' is not online.");
			return INVALIDTARGET;
		}

		ObjectController* controller = creature->getZoneServer()->getObjectController();
		controller->logAdminCommand(creature, this, target, arguments);

		Locker crossLocker(targetPlayer, creature);

		PlayerObject* targetGhost = targetPlayer->getPlayerObject();

		if (targetGhost == nullptr)
			return GENERALERROR;

		int oldMax = targetGhost->getMaxSkillPoints();
		targetGhost->setMaxSkillPoints(amount);
		targetGhost->addSkillPoints(amount - oldMax);

		StringBuffer msg;
		msg << "/maxSkillPoints: " << targetPlayer->getFirstName() << " " << oldMax << " -> " << amount
		    << " (available adjusted by " << (amount - oldMax) << ").";
		creature->sendSystemMessage(msg.toString());

		if (targetPlayer != creature) {
			StringBuffer tmsg;
			tmsg << "Your skill point pool is now " << amount
			     << ". (The skill window still displays /250 — the extra capacity is real.)";
			targetPlayer->sendSystemMessage(tmsg.toString());
		}

		return SUCCESS;
	}
};

#endif /* MAXSKILLPOINTSCOMMAND_H_ */
