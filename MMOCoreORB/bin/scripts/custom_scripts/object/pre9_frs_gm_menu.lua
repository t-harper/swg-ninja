-- pre9 local: native snapshots hide this leaf from non-privileged players.
-- Native entry, callbacks and service operations independently recheck privilege.
local path="object/tangible/terminal/terminal_character_builder.iff"
local t=ObjectTemplates[crcString(path)]
if not t or type(t.itemList)~="table" then print("pre9_frs_gm_menu: missing character builder");return end
local tools
for i=1,#t.itemList,2 do if t.itemList[i]=="GM Tools" and type(t.itemList[i+1])=="table" then tools=t.itemList[i+1];break end end
if not tools then tools={};t.itemList[#t.itemList+1]="GM Tools";t.itemList[#t.itemList+1]=tools end
for i=1,#tools,2 do if tools[i+1]=="gm_frs_editor" then return end end
local label="Force Ranking Editor"
local names={};for i=1,#tools,2 do names[tools[i]]=true end
while names[label] do label=label.." (GM)" end
tools[#tools+1]=label;tools[#tools+1]="gm_frs_editor"
ObjectTemplates:addTemplate(t,path)
