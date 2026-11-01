-- jtp_act4.lua — Act IV: "The Silent Council" (L) / "The Inquisitor's Gambit" (D).
-- First fully mirrored act: ONE state machine, side-flavored via FLAVOR
-- tables (plan EPIC E4). Quests (bit ledger: started 2^(2n-2) / done
-- 2^(2n-1) in state "JediParkAct4"):
--   1 L "The Quiet Promotion"    / D "An Audience of One"     [talk]
--   2 L "The Chained Choir"      / D "The Harvest of Echoes"  [kill — Jinda cave]
--   3   "The Fifteen" (shared)                                [pilgrimage III + watchers]
--   4 L "A Pearl for the Broken" / D "A Pearl for the Rising" [collect — Krayt Graveyard]
--   5 L "Seal the Echo"          / D "Commune With the Echo"  [theater — Exar Kun r15]
--   6 L "The Well Watch"         / D "The Courier Road"       [defend/ambush]
--   7 L BOSS "The Inquisitor's Face" / D BOSS "The Elder's Knee"
--   8 L "Letters Northward"      / D "Bait of Paper"          [side]
--   9 L "Warn the Mountain"      / D "The Sealed Testament"   [side]
--
-- Act gate: matching jedi_<side>_side_master_novice + Act III done (JediPark
-- global bit 64) + FRS rank >= 2 at entry. GRACE FLOOR (plan 7.4 — the
-- contract Acts V/VI copy): first acceptance writes act4_entry_rank; every
-- later gate check requires frsRankOf >= max(2, entryRank - 1). A player
-- demoted below the floor gets the pause SUI and every quest HOLDS — no
-- state loss, no wipe.
-- Completion: JediPark bit 128 + badge 143 placeholder sysmsg + robe s03 +
-- side ceremony token + color-crystal roll. FRS XP 4000/quest, 10000 boss;
-- credits 2000/quest (no jedi_general XP in Acts III+ per plan section 6).
--
-- Light giver: Serenna Vale (Act II's warroom NPC — the MAIN LOOP routes her
-- convo handler to JediParkAct4:onSerennaTalk at integration; this file never
-- touches act2). Dark giver: The Hand's Voice (custom_scripts/mobile/
-- jtp_voice.lua) in dark enclave council1, cell 3435650 (claimed below via
-- JtpCells — the pre-verified seed; NEVER any other enclave cell).
--
-- Site notes:
--  * Exar Kun temple: deep cell r15 = 3465394 ONLY; zero permission changes,
--    all spawns per-player and torn down. Stock ThemeParkRebel permission-maps
--    3465380-94 (themeParkRebel.lua permissionMapRebel) — see the boot audit
--    log line; do not fight it, only observe.
--  * Jinda Ritualist Cave (endor -1713 53): cell IDs beyond the first are
--    UNVERIFIED; boot-checked, with a world-spawn fallback at the entrance.
--  * Dark enclave council1 spawn z copies the stock terminal-injection floor
--    (object/building/yavin/dark_enclave.lua: z = -43.42). WALK-TEST the
--    Voice's spot on first boot; coords are config tunables.
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- ScreenPlayData namespace "JediPark", keys prefixed act4_:
--   act4_entry_rank            grace-floor anchor (written once; ""/nil = unset)
--   act4_menukeys/_menu_giver  giver menu bookkeeping
--   act4_jinda_kills, act4_jinda_obj_1..3
--   act4_pearl                 krayt route A credit, pending turn-in
--   act4_kun_stage/_token/_left, act4_kun_done, act4_kun_sealed (L), act4_kun_communed (D)
--   act4_well_state            0 idle / 2 waves held (L)
--   act4_courier_oid/_left/_ready, act4_courier_done (D)
--   act4_boss_oid/_engaged, act4_boss_dead, act4_vheress_dead (L kill flag — Act V-D reads)
--   act4_letters_1..3, act4_s1_item, act4_s1_holo_due
--   act4_veshaan_warned (L — Act VI-L reads), act4_testa_left, act4_testament (D — Act V-D reads)

-- ---- tuning (jtp_config owns nothing act4-specific yet; claim the slot) ------

JtpConfig.act4 = JtpConfig.act4 or {
	frsPerQuest = 4000,
	frsBoss = 10000,
	frsPearlTurnIn = 2000,      -- route B (offered pearl, Phase A simplification)
	creditsPerQuest = 2000,
	visWarn = -100,             -- Q4.S2L quiet step

	-- Act gate.
	gateRank = 2,
	gateSkillLight = "jedi_light_side_master_novice",
	gateSkillDark = "jedi_dark_side_master_novice",
	prevActBit = 64,            -- JediPark global: Act III done

	-- Dark giver post: dark enclave council1 (yavin4 building at 5070 310).
	-- z copies the stock enclave interior floor (terminal injection -43.42);
	-- x/y are building-frame guesses — WALK-TEST and tune here.
	voice = { planet = "yavin4", cell = 3435650, x = 0, z = -43.42, y = 0, heading = 0 },

	-- Q4.2 — Jinda Ritualist Cave (endor). Cells beyond 6015489 UNVERIFIED:
	-- boot check falls back to world spawns around the entrance when any of
	-- the three chosen objective cells fails getSceneObject.
	jinda = {
		planet = "endor", x = -1713, y = 53,
		kills = 12, killRadius = 192,
		cells = { 6015495, 6015505, 6015515 },
		areaRadius = 128,       -- world circle for the cell-filtered areas
		entranceRadius = 64,    -- fallback world trigger
		fallbackOffsets = { { 18, 12 }, { -16, 20 }, { 4, -22 } },
		captiveTemplate = "commoner",
		urnProp = "object/tangible/jedi/power_shrine_red.iff",
	},

	-- Q4.3 — pilgrimage III.
	pilgrimage = { count = 15, planets = 6, watcherChance = 4, watcherRange = 40, watcherLifeSec = 45 },
	watcherLight = "lesser_prophet_of_the_dark_side",   -- stalks LIGHT players (CL85)
	watcherDark = "lesser_prophet_of_the_light_side",   -- stalks DARK players (CL85)

	-- Q4.4 — Krayt Graveyard. canyon_krayt_dragon is the mid canyon krayt
	-- (juvenile 122 / canyon 275 / giant 300).
	graveyard = { planet = "tatooine", x = 7451, y = 4510, radius = 64,
		krayt = "canyon_krayt_dragon", lifeSec = 1800 },

	-- Q4.5 — Exar Kun temple, deep cell r15 ONLY.
	kun = {
		planet = "yavin4", x = 5057, y = 5538, cell = 3465394, areaRadius = 128,
		-- kun-echo guards; the named remnant rides the archaist chassis
		-- (dark_jedi_sentinel is a level-1 stock stub — see report).
		remnantTemplate = "force_trained_archaist",
		remnantName = "an echo remnant",
		echoTemplate = "dark_jedi_master",
		echoName = "the Echo of Exar Kun",
		batchDelayMs = 8000, sealStepMs = 6000,
	},

	-- Q4.6L — wave defense at the Rori shrine 01 site (object 6885431; census
	-- reference 307 -982 — true coords read from the live object at boot).
	well = {
		planet = "rori", shrineID = 6885431, x = 307, y = -982, radius = 40,
		abortSec = 600,
		waves = {
			{ mobs = { { "lesser_prophet_of_the_dark_side", 2 } } },                                              -- CL85 x2
			{ mobs = { { "lesser_prophet_of_the_dark_side", 2 }, { "senior_prophet_of_the_dark_side", 1 } } },    -- +CL138
			{ mobs = { { "senior_prophet_of_the_dark_side", 2 } } },                                              -- CL138 x2
		},
	},

	-- Q4.6D — courier ambush on the Naboo shrine road (shrine at 2378 -477).
	courier = {
		planet = "naboo", x = 2340, y = -440, radius = 40, lifeSec = 900,
		courierTemplate = "commoner", courierName = "a Circle courier",
		guardName = "a Circle zealot",
		guards = {   -- rebel-tier 60-90 (see report): {template, dx, dy}
			{ "fbase_rebel_guardsman_hard", -4, 3 },
			{ "fbase_rebel_guardsman_hard", 4, 3 },
			{ "fbase_rebel_rifleman_hard", -6, -4 },
			{ "fbase_rebel_squad_leader_hard", 6, -4 },
		},
	},

	-- Q4.7L — Inquisitor Vheress (stock emperors_hand chassis, CL252 —
	-- plan wanted ~220 tuned; accepted deviation, see report) + dark_adept
	-- (CL140) adds. Sited in the Jinda depths (objective cell 3, or the
	-- world fallback site near the cave entrance).
	bossLight = {
		template = "emperors_hand", name = "Inquisitor Vheress",
		adds = { { "dark_adept", -4, -3 }, { "dark_adept", 4, -3 } },
		fallback = { x = -1725, y = 40 },
		lifeSec = 1800,
	},

	-- Q4.7D — the defiant Nightsister elder, stronghold-EXTERIOR theater
	-- (~90m from the -4086 -136 approach; the stronghold itself untouched).
	bossDark = {
		planet = "dathomir", x = -4150, y = -200, radius = 48,
		template = "nightsister_elder", name = "the Unkneeling Elder",
		adds = { { "spiderclan_protector", -5, 4 }, { "spiderclan_protector", 5, 4 } },
		lifeSec = 1800,
	},

	-- Q4.S1 — letter shrines (positions read from the live objects at boot).
	letters = {
		{ planet = "dathomir", id = 7325403 },
		{ planet = "endor", id = 7255422 },
		{ planet = "naboo", id = 7525440 },
	},
	letterRadius = 32,
	s1AmbushGuards = 2,          -- D self-ambush at the third delivery

	-- Q4.S2L — Singing Mountain approach (spawn NOTHING there).
	mountain = { planet = "dathomir", x = 164, y = 4489, radius = 40 },

	-- Q4.S2D — courier-cache theater, further down the Naboo shrine road.
	cache = {
		planet = "naboo", x = 2260, y = -560, radius = 40, lifeSec = 900,
		prop = "object/tangible/jedi/power_shrine_red.iff",
		guardName = "a Circle zealot",
		guards = {
			{ "fbase_rebel_guardsman_hard", -4, 3 },
			{ "fbase_rebel_rifleman_hard", 4, 3 },
			{ "fbase_rebel_squad_leader_hard", 0, -5 },
		},
	},

	items = {
		token = "object/tangible/mission/mission_datadisk.iff",
		tokenLightName = "Kenobi's Legacy — Ember Token",
		tokenDarkName = "Ulic's Redemption — Shadow Token",
		robeLight = "object/tangible/wearables/robe/robe_jedi_light_s03.iff",
		robeDark = "object/tangible/wearables/robe/robe_jedi_dark_s03.iff",
		holocronLight = "object/tangible/jedi/jedi_holocron_light.iff",
		holocronDark = "object/tangible/jedi/jedi_holocron_dark.iff",
		letter = "object/tangible/mission/mission_datadisk.iff",
		letterLightName = "Ondel's Letters — Three, Sealed",
		letterDarkName = "Three Forged Letters",
		testament = "object/tangible/jedi/no_drop_jedi_holocron_light.iff",
		testamentName = "The Sealed Testament",
	},
	lootGroups = {
		colorCrystal = "color_crystals",
		powerCrystal = "power_crystals",
		pearls = "krayt_pearls",
	},
}

-- ---- cell claim (file scope, per the JtpCells wiring contract) ---------------
-- INTEGRATION DECISION (main loop): council1 (3435650) is deliberately
-- NOT claimed. It is a live FRS rank-1 cell (frs_manager.lua
-- enclaveRoomRequirements) — the enclave's own DarkEnclaveRank1 group
-- already admits every act4-eligible dark Jedi (act gate = rank >= 2),
-- and a jtp gate-claim on the shared "jtp_denclave_knight" group would
-- loosen the stock FRS door to rank-0 knights. The Hand's Voice simply
-- stands in the FRS-gated room.
--
-- Exar Kun temple route (r1–r15 = 3465380–3465394): the stock Rebel
-- themepark deny-gates ALL fifteen cells (themeParkRebel.lua
-- permissionMapRebel groups, missionState + rebel faction), so Q4.5
-- needs an ADDITIVE allow group for act4-tier knights of either
-- council. Allow mode composes with the rebel park's groups — rebels
-- keep their own access, nothing is cleared. The group is granted by
-- JtpCells:heal (login self-heal); if the temple door refuses right
-- after reaching rank 2, relog once.

if (JtpCells ~= nil) then
	for kunCell = 3465380, 3465394, 1 do
		JtpCells:register({
			cellID = kunCell, group = "jtp_kun_route", mode = "allow",
			conditions = {
				{ permissionType = "isKnight" },
				{ permissionType = "frsRank", minRank = 2 },
			},
		})
	end
end

JediParkAct4 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 4,
}

registerScreenPlay("JediParkAct4", true)

JTP_ACT4_SPAWNED = JTP_ACT4_SPAWNED or nil
JTP_ACT4_JINDA_FALLBACK = JTP_ACT4_JINDA_FALLBACK or nil
JTP_ACT4_WELL = JTP_ACT4_WELL or nil

function JediParkAct4:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT4_SPAWNED ~= nil) then
		print("jtp: act4 already spawned (reload) — skipping spawns")
		print("jtp: act4 'The Silent Council / The Inquisitor's Gambit' loaded")
		return
	end

	JTP_ACT4_SPAWNED = {}

	local C = JtpConfig.act4

	-- The Hand's Voice + the Kun deep-cell trigger (yavin4).
	if (isZoneEnabled("yavin4")) then
		local v = C.voice
		local pVoice = spawnMobile(v.planet, "jtp_voice", 0, v.x, v.z, v.y, v.heading, v.cell)

		if (pVoice ~= nil) then
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pVoice):getObjectID())
			print("jtp: act4 the Hand's Voice posted in dark enclave council1 (WALK-TEST the spot)")
		else
			print("jtp: WARNING — act4 Voice spawn failed (is mobile/jtp_voice.lua included in serverobjects.lua?)")
		end

		local k = C.kun
		local pKun = spawnActiveArea(k.planet, "object/active_area.iff", k.x, 0, k.y, k.areaRadius, k.cell)

		if (pKun ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterKunDeep", pKun)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pKun):getObjectID())
		end

		-- Audit note only — we never touch these permissions (plan AC).
		print("jtp: act4 Kun deep cell in use: 3465394 (r15) — stock ThemeParkRebel permission-maps 3465380-94; act4 makes ZERO permission changes there")
	end

	-- Jinda Ritualist Cave triggers (endor) — boot-checked cells + fallback.
	if (isZoneEnabled(C.jinda.planet)) then
		self:setupJinda()
	end

	-- Krayt Graveyard trigger (tatooine).
	if (isZoneEnabled(C.graveyard.planet)) then
		local g = C.graveyard
		local pArea = spawnActiveArea(g.planet, "object/active_area.iff", g.x, 0, g.y, g.radius, 0)

		if (pArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterGraveyard", pArea)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pArea):getObjectID())
		end
	end

	-- Rori well-watch site (true coords read from the shrine object).
	if (isZoneEnabled(C.well.planet)) then
		local w = C.well
		local x, y = w.x, w.y
		local pShrine = getSceneObject(w.shrineID)

		if (pShrine ~= nil) then
			x = SceneObject(pShrine):getWorldPositionX()
			y = SceneObject(pShrine):getWorldPositionY()
		else
			print("jtp: WARNING — act4 rori shrine " .. w.shrineID .. " missing; well watch uses census coords")
		end

		JTP_ACT4_WELL = { x = x, y = y }
		local pArea = spawnActiveArea(w.planet, "object/active_area.iff", x, 0, y, w.radius, 0)

		if (pArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterWellSite", pArea)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pArea):getObjectID())
		end
	end

	-- Naboo shrine road: courier ambush + testament cache triggers.
	if (isZoneEnabled(C.courier.planet)) then
		local co = C.courier
		local pRoad = spawnActiveArea(co.planet, "object/active_area.iff", co.x, 0, co.y, co.radius, 0)

		if (pRoad ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterCourierRoad", pRoad)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pRoad):getObjectID())
		end

		local ca = C.cache
		local pCache = spawnActiveArea(ca.planet, "object/active_area.iff", ca.x, 0, ca.y, ca.radius, 0)

		if (pCache ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterTestamentCache", pCache)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pCache):getObjectID())
		end
	end

	-- Dathomir: elder boss site + Singing Mountain approach.
	if (isZoneEnabled("dathomir")) then
		local b = C.bossDark
		local pElder = spawnActiveArea(b.planet, "object/active_area.iff", b.x, 0, b.y, b.radius, 0)

		if (pElder ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterElderSite", pElder)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pElder):getObjectID())
		end

		local m = C.mountain
		local pMountain = spawnActiveArea(m.planet, "object/active_area.iff", m.x, 0, m.y, m.radius, 0)

		if (pMountain ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterMountainApproach", pMountain)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pMountain):getObjectID())
		end
	end

	-- Q4.S1 letter shrines (positions from the live shrine objects).
	for i = 1, #C.letters, 1 do
		local entry = C.letters[i]

		if (isZoneEnabled(entry.planet)) then
			local pShrine = getSceneObject(entry.id)

			if (pShrine == nil) then
				print("jtp: WARNING — act4 letter shrine " .. entry.id .. " missing on " .. entry.planet)
			else
				local x = SceneObject(pShrine):getWorldPositionX()
				local y = SceneObject(pShrine):getWorldPositionY()
				local pArea = spawnActiveArea(entry.planet, "object/active_area.iff", x, 0, y, C.letterRadius, 0)

				if (pArea ~= nil) then
					writeData(SceneObject(pArea):getObjectID() .. ":jtpAct4Letter", i)
					createObserver(ENTEREDAREA, "JediParkAct4", "onEnterLetterShrine", pArea)
					table.insert(JTP_ACT4_SPAWNED, SceneObject(pArea):getObjectID())
				end
			end
		end
	end

	print("jtp: act4 'The Silent Council / The Inquisitor's Gambit' loaded")
end

-- Jinda boot check: verify the three chosen objective cells resolve; any
-- miss flips the whole dungeon leg to world-position fallback spawns at
-- the cave entrance (the cave's 29 cells start at 6015489, but only the
-- first ID is verified).
function JediParkAct4:setupJinda()
	local J = JtpConfig.act4.jinda

	if (JTP_ACT4_JINDA_FALLBACK == nil) then
		JTP_ACT4_JINDA_FALLBACK = false

		for i = 1, #J.cells, 1 do
			if (getSceneObject(J.cells[i]) == nil) then
				JTP_ACT4_JINDA_FALLBACK = true
			end
		end

		if (JTP_ACT4_JINDA_FALLBACK) then
			print("jtp: WARNING — act4 Jinda objective cell(s) unresolved (unverified IDs); world-spawn fallback at the cave entrance is active")
		else
			print("jtp: act4 Jinda objective cells verified: " .. table.concat(J.cells, ", "))
		end
	end

	if (JTP_ACT4_JINDA_FALLBACK) then
		local pArea = spawnActiveArea(J.planet, "object/active_area.iff", J.x, 0, J.y, J.entranceRadius, 0)

		if (pArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct4", "onEnterJindaEntrance", pArea)
			table.insert(JTP_ACT4_SPAWNED, SceneObject(pArea):getObjectID())
		end
	else
		for i = 1, #J.cells, 1 do
			local pArea = spawnActiveArea(J.planet, "object/active_area.iff", J.x, 0, J.y, J.areaRadius, J.cells[i])

			if (pArea ~= nil) then
				writeData(SceneObject(pArea):getObjectID() .. ":jtpAct4Jinda", i)
				createObserver(ENTEREDAREA, "JediParkAct4", "onEnterJindaObjective", pArea)
				table.insert(JTP_ACT4_SPAWNED, SceneObject(pArea):getObjectID())
			end
		end
	end
end

-- ---- data helpers ------------------------------------------------------------

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

-- Live (undestroyed, undead) members of a theater tag. Props count as live.
function JediParkAct4:liveCount(pPlayer, tag)
	local oids = JtpTheaters:getOids(pPlayer, tag)
	local n = 0

	for i = 1, #oids, 1 do
		local pObject = getSceneObject(oids[i])

		if (pObject ~= nil and (not SceneObject(pObject):isCreatureObject() or not CreatureObject(pObject):isDead())) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct4:planetsWalked(pPlayer)
	local n = 0

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		if (JtpShrines:countVisitedOnPlanet(pPlayer, JtpConfig.shrinePlanets[p]) > 0) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct4:pilgrimageMet(pPlayer)
	local pg = JtpConfig.act4.pilgrimage

	return JtpShrines:countVisited(pPlayer) >= pg.count and self:planetsWalked(pPlayer) >= pg.planets
end

function JediParkAct4:jindaMet(pPlayer)
	return dataNum(pPlayer, "act4_jinda_obj_1") == 1
		and dataNum(pPlayer, "act4_jinda_obj_2") == 1
		and dataNum(pPlayer, "act4_jinda_obj_3") == 1
		and dataNum(pPlayer, "act4_jinda_kills") >= JtpConfig.act4.jinda.kills
end

-- ---- the act gate + grace floor (plan 7.4 — Acts V/VI copy this) -------------

-- nil until the act has been accepted once; then the rank written at entry.
function JediParkAct4:entryRank(pPlayer)
	local raw = readScreenPlayData(pPlayer, "JediPark", "act4_entry_rank")

	if (raw == nil or raw == "") then
		return nil
	end

	return tonumber(raw)
end

-- "ok" | "pause" | "no". "pause" = accepted, then demoted below the grace
-- floor max(2, entryRank - 1): everything HOLDS, nothing is wiped.
function JediParkAct4:gateState(pPlayer)
	local M = JediParkManager

	if (pPlayer == nil or not M:isJedi(pPlayer)) then
		return "no"
	end

	local side = M:sideOf(pPlayer)

	if (side == 0) then
		return "no"
	end

	local C = JtpConfig.act4
	local skill = C.gateSkillDark

	if (side == 1) then
		skill = C.gateSkillLight
	end

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return "no"
	end

	if (not M:hasGlobal(pPlayer, C.prevActBit)) then
		return "no"
	end

	local rank = M:frsRankOf(pPlayer)
	local entry = self:entryRank(pPlayer)

	if (entry == nil) then
		if (rank < C.gateRank) then
			return "no"
		end

		return "ok"
	end

	if (rank < math.max(C.gateRank, entry - 1)) then
		return "pause"
	end

	return "ok"
end

function JediParkAct4:gateOk(pPlayer)
	return self:gateState(pPlayer) == "ok"
end

function JediParkAct4:sendPauseNotice(pPlayer)
	local M = JediParkManager
	local entry = self:entryRank(pPlayer) or JtpConfig.act4.gateRank
	local floor = math.max(JtpConfig.act4.gateRank, entry - 1)
	local title = "The Silent Council"

	if (M:sideOf(pPlayer) == 2) then
		title = "The Inquisitor's Gambit"
	end

	self:sui(pPlayer, title, "The council goes quiet around you. Not hostile — quiet, the way a ledger goes quiet about a debt under review. Your standing in the Force's hierarchy has slipped below what the Silent War will spend (you hold rank " .. M:frsRankOf(pPlayer) .. "; the war remembers you at rank " .. entry .. ", and will wait for rank " .. floor .. "). Nothing you have earned is lost, and nothing new opens until you stand where you stood. Recover your rank; the war keeps your place.")
end

-- ---- side flavor (one state machine, two voices) -----------------------------

local FLAVOR = {
	[1] = {
		actName = "The Silent Council",
		giver = "Serenna Vale",
		q1 = "The Quiet Promotion", q2 = "The Chained Choir", q3 = "The Fifteen",
		q4 = "A Pearl for the Broken", q5 = "Seal the Echo", q6 = "The Well Watch",
		q7 = "The Inquisitor's Face", q8 = "Letters Northward", q9 = "Warn the Mountain",
	},
	[2] = {
		actName = "The Inquisitor's Gambit",
		giver = "The Hand's Voice",
		q1 = "An Audience of One", q2 = "The Harvest of Echoes", q3 = "The Fifteen",
		q4 = "A Pearl for the Rising", q5 = "Commune With the Echo", q6 = "The Courier Road",
		q7 = "The Elder's Knee", q8 = "Bait of Paper", q9 = "The Sealed Testament",
	},
}

-- ---- giver conversation routers ----------------------------------------------
-- The light line rides Act II's Serenna (the MAIN LOOP wires the route into
-- convo/jtp_serenna_handler.lua at integration); the dark line is the Voice.
-- Every screen re-evaluates side + gate live (global AC 1 + 7.4).

function JediParkAct4:onSerennaTalk(pPlayer)
	self:onGiverTalk(pPlayer, 1)
end

function JediParkAct4:onVoiceTalk(pPlayer)
	self:onGiverTalk(pPlayer, 2)
end

function JediParkAct4:onGiverTalk(pPlayer, giverSide)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager
	local F = FLAVOR[giverSide]

	if (not M:isJedi(pPlayer) or M:sideOf(pPlayer) == 0) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "Serenna does not look up from the pin-bled map. \"The warroom is for the war. When the Force has finished choosing you a church, we will have something to argue about.\"")
		else
			self:sui(pPlayer, F.giver, "The figure at the far wall does not turn. \"This room convenes for instruments. You are, at present, noise.\"")
		end
		return
	end

	if (M:sideOf(pPlayer) ~= giverSide) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "Serenna's eyes flick to your shadow before your face. \"Knight. The warroom stays open to you — the Circle's counsel does not, any longer. The dark enclave on Yavin keeps a voice that speaks your language now. Council One. Knock quietly.\"")
		else
			self:sui(pPlayer, F.giver, "The Hand's Voice does not turn. \"You filed yourself under something softer. The Emperor's interest in you is now an accounting question, and this room does not do arithmetic aloud. The door remembers the way out.\"")
		end
		return
	end

	local gate = self:gateState(pPlayer)

	if (gate == "no") then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "\"Not yet, knight. The Silent Council seats people the war can spend: begin the mastery of the light's own discipline, finish the Knight of Embers road, and hold the second rank of the Force's hierarchy. Then sit at my board.\" (Requires: light master training begun, Act III complete, FRS rank 2.)")
		else
			self:sui(pPlayer, F.giver, "\"Council One does not convene for potential. Begin the mastery of the dark's discipline, finish the Knight of Shadows road, and hold the second rank of the hierarchy. The Voice will still be here. The Voice is always here.\" (Requires: dark master training begun, Act III complete, FRS rank 2.)")
		end
		return
	end

	if (gate == "pause") then
		self:sendPauseNotice(pPlayer)
		return
	end

	if (not M:hasStarted(pPlayer, 4, 1)) then
		self:offerBriefing(pPlayer, giverSide)
		return
	end

	self:giverMenu(pPlayer, giverSide)
end

-- ---- Q4.1: the act briefing --------------------------------------------------

function JediParkAct4:offerBriefing(pPlayer, side)
	local F = FLAVOR[side]
	local sui = SuiListBox.new("JediParkAct4", "briefingCallback")
	sui.setTitle(F.q1)

	if (side == 1) then
		sui.setPrompt("Serenna Vale no longer argues for the Circle; she runs it. The warroom map has new pins, and all of them are bleeding. \"Knight. I stopped being the arguing voice the day the arguing stopped mattering — someone is peeling us open, cell by cell, and the someone has a budget. We are calling it the Silent War, because the day it gets loud we have lost it. Sit. Look at the board. I need hands I do not have to explain the stakes to.\"")
		sui.add("Sit. Look at the board. (Begin Act IV: The Silent Council)", "")
		sui.add("\"Not today.\"", "")
	else
		sui.setPrompt("Council One. The Hand's Voice does not repeat itself, and does not forgive note-taking. The figure in the Emperor's black has a voice like a door closing. \"Knight. You are here because the ledger says you finish things. The Circle calls what is happening to it the Silent War; we call it inventory. You will take instruction from me, you will take it once, and you will write nothing down.\"")
		sui.add("Stand and listen. (Begin Act IV: The Inquisitor's Gambit)", "")
		sui.add("Withdraw.", "")
	end

	sui.sendTo(pPlayer)
end

function JediParkAct4:briefingCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0 or M:hasStarted(pPlayer, 4, 1) or not self:gateOk(pPlayer)) then
		return
	end

	-- GRACE FLOOR anchor: written exactly once, at first acceptance.
	if (self:entryRank(pPlayer) == nil) then
		dataSet(pPlayer, "act4_entry_rank", math.max(0, M:frsRankOf(pPlayer)))
		M:log(pPlayer, "act4 entry rank " .. math.max(0, M:frsRankOf(pPlayer)))
	end

	JtpCells:heal(pPlayer)
	M:setStarted(pPlayer, 4, 1)
	M:setDone(pPlayer, 4, 1)
	self:reward(pPlayer)

	if (side == 1) then
		self:sui(pPlayer, "The Silent Council", "The pins: wells held, wells lost, couriers vanished, two safehouses gone dark with nobody's name attached. And over all of it one initial, recurring, in Imperial filing-hand. Serenna: \"We have a war to not-lose and an Inquisitor to name. Start on Endor — the Jinda ritualists have begun binding OUR kind into their rites, and I no longer have the luxury of believing in coincidence.\"")
	else
		self:sui(pPlayer, "The Inquisitor's Gambit", "\"An Inquisitor runs the Circle harvest — competent, ambitious, and therefore a variable. The Emperor's interest is served by the harvest, not the harvester. You will run the errands she cannot see, and at the end of them you will understand the gambit. First: Endor. The Jinda ritualists bind echoes the Hand can use. Harvest the bindings; the vessels are incidental.\"")
	end

	self:beginQuest(pPlayer, side, 2)
end

-- ---- quest openers (shared; side text branches) -------------------------------

function JediParkAct4:beginQuest(pPlayer, side, quest)
	local M = JediParkManager
	local F = FLAVOR[side]
	local C = JtpConfig.act4

	if (M:hasStarted(pPlayer, 4, quest)) then
		return
	end

	M:setStarted(pPlayer, 4, quest)

	if (quest == 2) then
		dataSet(pPlayer, "act4_jinda_kills", 0)
		self:attachKillObserver(pPlayer)

		if (side == 1) then
			self:sui(pPlayer, F.q2, "\"Jinda ritualists on Endor are binding captive sensitives into their rites. Twenty-nine chambers under the roots. Bring everyone out who can still walk.\" (Fight into the Jinda Ritualist Cave at -1713 53, Endor: defeat " .. C.jinda.kills .. " of the ritual gangs and free 3 chained sensitives at the deep chambers.)")
		else
			self:sui(pPlayer, F.q2, "\"The ritualists bind echoes the Hand can use. Harvest the bindings; the vessels are incidental.\" (Fight into the Jinda Ritualist Cave at -1713 53, Endor: defeat " .. C.jinda.kills .. " of the ritual gangs and pull 3 binding urns from the deep chambers.)")
		end

	elseif (quest == 3) then
		self:sui(pPlayer, F.q3, "\"Fifteen wells, six worlds. By now the shrines know your footsteps. So does someone else.\" (Walk " .. C.pilgrimage.count .. " Force shrines in your lifetime of walking, across at least " .. C.pilgrimage.planets .. " planets. Expect company at the wells — it watches; it does not approach. Yet.)")

	elseif (quest == 4) then
		if (side == 1) then
			self:sui(pPlayer, F.q4, "\"Sarov's old hilt — the Fallen Master's — wants a krayt pearl at its heart before it can be offered back to him. The graveyard owes you a near-miss.\" (Travel to the Krayt Graveyard at 7451 4510, Tatooine, and take a pearl from a canyon krayt — or offer one you already carry.)")
		else
			self:sui(pPlayer, F.q4, "\"Your ascent wants a pearl the color of consequence. The canyon krayts collect consequences.\" (Travel to the Krayt Graveyard at 7451 4510, Tatooine, and take a pearl from a canyon krayt — or offer one you already carry.)")
		end

	elseif (quest == 5) then
		if (side == 1) then
			self:sui(pPlayer, F.q5, "\"Something of Exar Kun still murmurs in the temple's deepest cell — and the Rebels bunking upstairs have no idea. Seal it before the Empire hears it first.\" (Enter the Temple of Exar Kun at 5057 5538, Yavin IV, and descend to the deepest chamber. Touch nothing on the way down; the upstairs war is not ours.)")
		else
			self:sui(pPlayer, F.q5, "\"Four thousand years of undiluted hunger, murmuring in a cell the Rebels use as a wall. Listen. Learn. Leave it wanting you.\" (Enter the Temple of Exar Kun at 5057 5538, Yavin IV, and descend to the deepest chamber. The Rebels upstairs are scenery. Leave them scenery.)")
		end

	elseif (quest == 6) then
		if (side == 1) then
			self:sui(pPlayer, F.q6, "\"A Prophet strike team moves on the Rori shrine tonight. The Circle holds wells; that is the whole of the war.\" (Stand the watch at the Rori shrine near 307 -982 — three waves. Do not leave the well while it stands.)")
		else
			self:sui(pPlayer, F.q6, "\"Circle couriers run the Naboo shrine road with the census annotations YOU provided. The Voice wants the couriers, not the letters.\" (Ambush the courier's guard on the shrine road near 2340 -440, Naboo, and take the courier standing.)")
		end

	elseif (quest == 7) then
		if (side == 1) then
			self:sui(pPlayer, F.q7, "\"The Inquisitor peeling the Circle open, cell by cell, finally has a face: Vheress. She remembers you from a dead man's doorstep. She has been ahead of you the whole way — until the Jinda dark.\" (Return to the depths of the Jinda Ritualist Cave. She is waiting. She knows she is waiting.)")
		else
			self:sui(pPlayer, F.q7, "\"Sereth's price comes due: a Nightsister elder who defies the pact must kneel or fall.\" The Voice adds, mildly: \"Kneeling is optional.\" (Find the defiant elder in the wilds outside the Nightsister stronghold, near -4150 -200, Dathomir.)")
		end

	elseif (quest == 8) then
		if (dataNum(pPlayer, "act4_s1_item") == 0) then
			local itemName = C.items.letterLightName

			if (side == 2) then
				itemName = C.items.letterDarkName
			end

			local pItem = M:giveNamedItem(pPlayer, C.items.letter, itemName)

			if (pItem ~= nil) then
				dataSet(pPlayer, "act4_s1_item", 1)
			end
		end

		if (side == 1) then
			self:sui(pPlayer, F.q8, "\"Three of Ondel's letters, three shrines the war has made dangerous.\" (Deliver the letters by walking to the marked wells: the Dathomir witch-road shrine, the Endor shrine, and the Naboo shrine. The letters are flavor of the road — losing them loses nothing.)")
		else
			self:sui(pPlayer, F.q8, "\"Three forged letters, three shrines — let the zealots come collect them.\" (Plant the letters by walking to the marked wells on Dathomir, Endor and Naboo. Expect the third delivery to be read before you leave the well.)")
		end

	elseif (quest == 9) then
		if (side == 1) then
			self:sui(pPlayer, F.q9, "\"Vheress's files named the Singing Mountain. Veshaan must hear it from you, not from the fire.\" (Carry the warning to the Singing Mountain approach at 164 4489, Dathomir. Go quietly; arrive unseen; leave nothing there but the words.)")
		else
			self:sui(pPlayer, F.q9, "\"The Circle's founding holocron exists. The Voice wants it unopened — an instrument that reads its master's mail is a tool that breaks.\" (Take it from the Circle courier-cache on the Naboo shrine road, near 2260 -560. The guards are not incidental. The seal is.)")
		end
	end
end

-- ---- the giver menu (mando_rank_stone menuKeys pattern, act2 idiom) ----------

function JediParkAct4:giverMenu(pPlayer, side)
	local M = JediParkManager
	local F = FLAVOR[side]
	local options = {}

	-- Main spine (linear; *_start branches self-heal a missing started bit).
	if (not M:hasStarted(pPlayer, 4, 2)) then
		options[#options + 1] = { "q2_start", "Ask where the war starts (Begin: " .. F.q2 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 2)) then
		if (self:jindaMet(pPlayer)) then
			options[#options + 1] = { "q2_turnin", "\"The chambers are empty.\" (Turn in: " .. F.q2 .. ")" }
		else
			options[#options + 1] = { "q2_hint", "Ask about the Jinda cave (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 4, 3)) then
		options[#options + 1] = { "q3_start", "\"Where does the road go now?\" (Begin: " .. F.q3 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 3)) then
		if (self:pilgrimageMet(pPlayer)) then
			options[#options + 1] = { "q3_turnin", "\"Fifteen wells are walked.\" (Turn in: " .. F.q3 .. ")" }
		else
			options[#options + 1] = { "q3_hint", "Ask about the fifteen wells (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 4, 4)) then
		options[#options + 1] = { "q4_start", "Ask about the pearl (Begin: " .. F.q4 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 4)) then
		if (dataNum(pPlayer, "act4_pearl") == 1) then
			options[#options + 1] = { "q4_turnin", "Present the krayt's pearl (Turn in: " .. F.q4 .. ")" }
		else
			options[#options + 1] = { "q4_hint", "Ask about the graveyard (progress)" }
			options[#options + 1] = { "q4_offer", "Offer a pearl you already carry (complete now)" }
		end
	elseif (not M:hasStarted(pPlayer, 4, 5)) then
		options[#options + 1] = { "q5_start", "Ask about the temple's murmur (Begin: " .. F.q5 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 5)) then
		if (dataNum(pPlayer, "act4_kun_done") == 1) then
			options[#options + 1] = { "q5_turnin", "Report from the deep cell (Turn in: " .. F.q5 .. ")" }
		else
			options[#options + 1] = { "q5_hint", "Ask about the Temple of Exar Kun (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 4, 6)) then
		options[#options + 1] = { "q6_start", "Ask where the war moves next (Begin: " .. F.q6 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 6)) then
		local q6ready = false

		if (side == 1) then
			q6ready = dataNum(pPlayer, "act4_well_state") == 2
		else
			q6ready = dataNum(pPlayer, "act4_courier_done") == 1
		end

		if (q6ready) then
			options[#options + 1] = { "q6_turnin", "Report the outcome (Turn in: " .. F.q6 .. ")" }
		else
			options[#options + 1] = { "q6_hint", "Ask about the engagement (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 4, 7)) then
		options[#options + 1] = { "q7_start", "Ask for the name (Begin: " .. F.q7 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 7)) then
		if (dataNum(pPlayer, "act4_boss_dead") == 1) then
			options[#options + 1] = { "q7_turnin", "It is done. (Turn in: " .. F.q7 .. " — act finale)" }
		else
			options[#options + 1] = { "q7_hint", "Ask about the hunt (progress)" }
		end
	else
		options[#options + 1] = { "road_ahead", "Ask about the road ahead" }
	end

	-- Side quests (open once the act is underway).
	if (dataNum(pPlayer, "act4_s1_holo_due") == 1) then
		options[#options + 1] = { "s1_claim", "Receive the archivist's holocron (" .. F.q8 .. ")" }
	end

	if (not M:hasStarted(pPlayer, 4, 8)) then
		options[#options + 1] = { "s1_start", "Ask about the letters (Side: " .. F.q8 .. ")" }
	elseif (not M:hasDone(pPlayer, 4, 8)) then
		options[#options + 1] = { "s1_hint", "Ask about the letter run (progress)" }
	end

	if (not M:hasStarted(pPlayer, 4, 9)) then
		if (side == 1) then
			options[#options + 1] = { "s2_start", "Ask what Vheress's files named (Side: " .. F.q9 .. ")" }
		else
			options[#options + 1] = { "s2_start", "Ask about the founding holocron (Side: " .. F.q9 .. ")" }
		end
	elseif (not M:hasDone(pPlayer, 4, 9)) then
		options[#options + 1] = { "s2_hint", "Ask about the errand (progress)" }
	end

	if (side == 2 and JediParkRepeat ~= nil and JediParkRepeat:eligible(pPlayer)) then
		options[#options + 1] = { "repeatables", "Ask what standing lines the ledger keeps. (Weekly)" }
	end

	options[#options + 1] = { "wells", "Ask how many wells you have walked." }

	local keys = {}
	local sui = SuiListBox.new("JediParkAct4", "giverMenuCallback")
	sui.setTitle(F.giver)

	if (side == 1) then
		sui.setPrompt("\"The board is listening.\"")
	else
		sui.setPrompt("\"Speak. Once.\"")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "act4_menukeys", table.concat(keys, ","))
	dataSet(pPlayer, "act4_menu_giver", side)
	sui.sendTo(pPlayer)
end

function JediParkAct4:giverMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act4_menukeys")
	dataSet(pPlayer, "act4_menukeys", "")

	if (list == nil or list == "") then
		return
	end

	local keys = {}

	for k in string.gmatch(list, "[^,]+") do
		keys[#keys + 1] = k
	end

	local action = keys[idx + 1]

	if (action == nil) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	-- Live re-checks on every selection: side + gate (global AC 1/4).
	if (side == 0 or side ~= dataNum(pPlayer, "act4_menu_giver")) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		if (self:gateState(pPlayer) == "pause") then
			self:sendPauseNotice(pPlayer)
		end
		return
	end

	local F = FLAVOR[side]
	local C = JtpConfig.act4

	if (action == "q2_start") then
		if (M:hasDone(pPlayer, 4, 1)) then
			self:beginQuest(pPlayer, side, 2)
		end

	elseif (action == "q2_hint") then
		local kills = dataNum(pPlayer, "act4_jinda_kills")
		local objs = dataNum(pPlayer, "act4_jinda_obj_1") + dataNum(pPlayer, "act4_jinda_obj_2") + dataNum(pPlayer, "act4_jinda_obj_3")
		local where = "the deep chambers"

		if (JTP_ACT4_JINDA_FALLBACK) then
			where = "the chambers by the cave mouth"
		end

		self:attachKillObserver(pPlayer)

		if (side == 1) then
			self:sui(pPlayer, F.q2, "\"The cave at -1713 53, Endor. " .. kills .. " of " .. C.jinda.kills .. " ritualists accounted for; " .. objs .. " of 3 sensitives brought out of " .. where .. ". Every chamber you empty is a choir the rite goes without.\"")
		else
			self:sui(pPlayer, F.q2, "\"The cave at -1713 53, Endor. " .. kills .. " of " .. C.jinda.kills .. " ritualists retired; " .. objs .. " of 3 bindings pulled from " .. where .. ". The Hand does not pay for partial inventory.\"")
		end

	elseif (action == "q2_turnin") then
		if (M:hasStarted(pPlayer, 4, 2) and not M:hasDone(pPlayer, 4, 2) and self:jindaMet(pPlayer)) then
			self:completeQuest(pPlayer, 2)

			if (side == 1) then
				self:sui(pPlayer, F.q2, "\"Three people are breathing tonight who were furniture this morning. The rite is broken and the Jinda will blame their spirits, not us — which is the correct shape for a Silent War victory.\"")
			else
				self:sui(pPlayer, F.q2, "\"Three bindings, twelve retirements. The vessels walked out, I am told. Sentiment, or camouflage?\" The Voice does not wait for an answer. \"Either is acceptable. Both are useful.\"")
			end

			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_start") then
		if (M:hasDone(pPlayer, 4, 2)) then
			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_hint") then
		self:sui(pPlayer, F.q3, "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. C.pilgrimage.count .. " wells; " .. self:planetsWalked(pPlayer) .. " of " .. C.pilgrimage.planets .. " worlds. The watchers are counting too. Let them count. Counting is all they have been paid to do — so far.\"")

	elseif (action == "q3_turnin") then
		if (M:hasStarted(pPlayer, 4, 3) and not M:hasDone(pPlayer, 4, 3) and self:pilgrimageMet(pPlayer)) then
			self:completeQuest(pPlayer, 3)
			M:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)

			if (side == 1) then
				self:sui(pPlayer, F.q3, "\"Fifteen wells, and every one of them now knows a footstep the Empire cannot file. Ondel forwards a power crystal with a note: 'For the walker. The watchers walked home hungry.'\"")
			else
				self:sui(pPlayer, F.q3, "\"Fifteen wells. The light's watchers made their counts and their counts made their way here, which is the point of watchers.\" A courier case: a power crystal. \"The Hand pays for mileage.\"")
			end

			self:beginQuest(pPlayer, side, 4)
		end

	elseif (action == "q4_start") then
		if (M:hasDone(pPlayer, 4, 3)) then
			self:beginQuest(pPlayer, side, 4)
		end

	elseif (action == "q4_hint") then
		self:sui(pPlayer, F.q4, "\"The graveyard at 7451 4510, Tatooine. Walk the bone-line; something will notice you. It always notices.\"")

	elseif (action == "q4_offer") then
		if (M:hasStarted(pPlayer, 4, 4) and not M:hasDone(pPlayer, 4, 4) and dataNum(pPlayer, "act4_pearl") == 0) then
			self:offerPearl(pPlayer, side)
		end

	elseif (action == "q4_turnin") then
		if (M:hasStarted(pPlayer, 4, 4) and not M:hasDone(pPlayer, 4, 4) and dataNum(pPlayer, "act4_pearl") == 1) then
			self:completeQuest(pPlayer, 4)
			M:giveLootGroup(pPlayer, C.lootGroups.pearls)

			if (side == 1) then
				self:sui(pPlayer, F.q4, "\"A pearl out of the canyon's own jaw.\" Serenna turns it once against the light. \"Sarov's hilt will take it, when he is ready to be given things again. Keep what the graveyard gave you back — select quality finds its own hand.\" (A pearl grant arrives in your inventory; choice-grade selection lands with the client update.)")
			else
				self:sui(pPlayer, F.q4, "\"The color of consequence, as promised.\" The Voice weighs it without touching it. \"Keep what the graveyard yielded — the Hand equips its instruments from the instrument's own kills. It teaches the correct lesson about supply.\" (A pearl grant arrives in your inventory; choice-grade selection lands with the client update.)")
			end

			self:beginQuest(pPlayer, side, 5)
		end

	elseif (action == "q5_start") then
		if (M:hasDone(pPlayer, 4, 4)) then
			self:beginQuest(pPlayer, side, 5)
		end

	elseif (action == "q5_hint") then
		self:sui(pPlayer, F.q5, "\"The temple at 5057 5538, Yavin IV — down, past the Rebels' bunks, to the last cell the torches reach. The murmur is quietest right before you are standing in it.\"")

	elseif (action == "q5_turnin") then
		if (M:hasStarted(pPlayer, 4, 5) and not M:hasDone(pPlayer, 4, 5) and dataNum(pPlayer, "act4_kun_done") == 1) then
			self:completeQuest(pPlayer, 5)

			if (side == 1) then
				self:sui(pPlayer, F.q5, "\"Sealed, and the Rebels none the wiser. Good. The Empire hunts echoes like that the way it hunts us — as inventory. Tonight its shelf is one item shorter.\"")
			else
				self:sui(pPlayer, F.q5, "\"You listened, and left it wanting.\" Something in the Voice approves, which is worse than warmth. \"What it told you will matter in a room where oaths are taken. Do not spend the sentence early.\"")
			end

			self:beginQuest(pPlayer, side, 6)
		end

	elseif (action == "q6_start") then
		if (M:hasDone(pPlayer, 4, 5)) then
			self:beginQuest(pPlayer, side, 6)
		end

	elseif (action == "q6_hint") then
		if (side == 1) then
			local active, waveIdx, remaining = JtpTheaters:waveStatus(pPlayer, "act4_well")

			if (active) then
				self:sui(pPlayer, F.q6, "\"The watch is STANDING — wave " .. waveIdx .. ", " .. remaining .. " still in the wire. Get back to the shrine!\"")
			else
				self:sui(pPlayer, F.q6, "\"The Rori shrine, near 307 -982. Stand at the well and say so; the Prophets will do the rest of the introductions.\"")
			end
		else
			if (dataNum(pPlayer, "act4_courier_ready") == 1) then
				self:sui(pPlayer, F.q6, "\"The guard is down and the courier is standing very still. Finish the errand: take the courier.\"")
			else
				self:sui(pPlayer, F.q6, "\"The shrine road near 2340 -440, Naboo. Four zealots and one courier who believes in them. Adjust the arithmetic.\"")
			end
		end

	elseif (action == "q6_turnin") then
		if (M:hasStarted(pPlayer, 4, 6) and not M:hasDone(pPlayer, 4, 6)) then
			if (side == 1 and dataNum(pPlayer, "act4_well_state") == 2) then
				dataSet(pPlayer, "act4_well_state", 0)
				self:completeQuest(pPlayer, 6)
				self:sui(pPlayer, F.q6, "\"Three waves, and the well is still a well. The Prophets will write it up as a mapping error — their paymasters do not pay for defeats, so defeats get renamed. Let them. The war stays silent and the water stays ours.\"")
				self:beginQuest(pPlayer, side, 7)
			elseif (side == 2 and dataNum(pPlayer, "act4_courier_done") == 1) then
				self:completeQuest(pPlayer, 6)
				self:sui(pPlayer, F.q6, "\"The courier talked before the courier finished sitting down. Routes, drop-stones, two names we lacked.\" A pause. \"The letters, as stated, did not interest the Voice. The Voice read them anyway. Consistency is for instruments.\"")
				self:beginQuest(pPlayer, side, 7)
			end
		end

	elseif (action == "q7_start") then
		if (M:hasDone(pPlayer, 4, 6)) then
			self:beginQuest(pPlayer, side, 7)
		end

	elseif (action == "q7_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q7, "\"The Jinda depths — where you broke her harvest. She chose the ground herself; she thinks it is a message. It is: it tells us she has run out of people to send instead.\"")
		else
			self:sui(pPlayer, F.q7, "\"The wilds by the stronghold, near -4150 -200. She will not run. Elders who defy pacts have already decided how the story ends; you are only the punctuation.\"")
		end

	elseif (action == "q7_turnin") then
		if (M:hasStarted(pPlayer, 4, 7) and not M:hasDone(pPlayer, 4, 7) and dataNum(pPlayer, "act4_boss_dead") == 1) then
			self:finishAct(pPlayer, side)
		end

	elseif (action == "road_ahead") then
		if (side == 1) then
			self:sui(pPlayer, "The Road Ahead", "\"The Inquisitor is named and the wells still speak. What comes next is not a war of cells — it is a war for what the light IS when nobody survives to argue about it. Rest. The Unbroken Light arrives in a later update.\"")
		else
			self:sui(pPlayer, "The Road Ahead", "\"The gambit is understood, the board is swept, and the Emperor's interest in you has been... upgraded. Do not enjoy that. Heart of Darkness arrives in a later update.\"")
		end

	elseif (action == "s1_start") then
		if (not M:hasStarted(pPlayer, 4, 8)) then
			self:beginQuest(pPlayer, side, 8)
		end

	elseif (action == "s1_hint") then
		local n = dataNum(pPlayer, "act4_letters_1") + dataNum(pPlayer, "act4_letters_2") + dataNum(pPlayer, "act4_letters_3")
		self:sui(pPlayer, F.q8, "\"" .. n .. " of 3 wells lettered — the Dathomir witch-road, the Endor stones, the Naboo road-well. Paper is slow. Slow is invisible. Invisible wins.\"")

	elseif (action == "s1_claim") then
		if (dataNum(pPlayer, "act4_s1_holo_due") == 1) then
			local template = C.items.holocronLight

			if (side == 2) then
				template = C.items.holocronDark
			end

			local pItem = M:giveNamedItem(pPlayer, template, nil)

			if (pItem == nil) then
				CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. The holocron will be held — ask for it again.")
			else
				dataSet(pPlayer, "act4_s1_holo_due", 0)

				if (side == 1) then
					self:sui(pPlayer, F.q8, "Ondel's thanks, courier-sealed: a holocron, and a margin note. \"Three wells that know the war by name now know our handwriting too. Teach it to no one. Teach it to everyone.\"")
				else
					self:sui(pPlayer, F.q8, "The reader's fee: a holocron, unsigned. \"The zealots collected the bait and the bait collected the zealots,\" the Voice observes. \"Symmetry. The Emperor is fond of it.\"")
				end
			end
		end

	elseif (action == "s2_start") then
		if (not M:hasStarted(pPlayer, 4, 9)) then
			self:beginQuest(pPlayer, side, 9)
		end

	elseif (action == "s2_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q9, "\"The Mountain approach at 164 4489. Veshaan will be at the porch-line before you see her arrive — she always is. Say it plainly and leave lightly.\"")
		else
			self:sui(pPlayer, F.q9, "\"The cache near 2260 -560, Naboo. Kill the guard, take the Testament, break nothing else — least of all the seal.\"")
		end

	elseif (action == "repeatables") then
		JediParkRepeat:offer(pPlayer)

	elseif (action == "wells") then
		self:sui(pPlayer, "The Pilgrim's Ledger", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. JtpConfig.shrineTotal() .. " wells, across " .. self:planetsWalked(pPlayer) .. " worlds. The network only exists while someone walks it.\"")
	end
end

-- ---- Q4.2: the Jinda Ritualist Cave ------------------------------------------
-- Verified-cell mode: one cell-filtered area per objective chamber; the same
-- areas double as the L-boss trigger (objective cell 3). Fallback mode: one
-- entrance area stages everything at world offsets. Stock cave spawns are
-- untouched — ritualist credit is a zone+radius kill filter.

function JediParkAct4:onEnterJindaObjective(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager
	local idx = readData(SceneObject(pArea):getObjectID() .. ":jtpAct4Jinda")

	if (idx == nil or idx == 0) then
		return 0
	end

	if (M:hasStarted(pPlayer, 4, 2) and not M:hasDone(pPlayer, 4, 2)) then
		self:attachKillObserver(pPlayer)

		if (dataNum(pPlayer, "act4_jinda_obj_" .. idx) == 0 and self:liveCount(pPlayer, "act4_jinda" .. idx) == 0) then
			self:buildObjective(pPlayer, idx, JtpConfig.act4.jinda.cells[idx])
		end
	elseif (idx == 3 and M:sideOf(pPlayer) == 1 and M:hasStarted(pPlayer, 4, 7) and not M:hasDone(pPlayer, 4, 7)) then
		self:stageBossLight(pPlayer, JtpConfig.act4.jinda.cells[3])
	end

	return 0
end

function JediParkAct4:onEnterJindaEntrance(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:hasStarted(pPlayer, 4, 2) and not M:hasDone(pPlayer, 4, 2)) then
		self:attachKillObserver(pPlayer)

		for i = 1, 3, 1 do
			if (dataNum(pPlayer, "act4_jinda_obj_" .. i) == 0 and self:liveCount(pPlayer, "act4_jinda" .. i) == 0) then
				self:buildObjective(pPlayer, i, 0)
			end
		end
	elseif (M:sideOf(pPlayer) == 1 and M:hasStarted(pPlayer, 4, 7) and not M:hasDone(pPlayer, 4, 7)) then
		self:stageBossLight(pPlayer, 0)
	end

	return 0
end

-- Objective theater: L = a chained sensitive (invulnerable commoner, freed
-- via radial); D = a binding urn (red shrine prop, looted via radial).
-- cellID ~= 0 uses the player's OWN cell-local position (bulletproof against
-- unknown room coordinates); cellID == 0 uses the authored world offsets.
function JediParkAct4:buildObjective(pPlayer, idx, cellID)
	local J = JtpConfig.act4.jinda
	local side = JediParkManager:sideOf(pPlayer)
	local spec = { planet = J.planet, tag = "act4_jinda" .. idx, lifetimeSec = 900 }

	if (cellID ~= nil and cellID ~= 0) then
		spec.cell = cellID
		spec.x = SceneObject(pPlayer):getPositionX()
		spec.z = SceneObject(pPlayer):getPositionZ()
		spec.y = SceneObject(pPlayer):getPositionY()
	else
		local off = J.fallbackOffsets[idx] or { 0, 0 }
		spec.cell = 0
		spec.x = J.x + off[1]
		spec.z = 0
		spec.y = J.y + off[2]
	end

	if (side == 1) then
		local captive = { J.captiveTemplate, 1.5, 0, 1.5, 0, "a chained sensitive" }
		captive.invuln = true
		spec.mobs = { captive }
	else
		spec.props = { { J.urnProp, 1.5, 0, 1.5 } }
	end

	local built = JtpTheaters:build(pPlayer, spec)

	if (built == nil) then
		return
	end

	local pObjective = nil

	if (side == 1) then
		pObjective = built.mobs[1]
	else
		pObjective = built.props[1]
	end

	if (pObjective ~= nil) then
		SceneObject(pObjective):setObjectMenuComponent("JtpAct4ObjectiveMenuComponent")

		if (side == 1) then
			CreatureObject(pPlayer):sendSystemMessage("A chained sensitive kneels in the ritual ring, eyes open, seeing nothing you can see. (Use the radial menu to free them.)")
		else
			CreatureObject(pPlayer):sendSystemMessage("A binding urn hums on the ritual stone, red-lit from within. (Use the radial menu to take the binding.)")
		end
	end
end

-- Radial component for both objective flavors (per-player: only the owner's
-- theater members respond).
JtpAct4ObjectiveMenuComponent = {}

function JtpAct4ObjectiveMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpAct4ObjectiveMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local A = JediParkAct4
	local idx = 0

	for i = 1, 3, 1 do
		if (JtpTheaters:isTheaterMob(pPlayer, "act4_jinda" .. i, pSceneObject)) then
			idx = i
			break
		end
	end

	if (idx == 0) then
		CreatureObject(pPlayer):sendSystemMessage("It does not answer to you. Whatever claim is on it belongs to someone else's war.")
		return 0
	end

	if (not A:gateOk(pPlayer) or not M:hasStarted(pPlayer, 4, 2) or M:hasDone(pPlayer, 4, 2)) then
		return 0
	end

	if (dataNum(pPlayer, "act4_jinda_obj_" .. idx) == 1) then
		return 0
	end

	dataSet(pPlayer, "act4_jinda_obj_" .. idx, 1)
	JtpTheaters:teardown(pPlayer, "act4_jinda" .. idx)

	local n = dataNum(pPlayer, "act4_jinda_obj_1") + dataNum(pPlayer, "act4_jinda_obj_2") + dataNum(pPlayer, "act4_jinda_obj_3")

	if (M:sideOf(pPlayer) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("The chains come apart and the sensitive comes back from wherever the rite had put them. They do not thank you; they RUN, which is better. (" .. n .. " of 3 freed)")
	else
		CreatureObject(pPlayer):sendSystemMessage("The urn goes quiet in your hands — not empty. Kept. (" .. n .. " of 3 bindings)")
	end

	if (A:jindaMet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[M:sideOf(pPlayer)].q2 .. ": the chambers are done. Return to " .. FLAVOR[M:sideOf(pPlayer)].giver .. ".")
	end

	return 0
end

-- ---- Q4.3: shrine hook (the MAIN LOOP wires this into jtp_shrines.lua) -------

function JediParkAct4:onShrineVisited(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 3) or M:hasDone(pPlayer, 4, 3) or not self:gateOk(pPlayer)) then
		return
	end

	local C = JtpConfig.act4

	if (self:pilgrimageMet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The Fifteen: the wells are walked. Return to " .. FLAVOR[M:sideOf(pPlayer)].giver .. ".")
	else
		CreatureObject(pPlayer):sendSystemMessage("The Fifteen: " .. math.min(C.pilgrimage.count, JtpShrines:countVisited(pPlayer)) .. " of " .. C.pilgrimage.count .. " wells; " .. math.min(C.pilgrimage.planets, self:planetsWalked(pPlayer)) .. " of " .. C.pilgrimage.planets .. " worlds.")
	end

	self:maybeSpawnWatcher(pPlayer)
end

-- The watcher: apparition-spawned stalker at 40m — non-aggro, invulnerable,
-- despawns in 45s, drops nothing. Pure dread; walking away always works.
function JediParkAct4:maybeSpawnWatcher(pPlayer)
	local C = JtpConfig.act4

	if (SceneObject(pPlayer):getParentID() ~= 0) then
		return
	end

	if (getRandomNumber(C.pilgrimage.watcherChance) ~= 1) then
		return
	end

	local zone = SceneObject(pPlayer):getZoneName()

	if (zone == "" or not isZoneEnabled(zone)) then
		return
	end

	local side = JediParkManager:sideOf(pPlayer)
	local template = C.watcherLight
	local glow = "dark"

	if (side == 2) then
		template = C.watcherDark
		glow = "light"
	end

	local angle = math.rad(getRandomNumber(360))
	local range = C.pilgrimage.watcherRange

	JtpTheaters:apparition(pPlayer, {
		planet = zone,
		x = SceneObject(pPlayer):getWorldPositionX() + math.cos(angle) * range,
		z = 0,
		y = SceneObject(pPlayer):getWorldPositionY() + math.sin(angle) * range,
		template = template,
		heading = 0,
		glow = glow,
		lifetimeSec = C.pilgrimage.watcherLifeSec,
		invulnerable = true,
		onAppear = { screenplay = "JediParkAct4", fn = "onWatcherAppears" },
		tag = "act4_watcher",
	})
end

function JediParkAct4:onWatcherAppears(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (JediParkManager:sideOf(pPlayer) == 2) then
		CreatureObject(pPlayer):sendSystemMessage("A figure in pale robes stands at the tree line — exactly forty meters away, exactly still. It takes no notes it needs to write down. It is not afraid of you. That is the message.")
	else
		CreatureObject(pPlayer):sendSystemMessage("A figure in Prophet's rags stands on the ridge line — exactly forty meters away, exactly still. It does not approach. Somehow the not-approaching is worse.")
	end
end

-- ---- Q4.4: the Krayt Graveyard -----------------------------------------------

function JediParkAct4:onEnterGraveyard(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 4) or M:hasDone(pPlayer, 4, 4) or dataNum(pPlayer, "act4_pearl") == 1) then
		return 0
	end

	if (self:liveCount(pPlayer, "act4_krayt") > 0) then
		return 0
	end

	local G = JtpConfig.act4.graveyard
	local built = JtpTheaters:build(pPlayer, {
		planet = G.planet, x = G.x, z = 0, y = G.y,
		mobs = { { G.krayt, 12, 0, 14, 180 } },
		lifetimeSec = G.lifeSec,
		tag = "act4_krayt",
	})

	if (built ~= nil and built.mobs[1] ~= nil) then
		self:attachKillObserver(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("The bone-line shifts. Something the graveyard was keeping decides you are worth getting up for.")
	end

	return 0
end

-- Route B (Phase A simplification, flagged in the SUI): a confirm-dialog
-- pearl offer that consumes nothing and completes at a reduced FRS grant.
function JediParkAct4:offerPearl(pPlayer, side)
	local F = FLAVOR[side]
	local sui = SuiListBox.new("JediParkAct4", "pearlOfferCallback")
	sui.setTitle(F.q4)

	if (side == 1) then
		sui.setPrompt("\"If the graveyard already paid you once, a pearl you carry will serve — the hilt cares about the pearl, not the errand.\" (Phase A note: the offered pearl is not consumed by this exchange, and the grant is reduced accordingly.)")
	else
		sui.setPrompt("\"If you already carry consequence, the Hand will not send you to collect it twice. Offer it.\" (Phase A note: the offered pearl is not consumed by this exchange, and the grant is reduced accordingly.)")
	end

	sui.add("Offer a pearl you carry. (Complete now, reduced grant)", "")
	sui.add("\"I'll take it from the canyon myself.\"", "")
	sui.sendTo(pPlayer)
end

function JediParkAct4:pearlOfferCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 4, 4) or M:hasDone(pPlayer, 4, 4)) then
		return
	end

	JtpTheaters:teardown(pPlayer, "act4_krayt")
	self:completeQuest(pPlayer, 4, JtpConfig.act4.frsPearlTurnIn)
	M:giveLootGroup(pPlayer, JtpConfig.act4.lootGroups.pearls)

	if (side == 1) then
		self:sui(pPlayer, FLAVOR[side].q4, "Serenna accepts the pearl the way one accepts a debt transferred, and hands you back a courier-wrapped one in exchange. \"The graveyard's own, from the Circle's stores. Fair trade for not making you bleed twice.\"")
	else
		self:sui(pPlayer, FLAVOR[side].q4, "The Voice does not touch the pearl; the Voice inventories it. \"Acceptable provenance.\" A courier case slides across. \"An equivalent, from stock. The Hand does not hold assets it can circulate.\"")
	end

	self:beginQuest(pPlayer, side, 5)
end

-- ---- Q4.5: the Exar Kun deep cell (r15 = 3465394, and nothing else) ----------
-- ZERO permission changes; every spawn is per-player, non-aggro until the
-- player's own trigger, and torn down afterward. Spawn coordinates are the
-- player's OWN cell-local position (the deep room's floorplan is unmapped).
-- L: channel beat = confirm SUI -> defender batch 1 -> batch 2 (chained
-- builds, NOT startWaves — never waves inside cells) -> timed presence SUI
-- chain. D: SUI rite + the Echo apparition.

function JediParkAct4:onEnterKunDeep(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_done") == 1) then
		return 0
	end

	local stage = dataNum(pPlayer, "act4_kun_stage")

	if (stage == 1 or stage == 2) then
		-- Restart/expiry self-heal: a stage with no living batch lapses.
		local tag = "act4_kun1"

		if (stage == 2) then
			tag = "act4_kun2"
		end

		if (self:liveCount(pPlayer, tag) == 0) then
			self:resetKun(pPlayer, "The old ground has gone cold — whatever you began here lapsed with your absence. Begin the working again.")
		end

		return 0
	end

	if (stage ~= 0) then
		return 0 -- seal chain in flight
	end

	if (M:sideOf(pPlayer) == 1) then
		local sui = SuiListBox.new("JediParkAct4", "sealBeginCallback")
		sui.setTitle(FLAVOR[1].q5)
		sui.setPrompt("The deepest cell hums like a struck bell that refuses to finish. Something of Exar Kun is HERE — thin as smoke, patient as debt, murmuring in a tongue you almost know. To seal it you must hold this ground and keep speaking the old words, whatever the murmur sends up the stairs of itself.")
		sui.add("Begin the sealing.", "")
		sui.add("Not yet.", "")
		sui.sendTo(pPlayer)
	else
		local sui = SuiListBox.new("JediParkAct4", "riteCallback")
		sui.setTitle(FLAVOR[2].q5)
		sui.setPrompt("The deepest cell hums like a struck bell that refuses to finish. The murmur turns toward you the way a door turns on a hinge — it knows the shape of ambition. It has worn it. The Voice's instruction was three words: listen, learn, leave. The murmur has a longer offer.")
		sui.add("Listen.", "")
		sui.add("Step back.", "")
		sui.sendTo(pPlayer)
	end

	return 0
end

function JediParkAct4:sealBeginCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_done") == 1) then
		return
	end

	if (dataNum(pPlayer, "act4_kun_stage") ~= 0) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act4.kun.cell) then
		CreatureObject(pPlayer):sendSystemMessage("The old words need you standing inside the deep cell itself.")
		return
	end

	local token = getTimestamp()
	dataSet(pPlayer, "act4_kun_stage", 1)
	dataSet(pPlayer, "act4_kun_token", token)
	self:spawnKunBatch(pPlayer, 1)
	CreatureObject(pPlayer):sendSystemMessage("The murmur stops. Then, all at once, it ANSWERS.")
end

-- Chained defender batches (kun-echo guards), spawned at the player's own
-- cell-local position and pressed onto the player immediately.
function JediParkAct4:spawnKunBatch(pPlayer, batch)
	local K = JtpConfig.act4.kun
	local mobs = {}

	if (batch == 1) then
		mobs = {
			{ "force_sensitive_crypt_crawler", -3, 0, 3, 0 },
			{ "force_sensitive_crypt_crawler", 3, 0, 3, 0 },
			{ "force_sensitive_crypt_crawler", 0, 0, 5, 0 },
		}
	else
		local remnant = { K.remnantTemplate, 0, 0, 5, 0, K.remnantName }
		mobs = {
			{ "force_trained_archaist", -3, 0, 3, 0 },
			{ "force_trained_archaist", 3, 0, 3, 0 },
			remnant,
		}
	end

	local tag = "act4_kun1"

	if (batch == 2) then
		tag = "act4_kun2"
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = K.planet, cell = K.cell,
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY(),
		mobs = mobs,
		lifetimeSec = 600,
		tag = tag,
	})

	if (built == nil or #built.mobs == 0) then
		self:resetKun(pPlayer, "The working stumbles — the echo's defenders never came. Begin again.")
		return
	end

	dataSet(pPlayer, "act4_kun_left", #built.mobs)
	self:attachKillObserver(pPlayer)

	for i = 1, #built.mobs, 1 do
		AiAgent(built.mobs[i]):setDefender(pPlayer)
	end

	if (batch == 2) then
		CreatureObject(pPlayer):sendSystemMessage("The temple's last keepers come — and with them something that remembers being worshipped.")
	end
end

function JediParkAct4:kunBatchTwoEvent(pPlayer, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (tostring(dataNum(pPlayer, "act4_kun_token")) ~= tostring(args)) then
		return -- stale timer from an earlier working
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_stage") ~= 2) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act4.kun.cell) then
		self:resetKun(pPlayer, "The sealing falters — the old words need you INSIDE the deep cell. The echo re-gathers; begin again when you can hold the ground.")
		return
	end

	self:spawnKunBatch(pPlayer, 2)
end

-- The timed-presence seal chain (steps 2 and 3, 6s apart, in-cell enforced).
function JediParkAct4:kunSealEvent(pPlayer, args)
	if (pPlayer == nil or args == nil or not JediParkManager.enabled()) then
		return
	end

	local token, step = string.match(args, "^(%d+):(%d+)$")

	if (token == nil) then
		return
	end

	if (tostring(dataNum(pPlayer, "act4_kun_token")) ~= token) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_stage") ~= 3) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act4.kun.cell) then
		self:resetKun(pPlayer, "The sealing falters — the old words need you INSIDE the deep cell. The echo re-gathers; begin again when you can hold the ground.")
		return
	end

	local K = JtpConfig.act4.kun

	if (tonumber(step) == 2) then
		self:sui(pPlayer, FLAVOR[1].q5, "You keep speaking. The old words do not argue with the murmur; they simply take the room back, stone by stone. The murmur climbs, pleads, offers — power, mostly, and one very specific future in which nobody you love burns.")
		createEvent(K.sealStepMs, "JediParkAct4", "kunSealEvent", pPlayer, token .. ":3")
	else
		dataSet(pPlayer, "act4_kun_stage", 4)
		dataSet(pPlayer, "act4_kun_done", 1)
		dataSet(pPlayer, "act4_kun_sealed", 1)
		JtpTheaters:teardown(pPlayer, "act4_kun1")
		JtpTheaters:teardown(pPlayer, "act4_kun2")
		self:sui(pPlayer, FLAVOR[1].q5 .. " — Silence", "The bell finishes. The cell is only a cell — cold, wet, and astonishingly empty. Whatever remains of Exar Kun remains somewhere smaller now. The Rebels upstairs will never know what slept under their bunks, which is the only kind of victory this war pays out.")
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": the echo is sealed. Return to Serenna Vale.")
	end
end

function JediParkAct4:resetKun(pPlayer, message)
	JtpTheaters:teardown(pPlayer, "act4_kun1")
	JtpTheaters:teardown(pPlayer, "act4_kun2")
	dataSet(pPlayer, "act4_kun_stage", 0)
	dataSet(pPlayer, "act4_kun_left", 0)

	if (message ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end
end

function JediParkAct4:riteCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_done") == 1) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act4.kun.cell) then
		CreatureObject(pPlayer):sendSystemMessage("The murmur wants you standing inside the deep cell itself.")
		return
	end

	local K = JtpConfig.act4.kun

	JtpTheaters:apparition(pPlayer, {
		planet = K.planet, cell = K.cell,
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY() + 4,
		template = K.echoTemplate,
		name = K.echoName,
		heading = 180,
		glow = "dark",
		lifetimeSec = 60,
		invulnerable = true,
		onAppear = { screenplay = "JediParkAct4", fn = "onEchoAppears" },
		tag = "act4_echo",
	})

	return
end

function JediParkAct4:onEchoAppears(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 5) or M:hasDone(pPlayer, 4, 5) or dataNum(pPlayer, "act4_kun_done") == 1) then
		return
	end

	dataSet(pPlayer, "act4_kun_done", 1)
	dataSet(pPlayer, "act4_kun_communed", 1)
	self:sui(pPlayer, FLAVOR[2].q5, "The Echo of Exar Kun does not appear so much as ADMIT it was always standing there — a figure the torchlight declines to argue with. It speaks one sentence in a dead tongue, and you understand it anyway: \"AN OATH IS A BLADE THAT REMEMBERS ITS FIRST HAND.\" You will hear that sentence again, later, in a room where oaths are taken. Leave now, while it still wants you.")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q5 .. ": the communion is done. Return to the Hand's Voice.")
end

-- ---- Q4.6L: the Well Watch (startWaves — WORLD site) -------------------------

function JediParkAct4:onEnterWellSite(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 4, 6) or M:hasDone(pPlayer, 4, 6) or dataNum(pPlayer, "act4_well_state") == 2) then
		return 0
	end

	local active = JtpTheaters:waveStatus(pPlayer, "act4_well")

	if (active) then
		return 0
	end

	local sui = SuiListBox.new("JediParkAct4", "wellStartCallback")
	sui.setTitle(FLAVOR[1].q6)
	sui.setPrompt("The Rori well is quiet the way a held breath is quiet. Out past the mist line, lights that are not torches are pretending to be torches. The Prophets are early. So are you — the only part of tonight the Circle planned.")
	sui.add("Stand the watch. (Begin the defense — 3 waves)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)

	return 0
end

function JediParkAct4:wellStartCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 4, 6) or M:hasDone(pPlayer, 4, 6) or dataNum(pPlayer, "act4_well_state") == 2) then
		return
	end

	local W = JtpConfig.act4.well
	local site = JTP_ACT4_WELL or { x = W.x, y = W.y }

	local started = JtpTheaters:startWaves(pPlayer, {
		planet = W.planet, x = site.x, z = 0, y = site.y,
		waves = W.waves,
		tag = "act4_well",
		abortSec = W.abortSec,
		ringMin = 16, ringMax = 40,
		onComplete = { screenplay = "JediParkAct4", fn = "onWellHeld" },
	})

	if (started) then
		CreatureObject(pPlayer):sendSystemMessage("The Well Watch: the false torches go out. The first wave comes out of the mist.")
	end
end

function JediParkAct4:onWellHeld(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 6) or M:hasDone(pPlayer, 4, 6)) then
		return
	end

	dataSet(pPlayer, "act4_well_state", 2)
	CreatureObject(pPlayer):sendSystemMessage("The Well Watch: the third wave breaks and does not re-form. The well is still a well. Return to Serenna Vale.")
end

-- ---- Q4.6D: the Courier Road (ambush theater) --------------------------------

function JediParkAct4:onEnterCourierRoad(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 4, 6) or M:hasDone(pPlayer, 4, 6) or dataNum(pPlayer, "act4_courier_done") == 1) then
		return 0
	end

	if (self:liveCount(pPlayer, "act4_courier") > 0) then
		return 0
	end

	local CO = JtpConfig.act4.courier
	local courier = { CO.courierTemplate, 0, 0, 0, 0, CO.courierName }
	courier.invuln = true
	local mobs = { courier }

	for i = 1, #CO.guards, 1 do
		local g = CO.guards[i]
		mobs[#mobs + 1] = { g[1], g[2], 0, g[3], 0, CO.guardName }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = CO.planet, x = CO.x, z = 0, y = CO.y,
		mobs = mobs,
		lifetimeSec = CO.lifeSec,
		tag = "act4_courier",
	})

	if (built == nil or built.mobs[1] == nil) then
		return 0
	end

	dataSet(pPlayer, "act4_courier_oid", tostring(SceneObject(built.mobs[1]):getObjectID()))
	dataSet(pPlayer, "act4_courier_left", #built.mobs - 1)
	dataSet(pPlayer, "act4_courier_ready", 0)
	SceneObject(built.mobs[1]):setObjectMenuComponent("JtpAct4CourierMenuComponent")
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Down the road: a Circle courier under four watchful shadows, walking the census route YOU annotated. The zealots have not seen you. Arithmetic favors the patient.")

	return 0
end

JtpAct4CourierMenuComponent = {}

function JtpAct4CourierMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpAct4CourierMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local A = JediParkAct4

	if (not JtpTheaters:isTheaterMob(pPlayer, "act4_courier", pSceneObject)) then
		CreatureObject(pPlayer):sendSystemMessage("The courier does not answer to you.")
		return 0
	end

	if (not A:gateOk(pPlayer) or not M:hasStarted(pPlayer, 4, 6) or M:hasDone(pPlayer, 4, 6)) then
		return 0
	end

	if (dataNum(pPlayer, "act4_courier_done") == 1) then
		return 0
	end

	if (dataNum(pPlayer, "act4_courier_left") > 0) then
		CreatureObject(pPlayer):sendSystemMessage("The zealot guard still stands between you and the courier.")
		return 0
	end

	dataSet(pPlayer, "act4_courier_done", 1)
	JtpTheaters:teardown(pPlayer, "act4_courier")
	A:sui(pPlayer, FLAVOR[2].q6, "The courier surrenders the satchel and, after one look at the ground where the guards stopped being an argument, agrees to walk. The Voice wanted the courier, not the letters — although the Voice will, of course, read the letters.")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q6 .. ": the courier is taken. Return to the Hand's Voice.")

	return 0
end

-- ---- Q4.7L: BOSS "The Inquisitor's Face" -------------------------------------
-- Talk-then-fight: Vheress and her adepts stage invulnerable, the recruitment
-- SUI plays, and only the player's answer wakes the blades. cellID ~= 0 =
-- verified Jinda objective cell 3; cellID == 0 = world fallback by the mouth.

function JediParkAct4:stageBossLight(pPlayer, cellID)
	local M = JediParkManager

	if (dataNum(pPlayer, "act4_boss_dead") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act4_boss") > 0) then
		if (dataNum(pPlayer, "act4_boss_engaged") == 0) then
			self:offerRecruitment(pPlayer)
		end

		return
	end

	local B = JtpConfig.act4.bossLight
	local J = JtpConfig.act4.jinda
	local spec = { planet = J.planet, tag = "act4_boss", lifetimeSec = B.lifeSec }

	if (cellID ~= nil and cellID ~= 0) then
		spec.cell = cellID
		spec.x = SceneObject(pPlayer):getPositionX()
		spec.z = SceneObject(pPlayer):getPositionZ()
		spec.y = SceneObject(pPlayer):getPositionY()
	else
		spec.cell = 0
		spec.x = B.fallback.x
		spec.z = 0
		spec.y = B.fallback.y
	end

	local vheress = { B.template, 0, 0, 6, 180, B.name }
	vheress.invuln = true
	spec.mobs = { vheress }

	for i = 1, #B.adds, 1 do
		local a = B.adds[i]
		local add = { a[1], a[2], 0, 6 + a[3], 180 }
		add.invuln = true
		spec.mobs[#spec.mobs + 1] = add
	end

	local built = JtpTheaters:build(pPlayer, spec)

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	dataSet(pPlayer, "act4_boss_oid", tostring(SceneObject(built.mobs[1]):getObjectID()))
	dataSet(pPlayer, "act4_boss_engaged", 0)
	self:attachKillObserver(pPlayer)
	self:offerRecruitment(pPlayer)
end

function JediParkAct4:offerRecruitment(pPlayer)
	local sui = SuiListBox.new("JediParkAct4", "bossOfferCallback")
	sui.setTitle(FLAVOR[1].q7)
	sui.setPrompt("Torchlight, root-smoke, and a woman in the Emperor's black standing exactly where your war has been leading. \"Adjunct Vheress. Inquisitor, now — you kept making my reports interesting.\" She does not draw. \"You stood in the Dantooine rubble and felt watched; that was me, filing in your favor. You declared yourself in a dead temple; I filed that too. Everything you have walked, I have graded. So hear the last offer, once: a ledger holds two kinds of names — the written, and the writing hand. Take my hand, and write.\"")
	sui.add("Take her hand.", "")
	sui.add("\"The Circle carries names OUT of ledgers.\" (Refuse)", "")
	sui.sendTo(pPlayer)
end

function JediParkAct4:bossOfferCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0 or idx > 1) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 4, 7) or M:hasDone(pPlayer, 4, 7) or dataNum(pPlayer, "act4_boss_dead") == 1) then
		return
	end

	if (dataNum(pPlayer, "act4_boss_engaged") == 1 or self:liveCount(pPlayer, "act4_boss") == 0) then
		return
	end

	dataSet(pPlayer, "act4_boss_engaged", 1)

	if (idx == 0) then
		self:sui(pPlayer, FLAVOR[1].q7, "Her smile is the professional kind. \"No. You would say yes today and unsay it by winter — I graded you, remember. The offer was the test. The test is over.\" The blade wakes red.")
	else
		self:sui(pPlayer, FLAVOR[1].q7, "\"Serenna's line. She stole it from a better teacher.\" The blade wakes red. \"For the record: I argued for recruiting you. The record will show I corrected the error myself.\"")
	end

	local oids = JtpTheaters:getOids(pPlayer, "act4_boss")

	for i = 1, #oids, 1 do
		local pMob = getSceneObject(oids[i])

		if (pMob ~= nil and SceneObject(pMob):isCreatureObject() and not CreatureObject(pMob):isDead()) then
			CreatureObject(pMob):setPvpStatusBitmask(ATTACKABLE)
			AiAgent(pMob):setDefender(pPlayer)
		end
	end

	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q7 .. ": Vheress moves first. She always has.")
end

-- ---- Q4.7D: BOSS "The Elder's Knee" (stronghold-EXTERIOR; straight kill) -----

function JediParkAct4:onEnterElderSite(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 4, 7) or M:hasDone(pPlayer, 4, 7) or dataNum(pPlayer, "act4_boss_dead") == 1) then
		return 0
	end

	if (self:liveCount(pPlayer, "act4_boss") > 0) then
		return 0
	end

	local B = JtpConfig.act4.bossDark
	local mobs = { { B.template, 0, 0, 10, 180, B.name } }

	for i = 1, #B.adds, 1 do
		local a = B.adds[i]
		mobs[#mobs + 1] = { a[1], a[2], 0, 10 + a[3], 180 }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = B.planet, x = B.x, z = 0, y = B.y,
		mobs = mobs,
		lifetimeSec = B.lifeSec,
		tag = "act4_boss",
	})

	if (built == nil or built.mobs[1] == nil) then
		return 0
	end

	dataSet(pPlayer, "act4_boss_oid", tostring(SceneObject(built.mobs[1]):getObjectID()))
	dataSet(pPlayer, "act4_boss_engaged", 1)
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("From the stones above the wild camp, a voice like torn cloth: \"The Hand's pet, come to collect a knee. Tell your Voice — the Mountain's sisters bend. I do not.\" The elder descends, and her spiders with her.")

	return 0
end

-- Post-fight janitor (leftover adds, staged props). Delayed so corpses and
-- closing dialog land before the scene sweeps itself.
function JediParkAct4:bossCleanupEvent(pPlayer, args)
	if (pPlayer == nil) then
		return
	end

	JtpTheaters:teardown(pPlayer, "act4_boss")
end

-- ---- Q4.S1: the letter shrines -----------------------------------------------

function JediParkAct4:onEnterLetterShrine(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 4, 8) or M:hasDone(pPlayer, 4, 8)) then
		return 0
	end

	local idx = readData(SceneObject(pArea):getObjectID() .. ":jtpAct4Letter")

	if (idx == nil or idx == 0) then
		return 0
	end

	if (dataNum(pPlayer, "act4_letters_" .. idx) == 1) then
		return 0
	end

	dataSet(pPlayer, "act4_letters_" .. idx, 1)

	local side = M:sideOf(pPlayer)
	local n = dataNum(pPlayer, "act4_letters_1") + dataNum(pPlayer, "act4_letters_2") + dataNum(pPlayer, "act4_letters_3")

	if (n < 3) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q8 .. ": " .. n .. " of 3 wells lettered. The old stones take the paper the way a hand takes a hand.")
		return 0
	end

	-- Third delivery: the dark line's bait springs on the carrier (escapable
	-- by design — the credit is already yours; run or fight, nothing drops
	-- that matters, and the ambush sweeps itself in two minutes).
	if (side == 2) then
		local CO = JtpConfig.act4.courier
		local built = JtpTheaters:build(pPlayer, {
			planet = SceneObject(pPlayer):getZoneName(),
			x = SceneObject(pPlayer):getWorldPositionX(),
			z = 0,
			y = SceneObject(pPlayer):getWorldPositionY(),
			mobs = {
				{ "fbase_rebel_guardsman_hard", -12, 0, 10, 0, CO.guardName },
				{ "fbase_rebel_guardsman_hard", 12, 0, 10, 0, CO.guardName },
			},
			lifetimeSec = 120,
			tag = "act4_s1amb",
		})

		if (built ~= nil) then
			for i = 1, #built.mobs, 1 do
				AiAgent(built.mobs[i]):setDefender(pPlayer)
			end

			CreatureObject(pPlayer):sendSystemMessage("The third letter was read before you set it down — the bait cut both ways. Zealots break from the tree line. You owe them nothing; the paper has already done its work.")
		end
	end

	self:completeQuest(pPlayer, 8)
	dataSet(pPlayer, "act4_s1_holo_due", 1)
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q8 .. ": all three wells lettered. Return to " .. FLAVOR[side].giver .. " for the archivist's due.")

	return 0
end

-- ---- Q4.S2L: "Warn the Mountain" (convo beat — spawns NOTHING at the SMC) ----

function JediParkAct4:onEnterMountainApproach(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 4, 9) or M:hasDone(pPlayer, 4, 9) or dataNum(pPlayer, "act4_veshaan_warned") == 1) then
		return 0
	end

	dataSet(pPlayer, "act4_veshaan_warned", 1)
	JediParkManager:adjustVisibility(pPlayer, JtpConfig.act4.visWarn)
	self:completeQuest(pPlayer, 9)
	self:sui(pPlayer, FLAVOR[1].q9, "You come up the mountain road the quiet way, and Veshaan is at the porch-line before you see her arrive — she always is. She reads the warning off your face before you finish it. \"The Inquisitor's files. Our name in them.\" A long look down the valley, the way weather looks at a roof. \"Then the Mountain owes you a fire it will not have to survive. The daughters will scatter the pattern tonight; the wells we watch will watch back. Go quietly, little ember. We remember our debts LOUDLY.\" She is gone before the wind finishes.")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q9 .. ": Veshaan is warned. The Mountain prepares. (Your visibility fades.)")

	return 0
end

-- ---- Q4.S2D: "The Sealed Testament" (courier-cache theater) ------------------

function JediParkAct4:onEnterTestamentCache(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 4, 9) or M:hasDone(pPlayer, 4, 9) or dataNum(pPlayer, "act4_testament") == 1) then
		return 0
	end

	if (self:liveCount(pPlayer, "act4_testa") > 0) then
		return 0
	end

	local CA = JtpConfig.act4.cache
	local mobs = {}

	for i = 1, #CA.guards, 1 do
		local g = CA.guards[i]
		mobs[#mobs + 1] = { g[1], g[2], 0, g[3], 0, CA.guardName }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = CA.planet, x = CA.x, z = 0, y = CA.y,
		props = { { CA.prop, 0, 0, 0 } },
		mobs = mobs,
		lifetimeSec = CA.lifeSec,
		tag = "act4_testa",
	})

	if (built == nil or built.props[1] == nil) then
		return 0
	end

	dataSet(pPlayer, "act4_testa_left", #built.mobs)
	SceneObject(built.props[1]):setObjectMenuComponent("JtpAct4CacheMenuComponent")
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("A red-lit cache-stone off the road shoulder, and a zealot guard that believes in it. The Testament is under the stone. The guard is the argument.")

	return 0
end

JtpAct4CacheMenuComponent = {}

function JtpAct4CacheMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpAct4CacheMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local A = JediParkAct4

	if (not JtpTheaters:isTheaterMob(pPlayer, "act4_testa", pSceneObject)) then
		CreatureObject(pPlayer):sendSystemMessage("The stone is warm, and red, and keeps somebody else's counsel.")
		return 0
	end

	if (not A:gateOk(pPlayer) or not M:hasStarted(pPlayer, 4, 9) or M:hasDone(pPlayer, 4, 9)) then
		return 0
	end

	if (dataNum(pPlayer, "act4_testa_left") > 0) then
		CreatureObject(pPlayer):sendSystemMessage("The zealot guard still stands. The stone can wait; the guard should not.")
		return 0
	end

	if (dataNum(pPlayer, "act4_testament") == 1) then
		return 0
	end

	local C = JtpConfig.act4
	local pItem = M:giveNamedItem(pPlayer, C.items.testament, C.items.testamentName)

	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and search the cache again.")
		return 0
	end

	dataSet(pPlayer, "act4_testament", 1)
	A:completeQuest(pPlayer, 9)
	JtpTheaters:teardown(pPlayer, "act4_testa")
	A:sui(pPlayer, FLAVOR[2].q9, "Under the cache-stone: a holocron older than the Circle's name for itself, sealed in wax the color of old blood. It is very heavy for its size. You do not open it. That is the entire job — and somewhere, a Voice that already knew you would not is filing the fact anyway.")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q9 .. ": the Testament is taken, unopened. The Voice's errand is done.")

	return 0
end

-- ---- the shared kill observer ------------------------------------------------

function JediParkAct4:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct4", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct4", "onKill", pPlayer, 1)
end

function JediParkAct4:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	-- Grace-floor hold: while paused, nothing advances and nothing is lost.
	if (not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager
	local C = JtpConfig.act4
	local victimID = tostring(SceneObject(pVictim):getObjectID())

	-- Q4.2: ritualist kills — zone + radius filter around the Jinda cave.
	if (M:hasStarted(pPlayer, 4, 2) and not M:hasDone(pPlayer, 4, 2)) then
		local J = C.jinda

		if (SceneObject(pPlayer):getZoneName() == J.planet and dataNum(pPlayer, "act4_jinda_kills") < J.kills) then
			local dx = SceneObject(pVictim):getWorldPositionX() - J.x
			local dy = SceneObject(pVictim):getWorldPositionY() - J.y

			if ((dx * dx + dy * dy) <= (J.killRadius * J.killRadius)) then
				local kills = dataNum(pPlayer, "act4_jinda_kills") + 1
				dataSet(pPlayer, "act4_jinda_kills", kills)

				if (kills >= J.kills) then
					CreatureObject(pPlayer):sendSystemMessage(FLAVOR[M:sideOf(pPlayer)].q2 .. ": the ritual gangs are broken (" .. kills .. " of " .. J.kills .. "). See to the chambers.")
				else
					CreatureObject(pPlayer):sendSystemMessage(FLAVOR[M:sideOf(pPlayer)].q2 .. ": " .. kills .. " of " .. J.kills .. " ritualists.")
				end
			end
		end
	end

	-- Q4.5L: the chained kun-echo batches.
	if (M:hasStarted(pPlayer, 4, 5) and not M:hasDone(pPlayer, 4, 5) and dataNum(pPlayer, "act4_kun_done") == 0) then
		local stage = dataNum(pPlayer, "act4_kun_stage")

		if (stage == 1 and JtpTheaters:isTheaterMob(pPlayer, "act4_kun1", pVictim)) then
			local left = dataNum(pPlayer, "act4_kun_left") - 1
			dataSet(pPlayer, "act4_kun_left", left)

			if (left <= 0) then
				dataSet(pPlayer, "act4_kun_stage", 2)
				self:sui(pPlayer, FLAVOR[1].q5 .. " — the First Silence", "The crawling things fall and the murmur loses its footing. Hold. Speak. The words feel older than the temple that holds them. Under them, something gathers itself for one more argument.")
				createEvent(C.kun.batchDelayMs, "JediParkAct4", "kunBatchTwoEvent", pPlayer, tostring(dataNum(pPlayer, "act4_kun_token")))
			end
		elseif (stage == 2 and JtpTheaters:isTheaterMob(pPlayer, "act4_kun2", pVictim)) then
			local left = dataNum(pPlayer, "act4_kun_left") - 1
			dataSet(pPlayer, "act4_kun_left", left)

			if (left <= 0) then
				dataSet(pPlayer, "act4_kun_stage", 3)
				self:sui(pPlayer, FLAVOR[1].q5, "The last keeper falls, and for one whole breath the deep cell belongs to nobody. Now the words, and nothing but the words — the seal is spoken standing.")
				createEvent(C.kun.sealStepMs, "JediParkAct4", "kunSealEvent", pPlayer, tostring(dataNum(pPlayer, "act4_kun_token")) .. ":2")
			end
		end
	end

	-- Q4.4: the graveyard krayt.
	if (M:hasStarted(pPlayer, 4, 4) and not M:hasDone(pPlayer, 4, 4) and dataNum(pPlayer, "act4_pearl") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act4_krayt", pVictim)) then
			dataSet(pPlayer, "act4_pearl", 1)
			CreatureObject(pPlayer):sendSystemMessage(FLAVOR[M:sideOf(pPlayer)].q4 .. ": from the canyon krayt's gullet, a pearl the size of a closed fist. Return to " .. FLAVOR[M:sideOf(pPlayer)].giver .. ".")
		end
	end

	-- Q4.6D: the courier's zealot guard.
	if (M:hasStarted(pPlayer, 4, 6) and not M:hasDone(pPlayer, 4, 6) and dataNum(pPlayer, "act4_courier_done") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act4_courier", pVictim) and victimID ~= (readScreenPlayData(pPlayer, "JediPark", "act4_courier_oid") or "")) then
			local left = dataNum(pPlayer, "act4_courier_left") - 1
			dataSet(pPlayer, "act4_courier_left", left)

			if (left <= 0) then
				dataSet(pPlayer, "act4_courier_ready", 1)
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q6 .. ": the last zealot drops. The courier stands very, very still. (Use the radial menu to take the courier.)")
			else
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q6 .. ": " .. left .. " zealot(s) still standing.")
			end
		end
	end

	-- Q4.S2D: the cache guard.
	if (M:hasStarted(pPlayer, 4, 9) and not M:hasDone(pPlayer, 4, 9) and dataNum(pPlayer, "act4_testament") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act4_testa", pVictim)) then
			local left = dataNum(pPlayer, "act4_testa_left") - 1
			dataSet(pPlayer, "act4_testa_left", left)

			if (left <= 0) then
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q9 .. ": the cache stands unguarded. (Use the radial menu on the cache-stone.)")
			end
		end
	end

	-- Q4.7: the boss.
	if (M:hasStarted(pPlayer, 4, 7) and not M:hasDone(pPlayer, 4, 7) and dataNum(pPlayer, "act4_boss_dead") == 0) then
		if (victimID == (readScreenPlayData(pPlayer, "JediPark", "act4_boss_oid") or "") and JtpTheaters:isTheaterMob(pPlayer, "act4_boss", pVictim)) then
			dataSet(pPlayer, "act4_boss_dead", 1)

			if (M:sideOf(pPlayer) == 1) then
				dataSet(pPlayer, "act4_vheress_dead", 1)
				self:sui(pPlayer, FLAVOR[1].q7, "The red blade goes out before she hits the ground, the way a ledger closes. Vheress, at the end, says nothing at all — and somehow that is her first honest report. The Jinda dark takes back its silence. The Silent War just lost its best-funded pen. Return to Serenna Vale.")
			else
				self:sui(pPlayer, FLAVOR[2].q7, "She fights the way weather fights, and falls the way weather falls — without apology. At the end there is no kneeling in her, and you suspect the Voice knew there would not be. The pact is paid in the only coin she carried. Return to the Hand's Voice.")
			end

			createEvent(2500, "JediParkAct4", "bossCleanupEvent", pPlayer, "")
		end
	end

	return 0
end

-- ---- rewards, act finale, shared helpers -------------------------------------

function JediParkAct4:completeQuest(pPlayer, quest, frsOverride)
	local C = JtpConfig.act4
	JediParkManager:setDone(pPlayer, 4, quest)
	JediParkManager:giveCredits(pPlayer, C.creditsPerQuest)
	JediParkManager:awardFrsXp(pPlayer, frsOverride or C.frsPerQuest)
end

function JediParkAct4:reward(pPlayer)
	local C = JtpConfig.act4
	JediParkManager:giveCredits(pPlayer, C.creditsPerQuest)
	JediParkManager:awardFrsXp(pPlayer, C.frsPerQuest)
end

-- The act finale: boss turn-in — 10k FRS, ceremony token, crystal roll,
-- robe s03, JediPark bit 128, badge 143 placeholder.
function JediParkAct4:finishAct(pPlayer, side)
	local M = JediParkManager
	local C = JtpConfig.act4
	local F = FLAVOR[side]

	self:completeQuest(pPlayer, 7, C.frsBoss)
	M:giveLootGroup(pPlayer, C.lootGroups.colorCrystal)

	if (side == 1) then
		M:giveNamedItem(pPlayer, C.items.token, C.items.tokenLightName)
		M:giveNamedItem(pPlayer, C.items.robeLight, nil)
	else
		M:giveNamedItem(pPlayer, C.items.token, C.items.tokenDarkName)
		M:giveNamedItem(pPlayer, C.items.robeDark, nil)
	end

	M:setGlobal(pPlayer, 128)
	CreatureObject(pPlayer):sendSystemMessage("Act complete: " .. F.actName .. ". (Badge 'The Silent War' arrives with the client update.)")

	if (side == 1) then
		self:sui(pPlayer, F.actName, "Serenna stands over the map a long time before she pulls the first pin. \"The Inquisitor is dead and the Circle still exists. Those two facts will spend the rest of the war arguing about which one caused the other.\" She sets a crystal in your palm — sea-deep, steady. \"Kenobi's Legacy. He taught that the fight is for the people who never learn it happened.\" The robe she folds into your arms is the good cloth, unsigned, like everything the Circle does. \"Wear it where nobody knows what it means.\"")
	else
		self:sui(pPlayer, F.actName, "The Voice does not congratulate; the Voice reconciles accounts. \"The elder did not kneel. The Emperor's pact holds anyway — Sereth will be reminded who paid for it.\" A crystal, dark as a held breath: \"Ulic's Redemption. An instructive name: he was redeemed, and it saved nothing he wanted saved. Decide what you want saved BEFORE the redeeming.\" The robe is dark, well-made, and unsigned. \"The gambit is understood. The Hand closes.\"")
	end
end

function JediParkAct4:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct4", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct4:emptyCallback(pPlayer, pSui, eventIndex, args)
end
