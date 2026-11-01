-- mando_config.lua — all knobs for the Mandalorian clan-rank system
-- (lua FRS-analogue; master plan decision #10/#11). Pure data, hot-
-- reloadable. Numbers mirror the stock FRS lua wherever a counterpart
-- exists (frs_manager.lua rankingData thresholds + player caps,
-- frsExperienceValues win column, arenaChallengeCooldown).

MandoRankConfig = {
	enabled = true,

	-- NAMED fields (the manager/duel/stone all read .skillName/.xpRequired/
	-- .playerCap/.title — positional rows here silently nil out every rank
	-- operation; learned 2026-07-11). xpRequired = FRS rankingData
	-- thresholds verbatim; caps likewise (top rank cap 1 = one Mand'alor).
	ranks = {
		{ rank = 0,  skillName = "mandalorian_rank_novice", xpRequired = 0,      playerCap = -1, title = "Ge'verd" },
		{ rank = 1,  skillName = "mandalorian_rank_01",     xpRequired = 5000,   playerCap = 10, title = "Verd'ika" },
		{ rank = 2,  skillName = "mandalorian_rank_02",     xpRequired = 15000,  playerCap = 10, title = "Alor'uus" },
		{ rank = 3,  skillName = "mandalorian_rank_03",     xpRequired = 25000,  playerCap = 10, title = "Ruus'alor" },
		{ rank = 4,  skillName = "mandalorian_rank_04",     xpRequired = 35000,  playerCap = 10, title = "Ver'alor" },
		{ rank = 5,  skillName = "mandalorian_rank_05",     xpRequired = 50000,  playerCap = 9,  title = "Alor'ad" },
		{ rank = 6,  skillName = "mandalorian_rank_06",     xpRequired = 70000,  playerCap = 9,  title = "Al'verde" },
		{ rank = 7,  skillName = "mandalorian_rank_07",     xpRequired = 90000,  playerCap = 9,  title = "Ori'ramikad" },
		{ rank = 8,  skillName = "mandalorian_rank_08",     xpRequired = 130000, playerCap = 8,  title = "Aliit'alor" },
		{ rank = 9,  skillName = "mandalorian_rank_09",     xpRequired = 180000, playerCap = 8,  title = "Cuy'val Dar" },
		{ rank = 10, skillName = "mandalorian_rank_10",     xpRequired = 250000, playerCap = 11, title = "Ori'alor" },
		{ rank = 11, skillName = "mandalorian_rank_master", xpRequired = 400000, playerCap = 1,  title = "Mand'alor" },
	},

	xpType = "mandalorian_rank_xp",

	-- Kill award by VICTIM rank 0..11 (index = victim rank + 1). Values =
	-- the frsExperienceValues rank0_win..rank11_win column. Applies to a
	-- clan member killing: a clan-ranked mando OR an FRS jedi (victim
	-- rank = their FRS rank). The same table feeds the APPROVED JEDI
	-- EXCEPTION: an FRS jedi killing a ranked mando earns force_rank_xp
	-- of the victim's rank value (positive-only; engine cap-clamps).
	xpWin = { 750, 900, 1250, 2250, 3000, 3750, 4500, 5500, 6500, 7500, 8750, 9750 },

	-- Victim-side loss on PvP death (OFF by default; decay is meant to
	-- come from maintenance, not deaths). When enabled the victim loses
	-- the same matrix value the killer gained, floored at their current
	-- rank's threshold (pvp loss never demotes — only maintenance does).
	victimLossEnabled = false,

	-- PvE: pledged path members earn mandalorian_general from kills:
	-- max(pveKillXpMin, victimLevel * pveKillXpPerLevel). The constants
	-- bake in the ~20x the C++ combat-XP path applies via multipliers —
	-- lua awardExperience is multiplier-free. Do not add multipliers.
	pveKillXpPerLevel = 25,
	pveKillXpMin = 25,

	-- Daily upkeep: cost = baseMaintCost * rank per interval (FRS
	-- baseMaintCost=100/day mirror). Settled for online members by the
	-- server event, and per-member at login (epoch math covers offline
	-- time). Auto-demote while xp < current rank threshold. An inactive
	-- top-rank holder who never logs in is removed via the stone's
	-- admin Force Demote.
	maintIntervalSec = 86400,
	baseMaintCost = 100,
	maintEventName = "MandoRankMaint",
	-- server event granularity: how often the online-settle tick runs
	-- (independent of the debt interval; short tick = timely demotions).
	maintTickMs = 3600 * 1000,

	-- Challenge duels (capped-rank promotion; replaces FRS petition/vote).
	challenge = {
		acceptWindowSec = 300,     -- holder may accept early; auto-active after
		duelWindowSec = 3600,      -- FRS arenaChallengeDuration mirror (60 min)
		cooldownSec = 90000,       -- FRS arenaChallengeCooldown mirror (25 h)
	},

	-- APPROVED JEDI EXCEPTION (master plan decision #11): FRS jedi earn
	-- force_rank_xp for killing clan-ranked mandos. Implemented entirely
	-- in our observers — zero FRS code changes.
	jediException = { enabled = true },
}
