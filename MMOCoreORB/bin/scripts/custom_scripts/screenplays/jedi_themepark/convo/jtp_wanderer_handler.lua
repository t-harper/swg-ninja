-- jtp_wanderer_handler.lua — conversation handler for The Wanderer.
-- The convo template (registered boot-only in custom_scripts/mobile/
-- jtp_wanderer.lua) has a single empty auto-closing screen; ALL dialog is
-- SUI-driven from JediParkAct0:onWandererTalk so it hot-reloads with the
-- screenplays (Phase A placeholder-dialog contract).

jtpWandererConvoHandler = conv_handler:new {}

function jtpWandererConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	local screen = LuaConversationScreen(pConvScreen)

	if (screen:getScreenID() == "init" and pPlayer ~= nil) then
		if (JediParkAct0 ~= nil) then
			JediParkAct0:onWandererTalk(pPlayer)
		end
	end

	return pConvScreen
end
