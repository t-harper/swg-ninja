# Station landing behavioral regression

Run `./run-tests.sh` with a C++17 compiler (`CXX` defaults to `c++`). The runner
compiles and executes the **production StoreShipTask header**, then removes its
temporary executable. It needs no server, database, credentials, or game assets.

The boundary doubles replace Core3's generated distributed references, scheduling,
locking and live world objects. `ShipObject::removeAllPlayersFromShip` follows its
existing contract of moving the pilot, gunner and passengers to the ship's saved
launch location. Tests exercise the real task's destination selection, validation,
cleanup and stored parking result through those world boundaries. They do not
match source text or duplicate the task's landing policy.

Coverage: selected destination on another planet, another port on the same planet,
all onboard roles, missing/disabled/space destinations, nonfinite coordinates,
original destruction return, empty-origin Coronet fallback, legacy cleanup behavior,
loading-screen deferral, astromech and group cleanup.
The server's actual distributed locks/networking and real ship removal implementation
still require the normal Core3 build and in-game smoke test.

To check the test against another revision without changing this checkout, write
that revision's `StoreShipTask.h` under a temporary
`server/zone/objects/intangible/tasks/` tree, then set `LANDING_SOURCE_ROOT` to its
root and `SPACE_LANDING_BASELINE_TASK=1` when invoking the runner. The latter
uses the original station constructor call without the new opt-in argument. Only
that production header is replaced; the same
behavioral tests and world boundaries execute it.

The parent `MMOCoreORB/.gitignore` ignores `*test*`; use `git add -f` when staging
this directory.

Station tests opt into the selected destination exactly as the Lua binding does.
Existing four-argument callers retain saved-launch behavior, including the
empty-origin Coronet fallback. The Lua binding itself is checked by source
review and the full Core3 build; the standalone harness compiles the landing task.
