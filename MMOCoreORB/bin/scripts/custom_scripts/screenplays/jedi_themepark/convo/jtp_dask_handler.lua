-- jtp_dask_handler.lua — conversation handler for Overseer Dask (Act III
-- dark enclave giver). The convo template (registered boot-only in
-- custom_scripts/mobile/jtp_dask.lua) has a single empty auto-closing
-- screen; ALL dialog is SUI-driven from JediParkAct3:onDaskTalk so it
-- hot-reloads with the screenplays (Phase A placeholder-dialog contract).

jtpDaskConvoHandler = conv_handler:new {}

function jtpDaskConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct3 ~= nil) then
			JediParkAct3:onDaskTalk(pPlayer)
		end
	end

	return pConvScreen
end
