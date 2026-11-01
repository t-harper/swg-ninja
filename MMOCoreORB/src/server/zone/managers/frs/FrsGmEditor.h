#ifndef FRSGMEDITOR_H_
#define FRSGMEDITOR_H_
#include "engine/engine.h"
namespace server { namespace zone { namespace objects { namespace creature { class CreatureObject; } } } }
using namespace server::zone::objects::creature;

// Actual values, including GM XP above ordinary limits; reading never mutates.
struct FrsGmEditorState {
 int council = 0;
 int rank = -1;
 int xp = 0;
 int jediState = 0;
 uint32 faction = 0;
 int factionStatus = 0;
 int normalXpCap = 2000;
};

class FrsGmEditor {
public:
 static bool isAuthorized(CreatureObject* actor);
 static bool parseNonnegativeInt(const String& text, int& value);
 static bool readState(CreatureObject* actor, CreatureObject* target, FrsGmEditorState& state, String& error);
 // council0 requires rank-1; Light/Dark accept ranks0..11. Existing XP survives.
 static bool setCouncilAndRank(CreatureObject* actor, CreatureObject* target, int council, int rank, String& error);
 static bool setExactXp(CreatureObject* actor, CreatureObject* target, int total, String& error);
 static void open(CreatureObject* actor);
};
#endif
