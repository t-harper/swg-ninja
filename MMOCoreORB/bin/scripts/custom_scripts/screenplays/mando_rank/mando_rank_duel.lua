-- mando_rank_duel.lua — challenge duels: the promotion path into FULL
-- ranks (replaces the FRS petition/vote cycle). A challenger of rank r
-- picks an ONLINE holder of rank r+1; after a 5-minute acceptance
-- window (the holder may accept early at the stone) the duel is live
-- for 60 minutes. A deathblow between the pair resolves it:
--   challenger kills holder -> ranks swap (holder drops one, challenger
--   rises one); holder kills challenger -> defense, challenger takes the
--   25h cooldown. Window expiry (incl. disconnects) = draw + cooldown.
--
-- State lives in writeScreenPlayData strings keyed off both players, so
-- it survives restarts; validity is always re-derived from epoch math
-- (a restart that eats the expiry event just leaves a stale state that
-- self-cleans on the next read). Resolution runs inside the single lua
-- lock: read state -> clear state ("the claim") -> apply ranks.

MandoRankDuel = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("MandoRankDuel", true)

function MandoRankDuel:start()
end

-- --- state helpers ------------------------------------------------------------

local function sp(pPlayer, key)
	local v = readScreenPlayData(pPlayer, "MandoRankDuel", key)

	if (v == nil or v == "") then
		return nil
	end

	return v
end

local function spSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "MandoRankDuel", key, value)
end

function MandoRankDuel:clearState(pChallenger, pHolder)
	if (pChallenger ~= nil) then
		spSet(pChallenger, "targetID", "")
		spSet(pChallenger, "start", "")
		spSet(pChallenger, "accepted", "")
	end

	if (pHolder ~= nil) then
		spSet(pHolder, "challengerID", "")
	end
end

function MandoRankDuel:setCooldown(pPlayer)
	spSet(pPlayer, "cooldownUntil", tostring(getTimestamp() + MandoRankConfig.challenge.cooldownSec))
end

function MandoRankDuel:clearCooldown(pPlayer)
	spSet(pPlayer, "cooldownUntil", "")
end

function MandoRankDuel:onCooldown(pPlayer)
	local untilTs = tonumber(sp(pPlayer, "cooldownUntil") or "0")
	return untilTs > getTimestamp()
end

-- Active (or pending) outgoing challenge, self-cleaning stale entries.
function MandoRankDuel:activeChallenge(pChallenger)
	local targetID = tonumber(sp(pChallenger, "targetID") or "0")
	local startTs = tonumber(sp(pChallenger, "start") or "0")

	if (targetID == 0 or startTs == 0) then
		return nil
	end

	if (getTimestamp() > startTs + MandoRankConfig.challenge.duelWindowSec) then
		-- stale (expiry event lost to a restart, or already fired): draw
		self:expireByChallenger(pChallenger, true)
		return nil
	end

	return { targetID = targetID, start = startTs, accepted = (sp(pChallenger, "accepted") == "1") }
end

function MandoRankDuel:isLive(ch)
	return ch ~= nil and (ch.accepted or getTimestamp() >= ch.start + MandoRankConfig.challenge.acceptWindowSec)
end

-- --- challenge lifecycle --------------------------------------------------------

-- Stone entry: list online holders of the challenger's next rank.
function MandoRankDuel:beginChallenge(pPlayer)
	if (not MandoRankManager:isEnrolled(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have not sworn to the clans.")
		return
	end

	MandoRankManager:settle(pPlayer)

	local rank = MandoRankManager:getRank(pPlayer)

	if (rank < 0 or rank >= 11) then
		CreatureObject(pPlayer):sendSystemMessage("There is no rank above you to challenge for.")
		return
	end

	local nxt = MandoRankManager:rankInfo(rank + 1)

	if (MandoRankManager:getXp(pPlayer) < nxt.xpRequired) then
		CreatureObject(pPlayer):sendSystemMessage("You need " .. nxt.xpRequired .. " Clan Rank XP before you may challenge for " .. nxt.title .. ".")
		return
	end

	if (nxt.playerCap < 0 or MandoRankManager:countAtRank(rank + 1) < nxt.playerCap) then
		CreatureObject(pPlayer):sendSystemMessage(nxt.title .. " has open positions — use Claim Rank instead of a challenge.")
		return
	end

	if (self:onCooldown(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("You have challenged recently. The clans demand patience (25 hour cooldown).")
		return
	end

	if (self:activeChallenge(pPlayer) ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage("You already have an open challenge.")
		return
	end

	-- collect ONLINE holders of the target rank
	local names, ids = {}, {}

	MandoRankManager:rosterEach(function(id, e)
		if (e.rank == rank + 1) then
			local pHolder = getCreatureObject(tonumber(id))

			if (pHolder ~= nil) then
				local pGhost = CreatureObject(pHolder):getPlayerObject()

				if (pGhost ~= nil and PlayerObject(pGhost):isOnline()) then
					names[#names + 1] = e.name .. "  (" .. nxt.title .. ")"
					ids[#ids + 1] = id
				end
			end
		end
	end)

	if (#ids == 0) then
		CreatureObject(pPlayer):sendSystemMessage("No holder of " .. nxt.title .. " is online to challenge.")
		return
	end

	spSet(pPlayer, "pickList", table.concat(ids, ","))

	local sui = SuiListBox.new("MandoRankDuel", "challengePickCallback")
	sui.setTitle("Challenge for " .. nxt.title)
	sui.setPrompt("Choose the holder you will challenge. After a 5 minute call-out (they may accept at the stone sooner), the duel is live for 60 minutes: a deathblow between you decides the rank.")

	for i = 1, #names do
		sui.add(names[i], "")
	end

	sui.sendTo(pPlayer)
end

function MandoRankDuel:challengePickCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = sp(pPlayer, "pickList")
	spSet(pPlayer, "pickList", "")

	if (list == nil) then
		return
	end

	local ids = {}
	for id in string.gmatch(list, "[^,]+") do
		ids[#ids + 1] = id
	end

	local targetID = ids[idx + 1]

	if (targetID == nil) then
		return
	end

	local pHolder = getCreatureObject(tonumber(targetID))

	if (pHolder == nil) then
		CreatureObject(pPlayer):sendSystemMessage("That holder is no longer online.")
		return
	end

	-- refuse if the holder is already being challenged
	if (sp(pHolder, "challengerID") ~= nil) then
		CreatureObject(pPlayer):sendSystemMessage(CreatureObject(pHolder):getFirstName() .. " is already facing a challenge.")
		return
	end

	local now = getTimestamp()
	spSet(pPlayer, "targetID", targetID)
	spSet(pPlayer, "start", tostring(now))
	spSet(pPlayer, "accepted", "")
	spSet(pHolder, "challengerID", tostring(SceneObject(pPlayer):getObjectID()))

	createEvent((MandoRankConfig.challenge.duelWindowSec + 5) * 1000, "MandoRankDuel", "expireEvent", pPlayer, "")

	local cName = CreatureObject(pPlayer):getFirstName()
	local hName = CreatureObject(pHolder):getFirstName()
	CreatureObject(pPlayer):sendSystemMessage("You call out " .. hName .. " before the clans! The duel goes live in 5 minutes (or when they accept) and stays open for 60 minutes. A deathblow decides it.")
	CreatureObject(pHolder):sendSystemMessage(cName .. " challenges you for your rank! The duel goes live in 5 minutes (accept early at the Oyu'baat stone) and stays open for 60 minutes. A deathblow decides it — refusing to fight forfeits nothing but honor.")
	print("mando_rank: CHALLENGE " .. cName .. " -> " .. hName .. " (for rank " .. (MandoRankManager:getRank(pHolder)) .. ")")
end

-- Holder accepts early at the stone.
function MandoRankDuel:acceptIncoming(pHolder)
	local challengerID = tonumber(sp(pHolder, "challengerID") or "0")

	if (challengerID == 0) then
		CreatureObject(pHolder):sendSystemMessage("No one is challenging you.")
		return
	end

	local pChallenger = getCreatureObject(challengerID)

	if (pChallenger == nil or self:activeChallenge(pChallenger) == nil) then
		spSet(pHolder, "challengerID", "")
		CreatureObject(pHolder):sendSystemMessage("The challenge has lapsed.")
		return
	end

	spSet(pChallenger, "accepted", "1")
	CreatureObject(pHolder):sendSystemMessage("You accept the challenge. Fight!")
	CreatureObject(pChallenger):sendSystemMessage(CreatureObject(pHolder):getFirstName() .. " accepts your challenge. Fight!")
end

-- Deathblow hook (from MandoRankObservers:onMemberKilled). Returns true
-- if the kill resolved a duel (consume — no matrix XP for duel kills).
function MandoRankDuel:resolveKill(pVictim, pKiller)
	if (not CreatureObject(pKiller):isPlayerCreature()) then
		return false
	end

	local victimID = SceneObject(pVictim):getObjectID()
	local killerID = SceneObject(pKiller):getObjectID()

	-- case A: challenger (killer) took down the holder (victim)
	local ch = self:activeChallenge(pKiller)

	if (ch ~= nil and ch.targetID == victimID and self:isLive(ch)) then
		self:clearState(pKiller, pVictim)
		self:setCooldown(pKiller)

		local ok = MandoRankManager:demoteOne(pVictim, "defeated in a rank challenge")

		if (ok and not MandoRankManager:promoteOne(pKiller, "challenge victory")) then
			print("mando_rank: DUEL DESYNC — holder demoted but challenger promote failed: " ..
				CreatureObject(pKiller):getFirstName() .. " — fix via stone admin menu")
		end

		print("mando_rank: DUEL WIN " .. CreatureObject(pKiller):getFirstName() .. " defeats " .. CreatureObject(pVictim):getFirstName())
		return true
	end

	-- case B: holder (killer) defended against the challenger (victim)
	local chV = self:activeChallenge(pVictim)

	if (chV ~= nil and chV.targetID == killerID and self:isLive(chV)) then
		self:clearState(pVictim, pKiller)
		self:setCooldown(pVictim)
		CreatureObject(pKiller):sendSystemMessage("You have defended your rank before the clans.")
		CreatureObject(pVictim):sendSystemMessage("Your challenge has failed. The clans demand patience before you try again.")
		print("mando_rank: DUEL DEFENDED " .. CreatureObject(pKiller):getFirstName() .. " holds against " .. CreatureObject(pVictim):getFirstName())
		return true
	end

	return false
end

-- Window expiry: draw + cooldown (also self-invoked on stale reads).
function MandoRankDuel:expireByChallenger(pChallenger, silent)
	local targetID = tonumber(sp(pChallenger, "targetID") or "0")

	if (targetID == 0) then
		return
	end

	local pHolder = getCreatureObject(targetID)
	self:clearState(pChallenger, pHolder)
	self:setCooldown(pChallenger)

	if (not silent) then
		CreatureObject(pChallenger):sendSystemMessage("Your challenge window has closed without a decision. The clans call it a draw.")

		if (pHolder ~= nil) then
			CreatureObject(pHolder):sendSystemMessage("The challenge against you lapsed without a decision.")
		end
	end

	print("mando_rank: DUEL DRAW/EXPIRED challenger " .. CreatureObject(pChallenger):getFirstName())
end

function MandoRankDuel:expireEvent(pChallenger)
	if (pChallenger == nil) then
		return
	end

	local ch = nil
	local targetID = tonumber(sp(pChallenger, "targetID") or "0")
	local startTs = tonumber(sp(pChallenger, "start") or "0")

	if (targetID ~= 0 and startTs ~= 0 and getTimestamp() > startTs + MandoRankConfig.challenge.duelWindowSec) then
		self:expireByChallenger(pChallenger, false)
	end
end

-- Status line for the stone.
function MandoRankDuel:statusLine(pPlayer)
	local ch = self:activeChallenge(pPlayer)

	if (ch ~= nil) then
		local pHolder = getCreatureObject(ch.targetID)
		local hName = pHolder ~= nil and CreatureObject(pHolder):getFirstName() or "(offline)"
		local live = self:isLive(ch) and "LIVE" or "pending acceptance"
		return "Challenge out against " .. hName .. " — " .. live .. ", closes in " ..
			math.max(0, math.floor((ch.start + MandoRankConfig.challenge.duelWindowSec - getTimestamp()) / 60)) .. " min."
	end

	local challengerID = tonumber(sp(pPlayer, "challengerID") or "0")

	if (challengerID ~= 0) then
		local pC = getCreatureObject(challengerID)

		if (pC ~= nil and self:activeChallenge(pC) ~= nil) then
			return "You are being challenged by " .. CreatureObject(pC):getFirstName() .. "! (Accept at this stone to start the duel early.)"
		else
			spSet(pPlayer, "challengerID", "")
		end
	end

	if (self:onCooldown(pPlayer)) then
		return "Challenge cooldown: " .. math.ceil((tonumber(sp(pPlayer, "cooldownUntil")) - getTimestamp()) / 3600) .. " hour(s) remain."
	end

	return nil
end
