#include "gtest/gtest.h"
#include "server/zone/managers/crafting/labratories/Genetics.h"
#include "server/zone/managers/loot/CrystalData.h"
#include "server/zone/managers/crafting/labratories/GeneticLabratory.h"

TEST(PerfectCraftingSpecial, QualityOneUsesNormalSamplingUpperEndpoint) {
 EXPECT_EQ(520, Genetics::randomizeValue(500, 1, true));
 EXPECT_EQ(770, Genetics::dietToValue(ObjectFlag::HERBIVORE, 1, true));
 EXPECT_EQ(520, Genetics::dietToValue(ObjectFlag::CARNIVORE, 1, true));
 EXPECT_EQ(853, Genetics::hamToValue(15000, 1, true));
 EXPECT_EQ(770, Genetics::resistanceToValue(25, 1, 1, true));
 EXPECT_EQ(979, Genetics::damageToValue(710, 1, true));
}
TEST(PerfectCraftingSpecial, ProgressionIntervalsPreserveNegativeBenefits) {
 EXPECT_TRUE(CrystalData::containsNormalStat(-9, 0, -9));
 EXPECT_TRUE(CrystalData::containsNormalStat(-0.6f, 0.f, -0.6f));
 EXPECT_TRUE(CrystalData::containsNormalStat(-9.9f, 0.f, -9.9f));
 EXPECT_TRUE(CrystalData::containsNormalStat(50, 1, 50));
 EXPECT_TRUE(CrystalData::containsNormalStat(7, 7, 7));
 EXPECT_FALSE(CrystalData::containsNormalStat(-10, 0, -9));
 EXPECT_FALSE(CrystalData::containsNormalStat(51, 1, 50));
 EXPECT_FALSE(CrystalData::containsNormalStat(6, 7, 7));
}
TEST(PerfectCraftingSpecial, DeterministicSpecialIsAnAttainableNormalOutcome) {
 EXPECT_EQ(String("dizzyattack"), GeneticLabratory::selectNormalSpecial("dizzyattack", "blindattack", "", "", "", 100, "defaultattack"));
 EXPECT_EQ(String("blindattack"), GeneticLabratory::selectNormalSpecial("", "dizzyattack", "blindattack", "", "", 100, "dizzyattack"));
 EXPECT_EQ(String("defaultattack"), GeneticLabratory::selectNormalSpecial("creatureareableeding", "blindattack", "", "", "", 100, "defaultattack"));
 EXPECT_EQ(String("defaultattack"), GeneticLabratory::selectNormalSpecial("blindattack", "", "", "", "", 751, "defaultattack"));
}

#include "templates/LootItemTemplate.h"
#include "server/zone/managers/loot/LootValues.h"
#include "server/zone/managers/loot/LootAttributeType.h"

namespace {
class NormalLootSource : public LootItemTemplate {
public:
 NormalLootSource(int minimum, int maximum) : LootItemTemplate("normal-test-source") {
  levelMin = minimum; levelMax = maximum;
  objectType = SceneObjectType::COMPONENT;
  attributesMap.addExperimentalAttribute("fixed", "fixed", 3, 90, 0, false, LootAttributeType::STATIC);
  attributesMap.addExperimentalAttribute("uniform", "uniform", 3, 9, 0, false, LootAttributeType::UNIFORM);
  attributesMap.addExperimentalAttribute("reverse", "reverse", 0, -9, 0, false, LootAttributeType::NORMAL);
  attributesMap.addExperimentalAttribute("dynamic", "dynamic", 5, 20, 0, false, LootAttributeType::DYNAMIC);
  attributesMap.addExperimentalAttribute("integerFraction", "integerFraction", 3.2f, 9.8f, 0, false, LootAttributeType::UNIFORM);
  attributesMap.addExperimentalAttribute("zeroDynamic", "zeroDynamic", 0, 9.8f, 0, false, LootAttributeType::DYNAMIC);
  attributesMap.addExperimentalAttribute("fractionDynamic", "fractionDynamic", 3.2f, 9.8f, 0, false, LootAttributeType::DYNAMIC);
 }
};
}
TEST(PerfectCraftingSpecial, NormalLootUsesSourceEndpointsAndNeverExceptionalMultipliers) {
 NormalLootSource source(1, 350);
 LootValues values(&source, 350, LootValues::LEGENDARY, true);
 EXPECT_FLOAT_EQ(3, values.getCurrentValue("fixed"));
 EXPECT_FLOAT_EQ(9, values.getCurrentValue("uniform"));
 EXPECT_FLOAT_EQ(-9, values.getCurrentValue("reverse"));
 EXPECT_FLOAT_EQ(20, values.getCurrentValue("dynamic"));
 EXPECT_FLOAT_EQ(9, values.getCurrentValue("integerFraction"));
 EXPECT_FLOAT_EQ(9, values.getCurrentValue("zeroDynamic"));
 EXPECT_FLOAT_EQ(9.8f, values.getCurrentValue("fractionDynamic"));
 EXPECT_FLOAT_EQ(1, values.getCurrentValue("modifier"));
 EXPECT_FLOAT_EQ(1, values.getMaxPercentage("dynamic"));
 NormalLootSource staticSource(0, 0);
 LootValues disabled(&staticSource, 350, LootValues::LEGENDARY, true);
 EXPECT_FLOAT_EQ(5, disabled.getCurrentValue("dynamic"));
 EXPECT_FLOAT_EQ(0, disabled.getCurrentValue("modifier"));
}

#include "conf/ConfigManager.h"
#include "templates/manager/DataArchiveStore.h"
#include "server/zone/managers/creature/CreatureTemplateManager.h"
#include "server/zone/managers/creature/DnaManager.h"
#include "server/zone/objects/tangible/component/genetic/GeneticComponent.h"
#include "server/zone/objects/manufactureschematic/ingredientslots/ComponentSlot.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "server/zone/managers/crafting/PerfectCraftingSpecialAdapter.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/objects/tangible/misc/CustomIngredient.h"
#include "server/zone/objects/tangible/component/droid/DroidComponent.h"
#include "server/zone/objects/resource/simplexnoise/SimplexNoise.h"
#include "templates/datatables/DataTableIff.h"
#include <cstring>
#include <new>

namespace {
class DnaMemberReader : public DnaComponentImplementation {
public:
 using DnaComponentImplementation::readObjectMember;
};
class GeneticMemberReader : public GeneticComponentImplementation {
public:
 using GeneticComponentImplementation::readObjectMember;
};
class DroidConstructorProbe : public DroidComponentImplementation {
public:
 bool hasZeroModuleDefaults() const {
  return autoRepairPower == 0 && combatRating == 0 && detonationRating == 0 && harvestBonus == 0 &&
   stimpackSpeed == 0 && stimpackCapacity == 0 && trapBonus == 0;
 }
};
// Full SceneObject reload resolves ZoneReference and invokes server lifecycle.
// Standalone tests use the real writer and generated readers for typed members;
// full graph/zone reload is exercised by the running-server acceptance suite.
template<typename Implementation>
bool restoreTypedMembers(Implementation* target, ObjectInputStream& input, std::initializer_list<const char*> names) {
 std::set<uint32> remaining;
 for (const char* name : names) remaining.insert(String(name).hashCode());
 const auto count = input.readShort();
 for (int i = 0; i < count; ++i) {
  const uint32 hash = input.readInt();
  const uint32 size = input.readInt();
  const int offset = input.getOffset();
  if (size > (uint32)(input.size() - offset)) return false;
  if (remaining.erase(hash) && !target->readObjectMember(&input, hash)) return false;
  input.setOffset(offset + size);
 }
 return remaining.empty();
}
void loadSpecialTestSources() {
 ConfigManager::instance()->loadConfigData();
 DataArchiveStore::instance()->loadTres(ConfigManager::instance()->getTrePath(), ConfigManager::instance()->getTreFiles());
 auto templates = TemplateManager::instance();
 if (templates->loadedTemplatesCount == 0) templates->loadLuaTemplates();
 if (CreatureTemplateManager::instance()->getTemplate(String("mutant_rancor")) == nullptr) CreatureTemplateManager::instance()->loadTemplates();
}
}
TEST(PerfectCraftingSpecial, DetachedDroidConstructorDefinesAllPersistedModuleFloats) {
 alignas(DroidConstructorProbe) unsigned char storage[sizeof(DroidConstructorProbe)];
 std::memset(storage, 0xff, sizeof(storage));
 auto component = ::new (storage) DroidConstructorProbe();
 EXPECT_TRUE(component->hasZeroModuleDefaults());
 component->~DroidConstructorProbe();
}
TEST(PerfectCraftingSpecialPipeline, SurveyProviderMaximumBindsLoadedQuestAndActualResourceAttributes) {
 loadSpecialTestSources();
 auto loot = LootGroupMap::instance();
 if (loot->getLootItemTemplate("village_wind_crystal") == nullptr) loot->initialize();
 auto templates = TemplateManager::instance();
 auto stream = templates->openIffFile("datatables/player/quests.iff");
 ASSERT_NE(nullptr, stream);
 DataTableIff quests;
 quests.readObject(stream);
 delete stream;
 std::map<std::string, std::pair<std::string, std::string>> steps;
 for (int i = 0; i < quests.getTotalRows(); ++i) {
  String name, next, target;
  quests.getRow(i)->getValue(0, name);
  quests.getRow(i)->getValue(5, next);
  quests.getRow(i)->getValue(7, target);
  steps[name.toCharArray()] = {next.toCharArray(), target.toCharArray()};
 }
 // Ordinary concentration1 permits0.99, seed0 and these in-map offsets.
 // SurveySession forwards percent density; the observer can receive95.
 EXPECT_GE(SimplexNoise::noise(6440 * .0006f, 5080 * .0006f, 0.f) * .99f * 100.f, 95.f);
 for (const char* suffix : {"ardanium_ii", "wind_crystal", "ostrine", "endrine", "rudic"}) {
  const String key = "village_" + String(suffix);
  auto source = loot->getLootItemTemplate(key);
  ASSERT_NE(nullptr, source);
  const String target = "object/tangible/loot/quest/" + String(suffix) + ".iff";
  ASSERT_EQ(target, source->getDirectObjectTemplate());
  bool hasNormalSurveyReward = false;
  for (const auto& step : steps) {
   if (step.first.compare(0, 14, "survey_phase2_") && step.first.compare(0, 14, "survey_phase3_")) continue;
   auto reward = steps.find(step.second.first);
   if (reward != steps.end() && reward->second.second == target.toCharArray() &&
       reward->second.first != "fs_survey_phase2_reward" && reward->second.first != "fs_survey_phase3_reward") hasNormalSurveyReward = true;
  }
  ASSERT_TRUE(hasNormalSurveyReward) << target.toCharArray();
  auto loaded = templates->getTemplate(target.hashCode());
  ASSERT_NE(nullptr, loaded);
  ManagedReference<CustomIngredient*> prototype = new CustomIngredient();
  prototype->initializeContainerObjectsMap();
  prototype->setServerObjectCRC(target.hashCode());
  prototype->loadTemplateData(loaded);
  std::set<std::string> attributes;
  for (int i = 0; i < 5; ++i) {
   String attribute;
   prototype->getAttributeAndValue(attribute, i);
   if (!attribute.isEmpty()) attributes.insert(attribute.toCharArray());
  }
  ASSERT_FALSE(attributes.empty());
  PerfectCraftingRecipe recipe;
  recipe.kind = "loot"; recipe.targetTemplate = target;
  recipe.sourceProfile = "survey:" + key + ":density95";
  recipe.sourceSupport = "verified-village-survey-provider";
  PerfectCraftingContext context(nullptr, true);
  String fingerprint, error;
  ASSERT_TRUE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, fingerprint, error)) << error.toCharArray();
  for (const auto& attribute : attributes) EXPECT_EQ(1000, prototype->getValueOf(String(attribute.c_str())));
  EXPECT_EQ(0U, context.allocationCount());
  String repeated;
  ASSERT_TRUE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, repeated, error));
  EXPECT_EQ(fingerprint, repeated);
  recipe.sourceProfile = "survey:" + key + ":density100";
  EXPECT_FALSE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, repeated, error));
  recipe.sourceProfile = "survey:" + key + ":density95";
  recipe.sourceSupport = "";
  EXPECT_FALSE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, repeated, error));
 }
}
TEST(PerfectCraftingSpecialPipeline, CrystalProgressionUsesTheNormalLoadedTemplateKey) {
 loadSpecialTestSources();
 ManagedReference<LootManager*> manager = new LootManager(nullptr, nullptr, nullptr);
 manager->initialize();
 for (const char* basename : {"lightsaber_module_force_crystal", "lightsaber_module_krayt_dragon_pearl"}) {
  const String path = "object/tangible/component/weapon/lightsaber/" + String(basename) + ".iff";
  auto loaded = TemplateManager::instance()->getTemplate(path.hashCode());
  ASSERT_NE(nullptr, loaded);
  EXPECT_EQ(String(basename), loaded->getTemplateFileName());
  // This is the lookup used by ordinary generation and normal initialization.
  EXPECT_NE(nullptr, manager->getCrystalData(loaded->getTemplateFileName()));
  EXPECT_EQ(nullptr, manager->getCrystalData(path));
 }
}
TEST(PerfectCraftingSpecialPipeline, NamedDonorsUseLoadedLegalSourcesAndRejectUnsampleableSources) {
 loadSpecialTestSources();
 auto templates = TemplateManager::instance();
 auto dnaTemplate = templates->getTemplate(String("object/tangible/component/dna/dna_sample_very_high.iff").hashCode());
 ASSERT_NE(nullptr, dnaTemplate);
 for (const char* name : {"mutant_rancor", "kusak_hunter", "enraged_defender"}) {
  auto source = CreatureTemplateManager::instance()->getTemplate(String(name));
  ASSERT_NE(nullptr, source) << name;
  ManagedReference<DnaComponent*> sample = new DnaComponent();
  sample->initializeContainerObjectsMap();
  sample->loadTemplateData(dnaTemplate);
  String error;
  ASSERT_TRUE(DnaManager::initializeNormalMaximumSample(sample, source, error)) << error.toCharArray();
  EXPECT_EQ(1, sample->getQuality());
  EXPECT_LE(sample->getLevel(), 75);
  EXPECT_FLOAT_EQ(Genetics::hamToValue(source->getBaseHAMmax(), 1, true), sample->getHardiness());
  EXPECT_FLOAT_EQ(Genetics::dietToValue(source->getDiet(), 1, true), sample->getDependability());
  EXPECT_FLOAT_EQ(source->getKinetic(), sample->getKinetic());
  EXPECT_EQ(source->isSpecialProtection(SharedWeaponObjectTemplate::KINETIC), sample->isSpecialResist(SharedWeaponObjectTemplate::KINETIC));
  ObjectOutputStream output;
  sample->writeObject(&output);
  ObjectInputStream input;
  output.copy(&input, 0); input.reset();
  DnaMemberReader restored;
  ASSERT_TRUE(restoreTypedMembers(&restored, input,
   {"DnaComponent.hardiness", "DnaComponent.kinResist", "DnaComponent.special1"}));
  EXPECT_FLOAT_EQ(sample->getHardiness(), restored.getHardiness());
  EXPECT_FLOAT_EQ(sample->getKinetic(), restored.getKinetic());
  EXPECT_EQ(sample->getSpecialAttackOne(), restored.getSpecialAttackOne());
 }
 ManagedReference<DnaComponent*> sample = new DnaComponent();
 String error;
 EXPECT_FALSE(DnaManager::initializeNormalMaximumSample(sample, nullptr, error));
 auto invalid = CreatureTemplateManager::instance()->getTemplate(String("krayt_dragon_ancient"));
 ASSERT_NE(nullptr, invalid);
 ASSERT_GT(invalid->getLevel(), 75);
 EXPECT_FALSE(DnaManager::initializeNormalMaximumSample(sample, invalid, error));
 auto noOrganics = CreatureTemplateManager::instance()->getTemplate(String("ancient_reptillian"));
 ASSERT_NE(nullptr, noOrganics);
 ASSERT_EQ(57, noOrganics->getLevel());
 ASSERT_EQ(0.f, noOrganics->getHideMax() + noOrganics->getBoneMax() + noOrganics->getMeatMax());
 EXPECT_FALSE(DnaManager::initializeNormalMaximumSample(sample, noOrganics, error));
 EXPECT_EQ(String("DNA source has no harvestable organics"), error);
}

TEST(PerfectCraftingSpecialPipeline, GeneticCapsAndHiddenResistanceSurviveFinalizationAndSerialization) {
 loadSpecialTestSources();
 auto templates = TemplateManager::instance();
 auto source = CreatureTemplateManager::instance()->getTemplate(String("mutant_rancor"));
 ASSERT_NE(nullptr, source);
 auto draftTemplate = templates->getTemplate(String("object/draft_schematic/bio_engineer/dna_template/dna_template_generic.iff").hashCode());
 ASSERT_NE(nullptr, draftTemplate);
 ManagedReference<DraftSchematic*> draft = new DraftSchematic();
 draft->loadTemplateData(draftTemplate);
 ManagedReference<ManufactureSchematic*> schematic = new ManufactureSchematic();
 schematic->setDraftSchematic(draft);
 ASSERT_TRUE(schematic->initializeGeneratedIngredientSlots());
 auto dnaTemplate = templates->getTemplate(String("object/tangible/component/dna/dna_sample_very_high.iff").hashCode());
 ASSERT_NE(nullptr, dnaTemplate);
 for (int i = 0; i < schematic->getSlotCount(); ++i) {
  auto slot = dynamic_cast<ComponentSlot*>(schematic->getSlot(i));
  ASSERT_NE(nullptr, slot);
  ManagedReference<DnaComponent*> sample = new DnaComponent();
  sample->initializeContainerObjectsMap();
  sample->loadTemplateData(dnaTemplate);
  String error;
  ASSERT_TRUE(DnaManager::initializeNormalMaximumSample(sample, source, error)) << error.toCharArray();
  sample->setUseCount(0, false);
  String serial = "(normal-special-test)";
  sample->setSerialNumber(serial);
  ASSERT_TRUE(slot->addGeneratedIngredient(sample));
 }
 ManagedReference<GeneticComponent*> prototype = new GeneticComponent();
 prototype->initializeContainerObjectsMap();
 auto target = templates->getTemplate(draft->getTanoCRC());
 ASSERT_NE(nullptr, target);
 prototype->loadTemplateData(target);
 auto values = schematic->getCraftingValues();
 values->setManufactureSchematic(schematic);
 PerfectCraftingContext context(nullptr, true);
 PerfectCraftingRecipe recipe;
 recipe.variantId = "tank";
 String fingerprint, error;
 ASSERT_TRUE(PerfectCraftingSpecialAdapter::finalizeGenetic(recipe, prototype, schematic, context, fingerprint, error)) << error.toCharArray();
 int visible = 0;
 for (int i = 0; i < values->getTotalExperimentalAttributes(); ++i) {
  const String& name = values->getAttribute(i);
  if (values->isHidden(name)) continue;
  ++visible;
  EXPECT_FLOAT_EQ(values->getCapValue(name) / 1000.f, values->getCurrentPercentage(name)) << name.toCharArray();
 }
 EXPECT_EQ(10, visible);
 EXPECT_LT(values->getMaxPercentage("power"), 1.f);
 EXPECT_GT(values->getCurrentValue("dna_comp_armor_energy"), 0.f);
 const float resistance = values->getCurrentValue("dna_comp_armor_energy");
 values->recalculateValues(false);
 EXPECT_FLOAT_EQ(resistance, values->getCurrentValue("dna_comp_armor_energy"));
 EXPECT_EQ((int)values->getCurrentValue("power"), prototype->getPower());
 EXPECT_EQ((int)values->getCurrentValue("fortitude"), prototype->getFortitude());
 EXPECT_EQ((int)values->getCurrentValue("hardiness"), prototype->getHardiness());
 EXPECT_FLOAT_EQ(resistance, prototype->getEnergy());
 EXPECT_EQ(String("defaultattack"), prototype->getSpecial1());
 EXPECT_EQ(String("dizzyattack"), prototype->getSpecial2());
 ObjectOutputStream output;
 prototype->writeObject(&output);
 ObjectInputStream input;
 output.copy(&input, 0); input.reset();
 GeneticMemberReader restored;
 ASSERT_TRUE(restoreTypedMembers(&restored, input,
  {"GeneticComponent.power", "GeneticComponent.fortitude", "GeneticComponent.special2", "GeneticComponent.ranged", "GeneticComponent.energyResist"}));
 EXPECT_EQ(prototype->getPower(), restored.getPower());
 EXPECT_EQ(prototype->getFortitude(), restored.getFortitude());
 EXPECT_EQ(prototype->getSpecial2(), restored.getSpecial2());
 EXPECT_EQ(prototype->getRanged(), restored.getRanged());
 EXPECT_FLOAT_EQ(prototype->getEnergy(), restored.getEnergy());
}

TEST(PerfectCraftingSpecialPipeline, FixedSourcesRequireExplicitNormalProviderProof) {
 loadSpecialTestSources();
 const String target = "object/tangible/component/food/secrets/secret_imperial_biochem.iff";
 auto loaded = TemplateManager::instance()->getTemplate(target.hashCode());
 ASSERT_NE(nullptr, loaded);
 ManagedReference<Component*> prototype = new Component();
 prototype->loadTemplateData(loaded);
 prototype->setServerObjectCRC(target.hashCode());
 const int propertiesBefore = prototype->getPropertyCount();
 PerfectCraftingContext context(nullptr, true);
 PerfectCraftingRecipe recipe;
 recipe.kind = "fixed";
 recipe.targetTemplate = target;
 recipe.sourceProfile = "fixed:" + target;
 for (const char* support : {"", "unsupported-no-normal-provider", "pending", "verified-statful-provider"}) {
  recipe.sourceSupport = support;
  String fingerprint = "unchanged", error;
  EXPECT_FALSE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, fingerprint, error));
  EXPECT_EQ(String("Fixed source lacks verified normal provider evidence"), error);
  EXPECT_EQ(String("unchanged"), fingerprint);
  EXPECT_EQ(propertiesBefore, prototype->getPropertyCount());
  EXPECT_EQ(0U, context.allocationCount());
 }
 // The recognized status only opens the existing source/template/bounds checks;
 // it must never bypass them or assert this unsupported candidate is a reward.
 recipe.sourceSupport = "verified-statless-provider";
 recipe.sourceProfile = "fixed:object/tangible/component/food/secrets/secret_rebel_biochem.iff";
 String fingerprint, error;
 EXPECT_FALSE(PerfectCraftingSpecialAdapter::initialize(recipe, prototype, context, fingerprint, error));
 EXPECT_EQ(String("Fixed source does not match target"), error);
}
