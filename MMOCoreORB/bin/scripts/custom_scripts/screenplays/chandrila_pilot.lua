-- pre9: stardust pilot-planet screenplay. Round 1 pilot = HUTTA
-- (chandrila's terrain file is defective — deferred to terrain
-- surgery; see stardust/LEDGER.md). Spawns the starport transport so
-- the travel point links a shuttle at boot.
ChandrilaPilot = ScreenPlay:new {
	screenplayName = "ChandrilaPilot",
}

registerScreenPlay("ChandrilaPilot", true)

function ChandrilaPilot:start()
	if (isZoneEnabled("chandrila")) then
		spawnMobile("chandrila", "player_transport", 1, 164.0, 6.0, -2937.0, 0, 0)
		spawnMobile("chandrila", "player_transport", 1, -5248.3, 18.9, 281.2, 0, 0)
	end
end
