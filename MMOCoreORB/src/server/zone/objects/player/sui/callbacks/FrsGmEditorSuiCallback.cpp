#include "FrsGmEditorSuiCallback.h"
#include "server/zone/managers/frs/FrsGmEditor.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"

namespace {
const int EDIT_COUNCIL=1, EDIT_RANK=2, EDIT_XP=3, EDIT_TARGET=4;
String councilName(int council) {return council==1?"Light":council==2?"Dark":"None";}
String describe(CreatureObject* target,const FrsGmEditorState& state) {
 StringBuffer text;
 text<<"Target: "<<target->getFirstName()<<" ("<<target->getObjectID()<<")\nCouncil: "<<councilName(state.council)
  <<"\nRank: "<<state.rank<<"\nExact FRS XP: "<<state.xp<<"\n\n"
  <<"GM rank is retained at low XP. Normal FRS upkeep or losses can demote it later.\n";
 if(state.xp>state.normalXpCap)
  text<<"Warning: XP exceeds the normal cap ("<<state.normalXpCap<<"). Ordinary later awards can cap it.\n";
 return text.toString();
}
void publish(CreatureObject* actor,SuiBox* box) {
 actor->getPlayerObject()->addSuiBox(box);actor->sendMessage(box->generateMessage());
}
void showTarget(CreatureObject* actor,CreatureObject* target) {
 FrsGmEditorState state;String error;
 if(!FrsGmEditor::readState(actor,target,state,error)){actor->sendSystemMessage(error);return;}
 ManagedReference<SuiListBox*> box=new SuiListBox(actor,0);
 box->setPromptTitle("GM Force Ranking Editor");box->setPromptText(describe(target,state));
 box->addMenuItem("Set Council",EDIT_COUNCIL);
 if(state.council==1||state.council==2)box->addMenuItem("Set Rank (0-11)",EDIT_RANK);
 box->addMenuItem("Set Exact FRS XP",EDIT_XP);box->addMenuItem("Choose Another Target",EDIT_TARGET);
 box->setCallback(new FrsGmEditorSuiCallback(actor->getZoneServer(),FrsGmEditorSuiCallback::EDIT,target));
 publish(actor,box);
}
void showCouncil(CreatureObject* actor,CreatureObject* target,const FrsGmEditorState& state) {
 ManagedReference<SuiListBox*> box=new SuiListBox(actor,0);
 box->setPromptTitle("Set FRS Council");box->setPromptText(describe(target,state)+"\nExisting XP and enrolled rank are preserved; new enrollment starts at rank 0.");
 box->addMenuItem("None (leave FRS)",0);box->addMenuItem("Light",1);box->addMenuItem("Dark",2);
 box->setCallback(new FrsGmEditorSuiCallback(actor->getZoneServer(),FrsGmEditorSuiCallback::COUNCIL,target));publish(actor,box);
}
void showRank(CreatureObject* actor,CreatureObject* target,const FrsGmEditorState& state) {
 if(state.council!=1&&state.council!=2){actor->sendSystemMessage("Choose Light or Dark council before setting rank.");showTarget(actor,target);return;}
 ManagedReference<SuiListBox*> box=new SuiListBox(actor,0);
 box->setPromptTitle("Set FRS Rank");box->setPromptText(describe(target,state));
 for(int rank=0;rank<=11;++rank)box->addMenuItem("Rank "+String::valueOf(rank),rank);
 box->setCallback(new FrsGmEditorSuiCallback(actor->getZoneServer(),FrsGmEditorSuiCallback::RANK,target));publish(actor,box);
}
void showXp(CreatureObject* actor,CreatureObject* target,const FrsGmEditorState& state) {
 ManagedReference<SuiInputBox*> box=new SuiInputBox(actor,0);
 box->setPromptTitle("Set Exact FRS XP");box->setPromptText(describe(target,state)+"\nEnter the exact total, from 0 through 2147483647. No XP multiplier or silent cap is applied.");
 box->setMaxInputSize(10);box->setDefaultInput(String::valueOf(state.xp));
 box->setCallback(new FrsGmEditorSuiCallback(actor->getZoneServer(),FrsGmEditorSuiCallback::XP,target));publish(actor,box);
}
}

void FrsGmEditor::open(CreatureObject* actor) {
 if(!actor)return;
 Locker lock(actor);
 if(!isAuthorized(actor)){actor->sendSystemMessage("GM privilege is required.");return;}
 if(!actor->getZoneServer()){actor->sendSystemMessage("The player is not attached to a galaxy.");return;}
 ManagedReference<SuiListBox*> box=new SuiListBox(actor,0);
 box->setPromptTitle("GM Force Ranking Editor");box->setPromptText("Choose a player. That target remains pinned until you explicitly choose another target.");
 box->addMenuItem("Edit Myself",1);box->addMenuItem("Edit Selected Player",2);
 box->setCallback(new FrsGmEditorSuiCallback(actor->getZoneServer(),FrsGmEditorSuiCallback::TARGET));publish(actor,box);
}
void FrsGmEditorSuiCallback::run(CreatureObject* actor,SuiBox* box,uint32 eventIndex,Vector<UnicodeString>* args) {
 if(!actor)return;
 Locker lock(actor);
 if(!FrsGmEditor::isAuthorized(actor)){actor->sendSystemMessage("GM privilege is required.");return;}
 if(server==nullptr||server!=actor->getZoneServer())return;
 // Cancel, unknown events, missing args and the wrong box kind never mutate.
 if(eventIndex!=0||!box||!args||args->size()<1)return;
 if(stage==XP ? !box->isInputBox() : !box->isListBox())return;
 String error;
 if(stage==TARGET) {
  int index;
  auto list=cast<SuiListBox*>(box);
  if(!FrsGmEditor::parseNonnegativeInt(args->get(0).toString(),index)||index>=list->getMenuSize())return;
  uint64 choice=list->getMenuObjectID(index);
  ManagedReference<CreatureObject*> selected;
  if(choice==1)selected=actor;
  else if(choice==2)selected=server->getObject(actor->getTargetID()).castTo<CreatureObject*>();
  else return;
  FrsGmEditorState state;
  if(!FrsGmEditor::readState(actor,selected,state,error)){actor->sendSystemMessage(error);return;}
  showTarget(actor,selected);return;
 }
 // Revalidate the pinned reference against its original server/OID. A changed
 // selection, reused client row, disconnected target or replaced object cannot
 // redirect an already open edit dialog to another character.
 auto current=server->getObject(targetId).castTo<CreatureObject*>();
 if(target==nullptr||current.get()!=target.get()||target->getObjectID()!=targetId) {
  actor->sendSystemMessage("The pinned player is no longer available. Reopen the editor.");return;
 }
 FrsGmEditorState state;
 if(!FrsGmEditor::readState(actor,target,state,error)){actor->sendSystemMessage(error);return;}
 if(stage==XP) {
  int total;
  if(!FrsGmEditor::parseNonnegativeInt(args->get(0).toString(),total))error="Enter an exact integer from 0 through 2147483647; no signs, spaces or decimals.";
  else FrsGmEditor::setExactXp(actor,target,total,error);
  if(!error.isEmpty())actor->sendSystemMessage(error);
  showTarget(actor,target);return;
 }
 int index;
 auto list=cast<SuiListBox*>(box);
 if(!FrsGmEditor::parseNonnegativeInt(args->get(0).toString(),index)||index>=list->getMenuSize())return;
 uint64 choice=list->getMenuObjectID(index);
 if(stage==EDIT) {
  if(choice==EDIT_COUNCIL)showCouncil(actor,target,state);
  else if(choice==EDIT_RANK)showRank(actor,target,state);
  else if(choice==EDIT_XP)showXp(actor,target,state);
  else if(choice==EDIT_TARGET)FrsGmEditor::open(actor);
  return;
 }
 if(stage==COUNCIL&&choice<=2) {
  int rank=choice==0?-1:(state.rank>=0&&state.rank<=11?state.rank:0);
  FrsGmEditor::setCouncilAndRank(actor,target,choice,rank,error);
 }else if(stage==RANK&&choice<=11)FrsGmEditor::setCouncilAndRank(actor,target,state.council,choice,error);
 else return;
 if(!error.isEmpty())actor->sendSystemMessage(error);
 showTarget(actor,target);
}
