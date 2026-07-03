-- pre9_city_frogs.lua — spawn character-builder (blue frog) terminals at
-- the three major starports. FUN-GALAXY ONLY: the swgemu-live instance
-- bind-mounts an empty stub over this file (plus a frog-less
-- player_creation_manager override and CharacterBuilderEnabled=false),
-- so galaxy 3 "SWG Ninja" never sees these spawns.
--
-- Coordinates are the planet_manager travel points offset a few meters
-- off each landing pad (proven ground heights).

Pre9CityFrogs = ScreenPlay:new {
	screenplayName = "Pre9CityFrogs",

	terminals = {
		-- { zone, x, z, y, heading }
		{ "tatooine", 3605.9, 5, -4775.4, math.rad(225) },   -- Mos Eisley Starport
		{ "corellia", -60.8, 28, -4705.3, math.rad(225) },   -- Coronet Starport
		{ "naboo", -4852.8, 6, 4170.1, math.rad(45) },       -- Theed Spaceport
	},
}

registerScreenPlay("Pre9CityFrogs", true)

function Pre9CityFrogs:start()
	local count = 0

	for _, t in ipairs(self.terminals) do
		if isZoneEnabled(t[1]) then
			spawnSceneObject(t[1],
				"object/tangible/terminal/terminal_character_builder.iff",
				t[2], t[3], t[4], 0, t[5])
			count = count + 1
		end
	end

	print("pre9_city_frogs: spawned " .. count .. " blue frog terminals at starports")
end
