-- pre9_jedi.lua — pre-publish-9 Jedi: trainer skill list + trainer spawn.
--
-- Loaded LAST via custom_scripts/screenplays/screenplays.lua, so the
-- trainerSkills.trainer_jedi assignment overrides the stock 14.1 list in
-- trainerData.lua (the table is read per conversation — late binding —
-- and this whole chain re-runs on `reloadscreenplays`).

PRE9_ADVANCED_TREES = true  -- P2 knob: false = padawan tier only

local BRANCHES = { "saber", "healing", "force_power", "force_manipulation" }

local function pre9Chain(prefix)
	local t = { prefix .. "_novice" }
	for _, b in ipairs(BRANCHES) do
		for i = 1, 4 do
			t[#t + 1] = string.format("%s_%s_%02d", prefix, b, i)
		end
	end
	t[#t + 1] = prefix .. "_master"
	return t
end

local list = pre9Chain("jedi_padawan")
if PRE9_ADVANCED_TREES then
	for _, prefix in ipairs({
		"jedi_light_side_journeyman", "jedi_dark_side_journeyman",
		"jedi_light_side_master", "jedi_dark_side_master" }) do
		local chain = pre9Chain(prefix)
		for i = 1, #chain do
			list[#list + 1] = chain[i]
		end
	end
end

trainerSkills.trainer_jedi = list
print("pre9_jedi: trainer_jedi teaches " .. #list .. " legacy boxes (advanced trees: " .. tostring(PRE9_ADVANCED_TREES) .. ")")

PreNineJediScreenPlay = ScreenPlay:new {
	numberOfActs = 1
}

registerScreenPlay("PreNineJediScreenPlay", true)

function PreNineJediScreenPlay:start()
	if isZoneEnabled("tatooine") then
		self:spawnMobiles()
	end
end

function PreNineJediScreenPlay:spawnMobiles()
	-- Mos Eisley, outdoors near the artisan trainer row
	spawnMobile("tatooine", "pre9_trainer_jedi", 1, 3508, 5, -4806, 220, 0)
end
