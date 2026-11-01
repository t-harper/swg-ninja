-- jtp_sereth_handler.lua — conversation handler for Envoy Sereth (Act III
-- dark-line ally on the Nightsister stronghold approach). The convo
-- template (registered boot-only in custom_scripts/mobile/jtp_sereth.lua)
-- has a single empty auto-closing screen; ALL dialog is SUI-driven from
-- JediParkAct3:onSerethTalk so it hot-reloads with the screenplays
-- (Phase A placeholder-dialog contract).

jtpSerethConvoHandler = conv_handler:new {}

function jtpSerethConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct3 ~= nil) then
			JediParkAct3:onSerethTalk(pPlayer)
		end
	end

	return pConvScreen
end
