# Standalone FIFO regression

Compile the production transport test from MMOCoreORB:

```sh
c++ -std=c++14 -Wall -Wextra -Werror -pthread -I src tests/local/fifo_console/FifoConsoleReaderTest.cpp -o /tmp/fifo-reader-test
/tmp/fifo-reader-test
```

Compile with `-DLEGACY_FIFO_REPRO` (no source include path required) to reproduce the old blocked-open bug. It intentionally exits1 after verifying stop failed; it wakes and joins only its own temporary FIFO thread before returning. Neither mode touches any server or configured console FIFO. Tests use mkdtemp and never require an ORB, game database or live services.
