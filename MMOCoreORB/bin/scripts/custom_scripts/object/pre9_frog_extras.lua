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

	items[#items + 1] = "Armor Attachment Builder"
	items[#items + 1] = "aa_builder"

	local jediItems = findSub(items, "Jedi Items")
	if jediItems ~= nil then
		jediItems[#jediItems + 1] = "Special Crystals"
		-- canonical color names from string/en/jedi_spam.stf
		-- saber_color_N — labels must match the client color line
		jediItems[#jediItems + 1] = {
			"Maul's Vengence", "crystal_color:12:Maul's Vengence",
			"Kun's Blood", "crystal_color:13:Kun's Blood",
			"Bondara's Folly", "crystal_color:14:Bondara's Folly",
			"Ulic's Redemption", "crystal_color:15:Ulic's Redemption",
			"Bane's Heart", "crystal_color:16:Bane's Heart",
			"Gallia's Intuition", "crystal_color:17:Gallia's Intuition",
			"Prowess of Plo Koon", "crystal_color:18:Prowess of Plo Koon",
			"B'nar's Sacrifice", "crystal_color:19:B'nar's Sacrifice",
			"Windu's Guile", "crystal_color:20:Windu's Guile",
			"Mundi's Response", "crystal_color:21:Mundi's Response",
			"Strength of Luminaria", "crystal_color:22:Strength of Luminaria",
			"Baas's Wisdom", "crystal_color:23:Baas's Wisdom",
			"Quintessence of the Force", "crystal_color:24:Quintessence of the Force",
			"Dawn of Dagobah", "crystal_color:25:Dawn of Dagobah",
			"Horn's Future", "crystal_color:26:Horn's Future",
			"Qui-gon's Devotion", "crystal_color:27:Qui-gon's Devotion",
			"Kenobi's Legacy", "crystal_color:28:Kenobi's Legacy",
			"Sunrider's Destiny", "crystal_color:29:Sunrider's Destiny",
			"Kit's Ferocity", "crystal_color:30:Kit's Ferocity",
		}
	end

	local W = "object/tangible/wearables/"
	items[#items + 1] = "Socketed Clothing"
	items[#items + 1] = {
		"Pants (4 sockets)", "socketed:Pants:" .. W .. "pants/pants_s01.iff",
		"Shirt (4 sockets)", "socketed:Shirt:" .. W .. "shirt/shirt_s03.iff",
		"Gloves (4 sockets)", "socketed:Gloves:" .. W .. "gloves/gloves_s02.iff",
		"Boots (4 sockets)", "socketed:Boots:" .. W .. "boots/boots_s03.iff",
		"Hat (4 sockets)", "socketed:Hat:" .. W .. "hat/hat_chef_s01.iff",
		"Belt (4 sockets)", "socketed:Belt:" .. W .. "belt/belt_s01.iff",
	}

	local armor = findSub(items, "Armor")

	if armor == nil then
		print("pre9_frog_extras: FAILED to locate Items > Armor (stock layout changed?)")
	else
		-- Finished Mandalorian armor handout intentionally REMOVED (pre9
		-- crafting feature): the frog now hands out only the learn
		-- schematics below; a master armorsmith must craft each piece from
		-- real resources. (Craftable set = composite +10%; see
		-- custom_scripts/object/pre9_mandalorian_armor.lua.)

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

		local COMP = "object/tangible/wearables/armor/composite/armor_composite_"
		armor[#armor + 1] = "High-End Composite"
		armor[#armor + 1] = {
			"Composite Left Bicep (HE)", "hicomp:Composite Left Bicep:" .. COMP .. "bicep_l.iff",
			"Composite Right Bicep (HE)", "hicomp:Composite Right Bicep:" .. COMP .. "bicep_r.iff",
			"Composite Boots (HE)", "hicomp:Composite Boots:" .. COMP .. "boots.iff",
			"Composite Left Bracer (HE)", "hicomp:Composite Left Bracer:" .. COMP .. "bracer_l.iff",
			"Composite Right Bracer (HE)", "hicomp:Composite Right Bracer:" .. COMP .. "bracer_r.iff",
			"Composite Chest Plate (HE)", "hicomp:Composite Chest Plate:" .. COMP .. "chest_plate.iff",
			"Composite Gloves (HE)", "hicomp:Composite Gloves:" .. COMP .. "gloves.iff",
			"Composite Helmet (HE)", "hicomp:Composite Helmet:" .. COMP .. "helmet.iff",
			"Composite Leggings (HE)", "hicomp:Composite Leggings:" .. COMP .. "leggings.iff",
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
