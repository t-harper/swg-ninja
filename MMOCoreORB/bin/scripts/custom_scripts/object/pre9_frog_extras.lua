-- pre9_frog_extras.lua — misc character-builder additions:
--   1. Jetpack deed in Items > Deeds > Vehicle Deeds (stock ships it
--      commented out; the deed/PCD/vehicle templates are all registered
--      and need no certification).
--   2. "Clothing Attachment Builder" token (sea_builder — local C++
--      SUI: pick up to 6 skill mods, +25 each, mints a clothing SEA).
--   3. Mandalorian + Bone armor sets under Items > Armor (stock ships
--      bone commented out; same per-piece pair shape, no wear certs in
--      this era — encumbrances apply as normal).
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

	local armor = findSub(items, "Armor")

	if armor == nil then
		print("pre9_frog_extras: FAILED to locate Items > Armor (stock layout changed?)")
	else
		local MANDO = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_"
		armor[#armor + 1] = "Mandalorian Armor"
		armor[#armor + 1] = {
			"Mandalorian Belt", MANDO .. "belt.iff",
			"Mandalorian Left Bicep", MANDO .. "bicep_l.iff",
			"Mandalorian Right Bicep", MANDO .. "bicep_r.iff",
			"Mandalorian Left Bracer", MANDO .. "bracer_l.iff",
			"Mandalorian Right Bracer", MANDO .. "bracer_r.iff",
			"Mandalorian Chest Plate", MANDO .. "chest_plate.iff",
			"Mandalorian Gloves", MANDO .. "gloves.iff",
			"Mandalorian Helmet", MANDO .. "helmet.iff",
			"Mandalorian Leggings", MANDO .. "leggings.iff",
			"Mandalorian Shoes", MANDO .. "shoes.iff",
		}

		local DWSCHEM = "object/tangible/loot/loot_schematic/death_watch_mandalorian_"
		armor[#armor + 1] = "Mandalorian Schematics"
		armor[#armor + 1] = {
			"Mandalorian Belt Schematic", DWSCHEM .. "belt_schematic.iff",
			"Mandalorian Left Bicep Schematic", DWSCHEM .. "bicep_l_schematic.iff",
			"Mandalorian Right Bicep Schematic", DWSCHEM .. "bicep_r_schematic.iff",
			"Mandalorian Boots Schematic", DWSCHEM .. "boots_schematic.iff",
			"Mandalorian Left Bracer Schematic", DWSCHEM .. "bracer_l_schematic.iff",
			"Mandalorian Right Bracer Schematic", DWSCHEM .. "bracer_r_schematic.iff",
			"Mandalorian Chest Plate Schematic", DWSCHEM .. "chest_plate_schematic.iff",
			"Mandalorian Gloves Schematic", DWSCHEM .. "gloves_schematic.iff",
			"Mandalorian Helmet Schematic", DWSCHEM .. "helmet_schematic.iff",
			"Mandalorian Leggings Schematic", DWSCHEM .. "leggings_schematic.iff",
			"Mandalorian Jetpack Schematic", DWSCHEM .. "jetpack_schematic.iff",
		}

		local BONE = "object/tangible/wearables/armor/bone/armor_bone_s01_"
		armor[#armor + 1] = "Bone Armor"
		armor[#armor + 1] = {
			"Bone Left Bicep", BONE .. "bicep_l.iff",
			"Bone Right Bicep", BONE .. "bicep_r.iff",
			"Bone Boots", BONE .. "boots.iff",
			"Bone Left Bracer", BONE .. "bracer_l.iff",
			"Bone Right Bracer", BONE .. "bracer_r.iff",
			"Bone Chest Plate", BONE .. "chest_plate.iff",
			"Bone Gloves", BONE .. "gloves.iff",
			"Bone Helmet", BONE .. "helmet.iff",
			"Bone Leggings", BONE .. "leggings.iff",
		}
	end

	ObjectTemplates:addTemplate(t, path)
	print("pre9_frog_extras: added Jetpack deed, Clothing Attachment Builder, Mandalorian + Bone armor to the character builder menu")
end
