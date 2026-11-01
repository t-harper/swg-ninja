#ifndef PERFECTFACTORYRUNTIMEACCEPTANCE_H_
#define PERFECTFACTORYRUNTIMEACCEPTANCE_H_

#include "server/zone/ZoneServer.h"

// Test-only entry point. Called on an engine worker only when the operator has
// explicitly supplied a private disposable-world fixture path.
void runPerfectFactoryRuntimeAcceptance(ZoneServer* server, const String& fixturePath);

#endif
