-- pre9_perfect_resources.lua — add the "Perfect Resources" chooser to the
-- character builder (blue frog) terminal, next to the Resource Deed.
--
-- The token "perfect_resource" is handled in SuiManager (local C++ patch):
-- it opens a resource-class chooser; picking a leaf mints/reuses a
-- never-harvestable singleton spawn with every applicable stat at 1000
-- and grants a full 100,000-unit container. A "perfect_resource:<qty>"
-- token variant selects a smaller quantity.
--
-- Same mutate-in-place + re-register pattern as pre9_charbuilder.lua.

local path = "object/tangible/terminal/terminal_character_builder.iff"

local function findSub(list, name)
	if type(list) ~= "table" then
		return nil
	end
	for i = 1, #list - 1, 2 do
		if list[i] == name and type(list[i + 1]) == "table" then
			return list[i + 1]
		end
	end
	return nil
end

local t = ObjectTemplates[crcString(path)]
local items = t and findSub(t.itemList, "Items")

if items == nil then
	print("pre9_perfect_resources: FAILED to locate Items in the character builder menu (stock layout changed?)")
else
	-- Top-level Items entry (moved out of Deeds 2026-07-04 by request).
	table.insert(items, 1, "perfect_resource")
	table.insert(items, 1, "Perfect Resources")
	ObjectTemplates:addTemplate(t, path)
	print("pre9_perfect_resources: added Perfect Resources to the character builder menu")
end
