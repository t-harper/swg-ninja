-- pre9_mandalorian.lua — Mandalorian multi-master path (r23): trainer
-- skill list + trainer/stone spawns.
--
-- Loaded LAST via custom_scripts/screenplays/screenplays.lua so the
-- trainerSkills.trainer_mandalorian assignment lands in the stock
-- trainerData table (read per conversation — late binding — and this
-- whole chain re-runs on `reloadscreenplays`).
--
-- The clan-rank ladder (mandalorian_rank_*) is deliberately NOT
-- trainable here: those hidden GOD_ONLY boxes are granted exclusively
-- by screenplays/mando_rank/ (lua FRS-analogue).

local BRANCHES = { "rifle", "carbine", "pistol", "code" }
local TIERS = {
	"mandalorian_foundling",
	"mandalorian_warrior",
	"mandalorian_protector",
}

local function mandoChain(prefix)
	local t = { prefix .. "_novice" }
	for _, b in ipairs(BRANCHES) do
		for i = 1, 4 do
			t[#t + 1] = string.format("%s_%s_%02d", prefix, b, i)
		end
	end
	t[#t + 1] = prefix .. "_master"
	return t
end

local list = {}
for _, prefix in ipairs(TIERS) do
	local chain = mandoChain(prefix)
	for i = 1, #chain do
		list[#list + 1] = chain[i]
	end
end

trainerSkills.trainer_mandalorian = list
print("pre9_mandalorian: trainer_mandalorian teaches " .. #list .. " boxes (3 tiers)")

PreNineMandalorianScreenPlay = ScreenPlay:new {
	numberOfActs = 1
}

registerScreenPlay("PreNineMandalorianScreenPlay", true)

function PreNineMandalorianScreenPlay:start()
	if isZoneEnabled("tatooine") then
		self:spawnMobiles()
	end
end

function PreNineMandalorianScreenPlay:spawnMobiles()
	-- Mos Eisley, on the street strip east of the pre9 jedi trainer
	-- (Vokara, 3508 -4806). NOT further south/east: the 64x16 filler
	-- building block centered at (3510, -4822) swallowed the original
	-- (3540, -4815) spawn (world-snapshot verified via the map data).
	spawnMobile("tatooine", "pre9_trainer_mandalorian", 1, 3528, 5, -4802, 220, 0)

	-- the Oyu'baat stone (clan-rank terminal) beside the trainer
	local pStone = spawnSceneObject("tatooine",
		"object/tangible/terminal/pre9_mando_stone.iff",
		3532, 5, -4800, 0, math.rad(220))

	if (pStone ~= nil) then
		SceneObject(pStone):setCustomObjectName("Oyu'baat Stone")
	end
end
