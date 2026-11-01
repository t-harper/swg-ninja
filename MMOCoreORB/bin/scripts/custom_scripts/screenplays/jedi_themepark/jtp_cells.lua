-- jtp_cells.lua — S-CORE-4: declarative permission-group claims on
-- VERIFIED-UNUSED cells, plus the login self-heal that keeps every
-- player's groups matched to their live progression.
--
-- Claim pattern is the Death Watch bunker one (deathWatchBunker.lua
-- setupPermissionGroups); condition shapes are JediParkManager:hasAccess
-- (skill / frsRank / side / actDone / isJedi / isKnight, AND semantics).
--
-- Two claim modes:
--   mode = "gate"  — full claim: the cell stops inheriting perms, its
--                    WALKIN defaults are cleared (nobody enters god-off),
--                    then ONLY rule.group may WALKIN (and never MOVEIN).
--   mode = "allow" — additive: existing perms untouched; rule.group is
--                    simply added as a WALKIN allow (the Ben's-hut case,
--                    where the stock lock stays authoritative for
--                    everyone else).
--
-- Wiring contract (the main loop owns the include + hook):
--   * this file loads AFTER jtp_manager.lua and BEFORE the act files;
--   * act files append rules AT LOAD TIME via JtpCells:register(rule);
--   * JtpObservers:onLogin calls JtpCells:heal(pPlayer) (the self-heal).
--
-- Reload/restart safety: JTP_CELL_RULES and JTP_CELLS_CLAIMED are
-- reload-guarded globals; claimAll() never runs twice; register() after
-- the initial claim (an act enabled via reloadscreenplays) claims its
-- cell immediately. Applying a claim twice is harmless (idempotent
-- container-permission writes), so a full restart just re-claims.

JtpCells = ScreenPlay:new {
	numberOfActs = 1,
}

registerScreenPlay("JtpCells", true)

-- Reload guard: nil until the first successful claim pass, then a map of
-- cellID -> true for every cell actually claimed.
JTP_CELLS_CLAIMED = JTP_CELLS_CLAIMED or nil

-- The declarative registry. Rule shape:
--   { cellID = <number>, group = "jtp_<site>_<tier>",
--     mode = "gate"|"allow",
--     conditions = { <JediParkManager:hasAccess entries> } }
--
-- The initial table is EMPTY by design: Act I's hut group stays
-- act-local (jtp_act1 owns Ben's-hut access end to end — do not
-- duplicate it here), and acts III+ append their rules at load time via
-- JtpCells:register().
JTP_CELL_RULES = JTP_CELL_RULES or {
	-- Example (shape reference only — not a real cell):
	-- { cellID = 1234567, group = "jtp_example_knight", mode = "gate",
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 1 },
	--   } },

	-- ===== VERIFIED Act III+ cells — ready to enable ======================
	-- WARNING: these six are the verified-UNUSED enclave wings ONLY. NEVER
	-- claim any OTHER enclave cell: the remaining wings are the live FRS
	-- rank-tier cells (rank 1-11 gating, FrsManager property) and claiming
	-- one would fight the FRS system for control of its permissions.
	--
	-- Light Enclave, dantooine — Act III light home cells (Q3.1L/Q6.1L):
	-- { cellID = 8525441, group = "jtp_lenclave_knight", mode = "gate", -- trainingroom (Keeper Maro)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 1 },
	--   } },
	-- { cellID = 8525440, group = "jtp_lenclave_knight", mode = "gate", -- traininghall (Act VI-L rite)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 1 },
	--   } },
	--
	-- Dark Enclave, yavin4 — Act III+ dark home cells (Q3.1D/Q3.8D/Q4.1D/Q6.1D):
	-- { cellID = 3435636, group = "jtp_denclave_knight", mode = "gate", -- arenahall (Overseer Dask)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 2 },
	--   } },
	-- { cellID = 3435635, group = "jtp_denclave_knight", mode = "gate", -- cloning (Q3.8D rite)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 2 },
	--   } },
	-- { cellID = 3435650, group = "jtp_denclave_knight", mode = "gate", -- council1 (the Hand's Voice)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 2 },
	--   } },
	-- { cellID = 3435651, group = "jtp_denclave_seat", mode = "gate", -- council2 (Act VI-D, seat tier)
	--   conditions = {
	--       { permissionType = "isKnight" },
	--       { permissionType = "side", side = 2 },
	--       { permissionType = "frsRank", minRank = 8, council = 2 },
	--   } },
}

function JtpCells:start()
	if (not JediParkManager.enabled()) then
		return
	end

	self:claimAll()
end

-- ---- registration -----------------------------------------------------------

-- Append (or replace) a rule. Act files call this at FILE SCOPE so the
-- rule exists before any start() runs. Re-including an act file
-- (reloadscreenplays) replaces its rules in place — the registry never
-- grows on reload. If the initial claim pass already happened (an act
-- enabled live via reload), the cell is claimed immediately.
function JtpCells:register(rule)
	if (rule == nil or rule.cellID == nil or rule.group == nil or type(rule.conditions) ~= "table") then
		printLuaError("JtpCells:register — malformed rule (need cellID, group, conditions)")
		return
	end

	if (rule.mode == nil) then
		rule.mode = "gate"
	end

	if (rule.mode ~= "gate" and rule.mode ~= "allow") then
		printLuaError("JtpCells:register — bad mode '" .. tostring(rule.mode) .. "' for cell " .. rule.cellID)
		return
	end

	local replaced = false

	for i = 1, #JTP_CELL_RULES, 1 do
		local r = JTP_CELL_RULES[i]

		if (r.cellID == rule.cellID and r.group == rule.group) then
			JTP_CELL_RULES[i] = rule
			replaced = true
			break
		end
	end

	if (not replaced) then
		table.insert(JTP_CELL_RULES, rule)
	end

	-- Late registration (after the boot claim pass): claim now so a
	-- reload-enabled act works without a restart. claimOne is idempotent,
	-- so re-applying a replaced rule is harmless.
	if (JTP_CELLS_CLAIMED ~= nil and JediParkManager.enabled()) then
		if (self:claimOne(rule)) then
			if (JTP_CELLS_CLAIMED[rule.cellID] == nil) then
				print("jtp: cells — late claim " .. rule.cellID .. " (" .. rule.group .. ")")
			end

			JTP_CELLS_CLAIMED[rule.cellID] = true
		end
	end
end

-- ---- claiming ---------------------------------------------------------------

-- Idempotent: the JTP_CELLS_CLAIMED reload guard makes double
-- reloadscreenplays a no-op; a full restart re-claims (harmless).
function JtpCells:claimAll()
	if (not JediParkManager.enabled()) then
		return
	end

	if (JTP_CELLS_CLAIMED ~= nil) then
		print("jtp: cells already claimed (reload) — skipping")
		return
	end

	JTP_CELLS_CLAIMED = {}
	local claimed = 0

	-- Every rule is applied (several groups may share one cell — gate
	-- writes compose); the boot count is UNIQUE cells claimed.
	for i = 1, #JTP_CELL_RULES, 1 do
		local rule = JTP_CELL_RULES[i]

		if (self:claimOne(rule)) then
			if (JTP_CELLS_CLAIMED[rule.cellID] == nil) then
				claimed = claimed + 1
			end

			JTP_CELLS_CLAIMED[rule.cellID] = true
		end
	end

	print("jtp: cells — " .. #JTP_CELL_RULES .. " rules, " .. claimed .. " claimed")
end

-- Apply one rule's container permissions. Returns true when the cell was
-- found and written. A nil cell (zone disabled, bad ID) is skipped and
-- logged — never a hard error.
function JtpCells:claimOne(rule)
	local pCell = getSceneObject(rule.cellID)

	if (pCell == nil) then
		print("jtp: cells — cell " .. rule.cellID .. " missing (getSceneObject nil), rule '" .. rule.group .. "' skipped")
		return false
	end

	if (rule.mode == "allow") then
		-- Additive only: whatever locked (or opened) this cell before
		-- stays authoritative; we merely add our allow group.
		SceneObject(pCell):setContainerAllowPermission(rule.group, WALKIN)
	else
		-- Full gate: the Death Watch claim, verbatim.
		SceneObject(pCell):setContainerInheritPermissionsFromParent(false)
		SceneObject(pCell):clearContainerDefaultDenyPermission(WALKIN)
		SceneObject(pCell):clearContainerDefaultAllowPermission(WALKIN)
		SceneObject(pCell):setContainerAllowPermission(rule.group, WALKIN)
		SceneObject(pCell):setContainerDenyPermission(rule.group, MOVEIN)
	end

	return true
end

-- ---- login self-heal --------------------------------------------------------

-- Re-evaluate EVERY rule for this player and add/remove the permission
-- groups to match live state (grants after offline progression, revokes
-- after demotion/surrender — §7.5 "LOGGEDIN self-heal"). Groups shared
-- by several rules use OR semantics: the player holds the group if ANY
-- rule carrying it passes. God mode passes everything (themeParkLogic
-- parity, keeps the gate matrix testable).
--
-- Safe for any player pointer; cheap (small rule list); call it from
-- JtpObservers:onLogin and after any quest step that changes access.
function JtpCells:heal(pPlayer)
	if (pPlayer == nil or not JediParkManager.enabled()) then
		return
	end

	if (#JTP_CELL_RULES == 0) then
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local god = PlayerObject(pGhost):hasGodMode()

	-- Pass 1: verdict per group (OR across the group's rules).
	local verdict = {}
	local order = {}

	for i = 1, #JTP_CELL_RULES, 1 do
		local rule = JTP_CELL_RULES[i]

		if (verdict[rule.group] == nil) then
			verdict[rule.group] = false
			table.insert(order, rule.group)
		end

		if (god or JediParkManager:hasAccess(rule.conditions, pPlayer)) then
			verdict[rule.group] = true
		end
	end

	-- Pass 2: converge the player's actual groups.
	for i = 1, #order, 1 do
		local group = order[i]
		local has = PlayerObject(pGhost):hasPermissionGroup(group)

		if (verdict[group] and not has) then
			PlayerObject(pGhost):addPermissionGroup(group, true)
			JediParkManager:log(pPlayer, "cell group +" .. group)
		elseif (not verdict[group] and has) then
			PlayerObject(pGhost):removePermissionGroup(group, true)
			JediParkManager:log(pPlayer, "cell group -" .. group)
		end
	end
end
