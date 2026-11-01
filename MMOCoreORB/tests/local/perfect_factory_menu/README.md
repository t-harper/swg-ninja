# Factory catalog menus and native dialog snapshots

Run from `MMOCoreORB`:

```sh
lua tests/local/perfect_factory_menu/menu_spec.lua \
  bin/scripts/custom_scripts/object/pre9_factory_crates.lua \
  bin/scripts/custom_scripts/managers/crafting/perfect_factory_catalog.lua
./tests/local/perfect_factory_menu/run-native.sh
```

The Lua test executes the real injector and final menu sort. Its boundary is
ObjectTemplates registration. Fixtures cover explicit profession aliases, all
catalog products, 35-leaf pages, stable legacy Tailor routes, custom choices,
same-label collisions, duplicate/malformed ids, unsupported schema and reloads.
The optional second argument adds the complete generated catalog audit.

The native test compiles the real CharacterBuilderMenuNode header and actual
SuiCharacterBuilderBox renderer implementation, linking the real engine library
and Lua. Filtering, sorting, references, weak parent links and Lua table parsing
are real. Only external UI/network message assembly is a boundary double. It
checks availability pruning, rendered-row/callback index identity, source-tree
immutability, independent snapshots and retained ownership after the source and
other snapshots are released. It does not emulate world objects or give items.

`PERFECT_MENU_ENGINE_LIBRARY=/absolute/path/libengine3.a` can select an existing
read-only engine library if this worktree has not built one. Compiler/Lua/library
paths must match the engine toolchain. On this host the isolated test links the
already built engine library from the source checkout without changing it.

Generated SUI IDL and terminal/manager integration also need the normal native
build. These focused tests do not replace the required isolated catalog runtime
and real grant/extraction/factory/persistence acceptance. No test reads player
state, connects to SQL or modifies a galaxy. The repository ignores `*test*`, so
stage this directory explicitly when committing.
