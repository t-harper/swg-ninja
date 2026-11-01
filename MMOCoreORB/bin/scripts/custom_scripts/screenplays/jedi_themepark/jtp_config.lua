-- jtp_config.lua — "Echoes of the Purge" Jedi themepark: ALL tunables,
-- site constants, the corrected force-shrine census, and the state-bit
-- ledger. Design doc: ~/.claude/plans/let-s-plan-out-the-radiant-shore.md
--
-- ============================= BIT LEDGER (LAW) ==============================
-- Screenplay state names "JediParkAct0".."JediParkAct6":
--   quest n (1-based): started = 2^(2n-2), done = 2^(2n-1). Bits monotonic.
-- Screenplay state name "JediPark" (global):
--   1 park begun | 2 act0 done | 4 act1 done | 8 act2 done
--   16 side-intent LIGHT | 32 side-intent DARK
--   64 act3 done | 128 act4 done | 256 act5 done | 512 act6 done
--   1024 pilgrim-46 | 2048 schematic V granted | 4096 schematic VI granted
--   8192 finale L | 16384 finale D | >=32768 reserved
-- ScreenPlayData namespace "JediPark": shrines_<planet> (visit bitmask),
--   act_entry_rank, repeat_<name>_ts, vis_debt, side_cache — strings, tonumber().
-- =============================================================================

JtpConfig = {
	enabled = true,

	-- Galaxy gate: the park loads ONLY where the galaxy name matches.
	-- Fun cutover = add ["SWG Ninja Fun"] = true on operator approval.
	enabledGalaxies = {
		["SWG Ninja Dev"] = true,
	},

	debug = true, -- boot/flow print()s to server log

	-- ---- Act 0 tuning -------------------------------------------------------
	act0 = {
		xpPerQuest = 2500,          -- jedi_general, per plan §6
		creditsPerQuest = 500,
		killCount = 6,              -- Q0.4 wolves
		nyaxKillCount = 8,          -- Q0.S1 side quest
		wolfCamp = { planet = "dathomir", x = 5060, z = 78.5, y = -3950 },
		cache = { planet = "dathomir", x = 5322, z = 78.5, y = -4157 }, -- Q0.2 prop, by the communal hut
		nyax = { planet = "corellia", x = -2523, y = 2927, radius = 192, maxLevel = 45 },
		hutArea = { planet = "tatooine", x = -4489, z = 34.7, y = -2262, radius = 40 },
	},

	-- The Wanderer's fixed post outside Aurilia (walk-up encounter is a
	-- Phase-B polish; Phase A uses a login nudge + fixed giver).
	wanderer = { planet = "dathomir", x = 5340, z = 78.5, y = -4185, heading = -45 },

	visibility = {
		quietStep = -25,   -- shrine visit
		loudStep = 50,     -- flagged combat steps (Q0.4)
	},

	-- ---- Force-shrine census ------------------------------------------------
	-- Object IDs verified against the live snapshots (ws_parse sweep,
	-- 2026-08-01). x/y are reference coords; runtime uses the object's own
	-- world position. jedi_trials.lua stock table fixed separately
	-- (naboo 7525400->7525440, talus 6535891->7835391).
	shrines = {
		corellia = { 7345533, 7345540, 7345554, 7345561, 7345568 },
		dantooine = { 6045480, 6045494, 6045501, 6045508, 6045522 },
		dathomir = { 7325403, 7325410, 7325417, 7325424, 7325438 },
		endor = { 7255422, 7255429, 7255436, 7255443, 7255457 },
		lok = { 6625591, 6625598, 6625605, 6625619, 6625626 },
		naboo = { 7525395, 7525440, 7525447, 7525454 },
		rori = { 6885431, 6885438, 6885445, 6885452, 6885459 },
		talus = { 6535834, 6535841, 6535869, 7835391 },
		tatooine = { 5996497, 5996504, 5996539, 5996546, 5996560 },
		yavin4 = { 6845418, 6845425, 7665623, 7665630 },
	},
	shrineAreaRadius = 32,

	-- Item templates used by Act 0 (all verified stock server templates).
	items = {
		ledger = "object/tangible/mission/mission_datadisk.iff",
		cacheProp = "object/tangible/jedi/power_shrine.iff",
	},
	lootGroups = {
		colorCrystal = "color_crystals",
	},
}

-- Ordered planet list (stable iteration for census + progress readouts).
JtpConfig.shrinePlanets = { "corellia", "dantooine", "dathomir", "endor",
	"lok", "naboo", "rori", "talus", "tatooine", "yavin4" }

function JtpConfig.shrineTotal()
	local n = 0
	for i = 1, #JtpConfig.shrinePlanets, 1 do
		n = n + #JtpConfig.shrines[JtpConfig.shrinePlanets[i]]
	end
	return n
end
