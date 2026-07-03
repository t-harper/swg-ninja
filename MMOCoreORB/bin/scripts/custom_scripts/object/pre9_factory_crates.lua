-- pre9_factory_crates.lua — "Factory Crates" section on the character
-- builder. Each entry uses the local "crate:<server template path>"
-- token (SuiManager C++ patch) to mint a full 1000-count factory crate.
--
-- Tailor subsection: all 9 statless tailor components (every schematic
-- under draft_schematic/clothing/component/ has no experimental
-- properties, so frog-minted crates lose nothing vs crafted ones).
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

local TAILOR = {
	{ "Cargo Pocket", "cargo_pocket" },
	{ "Fiberplast Panel", "fiberplast_panel" },
	{ "Jewelry Setting", "jewelry_setting" },
	{ "Metal Fasteners", "metal_fasteners" },
	{ "Padding Segment", "padding_segment" },
	{ "Reinforced Fiber Panels", "reinforced_fiber_panels" },
	{ "Shoe Sole", "shoe_sole" },
	{ "Synthetic Cloth", "synthetic_cloth" },
	{ "Trim", "trim" },
}

local t = ObjectTemplates[crcString(path)]
local items = t and findSub(t.itemList, "Items")

if items == nil then
	print("pre9_factory_crates: FAILED to locate Items in the character builder menu (stock layout changed?)")
else
	local tailorMenu = {}
	for _, e in ipairs(TAILOR) do
		tailorMenu[#tailorMenu + 1] = e[1] .. " (crate of 1000)"
		-- token: crate:<label>:<path> — label becomes the prototype/crate name
		tailorMenu[#tailorMenu + 1] = "crate:" .. e[1] .. ":object/tangible/component/clothing/" .. e[2] .. ".iff"
	end

	items[#items + 1] = "Factory Crates"
	items[#items + 1] = {
		"Tailor", tailorMenu,
	}

	ObjectTemplates:addTemplate(t, path)
	print("pre9_factory_crates: added " .. #TAILOR .. " tailor component crates to the character builder menu")
end
