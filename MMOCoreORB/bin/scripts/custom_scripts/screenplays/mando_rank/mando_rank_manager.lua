-- mando_rank_manager.lua — roster + rank lifecycle for the Mandalorian
-- clan hierarchy (lua FRS-analogue).
--
-- State:
--   * roster: QuestVectorMap "MandoRankRoster" (persistent, galaxy-wide);
--     key = playerID string, value = "rank:lastMaintEpoch:firstName".
--   * pledge flag: writeScreenPlayData(player, "MandoRank", "pledged").
--   * XP pool: the real experience type mandalorian_rank_xp (caps ride
--     the hidden rank boxes: novice 15k ... master 625k, exactly the
--     force_rank ladder), so it shows in the client XP window.
--
-- Grant discipline: the lua awardSkill binding hardcodes
-- awardRequiredSkills=true, so awarding a box whose prerequisites are
-- missing would silently grant WHOLE TIERS. Every award here therefore
-- pre-checks hasSkill(previous box) and only ever awards a box whose
-- requirements are already present.

MandoRankManager = ScreenPlay:new {
	numberOfActs = 1,
	rosterMapName = "MandoRankRoster",
}

registerScreenPlay("MandoRankManager", true)

function MandoRankManager:start()
	if (not MandoRankConfig.enabled) then
		return
	end

	-- self-rescheduling online-settle tick (persistent server event)
	if (not hasServerEvent(MandoRankConfig.maintEventName)) then
		createServerEvent(MandoRankConfig.maintTickMs, "MandoRankManager", "maintenanceTick", MandoRankConfig.maintEventName)
	end
end

-- --- roster primitives -------------------------------------------------------

function MandoRankManager:getRosterMap()
	local pMap = getQuestVectorMap(self.rosterMapName)

	if (pMap == nil) then
		pMap = createQuestVectorMap(self.rosterMapName)
	end

	return pMap
end

function MandoRankManager:rosterGet(playerID)
	local pMap = self:getRosterMap()

	if (pMap == nil) then
		return nil
	end

	local map = LuaQuestVectorMap(pMap)

	if (not map:hasMapRow(playerID)) then
		return nil
	end

	local rank, last, name = string.match(map:getMapRow(playerID), "^(%-?%d+):(%d+):(.*)$")

	if (rank == nil) then
		return nil
	end

	return { rank = tonumber(rank), lastMaint = tonumber(last), name = name }
end

function MandoRankManager:rosterSet(playerID, rank, lastMaint, name)
	local pMap = self:getRosterMap()

	if (pMap == nil) then
		return
	end

	LuaQuestVectorMap(pMap):addMapRow(playerID, string.format("%d:%d:%s", rank, lastMaint, name))
end

function MandoRankManager:rosterDelete(playerID)
	local pMap = self:getRosterMap()

	if (pMap ~= nil and LuaQuestVectorMap(pMap):hasMapRow(playerID)) then
		LuaQuestVectorMap(pMap):deleteMapRow(playerID)
	end
end

function MandoRankManager:rosterEach(fn)
	local pMap = self:getRosterMap()

	if (pMap == nil) then
		return
	end

	local map = LuaQuestVectorMap(pMap)
	local size = map:getMapSize()

	-- snapshot keys first: fn may mutate the map
	local keys = {}
	for i = 1, size do
		keys[#keys + 1] = map:getMapKeyAtIndex(i - 1)
	end

	for i = 1, #keys do
		local entry = self:rosterGet(keys[i])
		if (entry ~= nil) then
			fn(keys[i], entry)
		end
	end
end

function MandoRankManager:countAtRank(rank)
	local n = 0
	self:rosterEach(function(id, e)
		if (e.rank == rank) then
			n = n + 1
		end
	end)
	return n
end

function MandoRankManager:isEnrolled(pPlayer)
	return self:rosterGet(tostring(SceneObject(pPlayer):getObjectID())) ~= nil
end

function MandoRankManager:getRank(pPlayer)
	local e = self:rosterGet(tostring(SceneObject(pPlayer):getObjectID()))
	return e ~= nil and e.rank or -1
end

function MandoRankManager:rankInfo(rank)
	return MandoRankConfig.ranks[rank + 1]
end

function MandoRankManager:getXp(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return 0
	end

	return PlayerObject(pGhost):getExperience(MandoRankConfig.xpType)
end

-- --- pledge (profession-path PvE XP opt-in, at the stone) --------------------

function MandoRankManager:isPledged(pPlayer)
	return readScreenPlayData(pPlayer, "MandoRank", "pledged") == "1"
end

function MandoRankManager:pledge(pPlayer)
	if (not CreatureObject(pPlayer):hasSkill("mandalorian_foundling_novice")) then
		CreatureObject(pPlayer):sendSystemMessage("Only those walking the Mandalorian path may pledge to the Creed.")
		return
	end

	writeScreenPlayData(pPlayer, "MandoRank", "pledged", "1")
	MandoRankObservers:attachPledgeObserver(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("You pledge yourself to the Resol'nare. Your deeds in battle will now strengthen your walk on the path. (Mandalorian XP from kills enabled.)")
	print("mando_rank: pledge by " .. CreatureObject(pPlayer):getFirstName())
end

-- --- enrollment (Swear, at the stone; Verd gate) ------------------------------

function MandoRankManager:enroll(pPlayer)
	if (self:isEnrolled(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have already sworn to the clans.")
		return
	end

	if (not CreatureObject(pPlayer):hasSkill("mandalorian_warrior_master")) then
		CreatureObject(pPlayer):sendSystemMessage("Only a proven Verd (Master Warrior) may swear before the clans.")
		return
	end

	-- hasSkill pre-check satisfied by the gate above: novice requires
	-- mandalorian_warrior_master, which we just verified.
	awardSkill(pPlayer, "mandalorian_rank_novice")

	if (not CreatureObject(pPlayer):hasSkill("mandalorian_rank_novice")) then
		CreatureObject(pPlayer):sendSystemMessage("The clans could not accept your oath. (Skill grant failed — contact staff.)")
		return
	end

	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	self:rosterSet(playerID, 0, getTimestamp(), CreatureObject(pPlayer):getFirstName())
	MandoRankObservers:attachMemberObservers(pPlayer)

	CreatureObject(pPlayer):sendSystemMessage("You swear the oath of the clans. You are Ge'verd — prove yourself in blood. (Clan Rank XP from PvP kills of FRS Jedi and ranked Mandalorians enabled.)")
	print("mando_rank: enroll (Ge'verd) " .. CreatureObject(pPlayer):getFirstName() .. " oid " .. playerID)
end

-- --- maintenance / decay ------------------------------------------------------

-- Reconcile the roster with the rank boxes actually on the player. The
-- ladder is VISIBLE in the skill browser since r26, which exposes the
-- window's manual "surrender skill" — a path that bypasses this system.
-- The truth is whatever skills the player holds: adopt it, loudly.
function MandoRankManager:reconcile(pPlayer)
	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local e = self:rosterGet(playerID)

	if (e == nil) then
		return
	end

	local actual = -1
	for r = 0, 11 do
		if (CreatureObject(pPlayer):hasSkill(self:rankInfo(r).skillName)) then
			actual = r
		end
	end

	if (actual == e.rank) then
		return
	end

	if (actual < 0) then
		self:rosterDelete(playerID)
		CreatureObject(pPlayer):sendSystemMessage("You have forsaken the clans. Swear again at the stone if you would return — from the bottom.")
		print("mando_rank: RECONCILE " .. e.name .. " holds no rank boxes (manual surrender?) -> removed from roster")
		return
	end

	self:rosterSet(playerID, actual, e.lastMaint, e.name)
	CreatureObject(pPlayer):sendSystemMessage("The clans take note of what you have given up. Your standing is now " .. self:rankInfo(actual).title .. ".")
	print("mando_rank: RECONCILE " .. e.name .. " roster rank " .. e.rank .. " -> actual " .. actual .. " (manual surrender?)")
end

-- Settle a member's upkeep debt from epoch math (covers offline time),
-- then auto-demote while below the current rank's threshold.
function MandoRankManager:settle(pPlayer)
	self:reconcile(pPlayer)

	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local e = self:rosterGet(playerID)

	if (e == nil) then
		return
	end

	local now = getTimestamp()
	local periods = math.floor((now - e.lastMaint) / MandoRankConfig.maintIntervalSec)

	if (periods <= 0) then
		return
	end

	local cost = MandoRankConfig.baseMaintCost * e.rank * periods

	if (cost > 0) then
		CreatureObject(pPlayer):awardExperience(MandoRankConfig.xpType, -cost, false)
		CreatureObject(pPlayer):sendSystemMessage("Clan upkeep: " .. cost .. " Mandalorian Clan Rank XP (" .. periods .. " day(s) at rank " .. e.rank .. ").")
	end

	e.lastMaint = e.lastMaint + periods * MandoRankConfig.maintIntervalSec
	self:rosterSet(playerID, e.rank, e.lastMaint, e.name)

	-- demote while under the CURRENT rank's threshold
	local xp = self:getXp(pPlayer)
	while (e.rank > 0 and xp < self:rankInfo(e.rank).xpRequired) do
		self:demoteOne(pPlayer, "upkeep")
		e = self:rosterGet(playerID)
		if (e == nil) then
			return
		end
		xp = self:getXp(pPlayer)
	end
end

-- One tick: settle every ONLINE member, then reschedule.
function MandoRankManager:maintenanceTick()
	local settled = 0

	MandoRankManager:rosterEach(function(id, e)
		local pPlayer = getCreatureObject(tonumber(id))

		if (pPlayer ~= nil) then
			local pGhost = CreatureObject(pPlayer):getPlayerObject()

			if (pGhost ~= nil and PlayerObject(pGhost):isOnline()) then
				MandoRankManager:settle(pPlayer)
				settled = settled + 1
			end
		end
	end)

	print("mando_rank: maintenance tick settled " .. settled .. " online member(s)")
	createServerEvent(MandoRankConfig.maintTickMs, "MandoRankManager", "maintenanceTick", MandoRankConfig.maintEventName)
end

-- --- rank movement ------------------------------------------------------------

-- Award exactly one rank step. hasSkill(prev) is pre-checked so the
-- awardRequiredSkills=true binding can never cascade a grant.
function MandoRankManager:promoteOne(pPlayer, reason)
	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local e = self:rosterGet(playerID)

	if (e == nil or e.rank >= 11) then
		return false
	end

	local cur = self:rankInfo(e.rank)
	local nxt = self:rankInfo(e.rank + 1)

	if (not CreatureObject(pPlayer):hasSkill(cur.skillName)) then
		print("mando_rank: DESYNC promoteOne " .. e.name .. " missing " .. cur.skillName .. " at roster rank " .. e.rank)
		return false
	end

	awardSkill(pPlayer, nxt.skillName)

	if (not CreatureObject(pPlayer):hasSkill(nxt.skillName)) then
		return false
	end

	self:rosterSet(playerID, e.rank + 1, e.lastMaint, e.name)
	CreatureObject(pPlayer):sendSystemMessage("The clans recognize you: you now hold the rank of " .. nxt.title .. ". (" .. (reason or "promotion") .. ")")
	print("mando_rank: promote " .. e.name .. " -> rank " .. (e.rank + 1) .. " (" .. nxt.title .. ") [" .. (reason or "promotion") .. "]")
	return true
end

function MandoRankManager:demoteOne(pPlayer, reason)
	local playerID = tostring(SceneObject(pPlayer):getObjectID())
	local e = self:rosterGet(playerID)

	if (e == nil or e.rank <= 0) then
		return false
	end

	local cur = self:rankInfo(e.rank)

	if (CreatureObject(pPlayer):hasSkill(cur.skillName)) then
		CreatureObject(pPlayer):surrenderSkill(cur.skillName)
	end

	self:rosterSet(playerID, e.rank - 1, e.lastMaint, e.name)
	CreatureObject(pPlayer):sendSystemMessage("You have fallen to the rank of " .. self:rankInfo(e.rank - 1).title .. ". (" .. (reason or "demotion") .. ")")
	print("mando_rank: demote " .. e.name .. " -> rank " .. (e.rank - 1) .. " [" .. (reason or "demotion") .. "]")
	return true
end

-- Claim the next rank (stone option). Full ranks require a challenge.
function MandoRankManager:claim(pPlayer)
	if (not self:isEnrolled(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have not sworn to the clans.")
		return
	end

	self:settle(pPlayer)

	local e = self:rosterGet(tostring(SceneObject(pPlayer):getObjectID()))

	if (e == nil) then
		return
	end

	if (e.rank >= 11) then
		CreatureObject(pPlayer):sendSystemMessage("You are Mand'alor. There is nothing above you.")
		return
	end

	local nxt = self:rankInfo(e.rank + 1)
	local xp = self:getXp(pPlayer)

	if (xp < nxt.xpRequired) then
		CreatureObject(pPlayer):sendSystemMessage("You need " .. nxt.xpRequired .. " Clan Rank XP for " .. nxt.title .. " (you have " .. xp .. ").")
		return
	end

	if (nxt.playerCap >= 0 and self:countAtRank(e.rank + 1) >= nxt.playerCap) then
		CreatureObject(pPlayer):sendSystemMessage("All " .. nxt.title .. " positions are held. Challenge a holder to take their place (Challenge option).")
		return
	end

	self:promoteOne(pPlayer, "claim")
end

-- --- admin ops (stone admin submenu; staff only) -------------------------------

function MandoRankManager:adminClearDebt(pPlayer, pTarget)
	local playerID = tostring(SceneObject(pTarget):getObjectID())
	local e = self:rosterGet(playerID)

	if (e == nil) then
		CreatureObject(pPlayer):sendSystemMessage("Target is not enrolled.")
		return
	end

	self:rosterSet(playerID, e.rank, getTimestamp(), e.name)
	MandoRankDuel:clearCooldown(pTarget)
	CreatureObject(pPlayer):sendSystemMessage("Cleared upkeep debt + challenge cooldown for " .. e.name .. ".")
	print("mando_rank: ADMIN clearDebt " .. e.name .. " by " .. CreatureObject(pPlayer):getFirstName())
end

function MandoRankManager:adminForceDemote(pPlayer, pTarget)
	if (self:demoteOne(pTarget, "staff decision")) then
		CreatureObject(pPlayer):sendSystemMessage("Demoted " .. CreatureObject(pTarget):getFirstName() .. " one rank.")
		print("mando_rank: ADMIN forceDemote " .. CreatureObject(pTarget):getFirstName() .. " by " .. CreatureObject(pPlayer):getFirstName())
	else
		CreatureObject(pPlayer):sendSystemMessage("Target cannot be demoted (not enrolled or rank 0).")
	end
end

function MandoRankManager:adminPromote(pPlayer, pTarget)
	if (not self:isEnrolled(pTarget)) then
		CreatureObject(pPlayer):sendSystemMessage("Target is not enrolled (they must Swear at the stone first).")
		return
	end

	if (self:promoteOne(pTarget, "staff decision")) then
		CreatureObject(pPlayer):sendSystemMessage("Promoted " .. CreatureObject(pTarget):getFirstName() .. " one rank.")
		print("mando_rank: ADMIN promote " .. CreatureObject(pTarget):getFirstName() .. " by " .. CreatureObject(pPlayer):getFirstName())
	else
		CreatureObject(pPlayer):sendSystemMessage("Promote failed (already Mand'alor, or skill desync — see log).")
	end
end

function MandoRankManager:rosterSummary()
	local lines = {}

	self:rosterEach(function(id, e)
		local info = MandoRankManager:rankInfo(e.rank)
		lines[#lines + 1] = string.format("%s — rank %d (%s), last upkeep %d", e.name, e.rank, info.title, e.lastMaint)
	end)

	if (#lines == 0) then
		lines[1] = "(no clan members)"
	end

	return lines
end
