-- pre9_charbuilder.lua — add pre-publish-9 Jedi grants to the character
-- builder (blue frog) terminal, shaped like the stock profession menus:
-- per tree — Novice, one submenu per branch with boxes I-IV granted
-- individually, Master.
--
-- Menu entries whose value is a skill name fall through SuiManager's
-- selection handler to awardSkill(name, player, notify=true,
-- awardRequiredSkills=true, noXpRequired=true), so picking e.g.
-- "Lightsaber III" grants I and II (and the tree's novice — including
-- the padawan novice's 250 skill points) automatically. Light/dark
-- exclusivity is enforced server-side by the PRECLUSION_SKILLS check in
-- SkillManager::fulfillsSkillPrerequisites.
--
-- Same mutate-in-place + re-register pattern as pre9_sabers.lua.

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

local BRANCHES = {
	{ key = "saber", label = "Lightsaber" },
	{ key = "healing", label = "Healing" },
	{ key = "force_power", label = "Force Powers" },
	{ key = "force_manipulation", label = "Force Manipulation" },
}

local ROMAN = { "I", "II", "III", "IV" }

local function treeMenu(prefix, noviceLabel)
	local menu = {}
	menu[#menu + 1] = noviceLabel or "Novice"
	menu[#menu + 1] = prefix .. "_novice"
	for _, b in ipairs(BRANCHES) do
		local sub = {}
		for i = 1, 4 do
			sub[#sub + 1] = b.label .. " " .. ROMAN[i]
			sub[#sub + 1] = string.format("%s_%s_%02d", prefix, b.key, i)
		end
		menu[#menu + 1] = b.label
		menu[#menu + 1] = sub
	end
	menu[#menu + 1] = "Master"
	menu[#menu + 1] = prefix .. "_master"
	return menu
end

local t = ObjectTemplates[crcString(path)]
local learnSkill = t and findSub(findSub(t.itemList, "Character Options"), "Learn Skill")

if learnSkill == nil then
	print("pre9_charbuilder: FAILED to locate Character Options > Learn Skill (stock menu layout changed?)")
else
	learnSkill[#learnSkill + 1] = "Jedi (Pre-9)"
	learnSkill[#learnSkill + 1] = {
		"Padawan", treeMenu("jedi_padawan", "Novice (250 pts, fresh character)"),
		"Light Side Journeyman", treeMenu("jedi_light_side_journeyman"),
		"Light Side Master", treeMenu("jedi_light_side_master"),
		"Dark Side Journeyman", treeMenu("jedi_dark_side_journeyman"),
		"Dark Side Master", treeMenu("jedi_dark_side_master"),
	}
	ObjectTemplates:addTemplate(t, path)
	print("pre9_charbuilder: added Jedi (Pre-9) grants (branch-granular) to the character builder menu")
end
