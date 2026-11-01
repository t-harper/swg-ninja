-- jtp_act2.lua — Act II: "The Parting of Ways" (shared spine, side-flavored
-- finale). Quests (bit ledger: started 2^(2n-2) / done 2^(2n-1) in state
-- "JediParkAct2"):
--   1  "The Temple That Watches"  [talk]    — meet BOTH emissaries (warroom)
--   2  "Two Futures"              [vision]  — Blueleaf foyer, two staged visions
--   3  "The Hollow Beneath"       [kill/collect] — Woolamander soulroom relic
--   4  "The Pilgrim Road"         [visit]   — 5 lifetime shrines on >=2 planets
--   5  "The Siege of Whispers"    [defend]  — 3 waves at the Aurilia palisade
--   6  "The Question of Teeth"    [kill]    — reliquary gang at the Dantooine ruins
--   7  "The Writ of Ash"          [talk]    — both emissaries read the writ
--   8  "The Parting of Ways"      [choice]  — ceremony hall; intent bit 16 (L) / 32 (D)
--   9  "The Monolith Cipher"      [side]    — 3 marker visits (corellia + yavin4)
--   10 "What the Witches Keep"    [side]    — 2 stronghold-approach cameos (dathomir)
--
-- Act gate: Act I done (JediPark global bit 4) + jedi_padawan_master.
-- Completion: JediPark bit 8 + intent bit 16 OR 32 (never both).
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- ScreenPlayData namespace "JediPark", keys prefixed act2_.

-- ---- tuning (jtp_config owns nothing act2-specific yet; claim the slot) ------

JtpConfig.act2 = JtpConfig.act2 or {
	xpPerQuest = 7500,           -- jedi_general, per plan §6
	creditsPerQuest = 1000,
	visDefense = 75,             -- loud step: Q2.5 completion

	-- Act gate.
	gateSkill = "jedi_padawan_master",
	prevActBit = 4,              -- JediPark global: Act I done

	-- Q2.1/Q2.7/Q2.8 — Great Massassi Temple (yavin4 building at -3038,-2960).
	-- Cell-local spawn coords keyed off the stock warroom mission giver
	-- (gins_darone at -22.0/32.0/58.0 in 3465358) with a >=8m offset.
	massassi = {
		planet = "yavin4",
		warroomCell = 3465358,
		ceremonyCell = 3465362,
		buildingX = -3038, buildingY = -2960,
		ceremonyRadius = 128,    -- 2D world circle; the cellID filter does the real gating
		serenna = { x = -24, z = 32.0, y = 66.5, heading = 90 },
		vheress = { x = -20, z = 32.0, y = 66.5, heading = -90 },
	},

	-- Q2.2 — Blueleaf Temple (yavin4 -830,-2056), vision in foyer1 468318.
	-- Stock foyer spawns sit at z -1.3 around y 32; props flank the aisle.
	blueleaf = {
		planet = "yavin4",
		foyerCell = 468318,
		x = -830, y = -2056, radius = 64,
		propLight = { x = -6, z = -1.3, y = 32 },
		propDark = { x = 6, z = -1.3, y = 32 },
		propLifeMs = 60 * 1000,
	},

	-- Q2.3 — Woolamander Palace (yavin4 549,-622), soulroom 3705355 (floor z=2).
	woolamander = {
		planet = "yavin4",
		x = 549, y = -622, radius = 128,
		maxLevel = 60,           -- gatherer 29 / harvester 38 / harrower 51
		kills = 8,
		soulroomCell = 3705355,
		cache = { x = 0, z = 2, y = -3 },
	},

	-- Q2.4 — pilgrimage I.
	pilgrimage = { count = 5, planets = 2 },

	-- Q2.5 — Aurilia palisade defense (village plateau z 78.5, per act0).
	defense = {
		planet = "dathomir",
		x = 5250, z = 78.5, y = -4100,
		marshalHeading = 170,
		abortMs = 10 * 60 * 1000,
		waves = {
			{ template = "sith_shadow_thug", count = 3 },       -- CL51
			{ template = "sith_shadow_mercenary", count = 4 },  -- CL69
			{ template = "sith_shadow_mercenary", count = 5 },
		},
		-- attack line comes out of the northern treeline
		offsets = { { 0, 18 }, { -8, 15 }, { 8, 15 }, { -14, 10 }, { 14, 10 } },
	},

	-- Q2.6 — reliquary gang at the Dantooine Jedi Temple ruins.
	gang = {
		planet = "dantooine",
		x = 4192, y = 5196, radius = 64,
		cleanupMs = 30 * 60 * 1000,
		leaderTemplate = "force_trained_archaist",              -- CL90
		leaderName = "Reliquarist Veth",
		mobs = {
			{ "dark_side_savage", -8, 6 },   { "dark_side_savage", 8, 6 },
			{ "dark_side_savage", -12, -4 }, { "dark_side_savage", 12, -4 },
			{ "forsaken_force_drifter", -5, 12 }, { "forsaken_force_drifter", 5, 12 },
			{ "forsaken_force_drifter", 0, -10 },
			{ "force_sensitive_renegade", -16, 2 }, { "force_sensitive_renegade", 16, 2 },
			{ "force_sensitive_renegade", 0, 16 },
		},
	},

	-- Q2.S1 — pre-Republic markers.
	monoliths = {
		{ planet = "corellia", x = -1907, y = 3996 },
		{ planet = "yavin4", x = 5045, y = 279 },
		{ planet = "yavin4", x = 5098, y = 317 },
	},
	monolithRadius = 32,

	-- Q2.S2 — stronghold approaches (exterior only; spawn NOTHING there).
	witches = {
		{ planet = "dathomir", x = 164, y = 4489 },    -- Singing Mountain approach
		{ planet = "dathomir", x = -4086, y = -136 },  -- Nightsister approach
	},
	witchRadius = 32,

	-- Q2.8 — the journeyman trainer the ceremony points to.
	vokara = { planet = "tatooine", x = 3508, y = -4806 },

	-- Items. sharred_force_crystal.iff has NO server template (client-only;
	-- the server file registers force_crystal.iff instead, wired to the FS
	-- village menu component) — so ceremony items use the datadisk fallback.
	items = {
		relic = "object/tangible/mission/mission_datadisk.iff",
		relicName = "The Hollow Echo",
		writ = "object/tangible/mission/mission_datadisk.iff",
		writName = "A Sealed Imperial Writ",
		oathstone = "object/tangible/mission/mission_datadisk.iff",
		oathstoneLightName = "Dawn of Dagobah — Oathstone",
		oathstoneDarkName = "Bane's Heart — Oathstone",
		robeLight = "object/tangible/wearables/robe/robe_jedi_light_s01.iff",
		robeDark = "object/tangible/wearables/robe/robe_jedi_dark_s01.iff",
		holocronLight = "object/tangible/jedi/jedi_holocron_light.iff",
		holocronDark = "object/tangible/jedi/jedi_holocron_dark.iff",
		propLight = "object/tangible/jedi/power_shrine.iff",
		propDark = "object/tangible/jedi/power_shrine_red.iff",
		cacheProp = "object/tangible/jedi/power_shrine_red.iff",
	},
	lootGroups = {
		colorCrystal = "color_crystals",
		powerCrystal = "power_crystals",
	},
}

JediParkAct2 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 2,
}

registerScreenPlay("JediParkAct2", true)

JTP_ACT2_SPAWNED = JTP_ACT2_SPAWNED or nil

function JediParkAct2:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT2_SPAWNED ~= nil) then
		print("jtp: act2 already spawned (reload) — skipping spawns")
		print("jtp: act2 'The Parting of Ways' loaded")
		return
	end

	JTP_ACT2_SPAWNED = {}

	local C = JtpConfig.act2

	-- Emissaries + ceremony trigger + soulroom cache + vision trigger (yavin4).
	if (isZoneEnabled(C.massassi.planet)) then
		local m = C.massassi

		local pSerenna = spawnMobile(m.planet, "jtp_serenna", 0, m.serenna.x, m.serenna.z, m.serenna.y, m.serenna.heading, m.warroomCell)

		if (pSerenna ~= nil) then
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pSerenna):getObjectID())
			print("jtp: act2 Serenna Vale posted in the Massassi warroom")
		else
			print("jtp: WARNING — act2 Serenna spawn failed")
		end

		local pVheress = spawnMobile(m.planet, "jtp_vheress_emissary", 0, m.vheress.x, m.vheress.z, m.vheress.y, m.vheress.heading, m.warroomCell)

		if (pVheress ~= nil) then
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pVheress):getObjectID())
			print("jtp: act2 Adjunct Vheress posted in the Massassi warroom")
		else
			print("jtp: WARNING — act2 Vheress spawn failed")
		end

		-- Ceremony hall trigger: world circle on the building + cellID filter.
		local pCeremony = spawnActiveArea(m.planet, "object/active_area.iff", m.buildingX, 0, m.buildingY, m.ceremonyRadius, m.ceremonyCell)

		if (pCeremony ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct2", "onEnterCeremonyHall", pCeremony)
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pCeremony):getObjectID())
		end

		-- Blueleaf vision trigger (foyer1).
		local b = C.blueleaf
		local pVision = spawnActiveArea(b.planet, "object/active_area.iff", b.x, 0, b.y, b.radius, b.foyerCell)

		if (pVision ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct2", "onEnterBlueleaf", pVision)
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pVision):getObjectID())
		end

		-- Woolamander soulroom cache prop.
		local w = C.woolamander
		local pCache = spawnSceneObject(w.planet, C.items.cacheProp, w.cache.x, w.cache.z, w.cache.y, w.soulroomCell, 1, 0, 0, 0)

		if (pCache ~= nil) then
			SceneObject(pCache):setObjectMenuComponent("JtpAct2EchoMenuComponent")
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pCache):getObjectID())
			print("jtp: act2 soulroom cache placed")
		else
			print("jtp: WARNING — act2 soulroom cache spawn failed")
		end
	end

	-- Marshal Kessa at the Aurilia palisade.
	if (isZoneEnabled(C.defense.planet)) then
		local d = C.defense
		local pMarshal = spawnMobile(d.planet, "jtp_marshal", 0, d.x, d.z, d.y, d.marshalHeading, 0)

		if (pMarshal ~= nil) then
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pMarshal):getObjectID())
			print("jtp: act2 Marshal Kessa posted at the Aurilia palisade")
		else
			print("jtp: WARNING — act2 marshal spawn failed")
		end
	end

	-- Reliquary-gang trigger at the Dantooine ruins.
	if (isZoneEnabled(C.gang.planet)) then
		local g = C.gang
		local pRuins = spawnActiveArea(g.planet, "object/active_area.iff", g.x, 0, g.y, g.radius, 0)

		if (pRuins ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct2", "onEnterRuins", pRuins)
			table.insert(JTP_ACT2_SPAWNED, SceneObject(pRuins):getObjectID())
		end
	end

	-- Q2.S1 monolith markers.
	for i = 1, #C.monoliths, 1 do
		local mk = C.monoliths[i]

		if (isZoneEnabled(mk.planet)) then
			local pArea = spawnActiveArea(mk.planet, "object/active_area.iff", mk.x, 0, mk.y, C.monolithRadius, 0)

			if (pArea ~= nil) then
				writeData(SceneObject(pArea):getObjectID() .. ":jtpAct2Mono", i)
				createObserver(ENTEREDAREA, "JediParkAct2", "onEnterMonolith", pArea)
				table.insert(JTP_ACT2_SPAWNED, SceneObject(pArea):getObjectID())
			end
		end
	end

	-- Q2.S2 witch approaches (areas only — the strongholds keep their own parks).
	for i = 1, #C.witches, 1 do
		local wt = C.witches[i]

		if (isZoneEnabled(wt.planet)) then
			local pArea = spawnActiveArea(wt.planet, "object/active_area.iff", wt.x, 0, wt.y, C.witchRadius, 0)

			if (pArea ~= nil) then
				writeData(SceneObject(pArea):getObjectID() .. ":jtpAct2Witch", i)
				createObserver(ENTEREDAREA, "JediParkAct2", "onEnterWitchApproach", pArea)
				table.insert(JTP_ACT2_SPAWNED, SceneObject(pArea):getObjectID())
			end
		end
	end

	print("jtp: act2 'The Parting of Ways' loaded")
end

-- ---- gate --------------------------------------------------------------------

function JediParkAct2:meetsActGate(pPlayer)
	local M = JediParkManager

	return M:isJedi(pPlayer)
		and M:hasGlobal(pPlayer, JtpConfig.act2.prevActBit)
		and CreatureObject(pPlayer):hasSkill(JtpConfig.act2.gateSkill)
end

-- ---- data helpers ------------------------------------------------------------

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

function JediParkAct2:planetsWalked(pPlayer)
	local n = 0

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		if (JtpShrines:countVisitedOnPlanet(pPlayer, JtpConfig.shrinePlanets[p]) > 0) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct2:pilgrimageMet(pPlayer)
	local pg = JtpConfig.act2.pilgrimage

	return JtpShrines:countVisited(pPlayer) >= pg.count and self:planetsWalked(pPlayer) >= pg.planets
end

-- ---- emissary conversation routers ------------------------------------------
-- Called by the convo handlers on every talk; every screen re-evaluates the
-- gate live (global AC 1).

function JediParkAct2:onSerennaTalk(pPlayer)
	self:onEmissaryTalk(pPlayer, "serenna")
end

function JediParkAct2:onVheressTalk(pPlayer)
	self:onEmissaryTalk(pPlayer, "vheress")
end

function JediParkAct2:onEmissaryTalk(pPlayer, who)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		if (who == "serenna") then
			self:sui(pPlayer, "Serenna Vale", "A robed woman studies you without unkindness. \"The temple lets many people walk through it. It only watches a few. Today it is not watching you.\"")
		else
			self:sui(pPlayer, "Adjunct Vheress", "The woman in the feral wrappings does not turn. \"You are furniture. Furniture may leave.\"")
		end
		return
	end

	if (not self:meetsActGate(pPlayer)) then
		if (who == "serenna") then
			self:sui(pPlayer, "Serenna Vale", "\"Not yet. Finish the hermit's road, and master the padawan's discipline entire. When there is something in you worth arguing over, the arguing can begin.\" (Requires: Act I complete, Padawan Master.)")
		else
			self:sui(pPlayer, "Adjunct Vheress", "\"The ledger has a line for you. It is not filled in. Come back when the padawan's course is mastered and the hermit's road walked — the Empire does not bid on unfinished goods.\" (Requires: Act I complete, Padawan Master.)")
		end
		return
	end

	-- Q2.1 — the formal introductions (no menu until both are met).
	if (not M:hasDone(pPlayer, 2, 1)) then
		self:runIntroductions(pPlayer, who)
		return
	end

	self:emissaryMenu(pPlayer, who)
end

-- ---- Q2.1: "The Temple That Watches" ----------------------------------------

function JediParkAct2:runIntroductions(pPlayer, who)
	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 2, 1)) then
		M:setStarted(pPlayer, 2, 1)
		dataSet(pPlayer, "act2_met_s", 0)
		dataSet(pPlayer, "act2_met_v", 0)
	end

	if (who == "serenna" and dataNum(pPlayer, "act2_met_s") ~= 1) then
		dataSet(pPlayer, "act2_met_s", 1)
		self:sui(pPlayer, "The Temple That Watches", "\"Serenna Vale. I speak for the Ember Circle — the survivors' road you have been walking since Aurilia, whether you knew its name or not. The Massassi built this place for masters no history book will name; it seems fitting that what you become gets argued over here.\" Her eyes go to the woman across the warroom. \"The Empire sent its own voice. Hear her too. Choices made deaf are not choices.\"")
	elseif (who == "vheress" and dataNum(pPlayer, "act2_met_v") ~= 1) then
		dataSet(pPlayer, "act2_met_v", 1)

		if (M:hasDone(pPlayer, 1, 5)) then
			self:sui(pPlayer, "The Temple That Watches", "\"Adjunct Vheress.\" She lets the silence sit. \"You stood in the Dantooine rubble once and felt watched. You were. I filed a favorable report — that is the only reason we are speaking instead of something else. I represent the interest the Emperor takes in unclaimed instruments. The Circle will promise you belonging. I promise you terms. Terms are honester.\"")
		else
			self:sui(pPlayer, "The Temple That Watches", "\"Adjunct Vheress. I represent the interest the Emperor takes in unclaimed instruments. The Circle will promise you belonging. I promise you terms. Terms are honester.\"")
		end
	else
		if (who == "serenna") then
			self:sui(pPlayer, "Serenna Vale", "\"You have my name. Take the Adjunct's as well — the temple insists on witnesses.\"")
		else
			self:sui(pPlayer, "Adjunct Vheress", "\"You have my terms. Collect the Circle woman's sentiment too, if you must. Symmetry has its uses.\"")
		end
	end

	if (dataNum(pPlayer, "act2_met_s") == 1 and dataNum(pPlayer, "act2_met_v") == 1 and not JediParkManager:hasDone(pPlayer, 2, 1)) then
		self:completeQuest(pPlayer, 1)
		JediParkManager:setStarted(pPlayer, 2, 2)
		self:sui(pPlayer, "Two Futures", "For one moment the two emissaries speak almost together. \"Blueleaf.\" Serenna: \"South of here the Force runs thin as paper. I call it a window.\" Vheress: \"I call it a mirror.\" Serenna, quietly: \"Sit in the old foyer, and see which one blinks.\" (Travel to the Blueleaf Temple at -830 -2056, Yavin IV, and enter the foyer.)")
	end
end

-- ---- the emissary menu (mando_rank_stone menuKeys pattern) -------------------

function JediParkAct2:emissaryMenu(pPlayer, who)
	local M = JediParkManager
	local options = {}

	-- Spine entry. (Reaching the menu implies Q2.1 is done; the *_start
	-- fallbacks self-heal any missing next-started bit.)
	if (not M:hasStarted(pPlayer, 2, 2)) then
		options[#options + 1] = { "vision_start", "\"Where do I look for these futures?\" (Begin: Two Futures)" }
	elseif (M:hasStarted(pPlayer, 2, 2) and not M:hasDone(pPlayer, 2, 2)) then
		options[#options + 1] = { "vision_hint", "Ask again about Blueleaf (Two Futures)" }
	elseif (M:hasDone(pPlayer, 2, 2) and not M:hasStarted(pPlayer, 2, 3)) then
		options[#options + 1] = { "soulroom_start", "\"What eats the echoes under Woolamander?\" (Begin: The Hollow Beneath)" }
	elseif (M:hasStarted(pPlayer, 2, 3) and not M:hasDone(pPlayer, 2, 3)) then
		options[#options + 1] = { "soulroom_hint", "Ask about the Woolamander soulroom (The Hollow Beneath)" }
	elseif (M:hasDone(pPlayer, 2, 3) and not M:hasStarted(pPlayer, 2, 4)) then
		options[#options + 1] = { "pilgrim_start", "\"Where does the road go next?\" (Begin: The Pilgrim Road)" }
	elseif (M:hasStarted(pPlayer, 2, 4) and not M:hasDone(pPlayer, 2, 4)) then
		if (self:pilgrimageMet(pPlayer)) then
			options[#options + 1] = { "pilgrim_turnin", "\"The five wells are walked.\" (Turn in: The Pilgrim Road)" }
		else
			options[#options + 1] = { "pilgrim_hint", "Ask about the pilgrim road (progress)" }
		end
	elseif (M:hasDone(pPlayer, 2, 4) and not M:hasStarted(pPlayer, 2, 5)) then
		options[#options + 1] = { "defense_start", "\"Where does Aurilia need me?\" (Begin: The Siege of Whispers)" }
	elseif (M:hasStarted(pPlayer, 2, 5) and not M:hasDone(pPlayer, 2, 5)) then
		options[#options + 1] = { "defense_hint", "Ask about the Aurilia palisade (The Siege of Whispers)" }
	elseif (M:hasDone(pPlayer, 2, 5) and not M:hasStarted(pPlayer, 2, 6)) then
		options[#options + 1] = { "gang_start", "\"What of the Dantooine ruins?\" (Begin: The Question of Teeth)" }
	elseif (M:hasStarted(pPlayer, 2, 6) and not M:hasDone(pPlayer, 2, 6)) then
		options[#options + 1] = { "gang_hint", "Ask about the reliquary gang (progress)" }
	elseif (M:hasDone(pPlayer, 2, 6) and not M:hasDone(pPlayer, 2, 7)) then
		if ((who == "serenna" and dataNum(pPlayer, "act2_writ_s") ~= 1) or (who == "vheress" and dataNum(pPlayer, "act2_writ_v") ~= 1)) then
			options[#options + 1] = { "writ_hear", "Present the sealed Imperial writ (The Writ of Ash)" }
		else
			options[#options + 1] = { "writ_other", "Ask about the writ again" }
		end
	elseif (M:hasDone(pPlayer, 2, 7) and not M:hasDone(pPlayer, 2, 8)) then
		options[#options + 1] = { "ceremony", "Declare your path (the ceremony hall stands ready)" }
	elseif (M:hasDone(pPlayer, 2, 8)) then
		options[#options + 1] = { "road_ahead", "Ask about the road ahead" }
	end

	if (dataNum(pPlayer, "act2_holocron_due") == 1) then
		options[#options + 1] = { "holocron_claim", "Receive the pilgrim's holocron" }
	end

	-- Side quests (available once the act is underway).
	if (not M:hasStarted(pPlayer, 2, 9)) then
		options[#options + 1] = { "s1_start", "Ask after the old markers (Side: The Monolith Cipher)" }
	elseif (not M:hasDone(pPlayer, 2, 9)) then
		options[#options + 1] = { "s1_hint", "Ask about the monolith rubbings (progress)" }
	end

	if (not M:hasStarted(pPlayer, 2, 10)) then
		options[#options + 1] = { "s2_start", "Ask about the Dathomir witches (Side: What the Witches Keep)" }
	elseif (not M:hasDone(pPlayer, 2, 10)) then
		options[#options + 1] = { "s2_hint", "Ask about the stronghold porches (progress)" }
	end

	options[#options + 1] = { "wells", "Ask how many wells you have walked." }

	local keys = {}
	local sui = SuiListBox.new("JediParkAct2", "emissaryMenuCallback")

	if (who == "serenna") then
		sui.setTitle("Serenna Vale")
		sui.setPrompt("\"The Circle is listening.\"")
	else
		sui.setTitle("Adjunct Vheress")
		sui.setPrompt("\"State your business. The ledger is patient. I am less so.\"")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "act2_menukeys", table.concat(keys, ","))
	dataSet(pPlayer, "act2_menu_npc", who)
	sui.sendTo(pPlayer)
end

function JediParkAct2:emissaryMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act2_menukeys")
	local who = readScreenPlayData(pPlayer, "JediPark", "act2_menu_npc")
	dataSet(pPlayer, "act2_menukeys", "")

	if (list == nil or list == "" or who == nil or who == "") then
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

	if (action == "vision_start") then
		if (M:hasDone(pPlayer, 2, 1) and not M:hasStarted(pPlayer, 2, 2)) then
			M:setStarted(pPlayer, 2, 2)
			self:sui(pPlayer, "Two Futures", "Serenna: \"Blueleaf, south of here — the Force runs thin as paper there. I call it a window.\" Vheress: \"I call it a mirror.\" Serenna: \"Sit in the old foyer, and see which one blinks.\" (Travel to the Blueleaf Temple at -830 -2056, Yavin IV, and enter the foyer.)")
		end

	elseif (action == "vision_hint") then
		self:sui(pPlayer, "Two Futures", "\"The Blueleaf foyer, south along the river of trees. Both futures will be shown — the window and the mirror. Neither of us gets to edit yours.\" (Enter the Blueleaf Temple foyer at -830 -2056, Yavin IV.)")

	elseif (action == "soulroom_start") then
		if (M:hasDone(pPlayer, 2, 2) and not M:hasStarted(pPlayer, 2, 3)) then
			M:setStarted(pPlayer, 2, 3)
			dataSet(pPlayer, "act2_wool_kills", 0)
			self:attachKillObserver(pPlayer)
			self:sui(pPlayer, "The Hollow Beneath", "Serenna: \"Something in the Woolamander palace eats the echo of every voice that enters.\" Vheress: \"And keeps them. In the soulroom, under everything.\" Serenna: \"Cut your way down and bring back what it keeps.\" (Defeat " .. JtpConfig.act2.woolamander.kills .. " of the palace's creatures at 549 -622, Yavin IV, then search the red-lit stone in the soulroom.)")
		end

	elseif (action == "soulroom_hint") then
		local kills = dataNum(pPlayer, "act2_wool_kills")

		if (kills >= JtpConfig.act2.woolamander.kills) then
			self:sui(pPlayer, "The Hollow Beneath", "\"The palace is thinned. The soulroom is the deep chamber — the stone there glows the wrong color. Search it.\"")
		else
			self:sui(pPlayer, "The Hollow Beneath", "\"The palace at 549 -622. " .. kills .. " of " .. JtpConfig.act2.woolamander.kills .. " of its keepers accounted for. The soulroom will not open its secret to someone the palace can still shout down.\"")
		end

	elseif (action == "pilgrim_start") then
		if (M:hasDone(pPlayer, 2, 3) and not M:hasStarted(pPlayer, 2, 4)) then
			M:setStarted(pPlayer, 2, 4)
			local pg = JtpConfig.act2.pilgrimage
			self:sui(pPlayer, "The Pilgrim Road", "Serenna: \"" .. pg.count .. " wells on " .. pg.planets .. " worlds, at the least. The Circle walks them to remember.\" Vheress: \"The Hand maps them to own. Walk them and decide what you are doing.\" (Visit " .. pg.count .. " Force shrines in your lifetime of walking, across at least " .. pg.planets .. " planets, then return.)")
		end

	elseif (action == "pilgrim_hint") then
		local pg = JtpConfig.act2.pilgrimage
		self:sui(pPlayer, "The Pilgrim Road", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. pg.count .. " wells; " .. self:planetsWalked(pPlayer) .. " of " .. pg.planets .. " worlds. The old stones do not hurry. Neither should you — but do not stop.\"")

	elseif (action == "pilgrim_turnin") then
		if (M:hasStarted(pPlayer, 2, 4) and not M:hasDone(pPlayer, 2, 4) and self:pilgrimageMet(pPlayer)) then
			self:completeQuest(pPlayer, 4)
			M:giveLootGroup(pPlayer, JtpConfig.act2.lootGroups.colorCrystal)
			dataSet(pPlayer, "act2_holocron_due", 1)
			M:setStarted(pPlayer, 2, 5)
			self:offerHolocron(pPlayer)
			self:sui(pPlayer, "The Siege of Whispers", "Vheress, without looking up: \"While you walked, the Shadows learned where the whispers come from.\" Serenna: \"Aurilia. The palisade is wood and hope. Marshal Kessa is standing on it — go stand with her.\" (Find Marshal Kessa at the Aurilia palisade, 5250 -4100, Dathomir.)")
		end

	elseif (action == "defense_start") then
		if (M:hasDone(pPlayer, 2, 4) and not M:hasStarted(pPlayer, 2, 5)) then
			M:setStarted(pPlayer, 2, 5)
			self:sui(pPlayer, "The Siege of Whispers", "Serenna: \"The Shadows have learned where the whispers come from. Aurilia's palisade is wood and hope — stand on it.\" (Find Marshal Kessa at the Aurilia palisade, 5250 -4100, Dathomir.)")
		end

	elseif (action == "defense_hint") then
		self:sui(pPlayer, "The Siege of Whispers", "\"Marshal Kessa holds the palisade north of the village — 5250 -4100. Wood and hope, and now you.\"")

	elseif (action == "gang_start") then
		if (M:hasDone(pPlayer, 2, 5) and not M:hasStarted(pPlayer, 2, 6)) then
			M:setStarted(pPlayer, 2, 6)
			self:attachKillObserver(pPlayer)
			self:sui(pPlayer, "The Question of Teeth", "Serenna: \"A kun-cult reliquary gang is stripping the Dantooine ruins for the Empire's buyers.\" Vheress: \"Freelancers. Unwritted. On this we agree, for once: stop them.\" Serenna, dryly: \"We disagree about how much to enjoy it.\" (Destroy the reliquary gang and its leader at the Jedi Temple ruins, 4192 5196, Dantooine.)")
		end

	elseif (action == "gang_hint") then
		local left = dataNum(pPlayer, "act2_gang_left")

		if (dataNum(pPlayer, "act2_gang_token") ~= 0 and left > 0) then
			self:sui(pPlayer, "The Question of Teeth", "\"" .. left .. " of the gang still standing at the pillar line. Finish it.\"")
		else
			self:sui(pPlayer, "The Question of Teeth", "\"The ruins at 4192 5196, Dantooine. Walk the pillar line; the gang will introduce itself.\"")
		end

	elseif (action == "writ_hear") then
		self:hearWrit(pPlayer, who)

	elseif (action == "writ_other") then
		if (who == "serenna") then
			self:sui(pPlayer, "Serenna Vale", "\"The Adjunct has her own reading of it. Hear it. Then come to the hall above with your eyes open.\"")
		else
			self:sui(pPlayer, "Adjunct Vheress", "\"The Circle woman will dress the same facts in warmer cloth. Collect her version. Symmetry, again.\"")
		end

	elseif (action == "ceremony") then
		if (M:hasDone(pPlayer, 2, 7) and not M:hasStarted(pPlayer, 2, 8)) then
			M:setStarted(pPlayer, 2, 8) -- self-heal a missing started bit
		end
		self:offerCeremony(pPlayer)

	elseif (action == "road_ahead") then
		self:sui(pPlayer, "The Road Ahead", "\"Vokara waits on Tatooine — " .. JtpConfig.act2.vokara.x .. " " .. JtpConfig.act2.vokara.y .. " — to train the journeyman's first discipline. What you declared here was intent. What you train is truth; knighthood opens the enclaves, and Act III with them.\" (Act III arrives in a later update.)")

	elseif (action == "holocron_claim") then
		self:offerHolocron(pPlayer)

	elseif (action == "s1_start") then
		if (not M:hasStarted(pPlayer, 2, 9)) then
			M:setStarted(pPlayer, 2, 9)
			self:sui(pPlayer, "The Monolith Cipher", "Serenna unrolls a ledger sketch in Ondel's crabbed hand: a monolith on Corellia, two obelisks on Yavin, older than both temples. \"Rub-print all three. The archivist believes they are the shrine-network's first alphabet.\" (Visit the Corellian monolith at -1907 3996, and the Yavin obelisks at 5045 279 and 5098 317.)")
		end

	elseif (action == "s1_hint") then
		local n = dataNum(pPlayer, "act2_mono_1") + dataNum(pPlayer, "act2_mono_2") + dataNum(pPlayer, "act2_mono_3")
		self:sui(pPlayer, "The Monolith Cipher", "\"" .. n .. " of 3 markers printed. Corellia -1907 3996; Yavin 5045 279 and 5098 317. Stone before the Republic, and it still says something.\"")

	elseif (action == "s2_start") then
		if (not M:hasStarted(pPlayer, 2, 10)) then
			M:setStarted(pPlayer, 2, 10)
			self:sui(pPlayer, "What the Witches Keep", "Vheress, unexpectedly: \"Two strongholds on Dathomir have watched the shrines longer than the Republic watched anything.\" Serenna: \"Introduce yourself to both porches. Politely. Go no further than the porch — their houses keep their own law.\" (Visit the Singing Mountain approach at 164 4489 and the Nightsister approach at -4086 -136, Dathomir.)")
		end

	elseif (action == "s2_hint") then
		local n = dataNum(pPlayer, "act2_witch_1") + dataNum(pPlayer, "act2_witch_2")
		self:sui(pPlayer, "What the Witches Keep", "\"" .. n .. " of 2 porches greeted. The Mountain at 164 4489; the Nightsisters at -4086 -136. Politely, remember.\"")

	elseif (action == "wells") then
		self:sui(pPlayer, "The Pilgrim's Ledger", "\"" .. JtpShrines:countVisited(pPlayer) .. " of " .. JtpConfig.shrineTotal() .. " wells, across " .. self:planetsWalked(pPlayer) .. " worlds. The network only exists while someone walks it.\"")
	end
end

-- ---- Q2.2: the Blueleaf visions ----------------------------------------------

function JediParkAct2:onEnterBlueleaf(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not self:meetsActGate(pPlayer)) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 2, 2) or M:hasDone(pPlayer, 2, 2)) then
		return 0
	end

	local b = JtpConfig.act2.blueleaf
	local pProp = spawnSceneObject(b.planet, JtpConfig.act2.items.propLight, b.propLight.x, b.propLight.z, b.propLight.y, b.foyerCell, 1, 0, 0, 0)

	if (pProp ~= nil) then
		createEvent(b.propLifeMs, "JediParkAct2", "despawnProp", pProp, "")
	end

	local sui = SuiMessageBox.new("JediParkAct2", "visionTwoCallback")
	sui.setTitle("Two Futures — the Window")
	sui.setPrompt("The air in the foyer goes thin as paper, and green light climbs a stone that was dark a breath ago. You see: a convoy of ragged speeders under a storm, and a single hooded figure walking the line of them with one hand raised — and the storm bending, mile after mile, around people who will never know why they lived. No banners. No names. Serenna's voice, from nowhere: \"A window. This is what the Circle is for.\"")
	sui.sendTo(pPlayer)

	return 0
end

function JediParkAct2:visionTwoCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 2, 2) or M:hasDone(pPlayer, 2, 2)) then
		return
	end

	local b = JtpConfig.act2.blueleaf
	local pProp = spawnSceneObject(b.planet, JtpConfig.act2.items.propDark, b.propDark.x, b.propDark.z, b.propDark.y, b.foyerCell, 1, 0, 0, 0)

	if (pProp ~= nil) then
		createEvent(b.propLifeMs, "JediParkAct2", "despawnProp", pProp, "")
	end

	local sui = SuiMessageBox.new("JediParkAct2", "visionDoneCallback")
	sui.setTitle("Two Futures — the Mirror")
	sui.setPrompt("The green light gutters. A second stone answers in red. You see: a hall with no windows, and a figure kneeling on polished black, head bowed, while a voice from a throne you cannot see — will not see, the vision itself refuses — speaks one approving word too quiet to hear. The kneeling figure is stronger than everyone who ever hurt them. The kneeling figure is you, if you want. Vheress's voice, from nowhere: \"A mirror. Clarity. Nothing in it is a lie.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct2:visionDoneCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 2, 2) or M:hasDone(pPlayer, 2, 2)) then
		return
	end

	self:completeQuest(pPlayer, 2)
	CreatureObject(pPlayer):sendSystemMessage("Two Futures: both stones go dark. Neither blinked first. Return to the emissaries in the Massassi warroom.")
end

function JediParkAct2:despawnProp(pProp)
	if (pProp ~= nil) then
		SceneObject(pProp):destroyObjectFromWorld()
	end
end

-- ---- Q2.3: the soulroom cache (radial menu component) ------------------------

JtpAct2EchoMenuComponent = {}

function JtpAct2EchoMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpAct2EchoMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:isJedi(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The stone is warm, and red, and keeps its own counsel.")
		return 0
	end

	if (not M:hasStarted(pPlayer, 2, 3) or M:hasDone(pPlayer, 2, 3)) then
		CreatureObject(pPlayer):sendSystemMessage("The stone holds its silence. Whatever it kept for you, it has already given — or is not yet owed.")
		return 0
	end

	if (dataNum(pPlayer, "act2_wool_kills") < JtpConfig.act2.woolamander.kills) then
		CreatureObject(pPlayer):sendSystemMessage("The palace is still shouting — too many of its keepers stand. The stone will not speak over them. (" .. dataNum(pPlayer, "act2_wool_kills") .. " of " .. JtpConfig.act2.woolamander.kills .. ")")
		return 0
	end

	if (dataNum(pPlayer, "act2_soulroom_relic") ~= 1) then
		local pItem = M:giveNamedItem(pPlayer, JtpConfig.act2.items.relic, JtpConfig.act2.items.relicName)

		if (pItem == nil) then
			CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and search the stone again.")
			return 0
		end

		dataSet(pPlayer, "act2_soulroom_relic", 1)
		CreatureObject(pPlayer):sendSystemMessage("From a seam in the stone you draw something small and cold that is not quite an object: the hollow echo. It is very quiet. It is quiet AT you.")
	end

	JediParkAct2:offerEchoChoice(pPlayer)

	return 0
end

function JediParkAct2:offerEchoChoice(pPlayer)
	local sui = SuiListBox.new("JediParkAct2", "echoChoiceCallback")
	sui.setTitle("The Hollow Beneath")
	sui.setPrompt("The echo waits in your hand. If you let it, it will speak — every voice the palace ever ate, and under them all one voice that knows your name and likes it. Or you can seal it now, unheard, and carry it out as nothing but evidence. It costs nothing either way. That is what it wants you to think, and it happens to be true.")
	sui.add("Listen to the echo.", "")
	sui.add("Seal it unheard.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct2:echoChoiceCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)
	local M = JediParkManager

	if (idx == nil or idx < 0 or not M:hasStarted(pPlayer, 2, 3) or M:hasDone(pPlayer, 2, 3)) then
		return
	end

	if (idx == 0) then
		dataSet(pPlayer, "act2_soulroom_listened", 1)
		self:sui(pPlayer, "The Hollow Beneath", "You listen. The eaten voices pour through you — grief, mostly, and under the grief the one voice, patient as sediment: \"You could hold all of this and spill none.\" Then it is done, and the echo is only cold again. You are not sure the last voice was talking about the grief.")
	else
		dataSet(pPlayer, "act2_soulroom_listened", 0)
		self:sui(pPlayer, "The Hollow Beneath", "You seal it. The echo presses once against the seam — one long, tired push, like a door tried in the night — and goes still. Some things are evidence, not conversation.")
	end

	self:completeQuest(pPlayer, 3)
	CreatureObject(pPlayer):sendSystemMessage("The Hollow Beneath: the soulroom's keeping is yours. Return to the emissaries in the Massassi warroom.")
end

-- ---- Q2.4: pilgrimage hook (wired into jtp_shrines at integration) -----------

function JediParkAct2:onShrineVisited(pPlayer)
	if (not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 2, 4) or M:hasDone(pPlayer, 2, 4)) then
		return
	end

	local pg = JtpConfig.act2.pilgrimage

	if (self:pilgrimageMet(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The Pilgrim Road: the fifth well acknowledges you. Return to the Massassi warroom.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The Pilgrim Road: " .. math.min(pg.count, JtpShrines:countVisited(pPlayer)) .. " of " .. pg.count .. " wells; " .. math.min(pg.planets, self:planetsWalked(pPlayer)) .. " of " .. pg.planets .. " worlds.")
	end
end

function JediParkAct2:offerHolocron(pPlayer)
	if (dataNum(pPlayer, "act2_holocron_due") ~= 1) then
		return
	end

	local sui = SuiListBox.new("JediParkAct2", "holocronCallback")
	sui.setTitle("The Pilgrim Road — the Archivist's Due")
	sui.setPrompt("A courier-sealed case from Archivist Ondel, forwarded to the warroom: a holocron for the road walked. His note reads only: \"Both churches came from the same walking. Pick the voice you can stand to learn from.\"")
	sui.add("Take the light-aspect holocron.", "")
	sui.add("Take the dark-aspect holocron.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct2:holocronCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0 or dataNum(pPlayer, "act2_holocron_due") ~= 1) then
		return
	end

	local template = JtpConfig.act2.items.holocronLight

	if (idx == 1) then
		template = JtpConfig.act2.items.holocronDark
	end

	local pItem = JediParkManager:giveNamedItem(pPlayer, template, nil)

	if (pItem == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. The emissaries will hold the holocron — ask for it again.")
		return
	end

	dataSet(pPlayer, "act2_holocron_due", 0)
	CreatureObject(pPlayer):sendSystemMessage("The holocron settles into your pack with the particular weight of somebody else's homework.")
end

-- ---- Q2.5: the Aurilia palisade defense --------------------------------------

function JediParkAct2:onMarshalTalk(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer) or not self:meetsActGate(pPlayer)) then
		self:sui(pPlayer, "Marshal Kessa", "A broad woman with a village captain's bearing and a treeline squint. \"Palisade's closed to sightseers. If the whispers ever start meaning you, come back.\"")
		return
	end

	if (not M:hasStarted(pPlayer, 2, 5)) then
		self:sui(pPlayer, "Marshal Kessa", "\"I know who sends people like you. Temple's still arguing over your soul, is it? Come back when the arguing gets to the part where Aurilia needs you.\"")
		return
	end

	if (M:hasDone(pPlayer, 2, 5)) then
		self:sui(pPlayer, "Marshal Kessa", "\"Palisade's still standing. So are you. In my trade that's the whole of a good week.\"")
		return
	end

	if (dataNum(pPlayer, "act2_def_state") == 2) then
		-- Waves cleared — turn in.
		dataSet(pPlayer, "act2_def_state", 0)
		dataSet(pPlayer, "act2_def_token", 0)
		self:completeQuest(pPlayer, 5)
		M:adjustVisibility(pPlayer, JtpConfig.act2.visDefense)
		self:sui(pPlayer, "The Siege of Whispers — complete", "Kessa counts the treeline twice before she lowers the macrobinoculars. \"Three waves and the wood still stands. The village will never thank you properly — half of them slept through it, which was the point.\" She spits. \"You fought loud, though. Loud gets remembered by the wrong ledgers. Go tell the temple the whispers keep their address.\" (Return to the Massassi warroom. Visibility increased.)")
		return
	end

	if (dataNum(pPlayer, "act2_def_state") == 1) then
		-- Attempt in flight — self-heal if the wave set evaporated (restart).
		if (self:countLiveOids(readScreenPlayData(pPlayer, "JediPark", "act2_def_oids")) == 0) then
			dataSet(pPlayer, "act2_def_state", 0)
			dataSet(pPlayer, "act2_def_token", 0)
			dataSet(pPlayer, "act2_def_oids", "")
			self:sui(pPlayer, "Marshal Kessa", "\"Lost the thread of that last attack — treeline's gone quiet wrong. They'll come again the moment you're ready. Say the word.\"")
		else
			self:sui(pPlayer, "Marshal Kessa", "\"Wave " .. dataNum(pPlayer, "act2_def_wave") .. " is still in the wire! Hold the palisade!\"")
		end
		return
	end

	-- Offer to start (or restart) the defense.
	local sui = SuiListBox.new("JediParkAct2", "defenseStartCallback")
	sui.setTitle("Marshal Kessa")
	sui.setPrompt("\"Shadows in the treeline since dawn — purge-scavengers with a grudge and a buyer. Three pushes, I'd guess, each uglier than the last. The palisade is wood and hope, stranger. Stand on it with me and it's wood, hope, and you.\" (Begin the defense: 3 waves. Leaving the fight for ten minutes forfeits the attempt.)")
	sui.add("\"I'll stand.\" (Begin the defense)", "")
	sui.add("\"Not yet.\"", "")
	sui.sendTo(pPlayer)
end

function JediParkAct2:defenseStartCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 2, 5) or M:hasDone(pPlayer, 2, 5) or dataNum(pPlayer, "act2_def_state") ~= 0) then
		return
	end

	local token = getTimestamp()
	dataSet(pPlayer, "act2_def_token", token)
	dataSet(pPlayer, "act2_def_state", 1)
	self:attachKillObserver(pPlayer)
	self:spawnDefenseWave(pPlayer, 1)
	createEvent(JtpConfig.act2.defense.abortMs, "JediParkAct2", "abortDefense", pPlayer, tostring(token))
	CreatureObject(pPlayer):sendSystemMessage("The Siege of Whispers: the first wave breaks from the treeline!")
end

function JediParkAct2:spawnDefenseWave(pPlayer, waveNum)
	local d = JtpConfig.act2.defense
	local wave = d.waves[waveNum]

	if (wave == nil) then
		return
	end

	local oids = {}

	for i = 1, wave.count, 1 do
		local off = d.offsets[i] or { 0, 12 }
		local x = d.x + off[1]
		local y = d.y + off[2]
		local z = getTerrainHeight(pPlayer, x, y)
		local pMob = spawnMobile(d.planet, wave.template, 0, x, z, y, getRandomNumber(360) - 180, 0)

		if (pMob ~= nil) then
			table.insert(oids, SceneObject(pMob):getObjectID())
		end
	end

	dataSet(pPlayer, "act2_def_wave", waveNum)
	dataSet(pPlayer, "act2_def_oids", table.concat(oids, ","))
	dataSet(pPlayer, "act2_def_left", #oids)
end

function JediParkAct2:abortDefense(pPlayer, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (tostring(dataNum(pPlayer, "act2_def_token")) ~= tostring(args)) then
		return -- stale timer from an earlier attempt
	end

	if (dataNum(pPlayer, "act2_def_state") ~= 1) then
		return
	end

	self:despawnOids(readScreenPlayData(pPlayer, "JediPark", "act2_def_oids"))
	dataSet(pPlayer, "act2_def_oids", "")
	dataSet(pPlayer, "act2_def_state", 0)
	dataSet(pPlayer, "act2_def_token", 0)
	CreatureObject(pPlayer):sendSystemMessage("The Siege of Whispers: the attack ebbs back into the treeline. The attempt is forfeit — speak to Marshal Kessa to stand the watch again.")
end

-- ---- Q2.6: the reliquary gang ------------------------------------------------

function JediParkAct2:onEnterRuins(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not self:meetsActGate(pPlayer)) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 2, 6) or M:hasDone(pPlayer, 2, 6)) then
		return 0
	end

	-- A live set already out for this player?
	local oids = readScreenPlayData(pPlayer, "JediPark", "act2_gang_oids")

	if (oids ~= nil and oids ~= "" and self:countLiveOids(oids) > 0) then
		return 0
	end

	self:spawnGang(pPlayer)

	return 0
end

function JediParkAct2:spawnGang(pPlayer)
	local g = JtpConfig.act2.gang
	local oids = {}

	for i = 1, #g.mobs, 1 do
		local m = g.mobs[i]
		local x = g.x + m[2]
		local y = g.y + m[3]
		local z = getTerrainHeight(pPlayer, x, y)
		local pMob = spawnMobile(g.planet, m[1], 0, x, z, y, getRandomNumber(360) - 180, 0)

		if (pMob ~= nil) then
			table.insert(oids, SceneObject(pMob):getObjectID())
		end
	end

	local z = getTerrainHeight(pPlayer, g.x, g.y)
	local pLeader = spawnMobile(g.planet, g.leaderTemplate, 0, g.x, z, g.y, getRandomNumber(360) - 180, 0)

	if (pLeader ~= nil) then
		CreatureObject(pLeader):setCustomObjectName(g.leaderName)
		table.insert(oids, SceneObject(pLeader):getObjectID())
	end

	local token = getTimestamp()
	dataSet(pPlayer, "act2_gang_token", token)
	dataSet(pPlayer, "act2_gang_oids", table.concat(oids, ","))
	dataSet(pPlayer, "act2_gang_left", #oids)
	self:attachKillObserver(pPlayer)
	createEvent(g.cleanupMs, "JediParkAct2", "cleanupGang", pPlayer, tostring(token))
	CreatureObject(pPlayer):sendSystemMessage("The Question of Teeth: the reliquary gang rises from the dig-pits along the pillar line — " .. #oids .. " of them, and the one called Veth.")
end

function JediParkAct2:cleanupGang(pPlayer, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (tostring(dataNum(pPlayer, "act2_gang_token")) ~= tostring(args)) then
		return
	end

	if (JediParkManager:hasDone(pPlayer, 2, 6)) then
		return
	end

	self:despawnOids(readScreenPlayData(pPlayer, "JediPark", "act2_gang_oids"))
	dataSet(pPlayer, "act2_gang_oids", "")
	dataSet(pPlayer, "act2_gang_left", 0)
	dataSet(pPlayer, "act2_gang_token", 0)
end

-- ---- Q2.7: the writ debrief --------------------------------------------------

function JediParkAct2:hearWrit(pPlayer, who)
	local M = JediParkManager

	if (not M:hasDone(pPlayer, 2, 6) or M:hasDone(pPlayer, 2, 7)) then
		return
	end

	if (not M:hasStarted(pPlayer, 2, 7)) then
		M:setStarted(pPlayer, 2, 7)
	end

	-- Re-grant the writ prop if the field grant failed (death-strip safe).
	if (dataNum(pPlayer, "act2_writ_item") ~= 1) then
		local pItem = M:giveNamedItem(pPlayer, JtpConfig.act2.items.writ, JtpConfig.act2.items.writName)

		if (pItem ~= nil) then
			dataSet(pPlayer, "act2_writ_item", 1)
		end
	end

	if (who == "serenna") then
		dataSet(pPlayer, "act2_writ_s", 1)
		self:sui(pPlayer, "The Writ of Ash", "Serenna breaks the seal like someone defusing it. \"A purchase order. Relics by the crate — and an appendix.\" She turns the flimsi so you can see the column of shrine names. Beside four of them, a stranger's initials. Yours. \"The Empire has been grading your walking. The Circle carries names OUT of ledgers; that is the whole of what we are. Let me carry yours.\" Her closing argument is that she hands the writ back instead of keeping it.")
	else
		dataSet(pPlayer, "act2_writ_v", 1)
		self:sui(pPlayer, "The Writ of Ash", "Vheress reads it once, at speed. \"Freelance relic-buyers with a stolen distribution list. Embarrassing.\" A pause. \"You noticed the appendix. Good. You are IN the ledger, permanently — no ceremony in this temple will un-write that. The only safe place in a ledger is the hand that writes it.\" She lets that finish. \"The Emperor rewards clarity. That is my closing argument, and unlike hers, it comes with terms in writing.\"")
	end

	if (dataNum(pPlayer, "act2_writ_s") == 1 and dataNum(pPlayer, "act2_writ_v") == 1) then
		self:completeQuest(pPlayer, 7)
		M:setStarted(pPlayer, 2, 8)
		self:sui(pPlayer, "The Parting of Ways", "The arguing is over; neither voice won, which was never the point. Serenna: \"The hall of ceremony stands above the temple. We will follow, in our own ways.\" Vheress: \"Declare yourself where the Massassi declared. It is the one thing this place is still for.\" (Ascend to the great temple's ceremony hall and declare your path.)")
	end
end

-- ---- Q2.8: the Choice --------------------------------------------------------

function JediParkAct2:onEnterCeremonyHall(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	if (not self:meetsActGate(pPlayer) or not M:hasStarted(pPlayer, 2, 8) or M:hasDone(pPlayer, 2, 8)) then
		return 0
	end

	self:offerCeremony(pPlayer)

	return 0
end

function JediParkAct2:offerCeremony(pPlayer)
	local M = JediParkManager

	if (not JediParkManager.enabled() or not self:meetsActGate(pPlayer)) then
		return
	end

	if (not M:hasStarted(pPlayer, 2, 8) or M:hasDone(pPlayer, 2, 8)) then
		return
	end

	local echoLine = ""

	if (dataNum(pPlayer, "act2_soulroom_listened") == 1) then
		echoLine = " Vheress adds, for you alone: \"You listened, under Woolamander. I heard it in you when you came back up. Remember that the mirror never lied.\""
	else
		echoLine = " Serenna adds, for you alone: \"You sealed the hollow rather than drink it. The Circle noticed. Remember that the window never needed you to.\""
	end

	local sui = SuiListBox.new("JediParkAct2", "ceremonyCallback")
	sui.setTitle("The Parting of Ways")
	sui.setPrompt("The ceremony hall holds its breath. Serenna lights a single lamp: \"The Circle does not promise you power. It promises you people worth protecting.\" Vheress does not light hers: \"The dark is not cruelty. It is clarity. The Emperor rewards clarity.\"" .. echoLine .. " What you declare tonight is intent, not destiny — the training will tell the truth of you later. Declare.")
	sui.add("Light the second lamp. (Declare LIGHT intent — the Ember Circle)", "")
	sui.add("Leave the lamps dark. (Declare DARK intent — the Unseen Hand)", "")
	sui.add("Step back. (Decide later)", "")
	sui.sendTo(pPlayer)
end

function JediParkAct2:ceremonyCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)
	local M = JediParkManager

	if (idx == nil or idx < 0 or idx > 1) then
		if (idx == 2) then
			CreatureObject(pPlayer):sendSystemMessage("The hall keeps your silence. Return when you are ready to declare.")
		end
		return
	end

	if (not M:hasStarted(pPlayer, 2, 8) or M:hasDone(pPlayer, 2, 8)) then
		return
	end

	if (idx == 0) then
		-- Light intent.
		if (M:hasGlobal(pPlayer, 32)) then
			self:sui(pPlayer, "The Parting of Ways", "The lamp gutters before your hand reaches it. Vheress, quietly, without triumph: \"No. You already gave the dark your word in this hall. Ceremony is not a coin to be flipped until it lands prettily.\"")
			return
		end

		M:setGlobal(pPlayer, 16)
		self:finishCeremony(pPlayer, 1)
	else
		-- Dark intent.
		if (M:hasGlobal(pPlayer, 16)) then
			self:sui(pPlayer, "The Parting of Ways", "The lamps stay lit no matter how long you look at them. Serenna, gently: \"You lit the second lamp in this hall. The Circle does not hold you prisoner — but the hall will not un-see it. Walk the road you declared, or walk it badly; both are still yours.\"")
			return
		end

		M:setGlobal(pPlayer, 32)
		self:finishCeremony(pPlayer, 2)
	end
end

function JediParkAct2:finishCeremony(pPlayer, side)
	local M = JediParkManager
	local items = JtpConfig.act2.items

	-- Ceremony crystal: a color crystal from the ceremonial pool, plus the
	-- named Oathstone keepsake (datadisk fallback — see items comment).
	M:giveLootGroup(pPlayer, JtpConfig.act2.lootGroups.colorCrystal)

	if (side == 1) then
		M:giveNamedItem(pPlayer, items.oathstone, items.oathstoneLightName)
		M:giveNamedItem(pPlayer, items.robeLight, nil)
	else
		M:giveNamedItem(pPlayer, items.oathstone, items.oathstoneDarkName)
		M:giveNamedItem(pPlayer, items.robeDark, nil)
	end

	self:completeQuest(pPlayer, 8)
	M:setGlobal(pPlayer, 8)
	CreatureObject(pPlayer):sendSystemMessage("Act complete: The Parting of Ways. (Badge 'The Crossroads' arrives with the client update.)")

	local v = JtpConfig.act2.vokara

	if (side == 1) then
		self:sui(pPlayer, "The Parting of Ways — Light", "Two lamps burn. Serenna does not smile; the Circle buries too many people for smiling. \"Dawn of Dagobah — carry the stone, and the promise with it.\" She folds a traveling robe into your arms like it is somebody's memory. \"Intent is declared. Now make it true: Vokara keeps a quiet room on Tatooine, " .. v.x .. " " .. v.y .. ". Train the journeyman's first discipline of the light. The enclaves open to knights — and the war, quietly, to you.\"")
	else
		self:sui(pPlayer, "The Parting of Ways — Dark", "No lamps burn, and the hall is somehow easier to see. Vheress inclines her head one degree — from her, a coronation. \"Bane's Heart — carry the stone, and the terms with it.\" The robe she offers is dark, well-made, and unsigned. \"Intent is on record. Now make it useful: Vokara keeps a quiet room on Tatooine, " .. v.x .. " " .. v.y .. ". Train the journeyman's first discipline of the dark. The Emperor's ledger prefers verbs to vows.\"")
	end
end

-- ---- Q2.S1: the monolith cipher ----------------------------------------------

function JediParkAct2:onEnterMonolith(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:isJedi(pPlayer)) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 2, 9) or M:hasDone(pPlayer, 2, 9)) then
		return 0
	end

	local index = readData(SceneObject(pArea):getObjectID() .. ":jtpAct2Mono")

	if (index == nil or index == 0) then
		return 0
	end

	if (dataNum(pPlayer, "act2_mono_" .. index) == 1) then
		return 0
	end

	dataSet(pPlayer, "act2_mono_" .. index, 1)

	local n = dataNum(pPlayer, "act2_mono_1") + dataNum(pPlayer, "act2_mono_2") + dataNum(pPlayer, "act2_mono_3")

	if (n >= 3) then
		self:completeQuest(pPlayer, 9)
		JediParkManager:giveLootGroup(pPlayer, JtpConfig.act2.lootGroups.powerCrystal)
		self:sui(pPlayer, "The Monolith Cipher", "The third rubbing settles it: the same glyph-row on all three stones, cut by hands dead before the Republic named itself — a walking-mark, repeated, like a trail blazed for someone the carvers would never meet. Ondel's marginal note, when you sketch it later, will read: \"The 46 wells are not sites. They are SENTENCES. Someone wrote the pilgrimage before anyone walked it.\" A power crystal, courier-sealed, arrives with his thanks.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The Monolith Cipher: the old stone takes your rubbing. (" .. n .. " of 3 markers)")
	end

	return 0
end

-- ---- Q2.S2: the witch approaches ---------------------------------------------

function JediParkAct2:onEnterWitchApproach(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:isJedi(pPlayer)) then
		return 0
	end

	if (not M:hasStarted(pPlayer, 2, 10) or M:hasDone(pPlayer, 2, 10)) then
		return 0
	end

	local index = readData(SceneObject(pArea):getObjectID() .. ":jtpAct2Witch")

	if (index == nil or index == 0) then
		return 0
	end

	if (dataNum(pPlayer, "act2_witch_" .. index) == 1) then
		return 0
	end

	dataSet(pPlayer, "act2_witch_" .. index, 1)

	if (index == 1) then
		self:sui(pPlayer, "What the Witches Keep — the Mountain", "You stop at the porch-line, politely, and the Mountain notices politeness. A sister in trail-leathers appears where no one was standing — Veshaan, by the way the others angle toward her. \"An off-worlder who KNOCKS.\" She looks you over the way weather looks over a roof. \"The clans watched the old wells before your Republic watched anything, and we lost daughters to the same fire that is hunting you. Walk your parting of ways, little ember. If the road brings you back a knight, the Mountain may have opinions worth your hearing.\" She is gone before the wind finishes.")
	else
		self:sui(pPlayer, "What the Witches Keep — the Nightsisters", "You keep to the approach, and it is still nearly too far. A voice arrives without a speaker — Sereth, envoy of the stronghold, somewhere among the stones. \"Courtesy, from a shrine-walker. How novel.\" A dry sound that might be laughter. \"The sisters keep the count of the old places, and the count says the Empire is mapping what it cannot read. Amusing. Go and choose your church, walker. If you choose the honest one — the dark one — the stronghold's silence can be bought. Not its friendship. Silence is worth more.\"")
	end

	if (dataNum(pPlayer, "act2_witch_1") == 1 and dataNum(pPlayer, "act2_witch_2") == 1) then
		dataSet(pPlayer, "act2_witches", 1)
		self:completeQuest(pPlayer, 10)
		CreatureObject(pPlayer):sendSystemMessage("What the Witches Keep: both porches greeted, both doors left unopened. Somewhere, two very old ledgers add your name — in pencil.")
	end

	return 0
end

-- ---- shared kill observer (Q2.3 / Q2.5 / Q2.6) -------------------------------

function JediParkAct2:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct2", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct2", "onKill", pPlayer, 1)
end

function JediParkAct2:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	-- Q2.3: stock Woolamander palace mobs — planet + radius + level filter.
	if (M:hasStarted(pPlayer, 2, 3) and not M:hasDone(pPlayer, 2, 3)) then
		local w = JtpConfig.act2.woolamander

		if (SceneObject(pPlayer):getZoneName() == w.planet and CreatureObject(pVictim):getLevel() <= w.maxLevel) then
			local dx = SceneObject(pVictim):getWorldPositionX() - w.x
			local dy = SceneObject(pVictim):getWorldPositionY() - w.y

			if ((dx * dx + dy * dy) <= (w.radius * w.radius)) then
				local kills = dataNum(pPlayer, "act2_wool_kills") + 1

				if (kills <= w.kills) then
					dataSet(pPlayer, "act2_wool_kills", kills)

					if (kills >= w.kills) then
						CreatureObject(pPlayer):sendSystemMessage("The Hollow Beneath: the palace quiets. Find the red-lit stone in the soulroom.")
					else
						CreatureObject(pPlayer):sendSystemMessage("The Hollow Beneath: " .. kills .. " of " .. w.kills .. ".")
					end
				end
			end
		end
	end

	local victimID = tostring(SceneObject(pVictim):getObjectID())

	-- Q2.5: current defense wave.
	if (M:hasStarted(pPlayer, 2, 5) and not M:hasDone(pPlayer, 2, 5) and dataNum(pPlayer, "act2_def_state") == 1) then
		if (self:oidInList(victimID, readScreenPlayData(pPlayer, "JediPark", "act2_def_oids"))) then
			local left = dataNum(pPlayer, "act2_def_left") - 1
			dataSet(pPlayer, "act2_def_left", left)

			if (left <= 0) then
				local nextWave = dataNum(pPlayer, "act2_def_wave") + 1

				if (nextWave > #JtpConfig.act2.defense.waves) then
					dataSet(pPlayer, "act2_def_state", 2)
					dataSet(pPlayer, "act2_def_oids", "")
					CreatureObject(pPlayer):sendSystemMessage("The Siege of Whispers: the treeline empties. The palisade holds — report to Marshal Kessa.")
				else
					self:spawnDefenseWave(pPlayer, nextWave)
					CreatureObject(pPlayer):sendSystemMessage("The Siege of Whispers: wave " .. nextWave .. " breaks from the treeline!")
				end
			else
				CreatureObject(pPlayer):sendSystemMessage("The Siege of Whispers: " .. left .. " attackers left in wave " .. dataNum(pPlayer, "act2_def_wave") .. ".")
			end
		end
	end

	-- Q2.6: the reliquary gang set.
	if (M:hasStarted(pPlayer, 2, 6) and not M:hasDone(pPlayer, 2, 6)) then
		if (self:oidInList(victimID, readScreenPlayData(pPlayer, "JediPark", "act2_gang_oids"))) then
			local left = dataNum(pPlayer, "act2_gang_left") - 1
			dataSet(pPlayer, "act2_gang_left", left)

			if (left <= 0) then
				dataSet(pPlayer, "act2_gang_oids", "")
				dataSet(pPlayer, "act2_gang_token", 0)

				local pItem = M:giveNamedItem(pPlayer, JtpConfig.act2.items.writ, JtpConfig.act2.items.writName)

				if (pItem ~= nil) then
					dataSet(pPlayer, "act2_writ_item", 1)
					CreatureObject(pPlayer):sendSystemMessage("From Veth's dig-satchel: a courier flimsi under an unbroken Imperial seal.")
				else
					CreatureObject(pPlayer):sendSystemMessage("Veth carried a sealed Imperial writ, but your inventory is full — the emissaries will draw a copy.")
				end

				self:completeQuest(pPlayer, 6)
				CreatureObject(pPlayer):sendSystemMessage("The Question of Teeth: the reliquary gang is broken. Return to the Massassi warroom.")
			else
				CreatureObject(pPlayer):sendSystemMessage("The Question of Teeth: " .. left .. " of the gang remain.")
			end
		end
	end

	return 0
end

-- ---- shared helpers ----------------------------------------------------------

function JediParkAct2:oidInList(oidString, list)
	if (list == nil or list == "") then
		return false
	end

	for oid in string.gmatch(list, "[^,]+") do
		if (oid == oidString) then
			return true
		end
	end

	return false
end

function JediParkAct2:countLiveOids(list)
	if (list == nil or list == "") then
		return 0
	end

	local n = 0

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil and not CreatureObject(pMob):isDead()) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct2:despawnOids(list)
	if (list == nil or list == "") then
		return
	end

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end
end

function JediParkAct2:completeQuest(pPlayer, quest)
	JediParkManager:setDone(pPlayer, 2, quest)
	self:reward(pPlayer)
end

function JediParkAct2:reward(pPlayer)
	JediParkManager:giveCredits(pPlayer, JtpConfig.act2.creditsPerQuest)
	JediParkManager:awardJediXp(pPlayer, JtpConfig.act2.xpPerQuest)
end

function JediParkAct2:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct2", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct2:emptyCallback(pPlayer, pSui, eventIndex, args)
end

-- ---- Marshal Kessa convo handler (mobile registers boot-only template) -------
-- The marshal's convo TEMPLATE lives in custom_scripts/mobile/jtp_marshal.lua
-- (boot-only include); this handler class hot-reloads with the screenplays.

jtpMarshalConvoHandler = conv_handler:new {}

function jtpMarshalConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct2 ~= nil) then
			JediParkAct2:onMarshalTalk(pPlayer)
		end
	end

	return pConvScreen
end
