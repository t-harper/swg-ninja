-- jtp_givers.lua — persistent park NPCs and props, spawn-guarded so
-- reloadscreenplays/restarts never duplicate them.
--
-- Phase A roster: The Wanderer (Aurilia) + the archivist's cache prop
-- (Q0.2). More givers arrive with their acts.

JtpGivers = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JtpGivers", true)

JTP_GIVERS_SPAWNED = JTP_GIVERS_SPAWNED or nil

function JtpGivers:start()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_GIVERS_SPAWNED ~= nil) then
		print("jtp: givers already spawned (reload) — skipping")
		return
	end

	JTP_GIVERS_SPAWNED = {}

	local w = JtpConfig.wanderer

	if (isZoneEnabled(w.planet)) then
		local pWanderer = spawnMobile(w.planet, "jtp_wanderer", 0, w.x, w.z, w.y, w.heading, 0)

		if (pWanderer ~= nil) then
			table.insert(JTP_GIVERS_SPAWNED, SceneObject(pWanderer):getObjectID())
			print("jtp: Wanderer posted at " .. w.planet .. " " .. w.x .. " " .. w.y)
		else
			print("jtp: WARNING — Wanderer spawn failed")
		end

		local c = JtpConfig.act0.cache
		local pCache = spawnSceneObject(c.planet, JtpConfig.items.cacheProp, c.x, c.z, c.y, 0, 1, 0, 0, 0)

		if (pCache ~= nil) then
			SceneObject(pCache):setObjectMenuComponent("JtpCacheMenuComponent")
			table.insert(JTP_GIVERS_SPAWNED, SceneObject(pCache):getObjectID())
			print("jtp: archivist cache placed")
		else
			print("jtp: WARNING — cache prop spawn failed (" .. JtpConfig.items.cacheProp .. ")")
		end
	end
end
