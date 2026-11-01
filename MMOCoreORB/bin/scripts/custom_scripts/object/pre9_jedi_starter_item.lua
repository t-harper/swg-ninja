-- A server-side starter saber that reuses the stock first-generation client
-- appearance and crystal inventory, but accepts the generic one-handed saber
-- certification granted by jedi_padawan_novice.

local basePath = "object/weapon/melee/sword/crafted_saber/sword_lightsaber_one_handed_gen1.iff"
local starterPath = "object/weapon/melee/sword/crafted_saber/pre9_jedi_starter_lightsaber.iff"
local baseTemplate = ObjectTemplates[crcString(basePath)]

if (baseTemplate == nil) then
	print("pre9_jedi_starter_item: missing base saber template " .. basePath)
else
	local starterTemplate = {}

	-- Copy the raw server fields so childObjects and experimental data survive
	-- the template reader; keep the same shared client template via its metatable.
	for key, value in pairs(baseTemplate) do
		starterTemplate[key] = value
	end

	setmetatable(starterTemplate, getmetatable(baseTemplate))
	starterTemplate.certificationsRequired = { "cert_onehandlightsaber" }

	ObjectTemplates:addTemplate(starterTemplate, starterPath)
	print("pre9_jedi_starter_item: registered novice-certified first-generation saber")
end
