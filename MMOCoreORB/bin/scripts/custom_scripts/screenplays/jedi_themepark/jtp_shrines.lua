-- jtp_shrines.lua — force-shrine census check, per-shrine ActiveArea
-- visit credits, and the lifetime pilgrimage tracker (S-CORE-2/3).
--
-- Areas are spawned at each shrine object's TRUE world position (read from
-- the live object, census coords are reference-only). Visit credits are
-- suppressed while the player is on Padawan/Knight Trials so the park never
-- collides with the Meditate-driven trials flow.

JtpShrines = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JtpShrines", true)

-- Reload guard: globals survive reloadscreenplays; never respawn areas.
JTP_SHRINE_AREAS = JTP_SHRINE_AREAS or nil

function JtpShrines:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_SHRINE_AREAS ~= nil) then
		print("jtp: shrine areas already spawned (reload) — skipping")
		return
	end

	JTP_SHRINE_AREAS = {}
	local ok, missing = 0, 0

	for p = 1, #JtpConfig.shrinePlanets, 1 do
		local planet = JtpConfig.shrinePlanets[p]

		if (isZoneEnabled(planet)) then
			local ids = JtpConfig.shrines[planet]

			for i = 1, #ids, 1 do
				local pShrine = getSceneObject(ids[i])

				if (pShrine == nil) then
					missing = missing + 1
					print("jtp: MISSING shrine " .. ids[i] .. " on " .. planet)
				else
					local x = SceneObject(pShrine):getWorldPositionX()
					local z = SceneObject(pShrine):getWorldPositionZ()
					local y = SceneObject(pShrine):getWorldPositionY()

					local pArea = spawnActiveArea(planet, "object/active_area.iff", x, z, y, JtpConfig.shrineAreaRadius, 0)

					if (pArea ~= nil) then
						local areaID = SceneObject(pArea):getObjectID()
						writeStringData(areaID .. ":jtpShrinePlanet", planet)
						writeData(areaID .. ":jtpShrineIndex", i)
						createObserver(ENTEREDAREA, "JtpShrines", "onEnterShrine", pArea)
						table.insert(JTP_SHRINE_AREAS, areaID)
						ok = ok + 1
					end
				end
			end
		end
	end

	print("jtp: shrine census — " .. ok .. " areas live, " .. missing .. " missing, " .. JtpConfig.shrineTotal() .. " listed")
end

-- ---- visit credit -----------------------------------------------------------

function JtpShrines:onEnterShrine(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not JediParkManager.enabled() or not JediParkManager:isJedi(pPlayer)) then
		return 0
	end

	-- Never interleave with the trials' own shrine flow.
	if (JediTrials ~= nil and (JediTrials:isOnPadawanTrials(pPlayer) or JediTrials:isOnKnightTrials(pPlayer))) then
		return 0
	end

	local areaID = SceneObject(pArea):getObjectID()
	local planet = readStringData(areaID .. ":jtpShrinePlanet")
	local index = readData(areaID .. ":jtpShrineIndex")

	if (planet == nil or planet == "" or index == nil or index == 0) then
		return 0
	end

	-- EVERY-ENTRY hooks (revisits count) — these MUST run before the
	-- lifetime-visit dedup return below: the E-R vigil, Act VI's
	-- contested-wells rotation, and Act V's pick-a-shrine beats all
	-- operate on already-walked wells. All are nil-safe and self-gating.
	if (JediParkRepeat ~= nil) then
		JediParkRepeat:onShrineEntered(pPlayer, planet, index)
	end
	if (JediParkAct6 ~= nil) then
		JediParkAct6:onShrineEntered(pPlayer, planet, index)
	end
	if (JediParkAct5 ~= nil) then
		JediParkAct5:onShrineVisited(pPlayer)
	end

	if (self:hasVisited(pPlayer, planet, index)) then
		return 0
	end

	self:markVisited(pPlayer, planet, index)
	JediParkManager:adjustVisibility(pPlayer, JtpConfig.visibility.quietStep)

	local total = self:countVisited(pPlayer)
	CreatureObject(pPlayer):sendSystemMessage("The old stones acknowledge you. (" .. total .. " of " .. JtpConfig.shrineTotal() .. " Force shrines walked)")

	-- Act hooks (optional, defined when their act is loaded).
	if (JediParkAct0 ~= nil) then
		JediParkAct0:onShrineVisited(pPlayer)
	end
	if (JediParkAct1 ~= nil) then
		JediParkAct1:onShrineVisited(pPlayer)
	end
	if (JediParkAct2 ~= nil) then
		JediParkAct2:onShrineVisited(pPlayer)
	end
	if (JediParkAct3 ~= nil) then
		JediParkAct3:onShrineVisited(pPlayer)
	end
	if (JediParkAct4 ~= nil) then
		JediParkAct4:onShrineVisited(pPlayer)
	end

	return 0
end

-- ---- per-planet visit bitmasks (arithmetic bit ops — lua-version safe) ------

local function hasBit(value, bit)
	return math.floor(value / bit) % 2 == 1
end

function JtpShrines:hasVisited(pPlayer, planet, index)
	local mask = tonumber(readScreenPlayData(pPlayer, "JediPark", "shrines_" .. planet)) or 0
	return hasBit(mask, 2 ^ (index - 1))
end

function JtpShrines:markVisited(pPlayer, planet, index)
	local mask = tonumber(readScreenPlayData(pPlayer, "JediPark", "shrines_" .. planet)) or 0
	local bit = 2 ^ (index - 1)
	if (not hasBit(mask, bit)) then
		writeScreenPlayData(pPlayer, "JediPark", "shrines_" .. planet, mask + bit)
	end
end

function JtpShrines:countVisitedOnPlanet(pPlayer, planet)
	local mask = tonumber(readScreenPlayData(pPlayer, "JediPark", "shrines_" .. planet)) or 0
	local n, bit = 0, 1
	for i = 1, #JtpConfig.shrines[planet], 1 do
		if (hasBit(mask, bit)) then
			n = n + 1
		end
		bit = bit * 2
	end
	return n
end

function JtpShrines:countVisited(pPlayer)
	local n = 0
	for p = 1, #JtpConfig.shrinePlanets, 1 do
		n = n + self:countVisitedOnPlanet(pPlayer, JtpConfig.shrinePlanets[p])
	end
	return n
end
