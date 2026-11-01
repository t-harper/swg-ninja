-- pre9_hoth_statics.lua — round-2 slice 2 (Hoth activation).
-- Registers the frozen_tauntaun static (STAT) that the Hoth world snapshot
-- places. The client assets ship in ninja_assets_r1 (shared IFF + appearance
-- chain) + ninja_textures_r1 (textures); the client CRC table entry is added
-- by build_tre's staged-object scan. This half is the SERVER template: the
-- snapshot loader strips "shared_" and calls createObject on the non-shared
-- path, so without addTemplate here it returns null (now guarded + logged in
-- PlanetManagerImplementation::loadSnapshotObject, formerly a boot segfault).
-- addClientTemplate mirrors the stock static pattern (see campfire_fresh).

object_building_heroic_shared_frozen_tauntaun = SharedStaticObjectTemplate:new {
	clientTemplateFileName = "object/building/heroic/shared_frozen_tauntaun.iff"
}
ObjectTemplates:addClientTemplate(object_building_heroic_shared_frozen_tauntaun, "object/building/heroic/shared_frozen_tauntaun.iff")

object_building_heroic_frozen_tauntaun = object_building_heroic_shared_frozen_tauntaun:new {
}
ObjectTemplates:addTemplate(object_building_heroic_frozen_tauntaun, "object/building/heroic/frozen_tauntaun.iff")
