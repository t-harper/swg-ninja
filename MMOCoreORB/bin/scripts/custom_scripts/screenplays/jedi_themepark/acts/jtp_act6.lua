-- jtp_act6.lua — Act VI: "The Reckoning" — (L: "The Ember Ascendant") /
-- (D: "The Emperor's Instrument") — the endgame act. ONE state machine,
-- side-flavored via FLAVOR tables (the jtp_act3/jtp_act4 split-act canon).
-- Quests (bit ledger: started 2^(2n-2) / done 2^(2n-1) in "JediParkAct6"):
--   1 L "A Seat Among Embers"    / D "A Chair in the Dark"    [talk/rite] — council seat + war board
--   2 L "The Contested Wells"    / D "The Claimed Wells"      [kill/defend rotation, 3 staged sites]
--   3 L "Champions of the Pyre"  / D "Champions of the Choir" [theater — Endor well set-piece]
--   4   "The Pattern of the Pike" (shared name)               [ceremony — Phase A schematic pledge]
--   5 L "The Forty-Sixth"        / D "The Mountain Must Kneel" [FINALE flagships]
--   6 L "The Ember Ascendant"    / D "The Emperor's Instrument" [epilogue ceremonies]
-- Q6.S1: the plan's EPIC E6 lists NO side quest for Act VI — quest index 7
-- is deliberately absent (verified against the epic text; nothing skipped).
--
-- Act gate: matching side + Act V done (JediPark global bit 256) + FRS
-- rank >= 8 (the council-seat tier; force_title_jedi_master arrives with
-- rank 8 automatically, so the rank check subsumes the title). GRACE
-- FLOOR (plan 7.4, the act4 contract copied verbatim): first acceptance
-- writes act6_entry_rank; every later gate check requires frsRankOf >=
-- max(8, entryRank - 1). A player demoted below the floor gets the pause
-- SUI and every quest HOLDS — no state loss, no wipe.
-- Completion: JediPark bit 512 + badge 147/148 placeholder sysmsg + the
-- "Shard of the Silent War" ceremony pair (select power-crystal roll +
-- named datadisk). FRS XP: 10000/quest baseline, 10000/well site (x3),
-- 15000 champions, 25000 finale; credits 4000/quest. The pike SCHEMATIC
-- is Phase C client work: Q6.4 grants the ceremonial pattern + the
-- act6_schematic_pending flag and does NOT set JediPark bit 4096.
--
-- Givers: NO new NPCs and NO new handlers. The light line rides Act
-- III's Keeper Maro (light enclave trainingroom 8525441) and the dark
-- line rides Act IV's the Hand's Voice (dark enclave council1 3435650);
-- the MAIN LOOP wires the routes into jtp_maro_handler.lua /
-- jtp_voice_handler.lua at integration (the act4-Serenna idiom: most-
-- progressed act first, keyed on JediPark bit 256). Sister Veshaan's
-- handler MAY also route here (onVeshaanTalk returns true when Act VI
-- handled the talk, false to fall through to Act III).
--
-- CELL DECISION (verified against frs_manager.lua enclaveRoomRequirements
-- and FrsManagerImplementation.cpp setupEnclaveRooms/verifyRoomAccess):
--  * L rite: light enclave traininghall 8525440 — NOT FRS-listed; already
--    gate-claimed by act3 ("jtp_lenclave_knight"). Act VI registers NO
--    claim; it only stages there.
--  * D rite: the plan's council2 3435651 is FRS-listed at rank 10 and the
--    suggested chamber fallback 3435642 is FRS-listed at rank ELEVEN and
--    holds the stock voting/challenge terminals (dark_enclave.lua cell 17
--    injection) — both rooms would refuse the act's own rank-8 audience
--    (WALKIN denied below the listed rank; verifyRoomAccess teleports
--    under-ranked players out). RELOCATED to council4 3435653: FRS-listed
--    at rank EXACTLY 8, terminal-free — the hierarchy itself admits every
--    act6-eligible dark Jedi natively. ZERO claims on any FRS-listed cell
--    (see the council1 integration note at the top of jtp_act4.lua).
--
-- Site notes:
--  * Contested wells rotate per player over the FULL shrine census —
--    deterministic OID hash, formula documented at wellSite() below.
--  * Q6.3 set-piece: Endor shrine 02 site (census endor[2] = 7255429,
--    reference 5117 1921; true coords read from the live object at boot).
--  * Q6.5L: Dathomir shrine 01 site (census dathomir[1] = 7325403,
--    reference -4961 -3496 — the coincident mysterious_statue POI).
--  * Q6.5D: SMC approach-EXTERIOR anchor (120, 4430) — ~74m from the
--    (164, 4489) stronghold approach used by acts III/IV, well outside
--    both stock SMC content and our own approach areas. NOTHING is ever
--    spawned inside the stronghold.
--  * Q6.6D: Emperor's Retreat EXTERIOR approach. The stock Imperial park
--    (screenplays/themepark/imperial/emperors_retreat.lua) is untouched;
--    its nearest exterior spawns are the guard-tower stormtrooper pair at
--    (2536.8, -3881.4)/(2536.8, -3885.5) and the pad line (tie_pilot
--    2432 -3887, AT-STs ~2452 -3961). The scene anchor is (2550, -3810):
--    ~72m from the tower pair, 100m+ from everything else. (The task
--    brief's ~(2500, -3860) sketch is only ~43m from the towers and was
--    shifted to honor the >=50m isolation rule — see the report.)
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- Era rails: Vader spawns invulnerable and is never attackable; the
-- Emperor exists ONLY as the eleven words Vader carries; no post-ANH
-- knowledge anywhere in the text.
--
-- ScreenPlayData namespace "JediPark", keys prefixed act6_:
--   act6_entry_rank          grace-floor anchor (written once; ""/nil = unset)
--   act6_menukeys/_menu_giver giver menu bookkeeping
--   act6_wells               contested-well stages complete (0..3)
--   act6_camp_left           D well-camp zealots remaining (current site)
--   act6_champ_left          Q6.3 set-piece mobs remaining
--   act6_core                Q6.3 focusing core secured (0/1)
--   act6_schematic_pending   Q6.4 Phase A pledge — Phase C reads and grants
--   act6_forty_waves         Q6.5L wave phase held (0/1)
--   act6_boss_oid            finale boss OID (both flagships)
--   act6_kneel_flipped       Q6.5D talk-then-fight flip latch
--   act6_veshaan_dead        Q6.5D contract key (persistent, cross-act)
--   act6_judged              Q6.6D Retreat judgment witnessed (0/1)
--   act6_shard_due           epilogue shard re-grant latch (inventory full)
--   theater tags: act6_rite, act6_well, act6_camp, act6_champ,
--     act6_forty (waves), act6_boss, act6_witness, act6_scene, act6_ascend

-- ---- tuning (jtp_config owns nothing act6-specific yet; claim the slot) ------

JtpConfig.act6 = JtpConfig.act6 or {
	creditsPerQuest = 4000,
	frsPerQuest = 10000,
	frsPerWellSite = 10000,      -- Q6.2, per staged site (x3 = the quest's 30k)
	frsChampions = 15000,        -- Q6.3
	frsFinale = 25000,           -- Q6.5L / Q6.5D

	-- Act gate (plan EPIC E6): rank 8 = the council-seat tier.
	gateRank = 8,
	prevActBit = 256,            -- JediPark global: Act V done

	-- Home enclaves, keyed by side (1 light / 2 dark). riteCell is where
	-- the Q6.1 seat rite (and the L epilogue) stages: L traininghall is
	-- act3's gate-claimed cell; D council4 is FRS rank-8 property — see
	-- the CELL DECISION header. Rite props build at the PLAYER'S own
	-- cell-local position (the act4 buildObjective idiom — bulletproof
	-- against unmapped room floors), so no room coordinates are needed.
	enclaves = {
		[1] = { planet = "yavin4", x = -5514, y = 4912, riteCell = 8525440, areaRadius = 128 },
		[2] = { planet = "yavin4", x = 5070, y = 310, riteCell = 3435653, areaRadius = 128 },
	},

	-- Q6.2 — the contested-well rotation (formula at wellSite()).
	wells = {
		sites = 3,
		siteRadius = 40,
		abortSec = 600,
		ringMin = 16, ringMax = 40,
		-- L: two waves per site — the strike team, then the lieutenant.
		wavesLight = {
			{ mobs = { { "prophet_of_the_dark_side", 2 } } },                                                    -- CL126 x2
			{ mobs = { { "senior_prophet_of_the_dark_side", 1 }, { "lesser_prophet_of_the_dark_side", 1 } } },   -- CL138 + CL85
		},
		-- D: a staged zealot strike camp (act4's verified rebel-tier picks;
		-- the squad leader is the plan's "lieutenant"). {template, dx, dy}.
		campDark = {
			{ "fbase_rebel_guardsman_hard", -5, 4 },    -- CL70
			{ "fbase_rebel_guardsman_hard", 5, 4 },     -- CL70
			{ "fbase_rebel_rifleman_hard", -7, -4 },    -- CL76
			{ "fbase_rebel_rifleman_hard", 7, -4 },     -- CL76
			{ "fbase_rebel_squad_leader_hard", 0, 8 },  -- CL84 — the lieutenant
		},
		zealotName = "a Circle zealot",
		campLifetimeSec = 900,
	},

	-- Q6.3 — the Endor well set-piece (census endor[2]; live coords read
	-- from the object at boot, census reference as fallback).
	champions = {
		planet = "endor", shrineID = 7255429, x = 5117, y = 1921, radius = 40,
		lifeSec = 1800,
		-- L: two senior prophets + prophet retinue. {template, dx, dy [, name]}
		mobsLight = {
			{ "senior_prophet_of_the_dark_side", -4, 8 },
			{ "senior_prophet_of_the_dark_side", 4, 8 },
			{ "prophet_of_the_dark_side", -9, 3 },
			{ "prophet_of_the_dark_side", 9, 3 },
		},
		-- D: three consecrated champions + zealot retinue.
		mobsDark = {
			{ "fbase_rebel_squad_leader_hard", -5, 8, "a Champion of the Choir" },
			{ "fbase_rebel_squad_leader_hard", 0, 10, "a Champion of the Choir" },
			{ "fbase_rebel_squad_leader_hard", 5, 8, "a Champion of the Choir" },
			{ "fbase_rebel_rifleman_hard", -9, 2, "a Circle zealot" },
			{ "fbase_rebel_rifleman_hard", 9, 2, "a Circle zealot" },
		},
	},

	-- Q6.5L — the Forty-Sixth: defense of the first well (census
	-- dathomir[1]; the coincident mysterious_statue POI).
	forty = {
		planet = "dathomir", shrineID = 7325403, x = -4961, y = -3496, radius = 40,
		abortSec = 900,
		ringMin = 16, ringMax = 40,
		-- The prophet ladder (solo baseline — do not inflate).
		waves = {
			{ mobs = { { "prophet_of_the_dark_side", 2 } } },
			{ mobs = { { "prophet_of_the_dark_side", 3 } } },
			{ mobs = { { "senior_prophet_of_the_dark_side", 1 }, { "prophet_of_the_dark_side", 2 } } },
			{ mobs = { { "senior_prophet_of_the_dark_side", 2 }, { "prophet_of_the_dark_side", 1 } } },
		},
		bossTemplate = "master_prophet_of_the_dark_side",   -- CL168
		bossName = "the Emperor's Answer",
		addTemplate = "senior_prophet_of_the_dark_side",    -- CL138 x2
		-- act4_veshaan_warned == 1 payoff: two invulnerable SMC witnesses
		-- (jtp_veshaan chassis; flavor allies ONLY — Phase A simplification,
		-- no combat AI, they watch the debt get paid).
		witnessTemplate = "jtp_veshaan",
		witnessName = "a Singing Mountain sister",
		bossLifeSec = 1800,
	},

	-- Q6.5D — the Mountain Must Kneel: SMC approach-EXTERIOR theater.
	-- jtp_veshaan is a level-100 talk-chassis — UNDERTUNED for an apex
	-- finale (accepted Phase A deviation, the act3-D-boss precedent):
	-- Phase B retunes her HAM/damage or moves her to a tuned combat
	-- template. The adds are stock SMC arch witches (CL107, faction
	-- "mtn_clan" — see the faction-hit note in the report).
	kneel = {
		planet = "dathomir", x = 120, y = 4430, radius = 40,
		bossTemplate = "jtp_veshaan",
		bossName = "High Witch Veshaan",
		addTemplate = "singing_mountain_clan_arch_witch",
		lifeSec = 1800,
	},

	-- Q6.6D — the Emperor's Retreat exterior approach scene. Anchor is
	-- ~72m from the nearest stock spawn (guard towers 2536.8 -3881.4);
	-- the Imperial park itself is never touched.
	retreat = {
		planet = "naboo", x = 2550, y = -3810, radius = 40,
		vader = "darth_vader_city_control",   -- CL300, INVULNERABLE template
		voice = "jtp_voice",
		lifeSec = 300,
	},

	items = {
		token = "object/tangible/mission/mission_datadisk.iff",
		coreName = "A Pike's Focusing Core",
		patternLightName = "Pattern of the Pike — Light",
		patternDarkName = "Pattern of the Pike — Dark",
		shardName = "Shard of the Silent War",
		propLight = "object/tangible/jedi/power_shrine.iff",
		propDark = "object/tangible/jedi/power_shrine_red.iff",
	},
	lootGroups = {
		powerCrystal = "power_crystals",
	},
}

JediParkAct6 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 6,
}

registerScreenPlay("JediParkAct6", true)

-- Reload guard: survives reloadscreenplays; reset only by a full restart.
JTP_ACT6_SPAWNED = JTP_ACT6_SPAWNED or nil

-- ---- boot spawns -------------------------------------------------------------
-- Act VI spawns NO mobiles at boot — the givers belong to Acts III/IV and
-- every scene is a per-player theater. Boot work is trigger areas only,
-- and ZERO cell claims (see the CELL DECISION header).

function JediParkAct6:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT6_SPAWNED ~= nil) then
		print("jtp: act6 already spawned (reload) — skipping spawns")
		print("jtp: act6 'The Reckoning / The Emperor's Instrument' loaded")
		return
	end

	JTP_ACT6_SPAWNED = {}
	local C = JtpConfig.act6

	-- Enclave rite triggers (yavin4): world circle on each enclave with a
	-- cell filter (the act3 ritedark idiom). L = traininghall (act3's
	-- claim admits us); D = council4 (FRS rank-8 property, no claims).
	if (isZoneEnabled("yavin4")) then
		local L = C.enclaves[1]
		self:addArea(L.planet, L.x, 0, L.y, L.areaRadius, L.riteCell, "ritelight", 1)

		local D = C.enclaves[2]
		self:addArea(D.planet, D.x, 0, D.y, D.areaRadius, D.riteCell, "ritedark", 2)

		print("jtp: act6 D rite sited in dark enclave council4 (3435653, FRS rank-8 room) — council2/chamber refused, see file header; NO cell claims registered")
	end

	-- Q6.3 — the Endor well set-piece site (true coords from the object).
	if (isZoneEnabled(C.champions.planet)) then
		local ch = C.champions
		local x, y = self:shrineSitePos(ch.shrineID, ch.x, ch.y, "champions")
		self:addArea(ch.planet, x, getWorldFloor(x, y, ch.planet) or 0, y, ch.radius, 0, "champ", 0)
	end

	-- Dathomir: the Forty-Sixth defense site + the SMC approach boss site.
	if (isZoneEnabled("dathomir")) then
		local f = C.forty
		local x, y = self:shrineSitePos(f.shrineID, f.x, f.y, "forty")
		self:addArea(f.planet, x, getWorldFloor(x, y, f.planet) or 0, y, f.radius, 0, "forty", 1)

		local k = C.kneel
		self:addArea(k.planet, k.x, getWorldFloor(k.x, k.y, k.planet) or 0, k.y, k.radius, 0, "kneel", 2)
	end

	-- Naboo: the Emperor's Retreat exterior approach scene.
	if (isZoneEnabled(C.retreat.planet)) then
		local r = C.retreat
		self:addArea(r.planet, r.x, getWorldFloor(r.x, r.y, r.planet) or 0, r.y, r.radius, 0, "retreat", 2)
		print("jtp: act6 Retreat approach anchor (2550 -3810) — stock Imperial park untouched; nearest stock spawn ~72m (guard towers)")
	end

	print("jtp: act6 'The Reckoning / The Emperor's Instrument' loaded")
end

-- Live world position of a census shrine, with census-reference fallback.
function JediParkAct6:shrineSitePos(shrineID, refX, refY, label)
	local pShrine = getSceneObject(shrineID)

	if (pShrine == nil) then
		print("jtp: WARNING — act6 " .. label .. " shrine " .. shrineID .. " missing; using census reference coords")
		return refX, refY
	end

	return SceneObject(pShrine):getWorldPositionX(), SceneObject(pShrine):getWorldPositionY()
end

function JediParkAct6:addArea(planet, x, z, y, radius, cellFilter, kind, side)
	local pArea = spawnActiveArea(planet, "object/active_area.iff", x, z, y, radius, cellFilter)

	if (pArea == nil) then
		print("jtp: WARNING — act6 area '" .. kind .. "' spawn failed on " .. planet)
		return nil
	end

	local areaID = SceneObject(pArea):getObjectID()
	writeStringData(areaID .. ":jtpAct6Kind", kind)
	writeData(areaID .. ":jtpAct6Side", side or 0)
	createObserver(ENTEREDAREA, "JediParkAct6", "onEnterSite", pArea)
	table.insert(JTP_ACT6_SPAWNED, areaID)

	return pArea
end

-- ---- data helpers ------------------------------------------------------------

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

-- Live (undestroyed, undead) members of a theater tag (act4 idiom; props
-- count as live).
function JediParkAct6:liveCount(pPlayer, tag)
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

-- ---- the act gate + grace floor (the act4 contract, gateRank 8) --------------

-- nil until the act has been accepted once; then the rank written at entry.
function JediParkAct6:entryRank(pPlayer)
	local raw = readScreenPlayData(pPlayer, "JediPark", "act6_entry_rank")

	if (raw == nil or raw == "") then
		return nil
	end

	return tonumber(raw)
end

-- "ok" | "pause" | "no". "pause" = accepted, then demoted below the grace
-- floor max(8, entryRank - 1): everything HOLDS, nothing is wiped.
function JediParkAct6:gateState(pPlayer)
	local M = JediParkManager

	if (pPlayer == nil or not M:isJedi(pPlayer)) then
		return "no"
	end

	local side = M:sideOf(pPlayer)

	if (side == 0) then
		return "no"
	end

	local C = JtpConfig.act6

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

function JediParkAct6:gateOk(pPlayer)
	return self:gateState(pPlayer) == "ok"
end

function JediParkAct6:sendPauseNotice(pPlayer)
	local M = JediParkManager
	local entry = self:entryRank(pPlayer) or JtpConfig.act6.gateRank
	local floor = math.max(JtpConfig.act6.gateRank, entry - 1)
	local title = "The Ember Ascendant"

	if (M:sideOf(pPlayer) == 2) then
		title = "The Emperor's Instrument"
	end

	self:sui(pPlayer, title, "The Reckoning pauses around you the way a court pauses for a recount. Your standing in the Force's hierarchy has slipped below what a council seat spends (you hold rank " .. M:frsRankOf(pPlayer) .. "; the seat remembers you at rank " .. entry .. ", and will wait for rank " .. floor .. "). Nothing you have earned is lost, and nothing new opens until you stand where you stood. Recover your rank; the chair keeps your name.")
end

-- ---- side flavor (one state machine, two voices) -----------------------------

local FLAVOR = {
	[1] = {
		actName = "The Ember Ascendant",
		giver = "Keeper Maro",
		q1 = "A Seat Among Embers", q2 = "The Contested Wells",
		q3 = "Champions of the Pyre", q4 = "The Pattern of the Pike",
		q5 = "The Forty-Sixth", q6 = "The Ember Ascendant",
	},
	[2] = {
		actName = "The Emperor's Instrument",
		giver = "The Hand's Voice",
		q1 = "A Chair in the Dark", q2 = "The Claimed Wells",
		q3 = "Champions of the Choir", q4 = "The Pattern of the Pike",
		q5 = "The Mountain Must Kneel", q6 = "The Emperor's Instrument",
	},
}

-- ---- Q6.2: the contested-well rotation ---------------------------------------
-- Deterministic per-player site pick over the FULL census, no storage:
--   * flatten JtpConfig.shrines in JtpConfig.shrinePlanets order into an
--     ordered site list; N = its length (46 on the live census);
--   * h = playerOID % N   (engine OIDs are lua 5.3 integers — exact math);
--   * stage k (1..3) uses list index ((h + (k-1) * floor(N/3)) % N) + 1.
-- floor(N/3) >= 1 and 2*floor(N/3) < N for every N >= 3, so the three
-- indices are always distinct, spread across the census, and identical on
-- every recomputation for the same character. Two players may hash to the
-- same well; every engagement is a per-player theater, so they coexist.

local function censusFlat()
	local list = {}

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		local planet = JtpConfig.shrinePlanets[p]
		local ids = JtpConfig.shrines[planet]

		for i = 1, #ids, 1 do
			list[#list + 1] = { planet = planet, index = i, id = ids[i] }
		end
	end

	return list
end

-- Site for rotation stage k (1..3): { planet, index, id } or nil.
function JediParkAct6:wellSite(pPlayer, stage)
	local list = censusFlat()
	local n = #list

	if (n == 0 or stage < 1 or stage > JtpConfig.act6.wells.sites) then
		return nil
	end

	local h = SceneObject(pPlayer):getObjectID() % n
	local idx = ((h + (stage - 1) * math.floor(n / 3)) % n) + 1

	return list[idx]
end

-- Engagement anchor for a site: the live shrine's world position, with
-- the player's own position as the resilient fallback (the shrine object
-- is a snapshot fixture and should always resolve in an enabled zone).
function JediParkAct6:wellAnchor(pPlayer, site)
	if (site ~= nil) then
		local pShrine = getSceneObject(site.id)

		if (pShrine ~= nil) then
			return SceneObject(pShrine):getWorldPositionX(), SceneObject(pShrine):getWorldPositionY()
		end
	end

	return SceneObject(pPlayer):getWorldPositionX(), SceneObject(pPlayer):getWorldPositionY()
end

-- Player-facing description of a site (live coords when the zone is up).
function JediParkAct6:wellSiteText(site)
	if (site == nil) then
		return "an unmapped well"
	end

	local where = site.planet .. ", well " .. site.index

	local pShrine = getSceneObject(site.id)

	if (pShrine ~= nil) then
		where = where .. " (" .. math.floor(SceneObject(pShrine):getWorldPositionX()) .. " " .. math.floor(SceneObject(pShrine):getWorldPositionY()) .. ")"
	end

	return where
end

-- ---- giver conversation routers ----------------------------------------------
-- Wired by the MAIN LOOP into jtp_maro_handler.lua / jtp_voice_handler.lua
-- (most-progressed act first, keyed on JediPark bit 256 — the act4-Serenna
-- idiom). Every screen re-evaluates side + gate live (global AC 1 + 7.4).

function JediParkAct6:onMaroTalk(pPlayer)
	self:onGiverTalk(pPlayer, 1)
end

function JediParkAct6:onVoiceTalk(pPlayer)
	self:onGiverTalk(pPlayer, 2)
end

function JediParkAct6:onGiverTalk(pPlayer, giverSide)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager
	local F = FLAVOR[giverSide]

	if (not M:isJedi(pPlayer) or M:sideOf(pPlayer) == 0) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "The Keeper reads a ledger whose last pages are blank on purpose. Whatever is being decided in this hall, it is not being decided about you.")
		else
			self:sui(pPlayer, F.giver, "The figure in the Emperor's black does not turn. The room is convened for a reckoning, and you are not on its docket.")
		end
		return
	end

	if (M:sideOf(pPlayer) ~= giverSide) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "Maro looks up once, and files what he sees. \"The hall's reckoning is the light's own business, and your weight falls the other way. The dark keeps its councils under Yavin's other shadow. Go and be counted there.\"")
		else
			self:sui(pPlayer, F.giver, "The Voice does not turn. \"The Emperor's arithmetic has a column for you, and this is not it. The door remembers the way out.\"")
		end
		return
	end

	local gate = self:gateState(pPlayer)

	if (gate == "no") then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "\"Not yet.\" Maro sets down the pen with a bookkeeper's finality. \"The Reckoning seats survivors: finish the Unbroken Light's road, and stand at the eighth rank of the Force's hierarchy — the rank the galaxy calls Master without asking anyone's permission. Then the hall has a chair with your weight in mind.\" (Requires: Act V complete, FRS rank 8.)")
		else
			self:sui(pPlayer, F.giver, "\"The chair is not offered. It is reached.\" The Voice's patience is the patience of filing systems. \"Finish the Heart of Darkness. Stand at the eighth rank of the hierarchy. The Reckoning convenes for those already standing.\" (Requires: Act V complete, FRS rank 8.)")
		end
		return
	end

	if (gate == "pause") then
		self:sendPauseNotice(pPlayer)
		return
	end

	if (not M:hasStarted(pPlayer, 6, 1)) then
		self:offerSeat(pPlayer, giverSide)
		return
	end

	self:giverMenu(pPlayer, giverSide)
end

-- Sister Veshaan's Act VI voice (optional wire — the veshaan handler calls
-- this FIRST and falls through to Act III when it returns false). Handles:
--   * the L rite/act framing once the Reckoning is underway;
--   * the D flagship pre-fight (re-offer the parley if she is staged and
--     the fight has not been called — robustness for players who converse
--     with the staged boss instead of answering the SUI).
function JediParkAct6:onVeshaanTalk(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return false
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 2) then
		-- Only the staged Q6.5D boss speaks for Act VI on the dark line.
		if (M:hasStarted(pPlayer, 6, 5) and not M:hasDone(pPlayer, 6, 5)
			and self:liveCount(pPlayer, "act6_boss") > 0 and dataNum(pPlayer, "act6_kneel_flipped") == 0) then
			self:offerKneelParley(pPlayer)
			return true
		end

		return false
	end

	if (side ~= 1 or not M:hasStarted(pPlayer, 6, 1) or not self:gateOk(pPlayer)) then
		return false
	end

	-- L framing: the Mountain's read on the Reckoning (flavor only; the
	-- rite itself belongs to the enclave's training hall).
	if (M:hasDone(pPlayer, 6, 5)) then
		self:sui(pPlayer, "Sister Veshaan", "\"The first well stands, and the Mountain heard the answer you gave the Emperor's answer.\" Veshaan's nod carries the weight of a treaty. \"The clans will tell it as weather: the night the storm turned back. Walk your hall's last ceremony, ember. You have earned the unhooding.\"")
	elseif (M:hasStarted(pPlayer, 6, 5)) then
		if (dataNum(pPlayer, "act4_veshaan_warned") == 1) then
			self:sui(pPlayer, "Sister Veshaan", "\"The first well. Dathomir's own.\" Veshaan is already looking down the valley, the way weather looks for a roof. \"You warned the Mountain once, and mountains pay their debts LOUDLY — when the Emperor's answer arrives at the old statue, daughters of the clan will be standing witness. Go. We are already there.\"")
		else
			self:sui(pPlayer, "Sister Veshaan", "\"The first well. Dathomir's own.\" Veshaan weighs you like a sky. \"The old statue has watched that road since before roads. Whatever the Prophets send, it has watched worse arrive and not leave. Stand where it can watch you win.\"")
		end
	else
		self:sui(pPlayer, "Sister Veshaan", "\"The hall has offered you a seat among embers.\" It is not a question; the Mountain hears everything that happens in a training hall it approves of. \"Take it. Councils are how wars remember to end.\"")
	end

	return true
end

-- ---- Q6.1: the council seat ---------------------------------------------------

function JediParkAct6:offerSeat(pPlayer, side)
	local F = FLAVOR[side]
	local sui = SuiListBox.new("JediParkAct6", "seatCallback")
	sui.setTitle(F.q1)

	if (side == 1) then
		sui.setPrompt("Keeper Maro closes the ledger, which he has never once done with you in the room. \"The Circle finally has enough survivors to deserve the word 'council.' Eight ranks of the hierarchy stand behind your name, and the hall has counted every one.\" He rises — which he has also never done. \"The rite is held in the training hall; the auditorium belongs to the Rankers and their politics, and what we are about to do is older than politics. Walk next door when you are ready to sit among embers.\"")
		sui.add("Accept the seat. (Begin Act VI: The Ember Ascendant)", "")
		sui.add("\"Not yet.\"", "")
	else
		sui.setPrompt("Council One, and the Voice at its far wall. \"Council Two has been empty since its owner misjudged the Emperor's patience.\" The figure gestures — once — toward the hallways above. \"It does not repeat the gesture. Nor does the hierarchy: the room it opens at your rank is Council Four, and the Emperor seats instruments in rooms that open for them. Go up. Take the chair in the dark. The Reckoning convenes on your arrival.\"")
		sui.add("Rise to the chair. (Begin Act VI: The Emperor's Instrument)", "")
		sui.add("Withdraw.", "")
	end

	sui.sendTo(pPlayer)
end

function JediParkAct6:seatCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0 or M:hasStarted(pPlayer, 6, 1) or not self:gateOk(pPlayer)) then
		return
	end

	-- GRACE FLOOR anchor: written exactly once, at first acceptance.
	if (self:entryRank(pPlayer) == nil) then
		dataSet(pPlayer, "act6_entry_rank", math.max(0, M:frsRankOf(pPlayer)))
		M:log(pPlayer, "act6 entry rank " .. math.max(0, M:frsRankOf(pPlayer)))
	end

	-- Converge cell permission groups NOW (the L traininghall claim is
	-- act3's; heal grants it to the freshly qualified without a relog).
	JtpCells:heal(pPlayer)
	M:setStarted(pPlayer, 6, 1)

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q1 .. ": walk into the training hall beside the trainingroom. The rite waits there.")
	else
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q1 .. ": ascend to Council Four — the council room the hierarchy opens at the eighth rank. The chair waits there.")
	end
end

-- The rite fires from the enclave trigger areas (onEnterSite -> here).
-- Props build at the player's own cell-local position; the ceremony is a
-- two-beat SUI (the seat, then the war board), completing Q6.1.
function JediParkAct6:enterRite(pPlayer, side)
	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= side) then
		return
	end

	-- Q6.6L: the same hall hosts the ascension ceremony (state dispatch).
	if (side == 1 and M:hasStarted(pPlayer, 6, 6) and not M:hasDone(pPlayer, 6, 6)) then
		self:stageAscension(pPlayer)
		return
	end

	if (not M:hasStarted(pPlayer, 6, 1) or M:hasDone(pPlayer, 6, 1)) then
		return
	end

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act6.enclaves[side].riteCell) then
		return
	end

	if (self:liveCount(pPlayer, "act6_rite") > 0) then
		return
	end

	local C = JtpConfig.act6
	local prop = C.items.propLight

	if (side == 2) then
		prop = C.items.propDark
	end

	JtpTheaters:build(pPlayer, {
		planet = C.enclaves[side].planet, cell = C.enclaves[side].riteCell,
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY(),
		props = {
			{ prop, -2.2, 0, 1.6 },
			{ prop, 2.2, 0, 1.6 },
		},
		lifetimeSec = 300,
		tag = "act6_rite",
	})

	local sui = SuiMessageBox.new("JediParkAct6", "riteBoardCallback")
	sui.setTitle(FLAVOR[side].q1 .. " (1 of 2)")

	if (side == 1) then
		sui.setPrompt("The training hall has been cleared of everything except light. Whoever set the two stones did it hours ago and left no footprints.\n\nMaro's voice from the doorway, level as a ruled line: \"The Circle was never its famous dead. It was whoever swept the floor before the students came — and whoever holds the FLOOR now that the students are the council. Sit among embers, Master. The hall holds your name with the kept.\"\n\nYou sit. The hall does not creak. It has been waiting to be this quiet.")
	else
		sui.setPrompt("Council Four keeps its own darkness — the room the hierarchy opens at the eighth rank, and the chair in it that nobody has warmed since the Purge did its arithmetic.\n\nThe Voice did not climb the ramps with you, and is somehow at the wall anyway. \"Sit. The Emperor's ledger acquires a verb tonight: CONVENES.\"\n\nYou sit. The dark accepts the weight without comment, which from this room is a ceremony.")
	end

	sui.sendTo(pPlayer)
end

function JediParkAct6:riteBoardCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0 or not M:hasStarted(pPlayer, 6, 1) or M:hasDone(pPlayer, 6, 1)) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		return
	end

	-- Beat 2: the war board — the Silent War goes loud.
	self:completeQuest(pPlayer, 1)
	JtpTheaters:teardown(pPlayer, "act6_rite")

	if (side == 1) then
		self:sui(pPlayer, FLAVOR[1].q1 .. " (2 of 2) — the War Board", "Maro unrolls a map you have never been shown: every Force shrine on ten worlds, pinned. Too many pins are red.\n\n\"The Silent War has stopped being silent. The Prophets of the Dark Side move on the wells themselves now — openly, in strength, on a budget with the Emperor's handwriting on it. A council's first work is triage.\" He sets three unmarked pins in your palm. \"Yours. The board will tell you which wells are bleeding tonight. Hold them.\"\n\n(Return to Keeper Maro for the contested wells.)")
	else
		self:sui(pPlayer, FLAVOR[2].q1 .. " (2 of 2) — the Ledger of Wells", "The Voice's briefing is a single sheet, and the sheet is a list of wells.\n\n\"The Circle's zealot cells have stopped answering writs — light-drunk, self-consecrated, camping in the network's own shrines as if faith were a garrison. The Emperor's interest is the NETWORK. Unlicensed faith is a paperwork error.\" A pen crosses three lines, precisely. \"Yours. Correct them.\"\n\n(Return to the Hand's Voice for the claimed wells.)")
	end
end

-- ---- quest openers -----------------------------------------------------------

function JediParkAct6:beginQuest(pPlayer, side, quest)
	local M = JediParkManager
	local F = FLAVOR[side]
	local C = JtpConfig.act6

	if (M:hasStarted(pPlayer, 6, quest)) then
		return
	end

	M:setStarted(pPlayer, 6, quest)

	if (quest == 2) then
		dataSet(pPlayer, "act6_wells", 0)
		local site = self:wellSite(pPlayer, 1)

		if (side == 1) then
			self:sui(pPlayer, F.q2, "\"Three wells are under the Prophets' knives tonight. Hold them — one at a time; a council seat is not two places at once.\" (Stand at each contested well and take the engagement. First well: " .. self:wellSiteText(site) .. ". The board will re-mark the next when the first stands.)")
		else
			self:sui(pPlayer, F.q2, "\"Three wells shelter zealot cells that answer to no writ. Correct the paperwork — sequentially; the Emperor's instruments do not smear.\" (Travel to each claimed well and break the cell squatting on it. First well: " .. self:wellSiteText(site) .. ". The ledger advances as each entry closes.)")
		end

	elseif (quest == 3) then
		local ch = C.champions

		if (side == 1) then
			self:sui(pPlayer, F.q3, "\"The Prophets answer escalation with their seniors: two of them, with retinue, hold the Endor well as of this morning. The Circle holds YOU.\" (Travel to the Endor shrine near " .. ch.x .. " " .. ch.y .. " and break the seniors' claim on the well.)")
		else
			self:sui(pPlayer, F.q3, "\"The zealots consecrate 'champions' now — light-drunk duelists sworn to die interestingly. Three of them have claimed the Endor well as a pulpit.\" The Voice's pen does not pause. \"Oblige them.\" (Travel to the Endor shrine near " .. ch.x .. " " .. ch.y .. " and close the sermon.)")
		end

	elseif (quest == 4) then
		if (side == 1) then
			self:sui(pPlayer, F.q4, "\"Ondel's last pattern is two patterns — the same pike, drawn twice by two hands that hated each other for four thousand years.\" Maro sets a courier case on the ledger, unopened. \"He sends you the one your hands have earned. Ask for the ceremony when you are ready to receive it.\"")
		else
			self:sui(pPlayer, F.q4, "\"The archivist under Dantooine trades with anyone who reads — and he has read YOU since the tenth well.\" A courier case waits at the Voice's elbow, already inspected, pointedly resealed. \"Ondel's pike, the dark drawing. Ask for the ceremony when you are ready to hold it.\"")
		end

	elseif (quest == 5) then
		if (side == 1) then
			local f = C.forty
			self:sui(pPlayer, F.q5, "\"Every war has an address at the end. Theirs is the first well — Dathomir, where a statue nobody built has watched the road since before roads.\" Maro's finger lands on the map's oldest pin. \"A Master Prophet brings the Emperor's answer to the Circle tonight. Bring the Circle's answer to him.\" (Travel to the Dathomir shrine near " .. f.x .. " " .. f.y .. " and stand the defense of the Forty-Sixth.)")
		else
			local k = C.kneel
			self:sui(pPlayer, F.q5, "\"One name remains on the ledger of the Silent War.\" The Voice lets the sheet lie face-up, which it has never done. Veshaan, High Witch, Singing Mountain. \"The Circle's oldest ally. The Emperor's instruments do not keep sentimental appendices.\" A pause with no mercy in it, only precision. \"She will know why you have come. She has always known.\" (Travel to the Mountain approach near " .. k.x .. " " .. k.y .. ", Dathomir. EXTERIOR ground — the stronghold is not yours to enter.)")
		end

	elseif (quest == 6) then
		if (side == 1) then
			self:sui(pPlayer, F.q6, "\"The war is answered and the ledger is balanced — all but one line, and that line is a ceremony.\" Maro almost smiles. \"The Wanderer is waiting in the training hall. He has taken off exactly one hood in thirty years, and he is about to make it two.\" (Walk into the training hall.)")
		else
			local r = C.retreat
			self:sui(pPlayer, F.q6, "\"The summons is to Naboo. The Emperor's own retreat.\" For the first time, the Voice faces you entirely. \"You are not admitted. THAT IS THE HONOR — you will stand on the approach among the guard towers, and what comes down to meet you carries eleven words that are not his own. Hear them standing.\" (Travel to the Retreat approach near " .. r.x .. " " .. r.y .. ", Naboo, and wait on the open ground. Touch nothing. Greet no one.)")
		end
	end
end

-- ---- the giver menu (act4 menuKeys pattern) ----------------------------------

function JediParkAct6:giverMenu(pPlayer, side)
	local M = JediParkManager
	local F = FLAVOR[side]
	local C = JtpConfig.act6
	local options = {}

	-- Linear spine; *_start branches self-heal a missing started bit.
	if (not M:hasDone(pPlayer, 6, 1)) then
		if (side == 1) then
			options[#options + 1] = { "q1_hint", "Ask about the rite (walk into the training hall)" }
		else
			options[#options + 1] = { "q1_hint", "Ask about the chair (ascend to Council Four)" }
		end
	elseif (not M:hasStarted(pPlayer, 6, 2)) then
		options[#options + 1] = { "q2_start", "Ask which wells are bleeding (Begin: " .. F.q2 .. ")" }
	elseif (not M:hasDone(pPlayer, 6, 2)) then
		if (dataNum(pPlayer, "act6_wells") >= C.wells.sites) then
			options[#options + 1] = { "q2_turnin", "\"Three wells stand.\" (Turn in: " .. F.q2 .. ")" }
		else
			options[#options + 1] = { "q2_hint", "Ask about the wells (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 6, 3)) then
		options[#options + 1] = { "q3_start", "Ask about the Endor well (Begin: " .. F.q3 .. ")" }
	elseif (not M:hasDone(pPlayer, 6, 3)) then
		options[#options + 1] = { "q3_hint", "Ask about the champions (progress)" }
	elseif (not M:hasStarted(pPlayer, 6, 4)) then
		options[#options + 1] = { "q4_start", "Ask about Ondel's last pattern (Begin: " .. F.q4 .. ")" }
	elseif (not M:hasDone(pPlayer, 6, 4)) then
		options[#options + 1] = { "q4_rite", "Receive the pattern (" .. F.q4 .. " — ceremony)" }
	elseif (not M:hasStarted(pPlayer, 6, 5)) then
		options[#options + 1] = { "q5_start", "Ask for the last address (Begin: " .. F.q5 .. " — finale)" }
	elseif (not M:hasDone(pPlayer, 6, 5)) then
		options[#options + 1] = { "q5_hint", "Ask about the finale (progress)" }
	elseif (not M:hasStarted(pPlayer, 6, 6)) then
		options[#options + 1] = { "q6_start", "Ask what remains (Begin: " .. F.q6 .. " — epilogue)" }
	elseif (not M:hasDone(pPlayer, 6, 6)) then
		if (side == 1) then
			options[#options + 1] = { "q6_hint", "Ask about the unhooding (walk into the training hall)" }
		else
			if (dataNum(pPlayer, "act6_judged") == 1) then
				options[#options + 1] = { "q6_ceremony", "\"The eleven words are delivered.\" (Ceremony: " .. F.q6 .. ")" }
			else
				options[#options + 1] = { "q6_hint", "Ask about the summons (the Retreat approach)" }
			end
		end
	else
		options[#options + 1] = { "road_ahead", "Ask about the road past the Reckoning" }
	end

	if (dataNum(pPlayer, "act6_shard_due") == 1) then
		options[#options + 1] = { "shard_claim", "Receive the Shard of the Silent War (held for you)" }
	end

	options[#options + 1] = { "wells_count", "Ask how many wells you have walked." }

	local keys = {}
	local sui = SuiListBox.new("JediParkAct6", "giverMenuCallback")
	sui.setTitle(F.giver)

	if (side == 1) then
		sui.setPrompt("\"The council is sitting. Speak.\"")
	else
		sui.setPrompt("\"The Reckoning is convened. Speak. Once.\"")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "act6_menukeys", table.concat(keys, ","))
	dataSet(pPlayer, "act6_menu_giver", side)
	sui.sendTo(pPlayer)
end

function JediParkAct6:giverMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act6_menukeys")
	dataSet(pPlayer, "act6_menukeys", "")

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
	if (side == 0 or side ~= dataNum(pPlayer, "act6_menu_giver")) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		if (self:gateState(pPlayer) == "pause") then
			self:sendPauseNotice(pPlayer)
		end
		return
	end

	local F = FLAVOR[side]
	local C = JtpConfig.act6

	if (action == "q1_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q1, "\"The training hall, next door. The stones are set; the hall is quiet on purpose. Sit, and the rite will know what to do with you.\"")
		else
			self:sui(pPlayer, F.q1, "\"Up the ramps to Council Four — the room the hierarchy opens at your rank. Council Two stays empty; its chair is a caution, not a vacancy. Yours waits above.\"")
		end

	elseif (action == "q2_start") then
		if (M:hasDone(pPlayer, 6, 1)) then
			self:beginQuest(pPlayer, side, 2)
		end

	elseif (action == "q2_hint") then
		local done = dataNum(pPlayer, "act6_wells")
		local site = self:wellSite(pPlayer, math.min(C.wells.sites, done + 1))

		self:attachKillObserver(pPlayer)

		if (side == 1) then
			self:sui(pPlayer, F.q2, "\"" .. done .. " of " .. C.wells.sites .. " wells held. The board marks your next: " .. self:wellSiteText(site) .. ". Stand at the well and take the engagement — and do not leave while it stands.\"")
		else
			self:sui(pPlayer, F.q2, "\"" .. done .. " of " .. C.wells.sites .. " entries corrected. The next line: " .. self:wellSiteText(site) .. ". The cell is camped on the well itself. The lieutenant signs last.\"")
		end

	elseif (action == "q2_turnin") then
		if (M:hasStarted(pPlayer, 6, 2) and not M:hasDone(pPlayer, 6, 2) and dataNum(pPlayer, "act6_wells") >= C.wells.sites) then
			self:completeQuest(pPlayer, 2, 0)  -- the 3x10k was paid per site

			if (side == 1) then
				self:sui(pPlayer, F.q2, "\"Three wells, three dawns, zero eulogies.\" Maro pulls three red pins and does not replace them with anything, which is the whole point. \"The Prophets will file it as weather. Let them. Weather is what we are now — reliable, seasonal, and impossible to arrest.\"")
			else
				self:sui(pPlayer, F.q2, "\"Three entries, closed in your hand.\" The Voice draws one line through three names with visible satisfaction, which is to say none. \"The network breathes without permission again. The Emperor's interest is served; the servants were not consulted. Symmetry.\"")
			end

			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_start") then
		if (M:hasDone(pPlayer, 6, 2)) then
			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_hint") then
		local ch = C.champions
		self:attachKillObserver(pPlayer)

		if (side == 1) then
			self:sui(pPlayer, F.q3, "\"The Endor well, near " .. ch.x .. " " .. ch.y .. ". Two seniors and their retinue. They will not talk first — seniors are promoted past talking. Neither are you, anymore.\"")
		else
			self:sui(pPlayer, F.q3, "\"The Endor well, near " .. ch.x .. " " .. ch.y .. ". Three champions, consecrated and sworn to die interestingly, plus the audience they brought. Give the audience something accurate to remember.\"")
		end

	elseif (action == "q4_start") then
		if (M:hasDone(pPlayer, 6, 3)) then
			self:beginQuest(pPlayer, side, 4)
		end

	elseif (action == "q4_rite") then
		if (M:hasStarted(pPlayer, 6, 4) and not M:hasDone(pPlayer, 6, 4)) then
			self:offerPattern(pPlayer, side)
		end

	elseif (action == "q5_start") then
		if (M:hasDone(pPlayer, 6, 4)) then
			self:beginQuest(pPlayer, side, 5)
		end

	elseif (action == "q5_hint") then
		self:attachKillObserver(pPlayer)

		if (side == 1) then
			local f = C.forty

			if (dataNum(pPlayer, "act6_forty_waves") == 1) then
				self:sui(pPlayer, F.q5, "\"The waves are broken and the Answer himself is on the ground. Finish it — the first well watches, and so does everything the first well answers to.\"")
			else
				self:sui(pPlayer, F.q5, "\"The Dathomir shrine near " .. f.x .. " " .. f.y .. " — the old statue's road. Stand at the well and say the word; the Prophets have already RSVP'd. Four pushes, then the Emperor's answer in person.\"")
			end
		else
			local k = C.kneel
			self:sui(pPlayer, F.q5, "\"The approach below the Mountain, near " .. k.x .. " " .. k.y .. ". She will come down to meet you — high witches do not die indoors.\" A beat. \"The stronghold itself stays sealed to you. The Emperor buys outcomes, not architecture.\"")
		end

	elseif (action == "q6_start") then
		if (M:hasDone(pPlayer, 6, 5)) then
			self:beginQuest(pPlayer, side, 6)
		end

	elseif (action == "q6_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q6, "\"The training hall. He is already there. He has been there, one suspects, for thirty years.\"")
		else
			local r = C.retreat
			self:sui(pPlayer, F.q6, "\"The Retreat approach near " .. r.x .. " " .. r.y .. ", Naboo. Stand on the open ground below the towers and wait. What comes down the causeway is not a negotiation.\"")
		end

	elseif (action == "q6_ceremony") then
		if (side == 2 and M:hasStarted(pPlayer, 6, 6) and not M:hasDone(pPlayer, 6, 6) and dataNum(pPlayer, "act6_judged") == 1) then
			self:finishActDark(pPlayer)
		end

	elseif (action == "shard_claim") then
		if (dataNum(pPlayer, "act6_shard_due") == 1) then
			local pItem = M:giveNamedItem(pPlayer, C.items.token, C.items.shardName)

			if (pItem == nil) then
				CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. The Shard will be held — ask for it again.")
			else
				dataSet(pPlayer, "act6_shard_due", 0)
				CreatureObject(pPlayer):sendSystemMessage("The Shard of the Silent War is yours. It is very light for what it carries.")
			end
		end

	elseif (action == "road_ahead") then
		if (side == 1) then
			self:sui(pPlayer, "The Road Past the Reckoning", "\"The war is answered; the network breathes; the council sits. What remains is maintenance — which is the noblest word the Circle knows.\" Maro re-inks the ledger's first blank page. \"The wells will always want walking, and the Prophets will always send somebody. The hall will have weekly work for its Master. (Epilogue repeatables arrive in a later update.)\"")
		else
			self:sui(pPlayer, "The Road Past the Reckoning", "\"The ledger balances. The Emperor is aware of you — you have that in eleven words, which is ten more than most instruments receive in a lifetime.\" The Voice returns to the wall. \"The zealots will re-grow. Instruments keep their edges. (Epilogue repeatables arrive in a later update.)\"")
		end

	elseif (action == "wells_count") then
		self:sui(pPlayer, "The Pilgrim's Ledger", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. JtpConfig.shrineTotal() .. " wells, walked in a lifetime of walking. The network only exists while someone walks it — and tonight, someone with a seat.\"")
	end
end

-- ---- site dispatch -----------------------------------------------------------

function JediParkAct6:onEnterSite(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	local areaID = SceneObject(pArea):getObjectID()
	local kind = readStringData(areaID .. ":jtpAct6Kind")
	local side = readData(areaID .. ":jtpAct6Side") or 0

	if (kind == nil or kind == "") then
		return 0
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		return 0
	end

	if (side ~= 0 and M:sideOf(pPlayer) ~= side) then
		return 0
	end

	-- Grace-floor hold: paused players stage nothing (state untouched).
	if (not self:gateOk(pPlayer)) then
		return 0
	end

	if (kind == "ritelight") then
		self:enterRite(pPlayer, 1)
	elseif (kind == "ritedark") then
		self:enterRite(pPlayer, 2)
	elseif (kind == "champ") then
		self:enterChampions(pPlayer)
	elseif (kind == "forty") then
		self:enterForty(pPlayer)
	elseif (kind == "kneel") then
		self:enterKneel(pPlayer)
	elseif (kind == "retreat") then
		self:enterRetreat(pPlayer)
	end

	return 0
end

-- ---- Q6.2: the contested/claimed wells ---------------------------------------
-- Route: the MAIN LOOP wires JtpShrines:onEnterShrine to call this BEFORE
-- its first-visit dedupe (act6 wells rotate over already-walked shrines,
-- so the visit-credit early-out must not swallow the entry).

function JediParkAct6:onShrineEntered(pPlayer, planet, index)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 6, 2) or M:hasDone(pPlayer, 6, 2)) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		return
	end

	local C = JtpConfig.act6
	local done = dataNum(pPlayer, "act6_wells")

	if (done >= C.wells.sites) then
		return
	end

	local site = self:wellSite(pPlayer, done + 1)

	if (site == nil or site.planet ~= planet or site.index ~= index) then
		return
	end

	local side = M:sideOf(pPlayer)

	if (side == 1) then
		-- One engagement at a time (plan AC): a live wave run holds the
		-- slot. totalWaves == 0 means the spec died with a restart —
		-- documented waveStatus contract: treat as lapsed and clear.
		local active, _, _, totalWaves = JtpTheaters:waveStatus(pPlayer, "act6_well")

		if (active and totalWaves == 0) then
			JtpTheaters:stopWaves(pPlayer, "act6_well")
			active = false
		end

		if (active) then
			return
		end

		local sui = SuiListBox.new("JediParkAct6", "wellStartCallback")
		sui.setTitle(FLAVOR[1].q2)
		sui.setPrompt("The well is quiet the way a held breath is quiet. Past the light of the stones, lights that are not stones are pretending to be stones. The Prophets' strike team is early. So is the council. (Well " .. (done + 1) .. " of " .. C.wells.sites .. " — two pushes, then the lieutenant.)")
		sui.add("Hold the well. (Begin the engagement)", "")
		sui.add("Not yet.", "")
		sui.sendTo(pPlayer)
	else
		if (self:liveCount(pPlayer, "act6_camp") > 0) then
			return
		end

		self:buildWellCamp(pPlayer)
	end
end

function JediParkAct6:wellStartCallback(pPlayer, pSui, eventIndex, args)
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

	if (not M:hasStarted(pPlayer, 6, 2) or M:hasDone(pPlayer, 6, 2)) then
		return
	end

	local C = JtpConfig.act6
	local done = dataNum(pPlayer, "act6_wells")

	if (done >= C.wells.sites) then
		return
	end

	local active, _, _, totalWaves = JtpTheaters:waveStatus(pPlayer, "act6_well")

	if (active and totalWaves > 0) then
		return
	end

	-- The engagement rings the WELL itself (live shrine position; the
	-- player is standing in its shrine area by construction).
	local anchorX, anchorY = self:wellAnchor(pPlayer, self:wellSite(pPlayer, done + 1))
	local started = JtpTheaters:startWaves(pPlayer, {
		planet = SceneObject(pPlayer):getZoneName(),
		x = anchorX,
		z = 0,
		y = anchorY,
		waves = C.wells.wavesLight,
		tag = "act6_well",
		abortSec = C.wells.abortSec,
		ringMin = C.wells.ringMin, ringMax = C.wells.ringMax,
		onComplete = { screenplay = "JediParkAct6", fn = "onWellHeld" },
	})

	if (started) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q2 .. ": the false stones go dark. The strike team comes out of the treeline.")
	end
end

function JediParkAct6:onWellHeld(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not M:hasStarted(pPlayer, 6, 2) or M:hasDone(pPlayer, 6, 2)) then
		return
	end

	self:wellSiteWon(pPlayer)
end

-- D: the staged zealot camp at the current rotation well.
function JediParkAct6:buildWellCamp(pPlayer)
	local C = JtpConfig.act6
	local W = C.wells
	local mobs = {}

	for i = 1, #W.campDark, 1 do
		local g = W.campDark[i]
		mobs[#mobs + 1] = { g[1], g[2], 0, g[3], 0, W.zealotName }
	end

	local anchorX, anchorY = self:wellAnchor(pPlayer, self:wellSite(pPlayer, dataNum(pPlayer, "act6_wells") + 1))
	local built = JtpTheaters:build(pPlayer, {
		planet = SceneObject(pPlayer):getZoneName(),
		x = anchorX,
		z = 0,
		y = anchorY,
		mobs = mobs,
		lifetimeSec = W.campLifetimeSec,
		tag = "act6_camp",
	})

	if (built == nil or #built.mobs == 0) then
		return
	end

	dataSet(pPlayer, "act6_camp_left", #built.mobs)
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q2 .. ": the zealot cell rises from the well's shadow — four blades and the lieutenant who signs for them. Correct the entry. (Well " .. (dataNum(pPlayer, "act6_wells") + 1) .. " of " .. JtpConfig.act6.wells.sites .. ")")
end

-- A well stage is won (either side): pay the site, advance the rotation.
function JediParkAct6:wellSiteWon(pPlayer)
	local M = JediParkManager
	local C = JtpConfig.act6
	local done = dataNum(pPlayer, "act6_wells") + 1

	dataSet(pPlayer, "act6_wells", done)
	dataSet(pPlayer, "act6_camp_left", 0)
	M:awardFrsXp(pPlayer, C.frsPerWellSite)

	local side = M:sideOf(pPlayer)

	if (done >= C.wells.sites) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q2 .. ": the third well stands answered. Return to " .. FLAVOR[side].giver .. ".")
	else
		local nextSite = self:wellSite(pPlayer, done + 1)
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q2 .. ": " .. done .. " of " .. C.wells.sites .. " wells answered. The board marks your next: " .. self:wellSiteText(nextSite) .. ".")
	end
end

-- ---- Q6.3: the Endor well set-piece ------------------------------------------

function JediParkAct6:enterChampions(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 6, 3) or M:hasDone(pPlayer, 6, 3)) then
		return
	end

	if (self:liveCount(pPlayer, "act6_champ") > 0) then
		return
	end

	local C = JtpConfig.act6
	local ch = C.champions
	local side = M:sideOf(pPlayer)
	local source = ch.mobsLight

	if (side == 2) then
		source = ch.mobsDark
	end

	local mobs = {}

	for i = 1, #source, 1 do
		local m = source[i]
		mobs[#mobs + 1] = { m[1], m[2], 0, m[3], 180, m[4] }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = ch.planet,
		x = SceneObject(pPlayer):getWorldPositionX(),
		z = 0,
		y = SceneObject(pPlayer):getWorldPositionY(),
		mobs = mobs,
		lifetimeSec = ch.lifeSec,
		tag = "act6_champ",
	})

	if (built == nil or #built.mobs == 0) then
		return
	end

	dataSet(pPlayer, "act6_champ_left", #built.mobs)
	self:attachKillObserver(pPlayer)

	for i = 1, #built.mobs, 1 do
		AiAgent(built.mobs[i]):setDefender(pPlayer)
	end

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q3 .. ": two senior prophets turn from the well as one, unhurried — seniors are promoted past hurry. Their retinue is not.")
	else
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q3 .. ": three consecrated champions rise from their vigil, delighted. They have been promised an interesting death. Keep the promise.")
	end
end

function JediParkAct6:championsWon(pPlayer)
	local M = JediParkManager
	local C = JtpConfig.act6
	local side = M:sideOf(pPlayer)

	self:completeQuest(pPlayer, 3, C.frsChampions)

	local pItem = M:giveNamedItem(pPlayer, C.items.token, C.items.coreName)

	if (pItem ~= nil) then
		dataSet(pPlayer, "act6_core", 1)
	else
		-- Flag-item only; the pattern ceremony proceeds on the quest bit.
		dataSet(pPlayer, "act6_core", 1)
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full — the focusing core's provenance is recorded anyway; the pattern will not mind.")
	end

	if (side == 1) then
		self:sui(pPlayer, FLAVOR[1].q3, "The second senior falls across the first, and the Endor well goes back to sounding like water. Among the champions' effects: a focusing core, machined four thousand years ago to a tolerance nobody alive can measure — the heart Ondel's pike has been waiting for.\n\nReturn to Keeper Maro.")
	else
		self:sui(pPlayer, FLAVOR[2].q3, "The third champion dies interestingly, as sworn, and the audience of zealots stops being an audience. On the pulpit stone: a focusing core older than their whole heresy — the heart Ondel's pike has been waiting for.\n\nReturn to the Hand's Voice.")
	end
end

-- ---- Q6.4: the Pattern of the Pike (Phase A ceremony) ------------------------
-- Grants the ceremonial pattern + the pending flag; the CRAFTABLE side
-- schematic is Phase C client work. JediPark bit 4096 is NOT set here —
-- Phase C sets it when the real schematic lands (task contract).

local function patternNote(side)
	if (side == 1) then
		return "The Pattern of the Pike — Light is yours. (The pike schematic 'Pike of the Unbroken Light' arrives with the client update; the pattern and the focusing core will be honored then.)"
	end

	return "The Pattern of the Pike — Dark is yours. (The pike schematic 'Pike of the Unseen Hand' arrives with the client update; the pattern and the focusing core will be honored then.)"
end

function JediParkAct6:offerPattern(pPlayer, side)
	local F = FLAVOR[side]
	local sui = SuiListBox.new("JediParkAct6", "patternCallback")
	sui.setTitle(F.q4)

	if (side == 1) then
		sui.setPrompt("Maro opens the courier case with both thumbs, the way one opens a reliquary. Inside, on linen: a pattern in Ondel's crabbed hand — a pike, drawn with the patience of a man who knew he was drawing it for the last time. \"The light's drawing. Four thousand years of argument, and the argument's answer is: the same blade, held differently.\" (Receive the Pattern of the Pike. The craftable schematic itself arrives with the client update.)")
	else
		sui.setPrompt("The Voice slides the courier case across without touching the pattern inside — a pike in Ondel's crabbed hand, annotated in a second hand that is older and angrier. \"The dark drawing. The same blade the light carries, held with the truth about holding.\" (Receive the Pattern of the Pike. The craftable schematic itself arrives with the client update.)")
	end

	sui.add("Receive the pattern. (Complete the ceremony)", "")
	sui.add("\"Not yet.\"", "")
	sui.sendTo(pPlayer)
end

function JediParkAct6:patternCallback(pPlayer, pSui, eventIndex, args)
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

	if (not M:hasStarted(pPlayer, 6, 4) or M:hasDone(pPlayer, 6, 4)) then
		return
	end

	local C = JtpConfig.act6
	local patternName = C.items.patternLightName

	if (side == 2) then
		patternName = C.items.patternDarkName
	end

	M:giveNamedItem(pPlayer, C.items.token, patternName)
	dataSet(pPlayer, "act6_schematic_pending", 1)
	self:completeQuest(pPlayer, 4)
	M:log(pPlayer, "act6 pattern ceremony — schematic pending (Phase C)")

	CreatureObject(pPlayer):sendSystemMessage(patternNote(side))
	self:beginQuest(pPlayer, side, 5)
end

-- ---- Q6.5L: THE FORTY-SIXTH (flagship defense) -------------------------------

function JediParkAct6:enterForty(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 6, 5) or M:hasDone(pPlayer, 6, 5)) then
		return
	end

	local C = JtpConfig.act6

	if (dataNum(pPlayer, "act6_forty_waves") == 1) then
		-- Wave phase held; the boss phase self-heals across restarts.
		if (self:liveCount(pPlayer, "act6_boss") == 0) then
			self:buildFortyBoss(pPlayer)
		end

		return
	end

	-- Restart-lapse handling (documented waveStatus contract: total == 0
	-- means the spec died with a restart — clear and re-offer).
	local active, _, _, totalWaves = JtpTheaters:waveStatus(pPlayer, "act6_forty")

	if (active and totalWaves == 0) then
		JtpTheaters:stopWaves(pPlayer, "act6_forty")
		active = false
	end

	if (active) then
		return
	end

	local sui = SuiListBox.new("JediParkAct6", "fortyStartCallback")
	sui.setTitle(FLAVOR[1].q5)
	sui.setPrompt("The first well. The statue nobody built watches the road the way it has watched since before roads, and tonight the road is full: prophet lights in the witch-dark, moving with a budget's confidence. Somewhere behind them walks the Emperor's answer to the Circle.\n\nThe Circle's answer is already standing at the well. (Begin the defense: 4 waves, then the Answer himself. Leaving the fight for fifteen minutes forfeits the attempt.)")
	sui.add("Stand the Forty-Sixth. (Begin the defense)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct6:fortyStartCallback(pPlayer, pSui, eventIndex, args)
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

	if (not M:hasStarted(pPlayer, 6, 5) or M:hasDone(pPlayer, 6, 5) or dataNum(pPlayer, "act6_forty_waves") == 1) then
		return
	end

	local active, _, _, totalWaves = JtpTheaters:waveStatus(pPlayer, "act6_forty")

	if (active and totalWaves > 0) then
		return
	end

	local f = JtpConfig.act6.forty
	local started = JtpTheaters:startWaves(pPlayer, {
		planet = f.planet,
		x = SceneObject(pPlayer):getWorldPositionX(),
		z = 0,
		y = SceneObject(pPlayer):getWorldPositionY(),
		waves = f.waves,
		tag = "act6_forty",
		abortSec = f.abortSec,
		ringMin = f.ringMin, ringMax = f.ringMax,
		onComplete = { screenplay = "JediParkAct6", fn = "onFortyWavesHeld" },
	})

	if (started) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": the prophet lights go out all at once — which is how prophets say 'begin.'")
	end
end

function JediParkAct6:onFortyWavesHeld(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not M:hasStarted(pPlayer, 6, 5) or M:hasDone(pPlayer, 6, 5)) then
		return
	end

	dataSet(pPlayer, "act6_forty_waves", 1)
	self:buildFortyBoss(pPlayer)
end

function JediParkAct6:buildFortyBoss(pPlayer)
	local C = JtpConfig.act6
	local f = C.forty
	local anchorX = SceneObject(pPlayer):getWorldPositionX()
	local anchorY = SceneObject(pPlayer):getWorldPositionY()

	local built = JtpTheaters:build(pPlayer, {
		planet = f.planet,
		x = anchorX,
		z = 0,
		y = anchorY,
		mobs = {
			{ f.bossTemplate, 0, 0, 14, 180, f.bossName },
			{ f.addTemplate, -5, 0, 17, 180 },
			{ f.addTemplate, 5, 0, 17, 180 },
		},
		lifetimeSec = f.bossLifeSec,
		tag = "act6_boss",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	-- The Q4.S2L payoff: if the Mountain was warned, her daughters stand
	-- witness — invulnerable flavor allies in their OWN tag (Phase A
	-- simplification: named props, no combat assist; kept out of the
	-- combat build so they can never be pressed into the fight).
	if (dataNum(pPlayer, "act4_veshaan_warned") == 1) then
		local w1 = { f.witnessTemplate, -14, 0, -4, 45, f.witnessName }
		w1.invuln = true
		local w2 = { f.witnessTemplate, 14, 0, -4, -45, f.witnessName }
		w2.invuln = true

		JtpTheaters:build(pPlayer, {
			planet = f.planet,
			x = anchorX,
			z = 0,
			y = anchorY,
			mobs = { w1, w2 },
			lifetimeSec = f.bossLifeSec,
			tag = "act6_witness",
		})
	end

	dataSet(pPlayer, "act6_boss_oid", tostring(SceneObject(built.mobs[1]):getObjectID()))
	self:attachKillObserver(pPlayer)

	-- The Answer and his retinue press immediately (no parley — he IS the
	-- reply). Witnesses stay staged invulnerable.
	for i = 1, #built.mobs, 1 do
		local pMob = built.mobs[i]

		if (pMob ~= nil and SceneObject(pMob):isCreatureObject() and not CreatureObject(pMob):isDead()) then
			AiAgent(pMob):setDefender(pPlayer)
		end
	end

	if (dataNum(pPlayer, "act4_veshaan_warned") == 1) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": the waves break, and the Emperor's Answer walks out of the witch-dark with two seniors at heel — and on the rocks above, two sisters of the Singing Mountain stand witness. The Mountain pays its debts by WATCHING them get paid.")
	else
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": the waves break, and the Emperor's Answer walks out of the witch-dark with two seniors at heel. The statue watches. It has watched worse arrive and not leave.")
	end
end

function JediParkAct6:fortyWon(pPlayer)
	local C = JtpConfig.act6

	self:completeQuest(pPlayer, 5, C.frsFinale)

	if (dataNum(pPlayer, "act4_veshaan_warned") == 1) then
		self:sui(pPlayer, FLAVOR[1].q5, "The Emperor's Answer dies the way a sentence ends — completely, and with the argument still unresolved on his face. His seniors do not re-form. On the rocks, the two sisters of the Mountain incline their heads — the clans' whole vocabulary of applause — and are gone before the wind finishes.\n\nThe Silent War asked its last question here tonight. You were the answer, and the Mountain witnessed it.\n\nReturn to Keeper Maro. The hall has one ceremony left in it.")
	else
		self:sui(pPlayer, FLAVOR[1].q5, "The Emperor's Answer dies the way a sentence ends — completely, and with the argument still unresolved on his face. His seniors do not re-form. The first well keeps making its small water-sound, which four thousand years of prophets have failed to interrupt.\n\nThe Silent War asked its last question here tonight. You were the answer.\n\nReturn to Keeper Maro. The hall has one ceremony left in it.")
	end

	-- Clean despawn for the whole scene, witnesses included (plan AC).
	createEvent(8 * 1000, "JediParkAct6", "teardownTag", pPlayer, "act6_boss")
	createEvent(8 * 1000, "JediParkAct6", "teardownTag", pPlayer, "act6_witness")
end

-- ---- Q6.5D: THE MOUNTAIN MUST KNEEL (flagship boss) --------------------------
-- Talk-then-fight at the approach-EXTERIOR anchor. Veshaan stages
-- invulnerable (jtp_veshaan chassis) with two SMC arch witches; the
-- parley SUI flips the scene attackable (the act3 flip idiom, plus
-- setOptionsBitmask(0) because the giver chassis is template-
-- INVULNERABLE). Level-100 chassis is UNDERTUNED for an apex finale —
-- flagged for Phase B tuning (see config note).

function JediParkAct6:enterKneel(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 6, 5) or M:hasDone(pPlayer, 6, 5)) then
		return
	end

	if (self:liveCount(pPlayer, "act6_boss") > 0) then
		if (dataNum(pPlayer, "act6_kneel_flipped") == 0) then
			self:offerKneelParley(pPlayer)
		end

		return
	end

	local k = JtpConfig.act6.kneel
	local boss = { k.bossTemplate, 0, 0, 12, 180, k.bossName }
	boss.invuln = true
	local add1 = { k.addTemplate, -6, 0, 15, 180 }
	add1.invuln = true
	local add2 = { k.addTemplate, 6, 0, 15, 180 }
	add2.invuln = true

	local built = JtpTheaters:build(pPlayer, {
		planet = k.planet, x = k.x, z = 0, y = k.y,
		mobs = { boss, add1, add2 },
		lifetimeSec = k.lifeSec,
		tag = "act6_boss",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	dataSet(pPlayer, "act6_boss_oid", tostring(SceneObject(built.mobs[1]):getObjectID()))
	dataSet(pPlayer, "act6_kneel_flipped", 0)
	self:attachKillObserver(pPlayer)
	self:offerKneelParley(pPlayer)
end

function JediParkAct6:offerKneelParley(pPlayer)
	local sui = SuiListBox.new("JediParkAct6", "kneelParleyCallback")
	sui.setTitle(FLAVOR[2].q5)

	local prompt

	if (dataNum(pPlayer, "act2_witches") == 1) then
		prompt = "She is on the rocks above the approach before you see her arrive — she always is. Two arch witches flank her, still as weather about to happen.\n\n\"An off-worlder who KNOCKS,\" Veshaan says — your own first porch-greeting, handed back across two years and one whole war. \"I marked you the day you knocked, dark thing. Politeness is how ambition introduces itself.\" She descends one step; the mountain seems to descend with her. \"The Emperor's ledger has one name left, and it is mine, and they sent the one who knocked. Good. The Mountain prefers to be killed by someone with manners.\""
	else
		prompt = "She is on the rocks above the approach before you see her arrive — she always is. Two arch witches flank her, still as weather about to happen.\n\n\"The Hand's instrument,\" Veshaan says, in the register the Mountain keeps for weather and debts. \"The ledger of your Silent War has one name left, and it is mine. I have known since before your Voice knew.\" She descends one step; the mountain seems to descend with her. \"The Mountain does not kneel, little instrument. It has practiced not-kneeling for ten thousand years. Show me what the Emperor sends instead of winter.\""
	end

	sui.setPrompt(prompt)
	sui.add("\"The ledger closes tonight.\" (Begin the fight)", "")
	sui.add("\"Kneel, and the name is struck instead.\" (She will not. Begin the fight)", "")
	sui.sendTo(pPlayer)
end

function JediParkAct6:kneelParleyCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0 or idx > 1) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 6, 5) or M:hasDone(pPlayer, 6, 5)) then
		return
	end

	if (dataNum(pPlayer, "act6_kneel_flipped") == 1 or self:liveCount(pPlayer, "act6_boss") == 0) then
		return
	end

	dataSet(pPlayer, "act6_kneel_flipped", 1)

	if (idx == 1) then
		self:sui(pPlayer, FLAVOR[2].q5, "\"Struck.\" Veshaan tastes the word and hands it back. \"Daughters have died for this clan with that word un-said. I will not out-live their standard.\" The storm arrives.")
	else
		self:sui(pPlayer, FLAVOR[2].q5, "\"Then close it standing up,\" she says, almost kindly — the kindness of weather, which does not hate the roof. The storm arrives.")
	end

	-- The act3 flip idiom, extended for the boss chassis: jtp_veshaan is a
	-- template-INVULNERABLE + CONVERSE talk NPC, so the BOSS (and only the
	-- boss) gets her options rewritten to 128 = AIENABLED, the stock
	-- fighting-mobile baseline (OptionBitmask.h: CONVERSE 0x08, AIENABLED
	-- 0x80, INVULNERABLE 0x100). The arch-witch adds keep their stock
	-- options and flip on the plain act3 path.
	local bossID = readScreenPlayData(pPlayer, "JediPark", "act6_boss_oid") or ""
	local oids = JtpTheaters:getOids(pPlayer, "act6_boss")

	for i = 1, #oids, 1 do
		local pMob = getSceneObject(oids[i])

		if (pMob ~= nil and SceneObject(pMob):isCreatureObject() and not CreatureObject(pMob):isDead()) then
			if (tostring(SceneObject(pMob):getObjectID()) == bossID) then
				CreatureObject(pMob):setOptionsBitmask(128)
			end

			CreatureObject(pMob):setPvpStatusBitmask(AGGRESSIVE + ATTACKABLE + ENEMY)
			AiAgent(pMob):removeObjectFlag(AI_NOAIAGGRO)
			AiAgent(pMob):setDefender(pPlayer)
		end
	end

	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q5 .. ": the High Witch comes down the rocks like a season changing.")
end

function JediParkAct6:kneelWon(pPlayer)
	local C = JtpConfig.act6

	dataSet(pPlayer, "act6_veshaan_dead", 1)
	self:completeQuest(pPlayer, 5, C.frsFinale)
	self:sui(pPlayer, FLAVOR[2].q5, "She falls the way weather falls — without apology, and without kneeling; the arithmetic of the thing will have to be written up as a rounding error. Her sisters' bodies lie where the storm left them, and above, the stronghold's fires do not so much as flicker: the Mountain has outlasted worse, and intends to outlast you too.\n\nThe last name on the ledger of the Silent War is closed. Nobody knelt. The Voice, you suspect, never expected anyone to.\n\nReturn to the Hand's Voice.")
	createEvent(8 * 1000, "JediParkAct6", "teardownTag", pPlayer, "act6_boss")
end

-- ---- Q6.6L: THE EMBER ASCENDANT (epilogue ceremony) --------------------------
-- Staged in the training hall (the rite trigger dispatches here once
-- quest 6 is underway): the Wanderer unhoods, the ledger closes, badge
-- 147 placeholder + JediPark bit 512 + the Shard pair.

function JediParkAct6:stageAscension(pPlayer)
	local M = JediParkManager

	if (SceneObject(pPlayer):getParentID() ~= JtpConfig.act6.enclaves[1].riteCell) then
		return
	end

	if (self:liveCount(pPlayer, "act6_ascend") > 0) then
		return
	end

	local C = JtpConfig.act6

	JtpTheaters:apparition(pPlayer, {
		planet = C.enclaves[1].planet, cell = C.enclaves[1].riteCell,
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY() + 3,
		template = "jtp_wanderer",
		name = "the Wanderer",
		heading = 180,
		glow = "light",
		lifetimeSec = 180,
		invulnerable = true,
		onAppear = { screenplay = "JediParkAct6", fn = "onAscensionScene" },
		tag = "act6_ascend",
	})
end

function JediParkAct6:onAscensionScene(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not M:hasStarted(pPlayer, 6, 6) or M:hasDone(pPlayer, 6, 6)) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		return
	end

	local sarovLine = ""

	-- Act V coda variant (defensive read — the key belongs to jtp_act5).
	if (dataNum(pPlayer, "act5_sarov_spared") == 1) then
		sarovLine = "\n\n\"Sarov sends one line, by a courier who cried the whole way: 'Tell the new page I am learning to be worth the mercy.' The Circle carries names OUT of ledgers. Even its own.\""
	end

	local sui = SuiMessageBox.new("JediParkAct6", "ascensionCallback")
	sui.setTitle(FLAVOR[1].q6)
	sui.setPrompt("In the training hall, the Wanderer finally lowers his hood.\n\nYou do not know his face. That is the point — the Circle was never its famous dead; it was always whoever swept the floor and kept the ledger and walked the wells while the galaxy busied itself with martyrs. An old man. A survivor. Nobody.\n\nHe hands you the ledger from Aurilia, complete: every name, every well, every act of the Silent War in a crabbed archival hand. Your name is the last entry — and the first of the next page." .. sarovLine .. "\n\n\"The hut on Tatooine is only a hut now,\" he says, hooding again, becoming nobody again, \"and the war is only weather. Walk well, Ember Ascendant.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct6:ascensionCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not M:hasStarted(pPlayer, 6, 6) or M:hasDone(pPlayer, 6, 6)) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		return
	end

	self:finishAct(pPlayer, 1)
end

-- ---- Q6.6D: THE EMPEROR'S INSTRUMENT (epilogue) ------------------------------
-- The Retreat approach scene: Vader anchor (invulnerable — era rail) +
-- the Voice, eleven words, then the ceremony back at the Voice's room.

function JediParkAct6:enterRetreat(pPlayer)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 6, 6) or M:hasDone(pPlayer, 6, 6)) then
		return
	end

	if (dataNum(pPlayer, "act6_judged") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act6_scene") > 0) then
		return
	end

	local r = JtpConfig.act6.retreat
	local vader = { r.vader, 0, 0, 10, 180, nil }
	vader.invuln = true
	local voice = { r.voice, 4, 0, 8, 200, nil }
	voice.invuln = true

	local built = JtpTheaters:build(pPlayer, {
		planet = r.planet, x = r.x, z = 0, y = r.y,
		mobs = { vader, voice },
		lifetimeSec = r.lifeSec,
		tag = "act6_scene",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	createEvent(2500, "JediParkAct6", "retreatJudgment", pPlayer, "")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q6 .. ": down the causeway, unhurried, comes a shape the guard towers do not challenge. The Voice is already at your shoulder, having arrived the way it does. \"Stand,\" it says quietly. \"Say nothing. This is the honor.\"")
end

function JediParkAct6:retreatJudgment(pPlayer, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not M:hasStarted(pPlayer, 6, 6) or M:hasDone(pPlayer, 6, 6)) then
		return
	end

	if (dataNum(pPlayer, "act6_judged") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act6_scene") == 0) then
		return
	end

	dataSet(pPlayer, "act6_judged", 1)

	local sui = SuiMessageBox.new("JediParkAct6", "judgmentCallback")
	sui.setTitle(FLAVOR[2].q6)
	sui.setPrompt("Lord Vader stops at exactly the distance at which no one has ever been glad to see him, and the breathing is the whole conversation for a while. When the words come, they are not his own; he carries them the way the towers carry the sky.\n\n\"He is aware of you. Remain useful. Remain quiet. Go.\"\n\nThe Voice told you there would be eleven words. You will count them later — ten. The eleventh is the pause before 'Go,' and it is the only one addressed to you personally.\n\nVader has already turned. The audience is over; the honor, apparently, was real.\n\n(Return to the Hand's Voice for the ceremony.)")
	sui.sendTo(pPlayer)
end

function JediParkAct6:judgmentCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil) then
		return
	end

	-- The scene sweeps itself shortly after the words land.
	createEvent(8 * 1000, "JediParkAct6", "teardownTag", pPlayer, "act6_scene")
end

function JediParkAct6:finishActDark(pPlayer)
	self:finishAct(pPlayer, 2)
end

-- ---- the shared kill observer ------------------------------------------------

function JediParkAct6:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct6", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct6", "onKill", pPlayer, 1)
end

function JediParkAct6:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	-- Grace-floor hold: while paused, nothing advances and nothing is lost.
	if (not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager
	local victimID = tostring(SceneObject(pVictim):getObjectID())

	-- Q6.2D: the well camps.
	if (M:hasStarted(pPlayer, 6, 2) and not M:hasDone(pPlayer, 6, 2) and M:sideOf(pPlayer) == 2) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act6_camp", pVictim)) then
			local left = dataNum(pPlayer, "act6_camp_left") - 1
			dataSet(pPlayer, "act6_camp_left", left)

			if (left <= 0) then
				JtpTheaters:teardown(pPlayer, "act6_camp")
				self:wellSiteWon(pPlayer)
			else
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q2 .. ": " .. left .. " zealot(s) still standing at the well.")
			end

			return 0
		end
	end

	-- Q6.3: the champions set-piece.
	if (M:hasStarted(pPlayer, 6, 3) and not M:hasDone(pPlayer, 6, 3)) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act6_champ", pVictim)) then
			local left = dataNum(pPlayer, "act6_champ_left") - 1
			dataSet(pPlayer, "act6_champ_left", left)

			if (left <= 0) then
				self:championsWon(pPlayer)
				createEvent(8 * 1000, "JediParkAct6", "teardownTag", pPlayer, "act6_champ")
			else
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[M:sideOf(pPlayer)].q3 .. ": " .. left .. " remain at the well.")
			end

			return 0
		end
	end

	-- Q6.5: the finale bosses (both flagships share the tag + OID latch).
	if (M:hasStarted(pPlayer, 6, 5) and not M:hasDone(pPlayer, 6, 5)) then
		if (victimID == (readScreenPlayData(pPlayer, "JediPark", "act6_boss_oid") or "") and JtpTheaters:isTheaterMob(pPlayer, "act6_boss", pVictim)) then
			if (M:sideOf(pPlayer) == 1) then
				self:fortyWon(pPlayer)
			else
				self:kneelWon(pPlayer)
			end

			return 0
		end
	end

	return 0
end

-- ---- login self-heal (optional wire beside JediParkAct3:heal) ----------------
-- Re-arms the volatile kill observer for any in-flight tracked quest; all
-- theater/wave state self-heals through JtpTheaters' own lapse machinery.

function JediParkAct6:heal(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local M = JediParkManager
	local tracked = { 2, 3, 5 }

	for i = 1, #tracked, 1 do
		if (M:hasStarted(pPlayer, 6, tracked[i]) and not M:hasDone(pPlayer, 6, tracked[i])) then
			self:attachKillObserver(pPlayer)
			break
		end
	end
end

-- ---- rewards, act finale, shared helpers -------------------------------------

-- frsOverride: nil = the 10k baseline; 0 = no FRS grant (paid elsewhere).
function JediParkAct6:completeQuest(pPlayer, quest, frsOverride)
	local C = JtpConfig.act6

	JediParkManager:setDone(pPlayer, 6, quest)
	JediParkManager:giveCredits(pPlayer, C.creditsPerQuest)

	local frs = frsOverride

	if (frs == nil) then
		frs = C.frsPerQuest
	end

	if (frs > 0) then
		JediParkManager:awardFrsXp(pPlayer, frs)
	end
end

-- The epilogue payout (both sides): quest 6 done, JediPark bit 512, badge
-- placeholder, the Shard pair (select power-crystal roll + named datadisk).
function JediParkAct6:finishAct(pPlayer, side)
	local M = JediParkManager
	local C = JtpConfig.act6
	local F = FLAVOR[side]

	self:completeQuest(pPlayer, 6)
	M:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)

	local pShard = M:giveNamedItem(pPlayer, C.items.token, C.items.shardName)

	if (pShard == nil) then
		dataSet(pPlayer, "act6_shard_due", 1)
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full — the Shard of the Silent War will be held for you; ask your giver for it.")
	end

	M:setGlobal(pPlayer, 512)
	M:log(pPlayer, "act6 complete — side " .. side)

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Act complete: " .. F.actName .. ". (Badge 'The Reckoning' arrives with the client update.)")
		self:sui(pPlayer, F.actName, "The hall does not applaud; halls that survive purges learn better manners. Maro re-inks one line — yours — and beside it, in the margin, the mark the ledger reserves for pages that turn themselves.\n\nA power crystal arrives with the Circle's compliments, and with it the Shard of the Silent War: small, dark, unremarkable — a splinter of the first well's stone, cut the night the war ended and nobody heard. Most wars issue medals. This one issues proof.\n\nThe Ember has ascended. The wells will always want walking; the hall will keep your name with the kept.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Act complete: " .. F.actName .. ". (Badge 'The Emperor's Instrument' arrives with the client update.)")
		self:sui(pPlayer, F.actName, "The Voice conducts the ceremony the way it does everything: briefly, precisely, and with the door already in mind. A power crystal — \"from stock; the Hand equips what it keeps\" — and the Shard of the Silent War: small, dark, unremarkable, a splinter of the first well's stone with the whole war inside it.\n\n\"He is aware of you,\" the Voice repeats, and files the sheet with your name on it in the drawer that does not open twice. \"Remain useful. Remain quiet.\"\n\nThe instrument is finished. Instruments keep their edges.")
	end
end

function JediParkAct6:teardownTag(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	JtpTheaters:teardown(pPlayer, arg)
end

function JediParkAct6:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct6", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct6:emptyCallback(pPlayer, pSui, eventIndex, args)
end
