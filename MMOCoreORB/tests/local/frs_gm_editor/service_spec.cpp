#include "server/zone/managers/frs/FrsGmEditor.h"
#include "world_boundary.h"
#include <cassert>
#include <climits>
#include <iostream>
int main() {
 int value=99;
 for(const char* invalid:{"", "-1", "+1", " 1", "1 ", "1.0", "1x", "2147483648", "999999999999999999999999999"}) {assert(!FrsGmEditor::parseNonnegativeInt(invalid,value)); assert(value==99);}
 assert(FrsGmEditor::parseNonnegativeInt("0",value)&&value==0);
 assert(FrsGmEditor::parseNonnegativeInt("2147483647",value)&&value==INT_MAX);
 ZoneServer world; Reference<CreatureObject*> gmRef=new CreatureObject(&world,1,true), targetRef=new CreatureObject(&world,2,false);
 auto& gm=*gmRef.get(); auto& target=*targetRef.get();
 target.ghost.xp=5000; target.skills.insert("combat_rifleman_master"); target.skills.insert("jedi_saber_04"); target.inventoryMarker=17;
 String error;
 assert(!FrsGmEditor::setExactXp(&target,&target,12345,error)); assert(target.ghost.xp==5000);
 assert(FrsGmEditor::setExactXp(&gm,&target,12345,error)); assert(target.ghost.xp==12345); assert(target.ghost.deltas==1);assert(target.ghost.saves==1&&target.saves==1);
 assert(FrsGmEditor::setExactXp(&gm,&target,INT_MAX,error)); assert(target.ghost.xp==INT_MAX);
 assert(!FrsGmEditor::setExactXp(&gm,&target,-1,error)); assert(target.ghost.xp==INT_MAX);
 assert(!FrsGmEditor::setCouncilAndRank(&gm,&target,1,12,error)); assert(target.ghost.frs.rank==-1);
 assert(!FrsGmEditor::setCouncilAndRank(&gm,&target,0,0,error));
 assert(FrsGmEditor::setCouncilAndRank(&gm,&target,1,11,error));
 assert(target.ghost.frs.council==1&&target.ghost.frs.rank==11&&target.ghost.xp==INT_MAX);
 assert(target.ghost.jediState==4&&target.faction==Factions::FACTIONREBEL&&target.factionStatus==FactionStatus::OVERT);
 assert(world.frs.light.count(2)&&!world.frs.dark.count(2));
 assert(FrsGmEditor::setExactXp(&gm,&target,0,error)); assert(target.ghost.xp==0&&target.ghost.frs.rank==11);
 assert(FrsGmEditor::setCouncilAndRank(&gm,&target,2,0,error));
 assert(!world.frs.light.count(2)&&!world.frs.dark.count(2));
 assert(target.ghost.frs.council==2&&target.ghost.frs.rank==0&&target.ghost.jediState==8&&target.ghost.xp==0);
 assert(target.faction==Factions::FACTIONIMPERIAL&&target.ghost.permissions.count("DarkEnclaveRank0"));
 assert(!target.ghost.permissions.count("LightEnclaveRank11"));
 assert(FrsGmEditor::setCouncilAndRank(&gm,&target,2,11,error)); assert(world.frs.dark.count(2));
 assert(FrsGmEditor::setCouncilAndRank(&gm,&target,0,-1,error));
 assert(target.ghost.frs.council==0&&target.ghost.frs.rank==-1&&!world.frs.dark.count(2));
 assert(target.skills.count("combat_rifleman_master")&&target.skills.count("jedi_saber_04")&&target.inventoryMarker==17);
 gm.ghost.privileged=false;
 assert(!FrsGmEditor::setCouncilAndRank(&gm,&target,1,0,error));
 assert(!FrsGmEditor::setExactXp(&gm,&target,25,error)); assert(target.ghost.xp==0);
 FrsGmEditorState denied;assert(!FrsGmEditor::readState(&gm,&target,denied,error));
 gm.ghost.privileged=true;gm.targetId=target.oid;
 FrsGmEditor::open(&gm);
 auto click=[&](const char* input,uint32 event=0){Reference<SuiBox*> box=gm.ghost.lastBox;gm.ghost.lastBox=nullptr;Vector<UnicodeString> args;args.add(UnicodeString(input));args.add(UnicodeString("presentation field"));box->callback->run(&gm,box,event,&args);};
 click("1"); // root: selected player
 assert(gm.ghost.lastBox && gm.ghost.lastBox->prompt.contains("Target: 2"));
 gm.targetId=gm.oid;
 click("1"); // enrolled? None: XP is the second row
 assert(gm.ghost.lastBox->isInputBox());
 click("12345");assert(target.ghost.xp==12345&&gm.ghost.xp==0);
 click("1");click("2147483648");assert(target.ghost.xp==12345);
 click("1");click("42",1);assert(target.ghost.xp==12345); // cancel input
 gm.targetId=target.oid;FrsGmEditor::open(&gm);click("1");
 click("0");click("1");assert(target.ghost.frs.council==1&&target.ghost.frs.rank==0);
 click("1");click("11");assert(target.ghost.frs.rank==11);
 click("2");click("0");assert(target.ghost.xp==0&&target.ghost.frs.rank==11);
 click("0");click("2");assert(target.ghost.frs.council==2&&target.ghost.frs.rank==11);
 click("2");click("2147483647");assert(target.ghost.xp==INT_MAX&&gm.ghost.lastBox->prompt.contains("Warning: XP exceeds the normal cap"));
 click("0");click("0");assert(target.ghost.frs.council==0&&target.ghost.frs.rank==-1&&target.ghost.xp==INT_MAX);
 world.objects.erase(target.oid);click("0");assert(!gm.ghost.lastBox&&target.ghost.frs.council==0);world.objects[target.oid]=&target;
 FrsGmEditor::open(&gm);click("1");Reference<CreatureObject*> replacement=new CreatureObject(&world,target.oid,false);
 click("0");assert(!gm.ghost.lastBox&&replacement->ghost.frs.council==0);world.objects[target.oid]=&target;
 FrsGmEditor::open(&gm);click("0");assert(gm.ghost.lastBox->prompt.contains("Target: 1"));click("0",1);assert(!gm.ghost.lastBox);
 FrsGmEditor::open(&gm);click("1");
 gm.ghost.privileged=false;click("0");assert(!gm.ghost.lastBox);assert(target.ghost.frs.council==0);
 gm.ghost.privileged=true;FrsGmEditor::open(&gm);click("2147483648");assert(!gm.ghost.lastBox);
 std::cout<<"FRS GM service and real callbacks: strict input, privilege, exact XP, rank/council preservation PASS\n";
}
