-- pre9_zz_menu_sort.lua — FINAL menu pass: alphabetically sort every
-- submenu of the character builder, at every depth. MUST be included
-- LAST among the frog injectors (it sorts whatever the others built).
-- The itemList is alternating {label, value} pairs; values are tokens/
-- paths (string) or subtables (submenus, recursed before sorting).

local path = "object/tangible/terminal/terminal_character_builder.iff"

local function sortMenu(list, depth)
	if type(list) ~= "table" then
		return 0
	end

	local pairsList = {}
	for i = 1, #list - 1, 2 do
		local value = list[i + 1]
		if type(value) == "table" then
			sortMenu(value, depth + 1)
		end
		pairsList[#pairsList + 1] = { label = list[i], value = value }
	end

	table.sort(pairsList, function(a, b)
		return string.lower(tostring(a.label)) < string.lower(tostring(b.label))
	end)

	for i = 1, #list do
		list[i] = nil
	end
	for i = 1, #pairsList do
		list[2 * i - 1] = pairsList[i].label
		list[2 * i] = pairsList[i].value
	end

	return #pairsList
end

local t = ObjectTemplates[crcString(path)]

if t == nil or type(t.itemList) ~= "table" then
	print("pre9_zz_menu_sort: FAILED to load the character builder menu")
else
	local top = sortMenu(t.itemList, 0)
	ObjectTemplates:addTemplate(t, path)
	print("pre9_zz_menu_sort: sorted all character builder menus (" .. top .. " top-level sections)")
end
