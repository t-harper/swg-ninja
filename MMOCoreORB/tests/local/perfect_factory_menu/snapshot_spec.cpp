// Real production tree + real engine Reference/WeakReference/SortedVector/Lua.
// A wrong filter, shared-tree mutation, or index remap breaks these assertions.
#include "templates/tangible/CharacterBuilderMenuNode.h"
#include "server/zone/objects/player/sui/characterbuilderbox/SuiCharacterBuilderBox.h"
#include <cassert>
#include <iostream>

static Reference<CharacterBuilderMenuNode*> parse(const char* value) {
 auto state = luaL_newstate();
 assert(luaL_dostring(state, value) == 0);
 LuaObject table(state);
 Reference<CharacterBuilderMenuNode*> root = new CharacterBuilderMenuNode("root");
 root->readLuaObject(table, true);
 lua_close(state);
 return root;
}
static const CharacterBuilderMenuNode* named(const CharacterBuilderMenuNode* node, const char* name) {
 for (int i=0;i<node->getChildNodeSize();++i) if (node->getChildNodeAt(i)->getDisplayName()==name) return node->getChildNodeAt(i);
 return nullptr;
}
int main() {
 auto source=parse("return {'Items', {'Factory Crates', {'Chef', {'Food', {'A Pending', 'perfectcrate:r_aaaa', 'B Verified', 'perfectcrate:r_bbbb', 'C Rejected','perfectcrate:r_cccc'}}, 'Empty New', {'Gone','perfectcrate:r_dead'}, 'Tailor', {'Trim (crate of 1000)','crate:Trim:object/tangible/component/clothing/trim.iff'}}, 'Existing Empty', {}, 'Unrelated','object/tangible/existing.iff'}}");
 auto available=[](const String& id){return id=="r_bbbb";};
 auto snapshot=source->filteredCopy(available);
 assert(source->getChildNodeAt(0)!=snapshot->getChildNodeAt(0));
 auto items=named(snapshot,"Items"); auto crates=named(items,"Factory Crates");
 assert(named(items,"Existing Empty") && named(items,"Unrelated"));
 assert(!named(crates,"Empty New"));
 auto food=named(named(crates,"Chef"),"Food");
 assert(food->getChildNodeSize()==1);
 SuiCharacterBuilderBoxImplementation dialog(snapshot);
 dialog.setCurrentNode(food);
 auto message=dialog.generateMessage();
 bool renderedVerified=false;
 for(const auto& setting:dialog.settings) {
  if(setting[1]=="List.dataList.0" && setting[2]=="Text") {assert(setting[3]=="B Verified"); renderedVerified=true;}
  assert(setting[1]!="List.dataList.1");
 }
 assert(renderedVerified);
 delete message;
 // Renderer rows and returned selection index resolve against the same snapshot.
 assert(dialog.getCurrentNode()->getChildNodeAt(0)->getTemplatePath()=="perfectcrate:r_bbbb");
 assert(food->getChildNodeAt(0)->getDisplayName()=="B Verified");
 assert(food->getChildNodeAt(0)->getTemplatePath()=="perfectcrate:r_bbbb");
 assert(!food->getChildNodeAt(-1) && !food->getChildNodeAt(1));
 assert(food->getParentNode()==named(crates,"Chef"));
 assert(food->getChildNodeAt(0)->getParentNode()==food);
 assert(named(named(crates,"Tailor"),"Trim (crate of 1000)")->getTemplatePath().beginsWith("crate:"));
 auto originalFood=named(named(named(named(source,"Items"),"Factory Crates"),"Chef"),"Food");
 assert(originalFood->getChildNodeSize()==3);
 auto nextSnapshot=source->filteredCopy([](const String& id){return id=="r_aaaa";});
 auto nextFood=named(named(named(named(nextSnapshot,"Items"),"Factory Crates"),"Chef"),"Food");
 assert(nextFood->getChildNodeAt(0)->getTemplatePath()=="perfectcrate:r_aaaa");
 // Older dialogs retain their own root and original index mapping after reload.
 source=nullptr; nextSnapshot=nullptr; snapshot=nullptr;
 assert(food->getChildNodeAt(0)->getTemplatePath()=="perfectcrate:r_bbbb");
 assert(food->getParentNode()!=nullptr);
 auto onlyPending=parse("return {'Items', {'Factory Crates', {'Chef', {'Pending','perfectcrate:r_aaaa'}}, 'Keep','keep'}}");
 auto noProducts=onlyPending->filteredCopy([](const String&){return false;});
 assert(!named(named(noProducts,"Items"),"Factory Crates"));
 assert(named(named(noProducts,"Items"),"Keep"));
 auto staffSource=parse("return {'GM Tools', {'Force Ranking Editor','gm_frs_editor'}, 'Keep','keep'}");
 auto ordinary=staffSource->filteredCopy([](const String&){return true;},false);
 assert(!named(ordinary,"GM Tools") && named(ordinary,"Keep"));
 auto privileged=staffSource->filteredCopy([](const String&){return true;},true);
 assert(named(named(privileged,"GM Tools"),"Force Ranking Editor"));
 std::cout << "perfect factory snapshot: availability, indices, ownership, parent links PASS\n";
}
