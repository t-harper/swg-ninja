-- pre9_armor_certs.lua — remove the Mandalorian armor profession lock.
-- Stock gates every piece behind certificationsRequired = { master BH,
-- master Commando, master Squad Leader, master Ranger } (the era's only
-- certified armor set); enforcement is PlayerContainerComponent's
-- equip-time template read ("You lack the skill to use this item."), so
-- clearing the registered template frees already-spawned pieces too.
-- Mutate-in-place + re-register like the other injectors.

local PIECES = {
	"belt", "bicep_l", "bicep_r", "bracer_l", "bracer_r",
	"chest_plate", "gloves", "helmet", "leggings", "shoes",
}

local cleared = 0

for _, p in ipairs(PIECES) do
	local path = "object/tangible/wearables/armor/mandalorian/armor_mandalorian_" .. p .. ".iff"
	local t = ObjectTemplates[crcString(path)]

	if t ~= nil then
		t.certificationsRequired = {}
		ObjectTemplates:addTemplate(t, path)
		cleared = cleared + 1
	else
		print("pre9_armor_certs: MISSING template " .. path)
	end
end

print("pre9_armor_certs: cleared profession certs on " .. cleared .. "/10 mandalorian pieces")
