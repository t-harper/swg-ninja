-- jtp_sarov_handler.lua — conversation handler for Master Sarov, the
-- Fallen (Act V light line: Q5.4L parley, Q5.6L redemption finale). The
-- convo template (registered boot-only in custom_scripts/mobile/
-- jtp_sarov.lua) has a single empty auto-closing screen; ALL dialog is
-- SUI-driven from JediParkAct5:onSarovTalk so it hot-reloads with the
-- screenplays (Phase A placeholder-dialog contract).
--
-- pNpc is passed through: Sarov exists only as per-player theater spawns,
-- and the act router uses it to refuse someone else's staged Master.

jtpSarovConvoHandler = conv_handler:new {}

function jtpSarovConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct5 ~= nil) then
			JediParkAct5:onSarovTalk(pPlayer, pNpc)
		end
	end

	return pConvScreen
end
