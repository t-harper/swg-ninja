"""Behavioral source/contract checks. Native verification remains mandatory."""
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
GENERATOR = ROOT / 'scripts/tools/generate_perfect_factory_catalog.py'
OUTPUT = ROOT / 'bin/scripts/custom_scripts/managers/crafting/perfect_factory_catalog.lua'

class PerfectFactoryCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not GENERATOR.exists():
            return
        spec = importlib.util.spec_from_file_location('perfect_factory_generator', GENERATOR)
        cls.generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.generator)
        cls.catalog, cls.coverage = cls.generator.build_catalog(ROOT)
        cls.entries = {e['id']: e for e in cls.catalog['entries']}

    def setUp(self):
        self.assertTrue(GENERATOR.exists(), 'Source-backed product catalog generator is missing')

    def test_all_seeded_recipes_and_normalized_variants_are_preserved(self):
        recipes = [e for e in self.entries.values() if e['kind'] == 'recipe']
        self.assertEqual(len({e['draftPath'] for e in recipes}), 1795)
        self.assertEqual(len({e['targetTemplate'] for e in recipes}), 2012)
        self.assertEqual(len(self.catalog['exceptions']), 9)
        self.assertTrue(all(x['reason'] == 'incomplete-source' for x in self.catalog['exceptions']))

    def test_chef_aliases_include_novice_food_containers_and_additives(self):
        recipes = [e for e in self.entries.values() if e['kind'] == 'recipe' and 'Chef' in e['professions']]
        self.assertEqual(len({e['draftPath'] for e in recipes}), 87)
        for suffix in ['food/additive/additive_light.iff', 'food/additive/additive_medium.iff', 'food/additive/additive_heavy.iff', 'food/component/container_barrel.iff']:
            self.assertTrue(any(e['draftPath'].endswith(suffix) for e in recipes), suffix)

    def test_bio_engineer_retains_genetics_pet_deeds_tissues_and_medicine(self):
        recipes = [e for e in self.entries.values() if e['kind'] == 'recipe' and 'Bio-Engineer' in e['professions']]
        paths = {e['draftPath'] for e in recipes}
        self.assertEqual(len(paths), 105)
        self.assertEqual(sum('/creature/' in p for p in paths), 69)
        self.assertEqual(sum('/bio_component/' in p for p in paths), 28)
        self.assertEqual(sum('/utilities/' in p for p in paths), 7)
        self.assertTrue(any('/dna_template/' in p for p in paths))

    def test_compact_ids_are_unique_and_do_not_depend_on_display_labels(self):
        self.assertEqual(len(self.entries), len(self.catalog['entries']))
        for entry in self.entries.values():
            self.assertRegex(entry['id'], r'^[ri]_[0-9a-f]{32}$')
            self.assertEqual(self.generator.stable_id('recipe', 'a|b'), 'r_' + __import__('hashlib').sha256(b'recipe\0a|b').hexdigest()[:32])
            self.assertRegex(entry['qualitySignature'], r'^[0-9a-f]{64}$')

    def test_all_catalog_display_labels_are_ascii_for_sui(self):
        # SUI widens each String byte independently; UTF-8 punctuation becomes
        # several unsupported glyphs in both menu rows and created item names.
        for entry in self.catalog['entries']:
            self.assertTrue(entry['label'].isascii(), entry['id'] + ': ' + entry['label'])

    def test_real_bake_master_label_matches_lua_value(self):
        entry = next(e for e in self.entries.values() if e['draftPath'].endswith('/clothing_hat_chef_02.iff') and e['variantId']=='standard')
        self.assertEqual(entry['label'], "Bake Master's Cap")

    def test_every_slot_has_exact_zero_based_choice_or_explicit_optional_omit(self):
        for entry in self.entries.values():
            if entry['kind'] != 'recipe':
                continue
            slots = self.coverage['recipeSlots'][entry['draftPath']]
            expected = [s for s in slots if s['slotType'] != 0]
            choices = entry['ingredientChoices']
            self.assertEqual([x['slotIndex'] for x in choices], [s['slotIndex'] for s in expected], entry['id'])
            for choice, slot in zip(choices, expected):
                self.assertEqual(choice['quantity'], slot['quantity'])
                self.assertEqual(choice['slotType'], slot['slotType'])
                if choice.get('omit'):
                    self.assertIn(slot['slotType'], [3, 4])
                    self.assertNotIn('childId', choice)
                else:
                    self.assertIn(choice['childId'], self.entries)

    def test_refactor_once_consumes_a_base_without_a_recursive_self_edge(self):
        names = ['lightweight_turret_electronics', 'power_supply', 'primary_computer', 'regulator', 'reinforced_wall_module', 'unit_computer']
        for name in names:
            path = f'object/draft_schematic/community_crafting/component/{name}.iff'
            products = [e for e in self.entries.values() if e['draftPath'] == path]
            base = next(e for e in products if e['variantId'] == 'base')
            once = next(e for e in products if e['variantId'] == 'refactor-once')
            slot = next(s for s in self.coverage['recipeSlots'][path] if s['title'] == 'refactor')
            self.assertTrue(next(c for c in base['ingredientChoices'] if c['slotIndex'] == slot['slotIndex'])['omit'])
            self.assertEqual(next(c for c in once['ingredientChoices'] if c['slotIndex'] == slot['slotIndex'])['childId'], base['id'])

    def test_selected_graph_is_acyclic_and_never_multiplies_delivery_count(self):
        self.assertFalse(self.coverage['selectedCycles'])
        self.assertGreaterEqual(self.coverage['maximumExpandedPrototypeObjects'], 374)
        self.assertLess(self.coverage['maximumExpandedPrototypeObjects'], 16384)
        self.assertLessEqual(self.coverage['maximumSelectedDepth'], 32)
        self.assertEqual(self.coverage['maximumSingleObjectSlotQuantity'], 30)

    def test_source_candidates_are_pending_and_abstract_templates_are_not_products(self):
        for entry in self.entries.values():
            self.assertEqual(entry['availability'], 'pending')
            name = entry['targetTemplate'].rsplit('/', 1)[-1]
            self.assertFalse(name.startswith('shared_'), entry['targetTemplate'])
            if entry['kind'] != 'recipe':
                self.assertFalse(name.startswith('base_'), entry['targetTemplate'])
            if entry['kind'] != 'recipe':
                self.assertFalse(name.endswith('_base.iff'), entry['targetTemplate'])
            self.assertTrue(entry['sourceProfile'])
            self.assertTrue(entry['provenance'])
            self.assertIsInstance(entry['expectedFactoryEligible'], bool)
        self.assertTrue(any(e['kind'] == 'loot' and 'krayt_dragon_tissue_rare' in e['sourceProfile'] for e in self.entries.values()))
        self.assertTrue(any(e['kind'] == 'dna' for e in self.entries.values()))
        self.assertTrue(any(e['kind'] == 'crystal' for e in self.entries.values()))

    def test_fixed_candidates_have_explicit_unsupported_source_and_dependency_ledger(self):
        fixed = [e for e in self.entries.values() if e['kind']=='fixed']
        ledger = self.coverage['fixedSourceSupport']
        self.assertEqual({x['id'] for x in ledger}, {e['id'] for e in fixed})
        self.assertEqual(len(fixed),65)
        for e in fixed:
            self.assertEqual(e['provenance']['sourceSupport'],'unsupported-no-normal-provider')
            self.assertTrue(e['provenance']['sourceSupportReason'])
        for record in ledger:
            self.assertEqual(record['sourceSupport'],'unsupported-no-normal-provider')
            for consumer in record['directConsumers']:
                entry = self.entries[consumer['id']]
                choice = next(c for c in entry['ingredientChoices'] if c['slotIndex']==consumer['slotIndex'])
                self.assertEqual(choice['childId'],record['id'])
                self.assertEqual(consumer['omitAllowed'],choice['slotType'] in [3,4])
                for pid in consumer['supportedAlternativeIds']:
                    self.assertIn(pid,self.entries)
                    self.assertFalse(self.coverage['unsupportedDependencyProducts'].get(pid),pid)
            self.assertIn(record['id'], self.coverage['unsupportedDependencyProducts'])
        self.assertTrue(any(c['omitAllowed'] or c['supportedAlternativeIds'] for r in ledger for c in r['directConsumers']))

    def test_source_supported_defaults_do_not_require_unsupported_optional_secrets(self):
        blocked = self.coverage['unsupportedDependencyProducts']
        paths = ['object/draft_schematic/food/additive/additive_'+size+'.iff' for size in ['light','medium','heavy']]
        paths += ['object/draft_schematic/bio_engineer/bio_component/bio_component_food_heavy_'+name+'.iff' for name in ['flavor','filling','quantity','nutrition']]
        for path in paths:
            entry = next(e for e in self.entries.values() if e['draftPath']==path and e['variantId']=='standard')
            self.assertNotIn(entry['id'],blocked,path)
        for entry in self.entries.values():
            if entry['kind']=='recipe' and entry['variantId']=='standard':
                for choice in entry['ingredientChoices']:
                    if choice['slotType'] in [3,4] and choice.get('childId'):
                        self.assertNotIn(choice['childId'],blocked,entry['draftPath'])

    def test_selected_override_children_satisfy_effective_iff_predicates(self):
        overrides=json.loads((ROOT/'scripts/tools/perfect_factory_ancestry_overrides.json').read_text())['overrides']
        for e in self.entries.values():
            for c in e['ingredientChoices']:
                if not c.get('childId'):continue
                child=self.entries[c['childId']]
                if child['targetTemplate'] in overrides:
                    self.assertIn(c['predicate'],overrides[child['targetTemplate']]['ancestors'],e['id'])
                    self.assertIn('effectiveIffAncestry',child['provenance'])

    def test_explicit_zero_organic_donor_is_a_retained_unsampleable_source_exception(self):
        e=self.entries['i_7fe616404c127b63de710e88a82e8293']
        self.assertEqual(e['provenance']['sourceSupport'],'unsupported-unsampleable-dna')
        self.assertEqual(e['provenance']['organicAmounts'],{'meatAmount':0,'hideAmount':0,'boneAmount':0})
        self.assertIn(e['id'],self.coverage['unsupportedDependencyProducts'])
        self.assertIn('r_47a6586ed815bd2092188c80f9cdb69e',self.coverage['unsupportedDependencyProducts'])

    def test_village_rewards_use_source_backed_density95_survey_profiles(self):
        expected={'village_ardanium_ii':'ardanium_ii','village_wind_crystal':'wind_crystal',
            'village_ostrine':'ostrine','village_endrine':'endrine','village_rudic':'rudic'}
        products=[e for e in self.entries.values() if e['kind']=='loot' and e['provenance'].get('lootName') in expected]
        self.assertEqual(len(products),5)
        for e in products:
            key=e['provenance']['lootName']
            self.assertEqual(e['sourceProfile'],'survey:'+key+':density95')
            self.assertEqual(e['targetTemplate'],'object/tangible/loot/quest/'+expected[key]+'.iff')
            self.assertEqual(e['provenance']['sourceSupport'],'verified-village-survey-provider')
            self.assertTrue(any(s['source']=='bin/scripts/screenplays/village/multiple/fs_survey.lua' for s in e['provenance']['sources']))

    def test_revive_products_enumerate_both_legal_split_endpoints(self):
        products=[e for e in self.entries.values() if e['kind']=='recipe' and e['targetTemplate'].endswith('/medpack_revive.iff')]
        self.assertTrue(products)
        groups={}
        for e in products:
            self.assertIn(e.get('reviveProfile'),['healing-max','wounds-max'])
            suffix='-revive-'+e['reviveProfile']
            self.assertTrue(e['variantId'].endswith(suffix))
            groups.setdefault((e['targetTemplate'],e['variantId'][:-len(suffix)]),set()).add(e['reviveProfile'])
            changed=dict(e,reviveProfile='wounds-max' if e['reviveProfile']=='healing-max' else 'healing-max')
            self.assertNotEqual(self.generator.quality_signature(e),self.generator.quality_signature(changed))
        self.assertTrue(all(profiles=={'healing-max','wounds-max'} for profiles in groups.values()))

    def test_incomplete_ship_repair_outputs_remain_explicit_recipe_source_gaps(self):
        rows=self.coverage['recipeSourceExceptions']
        self.assertEqual(len(rows),11)
        for row in rows:
            self.assertEqual(row['sourceSupport'],'unsupported-incomplete-ship-repair-kit')
            matching=[e for e in self.entries.values() if e['draftPath']==row['draftPath'] and e['targetTemplate']==row['targetTemplate']]
            self.assertTrue(matching)
            for e in matching:
                self.assertEqual(e['provenance']['sourceSupport'],row['sourceSupport'])
                self.assertIn(e['id'],self.coverage['unsupportedDependencyProducts'])

    def test_competing_optional_inputs_have_named_variants_and_omit_profile(self):
        path = 'object/draft_schematic/food/additive/additive_heavy.iff'
        recipes = [e for e in self.entries.values() if e['draftPath'] == path]
        children = {self.entries[c['childId']]['targetTemplate'] for e in recipes for c in e['ingredientChoices'] if c.get('childId')}
        self.assertGreaterEqual(len(children), 4)
        path = 'object/draft_schematic/armor/armor_segment_composite_advanced.iff'
        variants = [e for e in self.entries.values() if e['draftPath'] == path]
        self.assertTrue(any(all(c.get('omit') for c in e['ingredientChoices'] if c['slotType'] in (3,4)) for e in variants))
        self.assertTrue(any('krayt' in e['label'].lower() or 'krayt' in e['variantId'] for e in variants))

    def test_powerup_products_bind_all_853_legal_ordered_outcomes(self):
        products = [e for e in self.entries.values() if 'powerupPrimaryIndex' in e]
        self.assertEqual(len(products), 853)
        self.assertTrue(all(len(e['powerupSecondaryIndices'])<=4 for e in products))
        for e in products:
            changed=dict(e,powerupSecondaryIndices=list(reversed(e['powerupSecondaryIndices'])))
            if len(e['powerupSecondaryIndices'])>1:
                self.assertNotEqual(self.generator.quality_signature(e),self.generator.quality_signature(changed))

    def test_generated_lua_is_pure_data_and_matches_deterministic_renderer(self):
        self.assertTrue(OUTPUT.exists())
        generated = self.generator.render_lua(self.catalog)
        self.assertEqual(__import__('hashlib').sha256(OUTPUT.read_bytes()).hexdigest(), __import__('hashlib').sha256(generated.encode()).hexdigest(), 'Generated Lua is stale or nondeterministic; rerun generator after source edits')
        self.assertEqual(generated, self.generator.render_lua(self.catalog))
        with tempfile.TemporaryDirectory() as tmp:
            lua = Path(tmp) / 'check.lua'
            lua.write_text('dofile(arg[1]); assert(type(PerfectFactoryCatalog)=="table"); assert(PerfectFactoryCatalog.schemaVersion==1); for _,e in ipairs(PerfectFactoryCatalog.entries) do assert(type(e)=="table"); assert(e.availability=="pending") end; print(#PerfectFactoryCatalog.entries)')
            result = subprocess.run(['lua', str(lua), str(OUTPUT)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(int(result.stdout.strip()), len(self.entries))

    def test_changed_recipe_inputs_change_quality_identity_but_not_catalog_id(self):
        entry = next(e for e in self.entries.values() if e['kind'] == 'recipe')
        modified = dict(entry, label='Renamed display only')
        self.assertEqual(self.generator.quality_signature(entry), self.generator.quality_signature(modified))
        changed = dict(entry, sourceProfile=entry['sourceProfile'] + '.revision2')
        self.assertNotEqual(self.generator.quality_signature(entry), self.generator.quality_signature(changed))
        self.assertEqual(entry['id'], changed['id'])

class SourceMetadataTests(unittest.TestCase):
    def test_ship_repair_source_gap_registry_preserves_all_eleven_targets(self):
        path=ROOT/'scripts/tools/perfect_factory_recipe_source_exceptions.json'
        self.assertTrue(path.exists(),'Proven incomplete repair-kit source exception ledger is missing')
        data=json.loads(path.read_text())
        self.assertEqual(len(data['exceptions']),11)
        self.assertEqual(len({(r['draftPath'],r['targetTemplate']) for r in data['exceptions']}),11)
        self.assertIn('src/server/zone/objects/ship/LuaPobShipObject.cpp',data['providerSources'])

    def test_proven_iff_overrides_replace_false_lua_parent_ancestry(self):
        path=ROOT/'scripts/tools/perfect_factory_ancestry_overrides.json'
        self.assertTrue(path.exists(),'Effective IFF ancestry proof index is missing')
        data=json.loads(path.read_text())
        self.assertEqual(len(data['overrides']),11)
        mandalorian=data['overrides']['object/tangible/component/armor/armor_segment_mandalorian.iff']
        self.assertNotIn('object/tangible/component/armor/shared_armor_segment.iff',mandalorian['ancestors'])
        entertainer=data['overrides']['object/tangible/component/bio/bio_component_clothing_casual_entertainer.iff']
        self.assertIn('object/tangible/component/bio/shared_base_bio_component_clothing_field.iff',entertainer['ancestors'])
        self.assertNotIn('object/tangible/component/bio/shared_base_bio_component_clothing_casual.iff',entertainer['ancestors'])
        for record in data['overrides'].values():
            self.assertTrue(record['iffEvidence'])
            for evidence in record['iffEvidence']:
                self.assertRegex(evidence['sha256'],r'^[0-9a-f]{64}$')
                self.assertTrue(evidence['archive'].endswith('.tre'))

    def test_lua_short_strings_decode_escapes_without_corrupting_utf8(self):
        spec = importlib.util.spec_from_file_location('catalog_lua_strings', GENERATOR)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        examples = [
            (r'"Bake Master\'s Cap"', "Bake Master's Cap"),
            (r'"a\\b\"c"', 'a\\b"c'),
            (r"'a\'b\"c'", 'a\'b"c'),
            ('"café — 雪"', 'café — 雪'),
            (r'"caf\195\169\x21"', 'café!'),
            (r'"a\n\t\097b"', 'a\n\tab'),
            ('"a\\\r\nb"', 'a\nb'),
            ('"a\\z \t\nb"', 'ab'),
        ]
        for source, expected in examples:
            with self.subTest(source=source):
                self.assertEqual(module.value(source), expected)
                result = subprocess.run(['lua', '-e', 'io.write('+source+')'], capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(module.value(source).encode(), result.stdout)
        self.assertEqual(module.fields('label = "Bake Master\\\'s Cap", names = {"a\\\\b", "café"}')['names'], ['a\\b', 'café'])

    def test_powerup_outcomes_preserve_secondary_order_and_exclude_primary_duplicates(self):
        spec = importlib.util.spec_from_file_location('catalog_powerup_profiles', GENERATOR)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, 'powerup_outcomes'), 'Explicit powerup source-choice generator is missing')
        source = {'primary':['x','X','cat.x','y','Y','cat.y'], 'secondary':['x','X','cat.x','z','Z','cat.z','w','W','cat.w']}
        outcomes = module.powerup_outcomes(source)
        self.assertEqual(len(outcomes), 8)
        self.assertEqual([x['secondaryIndices'] for x in outcomes if x['primaryIndex']==0], [[1,2],[2,1]])
        for item in outcomes:
            names = [source['secondary'][i*3] for i in item['secondaryIndices']]
            self.assertNotIn(source['primary'][item['primaryIndex']*3], names)
            self.assertEqual(len(names), len(set(names)))
        source = {'primary':['p','P','cat.p'], 'secondary':[v for n in 'abcde' for v in [n,n,'cat.'+n]]}
        self.assertEqual(len(module.powerup_outcomes(source)), 120)
        self.assertTrue(all(len(x['secondaryIndices'])==4 for x in module.powerup_outcomes(source)))

    def test_high_end_named_profiles_preserve_the_source_backed_role_order(self):
        path = ROOT/'scripts/tools/perfect_factory_genetic_profiles.json'
        self.assertTrue(path.exists(), 'Validated named source profile registry is missing')
        config = json.loads(path.read_text())
        presets = {p['id']:p['roles'] for p in config['presets']}
        roles = ['physique_profile','prowess_profile','mental_profile','psychological_profile','aggression_profile']
        self.assertEqual([presets['balanced'][r] for r in roles], ['mutant_rancor','mutant_rancor','mutant_rancor','enraged_defender','mutant_rancor'])
        self.assertEqual([presets['tank'][r] for r in roles], ['mutant_rancor']*5)
        self.assertEqual([presets['damage'][r] for r in roles], ['kusak_hunter']*5)

    def test_named_genetics_require_all_five_real_donor_sources(self):
        spec = importlib.util.spec_from_file_location('catalog_genetic_profiles', GENERATOR)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, 'resolve_genetic_presets'), 'Named genotype source resolver is missing')
        roles = {'physique_profile':'a','prowess_profile':'b','mental_profile':'a','psychological_profile':'b','aggression_profile':'a'}
        config = {'default':'balanced','presets':[{'id':'balanced','label':'Balanced','roles':roles}]}
        result = module.resolve_genetic_presets(config, {'a':'i_a','b':'i_b'})
        self.assertEqual(result[0]['childIds'], ['i_a','i_b','i_a','i_b','i_a'])
        with self.assertRaisesRegex(ValueError, 'Unknown DNA donor'):
            module.resolve_genetic_presets(config, {'a':'i_a'})
        config['presets'][0]['roles'].pop('mental_profile')
        with self.assertRaisesRegex(ValueError, 'five DNA roles'):
            module.resolve_genetic_presets(config, {'a':'i_a','b':'i_b'})

    def test_generated_data_and_runtime_resource_state_are_excluded_from_source_hash(self):
        spec = importlib.util.spec_from_file_location('catalog_source_exclusions', GENERATOR)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for rel in ['bin/scripts/object/serverobjects.lua', module.OUTPUT, 'bin/scripts/managers/resource_manager_spawns.lua']:
                path = root / rel; path.parent.mkdir(parents=True, exist_ok=True); path.write_text('return {}')
            (root/'bin/scripts/object/serverobjects.lua').write_text('includeFile("../custom_scripts/managers/crafting/perfect_factory_catalog.lua")\nincludeFile("../managers/resource_manager_spawns.lua")')
            scanner = module.SourceInventory.__new__(module.SourceInventory)
            scanner.root=root; scanner.scripts=root/'bin/scripts'; scanner.hashes={}; scanner.missing=[]
            paths = scanner.includes('object', 'serverobjects.lua')
            self.assertEqual([scanner.rel(p) for p in paths], ['bin/scripts/object/serverobjects.lua'])
            self.assertEqual(set(scanner.hashes), {'bin/scripts/object/serverobjects.lua'})

    def test_failed_atomic_publication_preserves_previous_complete_file(self):
        spec = importlib.util.spec_from_file_location('catalog_atomic_write', GENERATOR)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, 'atomic_write'), 'Atomic artifact publisher is missing')
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'catalog.lua'; path.write_text('old complete data')
            with patch.object(module.os, 'replace', side_effect=OSError('injected publication failure')):
                with self.assertRaises(OSError):module.atomic_write(path, 'new complete data')
            self.assertEqual(path.read_text(), 'old complete data')
            self.assertEqual(list(Path(tmp).iterdir()), [path])
            module.atomic_write(path, 'new complete data')
            self.assertEqual(path.read_text(), 'new complete data')

    def test_child_source_quality_changes_parent_signature_without_id_change(self):
        spec = importlib.util.spec_from_file_location('catalog_quality_signature', GENERATOR)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        parent = {'id':'r_unchanged', 'kind':'recipe', 'sourceProfile':'recipe.normal100', 'dependencySignatures':{'i_child':'a'*64}}
        changed = dict(parent, dependencySignatures={'i_child':'b'*64})
        self.assertNotEqual(module.quality_signature(parent), module.quality_signature(changed))
        self.assertEqual(parent['id'], changed['id'])

    def test_deprecated_ancestry_lookup_ignores_apostrophes_in_comments(self):
        spec = importlib.util.spec_from_file_location('catalog_source_parser', GENERATOR)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertTrue(hasattr(module, 'ancestry_metadata'), 'Comment-safe ancestry reader is missing')
        source = "sample = Shared:new {\n-- object's harmless comment\n--[[ derivedFromTemplates = {\"object/base/shared_base.iff\"} ]]\n}"
        self.assertEqual(module.ancestry_metadata(source), {'sample': ['object/base/shared_base.iff']})

if __name__ == '__main__':
    unittest.main()
