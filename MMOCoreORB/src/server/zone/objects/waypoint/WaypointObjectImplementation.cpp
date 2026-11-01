/*
 * WaypointObjectImplementation.cpp
 *
 *  Created on: 28/12/2009
 *      Author: victor
 */

#include "server/zone/objects/waypoint/WaypointObject.h"
#include "server/zone/Zone.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/radial/RadialOptions.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

#include <cmath>

namespace {
	constexpr uint8 GM_PLANETWARP_RADIAL = RadialOptions::SERVER_MENU10;

	bool canPlanetwarpFromWaypoint(CreatureObject* player) {
		if (player == nullptr)
			return false;

		PlayerObject* ghost = player->getPlayerObject();

		return ghost != nullptr && ghost->isPrivileged();
	}

	bool isSafePlanetwarpState(CreatureObject* player) {
		if (player == nullptr || player->isDead() || player->isIncapacitated() || player->isRidingMount() ||
				player->isPilotingShip() || player->isInShipStation() || player->isOnboardPobShip())
			return false;

		Zone* currentZone = player->getZone();

		return currentZone != nullptr && !currentZone->isSpaceZone();
	}
}

void WaypointObjectImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	IntangibleObjectImplementation::loadTemplateData(templateData);

	cellID = 0; //?

	unknown = 0;
	planetCRC = 0;

	color = COLOR_BLUE;
	active = 0;

	specialTypeID = 0;
}

String WaypointObjectImplementation::getDetailedDescription() const {
	if (detailedDescription.isEmpty())
		return SceneObjectImplementation::getDetailedDescription();

	return detailedDescription;
}

void WaypointObjectImplementation::insertToMessage(BaseMessage* msg) {
	msg->writeInt(cellID); // cellID
	msg->writeFloat(getPositionX());
	msg->writeFloat(getPositionZ()); //Z
	msg->writeFloat(getPositionY());
	msg->writeLong(unknown); //?
	msg->writeInt(planetCRC);

	customName.toBinaryStream(msg);

	msg->writeLong(getObjectID());
	msg->writeByte(color);
	msg->writeByte(active);
}

void WaypointObjectImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	IntangibleObjectImplementation::fillAttributeList(alm, object);

	if (questDetails.length() > 0)
		alm->insertAttribute("quest_details", questDetails);
}

void WaypointObjectImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	SceneObjectImplementation::fillObjectMenuResponse(menuResponse, player);

	if (menuResponse != nullptr && canPlanetwarpFromWaypoint(player))
		menuResponse->addRadialMenuItem(GM_PLANETWARP_RADIAL, 3, "Planetwarp to Waypoint (GM)");
}

int WaypointObjectImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (selectedID != GM_PLANETWARP_RADIAL)
		return SceneObjectImplementation::handleObjectMenuSelect(player, selectedID);

	// Recheck authorization server-side so a forged radial selection cannot be
	// used by a player who was never offered the GM-only menu item.
	if (!canPlanetwarpFromWaypoint(player)) {
		if (player != nullptr)
			player->sendSystemMessage("Only a GM can planetwarp to a waypoint.");

		return 1;
	}

	// Avoid carrying mount, ship-station, or incapacitation relationships through
	// a direct zone transfer. Staff can retry after returning to a normal ground
	// state; ordinary indoor cells remain valid starting locations.
	if (!isSafePlanetwarpState(player)) {
		player->sendSystemMessage("Dismount and return to a normal ground state before planetwarping.");
		return 1;
	}

	ZoneServer* zoneServer = player->getZoneServer();

	if (zoneServer == nullptr || zoneServer->isServerLoading() || zoneServer->isServerShuttingDown()) {
		player->sendSystemMessage("Planetwarp is unavailable right now.");
		return 1;
	}

	Zone* targetZone = nullptr;

	// A planet waypoint must resolve to an enabled ground zone. Space waypoints
	// require a ship and are deliberately not treated as planet destinations.
	for (int i = 0; i < zoneServer->getZoneCount(); ++i) {
		Zone* zone = zoneServer->getZone(i);

		if (zone != nullptr && zone->getZoneName().hashCode() == planetCRC) {
			targetZone = zone;
			break;
		}
	}

	if (targetZone == nullptr || targetZone->isSpaceZone()) {
		player->sendSystemMessage("That waypoint does not point to an available planet.");
		return 1;
	}

	const float targetX = getPositionX();
	const float targetZ = getPositionZ();
	const float targetY = getPositionY();

	if (!std::isfinite(targetX) || !std::isfinite(targetZ) || !std::isfinite(targetY) ||
			std::fabs(targetZ) > 8192.f || !targetZone->isWithinBoundaries(Vector3(targetX, targetY, targetZ))) {
		player->sendSystemMessage("That waypoint has invalid or unsafe coordinates.");
		return 1;
	}

	String destination = targetZone->getZoneName();
	String waypointName = getDisplayedName();

	player->sendSystemMessage("Planetwarping to " + waypointName + " on " + destination + ".");
	player->switchZone(destination, targetX, targetZ, targetY, 0);

	return 0;
}
