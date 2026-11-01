-- jtp_act0.lua — Act 0: "Whispers in the Sand" (shared spine).
-- Quests (bit ledger: started 2^(2n-2) / done 2^(2n-1) in "JediParkAct0"):
--   1 "The Man Who Wasn't There"  [talk]    — intro, one-shot at accept
--   2 "Ashes in the Record"       [collect] — archivist's cache ledger
--   3 "The First Well"            [visit]   — any force shrine credit
--   4 "Wolves at the Door"        [kill]    — 6 sith shadows at the camp
--   5 "The Locked Door"           [visit]   — Ben's hut approach + turn-in (act finale)
--   6 "Smaller Shadows"           [side]    — 8 Nyax cultists, Corellia
--
-- Phase A: all dialog is SUI placeholder text (STFs land in Phase C).
-- The Q0.1 walk-up encounter is simplified to a login nudge + fixed giver
-- (upgrade to a true Encounter task in Phase B polish).

JediParkAct0 = ScreenPlay:new {
	numberOfActs = 1,
	ACT = 0,
}

registerScreenPlay("JediParkAct0", true)

JTP_ACT0_AREAS = JTP_ACT0_AREAS or nil

function JediParkAct0:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_ACT0_AREAS == nil) then
		JTP_ACT0_AREAS = {}
		local h = JtpConfig.act0.hutArea

		if (isZoneEnabled(h.planet)) then
			local pArea = spawnActiveArea(h.planet, "object/active_area.iff", h.x, h.z, h.y, h.radius, 0)

			if (pArea ~= nil) then
				createObserver(ENTEREDAREA, "JediParkAct0", "onEnterHutArea", pArea)
				table.insert(JTP_ACT0_AREAS, SceneObject(pArea):getObjectID())
			end
		end
	end

	print("jtp: act0 'Whispers in the Sand' loaded")
end

-- ---- The Wanderer's conversation router ------------------------------------
-- Called by the convo handler on every talk. Linear state machine.

function JediParkAct0:onWandererTalk(pPlayer)
	if (not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer)) then
		self:sui(pPlayer, "The Wanderer", "The hood tilts. \"You have the walk of someone looking for a teacher. I only talk to students the Force has already chosen. Come back when it has.\"")
		return
	end

	if (not M:hasStarted(pPlayer, 0, 1)) then
		self:offerIntro(pPlayer)
		return
	end

	if (M:hasStarted(pPlayer, 0, 2) and not M:hasDone(pPlayer, 0, 2)) then
		if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_ledger")) == 1) then
			self:completeQuest(pPlayer, 2, "He reads the burned page twice and folds it away. \"Names. The Empire burns names first, because names are how people find each other. We are going to find each other anyway.\"")
			M:setStarted(pPlayer, 0, 3)
			self:sui(pPlayer, "The First Well", "\"Sit where the old ones sat. There is a shrine east of the witch-roads — dathomir " .. math.floor(JtpConfig.shrines.dathomir[3]) .. " marks it in my ledger, but any of the old wells will do. If it still speaks, you will hear it.\" (Visit any Force shrine.)")
		else
			self:sui(pPlayer, "The Wanderer", "\"The archivist's cache is the green-lit stone by the communal hut. Search it. Bring me what the fire missed.\"")
		end
		return
	end

	if (M:hasStarted(pPlayer, 0, 3) and not M:hasDone(pPlayer, 0, 3)) then
		self:sui(pPlayer, "The Wanderer", "\"The well will know you before I do. Go and be known.\" (Visit any Force shrine.)")
		return
	end

	if (M:hasDone(pPlayer, 0, 3) and not M:hasStarted(pPlayer, 0, 4)) then
		M:setStarted(pPlayer, 0, 4)
		writeScreenPlayData(pPlayer, "JediPark", "act0_wolf_kills", 0)
		self:spawnWolfCamp(pPlayer)
		self:attachKillObserver(pPlayer)
		self:sui(pPlayer, "Wolves at the Door", "\"Sith Shadows — purge-scavengers who sell what they catch — have marked a farmstead family as 'latent.' Their camp squats northwest of the village. I will not reach them in time. You will.\" (Defeat " .. JtpConfig.act0.killCount .. " Sith Shadows at the camp.)")
		return
	end

	if (M:hasStarted(pPlayer, 0, 4) and not M:hasDone(pPlayer, 0, 4)) then
		local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_wolf_kills")) or 0

		if (kills >= JtpConfig.act0.killCount) then
			self:completeQuest(pPlayer, 4, "\"The family will never know your name. That is what doing this correctly feels like. Get used to it.\"")
			self:cleanupWolfCamp(pPlayer)
			M:setStarted(pPlayer, 0, 5)
			self:sui(pPlayer, "The Locked Door", "\"On Tatooine, above the Western Dune Sea, there is a hut no scavenger has managed to open — and believe me, they have managed everything else. Its owner died with a borrowed name. Go and look at the door. I want to know what it does when YOU look.\" (Visit the sealed hut at -4489 -2262, Tatooine.)")
		else
			self:sui(pPlayer, "The Wanderer", "\"The camp still stands. " .. kills .. " of " .. JtpConfig.act0.killCount .. " wolves accounted for.\"")
		end
		return
	end

	if (M:hasStarted(pPlayer, 0, 5) and not M:hasDone(pPlayer, 0, 5)) then
		if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_hut")) == 1) then
			self:completeQuest(pPlayer, 5, "\"A door that answers to nothing you carried. Remember that feeling.\" He is quiet a moment. \"There is a network of us. Old students, old teachers, old debts. We call it the Ember Circle, when we risk calling it anything. You have just walked its first road.\"")
			JediParkManager:setGlobal(pPlayer, 2)
			CreatureObject(pPlayer):sendSystemMessage("Act complete: Whispers in the Sand. (Badge 'Path Begun' arrives with the client update.)")
		else
			self:sui(pPlayer, "The Wanderer", "\"The hut above the Western Dune Sea. Look at the door; let the door look at you.\"")
		end
		return
	end

	-- Idle / post-act menu: side quest + status.
	self:idleMenu(pPlayer)
end

function JediParkAct0:offerIntro(pPlayer)
	local sui = SuiListBox.new("JediParkAct0", "introCallback")
	sui.setTitle("The Wanderer")
	sui.setPrompt("An old man in a road-worn hood. He does not introduce himself. \"You hear it now, don't you. The whisper under everything. The Empire hears it too — that is what the survey teams are for, and the black-sailed scavengers, and the quiet lists of names. There is another way to answer the whisper. Walk a while with me and I will show you where it starts.\"")
	sui.add("\"Who are you?\" (Begin: Whispers in the Sand)", "")
	sui.add("Walk away.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct0:introCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	if (tonumber(args) ~= 0) then
		return
	end

	local M = JediParkManager
	M:setStarted(pPlayer, 0, 1)
	M:setDone(pPlayer, 0, 1)
	M:setGlobal(pPlayer, 1)
	self:reward(pPlayer)
	M:setStarted(pPlayer, 0, 2)
	self:sui(pPlayer, "Ashes in the Record", "\"Nobody. A man who was somebody would already be dead. First errand: the village archivist kept one page out of the fire when the registries burned. Her cache is the green-lit stone by the communal hut. Bring me the page.\"")
end

function JediParkAct0:idleMenu(pPlayer)
	local M = JediParkManager
	local sui = SuiListBox.new("JediParkAct0", "idleCallback")
	sui.setTitle("The Wanderer")
	sui.setPrompt("\"The road goes on. It always goes on.\"")

	if (not M:hasStarted(pPlayer, 0, 6)) then
		sui.add("\"What else can I do?\" (Side: Smaller Shadows)", "")
	elseif (not M:hasDone(pPlayer, 0, 6)) then
		local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_nyax_kills")) or 0
		if (kills >= JtpConfig.act0.nyaxKillCount) then
			sui.add("\"The Nyax cult is thinned.\" (Turn in: Smaller Shadows)", "")
		else
			sui.add("Ask about the Nyax cult (" .. kills .. " of " .. JtpConfig.act0.nyaxKillCount .. ")", "")
		end
	else
		sui.add("Ask about the road ahead.", "")
	end

	sui.add("Ask how many wells you have walked.", "")
	sui.sendTo(pPlayer)
end

function JediParkAct0:idleCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	local idx = tonumber(args)
	local M = JediParkManager

	if (idx == 0) then
		if (not M:hasStarted(pPlayer, 0, 6)) then
			M:setStarted(pPlayer, 0, 6)
			writeScreenPlayData(pPlayer, "JediPark", "act0_nyax_kills", 0)
			self:attachKillObserver(pPlayer)
			self:sui(pPlayer, "Smaller Shadows", "\"Cultists of a thing they call Nyax steal Force-touched children on Corellia — a cave southwest of Coronet. The Circle pays attention to smaller shadows too.\" (Defeat " .. JtpConfig.act0.nyaxKillCount .. " cultists in the cult cave.)")
		elseif (not M:hasDone(pPlayer, 0, 6)) then
			local kills = tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_nyax_kills")) or 0
			if (kills >= JtpConfig.act0.nyaxKillCount) then
				M:setDone(pPlayer, 0, 6)
				self:reward(pPlayer)
				M:giveLootGroup(pPlayer, JtpConfig.lootGroups.colorCrystal)
				self:sui(pPlayer, "Smaller Shadows — complete", "\"Children who will never know they were on a list. Keep collecting those.\" He presses a crystal into your hand — sea-glass smooth, faintly warm.")
			else
				self:sui(pPlayer, "The Wanderer", "\"The cave southwest of Coronet. The little shadows first — the big ones are patient.\"")
			end
		else
			self:sui(pPlayer, "The Wanderer", "\"Grow. Choose branches, not just steps. When you have mastered two disciplines of the padawan's road, the Hermit's Path opens.\" (Act I arrives in the next update.)")
		end
	elseif (idx == 1) then
		local n = JtpShrines:countVisited(pPlayer)
		self:sui(pPlayer, "The Pilgrim's Ledger", "\"" .. n .. " of " .. JtpConfig.shrineTotal() .. " wells. The network only exists while someone walks it.\"")
	end
end

-- ---- Q0.2: the archivist's cache -------------------------------------------

JtpCacheMenuComponent = {}

function JtpCacheMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(198, 3, "@ui_radial:item_use")
end

function JtpCacheMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or selectedID ~= 198) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:isJedi(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The stone is warm, and keeps its own counsel.")
		return 0
	end

	if (M:hasStarted(pPlayer, 0, 2) and not M:hasDone(pPlayer, 0, 2) and tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_ledger")) ~= 1) then
		local pItem = M:giveNamedItem(pPlayer, JtpConfig.items.ledger, "A Burned Registry Page")

		if (pItem ~= nil) then
			writeScreenPlayData(pPlayer, "JediPark", "act0_ledger", 1)
			CreatureObject(pPlayer):sendSystemMessage("Beneath the stone: a single page, charred at three edges. Column after column of names — one column deliberately inked out by hand.")
		else
			CreatureObject(pPlayer):sendSystemMessage("Your inventory is full. Make room and search again.")
		end
	else
		CreatureObject(pPlayer):sendSystemMessage("The cache is empty. The green light holds steady, like held breath.")
	end

	return 0
end

-- ---- Q0.3: shrine hook (called by JtpShrines) -------------------------------

function JediParkAct0:onShrineVisited(pPlayer)
	local M = JediParkManager

	if (M:hasStarted(pPlayer, 0, 3) and not M:hasDone(pPlayer, 0, 3)) then
		self:completeQuest(pPlayer, 3, nil)
		CreatureObject(pPlayer):sendSystemMessage("The First Well: something old turns its attention toward you, the way a door turns on a hinge. Return to the Wanderer.")
	end
end

-- ---- Q0.4 / Q0.6: kill tracking --------------------------------------------

function JediParkAct0:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkAct0", "onKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkAct0", "onKill", pPlayer, 1)
end

function JediParkAct0:spawnWolfCamp(pPlayer)
	local c = JtpConfig.act0.wolfCamp
	local oids = {}
	local layout = {
		{ "sith_shadow_outlaw", -6, 4 }, { "sith_shadow_outlaw", 6, 4 },
		{ "sith_shadow_outlaw", -4, -6 }, { "sith_shadow_outlaw", 4, -6 },
		{ "sith_shadow_pirate", 0, 8 }, { "sith_shadow_pirate", 0, -10 },
	}

	for i = 1, #layout, 1 do
		local m = layout[i]
		local pMob = spawnMobile(c.planet, m[1], 0, c.x + m[2], c.z, c.y + m[3], getRandomNumber(360) - 180, 0)

		if (pMob ~= nil) then
			table.insert(oids, SceneObject(pMob):getObjectID())
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act0_wolf_oids", table.concat(oids, ","))
end

function JediParkAct0:cleanupWolfCamp(pPlayer)
	local list = readScreenPlayData(pPlayer, "JediPark", "act0_wolf_oids")

	if (list == nil or list == "") then
		return
	end

	for oid in string.gmatch(list, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end

	writeScreenPlayData(pPlayer, "JediPark", "act0_wolf_oids", "")
end

function JediParkAct0:onKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	local M = JediParkManager

	-- Q0.4: victims from the player's own camp spawn set.
	if (M:hasStarted(pPlayer, 0, 4) and not M:hasDone(pPlayer, 0, 4)) then
		local victimID = tostring(SceneObject(pVictim):getObjectID())
		local list = readScreenPlayData(pPlayer, "JediPark", "act0_wolf_oids") or ""

		for oid in string.gmatch(list, "[^,]+") do
			if (oid == victimID) then
				local kills = (tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_wolf_kills")) or 0) + 1
				writeScreenPlayData(pPlayer, "JediPark", "act0_wolf_kills", kills)
				M:adjustVisibility(pPlayer, JtpConfig.visibility.loudStep / JtpConfig.act0.killCount)

				if (kills >= JtpConfig.act0.killCount) then
					CreatureObject(pPlayer):sendSystemMessage("Wolves at the Door: the camp is broken. Return to the Wanderer.")
				else
					CreatureObject(pPlayer):sendSystemMessage("Wolves at the Door: " .. kills .. " of " .. JtpConfig.act0.killCount .. ".")
				end
				break
			end
		end
	end

	-- Q0.6: Nyax cultists — corellia, near the cave, low level.
	if (M:hasStarted(pPlayer, 0, 6) and not M:hasDone(pPlayer, 0, 6)) then
		local n = JtpConfig.act0.nyax

		if (SceneObject(pPlayer):getZoneName() == n.planet and CreatureObject(pVictim):getLevel() <= n.maxLevel) then
			local dx = SceneObject(pVictim):getWorldPositionX() - n.x
			local dy = SceneObject(pVictim):getWorldPositionY() - n.y

			if ((dx * dx + dy * dy) <= (n.radius * n.radius)) then
				local kills = (tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_nyax_kills")) or 0) + 1
				writeScreenPlayData(pPlayer, "JediPark", "act0_nyax_kills", kills)

				if (kills >= JtpConfig.act0.nyaxKillCount) then
					CreatureObject(pPlayer):sendSystemMessage("Smaller Shadows: the cult is thinned. The Wanderer will want to hear it.")
				else
					CreatureObject(pPlayer):sendSystemMessage("Smaller Shadows: " .. kills .. " of " .. JtpConfig.act0.nyaxKillCount .. ".")
				end
			end
		end
	end

	return 0
end

-- ---- Q0.5: the hut approach -------------------------------------------------

function JediParkAct0:onEnterHutArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local M = JediParkManager

	if (not JediParkManager.enabled() or not M:hasStarted(pPlayer, 0, 5) or M:hasDone(pPlayer, 0, 5)) then
		return 0
	end

	if (tonumber(readScreenPlayData(pPlayer, "JediPark", "act0_hut")) ~= 1) then
		writeScreenPlayData(pPlayer, "JediPark", "act0_hut", 1)
		CreatureObject(pPlayer):sendSystemMessage("The hut is smaller than the stories. Scavenger pry-marks scar the doorframe — dozens of attempts, none successful. As you watch, the door does nothing at all. And somehow the nothing feels like being read.")
		CreatureObject(pPlayer):sendSystemMessage("The Locked Door: return to the Wanderer.")
	end

	return 0
end

-- ---- shared helpers ---------------------------------------------------------

function JediParkAct0:completeQuest(pPlayer, quest, text)
	JediParkManager:setDone(pPlayer, 0, quest)
	self:reward(pPlayer)

	if (text ~= nil) then
		self:sui(pPlayer, "The Wanderer", text)
	end
end

function JediParkAct0:reward(pPlayer)
	JediParkManager:giveCredits(pPlayer, JtpConfig.act0.creditsPerQuest)
	JediParkManager:awardJediXp(pPlayer, JtpConfig.act0.xpPerQuest)
end

function JediParkAct0:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkAct0", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkAct0:emptyCallback(pPlayer, pSui, eventIndex, args)
end
