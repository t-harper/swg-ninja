# GM FRS editor focused regressions

Run from `MMOCoreORB`:

```sh
lua tests/local/frs_gm_editor/menu_spec.lua
FRS_GM_ENGINE_LIBRARY=/absolute/path/libengine3.a tests/local/frs_gm_editor/run-tests.sh
PERFECT_MENU_ENGINE_LIBRARY=/absolute/path/libengine3.a tests/local/perfect_factory_menu/run-native.sh
```

`run-tests.sh` compiles the actual `FrsGmEditor.cpp` and actual
`FrsGmEditorSuiCallback.cpp`. Engine strings, references, parsing and locks are
real. World objects, FRS manager, persistence and SUI/network packets are external
boundary doubles. The FRS double deliberately caps XP while synchronizing rank,
so the production service must restore exact XP. Tests inspect resulting values
and UI behavior, rather than source text or a replacement editor algorithm.

Coverage includes strict nonnegative signed-int parsing (zero/INT_MAX, signs,
whitespace, decimals, garbage, overflow), non-GM and revoked privilege, rank0/11,
invalid council/rank combinations, retained low-XP rank, above-cap exact XP,
Light/Dark/None transitions, unrelated skill/inventory sentinels, client-update
and persistence calls, self/selected targeting, changed selection during a pinned
edit, missing/replaced target, cancel, extra real SUI presentation fields,
malformed row indices, actual saved-value refresh and the above-cap warning.
The Lua test executes the real injector and checks existing choices and reloads.
The separate real-engine snapshot/renderer test proves ordinary snapshots prune
the GM editor and privileged snapshots retain it.

These tests cannot establish the real FrsManager's roster/skill changes, packet
encoding, persistent world saves/reloads or the live20x configuration. Root must
run the published service API against explicitly cloned disposable players and
save/reload there before accepting the release. No test here connects to SQL,
reads player worlds or changes live services. Test directories are ignored by
repository patterns; stage explicitly.
