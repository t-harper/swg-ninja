-- mando_rank_stone.lua — the Oyu'baat stone UI: radial menu component +
-- SUI menus for every clan-rank interaction, plus the staff submenu.
-- The object template (custom_scripts/object/pre9_mando_stone.lua)
-- references MandoStoneMenuComponent by name; this class lives in the
-- screenplays tree so the whole UI is hot-reloadable.

MandoStoneMenuComponent = {}

function MandoStoneMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(120, 3, "Consult the Stone")
end

function MandoStoneMenuComponent:handleObjectMenuSelect(pObject, pPlayer, selectedID)
	if (pPlayer == nil or pObject == nil) then
		return 0
	end

	if (selectedID == 120) then
		MandoRankStone:mainMenu(pPlayer)
	end

	return 0
end

MandoRankStone = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("MandoRankStone", true)

function MandoRankStone:start()
end

local function isStaff(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	return pGhost ~= nil and PlayerObject(pGhost):isPrivileged()
end

-- --- main menu ------------------------------------------------------------------

function MandoRankStone:mainMenu(pPlayer)
	local options = { { "status", "Status" } }

	if (CreatureObject(pPlayer):hasSkill("mandalorian_foundling_novice") and not MandoRankManager:isPledged(pPlayer)) then
		options[#options + 1] = { "pledge", "Pledge to the Creed (enable Mandalorian XP from kills)" }
	end

	if (CreatureObject(pPlayer):hasSkill("mandalorian_warrior_master") and not MandoRankManager:isEnrolled(pPlayer)) then
		options[#options + 1] = { "swear", "Swear to the Clans (join the rank hierarchy)" }
	end

	if (MandoRankManager:isEnrolled(pPlayer)) then
		options[#options + 1] = { "claim", "Claim Next Rank" }
		options[#options + 1] = { "challenge", "Challenge for Rank (full ranks only)" }
		options[#options + 1] = { "accept", "Accept Incoming Challenge" }
	end

	options[#options + 1] = { "heal", "Renew my oaths (re-attach observers)" }

	if (isStaff(pPlayer)) then
		options[#options + 1] = { "admin", "[Staff] Administration" }
	end

	local keys = {}
	local sui = SuiListBox.new("MandoRankStone", "mainMenuCallback")
	sui.setTitle("Oyu'baat Stone")
	sui.setPrompt("The clans remember. Creed, clan, hunt and forge — state your business.")

	for i = 1, #options do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	writeScreenPlayData(pPlayer, "MandoRankStone", "menuKeys", table.concat(keys, ","))
	sui.sendTo(pPlayer)
end

function MandoRankStone:mainMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = readScreenPlayData(pPlayer, "MandoRankStone", "menuKeys")
	writeScreenPlayData(pPlayer, "MandoRankStone", "menuKeys", "")

	if (list == nil or list == "") then
		return
	end

	local keys = {}
	for k in string.gmatch(list, "[^,]+") do
		keys[#keys + 1] = k
	end

	local action = keys[idx + 1]

	if (action == "status") then
		self:showStatus(pPlayer)
	elseif (action == "pledge") then
		MandoRankManager:pledge(pPlayer)
	elseif (action == "swear") then
		MandoRankManager:enroll(pPlayer)
	elseif (action == "claim") then
		MandoRankManager:claim(pPlayer)
	elseif (action == "challenge") then
		MandoRankDuel:beginChallenge(pPlayer)
	elseif (action == "accept") then
		MandoRankDuel:acceptIncoming(pPlayer)
	elseif (action == "heal") then
		MandoRankObservers:heal(pPlayer)
		CreatureObject(pPlayer):sendSystemMessage("Your oaths are renewed. (Observers re-attached.)")
	elseif (action == "admin" and isStaff(pPlayer)) then
		self:adminMenu(pPlayer)
	end
end

-- --- status ---------------------------------------------------------------------

function MandoRankStone:showStatus(pPlayer)
	local buf = ""

	if (MandoRankManager:isPledged(pPlayer)) then
		buf = buf .. "Pledged to the Creed: yes (Mandalorian XP from kills).\n"
	else
		buf = buf .. "Pledged to the Creed: no.\n"
	end

	if (MandoRankManager:isEnrolled(pPlayer)) then
		MandoRankManager:settle(pPlayer)
		local rank = MandoRankManager:getRank(pPlayer)
		local info = MandoRankManager:rankInfo(rank)
		local xp = MandoRankManager:getXp(pPlayer)
		buf = buf .. "\nClan rank: " .. rank .. " — " .. info.title .. "\n"
		buf = buf .. "Clan Rank XP: " .. xp .. "\n"

		if (rank < 11) then
			local nxt = MandoRankManager:rankInfo(rank + 1)
			local held = MandoRankManager:countAtRank(rank + 1)
			local capTxt = nxt.playerCap < 0 and "no cap" or (held .. "/" .. nxt.playerCap .. " held")
			buf = buf .. "Next: " .. nxt.title .. " at " .. nxt.xpRequired .. " XP (" .. capTxt .. ")\n"
		else
			buf = buf .. "You are Mand'alor. The clans answer to you.\n"
		end

		buf = buf .. "Upkeep: " .. (MandoRankConfig.baseMaintCost * rank) .. " XP per day at your rank.\n"

		local duel = MandoRankDuel:statusLine(pPlayer)

		if (duel ~= nil) then
			buf = buf .. "\n" .. duel .. "\n"
		end
	else
		buf = buf .. "\nYou have not sworn to the clans. (Master Warrior — Verd — required.)\n"
	end

	local sui = SuiMessageBox.new("MandoRankStone", "noopCallback")
	sui.setTitle("Oyu'baat Stone — Status")
	sui.setPrompt(buf)
	sui.sendTo(pPlayer)
end

function MandoRankStone:noopCallback(pPlayer, pSui, eventIndex, args)
end

-- --- staff submenu ---------------------------------------------------------------

local ADMIN_ACTIONS = {
	{ "promote", "Promote target one rank (by first name, online)" },
	{ "demote", "Force-demote target one rank (by first name, online)" },
	{ "cleardebt", "Clear target's upkeep debt + challenge cooldown" },
	{ "watchjedi", "Watch Jedi: attach FRS kill-credit observer (by first name)" },
	{ "roster", "Roster dump (chat + console log)" },
}

function MandoRankStone:adminMenu(pPlayer)
	if (not isStaff(pPlayer)) then
		return
	end

	local sui = SuiListBox.new("MandoRankStone", "adminMenuCallback")
	sui.setTitle("Oyu'baat Stone — Staff")
	sui.setPrompt("Rank moves are STEPWISE (one rank per use) so a grant can never cascade. All actions are audit-logged.")

	for i = 1, #ADMIN_ACTIONS do
		sui.add(ADMIN_ACTIONS[i][2], "")
	end

	sui.sendTo(pPlayer)
end

function MandoRankStone:adminMenuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not isStaff(pPlayer)) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0 or ADMIN_ACTIONS[idx + 1] == nil) then
		return
	end

	local action = ADMIN_ACTIONS[idx + 1][1]

	if (action == "roster") then
		local lines = MandoRankManager:rosterSummary()
		for i = 1, #lines do
			CreatureObject(pPlayer):sendSystemMessage(lines[i])
			print("mando_rank: ROSTER " .. lines[i])
		end
		return
	end

	writeScreenPlayData(pPlayer, "MandoRankStone", "adminAction", action)

	local sui = SuiInputBox.new("MandoRankStone", "adminNameCallback")
	sui.setTitle("Oyu'baat Stone — Staff")
	sui.setPrompt("Target player's FIRST NAME (must be online):")
	sui.sendTo(pPlayer)
end

function MandoRankStone:adminNameCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not isStaff(pPlayer)) then
		return
	end

	local action = readScreenPlayData(pPlayer, "MandoRankStone", "adminAction")
	writeScreenPlayData(pPlayer, "MandoRankStone", "adminAction", "")

	if (action == nil or action == "" or args == nil or args == "") then
		return
	end

	local pTarget = getPlayerByName(tostring(args))

	if (pTarget == nil) then
		CreatureObject(pPlayer):sendSystemMessage("No online player named '" .. tostring(args) .. "'.")
		return
	end

	if (action == "promote") then
		MandoRankManager:adminPromote(pPlayer, pTarget)
	elseif (action == "demote") then
		MandoRankManager:adminForceDemote(pPlayer, pTarget)
	elseif (action == "cleardebt") then
		MandoRankManager:adminClearDebt(pPlayer, pTarget)
	elseif (action == "watchjedi") then
		local pGhost = CreatureObject(pTarget):getPlayerObject()

		if (pGhost == nil or PlayerObject(pGhost):getFrsCouncil() <= 0) then
			CreatureObject(pPlayer):sendSystemMessage("Target is not an FRS jedi.")
			return
		end

		MandoRankObservers:attachJediWatch(pTarget)
		CreatureObject(pPlayer):sendSystemMessage("Watching " .. CreatureObject(pTarget):getFirstName() .. " — mando kill credit enabled.")
	end
end
