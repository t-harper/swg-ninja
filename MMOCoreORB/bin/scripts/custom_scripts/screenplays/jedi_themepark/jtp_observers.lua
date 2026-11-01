-- jtp_observers.lua — global login hook + self-heal for the park.
--
-- The engine calls JediManager:onPlayerLoggedIn for EVERY login
-- (JediManager.cpp:92 -> lua "JediManager"), and with
-- jediProgressionType = NOJEDIPROGRESSION that function is a stock no-op
-- stub — so wrapping it is a zero-behavior-change global login hook.
-- Guarded with a marker so reloadscreenplays never double-wraps
-- (mando_rank_observers idiom).

JtpObservers = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JtpObservers", true)

function JtpObservers:start()
	if (not JediParkManager.enabled()) then
		return
	end
	self:wrapLoginHook()
end

function JtpObservers:wrapLoginHook()
	if (JediManager == nil) then
		print("jtp: WARNING — JediManager not present, no login hook")
		return
	end

	if (JediManager._jtpWrapped) then
		return
	end

	local originalLoggedIn = JediManager.onPlayerLoggedIn

	JediManager.onPlayerLoggedIn = function(mgr, pCreature)
		originalLoggedIn(mgr, pCreature)

		if (pCreature ~= nil and JediParkManager.enabled()) then
			JtpObservers:onLogin(pCreature)
		end
	end

	JediManager._jtpWrapped = true
	print("jtp: JediManager login hook wrapped")
end

function JtpObservers:onLogin(pPlayer)
	if (not SceneObject(pPlayer):isPlayerCreature()) then
		return
	end

	-- Cell permission self-heal runs before the Jedi gate so an ex-Jedi
	-- also gets stale groups revoked (JtpCells:heal is self-gating).
	JtpCells:heal(pPlayer)

	if (JediParkAct1 ~= nil) then
		JediParkAct1:heal(pPlayer)
	end

	if (JediParkAct3 ~= nil) then
		JediParkAct3:heal(pPlayer)
	end

	if (JediParkAct5 ~= nil) then
		JediParkAct5:heal(pPlayer)
	end

	if (JediParkAct6 ~= nil) then
		JediParkAct6:heal(pPlayer)
	end

	if (not JediParkManager:isJedi(pPlayer)) then
		return
	end

	-- Act 0 nudge: a trained padawan who has never met the Wanderer hears
	-- about him shortly after login.
	if (not JediParkManager:hasGlobal(pPlayer, 1)) then
		createEvent(10 * 1000, "JtpObservers", "sendWandererNudge", pPlayer, "")
	end
end

function JtpObservers:sendWandererNudge(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (JediParkManager:hasGlobal(pPlayer, 1) or not JediParkManager:isJedi(pPlayer)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("A traveler's rumor: a hooded old man near the Aurilia village on Dathomir has been asking after someone of your description. Nobody remembers his face.")
end
