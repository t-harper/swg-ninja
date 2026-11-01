-- jtp_manager.lua — JediParkManager: progression predicates, act/quest
-- state helpers (per the jtp_config bit ledger), declarative access
-- evaluation, and reward dispatch. Pure logic — no spawns here.

JediParkManager = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JediParkManager", true)

function JediParkManager:start()
	if (not self.enabled()) then
		print("jtp: disabled on galaxy '" .. tostring(getGalaxyName()) .. "' — park inert")
		return
	end
	print("jtp: manager ready, census " .. JtpConfig.shrineTotal() .. " shrines listed")
end

function JediParkManager.enabled()
	return JtpConfig.enabled and JtpConfig.enabledGalaxies[getGalaxyName()] == true
end

-- ---- identity predicates ----------------------------------------------------

function JediParkManager:isJedi(pPlayer)
	return pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("jedi_padawan_novice")
end

-- 0 = no side yet, 1 = light, 2 = dark (journeyman novice is the earliest
-- signal; PRECLUSION makes the two mutually exclusive).
function JediParkManager:sideOf(pPlayer)
	if (pPlayer == nil) then
		return 0
	end
	if (CreatureObject(pPlayer):hasSkill("jedi_light_side_journeyman_novice")) then
		return 1
	elseif (CreatureObject(pPlayer):hasSkill("jedi_dark_side_journeyman_novice")) then
		return 2
	end
	return 0
end

function JediParkManager:isKnight(pPlayer)
	return pPlayer ~= nil and CreatureObject(pPlayer):hasSkill("force_title_jedi_rank_03")
end

-- FRS rank: -1 = not in FRS; 0..11 valid (0 = fresh knight).
function JediParkManager:frsRankOf(pPlayer)
	if (pPlayer == nil) then
		return -1
	end
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil) then
		return -1
	end
	if (PlayerObject(pGhost):getFrsCouncil() <= 0) then
		return -1
	end
	local rank = PlayerObject(pGhost):getFrsRank()
	if (rank < 0) then
		return -1
	end
	return rank
end

-- ---- quest-state helpers (bit ledger) ---------------------------------------

local function actState(act)
	return "JediParkAct" .. act
end

function JediParkManager:questStartedBit(quest)
	return 2 ^ (2 * quest - 2)
end

function JediParkManager:questDoneBit(quest)
	return 2 ^ (2 * quest - 1)
end

function JediParkManager:hasStarted(pPlayer, act, quest)
	return CreatureObject(pPlayer):hasScreenPlayState(self:questStartedBit(quest), actState(act))
end

function JediParkManager:hasDone(pPlayer, act, quest)
	return CreatureObject(pPlayer):hasScreenPlayState(self:questDoneBit(quest), actState(act))
end

function JediParkManager:setStarted(pPlayer, act, quest)
	CreatureObject(pPlayer):setScreenPlayState(self:questStartedBit(quest), actState(act))
end

function JediParkManager:setDone(pPlayer, act, quest)
	CreatureObject(pPlayer):setScreenPlayState(self:questDoneBit(quest), actState(act))
end

function JediParkManager:hasGlobal(pPlayer, bit)
	return CreatureObject(pPlayer):hasScreenPlayState(bit, "JediPark")
end

function JediParkManager:setGlobal(pPlayer, bit)
	CreatureObject(pPlayer):setScreenPlayState(bit, "JediPark")
end

-- ---- declarative access evaluation ------------------------------------------
-- conditions = { {permissionType="skill", skill="..."},
--                {permissionType="frsRank", minRank=n [, council=1|2]},
--                {permissionType="side", side=1|2},
--                {permissionType="actDone", act=n},
--                {permissionType="isJedi"}, {permissionType="isKnight"} }
-- AND semantics, themeParkLogic-familiar shape (extended types, our evaluator).

function JediParkManager:hasAccess(conditions, pPlayer)
	if (pPlayer == nil) then
		return false
	end

	for i = 1, #conditions, 1 do
		local c = conditions[i]

		if (c.permissionType == "skill") then
			if (not CreatureObject(pPlayer):hasSkill(c.skill)) then
				return false
			end
		elseif (c.permissionType == "frsRank") then
			local rank = self:frsRankOf(pPlayer)
			if (rank < (c.minRank or 0)) then
				return false
			end
			if (c.council ~= nil) then
				local pGhost = CreatureObject(pPlayer):getPlayerObject()
				if (pGhost == nil or PlayerObject(pGhost):getFrsCouncil() ~= c.council) then
					return false
				end
			end
		elseif (c.permissionType == "side") then
			if (self:sideOf(pPlayer) ~= c.side) then
				return false
			end
		elseif (c.permissionType == "actDone") then
			local actDoneBits = { [0] = 2, [1] = 4, [2] = 8, [3] = 64, [4] = 128, [5] = 256, [6] = 512 }
			if (not self:hasGlobal(pPlayer, actDoneBits[c.act])) then
				return false
			end
		elseif (c.permissionType == "isJedi") then
			if (not self:isJedi(pPlayer)) then
				return false
			end
		elseif (c.permissionType == "isKnight") then
			if (not self:isKnight(pPlayer)) then
				return false
			end
		end
	end

	return true
end

-- ---- reward dispatch --------------------------------------------------------

function JediParkManager:giveCredits(pPlayer, amount)
	CreatureObject(pPlayer):addCashCredits(amount, true)
	self:log(pPlayer, "credits +" .. amount)
end

function JediParkManager:awardJediXp(pPlayer, amount)
	CreatureObject(pPlayer):awardExperience("jedi_general", amount, true)
	self:log(pPlayer, "jedi_general +" .. amount)
end

function JediParkManager:awardFrsXp(pPlayer, amount)
	CreatureObject(pPlayer):awardExperience("force_rank_xp", amount, true)
	self:log(pPlayer, "force_rank_xp +" .. amount)
end

function JediParkManager:giveNamedItem(pPlayer, template, customName)
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return nil
	end
	local pItem = giveItem(pInventory, template, -1)
	if (pItem ~= nil and customName ~= nil and customName ~= "") then
		SceneObject(pItem):setCustomObjectName(customName)
	end
	self:log(pPlayer, "item " .. template)
	return pItem
end

function JediParkManager:giveLootGroup(pPlayer, group)
	local pInventory = SceneObject(pPlayer):getSlottedObject("inventory")
	if (pInventory == nil) then
		return
	end
	createLoot(pInventory, group, 0, false)
	self:log(pPlayer, "loot " .. group)
end

function JediParkManager:adjustVisibility(pPlayer, delta)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()
	if (pGhost == nil or delta == 0) then
		return
	end
	local vis = PlayerObject(pGhost):getVisibility()
	local newVis = math.max(0, vis + delta)
	PlayerObject(pGhost):setVisibility(newVis)
end

function JediParkManager:log(pPlayer, what)
	if (JtpConfig.debug) then
		print("jtp: [" .. SceneObject(pPlayer):getObjectID() .. "] " .. what)
	end
end
