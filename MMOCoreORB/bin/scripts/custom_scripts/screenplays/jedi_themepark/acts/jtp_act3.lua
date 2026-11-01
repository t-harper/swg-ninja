-- jtp_act3.lua — Act III: "Knight of Embers" (light) / "Knight of Shadows"
-- (dark) — the park's first split act. ONE mechanical implementation with
-- light/dark flavor tables; side decides giver, sites and words.
-- Quests (bit ledger: started 2^(2n-2) / done 2^(2n-1) in "JediParkAct3"):
--   1  "The Keeper's Ledger" / "The Overseer's Price"   [talk]  — enclave induction (home-cell claim)
--   2  "The Mountain's Answer" / "A Sister's Bargain"   [camp]  — witch-relic camp, deliver to ally
--   3  "Wolves With Writs" / "Wolves Without Writs"     [kill]  — 9-mob shadow camp, loot the paper
--   4  "The Ten Wells"                                  [visit] — 10 lifetime shrines on >=4 planets
--   5  "The Second Siege" / "The Refuge That Wasn't"    [defend/raid] — L waves at Aurilia / D waystation on Talus
--   6  "Pages of the Missing" / "The Census of Sparks"  [collect] — survey camp, steal/annotate the census
--   7  "The Kilnmaster" / "The Zealot's Pyre"           [boss]  — talk-then-fight arena theater
--   8  "Where the Mountain Breathes" / "Die Before You Serve" [rite] — L SMC meditation / D cloning-cell oath
--   9  "Sabers for Small Hands" / "Tribute in Kind"     [side]  — 4 tokens from a tier camp
--   10 "The Long Way Home" (L escort) / "The Taskmaster's Lesson" (D duel) [side]
--
-- Act gate: isKnight + matching journeyman side (L line side 1 / D line
-- side 2) + Act II done (JediPark global bit 8). FRS rank NOT required —
-- a fresh Knight (rank 0) qualifies. A crossed Act II ceremony (intent
-- bit 16/32 against the trained side) gets ONE bridging line at Q3.1 and
-- proceeds on skills-as-truth.
-- Completion (quests 1-8): JediPark global bit 64; badge 142 "Knight
-- Errant" is a placeholder sysmsg until the Phase C client patch.
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- ScreenPlayData namespace "JediPark", keys prefixed act3_. The Act V-D
-- Vader scene reads act3_oath_taken (persistent contract key).
--
-- Machinery: JtpCells (home-cell claims registered at file scope below,
-- copied from the pre-verified seeds in jtp_cells.lua), JtpTheaters
-- (per-player camps/arenas/rite props via build, L siege via startWaves).
-- Cell-local anchors verified against the live pob/ws data:
--   light trainingroom 8525441: cloner revive (22, -24.1, 74), door portal
--     (21.8, -22.5, 51.1) — Maro at (22, -24.1, 63) facing the door;
--   dark arenahall 3435636: corridor x=0, y -43..-60, floor -47.4 (FRS
--     arena teleport z) — Dask at (0, -47.4, -52);
--   dark cloning 3435635: revive (-39, -43, -31), door (-25.5, -41.7,
--     -31.6) — rite staged at (-33, -43, -31);
--   SMC meditation 2665883: stock Zideera at (-14.2, 1.9, -21) — Veshaan
--     at (-7, 1.9, -13.5), rite at the room heart (-10.5, 1.9, -17).
--
-- Integration points the main loop wires at include time: JtpShrines
-- calls JediParkAct3:onShrineVisited beside the act0-2 hooks, and the
-- shared login hook (jtp_observers) calls JediParkAct3:heal beside
-- JediParkAct1:heal.

-- ---- tuning (jtp_config owns nothing act3-specific yet; claim the slot) ------

JtpConfig.act3 = JtpConfig.act3 or {
	creditsPerQuest = 1500,
	frsXpPerQuest = 2000,        -- per plan §6: FRS XP begins in Act III
	frsXpDefend = 3000,          -- Q3.5
	frsXpBoss = 5000,            -- Q3.7

	prevActBit = 8,              -- JediPark global: Act II done

	visLoud = 75,                -- Q3.3 completion (loud step)
	visCensusQuiet = -50,        -- Q3.6 zero-kill bonus
	visPilgrimLight = -100,      -- Q3.4 completion, light line only
	visRiteLight = -150,         -- Q3.8L rite

	pilgrimage = { count = 10, planets = 4 },

	-- Home enclaves (yavin4). Keyed by side (1 light / 2 dark). The heal
	-- circle is the walk-up "the door recognizes you" JtpCells:heal.
	enclaves = {
		[1] = { planet = "yavin4", x = -5514, y = 4912, healRadius = 96,
			giverCell = 8525441,
			giver = { x = 22, z = -24.1, y = 63, heading = 180 } },
		[2] = { planet = "yavin4", x = 5070, y = 310, healRadius = 96,
			giverCell = 3435636,
			giver = { x = 0, z = -47.4, y = -52, heading = 0 },
			cloningCell = 3435635,
			rite = { x = -33, z = -43.0, y = -31 } },
	},

	-- Singing Mountain Clan stronghold (light ally + Q3.8L rite).
	smc = { planet = "dathomir", x = 164, y = 4489, arriveRadius = 40,
		cell = 2665883,
		veshaan = { x = -7.0, z = 1.9, y = -13.5, heading = 150 },
		rite = { x = -10.5, z = 1.9, y = -17 } },

	-- Nightsister stronghold approach (dark ally). EXTERIOR ONLY — the
	-- stronghold interior and its themepark are never touched.
	sereth = { planet = "dathomir", x = -4116, y = -135, heading = 100 },

	-- Per-side wilderness sites (z resolved from terrain at spawn time —
	-- camps only build with the player standing in the site area).
	sites = {
		[1] = { planet = "dathomir",            -- the pilgrim road
			camp2 = { x = -4310, y = -470 },
			camp3 = { x = -3930, y = -540 },
			camp6 = { x = -4180, y = -720 },
			campS1 = { x = -4260, y = -260 },
			arena = { x = 5100, y = -4300 } },
		[2] = { planet = "lok",                 -- the wastes
			camp2 = { x = -2000, y = 1650 },
			camp3 = { x = -1650, y = 1320 },
			camp6 = { x = -1800, y = 1500 },
			campS1 = { x = -1950, y = 1250 },
			arena = { x = -2100, y = 1800 } },
	},
	siteRadius = 64,
	arenaRadius = 32,
	campLifetimeSec = 1800,

	-- Q3.5L — Aurilia second siege (same palisade as Act II's defense; the
	-- z is the village plateau). Solo baseline counts — do not inflate.
	siege = {
		planet = "dathomir", x = 5250, z = 78.5, y = -4100, radius = 48,
		abortSec = 600,
		waves = {
			{ mobs = { { "sith_shadow_thug", 3 } } },
			{ mobs = { { "sith_shadow_mercenary", 4 } } },
			{ mobs = { { "sith_shadow_mercenary", 4 } } },
			{ mobs = { { "sith_shadow_mercenary", 5 }, { "sith_shadow_taskmaster", 1 } } },
		},
	},

	-- Q3.5D — the Talus waystation raid.
	waystation = { planet = "talus", x = -5300, y = 2500, radius = 64, satchels = 3 },

	-- Q3.S2L — the escort (pilgrim road -> SMC approach).
	escort = {
		planet = "dathomir", x = -4100, y = -300,
		template = "villager_force_sensitive_village",
		name = "Issa, a rescued sensitive",
		lapseMs = 45 * 60 * 1000,
		ambushes = {
			{ x = -2680, y = 1296, radius = 250 },
			{ x = -1258, y = 2893, radius = 250 },
		},
		ambushTemplate = "sith_shadow_mercenary",
		ambushCount = 2,
		ambushOffset = 21,
		ambushDespawnMs = 300 * 1000,
	},

	-- Q3.S2D — the arenahall duel (cell-local coords).
	duel = { template = "sith_shadow_taskmaster", name = "Jarratt the Breaker",
		x = 0, z = -47.4, y = -57, heading = 0 },

	-- Camp compositions ({template, dx, dz, dy}); solo baseline.
	camps = {
		camp2 = {
			{ "sith_shadow_taskmaster", 0, 0, 0 },
			{ "sith_shadow_mercenary", -5, 0, 4 },
			{ "sith_shadow_mercenary", 5, 0, -3 },
		},
		camp3 = {
			{ "sith_shadow_thug", -8, 0, 6 }, { "sith_shadow_thug", 8, 0, 6 },
			{ "sith_shadow_thug", 0, 0, -9 },
			{ "sith_shadow_mercenary", -12, 0, -2 }, { "sith_shadow_mercenary", 12, 0, -2 },
			{ "sith_shadow_mercenary", -5, 0, 11 }, { "sith_shadow_mercenary", 5, 0, 11 },
			{ "sith_shadow_taskmaster", 0, 0, 3 },
			{ "sith_shadow_thug_nonaggro", 0, 0, 16 },
		},
		camp6guards = {
			{ "stormtrooper", -8, 0, -4 }, { "stormtrooper", 8, 0, -4 },
			{ "stormtrooper", -8, 0, 8 }, { "stormtrooper", 8, 0, 8 },
		},
		campS1 = {
			{ "sith_shadow_mercenary", -4, 0, 3 }, { "sith_shadow_mercenary", 4, 0, 3 },
			{ "sith_shadow_thug", -6, 0, -4 }, { "sith_shadow_thug", 6, 0, -4 },
		},
	},
	s1TokenCount = 4,

	-- Q3.7 bosses (keyed by side).
	boss = {
		[1] = { template = "dark_adept", name = "the Kilnmaster", adds = 0 },
		[2] = { template = "lesser_prophet_of_the_light_side", name = "the Pyre-Zealot",
			adds = 2, addTemplate = "lesser_prophet_of_the_light_side" },
	},

	-- Q3.5D waystation garrison (prophets + mid-tier rebel guards; the
	-- civilians are untouchable set dressing — era rail: clarity, not
	-- cruelty).
	raid = {
		mobs = {
			{ "lesser_prophet_of_the_light_side", -3, 0, 6 },
			{ "lesser_prophet_of_the_light_side", 3, 0, 6 },
			{ "fbase_rebel_soldier_hard", -10, 0, 0 }, { "fbase_rebel_soldier_hard", 10, 0, 0 },
			{ "fbase_rebel_soldier_hard", 0, 0, 12 }, { "fbase_rebel_soldier_hard", 0, 0, -10 },
		},
		civilians = {
			{ "commoner", -1, 0, -2 }, { "commoner", 2, 0, -4 },
		},
	},

	items = {
		token = "object/tangible/mission/mission_datadisk.iff",
		relicName = "A Witch-Clan Reliquary, Reclaimed",
		writNameLight = "An Imperial Writ of Collection",
		writNameDark = "A Freelancer's Unstamped Ledger",
		caseName = "The Census of Sparks — Sealed Case",
		s1TokenNameLight = "A Training Saber, Recovered",
		s1TokenNameDark = "A Duelist's Trophy",
		ceremonyNameLight = "Windu's Guile — Ember Token",
		ceremonyNameDark = "Kun's Blood — Shadow Token",
		propLight = "object/tangible/jedi/power_shrine.iff",
		propDark = "object/tangible/jedi/power_shrine_red.iff",
	},
	lootGroups = {
		powerCrystal = "power_crystals",
		colorCrystal = "color_crystals",
		holocronLight = "holocron_light",
		holocronDark = "holocron_dark",
	},

	camshakeCef = "clienteffect/int_camshake_heavy.cef",
}

JediParkAct3 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 3,
}

registerScreenPlay("JediParkAct3", true)

-- Reload guard: survives reloadscreenplays; reset only by a full restart.
JTP_ACT3_SPAWNED = JTP_ACT3_SPAWNED or nil

-- ---- home-cell claims (S-CORE-4) ---------------------------------------------
-- Registered at FILE SCOPE so the rules exist before any start() runs.
-- These four are copied verbatim from the pre-verified seeds in
-- jtp_cells.lua (the verified-UNUSED enclave wings; absent from the FRS
-- manager's enclaveRoomRequirements). The enclave cloner revive points
-- land inside these cells, but enclave cloning requires FRS membership
-- (force_rank_<side>_novice) — every legitimate reviver passes the gate.
--
-- DEVIATION: the SMC meditation cell 2665883 is registered mode="allow",
-- NOT "gate" — the live pob/screenplay audit shows the stock SMC
-- themepark giver Zideera spawns IN that cell and it is the only corridor
-- to the stronghold's throne/craft wing. A gate claim would lock the
-- public away from live stock content (violates the plan's verified-
-- unused law and the SMC isolation audit). The allow-mode group keeps the
-- declared claim + heal bookkeeping with zero stock impact.

JtpCells:register({ cellID = 8525441, group = "jtp_lenclave_knight", mode = "gate", -- trainingroom (Keeper Maro)
	conditions = {
		{ permissionType = "isKnight" },
		{ permissionType = "side", side = 1 },
	} })

JtpCells:register({ cellID = 8525440, group = "jtp_lenclave_knight", mode = "gate", -- traininghall (approach + Act VI-L rite)
	conditions = {
		{ permissionType = "isKnight" },
		{ permissionType = "side", side = 1 },
	} })

JtpCells:register({ cellID = 3435636, group = "jtp_denclave_knight", mode = "gate", -- arenahall (Overseer Dask)
	conditions = {
		{ permissionType = "isKnight" },
		{ permissionType = "side", side = 2 },
	} })

JtpCells:register({ cellID = 3435635, group = "jtp_denclave_knight", mode = "gate", -- cloning (Q3.8D rite)
	conditions = {
		{ permissionType = "isKnight" },
		{ permissionType = "side", side = 2 },
	} })

JtpCells:register({ cellID = 2665883, group = "jtp_smc_meditation", mode = "allow", -- SMC meditation (shared with stock Zideera — see DEVIATION note)
	conditions = {
		{ permissionType = "isKnight" },
		{ permissionType = "side", side = 1 },
	} })

-- ---- boot spawns -------------------------------------------------------------

function JediParkAct3:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT3_SPAWNED ~= nil) then
		print("jtp: act3 already spawned (reload) — skipping spawns")
		print("jtp: act3 'Knight of Embers / Knight of Shadows' loaded")
		return
	end

	JTP_ACT3_SPAWNED = {}
	local C = JtpConfig.act3

	-- Enclave givers + door-recognition circles + the dark rite trigger.
	if (isZoneEnabled("yavin4")) then
		local L = C.enclaves[1]
		local pMaro = spawnMobile(L.planet, "jtp_maro", 0, L.giver.x, L.giver.z, L.giver.y, L.giver.heading, L.giverCell)

		if (pMaro ~= nil) then
			table.insert(JTP_ACT3_SPAWNED, SceneObject(pMaro):getObjectID())
			print("jtp: act3 Keeper Maro posted (light enclave trainingroom)")
		else
			print("jtp: WARNING — act3 Maro spawn failed")
		end

		local D = C.enclaves[2]
		local pDask = spawnMobile(D.planet, "jtp_dask", 0, D.giver.x, D.giver.z, D.giver.y, D.giver.heading, D.giverCell)

		if (pDask ~= nil) then
			table.insert(JTP_ACT3_SPAWNED, SceneObject(pDask):getObjectID())
			print("jtp: act3 Overseer Dask posted (dark enclave arenahall)")
		else
			print("jtp: WARNING — act3 Dask spawn failed")
		end

		-- Walk-up self-heal circles: a qualifying knight gets the home-cell
		-- permission group at the door instead of waiting for a relog.
		self:addArea(L.planet, L.x, getWorldFloor(L.x, L.y, L.planet) or 0, L.y, L.healRadius, 0, "heal", 0)
		self:addArea(D.planet, D.x, getWorldFloor(D.x, D.y, D.planet) or 0, D.y, D.healRadius, 0, "heal", 0)

		-- Q3.8D trigger: world circle on the dark enclave + cloning-cell filter.
		self:addArea(D.planet, D.x, 0, D.y, 128, D.cloningCell, "ritedark", 2)
	end

	-- Dathomir: Veshaan (SMC), Sereth (NS approach, exterior only), the
	-- light-line sites, the siege trigger, the escort machinery.
	if (isZoneEnabled("dathomir")) then
		local s = C.smc
		local pVeshaan = spawnMobile(s.planet, "jtp_veshaan", 0, s.veshaan.x, s.veshaan.z, s.veshaan.y, s.veshaan.heading, s.cell)

		if (pVeshaan ~= nil) then
			table.insert(JTP_ACT3_SPAWNED, SceneObject(pVeshaan):getObjectID())
			print("jtp: act3 Sister Veshaan posted (SMC meditation cell)")
		else
			print("jtp: WARNING — act3 Veshaan spawn failed")
		end

		local n = C.sereth
		local nz = getWorldFloor(n.x, n.y, n.planet) or 0
		local pSereth = spawnMobile(n.planet, "jtp_sereth", 0, n.x, nz, n.y, n.heading, 0)

		if (pSereth ~= nil) then
			table.insert(JTP_ACT3_SPAWNED, SceneObject(pSereth):getObjectID())
			print("jtp: act3 Envoy Sereth posted (Nightsister approach, exterior)")
		else
			print("jtp: WARNING — act3 Sereth spawn failed")
		end

		self:addSiteAreas(1)

		local g = C.siege
		self:addArea(g.planet, g.x, g.z, g.y, g.radius, 0, "siege", 1)

		self:addArea(s.planet, s.x, getWorldFloor(s.x, s.y, s.planet) or 0, s.y, s.arriveRadius, 0, "smcarrive", 1)

		for i = 1, #C.escort.ambushes, 1 do
			local a = C.escort.ambushes[i]
			self:addArea(C.escort.planet, a.x, getWorldFloor(a.x, a.y, C.escort.planet) or 0, a.y, a.radius, 0, "amb" .. i, 1)
		end
	end

	-- Lok: the dark-line sites.
	if (isZoneEnabled("lok")) then
		self:addSiteAreas(2)
	end

	-- Talus: the waystation raid site.
	if (isZoneEnabled("talus")) then
		local w = C.waystation
		self:addArea(w.planet, w.x, getWorldFloor(w.x, w.y, w.planet) or 0, w.y, w.radius, 0, "waystation", 2)
	end

	print("jtp: act3 'Knight of Embers / Knight of Shadows' loaded")
end

function JediParkAct3:addSiteAreas(side)
	local C = JtpConfig.act3
	local S = C.sites[side]

	local plots = {
		{ S.camp2, C.siteRadius, "camp2" },
		{ S.camp3, C.siteRadius, "camp3" },
		{ S.camp6, C.siteRadius, "camp6" },
		{ S.campS1, C.siteRadius, "camps1" },
		{ S.arena, C.arenaRadius, "arena" },
	}

	for i = 1, #plots, 1 do
		local p = plots[i]
		self:addArea(S.planet, p[1].x, getWorldFloor(p[1].x, p[1].y, S.planet) or 0, p[1].y, p[2], 0, p[3], side)
	end
end

function JediParkAct3:addArea(planet, x, z, y, radius, cellFilter, kind, side)
	local pArea = spawnActiveArea(planet, "object/active_area.iff", x, z, y, radius, cellFilter)

	if (pArea == nil) then
		print("jtp: WARNING — act3 area '" .. kind .. "' spawn failed on " .. planet)
		return nil
	end

	local areaID = SceneObject(pArea):getObjectID()
	writeStringData(areaID .. ":jtpAct3Kind", kind)
	writeData(areaID .. ":jtpAct3Side", side or 0)
	createObserver(ENTEREDAREA, "JediParkAct3", "onEnterSite", pArea)
	table.insert(JTP_ACT3_SPAWNED, areaID)

	return pArea
end

-- ---- gate --------------------------------------------------------------------

-- side: 1 = light line, 2 = dark line.
function JediParkAct3:meetsActGate(pPlayer, side)
	local M = JediParkManager

	return M:isJedi(pPlayer)
		and M:isKnight(pPlayer)
		and M:sideOf(pPlayer) == side
		and M:hasGlobal(pPlayer, JtpConfig.act3.prevActBit)
end

-- Crossed Act II intent: declared one church, trained the other.
function JediParkAct3:crossedIntent(pPlayer, side)
	local M = JediParkManager

	if (side == 1) then
		return M:hasGlobal(pPlayer, 32)
	end

	return M:hasGlobal(pPlayer, 16)
end

-- ---- data helpers ------------------------------------------------------------

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

local campTags = { [2] = "q32_camp", [3] = "q33_camp", [6] = "q36_camp", [9] = "q3s1_camp" }

function JediParkAct3:planetsWalked(pPlayer)
	local n = 0

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		if (JtpShrines:countVisitedOnPlanet(pPlayer, JtpConfig.shrinePlanets[p]) > 0) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct3:pilgrimageMet(pPlayer)
	local pg = JtpConfig.act3.pilgrimage

	return JtpShrines:countVisited(pPlayer) >= pg.count and self:planetsWalked(pPlayer) >= pg.planets
end

-- True while any object of the tag's scene still stands (corpses do not
-- count — a cleared-but-unlooted camp must not rebuild over its dead).
function JediParkAct3:anyLive(pPlayer, tag)
	local oids = JtpTheaters:getOids(pPlayer, tag)

	for i = 1, #oids, 1 do
		local pObj = getSceneObject(oids[i])

		if (pObj ~= nil) then
			if (not SceneObject(pObj):isCreatureObject()) then
				return true
			end

			if (not CreatureObject(pObj):isDead()) then
				return true
			end
		end
	end

	return false
end

-- ---- giver conversation routers ----------------------------------------------
-- Called by the convo handlers on every talk; every screen re-evaluates
-- the gate live (global AC 1). The enclave cells already keep the wrong
-- side out god-off; these refusals cover admins, allow-mode visitors and
-- the stale-permission edge.

function JediParkAct3:onMaroTalk(pPlayer)
	self:onGiverTalk(pPlayer, 1)
end

function JediParkAct3:onDaskTalk(pPlayer)
	self:onGiverTalk(pPlayer, 2)
end

function JediParkAct3:onGiverTalk(pPlayer, side)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		if (side == 1) then
			self:sui(pPlayer, "Keeper Maro", "The old man studies a ledger page and does not look up. Whatever this hall is for, it is not for you, and both of you know it.")
		else
			self:sui(pPlayer, "Overseer Dask", "The man watches the arena door past your shoulder, as if expecting someone worth watching for. It is not you.")
		end
		return
	end

	if (M:sideOf(pPlayer) ~= side) then
		if (side == 1) then
			self:sui(pPlayer, "Keeper Maro", "The Keeper does not look up. \"This hall buried its dead under light. Your steps carry a different weight — and the hall hears steps before it hears words. Wherever the dark keeps its ledgers, it is not here. Go and be kept.\"")
		else
			self:sui(pPlayer, "Overseer Dask", "\"Wrong hall, ember.\" Dask's smile has no warmth in it. \"The Overseer trains instruments, not lanterns. Wherever the light hides its halls, it is not here — walk out while walking is free.\"")
		end
		return
	end

	if (not M:isKnight(pPlayer)) then
		if (side == 1) then
			self:sui(pPlayer, "Keeper Maro", "\"Names go into this ledger at a knight's rank or not at all.\" He closes the book with a bookkeeper's finality. \"Finish the trials. The hall will still be hidden when you are worth hiding.\" (Requires: Jedi Knight.)")
		else
			self:sui(pPlayer, "Overseer Dask", "\"The arena bets on knights. You are a wager nobody at this rail would take — yet.\" He turns back to the sand. \"Come back ranked.\" (Requires: Jedi Knight.)")
		end
		return
	end

	if (not M:hasGlobal(pPlayer, JtpConfig.act3.prevActBit)) then
		if (side == 1) then
			self:sui(pPlayer, "Keeper Maro", "\"The Massassi hall remembers who declared and who only visited. Your parting of ways is unfinished business.\" (Complete Act II: The Parting of Ways — the emissaries wait in the Great Massassi Temple warroom.)")
		else
			self:sui(pPlayer, "Overseer Dask", "\"No record of your declaration reached this ledger. The temple ceremony is not optional paperwork — it is the paperwork.\" (Complete Act II: The Parting of Ways — the emissaries wait in the Great Massassi Temple warroom.)")
		end
		return
	end

	if (not M:hasStarted(pPlayer, 3, 1)) then
		self:offerInduction(pPlayer, side)
		return
	end

	self:giverMenu(pPlayer, side)
end

-- ---- Q3.1: induction ---------------------------------------------------------

function JediParkAct3:offerInduction(pPlayer, side)
	local bridge = ""

	if (self:crossedIntent(pPlayer, side)) then
		if (side == 1) then
			bridge = "\n\nHe glances once at the temple's oath-record. \"The Massassi hall says you declared for the dark — and the training on your hands says otherwise. The Force laughs at ceremonies. The hands win; they always do. We proceed on what you ARE.\""
		else
			bridge = "\n\nDask taps the temple's oath-record without reading it. \"Says here you lit the Circle's lamp. And then your hands trained the dark anyway. The Force laughs at ceremonies. So do I. We proceed on what you ARE.\""
		end
	end

	local sui = SuiListBox.new("JediParkAct3", "inductionCallback")

	if (side == 1) then
		sui.setTitle("The Keeper's Ledger")
		sui.setPrompt("The trainingroom smells of lamp oil, dust and patience. Keeper Maro sets down a hand-bound ledger whose spine has been re-sewn more times than any book deserves. \"I know what you are. The Circle sends me its knights the way rivers send the sea their stones — worn, and expecting a welcome.\" He does not smile. \"I have buried more names than I have taught. Convince me yours is worth teaching: take the oath of the hall, and the hall will hold your name with the others — the kept and the buried both.\"" .. bridge)
		sui.add("Take the oath of the hall. (Begin Act III: Knight of Embers)", "")
		sui.add("Not yet.", "")
	else
		sui.setTitle("The Overseer's Price")
		sui.setPrompt("The arenahall keeps its echoes close, and Overseer Dask watches you cross it the way a buyer watches a blade being drawn. \"The council pretends not to have this arena. I run it anyway. Everything I teach costs, and the first price is honesty: you are here because the Emperor's ledger has a line with your name on it and no verbs after the name — yet.\" He waits exactly as long as it takes you to understand. \"Pay the entry. Your obedience, drawn against future works. Ask the price, and be told when it is due.\"" .. bridge)
		sui.add("Pay the price. (Begin Act III: Knight of Shadows)", "")
		sui.add("Not today.", "")
	end

	dataSet(pPlayer, "act3_offer_side", side)
	sui.sendTo(pPlayer)
end

function JediParkAct3:inductionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local side = dataNum(pPlayer, "act3_offer_side")
	dataSet(pPlayer, "act3_offer_side", "")

	if (side ~= 1 and side ~= 2) then
		return
	end

	local M = JediParkManager

	if (M:hasStarted(pPlayer, 3, 1) or not self:meetsActGate(pPlayer, side)) then
		return
	end

	M:setStarted(pPlayer, 3, 1)

	-- The home-cell claim: progression already qualifies the player; the
	-- heal converges the permission groups NOW instead of at next login.
	JtpCells:heal(pPlayer)

	self:completeQuest(pPlayer, 1)
	M:setStarted(pPlayer, 3, 2)

	local S = JtpConfig.act3.sites[side]

	if (side == 1) then
		self:sui(pPlayer, "The Mountain's Answer", "\"Then the hall knows you, and its door will remember your weight.\" Maro re-inks a line that has waited years for a name. \"First work. The Singing Mountain Clan lost daughters to the Purge too — and Sister Veshaan will trade sanctuary for a promise and a relic the Shadows stole from her clan. Their camp squats on the pilgrim road at " .. S.camp2.x .. " " .. S.camp2.y .. ", Dathomir. Take the reliquary back. Carry it to Veshaan in the stronghold at 164 4489 — the mountain's door will stand open to the hall's own.\" (Clear the Shadow camp, recover the reliquary, deliver it to Sister Veshaan.)")
	else
		self:sui(pPlayer, "A Sister's Bargain", "\"Entry paid. Collection begins.\" Dask's ledger-hand is quicker than his smile. \"The Nightsisters' silence is for sale, and their envoy Sereth sets the fee: proof you can take what the Shadows could not. A freelancer camp on the Lok wastes at " .. S.camp2.x .. " " .. S.camp2.y .. " sits on a witch-clan reliquary they cannot even open. Take it. Deliver it to Sereth on the stronghold approach at -4086 -136, Dathomir — and go no further than the porch. The stronghold is not ours to walk.\" (Clear the Shadow camp, recover the reliquary, deliver it to Envoy Sereth.)")
	end
end

-- ---- the giver menu (mando_rank menuKeys pattern) ----------------------------

function JediParkAct3:giverMenu(pPlayer, side)
	local M = JediParkManager
	local C = JtpConfig.act3
	local S = C.sites[side]
	local options = {}

	-- Spine.
	if (M:hasStarted(pPlayer, 3, 2) and not M:hasDone(pPlayer, 3, 2)) then
		if (dataNum(pPlayer, "act3_relic") == 1) then
			options[#options + 1] = { "q2hint", "Ask about delivering the reliquary" }
		elseif (dataNum(pPlayer, "act3_q2_cleared") == 1) then
			options[#options + 1] = { "q2relic", "Ask for the reliquary again (your hands were full)" }
		else
			options[#options + 1] = { "q2hint", "Ask about the Shadow camp (" .. (side == 1 and "The Mountain's Answer" or "A Sister's Bargain") .. ")" }
		end
	elseif (M:hasDone(pPlayer, 3, 2) and not M:hasStarted(pPlayer, 3, 3)) then
		options[#options + 1] = { "q3start", (side == 1 and "\"What of the wolves and their paper?\" (Begin: Wolves With Writs)" or "\"Which wolves embarrass the pipeline?\" (Begin: Wolves Without Writs)") }
	elseif (M:hasStarted(pPlayer, 3, 3) and not M:hasDone(pPlayer, 3, 3)) then
		options[#options + 1] = { "q3hint", "Ask about the Shadow cell (" .. dataNum(pPlayer, "act3_q3_kills") .. " of " .. #C.camps.camp3 .. ")" }
	elseif (M:hasDone(pPlayer, 3, 3) and not M:hasStarted(pPlayer, 3, 4)) then
		options[#options + 1] = { "q4start", "\"Where does the road go now?\" (Begin: The Ten Wells)" }
	elseif (M:hasStarted(pPlayer, 3, 4) and not M:hasDone(pPlayer, 3, 4)) then
		if (self:pilgrimageMet(pPlayer)) then
			options[#options + 1] = { "q4turnin", "\"Ten wells, four worlds — walked.\" (Turn in: The Ten Wells)" }
		else
			options[#options + 1] = { "q4hint", "Ask about the ten wells (progress)" }
		end
	elseif (M:hasDone(pPlayer, 3, 4) and not M:hasStarted(pPlayer, 3, 5)) then
		options[#options + 1] = { "q5start", (side == 1 and "\"Where do the Shadows strike next?\" (Begin: The Second Siege)" or "\"Where does the Circle hide its letters?\" (Begin: The Refuge That Wasn't)") }
	elseif (M:hasStarted(pPlayer, 3, 5) and not M:hasDone(pPlayer, 3, 5)) then
		options[#options + 1] = { "q5hint", "Ask about the " .. (side == 1 and "Aurilia palisade (The Second Siege)" or "Talus waystation (The Refuge That Wasn't)") }
	elseif (M:hasDone(pPlayer, 3, 5) and not M:hasStarted(pPlayer, 3, 6)) then
		options[#options + 1] = { "q6start", (side == 1 and "\"The writ spoke of a census.\" (Begin: Pages of the Missing)" or "\"The census should arrive annotated.\" (Begin: The Census of Sparks)") }
	elseif (M:hasStarted(pPlayer, 3, 6) and not M:hasDone(pPlayer, 3, 6)) then
		if (dataNum(pPlayer, "act3_case") == 1) then
			options[#options + 1] = { "q6turnin", "Deliver the census case (" .. (side == 1 and "Pages of the Missing" or "The Census of Sparks") .. ")" }
		else
			options[#options + 1] = { "q6hint", "Ask about the survey camp" }
		end
	elseif (M:hasDone(pPlayer, 3, 6) and not M:hasStarted(pPlayer, 3, 7)) then
		options[#options + 1] = { "q7start", (side == 1 and "\"Who is the Kilnmaster?\" (Begin: The Kilnmaster)" or "\"Who preaches the pyre?\" (Begin: The Zealot's Pyre)") }
	elseif (M:hasStarted(pPlayer, 3, 7) and not M:hasDone(pPlayer, 3, 7)) then
		options[#options + 1] = { "q7hint", "Ask about the arena at " .. S.arena.x .. " " .. S.arena.y }
	elseif (M:hasDone(pPlayer, 3, 7) and not M:hasStarted(pPlayer, 3, 8)) then
		options[#options + 1] = { "q8start", (side == 1 and "\"The Mountain has opinions?\" (Begin: Where the Mountain Breathes)" or "\"What is the last price?\" (Begin: Die Before You Serve)") }
	elseif (M:hasStarted(pPlayer, 3, 8) and not M:hasDone(pPlayer, 3, 8)) then
		options[#options + 1] = { "q8hint", (side == 1 and "Ask about the rite at the Mountain" or "Ask about the cloning cell") }
	elseif (M:hasDone(pPlayer, 3, 8)) then
		options[#options + 1] = { "road", "Ask about the road ahead" }
	end

	-- Side quests, once the act is underway (ally pact sealed).
	if (M:hasDone(pPlayer, 3, 2)) then
		if (not M:hasStarted(pPlayer, 3, 9)) then
			options[#options + 1] = { "s1start", (side == 1 and "Ask after the hidden students. (Side: Sabers for Small Hands)" or "Ask what tribute the arena takes. (Side: Tribute in Kind)") }
		elseif (not M:hasDone(pPlayer, 3, 9)) then
			local tokens = dataNum(pPlayer, "act3_s1_tokens")

			if (tokens >= C.s1TokenCount) then
				options[#options + 1] = { "s1turnin", (side == 1 and "\"Four sabers, recovered.\" (Turn in: Sabers for Small Hands)" or "\"Four trophies, taken.\" (Turn in: Tribute in Kind)") }
			else
				options[#options + 1] = { "s1hint", "Ask about the trophy camp (" .. tokens .. " of " .. C.s1TokenCount .. ")" }
			end
		end

		if (not M:hasStarted(pPlayer, 3, 10)) then
			options[#options + 1] = { "s2start", (side == 1 and "Ask about the orphan on the pilgrim road. (Side: The Long Way Home)" or "Ask about the taskmaster's boast. (Side: The Taskmaster's Lesson)") }
		elseif (not M:hasDone(pPlayer, 3, 10)) then
			if (side == 1) then
				local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

				if (escOid ~= nil and getSceneObject(escOid) ~= nil) then
					options[#options + 1] = { "s2hint", "Ask about Issa's road (The Long Way Home)" }
				else
					options[#options + 1] = { "s2restart", "\"Issa is not where I left her.\" (Restart: The Long Way Home)" }
				end
			else
				if (self:anyLive(pPlayer, "q3s2d_duel")) then
					options[#options + 1] = { "s2hint", "Ask about Jarratt (The Taskmaster's Lesson)" }
				else
					options[#options + 1] = { "s2restart", "\"Call the Breaker to the sand.\" (The Taskmaster's Lesson)" }
				end
			end
		end
	end

	if (side == 1 and JediParkRepeat ~= nil and JediParkRepeat:eligible(pPlayer)) then
		options[#options + 1] = { "repeatables", "Ask what standing work the hall keeps. (Weekly)" }
	end

	options[#options + 1] = { "wells", "Ask how many wells you have walked." }

	local keys = {}
	local sui = SuiListBox.new("JediParkAct3", "giverMenuCallback")

	if (side == 1) then
		sui.setTitle("Keeper Maro")
		sui.setPrompt("\"The hall is listening. Quietly, as it does everything.\"")
	else
		sui.setTitle("Overseer Dask")
		sui.setPrompt("\"Speak. The sand is patient; I am a schedule.\"")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "act3_menukeys", table.concat(keys, ","))
	dataSet(pPlayer, "act3_menu_side", side)
	sui.sendTo(pPlayer)
end

function JediParkAct3:giverMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act3_menukeys")
	local side = dataNum(pPlayer, "act3_menu_side")
	dataSet(pPlayer, "act3_menukeys", "")

	if (list == nil or list == "" or (side ~= 1 and side ~= 2)) then
		return
	end

	-- The gate stays live even inside the menu round-trip.
	if (not self:meetsActGate(pPlayer, side)) then
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
	local C = JtpConfig.act3
	local S = C.sites[side]

	if (action == "q2hint") then
		if (dataNum(pPlayer, "act3_relic") == 1) then
			if (side == 1) then
				self:sui(pPlayer, "The Mountain's Answer", "\"The reliquary in your pack is a promise the Mountain has waited years to hear kept. Sister Veshaan — the stronghold at 164 4489, the meditation cell. Walk it to her.\"")
			else
				self:sui(pPlayer, "A Sister's Bargain", "\"You hold the fee. Sereth waits on the stronghold approach, -4086 -136, Dathomir. The porch, knight. Not a step past it.\"")
			end
		else
			self:sui(pPlayer, (side == 1 and "The Mountain's Answer" or "A Sister's Bargain"), "\"The Shadow camp sits at " .. S.camp2.x .. " " .. S.camp2.y .. (side == 1 and ", Dathomir — the pilgrim road. The reliquary will be with the taskmaster; taskmasters trust nobody else with anything.\"" or ", Lok. The reliquary travels with the taskmaster. Freelancers trust nobody, which makes them predictable.\""))
		end

	elseif (action == "q2relic") then
		if (M:hasStarted(pPlayer, 3, 2) and not M:hasDone(pPlayer, 3, 2) and dataNum(pPlayer, "act3_q2_cleared") == 1 and dataNum(pPlayer, "act3_relic") ~= 1) then
			self:grantRelic(pPlayer)
		end

	elseif (action == "q3start") then
		if (M:hasDone(pPlayer, 3, 2) and not M:hasStarted(pPlayer, 3, 3)) then
			M:setStarted(pPlayer, 3, 3)
			dataSet(pPlayer, "act3_q3_kills", 0)
			self:attachKillObserver(pPlayer)

			if (side == 1) then
				self:sui(pPlayer, "Wolves With Writs", "\"This Shadow cell carries Imperial paper for its kidnappings — writs, stamped and countersigned, for the taking of children. Paper does not make it lawful.\" Maro's voice stays level the way held weight stays level. \"End the cell — nine of them, camped at " .. S.camp3.x .. " " .. S.camp3.y .. " on the pilgrim road — and KEEP the paper. The Circle reads what the Empire signs. It will be loud work. Loud gets remembered by the wrong ledgers; do it anyway.\"")
			else
				self:sui(pPlayer, "Wolves Without Writs", "\"These Shadows freelance without the Hand's writ — kidnapping on speculation, embarrassing the pipeline that feeds your Empire.\" Dask makes a small sound of distaste. \"Discipline is a kindness. Nine of them, camped at " .. S.camp3.x .. " " .. S.camp3.y .. " on the wastes. Break the cell and bring me their ledger. The Voice enjoys receipts.\"")
			end
		end

	elseif (action == "q3hint") then
		self:sui(pPlayer, (side == 1 and "Wolves With Writs" or "Wolves Without Writs"), "\"The camp at " .. S.camp3.x .. " " .. S.camp3.y .. ". " .. dataNum(pPlayer, "act3_q3_kills") .. " of " .. #C.camps.camp3 .. " accounted for. Wolves do not negotiate; neither should you.\"")

	elseif (action == "q4start") then
		if (M:hasDone(pPlayer, 3, 3) and not M:hasStarted(pPlayer, 3, 4)) then
			M:setStarted(pPlayer, 3, 4)
			local pg = C.pilgrimage

			if (side == 1) then
				self:sui(pPlayer, "The Ten Wells", "\"" .. pg.count .. " wells on " .. pg.planets .. " worlds, walked as the Circle walks: unseen, leaving each quieter than you found it.\" Maro turns the ledger toward you; the pilgrim pages are in Ondel's crabbed hand. \"The archivist keeps your count true. When the tenth stone knows you, his courier forwards the case to this hall.\" (Visit " .. pg.count .. " Force shrines in your lifetime of walking, across at least " .. pg.planets .. " planets, then return.)")
			else
				self:sui(pPlayer, "The Ten Wells", "\"Map " .. pg.count .. " wells on " .. pg.planets .. " worlds for the Hand's survey — and mark which ones already watch back.\" Dask shrugs at your look. \"The archivist under Dantooine trades with anyone who reads. His courier will forward the survey case here; the annotations are yours to earn.\" (Visit " .. pg.count .. " Force shrines in your lifetime of walking, across at least " .. pg.planets .. " planets, then return.)")
			end
		end

	elseif (action == "q4hint") then
		local pg = C.pilgrimage
		self:sui(pPlayer, "The Ten Wells", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. pg.count .. " wells; " .. self:planetsWalked(pPlayer) .. " of " .. pg.planets .. " worlds. The old stones do not hurry, and they do not forget.\"")

	elseif (action == "q4turnin") then
		if (M:hasStarted(pPlayer, 3, 4) and not M:hasDone(pPlayer, 3, 4) and self:pilgrimageMet(pPlayer)) then
			self:completeQuest(pPlayer, 4)
			local holoGroup = C.lootGroups.holocronLight

			if (side == 2) then
				holoGroup = C.lootGroups.holocronDark
			end

			M:giveLootGroup(pPlayer, holoGroup)
			M:giveLootGroup(pPlayer, holoGroup)
			M:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)
			M:setStarted(pPlayer, 3, 5)

			if (side == 1) then
				M:adjustVisibility(pPlayer, C.visPilgrimLight)
				self:sui(pPlayer, "The Ten Wells — the Archivist's Due", "A courier-sealed case from Archivist Ondel, forwarded to the hall. Inside: two teaching-holocrons and a power crystal, and a marginal note — \"Ten wells and the road forgot them as they walked it. That is the whole craft. Both churches came from this walking.\" (Visibility reduced: the road keeps your secret.)\n\nMaro closes the ledger line. \"Now the loud work. Aurilia.\"")
			else
				self:sui(pPlayer, "The Ten Wells — the Survey's Due", "A courier-sealed case from Archivist Ondel, forwarded to the arena hall. Inside: two teaching-holocrons and a power crystal. Dask reads your annotations once, at speed, and files them somewhere that is not the case. \"Four wells already watch back. The Voice will want to know which. Thoroughness, noted.\"\n\n\"Now — the refuge that wasn't.\"")
			end
		end

	elseif (action == "q5start") then
		if (M:hasDone(pPlayer, 3, 4) and not M:hasStarted(pPlayer, 3, 5)) then
			M:setStarted(pPlayer, 3, 5)
		end

		if (M:hasStarted(pPlayer, 3, 5) and not M:hasDone(pPlayer, 3, 5)) then
			if (side == 1) then
				self:sui(pPlayer, "The Second Siege", "\"The Shadows return to Aurilia with numbers and a grudge. The palisade remembers you — go stand on it.\" Maro's jaw sets. \"Four pushes this time, by the Circle's count. The village will sleep through it if you do this right. That is what doing it right is FOR.\" (Travel to the Aurilia palisade at 5250 -4100, Dathomir; the watch begins on your word.)")
			else
				self:sui(pPlayer, "The Refuge That Wasn't", "\"A 'refugee waystation' on Talus shelters Circle couriers — letters, safehouse lists, names that should be verbs in somebody's ledger.\" Dask holds up one finger. \"Break it. Leave the civilians their lives — instruments are not butchers — but burn the network's letters. Three satchels. The refuge un-happens.\" (Travel to the waystation at -5300 2500, Talus; burn the three courier satchels.)")
			end
		end

	elseif (action == "q5hint") then
		if (side == 1) then
			local active, waveIdx, remaining, totalWaves = JtpTheaters:waveStatus(pPlayer, "q35_siege")

			if (active and totalWaves > 0) then
				self:sui(pPlayer, "The Second Siege", "\"The palisade is IN IT — wave " .. waveIdx .. " of " .. totalWaves .. ", " .. remaining .. " still in the wire. Why are you here and not there?\"")
			else
				self:sui(pPlayer, "The Second Siege", "\"The palisade at 5250 -4100, north edge of Aurilia. Stand on it and say the word; the treeline will provide the rest.\"")
			end
		else
			self:sui(pPlayer, "The Refuge That Wasn't", "\"The waystation at -5300 2500, Talus. " .. dataNum(pPlayer, "act3_satchels") .. " of " .. C.waystation.satchels .. " satchels burned. Letters first; sentiment never.\"")
		end

	elseif (action == "q6start") then
		if (M:hasDone(pPlayer, 3, 5) and not M:hasStarted(pPlayer, 3, 6)) then
			M:setStarted(pPlayer, 3, 6)
			dataSet(pPlayer, "act3_q6_kills", 0)
			dataSet(pPlayer, "act3_case", 0)
			self:attachKillObserver(pPlayer)

			if (side == 1) then
				self:sui(pPlayer, "Pages of the Missing", "\"The cell's writ referenced a census of Force-touched families — pages of the missing, graded like livestock for a Prophet's desk.\" For the first time, the Keeper's voice frays at one edge. \"An Imperial survey camp holds it at " .. S.camp6.x .. " " .. S.camp6.y .. " on the pilgrim road. Steal it back before it reaches that desk. Quietly, if quiet is a thing you can still afford — the Circle carries names OUT of ledgers.\" (Recover the census case. A bloodless theft keeps you off the hunters' lists.)")
			else
				self:sui(pPlayer, "The Census of Sparks", "\"The same census, the same desk — but it arrives by YOUR hand, annotated.\" Dask lets the difference land. \"The survey camp holds the case at " .. S.camp6.x .. " " .. S.camp6.y .. " on the wastes. The surveyors need not survive the errand — but a clean hand impresses the Voice more than a red one.\" (Recover the census case. A bloodless collection is noticed.)")
			end
		end

	elseif (action == "q6hint") then
		self:sui(pPlayer, (side == 1 and "Pages of the Missing" or "The Census of Sparks"), "\"The survey camp at " .. S.camp6.x .. " " .. S.camp6.y .. ". The case will be under guard and under seal. Guards can be walked past. Seals cannot tell anyone anything.\"")

	elseif (action == "q6turnin") then
		if (M:hasStarted(pPlayer, 3, 6) and not M:hasDone(pPlayer, 3, 6) and dataNum(pPlayer, "act3_case") == 1) then
			self:completeQuest(pPlayer, 6)
			local quiet = (dataNum(pPlayer, "act3_q6_kills") == 0)
			local quietLine = ""

			if (quiet) then
				JediParkManager:adjustVisibility(pPlayer, C.visCensusQuiet)
				quietLine = " (No blood on the pages — the hunters' ledgers stay ignorant of you. Visibility reduced.)"
			end

			if (side == 1) then
				self:sui(pPlayer, "Pages of the Missing — delivered", "Maro reads three pages and stops being able to. He seals the case into a shelf that is not visible until he opens it. \"Every name in here is a door the Empire meant to knock on. Now the knock never comes.\" He re-inks his ledger with fingers that are not quite steady. \"This is the whole of what we are, knight. Names OUT of ledgers.\"" .. quietLine)
			else
				self:sui(pPlayer, "The Census of Sparks — forwarded", "The enclave's courier takes the annotated case without looking up; couriers who look up do not stay couriers. Dask signs the transfer with a flourish that is almost respect. \"Somewhere a desk approves of you. Desks decide more wars than blades — do not repeat that in the arena.\"" .. quietLine)
			end
		end

	elseif (action == "q7start") then
		if (M:hasDone(pPlayer, 3, 6) and not M:hasStarted(pPlayer, 3, 7)) then
			M:setStarted(pPlayer, 3, 7)
			dataSet(pPlayer, "act3_q7_flipped", 0)

			if (side == 1) then
				self:sui(pPlayer, "The Kilnmaster", "\"A dark jedi who calls himself the Kilnmaster 'recruits' padawans by breaking them. A kiln, he says, hardens or cracks — and he sells whichever comes out.\" Maro closes the ledger entirely. \"The Circle does not trade lives. His firing-ground is a scorch of earth at " .. S.arena.x .. " " .. S.arena.y .. ", Dathomir. Go and be unreasonable.\"")
			else
				self:sui(pPlayer, "The Zealot's Pyre", "\"A light-side zealot preaches that every dark student deserves the pyre — and has been ambushing the Hand's candidates to prove the sermon.\" Dask's voice drops to bookkeeping flatness, which from him is fury. \"The Emperor's instruments do not tolerate competition in cruelty. His pulpit stands at " .. S.arena.x .. " " .. S.arena.y .. ", Lok. Close the sermon.\"")
			end
		end

	elseif (action == "q7hint") then
		self:sui(pPlayer, (side == 1 and "The Kilnmaster" or "The Zealot's Pyre"), "\"The arena at " .. S.arena.x .. " " .. S.arena.y .. ". He will talk first. They always talk first. Let him finish — you will fight better for having heard it.\"")

	elseif (action == "q8start") then
		if (M:hasDone(pPlayer, 3, 7) and not M:hasStarted(pPlayer, 3, 8)) then
			M:setStarted(pPlayer, 3, 8)

			if (side == 1) then
				self:sui(pPlayer, "Where the Mountain Breathes", "\"Veshaan has cleared the meditation cell for you — the first outsider in a generation of sisters.\" Maro almost smiles; the ledger has no column for it. \"Sit. The mountain has opinions, and it has been waiting to give them to someone who walks the road you walk. Go to the stronghold at 164 4489; Veshaan will seat you.\"")
			else
				self:sui(pPlayer, "Die Before You Serve", "Dask walks you as far as the arenahall's north door and stops at the threshold like a man at a grave-edge he respects. \"The cloning cell. Everyone who matters has already died once — to fear, to family, to the person they were going to be.\" He nods you through. \"Practice.\" (Enter the enclave's cloning cell and speak the oath.)")
			end
		end

	elseif (action == "q8hint") then
		if (side == 1) then
			self:sui(pPlayer, "Where the Mountain Breathes", "\"The stronghold at 164 4489, Dathomir — the meditation cell past the healing ward. Veshaan seats you; the mountain does the rest. Kneel, and stay kneeling. Mountains are not brief.\"")
		else
			self:sui(pPlayer, "Die Before You Serve", "\"The cloning cell, through the antechamber. The vat teaches nothing; the dying is the lesson. Say the words and mean them — the cell can tell.\"")
		end

	elseif (action == "road") then
		if (side == 1) then
			self:sui(pPlayer, "The Road Ahead", "\"The war is quiet, not gone. Past this hall wait councils, a rank worth the word, and a silent war that is about to learn your name.\" Maro pauses over the ledger. \"Rest. Sharpen. The next page is already ruled.\" (Act IV arrives in a later update.)")
		else
			self:sui(pPlayer, "The Road Ahead", "\"Past the arena waits Council One, and a Voice that does not repeat itself.\" Dask looks almost wistful. \"You are becoming expensive. Good. The ledger prefers verbs, and you are collecting them.\" (Act IV arrives in a later update.)")
		end

	elseif (action == "s1start") then
		if (M:hasDone(pPlayer, 3, 2) and not M:hasStarted(pPlayer, 3, 9)) then
			M:setStarted(pPlayer, 3, 9)
			dataSet(pPlayer, "act3_s1_tokens", 0)
			self:attachKillObserver(pPlayer)

			if (side == 1) then
				self:sui(pPlayer, "Sabers for Small Hands", "\"The enclave hides students the galaxy must never count. Their training sabers went with a plundered cache — four of them, kept as trophies now by a Shadow band camped at " .. S.campS1.x .. " " .. S.campS1.y .. ".\" Maro's voice gentles by one degree. \"Recover them. Small hands are waiting.\"")
			else
				self:sui(pPlayer, "Tribute in Kind", "\"The arena takes tribute: four trophies from worthy kills. A freelancer band at " .. S.campS1.x .. " " .. S.campS1.y .. " has been collecting other people's.\" Dask spreads his hands. \"Theirs will do.\"")
			end
		end

	elseif (action == "s1hint") then
		self:sui(pPlayer, (side == 1 and "Sabers for Small Hands" or "Tribute in Kind"), "\"The band camps at " .. S.campS1.x .. " " .. S.campS1.y .. ". " .. dataNum(pPlayer, "act3_s1_tokens") .. " of " .. C.s1TokenCount .. " recovered.\"")

	elseif (action == "s1turnin") then
		if (M:hasStarted(pPlayer, 3, 9) and not M:hasDone(pPlayer, 3, 9) and dataNum(pPlayer, "act3_s1_tokens") >= C.s1TokenCount) then
			self:completeQuest(pPlayer, 9)
			M:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)

			if (side == 1) then
				self:sui(pPlayer, "Sabers for Small Hands — complete", "Maro receives the four small hilts the way other men receive returned dead. \"They will never know your name. The hands that hold these will be steadier for it anyway.\" He pays the hall's debt in crystal, still warm from keeping.")
			else
				self:sui(pPlayer, "Tribute in Kind — complete", "Dask hangs the four trophies on the arena rail without ceremony; the arena is the ceremony. \"Tribute accepted. The house pays out.\" The crystal he hands over hums like a held note.")
			end
		end

	elseif (action == "s2start") then
		if (M:hasDone(pPlayer, 3, 2) and not M:hasStarted(pPlayer, 3, 10)) then
			M:setStarted(pPlayer, 3, 10)

			if (side == 1) then
				self:spawnEscort(pPlayer)
				self:sui(pPlayer, "The Long Way Home", "\"One more orphan, one more road — this one ends at the Mountain instead of a grave.\" Maro writes the name with unusual care: Issa. \"She waits on the pilgrim road at " .. C.escort.x .. " " .. C.escort.y .. ". Take her hand and walk her to the stronghold approach; Veshaan's sisters will meet her at the porch. Two of the road's shadows will object. Object harder.\"")
			else
				self:startDuel(pPlayer)
				self:sui(pPlayer, "The Taskmaster's Lesson", "\"A sith shadow taskmaster — Jarratt, he styles himself 'the Breaker' — claims he can break any knight the enclave sends to the sand.\" Dask gestures at the hall behind you, where a shape is already rolling its shoulders. \"I sold tickets. Try not to disappoint the house.\"")
			end
		end

	elseif (action == "s2hint") then
		if (side == 1) then
			self:sui(pPlayer, "The Long Way Home", "\"Issa waits where the pilgrim road remembers her — " .. C.escort.x .. " " .. C.escort.y .. ". Take her hand; the road does the rest, except the parts where it doesn't.\"")
		else
			self:sui(pPlayer, "The Taskmaster's Lesson", "\"Jarratt is on the sand and the book is still open. The house took your side, if it helps. It should not help.\"")
		end

	elseif (action == "s2restart") then
		if (M:hasStarted(pPlayer, 3, 10) and not M:hasDone(pPlayer, 3, 10)) then
			if (side == 1) then
				self:spawnEscort(pPlayer)
				self:sui(pPlayer, "The Long Way Home", "\"She went back to waiting. Orphans are patient the way stones are patient — they have practiced.\" (Issa waits again at " .. C.escort.x .. " " .. C.escort.y .. ", Dathomir.)")
			else
				self:startDuel(pPlayer)
				self:sui(pPlayer, "The Taskmaster's Lesson", "Dask raises one hand; somewhere behind you the sand accepts a familiar weight. \"The Breaker answers the bell. Again.\"")
			end
		end

	elseif (action == "repeatables") then
		JediParkRepeat:offer(pPlayer)

	elseif (action == "wells") then
		self:sui(pPlayer, "The Pilgrim's Ledger", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. JtpConfig.shrineTotal() .. " wells, across " .. self:planetsWalked(pPlayer) .. " worlds. The network only exists while someone walks it.\"")
	end
end

-- ---- ally conversation routers -----------------------------------------------

function JediParkAct3:onVeshaanTalk(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		self:sui(pPlayer, "Sister Veshaan", "A sister in trail-leathers regards you the way weather regards a roof. \"The Mountain hears every footstep in this cell. Yours are only footsteps.\"")
		return
	end

	if (M:sideOf(pPlayer) == 2) then
		self:sui(pPlayer, "Sister Veshaan", "Veshaan does not rise. \"The Mountain reads intent the way weather reads a roof, and yours is a storm's.\" Her eyes hold neither fear nor welcome — an accounting. \"The clans have outlasted better storms. Go.\"")
		return
	end

	if (not M:isKnight(pPlayer) or M:sideOf(pPlayer) ~= 1) then
		self:sui(pPlayer, "Sister Veshaan", "\"Little ember.\" Almost kind. \"The Mountain trades with the hall's knights, and you are not yet either. Walk your road; if it brings you back a knight, the Mountain may have opinions worth your hearing.\"")
		return
	end

	-- Q3.2L delivery.
	if (M:hasStarted(pPlayer, 3, 2) and not M:hasDone(pPlayer, 3, 2) and dataNum(pPlayer, "act3_relic") == 1) then
		self:completeQuest(pPlayer, 2)
		self:sui(pPlayer, "The Mountain's Answer — delivered", "Veshaan takes the reliquary in both hands and is quiet long enough for the cell to notice. \"Three sisters carried this before the Shadows took it. Two of them are names on the wind now.\" She sets it in a wall-niche shaped exactly for it. \"The Mountain remembers what is returned as long as what is taken. Sanctuary is yours, knight — and when your hall sends you to sit with the Mountain, this cell will be cleared for you.\" (Return to Keeper Maro; the hall will have work.)")
		return
	end

	-- Q3.8L rite.
	if (M:hasStarted(pPlayer, 3, 8) and not M:hasDone(pPlayer, 3, 8)) then
		if (SceneObject(pPlayer):getParentID() == JtpConfig.act3.smc.cell) then
			self:offerRite(pPlayer)
		else
			self:sui(pPlayer, "Where the Mountain Breathes", "\"Come into the cell where the Mountain can hear you — past the healing ward, where the stone goes quiet. I will seat you there.\"")
		end
		return
	end

	if (M:hasDone(pPlayer, 3, 8)) then
		self:sui(pPlayer, "Sister Veshaan", "\"The Mountain speaks of you now, in the register it keeps for weather and daughters.\" A nod that is almost a bow. \"Walk well, knight of embers.\"")
		return
	end

	self:sui(pPlayer, "Sister Veshaan", "\"The clans watched the old wells before your Republic watched anything — and we lost daughters to the same fire that hunts you. The Mountain trades in promises kept. Keep yours, and it will keep you.\"")
end

function JediParkAct3:onSerethTalk(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		self:sui(pPlayer, "Envoy Sereth", "The envoy's attention passes over you the way lamplight passes over furniture. Somewhere among the stones, a dry sound that might be laughter.")
		return
	end

	if (M:sideOf(pPlayer) == 1) then
		self:sui(pPlayer, "Envoy Sereth", "\"The stronghold's silence is not for sale to embers.\" Sereth's smile shows exactly no teeth. \"You chose the church that apologizes. Walk on, little light — the sisters keep a different arithmetic.\"")
		return
	end

	if (not M:isKnight(pPlayer) or M:sideOf(pPlayer) ~= 2) then
		self:sui(pPlayer, "Envoy Sereth", "\"Come back ranked, dark thing. The sisters do not negotiate with promissory notes.\"")
		return
	end

	-- Q3.2D delivery.
	if (M:hasStarted(pPlayer, 3, 2) and not M:hasDone(pPlayer, 3, 2) and dataNum(pPlayer, "act3_relic") == 1) then
		self:completeQuest(pPlayer, 2)
		self:sui(pPlayer, "A Sister's Bargain — paid", "\"So the little dark thing takes what the Shadows could not.\" Sereth turns the reliquary once; it opens for her like a confession. \"The fee is met. The stronghold's silence is bought — NOT its friendship. Silence is worth more.\" She is already looking past you, at futures. \"When your masters come wanting elder-blood, my intelligence is part of what you purchased today. Later. Everything of worth is later.\" (Return to Overseer Dask.)")
		return
	end

	if (M:hasDone(pPlayer, 3, 2)) then
		self:sui(pPlayer, "Envoy Sereth", "\"The bargain holds. The sisters watch the old wells and the Empire that maps what it cannot read — amusing, still.\" A pause. \"When the elder-hunt begins, knight, remember whose porch you learned patience on.\"")
		return
	end

	self:sui(pPlayer, "Envoy Sereth", "\"Courtesy, from a shrine-walker. The porch tolerates you. The price of anything more is set by your Overseer — ask him what the sisters want taken.\"")
end

-- ---- Q3.8L: the rite of the Mountain -----------------------------------------

function JediParkAct3:offerRite(pPlayer)
	local sui = SuiListBox.new("JediParkAct3", "riteOfferCallback")
	sui.setTitle("Where the Mountain Breathes")
	sui.setPrompt("Veshaan clears the cell with a look; even the air seems to step out. She sets candles in a ring older than the habit of counting. \"Sit where the sisters sit. Kneel, and stay kneeling — the Mountain is not brief, and it does not repeat itself for the restless.\" (Kneel among the candles and remain kneeling in this cell for one minute.)")
	sui.add("Kneel among the candles. (Begin the rite)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct3:riteOfferCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 8) or M:hasDone(pPlayer, 3, 8) or M:sideOf(pPlayer) ~= 1) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act3.smc.cell) then
		CreatureObject(pPlayer):sendSystemMessage("The Mountain hears you only in the meditation cell.")
		return
	end

	local r = JtpConfig.act3.smc.rite

	JtpTheaters:build(pPlayer, {
		planet = JtpConfig.act3.smc.planet, x = r.x, z = r.z, y = r.y, cell = JtpConfig.act3.smc.cell,
		props = {
			{ JtpConfig.act3.items.propLight, 0, 0, 1.8 },
			{ JtpConfig.act3.items.propLight, -1.6, 0, -0.9 },
			{ JtpConfig.act3.items.propLight, 1.6, 0, -0.9 },
		},
		lifetimeSec = 150,
		tag = "q38l_candles",
	})

	local gen = dataNum(pPlayer, "act3_rite_gen") + 1
	dataSet(pPlayer, "act3_rite_gen", gen)

	CreatureObject(pPlayer):sendSystemMessage("Candle-light rings you. Kneel, and remain kneeling; the Mountain is gathering its attention.")
	createEvent(15 * 1000, "JediParkAct3", "riteTick", pPlayer, gen .. ":1")
end

local riteLines = {
	"Stone-cold air settles over the ring. The candle flames lean toward you, all of them, at once.",
	"Somewhere above, the mountain shifts its weight — the sound a listener makes settling in.",
	"The whisper under everything goes quiet, the way a room quiets when its owner enters.",
}

function JediParkAct3:riteTick(pPlayer, arg)
	if (pPlayer == nil or arg == nil or not JediParkManager.enabled()) then
		return
	end

	local gen, step = string.match(arg, "^(%d+):(%d+)$")

	if (gen == nil or tonumber(gen) ~= dataNum(pPlayer, "act3_rite_gen")) then
		return
	end

	step = tonumber(step)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 8) or M:hasDone(pPlayer, 3, 8)) then
		JtpTheaters:teardown(pPlayer, "q38l_candles")
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act3.smc.cell or CreatureObject(pPlayer):getPosture() ~= CROUCHED) then
		CreatureObject(pPlayer):sendSystemMessage("The candles gutter. The mountain's attention slips away like weather — Veshaan will seat you again when you are ready to be still.")
		JtpTheaters:teardown(pPlayer, "q38l_candles")
		return
	end

	if (step < 4) then
		CreatureObject(pPlayer):sendSystemMessage(riteLines[step])
		createEvent(15 * 1000, "JediParkAct3", "riteTick", pPlayer, gen .. ":" .. (step + 1))
		return
	end

	-- The minute is kept. The vision.
	JtpTheaters:teardown(pPlayer, "q38l_candles")
	JediParkManager:adjustVisibility(pPlayer, JtpConfig.act3.visRiteLight)
	self:completeQuest(pPlayer, 8)

	self:sui(pPlayer, "Where the Mountain Breathes", "The candlelight narrows to a coin of gold, and the mountain shows you what it keeps:\n\nA man's face, seamed and patient — a teacher's face, the kind the Purge should have made a martyr of. It did something worse. The mountain regards him with old grief, the way stone regards a fault line. A name arrives like weather rolling downhill: SAROV.\n\nThen the light gutters, and the cell is only a cell, and you are kneeling among spent candles with somebody else's sorrow lodged under your ribs.\n\n(Visibility greatly reduced: the mountain keeps what it hears.)")
	CreatureObject(pPlayer):sendSystemMessage("Where the Mountain Breathes: complete. Keeper Maro should hear of this.")
end

-- ---- Q3.8D: the cloning-cell oath --------------------------------------------

function JediParkAct3:enterCloningCell(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 8) or M:hasDone(pPlayer, 3, 8) or M:sideOf(pPlayer) ~= 2) then
		return
	end

	if (self:anyLive(pPlayer, "q38d_props")) then
		return
	end

	self:stageOath(pPlayer)
end

function JediParkAct3:stageOath(pPlayer)
	local D = JtpConfig.act3.enclaves[2]
	local r = D.rite

	JtpTheaters:teardown(pPlayer, "q38d_props")
	JtpTheaters:build(pPlayer, {
		planet = D.planet, x = r.x, z = r.z, y = r.y, cell = D.cloningCell,
		props = {
			{ JtpConfig.act3.items.propDark, -2.5, 0, 0 },
			{ JtpConfig.act3.items.propDark, 2.5, 0, 0 },
		},
		lifetimeSec = 240,
		tag = "q38d_props",
	})

	local sui = SuiMessageBox.new("JediParkAct3", "oathCb2")
	sui.setTitle("Die Before You Serve (1 of 2)")
	sui.setPrompt("The cloning cell hums with the patience of machines that outlive their patients. Red light climbs two stones that were dark when you entered.\n\nDask's voice carries from the threshold, unhurried: \"Every instrument the Emperor keeps has already died once — to fear, to family, to the person they were going to be. The vat teaches nothing. The DYING is the lesson.\"\n\n\"Say the words.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct3:oathCb2(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	if (eventIndex == 1 or not JediParkManager.enabled()) then
		-- Backed out of the oath: clear the staging so stepping out of the
		-- cell and back in restages immediately (no 4-minute prop wait).
		JtpTheaters:teardown(pPlayer, "q38d_props")
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 8) or M:hasDone(pPlayer, 3, 8)) then
		return
	end

	CreatureObject(pPlayer):playEffect(JtpConfig.act3.camshakeCef, "")

	local sui = SuiMessageBox.new("JediParkAct3", "oathCbDone")
	sui.setTitle("Die Before You Serve (2 of 2)")
	sui.setPrompt("You say them.\n\n\"I died before service. What walks out, serves.\"\n\nThe words cost more than they weigh. The floor SHUDDERS — once, deep, as if something vast beneath Yavin rolled over in its sleep to look at you. The red light holds steady through it, which is somehow worse.\n\nFrom the threshold, Dask sounds almost pleased: \"Noted. Filed. Binding.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct3:oathCbDone(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 8) or M:hasDone(pPlayer, 3, 8)) then
		return
	end

	dataSet(pPlayer, "act3_oath_taken", 1)
	self:completeQuest(pPlayer, 8)
	CreatureObject(pPlayer):sendSystemMessage("Die Before You Serve: the oath is taken, and something with a very long memory has witnessed it. Overseer Dask awaits.")
	createEvent(10 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q38d_props")
end

-- ---- site dispatch -----------------------------------------------------------

function JediParkAct3:onEnterSite(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	local areaID = SceneObject(pArea):getObjectID()
	local kind = readStringData(areaID .. ":jtpAct3Kind")
	local side = readData(areaID .. ":jtpAct3Side") or 0

	if (kind == nil or kind == "") then
		return 0
	end

	-- The door-recognition circles heal ANYONE (revokes are healing too).
	if (kind == "heal") then
		JtpCells:heal(pPlayer)
		return 0
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		return 0
	end

	if (side ~= 0 and M:sideOf(pPlayer) ~= side) then
		return 0
	end

	if (kind == "camp2") then
		self:enterCamp(pPlayer, side, 2)
	elseif (kind == "camp3") then
		self:enterCamp(pPlayer, side, 3)
	elseif (kind == "camp6") then
		self:enterCamp(pPlayer, side, 6)
	elseif (kind == "camps1") then
		self:enterCamp(pPlayer, side, 9)
	elseif (kind == "arena") then
		self:enterArena(pPlayer, side)
	elseif (kind == "siege") then
		self:enterSiege(pPlayer)
	elseif (kind == "waystation") then
		self:enterWaystation(pPlayer)
	elseif (kind == "ritedark") then
		self:enterCloningCell(pPlayer)
	elseif (kind == "smcarrive") then
		self:arriveEscort(pPlayer)
	elseif (kind == "amb1") then
		self:escortAmbush(pPlayer, 1)
	elseif (kind == "amb2") then
		self:escortAmbush(pPlayer, 2)
	end

	return 0
end

-- ---- the camps (Q3.2 / Q3.3 / Q3.6 / Q3.S1) ----------------------------------

function JediParkAct3:enterCamp(pPlayer, side, quest)
	local M = JediParkManager
	local C = JtpConfig.act3

	if (not M:hasStarted(pPlayer, 3, quest) or M:hasDone(pPlayer, 3, quest)) then
		return
	end

	-- Objective already secured: never rebuild over a finished errand.
	-- (q2_cleared covers the full-inventory case — the giver regrants the
	-- relic; the camp stays dead.)
	if (quest == 2 and (dataNum(pPlayer, "act3_relic") == 1 or dataNum(pPlayer, "act3_q2_cleared") == 1)) then
		return
	end

	if (quest == 6 and dataNum(pPlayer, "act3_case") == 1) then
		return
	end

	if (quest == 9 and dataNum(pPlayer, "act3_s1_tokens") >= C.s1TokenCount) then
		return
	end

	local tag = campTags[quest]

	if (self:anyLive(pPlayer, tag)) then
		return
	end

	self:buildCamp(pPlayer, side, quest)
end

function JediParkAct3:buildCamp(pPlayer, side, quest)
	local C = JtpConfig.act3
	local S = C.sites[side]
	local tag = campTags[quest]
	local spec = { planet = S.planet, z = 0, cell = 0, lifetimeSec = C.campLifetimeSec, tag = tag }

	if (quest == 2) then
		spec.x = S.camp2.x
		spec.y = S.camp2.y
		spec.mobs = C.camps.camp2
		dataSet(pPlayer, "act3_q2_kills", 0)
	elseif (quest == 3) then
		spec.x = S.camp3.x
		spec.y = S.camp3.y
		spec.mobs = C.camps.camp3
		dataSet(pPlayer, "act3_q3_kills", 0)
	elseif (quest == 6) then
		spec.x = S.camp6.x
		spec.y = S.camp6.y
		spec.props = { { C.items.propDark, 0, 0, 0 } }
		spec.mobs = {}

		for i = 1, #C.camps.camp6guards, 1 do
			spec.mobs[#spec.mobs + 1] = C.camps.camp6guards[i]
		end

		spec.mobs[#spec.mobs + 1] = { "dark_initiate", -3, 0, 2, -30, "an Imperial survey adjunct", invuln = true }
		spec.mobs[#spec.mobs + 1] = { "dark_initiate", 3, 0, 2, 30, "an Imperial survey adjunct", invuln = true }
	elseif (quest == 9) then
		spec.x = S.campS1.x
		spec.y = S.campS1.y
		spec.mobs = C.camps.campS1
	else
		return
	end

	local built = JtpTheaters:build(pPlayer, spec)

	if (built == nil) then
		return
	end

	self:attachKillObserver(pPlayer)

	if (quest == 2) then
		CreatureObject(pPlayer):sendSystemMessage("The Shadow camp wakes along the rocks — a taskmaster and his keepers, and somewhere among their plunder, the clan's reliquary.")
	elseif (quest == 3) then
		CreatureObject(pPlayer):sendSystemMessage("Nine shapes in black sailcloth rise from the camp — wolves, papered or not. The paper is with the taskmaster.")
	elseif (quest == 6) then
		if (built.props[1] ~= nil) then
			SceneObject(built.props[1]):setObjectMenuComponent("JtpAct3CaseMenuComponent")
			writeData(SceneObject(built.props[1]):getObjectID() .. ":jtpOwner", SceneObject(pPlayer):getObjectID())
		end

		CreatureObject(pPlayer):sendSystemMessage("The survey camp: white-armored guards on a lazy rotation, two robed adjuncts grading names by lamplight, and a sealed case against the red-lit stone. Quiet hands keep quiet names.")
	elseif (quest == 9) then
		CreatureObject(pPlayer):sendSystemMessage("The trophy-takers' camp stirs. Four keepsakes that are not theirs; four keepers who will mind.")
	end
end

-- ---- Q3.7: the boss arena ----------------------------------------------------

function JediParkAct3:enterArena(pPlayer, side)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 7) or M:hasDone(pPlayer, 3, 7)) then
		return
	end

	if (not self:anyLive(pPlayer, "q37_arena")) then
		self:buildArena(pPlayer, side)
	end

	if (dataNum(pPlayer, "act3_q7_flipped") ~= 1) then
		self:offerTaunt(pPlayer, side)
	end
end

function JediParkAct3:buildArena(pPlayer, side)
	local C = JtpConfig.act3
	local S = C.sites[side]
	local B = C.boss[side]
	local prop = C.items.propLight

	if (side == 2) then
		prop = C.items.propDark
	end

	local mobs = {
		{ B.template, 0, 0, 8, 180, B.name, invuln = true },
	}

	for i = 1, (B.adds or 0), 1 do
		mobs[#mobs + 1] = { B.addTemplate, (i * 2 - 3) * 6, 0, 10, 180, nil, invuln = true }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = S.planet, x = S.arena.x, z = 0, y = S.arena.y, cell = 0,
		props = {
			{ prop, -4, 0, 3 },
			{ prop, 4, 0, 3 },
		},
		mobs = mobs,
		lifetimeSec = C.campLifetimeSec,
		tag = "q37_arena",
	})

	if (built == nil) then
		return
	end

	dataSet(pPlayer, "act3_q7_flipped", 0)

	local mobOids = {}

	for i = 1, #built.mobs, 1 do
		mobOids[#mobOids + 1] = SceneObject(built.mobs[i]):getObjectID()
	end

	dataSet(pPlayer, "act3_q7_mobs", table.concat(mobOids, ","))

	if (built.mobs[1] ~= nil) then
		dataSet(pPlayer, "act3_q7_boss", SceneObject(built.mobs[1]):getObjectID())
	end

	self:attachKillObserver(pPlayer)
end

function JediParkAct3:offerTaunt(pPlayer, side)
	local prompt

	if (side == 1) then
		prompt = "The figure between the shrine-stones does not bow. \"Another delivery from the Circle's charity,\" the Kilnmaster says. \"Good. The kiln was cooling.\" He circles without hurry; hurry is for clay. \"I do not break students. I FIRE them. What cracks was always going to crack — I merely schedule it.\""

		if (dataNum(pPlayer, "act3_writ") == 1) then
			prompt = prompt .. "\n\nHis eyes find the stolen writ's shape in your pack, and approve. \"A thief of paper, come to lecture a fireman about children. When you crack — and the soft ones always crack — I will sell the pieces back to both sides.\""
		end

		prompt = prompt .. "\n\n(He draws. The scorched ground is his answer, and yours.)"
	else
		prompt = "\"Dark thing,\" the Pyre-Zealot says, gently, the way surgeons say a diagnosis. \"You walked here on your own feet. They always do.\" Two acolytes take station at his shoulders, lit like votives. \"The pyre is not cruelty. It is HYGIENE. Ask the ones I saved from becoming you — you cannot; that is the point.\""

		if (dataNum(pPlayer, "act3_case") == 1) then
			prompt = prompt .. "\n\n\"And a census-thief besides. Names belong to the light, little instrument. You are carrying somebody's kindling.\""
		end

		prompt = prompt .. "\n\n(He lifts his hand. The sermon is over; the pyre wants tending.)"
	end

	local sui = SuiMessageBox.new("JediParkAct3", "tauntCallback")
	sui.setTitle(side == 1 and "The Kilnmaster" or "The Zealot's Pyre")
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct3:tauntCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 7) or M:hasDone(pPlayer, 3, 7)) then
		return
	end

	if (dataNum(pPlayer, "act3_q7_flipped") == 1) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act3_q7_mobs")

	if (list == nil or list == "") then
		return
	end

	local flipped = 0

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil and SceneObject(pMob):isCreatureObject() and not CreatureObject(pMob):isDead()) then
			CreatureObject(pMob):setPvpStatusBitmask(AGGRESSIVE + ATTACKABLE + ENEMY)
			AiAgent(pMob):removeObjectFlag(AI_NOAIAGGRO)
			AiAgent(pMob):setDefender(pPlayer)
			flipped = flipped + 1
		end
	end

	if (flipped > 0) then
		dataSet(pPlayer, "act3_q7_flipped", 1)
		CreatureObject(pPlayer):sendSystemMessage("The talking is done.")
	end
end

-- ---- Q3.5L: the second siege of Aurilia --------------------------------------

function JediParkAct3:enterSiege(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 5) or M:hasDone(pPlayer, 3, 5)) then
		return
	end

	local active = JtpTheaters:waveStatus(pPlayer, "q35_siege")

	if (active) then
		return
	end

	local sui = SuiListBox.new("JediParkAct3", "siegeStartCallback")
	sui.setTitle("The Second Siege")
	sui.setPrompt("The palisade remembers you: the same treeline squint from the villagers on watch, the same wood, the same hope. This time the Shadows have numbers and a grudge — four pushes, each uglier than the last, and no Marshal to split them with. The wall is wood, hope, and you. (Begin the defense: 4 waves. Leaving the fight for ten minutes forfeits the attempt.)")
	sui.add("Stand the palisade. (Begin the defense)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct3:siegeStartCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 5) or M:hasDone(pPlayer, 3, 5) or M:sideOf(pPlayer) ~= 1) then
		return
	end

	local active = JtpTheaters:waveStatus(pPlayer, "q35_siege")

	if (active) then
		return
	end

	local g = JtpConfig.act3.siege

	local started = JtpTheaters:startWaves(pPlayer, {
		planet = g.planet, x = g.x, z = g.z, y = g.y,
		waves = g.waves,
		tag = "q35_siege",
		onComplete = { screenplay = "JediParkAct3", fn = "onSiegeWon" },
		abortSec = g.abortSec,
	})

	if (started) then
		CreatureObject(pPlayer):sendSystemMessage("The Second Siege: the first wave breaks from the treeline!")
	end
end

function JediParkAct3:onSiegeWon(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 5) or M:hasDone(pPlayer, 3, 5)) then
		return
	end

	self:completeQuest(pPlayer, 5, JtpConfig.act3.frsXpDefend)
	self:sui(pPlayer, "The Second Siege — held", "The treeline empties a second time, and the village never woke. On the palisade walk, one of the watch-villagers presses something into your hand — caf, cold, in a dented cup — which is the largest medal Aurilia has ever issued.\n\nThe palisade holds. Keeper Maro should hear of it.")
end

-- ---- Q3.5D: the waystation raid ----------------------------------------------

function JediParkAct3:enterWaystation(pPlayer)
	local M = JediParkManager
	local C = JtpConfig.act3

	if (not M:hasStarted(pPlayer, 3, 5) or M:hasDone(pPlayer, 3, 5)) then
		return
	end

	if (self:anyLive(pPlayer, "q35_waystation")) then
		return
	end

	local w = C.waystation
	local spec = {
		planet = w.planet, x = w.x, z = 0, y = w.y, cell = 0,
		props = {
			{ C.items.propLight, -6, 0, 2 },
			{ C.items.propLight, 6, 0, 2 },
			{ C.items.propLight, 0, 0, -6 },
		},
		mobs = {},
		lifetimeSec = C.campLifetimeSec,
		tag = "q35_waystation",
	}

	for i = 1, #C.raid.mobs, 1 do
		spec.mobs[#spec.mobs + 1] = C.raid.mobs[i]
	end

	for i = 1, #C.raid.civilians, 1 do
		local cv = C.raid.civilians[i]
		spec.mobs[#spec.mobs + 1] = { cv[1], cv[2], cv[3], cv[4], 0, "a waystation refugee", invuln = true }
	end

	local built = JtpTheaters:build(pPlayer, spec)

	if (built == nil) then
		return
	end

	dataSet(pPlayer, "act3_satchels", 0)

	for i = 1, #built.props, 1 do
		SceneObject(built.props[i]):setObjectMenuComponent("JtpAct3SatchelMenuComponent")
		writeData(SceneObject(built.props[i]):getObjectID() .. ":jtpOwner", SceneObject(pPlayer):getObjectID())
	end

	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("The 'waystation': prophets of the light keeping watch over courier satchels, hired guns on the perimeter, and refugees who chose the wrong hosts. The letters burn; the civilians do not. Instruments are not butchers.")
end

JtpAct3SatchelMenuComponent = {}

function JtpAct3SatchelMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "Burn the correspondence")
end

function JtpAct3SatchelMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local ownerID = readData(SceneObject(pSceneObject):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("The satchel is somebody else's errand.")
		return 0
	end

	if (not M:hasStarted(pPlayer, 3, 5) or M:hasDone(pPlayer, 3, 5) or M:sideOf(pPlayer) ~= 2) then
		return 0
	end

	SceneObject(pSceneObject):destroyObjectFromWorld()

	local burned = dataNum(pPlayer, "act3_satchels") + 1
	dataSet(pPlayer, "act3_satchels", burned)

	local C = JtpConfig.act3

	if (burned >= C.waystation.satchels) then
		JediParkAct3:completeQuest(pPlayer, 5, C.frsXpDefend)
		CreatureObject(pPlayer):sendSystemMessage("The Refuge That Wasn't: the last satchel takes the flame — names, routes and kindness, all of it smoke. The network un-happens here. Overseer Dask awaits.")
		createEvent(10 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q35_waystation")
	else
		CreatureObject(pPlayer):sendSystemMessage("The Refuge That Wasn't: the correspondence curls to ash (" .. burned .. " of " .. C.waystation.satchels .. " satchels).")
	end

	return 0
end

-- ---- Q3.6: the census case ---------------------------------------------------

JtpAct3CaseMenuComponent = {}

function JtpAct3CaseMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "Search the survey stone")
end

function JtpAct3CaseMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local ownerID = readData(SceneObject(pSceneObject):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("The stone is warm, and red, and minding somebody else's business.")
		return 0
	end

	if (not M:hasStarted(pPlayer, 3, 6) or M:hasDone(pPlayer, 3, 6) or dataNum(pPlayer, "act3_case") == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Nothing here is owed to you today.")
		return 0
	end

	local pItem = M:giveNamedItem(pPlayer, JtpConfig.act3.items.token, JtpConfig.act3.items.caseName)

	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and search again.")
		return 0
	end

	dataSet(pPlayer, "act3_case", 1)

	if (dataNum(pPlayer, "act3_q6_kills") == 0) then
		CreatureObject(pPlayer):sendSystemMessage("The census case slides free of the survey rig. The guards' rotation never breaks; the adjuncts never look up. Nobody will know it is gone until the desk asks. Return to your enclave.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The census case slides free of the survey rig, past the cooling evidence of your methods. Return to your enclave.")
	end

	return 0
end

-- ---- the shared kill observer ------------------------------------------------

function JediParkAct3:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct3", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct3", "onKill", pPlayer, 1)
end

function JediParkAct3:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local C = JtpConfig.act3

	-- Q3.2: the relic camp.
	if (M:hasStarted(pPlayer, 3, 2) and not M:hasDone(pPlayer, 3, 2) and JtpTheaters:isTheaterMob(pPlayer, "q32_camp", pVictim)) then
		local kills = dataNum(pPlayer, "act3_q2_kills") + 1
		dataSet(pPlayer, "act3_q2_kills", kills)

		if (kills >= #C.camps.camp2) then
			dataSet(pPlayer, "act3_q2_cleared", 1)
			self:grantRelic(pPlayer)
			createEvent(8 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q32_camp")
		else
			CreatureObject(pPlayer):sendSystemMessage((#C.camps.camp2 - kills) .. " of the camp remain.")
		end

		return 0
	end

	-- Q3.3: the nine wolves.
	if (M:hasStarted(pPlayer, 3, 3) and not M:hasDone(pPlayer, 3, 3) and JtpTheaters:isTheaterMob(pPlayer, "q33_camp", pVictim)) then
		local kills = dataNum(pPlayer, "act3_q3_kills") + 1
		dataSet(pPlayer, "act3_q3_kills", kills)

		if (kills >= #C.camps.camp3) then
			dataSet(pPlayer, "act3_writ", 1)
			local itemName = C.items.writNameLight

			if (M:sideOf(pPlayer) == 2) then
				itemName = C.items.writNameDark
			end

			local pItem = M:giveNamedItem(pPlayer, C.items.token, itemName)

			if (pItem ~= nil) then
				CreatureObject(pPlayer):sendSystemMessage("From the taskmaster's satchel: the cell's paper — kept, as instructed.")
			else
				CreatureObject(pPlayer):sendSystemMessage("The taskmaster's paper survives the fight, but your inventory is full — the enclave will draw a copy.")
			end

			M:adjustVisibility(pPlayer, C.visLoud)
			self:completeQuest(pPlayer, 3)
			CreatureObject(pPlayer):sendSystemMessage("The Shadow cell is ended. That was loud work, and loud gets remembered — return to your enclave. (Visibility increased.)")
			createEvent(8 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q33_camp")
		else
			CreatureObject(pPlayer):sendSystemMessage("Wolves accounted for: " .. kills .. " of " .. #C.camps.camp3 .. ".")
		end

		return 0
	end

	-- Q3.6: census-camp guards (stealth bookkeeping only).
	if (M:hasStarted(pPlayer, 3, 6) and not M:hasDone(pPlayer, 3, 6) and JtpTheaters:isTheaterMob(pPlayer, "q36_camp", pVictim)) then
		dataSet(pPlayer, "act3_q6_kills", dataNum(pPlayer, "act3_q6_kills") + 1)
		return 0
	end

	-- Q3.7: the arena.
	if (M:hasStarted(pPlayer, 3, 7) and not M:hasDone(pPlayer, 3, 7) and JtpTheaters:isTheaterMob(pPlayer, "q37_arena", pVictim)) then
		local bossID = tostring(dataNum(pPlayer, "act3_q7_boss"))

		if (tostring(SceneObject(pVictim):getObjectID()) == bossID) then
			local side = M:sideOf(pPlayer)
			local tokenName = C.items.ceremonyNameLight

			if (side == 2) then
				tokenName = C.items.ceremonyNameDark
			end

			M:giveNamedItem(pPlayer, C.items.token, tokenName)
			M:giveLootGroup(pPlayer, C.lootGroups.colorCrystal)
			self:completeQuest(pPlayer, 7, C.frsXpBoss)

			if (side == 1) then
				CreatureObject(pPlayer):sendSystemMessage("The Kilnmaster: the kiln goes cold. Among his effects, a ceremony token the Circle will want witnessed — return to Keeper Maro.")
			else
				CreatureObject(pPlayer):sendSystemMessage("The Zealot's Pyre: the sermon is closed. The token he carried now carries you — return to Overseer Dask.")
			end

			createEvent(8 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q37_arena")
		end

		return 0
	end

	-- Q3.S1: the trophy camp.
	if (M:hasStarted(pPlayer, 3, 9) and not M:hasDone(pPlayer, 3, 9) and JtpTheaters:isTheaterMob(pPlayer, "q3s1_camp", pVictim)) then
		local tokens = dataNum(pPlayer, "act3_s1_tokens")

		if (tokens < C.s1TokenCount) then
			tokens = tokens + 1
			dataSet(pPlayer, "act3_s1_tokens", tokens)

			local tokenName = C.items.s1TokenNameLight

			if (M:sideOf(pPlayer) == 2) then
				tokenName = C.items.s1TokenNameDark
			end

			M:giveNamedItem(pPlayer, C.items.token, tokenName)

			if (tokens >= C.s1TokenCount) then
				CreatureObject(pPlayer):sendSystemMessage("The fourth keepsake is recovered. Your enclave will want them.")
			else
				CreatureObject(pPlayer):sendSystemMessage("Recovered: " .. tokens .. " of " .. C.s1TokenCount .. ".")
			end
		end

		return 0
	end

	-- Q3.S2D: the duel.
	if (M:hasStarted(pPlayer, 3, 10) and not M:hasDone(pPlayer, 3, 10) and M:sideOf(pPlayer) == 2 and JtpTheaters:isTheaterMob(pPlayer, "q3s2d_duel", pVictim)) then
		self:completeQuest(pPlayer, 10)
		JediParkManager:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)
		CreatureObject(pPlayer):sendSystemMessage("The Taskmaster's Lesson: the Breaker breaks. The house pays out, and Dask looks unbearably vindicated.")
		createEvent(8 * 1000, "JediParkAct3", "teardownTag", pPlayer, "q3s2d_duel")
		return 0
	end

	return 0
end

function JediParkAct3:grantRelic(pPlayer)
	local M = JediParkManager
	local pItem = M:giveNamedItem(pPlayer, JtpConfig.act3.items.token, JtpConfig.act3.items.relicName)

	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("The reliquary is yours by right of the fight, but your inventory is full — your enclave giver will hold it for you.")
		return
	end

	dataSet(pPlayer, "act3_relic", 1)

	if (M:sideOf(pPlayer) == 1) then
		CreatureObject(pPlayer):sendSystemMessage("From the taskmaster's plunder: the witch-clan reliquary, wrapped in somebody's stolen prayer-cloth. Carry it to Sister Veshaan at the Singing Mountain stronghold (164 4489, Dathomir).")
	else
		CreatureObject(pPlayer):sendSystemMessage("From the taskmaster's plunder: the witch-clan reliquary, still sealed against every tool the Shadows owned. Deliver it to Envoy Sereth on the Nightsister approach (-4086 -136, Dathomir). The porch. No further.")
	end
end

function JediParkAct3:teardownTag(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	JtpTheaters:teardown(pPlayer, arg)
end

-- ---- Q3.S2L: the escort ------------------------------------------------------

function JediParkAct3:spawnEscort(pPlayer)
	local E = JtpConfig.act3.escort

	self:cleanupEscort(pPlayer)

	if (not isZoneEnabled(E.planet)) then
		return
	end

	local z = getWorldFloor(E.x, E.y, E.planet) or 0
	local pNpc = spawnMobile(E.planet, E.template, 0, E.x, z, E.y, 45, 0)

	if (pNpc == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Issa is not at the roadside just now. (Spawn failed — ask again in a moment.)")
		return
	end

	local npcID = SceneObject(pNpc):getObjectID()

	SceneObject(pNpc):setCustomObjectName(JtpConfig.act3.escort.name)
	SceneObject(pNpc):setObjectMenuComponent("JtpAct3EscortMenuComponent")
	writeData(npcID .. ":jtpOwner", SceneObject(pPlayer):getObjectID())

	AiAgent(pNpc):addObjectFlag(AI_NOAIAGGRO)
	AiAgent(pNpc):addObjectFlag(AI_STATIONARY)

	dataSet(pPlayer, "act3_esc_oid", npcID)
	dataSet(pPlayer, "act3_esc_follow", 0)
	dataSet(pPlayer, "act3_esc_amb1", 0)
	dataSet(pPlayer, "act3_esc_amb2", 0)

	createEvent(E.lapseMs, "JediParkAct3", "escortLapse", pPlayer, tostring(npcID))
end

JtpAct3EscortMenuComponent = {}

function JtpAct3EscortMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "Take her hand")
end

function JtpAct3EscortMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local ownerID = readData(SceneObject(pSceneObject):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("The girl pulls her hood lower. She is waiting for somebody, and it is not you.")
		return 0
	end

	if (not M:hasStarted(pPlayer, 3, 10) or M:hasDone(pPlayer, 3, 10)) then
		return 0
	end

	if (dataNum(pPlayer, "act3_esc_follow") == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Issa keeps her eyes on the road north. \"The Mountain is far,\" she says, to the wind. \"Please keep walking.\"")
		return 0
	end

	AiAgent(pSceneObject):removeObjectFlag(AI_STATIONARY)
	AiAgent(pSceneObject):addObjectFlag(AI_ESCORT)
	AiAgent(pSceneObject):addObjectFlag(AI_FOLLOW)
	AiAgent(pSceneObject):setFollowObject(pPlayer)
	AiAgent(pSceneObject):setMovementState(AI_FOLLOWING)
	AiAgent(pSceneObject):setAITemplate()

	dataSet(pPlayer, "act3_esc_follow", 1)
	CreatureObject(pPlayer):sendSystemMessage("The Long Way Home: Issa takes your hand for exactly one step, then settles into your shadow. The Singing Mountain stronghold stands far to the northeast (164 4489). Let nothing follow.")

	return 0
end

function JediParkAct3:escortAmbush(pPlayer, idx)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 10) or M:hasDone(pPlayer, 3, 10) or M:sideOf(pPlayer) ~= 1) then
		return
	end

	if (dataNum(pPlayer, "act3_esc_follow") ~= 1) then
		return
	end

	if (dataNum(pPlayer, "act3_esc_amb" .. idx) == 1) then
		return
	end

	local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

	if (escOid == nil or getSceneObject(escOid) == nil) then
		return
	end

	dataSet(pPlayer, "act3_esc_amb" .. idx, 1)

	local E = JtpConfig.act3.escort
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local o = E.ambushOffset
	local spots = { { px + o, py + o }, { px - o, py + o } }
	local oids = {}

	for i = 1, E.ambushCount, 1 do
		local s = spots[((i - 1) % #spots) + 1]
		local z = getTerrainHeight(pPlayer, s[1], s[2])
		local pMob = spawnMobile(E.planet, E.ambushTemplate, 0, s[1], z, s[2], getRandomNumber(360) - 180, 0)

		if (pMob ~= nil) then
			table.insert(oids, SceneObject(pMob):getObjectID())
			AiAgent(pMob):setDefender(pPlayer)
		end
	end

	if (#oids > 0) then
		dataSet(pPlayer, "act3_esc_amb_oids_" .. idx, table.concat(oids, ","))
		createEvent(E.ambushDespawnMs, "JediParkAct3", "despawnEscortAmbush", pPlayer, tostring(idx))
		CreatureObject(pPlayer):sendSystemMessage("Shapes detach from the witch-country rocks — road-shadows with a buyer in mind. Issa makes a very small sound.")
	end

	return
end

function JediParkAct3:despawnEscortAmbush(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act3_esc_amb_oids_" .. arg)

	if (list == nil or list == "") then
		return
	end

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end

	dataSet(pPlayer, "act3_esc_amb_oids_" .. arg, "")
end

function JediParkAct3:arriveEscort(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 10) or M:hasDone(pPlayer, 3, 10) or M:sideOf(pPlayer) ~= 1) then
		return
	end

	if (dataNum(pPlayer, "act3_esc_follow") ~= 1) then
		return
	end

	local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

	if (escOid == nil or getSceneObject(escOid) == nil) then
		return
	end

	self:cleanupEscort(pPlayer)
	self:completeQuest(pPlayer, 10)
	JediParkManager:giveLootGroup(pPlayer, JtpConfig.act3.lootGroups.holocronLight)
	self:sui(pPlayer, "The Long Way Home", "At the porch-line, two sisters are already waiting — the Mountain always knows. Issa stops, looks back at you once, and does the thing nobody on this road has managed in years: she waves. Then the stronghold folds her in, and the road is only a road again.\n\nSomewhere a ledger adds a name to the SHELTERED column. That column is the whole war.")
end

function JediParkAct3:cleanupEscort(pPlayer)
	local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

	if (escOid ~= nil) then
		local pNpc = getSceneObject(escOid)

		if (pNpc ~= nil) then
			SceneObject(pNpc):destroyObjectFromWorld()
		end
	end

	dataSet(pPlayer, "act3_esc_oid", "")
	dataSet(pPlayer, "act3_esc_follow", 0)
	self:despawnEscortAmbush(pPlayer, "1")
	self:despawnEscortAmbush(pPlayer, "2")
end

function JediParkAct3:escortLapse(pPlayer, arg)
	if (pPlayer == nil or arg == nil or not JediParkManager.enabled()) then
		return
	end

	local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

	if (escOid == nil or tostring(escOid) ~= tostring(arg)) then
		return -- a newer walk owns the road
	end

	local M = JediParkManager

	if (M:hasDone(pPlayer, 3, 10)) then
		return
	end

	self:cleanupEscort(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("The Long Way Home: the road went cold and Issa went back to waiting. Ask at the enclave to walk it again.")
end

-- ---- Q3.S2D: the duel --------------------------------------------------------

function JediParkAct3:startDuel(pPlayer)
	local C = JtpConfig.act3
	local D = C.enclaves[2]
	local d = C.duel

	local built = JtpTheaters:build(pPlayer, {
		planet = D.planet, x = d.x, z = d.z, y = d.y, cell = D.giverCell,
		mobs = {
			{ d.template, 0, 0, 0, d.heading, d.name },
		},
		lifetimeSec = 900,
		tag = "q3s2d_duel",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	AiAgent(built.mobs[1]):setDefender(pPlayer)
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Jarratt the Breaker rolls his shoulders on the sand. \"A knight,\" he says, delighted, like a man reading a menu.")
end

-- ---- Q3.4: shrine hook (wired into jtp_shrines at integration) ----------------

function JediParkAct3:onShrineVisited(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 3, 4) or M:hasDone(pPlayer, 3, 4)) then
		return
	end

	local pg = JtpConfig.act3.pilgrimage

	if (self:pilgrimageMet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The Ten Wells: the tenth stone knows you. Ondel's courier is faster than rumor — return to your enclave.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The Ten Wells: " .. math.min(pg.count, JtpShrines:countVisited(pPlayer)) .. " of " .. pg.count .. " wells; " .. math.min(pg.planets, self:planetsWalked(pPlayer)) .. " of " .. pg.planets .. " worlds.")
	end
end

-- ---- login self-heal ---------------------------------------------------------
-- The main loop calls this from the shared login hook (jtp_observers) at
-- integration, beside JediParkAct1:heal. Cell permission groups are
-- healed by JtpCells:heal (already wired); this re-arms the volatile
-- act3 pieces a restart drops.

function JediParkAct3:heal(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local M = JediParkManager

	-- Kill observer for any tracked quest mid-flight.
	local tracked = { 2, 3, 6, 7, 9, 10 }

	for i = 1, #tracked, 1 do
		if (M:hasStarted(pPlayer, 3, tracked[i]) and not M:hasDone(pPlayer, 3, tracked[i])) then
			self:attachKillObserver(pPlayer)
			break
		end
	end

	-- The escort: resume the walk if Issa survived the player's absence,
	-- or clear the pointer so the enclave re-offers cleanly.
	local escOid = tonumber(readScreenPlayData(pPlayer, "JediPark", "act3_esc_oid"))

	if (escOid ~= nil) then
		local pNpc = getSceneObject(escOid)

		if (pNpc == nil) then
			dataSet(pPlayer, "act3_esc_oid", "")
			dataSet(pPlayer, "act3_esc_follow", 0)
		elseif (M:hasStarted(pPlayer, 3, 10) and not M:hasDone(pPlayer, 3, 10)) then
			if (dataNum(pPlayer, "act3_esc_follow") == 1) then
				AiAgent(pNpc):setFollowObject(pPlayer)
				AiAgent(pNpc):setMovementState(AI_FOLLOWING)
			end
		else
			SceneObject(pNpc):destroyObjectFromWorld()
			dataSet(pPlayer, "act3_esc_oid", "")
			dataSet(pPlayer, "act3_esc_follow", 0)
		end
	end
end

-- ---- shared helpers ----------------------------------------------------------

function JediParkAct3:completeQuest(pPlayer, quest, frsOverride)
	local M = JediParkManager
	local C = JtpConfig.act3

	M:setDone(pPlayer, 3, quest)
	M:giveCredits(pPlayer, C.creditsPerQuest)
	M:awardFrsXp(pPlayer, frsOverride or C.frsXpPerQuest)
	self:checkActComplete(pPlayer)
end

function JediParkAct3:checkActComplete(pPlayer)
	local M = JediParkManager

	if (M:hasGlobal(pPlayer, 64)) then
		return
	end

	for q = 1, 8, 1 do
		if (not M:hasDone(pPlayer, 3, q)) then
			return
		end
	end

	M:setGlobal(pPlayer, 64)

	if (M:sideOf(pPlayer) == 2) then
		CreatureObject(pPlayer):sendSystemMessage("Act complete: Knight of Shadows. The ledger has verbs now. (Badge 'Knight Errant' arrives with the client update.)")
	else
		CreatureObject(pPlayer):sendSystemMessage("Act complete: Knight of Embers. The hall holds your name with the kept. (Badge 'Knight Errant' arrives with the client update.)")
	end
end

function JediParkAct3:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct3", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct3:emptyCallback(pPlayer, pSui, eventIndex, args)
end
