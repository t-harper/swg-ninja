-- jtp_act1.lua — Act I: "The Hermit's Path" (shared spine).
-- Quests (bit ledger: started 2^(2n-2) / done 2^(2n-1) in "JediParkAct1"):
--   1 "What the Sand Remembers"  [talk]    — three Anchorhead townsfolk, any order
--   2 "The Boy from Bestine"     [escort]  — walk Tam to the hut approach (ambush en route)
--   3 "A Door Answers"           [visit]   — hut permission granted, door beat
--   4 "The Hermit's Voice"       [talk]    — FLAGSHIP apparition in cell 3565386
--   5 "The Broken Enclave"       [visit]   — Dantooine ruins + reliquary seal (+ Vheress cameo)
--   6 "The Archivist Below"      [talk]    — meet Ondel in the damprock cave
--   7 "First Facets"             [kill]    — crystal hunter cave (act finale)
--   8 "The Graveyard Rumor"      [side]    — krayt graveyard visit + near-miss vignette
--   9 "Letters for the Dead"     [side]    — 3 letters at 3 newly-walked shrines
--
-- Act gate: Act 0 done (JediPark global bit 2) + any TWO of the four padawan
-- branches at _02. Act completion (quests 1-7): JediPark global bit 4.
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C). The
-- hut unlock is ADDITIVE: the stock deny-default lock in
-- screenplays/poi/tatooine_ben_kenobis_house.lua stays byte-untouched; we
-- only add an allow-group on the cell and grant/revoke the group per player.
--
-- Integration points the main loop wires at include time (see file forge
-- notes): JtpShrines calls JediParkAct1:onShrineVisited, the shared login
-- hook calls JediParkAct1:heal.

JtpConfig.act1 = JtpConfig.act1 or {
	xpPerQuest = 5000,           -- jedi_general, per plan §6 (Acts 0-I tier)
	creditsPerQuest = 750,

	-- Q1.1: the three Anchorhead talk-targets (z resolved via getWorldFloor).
	townsfolk = {
		{ name = "Ruwan Tokai, a moisture broker", template = "commoner_tatooine", x = 52, y = -5346, heading = 120 },
		{ name = "Mera Venz, a cantina regular", template = "commoner_old", x = 24, y = -5368, heading = -60 },
		{ name = "Jorba the Salvage-Monger", template = "commoner_tatooine", x = 88, y = -5330, heading = 170 },
	},

	-- Q1.2: the escort.
	tam = { x = 60, z = 52, y = -5330 },        -- Anchorhead northern outskirts
	tamTemplate = "villager_force_sensitive_village",
	ambushArea = { x = -2215, y = -3796, radius = 300 },  -- straight-line midpoint Anchorhead -> hut
	ambushTemplate = "sith_shadow_outlaw",
	ambushCount = 2,
	ambushOffset = 21,                          -- ~30m diagonal from the player
	ambushDespawnMs = 300 * 1000,

	-- Q1.3/Q1.4: Ben's hut (building 3565385, interior cell 3565386).
	hut = { x = -4489, z = 34.7, y = -2262, radius = 40, cellID = 3565386 },
	permGroup = "JtpHut",
	apparition = {
		props = { { -2.5, 0.2, 2.5 }, { 2.5, 0.2, -2.5 } },  -- cell-local x, z, y
		spirit = { x = 0.3, z = 0.2, y = 1.2, heading = 135 },
		despawnMs = 120 * 1000,
		afterTalkMs = 8 * 1000,
	},

	-- Q1.5: Dantooine Jedi Temple Ruins.
	ruins = { x = 4192, y = 5196, radius = 64 },
	sealProp = { x = 4200, y = 5210 },
	vheress = { x = 4224, y = 5228, heading = -120, closeRadius = 15, timeoutMs = 60 * 1000 },

	-- Q1.6: Archivist Ondel, damprock cave (first cell; cave-mouth fallback).
	damprock = { buildingID = 8535537, cell = 1, x = 0, z = 0.2, y = -5, heading = 0,
		mouth = { x = 4198, y = 5116 } },

	-- Q1.7: Force Crystal Hunter Cave (kills counted template-agnostic by
	-- planet + radius + level band, the act0 nyax-filter idiom).
	crystalCave = { planet = "dantooine", x = -6240, y = 7405, radius = 192, minLevel = 90, maxLevel = 130 },
	hunterKillCount = 8,
	facetCount = 3,
	lootPowerCrystal = "power_crystals",
	lootHolocronLight = "holocron_light",
	lootHolocronDark = "holocron_dark",

	-- Q1.S1: Krayt Graveyard named region.
	graveyard = { x = 7451, y = 4510, radius = 500 },

	-- Q1.S2: letters for the dead.
	lettersCount = 3,
}

JediParkAct1 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 1,
}

registerScreenPlay("JediParkAct1", true)

-- Reload guard: survives reloadscreenplays; reset only by a full restart.
JTP_ACT1_SPAWNED = JTP_ACT1_SPAWNED or nil

local act1PadawanBranches = {
	"jedi_padawan_saber_02",
	"jedi_padawan_healing_02",
	"jedi_padawan_force_power_02",
	"jedi_padawan_force_manipulation_02",
}

function JediParkAct1:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT1_SPAWNED ~= nil) then
		print("jtp: act1 already spawned (reload) — skipping spawns")
		print("jtp: act1 'The Hermit's Path' loaded")
		return
	end

	JTP_ACT1_SPAWNED = {}
	local A = JtpConfig.act1

	if (isZoneEnabled("tatooine")) then
		-- Q1.1: the three Anchorhead talk-targets.
		for i = 1, #A.townsfolk, 1 do
			local t = A.townsfolk[i]
			local z = getWorldFloor(t.x, t.y, "tatooine") or 0
			local pNpc = spawnMobile("tatooine", t.template, 0, t.x, z, t.y, t.heading, 0)

			if (pNpc ~= nil) then
				SceneObject(pNpc):setCustomObjectName(t.name)
				SceneObject(pNpc):setObjectMenuComponent("JtpAct1TownsfolkMenuComponent")
				AiAgent(pNpc):addObjectFlag(AI_STATIONARY)
				writeData(SceneObject(pNpc):getObjectID() .. ":jtpTownsfolk", i)
				table.insert(JTP_ACT1_SPAWNED, SceneObject(pNpc):getObjectID())
			else
				print("jtp: WARNING — act1 townsfolk " .. i .. " spawn failed")
			end
		end

		-- Hut approach area (our own; act0's overlapping area stays untouched).
		local h = A.hut
		local pArea = spawnActiveArea("tatooine", "object/active_area.iff", h.x, h.z, h.y, h.radius, 0)

		if (pArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct1", "onEnterHutArea", pArea)
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pArea):getObjectID())
		end

		-- Q1.2: mid-route ambush trigger.
		local am = A.ambushArea
		local pAmbushArea = spawnActiveArea("tatooine", "object/active_area.iff", am.x, getWorldFloor(am.x, am.y, "tatooine") or 0, am.y, am.radius, 0)

		if (pAmbushArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct1", "onEnterAmbushArea", pAmbushArea)
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pAmbushArea):getObjectID())
		end

		-- Q1.S1: krayt graveyard region.
		local g = A.graveyard
		local pGraveArea = spawnActiveArea("tatooine", "object/active_area.iff", g.x, getWorldFloor(g.x, g.y, "tatooine") or 0, g.y, g.radius, 0)

		if (pGraveArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct1", "onEnterGraveyard", pGraveArea)
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pGraveArea):getObjectID())
		end

		-- Q1.3: ADDITIVE allow-group on the hut cell. The stock screenplay's
		-- deny-default WALKIN stays in force for everyone else.
		local pCell = getSceneObject(h.cellID)

		if (pCell ~= nil) then
			SceneObject(pCell):setContainerAllowPermission(A.permGroup, WALKIN)
			print("jtp: hut cell " .. h.cellID .. " accepts group '" .. A.permGroup .. "' (stock lock untouched)")
		else
			print("jtp: WARNING — hut cell " .. h.cellID .. " not found, door beat inert")
		end
	end

	if (isZoneEnabled("dantooine")) then
		-- Q1.6: Archivist Ondel inside the damprock cave's first cell;
		-- exterior cave-mouth fallback if cell placement is unavailable.
		local d = A.damprock
		local pOndel = nil
		local pBuilding = getSceneObject(d.buildingID)

		if (pBuilding ~= nil) then
			local pCaveCell = BuildingObject(pBuilding):getCell(d.cell)

			if (pCaveCell ~= nil) then
				pOndel = spawnMobile("dantooine", "jtp_ondel", 0, d.x, d.z, d.y, d.heading, SceneObject(pCaveCell):getObjectID())
			end
		end

		if (pOndel == nil) then
			local mz = getWorldFloor(d.mouth.x, d.mouth.y, "dantooine") or 0
			pOndel = spawnMobile("dantooine", "jtp_ondel", 0, d.mouth.x, mz, d.mouth.y, 0, 0)
			print("jtp: WARNING — damprock cell unavailable, Ondel posted at the cave mouth")
		end

		if (pOndel ~= nil) then
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pOndel):getObjectID())
			print("jtp: Archivist Ondel posted (damprock cave)")
		else
			print("jtp: WARNING — Ondel spawn failed")
		end

		-- Q1.5: the reliquary-seal rubble prop at the temple ruins.
		local s = A.sealProp
		local sz = getWorldFloor(s.x, s.y, "dantooine") or 0
		local pSeal = spawnSceneObject("dantooine", JtpConfig.items.cacheProp, s.x, sz, s.y, 0, 1, 0, 0, 0)

		if (pSeal ~= nil) then
			SceneObject(pSeal):setObjectMenuComponent("JtpAct1SealMenuComponent")
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pSeal):getObjectID())
			print("jtp: ruins reliquary prop placed")
		else
			print("jtp: WARNING — ruins seal prop spawn failed")
		end

		-- Q1.5: the temple ruins area (vignette + Vheress cameo).
		local r = A.ruins
		local pRuinsArea = spawnActiveArea("dantooine", "object/active_area.iff", r.x, getWorldFloor(r.x, r.y, "dantooine") or 0, r.y, r.radius, 0)

		if (pRuinsArea ~= nil) then
			createObserver(ENTEREDAREA, "JediParkAct1", "onEnterRuins", pRuinsArea)
			table.insert(JTP_ACT1_SPAWNED, SceneObject(pRuinsArea):getObjectID())
		end
	end

	print("jtp: act1 'The Hermit's Path' loaded")
end

-- ---- act gate ---------------------------------------------------------------

function JediParkAct1:countPadawanBranches(pPlayer)
	local n = 0

	for i = 1, #act1PadawanBranches, 1 do
		if (CreatureObject(pPlayer):hasSkill(act1PadawanBranches[i])) then
			n = n + 1
		end
	end

	return n
end

function JediParkAct1:gatePassed(pPlayer)
	return JediParkManager:hasGlobal(pPlayer, 2) and self:countPadawanBranches(pPlayer) >= 2
end

-- ---- Q1.1: the three townsfolk ---------------------------------------------

JtpAct1TownsfolkMenuComponent = {}

function JtpAct1TownsfolkMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	local M = JediParkManager

	if (pPlayer ~= nil and JediParkManager.enabled() and M:hasDone(pPlayer, 1, 1) and not M:hasDone(pPlayer, 1, 2)) then
		menuResponse:addRadialMenuItem(198, 3, "Ask about the boy")
	else
		menuResponse:addRadialMenuItem(198, 3, "Ask about the old hermit")
	end
end

function JtpAct1TownsfolkMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 198) then
		return 0
	end

	JediParkAct1:onTownsfolkTalk(pPlayer, pSceneObject)
	return 0
end

local act1Testimonies = {
	"\"Crazy Ben? Paid for water chits with real credits and never once haggled — strangest man in the Wastes by that alone. I watched him talk a Tusken raiding line into turning around. TALK, mind you. Nobody laughed about him twice.\"",
	"\"After the battle out past Mos Eisley, men came in asking after the old hermit. No uniforms. New boots. Imperial scrip so crisp it could cut you. They never asked where he lived — they asked who he TALKED to, and wrote down every name we were fools enough to give.\"",
	"\"The hut? Save your prybar. Every salvage crew this side of the Dune Sea has had a go at that door, and my best cutter swears the lock isn't metal at all. And mind how loud you ask about the askers — when they ran out of names, they took a boy for questioning. A refugee kid, out of Bestine.\"",
}

function JediParkAct1:onTownsfolkTalk(pPlayer, pNpc)
	if (not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		self:sui(pPlayer, "Anchorhead", "A polite shrug, a squint at the suns, and five unbroken minutes about water futures. Whatever you were hoping this town remembered, it does not remember it for strangers.")
		return
	end

	-- Act entry: the gate is evaluated live on every talk (§7.1).
	if (not M:hasStarted(pPlayer, 1, 1)) then
		if (not M:hasGlobal(pPlayer, 2)) then
			self:sui(pPlayer, "Anchorhead", "\"Hermit stories? Ask the road you came in on.\" (The Hermit's Path opens after Whispers in the Sand — the Wanderer near Aurilia still has words for you.)")
			return
		end

		if (self:countPadawanBranches(pPlayer) < 2) then
			self:sui(pPlayer, "Anchorhead", "\"You've the look of somebody halfway to becoming something.\" The trader turns back to their ledger. (Master any TWO disciplines of the padawan's road to their second rank, and Anchorhead's memories will start adding up.)")
			return
		end

		writeScreenPlayData(pPlayer, "JediPark", "act1_offer_npc", readData(SceneObject(pNpc):getObjectID() .. ":jtpTownsfolk") or 0)
		self:offerAct(pPlayer)
		return
	end

	if (M:hasStarted(pPlayer, 1, 1) and not M:hasDone(pPlayer, 1, 1)) then
		self:recordTownsfolkContact(pPlayer, readData(SceneObject(pNpc):getObjectID() .. ":jtpTownsfolk") or 0)
		return
	end

	if (M:hasDone(pPlayer, 1, 1) and not M:hasStarted(pPlayer, 1, 2)) then
		self:offerEscort(pPlayer)
		return
	end

	if (M:hasStarted(pPlayer, 1, 2) and not M:hasDone(pPlayer, 1, 2)) then
		local tamID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_tam_oid"))

		if (tamID == nil or getSceneObject(tamID) == nil) then
			self:offerEscort(pPlayer)
		else
			self:sui(pPlayer, "Anchorhead", "\"The boy's already walking in your shadow. Long road to the Western Dune Sea — keep him out of everyone's memory but yours.\"")
		end
		return
	end

	self:sui(pPlayer, "Anchorhead", "\"The hut answered for you, did it.\" It is not a question, and the speaker is already finding something else to look at. \"Then Anchorhead heard nothing, saw nothing, and sold you nothing. Safe roads.\"")
end

function JediParkAct1:offerAct(pPlayer)
	local sui = SuiListBox.new("JediParkAct1", "actOfferCallback")
	sui.setTitle("The Hermit's Path")
	sui.setPrompt("Anchorhead remembers the old hermit — 'crazy Ben' — and remembers the men who came asking about him after the battle. The Wanderer's word reached you on the road: ask better questions than they did.\n\n(Begin Act I: speak with three of Anchorhead's townsfolk, in any order.)")
	sui.add("Ask better questions. (Begin: What the Sand Remembers)", "")
	sui.add("Not now.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct1:actOfferCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	if (tonumber(args) ~= 0 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (M:hasStarted(pPlayer, 1, 1) or not M:isJedi(pPlayer) or not self:gatePassed(pPlayer)) then
		return
	end

	M:setStarted(pPlayer, 1, 1)
	writeScreenPlayData(pPlayer, "JediPark", "act1_towntalk", 0)
	CreatureObject(pPlayer):sendSystemMessage("What the Sand Remembers: speak with three of Anchorhead's townsfolk (0 of 3).")

	-- Count the townsperson who took the question first.
	local idx = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_offer_npc")) or 0
	writeScreenPlayData(pPlayer, "JediPark", "act1_offer_npc", "")

	if (idx > 0) then
		self:recordTownsfolkContact(pPlayer, idx)
	end
end

function JediParkAct1:recordTownsfolkContact(pPlayer, idx)
	if (idx == nil or idx < 1 or idx > #act1Testimonies) then
		return
	end

	local M = JediParkManager
	local mask = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_towntalk")) or 0
	local bit = 2 ^ (idx - 1)

	if (math.floor(mask / bit) % 2 == 1) then
		self:sui(pPlayer, "Anchorhead", "\"Told you what I know. Told you TWICE now, which around here counts as a gift.\"")
		return
	end

	mask = mask + bit
	writeScreenPlayData(pPlayer, "JediPark", "act1_towntalk", mask)
	self:sui(pPlayer, "Anchorhead remembers", act1Testimonies[idx])

	local heard = 0
	for i = 1, #act1Testimonies, 1 do
		if (math.floor(mask / (2 ^ (i - 1))) % 2 == 1) then
			heard = heard + 1
		end
	end

	if (heard >= #act1Testimonies) then
		self:completeQuest(pPlayer, 1, nil)
		self:sui(pPlayer, "What the Sand Remembers", "The pieces assemble into something with edges. The askers took a boy — Tam, a Purge-orphan out of Bestine who used to run errands up to the hermit's door — and gave him back three days later, hollowed-out and silent. He sleeps at the northern outskirts now and will not come inside the wire.\n\nThey say he still knows the way to the hut.")
		CreatureObject(pPlayer):sendSystemMessage("What the Sand Remembers: complete. Ask any of the townsfolk about the boy when you are ready to walk him home.")
	else
		CreatureObject(pPlayer):sendSystemMessage("What the Sand Remembers: " .. heard .. " of " .. #act1Testimonies .. " townsfolk heard.")
	end
end

-- ---- Q1.2: the escort -------------------------------------------------------

function JediParkAct1:offerEscort(pPlayer)
	local sui = SuiListBox.new("JediParkAct1", "escortOfferCallback")
	sui.setTitle("The Boy from Bestine")
	sui.setPrompt("The questioners lost interest in the boy once he stopped crying. He knows the way to the hut — walk him there, and let nothing follow.")
	sui.add("Walk the boy home. (Begin: The Boy from Bestine)", "")
	sui.add("Not yet.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct1:escortOfferCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	if (tonumber(args) ~= 0 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasDone(pPlayer, 1, 1) or M:hasDone(pPlayer, 1, 2)) then
		return
	end

	self:startEscort(pPlayer)
end

function JediParkAct1:startEscort(pPlayer)
	local A = JtpConfig.act1

	self:cleanupEscort(pPlayer)

	local t = A.tam
	local z = getWorldFloor(t.x, t.y, "tatooine") or t.z
	local pTam = spawnMobile("tatooine", A.tamTemplate, 0, t.x, z, t.y, -140, 0)

	if (pTam == nil) then
		CreatureObject(pPlayer):sendSystemMessage("The boy is not at the outskirts just now. (Spawn failed — try again in a moment.)")
		return
	end

	SceneObject(pTam):setCustomObjectName("Tam, a Purge orphan")
	SceneObject(pTam):setObjectMenuComponent("JtpAct1TamMenuComponent")
	writeData(SceneObject(pTam):getObjectID() .. ":jtpOwner", SceneObject(pPlayer):getObjectID())

	AiAgent(pTam):removeObjectFlag(AI_STATIONARY)
	AiAgent(pTam):addObjectFlag(AI_NOAIAGGRO)
	AiAgent(pTam):addObjectFlag(AI_ESCORT)
	AiAgent(pTam):addObjectFlag(AI_FOLLOW)
	AiAgent(pTam):setFollowObject(pPlayer)
	AiAgent(pTam):setMovementState(AI_FOLLOWING)
	AiAgent(pTam):setAITemplate()

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 2)) then
		M:setStarted(pPlayer, 1, 2)
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_tam_oid", SceneObject(pTam):getObjectID())
	writeScreenPlayData(pPlayer, "JediPark", "act1_ambush", 0)

	CreatureObject(pPlayer):sendSystemMessage("The Boy from Bestine: Tam falls in behind you without a word. The hut stands above the Western Dune Sea, far to the west (-4489 -2262). Let nothing follow.")
end

function JediParkAct1:cleanupEscort(pPlayer)
	local tamID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_tam_oid"))

	if (tamID ~= nil) then
		local pTam = getSceneObject(tamID)

		if (pTam ~= nil) then
			SceneObject(pTam):destroyObjectFromWorld()
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_tam_oid", "")
	self:despawnAmbush(pPlayer)
end

function JediParkAct1:onEnterAmbushArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 2) or M:hasDone(pPlayer, 1, 2)) then
		return 0
	end

	if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_ambush")) == 1) then
		return 0
	end

	local tamID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_tam_oid"))

	if (tamID == nil or getSceneObject(tamID) == nil) then
		return 0
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_ambush", 1)

	local A = JtpConfig.act1
	local px = SceneObject(pPlayer):getWorldPositionX()
	local py = SceneObject(pPlayer):getWorldPositionY()
	local o = A.ambushOffset
	local spots = { { px + o, py + o }, { px - o, py + o } }
	local oids = {}

	for i = 1, A.ambushCount, 1 do
		local s = spots[((i - 1) % #spots) + 1]
		local z = getTerrainHeight(pPlayer, s[1], s[2])
		local pMob = spawnMobile("tatooine", A.ambushTemplate, 0, s[1], z, s[2], getRandomNumber(360) - 180, 0)

		if (pMob ~= nil) then
			table.insert(oids, SceneObject(pMob):getObjectID())
		end
	end

	if (#oids > 0) then
		writeScreenPlayData(pPlayer, "JediPark", "act1_ambush_oids", table.concat(oids, ","))
		createEvent(A.ambushDespawnMs, "JediParkAct1", "despawnAmbush", pPlayer, "")
		CreatureObject(pPlayer):sendSystemMessage("Shapes detach from the rocks ahead — scavengers in black sailcloth, waiting for somebody. The boy makes a very small sound.")
	end

	return 0
end

function JediParkAct1:despawnAmbush(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act1_ambush_oids")

	if (list == nil or list == "") then
		return
	end

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_ambush_oids", "")
end

JtpAct1TamMenuComponent = {}

function JtpAct1TamMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "Speak softly to Tam")
end

function JtpAct1TamMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or pSceneObject == nil or selectedID ~= 198) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local ownerID = readData(SceneObject(pSceneObject):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		CreatureObject(pPlayer):sendSystemMessage("The boy pulls his hood lower and says nothing. He is walking with somebody, and it is not you.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Tam does not look up. \"I know the way,\" he says, to the sand. \"It's far. Please keep walking.\"")
	end

	return 0
end

-- ---- Q1.3/Q1.4: the hut approach — arrival cascade --------------------------
-- One arrival can legitimately advance three beats: escort complete (Q1.2),
-- the door answering (Q1.3, perm granted + present at the door), and the
-- apparition staging (Q1.4). Each block re-checks its own bits, so partial
-- states resume correctly on any later entry (including apparition re-stage
-- after a missed 120s window).

function JediParkAct1:onEnterHutArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or CreatureObject(pPlayer):isDead()) then
		return 0
	end

	local M = JediParkManager

	-- Q1.2: escort success = the player arrives alive (Tam cannot be harmed).
	if (M:hasStarted(pPlayer, 1, 2) and not M:hasDone(pPlayer, 1, 2)) then
		self:cleanupEscort(pPlayer)
		self:completeQuest(pPlayer, 2, nil)
		self:sui(pPlayer, "The Boy from Bestine", "At the top of the rise the boy stops and looks at the door for a long moment — and, for the first time since Bestine you would swear, almost smiles. Then he is walking away down the slope, hood up, already becoming somebody else's rumor.")

		M:setStarted(pPlayer, 1, 3)
		self:grantHutPermission(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("A Door Answers: somewhere inside the door, something that is not a lock stops holding its breath.")
	end

	-- Q1.3: the door answers to what you are, not what you carry.
	if (M:hasStarted(pPlayer, 1, 3) and not M:hasDone(pPlayer, 1, 3) and M:hasDone(pPlayer, 1, 2) and M:isJedi(pPlayer)) then
		self:grantHutPermission(pPlayer)
		self:completeQuest(pPlayer, 3, nil)
		self:sui(pPlayer, "A Door Answers", "The Wanderer's key is not metal. 'Doors like this one answer to what you are, not what you carry.' No code, no ceremony — just a lock deciding, after all these years, that you are the kind of thing it was waiting for. The hut is open to you.")

		M:setStarted(pPlayer, 1, 4)
	end

	-- Q1.4: stage (or re-stage) the apparition while it remains unclaimed.
	if (M:hasStarted(pPlayer, 1, 4) and not M:hasDone(pPlayer, 1, 4)) then
		if (not self:isSceneLive(pPlayer)) then
			self:stageApparition(pPlayer)
		end
	end

	return 0
end

function JediParkAct1:grantHutPermission(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (not PlayerObject(pGhost):hasPermissionGroup(JtpConfig.act1.permGroup)) then
		PlayerObject(pGhost):addPermissionGroup(JtpConfig.act1.permGroup, true)
	end
end

function JediParkAct1:revokeHutPermission(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	if (PlayerObject(pGhost):hasPermissionGroup(JtpConfig.act1.permGroup)) then
		PlayerObject(pGhost):removePermissionGroup(JtpConfig.act1.permGroup, true)
	end
end

-- ---- Q1.4: the apparition ---------------------------------------------------

function JediParkAct1:isSceneLive(pPlayer)
	local list = readScreenPlayData(pPlayer, "JediPark", "act1_scene_oids")

	if (list == nil or list == "") then
		return false
	end

	for oid in string.gmatch(list, "[^,]+") do
		if (getSceneObject(tonumber(oid)) ~= nil) then
			return true
		end
	end

	-- Stale pointers (restart mid-scene): clear so a fresh stage can run.
	writeScreenPlayData(pPlayer, "JediPark", "act1_scene_oids", "")
	return false
end

function JediParkAct1:stageApparition(pPlayer)
	local A = JtpConfig.act1
	local pCell = getSceneObject(A.hut.cellID)

	if (pCell == nil) then
		return
	end

	self:despawnApparition(pPlayer)

	local oids = {}

	for i = 1, #A.apparition.props, 1 do
		local p = A.apparition.props[i]
		local pProp = spawnSceneObject("tatooine", JtpConfig.items.cacheProp, p[1], p[2], p[3], A.hut.cellID, 1, 0, 0, 0)

		if (pProp ~= nil) then
			table.insert(oids, SceneObject(pProp):getObjectID())
		end
	end

	local s = A.apparition.spirit
	local pSpirit = spawnMobile("tatooine", "jtp_kenobi_spirit", 0, s.x, s.z, s.y, s.heading, A.hut.cellID)

	if (pSpirit ~= nil) then
		writeData(SceneObject(pSpirit):getObjectID() .. ":jtpOwner", SceneObject(pPlayer):getObjectID())
		table.insert(oids, SceneObject(pSpirit):getObjectID())
	end

	if (#oids == 0) then
		return
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_scene_oids", table.concat(oids, ","))
	createEvent(A.apparition.despawnMs, "JediParkAct1", "despawnApparition", pPlayer, "")
	CreatureObject(pPlayer):sendSystemMessage("The Hermit's Voice: light kindles inside the hut — twin motes of pale fire where no lamp should be lit.")
end

function JediParkAct1:despawnApparition(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act1_scene_oids")

	if (list == nil or list == "") then
		return
	end

	for oid in string.gmatch(list, "[^,]+") do
		local pObj = getSceneObject(tonumber(oid))

		if (pObj ~= nil) then
			SceneObject(pObj):destroyObjectFromWorld()
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_scene_oids", "")
end

-- Kenobi conversation: four SUI screens, chained. Era rails: he cannot stay,
-- he CANNOT TRAIN, he names Dantooine's broken enclave, he warns of the
-- follower. No names that postdate the era's secrecy.

function JediParkAct1:onKenobiTalk(pPlayer, pNpc)
	if (not JediParkManager.enabled() or pPlayer == nil or pNpc == nil) then
		return
	end

	local ownerID = readData(SceneObject(pNpc):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		self:sui(pPlayer, "The Hermit's Hut", "The air by the table holds the shape of a man the way heat holds a mirage. Whatever this moment is, it is not yours.")
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 4) or M:hasDone(pPlayer, 1, 4)) then
		self:sui(pPlayer, "The Hermit's Hut", "Only shrine-light, thinning. The hut keeps its last word.")
		return
	end

	local sui = SuiMessageBox.new("JediParkAct1", "kenobiCb2")
	sui.setTitle("The Hermit's Voice (1 of 4)")
	sui.setPrompt("For one breath the hut is not empty.\n\nThe shrine-light bends, and an old man is standing at the table as if he had merely been overlooked — threadbare robe, sand-scoured boots, eyes with far too much patience in them.\n\n\"So the door has learned to make friends again,\" he says. \"Forgive the theatrics. Belief was always half the trick.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct1:kenobiCb2(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 4) or M:hasDone(pPlayer, 1, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct1", "kenobiCb3")
	sui.setTitle("The Hermit's Voice (2 of 4)")
	sui.setPrompt("\"You walked here hoping for a teacher. I am sorry. I cannot stay — and I cannot teach you. That burden has passed to another, and I am only an echo with manners.\"\n\nHe glances at the cold hearth, almost fondly.\n\n\"But an echo remembers the shape of the room it died in. Listen.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct1:kenobiCb3(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 4) or M:hasDone(pPlayer, 1, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct1", "kenobiCb4")
	sui.setTitle("The Hermit's Voice (3 of 4)")
	sui.setPrompt("\"On Dantooine there was an enclave — broken to rubble before the Empire had a name for itself. Rubble keeps secrets badly.\n\n\"What my teachers' teachers buried there is not power. It is a library's worth of stubbornness — and a keeper beneath it who never learned to stop keeping. Start there. Walk the old wells as you go; they remember what the registries burned.\"")
	sui.sendTo(pPlayer)
end

function JediParkAct1:kenobiCb4(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 4) or M:hasDone(pPlayer, 1, 4)) then
		return
	end

	local sui = SuiMessageBox.new("JediParkAct1", "kenobiCbDone")
	sui.setTitle("The Hermit's Voice (4 of 4)")
	sui.setPrompt("\"One thing more. You are followed. A shadow that arrives after you leave and asks your questions in a harder voice. Do not lead it anywhere you love — and do not let being hunted teach you to hunt.\"\n\nThe light is already thinning, and the voice with it.\n\n\"The hut was a fine hiding place. It will make a better beginning.\"\n\nAnd the room is only a room.")
	sui.sendTo(pPlayer)
end

function JediParkAct1:kenobiCbDone(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 4) or M:hasDone(pPlayer, 1, 4)) then
		return
	end

	self:completeQuest(pPlayer, 4, nil)
	M:setStarted(pPlayer, 1, 5)
	CreatureObject(pPlayer):sendSystemMessage("The Broken Enclave: the trail bends to Dantooine — the Jedi Temple Ruins (4192 5196). Rubble keeps secrets badly.")
	createEvent(JtpConfig.act1.apparition.afterTalkMs, "JediParkAct1", "despawnApparition", pPlayer, "")
end

-- ---- Q1.5: the ruins, the seal, and the shadow on the trail ------------------

function JediParkAct1:onEnterRuins(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 5) or M:hasDone(pPlayer, 1, 5)) then
		return 0
	end

	if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_ruins_hint")) ~= 1) then
		writeScreenPlayData(pPlayer, "JediPark", "act1_ruins_hint", 1)
		CreatureObject(pPlayer):sendSystemMessage("The Broken Enclave: pillars older than the Republic's name for itself, filed down by wind into a rumor of architecture. Search the rubble for anything the scavengers' hands refused.")
	end

	if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_vheress_seen")) ~= 1) then
		self:spawnVheress(pPlayer)
	end

	return 0
end

function JediParkAct1:spawnVheress(pPlayer)
	local v = JtpConfig.act1.vheress

	writeScreenPlayData(pPlayer, "JediPark", "act1_vheress_seen", 1)

	local z = getTerrainHeight(pPlayer, v.x, v.y)
	local pMob = spawnMobile("dantooine", "dark_initiate", 0, v.x, z, v.y, v.heading, 0)

	if (pMob == nil) then
		return
	end

	SceneObject(pMob):setCustomObjectName("Adjunct Vheress")
	AiAgent(pMob):addObjectFlag(AI_STATIONARY)
	writeScreenPlayData(pPlayer, "JediPark", "act1_vheress_oid", SceneObject(pMob):getObjectID())

	-- Despawn-on-approach: an inner, owner-guarded circle at her feet.
	local pInner = spawnActiveArea("dantooine", "object/active_area.iff", v.x, z, v.y, v.closeRadius, 0)

	if (pInner ~= nil) then
		writeData(SceneObject(pInner):getObjectID() .. ":jtpOwner", SceneObject(pPlayer):getObjectID())
		createObserver(ENTEREDAREA, "JediParkAct1", "onApproachVheress", pInner)
		writeScreenPlayData(pPlayer, "JediPark", "act1_vheress_area", SceneObject(pInner):getObjectID())
	end

	createEvent(v.timeoutMs, "JediParkAct1", "despawnVheress", pPlayer, "")
	CreatureObject(pPlayer):sendSystemMessage("By the pillar line east of the rubble, a figure in dark travel-cloth stands very still. Watching. You realize it has been watching for some time.")
end

function JediParkAct1:onApproachVheress(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local ownerID = readData(SceneObject(pArea):getObjectID() .. ":jtpOwner")

	if (ownerID ~= SceneObject(pPlayer):getObjectID()) then
		return 0
	end

	self:despawnVheress(pPlayer)
	return 0
end

function JediParkAct1:despawnVheress(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local mobID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_vheress_oid"))
	local sawHer = false

	if (mobID ~= nil) then
		local pMob = getSceneObject(mobID)

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
			sawHer = true
		end
	end

	local areaID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_vheress_area"))

	if (areaID ~= nil) then
		local pInner = getSceneObject(areaID)

		if (pInner ~= nil) then
			SceneObject(pInner):destroyObjectFromWorld()
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_vheress_oid", "")
	writeScreenPlayData(pPlayer, "JediPark", "act1_vheress_area", "")

	if (sawHer) then
		CreatureObject(pPlayer):sendSystemMessage("Between one blink and the next, the pillar line is only pillars. In the dust where the figure stood: bootprints — real, fresh, and already filling with wind.")
	end
end

JtpAct1SealMenuComponent = {}

function JtpAct1SealMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "Search the rubble")
end

function JtpAct1SealMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:isJedi(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("Old stone, old dust. It keeps its own counsel.")
		return 0
	end

	if (M:hasStarted(pPlayer, 1, 5) and not M:hasDone(pPlayer, 1, 5)) then
		local pItem = M:giveNamedItem(pPlayer, JtpConfig.items.ledger, "A Reliquary Seal, Cracked")

		if (pItem == nil) then
			CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and search again.")
			return 0
		end

		writeScreenPlayData(pPlayer, "JediPark", "act1_seal", 1)
		JediParkAct1:completeQuest(pPlayer, 5, nil)
		JediParkAct1:sui(pPlayer, "The Broken Enclave", "Under a fallen lintel, wrapped in wax-cloth gone to crumbs: a disc of fired clay stamped with a sigil nobody has drawn in a very long time. A reliquary seal — cracked, and somehow still holding something shut.")

		M:setStarted(pPlayer, 1, 6)
		CreatureObject(pPlayer):sendSystemMessage("The Archivist Below: a record-keeper haunts the damp caves south of the ruins (4198 5116) — the last librarian of a library that no longer exists.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The rubble has yielded what it means to yield today.")
	end

	return 0
end

-- ---- Q1.6/Q1.7 and the side ledger: Archivist Ondel -------------------------

function JediParkAct1:onOndelTalk(pPlayer)
	if (not JediParkManager.enabled() or pPlayer == nil) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		self:sui(pPlayer, "Archivist Ondel", "A stooped figure among fungus-shelves and crates of salvaged flimsiplast looks up exactly once. \"The reading room is closed. It has been closed for nineteen years, and you are not the sort of weather that reopens it.\"")
		return
	end

	-- Q1.6 turn-in: he takes the seal, and the pilgrimage ledger opens.
	if (M:hasStarted(pPlayer, 1, 6) and not M:hasDone(pPlayer, 1, 6)) then
		if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_seal")) == 1) then
			self:completeQuest(pPlayer, 6, nil)
			self:sui(pPlayer, "The Archivist Below", "He turns the seal over twice, and for a moment the dry voice cracks its spine. \"Sixty years I have catalogued what the rubble lets go of. It has never let go of one of THESE.\" He shelves it with absurd tenderness. \"You walk, then. Good. Books lie less to people who walk. I keep the pilgrim's ledger — the old wells, all of them. Walk them, and I will keep your count true.\"")

			M:setStarted(pPlayer, 1, 7)
			writeScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills", 0)
			writeScreenPlayData(pPlayer, "JediPark", "act1_facets", 0)
			self:attachKillObserver(pPlayer)
			self:sui(pPlayer, "First Facets", "\"Crystals answer the same call you do. The hunters in the northern cave have been beating them out of the rock for off-world buyers — show them what else the rock answers to.\"\n\n(Defeat " .. JtpConfig.act1.hunterKillCount .. " crystal hunters at the cave northwest of the ruins (-6240 7405) and recover " .. JtpConfig.act1.facetCount .. " raw facets.)")
		else
			self:sui(pPlayer, "Archivist Ondel", "\"You smell of the ruins. Come back when the rubble has let something go — it will, for the right kind of patience.\"")
		end
		return
	end

	self:ondelMenu(pPlayer)
end

function JediParkAct1:ondelMenu(pPlayer)
	local M = JediParkManager
	local A = JtpConfig.act1
	local options = {}

	if (M:hasStarted(pPlayer, 1, 7) and not M:hasDone(pPlayer, 1, 7)) then
		local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills")) or 0
		local facets = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_facets")) or 0

		if (kills >= A.hunterKillCount and facets >= A.facetCount) then
			options[#options + 1] = { "q7turnin", "Deliver the cave's answer. (Turn in: First Facets)" }
		else
			options[#options + 1] = { "q7status", "Ask about the crystal hunters (" .. kills .. " of " .. A.hunterKillCount .. " hunters, " .. facets .. " of " .. A.facetCount .. " facets)" }
		end
	end

	options[#options + 1] = { "ledger", "Open the pilgrim's ledger" }

	if (M:hasDone(pPlayer, 1, 4)) then
		options[#options + 1] = { "recap", "Meditate on the memory of the hut" }
	end

	if (M:hasDone(pPlayer, 1, 6)) then
		if (not M:hasStarted(pPlayer, 1, 8)) then
			options[#options + 1] = { "s1", "Ask about the Krayt Graveyard. (Side: The Graveyard Rumor)" }
		elseif (not M:hasDone(pPlayer, 1, 8)) then
			options[#options + 1] = { "s1status", "Ask again about the Graveyard road" }
		end

		if (not M:hasStarted(pPlayer, 1, 9)) then
			options[#options + 1] = { "s2", "Take the letters for the dead. (Side: Letters for the Dead)" }
		elseif (not M:hasDone(pPlayer, 1, 9)) then
			local n = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_letters")) or 0

			if (n >= A.lettersCount) then
				options[#options + 1] = { "s2turnin", "The letters are delivered. (Turn in: Letters for the Dead)" }
			else
				options[#options + 1] = { "s2status", "Ask about the letters (" .. n .. " of " .. A.lettersCount .. " delivered)" }
			end
		end
	end

	if (M:hasGlobal(pPlayer, 4)) then
		options[#options + 1] = { "ahead", "Ask about the road ahead" }
	end

	local keys = {}
	local sui = SuiListBox.new("JediParkAct1", "ondelMenuCallback")
	sui.setTitle("Archivist Ondel")
	sui.setPrompt("A stooped figure among fungus-shelves and crates of salvaged flimsiplast, cataloguing by the light of a lamp older than the cataloguer. \"State your business with the library. Quietly. The dark down here keeps better records than I do.\"")

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_ondel_menu", table.concat(keys, ","))
	sui.sendTo(pPlayer)
end

function JediParkAct1:ondelMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "JediPark", "act1_ondel_menu")
	writeScreenPlayData(pPlayer, "JediPark", "act1_ondel_menu", "")

	if (list == nil or list == "") then
		return
	end

	local keys = {}
	for k in string.gmatch(list, "[^,]+") do
		keys[#keys + 1] = k
	end

	local action = keys[idx + 1]
	local M = JediParkManager
	local A = JtpConfig.act1

	if (action == "q7turnin") then
		self:offerHolocronPick(pPlayer)
	elseif (action == "q7status") then
		local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills")) or 0
		local facets = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_facets")) or 0
		self:sui(pPlayer, "First Facets", "\"The northern cave (-6240 7405). Hunters accounted for: " .. kills .. " of " .. A.hunterKillCount .. ". Facets recovered: " .. facets .. " of " .. A.facetCount .. ". The rock is patient. Be more so.\"")
	elseif (action == "ledger") then
		local n = JtpShrines:countVisited(pPlayer)
		self:sui(pPlayer, "The Pilgrim's Ledger", "Ondel opens a hand-stitched ledger whose first pages are older than the Empire. \"" .. n .. " of " .. JtpConfig.shrineTotal() .. " wells walked. The network only exists while someone walks it — and the ledger only lies when nobody does.\"")
	elseif (action == "recap") then
		self:sui(pPlayer, "The Memory of the Hut", "You sit among the shelves and let the memory surface, whole:\n\nShrine-light bending, and an old man overlooked by time. 'I cannot stay — and I cannot teach you. That burden has passed to another; I am only an echo with manners.' The broken enclave on Dantooine, where rubble keeps secrets badly, and a keeper who never learned to stop keeping. And the warning that walks with you still: you are followed. Do not let being hunted teach you to hunt.")
	elseif (action == "s1") then
		M:setStarted(pPlayer, 1, 8)
		writeScreenPlayData(pPlayer, "JediPark", "act1_krayt_running", "")
		self:sui(pPlayer, "The Graveyard Rumor", "\"Krayt bones the size of sail barges, and pearls the color of a dead man's promise. One day you will need one. Today, just come back alive.\"\n\n(Visit the Krayt Graveyard, far northeast across the Tatooine wastes (7451 4510).)")
	elseif (action == "s1status") then
		self:sui(pPlayer, "The Graveyard Rumor", "\"Northeast, past everything sensible (7451 4510). Walk in, keep your footsteps polite, and come back alive. That is the entire assignment.\"")
	elseif (action == "s2") then
		M:setStarted(pPlayer, 1, 9)
		writeScreenPlayData(pPlayer, "JediPark", "act1_letters", 0)
		M:giveNamedItem(pPlayer, JtpConfig.items.ledger, "Letters for the Dead (three, sealed)")
		self:sui(pPlayer, "Letters for the Dead", "\"I trade in unfinished correspondence — letters to Jedi who will never read them. Deliver them anyway. To the shrines.\"\n\n(Leave a letter at " .. A.lettersCount .. " Force shrines you have NOT yet walked — any planet. The wells will witness the delivery.)")
	elseif (action == "s2status") then
		local n = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_letters")) or 0
		self:sui(pPlayer, "Letters for the Dead", "\"" .. n .. " of " .. A.lettersCount .. " delivered. A letter is delivered when a well you have never walked has witnessed it. The dead are not in a hurry; the network is.\"")
	elseif (action == "s2turnin") then
		if (M:hasStarted(pPlayer, 1, 9) and not M:hasDone(pPlayer, 1, 9)) then
			self:completeQuest(pPlayer, 9, nil)
			M:giveLootGroup(pPlayer, JtpConfig.lootGroups.colorCrystal)
			self:sui(pPlayer, "Letters for the Dead — complete", "\"Delivered,\" Ondel says, as if closing a ledger line forty years overdue. \"They will never read them. That was never the point. The point is that the network remembers how to CARRY.\" He pays the courier's fee in the oldest currency the library has — something sea-glass smooth that hums against your palm.")
		end
	elseif (action == "ahead") then
		self:sui(pPlayer, "Archivist Ondel", "\"The road ahead runs through a temple the Massassi built for masters no history book will name. Two voices are already waiting there to argue about you. Grow past the padawan's road first — the arguing is better when you can follow it.\" (Act II arrives in a later update.)")
	end
end

function JediParkAct1:offerHolocronPick(pPlayer)
	local sui = SuiListBox.new("JediParkAct1", "holocronPickCallback")
	sui.setTitle("First Facets — the library's due")
	sui.setPrompt("Ondel sets a power crystal on the table — your first, still warm from wherever the library keeps such things — and beside it two lacquered cases. \"Teaching-holocrons. One kept by the light, one kept by the dark. The library does not editorialize, and I do not ration inheritance. Choose the voice you can stand to learn from.\"")
	sui.add("Take the light teaching.", "")
	sui.add("Take the dark teaching.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct1:holocronPickCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager
	local A = JtpConfig.act1

	if (not M:hasStarted(pPlayer, 1, 7) or M:hasDone(pPlayer, 1, 7)) then
		return
	end

	local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills")) or 0
	local facets = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_facets")) or 0

	if (kills < A.hunterKillCount or facets < A.facetCount) then
		return
	end

	local group = A.lootHolocronLight

	if (tonumber(args) == 1) then
		group = A.lootHolocronDark
	end

	M:giveLootGroup(pPlayer, A.lootPowerCrystal)
	M:giveLootGroup(pPlayer, group)
	self:completeQuest(pPlayer, 7, nil)
	self:sui(pPlayer, "First Facets — complete", "\"Eight fewer hammers in the dark,\" Ondel says, and enters it in the ledger like a returned book. \"The crystal is yours by the oldest rule the library has: what answers you, follows you.\"")
end

-- ---- Q1.7: crystal-cave kill tracking ---------------------------------------

function JediParkAct1:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct1", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct1", "onKill", pPlayer, 1)
end

function JediParkAct1:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 7) or M:hasDone(pPlayer, 1, 7)) then
		return 0
	end

	local c = JtpConfig.act1.crystalCave

	if (SceneObject(pPlayer):getZoneName() ~= c.planet) then
		return 0
	end

	local lvl = CreatureObject(pVictim):getLevel()

	if (lvl < c.minLevel or lvl > c.maxLevel) then
		return 0
	end

	local dx = SceneObject(pVictim):getWorldPositionX() - c.x
	local dy = SceneObject(pVictim):getWorldPositionY() - c.y

	if ((dx * dx + dy * dy) > (c.radius * c.radius)) then
		return 0
	end

	local A = JtpConfig.act1
	local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills")) or 0
	local facets = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_facets")) or 0

	if (kills < A.hunterKillCount) then
		kills = kills + 1
		writeScreenPlayData(pPlayer, "JediPark", "act1_hunter_kills", kills)
	end

	if (facets < A.facetCount) then
		facets = facets + 1
		writeScreenPlayData(pPlayer, "JediPark", "act1_facets", facets)
		M:giveNamedItem(pPlayer, JtpConfig.items.ledger, "A Raw Crystal Facet")
		CreatureObject(pPlayer):sendSystemMessage("First Facets: a raw facet, prised whole from the hunter's satchel (" .. facets .. " of " .. A.facetCount .. ").")
	end

	if (kills >= A.hunterKillCount and facets >= A.facetCount) then
		CreatureObject(pPlayer):sendSystemMessage("First Facets: the cave's answer is given. Return to Archivist Ondel.")
	else
		CreatureObject(pPlayer):sendSystemMessage("First Facets: " .. kills .. " of " .. A.hunterKillCount .. " hunters.")
	end

	return 0
end

-- ---- Q1.S1: the graveyard near-miss -----------------------------------------

function JediParkAct1:onEnterGraveyard(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 8) or M:hasDone(pPlayer, 1, 8)) then
		return 0
	end

	if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_krayt_running")) == 1) then
		return 0
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_krayt_running", 1)
	CreatureObject(pPlayer):sendSystemMessage("Bone ridges taller than sail barges wall the horizon. The sand between them is very quiet — the kind of quiet that is a held breath.")
	createEvent(6 * 1000, "JediParkAct1", "kraytVignette2", pPlayer, "")

	return 0
end

function JediParkAct1:kraytVignette2(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 8) or M:hasDone(pPlayer, 1, 8)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("The ground shivers. Somewhere beneath the bone-field, something vast turns over without waking. A dune to the north slumps — a ridge of plated spine breaks the sand like a surfacing ship, and is gone.")
	createEvent(8 * 1000, "JediParkAct1", "kraytVignette3", pPlayer, "")
end

function JediParkAct1:kraytVignette3(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 8) or M:hasDone(pPlayer, 1, 8)) then
		return
	end

	writeScreenPlayData(pPlayer, "JediPark", "act1_krayt_running", "")
	self:completeQuest(pPlayer, 8, nil)
	CreatureObject(pPlayer):sendSystemMessage("Stillness returns a centimeter at a time. You were not prey today. You were NOTED. (The Graveyard Rumor: complete — come back alive, as promised.)")
end

-- ---- Q1.S2: letters at the shrines ------------------------------------------
-- Called by JtpShrines:onEnterShrine on every FIRST visit to a shrine (the
-- main loop adds the act1 call beside the act0 one at integration). The
-- shrine's own quiet-step visibility credit (-25) is the delivery's credit.

function JediParkAct1:onShrineVisited(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:hasStarted(pPlayer, 1, 9) or M:hasDone(pPlayer, 1, 9)) then
		return
	end

	local A = JtpConfig.act1
	local n = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_letters")) or 0

	if (n >= A.lettersCount) then
		return
	end

	n = n + 1
	writeScreenPlayData(pPlayer, "JediPark", "act1_letters", n)

	if (n >= A.lettersCount) then
		CreatureObject(pPlayer):sendSystemMessage("Letters for the Dead: the last letter is left beneath the old stones. Return to Archivist Ondel.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Letters for the Dead: you leave a letter where the old stones will keep it (" .. n .. " of " .. A.lettersCount .. "). The quiet of the place follows you out.")
	end
end

-- ---- login self-heal ---------------------------------------------------------
-- The main loop calls this from the shared login hook (jtp_observers) at
-- integration. Grants/revokes the hut group to match live state, re-attaches
-- the kill observer, and sweeps volatile scene state a restart may have
-- orphaned.

function JediParkAct1:heal(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	local M = JediParkManager

	-- Hut permission group: earned by Q1.2 done + being a Jedi; corrected
	-- in both directions.
	if (M:isJedi(pPlayer) and M:hasDone(pPlayer, 1, 2)) then
		self:grantHutPermission(pPlayer)
	else
		self:revokeHutPermission(pPlayer)
	end

	-- Crystal-cave kill observer.
	if (M:hasStarted(pPlayer, 1, 7) and not M:hasDone(pPlayer, 1, 7)) then
		self:attachKillObserver(pPlayer)
	end

	-- Apparition scene: clear stale pointers (isSceneLive does the sweep);
	-- despawn a lingering scene whose dialog was already claimed.
	if (self:isSceneLive(pPlayer) and M:hasDone(pPlayer, 1, 4)) then
		self:despawnApparition(pPlayer)
	end

	-- Vheress cameo never outlives a session.
	self:despawnVheress(pPlayer)

	-- Krayt vignette chain does not survive a restart; unlock the trigger.
	if (not M:hasDone(pPlayer, 1, 8)) then
		writeScreenPlayData(pPlayer, "JediPark", "act1_krayt_running", "")
	end

	-- Escort: resume the walk if Tam survived the player's absence, or clear
	-- the pointer so the townsfolk re-offer cleanly.
	local tamID = tonumber(readScreenPlayData(pPlayer, "JediPark", "act1_tam_oid"))

	if (tamID ~= nil) then
		local pTam = getSceneObject(tamID)

		if (pTam == nil) then
			writeScreenPlayData(pPlayer, "JediPark", "act1_tam_oid", "")
		elseif (M:hasStarted(pPlayer, 1, 2) and not M:hasDone(pPlayer, 1, 2)) then
			AiAgent(pTam):setFollowObject(pPlayer)
			AiAgent(pTam):setMovementState(AI_FOLLOWING)
		else
			SceneObject(pTam):destroyObjectFromWorld()
			writeScreenPlayData(pPlayer, "JediPark", "act1_tam_oid", "")
		end
	end
end

-- ---- shared helpers ----------------------------------------------------------

function JediParkAct1:completeQuest(pPlayer, quest, text)
	JediParkManager:setDone(pPlayer, 1, quest)
	self:reward(pPlayer)

	if (text ~= nil) then
		self:sui(pPlayer, "The Hermit's Path", text)
	end

	self:checkActComplete(pPlayer)
end

function JediParkAct1:checkActComplete(pPlayer)
	local M = JediParkManager

	if (M:hasGlobal(pPlayer, 4)) then
		return
	end

	for q = 1, 7, 1 do
		if (not M:hasDone(pPlayer, 1, q)) then
			return
		end
	end

	M:setGlobal(pPlayer, 4)
	CreatureObject(pPlayer):sendSystemMessage("Act complete: The Hermit's Path. The road now bends toward a temple the Massassi built for masters no history book will name — and the two voices waiting there to argue about you. (Act II arrives in a later update; badges land with the client patch.)")
end

function JediParkAct1:reward(pPlayer)
	JediParkManager:giveCredits(pPlayer, JtpConfig.act1.creditsPerQuest)
	JediParkManager:awardJediXp(pPlayer, JtpConfig.act1.xpPerQuest)
end

function JediParkAct1:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct1", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct1:emptyCallback(pPlayer, pSui, eventIndex, args)
end
