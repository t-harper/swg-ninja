-- jtp_serenna_handler.lua — conversation handler for Serenna Vale, light
-- emissary of the Ember Circle (Act II giver, Massassi warroom).
-- The convo template (registered boot-only in custom_scripts/mobile/
-- jtp_serenna.lua) has a single empty auto-closing screen; ALL dialog is
-- SUI-driven from JediParkAct2:onSerennaTalk so it hot-reloads with the
-- screenplays (Phase A placeholder-dialog contract).

jtpSerennaConvoHandler = conv_handler:new {}

function jtpSerennaConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		-- Most-progressed act first: Act IV takes over once Act III is done.
		if (JediParkManager:hasGlobal(pPlayer, 64) and JediParkAct4 ~= nil) then
			JediParkAct4:onSerennaTalk(pPlayer)
		elseif (JediParkAct2 ~= nil) then
			JediParkAct2:onSerennaTalk(pPlayer)
		end
	end

	return pConvScreen
end
