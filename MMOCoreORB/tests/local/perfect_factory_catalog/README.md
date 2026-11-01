# Perfect factory catalog

The producer scans this checkout's active object, loot and creature include graphs,
stock/custom schematic seed lists and shared source lookup metadata. It writes one
pure-data Lua global, `PerfectFactoryCatalog`; it performs no world operations.
It has no dependency on the external discovery artifacts or live game directories.

From the repository root:

```bash
python3 MMOCoreORB/scripts/tools/generate_perfect_factory_catalog.py
python3 MMOCoreORB/scripts/tools/generate_perfect_factory_catalog.py --check
python3 -m unittest discover -s MMOCoreORB/tests/local/perfect_factory_catalog -p 'test_*.py'
```

The catalog preserves all 1,795 usable seeded drafts and 2,012 server output
appearances. The nine incomplete Shipwright seed placeholders remain explicit
exceptions. Chef has 87 recipe aliases; Bio-Engineer has 105, including all tissues,
pet medicines, genetics and pet deeds. `coverage.json` joins source slots, source
hashes, professions and selected-graph bounds. `special_profiles.json` exposes
exact special-source IDs, five-role donor maps, pet defaults and power-up indices.

Every product is **pending** in generated data. Only the native audit may make it
available; source metadata is not proof of a correct live prototype, genealogy,
module loadout, clone or persisted result. The `objects.lua` ancestry lists are
explicitly deprecated hints and require runtime `isDerivedFrom` validation.
`scripts/tools/perfect_factory_ancestry_overrides.json` replaces eleven proven
incorrect hints with effective Pre-CU IFF ancestry. Each record identifies its
client template, complete DERV chain, winning archive and IFF SHA-256 evidence;
the index enters source fingerprints and affected product signatures. It corrects
Mandalorian segments and the actual field ancestry of ten BE tissue templates.
Native type validation remains mandatory. The index rejects a changed Lua client
template until its IFF proof is refreshed.
Source
fixed-template candidates additionally require an established normal provider.
All 65 current fixed candidates have `provenance.sourceSupport` equal to
`unsupported-no-normal-provider` and must fail native verification. Registration,
empty experimentation arrays and cosmetic component mappings cannot establish
meaningful fixed state. These records remain as explicit source exceptions;
`coverage.json` contains `fixedSourceSupport` with exact source references, direct
consumer slots, legal optional omission and source-supported alternative IDs.
`unsupportedDependencyProducts` maps every affected product to its unsupported
fixed dependencies. Alternatives still require native predicate/state validation.
No recipe is silently removed, and no abstract base template is offered.

The selected graph contains one source choice per object slot, or explicit
`omit=true` for each absent optional slot. Slot indices are zero-based; quantity
and slot type are runtime cross-checks, not overrides. Standard choices use real
recipe/loot/DNA sources when a supported tree exists. Unsupported optional inputs
are omitted from defaults; required unsupported inputs remain explicit source
exceptions. Named profiles retain the unsupported alternatives for audit and
replace a competing predicate across
its repeated slots. This finite legal profile basis intentionally does not invent
an item containing every competing bonus or enumerate the unbounded Cartesian
product of all possible player combinations. All selected input trees are checked
for cycles, overflow guard limits and depth before serialization. Six community
refactor families expose Base and Refactor once, which consumes perfect Base.
Delivery count 1000 never multiplies this graph. Native input placements must
normalize useCount to 0/1 while delivery prototypes retain normal charges.

`sourceProfile` grammar is exact:

- `recipe.normal100`
- `loot:<registered loot item key>`
- `survey:<registered village loot key>:density95`
- `fixed:<exact server template path>`
- `crystal:<force_color_crystal|force_power_crystal|krayt_dragon_pearl>:color-<0..11 or 31>`
- `dna:<registered creature template key>:quality1-max`

These are source identities, never arbitrary final-stat maps. The offline registry
`scripts/tools/perfect_factory_genetic_profiles.json` names source-reviewed
Balanced, Tank and Damage five-role donors. They are best within their named normal
profile, not a claim of one universally strongest genotype. Native validation of
sample eligibility, a jointly attainable normal spawn/quality1 roll, DNA-dependent
caps and phenotype persistence remains mandatory. Each preset propagates into all
pet-deed output templates. The source index also retains the other ordinary donor
candidates and single-donor genotype choices for native validation.
The explicit zero-organic ancient_reptillian donor remains recorded as
`unsupported-unsampleable-dna`, with its source harvest amounts and dependent
profile in the unsupported-source ledger. Normal `hasDNA()` requires organics;
the producer never substitutes an invented sample or alters the donor's stats.

The five village ingredient rewards use the actual phase2/3 FsSurvey quest
provider. The survey registry records the loaded quests.iff chain/hash, exact
resource attribute names, and a normal density95 witness. At density95 the
ordinary inclusive upper roll reaches the normal cap1000; direct loot's Gaussian
default is a different provider. Profile identities bind this distinction.

Every actual RevivePack recipe has explicit `reviveProfile` equal to
`healing-max` or `wounds-max`, included in its identity and quality signature.
These select legal ordinary action/mind split endpoints while preserving their
fixed budgets, health formula, potency and doses. They do not combine competing
maxima into one invented outcome.

The recipe-source exception registry retains eleven incomplete ship repair-kit
draft/target pairs. Ordinary code never initializes componentSlot, and its
consumer also skips matching slots; the producer records this proven gap rather
than supplying an arbitrary slot. These source gaps remain distinct from the
five required quest-input gaps and nine incomplete seed placeholders.

Power-ups expose every legal full-effect ordered outcome: explicit zero-based
`powerupPrimaryIndex` and `powerupSecondaryIndices`, with at most four distinct
secondary attributes, excluding the selected primary attribute in every position.
The source's lower-effect thresholds and the native normal finalizer remain the
authority. Different orders have different IDs and source quality signatures.

Compact IDs are stable 128-bit SHA-256 prefixes of canonical recipe/source/choice
identity; labels, player names, time and OIDs never participate. Source quality
signatures bind selected child signatures and relevant source evidence. Native
final semantic hashes must additionally bind actual loaded bounds and finalized
normal gameplay state. Source signatures alone are not sufficient serial evidence.
Lua short strings are decoded once using Lua escape rules while preserving
literal UTF-8. Escaped apostrophes do not leak into labels; literal escaped
backslashes remain backslashes. Tests compare decoded bytes with Lua itself.

Generated catalog/coverage/profile outputs and runtime `resource_manager_spawns.lua`
are excluded from source hashing, even when an include points to them. Publications
use temporary files, fsync and atomic replacement; failed publication preserves the
previous complete artifact. Repeated fresh generations and `--check` must match
byte for byte after source edits settle. No generated output is fed back into its
own fingerprint.
