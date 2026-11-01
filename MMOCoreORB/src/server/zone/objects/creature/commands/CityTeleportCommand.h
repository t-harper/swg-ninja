/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.

	SWG Ninja local staff command:
	/cityteleport <destination>
*/

#ifndef CITYTELEPORTCOMMAND_H_
#define CITYTELEPORTCOMMAND_H_

#include "QueueCommand.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/collision/CollisionManager.h"
#include "server/zone/managers/objectcontroller/ObjectController.h"
#include "server/zone/objects/player/PlayerObject.h"

#include <cmath>

class CityTeleportCommand : public QueueCommand {
private:
	struct Destination {
		const char* token;
		const char* displayName;
		const char* zoneName;
		float x;
		float y;
	};

	static const Destination* getDestinations(int& count) {
		// Canonical city/outpost catalog from managers/mission/mission_cities.lua.
		// Arrival positions favor known outdoor starport, shuttle, starting-location,
		// or screenplay points. Vertical position is resolved from the live terrain.
		static const Destination destinations[] = {
			{"bela_vistal", "Bela Vistal", "corellia", 6644.269f, -5922.5225f},
			{"coronet", "Coronet", "corellia", -137.f, -4723.f},
			{"doaba_guerfel", "Doaba Guerfel", "corellia", 3349.8933f, 5598.1362f},
			{"kor_vella", "Kor Vella", "corellia", -3138.f, 2808.f},
			{"tyrena", "Tyrena", "corellia", -5045.f, -2294.f},
			{"vreni_island", "Vreni Island", "corellia", -5551.9473f, -6059.9673f},

			{"dantooine_mining_outpost", "Dantooine Mining Outpost", "dantooine", -637.f, 2504.4f},
			{"dantooine_agro_outpost", "Dantooine Agro Outpost", "dantooine", 1569.66f, -6415.7598f},
			{"dantooine_imperial_outpost", "Dantooine Imperial Outpost", "dantooine", -4208.6602f, -2350.24f},

			{"dathomir_trade_outpost", "Trade Outpost", "dathomir", 618.89258f, 3092.0142f},
			{"dathomir_science_outpost", "Science Outpost", "dathomir", -49.021923f, -1584.7278f},

			{"endor_smuggler_outpost", "Smuggler Outpost", "endor", -950.59241f, 1553.4125f},
			{"endor_research_outpost", "Research Outpost", "endor", 3201.6599f, -3499.76f},

			{"nyms_stronghold", "Nym's Stronghold", "lok", 462.f, 5124.f},

			{"theed", "Theed", "naboo", -4856.f, 4162.f},
			{"keren", "Keren", "naboo", 1371.5938f, 2747.9043f},
			{"moenia", "Moenia", "naboo", 4800.f, -4700.f},
			{"lake_retreat", "The Lake Retreat", "naboo", -5494.4224f, -21.837162f},
			{"deeja_peak", "Dee'ja Peak", "naboo", 5331.9375f, -1576.6733f},
			{"kaadara", "Kaadara", "naboo", 5209.f, 6677.f},

			{"narmle", "Narmle", "rori", -5374.0718f, -2188.6143f},
			{"restuss", "Restuss", "rori", 5340.f, 5734.f},
			{"rori_rebel_outpost", "Rebel Outpost", "rori", 3691.9023f, -6403.4404f},

			{"dearic", "Dearic", "talus", 263.58401f, -2952.1284f},
			{"nashal", "Nashal", "talus", 4453.7212f, 5354.3345f},
			{"talus_imperial_outpost", "Talus Imperial Outpost", "talus", -2227.4f, 2319.9f},

			{"bestine", "Bestine", "tatooine", -1290.f, -3590.f},
			{"mos_espa", "Mos Espa", "tatooine", -2902.f, 2130.f},
			{"mos_eisley", "Mos Eisley", "tatooine", 3528.f, -4804.f},
			{"mos_entha", "Mos Entha", "tatooine", 1266.0996f, 3065.1392f},
			{"mos_taike", "Mos Taike", "tatooine", 3821.75f, 2343.11f},
			{"anchorhead", "Anchorhead", "tatooine", 47.565128f, -5338.9072f},
			{"wayfar", "Wayfar", "tatooine", -5167.56f, -6610.58f},

			{"yavin4_mining_outpost", "Yavin IV Mining Outpost", "yavin4", -267.23914f, 4896.3013f},
			{"yavin4_labor_outpost", "Yavin IV Labor Outpost", "yavin4", -6921.6733f, -5726.5161f},
		};

		count = sizeof(destinations) / sizeof(destinations[0]);
		return destinations;
	}

	static String normalizeDestination(const String& rawDestination) {
		String token = rawDestination.trim().toLowerCase();
		token = token.replaceAll("'", "");
		token = token.replaceAll("-", "_");
		token = token.replaceAll(" ", "_");
		token = token.replaceAll("\t", "_");

		while (token.contains("__"))
			token = token.replaceAll("__", "_");

		if (token == "nym" || token == "nyms" || token == "nym_stronghold")
			return "nyms_stronghold";
		if (token == "bel_vistal")
			return "bela_vistal";
		if (token == "dee_ja_peak")
			return "deeja_peak";
		if (token == "the_lake_retreat")
			return "lake_retreat";
		if (token == "dant_mining_outpost" || token == "dant_mining")
			return "dantooine_mining_outpost";
		if (token == "dant_agro_outpost" || token == "dant_agro" || token == "agro_outpost" || token == "dantooine_pirate_outpost")
			return "dantooine_agro_outpost";
		if (token == "dant_imperial_outpost" || token == "dant_imperial")
			return "dantooine_imperial_outpost";
		if (token == "dath_trade_outpost" || token == "dath_trade" || token == "trade_outpost")
			return "dathomir_trade_outpost";
		if (token == "dath_science_outpost" || token == "dath_science" || token == "science_outpost" || token == "survey_outpost")
			return "dathomir_science_outpost";
		if (token == "smuggler_outpost")
			return "endor_smuggler_outpost";
		if (token == "research_outpost" || token == "neutral_outpost")
			return "endor_research_outpost";
		if (token == "rebel_outpost")
			return "rori_rebel_outpost";
		if (token == "yavin_mining_outpost" || token == "yavin_iv_mining_outpost")
			return "yavin4_mining_outpost";
		if (token == "yavin_labor_outpost" || token == "yavin_iv_labor_outpost" || token == "labor_outpost")
			return "yavin4_labor_outpost";

		return token;
	}

	static const Destination* findDestination(const String& token) {
		int count = 0;
		const Destination* destinations = getDestinations(count);

		for (int i = 0; i < count; ++i) {
			if (token == destinations[i].token)
				return &destinations[i];
		}

		return nullptr;
	}

	static void sendPlanetList(CreatureObject* creature, const String& zoneName, const String& displayName) {
		int count = 0;
		const Destination* destinations = getDestinations(count);
		StringBuffer message;
		message << displayName << ": ";
		bool first = true;

		for (int i = 0; i < count; ++i) {
			if (zoneName != destinations[i].zoneName)
				continue;

			if (!first)
				message << ", ";

			message << destinations[i].token;
			first = false;
		}

		creature->sendSystemMessage(message.toString());
	}

	static void sendDestinationList(CreatureObject* creature) {
		creature->sendSystemMessage("SYNTAX: /cityteleport <destination>  (use /cityteleport list to show this list)");
		sendPlanetList(creature, "corellia", "Corellia");
		sendPlanetList(creature, "dantooine", "Dantooine");
		sendPlanetList(creature, "dathomir", "Dathomir");
		sendPlanetList(creature, "endor", "Endor");
		sendPlanetList(creature, "lok", "Lok");
		sendPlanetList(creature, "naboo", "Naboo");
		sendPlanetList(creature, "rori", "Rori");
		sendPlanetList(creature, "talus", "Talus");
		sendPlanetList(creature, "tatooine", "Tatooine");
		sendPlanetList(creature, "yavin4", "Yavin IV");
		creature->sendSystemMessage("Destination names are case-insensitive; spaces and hyphens work like underscores.");
	}

public:
	CityTeleportCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr || !creature->isPlayerCreature())
			return GENERALERROR;

		PlayerObject* ghost = creature->getPlayerObject();

		// The command-table donor has no characterAbility, so authorization must
		// always be rechecked here even if a client forges the command packet.
		if (ghost == nullptr || !ghost->isPrivileged()) {
			creature->sendSystemMessage("/cityteleport is a staff command.");
			return INSUFFICIENTPERMISSION;
		}

		String destinationToken = normalizeDestination(arguments.toString());

		if (destinationToken.isEmpty() || destinationToken == "list" || destinationToken == "help" || destinationToken == "?") {
			sendDestinationList(creature);
			return SUCCESS;
		}

		if (destinationToken == "mining_outpost") {
			creature->sendSystemMessage("That name is ambiguous. Use dantooine_mining_outpost or yavin4_mining_outpost.");
			return INVALIDPARAMETERS;
		}

		if (destinationToken == "imperial_outpost") {
			creature->sendSystemMessage("That name is ambiguous. Use dantooine_imperial_outpost or talus_imperial_outpost.");
			return INVALIDPARAMETERS;
		}

		const Destination* destination = findDestination(destinationToken);

		if (destination == nullptr) {
			creature->sendSystemMessage("Unknown city destination '" + destinationToken + "'. Use /cityteleport list.");
			return INVALIDPARAMETERS;
		}

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		Zone* currentZone = creature->getZone();

		if (creature->isDead() || creature->isIncapacitated() || creature->isRidingMount() ||
				creature->isPilotingShip() || creature->isInShipStation() || creature->isOnboardPobShip() ||
				currentZone == nullptr || currentZone->isSpaceZone()) {
			creature->sendSystemMessage("Dismount and return to a normal ground state before using /cityteleport.");
			return INVALIDSTATE;
		}

		ZoneServer* zoneServer = creature->getZoneServer();

		if (zoneServer == nullptr || zoneServer->isServerLoading() || zoneServer->isServerShuttingDown()) {
			creature->sendSystemMessage("City teleport is unavailable right now.");
			return GENERALERROR;
		}

		Zone* targetZone = zoneServer->getZone(destination->zoneName);

		if (targetZone == nullptr || targetZone->isSpaceZone()) {
			creature->sendSystemMessage("That destination's planet is not available on this galaxy.");
			return INVALIDPARAMETERS;
		}

		const float targetX = destination->x;
		const float targetY = destination->y;

		if (!std::isfinite(targetX) || !std::isfinite(targetY) ||
				!targetZone->isWithinBoundaries(Vector3(targetX, targetY, 0.f))) {
			creature->sendSystemMessage("That city destination has invalid or unsafe coordinates.");
			return GENERALERROR;
		}

		const float targetZ = CollisionManager::getWorldFloorCollision(targetX, targetY, targetZone, false);

		if (!std::isfinite(targetZ) || std::fabs(targetZ) > 8192.f) {
			creature->sendSystemMessage("A safe landing height could not be found for that destination.");
			return GENERALERROR;
		}

		ObjectController* controller = zoneServer->getObjectController();

		if (controller != nullptr)
			controller->logAdminCommand(creature, this, target, arguments);

		creature->sendSystemMessage("Teleporting to " + String(destination->displayName) + ".");
		creature->setDirection(0);
		creature->switchZone(destination->zoneName, targetX, targetZ, targetY, 0);

		return SUCCESS;
	}
};

#endif // CITYTELEPORTCOMMAND_H_
