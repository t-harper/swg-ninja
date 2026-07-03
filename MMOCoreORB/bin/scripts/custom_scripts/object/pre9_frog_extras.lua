-- pre9_frog_extras.lua — misc character-builder additions:
--   1. Jetpack deed in Items > Deeds > Vehicle Deeds (stock ships it
--      commented out; the deed/PCD/vehicle templates are all registered
--      and need no certification).
--   2. "Clothing Attachment Builder" token (sea_builder — local C++
--      SUI: pick up to 6 skill mods, +25 each, mints a clothing SEA).
--
-- Same mutate-in-place + re-register pattern as the other injectors.

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
local vehicleDeeds = items and findSub(findSub(items, "Deeds"), "Vehicle Deeds")

if items == nil or vehicleDeeds == nil then
	print("pre9_frog_extras: FAILED to locate Items / Vehicle Deeds in the character builder menu (stock layout changed?)")
else
	vehicleDeeds[#vehicleDeeds + 1] = "Jetpack"
	vehicleDeeds[#vehicleDeeds + 1] = "object/tangible/deed/vehicle_deed/jetpack_deed.iff"

	items[#items + 1] = "Clothing Attachment Builder"
	items[#items + 1] = "sea_builder"

	ObjectTemplates:addTemplate(t, path)
	print("pre9_frog_extras: added Jetpack deed and Clothing Attachment Builder to the character builder menu")
end
