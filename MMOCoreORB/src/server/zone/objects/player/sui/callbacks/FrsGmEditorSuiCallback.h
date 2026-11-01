#ifndef FRSGMEDITORSUICALLBACK_H_
#define FRSGMEDITORSUICALLBACK_H_
#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/creature/CreatureObject.h"

// Server-owned stage and target; no name/OID is accepted from an input field.
class FrsGmEditorSuiCallback : public SuiCallback {
public:
 enum Stage { TARGET, EDIT, COUNCIL, RANK, XP };
 FrsGmEditorSuiCallback(ZoneServer* server, Stage stage, CreatureObject* pinned = nullptr)
  : SuiCallback(server), stage(stage), target(pinned), targetId(pinned ? pinned->getObjectID() : 0) {}
 void run(CreatureObject* actor, SuiBox* box, uint32 eventIndex, Vector<UnicodeString>* args) override;
private:
 Stage stage;
 ManagedReference<CreatureObject*> target;
 uint64 targetId;
};
#endif
