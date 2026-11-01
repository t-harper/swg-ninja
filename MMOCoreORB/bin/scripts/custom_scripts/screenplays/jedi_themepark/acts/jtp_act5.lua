-- jtp_act5.lua — Act V: "The Unbroken Light" (L) / "Heart of Darkness" (D).
-- Mirrored spine, split back half (plan EPIC E5). ONE state machine,
-- side-flavored via FLAVOR tables (the act4 idiom). Quests (bit ledger:
-- started 2^(2n-2) / done 2^(2n-1) in state "JediParkAct5"):
--   1 L "The Summons of Embers"  / D "The Summons of the Voice" [talk]
--   2 L "Fragments of a Broken Blade" / D "Components of Consequence"
--       [collect/kill — 3 sites: Crystal Hunter Cave strongbox, "the
--        collector" (dark_jedi_knight 265) at a wilderness anchor, and a
--        dig at ANY census shrine of the player's choice (shrine hook)]
--   3   "The Ancient Pattern" (shared)  [ceremony — Ondel's pattern]
--   4 L "The Master Who Broke" [parley — ruins arena, Sarov CONVERSABLE]
--     D "The Oath Collected"   [Vader audience — 4-screen scene]
--   5 L "His Last Students"    [2x dark_jedi_knight at the pillar line]
--     D "Vacancies Are Made"   [3 staggered arenahall duels]
--   6 L FINALE "The Unbroken Light"  [offer-blade -> flip -> spare/strike]
--     D FINALE "Heart of Darkness"   [Vheress in the soulroom, Vader watches]
--   7   "The Last Letter" (side, shared) [deliver at any shrine]
--
-- Act gate: matching jedi_<side>_side_master_novice + Act IV done (JediPark
-- global bit 128) + FRS rank >= 4 at entry. GRACE FLOOR (plan 7.4, the
-- act4 contract copied verbatim): first acceptance writes act5_entry_rank;
-- every later gate check requires frsRankOf >= max(4, entryRank - 1); a
-- demoted player gets the pause SUI and everything HOLDS — no wipes.
-- FINALE EXTRA GATE: Q5.6 additionally requires the tree capstone
-- jedi_<side>_side_master — refused with the "not yet whole" line.
-- Completion: JediPark bit 256 + finale bit 8192 (L) / 16384 (D), badge
-- 145/146 placeholder sysmsg, robe s05 (L) / robe_inquisitor (D), side
-- ceremony token + color-crystal roll. FRS XP 8000/quest, 15000
-- penultimate (Q5), 20000 finale (Q6); credits 3000/quest.
--
-- Q5.3 PHASE-A CONTRACT: the Ancient Pattern is a ceremony SUI +
-- ceremonial datadisk ("Pattern of the First Pilgrims") + data flag
-- act5_schematic_pending — the REAL addRewardedSchematic grant is Phase C
-- and owns JediPark global bit 2048. This file must NEVER set bit 2048.
--
-- Givers: light = Keeper Maro (act3's enclave NPC — the MAIN LOOP routes
-- his handler to JediParkAct5:onMaroTalk once Act IV is done, the act4
-- serenna-route idiom); dark = the Hand's Voice (act4's NPC, same route
-- contract via JediParkAct5:onVoiceTalk). This file spawns NO givers and
-- never touches the act1-4 files.
--
-- Site notes / DEVIATIONS:
--  * Q5.4D: the plan sited Vader in the dark enclave "chamber" 3435642.
--    VERIFIED BLOCKER: that cell is an FRS rank-ELEVEN room —
--    frs_manager.lua:96 lists { 3435642, 11 } and FrsManagerImplementation
--    setupEnclaveRooms() default-denies WALKIN below the rank group, with
--    verifyRoomAccess() teleport-ejecting under-ranked entrants. An act-V
--    player (rank >= 4) can never stand in it, and FRS cells are
--    law-untouchable. DEVIATION: the audience is staged in the claimed
--    cloning cell 3435635 — the act3 Q3.8D OATH ROOM (rite anchor
--    -33/-43.0/-31 verified in act3's cell-local notes) — which is
--    fictionally load-bearing: Vader reads the oath where it was taken.
--    Cell + anchor are config tunables if the operator wants it moved.
--  * Q5.6D: emperors_hand is faction="imperial"; dark FRS players are
--    Imperial-coerced, and AiAgentImplementation::isAttackableBy refuses
--    same-faction (and neutral-vs-faction) attackers regardless of pvp
--    bitmask. The staged Vheress is therefore faction-stripped at spawn
--    (CreatureObject:setFaction(0), stock recruiter precedent) or the
--    finale could never be fought. Vader stays stock (never fightable).
--  * Q5.6D boss name: "Vheress, Hand Incumbent" — unless act4_vheress_dead
--    is set (a light-line Act IV kill carried across a side change), in
--    which case the bridging rival "the Hand Incumbent" stands in.
--  * The ruins arena (4192 5196) also hosts act1/act2 triggers; all act5
--    areas are additive per-player machinery, zero stock/park edits.
--  * The collector's anchor (-6000 7200, ~316m from the cave heart, clear
--    of act1's r=192 kill filter) and the cave-heart radius are WALK-TEST
--    tunables.
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- ScreenPlayData namespace "JediPark", keys prefixed act5_:
--   act5_entry_rank            grace-floor anchor (written once; ""/nil = unset)
--   act5_menukeys/_menu_giver  giver menu bookkeeping
--   act5_c1/_c2/_c3            Q5.2 components (cave / collector / dig)
--   act5_pattern_item          Q5.3 datadisk granted
--   act5_schematic_pending     Q5.3 Phase-C schematic marker (NOT bit 2048)
--   act5_parley_done           Q5.4L
--   act5_vader_done            Q5.4D (scene runs once)
--   act5_students_left/_done   Q5.5L
--   act5_duel_stage/_token/_pending/_done  Q5.5D (token 0 = lapsed/reset;
--     pending 1 = between-duels timer in flight)
--   act5_fin_boss/_mobs/_flipped  Q5.6 staging
--   act5_sarov_down/_spared    Q5.6L (post-fight choice; both complete)
--   act5_fin_dead              Q5.6D
--   act5_kenobi_due/_seen      L coda at the hut (cell 3565386)
--   act5_s1_item               Q5.S1 letter granted
-- Theater tags: act5_cache, act5_coll, act5_dig, act5_sarov,
--   act5_students, act5_duel, act5_vader, act5_finale, act5_kenobi.
--
-- Integration points the MAIN LOOP wires (this file only exposes them):
--   JtpShrines -> JediParkAct5:onShrineVisited (MUST be called for EVERY
--     shrine entry, i.e. BEFORE the hasVisited early-return — Q5.2's dig
--     and Q5.S1's delivery are "any shrine of the player's choice", and
--     most choices will already be lifetime-visited);
--   jtp_maro_handler -> JediParkAct5:onMaroTalk (once JediPark bit 128);
--   jtp_voice_handler -> JediParkAct5:onVoiceTalk (once JediPark bit 128);
--   jtp_observers login hook -> JediParkAct5:heal.

-- ---- tuning (jtp_config owns nothing act5-specific yet; claim the slot) ------

JtpConfig.act5 = JtpConfig.act5 or {
	frsPerQuest = 8000,
	frsPenultimate = 15000,     -- Q5.5
	frsFinale = 20000,          -- Q5.6
	creditsPerQuest = 3000,
	visLetterLight = -200,      -- Q5.S1 quiet step (light line only)

	-- Act gate (grace floor per plan 7.4; capstone gates the finale only).
	gateRank = 4,
	gateSkillLight = "jedi_light_side_master_novice",
	gateSkillDark = "jedi_dark_side_master_novice",
	capstoneLight = "jedi_light_side_master",
	capstoneDark = "jedi_dark_side_master",
	prevActBit = 128,           -- JediPark global: Act IV done

	-- Q5.2 — the three component sites (mirrored). The cave heart sits
	-- inside act1's Crystal Hunter Cave circle (-6240 7405 r192); the
	-- strongbox builds at the PLAYER's own parent-aware position, so it
	-- works on world geometry and in cave cells alike. The collector's
	-- anchor is outside that circle (WALK-TEST).
	cave = { planet = "dantooine", x = -6240, y = 7405, radius = 24 },
	collector = { planet = "dantooine", x = -6000, y = 7200, radius = 48,
		template = "dark_jedi_knight", name = "the collector", lifeSec = 1800 },

	-- L line — the Dantooine Jedi Temple ruins arena (Q5.4L/5L/6L).
	arena = { planet = "dantooine", x = 4192, y = 5196, radius = 32, lifeSec = 1800,
		sarovTemplate = "jtp_sarov",
		studentTemplate = "dark_jedi_knight",
		studentName = "a last student of Sarov",
		studentCount = 2,
		-- 4 white shrines ring the arena; Sarov holds the north line.
		shrineOffsets = { { -6, -6 }, { 6, -6 }, { -6, 6 }, { 6, 6 } },
		students = { { -8, 14 }, { 8, 14 } } },

	-- D line Q5.4D — Vader's audience, staged in the claimed OATH ROOM
	-- (cloning cell 3435635; act3's verified rite anchor). See the header
	-- DEVIATION: the plan's chamber 3435642 is an FRS rank-11 cell.
	vader = { planet = "yavin4", x = 5070, y = 310, radius = 128,
		cell = 3435635, spot = { x = -35, z = -43.0, y = -29, heading = 100 },
		template = "darth_vader_city_control", lifeSec = 600 },

	-- D line Q5.5D — arenahall staggered duels (verified corridor floor
	-- -47.4; Dask stands at y=-52, act3's duel line at y=-57).
	duels = { planet = "yavin4", x = 5070, y = 310, radius = 128,
		cell = 3435636, spot = { x = 0, z = -47.4, y = -58, heading = 0 },
		template = "dark_jedi_knight", name = "a rival aspirant",
		count = 3, betweenMs = 6000, lifeSec = 900 },

	-- D line Q5.6D — the Woolamander soulroom (act2's verified floor
	-- point 0/2/-3 in cell 3705355).
	soulroom = { planet = "yavin4", x = 549, y = -622, radius = 128,
		cell = 3705355, anchor = { x = 0, z = 2, y = -3 },
		bossTemplate = "emperors_hand", lifeSec = 1800 },

	-- L coda — Ben's hut (building 3565385, interior cell 3565386;
	-- act1's verified cell-local spirit anchor).
	hut = { planet = "tatooine", x = -4489, y = -2262, radius = 40,
		cell = 3565386,
		spirit = { x = 0.3, z = 0.2, y = 1.2, heading = 135 },
		lifeSec = 60 },

	items = {
		pattern = "object/tangible/mission/mission_datadisk.iff",
		patternName = "Pattern of the First Pilgrims",
		letter = "object/tangible/mission/mission_datadisk.iff",
		letterName = "The Last Letter — To Whoever Is Left",
		token = "object/tangible/mission/mission_datadisk.iff",
		tokenLightName = "Quintessence of the Force — Ember Token",
		tokenDarkName = "Maul's Vengence — Shadow Token",
		robeLight = "object/tangible/wearables/robe/robe_jedi_light_s05.iff",
		-- robe_jedi_dark_s05.iff exists too, but the plan awards the dark
		-- line the Inquisitor's cut (both templates verified stock).
		robeDark = "object/tangible/wearables/robe/robe_inquisitor.iff",
		relicProp = "object/tangible/jedi/power_shrine_red.iff",
		shrineProp = "object/tangible/jedi/power_shrine.iff",
	},
	lootGroups = {
		colorCrystal = "color_crystals",
		powerCrystal = "power_crystals",
	},
}

JediParkAct5 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 5,
}

registerScreenPlay("JediParkAct5", true)

-- Reload guard: survives reloadscreenplays; reset only by a full restart.
JTP_ACT5_SPAWNED = JTP_ACT5_SPAWNED or nil

-- ---- boot spawns (trigger areas only — every NPC here is per-player) ---------

function JediParkAct5:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT5_SPAWNED ~= nil) then
		print("jtp: act5 already spawned (reload) — skipping spawns")
		print("jtp: act5 'The Unbroken Light / Heart of Darkness' loaded")
		return
	end

	JTP_ACT5_SPAWNED = {}
	local C = JtpConfig.act5

	-- Dantooine: cave strongbox, the collector's anchor, the ruins arena.
	if (isZoneEnabled("dantooine")) then
		self:addArea(C.cave.planet, C.cave.x, C.cave.y, C.cave.radius, 0, "cave")
		self:addArea(C.collector.planet, C.collector.x, C.collector.y, C.collector.radius, 0, "coll")
		self:addArea(C.arena.planet, C.arena.x, C.arena.y, C.arena.radius, 0, "arena")
	end

	-- Yavin IV: the oath room (Vader), the arenahall (duels), the
	-- soulroom (finale D). All cell-filtered world circles — the act2/act3
	-- pattern; ZERO permission changes anywhere in this act.
	if (isZoneEnabled("yavin4")) then
		self:addArea(C.vader.planet, C.vader.x, C.vader.y, C.vader.radius, C.vader.cell, "vader")
		self:addArea(C.duels.planet, C.duels.x, C.duels.y, C.duels.radius, C.duels.cell, "duels")
		self:addArea(C.soulroom.planet, C.soulroom.x, C.soulroom.y, C.soulroom.radius, C.soulroom.cell, "soulroom")
	end

	-- Tatooine: the hut coda (interior cell filter; act1 owns the door).
	if (isZoneEnabled("tatooine")) then
		self:addArea(C.hut.planet, C.hut.x, C.hut.y, C.hut.radius, C.hut.cell, "hut")
	end

	print("jtp: act5 'The Unbroken Light / Heart of Darkness' loaded")
end

function JediParkAct5:addArea(planet, x, y, radius, cellFilter, kind)
	local pArea = spawnActiveArea(planet, "object/active_area.iff", x, 0, y, radius, cellFilter)

	if (pArea == nil) then
		print("jtp: WARNING — act5 area '" .. kind .. "' spawn failed on " .. planet)
		return
	end

	local areaID = SceneObject(pArea):getObjectID()
	writeStringData(areaID .. ":jtpAct5Kind", kind)
	createObserver(ENTEREDAREA, "JediParkAct5", "onEnterSite", pArea)
	table.insert(JTP_ACT5_SPAWNED, areaID)
end

-- ---- data helpers ------------------------------------------------------------

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

-- Live (undestroyed, undead) members of a theater tag. Props count as live.
function JediParkAct5:liveCount(pPlayer, tag)
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

function JediParkAct5:componentCount(pPlayer)
	return dataNum(pPlayer, "act5_c1") + dataNum(pPlayer, "act5_c2") + dataNum(pPlayer, "act5_c3")
end

-- ---- the act gate + grace floor (act4's plan-7.4 contract, act5 keys) --------

-- nil until the act has been accepted once; then the rank written at entry.
function JediParkAct5:entryRank(pPlayer)
	local raw = readScreenPlayData(pPlayer, "JediPark", "act5_entry_rank")

	if (raw == nil or raw == "") then
		return nil
	end

	return tonumber(raw)
end

-- "ok" | "pause" | "no". "pause" = accepted, then demoted below the grace
-- floor max(4, entryRank - 1): everything HOLDS, nothing is wiped.
function JediParkAct5:gateState(pPlayer)
	local M = JediParkManager

	if (pPlayer == nil or not M:isJedi(pPlayer)) then
		return "no"
	end

	local side = M:sideOf(pPlayer)

	if (side == 0) then
		return "no"
	end

	local C = JtpConfig.act5
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

function JediParkAct5:gateOk(pPlayer)
	return self:gateState(pPlayer) == "ok"
end

function JediParkAct5:sendPauseNotice(pPlayer)
	local M = JediParkManager
	local entry = self:entryRank(pPlayer) or JtpConfig.act5.gateRank
	local floor = math.max(JtpConfig.act5.gateRank, entry - 1)
	local title = "The Unbroken Light"

	if (M:sideOf(pPlayer) == 2) then
		title = "Heart of Darkness"
	end

	self:sui(pPlayer, title, "The summit road goes quiet under your feet. Your standing in the Force's hierarchy has slipped below what this act will spend (you hold rank " .. M:frsRankOf(pPlayer) .. "; the road remembers you at rank " .. entry .. ", and will wait for rank " .. floor .. "). Nothing you have earned is lost, and nothing new opens until you stand where you stood. Recover your rank; the summit keeps your place.")
end

-- The finale's extra gate: the tree capstone (plan E5 — "not yet whole").
function JediParkAct5:hasCapstone(pPlayer, side)
	local C = JtpConfig.act5

	if (side == 1) then
		return CreatureObject(pPlayer):hasSkill(C.capstoneLight)
	end

	return CreatureObject(pPlayer):hasSkill(C.capstoneDark)
end

function JediParkAct5:sendNotWholeNotice(pPlayer, side)
	if (side == 1) then
		self:sui(pPlayer, "The Unbroken Light", "Maro closes the ledger on your name without writing. \"Not yet. You will stand in front of a man who broke at the SUMMIT of this discipline — and you are not yet whole in it. Finish the tree, ember. Every branch. What you offer him must have nothing missing, or he will find the missing piece and live in it.\" (The finale requires the full mastery of the light discipline.)")
	else
		self:sui(pPlayer, "Heart of Darkness", "The Voice does not turn. \"The chair is not inherited by the promising. You are not yet whole — the discipline has branches your hands have not closed. The Emperor's instruments are finished objects.\" A pause with a filing sound in it. \"Finish. Then take.\" (The finale requires the full mastery of the dark discipline.)")
	end
end

-- ---- side flavor (one state machine, two voices) -----------------------------

local FLAVOR = {
	[1] = {
		actName = "The Unbroken Light",
		giver = "Keeper Maro",
		q1 = "The Summons of Embers", q2 = "Fragments of a Broken Blade",
		q3 = "The Ancient Pattern", q4 = "The Master Who Broke",
		q5 = "His Last Students", q6 = "The Unbroken Light",
		q7 = "The Last Letter",
		comp1 = "the traded fragment", comp2 = "the stolen fragment", comp3 = "the buried fragment",
	},
	[2] = {
		actName = "Heart of Darkness",
		giver = "The Hand's Voice",
		q1 = "The Summons of the Voice", q2 = "Components of Consequence",
		q3 = "The Ancient Pattern", q4 = "The Oath Collected",
		q5 = "Vacancies Are Made", q6 = "Heart of Darkness",
		q7 = "The Last Letter",
		comp1 = "the deep-cave crystal", comp2 = "the hunter-killer's alloy", comp3 = "the rival's focusing ring",
	},
}

-- The D-line rival: Vheress holds the chair unless a light-line Act IV
-- already buried her (a side-crosser's save) — then the bridging rival.
local function incumbentName(pPlayer)
	if (dataNum(pPlayer, "act4_vheress_dead") == 1) then
		return "the Hand Incumbent"
	end

	return "Vheress, Hand Incumbent"
end

-- ---- giver conversation routers ----------------------------------------------
-- The light line rides act3's Keeper Maro and the dark line rides act4's
-- Hand's Voice (the MAIN LOOP wires both cross-act routes at integration,
-- the serenna-route idiom). Every screen re-evaluates side + gate live.

function JediParkAct5:onMaroTalk(pPlayer)
	self:onGiverTalk(pPlayer, 1)
end

function JediParkAct5:onVoiceTalk(pPlayer)
	self:onGiverTalk(pPlayer, 2)
end

function JediParkAct5:onGiverTalk(pPlayer, giverSide)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager
	local F = FLAVOR[giverSide]

	if (not M:isJedi(pPlayer) or M:sideOf(pPlayer) == 0) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "The Keeper reads his re-sewn ledger and does not look up. Whatever the hall is keeping now, it is not for the unchosen.")
		else
			self:sui(pPlayer, F.giver, "The figure at the far wall does not turn. \"This room convenes for instruments. You are, at present, noise.\"")
		end
		return
	end

	if (M:sideOf(pPlayer) ~= giverSide) then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "Maro looks up once, and files what he sees. \"The hall buried its dead under light, and you walk under something else now. The summit you want is not in my ledger. Go and be counted where they count you.\"")
		else
			self:sui(pPlayer, F.giver, "The Hand's Voice does not turn. \"You filed yourself under something softer. This room's arithmetic no longer includes you. The door remembers the way out.\"")
		end
		return
	end

	local gate = self:gateState(pPlayer)

	if (gate == "no") then
		if (giverSide == 1) then
			self:sui(pPlayer, F.giver, "\"Not yet, knight. The summit road opens to masters the war can spend: begin the light's own mastery, finish the Silent Council's war, and hold the fourth rank of the hierarchy. Then I will tell you about the man who broke.\" (Requires: light master training begun, Act IV complete, FRS rank 4.)")
		else
			self:sui(pPlayer, F.giver, "\"The second audience is not granted to potential. Begin the dark's mastery, finish the gambit, and hold the fourth rank of the hierarchy. The Voice will still be here. The Voice is always here.\" (Requires: dark master training begun, Act IV complete, FRS rank 4.)")
		end
		return
	end

	if (gate == "pause") then
		self:sendPauseNotice(pPlayer)
		return
	end

	if (not M:hasStarted(pPlayer, 5, 1)) then
		self:offerBriefing(pPlayer, giverSide)
		return
	end

	self:giverMenu(pPlayer, giverSide)
end

-- ---- Q5.1: the summons -------------------------------------------------------

function JediParkAct5:offerBriefing(pPlayer, side)
	local F = FLAVOR[side]
	local sui = SuiListBox.new("JediParkAct5", "briefingCallback")
	sui.setTitle(F.q1)

	if (side == 1) then
		sui.setPrompt("Serenna's courier found you at a well with one word, and the word was a name: \"Sarov.\" Now Maro sets down his ledger, and for the first time the old man looks every year of his age. \"The Circle's greatest teacher did not die in the Purge. He did something worse. He is holding the Dantooine ruins the way a grave holds a name — and he has killed every Inquisitor the Empire sent for him, and every student we sent to bring him home. Serenna believes a whole blade, made by YOUR hands, will reach what words cannot. I believe I have buried enough of my ledger. Sit. This is the whole story, and it is not short.\" (The last door of this act opens only to the crown of the tree: the full mastery of the light discipline.)")
		sui.add("Sit, and hear the whole story. (Begin Act V: The Unbroken Light)", "")
		sui.add("\"Not today.\"", "")
	else
		local bridge = ""

		if (dataNum(pPlayer, "act4_vheress_dead") == 1) then
			bridge = " The chair's last occupant is already in the ground — your ledger says you know something about that — and the office has been filled on an INTERIM basis. Interim is a word the Emperor uses about furniture."
		else
			bridge = " Its owner still wears it lit. That is the error."
		end

		sui.setPrompt("The Voice grants a second audience. Council One is darker than you remember, and on the far wall of the chamber hangs an unlit saber — the incumbent Hand's." .. bridge .. " \"Vacancies,\" says the Voice, \"are made. You will make one. You will do it correctly, which means: with a blade built the old way, under the eyes that matter, leaving no ambiguity for the historians the Empire does not employ.\" (The last door of this act opens only to the crown of the tree: the full mastery of the dark discipline.)")
		sui.add("Stand and receive the instruction. (Begin Act V: Heart of Darkness)", "")
		sui.add("Withdraw.", "")
	end

	sui.sendTo(pPlayer)
end

function JediParkAct5:briefingCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0 or M:hasStarted(pPlayer, 5, 1) or not self:gateOk(pPlayer)) then
		return
	end

	-- GRACE FLOOR anchor: written exactly once, at first acceptance.
	if (self:entryRank(pPlayer) == nil) then
		dataSet(pPlayer, "act5_entry_rank", math.max(0, M:frsRankOf(pPlayer)))
		M:log(pPlayer, "act5 entry rank " .. math.max(0, M:frsRankOf(pPlayer)))
	end

	JtpCells:heal(pPlayer)
	M:setStarted(pPlayer, 5, 1)
	M:setDone(pPlayer, 5, 1)
	self:reward(pPlayer)

	if (side == 1) then
		self:sui(pPlayer, FLAVOR[1].actName, "Maro talks until the lamp needs oil. Sarov taught half the names in the buried pages — taught Maro. The night the Purge found his school he held the door alone, and the door held; the students did not. He shattered his own hilt over their pyre and walked into the ruins with the pieces. \"What the ruins keep now kills rescuers and executioners with the same stroke, because it has stopped telling them apart. Serenna's plan is the blade: recover the three fragments of the hilt he broke, and we will make them into something whole enough to argue with.\"")
	else
		self:sui(pPlayer, FLAVOR[2].actName, "The instruction, once: a Hand's blade is BUILT, not issued — the old way, from the old places, so that when the vacancy is filled nobody can call the filling improvised. \"Three components. Then the pattern. Then the audience — there is a visitor whose shuttle is already on the pad, and he reads instruments the way you read fear.\" The Voice lets that sentence finish existing before adding: \"Do not be illiterate when he does.\"")
	end

	self:beginQuest(pPlayer, side, 2)
end

-- ---- quest openers -----------------------------------------------------------

function JediParkAct5:beginQuest(pPlayer, side, quest)
	local M = JediParkManager
	local F = FLAVOR[side]
	local C = JtpConfig.act5

	if (M:hasStarted(pPlayer, 5, quest)) then
		return
	end

	M:setStarted(pPlayer, 5, quest)

	if (quest == 2) then
		self:attachKillObserver(pPlayer)

		if (side == 1) then
			self:sui(pPlayer, F.q2, "\"Sarov shattered his own hilt the night he broke. Three fragments. One he TRADED to the crystal-hunters for silence — their deep strongbox still keeps it, at the hunter cave near -6240 7405, Dantooine. One was STOLEN by a scavenger the trade-lanes call 'the collector'; he prowls the cave road near -6000 7200 and will not part with it politely. And one he BURIED with a friend, at a well. Which well? He never said. Choose one; dig gently. The stones will let his grief go to the right hands.\" (Recover all three fragments: the cave strongbox, the collector, and a dig at any Force shrine of your choosing.)")
		else
			self:sui(pPlayer, F.q2, "\"Component one: crystal from the deep cave — the hunters' strongbox at the cave near -6240 7405, Dantooine, holds what the Hand requires. Component two: alloy from a hunter-killer's spine — the freelancer called 'the collector' works the cave road near -6000 7200; his spine is currently in use. Component three: a focusing ring from a dead rival's trophy case — the rival buried the case at a Force well, and any well you choose to open will do. The wells keep everything. That is their error.\" (Recover all three components: the cave strongbox, the collector, and a dig at any Force shrine of your choosing.)")
		end

	elseif (quest == 3) then
		self:sui(pPlayer, F.q3, "Word from the damprock cave: Archivist Ondel has sent a courier-case ahead of your components, sealed in wax older than the seal's own alphabet. " .. F.giver .. " has it waiting. Return when you are ready to receive the pattern.")

	elseif (quest == 4) then
		if (side == 1) then
			self:sui(pPlayer, F.q4, "\"He holds the Dantooine ruins like a grave holds a name — the arena among the pillars, near 4192 5196. Go to him. SPEAK to him. He has killed everyone who came with a drawn blade and everyone who came with a speech; you will go with a made thing and an honest face, and we will learn which of us has been praying correctly.\" (Walk into the ruins arena and speak with Master Sarov. He will not strike first. That is the only promise anyone can make you.)")
		else
			self:sui(pPlayer, F.q4, "\"Vader's shuttle is on the pad.\" The Voice says it the way other people say a weather report that kills. \"The audience is in the oath room — the cloning cell where you died before you served. He chose the room. Read that. He reads oaths the way you read fear. Do not be illiterate today.\" (Enter the dark enclave's cloning cell — the room of your Act III oath — at 5070 310, Yavin IV.)")
		end

	elseif (quest == 5) then
		if (side == 1) then
			self:sui(pPlayer, F.q5, "\"Sarov's 'guard' are the students he could not save — dark now, and loyal to his despair. They will not let you reach him twice.\" (Return to the ruins arena near 4192 5196. The pillar line is held by two of his last students. They were knights once. They are still knights. That is the tragedy, and the fight.)")
		else
			self:sui(pPlayer, F.q5, "\"The incumbent's bodyguard: aspirants who bet on the wrong survivor. The arena settles estates.\" (Enter the arenahall of the dark enclave at 5070 310, Yavin IV, and stand the floor. Three duels, one at a time, the old way. The estate files its claims in order.)")
		end

	elseif (quest == 6) then
		if (side == 1) then
			self:sui(pPlayer, F.q6, "\"Four shrines burn white around the arena. Offer Sarov the blade. Then survive his answer.\" Maro closes the ledger, and his hand stays on it. \"Whatever happens among those stones — whole is what you carry OUT, not what you carry in. Go.\" (Return to the ruins arena. Offer the blade. The rest is between you and the man who broke.)")
		else
			self:sui(pPlayer, F.q6, "\"Woolamander's soulroom, where you first heard the hollow. " .. incumbentName(pPlayer) .. " waits with her saber lit. Lord Vader watches from the dark with his arms folded. There is exactly one door out.\" The Voice hangs the unlit saber back on the wall, next to a new, empty hook. (Enter the soulroom beneath the Woolamander palace at 549 -622, Yavin IV. Make the vacancy.)")
		end

	elseif (quest == 7) then
		if (dataNum(pPlayer, "act5_s1_item") == 0) then
			local pItem = M:giveNamedItem(pPlayer, C.items.letter, C.items.letterName)

			if (pItem ~= nil) then
				dataSet(pPlayer, "act5_s1_item", 1)
			end
		end

		if (side == 1) then
			self:sui(pPlayer, F.q7, "Ondel's final letter has no address — 'to whoever is left.' \"Choose a shrine,\" the note on the wrapping says. \"Leave it. Some inheritances are for strangers.\" (Walk to any Force shrine and the delivery will make itself. The letter is the road's own flavor — losing the paper loses nothing.)")
		else
			self:sui(pPlayer, F.q7, "Ondel's final letter has no address — 'to whoever is left.' The Voice, unasked: \"Deliver it. The Emperor's instruments may carry sentiment, provided the sentiment is SOMEONE ELSE'S.\" (Walk to any Force shrine and the delivery will make itself. The letter is the road's own flavor — losing the paper loses nothing.)")
		end
	end
end

-- ---- the giver menu (mando_rank menuKeys pattern, act4 idiom) ----------------

function JediParkAct5:giverMenu(pPlayer, side)
	local M = JediParkManager
	local F = FLAVOR[side]
	local options = {}

	-- Main spine (linear; *_start branches self-heal a missing started bit).
	if (not M:hasStarted(pPlayer, 5, 2)) then
		options[#options + 1] = { "q2_start", "Ask where the making begins (Begin: " .. F.q2 .. ")" }
	elseif (not M:hasDone(pPlayer, 5, 2)) then
		if (self:componentCount(pPlayer) >= 3) then
			options[#options + 1] = { "q2_turnin", "Lay out all three pieces (Turn in: " .. F.q2 .. ")" }
		else
			options[#options + 1] = { "q2_hint", "Ask about the three pieces (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 5, 3)) then
		options[#options + 1] = { "q3_start", "Ask about Ondel's courier-case (Begin: " .. F.q3 .. ")" }
	elseif (not M:hasDone(pPlayer, 5, 3)) then
		options[#options + 1] = { "q3_rite", "Receive the Ancient Pattern (ceremony)" }
	elseif (not M:hasStarted(pPlayer, 5, 4)) then
		if (side == 1) then
			options[#options + 1] = { "q4_start", "\"Where is he?\" (Begin: " .. F.q4 .. ")" }
		else
			options[#options + 1] = { "q4_start", "Ask about the visitor (Begin: " .. F.q4 .. ")" }
		end
	elseif (not M:hasDone(pPlayer, 5, 4)) then
		options[#options + 1] = { "q4_hint", "Ask about the meeting (progress)" }
	elseif (not M:hasStarted(pPlayer, 5, 5)) then
		options[#options + 1] = { "q5_start", "Ask what stands in the way (Begin: " .. F.q5 .. ")" }
	elseif (not M:hasDone(pPlayer, 5, 5)) then
		local q5ready = false

		if (side == 1) then
			q5ready = dataNum(pPlayer, "act5_students_done") == 1
		else
			q5ready = dataNum(pPlayer, "act5_duels_done") == 1
		end

		if (q5ready) then
			options[#options + 1] = { "q5_turnin", "Report the way clear (Turn in: " .. F.q5 .. ")" }
		else
			options[#options + 1] = { "q5_hint", "Ask about the fight (progress)" }
		end
	elseif (not M:hasStarted(pPlayer, 5, 6)) then
		options[#options + 1] = { "q6_start", "Ask for the ending (Begin the finale: " .. F.q6 .. ")" }
	elseif (not M:hasDone(pPlayer, 5, 6)) then
		if (side == 1 and dataNum(pPlayer, "act5_sarov_down") == 1) then
			options[#options + 1] = { "q6_end", "Speak the ending (the choice among the stones)" }
		else
			options[#options + 1] = { "q6_hint", "Ask about the finale (progress)" }
		end
	else
		options[#options + 1] = { "road_ahead", "Ask about the road ahead" }
	end

	-- Side quest (opens once the act is underway).
	if (not M:hasStarted(pPlayer, 5, 7)) then
		options[#options + 1] = { "s1_start", "Ask about Ondel's last letter (Side: " .. F.q7 .. ")" }
	elseif (not M:hasDone(pPlayer, 5, 7)) then
		options[#options + 1] = { "s1_hint", "Ask about the letter (progress)" }
	end

	local keys = {}
	local sui = SuiListBox.new("JediParkAct5", "giverMenuCallback")
	sui.setTitle(F.giver)

	if (side == 1) then
		sui.setPrompt("\"The ledger is open.\"")
	else
		sui.setPrompt("\"Speak. Once.\"")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "act5_menukeys", table.concat(keys, ","))
	dataSet(pPlayer, "act5_menu_giver", side)
	sui.sendTo(pPlayer)
end

function JediParkAct5:giverMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act5_menukeys")
	dataSet(pPlayer, "act5_menukeys", "")

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
	if (side == 0 or side ~= dataNum(pPlayer, "act5_menu_giver")) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		if (self:gateState(pPlayer) == "pause") then
			self:sendPauseNotice(pPlayer)
		end
		return
	end

	local F = FLAVOR[side]
	local C = JtpConfig.act5

	if (action == "q2_start") then
		if (M:hasDone(pPlayer, 5, 1)) then
			self:beginQuest(pPlayer, side, 2)
		end

	elseif (action == "q2_hint") then
		local have = {}

		if (dataNum(pPlayer, "act5_c1") == 1) then have[#have + 1] = F.comp1 end
		if (dataNum(pPlayer, "act5_c2") == 1) then have[#have + 1] = F.comp2 end
		if (dataNum(pPlayer, "act5_c3") == 1) then have[#have + 1] = F.comp3 end

		local held = "none yet"

		if (#have > 0) then
			held = table.concat(have, "; ")
		end

		self:attachKillObserver(pPlayer)
		self:sui(pPlayer, F.q2, "\"" .. self:componentCount(pPlayer) .. " of 3 pieces in hand (" .. held .. "). The strongbox waits at the hunter cave's heart, -6240 7405; the collector works the cave road near -6000 7200; the third sleeps under any well you choose to open. Old things surrender slowly. Keep digging.\"")

	elseif (action == "q2_turnin") then
		if (M:hasStarted(pPlayer, 5, 2) and not M:hasDone(pPlayer, 5, 2) and self:componentCount(pPlayer) >= 3) then
			self:completeQuest(pPlayer, 2)

			if (side == 1) then
				self:sui(pPlayer, F.q2, "Maro sets the three fragments on the ledger like pallbearers setting down a small coffin. \"A trade, a theft, a burial. That is a fair biography of grief.\" He does not touch them again. \"Ondel has the pattern. What these become next is the argument we send instead of an army.\"")
			else
				self:sui(pPlayer, F.q2, "The Voice inventories the three components without touching them. \"Crystal. Alloy. Ring. Provenance: correct, correct, instructive.\" A beat. \"The archivist's pattern makes them a blade. The blade makes you a candidate. The audience decides what a candidate is FOR.\"")
			end

			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_start") then
		if (M:hasDone(pPlayer, 5, 2)) then
			self:beginQuest(pPlayer, side, 3)
		end

	elseif (action == "q3_rite") then
		if (M:hasStarted(pPlayer, 5, 3) and not M:hasDone(pPlayer, 5, 3)) then
			self:performPattern(pPlayer, side)
		end

	elseif (action == "q4_start") then
		if (M:hasDone(pPlayer, 5, 3)) then
			self:beginQuest(pPlayer, side, 4)
		end

	elseif (action == "q4_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q4, "\"The ruins arena, near 4192 5196. Walk in with the made thing and an honest face, and SPEAK with him. He has not struck a talker first in eleven years. The record is imperfect comfort. It is the only record we have.\"")
		else
			if (dataNum(pPlayer, "act5_vader_done") == 1) then
				self:sui(pPlayer, F.q4, "\"The audience is concluded,\" the Voice recaps, precisely once. \"He named the test: the incumbent Hand, alive, is an error. You have your arithmetic.\"")
			else
				self:sui(pPlayer, F.q4, "\"The oath room. The cloning cell where you died before you served — the enclave at 5070 310. He is already there in every way that matters, and will be there in the remaining way when you arrive. Do not keep the pad waiting.\"")
			end
		end

	elseif (action == "q5_start") then
		if (M:hasDone(pPlayer, 5, 4)) then
			self:beginQuest(pPlayer, side, 5)
		end

	elseif (action == "q5_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q5, "\"The pillar line at the ruins arena. Two of his last students hold it — knights of the buried pages, wearing the dark like borrowed mourning. Reach him THROUGH them. There is no around.\"")
		else
			self:sui(pPlayer, F.q5, "\"The arenahall floor. Three aspirants, one at a time — the estate files its claims in order, and the order is: whoever is left standing files last.\"")
		end

	elseif (action == "q5_turnin") then
		if (M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5)) then
			local ready = false

			if (side == 1) then
				ready = dataNum(pPlayer, "act5_students_left") == 0 and dataNum(pPlayer, "act5_students_done") == 1
			else
				ready = dataNum(pPlayer, "act5_duels_done") == 1
			end

			if (ready) then
				self:completeQuest(pPlayer, 5, C.frsPenultimate)

				if (side == 1) then
					self:sui(pPlayer, F.q5, "Maro writes two names into the buried pages, and the writing takes him a long time. \"They were his last lesson, and they learned it too well. The pillar line is open. What waits past it has watched you clear it — and has not moved. Take that for the omen it is, whichever omen that is.\"")
				else
					self:sui(pPlayer, F.q5, "\"Three claims, three settlements. The estate is uncontested.\" The Voice takes the empty hook off the wall and sets it on the table between you, which is the closest it has ever come to a gesture. \"The soulroom is next. Bring nothing you are not prepared to be.\"")
				end

				-- The finale gates on the tree capstone (plan E5): the
				-- "not yet whole" refusal here, the offer stays in the menu.
				if (self:hasCapstone(pPlayer, side)) then
					self:beginQuest(pPlayer, side, 6)
				else
					self:sendNotWholeNotice(pPlayer, side)
				end
			end
		end

	elseif (action == "q6_start") then
		if (M:hasDone(pPlayer, 5, 5)) then
			if (not self:hasCapstone(pPlayer, side)) then
				self:sendNotWholeNotice(pPlayer, side)
			else
				self:beginQuest(pPlayer, side, 6)
			end
		end

	elseif (action == "q6_hint") then
		if (side == 1) then
			self:sui(pPlayer, F.q6, "\"The arena, the four white fires, the offer. He will answer with everything he has left. Survive the answer, and then — only then — decide what the ending is.\"")
		else
			self:sui(pPlayer, F.q6, "\"The soulroom under Woolamander, 549 -622. One incumbent, one observer, one door. The observer will not help either of you. That is what makes him the Emperor's.\"")
		end

	elseif (action == "q6_end") then
		if (side == 1 and M:hasStarted(pPlayer, 5, 6) and not M:hasDone(pPlayer, 5, 6) and dataNum(pPlayer, "act5_sarov_down") == 1) then
			self:offerSpare(pPlayer)
		end

	elseif (action == "road_ahead") then
		if (side == 1) then
			self:sui(pPlayer, "The Road Ahead", "\"The blade held, and so did you.\" Maro's ledger lies open at a fresh page with one name on it. \"What remains is the war going loud across every well at once — a road for masters with a council's rank behind them. The Reckoning arrives in a later update. Rest, ember. You have earned a smaller word than 'rest,' and there isn't one.\"")
		else
			self:sui(pPlayer, "The Road Ahead", "\"The Hand has closed around a new instrument.\" The Voice regards you the way a ledger regards a settled column. \"The Emperor's attention now has a shape it approves of. Keep the shape. The Emperor's Instrument arrives in a later update — until then: remain useful. Remain quiet.\"")
		end

	elseif (action == "s1_start") then
		if (M:hasDone(pPlayer, 5, 1) and not M:hasStarted(pPlayer, 5, 7)) then
			self:beginQuest(pPlayer, side, 7)
		end

	elseif (action == "s1_hint") then
		self:sui(pPlayer, F.q7, "\"No address. 'To whoever is left.' Any well will take it — the wells were the post road before there were roads. Walk it to a shrine and let the stones do the delivering.\"")
	end
end

-- ---- Q5.3: the Ancient Pattern (ceremony — Phase A contract) -----------------
-- Grants the ceremonial datadisk + act5_schematic_pending. The REAL
-- addRewardedSchematic grant is Phase C property (bit 2048 — NEVER here).

function JediParkAct5:performPattern(pPlayer, side)
	local M = JediParkManager
	local C = JtpConfig.act5
	local F = FLAVOR[side]

	if (not self:gateOk(pPlayer)) then
		return
	end

	if (dataNum(pPlayer, "act5_pattern_item") == 0) then
		local pItem = M:giveNamedItem(pPlayer, C.items.pattern, C.items.patternName)

		if (pItem == nil) then
			CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and receive the pattern again.")
			return
		end

		dataSet(pPlayer, "act5_pattern_item", 1)
	end

	dataSet(pPlayer, "act5_schematic_pending", 1)
	self:completeQuest(pPlayer, 3)

	self:sui(pPlayer, F.q3, "The courier-case opens on oiled hide, and " .. F.giver .. " unrolls a pattern older than the Republic's name for it: a combat hilt of the first pilgrim-smiths, drawn in a hand that predates both churches. Ondel's note, in the margin: \"Both your churches came from this. Argue with the DRAWING, if you dare.\" Your three recovered pieces are laid into the pattern's frame one by one, and the frame accepts them the way a lock accepts a key it has been missing for four thousand years.")
	CreatureObject(pPlayer):sendSystemMessage(F.q3 .. ": the pattern is yours — 'Pattern of the First Pilgrims' rests in your inventory. (The craftable Ancient Combat Hilt schematic arrives with the client update.)")
	M:log(pPlayer, "act5 pattern ceremony (schematic pending — Phase C)")

	self:beginQuest(pPlayer, side, 4)
end

-- ---- site dispatch -----------------------------------------------------------

function JediParkAct5:onEnterSite(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local kind = readStringData(SceneObject(pArea):getObjectID() .. ":jtpAct5Kind")

	if (kind == nil or kind == "") then
		return 0
	end

	if (not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (kind == "cave") then
		if (M:hasStarted(pPlayer, 5, 2) and not M:hasDone(pPlayer, 5, 2) and dataNum(pPlayer, "act5_c1") == 0) then
			self:buildCache(pPlayer)
		end

	elseif (kind == "coll") then
		if (M:hasStarted(pPlayer, 5, 2) and not M:hasDone(pPlayer, 5, 2) and dataNum(pPlayer, "act5_c2") == 0) then
			self:buildCollector(pPlayer)
		end

	elseif (kind == "arena") then
		if (side ~= 1) then
			return 0
		end

		if (M:hasStarted(pPlayer, 5, 6) and not M:hasDone(pPlayer, 5, 6)) then
			if (dataNum(pPlayer, "act5_sarov_down") == 1) then
				self:offerSpare(pPlayer)
			else
				self:stageFinaleLight(pPlayer)
			end
		elseif (M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5)) then
			self:stageStudents(pPlayer)
		elseif (M:hasStarted(pPlayer, 5, 4) and not M:hasDone(pPlayer, 5, 4)) then
			self:stageSarovParley(pPlayer)
		end

	elseif (kind == "vader") then
		if (side == 2 and M:hasStarted(pPlayer, 5, 4) and not M:hasDone(pPlayer, 5, 4)) then
			self:stageVader(pPlayer)
		end

	elseif (kind == "duels") then
		if (side == 2 and M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5)) then
			self:enterDuels(pPlayer)
		end

	elseif (kind == "soulroom") then
		if (side == 2 and M:hasStarted(pPlayer, 5, 6) and not M:hasDone(pPlayer, 5, 6)) then
			self:stageFinaleDark(pPlayer)
		end

	elseif (kind == "hut") then
		if (dataNum(pPlayer, "act5_kenobi_due") == 1 and dataNum(pPlayer, "act5_kenobi_seen") == 0) then
			self:stageKenobiCoda(pPlayer)
		end
	end

	return 0
end

-- ---- Q5.2: the three components ----------------------------------------------
-- Every piece is re-grantable: the flags persist, the props rebuild while
-- a flag is missing, and nothing carried is the progress record.

-- The strongbox builds at the PLAYER's parent-aware position (act4's
-- unknown-floorplan idiom) so it works on world ground and in cave cells.
function JediParkAct5:buildCache(pPlayer)
	if (self:liveCount(pPlayer, "act5_cache") > 0) then
		return
	end

	local zone = SceneObject(pPlayer):getZoneName()

	if (zone == "" or not isZoneEnabled(zone)) then
		return
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = zone,
		cell = SceneObject(pPlayer):getParentID(),
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY(),
		props = { { JtpConfig.act5.items.relicProp, 1.5, 0, 1.5 } },
		lifetimeSec = 600,
		tag = "act5_cache",
	})

	if (built ~= nil and built.props[1] ~= nil) then
		SceneObject(built.props[1]):setObjectMenuComponent("JtpAct5RelicMenuComponent")
		CreatureObject(pPlayer):sendSystemMessage("Among the crystal-hunters' diggings, a strongbox older than the diggings — red-lit at the seams, sealed against everyone who was not sent for it. (Use the radial menu to open it.)")
	end
end

function JediParkAct5:buildCollector(pPlayer)
	if (self:liveCount(pPlayer, "act5_coll") > 0) then
		return
	end

	local CO = JtpConfig.act5.collector
	local built = JtpTheaters:build(pPlayer, {
		planet = CO.planet, x = CO.x, z = 0, y = CO.y,
		mobs = { { CO.template, 0, 0, 12, 180, CO.name } },
		lifetimeSec = CO.lifeSec,
		tag = "act5_coll",
	})

	if (built ~= nil and built.mobs[1] ~= nil) then
		self:attachKillObserver(pPlayer)
		AiAgent(built.mobs[1]):setDefender(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("The collector rises from a camp of other people's keepsakes, blade already lit. \"Everything here was TRADED fairly,\" he says, \"by the time I finished trading for it.\" What you came for hangs at his belt.")
	end
end

-- The shrine dig — staged by the shrine hook at whichever census well the
-- player chooses (parent-aware; shrines are world objects).
function JediParkAct5:buildDig(pPlayer)
	if (self:liveCount(pPlayer, "act5_dig") > 0) then
		return
	end

	local zone = SceneObject(pPlayer):getZoneName()

	if (zone == "" or not isZoneEnabled(zone)) then
		return
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = zone,
		cell = SceneObject(pPlayer):getParentID(),
		x = SceneObject(pPlayer):getPositionX(),
		z = SceneObject(pPlayer):getPositionZ(),
		y = SceneObject(pPlayer):getPositionY(),
		props = { { JtpConfig.act5.items.relicProp, 2, 0, 2 } },
		lifetimeSec = 600,
		tag = "act5_dig",
	})

	if (built ~= nil and built.props[1] ~= nil) then
		SceneObject(built.props[1]):setObjectMenuComponent("JtpAct5RelicMenuComponent")

		if (JediParkManager:sideOf(pPlayer) == 1) then
			CreatureObject(pPlayer):sendSystemMessage("At the shrine's foot, the ground shows a seam the years failed to close — something was buried here with ceremony, by hands that shook. (Use the radial menu to dig.)")
		else
			CreatureObject(pPlayer):sendSystemMessage("At the shrine's foot, a seam in the ground: the rival's trophy case, buried with the confidence of someone who expected to come back. (Use the radial menu to dig.)")
		end
	end
end

-- Shared radial for the strongbox and the dig (per-player: only the
-- owner's theater members answer).
JtpAct5RelicMenuComponent = {}

function JtpAct5RelicMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpAct5RelicMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pSceneObject == nil or pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager
	local A = JediParkAct5
	local which = 0

	if (JtpTheaters:isTheaterMob(pPlayer, "act5_cache", pSceneObject)) then
		which = 1
	elseif (JtpTheaters:isTheaterMob(pPlayer, "act5_dig", pSceneObject)) then
		which = 3
	end

	if (which == 0) then
		CreatureObject(pPlayer):sendSystemMessage("It is sealed against you. Whatever claim is on it belongs to someone else's making.")
		return 0
	end

	if (not A:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 2) or M:hasDone(pPlayer, 5, 2)) then
		return 0
	end

	if (dataNum(pPlayer, "act5_c" .. which) == 1) then
		return 0
	end

	local side = M:sideOf(pPlayer)
	dataSet(pPlayer, "act5_c" .. which, 1)

	if (which == 1) then
		JtpTheaters:teardown(pPlayer, "act5_cache")

		if (side == 1) then
			CreatureObject(pPlayer):sendSystemMessage("The strongbox gives up a hilt-fragment wrapped in a hunter's tally of what silence cost. (" .. A:componentCount(pPlayer) .. " of 3 pieces — " .. FLAVOR[1].comp1 .. ")")
		else
			CreatureObject(pPlayer):sendSystemMessage("The strongbox gives up a raw deep-cave crystal, cold enough to bite through the wrapping. (" .. A:componentCount(pPlayer) .. " of 3 pieces — " .. FLAVOR[2].comp1 .. ")")
		end
	else
		JtpTheaters:teardown(pPlayer, "act5_dig")

		if (side == 1) then
			CreatureObject(pPlayer):sendSystemMessage("Under a hand's-depth of years: the buried fragment, folded in a dead friend's cloak-cloth. The shrine keeps its opinion. (" .. A:componentCount(pPlayer) .. " of 3 pieces — " .. FLAVOR[1].comp3 .. ")")
		else
			CreatureObject(pPlayer):sendSystemMessage("The trophy case opens on velvet and vanity — and one focusing ring of the old pattern, which is the only thing in it that was ever worth burying. (" .. A:componentCount(pPlayer) .. " of 3 pieces — " .. FLAVOR[2].comp3 .. ")")
		end
	end

	if (A:componentCount(pPlayer) >= 3) then
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q2 .. ": all three pieces are in hand. Return to " .. FLAVOR[side].giver .. ".")
	end

	return 0
end

-- ---- shrine hook (MAIN LOOP wiring: called for EVERY shrine entry) -----------
-- Placement contract (integration): jtp_shrines.lua must invoke this
-- BEFORE its hasVisited early-return — the dig and the letter are "any
-- shrine of the player's choice", and the nearest choice is usually a
-- shrine the player has already walked.

function JediParkAct5:onShrineVisited(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	-- Cheap-out fast: this fires on every shrine entry.
	local wantDig = M:hasStarted(pPlayer, 5, 2) and not M:hasDone(pPlayer, 5, 2) and dataNum(pPlayer, "act5_c3") == 0
	local wantLetter = M:hasStarted(pPlayer, 5, 7) and not M:hasDone(pPlayer, 5, 7)

	if (not wantDig and not wantLetter) then
		return
	end

	if (not self:gateOk(pPlayer)) then
		return
	end

	if (wantDig) then
		self:buildDig(pPlayer)
	end

	if (wantLetter) then
		local side = M:sideOf(pPlayer)
		local C = JtpConfig.act5

		self:completeQuest(pPlayer, 7)
		M:giveLootGroup(pPlayer, C.lootGroups.powerCrystal)
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q7 .. ": a power crystal arrives with the archivist's gratitude. (Choice-grade selection lands with the client update.)")

		if (side == 1) then
			M:adjustVisibility(pPlayer, C.visLetterLight)
			self:sui(pPlayer, FLAVOR[1].q7, "You set the letter at the shrine's foot, and the well takes it the way wells take rain — without ceremony, without loss. 'To whoever is left.' Someone will be. That was always Ondel's entire theology. You leave lighter than you came, in every way the Empire measures.")
			CreatureObject(pPlayer):sendSystemMessage("Your visibility fades. The road forgets your footsteps kindly.")
		else
			self:sui(pPlayer, FLAVOR[2].q7, "You set the letter at the shrine's foot. 'To whoever is left.' The well takes it without comment, which is more than the Voice managed — although later, filed between instructions, you will find one line of approval: \"The instrument delivered a stranger's inheritance intact. Noted.\"")
		end
	end
end

-- ---- Q5.4L: the parley (converse-driven; Sarov is CONVERSABLE) ---------------

function JediParkAct5:stageSarovParley(pPlayer)
	if (dataNum(pPlayer, "act5_parley_done") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act5_sarov") > 0) then
		return
	end

	if (self:buildSarovScene(pPlayer, "act5_sarov") ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("Among the pillars, between four cold shrine-stones, a figure the ruins have arranged themselves around. Master Sarov does not draw. He watches you cross his grave's threshold. (Speak with him.)")
	end
end

-- Shared arena dressing: 4 shrines + Sarov (invulnerable until flipped).
function JediParkAct5:buildSarovScene(pPlayer, tag)
	local A = JtpConfig.act5.arena
	local props = {}

	for i = 1, #A.shrineOffsets, 1 do
		local o = A.shrineOffsets[i]
		props[#props + 1] = { JtpConfig.act5.items.shrineProp, o[1], 0, o[2] }
	end

	local sarov = { A.sarovTemplate, 0, 0, 8, 180 }
	sarov.invuln = true

	local built = JtpTheaters:build(pPlayer, {
		planet = A.planet, x = A.x, z = 0, y = A.y, cell = 0,
		props = props,
		mobs = { sarov },
		lifetimeSec = A.lifeSec,
		tag = tag,
	})

	if (built == nil or built.mobs[1] == nil) then
		print("jtp: act5 WARNING — Sarov spawn failed (is mobile/jtp_sarov.lua included in custom_scripts/mobile/serverobjects.lua?)")
		return nil
	end

	return built
end

-- The convo router (jtp_sarov_handler). pNpc gates ownership: only the
-- player's own staged Master answers.
function JediParkAct5:onSarovTalk(pPlayer, pNpc)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	if (pNpc ~= nil and not JtpTheaters:isTheaterMob(pPlayer, "act5_sarov", pNpc) and not JtpTheaters:isTheaterMob(pPlayer, "act5_finale", pNpc)) then
		self:sui(pPlayer, "Master Sarov, the Fallen", "The Fallen Master's eyes pass over you and find nothing they were waiting for. Whatever is happening among these stones, it is not yours.")
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1) then
		self:sui(pPlayer, "Master Sarov, the Fallen", "The grief in the ruins turns its face toward you, reads what your hands have trained, and turns away. \"Another collector,\" he says, to nobody living. He does not consider you worth the stroke. Yet.")
		return
	end

	local gate = self:gateState(pPlayer)

	if (gate == "pause") then
		self:sendPauseNotice(pPlayer)
		return
	elseif (gate == "no") then
		self:sui(pPlayer, "Master Sarov, the Fallen", "\"Go home,\" the figure says, without looking. \"Whatever they sent you to be, you are not it yet.\"")
		return
	end

	if (M:hasStarted(pPlayer, 5, 6) and not M:hasDone(pPlayer, 5, 6)) then
		if (dataNum(pPlayer, "act5_sarov_down") == 1) then
			self:offerSpare(pPlayer)
		elseif (dataNum(pPlayer, "act5_fin_flipped") == 1) then
			CreatureObject(pPlayer):sendSystemMessage("The blade is his answer. There is no more talking in him until one of you is finished.")
		elseif (self:liveCount(pPlayer, "act5_finale") > 0) then
			self:offerBlade(pPlayer)
		else
			CreatureObject(pPlayer):sendSystemMessage("The arena is empty. Walk the stones; the fires will find their places.")
		end
		return
	end

	if (M:hasStarted(pPlayer, 5, 4) and not M:hasDone(pPlayer, 5, 4)) then
		if (self:liveCount(pPlayer, "act5_sarov") > 0) then
			self:parleyScreen1(pPlayer)
		end
		return
	end

	if (M:hasDone(pPlayer, 5, 4) and M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5)) then
		self:sui(pPlayer, "Master Sarov, the Fallen", "\"I told you what my answer costs.\" He is already turning away. \"My students will collect it. They always do.\"")
		return
	end

	self:sui(pPlayer, "Master Sarov, the Fallen", "The figure among the stones keeps its grief the way the ruins keep their name: completely, and to itself.")
end

function JediParkAct5:parleyScreen1(pPlayer)
	local sui = SuiMessageBox.new("JediParkAct5", "parleyCb2")
	sui.setTitle(FLAVOR[1].q4)
	sui.setPrompt("Up close, the Fallen Master is not a monster; that is the unbearable part. He is an old man standing very straight in a place where everyone he failed can see him. \"You walk like one of Maro's,\" he says. \"He keeps sending me knights. I keep sending him reasons to stop.\" His eyes find the pattern-work at your belt, and something in them goes very still. \"That geometry is four thousand years dead. Where did you steal it.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct5:parleyCb2(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct5", "parleyCb3")
	sui.setTitle(FLAVOR[1].q4)
	sui.setPrompt("You tell him: a trade, a theft, a burial. The three fragments of his own broken hilt, recovered and laid into the first pilgrims' pattern. For one breath the ruins are absolutely silent, and then he laughs — one note, the worst sound the stones have made in eleven years. \"A whole blade does not mend a broken hand. I BROKE it over their pyre so it could never be held again — do you understand? The holding is the crime. Every time I held it, someone I taught died of my competence.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct5:parleyCb3(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct5", "parleyCbDone")
	sui.setTitle(FLAVOR[1].q4)
	sui.setPrompt("\"No,\" he says, before you have finished offering. \"Take Maro's ledger home, and your church's forgiveness with it. I have killed Inquisitors for less mercy than you are showing me, and students for more.\" He turns his back — an old master's precise contempt, or an old man's precise despair; the ruins decline to translate. \"Finish your blade if you must. Bring it here if you dare. My last students hold the pillar line, and they will show you what my teaching is worth now.\" The parley is over. The fight has an appointment.")
	sui.sendTo(pPlayer)
end

function JediParkAct5:parleyCbDone(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	dataSet(pPlayer, "act5_parley_done", 1)
	self:completeQuest(pPlayer, 4)
	createEvent(10000, "JediParkAct5", "teardownTag", pPlayer, "act5_sarov")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q4 .. ": he refused — and named his price. Return to Keeper Maro.")
end

-- ---- Q5.4D: the Vader audience (oath room — see header DEVIATION) ------------

function JediParkAct5:stageVader(pPlayer)
	if (dataNum(pPlayer, "act5_vader_done") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act5_vader") > 0) then
		return
	end

	local V = JtpConfig.act5.vader
	local vader = { V.template, 0, 0, 0, V.spot.heading }
	vader.invuln = true

	local built = JtpTheaters:build(pPlayer, {
		planet = V.planet, cell = V.cell,
		x = V.spot.x, z = V.spot.z, y = V.spot.y,
		props = {
			{ JtpConfig.act5.items.relicProp, -2.5, 0, 1.5 },
			{ JtpConfig.act5.items.relicProp, 2.5, 0, 1.5 },
		},
		mobs = { vader },
		lifetimeSec = V.lifeSec,
		tag = "act5_vader",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	self:vaderScreen1(pPlayer)
end

function JediParkAct5:vaderScreen1(pPlayer)
	local sui = SuiMessageBox.new("JediParkAct5", "vaderCb2")
	sui.setTitle(FLAVOR[2].q4)
	sui.setPrompt("The cloning cell is colder than the vats can explain. He chose this room — the room where you died before you served — and he fills it the way a verdict fills a courtroom. The breathing arrives before the shape does. Lord Vader does not greet. Lord Vader does not need to. Two red fires burn at his back, and the vats reflect him badly, as if the glass would rather not.")
	sui.sendTo(pPlayer)
end

function JediParkAct5:vaderCb2(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	local prompt

	if (dataNum(pPlayer, "act3_oath_taken") == 1) then
		prompt = "\"You spoke an oath in this room.\" It is not a question; the room itself seems to have reported it. \"'Die before you serve.' The dying was recorded. The serving is under review.\" He crosses to the spot where you knelt, and looks at the floor as if the words were still lying there. \"Most who speak it believe they are describing a ceremony. It is a LEDGER ENTRY. The Emperor collects on every line.\""
	else
		prompt = "\"This room takes oaths.\" He regards the floor where other knees have learned that. \"Yours was taken elsewhere — or not at all. The distinction has been noted, and the notation is not in your favor. What the Empire cannot read, the Empire re-reads at its own pace, in rooms with fewer doors than this one.\""
	end

	local sui = SuiMessageBox.new("JediParkAct5", "vaderCb3")
	sui.setTitle(FLAVOR[2].q4)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct5:vaderCb3(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	local prompt

	if (dataNum(pPlayer, "act4_testament") == 1) then
		prompt = "\"You carry the Circle's Testament. Sealed.\" A pause the length of a held breath that is not yours. \"The Voice wagered you would not open it. I wagered nothing. I have watched stronger appetites than yours starve at a seal — and I have watched one man's unopened letter burn a fleet.\" The mask tilts, a degree. \"You did not read it. That is the first thing about you the Emperor will be told.\""
	else
		prompt = "\"The Voice's errands reach my desk with the names removed. Yours survives the redaction.\" The mask tilts, a degree — the largest gesture the room will get. \"Understand what that costs the people whose names do not.\""
	end

	local sui = SuiMessageBox.new("JediParkAct5", "vaderCb4")
	sui.setTitle(FLAVOR[2].q4)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct5:vaderCb4(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct5", "vaderCbDone")
	sui.setTitle(FLAVOR[2].q4)
	sui.setPrompt("\"The test, then. The Emperor keeps one Hand in this sector. The office is occupied. The occupant is ALIVE.\" He lets the word stand in the cold until it means what he needs it to mean. \"An incumbent who can be replaced is an error in the incumbent. An aspirant who cannot replace her is an error in the aspirant. The Emperor does not keep errors.\" The breathing turns away; the audience is ending the way weather ends. \"Correct one of them.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct5:vaderCbDone(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 2 or not self:gateOk(pPlayer) or not M:hasStarted(pPlayer, 5, 4) or M:hasDone(pPlayer, 5, 4)) then
		return
	end

	dataSet(pPlayer, "act5_vader_done", 1)
	self:completeQuest(pPlayer, 4)
	createEvent(12000, "JediParkAct5", "teardownTag", pPlayer, "act5_vader")
	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q4 .. ": the oath is collected; the test is named. Return to the Hand's Voice.")
end

-- ---- Q5.5L: His Last Students ------------------------------------------------

function JediParkAct5:stageStudents(pPlayer)
	if (dataNum(pPlayer, "act5_students_done") == 1) then
		return
	end

	if (self:liveCount(pPlayer, "act5_students") > 0) then
		return
	end

	local A = JtpConfig.act5.arena
	local mobs = {}

	for i = 1, #A.students, 1 do
		local o = A.students[i]
		mobs[#mobs + 1] = { A.studentTemplate, o[1], 0, o[2], 180, A.studentName }
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = A.planet, x = A.x, z = 0, y = A.y, cell = 0,
		mobs = mobs,
		lifetimeSec = A.lifeSec,
		tag = "act5_students",
	})

	if (built == nil or #built.mobs == 0) then
		return
	end

	dataSet(pPlayer, "act5_students_left", #built.mobs)
	self:attachKillObserver(pPlayer)

	for i = 1, #built.mobs, 1 do
		AiAgent(built.mobs[i]):setDefender(pPlayer)
	end

	CreatureObject(pPlayer):sendSystemMessage("Two figures step out of the pillar shadows in the ruins' silence — knights' stances under dark robes, and grief worn like armor over the armor. Neither speaks. Their master taught them everything except how to stop.")
end

-- ---- Q5.5D: Vacancies Are Made (staggered arenahall duels) -------------------

function JediParkAct5:enterDuels(pPlayer)
	if (dataNum(pPlayer, "act5_duels_done") == 1) then
		return
	end

	local stage = dataNum(pPlayer, "act5_duel_stage")

	if (stage > 0) then
		-- Restart/expiry self-heal: a stage with no living duelist lapses
		-- (act4 kun idiom; the between-duels window is timer-fenced by the
		-- token, which the reset clears).
		if (self:liveCount(pPlayer, "act5_duel") == 0 and dataNum(pPlayer, "act5_duel_token") ~= 0) then
			local pending = dataNum(pPlayer, "act5_duel_pending")

			if (pending == 0) then
				self:resetDuels(pPlayer, "The floor has gone cold — the estate re-files its claims. Stand the arena again to begin the settlements over.")
			end
		end

		return
	end

	local sui = SuiListBox.new("JediParkAct5", "duelStartCallback")
	sui.setTitle(FLAVOR[2].q5)
	sui.setPrompt("The arenahall floor is swept, which in this enclave is a threat. Three aspirants wait in the gallery dark — the incumbent's bodyguard, each of them privately certain the other two are the ones who bet wrong. The estate settles one claim at a time. That is the only mercy on the docket.")
	sui.add("Stand the floor. (Begin: three duels, one at a time)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct5:duelStartCallback(pPlayer, pSui, eventIndex, args)
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

	if (not M:hasStarted(pPlayer, 5, 5) or M:hasDone(pPlayer, 5, 5) or dataNum(pPlayer, "act5_duels_done") == 1) then
		return
	end

	if (dataNum(pPlayer, "act5_duel_stage") ~= 0) then
		return
	end

	dataSet(pPlayer, "act5_duel_token", getTimestamp())
	dataSet(pPlayer, "act5_duel_pending", 0)
	self:spawnDuelist(pPlayer, 1)
end

function JediParkAct5:spawnDuelist(pPlayer, n)
	local D = JtpConfig.act5.duels
	local built = JtpTheaters:build(pPlayer, {
		planet = D.planet, cell = D.cell,
		x = D.spot.x, z = D.spot.z, y = D.spot.y,
		mobs = { { D.template, 0, 0, 0, D.spot.heading, D.name } },
		lifetimeSec = D.lifeSec,
		tag = "act5_duel",
	})

	if (built == nil or built.mobs[1] == nil) then
		self:resetDuels(pPlayer, "The settlement stumbles — no claimant took the floor. Stand the arena again.")
		return
	end

	dataSet(pPlayer, "act5_duel_stage", n)
	dataSet(pPlayer, "act5_duel_pending", 0)
	self:attachKillObserver(pPlayer)
	AiAgent(built.mobs[1]):setDefender(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Duel " .. n .. " of " .. JtpConfig.act5.duels.count .. ": an aspirant takes the floor, saber already committed to the argument.")
end

function JediParkAct5:duelNextEvent(pPlayer, args)
	if (pPlayer == nil or args == nil or not JediParkManager.enabled()) then
		return
	end

	local token, n = string.match(args, "^(%d+):(%d+)$")

	if (token == nil) then
		return
	end

	if (tostring(dataNum(pPlayer, "act5_duel_token")) ~= token) then
		return -- reset/lapsed run owns a new token (or 0)
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 5, 5) or M:hasDone(pPlayer, 5, 5) or dataNum(pPlayer, "act5_duels_done") == 1) then
		return
	end

	self:spawnDuelist(pPlayer, tonumber(n))
end

function JediParkAct5:resetDuels(pPlayer, message)
	JtpTheaters:teardown(pPlayer, "act5_duel")
	dataSet(pPlayer, "act5_duel_stage", 0)
	dataSet(pPlayer, "act5_duel_token", 0)
	dataSet(pPlayer, "act5_duel_pending", 0)

	if (message ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(message)
	end
end

-- ---- Q5.6L: FINALE "The Unbroken Light" --------------------------------------

function JediParkAct5:stageFinaleLight(pPlayer)
	if (dataNum(pPlayer, "act5_sarov_down") == 1) then
		return
	end

	if (not self:hasCapstone(pPlayer, 1)) then
		self:sendNotWholeNotice(pPlayer, 1)
		return
	end

	if (self:liveCount(pPlayer, "act5_finale") > 0) then
		if (dataNum(pPlayer, "act5_fin_flipped") == 0) then
			self:offerBlade(pPlayer)
		end

		return
	end

	local built = self:buildSarovScene(pPlayer, "act5_finale")

	if (built == nil) then
		return
	end

	dataSet(pPlayer, "act5_fin_boss", tostring(SceneObject(built.mobs[1]):getObjectID()))

	local mobOids = {}

	for i = 1, #built.mobs, 1 do
		mobOids[#mobOids + 1] = SceneObject(built.mobs[i]):getObjectID()
	end

	dataSet(pPlayer, "act5_fin_mobs", table.concat(mobOids, ","))
	dataSet(pPlayer, "act5_fin_flipped", 0)
	self:attachKillObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("Four shrines burn white around the arena — the ruins' own fires, lit for no living order. Sarov stands at their center with his empty hands open, waiting for what you carry.")
	self:offerBlade(pPlayer)
end

function JediParkAct5:offerBlade(pPlayer)
	local sui = SuiListBox.new("JediParkAct5", "bladeCallback")
	sui.setTitle(FLAVOR[1].q6)
	sui.setPrompt("The four fires hold the dark off the stones. Sarov looks at the blade you made — his three broken pieces, whole in a pattern older than both your churches — and for one moment there is a teacher's face over the grave's face. \"You rebuilt the crime,\" he says softly. \"Now we learn if it was ever the hilt that was broken.\" He does not reach for it. \"Offer it, then. And survive my answer — all of it. That is the only way either of us will believe the other.\"")
	sui.add("Offer Sarov the blade.", "")
	sui.add("Step back. (Not yet)", "")
	sui.sendTo(pPlayer)
end

function JediParkAct5:bladeCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (M:sideOf(pPlayer) ~= 1 or not self:gateOk(pPlayer) or not self:hasCapstone(pPlayer, 1)) then
		return
	end

	if (not M:hasStarted(pPlayer, 5, 6) or M:hasDone(pPlayer, 5, 6) or dataNum(pPlayer, "act5_sarov_down") == 1) then
		return
	end

	if (dataNum(pPlayer, "act5_fin_flipped") == 1 or self:liveCount(pPlayer, "act5_finale") == 0) then
		return
	end

	-- The act3 Q3.7 arena flip, verbatim: pvp mask up, aggro flag off,
	-- pressed onto the offerer.
	local list = readScreenPlayData(pPlayer, "JediPark", "act5_fin_mobs")

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
		dataSet(pPlayer, "act5_fin_flipped", 1)
		self:sui(pPlayer, FLAVOR[1].q6, "He takes the blade. He holds it the way a drowning man holds the water. And then his answer begins — everything he has left, which is everything: eleven years of grief with a master's footwork under it. \"SURVIVE me,\" he says, and the white fires bend away from what wakes in his hands.")
		CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q6 .. ": survive his answer.")
	end
end

-- The post-fight choice (Phase A: the fight runs to its end; the yielding
-- and the choice are the scene's closing beat — both paths complete).
function JediParkAct5:offerSpare(pPlayer)
	local sui = SuiListBox.new("JediParkAct5", "spareCallback")
	sui.setTitle(FLAVOR[1].q6)
	sui.setPrompt("It ends among the white fires: Sarov on his knees, the made blade fallen between you, his answer spent to the last stroke. What is left kneeling is not the grave's keeper — only the teacher, empty at last, looking up at the student the Purge never let him have. \"Well made,\" he says — the blade, or you; he does not specify. The ruins wait. The fires wait. The ending is yours to speak.")
	sui.add("Stay the blade. (Spare him for the Mountain's keeping)", "")
	sui.add("Strike true. (Grief has one mercy left)", "")
	sui.sendTo(pPlayer)
end

function JediParkAct5:spareCallback(pPlayer, pSui, eventIndex, args)
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

	if (not M:hasStarted(pPlayer, 5, 6) or M:hasDone(pPlayer, 5, 6) or dataNum(pPlayer, "act5_sarov_down") ~= 1) then
		return
	end

	local epilogue

	if (idx == 0) then
		dataSet(pPlayer, "act5_sarov_spared", 1)
		epilogue = "You lower the blade. Sarov closes his eyes as if the mercy were the heavier stroke — and perhaps it is; he will have to carry it. The Singing Mountain's daughters come down through the ruins before moonrise, the way Veshaan's people always know, and take the emptied man into the Mountain's keeping. No living master remains among the stones. What remains is lighter.\n\nAt the enclave, Maro opens the buried pages and — for the first time in eleven years — moves a name OUT of them. \"The Unbroken Light,\" he says, folding the good cloth into your arms, setting the crystal in your palm. \"It was never the blade, ember. It was the hand that stayed.\""
	else
		dataSet(pPlayer, "act5_sarov_spared", 0)
		epilogue = "You strike true. The grief goes out of him like a held door finally let go, and what falls among the white fires is only an old man the Purge finished eleven years late — at his own asking, by a whole blade, in front of witnesses of stone. The ruins keep the name. They were always going to.\n\nAt the enclave, Maro writes the last entry in the buried pages, and closes the book forever. \"The Unbroken Light,\" he says, folding the good cloth into your arms, setting the crystal in your palm. \"Grief has one mercy, and you did not make him beg for it. The hall holds him with the kept now. Both of you came home.\""
	end

	self:finishAct(pPlayer, 1, epilogue)
end

-- ---- Q5.6D: FINALE "Heart of Darkness" ---------------------------------------

function JediParkAct5:stageFinaleDark(pPlayer)
	if (dataNum(pPlayer, "act5_fin_dead") == 1) then
		return
	end

	if (not self:hasCapstone(pPlayer, 2)) then
		self:sendNotWholeNotice(pPlayer, 2)
		return
	end

	if (self:liveCount(pPlayer, "act5_finale") > 0) then
		return
	end

	local S = JtpConfig.act5.soulroom
	local rivalName = incumbentName(pPlayer)
	local vader = { JtpConfig.act5.vader.template, 4, 0, -3, 0 }
	vader.invuln = true

	local built = JtpTheaters:build(pPlayer, {
		planet = S.planet, cell = S.cell,
		x = S.anchor.x, z = S.anchor.z, y = S.anchor.y,
		props = {
			{ JtpConfig.act5.items.relicProp, -2.5, 0, 2 },
			{ JtpConfig.act5.items.relicProp, 2.5, 0, 2 },
		},
		mobs = {
			{ S.bossTemplate, 0, 0, 0, 180, rivalName },
			vader,
		},
		lifetimeSec = S.lifeSec,
		tag = "act5_finale",
	})

	if (built == nil or built.mobs[1] == nil) then
		return
	end

	-- FACTION STRIP (see header): emperors_hand is faction "imperial";
	-- an Imperial-coerced dark Jedi could never attack a same-faction
	-- agent. Neutralized at spawn, stock recruiter precedent.
	CreatureObject(built.mobs[1]):setFaction(0)

	dataSet(pPlayer, "act5_fin_boss", tostring(SceneObject(built.mobs[1]):getObjectID()))
	dataSet(pPlayer, "act5_fin_flipped", 1)
	self:attachKillObserver(pPlayer)
	AiAgent(built.mobs[1]):setDefender(pPlayer)

	if (dataNum(pPlayer, "act4_vheress_dead") == 1) then
		self:sui(pPlayer, FLAVOR[2].q6, "The soulroom still eats echoes — your footsteps go in and do not come back. The interim Hand waits in the hollow with her saber already lit, and in the deeper dark behind her: the breathing, and two folded arms. \"The office is not vacant,\" the incumbent says. \"It is DISPUTED. The distinction dies with one of us.\" The red light commits.")
	else
		self:sui(pPlayer, FLAVOR[2].q6, "The soulroom still eats echoes — your footsteps go in and do not come back. Vheress waits in the hollow with her saber already lit; she has been ahead of you the whole way, and she knows exactly how much of the way that bought her. In the deeper dark behind her: the breathing, and two folded arms, helping neither of you. \"The doorstep shadow,\" she says. \"The Emperor keeps one Hand. Come take the arithmetic personally.\" The red light commits.")
	end

	CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q6 .. ": there is exactly one door out.")
end

-- ---- L coda: the hut (cell 3565386) ------------------------------------------

function JediParkAct5:stageKenobiCoda(pPlayer)
	if (self:liveCount(pPlayer, "act5_kenobi") > 0) then
		return
	end

	local H = JtpConfig.act5.hut

	JtpTheaters:apparition(pPlayer, {
		planet = H.planet, cell = H.cell,
		x = H.spirit.x, z = H.spirit.z, y = H.spirit.y,
		template = "jtp_kenobi_spirit",
		heading = H.spirit.heading,
		glow = "light",
		lifetimeSec = H.lifeSec,
		invulnerable = true,
		onAppear = { screenplay = "JediParkAct5", fn = "onKenobiCoda" },
		tag = "act5_kenobi",
	})
end

function JediParkAct5:onKenobiCoda(pPlayer, tag)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (dataNum(pPlayer, "act5_kenobi_due") ~= 1 or dataNum(pPlayer, "act5_kenobi_seen") == 1) then
		return
	end

	dataSet(pPlayer, "act5_kenobi_seen", 1)
	dataSet(pPlayer, "act5_kenobi_due", 0)

	local closing

	if (dataNum(pPlayer, "act5_sarov_spared") == 1) then
		closing = "The hut is a hut — swept, small, and briefly not empty. The old man's shape stands in its own light for exactly as long as a sentence needs. \"You did what I could not, at Bestine. Do not ask which part.\" A pause that carries a smile it does not show. \"The hand that stayed. Tell Maro the ledger balances.\" The light goes out of the room politely, the way a guest leaves."
	else
		closing = "The hut is a hut — swept, small, and briefly not empty. The old man's shape stands in its own light for exactly as long as a sentence needs. \"You did what I could not, at Bestine. Do not ask which part.\" A pause with an old grief folded into it, neatly, like the blankets. \"Some mercies wear edges. He knew. So do you, now.\" The light goes out of the room politely, the way a guest leaves."
	end

	self:sui(pPlayer, "A Moment, Not a Haunting", closing)
	JediParkManager:log(pPlayer, "act5 kenobi coda delivered")
end

-- ---- the shared kill observer ------------------------------------------------

function JediParkAct5:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct5", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct5", "onKill", pPlayer, 1)
end

function JediParkAct5:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	-- Grace-floor hold: while paused, nothing advances and nothing is lost.
	if (not self:gateOk(pPlayer)) then
		return 0
	end

	local M = JediParkManager
	local C = JtpConfig.act5
	local side = M:sideOf(pPlayer)
	local victimID = tostring(SceneObject(pVictim):getObjectID())

	-- Q5.2: the collector.
	if (M:hasStarted(pPlayer, 5, 2) and not M:hasDone(pPlayer, 5, 2) and dataNum(pPlayer, "act5_c2") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act5_coll", pVictim)) then
			dataSet(pPlayer, "act5_c2", 1)

			if (side == 1) then
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q2 .. ": from the collector's belt, the stolen fragment — still wearing another man's grief like a pawn ticket. (" .. self:componentCount(pPlayer) .. " of 3 pieces)")
			else
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q2 .. ": the hunter-killer's spine surrenders its alloy. He collected consequences; you collected his. (" .. self:componentCount(pPlayer) .. " of 3 pieces)")
			end

			if (self:componentCount(pPlayer) >= 3) then
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[side].q2 .. ": all three pieces are in hand. Return to " .. FLAVOR[side].giver .. ".")
			end
		end
	end

	-- Q5.5L: the last students.
	if (side == 1 and M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5) and dataNum(pPlayer, "act5_students_done") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act5_students", pVictim)) then
			local left = dataNum(pPlayer, "act5_students_left") - 1
			dataSet(pPlayer, "act5_students_left", left)

			if (left <= 0) then
				dataSet(pPlayer, "act5_students_done", 1)
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": the pillar line is open. Among the stones, the Fallen Master has watched — and has not moved. Return to Keeper Maro.")
			else
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[1].q5 .. ": one student falls. The other does not look at the body. " .. left .. " still holds the line.")
			end
		end
	end

	-- Q5.5D: the staggered duels.
	if (side == 2 and M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5) and dataNum(pPlayer, "act5_duels_done") == 0) then
		if (JtpTheaters:isTheaterMob(pPlayer, "act5_duel", pVictim)) then
			local stage = dataNum(pPlayer, "act5_duel_stage")

			if (stage >= C.duels.count) then
				dataSet(pPlayer, "act5_duels_done", 1)
				dataSet(pPlayer, "act5_duel_pending", 0)
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q5 .. ": the third claim is settled. The floor is yours, which the gallery files as a fact about YOU. Return to the Hand's Voice.")
			else
				dataSet(pPlayer, "act5_duel_pending", 1)
				CreatureObject(pPlayer):sendSystemMessage(FLAVOR[2].q5 .. ": claim " .. stage .. " settled. The next aspirant is re-reading the estate.")
				createEvent(C.duels.betweenMs, "JediParkAct5", "duelNextEvent", pPlayer, tostring(dataNum(pPlayer, "act5_duel_token")) .. ":" .. (stage + 1))
			end
		end
	end

	-- Q5.6: the finale bosses.
	if (M:hasStarted(pPlayer, 5, 6) and not M:hasDone(pPlayer, 5, 6)) then
		if (victimID == (readScreenPlayData(pPlayer, "JediPark", "act5_fin_boss") or "") and JtpTheaters:isTheaterMob(pPlayer, "act5_finale", pVictim)) then
			if (side == 1 and dataNum(pPlayer, "act5_sarov_down") == 0) then
				dataSet(pPlayer, "act5_sarov_down", 1)
				createEvent(2500, "JediParkAct5", "teardownTag", pPlayer, "act5_finale")
				self:offerSpare(pPlayer)
			elseif (side == 2 and dataNum(pPlayer, "act5_fin_dead") == 0) then
				dataSet(pPlayer, "act5_fin_dead", 1)
				CreatureObject(pPlayer):sendSystemMessage("From the dark at the soulroom's edge, arms still folded, Lord Vader speaks exactly once: \"Adequate.\"")
				createEvent(6000, "JediParkAct5", "teardownTag", pPlayer, "act5_finale")
				self:finishAct(pPlayer, 2, nil)
			end
		end
	end

	return 0
end

-- ---- rewards, act finale, shared helpers -------------------------------------

function JediParkAct5:completeQuest(pPlayer, quest, frsOverride)
	local C = JtpConfig.act5
	JediParkManager:setDone(pPlayer, 5, quest)
	JediParkManager:giveCredits(pPlayer, C.creditsPerQuest)
	JediParkManager:awardFrsXp(pPlayer, frsOverride or C.frsPerQuest)
end

function JediParkAct5:reward(pPlayer)
	local C = JtpConfig.act5
	JediParkManager:giveCredits(pPlayer, C.creditsPerQuest)
	JediParkManager:awardFrsXp(pPlayer, C.frsPerQuest)
end

-- The act finale: 20k FRS, ceremony token, crystal roll, the robe,
-- JediPark bits 256 + 8192/16384, badge 145/146 placeholder. The L path
-- passes its spare/strike epilogue text; D uses the house closing.
function JediParkAct5:finishAct(pPlayer, side, epilogueText)
	local M = JediParkManager
	local C = JtpConfig.act5
	local F = FLAVOR[side]

	self:completeQuest(pPlayer, 6, C.frsFinale)
	M:giveLootGroup(pPlayer, C.lootGroups.colorCrystal)

	if (side == 1) then
		M:giveNamedItem(pPlayer, C.items.token, C.items.tokenLightName)
		M:giveNamedItem(pPlayer, C.items.robeLight, nil)
		M:setGlobal(pPlayer, 8192)
		dataSet(pPlayer, "act5_kenobi_due", 1)
	else
		M:giveNamedItem(pPlayer, C.items.token, C.items.tokenDarkName)
		M:giveNamedItem(pPlayer, C.items.robeDark, nil)
		M:setGlobal(pPlayer, 16384)
	end

	M:setGlobal(pPlayer, 256)

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Act complete: " .. F.actName .. ". (Badge 'The Unbroken Light' arrives with the client update.)")
	else
		CreatureObject(pPlayer):sendSystemMessage("Act complete: " .. F.actName .. ". (Badge 'Heart of Darkness' arrives with the client update.)")
	end

	if (epilogueText ~= nil) then
		self:sui(pPlayer, F.actName, epilogueText)
	elseif (side == 2) then
		self:sui(pPlayer, F.actName, "The soulroom takes the incumbent's last echo and gives nothing back — it never has. The breathing crosses the hollow, past you, without pausing; the audience was one word long and the word has been spent. There is exactly one door out, and you walk it as the Emperor's one Hand in this sector.\n\nAt Council One the unlit saber is gone from the wall. In its place: a hook, empty, at the height of YOUR belt. The Voice sets a dark crystal in your palm — Maul's Vengence, an instructive spelling, the Voice notes, in that the vengeance outlived the speller — and lays the Inquisitor's robe across your arms as if folding a flag. \"The Hand closes,\" says the Voice. \"Remain useful. Remain quiet.\"")
	end

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Something waits for you at a small, swept hut outside Anchorhead. The road knows the way by heart now.")
	end

	JediParkManager:log(pPlayer, "act5 finale complete (side " .. side .. ")")
end

-- ---- login self-heal (MAIN LOOP wires this beside JediParkAct3:heal) ---------
-- Re-arms the volatile pieces a restart drops; theater/duel state
-- self-heals lazily at its own sites (the act4 lapse idiom).

function JediParkAct5:heal(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local M = JediParkManager

	-- Kill observer for any tracked quest mid-flight.
	local tracked = { 2, 5, 6 }

	for i = 1, #tracked, 1 do
		if (M:hasStarted(pPlayer, 5, tracked[i]) and not M:hasDone(pPlayer, 5, tracked[i])) then
			self:attachKillObserver(pPlayer)
			break
		end
	end

	-- A restart mid-duel-gap loses the advance timer: clear the token so
	-- the arenahall lapse path re-offers cleanly instead of hanging.
	if (M:hasStarted(pPlayer, 5, 5) and not M:hasDone(pPlayer, 5, 5) and M:sideOf(pPlayer) == 2) then
		if (dataNum(pPlayer, "act5_duel_pending") == 1 and self:liveCount(pPlayer, "act5_duel") == 0) then
			self:resetDuels(pPlayer, nil)
		end
	end
end

-- ---- small shared helpers ----------------------------------------------------

-- createEvent janitor: tears down a named theater tag (arg = tag).
function JediParkAct5:teardownTag(pPlayer, arg)
	if (pPlayer == nil or arg == nil or arg == "") then
		return
	end

	JtpTheaters:teardown(pPlayer, arg)
end

function JediParkAct5:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct5", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct5:emptyCallback(pPlayer, pSui, eventIndex, args)
end
