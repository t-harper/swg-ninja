Run from `MMOCoreORB`:

```sh
lua tests/local/space_spawning/spawning_spec.lua
```

The harness loads the real `space_spawner.lua` and executes its patrol, spawning,
retry, completion and destruction methods. World creation, scene-object lookup,
Director shared memory, observer registration and scheduled events are in-memory
boundary doubles: running the tests cannot reach a live galaxy. The real engine
requires a running ZoneServer and templates for those operations.

The scheduler double leaves callbacks pending so tests can deliver duplicates,
stale task anchors, and destruction after route cleanup. The squadron-size
argument is an engine-provided count, not a Lua-maintained counter. Production
ScreenPlayTasks lock their scene-object anchor; the harness exercises their
resulting serial order, not real multi-threaded C++ execution. Engine integration
and gameplay verification remain separate rollout checks.

`SPACE_SPAWNER_SOURCE=/path/to/baseline.lua` selects a saved real baseline for
regression demonstrations. Zone declarations are also executed and checked for
valid intervals and unchanged authored record/slot counts.
