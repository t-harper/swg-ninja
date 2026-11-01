-- jtp_voice_handler.lua — conversation handler for The Hand's Voice,
-- the Act IV dark giver (dark enclave council1, cell 3435650).
-- The convo template (registered boot-only in custom_scripts/mobile/
-- jtp_voice.lua) has a single empty auto-closing screen; ALL dialog is
-- SUI-driven from JediParkAct4:onVoiceTalk so it hot-reloads with the
-- screenplays (Phase A placeholder-dialog contract).

jtpVoiceConvoHandler = conv_handler:new {}

function jtpVoiceConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		-- Most-progressed act first: VI (act V done) > V (act IV done) > IV.
		if (JediParkManager:hasGlobal(pPlayer, 256) and JediParkAct6 ~= nil) then
			JediParkAct6:onVoiceTalk(pPlayer)
		elseif (JediParkManager:hasGlobal(pPlayer, 128) and JediParkAct5 ~= nil) then
			JediParkAct5:onVoiceTalk(pPlayer)
		elseif (JediParkAct4 ~= nil) then
			JediParkAct4:onVoiceTalk(pPlayer)
		end
	end

	return pConvScreen
end
