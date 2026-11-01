#pragma once
#include "templates/tangible/CharacterBuilderMenuNode.h"
#include <vector>
#include <array>
// External UI/network boundary for the actual renderer .cpp. Tree ownership,
// sorting, filtering and Lua parsing use the real engine and production header.
class BaseMessage { public: virtual ~BaseMessage() {} };
class SuiCharacterBuilderBoxImplementation {
 Reference<const CharacterBuilderMenuNode*> rootNode;
 const CharacterBuilderMenuNode* currentNode;
 uint32 boxID = 1;
 String promptTitle, promptText, otherButtonText, cancelButtonText, okButtonText;
 bool hasGenerated = false;
public:
 std::vector<std::array<String,4>> settings;
 explicit SuiCharacterBuilderBoxImplementation(const CharacterBuilderMenuNode* root) : rootNode(root), currentNode(root) {}
 void addHeader(const String&,const String&) {}
 void addSetting(const String& type,const String& target,const String& key,const String& value) {settings.push_back({type,target,key,value});}
 void setHandlerText(const String&) {}
 void generateHeader(BaseMessage*) {}
 void generateBody(BaseMessage*) {}
 void generateFooter(BaseMessage*) {}
 BaseMessage* generateMessage();
 const CharacterBuilderMenuNode* getCurrentNode();
 void setCurrentNode(const CharacterBuilderMenuNode*);
};
