/*
 * PlayerContainerComponent.cpp
 *
 *  Created on: 26/05/2011
 *      Author: victor
 */

#include "PlayerContainerComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "server/zone/objects/tangible/wearables/ArmorObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/visibility/VisibilityManager.h"
#include "system/util/VectorMap.h"

namespace {
	/*
	 * Custom (non-stock) playable species reuse a stock body/skeleton for their
	 * appearance, so the clothing that fits that stock body also fits them. The
	 * stock wearable playerRaces lists only enumerate the ~10 stock playable
	 * species (+ vendor NPC variants), so without this mapping every custom
	 * species is hard-rejected at equip ("You lack the necessary requirements to
	 * wear this object"). Each custom species template is mapped to the stock
	 * race whose body its mesh is built on, verified from the client
	 * appearanceFilename .sat skeleton: the near-human species share
	 * appearance/skeleton/all_b.skt + hum_{m,f}_face and map to
	 * human_{male,female}; hutt (hutt.skt) and talz (muftak.skt) have unique
	 * skeletons and fall back to the gender-matched human body as the closest
	 * wearable base. Returns an empty String for stock/unknown templates, which
	 * then keep the original (unchanged) behavior.
	 */
	const String& getCustomSpeciesBaseRace(const String& race) {
		static const VectorMap<String, String> baseRaceMap = []() {
			const String humanMale = "object/creature/player/human_male.iff";
			const String humanFemale = "object/creature/player/human_female.iff";

			VectorMap<String, String> map;
			map.put("object/creature/player/aqualish_female.iff", humanFemale);
			map.put("object/creature/player/aqualish_male.iff", humanMale);
			map.put("object/creature/player/bith_female.iff", humanFemale);
			map.put("object/creature/player/bith_male.iff", humanMale);
			map.put("object/creature/player/chiss_female.iff", humanFemale);
			map.put("object/creature/player/chiss_male.iff", humanMale);
			map.put("object/creature/player/devaronian_male.iff", humanMale);
			map.put("object/creature/player/gotal_male.iff", humanMale);
			map.put("object/creature/player/gran_male.iff", humanMale);
			map.put("object/creature/player/gungan_male.iff", humanMale);
			map.put("object/creature/player/hutt_female.iff", humanFemale);
			map.put("object/creature/player/hutt_male.iff", humanMale);
			map.put("object/creature/player/ishi_tib_male.iff", humanMale);
			map.put("object/creature/player/nautolan_male.iff", humanMale);
			map.put("object/creature/player/nightsister_female.iff", humanFemale);
			map.put("object/creature/player/nikto_male.iff", humanMale);
			map.put("object/creature/player/quarren_male.iff", humanMale);
			map.put("object/creature/player/smc_female.iff", humanFemale);
			map.put("object/creature/player/talz_male.iff", humanMale);
			map.put("object/creature/player/togruta_female.iff", humanFemale);
			map.put("object/creature/player/weequay_male.iff", humanMale);

			return map;
		}();

		// get() returns an empty String (the map's nullValue) for any template
		// not in the table, i.e. stock species and non-player objects.
		return baseRaceMap.get(race);
	}
}

int PlayerContainerComponent::canAddObject(SceneObject* sceneObject, SceneObject* object, int containmentType, String& errorDescription) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return TransferErrorCode::PLAYERUSEMASKERROR;
	}

	if (object->isTangibleObject() && containmentType == 4) {
		TangibleObject* wearable = cast<TangibleObject*>(object);

		SharedTangibleObjectTemplate* tanoData = dynamic_cast<SharedTangibleObjectTemplate*>(wearable->getObjectTemplate());

		if (tanoData != nullptr) {
			const auto races = tanoData->getPlayerRaces();
			String race = creo->getObjectTemplate()->getFullTemplateString();

			if (!races->contains(race.hashCode())) {
				// Custom species aren't listed in the stock wearable playerRaces;
				// fall back to the stock base race their body is built on so they
				// can wear the same clothing. Stock species match directly above
				// and never reach this fallback, so their behavior is unchanged.
				const String& baseRace = getCustomSpeciesBaseRace(race);

				if (baseRace.isEmpty() || !races->contains(baseRace.hashCode())) {
					errorDescription = "You lack the necessary requirements to wear this object";

					return TransferErrorCode::PLAYERUSEMASKERROR;
				}
			}
		}

		if (creo->isPlayerCreature()) {
			if (!wearable->isNeutral()) {
				if (wearable->isImperial() && (creo->getFactionStatus() == FactionStatus::ONLEAVE || !creo->isImperial())) {
					errorDescription = "You lack the necessary requirements to wear this object";

					return TransferErrorCode::PLAYERUSEMASKERROR;
				}

				if (wearable->isRebel() && (creo->getFactionStatus() == FactionStatus::ONLEAVE || !creo->isRebel())) {
					errorDescription = "You lack the necessary requirements to wear this object";

					return TransferErrorCode::PLAYERUSEMASKERROR;
				}
			}
		}

		if (object->isArmorObject()) {
			PlayerManager* playerManager = sceneObject->getZoneServer()->getPlayerManager();

			if (!playerManager->checkEncumbrancies(creo, cast<ArmorObject*>(object))) {
				errorDescription = "You lack the necessary secondary stats to equip this item";

				return TransferErrorCode::NOTENOUGHENCUMBRANCE;
			}
		}

		if (object->isWearableObject()) {
			if (tanoData != nullptr) {
				const Vector<String>& skillsRequired = tanoData->getCertificationsRequired();

				if (skillsRequired.size() > 0) {
					bool hasSkill = false;

					for (int i = 0; i < skillsRequired.size(); i++) {
						const String& skill = skillsRequired.get(i);

						if (!skill.isEmpty() && creo->hasSkill(skill)) {
							hasSkill = true;
							break;
						}
					}

					if (!hasSkill) {
						errorDescription = "@error_message:insufficient_skill"; // You lack the skill to use this item.

						return TransferErrorCode::PLAYERUSEMASKERROR;
					}
				}
			}
		}

		if (object->isWeaponObject()) {
			WeaponObject* weapon = cast<WeaponObject*>(object);
			int bladeColor = weapon->getBladeColor();
			PlayerObject* ghost = creo->getPlayerObject();

			if (weapon->isJediWeapon()) {
				if (bladeColor == 31) {
					errorDescription = "@jedi_spam:lightsaber_no_color";
					return TransferErrorCode::PLAYERUSEMASKERROR;
				}

				if (weapon->getCraftersID() != creo->getObjectID() && !ghost->isPrivileged()) {
					errorDescription = "@jedi_spam:not_your_lightsaber";
					return TransferErrorCode::PLAYERUSEMASKERROR;
				}
			}
		}
	}

	return ContainerComponent::canAddObject(sceneObject, object, containmentType, errorDescription);
}

/**
 * Is called when this object has been inserted with an object
 * @param object object that has been inserted
 */
int PlayerContainerComponent::notifyObjectInserted(SceneObject* sceneObject, SceneObject* object) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return 0;
	}

	if (object->isArmorObject()) {
		PlayerManager* playerManager = sceneObject->getZoneServer()->getPlayerManager();
		playerManager->applyEncumbrancies(creo, cast<ArmorObject*>(object));
	}

	if (object->isTangibleObject()) {
		ManagedReference<TangibleObject*> tano = object->asTangibleObject();

		if (tano != nullptr) {
			// creo->info(true) << "Adding template & wearable skill mods from: " << tano->getDisplayedName();

			tano->addTemplateSkillMods(creo);
			tano->applySkillModsTo(creo);
		}
	}

	if (object->isInstrument() && creo->isEntertaining()) {
		creo->stopEntertaining();
	}

	// Update wearables vector
	if (object->isTangibleObject() && object->getArrangementDescriptorSize() != 0 && object->getArrangementDescriptor(0)->size() != 0) {
		const String& arrangement = object->getArrangementDescriptor(0)->get(0);

		if (arrangement != "mission_bag" && arrangement != "ghost" && arrangement != "bank") {
			creo->addWearableObject(object->asTangibleObject(), true);
		}
	}

	// Jedi stuff below.
	auto ghost = creo->getPlayerObject();

	if (ghost != nullptr && ghost->isJedi()) {
		if (object->isRobeObject()) {
			ghost->recalculateForcePower();
		} else if (object->isWeaponObject()) {
			WeaponObject* weaponObject = cast<WeaponObject*>(object);

			if (weaponObject->isJediWeapon()) {
				VisibilityManager::instance()->increaseVisibility(creo, VisibilityManager::SABERVISMOD);
			}
		}
	}

	return ContainerComponent::notifyObjectInserted(sceneObject, object);
}

/**
 * Is called when an object was removed
 * @param object object that has been inserted
 */
int PlayerContainerComponent::notifyObjectRemoved(SceneObject* sceneObject, SceneObject* object, SceneObject* destination) const {
	CreatureObject* creo = dynamic_cast<CreatureObject*>(sceneObject);

	if (creo == nullptr) {
		return 0;
	}

	if (object->isArmorObject()) {
		PlayerManager* playerManager = creo->getZoneServer()->getPlayerManager();
		playerManager->removeEncumbrancies(creo, cast<ArmorObject*>(object));
	}

	if (object->isTangibleObject()) {
		ManagedReference<TangibleObject*> tano = object->asTangibleObject();

		if (tano != nullptr) {
			// creo->info(true) << "Removing template & wearable skill mods from: " << tano->getDisplayedName();

			tano->removeTemplateSkillMods(creo);
			tano->removeSkillModsFrom(creo);
		}
	}

	if (object->isInstrument() && creo->isPlayingMusic()) {
		creo->stopEntertaining();
	}

	// Update wearables vector
	if (object->isTangibleObject() && object->getArrangementDescriptorSize() != 0 && object->getArrangementDescriptor(0)->size() != 0) {
		const String& arrangement = object->getArrangementDescriptor(0)->get(0); //CHK

		if (arrangement != "mission_bag" && arrangement != "ghost" && arrangement != "bank") {
			creo->removeWearableObject(object->asTangibleObject(), true);
		}
	}

	// Jedi stuff below.
	PlayerObject* ghost = creo->getPlayerObject();

	if (ghost != nullptr && ghost->isJedi()) {
		if (object->isRobeObject()) {
			ghost->recalculateForcePower();
		}
	}

	return ContainerComponent::notifyObjectRemoved(sceneObject, object, destination);
}
