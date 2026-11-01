local source=arg[1] or "bin/scripts/custom_scripts/object/pre9_frs_gm_menu.lua"
local path="object/tangible/terminal/terminal_character_builder.iff"
crcString=function(s)return s end
local t={itemList={"Items",{"Original","original:token"},"GM Tools",{"Existing Staff Tool","gm_other"}}}
ObjectTemplates={[path]=t,addTemplate=function()end}
local function find(menu,name) for i=1,#menu,2 do if menu[i]==name then return menu[i+1] end end return nil end
local function scan(menu)
 local names={}
 for i=1,#menu,2 do assert(not names[menu[i]],"duplicate sibling");names[menu[i]]=true;if type(menu[i+1])=="table" then scan(menu[i+1]) end end
end
dofile(source);dofile(source)
local tools=find(t.itemList,"GM Tools")
assert(find(tools,"Force Ranking Editor")=="gm_frs_editor","FRS editor missing")
assert(find(tools,"Existing Staff Tool")=="gm_other","existing staff tool changed")
assert(find(find(t.itemList,"Items"),"Original")=="original:token","original item changed")
scan(t.itemList)
print("FRS GM menu: real injector, preserved choices, repeat loading PASS")
