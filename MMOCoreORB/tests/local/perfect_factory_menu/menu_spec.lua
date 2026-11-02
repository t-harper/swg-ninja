-- Executes the production injector; only template registration is a boundary double.
local source = arg[1] or "bin/scripts/custom_scripts/object/pre9_factory_crates.lua"
local function loadMenu()
 dofile(source)
 dofile(source:gsub("pre9_factory_crates%.lua$", "pre9_zz_menu_sort.lua"))
end
local function product(id, label, professions, category, target)
 return {id=id, kind="recipe", draftPath="object/draft_schematic/test.iff", targetTemplate=target or "object/tangible/test.iff", variantIndex=-1, variantId="base", professions=professions, category=category, label=label, ingredientChoices={}, sourceProfile="normal", provenance={}, expectedFactoryEligible=true, availability="pending", qualitySignature="fixture"}
end
local function sub(menu, label)
 for i=1,#menu,2 do if menu[i]==label then return menu[i+1] end end
 return nil
end
local function setup(entries)
 crcString=function(s) return s end
 local t={itemList={"Items", {"Unrelated", "object/tangible/existing.iff", "Factory Crates", {"Tailor", {"Existing Custom", "custom:keep", "Trim (crate of 1000)", "crate:Custom Trim:object/tangible/component/clothing/trim.iff", "Components", {"Cargo Pocket", "custom:cargo"}}, "Other Custom", {"Keep", "custom:also_keep"}, "Chef", {"Food", {"Food 01", "custom:food"}}}}}}
 ObjectTemplates={["object/tangible/terminal/terminal_character_builder.iff"]=t, addTemplate=function() end}
 PerfectFactoryCatalog={schemaVersion=1, qualityRevision="normal100-v1", sourceFingerprint="fixture", entries=entries, exceptions={}}
 return t
end
local function scan(menu, counts)
 assert(#menu%2==0,"odd menu")
 local names={}; local leaves=0; local previous
 for i=1,#menu,2 do
  assert(not previous or previous<=menu[i]:lower(),"final menu sort missing"); previous=menu[i]:lower()
  assert(type(menu[i])=="string" and not names[menu[i]],"duplicate sibling: "..tostring(menu[i])); names[menu[i]]=true
  assert(not menu[i]:find("[\128-\255]"),"non-ASCII SUI display label: "..menu[i])
  local value=menu[i+1]
  if type(value)=="table" then scan(value,counts) else
   leaves=leaves+1
   if value:match("^perfectcrate:") then
    assert(not value:find(".iff",1,true),"perfect selection bypasses native catalog")
    counts[value]=(counts[value] or 0)+1
   end
  end
 end
 assert(leaves<=35,"unbounded leaf menu")
end
local entries={product("r_a001","Cargo Pocket",{"Tailor"},"components","object/tangible/component/clothing/cargo_pocket.iff"),product("r_a002","Medical Pack",{"Doctor","combat_medic","Combat Medic"},"medicine"),product("r_a003","Tissue",{"bio_engineer","BioEngineer"},"components")}
for i=1,73 do entries[#entries+1]=product(string.format("r_b%03x",i),"Food "..string.format("%02d",i),{"chef"},"food") end
entries[#entries+1]=product("r_c001","Same Label",{"Chef"},"food")
entries[#entries+1]=product("r_c002","Same Label",{"Chef"},"food")
entries[#entries+1]=product("r_a004","Group Medicine",{"Medic / Doctor"},"medicine")
local t=setup(entries)
loadMenu()
local items=sub(t.itemList,"Items"); local crates=sub(items,"Factory Crates")
assert(type(sub(crates,"Chef"))=="table","Chef catalog is missing")
assert(type(sub(crates,"Bio-Engineer"))=="table","Bio-Engineer alias is missing")
assert(type(sub(crates,"Combat Medic"))=="table","Combat Medic alias is missing")
assert(sub(items,"Unrelated")=="object/tangible/existing.iff","unrelated choice changed")
assert(sub(sub(crates,"Tailor"),"Existing Custom")=="custom:keep","Tailor custom choice lost")
assert(sub(sub(crates,"Tailor"),"Cargo Pocket (crate of 1000)")=="crate:Cargo Pocket:object/tangible/component/clothing/cargo_pocket.iff","legacy Tailor path changed")
assert(sub(sub(crates,"Tailor"),"Trim (crate of 1000)")=="crate:Custom Trim:object/tangible/component/clothing/trim.iff","customized legacy Tailor choice changed")
assert(sub(sub(crates,"Other Custom"),"Keep")=="custom:also_keep","custom crate branch lost")
assert(sub(sub(sub(crates,"Tailor"),"Components"),"Cargo Pocket")=="custom:cargo","catalog overwrote same-named custom component")
assert(sub(sub(sub(crates,"Chef"),"Food"),"Food 01")=="custom:food","catalog overwrote same-named custom choice")
local counts={}; scan(t.itemList,counts)
assert(counts["perfectcrate:r_a004"]==2,"Medic / Doctor must expose both professions")
assert(counts["perfectcrate:r_a002"]==2,"profession aliases must deduplicate within a profession")
assert(counts["perfectcrate:r_a003"]==1,"Bio-Engineer aliases duplicated")
for i=1,73 do assert(counts[string.format("perfectcrate:r_b%03x",i)]==1,"food unreachable") end
assert(counts["perfectcrate:r_c001"]==1 and counts["perfectcrate:r_c002"]==1,"duplicate readable labels dropped an item")
local foodPages=sub(sub(crates,"Chef"),"Food")
local customPage
for i=1,#foodPages,2 do if type(foodPages[i+1])=="table" and #foodPages[i+1]==70 then customPage=foodPages[i+1]; break end end
assert(customPage,"missing full catalog page")
customPage[#customPage+1]="Page Custom"; customPage[#customPage+1]="custom:page"
loadMenu()
local again={}; scan(t.itemList,again)
for token,n in pairs(counts) do assert(again[token]==n,"reloading duplicates or loses "..token) end
-- Removing a catalog product must remove its stale generated route on reload.
PerfectFactoryCatalog.entries={entries[1]}; loadMenu()
local reduced={}; scan(t.itemList,reduced)
assert(not reduced["perfectcrate:r_a002"],"removed catalog id remains selectable")
-- Duplicate ids with conflicting records must never choose one arbitrarily.
t=setup({product("r_dead","First",{"Chef"},"food"),product("r_dead","Second",{"Chef"},"food"),product("not:an_id","Invalid",{"Chef"},"food")})
loadMenu(); local invalid={}; scan(t.itemList,invalid); assert(next(invalid)==nil,"ambiguous/malformed id exposed")
PerfectFactoryCatalog={schemaVersion=9, entries={product("r_1234","Bad schema",{"Chef"},"food")}}; loadMenu()
invalid={}; scan(t.itemList,invalid); assert(next(invalid)==nil,"unsupported catalog schema exposed")
print("perfect factory menu: behavior, aliases, pages, reload, invalid input PASS")

local function checkPageLabels(menu)
 local pages=0
 for i=1,#menu,2 do
  if type(menu[i+1])=="table" then
   if menu[i]:match("^%d%d%d%-%d%d%d:") then
    assert(not menu[i]:find("[\128-\255]"),"non-ASCII paginated SUI label: "..menu[i])
    pages=pages+1
   end
   pages=pages+checkPageLabels(menu[i+1])
  end
 end
 return pages
end

if arg[2] then
 local actual=setup({})
 dofile(arg[2]); loadMenu()
 assert(checkPageLabels(actual.itemList)>0,"complete catalog did not exercise page labels")
 local fullCounts={}; scan(actual.itemList,fullCounts)
 for _,entry in ipairs(PerfectFactoryCatalog.entries) do assert(fullCounts["perfectcrate:"..entry.id],"unreachable product: "..entry.id) end
 local fullCrates=sub(sub(actual.itemList,"Items"),"Factory Crates")
 for _,name in ipairs({"Chef","Bio-Engineer","Jedi","Doctor","Medic","Combat Medic","Musician","Scout","Ranger"}) do assert(sub(fullCrates,name),"missing explicit profession "..name) end
 print("perfect factory menu: complete generated catalog reachability PASS ("..#PerfectFactoryCatalog.entries.." products)")
end
