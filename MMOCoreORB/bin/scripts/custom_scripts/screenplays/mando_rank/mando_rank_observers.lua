-- mando_rank_observers.lua — all kill/login observation for the clan
-- system. Everything is drop-then-create idempotent and persist=1, so a
-- double reloadscreenplays or restart never duplicates an observer.
--
-- Observer map:
--   * clan members:      LOGGEDIN (settle+self-heal) + PLAYERKILLED
--   * pledged path folk: KILLEDCREATURE (PvE mandalorian_general XP)
--   * watched FRS jedi:  PLAYERKILLED (mando killers earn clan XP)
--
-- PLAYERKILLED fires on the VICTIM (arg = killer), so member observers
-- cover: duel resolution, mando-killer matrix awards, AND the approved
-- jedi exception (an FRS-jedi killer earns force_rank_xp — the real FRS
-- pool via awardExperience; FrsManager code untouched). The jedi
-- WATCHLIST covers the reverse direction (mando kills jedi): populated
-- by (a) the JediTrials:unlockJediKnight wrapper below, (b) lazy attach
-- when a member dies to an unwatched FRS jedi, (c) admin backfill at
-- the stone.

MandoRankObservers = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("MandoRankObservers", true)

function MandoRankObservers:start()
end

-- --- attachment (drop-then-create everywhere) ---------------------------------

function MandoRankObservers:attachMemberObservers(pPlayer)
	dropObserver(LOGGEDIN, "MandoRankObservers", "onMemberLoggedIn", pPlayer)
	createObserver(LOGGEDIN, "MandoRankObservers", "onMemberLoggedIn", pPlayer, 1)
	dropObserver(PLAYERKILLED, "MandoRankObservers", "onMemberKilled", pPlayer)
	createObserver(PLAYERKILLED, "MandoRankObservers", "onMemberKilled", pPlayer, 1)
end

function MandoRankObservers:attachPledgeObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "MandoRankObservers", "onPledgedKill", pPlayer)
	createObserver(KILLEDCREATURE, "MandoRankObservers", "onPledgedKill", pPlayer, 1)
end

function MandoRankObservers:attachJediWatch(pJedi)
	dropObserver(PLAYERKILLED, "MandoRankObservers", "onWatchedJediKilled", pJedi)
	createObserver(PLAYERKILLED, "MandoRankObservers", "onWatchedJediKilled", pJedi, 1)
	print("mando_rank: watching FRS jedi " .. CreatureObject(pJedi):getFirstName() .. " (kill credit enabled)")
end

-- Self-heal path used by the stone: refresh whatever the player should have.
function MandoRankObservers:heal(pPlayer)
	if (MandoRankManager:isPledged(pPlayer)) then
		self:attachPledgeObserver(pPlayer)
	end

	if (MandoRankManager:isEnrolled(pPlayer)) then
		self:attachMemberObservers(pPlayer)
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil and PlayerObject(pGhost):getFrsCouncil() > 0) then
		self:attachJediWatch(pPlayer)
	end
end

-- --- helpers ------------------------------------------------------------------

local function frsRankOf(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return -1
	end

	if (PlayerObject(pGhost):getFrsCouncil() <= 0) then
		return -1
	end

	local rank = PlayerObject(pGhost):getFrsRank()

	if (rank < 0) then
		return -1
	end

	return rank
end

local function winValue(victimRank)
	local idx = math.max(0, math.min(11, victimRank)) + 1
	return MandoRankConfig.xpWin[idx]
end

-- --- handlers (always return 0: keep the observer) ----------------------------

function MandoRankObservers:onMemberLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	if (MandoRankManager:isEnrolled(pPlayer)) then
		MandoRankManager:settle(pPlayer)
	end

	return 0
end

-- Pledged path member killed a creature: PvE mandalorian_general.
function MandoRankObservers:onPledgedKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil) then
		return 0
	end

	if (not MandoRankConfig.enabled or not MandoRankManager:isPledged(pPlayer)) then
		return 0
	end

	if (not CreatureObject(pPlayer):hasSkill("mandalorian_foundling_novice")) then
		return 0
	end

	local level = CreatureObject(pVictim):getLevel()
	local xp = math.max(MandoRankConfig.pveKillXpMin, level * MandoRankConfig.pveKillXpPerLevel)
	CreatureObject(pPlayer):awardExperience("mandalorian_general", xp, true)

	return 0
end

-- A clan member died. pKiller may be: the duel opponent (consume), a
-- fellow clan member (matrix award), or an FRS jedi (the approved
-- exception + lazy watchlist attach).
function MandoRankObservers:onMemberKilled(pVictim, pKiller)
	if (pVictim == nil or pKiller == nil or not MandoRankConfig.enabled) then
		return 0
	end

	if (not CreatureObject(pKiller):isPlayerCreature()) then
		return 0
	end

	if (SceneObject(pVictim):getObjectID() == SceneObject(pKiller):getObjectID()) then
		return 0
	end

	local victimRank = MandoRankManager:getRank(pVictim)

	if (victimRank < 0) then
		return 0 -- stale observer: victim left the clan
	end

	-- 1. active challenge duel between the pair?
	if (MandoRankDuel:resolveKill(pVictim, pKiller)) then
		return 0
	end

	-- 2. clan-on-clan kill: killer earns the matrix value
	if (MandoRankManager:isEnrolled(pKiller)) then
		CreatureObject(pKiller):awardExperience(MandoRankConfig.xpType, winValue(victimRank), true)
		print("mando_rank: " .. CreatureObject(pKiller):getFirstName() .. " (clan) killed " ..
			CreatureObject(pVictim):getFirstName() .. " (rank " .. victimRank .. ") +" .. winValue(victimRank) .. " clan xp")
		self:applyVictimLoss(pVictim, victimRank)
		return 0
	end

	-- 3. APPROVED JEDI EXCEPTION: FRS jedi killer earns force_rank_xp
	local killerFrs = frsRankOf(pKiller)

	if (MandoRankConfig.jediException.enabled and killerFrs >= 0) then
		CreatureObject(pKiller):awardExperience("force_rank_xp", winValue(victimRank), true)
		print("mando_rank: FRS jedi " .. CreatureObject(pKiller):getFirstName() .. " (rank " .. killerFrs .. ") killed ranked mando " ..
			CreatureObject(pVictim):getFirstName() .. " (rank " .. victimRank .. ") +" .. winValue(victimRank) .. " force_rank_xp [jedi exception]")
		-- lazy watchlist: make sure future mando kills of THIS jedi pay out
		self:attachJediWatch(pKiller)
		self:applyVictimLoss(pVictim, victimRank)
	end

	return 0
end

function MandoRankObservers:applyVictimLoss(pVictim, victimRank)
	if (not MandoRankConfig.victimLossEnabled or victimRank <= 0) then
		return
	end

	-- floored at the current rank's threshold: pvp loss never demotes
	local threshold = MandoRankManager:rankInfo(victimRank).xpRequired
	local xp = MandoRankManager:getXp(pVictim)
	local loss = math.min(winValue(victimRank), math.max(0, xp - threshold))

	if (loss > 0) then
		CreatureObject(pVictim):awardExperience(MandoRankConfig.xpType, -loss, true)
	end
end

-- A watched FRS jedi died: a clan-member killer earns clan XP by the
-- jedi's FRS rank.
function MandoRankObservers:onWatchedJediKilled(pVictim, pKiller)
	if (pVictim == nil or pKiller == nil or not MandoRankConfig.enabled) then
		return 0
	end

	if (not CreatureObject(pKiller):isPlayerCreature()) then
		return 0
	end

	local jediRank = frsRankOf(pVictim)

	if (jediRank < 0) then
		return 0 -- no longer FRS
	end

	if (MandoRankManager:isEnrolled(pKiller)) then
		CreatureObject(pKiller):awardExperience(MandoRankConfig.xpType, winValue(jediRank), true)
		print("mando_rank: " .. CreatureObject(pKiller):getFirstName() .. " (clan) killed FRS jedi " ..
			CreatureObject(pVictim):getFirstName() .. " (rank " .. jediRank .. ") +" .. winValue(jediRank) .. " clan xp")
	end

	return 0
end

-- --- JediTrials wrapper (watchlist auto-population) ----------------------------
-- Stock reloadscreenplays rebuilds JediTrials fresh (wiping our marker),
-- then this file re-wraps it; a double include of THIS file sees the
-- marker and skips. Zero edits to the stock file.

if (JediTrials ~= nil and JediTrials.unlockJediKnight ~= nil and not JediTrials._mandoWatchWrapped) then
	local _origUnlockJediKnight = JediTrials.unlockJediKnight

	JediTrials.unlockJediKnight = function(selfArg, pPlayer)
		_origUnlockJediKnight(selfArg, pPlayer)

		if (pPlayer ~= nil) then
			local pGhost = CreatureObject(pPlayer):getPlayerObject()

			if (pGhost ~= nil and PlayerObject(pGhost):getFrsCouncil() > 0) then
				MandoRankObservers:attachJediWatch(pPlayer)
			end
		end
	end

	JediTrials._mandoWatchWrapped = true
	print("mando_rank: JediTrials:unlockJediKnight wrapped (FRS watchlist auto-attach)")
end
