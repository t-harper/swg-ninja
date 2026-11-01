-- jtp_ondel_handler.lua — conversation handler for Archivist Ondel.
-- The convo template (registered boot-only in custom_scripts/mobile/
-- jtp_ondel.lua) has a single empty auto-closing screen; ALL dialog is
-- SUI-driven from JediParkAct1:onOndelTalk so it hot-reloads with the
-- screenplays (Phase A placeholder-dialog contract).

jtpOndelConvoHandler = conv_handler:new {}

function jtpOndelConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct1 ~= nil) then
			JediParkAct1:onOndelTalk(pPlayer)
		end
	end

	return pConvScreen
end
