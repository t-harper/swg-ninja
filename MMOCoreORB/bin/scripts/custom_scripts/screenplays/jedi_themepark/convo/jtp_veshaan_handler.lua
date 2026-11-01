-- jtp_veshaan_handler.lua — conversation handler for Sister Veshaan (Act
-- III light-line ally at the SMC stronghold). The convo template
-- (registered boot-only in custom_scripts/mobile/jtp_veshaan.lua) has a
-- single empty auto-closing screen; ALL dialog is SUI-driven from
-- JediParkAct3:onVeshaanTalk so it hot-reloads with the screenplays
-- (Phase A placeholder-dialog contract).

jtpVeshaanConvoHandler = conv_handler:new {}

function jtpVeshaanConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		-- Act VI first (returns true when it handled the talk), else Act III.
		if (JediParkAct6 == nil or not JediParkAct6:onVeshaanTalk(pPlayer)) then
			if (JediParkAct3 ~= nil) then
				JediParkAct3:onVeshaanTalk(pPlayer)
			end
		end
	end

	return pConvScreen
end
