#include "PerfectCraftingSpecialAdapter.h"
#include "labratories/GeneticLabratory.h"
#include "server/zone/managers/creature/CreatureTemplateManager.h"
#include "server/zone/managers/creature/DnaManager.h"
#include "server/zone/managers/loot/LootGroupMap.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/managers/loot/LootValues.h"
#include "server/zone/managers/loot/CrystalData.h"
#include "server/zone/objects/tangible/component/lightsaber/LightsaberCrystalComponent.h"
#include "server/zone/objects/tangible/component/genetic/GeneticComponent.h"
#include "server/zone/objects/tangible/misc/CustomIngredient.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include <cmath>
#include <iomanip>
#include <sstream>

namespace {
void appendValues(std::ostringstream& out, const CraftingValues& values) {
 for (int i = 0; i < values.getTotalExperimentalAttributes(); ++i) {
  const String& key = values.getAttribute(i);
  out << '|' << key.toCharArray() << ':' << values.getMinValue(key) << ':' << values.getMaxValue(key)
      << ':' << values.getCurrentValue(key) << ':' << values.getMaxPercentage(key)
      << ':' << values.getPrecision(key) << ':' << values.getCombineType(key);
 }
}
}

bool PerfectCraftingSpecialAdapter::initialize(const PerfectCraftingRecipe& recipe, TangibleObject* prototype,
 PerfectCraftingContext& context, String& fingerprint, String& error) {
 context.checkpoint();
 if (prototype == nullptr || prototype->isPersistent() || prototype->getParent() != nullptr ||
     prototype->getServerObjectCRC() != recipe.targetTemplate.hashCode()) {
  error = "Special input must be a new transient object of the catalog template";
  return false;
 }
 std::ostringstream out;
 out << std::setprecision(9) << "normal-special-v1|" << recipe.sourceProfile.toCharArray();
 if (recipe.kind == "fixed") {
  // Empty bounds and registration do not establish a normal source. Only a
  // catalog entry with explicit reviewed provider evidence may use this path.
  if (recipe.sourceSupport != "verified-statless-provider") {
   error = "Fixed source lacks verified normal provider evidence"; return false;
  }
  out << "|provider:" << recipe.sourceSupport.toCharArray();
  if (recipe.sourceProfile != "fixed:" + recipe.targetTemplate) {
   error = "Fixed source does not match target"; return false;
  }
  // Registration is not evidence of perfect variable statistics. A fixed
  // source must have genuinely fixed loaded bounds; otherwise its normal
  // generation needs an explicit recipe/loot/reward profile.
  auto loaded = dynamic_cast<SharedTangibleObjectTemplate*>(prototype->getObjectTemplate());
  if (loaded == nullptr) { error = "Fixed source has no loaded tangible template"; return false; }
  const auto attributes = loaded->getExperimentalAttributes();
  const auto minima = loaded->getExperimentalMin();
  const auto maxima = loaded->getExperimentalMax();
  if (attributes->size() != minima->size() || attributes->size() != maxima->size()) {
   error = "Fixed source has inconsistent loaded bounds"; return false;
  }
  for (int i = 0; i < attributes->size(); ++i) {
   if (!std::isfinite(minima->get(i)) || minima->get(i) != maxima->get(i)) {
    error = "Fixed source has variable stats without a normal generation profile"; return false;
   }
   auto component = dynamic_cast<Component*>(prototype);
   if (component != nullptr && component->getAttributeValue(attributes->get(i)) != minima->get(i)) {
    error = "Fixed component default does not match its loaded constant stat"; return false;
   }
   out << "|fixed:" << attributes->get(i).toCharArray() << ':' << minima->get(i);
  }
 } else if (recipe.kind == "loot" || recipe.kind == "crystal") {
  const std::string profile(recipe.sourceProfile.toCharArray());
  const auto first = profile.find(':');
  const auto last = profile.rfind(':');
  const bool survey = recipe.kind == "loot" && profile.compare(0, 7, "survey:") == 0;
  const std::string prefix = recipe.kind == "crystal" ? "crystal:" : survey ? "survey:" : "loot:";
  const bool qualified = recipe.kind == "crystal" || survey;
  if (profile.compare(0, prefix.size(), prefix) || first == std::string::npos || (qualified && last == first)) {
   error = "Malformed normal loot profile"; return false;
  }
  const String key(profile.substr(first + 1, qualified ? last-first-1 : std::string::npos).c_str());
  const auto item = LootGroupMap::instance()->getLootItemTemplate(key);
  if (item == nullptr || item->getDirectObjectTemplate() != recipe.targetTemplate) {
   error = "Loaded loot source does not match catalog target"; return false;
  }
  if (recipe.kind == "crystal") {
   auto crystal = dynamic_cast<LightsaberCrystalComponent*>(prototype);
   const std::string colorProfile = profile.substr(last + 1);
   if (crystal == nullptr || colorProfile.compare(0, 6, "color-") != 0) {
    error = "Invalid crystal color source"; return false;
   }
   const String colorText(colorProfile.substr(6).c_str());
   const int color = Integer::valueOf(colorText);
   const auto bounds = item->getAttributesMapCopy();
   if (String::valueOf(color) != colorText || !bounds.hasExperimentalAttribute("color") ||
       !CrystalData::containsNormalStat((float)color, bounds.getMinValue("color"), bounds.getMaxValue("color")) ||
       !(color == 31 || (color >= 0 && color <= 11))) {
    error = "Crystal color is outside its normal loot source"; return false;
   }
   crystal->setColor(color);
   crystal->updateCrystal(color);
   if (!crystal->initializeNormalMaximum()) { error = "Missing normal crystal progression"; return false; }
   // TemplateManager stores the basename without .iff here. The loot manager's
   // progression map uses that same key in ordinary generateCrystalStats().
   const auto data = context.server->getLootManager()->getCrystalData(crystal->getObjectTemplate()->getTemplateFileName());
   if (data == nullptr) { error = "Missing crystal data"; return false; }
   out << '|' << data->getMinDamage() << ':' << data->getMaxDamage() << '|' << data->getMinHitpoints() << ':' << data->getMaxHitpoints()
       << '|' << data->getMinHealthSac() << ':' << data->getMaxHealthSac() << '|' << data->getMinActionSac() << ':' << data->getMaxActionSac()
       << '|' << data->getMinMindSac() << ':' << data->getMaxMindSac() << '|' << data->getMinAttackSpeed() << ':' << data->getMaxAttackSpeed()
       << '|' << data->getMinForceCost() << ':' << data->getMaxForceCost() << '|' << data->getMinWoundChance() << ':' << data->getMaxWoundChance();
  } else {
   if (survey) {
    if (profile.substr(last + 1) != "density95" || recipe.sourceSupport != "verified-village-survey-provider") {
     error = "Village resource requires its verified density95 survey provider"; return false;
    }
    auto resource = dynamic_cast<CustomIngredient*>(prototype);
    if (resource == nullptr) { error = "Survey source is not a custom resource ingredient"; return false; }
    std::set<std::string> attributes;
    if (key == "village_ardanium_ii") attributes = {"res_potential_energy", "res_quality"};
    else if (key == "village_wind_crystal") attributes = {"res_potential_energy"};
    else if (key == "village_ostrine") attributes = {"res_malleability", "res_quality"};
    else if (key == "village_endrine") attributes = {"res_malleability", "res_quality", "res_toughness"};
    else if (key == "village_rudic") attributes = {"res_conductivity", "res_decay_resist", "res_quality", "res_shock_resistance"};
    else { error = "Unknown normal village survey resource"; return false; }
    std::set<std::string> loadedAttributes;
    for (int i = 0; i <= 4; ++i) {
     String attribute;
     resource->getAttributeAndValue(attribute, i);
     if (!attribute.isEmpty()) loadedAttributes.insert(attribute.toCharArray());
    }
    if (loadedAttributes != attributes) { error = "Loaded village resource attributes differ from its normal survey provider"; return false; }
    // FsSurvey.giveResourceStats: density95 => average950, inclusive +50
    // is attainable independently for every listed attribute, capped at1000.
    // The direct-loot Gaussian is a different provider and is not used here.
    resource->clearAttributes();
    out << "|provider:FsSurvey.giveResourceStats|density:95|roll:50";
    for (const auto& attribute : attributes) {
     resource->addAttribute(String(attribute.c_str()), 1000);
     out << '|' << attribute << ":1000";
    }
   } else if (prototype->isCustomIngredient()) {
    error = "Custom resource ingredient requires a verified normal survey profile"; return false;
   }
   LootValues values(item, 350, LootValues::EXPERIMENTAL, true);
   prototype->updateCraftingValues(&values, true);
   appendValues(out, values);
   if (!item->getCustomObjectName().isEmpty()) prototype->setCustomObjectName(item->getCustomObjectName(), false);
   const auto names = item->getCustomizationStringNames();
   const auto choices = item->getCustomizationValues();
   for (int i = 0; i < names->size(); ++i) {
    if (i >= choices->size() || choices->get(i).size() == 0) { error = "Invalid loot customization source"; return false; }
    const int value = choices->get(i).get(0);
    prototype->setCustomizationVariable(names->get(i), value, false);
    out << "|custom:" << names->get(i).toCharArray() << ':' << value;
   }
   // These inputs are components. Static/random weapon DOT or wearable skill
   // generation requires a separate complete source profile, never omission.
   if (item->getSkillMods()->size() || item->getStaticDotValues()->size() || item->getRandomDotChance() > 0) {
    error = "Loot input requires a specialized skill/DOT source profile"; return false;
   }
  }
 } else if (recipe.kind == "dna") {
  const std::string profile(recipe.sourceProfile.toCharArray());
  const auto end = profile.rfind(':');
  if (profile.compare(0,4,"dna:") || end <= 4 || (profile.substr(end+1) != "quality1-max" && profile.substr(end+1) != "quality1")) {
   error = "Invalid normal DNA source profile"; return false;
  }
  auto sample = dynamic_cast<DnaComponent*>(prototype);
  const String name(profile.substr(4,end-4).c_str());
  auto source = CreatureTemplateManager::instance()->getTemplate(name);
  if (!DnaManager::initializeNormalMaximumSample(sample, source, error)) return false;
  out << '|' << source->getLevel() << ':' << source->getBaseHAM() << ':' << source->getBaseHAMmax()
      << ':' << source->getDamageMin() << ':' << source->getDamageMax() << ':' << source->getChanceHit()
      << ':' << source->getArmor() << ':' << source->getFerocity() << ':' << source->getDiet();
 } else {
  error = "Unknown special source kind"; return false;
 }
 fingerprint = String(out.str().c_str());
 return true;
}

bool PerfectCraftingSpecialAdapter::finalizeGenetic(const PerfectCraftingRecipe& recipe, TangibleObject* prototype,
 ManufactureSchematic* schematic, PerfectCraftingContext& context, String& fingerprint, String& error) {
 context.checkpoint();
 if (prototype == nullptr || prototype->getGameObjectType() != SceneObjectType::GENETICCOMPONENT || schematic == nullptr || schematic->getSlotCount() != 5) {
  error = "Genetic recipe requires five real DNA roles"; return false;
 }
 std::set<std::string> roles;
 for (int i = 0; i < schematic->getSlotCount(); ++i) {
  auto slot = dynamic_cast<ComponentSlot*>(schematic->getSlot(i));
  if (slot == nullptr || !slot->isFull() || dynamic_cast<DnaComponent*>(slot->getPrototype()) == nullptr) {
   error = "Genetic ingredient is missing or not DNA"; return false;
  }
  roles.insert(slot->getSlotName().toCharArray());
 }
 for (const char* role : {"physique_profile", "prowess_profile", "mental_profile", "psychological_profile", "aggression_profile"}) {
  if (!roles.count(role)) { error = "Missing genetic role"; return false; }
 }
 GeneticLabratory lab;
 lab.initialize(context.server);
 if (!lab.setNormalMaximumCraftingValues(prototype, schematic)) { error = "Genetic experimentation did not reach every normal cap"; return false; }
 auto values = schematic->getCraftingValues();
 if (!values->hasExperimentalAttribute("fortitude")) { error = "Genetic initialization failed"; return false; }
 prototype->updateCraftingValues(values, true);
 std::ostringstream out;
 out << std::setprecision(9) << "normal-genetic-v1|" << recipe.variantId.toCharArray();
 appendValues(out, *values);
 auto genetic = static_cast<GeneticComponent*>(prototype);
 out << '|' << genetic->getSpecial1().toCharArray() << '|' << genetic->getSpecial2().toCharArray() << '|' << genetic->getRanged();
 fingerprint = String(out.str().c_str());
 return true;
}
