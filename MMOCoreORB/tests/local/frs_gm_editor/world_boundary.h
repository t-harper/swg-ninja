#pragma once
#include "engine/engine.h"
#include <set>
#include <map>
#include <string>
namespace server { namespace zone { namespace objects { namespace creature { class CreatureObject; } namespace player { class PlayerObject; } } } }
using server::zone::objects::creature::CreatureObject;
using server::zone::objects::player::PlayerObject;
struct FrsData {int council=0,rank=-1; int getCouncilType(){return council;} int getRank(){return rank;} void setCouncilType(int c){council=c;} void setRank(int r){rank=r;}};
struct Factions {enum {FACTIONREBEL=1,FACTIONIMPERIAL=2};};
struct FactionStatus {enum {OVERT=2};};
struct FrsRank {};
class ZoneServer; class SuiBox;
class SuiCallback:public Object {
public:ZoneServer* server;explicit SuiCallback(ZoneServer*s):server(s){}virtual void run(CreatureObject*,SuiBox*,uint32,Vector<UnicodeString>*)=0;
};
struct GmUiMessage {};
class SuiBox:public Object {
public:Reference<SuiCallback*> callback;String prompt;int kind;explicit SuiBox(int k):kind(k){}
 bool isListBox(){return kind==1;}bool isInputBox(){return kind==2;}void setCallback(SuiCallback*c){callback=c;}
 void setPromptTitle(const String&){}void setPromptText(const String&s){prompt=s;}GmUiMessage* generateMessage(){return new GmUiMessage;}
};
class SuiListBox:public SuiBox {
public:std::vector<std::pair<String,uint64>> rows;SuiListBox(CreatureObject*,uint32=0):SuiBox(1){}
 void addMenuItem(const String&s,uint64 id=0){rows.push_back({s,id});}int getMenuSize(){return rows.size();}uint64 getMenuObjectID(int n){return rows.at(n).second;}
};
class SuiInputBox:public SuiBox {
public:String defaultInput;SuiInputBox(CreatureObject*,uint32=0):SuiBox(2){}void setMaxInputSize(int){}void setDefaultInput(const String&s){defaultInput=s;}
};
class PlayerObjectDeltaMessage8 {public: explicit PlayerObjectDeltaMessage8(PlayerObject*){} void startUpdate(int){} void close(){};};
using PlayerObjectImplementation=PlayerObject;
struct ExperienceMap {int* xp; void set(const String&,int n,PlayerObjectDeltaMessage8*,int){*xp=n;}};
namespace server { namespace zone { namespace objects { namespace player {
class PlayerObject:public Object,public Mutex {
public:
 Reference<SuiBox*> lastBox;void addSuiBox(SuiBox*b){lastBox=b;}
 bool privileged=false; int xp=0,jediState=0,deltas=0,saves=0; FrsData frs; ExperienceMap experience{&xp};
 VectorMap<String,int> caps; std::set<std::string> permissions;
 PlayerObject(){caps.setAllowOverwriteInsertPlan();caps.put("force_rank_xp",15000);}
 bool isPrivileged(){return privileged;} FrsData* getFrsData(){return &frs;} int getExperience(const String&){return xp;}
 int getJediState(){return jediState;} void setJediState(int n){jediState=n;} VectorMap<String,int>* getXpTypeCapList(){return &caps;}
 ExperienceMap* getExperienceList(){return &experience;} PlayerObject* _getImplementation(){return this;}
 void sendMessage(PlayerObjectDeltaMessage8* packet){++deltas;delete packet;} void updateToDatabase(){++saves;}
 bool hasPermissionGroup(const String& s){return permissions.count(s.toCharArray());}
 void removePermissionGroup(const String&s,bool){permissions.erase(s.toCharArray());}
};
} } } }
class FrsManager {public:std::set<uint64> light,dark; FrsRank rank; bool isFrsEnabled(){return true;} FrsRank* getFrsRank(int,int){return &rank;} void removeFromFrs(CreatureObject*);void setPlayerRank(CreatureObject*,int);void validatePlayerData(CreatureObject*,bool=false){};};
class ZoneServer {public:FrsManager frs;std::map<uint64,CreatureObject*> objects;FrsManager* getFrsManager(){return &frs;}ManagedReference<CreatureObject*> getObject(uint64);};
namespace server { namespace zone { namespace objects { namespace creature {
class CreatureObject:public Object,public Mutex {
public:
 ZoneServer* world;uint64 oid;uint64 targetId=0;std::vector<String> messages;PlayerObject ghost;int faction=0,factionStatus=0,inventoryMarker=0,saves=0;std::set<std::string> skills;
 CreatureObject(ZoneServer*w,uint64 id,bool gm):world(w),oid(id){ghost.privileged=gm;w->objects[id]=this;}
 PlayerObject* getPlayerObject(){return &ghost;} bool isPlayerCreature(){return true;} ZoneServer* getZoneServer(){return world;}
 uint64 getObjectID(){return oid;} String getFirstName(){return String::valueOf(oid);} uint32 getFaction(){return faction;} int getFactionStatus(){return factionStatus;}
 void setFaction(uint32 n){faction=n;} void setFactionStatus(int n){factionStatus=n;}
 bool hasSkill(const String&s){return skills.count(s.toCharArray());} void addSkill(const String&s,bool){skills.insert(s.toCharArray());}
 uint64 getTargetID(){return targetId;} void sendSystemMessage(const String&s){messages.push_back(s);}void sendMessage(GmUiMessage*m){delete m;}
 void updateToDatabase(){++saves;}
};
} } } }
inline void FrsManager::removeFromFrs(CreatureObject*p){
 light.erase(p->oid);dark.erase(p->oid);p->ghost.permissions.clear();p->ghost.frs.rank=-1;p->ghost.frs.council=0;
 // Model normal skill-limit recalculation; production must restore the exact XP.
 p->ghost.xp=std::min(p->ghost.xp,15000);
}
inline void FrsManager::setPlayerRank(CreatureObject*p,int r){p->ghost.frs.rank=r;if(r>0)(p->ghost.frs.council==1?light:dark).insert(p->oid);p->ghost.permissions.insert(std::string(p->ghost.frs.council==1?"LightEnclaveRank":"DarkEnclaveRank")+std::to_string(r));p->ghost.xp=std::min(p->ghost.xp,625000);}

inline ManagedReference<CreatureObject*> ZoneServer::getObject(uint64 id){auto it=objects.find(id);return it==objects.end()?nullptr:it->second;}
