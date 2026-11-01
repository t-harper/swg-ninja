# Login username boundary regression

From `MMOCoreORB` run:

```sh
bash tests/local/login_username/run-native.sh
```

The test compiles the real `AccountVersionMessage` decoder and links the real
engine `Packet`/`String` implementation. It verifies the decoded identity that
`AccountManager::loginAccount` passes to SQL/session lookup and AutoReg, before
SQL escaping or the optional SWGRealms session API. Fixtures cover leading,
trailing and mixed whitespace, a new account name, whitespace-only/empty names,
unchanged case/internal characters/SQL metacharacters, unchanged client version,
and exact length-delimited password bytes including an embedded NUL.

Whitespace uses the engine's existing `String::trim()` definition: space, tab,
CR, LF and form feed. Passwords are never trimmed. No account/character/credential
records are read or modified, and the test does not connect to a galaxy or SQL.
Actual database authentication and auto-registration remain integration checks.

`LOGIN_ENGINE_LIBRARY=/absolute/path/libengine3.a` selects an already-built engine
library when this worktree does not have one. The compiler and library must use
the same engine headers/toolchain. The script compiles one small executable in
a temporary directory and removes it on exit; it does not invoke IDL or rebuild
Core3. This repository ignores paths containing `test`, so stage this directory
explicitly when committing.
