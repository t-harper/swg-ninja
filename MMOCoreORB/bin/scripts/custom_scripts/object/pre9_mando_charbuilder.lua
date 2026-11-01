-- pre9_mando_charbuilder.lua — add the Mandalorian multi-master path
-- (r23) to the character builder (blue frog), shaped like the jedi
-- (Pre-9) submenu: per tier — Novice, one submenu per branch with boxes
-- I-IV granted individually, Master.
--
-- Menu entries whose value is a skill name fall through SuiManager's
-- selection handler to awardSkill(name, player, notify=true,
-- awardRequiredSkills=true, noXpRequired=true), so picking e.g.
-- "Rifle Discipline III" grants the whole chain below it (including
-- the Foundling novice's 250 skill points). Jedi/Mando exclusivity is
-- enforced server-side: PRECLUSION_SKILLS on mandalorian_foundling_novice
-- blocks jedi initiates, and the 250-point cost blocks the reverse.
--
-- The clan-rank ladder is NOT offered here (lua-granted only).
--
-- MUST be included BEFORE pre9_zz_menu_sort.lua (which sorts the menus
-- this file builds).

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
	{ key = "rifle", label = "Rifles" },
	{ key = "carbine", label = "Carbines" },
	{ key = "pistol", label = "Sidearms" },
	{ key = "code", label = "The Code" },
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
	print("pre9_mando_charbuilder: FAILED to locate Character Options > Learn Skill (stock menu layout changed?)")
else
	learnSkill[#learnSkill + 1] = "Mandalorian (Pre-9)"
	learnSkill[#learnSkill + 1] = {
		"Foundling", treeMenu("mandalorian_foundling", "Novice (250 pts, fresh character)"),
		"Warrior", treeMenu("mandalorian_warrior"),
		"Protector", treeMenu("mandalorian_protector"),
	}
	ObjectTemplates:addTemplate(t, path)
	print("pre9_mando_charbuilder: added Mandalorian (Pre-9) grants (branch-granular) to the character builder menu")
end
