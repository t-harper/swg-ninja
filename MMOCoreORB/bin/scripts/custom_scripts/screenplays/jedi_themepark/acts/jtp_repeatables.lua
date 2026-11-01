-- jtp_repeatables.lua — EPIC E-R: epilogue repeatables (post-finale, FRS >= 8).
-- Two weekly quests, the documented exception to the no-re-acquire rule (§7.2):
--   QR.1 [M] "Embers Still Falling" (L) / "Instruments Still Sharpening" (D)
--       [weekly hunt] — clear a rotating tier-apex cell camped at a census
--       shrine. Auto-completes on the last kill (no turn-in NPC):
--       5000 FRS XP + a power_crystals roll + cooldown stamp.
--   QR.2 "The Pilgrim's Round" [weekly vigil — shared] — stand before any 10
--       DISTINCT shrines within the week (lifetime revisits count).
--       Auto-completes at the tenth: 5000 FRS XP + (L: -300 visibility /
--       D: color_crystals roll) + cooldown stamp.
--
-- Gate (accept + offers): JediParkManager.enabled() + isJedi + finale done
-- (JediPark global bit 512) + frsRankOf >= 8 + a declared side. In-flight
-- progress runs on the §7.4 grace floor (rank >= 7 — the repeatable gate is
-- flat at 8, so "entry-1" collapses to a constant); below the floor all
-- progress FREEZES (one pause SUI, nothing wiped) and resumes with the rank.
--
-- WEEK MACHINERY (the house timestamp idiom): getTimestamp() — engine
-- binding, DirectorManager.cpp:1196 (registered :510), epoch SECONDS;
-- precedent mando_rank_duel.lua:54 (cooldownUntil stamps via ScreenPlayData).
--   cooldownSec  = one "week" (config; shrink on dev to walk boundaries)
--   weekNo       = floor(getTimestamp() / cooldownSec)     -- global cadence
--   re-accept during cooldown -> SUI with the remaining days/hours
--   an ACCEPTED quest lapses cooldownSec after accept (the "within the
--   week" rule); a lapse clears in-flight state only — no cooldown stamp,
--   re-accept immediately.
--
-- QR.1 SITE ROTATION (documented formula):
--   flat    = census flattened in JtpConfig.shrinePlanets order, then
--             per-planet index order (stable, 46 entries)
--   tail    = tonumber(last 6 digits of tostring(player OID))  -- keeps the
--             arithmetic exact under any lua number model
--   siteIdx = 1 + ((tail + weekNo * 37) % #flat)
--   from siteIdx, probe forward (wrapping) to the first census entry whose
--   object still resolves (missing shrines skip). 37 is co-prime with 46,
--   so one player walks the whole census over the weeks; the OID tail
--   spreads different players across different stones the same week. The
--   chosen site is STAMPED at accept (repeat_hunt_site) — a week rollover
--   mid-hunt never moves the goalposts.
--
-- The camp is a per-player JtpTheaters:build scene (tag qr1_hunt) raised
-- when the hunter stands before the assigned stone — and by the theaters
-- contract stale state lapses across restarts: a wiped camp simply
-- rebuilds on the next entry, kill tally intact.
--
-- STATE — ScreenPlayData namespace "JediPark", all keys repeat_-prefixed
-- (per the §4 ledger):
--   repeat_hunt_ts / repeat_vigil_ts      completion stamps (cooldown)
--   repeat_hunt_active, repeat_hunt_start, repeat_hunt_site ("planet:idx"),
--   repeat_hunt_kills                     in-flight hunt
--   repeat_vigil_active, repeat_vigil_start,
--   repeat_vigil_set ("planet:idx,...")   in-flight round (cleared at accept)
--   repeat_offer_ts                       shrine self-serve SUI throttle
--   repeat_menukeys                       SUI menu round-trip (act3 idiom)
--   repeat_paused                         demotion-freeze notice latch
-- The screenplay state name "JediParkRepeat" is RESERVED for this file's
-- transient bits; Phase A needs none (everything above is ScreenPlayData).
-- No boot spawns in this file — no JTP_REPEAT_SPAWNED guard is needed
-- (camps are per-player theaters; the shrine areas belong to JtpShrines).
--
-- ===================== MAIN LOOP INTEGRATION (four lines) ====================
-- 1) custom_scripts/screenplays/screenplays.lua — append after the
--    acts/jtp_act4.lua include:
--      includeFile("../custom_scripts/screenplays/jedi_themepark/acts/jtp_repeatables.lua")
-- 2) jtp_shrines.lua, JtpShrines:onEnterShrine — EVERY-entry signal. Insert
--    AFTER the planet/index nil-check block and BEFORE the
--    `if (self:hasVisited(pPlayer, planet, index)) then return 0 end`
--    dedup return (revisits MUST reach the vigil):
--      if (JediParkRepeat ~= nil) then
--          JediParkRepeat:onShrineEntered(pPlayer, planet, index)
--      end
-- 3) acts/jtp_act3.lua, JediParkAct3:giverMenu — Keeper Maro's idle menu
--    (light hall only), before the "wells" option:
--      if (side == 1 and JediParkRepeat ~= nil and JediParkRepeat:eligible(pPlayer)) then
--          options[#options + 1] = { "repeatables", "Ask what standing work the hall keeps. (Weekly)" }
--      end
--    and in giverMenuCallback's dispatch chain (before the "wells" branch):
--      elseif (action == "repeatables") then
--          JediParkRepeat:offer(pPlayer)
-- 4) acts/jtp_act4.lua, JediParkAct4:giverMenu — the Hand's Voice idle menu
--    (dark line only), before the "wells" option:
--      if (side == 2 and JediParkRepeat ~= nil and JediParkRepeat:eligible(pPlayer)) then
--          options[#options + 1] = { "repeatables", "Ask what standing lines the ledger keeps. (Weekly)" }
--      end
--    and in giverMenuCallback's dispatch chain (before the "wells" branch):
--      elseif (action == "repeatables") then
--          JediParkRepeat:offer(pPlayer)
-- =============================================================================

-- ---- tunables (jtp_config owns nothing repeatable-specific yet; claim it) ----

JtpConfig.repeatables = JtpConfig.repeatables or {
	frsRankMin = 8,              -- accept gate; in-flight grace floor is min-1
	finaleBit = 512,             -- JediPark global: Act VI done
	cooldownSec = 7 * 24 * 60 * 60, -- the "week" — DEV KNOB: set to e.g. 300
	                             -- to walk a full cooldown boundary in minutes
	frsXp = 5000,                -- per completion, both quests (plan §6 ceiling)
	offerThrottleSec = 1800,     -- shrine-entry self-serve SUI, at most 1/30min

	hunt = {
		lifetimeSec = 1800,      -- camp despawn (theaters lifetime timer)
		lootGroup = "power_crystals",
		-- Camp compositions keyed by side ({template, dx, dz, dy, heading
		-- [, name]} — JtpTheaters:build mob tuples, offsets from the stone).
		-- Solo baseline for a rank-8 master; do not hand-inflate.
		camps = {
			[1] = { -- the light hunts the Emperor's prophet cells
				{ "senior_prophet_of_the_dark_side", -12, 0, 10, 140 },
				{ "senior_prophet_of_the_dark_side", 12, 0, 10, -140 },
				{ "prophet_of_the_dark_side", -10, 0, -13, 40 },
				{ "prophet_of_the_dark_side", 10, 0, -13, -40 },
			},
			[2] = { -- the dark hunts the Circle's zealot watch
				{ "fbase_rebel_squad_leader_hard", -12, 0, 10, 140, "a Circle zealot" },
				{ "fbase_rebel_squad_leader_hard", 12, 0, 10, -140, "a Circle zealot" },
				{ "fbase_rebel_rifleman_hard", -10, 0, -13, 40, "a Circle zealot" },
				{ "fbase_rebel_rifleman_hard", 10, 0, -13, -40, "a Circle zealot" },
			},
		},
	},

	vigil = {
		count = 10,              -- distinct shrines per round
		visReward = -300,        -- light completion: visibility relief
		lootGroupDark = "color_crystals", -- dark completion: crystal roll
	},
}

JediParkRepeat = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JediParkRepeat", true)

function JediParkRepeat:start()
	if (not JediParkManager.enabled()) then
		return
	end

	print("jtp: repeatables loaded")
end

-- ---- small local helpers (package idiom) -------------------------------------

local HUNT_TAG = "qr1_hunt"

local function dataNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function dataStr(pPlayer, key)
	local value = readScreenPlayData(pPlayer, "JediPark", key)

	if (value == nil) then
		return ""
	end

	return value
end

local function dataSet(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

local function csvContains(csv, entry)
	for item in string.gmatch(csv, "[^,]+") do
		if (item == entry) then
			return true
		end
	end

	return false
end

local function csvCount(csv)
	local n = 0

	for _ in string.gmatch(csv, "[^,]+") do
		n = n + 1
	end

	return n
end

-- "3 day(s) 4 hour(s)" — cooldown SUI arithmetic (mando_rank_duel idiom).
local function fmtRemaining(sec)
	if (sec < 3600) then
		return math.max(1, math.ceil(sec / 60)) .. " minute(s)"
	end

	local days = math.floor(sec / 86400)
	local hours = math.ceil((sec - days * 86400) / 3600)

	if (days == 0) then
		return hours .. " hour(s)"
	end

	return days .. " day(s) " .. hours .. " hour(s)"
end

local function huntName(side)
	if (side == 2) then
		return "Instruments Still Sharpening"
	end

	return "Embers Still Falling"
end

local function planetPretty(planet)
	if (planet == "yavin4") then
		return "Yavin IV"
	end

	return string.upper(string.sub(planet, 1, 1)) .. string.sub(planet, 2)
end

-- ---- gate --------------------------------------------------------------------

function JediParkRepeat:finaleDone(pPlayer)
	return JediParkManager:hasGlobal(pPlayer, JtpConfig.repeatables.finaleBit)
end

-- Accept/offer gate (strict). The acts' idle menus call this to decide
-- whether to show their "standing work" row.
function JediParkRepeat:eligible(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return false
	end

	local M = JediParkManager

	return M:isJedi(pPlayer)
		and M:sideOf(pPlayer) ~= 0
		and self:finaleDone(pPlayer)
		and M:frsRankOf(pPlayer) >= JtpConfig.repeatables.frsRankMin
end

-- In-flight grace floor (§7.4): rank min-1 keeps progress alive through a
-- one-step demotion; below it everything freezes (never wipes).
function JediParkRepeat:inFlightOk(pPlayer)
	return self:finaleDone(pPlayer)
		and JediParkManager:frsRankOf(pPlayer) >= (JtpConfig.repeatables.frsRankMin - 1)
end

function JediParkRepeat:anyActive(pPlayer)
	return dataNum(pPlayer, "repeat_hunt_active") == 1 or dataNum(pPlayer, "repeat_vigil_active") == 1
end

-- Demotion freeze: one SUI per episode (latched), resume note on recovery.
function JediParkRepeat:notePause(pPlayer)
	if (not self:anyActive(pPlayer) or dataNum(pPlayer, "repeat_paused") == 1) then
		return
	end

	dataSet(pPlayer, "repeat_paused", 1)
	self:sui(pPlayer, "The Silent War Waits", "The standing work is cut for the eighth circle, and the hierarchy has moved you below its grace. Nothing is lost — the round and the hunt hold exactly where you left them. Regain your rank and walk on.")
	JediParkManager:log(pPlayer, "repeatables paused (rank below grace floor)")
end

function JediParkRepeat:noteResume(pPlayer)
	if (dataNum(pPlayer, "repeat_paused") ~= 1) then
		return
	end

	dataSet(pPlayer, "repeat_paused", "")

	if (self:anyActive(pPlayer)) then
		CreatureObject(pPlayer):sendSystemMessage("The hierarchy knows you again. Your standing work resumes where it held.")
	end
end

-- ---- cooldown / window machinery ---------------------------------------------

-- Seconds until the quest can be taken again (0 = ready). which = "hunt"|"vigil".
function JediParkRepeat:remainingCooldown(pPlayer, which)
	local ts = dataNum(pPlayer, "repeat_" .. which .. "_ts")

	if (ts == 0) then
		return 0
	end

	return math.max(0, ts + JtpConfig.repeatables.cooldownSec - getTimestamp())
end

-- The "within the week" rule: an accepted quest lapses cooldownSec after
-- accept. Lapse clears in-flight state only (NO cooldown stamp) — the
-- quest re-offers immediately with fresh ground. Returns true if lapsed.
function JediParkRepeat:lapseIfStale(pPlayer, which)
	if (dataNum(pPlayer, "repeat_" .. which .. "_active") ~= 1) then
		return false
	end

	local startTs = dataNum(pPlayer, "repeat_" .. which .. "_start")

	if (startTs ~= 0 and getTimestamp() <= startTs + JtpConfig.repeatables.cooldownSec) then
		return false
	end

	self:clearInFlight(pPlayer, which)

	if (which == "hunt") then
		JtpTheaters:teardown(pPlayer, HUNT_TAG)
		CreatureObject(pPlayer):sendSystemMessage("The week turned and the cell moved on. The hunt can be taken again — the ground will be new.")
	else
		CreatureObject(pPlayer):sendSystemMessage("The week turned before the tenth stone. The Pilgrim's Round begins fresh when you take it up again.")
	end

	JediParkManager:log(pPlayer, "repeatable " .. which .. " lapsed (window passed)")

	return true
end

function JediParkRepeat:clearInFlight(pPlayer, which)
	dataSet(pPlayer, "repeat_" .. which .. "_active", "")
	dataSet(pPlayer, "repeat_" .. which .. "_start", "")

	if (which == "hunt") then
		dataSet(pPlayer, "repeat_hunt_site", "")
		dataSet(pPlayer, "repeat_hunt_kills", "")
	else
		dataSet(pPlayer, "repeat_vigil_set", "")
	end
end

-- ---- QR.1 site rotation ------------------------------------------------------

-- Flattened census in stable order (shrinePlanets order, per-planet index
-- order). Entries: { planet = ..., index = ..., oid = ... }.
local function flatCensus()
	local flat = {}

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		local planet = JtpConfig.shrinePlanets[p]
		local ids = JtpConfig.shrines[planet]

		for i = 1, #ids, 1 do
			flat[#flat + 1] = { planet = planet, index = i, oid = ids[i] }
		end
	end

	return flat
end

-- The documented formula (see the file header). Returns site table
-- { planet, index, oid, x, y } or nil when no census object resolves.
function JediParkRepeat:pickHuntSite(pPlayer)
	local flat = flatCensus()

	if (#flat == 0) then
		return nil
	end

	local oidStr = tostring(SceneObject(pPlayer):getObjectID())
	local tail = tonumber(string.sub(oidStr, -6)) or 0
	local weekNo = math.floor(getTimestamp() / JtpConfig.repeatables.cooldownSec)
	local start = (tail + weekNo * 37) % #flat

	for probe = 0, #flat - 1, 1 do
		local site = flat[((start + probe) % #flat) + 1]

		if (isZoneEnabled(site.planet)) then
			local pShrine = getSceneObject(site.oid)

			if (pShrine ~= nil) then
				site.x = math.floor(SceneObject(pShrine):getWorldPositionX())
				site.y = math.floor(SceneObject(pShrine):getWorldPositionY())

				return site
			end
		end
	end

	return nil
end

function JediParkRepeat:huntSiteOf(pPlayer)
	local stored = dataStr(pPlayer, "repeat_hunt_site")
	local planet, index = string.match(stored, "^(%w+):(%d+)$") -- %w: "yavin4"

	if (planet == nil) then
		return nil, 0
	end

	return planet, tonumber(index)
end

-- ---- offer surfaces ----------------------------------------------------------

-- ============================================================================
-- ROUTER ENTRY POINT — this is the call the MAIN LOOP wires from the
-- Keeper Maro (act3, light) and Hand's Voice (act4, dark) idle menus (the
-- exact insertion lines are in the file header). Safe to route from any
-- future giver: it live-evaluates the gate and refuses in voice.
-- ============================================================================
function JediParkRepeat:offer(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	local M = JediParkManager

	if (not M:isJedi(pPlayer) or M:sideOf(pPlayer) == 0) then
		self:sui(pPlayer, "The Standing Work", "The standing work is cut for those the war already knows. It does not know you yet.")
		return
	end

	if (not self:finaleDone(pPlayer)) then
		self:sui(pPlayer, "The Standing Work", "The standing work begins where the war's last page ends. Finish the reckoning; the week will still be here.")
		return
	end

	if (M:frsRankOf(pPlayer) < JtpConfig.repeatables.frsRankMin) then
		self:sui(pPlayer, "The Standing Work", "The standing work is cut for the eighth circle of the hierarchy and above. Climb, and ask again. (Requires: FRS rank 8.)")
		return
	end

	self:menu(pPlayer)
end

-- The weekly board (shared by the router and the shrine self-serve).
function JediParkRepeat:menu(pPlayer)
	local R = JtpConfig.repeatables
	local side = JediParkManager:sideOf(pPlayer)

	self:lapseIfStale(pPlayer, "hunt")
	self:lapseIfStale(pPlayer, "vigil")

	local options = {}

	-- QR.1 — the weekly hunt.
	if (dataNum(pPlayer, "repeat_hunt_active") == 1) then
		local kills = dataNum(pPlayer, "repeat_hunt_kills")
		options[#options + 1] = { "hunt_hint", "Ask after the week's hunt (" .. kills .. " of " .. #R.hunt.camps[side] .. " accounted)" }
	else
		local rem = self:remainingCooldown(pPlayer, "hunt")

		if (rem > 0) then
			options[#options + 1] = { "hunt_cd", "The hunt is spent for this week (returns in " .. fmtRemaining(rem) .. ")" }
		else
			options[#options + 1] = { "hunt_accept", "Take the week's hunt. (" .. huntName(side) .. ")" }
		end
	end

	-- QR.2 — the shared vigil.
	if (dataNum(pPlayer, "repeat_vigil_active") == 1) then
		local n = csvCount(dataStr(pPlayer, "repeat_vigil_set"))
		options[#options + 1] = { "vigil_hint", "Ask after the Pilgrim's Round (" .. n .. " of " .. R.vigil.count .. " wells)" }
	else
		local rem = self:remainingCooldown(pPlayer, "vigil")

		if (rem > 0) then
			options[#options + 1] = { "vigil_cd", "The round is walked for this week (returns in " .. fmtRemaining(rem) .. ")" }
		else
			options[#options + 1] = { "vigil_accept", "Walk the Pilgrim's Round again. (10 wells this week)" }
		end
	end

	local keys = {}
	local sui = SuiListBox.new("JediParkRepeat", "menuCallback")

	if (side == 1) then
		sui.setTitle("The Circle's Standing Work")
		sui.setPrompt("The war went quiet, not away. The Circle keeps two works standing for its masters — a hunt and a road — and the week resets both. Nobody thanks you. That is how you know it matters.")
	else
		sui.setTitle("The Ledger's Standing Lines")
		sui.setPrompt("The ledger keeps two lines open for instruments of the eighth circle — a hunt and a road — ruled fresh each week. The Voice does not repeat itself, but the week does.")
	end

	for i = 1, #options, 1 do
		keys[#keys + 1] = options[i][1]
		sui.add(options[i][2], "")
	end

	dataSet(pPlayer, "repeat_menukeys", table.concat(keys, ","))
	sui.sendTo(pPlayer)
end

function JediParkRepeat:menuCallback(pPlayer, pSui, eventIndex, args)
	if (pPlayer == nil or eventIndex == 1 or not JediParkManager.enabled()) then
		return
	end

	local idx = tonumber(args)

	if (idx == nil or idx < 0) then
		return
	end

	local list = dataStr(pPlayer, "repeat_menukeys")
	dataSet(pPlayer, "repeat_menukeys", "")

	if (list == "") then
		return
	end

	-- The gate stays live through the menu round-trip (global AC 1).
	if (not self:eligible(pPlayer)) then
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

	local R = JtpConfig.repeatables
	local side = JediParkManager:sideOf(pPlayer)

	if (action == "hunt_accept") then
		self:acceptHunt(pPlayer, side)

	elseif (action == "hunt_hint") then
		self:huntHint(pPlayer, side)

	elseif (action == "hunt_cd") then
		self:sui(pPlayer, huntName(side), "The week still owes you nothing. The hunt returns in " .. fmtRemaining(self:remainingCooldown(pPlayer, "hunt")) .. ".")

	elseif (action == "vigil_accept") then
		self:acceptVigil(pPlayer, side)

	elseif (action == "vigil_hint") then
		local n = csvCount(dataStr(pPlayer, "repeat_vigil_set"))

		if (n >= R.vigil.count) then
			-- A payout frozen by a demotion settles here too.
			self:maybeFinishVigil(pPlayer)
		else
			self:sui(pPlayer, "The Pilgrim's Round", "\"" .. n .. " of " .. R.vigil.count .. " wells this round. Any worlds, any stones — the network only counts that somebody walked.\"")
		end

	elseif (action == "vigil_cd") then
		self:sui(pPlayer, "The Pilgrim's Round", "The round is walked for this week. The stones will take your count again in " .. fmtRemaining(self:remainingCooldown(pPlayer, "vigil")) .. ".")
	end
end

-- ---- QR.1: the weekly hunt ---------------------------------------------------

function JediParkRepeat:acceptHunt(pPlayer, side)
	if (not self:eligible(pPlayer) or dataNum(pPlayer, "repeat_hunt_active") == 1) then
		return
	end

	-- Re-accept during cooldown -> the remaining-time SUI (design AC).
	local rem = self:remainingCooldown(pPlayer, "hunt")

	if (rem > 0) then
		self:sui(pPlayer, huntName(side), "The week still owes you nothing. The hunt returns in " .. fmtRemaining(rem) .. ".")
		return
	end

	local site = self:pickHuntSite(pPlayer)

	if (site == nil) then
		self:sui(pPlayer, huntName(side), "The census will not settle on a stone this week. (No shrine site resolved — see the server log.)")
		print("jtp: WARNING — repeatables could not resolve a hunt site (census empty/unresolved)")
		return
	end

	dataSet(pPlayer, "repeat_hunt_active", 1)
	dataSet(pPlayer, "repeat_hunt_start", getTimestamp())
	dataSet(pPlayer, "repeat_hunt_site", site.planet .. ":" .. site.index)
	dataSet(pPlayer, "repeat_hunt_kills", 0)
	self:attachKillObserver(pPlayer)

	local where = "the Force shrine near " .. site.x .. " " .. site.y .. ", " .. planetPretty(site.planet)

	if (side == 1) then
		self:sui(pPlayer, huntName(1), "\"Prophet cells keep coming. The Circle keeps answers ready.\" This week the Emperor's dark-side surveyors squat at " .. where .. " — a senior pair and their two readers, taking the well's measure for the Hand. Clear the cell. No letters, no witnesses; the stones will confirm the work. (Travel to the marked shrine — the cell shows itself when you stand before the stone. Defeat all 4.)")
	else
		self:sui(pPlayer, huntName(2), "\"Zealot cells keep coming. The ledger keeps lines empty.\" This week four of the Circle's zealots hold a vigil at " .. where .. ", waiting for a network that should learn to stop answering. Close all four lines — cleanly, completely. (Travel to the marked shrine — the watch shows itself when you stand before the stone. Defeat all 4.)")
	end

	JediParkManager:log(pPlayer, "repeatable hunt accepted — site " .. site.planet .. ":" .. site.index .. " (" .. site.x .. " " .. site.y .. ")")
end

function JediParkRepeat:huntHint(pPlayer, side)
	local R = JtpConfig.repeatables

	-- A payout frozen by a demotion settles here too, not only on-site.
	if (dataNum(pPlayer, "repeat_hunt_kills") >= #R.hunt.camps[side]) then
		self:maybeFinishHunt(pPlayer)

		if (dataNum(pPlayer, "repeat_hunt_active") ~= 1) then
			return
		end
	end

	local planet, index = self:huntSiteOf(pPlayer)

	if (planet == nil) then
		return
	end

	local kills = dataNum(pPlayer, "repeat_hunt_kills")
	local where = planetPretty(planet)
	local pShrine = getSceneObject((JtpConfig.shrines[planet] or {})[index] or 0)

	if (pShrine ~= nil) then
		where = math.floor(SceneObject(pShrine):getWorldPositionX()) .. " " .. math.floor(SceneObject(pShrine):getWorldPositionY()) .. ", " .. where
	end

	self:sui(pPlayer, huntName(side), "The week's cell holds the Force shrine near " .. where .. ". " .. kills .. " of " .. #R.hunt.camps[side] .. " accounted. Stand before the stone and finish the count.")
end

-- Shrine-entry servicing for the hunt (called from onShrineEntered).
function JediParkRepeat:huntOnEntry(pPlayer, planet, index)
	if (dataNum(pPlayer, "repeat_hunt_active") ~= 1 or self:lapseIfStale(pPlayer, "hunt")) then
		return
	end

	local sitePlanet, siteIndex = self:huntSiteOf(pPlayer)

	if (sitePlanet ~= planet or siteIndex ~= index) then
		return
	end

	local R = JtpConfig.repeatables
	local side = JediParkManager:sideOf(pPlayer)

	if (side == 0) then
		return
	end

	-- Finished counts settle even if the last kill landed oddly (or a
	-- demotion froze the payout — see maybeFinishHunt).
	if (dataNum(pPlayer, "repeat_hunt_kills") >= #R.hunt.camps[side]) then
		self:maybeFinishHunt(pPlayer)
		return
	end

	-- A standing camp keeps standing; corpses decay on their own. The
	-- theaters contract makes a restart-wiped camp lapse -> rebuild here.
	if (self:anyLive(pPlayer, HUNT_TAG)) then
		return
	end

	local pShrine = getSceneObject((JtpConfig.shrines[planet] or {})[index] or 0)

	if (pShrine == nil) then
		return
	end

	local built = JtpTheaters:build(pPlayer, {
		planet = planet,
		x = SceneObject(pShrine):getWorldPositionX(),
		z = SceneObject(pShrine):getWorldPositionZ(),
		y = SceneObject(pShrine):getWorldPositionY(),
		cell = 0,
		mobs = R.hunt.camps[side],
		lifetimeSec = R.hunt.lifetimeSec,
		tag = HUNT_TAG,
	})

	if (built == nil) then
		return
	end

	self:attachKillObserver(pPlayer)

	if (side == 1) then
		CreatureObject(pPlayer):sendSystemMessage("Embers Still Falling: the prophet cell is here. The stone watches. The prophets do not — yet.")
	else
		CreatureObject(pPlayer):sendSystemMessage("Instruments Still Sharpening: the zealots' watch is here, and does not yet know it has ended.")
	end
end

-- True while any object of the tag's scene still stands alive (act3
-- anyLive idiom — a cleared camp must not rebuild over its own dead).
function JediParkRepeat:anyLive(pPlayer, tag)
	local oids = JtpTheaters:getOids(pPlayer, tag)

	for i = 1, #oids, 1 do
		local pObj = getSceneObject(oids[i])

		if (pObj ~= nil) then
			if (not SceneObject(pObj):isCreatureObject()) then
				return true
			end

			if (not CreatureObject(pObj):isDead()) then
				return true
			end
		end
	end

	return false
end

function JediParkRepeat:attachKillObserver(pPlayer)
	dropObserver(KILLEDCREATURE, "JediParkRepeat", "onHuntKill", pPlayer)
	createObserver(KILLEDCREATURE, "JediParkRepeat", "onHuntKill", pPlayer, 1)
end

-- KILLEDCREATURE on the owner (kill credit is owner-only, §7.3 / the
-- S-CORE-6 note). Return 0 keeps the observer, 1 releases it.
function JediParkRepeat:onHuntKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil or not JediParkManager.enabled()) then
		return 0
	end

	if (dataNum(pPlayer, "repeat_hunt_active") ~= 1) then
		return 1 -- nothing running: release (JtpTheaters onWaveKill idiom)
	end

	if (not JtpTheaters:isTheaterMob(pPlayer, HUNT_TAG, pVictim)) then
		return 0
	end

	if (self:lapseIfStale(pPlayer, "hunt")) then
		return 0
	end

	-- Demotion below the grace floor freezes the tally (never wipes);
	-- the camp self-heals via rebuild once the rank returns.
	if (not self:inFlightOk(pPlayer)) then
		self:notePause(pPlayer)
		return 0
	end

	self:noteResume(pPlayer)

	local R = JtpConfig.repeatables
	local side = JediParkManager:sideOf(pPlayer)

	if (side == 0) then
		return 0
	end

	local needed = #R.hunt.camps[side]
	local kills = dataNum(pPlayer, "repeat_hunt_kills") + 1
	dataSet(pPlayer, "repeat_hunt_kills", kills)

	if (kills >= needed) then
		self:maybeFinishHunt(pPlayer)
	else
		CreatureObject(pPlayer):sendSystemMessage(huntName(side) .. ": " .. kills .. " of " .. needed .. " accounted.")
	end

	return 0
end

-- Auto-complete (no turn-in NPC). Grace-floor checked; a frozen payout
-- retries from huntOnEntry when the rank returns.
function JediParkRepeat:maybeFinishHunt(pPlayer)
	if (dataNum(pPlayer, "repeat_hunt_active") ~= 1) then
		return
	end

	if (not self:inFlightOk(pPlayer)) then
		self:notePause(pPlayer)
		return
	end

	local R = JtpConfig.repeatables
	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0) then
		return
	end

	self:clearInFlight(pPlayer, "hunt")
	dataSet(pPlayer, "repeat_hunt_ts", getTimestamp())

	M:awardFrsXp(pPlayer, R.frsXp)
	M:giveLootGroup(pPlayer, R.hunt.lootGroup)

	if (side == 1) then
		self:sui(pPlayer, "Embers Still Falling — the cell is cleared", "The last prophet folds into the brush and the well goes quiet the way a held room goes quiet. No letters, no witnesses — but something crystalline found its way to your pack, and the Circle keeps its answer ready for the next cell. (The hunt returns with the new week.)")
	else
		self:sui(pPlayer, "Instruments Still Sharpening — the lines are closed", "Four zealots, four lines, closed in the ledger's preferred ink. Something crystalline found its way to your pack — the Hand equips its instruments from the instrument's own kills. (The hunt returns with the new week.)")
	end

	M:log(pPlayer, "repeatable hunt COMPLETE — frs " .. R.frsXp .. " + " .. R.hunt.lootGroup .. ", cooldown stamped")
end

-- ---- QR.2: the Pilgrim's Round -----------------------------------------------

function JediParkRepeat:acceptVigil(pPlayer, side)
	if (not self:eligible(pPlayer) or dataNum(pPlayer, "repeat_vigil_active") == 1) then
		return
	end

	local rem = self:remainingCooldown(pPlayer, "vigil")

	if (rem > 0) then
		self:sui(pPlayer, "The Pilgrim's Round", "The round is walked for this week. The stones will take your count again in " .. fmtRemaining(rem) .. ".")
		return
	end

	local R = JtpConfig.repeatables

	dataSet(pPlayer, "repeat_vigil_active", 1)
	dataSet(pPlayer, "repeat_vigil_start", getTimestamp())
	dataSet(pPlayer, "repeat_vigil_set", "") -- dedup set, cleared at accept

	self:sui(pPlayer, "The Pilgrim's Round", "\"Ten wells, any worlds, once more — because the network only exists while someone walks it.\" Old stones forget slowly, and a week is enough to remind them. (Stand before " .. R.vigil.count .. " different Force shrines within the week. The count begins with the next stone you stand before" .. (side == 1 and "; walk quietly, and the road will return the favor.)" or ". The stones keep receipts.)"))

	JediParkManager:log(pPlayer, "repeatable vigil accepted")
end

-- Shrine-entry servicing for the round (called from onShrineEntered —
-- EVERY entry, including lifetime revisits; dedup here is per-cycle only).
function JediParkRepeat:vigilOnEntry(pPlayer, planet, index)
	if (dataNum(pPlayer, "repeat_vigil_active") ~= 1 or self:lapseIfStale(pPlayer, "vigil")) then
		return
	end

	local R = JtpConfig.repeatables
	local entry = planet .. ":" .. index
	local set = dataStr(pPlayer, "repeat_vigil_set")

	if (csvContains(set, entry)) then
		-- Same stone twice in one round: settle a payout a demotion froze
		-- at the tenth stone, otherwise stay quiet.
		if (csvCount(set) >= R.vigil.count) then
			self:maybeFinishVigil(pPlayer)
		end

		return
	end

	if (set == "") then
		set = entry
	else
		set = set .. "," .. entry
	end

	dataSet(pPlayer, "repeat_vigil_set", set)

	local n = csvCount(set)

	if (n >= R.vigil.count) then
		self:maybeFinishVigil(pPlayer)
	else
		CreatureObject(pPlayer):sendSystemMessage("The Pilgrim's Round: " .. n .. " of " .. R.vigil.count .. " wells this round.")
	end
end

-- Auto-complete at the tenth stone. Grace-floor checked; a frozen payout
-- retries on the next shrine entry once the rank returns.
function JediParkRepeat:maybeFinishVigil(pPlayer)
	if (dataNum(pPlayer, "repeat_vigil_active") ~= 1) then
		return
	end

	if (not self:inFlightOk(pPlayer)) then
		self:notePause(pPlayer)
		return
	end

	local R = JtpConfig.repeatables
	local M = JediParkManager
	local side = M:sideOf(pPlayer)

	if (side == 0) then
		return
	end

	self:clearInFlight(pPlayer, "vigil")
	dataSet(pPlayer, "repeat_vigil_ts", getTimestamp())

	M:awardFrsXp(pPlayer, R.frsXp)

	if (side == 1) then
		M:adjustVisibility(pPlayer, R.vigil.visReward)
		M:log(pPlayer, "vigil visibility " .. R.vigil.visReward)
		self:sui(pPlayer, "The Pilgrim's Round — walked", "Ten stones, and the road forgot you as you walked it. That is the whole craft, and this week you were its whole practice. The hunters' ledgers thin where your name used to smolder. (The round returns with the new week.)")
	else
		M:giveLootGroup(pPlayer, R.vigil.lootGroupDark)
		self:sui(pPlayer, "The Pilgrim's Round — walked", "Ten stones took your measure and kept the receipt. Where the last one stood, something glitters in your pack — color pulled from a well that owed the hierarchy a debt. (The round returns with the new week.)")
	end

	M:log(pPlayer, "repeatable vigil COMPLETE — frs " .. R.frsXp .. (side == 1 and " + visibility" or " + " .. R.vigil.lootGroupDark) .. ", cooldown stamped")
end

-- ---- the every-entry shrine hook ---------------------------------------------
-- MAIN LOOP CONTRACT: JtpShrines:onEnterShrine calls this on EVERY area
-- entry, BEFORE its lifetime-visit dedup return (header snippet 2). Cheap
-- and self-guarded: nearly every player leaves at the finale-bit check.
function JediParkRepeat:onShrineEntered(pPlayer, planet, index)
	if (pPlayer == nil or planet == nil or planet == "") then
		return
	end

	-- readData numbers can arrive float-typed; keys need clean "3" not "3.0".
	index = math.floor(tonumber(index) or 0)

	if (index < 1) then
		return
	end

	if (not JediParkManager.enabled() or not self:finaleDone(pPlayer)) then
		return
	end

	local R = JtpConfig.repeatables
	local rank = JediParkManager:frsRankOf(pPlayer)

	-- Below the grace floor everything freezes (§7.4) — one notice, no loss.
	if (rank < R.frsRankMin - 1) then
		self:notePause(pPlayer)
		return
	end

	self:noteResume(pPlayer)

	self:vigilOnEntry(pPlayer, planet, index)
	self:huntOnEntry(pPlayer, planet, index)

	-- Self-serve accept surface: an idle master at any stone gets the
	-- weekly board (throttled; strict gate — grace ranks progress only).
	if (rank >= R.frsRankMin) then
		self:maybeSelfServe(pPlayer)
	end
end

function JediParkRepeat:maybeSelfServe(pPlayer)
	if (JediParkManager:sideOf(pPlayer) == 0) then
		return
	end

	local huntReady = dataNum(pPlayer, "repeat_hunt_active") ~= 1 and self:remainingCooldown(pPlayer, "hunt") == 0
	local vigilReady = dataNum(pPlayer, "repeat_vigil_active") ~= 1 and self:remainingCooldown(pPlayer, "vigil") == 0

	if (not huntReady and not vigilReady) then
		return
	end

	local now = getTimestamp()

	if (now - dataNum(pPlayer, "repeat_offer_ts") < JtpConfig.repeatables.offerThrottleSec) then
		return
	end

	dataSet(pPlayer, "repeat_offer_ts", now)
	self:menu(pPlayer)
end

-- ---- shared SUI helpers (package idiom) --------------------------------------

function JediParkRepeat:sui(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediParkRepeat", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediParkRepeat:emptyCallback(pPlayer, pSui, eventIndex, args)
end
