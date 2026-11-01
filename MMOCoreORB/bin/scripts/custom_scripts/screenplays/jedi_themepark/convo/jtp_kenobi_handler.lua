-- jtp_kenobi_handler.lua — conversation handler for the Kenobi apparition
-- (Q1.4 flagship scene). The convo template is registered boot-only in
-- custom_scripts/mobile/jtp_kenobi_spirit.lua; the four-screen dialog is
-- an SUI chain driven from JediParkAct1:onKenobiTalk, owner-guarded so
-- only the player the scene was staged for hears the voice.

jtpKenobiConvoHandler = conv_handler:new {}

function jtpKenobiConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct1 ~= nil) then
			JediParkAct1:onKenobiTalk(pPlayer, pNpc)
		end
	end

	return pConvScreen
end
