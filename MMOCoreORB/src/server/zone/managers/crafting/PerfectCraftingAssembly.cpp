#include "PerfectCraftedItemFactory.h"
#include "server/zone/managers/crafting/ComponentMap.h"
#include "server/zone/managers/skill/SkillModManager.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "templates/customization/AssetCustomizationManagerTemplate.h"
#include "templates/params/RangedIntCustomizationVariable.h"

void PerfectCraftedItemFactory::applyVisibleComponents(TangibleObject* prototype, ManufactureSchematic* schematic) {
	if (prototype->isWeaponObject()) {
		unsigned int type = prototype->getClientGameObjectType();

		if (type == SceneObjectType::PISTOL || type == SceneObjectType::CARBINE || type == SceneObjectType::RIFLE) {
			uint32 tanoCRC = prototype->getClientObjectCRC();

			for (int i = 0; i < schematic->getSlotCount(); ++i) {
				ComponentSlot* compSlot = cast<ComponentSlot*>(schematic->getSlot(i));

				if (compSlot == nullptr) {
					continue;
				}

				ManagedReference<TangibleObject*> compTano = compSlot->getPrototype();

				if (compTano == nullptr) {
					continue;
				}

				const String& slotName = compSlot->getSlotName();

				if (slotName.isEmpty()) {
					continue;
				}

				const auto& ids = ComponentMap::instance()->getVisibleCRC(tanoCRC, slotName.hashCode());

				if (ids.size() == 0) {
					continue;
				}

				uint32 compCrc = compTano->getClientObjectCRC();

				for (int ii = 0; ii < ids.size(); ++ii) {
					uint32 key = ids.elementAt(ii).getKey();
					uint32 val = ids.elementAt(ii).getValue();

					if (key == 0 || val == 0) {
						continue;
					}

					if (slotName == "stock" || compCrc == key) {
						prototype->addVisibleComponent(val, false);
						break;
					}
				}
			}
		}
	}

}
void PerfectCraftedItemFactory::applySkillMods(TangibleObject* prototype, DraftSchematic* draft) {
	const VectorMap<String, int>* skillMods = draft->getDraftSchematicTemplate()->getSkillMods();

	for (int i = 0; i < skillMods->size(); i++) {
		const auto& mod = skillMods->elementAt(i);

		if (prototype->isWearableObject()) {
			WearableObject* wearable = cast<WearableObject*>(prototype);
			VectorMap<String, int>* wearableMods = wearable->getWearableSkillMods();

			if (wearableMods->contains(mod.getKey())) {
				int oldValue = wearableMods->get(mod.getKey());
				int newValue = mod.getValue() + oldValue;

				if (newValue > 25)
					newValue = 25;

				wearableMods->put(mod.getKey(), newValue);
				continue;
			}
		}

		prototype->addSkillMod(SkillModManager::WEARABLE, mod.getKey(), mod.getValue(), false);
	}
}

void PerfectCraftedItemFactory::applyWeaponDots(TangibleObject* prototype, DraftSchematic* draft) {
	if (!prototype->isWeaponObject()) return;
	auto weapon = cast<WeaponObject*>(prototype);
	const Vector<VectorMap<String, int>>* weaponDots = draft->getDraftSchematicTemplate()->getWeaponDots();

	for (int i = 0; i < weaponDots->size(); i++) {
		const auto& dot = weaponDots->elementAt(i);

		for (int j = 0; j < dot.size(); j++) {
			const String& property = dot.elementAt(j).getKey();
			int value = dot.elementAt(j).getValue();

			if (property == "type")
				weapon->addDotType(value);
			else if (property == "attribute")
				weapon->addDotAttribute(value);
			else if (property == "strength")
				weapon->addDotStrength(value);
			else if (property == "duration")
				weapon->addDotDuration(value);
			else if (property == "potency")
				weapon->addDotPotency(value);
			else if (property == "uses")
				weapon->addDotUses(value);
		}
	}
}

void PerfectCraftedItemFactory::applyAssemblyHooks(TangibleObject* prototype, DraftSchematic* draft, ManufactureSchematic* schematic) {
	applyVisibleComponents(prototype, schematic);
	applySkillMods(prototype, draft);
	applyWeaponDots(prototype, draft);
	auto templateData = dynamic_cast<SharedTangibleObjectTemplate*>(prototype->getObjectTemplate());
	if (templateData == nullptr) throw Exception("Missing tangible template");
	VectorMap<String, Reference<CustomizationVariable*> > colors;
	AssetCustomizationManagerTemplate::instance()->getCustomizationVariables(templateData->getAppearanceFilename().hashCode(), colors, true);
	for (int i = 0; i < colors.size(); ++i) {
		String name = colors.elementAt(i).getKey();
		if (prototype->isDroidDeedObject() && name == "/private/index_color_0") continue;
		auto variable = dynamic_cast<RangedIntCustomizationVariable*>(colors.get(i).get());
		if (variable != nullptr) prototype->setCustomizationVariable(name, variable->getDefaultValue());
	}
}
