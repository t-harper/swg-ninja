Run from `MMOCoreORB`:

```sh
lua tests/local/space_spawning/spawning_spec.lua
python3 tests/local/space_spawning/cas_binding_spec.py
```

The Lua harness loads the real `space_spawner.lua` and executes its patrol,
spawning, retry, completion and destruction methods. World creation, scene-object
lookup, Director storage, observers and scheduled events are boundary doubles:
these tests cannot reach a live galaxy. Injected interleavings cover rapid deaths
with stale native squadron sizes, death during initial formation, arrival during
partial retries, competing completion owners, lost-wakeup boundaries and duplicate
queued reconciliation. Existing native squadronSize is deliberately not treated
as a living-ship count: destruction notification precedes delayed membership
removal in Core3.

Cohorts use the production Director compare-and-set binding for nonblocking
ownership. State1 is idle,2 owned/assembling,3 owned with a pending signal;
closed keys are absent/zero. The owner rescans dirty state before releasing, and a
CAS-coalesced queued token handles release between failed claims. Callback losers
never wait while holding another ship lock. New IDs are published before observers
and assembly completion reconciles deaths before releasing the cohort.

`cas_binding_spec.py` compiles the actual extracted C++ binding method against
minimal Lua/Director boundary doubles and races32 threads for100 rounds. It checks
comparison/update atomicity, mismatch, missing keys and invalid argument counts.
It does not replace native engine coverage. `DirectorSharedMemoryTest.*` in
`src/tests/DirectorSharedMemoryTest.cpp` exercises actual Director storage and the Lua
C-function boundary; the orchestrator runs those native tests in an isolated container.
The Lua tests model adversarial callback orders; they do not simulate the entire
multithreaded game world. Build, native integration and gameplay remain separate
deployment checks.

`SPACE_SPAWNER_SOURCE=/path/to/baseline.lua` selects a saved real baseline for
regression demonstrations. Zone declarations are executed and checked for valid
intervals and unchanged authored record/slot counts.
