-- pre9_mando_stone.lua — the "Oyu'baat stone": the clan-rank system's
-- interaction terminal. Server-template clone of the stock guild
-- terminal (client already knows shared_terminal_guild.iff — zero
-- client work); the radial menu is replaced wholesale by the lua
-- component in screenplays/mando_rank/mando_rank_stone.lua.
--
-- BOOT-ONLY include (object tree). The component class itself lives in
-- the screenplays tree so all rank-system logic stays hot-reloadable;
-- referencing it here by name is late-bound (resolved per interaction).

pre9_mando_stone = object_tangible_terminal_shared_terminal_guild:new {
	objectMenuComponent = "MandoStoneMenuComponent",
}

ObjectTemplates:addTemplate(pre9_mando_stone, "object/tangible/terminal/pre9_mando_stone.iff")
