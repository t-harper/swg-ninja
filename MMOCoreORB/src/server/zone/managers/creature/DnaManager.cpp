/*
 * DNAManager.cpp
 *
 *  Created on: July 7, 2012
 *      Author: washu
 */

#include "DnaManager.h"
#include "templates/manager/TemplateManager.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"
#include "server/zone/objects/tangible/component/dna/DnaComponent.h"
#include "server/zone/objects/tangible/deed/pet/PetDeed.h"
#include "server/zone/managers/crafting/labratories/Genetics.h"
#include "server/zone/managers/crafting/CraftingManager.h"

// #define DEBUG_GENETIC_LAB
// #define DEBUG_GENERATION_SAMPLE
// #define WRITE_DNA_TABLE

AtomicInteger DnaManager::loadedDnaData;

DnaManager::DnaManager() : Logger("DnaManager") {
	lua = new Lua();
	lua->init();
	lua->registerFunction("addQualityTemplate", addQualityTemplate);

	lua->setGlobalInt("FORTITUDE", DnaManager::FORTITUDE);
	lua->setGlobalInt("ENDURANCE", DnaManager::ENDURANCE);
	lua->setGlobalInt("CLEVERNESS", DnaManager::CLEVERNESS);
	lua->setGlobalInt("COURAGE", DnaManager::COURAGE);
	lua->setGlobalInt("POWER", DnaManager::POWER);
	lua->setGlobalInt("DEPENDABILITY", DnaManager::DEPENDABILITY);
	lua->setGlobalInt("DEXTERITY", DnaManager::DEXTERITY);
	lua->setGlobalInt("FIERCENESS", DnaManager::FIERCENESS);
	lua->setGlobalInt("HARDINESS", DnaManager::HARDINESS);
	lua->setGlobalInt("INTELLIGENCE", DnaManager::INTELLIGENCE);
}

DnaManager::~DnaManager() {
	if (lua != nullptr) {
		delete lua;
		lua = nullptr;
	}
}

void DnaManager::loadSampleData() {
	info("Loading DNA Information",true);
	try {
		lua->runFile("scripts/managers/dna_manager.lua");
		LuaObject luaObject = lua->getGlobalObject("DNACharacteristics");

#ifdef WRITE_DNA_TABLE
		FileWriter* writer = new FileWriter(new File("scripts/managers/dna_manager_new.lua"));
#endif

			if (luaObject.isValidTable()) {
#ifdef WRITE_DNA_TABLE
				int lastDam = 0;
				int lastHAM = 2000;
				float lastHit = 0.100f;
				int lastArmor = 0;
				int lastRegen = 0;
#endif

				for (int i = 1; i <= luaObject.getTableSize(); ++i) {
					LuaObject statRow = luaObject.getObjectAt(i);

					if (statRow.isValidTable()) {
						int level = statRow.getIntAt(1);
						int dps = statRow.getIntAt(2);
						float hit = statRow.getFloatAt(3);
						int ham = statRow.getIntAt(4);
						int armorBase = statRow.getIntAt(5);
						int regen = statRow.getIntAt(6);

#ifdef WRITE_DNA_TABLE
						StringBuffer table;

						if (i <= 20) {
							lastDam = (i * 2);
							lastHAM = ((i - 1) * 100.f) + 3000;
							lastHit = ((i - 1) * 1.00f) + 10.0f;
							lastArmor = 0;
							lastRegen = ((i - 1) * 4.00f) + 4.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						} else if (i <= 30) {
							lastDam += 10;
							lastHAM += 250;
							lastHit += 0.30f;
							lastArmor += 25;
							lastRegen += 3.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						} else if (i <= 40) {
							lastDam += 10;
							lastHAM += 200;
							lastHit += 0.30f;
							lastArmor += 25;
							lastRegen += 3.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						} else if (i <= 50) {
							lastDam += 3;
							lastHAM += 50;
							lastHit += 0.20f;
							lastArmor += 50;
							lastRegen += 2.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						} else if (i <= 60) {
							lastDam += 2;
							lastHAM += 50;
							lastHit += 0.20f;
							lastArmor += 50;
							lastRegen += 2.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						} else {
							lastDam += 2;
							lastHAM += 100;
							lastHit += 0.225f;
							lastArmor += 50;
							lastRegen += 2.0f;

							table << "	{ " << level << ", " << lastDam << ", " << lastHit << ", " << lastHAM << ", " << lastArmor << ", " << lastRegen << "},";
						}

						writer->writeLine(table.toString());
#endif

						dnaDPS.add(dps);
						dnaArmor.add(armorBase);
						dnaHam.add(ham);
						dnaHit.add(hit);
						dnaRegen.add(regen);
					}
					statRow.pop();
				}
			}
			luaObject.pop();
	} catch (Exception& e) {
		error(e.getMessage());
		e.printStackTrace();
	}
	info("Loaded " + String::valueOf(dnaDPS.size()) + " dna stats.", true);
	delete lua;
	lua = nullptr;
}

int DnaManager::generateXp(int creatureLevel) {
	float x1 = 0.00001896378 * (creatureLevel * 4);
	float x2 = 0.0025801845 * (creatureLevel * 3);
	float x3 = 0.1673150401 * (creatureLevel * 2);
	float x4 = 6.757844921 * creatureLevel;
	float x5 = 46.75746899f;
	return (int)ceil(x1-x2+x3+x4+x5);
}
int DnaManager::addQualityTemplate(lua_State * L) {
	int qual = lua_tointeger(L,-2);
	String ascii = lua_tostring(L,-1);
	uint32 crc = (uint32) ascii.hashCode();
	DnaManager::instance()->qualityTemplates.put(qual,crc);
	return 0;
}

void DnaManager::generationalSample(PetDeed* deed, CreatureObject* player, int quality) {
	if (deed == nullptr || player == nullptr)
		return;

#ifdef DEBUG_GENERATION_SAMPLE
	info(true) << "DnaManager::generationalSample - called";
#endif

	auto zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return;

	auto craftingManager = zoneServer->getCraftingManager();

	if (craftingManager == nullptr)
		return;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory == nullptr)
		return;

	if (inventory->isContainerFullRecursive()) {
		StringIdChatParameter err("survey", "no_inv_space");
		player->sendSystemMessage(err);
		player->setPosture(CreaturePosture::UPRIGHT, true);

		return;
	}

	const CreatureTemplate* creatureTemplate = deed->getCreatureTemplate();

	if (creatureTemplate == nullptr) {
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "generationalSample - Creature Template is null";
#endif
		return;
	}

	int ferocity = creatureTemplate->getFerocity();
	int creatureLevel = deed->getLevel();

	int hardiness = Genetics::hamToValue(deed->getHealth(), quality);
	int fortitude = Genetics::randomizeValue(deed->getFortitude(), quality);
	int dexterity = Genetics::hamToValue(deed->getAction(), quality);
	int endurance = Genetics::randomizeValue(500, quality);
	int intellect = Genetics::hamToValue(deed->getMind(), quality);
	int cleverness = Genetics::hitChanceToValue(deed->getHitChance(), quality);
	int dependability = Genetics::dietToValue(creatureTemplate->getDiet(), quality);
	int courage = Genetics::meatTypeToValue(creatureTemplate->getMeatType(), quality);
	int fierceness = Genetics::ferocityToValue(ferocity, quality);
	int power = Genetics::damageToValue((deed->getMinDamage() + deed->getMaxDamage()) / 2, quality);

#ifdef DEBUG_GENERATION_SAMPLE
	info(true) << "Hardiness: " << hardiness;
	info(true) << "Fortitude: " << fortitude;
	info(true) << "Dexterity: " << dexterity;
	info(true) << "Endurance: " << endurance;
	info(true) << "Intellect: " << intellect;
	info(true) << "Cleverness: " << cleverness;
	info(true) << "Dependability: " << dependability;
	info(true) << "Courage: " << courage;
	info(true) << "Fierceness: " << fierceness;
	info(true) << "Power: " << power;
#endif

	// calculate rest of stats here
	ManagedReference<DnaComponent*> prototype = zoneServer->createObject(qualityTemplates.get(quality), 1).castTo<DnaComponent*>();

	if (prototype == nullptr) {
		return;
	}

	Locker clocker(prototype);

	// Check Here for unique npcs
	prototype->setSource(deed->getTemplateName());
	prototype->setQuality(quality);
	prototype->setLevel(creatureLevel);

	String serial = craftingManager->generateSerial();

	// Set Serial Number
	prototype->setSerialNumber(serial);

	// Set Genetic Stats
	prototype->setStats(cleverness, endurance, fierceness, power, intellect, courage, dependability, dexterity, fortitude, hardiness);

	prototype->setStun(deed->getStun());
	prototype->setKinetic(deed->getKinetic());
	prototype->setEnergy(deed->getEnergy());
	prototype->setBlast(deed->getBlast());
	prototype->setHeat(deed->getHeat());
	prototype->setCold(deed->getCold());
	prototype->setElectric(deed->getElectric());
	prototype->setAcid(deed->getAcid());
	prototype->setSaber(deed->getSaber());
	prototype->setRanged(deed->getRanged());
	prototype->setArmorRating(deed->getArmor());
	prototype->setSpecialAttackOne(deed->getSpecial1());
	prototype->setSpecialAttackTwo(deed->getSpecial2());

	// info(true) << "DnaManager::generationalSample - checking resistances";

	if (deed->isSpecialResist(SharedWeaponObjectTemplate::STUN)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::STUN);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist STUN";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::KINETIC)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::KINETIC);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist KINETIC";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::ENERGY)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ENERGY);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist ENERGY";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::BLAST)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::BLAST);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist BLAST";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::HEAT)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::HEAT);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist HEAT";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::COLD)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::COLD);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist COLD";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::ELECTRICITY)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ELECTRICITY);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist ELECTRICITY";
#endif
	}
	if (deed->isSpecialResist(SharedWeaponObjectTemplate::ACID)) {
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ACID);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist ACID";
#endif
	}

	/*if (deed->isSpecialResist(SharedWeaponObjectTemplate::LIGHTSABER))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::LIGHTSABER);
#ifdef DEBUG_GENERATION_SAMPLE
		info(true) << "setting special resist LIGHTSABER";
#endif
	*/

	Locker locker(inventory, prototype);

	if (inventory->transferObject(prototype, -1, true, false)) {
		inventory->broadcastObject(prototype, true);
	} else {
		prototype->destroyObjectFromDatabase(true);
	}
}

void DnaManager::populateSample(DnaComponent* prototype, const CreatureTemplate* creatureTemplate,
 const SampleSource& state, int quality, bool maximumRoll) {
 const int hardiness = Genetics::hamToValue(state.health, quality, maximumRoll);
 const int fortitude = Genetics::resistanceToValue(state.effectiveResist, state.armor, quality, maximumRoll);
 const int dexterity = Genetics::hamToValue(state.action, quality, maximumRoll);
 const int endurance = Genetics::randomizeValue(500, quality, maximumRoll);
 const int intellect = Genetics::hamToValue(state.mind, quality, maximumRoll);
 const int cleverness = Genetics::hitChanceToValue(state.hitChance, quality, maximumRoll);
 const int dependability = Genetics::dietToValue(creatureTemplate->getDiet(), quality, maximumRoll);
 const int courage = Genetics::meatTypeToValue(creatureTemplate->getMeatType(), quality, maximumRoll);
 const int fierceness = Genetics::ferocityToValue(creatureTemplate->getFerocity(), quality, maximumRoll);
 const int power = Genetics::damageToValue(state.averageDamage, quality, maximumRoll);
 prototype->setQuality(quality);
 prototype->setLevel(state.level);
 prototype->setStats(cleverness, endurance, fierceness, power, intellect, courage, dependability, dexterity, fortitude, hardiness);
	prototype->setStun(creatureTemplate->getStun());
	prototype->setKinetic(creatureTemplate->getKinetic());
	prototype->setEnergy(creatureTemplate->getEnergy());
	prototype->setBlast(creatureTemplate->getBlast());
	prototype->setHeat(creatureTemplate->getHeat());
	prototype->setCold(creatureTemplate->getCold());
	prototype->setElectric(creatureTemplate->getElectricity());
	prototype->setAcid(creatureTemplate->getAcid());
	prototype->setSaber(creatureTemplate->getLightSaber());
	prototype->setArmorRating(creatureTemplate->getArmor());

	prototype->setRanged(state.ranged);

	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::STUN))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::STUN);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::KINETIC))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::KINETIC);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::ENERGY))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ENERGY);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::BLAST))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::BLAST);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::HEAT))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::HEAT);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::COLD))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::COLD);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::ELECTRICITY))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ELECTRICITY);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::ACID))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::ACID);
	if (creatureTemplate->isSpecialProtection(SharedWeaponObjectTemplate::LIGHTSABER))
		prototype->setSpecialResist(SharedWeaponObjectTemplate::LIGHTSABER);

	auto attackMap = creatureTemplate->getPrimaryAttacks();

	if (attackMap->size() > 0) {
		prototype->setSpecialAttackOne(String(attackMap->getCommand(0)));
		if(attackMap->size() > 1) {
			prototype->setSpecialAttackTwo(String(attackMap->getCommand(1)));
		}
	}

}

bool DnaManager::initializeNormalMaximumSample(DnaComponent* output, const CreatureTemplate* source, String& error) {
 // Creature::hasDNA() requires hasOrganics(); a carnivore template alone does
 // not make quest creatures with no harvestable material sampleable.
 if (source != nullptr && source->getHideMax() + source->getBoneMax() + source->getMeatMax() <= 0.f) {
  error = "DNA source has no harvestable organics";
  return false;
 }
 if (output == nullptr || source == nullptr || source->getLevel() < 1 || source->getLevel() > 75 ||
     !(source->getPvpBitmask() & ObjectFlag::ATTACKABLE) || source->getBaseHAMmax() < source->getBaseHAM() ||
     source->getDiet() == ObjectFlag::NONE ||
     (source->getCreatureBitmask() & ObjectFlag::BABY)) {
  error = "DNA source is not a legal level1..75 organic adult specimen";
  return false;
 }
 // The three HAM pools independently roll their source maximum. Resolve the
 // actual primary/secondary weapon choices without creating a world creature.
 // Sampling in either normal equipped state is legal; prefer the larger damage.
 bool ranged = false;
 int bestDamage = -1;
 for (const auto& weapon : {source->getPrimaryWeapon(), source->getSecondaryWeapon()}) {
  if (weapon.isEmpty() || weapon == "none") continue;
  int armorPiercing = 0;
  if (weapon != "unarmed") {
   auto loaded = dynamic_cast<SharedWeaponObjectTemplate*>(TemplateManager::instance()->getTemplate(weapon.hashCode()));
   if (loaded == nullptr) { error = "DNA source weapon is not a loaded explicit weapon template"; return false; }
   armorPiercing = loaded->getArmorPiercing();
   ranged = ranged || loaded->getAttackType() == SharedWeaponObjectTemplate::RANGEDATTACK;
  }
  const float modifier = 1.f - 0.1f * armorPiercing;
  const int low = source->getDamageMin() * modifier;
  const int high = source->getDamageMax() * modifier;
  bestDamage = Math::max(bestDamage, (low + high) / 2);
 }
 if (bestDamage < 0) bestDamage = (source->getDamageMin() + source->getDamageMax()) / 2;
 bool creature = false;
 for (int i = 0; i < source->getTemplates().size(); ++i) {
  auto loaded = TemplateManager::instance()->getTemplate(source->getTemplates().get(i).hashCode());
  if (loaded != nullptr && loaded->getGameObjectType() == SceneObjectType::CREATURE) creature = true;
 }
 if (!creature) { error = "DNA source has no loaded sampleable creature template"; return false; }
 float effective = 0.f;
 const int types[] = {SharedWeaponObjectTemplate::ACID, SharedWeaponObjectTemplate::BLAST, SharedWeaponObjectTemplate::COLD,
  SharedWeaponObjectTemplate::ELECTRICITY, SharedWeaponObjectTemplate::ENERGY, SharedWeaponObjectTemplate::HEAT,
  SharedWeaponObjectTemplate::KINETIC, SharedWeaponObjectTemplate::LIGHTSABER, SharedWeaponObjectTemplate::STUN};
 const float resists[] = {source->getAcid(), source->getBlast(), source->getCold(), source->getElectricity(), source->getEnergy(),
  source->getHeat(), source->getKinetic(), source->getLightSaber(), source->getStun()};
 for (int i = 0; i < 9; ++i) {
  if (!source->isSpecialProtection(types[i]) && resists[i] > 0.f) { effective = resists[i]; break; }
 }
 const int ham = source->getBaseHAMmax();
 // Preserve the ordinary integer division in generateSample.
 const SampleSource state{source->getLevel(), ham, ham, ham, (int)source->getArmor(), effective,
  source->getChanceHit(), (float)bestDamage, ranged};
 output->setSource(source->getObjectName());
 populateSample(output, source, state, 1, true);
 return true;
}

void DnaManager::generateSample(Creature* creature, CreatureObject* player, int quality){
	if (quality < 0 || quality > 7) {
		return;
	}

	if (creature == nullptr || player == nullptr)
		return;

	auto zoneServer = player->getZoneServer();

	if (zoneServer == nullptr)
		return;

	auto craftingManager = zoneServer->getCraftingManager();

	if (craftingManager == nullptr)
		return;

	ManagedReference<SceneObject*> inventory = player->getSlottedObject("inventory");

	if (inventory == nullptr)
		return;

	if (inventory->isContainerFullRecursive()) {
		StringIdChatParameter err("survey", "no_inv_space");

		player->sendSystemMessage(err);
		player->setPosture(CreaturePosture::UPRIGHT, true);

		return;
	}

	Locker lock(creature, player);

	auto creatureTemplate = dynamic_cast<const CreatureTemplate*>(creature->getCreatureTemplate());

	if (creatureTemplate == nullptr)
		return;

	// We should now have enough to generate a sample
	ManagedReference<DnaComponent*> prototype = zoneServer->createObject(qualityTemplates.get(quality), 1).castTo<DnaComponent*>();

	if (prototype == nullptr) {
		return;
	}

	Locker clocker(prototype);

	// Check Here for unique npcs
	const StringId* nameId = creature->getObjectName();

	if (nameId->getFile().isEmpty() || nameId->getStringID().isEmpty()) {
		prototype->setSource(creature->getCreatureName().toString());
	} else {
		prototype->setSource(nameId->getFullPath());
	}

 const SampleSource state{creature->getLevel(), creature->getMaxHAM(0), creature->getMaxHAM(3), creature->getMaxHAM(6),
  (int)creature->getArmor(), creature->getEffectiveResist(), creature->getChanceHit(),
  (float)((creature->getDamageMin() + creature->getDamageMax()) / 2), creature->isAiAgent() && creature->asAiAgent()->hasRangedWeapon()};
 prototype->setSerialNumber(craftingManager->generateSerial());
 populateSample(prototype, creatureTemplate, state, quality);

	Locker locker(inventory);

	if (inventory->transferObject(prototype, -1, true, false)) {
		inventory->broadcastObject(prototype, true);
	} else {
		prototype->destroyObjectFromDatabase(true);
	}
}

float DnaManager::valueForLevel(int type, int level) {
	float rc = 0;
	switch(type) {
		case HIT_LEVEL:
			return dnaHit.get(level);
		case DPS_LEVEL:
			return dnaDPS.get(level);
		case HAM_LEVEL:
			return dnaHam.get(level);
		case ARM_LEVEL:
			return dnaArmor.get(level);
		case REG_LEVEL:
			return dnaRegen.get(level);
	}
	return rc;
}

int DnaManager::levelForScore(int type, float value) {
	int rc = 0;

	switch (type) {
		case HIT_LEVEL:
			value *= 100.00f;

			for (int i = 0; i < dnaHit.size(); i++) {
				float lvminus = 1.00f, lvplus = 3.00f;

				if (i > 0)
					lvminus = dnaHit.get(i - 1);

				if (i < (dnaHit.size() - 1))
					lvplus = dnaHit.get(i + 1);

				float lv = dnaHit.get(i);

				if (value >= (lvminus + lv) / 2.000f && value <= (lvplus + lv) / 2.000f) {
					rc = i;
					break;
				}
			}

#ifdef DEBUG_GENETIC_LAB
			info(true) << "HIT_LEVEL - Checking: " << value << " Returning: " << rc;
#endif
			break;
		case DPS_LEVEL:
			for (int i = 0; i < dnaDPS.size(); i++) {
				float lvminus = 0, lvplus = 1000;

				if (i > 0)
					lvminus = dnaDPS.get(i - 1);

				if (i < (dnaDPS.size() - 1))
					lvplus = dnaDPS.get(i + 1);

				float lv = dnaDPS.get(i);

				if (value >= (lvminus + lv) / 2.0 && value <= (lvplus + lv) / 2.0) {
					rc = i;
					break;
				}
			}
#ifdef DEBUG_GENETIC_LAB
			info(true) << "DPS_LEVEL - Checking: " << value << " Returning: " << rc;
#endif
			break;
		case HAM_LEVEL:
			for (int i = 0; i < dnaHam.size(); i++) {
				float lvminus = 0, lvplus = 500000;

				if (i > 0)
					lvminus = dnaHam.get(i - 1);

				if (i < (dnaHam.size() - 1))
					lvplus = dnaHam.get(i + 1);

				float lv = dnaHam.get(i);

				if (value >= (lvminus + lv) / 2.0 && value <= (lvplus + lv) / 2.0) {
					rc = i;
					break;
				}
			}

#ifdef DEBUG_GENETIC_LAB
			info(true) << "HAM_LEVEL - Checking: " << value << " Returning: " << rc;
#endif
			break;
		case ARM_LEVEL:
			for (int i = 0; i < dnaArmor.size(); i++) {
				float lvminus = 0, lvplus = 2000;

				if (i > 0)
					lvminus = dnaArmor.get(i - 1);

				if (i < (dnaArmor.size() - 1))
					lvplus = dnaArmor.get(i + 1);

				float lv = dnaArmor.get(i);

				if (value >= (lvminus + lv) / 2.0 && value <= (lvplus + lv) / 2.0) {
					rc = i;
					break;
				}
			}
#ifdef DEBUG_GENETIC_LAB
			info(true) << "ARM_LEVEL - Checking: " << value << " Returning: " << rc;
#endif
			break;
		case REG_LEVEL:
			for (int i = 0; i < dnaRegen.size(); i++) {
				float lvminus = 0, lvplus = 50000;

				if (i > 0)
					lvminus = dnaRegen.get(i - 1);

				if (i < (dnaRegen.size() - 1))
					lvplus = dnaRegen.get(i + 1);

				float lv = dnaRegen.get(i);

				if (value >= (lvminus + lv) / 2.0 && value <= (lvplus + lv) / 2.0) {
					rc = i;
					break;
				}
			}
#ifdef DEBUG_GENETIC_LAB
			info(true) << "REG_LEVEL - Checking: " << value << " Returning: " << rc;
#endif
			break;
		default:
			rc = 0;
	}

	return rc;
}
