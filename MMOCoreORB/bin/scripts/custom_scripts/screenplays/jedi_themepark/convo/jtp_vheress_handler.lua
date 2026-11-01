-- jtp_vheress_handler.lua — conversation handler for Adjunct Vheress, the
-- Empire's shadow-recruitment emissary (Act II giver, Massassi warroom;
-- the rival first glimpsed on the Kenobi trail — S-CORE-9 continuity).
-- The convo template (registered boot-only in custom_scripts/mobile/
-- jtp_vheress_emissary.lua) has a single empty auto-closing screen; ALL
-- dialog is SUI-driven from JediParkAct2:onVheressTalk so it hot-reloads
-- with the screenplays (Phase A placeholder-dialog contract).

jtpVheressConvoHandler = conv_handler:new {}

function jtpVheressConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct2 ~= nil) then
			JediParkAct2:onVheressTalk(pPlayer)
		end
	end

	return pConvScreen
end
