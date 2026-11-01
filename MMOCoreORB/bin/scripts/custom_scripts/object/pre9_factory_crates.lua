-- pre9 local: data-only factory catalog menus. Runtime audit availability is
-- applied to an immutable native per-dialog tree, never to display rows alone.
local path = "object/tangible/terminal/terminal_character_builder.iff"
local PREFIX = "perfectcrate:"
local PAGE_SIZE = 35
local function findSub(list, name)
	if type(list) ~= "table" then return nil end
	for i = 1, #list - 1, 2 do
		if list[i] == name and type(list[i + 1]) == "table" then return list[i + 1] end
	end
	return nil
end
local function ensureSub(list, name)
	local child = findSub(list, name)
	if child then return child end
	for i = 1, #list - 1, 2 do
		if list[i] == name then return ensureSub(list, name .. " (Factory Crates)") end
	end
	list[#list + 1] = name
	child = {}; list[#list + 1] = child
	return child
end
local function setLeaf(list, name, token)
	for i = 1, #list - 1, 2 do
		if list[i] == name then list[i + 1] = token; return end
	end
	list[#list + 1] = name; list[#list + 1] = token
end
local function legacyLeaf(list, name, token, original)
	for i = 1, #list - 1, 2 do
		if list[i] == name then
			if list[i + 1] == original then list[i + 1] = token end
			return
		end
	end
	setLeaf(list, name, token)
end
-- Remove only this injector's previous leaves and newly empty catalog branches.
-- This makes reload deterministic while retaining other injectors/custom choices.
local function clearGenerated(list)
	local touched = false
	for i = #list - 1, 1, -2 do
		local value = list[i + 1]
		local remove = false
		if type(value) == "table" then
			local owned = clearGenerated(value)
			remove = owned and #value == 0
			touched = touched or owned
		elseif type(value) == "string" and value:sub(1, #PREFIX) == PREFIX then
			remove = true; touched = true
		end
		if remove then table.remove(list, i + 1); table.remove(list, i) end
	end
	return touched
end
local professionAliases = {
	artisan="Artisan", architect="Architect", armorsmith="Armorsmith",
	bioengineer="Bio-Engineer", bountyhunter="Bounty Hunter", chef="Chef",
	combatmedic="Combat Medic", commando="Commando", doctor="Doctor",
	droidengineer="Droid Engineer", jedi="Jedi", medic="Medic",
	rangerscout="Ranger / Scout", ranger="Ranger", scout="Scout",
	shipwright="Shipwright", smuggler="Smuggler", tailor="Tailor",
	weaponsmith="Weaponsmith", entertainer="Entertainer", musician="Musician",
	dancer="Dancer", squadleader="Squad Leader", creaturehandler="Creature Handler",
}
local professionGroups = {
	medicdoctor = { "Medic", "Doctor" }, artisanmusician = { "Artisan", "Musician" },
	artisangeneral = { "Artisan" }, scoutranger = { "Scout", "Ranger" },
	rangerscout = { "Scout", "Ranger" },
}
local categoryAliases = {
	component="Components", components="Components", subcomponents="Components",
	finished="Finished Items", finisheditems="Finished Items", gear="Finished Gear",
	finishedgear="Finished Gear", medicine="Medicines", medicines="Medicines",
	food="Food", drink="Drinks", drinks="Drinks", tissue="Tissues", tissues="Tissues",
	additive="Additives", additives="Additives", dna="DNA Samples", dnasamples="DNA Samples",
	petdeeds="Pet Deeds", modules="Modules", crystals="Crystals", weapons="Weapons",
	armor="Armor", clothing="Clothing", tools="Tools", furniture="Furniture", deeds="Deeds",
}
local function readable(value, aliases)
	if type(value) ~= "string" or value == "" or value:find("[%c]") then return nil end
	local key = value:lower():gsub("[^%w]", "")
	if aliases[key] then return aliases[key] end
	return (value:gsub("[_%-]+", " "):gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end
local TAILOR = {
	{ "Cargo Pocket", "cargo_pocket" }, { "Fiberplast Panel", "fiberplast_panel" },
	{ "Jewelry Setting", "jewelry_setting" }, { "Metal Fasteners", "metal_fasteners" },
	{ "Padding Segment", "padding_segment" }, { "Reinforced Fiber Panels", "reinforced_fiber_panels" },
	{ "Shoe Sole", "shoe_sole" }, { "Synthetic Cloth", "synthetic_cloth" }, { "Trim", "trim" },
}
local t = ObjectTemplates[crcString(path)]
local items = t and findSub(t.itemList, "Items")
if not items then print("pre9_factory_crates: missing Items menu"); return end
local crates = ensureSub(items, "Factory Crates")
clearGenerated(crates)
local tailor = ensureSub(crates, "Tailor")
for _, entry in ipairs(TAILOR) do
	local original = "crate:" .. entry[1] .. ":object/tangible/component/clothing/" .. entry[2] .. ".iff"
	legacyLeaf(tailor, entry[1] .. " (crate of 1000)", original, original)
end
local catalog = PerfectFactoryCatalog
local valid = type(catalog) == "table" and catalog.schemaVersion == 1
	and catalog.qualityRevision == "normal100-v1" and type(catalog.sourceFingerprint) == "string"
	and type(catalog.entries) == "table" and type(catalog.exceptions) == "table"
if not valid then
	print("pre9_factory_crates: catalog missing or unsupported; legacy choices retained")
	ObjectTemplates:addTemplate(t, path); return
end
local ids, duplicate = {}, {}
for _, entry in ipairs(catalog.entries) do
	if type(entry) == "table" and type(entry.id) == "string" then
		if ids[entry.id] then duplicate[entry.id] = true end
		ids[entry.id] = true
	end
end
local groups = {}
local added = 0
for _, entry in ipairs(catalog.entries) do
	local category = type(entry) == "table" and readable(entry.category, categoryAliases)
	if type(entry) == "table" and type(entry.id) == "string" and entry.id:match("^[ri]_%x+$")
		and not duplicate[entry.id] and type(entry.label) == "string" and entry.label ~= ""
		and not entry.label:find("[%c]") and type(entry.professions) == "table" and #entry.professions > 0
		and category and (entry.availability == "pending" or entry.availability == "verified" or entry.availability == "rejected") then
		local aliases = {}
		for _, alias in ipairs(entry.professions) do
			local key = type(alias) == "string" and alias:lower():gsub("[^%w]", "") or ""
			local expanded = professionGroups[key] or { readable(alias, professionAliases) }
			for _, profession in ipairs(expanded) do
				if profession and not aliases[profession] then
					aliases[profession] = true
					groups[profession] = groups[profession] or {}
					groups[profession][category] = groups[profession][category] or {}
					table.insert(groups[profession][category], entry)
					added = added + 1
				end
			end
		end
	end
end
for profession, categories in pairs(groups) do
	local professionMenu = ensureSub(crates, profession)
	for category, entries in pairs(categories) do
		local menu = ensureSub(professionMenu, category)
		table.sort(entries, function(a,b) if a.label:lower() == b.label:lower() then return a.id < b.id end; return a.label:lower() < b.label:lower() end)
		local names, used = {}, {}
		local existingLeaves = 0
		for i = 1, #menu - 1, 2 do
			used[menu[i]] = true
			if type(menu[i + 1]) == "string" then existingLeaves = existingLeaves + 1 end
		end
		for _, entry in ipairs(entries) do names[entry.label] = (names[entry.label] or 0) + 1 end
		local labels = {}
		for _, entry in ipairs(entries) do
			local label = entry.label
			if names[label] > 1 then
				local variant = readable(entry.variantId, {}) or entry.id
				label = label .. " (" .. variant .. ")"
			end
			-- Include a stable id only when normal variant labels still collide.
			if used[label] then label = label .. " [" .. entry.id:sub(1, 10) .. "]" end
			while used[label] do label = label .. " (catalog)" end
			used[label] = true; labels[#labels + 1] = label
		end
		for first = 1, #entries, PAGE_SIZE do
			local last = math.min(first + PAGE_SIZE - 1, #entries)
			local page = menu
			if #entries + existingLeaves > PAGE_SIZE then
				local pageLabel = string.format("%03d-%03d: %s - %s", first, last, labels[first], labels[last])
				local collision = true
				while collision do
					collision = false
					for i = 1, #menu - 1, 2 do
						if menu[i] == pageLabel then pageLabel = pageLabel .. " (catalog)"; collision = true; break end
					end
				end
				page = {}; menu[#menu + 1] = pageLabel; menu[#menu + 1] = page
			end
			for i = first, last do setLeaf(page, labels[i], PREFIX .. entries[i].id) end
		end
	end
end
ObjectTemplates:addTemplate(t, path)
print("pre9_factory_crates: catalog aliases added: " .. added)
