#!/usr/bin/env python3
"""Generate source-backed, pending perfect-factory products. No world operations.

Run from any directory; --root is the MMOCoreORB directory. Runtime audit, never
this static generator, promotes a product to verified. Source ancestry retained
in deprecated objects.lua is a candidate hint and must pass runtime isDerivedFrom.
"""
import argparse
import collections
import hashlib
import json
import itertools
import os
import tempfile
from pathlib import Path
import re
import sys

QUALITY_REVISION = 'normal100-v1'
OUTPUT = 'bin/scripts/custom_scripts/managers/crafting/perfect_factory_catalog.lua'
MANIFEST = 'tests/local/perfect_factory_catalog/coverage.json'
PROFILE_INDEX = 'tests/local/perfect_factory_catalog/special_profiles.json'
GENETICS_PROFILES = 'scripts/tools/perfect_factory_genetic_profiles.json'
ANCESTRY_OVERRIDES = 'scripts/tools/perfect_factory_ancestry_overrides.json'
SURVEY_PROFILES = 'scripts/tools/perfect_factory_survey_profiles.json'
REVIVE_FORMULA = 'src/server/zone/objects/tangible/pharmaceutical/RevivePack.idl'
RECIPE_SOURCE_EXCEPTIONS = 'scripts/tools/perfect_factory_recipe_source_exceptions.json'
DNA_ROLES = ['physique_profile','prowess_profile','mental_profile','psychological_profile','aggression_profile']
SKILLS = {
 'armor_assembly':'Armorsmith', 'clothing_assembly':'Tailor',
 'weapon_assembly':'Weaponsmith', 'bio_engineer_assembly':'Bio-Engineer',
 'medicine_assembly':'Medic / Doctor', 'combat_medicine_assembly':'Combat Medic',
 'food_assembly':'Chef', 'droid_assembly':'Droid Engineer',
 'structure_assembly':'Architect', 'spice_assembly':'Smuggler',
 'instrument_assembly':'Artisan / Musician', 'jedi_saber_assembly':'Jedi',
 'camouflage':'Scout / Ranger', 'general_assembly':'Artisan / General',
}


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True)


def digest(value):
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def stable_id(kind, identity):
    prefix = 'r_' if kind == 'recipe' else 'i_'
    return prefix + hashlib.sha256((kind + '\0' + identity).encode()).hexdigest()[:32]


def quality_signature(entry):
    # Display/readiness never changes gameplay identity. Runtime supplies the final
    # semantic signature including effective bounds and actual generated state.
    keys = ['kind','draftPath','targetTemplate','variantIndex','variantId',
            'ingredientChoices','sourceProfile','provenance','qualityRevision','dependencySignatures',
            'powerupPrimaryIndex','powerupSecondaryIndices','reviveProfile']
    return digest({k:entry[k] for k in keys if k in entry})


def strip_comments(src):
    pattern = r'("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')|(--\[\[.*?\]\]|--[^\n]*)'
    return re.sub(pattern, lambda m:m[1] if m[1] else '\n'*m[0].count('\n'), src, flags=re.S)


def balanced(src, start):
    depth = 0
    quote = None
    escaped = False
    for i in range(start, len(src)):
        c = src[i]
        if quote:
            if escaped: escaped = False
            elif c == '\\': escaped = True
            elif c == quote: quote = None
        elif c in '\"\'': quote = c
        elif c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return i + 1
    raise ValueError('Unclosed Lua source table')


def lua_short_string(src):
    """Decode Lua escapes as bytes; leave literal UTF-8 characters intact.

    Python's unicode_escape codec corrupts literal UTF-8 and has different
    decimal/hex escape rules. Decode once, as Lua does (never recursively).
    """
    if len(src) < 2 or src[-1] != src[0]:
        raise ValueError('Unclosed Lua short string')
    body = src[1:-1]
    result = bytearray()
    escapes = {'a':7, 'b':8, 'f':12, 'n':10, 'r':13, 't':9, 'v':11,
               '\\':92, '"':34, "'":39}
    i = 0
    while i < len(body):
        c = body[i]; i += 1
        if c != '\\':
            result.extend(c.encode('utf-8')); continue
        if i == len(body): raise ValueError('Trailing Lua string escape')
        c = body[i]; i += 1
        if c in escapes: result.append(escapes[c])
        elif c in '\r\n':
            if i < len(body) and body[i] in '\r\n' and body[i] != c: i += 1
            result.append(10)
        elif c == 'z':
            while i < len(body) and body[i] in ' \t\v\f\r\n': i += 1
        elif c.isascii() and c.isdigit():
            end = i
            while end < min(i+2,len(body)) and body[end] in '0123456789': end += 1
            number = int(c+body[i:end]); i = end
            if number > 255: raise ValueError('Lua decimal escape exceeds one byte')
            result.append(number)
        elif c == 'x' and re.fullmatch(r'[0-9a-fA-F]{2}', body[i:i+2]):
            result.append(int(body[i:i+2],16)); i += 2
        elif c == 'u':
            match = re.match(r'\{([0-9a-fA-F]+)\}',body[i:])
            if not match: raise ValueError('Invalid Lua UTF-8 escape')
            result.extend(chr(int(match[1],16)).encode('utf-8')); i += match.end()
        else: raise ValueError('Unsupported Lua string escape: '+repr(c))
    return result.decode('utf-8')


def value(src):
    src = src.strip()
    if src.startswith('{'):
        return [value(m[0]) for m in re.finditer(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|-?\d+(?:\.\d+)?|\btrue\b|\bfalse\b', src[1:-1])]
    if src.startswith(('"', "'")): return lua_short_string(src)
    if src == 'true': return True
    if src == 'false': return False
    try: return float(src) if '.' in src else int(src)
    except ValueError: return src


def fields(src):
    result = {}
    cursor = 0
    while cursor < len(src):
        match = re.search(r'\b(\w+)\s*=\s*', src[cursor:])
        if not match: break
        key = match[1]
        start = cursor + match.end()
        if src[start] == '{': end = balanced(src, start)
        elif src[start] in '\"\'':
            quote = src[start]
            end = start + 1
            while end < len(src):
                if src[end] == '\\': end += 2; continue
                if src[end] == quote: end += 1; break
                end += 1
        else:
            tail = re.search(r'[,\n]', src[start:])
            end = start + tail.start() if tail else len(src)
        result[key] = value(src[start:end])
        cursor = end
    return result


def ancestry_metadata(raw):
    # Deprecated lookup data lives inside comments. Bound by declarations rather
    # than lexing comment apostrophes as executable string delimiters.
    declarations = list(re.finditer(r'(?m)^\s*(\w+)\s*=\s*(\w+):new\s*{', raw))
    result = {}
    for i, declaration in enumerate(declarations):
        end = declarations[i+1].start() if i+1 < len(declarations) else len(raw)
        match = re.search(r'derivedFromTemplates\s*=\s*({[^}]*})',raw[declaration.end():end],re.S)
        if match: result[declaration[1]] = value(match[1])
    return result


def server_path(path):
    folder, name = path.rsplit('/', 1)
    return folder + '/' + name.removeprefix('shared_')


def shared_path(path):
    folder, name = path.rsplit('/', 1)
    return folder + '/' + (name if name.startswith('shared_') else 'shared_' + name)


def readable(path):
    name = path.rsplit('/', 1)[-1].removesuffix('.iff').removesuffix('.lua')
    return name.replace('_', ' ').title()


class SourceInventory:
    def __init__(self, root):
        self.root = Path(root).resolve()
        self.scripts = self.root / 'bin/scripts'
        self.hashes = {}
        self.objects = {}
        self.registered = {}
        self.sources = {}
        self.metadata = {}
        self.cache = {}
        self.ancestry_cache = {}
        self.ancestry_overrides = {}
        self.examined = set()
        self.missing = []
        graph = self.includes('object', 'serverobjects.lua')
        graph_set = set(graph)
        metadata = sorted(p for p in (self.scripts/'object').rglob('objects.lua') if p not in graph_set)
        for path in metadata + graph:
            raw = self.read(path)
            src = strip_comments(raw)
            self.metadata.update(ancestry_metadata(raw))
            for match in re.finditer(r'(?m)^\s*(\w+)\s*=\s*(\w+):new\s*{', src):
                end = balanced(src, match.end()-1)
                self.objects[match[1]] = {'parent':match[2], 'fields':fields(src[match.end():end-1]), 'source':self.rel(path)}
            for match in re.finditer(r'ObjectTemplates:addTemplate\(\s*(\w+)\s*,\s*"([^"]+)"\s*\)', src):
                self.registered[match[2]] = match[1]
                self.sources[match[2]] = self.rel(path)
        self.seeds = set()
        for rel in ['managers/crafting/schematics.lua','custom_scripts/managers/crafting/schematics.lua']:
            self.seeds.update(re.findall(r'path\s*=\s*"([^"]+)"', strip_comments(self.read(self.scripts/rel))))
        self.recipes = {}
        self.exceptions = []
        for path in sorted(self.seeds):
            data = self.template(path)
            if not data.get('targetTemplate'):
                self.exceptions.append({'draftPath':path,'reason':'incomplete-source'})
                continue
            profession = SKILLS.get(data.get('assemblySkill'), 'Shipwright' if data.get('xpType')=='shipwright' else 'Artisan / General')
            if data.get('xpType') == 'shipwright': profession = 'Shipwright'
            if data.get('xpType') == 'camp': profession = 'Scout / Ranger'
            aliases = {profession}
            if path.startswith('object/draft_schematic/food/'): aliases.add('Chef')
            if path.startswith(('object/draft_schematic/structure/','object/draft_schematic/furniture/')) and profession=='Artisan / General': aliases.add('Architect')
            if path.startswith('object/draft_schematic/weapon/') and profession=='Artisan / General': aliases.add('Weaponsmith')
            data = dict(data, draftPath=path, professions=sorted(aliases))
            slots = []
            names = ['ingredientSlotType','resourceTypes','resourceQuantities','ingredientTitleNames','contribution']
            count = len(data.get('resourceTypes', []))
            if any(len(data.get(k, [])) != count for k in names):
                raise ValueError('Unaligned ingredient source arrays: '+path)
            for i in range(count):
                slots.append({'slotIndex':i,'slotType':data['ingredientSlotType'][i],
                              'predicate':data['resourceTypes'][i], 'quantity':data['resourceQuantities'][i],
                              'title':data['ingredientTitleNames'][i], 'contribution':data['contribution'][i]})
            data['slots'] = slots
            self.recipes[path] = data
        self.loot = []
        for path in self.includes('loot', 'items.lua'):
            src = strip_comments(self.read(path))
            targets = re.findall(r'directObjectTemplate\s*=\s*"([^"]+)"', src)
            names = re.findall(r'addLootItemTemplate\(\s*"([^"]+)"', src)
            if not targets or not names: continue
            self.loot.append({'name':names[-1], 'target':targets[-1], 'source':self.rel(path)})
        self.dna = []
        for path in self.includes('mobile','serverobjects.lua'):
            src = strip_comments(self.read(path))
            match = re.search(r'(?m)^\s*(\w+)\s*=\s*Creature:new\s*{', src)
            if not match: continue
            end = balanced(src, match.end()-1)
            data = fields(src[match.end():end-1])
            name = re.search(r'CreatureTemplates:addCreatureTemplate\(\s*\w+\s*,\s*"([^"]+)"',src)
            level = data.get('level', 0)
            if not name or not isinstance(level, (int,float)) or not 1 <= level <= 75: continue
            if data.get('mobType') not in ['MOB_HERBIVORE','MOB_CARNIVORE','MOB_AGGRO','MOB_KILLER']: continue
            if 'ATTACKABLE' not in str(data.get('pvpBitmask','')): continue
            if '/pet/' in str(path) or 'baby' in name[1]: continue
            source={'name':name[1], 'level':level, 'source':self.rel(path)}
            organics={k:data[k] for k in ['meatAmount','hideAmount','boneAmount'] if isinstance(data.get(k),(int,float))}
            if len(organics)==3:source['organicAmounts']=organics
            self.dna.append(source)
        self.dna.sort(key=lambda x:x['name'])
        overrides_path=self.root/ANCESTRY_OVERRIDES
        if overrides_path.exists():
            overrides=json.loads(self.read(overrides_path))
            if overrides.get('schemaVersion')!=1: raise ValueError('Unsupported IFF ancestry override schema')
            for target,record in overrides['overrides'].items():
                if self.template(target).get('clientTemplateFileName')!=record['clientTemplate']:
                    raise ValueError('IFF ancestry proof is stale for client template: '+target)
                self.ancestry_overrides[target]=record

    def rel(self, path): return str(path.resolve().relative_to(self.root))

    def excluded(self, path):
        relative = self.rel(path)
        return relative in {OUTPUT, MANIFEST, PROFILE_INDEX, 'bin/scripts/managers/resource_manager_spawns.lua'}

    def read(self, path):
        path = path.resolve()
        if self.excluded(path):raise ValueError('Generated/runtime output cannot be a source fingerprint input: '+str(path))
        if not path.is_relative_to(self.root): raise ValueError('Source include escapes checkout: '+str(path))
        data = path.read_bytes()
        self.hashes[self.rel(path)] = hashlib.sha256(data).hexdigest()
        return data.decode()

    def includes(self, namespace, start):
        result = []
        seen = set()
        def visit(rel):
            path = (self.scripts/namespace/rel).resolve()
            if path in seen or self.excluded(path): return
            seen.add(path)
            if not path.is_file():
                self.missing.append(self.rel(path)); return
            result.append(path)
            for child in re.findall(r'includeFile\s*\(\s*"([^"]+)"\s*\)',strip_comments(self.read(path))): visit(child)
        visit(start)
        return result

    def resolve(self, name, ancestors=()):
        if name in self.cache: return self.cache[name]
        if name not in self.objects: return {}
        if name in ancestors: raise ValueError('Lua source inheritance cycle: '+name)
        obj = self.objects[name]
        data = self.resolve(obj['parent'], ancestors+(name,)).copy()
        data.update(obj['fields'])
        self.cache[name] = data
        return data

    def template(self, path): return self.resolve(self.registered.get(path,''))

    def ancestry(self, path):
        if path in self.ancestry_cache: return self.ancestry_cache[path]
        if path in self.ancestry_overrides:
            result=set(self.ancestry_overrides[path]['ancestors'])
            self.ancestry_cache[path]=result
            return result
        def walk(name, seen):
            if name in seen or name not in self.objects: return set()
            seen.add(name)
            obj = self.objects[name]
            result = set(self.metadata.get(name, []))
            own = obj['fields'].get('clientTemplateFileName')
            if own: result.add(own)
            return result | walk(obj['parent'], seen)
        result = walk(self.registered.get(path,''),set()) | {shared_path(path)}
        self.ancestry_cache[path] = result
        return result

    def evidence(self, *paths):
        return [{'source':p,'sha256':self.hashes[p]} for p in sorted(set(paths)) if p in self.hashes]


def abstract_target(path):
    name = path.rsplit('/',1)[-1]
    return (name.startswith('base_') or name.endswith('_base.iff') or '/base/' in path or
            name in {'armor_layer.iff','bio_component_food_heavy.iff','bio_component_food_medium.iff','bio_component_food_light.iff'})


def category(kind, path, recipe=None):
    if kind == 'dna': return 'DNA samples'
    if kind == 'crystal': return 'Crystals and pearls'
    if kind != 'recipe': return 'Rare ingredients' if kind == 'loot' else 'Fixed ingredients'
    if '/pet_deed/' in path: return 'Pets'
    if '/component/' in path or '/bio_component/' in path or '/additive/' in path or '/dna_template/' in path: return 'Components'
    if '/chemistry/' in recipe['draftPath'] or '/utilities/' in recipe['draftPath']: return 'Medicines'
    if '/food/' in path: return 'Food and drink'
    if '/deed/' in path: return 'Deeds'
    return 'Finished items'


def powerup_outcomes(data):
    primary=data.get('primary',[]);secondary=data.get('secondary',[])
    if len(primary)%3 or len(secondary)%3:raise ValueError('Malformed powerup source stat triples')
    result=[]
    for p in range(len(primary)//3):
        eligible=[i for i in range(len(secondary)//3) if secondary[i*3]!=primary[p*3]]
        # Every full-effect legal ordered outcome. The generated path forbids a
        # duplicated primary attribute even in its first secondary position.
        count=min(4,len({secondary[i*3] for i in eligible}))
        for order in itertools.permutations(eligible,count):
            if len({secondary[i*3] for i in order})!=count:continue
            result.append({'primaryIndex':p,'secondaryIndices':list(order),
                'label':primary[p*3+1]+(' / '+', '.join(secondary[i*3+1] for i in order) if order else '')})
    return result


def resolve_genetic_presets(config, donors):
    result=[]
    identities=set()
    for preset in config.get('presets',[]):
        if set(preset.get('roles',{})) != set(DNA_ROLES):
            raise ValueError('Named genotype requires exactly five DNA roles')
        if not re.fullmatch(r'[a-z][a-z0-9-]{0,31}',preset['id']) or preset['id'] in identities:
            raise ValueError('Invalid or duplicate named genotype identity')
        identities.add(preset['id'])
        for source in preset['roles'].values():
            if source not in donors:raise ValueError('Unknown DNA donor: '+source)
        result.append(dict(preset,childIds=[donors[preset['roles'][role]] for role in DNA_ROLES]))
    if config.get('default') not in identities:raise ValueError('Missing default named genotype')
    return result


def fixed_source_support(inventory, targets):
    """Keep registration separate from proof of a normal state-producing source.

    Broad source-reference audit: definitions and generated catalog data cannot
    establish a provider, and visible_components.lua only maps appearances.
    Unknown noncosmetic references require review, never automatic approval.
    There are currently no positively established fixed providers.
    """
    by_name = {p.rsplit('/',1)[-1].removesuffix('.iff'):p for p in targets}
    references = {p:[] for p in targets}
    tokens = set(by_name) | {'shared_'+name for name in by_name}
    pattern = re.compile(r'(?<![A-Za-z0-9_])(?:shared_)?('+ '|'.join(map(re.escape,sorted(by_name))) +r')(?![A-Za-z0-9_])')
    examined = 0
    files = list(inventory.scripts.rglob('*.lua'))
    files += [p for p in (inventory.root/'src').rglob('*') if p.suffix in {'.cpp','.h','.idl'}]
    for path in sorted(files):
        rel = inventory.rel(path)
        if inventory.excluded(path) or rel.startswith(('bin/scripts/object/','bin/scripts/custom_scripts/object/','src/tests/')): continue
        examined += 1
        source_bytes = path.read_bytes()
        raw = source_bytes.decode('utf-8',errors='replace')  # legacy C++ copyright bytes are not labels
        if not tokens.intersection(re.findall(r'[A-Za-z_][A-Za-z_0-9]*',raw)): continue
        for line_number,line in enumerate(raw.splitlines(),1):
            for match in pattern.finditer(line):
                references[by_name[match[1]]].append({'source':rel,'line':line_number,
                    'classification':('cosmetic-only' if rel=='bin/scripts/managers/crafting/visible_components.lua' else 'unverified-reference'),
                    'text':line.strip()})
        if pattern.search(raw): inventory.hashes[rel]=hashlib.sha256(source_bytes).hexdigest()
    return {target:{'sourceSupport':'unsupported-no-normal-provider',
        'sourceSupportReason':'No positively established normal loot/reward/grant/state initializer; registration and empty experimentation arrays do not establish usable fixed state.',
        'references':references[target]} for target in sorted(targets)}, examined


def build_catalog(root):
    inventory = SourceInventory(root)
    survey_profiles={};survey_source_paths=[];survey_config={}
    if (inventory.root/SURVEY_PROFILES).exists():
        survey_config=json.loads(inventory.read(inventory.root/SURVEY_PROFILES))
        survey_profiles={p['lootName']:p for p in survey_config['profiles']}
        survey_source_paths=[SURVEY_PROFILES]+survey_config['providerSources']
        for source in survey_config['providerSources']:inventory.read(inventory.root/source)
    recipe_source_gaps={};recipe_gap_sources=[]
    if (inventory.root/RECIPE_SOURCE_EXCEPTIONS).exists():
        gaps=json.loads(inventory.read(inventory.root/RECIPE_SOURCE_EXCEPTIONS))
        recipe_gap_sources=[RECIPE_SOURCE_EXCEPTIONS]+gaps['providerSources']
        for source in gaps['providerSources']:inventory.read(inventory.root/source)
        recipe_source_gaps={(r['draftPath'],r['targetTemplate']):r for r in gaps['exceptions']}
    slots_by_path = {path:data['slots'] for path,data in inventory.recipes.items()}
    predicates = {s['predicate'] for slots in slots_by_path.values() for s in slots if s['slotType'] != 0}
    consumers = collections.defaultdict(set)
    for path, recipe in inventory.recipes.items():
        for slot in recipe['slots']:
            if slot['slotType'] != 0: consumers[slot['predicate']].update(recipe['professions'])
    entries = {}
    output_records = []
    pending_sources = []
    producer_ids = collections.defaultdict(list)

    def new_entry(kind, draft, target, index, variant, professions, label, source_profile, provenance, factory=False):
        if (draft,target) in recipe_source_gaps:
            gap=recipe_source_gaps[(draft,target)]
            provenance=dict(provenance,sourceSupport=gap['sourceSupport'],sourceSupportReason=gap['reason'])
            provenance['sources']=provenance['sources']+inventory.evidence(*recipe_gap_sources)
        if target in inventory.ancestry_overrides:
            proof=inventory.ancestry_overrides[target]
            provenance=dict(provenance)
            provenance['sources']=provenance['sources']+inventory.evidence(ANCESTRY_OVERRIDES)
            provenance['effectiveIffAncestry']={'proofIndex':ANCESTRY_OVERRIDES,
                'clientTemplate':proof['clientTemplate'],'ancestors':proof['ancestors']}
        identity = '|'.join([draft,target,str(index),variant,source_profile])
        entry = {'id':stable_id(kind,identity), 'kind':kind, 'draftPath':draft,
                 'targetTemplate':target, 'variantIndex':index, 'variantId':variant,
                 'professions':sorted(set(professions)), 'category':category(kind,target,inventory.recipes.get(draft)),
                 'label':label, 'ingredientChoices':[], 'sourceProfile':source_profile,
                 'provenance':provenance, 'expectedFactoryEligible':bool(factory),
                 'availability':'pending', 'qualityRevision':QUALITY_REVISION}
        if entry['id'] in entries and entries[entry['id']] != entry: raise ValueError('Product id collision')
        entries[entry['id']] = entry
        return entry

    # Every source-backed appearance remains a distinct explicit target. Repeated
    # primary/alternate references within a draft do not create duplicate products.
    for path, recipe in inventory.recipes.items():
        seen = set()
        variants = [(-1,recipe['targetTemplate'])] + list(enumerate(recipe.get('additionalTemplates',[])))
        for index, raw in variants:
            target = server_path(raw)
            if target in seen: continue
            seen.add(target)
            if target not in inventory.registered: raise ValueError('Missing output registration: '+target)
            label = recipe.get('customObjectName') or readable(target)
            if index >= 0: label += ' — ' + readable(target)
            provenance = {'evidence':'source recipe and output; runtime target/ancestry/bounds audit required',
                          'sources':inventory.evidence(inventory.sources[path], inventory.sources[target])}
            entry = new_entry('recipe',path,target,index,'standard',recipe['professions'],label,'recipe.normal100',provenance,recipe.get('factoryCrateSize',25)>0)
            output_records.append(entry)
            for predicate in inventory.ancestry(target) & predicates: producer_ids[predicate].append(entry['id'])

    output_targets = {e['targetTemplate'] for e in output_records}
    loot_by_target = collections.defaultdict(list)
    for profile in inventory.loot: loot_by_target[profile['target']].append(profile)
    all_matches = {}
    for target in sorted(inventory.registered):
        if not target.startswith(('object/tangible/','object/weapon/')): continue
        matches = inventory.ancestry(target) & predicates
        if matches: all_matches[target] = matches
        if not matches or target in output_targets or abstract_target(target): continue
        if '/component/dna/' in target: continue  # valid sampled state below
        professions = set().union(*(consumers[p] for p in matches))
        profiles = loot_by_target.get(target,[])
        if profiles:
            for profile in sorted(profiles,key=lambda x:x['name']):
                provenance = {'evidence':'registered normal loot profile; runtime normal endpoints audit required',
                              'lootName':profile['name'],'sources':inventory.evidence(profile['source'],inventory.sources[target])}
                source_profile='loot:'+profile['name']
                label=readable(target)+' — '+readable(profile['name'])
                if profile['name'] in survey_profiles:
                    survey=survey_profiles[profile['name']]
                    if survey['targetTemplate']!=target:raise ValueError('Village survey/loot target mismatch: '+profile['name'])
                    source_profile=survey['sourceProfile']
                    if source_profile!='survey:'+profile['name']+':density95':raise ValueError('Unproven village survey source profile')
                    provenance.update(evidence='normal FsSurvey quest reward at attainable density95 and legal inclusive upper resource rolls; native provider validation required',
                        sourceSupport='verified-village-survey-provider',resourceAttributes=survey['resourceAttributes'],
                        questTableEvidence=survey_config.get('questTableEvidence',{}))
                    provenance['sources']+=inventory.evidence(*survey_source_paths)
                    label+=' — Survey density95 maximum'
                entry = new_entry('loot','',target,-1,profile['name'],professions,label,source_profile,provenance)
                for pred in matches: producer_ids[pred].append(entry['id'])
        else:
            # These declarations enumerate candidates only. Registration and
            # empty experiments do not prove usable fixed state or a provider.
            data = inventory.template(target)
            has_experiments = any(data.get(k) for k in ['experimentalSubGroupTitles','experimentalMin','experimentalMax'])
            if has_experiments:
                pending_sources.append({'targetTemplate':target,'reason':'needs-normal-source-profile'});continue
            provenance = {'evidence':'registered fixed-template candidate; runtime statless/fixed and ancestry verification required',
                          'sources':inventory.evidence(inventory.sources[target])}
            entry = new_entry('fixed','',target,-1,'fixed',professions,readable(target),'fixed:'+target,provenance)
            for pred in matches: producer_ids[pred].append(entry['id'])

    fixed_entries = [e for e in entries.values() if e['kind']=='fixed']
    fixed_support, fixed_audit_files = fixed_source_support(inventory,[e['targetTemplate'] for e in fixed_entries])
    for e in fixed_entries:
        e['provenance'].update(fixed_support[e['targetTemplate']])
        e['provenance']['evidence']='unsupported normal source candidate retained for explicit coverage exception; never a verified perfect ingredient'
        e['provenance']['sources'] += inventory.evidence(*(r['source'] for r in fixed_support[e['targetTemplate']]['references']))

    # Sources are normal sample candidates, not numeric genotype presets. Native
    # eligibility/joint-roll validation is a required availability gate.
    dna_target = 'object/tangible/component/dna/dna_sample_very_high.iff'
    dna_predicate = 'object/tangible/component/base/shared_base_dna_sample.iff'
    for source in inventory.dna:
        provenance = {'evidence':'attackable non-pet creature source level<=75; native sample eligibility and joint attainable quality1 roll required',
                      'creatureTemplate':source['name'], 'sources':inventory.evidence(source['source'])}
        if source.get('organicAmounts') and sum(source['organicAmounts'].values())<=0:
            provenance.update(sourceSupport='unsupported-unsampleable-dna',organicAmounts=source['organicAmounts'],
                sourceSupportReason='Explicit zero organic harvest amounts violate CreatureImplementation::hasOrganics(), required by normal hasDNA().')
        entry = new_entry('dna','',dna_target,-1,source['name'],['Bio-Engineer'],'DNA sample — '+readable(source['name']), 'dna:'+source['name']+':quality1-max',provenance)
        producer_ids[dna_predicate].append(entry['id'])
    if not producer_ids[dna_predicate]: raise ValueError('No source-backed sampleable DNA candidates')

    for loot_name, colors in [('force_color_crystal',range(12)),('force_power_crystal',[31]),('krayt_dragon_pearl',[31])]:
        source = next(x for x in inventory.loot if x['name']==loot_name)
        for color in colors:
            provenance = {'evidence':'normal crystal progression/loot profile; native coherent level/untuned endpoint validation required',
                          'lootName':loot_name, 'color':color, 'sources':inventory.evidence(source['source'])}
            new_entry('crystal','',source['target'],-1,loot_name+'-'+str(color),['Jedi'],readable(loot_name)+((' — Color '+str(color)) if color!=31 else ''),'crystal:'+loot_name+':color-'+str(color),provenance)

    # Rank sources without consulting labels/OIDs/RNG. Exact recipe output first;
    # keep every competing choice below as a named legal profile.
    def rank(product_id, predicate):
        e = entries[product_id]
        exact = shared_path(e['targetTemplate']) == predicate
        if e['kind']=='dna':
            # Stable known ordinary source as default, all donors remain offered.
            return (0 if e['variantId']=='dewback' else 1,e['variantId'])
        return (0 if e['kind']=='recipe' else 1,0 if exact else 1,e['draftPath'],e['targetTemplate'],e['sourceProfile'],product_id)
    for pred in producer_ids: producer_ids[pred] = sorted(set(producer_ids[pred]),key=lambda i:rank(i,pred))

    source_support_cache = {}
    def source_supported(product_id, ancestors=()):
        if product_id in source_support_cache: return source_support_cache[product_id]
        if product_id in ancestors: return False
        entry = entries[product_id]
        if entry['kind']=='fixed':
            result = entry['provenance'].get('sourceSupport')=='verified-statless-provider'
        elif entry['provenance'].get('sourceSupport','').startswith('unsupported-'): result=False
        elif entry['kind']!='recipe': result = True  # established source profile, still pending native audit
        else:
            # Optional inputs may legally be absent. Prove required inputs have
            # a source-backed tree before selecting this default child.
            result = all(any(source_supported(pid,ancestors+(product_id,)) for pid in producer_ids.get(slot['predicate'],[]))
                for slot in inventory.recipes[entry['draftPath']]['slots'] if slot['slotType'] in (1,2))
        source_support_cache[product_id] = result
        return result

    unresolved = []
    defaults = {}
    for entry in output_records:
        recipe = inventory.recipes[entry['draftPath']]
        choices = []
        self_refactor = False
        for slot in recipe['slots']:
            if slot['slotType']==0: continue
            choice = {k:slot[k] for k in ['slotIndex','slotType','quantity','predicate']}
            candidates = producer_ids.get(slot['predicate'],[])
            supported_candidates = [pid for pid in candidates if source_supported(pid)]
            # Remove all variants of the same draft for source refactor slots.
            self_slot = slot['title']=='refactor' and shared_path(entry['targetTemplate'])==slot['predicate']
            if self_slot and slot['slotType'] in (3,4):
                self_refactor = True; choice['omit']=True
            elif supported_candidates:
                choice['childId'] = supported_candidates[0]
            elif slot['slotType'] in (3,4): choice['omit']=True
            elif candidates:
                # Keep a required unsupported input explicit for source-exception
                # reporting; never erase the recipe or fake a normal provider.
                choice['childId'] = candidates[0]
            else:
                unresolved.append({'id':entry['id'],'draftPath':entry['draftPath'],'slotIndex':slot['slotIndex'],'predicate':slot['predicate']})
                choice['unresolved']=True
            choices.append(choice)
        entry['ingredientChoices'] = choices
        if self_refactor:
            old_id = entry['id'];entry['variantId']='base'
            entry['label'] += ' — Base'
            entry['id']=stable_id('recipe','|'.join([entry['draftPath'],entry['targetTemplate'],str(entry['variantIndex']),'base',entry['sourceProfile']]))
            del entries[old_id];entries[entry['id']]=entry
            for ids in producer_ids.values():
                for i,pid in enumerate(ids):
                    if pid==old_id:ids[i]=entry['id']
        defaults[(entry['draftPath'],entry['targetTemplate'])]=entry['id']

    # The previous pass may have replaced Base identifiers that earlier choices
    # referenced. Rewrite by semantic draft/target identity, not insertion order.
    def resolve_base_id(child_id):
        if child_id in entries:return child_id
        for e in output_records:
            old = stable_id('recipe','|'.join([e['draftPath'],e['targetTemplate'],str(e['variantIndex']),'standard',e['sourceProfile']]))
            if child_id==old:return e['id']
        raise ValueError('Unresolved source child id: '+child_id)
    for entry in output_records:
        for choice in entry['ingredientChoices']:
            if 'childId' in choice:choice['childId']=resolve_base_id(choice['childId'])

    genetics_config_path=inventory.root/GENETICS_PROFILES
    genetics_config=None
    if genetics_config_path.exists():
        genetics_config=json.loads(inventory.read(genetics_config_path))
        donors={e['provenance']['creatureTemplate']:e['id'] for e in entries.values() if e['kind']=='dna'}
        presets=resolve_genetic_presets(genetics_config,donors)
        for genetic_base in [e for e in output_records if '/bio_engineer/dna_template/' in e['draftPath']]:
            default_preset=next(p for p in presets if p['id']==genetics_config['default'])
            for c in genetic_base['ingredientChoices']:
                c['childId']=default_preset['childIds'][c['slotIndex']]
            genetic_base['label']+=' — '+default_preset['label']
            for preset in presets:
                provenance=dict(genetic_base['provenance'])
                provenance['geneticPreset']=preset['id']
                provenance['sources']=provenance['sources']+inventory.evidence(GENETICS_PROFILES)
                e=new_entry('recipe',genetic_base['draftPath'],genetic_base['targetTemplate'],genetic_base['variantIndex'],
                    'genetics-'+preset['id'],genetic_base['professions'],readable(genetic_base['targetTemplate'])+' — '+preset['label'],
                    genetic_base['sourceProfile'],provenance,genetic_base['expectedFactoryEligible'])
                e['ingredientChoices']=[dict(c,childId=preset['childIds'][c['slotIndex']]) for c in genetic_base['ingredientChoices']]
                for predicate in inventory.ancestry(e['targetTemplate']) & predicates:producer_ids[predicate].append(e['id'])

    # Named profiles are a finite basis of legal choices, not a Cartesian product.
    # Repeated slots with the same predicate change together; other choices remain
    # explicit. This covers every concrete source alternative without conflating
    # mutually exclusive effects into an invented universal component.
    for base in list(output_records):
        recipe = inventory.recipes[base['draftPath']]
        optional = [s for s in recipe['slots'] if s['slotType'] in (3,4)]
        variants = []
        if base['variantId']=='base':
            profile = [dict(c) for c in base['ingredientChoices']]
            for c in profile:
                slot=recipe['slots'][c['slotIndex']]
                if slot['title']=='refactor':c.pop('omit',None);c['childId']=base['id']
            variants.append(('refactor-once','Refactor once',profile))
        elif optional:
            profile=[dict(c) for c in base['ingredientChoices']]
            for c in profile:
                if c['slotType'] in (3,4):c.pop('childId',None);c.pop('unresolved',None);c['omit']=True
            variants.append(('no-enhancements','No optional enhancements',profile))
        grouped = collections.defaultdict(list)
        for slot in recipe['slots']:
            if slot['slotType'] != 0 and slot['title'] != 'refactor':grouped[slot['predicate']].append(slot)
        for pred, group in sorted(grouped.items()):
            default_choices = [c.get('childId') for c in base['ingredientChoices'] if c['predicate']==pred]
            for child_id in producer_ids.get(pred,[]):
                child_id=resolve_base_id(child_id)
                if default_choices and all(i==child_id for i in default_choices):continue
                child=entries[child_id]
                if child['draftPath']==base['draftPath']:continue
                profile=[dict(c) for c in base['ingredientChoices']]
                for c in profile:
                    if c['predicate']==pred:c.pop('omit',None);c.pop('unresolved',None);c['childId']=child_id
                name = readable(group[0]['title'])+' — '+child['label']
                variants.append(('choice-'+digest([pred,child_id])[:16],name,profile))
        for variant,name,choices in variants:
            entry=new_entry('recipe',base['draftPath'],base['targetTemplate'],base['variantIndex'],variant,base['professions'],base['label']+' — '+name,base['sourceProfile'],base['provenance'],base['expectedFactoryEligible'])
            entry['ingredientChoices']=choices

    powerup_replacements={}
    powerup_outcome_count=0
    for base in list(entries.values()):
        if base['kind']!='recipe' or not base['targetTemplate'].startswith('object/tangible/powerup/'):continue
        source=inventory.template(base['targetTemplate'])
        outcomes=powerup_outcomes(source)
        if not outcomes:continue
        del entries[base['id']]
        for outcome in outcomes:
            e=dict(base)
            p=outcome['primaryIndex'];order=outcome['secondaryIndices']
            e['powerupPrimaryIndex']=p;e['powerupSecondaryIndices']=order
            e['variantId']=base['variantId']+'-powerup-p'+str(p)+'-s'+'-'.join(map(str,order))
            e['id']=stable_id('recipe',canonical([base['id'],p,order]))
            e['label']=base['label']+' — '+outcome['label']
            entries[e['id']]=e
            powerup_replacements.setdefault(base['id'],e['id'])
            powerup_outcome_count+=1
    for e in entries.values():
        for choice in e['ingredientChoices']:
            if choice.get('childId') in powerup_replacements:choice['childId']=powerup_replacements[choice['childId']]

    revive_replacements={}
    revive_records=[e for e in list(entries.values()) if e['kind']=='recipe' and inventory.template(e['targetTemplate']).get('gameObjectType')==0x2033]
    if revive_records:inventory.read(inventory.root/REVIVE_FORMULA)
    for base in revive_records:
        del entries[base['id']]
        for profile in ['healing-max','wounds-max']:
            e=dict(base,reviveProfile=profile)
            e['id']=stable_id('recipe',canonical([base['id'],'revive',profile]))
            e['variantId']=base['variantId']+'-revive-'+profile
            e['label']=base['label']+' — '+('Healing maximum' if profile=='healing-max' else 'Wounds maximum')
            e['provenance']=dict(base['provenance'])
            e['provenance']['sources']=base['provenance']['sources']+inventory.evidence(REVIVE_FORMULA)
            e['provenance']['reviveOutcome']='ordinary power-derived action/mind fixed-sum split at legal RNG endpoint; health formula unchanged'
            entries[e['id']]=e
            revive_replacements.setdefault(base['id'],e['id'])
    for e in entries.values():
        for choice in e['ingredientChoices']:
            if choice.get('childId') in revive_replacements:choice['childId']=revive_replacements[choice['childId']]

    # Resolve and measure selected graphs before serialization. No root count1000
    # occurs here. Unit-normalization belongs to native placement, not source data.
    selected_cycles=[]; memo={}; visiting=[]
    def measure(product_id):
        if product_id in memo:return memo[product_id]
        if product_id in visiting:
            selected_cycles.append(visiting[visiting.index(product_id):]+[product_id]);return (0,0)
        visiting.append(product_id);entry=entries[product_id];count=1;depth=1
        for c in entry['ingredientChoices']:
            if 'childId' not in c:continue
            child_count,child_depth=measure(c['childId']);count+=c['quantity']*child_count;depth=max(depth,1+child_depth)
        visiting.pop();memo[product_id]=(count,depth);return memo[product_id]
    for pid in sorted(entries):measure(pid)
    if selected_cycles:raise ValueError('Selected product graph cycle: '+canonical(selected_cycles[:3]))
    if unresolved:raise ValueError('Required slots without concrete source: '+canonical(unresolved))
    if max(n for n,d in memo.values())>16384 or max(d for n,d in memo.values())>32:
        raise ValueError('Valid catalog exceeds reviewed generation guard; raise deliberately after review')

    unsupported_dependencies = {}
    def unsupported(product_id):
        if product_id not in unsupported_dependencies:
            e = entries[product_id]
            blocked = {product_id} if ((e['kind']=='fixed' and e['provenance'].get('sourceSupport')!='verified-statless-provider') or
                e['provenance'].get('sourceSupport','').startswith('unsupported-')) else set()
            for c in e['ingredientChoices']:
                if 'childId' in c: blocked.update(unsupported(c['childId']))
            unsupported_dependencies[product_id] = sorted(blocked)
        return unsupported_dependencies[product_id]
    for pid in sorted(entries): unsupported(pid)
    fixed_ledger = []
    for fixed in sorted(fixed_entries,key=lambda e:e['id']):
        direct = []
        for e in sorted(entries.values(),key=lambda e:e['id']):
            for c in e['ingredientChoices']:
                if c.get('childId') != fixed['id']: continue
                alternatives = sorted({resolve_base_id(pid) for pid in producer_ids[c['predicate']] if resolve_base_id(pid) in entries and not unsupported(resolve_base_id(pid))})
                direct.append({'id':e['id'],'draftPath':e['draftPath'],'slotIndex':c['slotIndex'],
                    'predicate':c['predicate'],'omitAllowed':c['slotType'] in (3,4),
                    'supportedAlternativeIds':alternatives})
        fixed_ledger.append({'id':fixed['id'],'targetTemplate':fixed['targetTemplate'],
            **fixed_support[fixed['targetTemplate']], 'directConsumers':direct,
            'transitiveDependentIds':sorted(pid for pid,ids in unsupported_dependencies.items() if pid!=fixed['id'] and fixed['id'] in ids)})

    def stamp(product_id):
        entry=entries[product_id]
        if 'qualitySignature' in entry:return entry['qualitySignature']
        entry['dependencySignatures']={c['childId']:stamp(c['childId']) for c in entry['ingredientChoices'] if 'childId' in c}
        entry['qualitySignature']=quality_signature(entry)
        return entry['qualitySignature']
    for product_id in sorted(entries):stamp(product_id)
    source_fingerprint = digest(inventory.hashes)
    catalog={'schemaVersion':1,'qualityRevision':QUALITY_REVISION,'sourceFingerprint':source_fingerprint,
             'entries':sorted(entries.values(),key=lambda e:e['id']), 'exceptions':inventory.exceptions}
    special_profiles={
        'schemaVersion':1,
        'sourceProfileGrammar':{'recipe':'recipe.normal100','loot':'loot:<registered loot item key>',
            'survey':'survey:<registered village loot key>:density95',
            'fixed':'fixed:<exact server template>','crystal':'crystal:<registered loot key>:color-<0..11 or 31>',
            'dna':'dna:<registered creature template key>:quality1-max'},
        'validation':'All candidates pending native source eligibility, joint attainable source roll and normal endpoint validation.',
        'geneticDefaultWarning':('Named presets identify actual five-role donors; best within each named legal profile, not a joint universal maximum. Native formula and joint-source attainability audit is mandatory.' if genetics_config else 'Standard uses five coherent dewback quality1-max sources as a provisional ordinary donor. It is not a globally strongest genotype. Parent/Task4 must supply finite validated Balanced/Tank/Damage/etc five-role source presets before final release.'),
        'sources':[{'id':e['id'],'kind':e['kind'],'targetTemplate':e['targetTemplate'],'sourceProfile':e['sourceProfile'],
                    'variantId':e['variantId'],'label':e['label'],'provenance':e['provenance']}
                   for e in catalog['entries'] if e['kind']!='recipe'],
        'geneticRoleProfiles':[], 'petDefaultProfiles':[],
        'powerupProfiles':[{'id':e['id'],'targetTemplate':e['targetTemplate'],'powerupPrimaryIndex':e['powerupPrimaryIndex'],
            'powerupSecondaryIndices':e['powerupSecondaryIndices']} for e in catalog['entries'] if 'powerupPrimaryIndex' in e],
        'reviveProfiles':[{'id':e['id'],'targetTemplate':e['targetTemplate'],'reviveProfile':e['reviveProfile']} for e in catalog['entries'] if 'reviveProfile' in e]}
    for e in catalog['entries']:
        if '/bio_engineer/dna_template/' in e['draftPath']:
            roles=[]
            for c in e['ingredientChoices']:
                if 'childId' not in c:continue
                child=entries[c['childId']]
                roles.append({'slotIndex':c['slotIndex'],'role':slots_by_path[e['draftPath']][c['slotIndex']]['title'],
                              'childId':child['id'],'sourceProfile':child['sourceProfile'],
                              'creatureTemplate':child['provenance'].get('creatureTemplate','')})
            special_profiles['geneticRoleProfiles'].append({'id':e['id'],'variantId':e['variantId'],'label':e['label'],'roles':roles})
        if '/bio_engineer/creature/' in e['draftPath'] and e['variantId']=='standard':
            special_profiles['petDefaultProfiles'].append({'id':e['id'],'draftPath':e['draftPath'],
                'targetTemplate':e['targetTemplate'],'ingredientChoices':e['ingredientChoices']})
    coverage={'schemaVersion':1,'specialProfileIndex':special_profiles,'sourceFingerprint':source_fingerprint,'sourceHashes':dict(sorted(inventory.hashes.items())),
              'usableRecipes':len(inventory.recipes),'uniqueOutputTargets':len(output_targets),'powerupOutcomeCount':powerup_outcome_count,
              'entriesByKind':dict(sorted(collections.Counter(e['kind'] for e in entries.values()).items())),
              'recipesByProfession':dict(sorted(collections.Counter(p for r in inventory.recipes.values() for p in r['professions']).items())),
              'recipeSlots':slots_by_path,'pendingNormalSources':pending_sources,'missingSourceIncludes':sorted(set(inventory.missing)),
              'fixedSourceSupport':fixed_ledger,'fixedSourceAuditFileCount':fixed_audit_files,
              'unsupportedDependencyProducts':{pid:ids for pid,ids in sorted(unsupported_dependencies.items()) if ids},
              'ancestryOverrideIndex':ANCESTRY_OVERRIDES,'ancestryOverrideTargets':sorted(inventory.ancestry_overrides),
              'dnaSourceExceptions':[{'id':e['id'],'sourceProfile':e['sourceProfile'],'provenance':e['provenance']}
                for e in catalog['entries'] if e['kind']=='dna' and e['provenance'].get('sourceSupport','').startswith('unsupported-')],
              'recipeSourceExceptions':[recipe_source_gaps[k] for k in sorted(recipe_source_gaps)],
              'runtimeValidationRequired':True,'selectedCycles':selected_cycles,'unresolvedRequiredSlots':unresolved,
              'maximumExpandedPrototypeObjects':max(n for n,d in memo.values()),'maximumSelectedDepth':max(d for n,d in memo.values()),
              'maximumSingleObjectSlotQuantity':max(s['quantity'] for slots in slots_by_path.values() for s in slots if s['slotType']!=0),
              'profilePolicy':'Finite legal source alternatives per repeated predicate; not a Cartesian product or universal combined-bonus item',
              'exceptions':inventory.exceptions}
    return catalog,coverage


def lua_value(value):
    if value is None:return 'nil'
    if value is True:return 'true'
    if value is False:return 'false'
    if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
    if isinstance(value,(int,float)):return repr(value)
    if isinstance(value,list):return '{'+','.join(lua_value(x) for x in value)+'}'
    if isinstance(value,dict):return '{'+','.join('['+lua_value(k)+']='+lua_value(v) for k,v in sorted(value.items()))+'}'
    raise TypeError(type(value))


def render_lua(catalog):
    lines=['-- Generated by scripts/tools/generate_perfect_factory_catalog.py; pure data.',
           '-- All products remain pending until the native content/state audit verifies them.',
           'PerfectFactoryCatalog = {', '  schemaVersion = 1,',
           '  qualityRevision = '+lua_value(catalog['qualityRevision'])+',',
           '  sourceFingerprint = '+lua_value(catalog['sourceFingerprint'])+',', '  entries = {']
    lines.extend('    '+lua_value(e)+',' for e in sorted(catalog['entries'],key=lambda e:e['id']))
    lines.extend(['  },','  exceptions = '+lua_value(catalog['exceptions'])+',','}',''])
    return '\n'.join(lines)


def atomic_write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', newline='\n',
                prefix='.'+path.name+'.',dir=path.parent,delete=False) as stream:
            temporary=Path(stream.name)
            stream.write(text);stream.flush();os.fsync(stream.fileno())
            os.fchmod(stream.fileno(),0o644)
        os.replace(temporary,path)
    finally:
        if temporary is not None:temporary.unlink(missing_ok=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[2])
    parser.add_argument('--check',action='store_true',help='read-only determinism/content check')
    args=parser.parse_args()
    catalog,coverage=build_catalog(args.root)
    profile_index=coverage.pop('specialProfileIndex')
    artifacts={args.root/OUTPUT:render_lua(catalog),args.root/MANIFEST:json.dumps(coverage,indent=2,sort_keys=True)+'\n',
               args.root/PROFILE_INDEX:json.dumps(profile_index,indent=2,sort_keys=True)+'\n'}
    stale=[]
    for path,text in artifacts.items():
        if args.check:
            if not path.is_file() or path.read_text()!=text:stale.append(str(path))
        else:
            atomic_write(path,text)
    print(canonical({k:coverage[k] for k in ['usableRecipes','uniqueOutputTargets','entriesByKind','recipesByProfession','maximumExpandedPrototypeObjects','maximumSelectedDepth']}))
    if stale:print('Stale generated artifacts: '+', '.join(stale),file=sys.stderr);return 1
    return 0

if __name__=='__main__':sys.exit(main())
