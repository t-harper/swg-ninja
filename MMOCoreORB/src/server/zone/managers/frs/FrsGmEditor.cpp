// pre9 local: surgical staff FRS changes; no ordinary progression bypasses.
#include "FrsGmEditor.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/frs/FrsManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/FactionStatus.h"
#include "server/zone/packets/player/PlayerObjectDeltaMessage8.h"
#include "templates/faction/Factions.h"
#include <climits>

namespace {
bool validate(CreatureObject* actor, CreatureObject* target, String& error) {
 if (!FrsGmEditor::isAuthorized(actor)) {error="GM privilege is required.";return false;}
 if (!target || !target->isPlayerCreature() || !target->getPlayerObject() || !actor->getZoneServer() || target->getZoneServer()!=actor->getZoneServer()) {
  error="The pinned target is not an available player in this galaxy.";return false;
 }
 return true;
}
void snapshot(CreatureObject* target, FrsGmEditorState& state) {
 auto ghost=target->getPlayerObject();
 state.council=ghost->getFrsData()->getCouncilType();state.rank=ghost->getFrsData()->getRank();
 state.xp=ghost->getExperience("force_rank_xp");state.jediState=ghost->getJediState();
 state.faction=target->getFaction();state.factionStatus=target->getFactionStatus();
 auto caps=ghost->getXpTypeCapList();
 state.normalXpCap=caps->contains("force_rank_xp") ? caps->get("force_rank_xp") : 2000;
}
void assignExactXp(PlayerObject* ghost, int total) {
 Locker lock(ghost);
 auto packet=new PlayerObjectDeltaMessage8(static_cast<PlayerObjectImplementation*>(ghost->_getImplementation()));
 packet->startUpdate(0);
 // The non-const getter marks the PlayerObject dirty through _getImplementation.
 // DeltaVectorMap updates its serialized list counter; no award multiplier/cap.
 ghost->getExperienceList()->set("force_rank_xp",total,packet,1);
 packet->close();ghost->sendMessage(packet);
}
void persist(CreatureObject* target) {
 target->getPlayerObject()->updateToDatabase();
 target->updateToDatabase();
}
void audit(CreatureObject* actor,CreatureObject* target,const FrsGmEditorState& oldState) {
 FrsGmEditorState state;snapshot(target,state);
 Logger::console.info(true)<<"FrsGmEditor actor="<<actor->getFirstName()<<" actorId="<<actor->getObjectID()
  <<" target="<<target->getFirstName()<<" targetId="<<target->getObjectID()
  <<" oldCouncil="<<oldState.council<<" newCouncil="<<state.council
  <<" oldRank="<<oldState.rank<<" newRank="<<state.rank<<" oldXp="<<oldState.xp<<" newXp="<<state.xp;
}
}

bool FrsGmEditor::isAuthorized(CreatureObject* actor) {
 return actor && actor->isPlayerCreature() && actor->getPlayerObject() && actor->getPlayerObject()->isPrivileged();
}
bool FrsGmEditor::parseNonnegativeInt(const String& text,int& value) {
 if(text.isEmpty()) return false;
 int result=0;
 for(int i=0;i<text.length();++i) {
  const char c=text.charAt(i);
  if(c<'0'||c>'9') return false;
  const int digit=c-'0';
  if(result>(INT_MAX-digit)/10) return false;
  result=result*10+digit;
 }
 value=result;return true;
}
bool FrsGmEditor::readState(CreatureObject* actor,CreatureObject* target,FrsGmEditorState& state,String& error) {
 error="";
 if(!actor||!target){error="A GM and player target are required.";return false;}
 Locker actorLock(actor);Locker targetLock(target,actor);
 if(!validate(actor,target,error)) return false;
 snapshot(target,state);return true;
}
bool FrsGmEditor::setExactXp(CreatureObject* actor,CreatureObject* target,int total,String& error) {
 error="";
 if(!actor||!target){error="A GM and player target are required.";return false;}
 Locker actorLock(actor);Locker targetLock(target,actor);
 if(!validate(actor,target,error)) return false;
 if(total<0){error="XP must be an exact integer from 0 through 2147483647.";return false;}
 FrsGmEditorState before;snapshot(target,before);
 assignExactXp(target->getPlayerObject(),total);
 persist(target);audit(actor,target,before);return true;
}
bool FrsGmEditor::setCouncilAndRank(CreatureObject* actor,CreatureObject* target,int council,int rank,String& error) {
 error="";
 if(!actor||!target){error="A GM and player target are required.";return false;}
 Locker actorLock(actor);Locker targetLock(target,actor);
 if(!validate(actor,target,error)) return false;
 if(council<0||council>2||(council==0?rank!=-1:rank<0||rank>11)) {
  error="Choose None with rank -1, or Light/Dark with rank 0 through 11.";return false;
 }
 auto manager=actor->getZoneServer()->getFrsManager();
 if(!manager||!manager->isFrsEnabled()||(rank>0&&!manager->getFrsRank(council,rank))) {
  error="The Force Ranking manager is not ready.";return false;
 }
 auto ghost=target->getPlayerObject();
 FrsGmEditorState before;snapshot(target,before);
 // Clean the OLD council first. Even same-council edits remove rank0 permissions
 // correctly; setPlayerRank alone removes only old positive-rank permissions.
 manager->removeFromFrs(target);
 ghost->getFrsData()->setCouncilType(0);
 if(council!=0) {
  target->addSkill("force_title_jedi_rank_03",true);
  ghost->setJediState(council==1?4:8);
  target->setFaction(council==1?Factions::FACTIONREBEL:Factions::FACTIONIMPERIAL);
  target->setFactionStatus(FactionStatus::OVERT);
  ghost->getFrsData()->setCouncilType(council);
  manager->setPlayerRank(target,rank);
  manager->validatePlayerData(target);
 }
 // Skill-limit recalculation can cap XP. The GM operation preserves the actual
 // old total, even above its ordinary cap, and never runs the XP demotion path.
 assignExactXp(ghost,before.xp);
 persist(target);audit(actor,target,before);
 return true;
}
