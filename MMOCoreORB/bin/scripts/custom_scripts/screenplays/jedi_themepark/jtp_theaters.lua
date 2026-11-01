-- jtp_theaters.lua — S-CORE-5 (apparition & theater kit) + S-CORE-6
-- (solo-tuned wave-defense wrapper). Per-player staged scenes and
-- defenses for Acts III+: enclave rites, arena bosses, Kenobi/Vader
-- apparitions, shrine-site sieges.
--
-- Patterns mined (stock untouched): mellichae_outro_theater.lua (prop-set
-- arena + setDefender adds), quest_tasks/encounter.lua (setNotAttackable
-- idiom: pvp bitmask 0 + AI_NOAIAGGRO), village_raids.lua (wave shape),
-- acts/jtp_act0.lua (OID-list spawn sets + KILLEDCREATURE kill matching
-- + cleanup).
--
-- Everything here is PER-PLAYER: spawned object IDs live in
-- ScreenPlayData namespace "JediPark" (player-scoped), so two players
-- can run the same scene at the same coordinates without collisions.
--
-- State keys (ScreenPlayData "JediPark", per player):
--   theater_<tag>_gen   monotonic build counter (stale-event fencing)
--   theater_<tag>_oids  CSV of live scene object IDs
--   wave_<tag>_gen      monotonic run counter
--   wave_<tag>_idx      current wave number (1-based)
--   wave_<tag>_oids     CSV of outstanding attacker IDs
--   wave_active         CSV of this player's live wave tags
-- Generation counters are NEVER cleared (monotonic forever) so a timer
-- from run N can never touch run N+1. Tags must be short [a-z0-9_] names
-- — no ':' or ',' (they are event-arg and CSV separators).
--
-- Reload/restart safety: JTP_WAVE_SPECS survives reloadscreenplays (the
-- in-flight wave continues). A FULL RESTART wipes specs, mobs and
-- timers; the persisted wave state is then treated as lapsed — the next
-- kill, startWaves() or stopWaves() clears it so the quest can re-offer.
-- Stale theater OID lists are self-healing the same way: teardown skips
-- dead IDs and build() always tears down its tag first.

JtpTheaters = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JtpTheaters", true)

-- Reload guard: in-flight wave specs, keyed "<playerID>:<tag>". In-memory
-- on purpose (specs are code-authored tables, re-supplied on re-offer).
JTP_WAVE_SPECS = JTP_WAVE_SPECS or {}

local GLOW_LIGHT = "object/tangible/jedi/power_shrine.iff"
local GLOW_DARK = "object/tangible/jedi/power_shrine_red.iff"

function JtpTheaters:start()
	if (not JediParkManager.enabled()) then
		return
	end

	print("jtp: theaters kit ready")
end

-- ---- small local helpers ----------------------------------------------------

local function readNum(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, "JediPark", key)) or 0
end

local function readStr(pPlayer, key)
	local value = readScreenPlayData(pPlayer, "JediPark", key)

	if (value == nil) then
		return ""
	end

	return value
end

local function writeVal(pPlayer, key, value)
	writeScreenPlayData(pPlayer, "JediPark", key, value)
end

local function clearKey(pPlayer, key)
	deleteScreenPlayData(pPlayer, "JediPark", key)
end

local function csvContains(csv, entry)
	for item in string.gmatch(csv, "[^,]+") do
		if (item == entry) then
			return true
		end
	end

	return false
end

local function csvAdd(csv, entry)
	if (csvContains(csv, entry)) then
		return csv
	end

	if (csv == "") then
		return entry
	end

	return csv .. "," .. entry
end

-- Returns newCsv, removed(boolean). Entries are unique in our lists.
local function csvRemove(csv, entry)
	local kept = {}
	local removed = false

	for item in string.gmatch(csv, "[^,]+") do
		if (item == entry and not removed) then
			removed = true
		else
			table.insert(kept, item)
		end
	end

	return table.concat(kept, ","), removed
end

local function csvCount(csv)
	local n = 0

	for _ in string.gmatch(csv, "[^,]+") do
		n = n + 1
	end

	return n
end

local function badTag(tag)
	return tag == nil or tag == "" or string.find(tag, "[:,]") ~= nil
end

-- Z for a spawn: cell spawns use authored cell-local z (+offset); world
-- spawns snap to terrain when the player is in-zone (mellichae idiom),
-- else fall back to the authored z.
local function resolveZ(pPlayer, spec, cell, worldX, worldY, dz)
	if (cell ~= 0) then
		return (spec.z or 0) + dz
	end

	if (pPlayer ~= nil and SceneObject(pPlayer):getZoneName() == spec.planet) then
		return getTerrainHeight(pPlayer, worldX, worldY) + dz
	end

	return (spec.z or 0) + dz
end

local function waveKey(pPlayer, tag)
	return SceneObject(pPlayer):getObjectID() .. ":" .. tag
end

-- ============================================================================
-- S-CORE-5: theater kit
-- ============================================================================

-- Build a per-player prop/mob set at a fixed site (world or cell).
--
-- spec = {
--   planet = "yavin4", x = ..., z = ..., y = ..., cell = 0,
--       -- cell ~= 0: x/z/y and all offsets are CELL-LOCAL coordinates
--   props = { { template, dx, dz, dy [, heading(deg)] }, ... },
--   mobs  = { { template, dx, dz, dy, heading(deg) [, name] [, invuln = true] }, ... },
--       -- name: custom display name; invuln: untargetable anchor
--       -- (pvp bitmask 0 + AI_NOAIAGGRO — the Vader/no-kill-credit rail)
--   lifetimeSec = 900, tag = "q37_kilnmaster",
-- }
--
-- Returns { props = {ptr...}, mobs = {ptr...} } (in spec order, failures
-- skipped) or nil. Re-entry safe: building a live tag tears the old
-- scene down first. Cleanup fires automatically after lifetimeSec.
function JtpTheaters:build(pPlayer, spec)
	if (pPlayer == nil or spec == nil or not JediParkManager.enabled()) then
		return nil
	end

	if (badTag(spec.tag)) then
		printLuaError("JtpTheaters:build — bad tag '" .. tostring(spec and spec.tag) .. "' (want [a-z0-9_], no ':' or ',')")
		return nil
	end

	if (spec.planet == nil or not isZoneEnabled(spec.planet)) then
		printLuaError("JtpTheaters:build [" .. spec.tag .. "] — zone '" .. tostring(spec.planet) .. "' not enabled")
		return nil
	end

	if (spec.x == nil or spec.y == nil) then
		printLuaError("JtpTheaters:build [" .. spec.tag .. "] — spec needs x and y")
		return nil
	end

	self:teardown(pPlayer, spec.tag)

	local tag = spec.tag
	local cell = spec.cell or 0
	local gen = readNum(pPlayer, "theater_" .. tag .. "_gen") + 1
	writeVal(pPlayer, "theater_" .. tag .. "_gen", gen)

	local oids = {}
	local result = { props = {}, mobs = {} }
	local props = spec.props or {}

	for i = 1, #props, 1 do
		local p = props[i]
		local worldX = spec.x + (p[2] or 0)
		local worldY = spec.y + (p[4] or 0)
		local worldZ = resolveZ(pPlayer, spec, cell, worldX, worldY, p[3] or 0)
		local pProp = spawnSceneObject(spec.planet, p[1], worldX, worldZ, worldY, cell, math.rad(p[5] or 0))

		if (pProp ~= nil) then
			table.insert(oids, SceneObject(pProp):getObjectID())
			table.insert(result.props, pProp)
		else
			print("jtp: theater [" .. tag .. "] prop spawn failed: " .. tostring(p[1]))
		end
	end

	local mobs = spec.mobs or {}

	for i = 1, #mobs, 1 do
		local m = mobs[i]
		local worldX = spec.x + (m[2] or 0)
		local worldY = spec.y + (m[4] or 0)
		local worldZ = resolveZ(pPlayer, spec, cell, worldX, worldY, m[3] or 0)
		local pMob = spawnMobile(spec.planet, m[1], 0, worldX, worldZ, worldY, m[5] or 0, cell)

		if (pMob ~= nil) then
			if (m[6] ~= nil and m[6] ~= "") then
				SceneObject(pMob):setCustomObjectName(m[6])
			end

			if (m.invuln) then
				CreatureObject(pMob):setPvpStatusBitmask(0)
				AiAgent(pMob):addObjectFlag(AI_NOAIAGGRO)
			end

			table.insert(oids, SceneObject(pMob):getObjectID())
			table.insert(result.mobs, pMob)
		else
			print("jtp: theater [" .. tag .. "] mob spawn failed: " .. tostring(m[1]))
		end
	end

	writeVal(pPlayer, "theater_" .. tag .. "_oids", table.concat(oids, ","))

	local lifetime = spec.lifetimeSec or 900
	createEvent(lifetime * 1000, "JtpTheaters", "onTheaterExpired", pPlayer, tag .. ":" .. gen)

	JediParkManager:log(pPlayer, "theater [" .. tag .. "] built — " .. #result.props .. " props, " .. #result.mobs .. " mobs, " .. lifetime .. "s")

	return result
end

-- Destroy whatever is left of a tag's scene (jtp_act0 cleanupWolfCamp
-- pattern: dead/decayed IDs skip silently). Always safe to call — even
-- when nothing is up, even after a restart (stale IDs just clear).
-- Deliberately NOT galaxy-gated: cleanup must never be refused.
function JtpTheaters:teardown(pPlayer, tag)
	if (pPlayer == nil or badTag(tag)) then
		return
	end

	local csv = readStr(pPlayer, "theater_" .. tag .. "_oids")

	if (csv == "") then
		return
	end

	local n = 0

	for oid in string.gmatch(csv, "[^,]+") do
		local pObject = getSceneObject(tonumber(oid))

		if (pObject ~= nil) then
			SceneObject(pObject):destroyObjectFromWorld()
			n = n + 1
		end
	end

	clearKey(pPlayer, "theater_" .. tag .. "_oids")
	JediParkManager:log(pPlayer, "theater [" .. tag .. "] torn down (" .. n .. " objects)")
end

-- Lifetime timer. Stale-fenced by generation: a rebuild of the same tag
-- bumps the gen, so the old scene's timer becomes a no-op.
function JtpTheaters:onTheaterExpired(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	local tag, gen = string.match(arg, "^(.+):(%d+)$")

	if (tag == nil) then
		return
	end

	if (tonumber(gen) ~= readNum(pPlayer, "theater_" .. tag .. "_gen")) then
		return
	end

	self:teardown(pPlayer, tag)
end

-- OIDs of a live scene (numbers, spawn order). For act-side observers.
function JtpTheaters:getOids(pPlayer, tag)
	local list = {}

	if (pPlayer == nil or badTag(tag)) then
		return list
	end

	for oid in string.gmatch(readStr(pPlayer, "theater_" .. tag .. "_oids"), "[^,]+") do
		table.insert(list, tonumber(oid))
	end

	return list
end

-- True when pObject belongs to this player's tag scene — the act-side
-- kill-credit test (KILLEDCREATURE handler: isTheaterMob(pPlayer, tag,
-- pVictim), the jtp_act0 OID-matching idiom).
function JtpTheaters:isTheaterMob(pPlayer, tag, pObject)
	if (pPlayer == nil or pObject == nil or badTag(tag)) then
		return false
	end

	local targetID = tostring(SceneObject(pObject):getObjectID())

	return csvContains(readStr(pPlayer, "theater_" .. tag .. "_oids"), targetID)
end

-- Apparition sugar over build(): one mobile flanked by glow props, short
-- lifetime, untargetable by default (an apparition is a scene, not a
-- fight — Kenobi at the hut, Vader anchors, vision figures).
--
-- spec = {
--   planet = "tatooine", x = ..., z = ..., y = ..., cell = 0,
--   template = "hero_of_tat_hermit", name = "the echo of a hermit",
--   heading = 0,
--   glow = "light"|"dark"|"both",  -- power_shrine / power_shrine_red props
--   lifetimeSec = 120,
--   invulnerable = true,           -- pass false for an attackable figure
--   onAppear = { screenplay = "JediParkAct1", fn = "onKenobiAppears" },
--       -- optional; fired ~1.5s after the spawn as fn(pPlayer, tag)
--   tag = "q14_kenobi",
-- }
-- Returns build()'s result table (mobs[1] is the apparition) or nil.
function JtpTheaters:apparition(pPlayer, spec)
	if (pPlayer == nil or spec == nil or spec.template == nil or not JediParkManager.enabled()) then
		return nil
	end

	local left = GLOW_LIGHT
	local right = GLOW_LIGHT

	if (spec.glow == "dark") then
		left = GLOW_DARK
		right = GLOW_DARK
	elseif (spec.glow == "both") then
		right = GLOW_DARK
	end

	local mob = { spec.template, 0, 0, 0, spec.heading or 0, spec.name }
	mob.invuln = (spec.invulnerable ~= false)

	local built = self:build(pPlayer, {
		planet = spec.planet, x = spec.x, z = spec.z, y = spec.y, cell = spec.cell or 0,
		props = {
			{ left, -2.5, 0, 1.5 },
			{ right, 2.5, 0, 1.5 },
		},
		mobs = { mob },
		lifetimeSec = spec.lifetimeSec or 120,
		tag = spec.tag,
	})

	if (built == nil) then
		return nil
	end

	if (built.mobs[1] ~= nil) then
		SceneObject(built.mobs[1]):playEffect("clienteffect/healing_healdamage.cef", "")
	end

	if (spec.onAppear ~= nil) then
		local play = spec.onAppear.screenplay or spec.onAppear[1]
		local fn = spec.onAppear.fn or spec.onAppear[2]

		if (play ~= nil and fn ~= nil) then
			createEvent(1500, play, fn, pPlayer, spec.tag)
		end
	end

	return built
end

-- ============================================================================
-- S-CORE-6: solo-tuned wave-defense wrapper
-- ============================================================================
--
-- GROUP SCALING (operator decision "solo-tuned, group-scaled"): wave
-- counts below spawn EXACTLY as authored — they are the SOLO BASELINE.
-- Group scaling arrives later as a jtp_config knob that multiplies each
-- count by the owner's group size at spawn time. Do NOT hand-inflate
-- authored counts for groups, and note that kill credit is owner-only
-- for now (KILLEDCREATURE on the owner, per the S-CORE-6 contract);
-- owner-or-group credit ships with the same scaling knob.

-- Start a wave defense at a fixed site.
--
-- spec = {
--   planet = "dathomir", x = ..., z = ..., y = ...,   -- world only, no cell
--   waves = {
--       { mobs = { { "sith_shadow_thug", 4 }, { "sith_shadow_mercenary", 2 } } },
--       { mobs = { ... } },  -- wave 2, spawns 2s after wave 1 clears
--   },
--   tag = "q25_siege",
--   onComplete = { screenplay = "JediParkAct2", fn = "onSiegeWon" },
--       -- optional; fired 2s after the last kill as fn(pPlayer, tag)
--   abortSec = 600,      -- lapse timer: teardown + state clear (re-offerable)
--   ringMin = 12, ringMax = 32,  -- spawn ring around the site (optional)
--   announce = true,     -- false silences the built-in progress messages
-- }
--
-- Attackers spawn on the ring and press the owner (setDefender). Kills
-- by the OWNER are counted via a drop-then-create KILLEDCREATURE
-- observer matched against the stored wave OIDs. Returns true when the
-- engagement started. Re-entry safe: restarting a live tag replaces it.
function JtpTheaters:startWaves(pPlayer, spec)
	if (pPlayer == nil or spec == nil or not JediParkManager.enabled()) then
		return false
	end

	if (badTag(spec.tag)) then
		printLuaError("JtpTheaters:startWaves — bad tag '" .. tostring(spec and spec.tag) .. "'")
		return false
	end

	if (spec.waves == nil or #spec.waves == 0 or spec.planet == nil or not isZoneEnabled(spec.planet)) then
		printLuaError("JtpTheaters:startWaves [" .. spec.tag .. "] — missing waves/planet")
		return false
	end

	if (spec.x == nil or spec.y == nil) then
		printLuaError("JtpTheaters:startWaves [" .. spec.tag .. "] — spec needs x and y")
		return false
	end

	local tag = spec.tag

	self:stopWaves(pPlayer, tag)

	local gen = readNum(pPlayer, "wave_" .. tag .. "_gen") + 1
	writeVal(pPlayer, "wave_" .. tag .. "_gen", gen)

	JTP_WAVE_SPECS[waveKey(pPlayer, tag)] = spec

	writeVal(pPlayer, "wave_active", csvAdd(readStr(pPlayer, "wave_active"), tag))

	dropObserver(KILLEDCREATURE, "JtpTheaters", "onWaveKill", pPlayer)
	createObserver(KILLEDCREATURE, "JtpTheaters", "onWaveKill", pPlayer, 1)

	createEvent((spec.abortSec or 600) * 1000, "JtpTheaters", "onWaveAbort", pPlayer, tag .. ":" .. gen)

	self:spawnWave(pPlayer, tag, 1)

	return true
end

-- Spawn wave waveIdx of an active engagement (internal).
function JtpTheaters:spawnWave(pPlayer, tag, waveIdx)
	if (pPlayer == nil or badTag(tag)) then
		return
	end

	local spec = JTP_WAVE_SPECS[waveKey(pPlayer, tag)]

	if (spec == nil) then
		-- Restart wiped the in-memory spec: lapse cleanly.
		self:stopWaves(pPlayer, tag)
		return
	end

	local wave = spec.waves[waveIdx]

	if (wave == nil or wave.mobs == nil) then
		printLuaError("JtpTheaters:spawnWave [" .. tag .. "] — no wave " .. waveIdx)
		return
	end

	writeVal(pPlayer, "wave_" .. tag .. "_idx", waveIdx)

	local ringMin = spec.ringMin or 12
	local ringMax = spec.ringMax or 32
	local oids = {}

	for i = 1, #wave.mobs, 1 do
		local entry = wave.mobs[i]
		-- SOLO BASELINE: authored count, unscaled (see the block comment
		-- above — group scaling is a later config knob, not a hand-edit).
		local count = entry[2] or 1

		for c = 1, count, 1 do
			local spawnX, spawnZ, spawnY
			local point = getSpawnPoint(spec.planet, spec.x, spec.y, ringMin, ringMax, true)

			if (point ~= nil) then
				spawnX = point[1]
				spawnZ = point[2]
				spawnY = point[3]
			else
				spawnX = spec.x + getRandomNumber(ringMax * 2) - ringMax
				spawnY = spec.y + getRandomNumber(ringMax * 2) - ringMax
				spawnZ = resolveZ(pPlayer, spec, 0, spawnX, spawnY, 0)
			end

			local pMob = spawnMobile(spec.planet, entry[1], 0, spawnX, spawnZ, spawnY, getRandomNumber(360) - 180, 0)

			if (pMob ~= nil) then
				table.insert(oids, SceneObject(pMob):getObjectID())
				AiAgent(pMob):setDefender(pPlayer)
			else
				print("jtp: wave [" .. tag .. "] spawn failed: " .. tostring(entry[1]))
			end
		end
	end

	writeVal(pPlayer, "wave_" .. tag .. "_oids", table.concat(oids, ","))

	if (spec.announce ~= false) then
		CreatureObject(pPlayer):sendSystemMessage("Wave " .. waveIdx .. " of " .. #spec.waves .. " — " .. #oids .. " attackers close in.")
	end

	JediParkManager:log(pPlayer, "wave [" .. tag .. "] " .. waveIdx .. "/" .. #spec.waves .. " up (" .. #oids .. " mobs)")

	if (#oids == 0) then
		-- Every spawn failed (bad template?) — never deadlock the quest.
		self:waveCleared(pPlayer, tag)
	end
end

-- KILLEDCREATURE on the owner. Return 0 keeps the observer, 1 drops it.
function JtpTheaters:onWaveKill(pPlayer, pVictim)
	if (pPlayer == nil or pVictim == nil) then
		return 0
	end

	if (not JediParkManager.enabled()) then
		return 0
	end

	local active = readStr(pPlayer, "wave_active")

	if (active == "") then
		return 1 -- nothing running anywhere: release the observer
	end

	local victimID = tostring(SceneObject(pVictim):getObjectID())

	for tag in string.gmatch(active, "[^,]+") do
		if (JTP_WAVE_SPECS[waveKey(pPlayer, tag)] == nil) then
			-- Persisted state without a spec = restart mid-wave: lapse it.
			self:stopWaves(pPlayer, tag)
		else
			local csv = readStr(pPlayer, "wave_" .. tag .. "_oids")
			local newCsv, removed = csvRemove(csv, victimID)

			if (removed) then
				writeVal(pPlayer, "wave_" .. tag .. "_oids", newCsv)

				if (newCsv == "") then
					self:waveCleared(pPlayer, tag)
				else
					local spec = JTP_WAVE_SPECS[waveKey(pPlayer, tag)]

					if (spec ~= nil and spec.announce ~= false) then
						CreatureObject(pPlayer):sendSystemMessage(csvCount(newCsv) .. " attacker(s) remain.")
					end
				end

				return 0
			end
		end
	end

	return 0
end

-- A wave's last attacker fell (or nothing spawned): advance or finish.
function JtpTheaters:waveCleared(pPlayer, tag)
	local spec = JTP_WAVE_SPECS[waveKey(pPlayer, tag)]

	if (spec == nil) then
		self:stopWaves(pPlayer, tag)
		return
	end

	local idx = readNum(pPlayer, "wave_" .. tag .. "_idx")
	local gen = readNum(pPlayer, "wave_" .. tag .. "_gen")

	if (idx >= #spec.waves) then
		if (spec.announce ~= false) then
			CreatureObject(pPlayer):sendSystemMessage("The last attacker falls. The ground is yours.")
		end

		-- Capture the callback BEFORE clearing state (clearing drops the spec).
		local play = nil
		local fn = nil

		if (spec.onComplete ~= nil) then
			play = spec.onComplete.screenplay or spec.onComplete[1]
			fn = spec.onComplete.fn or spec.onComplete[2]
		end

		JediParkManager:log(pPlayer, "wave [" .. tag .. "] complete")
		self:clearWaveState(pPlayer, tag)

		if (play ~= nil and fn ~= nil) then
			createEvent(2000, play, fn, pPlayer, tag)
		end
	else
		if (spec.announce ~= false) then
			CreatureObject(pPlayer):sendSystemMessage("Wave " .. idx .. " broken. Hold — more are coming.")
		end

		createEvent(2000, "JtpTheaters", "advanceWaveEvent", pPlayer, tag .. ":" .. gen .. ":" .. (idx + 1))
	end
end

-- 2s dramatic-delay hop between waves (internal, stale-fenced).
function JtpTheaters:advanceWaveEvent(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	local tag, gen, idx = string.match(arg, "^(.+):(%d+):(%d+)$")

	if (tag == nil) then
		return
	end

	if (tonumber(gen) ~= readNum(pPlayer, "wave_" .. tag .. "_gen")) then
		return -- a newer run owns this tag
	end

	if (not csvContains(readStr(pPlayer, "wave_active"), tag)) then
		return -- stopped/aborted meanwhile
	end

	self:spawnWave(pPlayer, tag, tonumber(idx))
end

-- Lapse timer: a still-running engagement past abortSec tears down and
-- clears state so the quest can re-offer (stale-fenced by generation;
-- a completed/stopped run is no longer in wave_active → no-op).
function JtpTheaters:onWaveAbort(pPlayer, arg)
	if (pPlayer == nil or arg == nil) then
		return
	end

	local tag, gen = string.match(arg, "^(.+):(%d+)$")

	if (tag == nil) then
		return
	end

	if (tonumber(gen) ~= readNum(pPlayer, "wave_" .. tag .. "_gen")) then
		return
	end

	if (not csvContains(readStr(pPlayer, "wave_active"), tag)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("The engagement has lapsed. The site falls quiet — the offer stands when you are ready.")
	JediParkManager:log(pPlayer, "wave [" .. tag .. "] aborted (timer)")
	self:stopWaves(pPlayer, tag)
end

-- Cancel a wave engagement: destroy outstanding attackers, clear all
-- state (the quest can re-offer). Safe when nothing is running; also the
-- stale-state janitor after a restart. Deliberately NOT galaxy-gated:
-- cleanup must never be refused.
function JtpTheaters:stopWaves(pPlayer, tag)
	if (pPlayer == nil or badTag(tag)) then
		return
	end

	local csv = readStr(pPlayer, "wave_" .. tag .. "_oids")

	for oid in string.gmatch(csv, "[^,]+") do
		local pMob = getSceneObject(tonumber(oid))

		if (pMob ~= nil) then
			SceneObject(pMob):destroyObjectFromWorld()
		end
	end

	self:clearWaveState(pPlayer, tag)
end

-- Internal: forget a tag (state + spec + observer when idle). The gen
-- counter is intentionally kept forever (monotonic stale-fencing).
function JtpTheaters:clearWaveState(pPlayer, tag)
	clearKey(pPlayer, "wave_" .. tag .. "_oids")
	clearKey(pPlayer, "wave_" .. tag .. "_idx")

	local active = csvRemove(readStr(pPlayer, "wave_active"), tag)

	if (active == "") then
		clearKey(pPlayer, "wave_active")
		dropObserver(KILLEDCREATURE, "JtpTheaters", "onWaveKill", pPlayer)
	else
		writeVal(pPlayer, "wave_active", active)
	end

	JTP_WAVE_SPECS[waveKey(pPlayer, tag)] = nil
end

-- Status for giver dialog: active(bool), waveIdx, remaining, totalWaves.
-- totalWaves is 0 when the spec was lost to a restart (treat as lapsed).
function JtpTheaters:waveStatus(pPlayer, tag)
	if (pPlayer == nil or badTag(tag) or not csvContains(readStr(pPlayer, "wave_active"), tag)) then
		return false, 0, 0, 0
	end

	local remaining = csvCount(readStr(pPlayer, "wave_" .. tag .. "_oids"))
	local spec = JTP_WAVE_SPECS[waveKey(pPlayer, tag)]
	local total = 0

	if (spec ~= nil) then
		total = #spec.waves
	end

	return true, readNum(pPlayer, "wave_" .. tag .. "_idx"), remaining, total
end
