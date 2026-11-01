-- Run from MMOCoreORB: lua tests/local/space_spawning/spawning_spec.lua
-- The actual screenplay runs below. Only Core3 world/observer/event/storage APIs
-- are doubled; no test ships are created in a game server.
local sourcePath = os.getenv("SPACE_SPAWNER_SOURCE") or "bin/scripts/screenplays/space/spawning/space_spawner.lua"
local source = assert(io.open(sourcePath)):read("*a")
local nextConstant = 1
for name in source:gmatch("SHIP_[%w_]+") do
 if _G[name] == nil then _G[name] = nextConstant; nextConstant = nextConstant + 1 end
end
SHIP_SPAWN_SINGLE = nextConstant
SHIPDESTROYED, DESTINATIONREACHED, LT_ERROR = 1, 2, 3
ScreenPlay = {}
function ScreenPlay:new(object) self.__index = self; return setmetatable(object or {}, self) end
function registerScreenPlay() end
local world, memory, strings, vectors, events, attempts, fail, warnings, rngMax, nextID
local methods = {}
function methods:getObjectID() return self.id end
function methods:isShipAiAgent() return true end
function methods:isShipDestroyed() return self.destroyed end
function methods:setDespawnOnNoPlayerInRange(value) self.despawn = value end
function methods:setFixedPatrol() self.patrol = "fixed" end
function methods:setRandomPatrol() self.patrol = "random" end
function methods:setSinglePatrolRotation() self.single = true end
function methods:setGuardPatrol() self.patrol = "guard" end
function methods:setMinimumGuardPatrol(value) self.minGuard = value end
function methods:setMaximumGuardPatrol(value) self.maxGuard = value end
function methods:addFixedPatrolPoint(name)
 assert(name ~= nil, "production attempted to assign a nil patrol point")
 table.insert(self.points, name)
end
function methods:createSquadron() self.squadron = {self} end
function methods:assignToSquadron(leader)
 assert(leader.squadron, "missing squadron leader")
 self.squadron = leader.squadron; table.insert(self.squadron, self)
end
function methods:setHyperspacing(value) self.hyperspacing = value end
function methods:getSpawnPointInFrontOfShip() return {10,20,30} end
function methods:setPosition(x,z,y) self.departure = {x,z,y} end
function SceneObject(object) return assert(object, "nil SceneObject") end
function ShipAiAgent(object) return assert(object, "nil ShipAiAgent") end
function ShipObject(object) return assert(object, "nil ShipObject") end
function getSceneObject(id) return world[tonumber(id)] end
function getRandomNumber(a,b)
 if b == nil then return rngMax and a or 1 end
 assert(a <= b, "reversed random interval")
 return rngMax and b or a
end
function isZoneEnabled() return true end
function writeData(key,value) memory[key] = value end
function readData(key) return memory[key] or 0 end
function deleteData(key) memory[key] = nil end
function writeStringData(key,value) strings[key] = value end
function readStringData(key) return strings[key] or "" end
function deleteStringData(key) strings[key] = nil end
function writeStringVectorSharedMemory(key,value)
 vectors[key] = {}; for i,v in ipairs(value) do vectors[key][i] = tostring(v) end
end
function readStringVectorSharedMemory(key)
 local result = {}; for i,v in ipairs(vectors[key] or {}) do result[i] = v end; return result
end
function deleteStringVectorSharedMemory(key) vectors[key] = nil end
function createObserver(kind,play,callback,object) object.observers[kind] = callback end
function dropObserver(kind,play,callback,object)
 if object.observers[kind] == callback then object.observers[kind] = nil end
end
function createEvent(delay,play,callback,object,args)
 assert(delay > 0, "events must have a positive delay")
 table.insert(events, {delay=delay,play=play,callback=callback,object=object,args=args})
end
Logger = {log=function(self,message) table.insert(warnings,message) end}
function spawnShipAgent(name,zone,x,z,y)
 attempts[name] = (attempts[name] or 0) + 1
 if fail[name] == true or (type(fail[name]) == "number" and attempts[name] <= fail[name]) then return nil end
 nextID = nextID + 1
 local object = setmetatable({id=nextID,name=name,points={},observers={},destroyed=false},{__index=methods})
 world[nextID] = object
 return object
end
dofile(sourcePath)
local function reset()
 world,memory,strings,vectors,events,attempts,fail,warnings = {},{},{},{},{},{},{},{}
 rngMax,nextID = false,100
end
local function eq(actual,expected,message)
 assert(actual == expected,(message or "unexpected value")..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function countShips() local n=0; for _ in pairs(world) do n=n+1 end; return n end
local function cohortShips() local ships={}; for _,s in pairs(world) do ships[#ships+1]=s end; table.sort(ships,function(a,b) return a.id<b.id end); return ships end
local function makePlay(squadron,explicitLeader)
 local spawn = {spawnName="fixture",spawnType=squadron and SHIP_SPAWN_SQUADRON or SHIP_SPAWN_SINGLE,x=0,z=0,y=0,
  minSpawnDistance=10,maxSpawnDistance=20,patrolType=SHIP_AI_SINGLE_PATROL_ROTATION,patrolsToAssign=2,
  fixedPatrolPoints={"p1","p2","p3"},minRespawn=60,maxRespawn=120,totalSpawns=1,
  shipSpawns=squadron and (explicitLeader and {"fixture_squad","commander"} or {"fixture_squad"}) or {"civilian"}}
 return SpaceSpawnerScreenPlay:new{screenplayName="FixturePlay",spaceZone="space_fixture",shipSpawns={spawn},
  squadronsShips={fixture_squad={1,{"wing_a","wing_b"}}}}
end
local function runNext(play,callback)
 for i,e in ipairs(events) do
  if not callback or e.callback==callback then
   table.remove(events,i); assert(play[e.callback],"unknown callback "..e.callback);play[e.callback](play,e.object,e.args);return e
  end
 end
 error("no scheduled "..tostring(callback).." event")
end
local function replacements()
 local n=0;for _,e in ipairs(events) do if e.callback=="spawnShipSquadron" or e.callback=="spawnShipAgent" then n=n+1 end end;return n
end
local function destroy(play,ship,size)
 ship.destroyed=true;play:squadronShipDestroyed(ship,nil,size)
end
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
-- Removing the +1 start bound must exclude p6 and fail this real-method test.
test("final authored waypoint is eligible",function()
 local play=makePlay(false);local ship=spawnShipAgent("fixture");rngMax=true
 play:assignFixedPatrolpoints(ship,5,{"p1","p2","p3","p4","p5","p6"})
 eq(table.concat(ship.points,","),"p2,p3,p4,p5,p6")
end)
test("short patrol lists add each available waypoint once",function()
 local play=makePlay(false);local ship=spawnShipAgent("fixture")
 play:assignFixedPatrolpoints(ship,5,{"p1","p2"});eq(table.concat(ship.points,","),"p1,p2")
end)
test("empty and zero-count patrols are harmless",function()
 local play=makePlay(false);local ship=spawnShipAgent("fixture")
 play:assignFixedPatrolpoints(ship,5,{});play:assignFixedPatrolpoints(ship,0,{"p1"});eq(#ship.points,0)
end)
for _,explicit in ipairs({false,true}) do
 test("single-pass squadron flags and one leader observer; explicit="..tostring(explicit),function()
  local play=makePlay(true,explicit);play:spawnShipSquadron(nil,"1")
  eq(countShips(),explicit and 3 or 2)
  local observers=0
  for _,ship in pairs(world) do
   eq(ship.patrol,"fixed");eq(ship.single,true);eq(ship.despawn,false)
   if ship.observers[DESTINATIONREACHED] then observers=observers+1 end
  end
  eq(observers,1)
 end)
end
test("convoy completion removes every member and schedules one replacement",function()
 local play=makePlay(true);play:spawnShipSquadron(nil,"1");local ships=cohortShips()
 play:squadronDestinationReached(ships[1]);play:squadronDestinationReached(ships[1])
 eq(replacements(),1)
 for _,ship in ipairs(ships) do
  eq(ship.hyperspacing,true);eq(readData(ship.id..":SpawnerIndex:"),0);eq(ship.observers[SHIPDESTROYED],nil)
  eq(ship.observers[DESTINATIONREACHED],nil)
 end
 eq(next(memory),nil,"cohort numeric data must be cleaned");eq(next(strings),nil);eq(next(vectors),nil)
end)
test("queued destruction after convoy cleanup cannot schedule another fleet",function()
 local play=makePlay(true);play:spawnShipSquadron(nil,"1");local ships=cohortShips()
 play:squadronDestinationReached(ships[1]);eq(ships[1].hyperspacing,true);destroy(play,ships[2],1);eq(replacements(),1)
end)
test("destroyed leader transfers completion to a surviving member",function()
 local play=makePlay(true,true);play:spawnShipSquadron(nil,"1");local ships=cohortShips()
 destroy(play,ships[1],3);eq(replacements(),0)
 eq(ships[2].observers[DESTINATIONREACHED],"squadronDestinationReached")
 play:squadronDestinationReached(ships[1]);eq(replacements(),0,"stale leader callback")
 play:squadronDestinationReached(ships[2]);eq(replacements(),1)
end)
test("last member destruction is idempotent and releases cohort state",function()
 local play=makePlay(true);play:spawnShipSquadron(nil,"1");local ships=cohortShips()
 destroy(play,ships[1],2);destroy(play,ships[2],1);destroy(play,ships[2],1)
 eq(replacements(),1);eq(next(memory),nil);eq(next(strings),nil);eq(next(vectors),nil)
end)
test("failed single spawn retries and recovers",function()
 local play=makePlay(false);fail.civilian=1;play:spawnShipAgent(nil,"1");eq(#events,1)
 assert(events[1].delay>=1000,"retry must not spin");runNext(play);eq(countShips(),1);eq(#events,0)
end)
test("single spawn retries have a finite ceiling",function()
 local play=makePlay(false);fail.civilian=true;play:spawnShipAgent(nil,"1")
 for _=1,10 do if #events==0 then break end;runNext(play) end
 eq(attempts.civilian,4);eq(#events,0);eq(next(memory),nil)
end)
test("partial squadron retries only never-created members",function()
 local play=makePlay(true);fail.wing_b=1;play:spawnShipSquadron(nil,"1");eq(countShips(),1);eq(#events,1)
 runNext(play);eq(countShips(),2);eq(attempts.wing_a,1);eq(attempts.wing_b,2);eq(#events,0)
 local ships=cohortShips();eq(ships[1].squadron,ships[2].squadron)
end)
test("failed explicit commander joins existing partial squadron on retry",function()
 local play=makePlay(true,true);fail.commander=1;play:spawnShipSquadron(nil,"1");eq(countShips(),2)
 runNext(play);eq(countShips(),3);eq(attempts.wing_a,1);eq(attempts.wing_b,1);eq(attempts.commander,2)
 local ships=cohortShips();for _,ship in ipairs(ships) do eq(ship.squadron,ships[1].squadron) end
end)
test("partial squadron permanent failures stop retrying without cloning survivors",function()
 local play=makePlay(true);fail.wing_b=true;play:spawnShipSquadron(nil,"1")
 for _=1,10 do if #events==0 then break end;runNext(play) end
 eq(attempts.wing_a,1);eq(attempts.wing_b,4);eq(countShips(),1);eq(#events,0)
end)
test("completely failed squadron has one bounded retry chain",function()
 local play=makePlay(true);fail.wing_a=true;fail.wing_b=true;play:spawnShipSquadron(nil,"1")
 for _=1,10 do if #events==0 then break end;runNext(play) end
 eq(attempts.wing_a,4);eq(attempts.wing_b,4);eq(countShips(),0);eq(#events,0);eq(next(memory),nil)
end)
test("completion invalidates queued partial retry",function()
 local play=makePlay(true);fail.wing_b=true;play:spawnShipSquadron(nil,"1");local retry=assert(table.remove(events,1),"partial failure must schedule a retry")
 local leader=cohortShips()[1];play:squadronDestinationReached(leader)
 play[retry.callback](play,retry.object,retry.args)
 eq(countShips(),1);eq(attempts.wing_b,1);eq(replacements(),1);eq(next(memory),nil)
end)
test("last death invalidates queued partial retry",function()
 local play=makePlay(true);fail.wing_b=true;play:spawnShipSquadron(nil,"1");local retry=assert(table.remove(events,1),"partial failure must schedule a retry")
 destroy(play,cohortShips()[1],1);play[retry.callback](play,retry.object,retry.args)
 eq(attempts.wing_b,1);eq(replacements(),1);eq(next(memory),nil)
end)
test("last death cleans members whose destruction callbacks are still queued",function()
 local play=makePlay(true);play:spawnShipSquadron(nil,"1");local ships=cohortShips()
 ships[1].destroyed=true -- engine already removed this ship; Lua callback can arrive later
 destroy(play,ships[2],1)
 eq(next(memory),nil);eq(next(strings),nil);eq(next(vectors),nil)
 destroy(play,ships[1],2);eq(replacements(),1)
end)
test("partial retry reanchors after leader death without resurrecting dead slots",function()
 local play=makePlay(true,true);fail.wing_b=1;play:spawnShipSquadron(nil,"1")
 local retry=assert(table.remove(events,1));local ships=cohortShips();destroy(play,ships[1],2)
 play[retry.callback](play,nil,retry.args)
 eq(attempts.wing_b,1,"nil task anchor must reanchor before world work")
 runNext(play,"retrySquadronMembers")
 eq(attempts.commander,1);eq(attempts.wing_a,1);eq(attempts.wing_b,2);eq(countShips(),3)
end)
test("late optional commander cannot steal engine leader succession",function()
 local play=makePlay(true,true);fail.commander=1;play:spawnShipSquadron(nil,"1");runNext(play)
 local ships=cohortShips();destroy(play,ships[1],3)
 eq(ships[2].observers[DESTINATIONREACHED],"squadronDestinationReached")
 eq(ships[3].observers[DESTINATIONREACHED],nil)
end)
test("single route completion and queued destruction schedule one replacement",function()
 local play=makePlay(false);play:spawnShipAgent(nil,"1");local ship=cohortShips()[1]
 play:shipDestinationReached(ship);play:shipDestinationReached(ship);play:staticShipDestroyed(ship,nil)
 eq(replacements(),1);eq(ship.hyperspacing,true);eq(next(memory),nil);eq(next(strings),nil)
end)
test("single destruction callback cannot replace the same ship twice",function()
 local play=makePlay(false);play:spawnShipAgent(nil,"1");local ship=cohortShips()[1]
 play:staticShipDestroyed(ship,nil);play:staticShipDestroyed(ship,nil);eq(replacements(),1)
end)
test("ordinary guard patrol preserves its limits and does not get a route observer",function()
 local play=makePlay(false);local spawn=play.shipSpawns[1]
 spawn.patrolType=SHIP_AI_GUARD_PATROL;spawn.minPatrol=50;spawn.maxPatrol=200
 play:spawnShipAgent(nil,"1");local ship=cohortShips()[1]
 eq(ship.patrol,"guard");eq(ship.minGuard,50);eq(ship.maxGuard,200);eq(ship.observers[DESTINATIONREACHED],nil)
end)
test("successful ordinary single spawn has no retry",function()
 local play=makePlay(false);play:spawnShipAgent(nil,"1");eq(countShips(),1);eq(#events,0)
 local ship=cohortShips()[1];eq(ship.patrol,"fixed");eq(ship.single,true);eq(readData(ship.id..":SpawnerIndex:"),1)
end)
test("all authored zone declarations have valid respawn intervals",function()
 local zones={"corellia","dantooine","dathomir","endor","heavy1","light1","lok","naboo","tatooine","yavin4"}
 local expected={corellia={120,430},dantooine={79,293},dathomir={56,189},endor={96,354},heavy1={10,50},light1={57,165},lok={91,256},naboo={104,347},tatooine={117,403},yavin4={81,288}}
 for _,zone in ipairs(zones) do
  local path="bin/scripts/screenplays/space/spawning/space_"..zone.."_spawner.lua"
  local content=assert(io.open(path)):read("*a");local name=content:match("^(%w+)%s*=");dofile(path)
  local play=_G[name];local slots=0;eq(#play.shipSpawns,expected[zone][1])
  for _,spawn in ipairs(play.shipSpawns) do
   assert(spawn.minRespawn<=spawn.maxRespawn,zone..":"..spawn.spawnName.." reversed respawn interval")
   slots=slots+spawn.totalSpawns
  end
  eq(slots,expected[zone][2],zone.." authored population")
 end
end)
local failed=0
for _,entry in ipairs(tests) do
 reset();local ok,err=xpcall(entry[2],debug.traceback)
 if ok then print("PASS "..entry[1]) else failed=failed+1;print("FAIL "..entry[1].."\n"..err) end
end
print(string.format("%d tests, %d failures",#tests,failed));os.exit(failed==0 and 0 or 1)
