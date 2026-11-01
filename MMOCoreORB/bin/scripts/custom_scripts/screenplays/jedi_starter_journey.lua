-- A short, one-time starter journey for every character who learns
-- jedi_padawan_novice. It deliberately uses stock objects and persistent
-- screenplay data so it can run on both galaxies without a client archive.

JediStarterJourney = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "JediStarterJourney",

	planet = "tatooine",
	namespace = "JediStarterJourney",

	STAGE_NEW = 0,
	STAGE_QUIET = 1,
	STAGE_MATERIALS = 2,
	STAGE_RETURN = 3,
	STAGE_COMPLETE = 4,

	-- Sites are world-snapshot verified (snapshot/tatooine.ws): every area
	-- centre must sit in open sand, because an 18m trigger circle that
	-- overlaps a building footprint strands the waypoint inside geometry.
	-- The original quiet site (3422 -5020) sat 19.9m from the Mos Eisley
	-- cloning facility, with its circle inside the building and storage
	-- debris 5.2m away — and inside the city it was contradicting its own
	-- "outside Mos Eisley" prompt. The replacement is 119m clear of the
	-- nearest static and still inside mos_eisley_nobuild_1 (r900,
	-- NOWORLDSPAWNAREA), so a fresh padawan walks it unmolested.
	areas = {
		quiet = { x = 3200, y = -5058, radius = 18 },
		materials = { x = 3680, y = -5110, radius = 18 },
		returnToVokara = { x = 3508, y = -4806, radius = 20 },

		-- Migration: characters already on the quiet step are carrying a
		-- waypoint to the retired site, and nothing re-issues it. Keep the
		-- old circle live as a second trigger for the same step so they can
		-- still finish. Safe to delete once no character is mid-journey.
		quietLegacy = { x = 3422, y = -5020, radius = 18 },
	},

	-- Keep each waypoint's x/y identical to its area above: the marker is
	-- the only instruction the player gets.
	waypoints = {
		[1] = { x = 3200, y = -5058, name = "Vokara's First Lesson: Find Quiet", description = "Find a quiet place outside Mos Eisley and consider the path you have chosen." },
		[2] = { x = 3680, y = -5110, name = "Vokara's First Lesson: Materials", description = "Visit the materials cache prepared for a new Padawan." },
		[3] = { x = 3508, y = -4806, name = "Vokara's First Lesson: Return", description = "Return to Vokara outside Mos Eisley." },
	},

	resources = {
		{ key = "steel", className = "steel_carbonite", amount = 20 },
		{ key = "gemstone", className = "crystalline_vertex", amount = 40 },
		{ key = "copper", className = "copper_desh", amount = 12 },
	},

	toolTemplate = "object/tangible/crafting/station/jedi_tool.iff",
	saberTemplate = "object/weapon/melee/sword/crafted_saber/pre9_jedi_starter_lightsaber.iff",
	crystalTemplate = "object/tangible/component/weapon/lightsaber/lightsaber_module_force_crystal.iff",
}

registerScreenPlay("JediStarterJourney", true)

PRE9_JEDI_STARTER_AREAS = PRE9_JEDI_STARTER_AREAS or nil

function JediStarterJourney:start()
	if (PRE9_JEDI_STARTER_AREAS ~= nil or not isZoneEnabled(self.planet)) then
		return
	end

	PRE9_JEDI_STARTER_AREAS = {}
	self:spawnJourneyArea("quiet", self.areas.quiet)
	self:spawnJourneyArea("quiet", self.areas.quietLegacy)
	self:spawnJourneyArea("materials", self.areas.materials)
	self:spawnJourneyArea("return", self.areas.returnToVokara)

	print("pre9: Jedi starter journey ready (3 objectives + 1 legacy trigger, Fun + Dev)")
end

function JediStarterJourney:spawnJourneyArea(tag, spec)
	local z = getWorldFloor(spec.x, spec.y, self.planet) or 0
	local pArea = spawnActiveArea(self.planet, "object/active_area.iff", spec.x, z, spec.y, spec.radius, 0)

	if (pArea == nil) then
		printLuaError("JediStarterJourney could not spawn the '" .. tag .. "' active area")
		return
	end

	local areaID = SceneObject(pArea):getObjectID()
	writeStringData(areaID .. ":JediStarterJourney:tag", tag)
	createObserver(ENTEREDAREA, "JediStarterJourney", "onEnterJourneyArea", pArea)
	table.insert(PRE9_JEDI_STARTER_AREAS, areaID)
end

function JediStarterJourney:getStage(pPlayer)
	return tonumber(readScreenPlayData(pPlayer, self.namespace, "stage")) or self.STAGE_NEW
end

function JediStarterJourney:setStage(pPlayer, stage)
	writeScreenPlayData(pPlayer, self.namespace, "stage", tostring(stage))
end

function JediStarterJourney:getRewardState(pPlayer, key)
	return tonumber(readScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_state")) or 0
end

function JediStarterJourney:setRewardState(pPlayer, key, state)
	writeScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_state", tostring(state))
end

function JediStarterJourney:hasNovice(pPlayer)
	return pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("jedi_padawan_novice")
end

function JediStarterJourney:getInventory(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	return SceneObject(pPlayer):getSlottedObject("inventory")
end

function JediStarterJourney:hasInventorySlots(pPlayer, needed)
	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false
	end

	local inventory = SceneObject(pInventory)
	local free = inventory:getContainerVolumeLimit() - inventory:getCountableObjectsRecursive()

	if (free < needed) then
		CreatureObject(pPlayer):sendSystemMessage("Vokara's lesson is waiting, but you need " .. needed .. " free inventory slot(s) for its remaining reward.")
		return false
	end

	return true
end

function JediStarterJourney:showMessage(pPlayer, title, prompt)
	local sui = SuiMessageBox.new("JediStarterJourney", "emptyCallback")
	sui.setTitle(title)
	sui.setPrompt(prompt)
	sui.sendTo(pPlayer)
end

function JediStarterJourney:emptyCallback(pPlayer, pSui, eventIndex, args)
end

function JediStarterJourney:removeWaypoint(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	local waypointID = tonumber(readScreenPlayData(pPlayer, self.namespace, "waypoint_id")) or 0

	if (pGhost ~= nil and waypointID > 0) then
		PlayerObject(pGhost):removeWaypoint(waypointID, true)
	end

	writeScreenPlayData(pPlayer, self.namespace, "waypoint_id", "0")
end

function JediStarterJourney:setWaypointForStage(pPlayer, stage)
	local spec = self.waypoints[stage]
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (spec == nil or pGhost == nil) then
		return
	end

	self:removeWaypoint(pPlayer)

	local waypointID = PlayerObject(pGhost):addWaypoint(self.planet, spec.name, spec.description, spec.x, 0, spec.y, WAYPOINT_YELLOW, true, true, 0, 0)
	writeScreenPlayData(pPlayer, self.namespace, "waypoint_id", tostring(waypointID))
end

function JediStarterJourney:ensureWaypoint(pPlayer, stage)
	local waypointID = tonumber(readScreenPlayData(pPlayer, self.namespace, "waypoint_id")) or 0

	if (waypointID <= 0 or getSceneObject(waypointID) == nil) then
		self:setWaypointForStage(pPlayer, stage)
	end
end

function JediStarterJourney:offerIfEligible(pPlayer, args)
	if (pPlayer == nil or not self:hasNovice(pPlayer)) then
		return
	end

	local stage = self:getStage(pPlayer)

	if (stage == self.STAGE_NEW) then
		self:setStage(pPlayer, self.STAGE_QUIET)
		self:setWaypointForStage(pPlayer, self.STAGE_QUIET)
		self:showMessage(pPlayer, "Vokara's First Lesson", "A lightsaber begins before the blade. Leave the noise of Mos Eisley behind and seek the quiet place marked in your datapad. I have left your first tool there. — Vokara")
	elseif (stage >= self.STAGE_QUIET and stage <= self.STAGE_RETURN) then
		self:ensureWaypoint(pPlayer, stage)
	elseif (stage == self.STAGE_COMPLETE) then
		self:removeWaypoint(pPlayer)
	end
end

function JediStarterJourney:findNamedReward(pInventory, template, customName)
	if (pInventory == nil) then
		return nil
	end

	local inventory = SceneObject(pInventory)

	for i = 0, inventory:getContainerObjectsSize() - 1, 1 do
		local pItem = inventory:getContainerObject(i)

		if (pItem ~= nil and SceneObject(pItem):getTemplateObjectPath() == template and SceneObject(pItem):getCustomObjectName() == customName) then
			return pItem
		end
	end

	return nil
end

function JediStarterJourney:isNamedRewardDone(pPlayer, key, template, customName)
	if (self:getRewardState(pPlayer, key) == 2) then
		return true
	end

	local pInventory = self:getInventory(pPlayer)
	local objectID = tonumber(readScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_oid")) or 0
	local pItem = objectID > 0 and getSceneObject(objectID) or nil

	if (pItem == nil) then
		pItem = self:findNamedReward(pInventory, template, customName)
	end

	if (pItem ~= nil) then
		writeScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_oid", tostring(SceneObject(pItem):getObjectID()))
		self:setRewardState(pPlayer, key, 2)
		return true
	end

	return false
end

function JediStarterJourney:giveNamedReward(pPlayer, key, template, customName, initializeChildren)
	if (self:isNamedRewardDone(pPlayer, key, template, customName)) then
		return true
	end

	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false
	end

	self:setRewardState(pPlayer, key, 1)
	local pItem

	if (initializeChildren) then
		pItem = giveInitializedItem(pInventory, template, -1)
	else
		pItem = giveItem(pInventory, template, -1)
	end

	if (pItem == nil) then
		self:setRewardState(pPlayer, key, 0)
		return false
	end

	SceneObject(pItem):setCustomObjectName(customName)
	writeScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_oid", tostring(SceneObject(pItem):getObjectID()))
	self:setRewardState(pPlayer, key, 2)
	return true
end

function JediStarterJourney:giveNamedLootReward(pPlayer, key, lootGroup, level, customName)
	if (self:isNamedRewardDone(pPlayer, key, self.crystalTemplate, customName)) then
		return true
	end

	local pInventory = self:getInventory(pPlayer)

	if (pInventory == nil) then
		return false
	end

	self:setRewardState(pPlayer, key, 1)
	local objectID = createLoot(pInventory, lootGroup, level, false)
	local pItem = objectID ~= nil and objectID > 0 and getSceneObject(objectID) or nil

	if (pItem == nil) then
		self:setRewardState(pPlayer, key, 0)
		return false
	end

	SceneObject(pItem):setCustomObjectName(customName)
	writeScreenPlayData(pPlayer, self.namespace, "reward_" .. key .. "_oid", tostring(objectID))
	self:setRewardState(pPlayer, key, 2)
	return true
end

function JediStarterJourney:giveResourceReward(pPlayer, reward)
	local state = self:getRewardState(pPlayer, reward.key)

	if (state == 2) then
		return true
	end

	local baselineKey = "reward_" .. reward.key .. "_baseline"
	local baseline = tonumber(readScreenPlayData(pPlayer, self.namespace, baselineKey))

	if (baseline == nil) then
		baseline = getPlayerResourceQuantity(pPlayer, reward.className)
		writeScreenPlayData(pPlayer, self.namespace, baselineKey, tostring(baseline))
		self:setRewardState(pPlayer, reward.key, 1)
	end

	if (getPlayerResourceQuantity(pPlayer, reward.className) >= baseline + reward.amount) then
		self:setRewardState(pPlayer, reward.key, 2)
		return true
	end

	if (not givePlayerResource(pPlayer, reward.className, reward.amount)) then
		return false
	end

	if (getPlayerResourceQuantity(pPlayer, reward.className) < baseline + reward.amount) then
		return false
	end

	self:setRewardState(pPlayer, reward.key, 2)
	return true
end

function JediStarterJourney:completeQuietStep(pPlayer)
	if (self:getStage(pPlayer) ~= self.STAGE_QUIET or not self:hasNovice(pPlayer)) then
		return
	end

	if (not self:isNamedRewardDone(pPlayer, "tool", self.toolTemplate, "Vokara's Jedi Crafting Tool") and not self:hasInventorySlots(pPlayer, 1)) then
		return
	end

	if (not self:giveNamedReward(pPlayer, "tool", self.toolTemplate, "Vokara's Jedi Crafting Tool")) then
		CreatureObject(pPlayer):sendSystemMessage("Your Jedi crafting tool could not be delivered. Make inventory room and enter the marked area again.")
		return
	end

	self:setStage(pPlayer, self.STAGE_MATERIALS)
	self:setWaypointForStage(pPlayer, self.STAGE_MATERIALS)
	self:showMessage(pPlayer, "First Lesson: The Tool", "Stillness comes before construction. Keep this Jedi crafting tool with you. Now follow the second marker; there are materials there for two refined crystal packs.")
end

function JediStarterJourney:completeMaterialsStep(pPlayer)
	if (self:getStage(pPlayer) ~= self.STAGE_MATERIALS or not self:hasNovice(pPlayer)) then
		return
	end

	local remaining = 0

	for i = 1, #self.resources, 1 do
		if (self:getRewardState(pPlayer, self.resources[i].key) ~= 2) then
			remaining = remaining + 1
		end
	end

	if (remaining > 0 and not self:hasInventorySlots(pPlayer, remaining)) then
		return
	end

	for i = 1, #self.resources, 1 do
		if (not self:giveResourceReward(pPlayer, self.resources[i])) then
			CreatureObject(pPlayer):sendSystemMessage("The starter resources could not all be delivered. Make inventory room and enter the marked area again.")
			return
		end
	end

	self:setStage(pPlayer, self.STAGE_RETURN)
	self:setWaypointForStage(pPlayer, self.STAGE_RETURN)
	self:showMessage(pPlayer, "First Lesson: The Materials", "Steel gives the pack structure, gemstone gives it focus, and copper carries what must flow. You now have enough for two refined crystal packs. Return to me. — Vokara")
end

function JediStarterJourney:completeReturnStep(pPlayer)
	if (self:getStage(pPlayer) ~= self.STAGE_RETURN or not self:hasNovice(pPlayer)) then
		return
	end

	local rewards = {
		{ key = "saber", template = self.saberTemplate, name = "Vokara's First Lightsaber" },
		{ key = "color", template = self.crystalTemplate, name = "Vokara's First Color Crystal" },
		{ key = "power", template = self.crystalTemplate, name = "Vokara's Poor Power Crystal" },
	}
	local remaining = 0

	for i = 1, #rewards, 1 do
		if (not self:isNamedRewardDone(pPlayer, rewards[i].key, rewards[i].template, rewards[i].name)) then
			remaining = remaining + 1
		end
	end

	if (remaining > 0 and not self:hasInventorySlots(pPlayer, remaining)) then
		return
	end

	if (not self:giveNamedReward(pPlayer, "saber", self.saberTemplate, "Vokara's First Lightsaber", true)) then
		return
	end

	if (not self:giveNamedLootReward(pPlayer, "color", "color_crystals", 1, "Vokara's First Color Crystal")) then
		return
	end

	-- Loot level 1 maps directly to crystal itemLevel 1, which is always POOR.
	if (not self:giveNamedLootReward(pPlayer, "power", "power_crystals", 1, "Vokara's Poor Power Crystal")) then
		return
	end

	self:setStage(pPlayer, self.STAGE_COMPLETE)
	self:removeWaypoint(pPlayer)
	self:showMessage(pPlayer, "Vokara's First Lesson Complete", "A first-generation blade, a color crystal, and a modest power crystal are yours. Tune the crystals before fitting them. Use the tool and materials to make two refined crystal packs, and remember: understanding the pieces matters more than possessing the weapon.")
	CreatureObject(pPlayer):sendSystemMessage("Vokara's first lesson is complete. Your starter lightsaber supplies are in your inventory.")
end

function JediStarterJourney:onEnterJourneyArea(pArea, pPlayer)
	if (pArea == nil or pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	local tag = readStringData(SceneObject(pArea):getObjectID() .. ":JediStarterJourney:tag")

	if (tag == "quiet") then
		self:completeQuietStep(pPlayer)
	elseif (tag == "materials") then
		self:completeMaterialsStep(pPlayer)
	elseif (tag == "return") then
		self:completeReturnStep(pPlayer)
	end

	return 0
end

-- The stock trainer has no skill-awarded observer. Wrap only the successful
-- trainer path and defer the SUI until its conversation response has returned.
if (trainerConvHandler ~= nil and not trainerConvHandler._pre9JediStarterWrapped and trainerConvHandler.handleConfirmLearnScreen ~= nil) then
	local originalConfirmLearn = trainerConvHandler.handleConfirmLearnScreen

	trainerConvHandler.handleConfirmLearnScreen = function(handler, pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, trainerType, stringTable, skillList, skillNum)
		local hadNovice = pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("jedi_padawan_novice")
		local result = originalConfirmLearn(handler, pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen, trainerType, stringTable, skillList, skillNum)

		if (trainerType == "trainer_jedi" and pPlayer ~= nil and not hadNovice and CreatureObject(pPlayer):hasSkill("jedi_padawan_novice")) then
			createEvent(750, "JediStarterJourney", "offerIfEligible", pPlayer, "")
		end

		return result
	end

	trainerConvHandler._pre9JediStarterWrapped = true
end
