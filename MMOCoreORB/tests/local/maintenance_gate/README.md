# Maintenance admission gate

Run `bash run-tests.sh` with a C++17 compiler and pthreads. The standalone suite
compiles and executes the production `NinjaMaintenanceGate.h`; it needs no server,
database, game assets, secrets, or live service. Temporary marker fixtures and
the executable are removed after the run.

Tests cover all-account blocking, active-admission draining and publication of
connected-player counts, wrong-owner operations, reconnect/remote-approval
rechecks, boot ownership across simulated restarts, malformed/unreadable/FIFO/
symlink markers, token length boundaries, RAII moves/exceptions and a concurrent
acquisition/admission race. The count-reader interleaving detects stale sampling
before gate acquisition. Delayed callback fixtures execute the real gate API;
the complete engine callback/world insertion requires a Core3 build and separate
runtime validation.

The shared `conf/ninja-maintenance.token` marker accepts a lowercase hex token
(32–64 characters), optionally followed by LF or CRLF. Absence opens admission;
malformed/unreadable/nonregular markers fail closed without a claimable owner.
Repair/remove an invalid marker and restart under operator control. There is
no automatic reopening or expiry.

Runtime commands are `maintenance acquire TOKEN`, `maintenance status TOKEN` and
`maintenance release TOKEN`. Matching release acknowledges `owned=1 blocked=0`;
later status returns `owned=0 blocked=0`. Release does not remove the shared boot
marker: the updater owns its lifecycle across both galaxy processes. A marker
left on disk intentionally closes admission again on the next restart.

`players=-1` means no zone server exists yet; an updater must reject this as an
empty-window acknowledgment. Protocol replies go through the core logger as a
single payload line prefixed `NINJA_MAINTENANCE`.
