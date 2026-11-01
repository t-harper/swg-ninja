-- jtp_maro_handler.lua — conversation handler for Keeper Maro (Act III
-- light enclave giver). The convo template (registered boot-only in
-- custom_scripts/mobile/jtp_maro.lua) has a single empty auto-closing
-- screen; ALL dialog is SUI-driven from JediParkAct3:onMaroTalk so it
-- hot-reloads with the screenplays (Phase A placeholder-dialog contract).

jtpMaroConvoHandler = conv_handler:new {}

function jtpMaroConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		-- Most-progressed act first: VI (act V done) > V (act IV done) > III.
		if (JediParkManager:hasGlobal(pPlayer, 256) and JediParkAct6 ~= nil) then
			JediParkAct6:onMaroTalk(pPlayer)
		elseif (JediParkManager:hasGlobal(pPlayer, 128) and JediParkAct5 ~= nil) then
			JediParkAct5:onMaroTalk(pPlayer)
		elseif (JediParkAct3 ~= nil) then
			JediParkAct3:onMaroTalk(pPlayer)
		end
	end

	return pConvScreen
end
