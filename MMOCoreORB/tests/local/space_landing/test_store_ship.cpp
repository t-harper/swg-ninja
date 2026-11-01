#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>
#include "server/zone/objects/intangible/tasks/StoreShipTask.h"

// Match the real LuaShipObject station boundary. The baseline switch lets the
// same behavioral suite execute the original four-argument production task.
StoreShipTask stationLanding(CreatureObject* player, ShipControlDevice* device, const String& zone, Vector3 coordinates) {
#ifdef SPACE_LANDING_BASELINE_TASK
    return StoreShipTask(player, device, zone, coordinates);
#else
    return StoreShipTask(player, device, zone, coordinates, true);
#endif
}

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
bool at(const Vector3& actual, float x, float y, float z) {
    return actual.getX() == x && actual.getY() == y && actual.getZ() == z;
}
struct World {
    Zone ground, space{true};
    ZoneServer server;
    CreatureObject pilot, passenger, gunner;
    ShipObject ship;
    ShipControlDevice device;
    GroupObject group;
    World() {
        server.zones = {{"naboo", &ground}, {"tatooine", &ground}, {"space_tatooine", &space}};
        pilot.server = passenger.server = gunner.server = &server;
        pilot.group = &group;
        ship.server = &server;
        ship.occupants = {&pilot, &passenger, &gunner};
        device.ship = &ship;
    }
};
void untouched(World& world) {
    require(world.ship.inWorld, "invalid landing removed ship from space");
    require(world.ship.occupants.size() == 3, "invalid landing ejected occupants");
    require(world.pilot.zone == "space_tatooine", "invalid landing moved pilot");
    require(world.ship.launchZone == "naboo" && at(world.ship.launchLocation, -4860, 4165, 6), "invalid landing changed emergency return");
    require(!world.device.stored && !world.device.statusUpdated, "invalid landing stored ship");
    require(world.ship.wingsOpen && world.ship.staffSpeed == 5, "invalid landing changed ship controls");
    require(!world.group.memberShipCleared, "invalid landing changed group");
}
int main() {
    int failed = 0, passed = 0;
    auto test = [&](const char* name, const std::function<void()>& body) {
        try { body(); std::cout << "PASS " << name << '\n'; ++passed; }
        catch (const std::exception& e) { std::cout << "FAIL " << name << ": " << e.what() << '\n'; ++failed; }
    };
    // Reverting destination use in the real task sends all these roles back to Theed.
    test("cross-planet station landing moves pilot, passengers and gunner to selected port", [] {
        World w;
        auto task = stationLanding(&w.pilot, &w.device, "tatooine", Vector3(3600, -4785, 5));
        task.run();
        require(w.pilot.zone == "tatooine" && at(w.pilot.location, 3600, -4785, 5), "pilot returned to saved departure instead of selected Mos Eisley");
        require(w.passenger.zone == "tatooine" && at(w.passenger.location, 3600, -4785, 5), "passenger missed selected landing");
        require(w.gunner.zone == "tatooine" && at(w.gunner.location, 3600, -4785, 5), "gunner missed selected landing");
        require(w.device.stored && !w.ship.inWorld, "landed ship was not stored");
        require(w.device.storedZone == "tatooine" && at(w.device.storedLocation, 3600, -4785, 5), "ship parking location did not follow selected landing");
        require(!w.ship.wingsOpen && w.ship.staffSpeed == 0 && w.group.memberShipCleared, "existing ship/group cleanup regressed");
    });
    test("same planet different starport honors selected coordinates", [] {
        World w;
        auto task = stationLanding(&w.pilot, &w.device, "naboo", Vector3(1370, 2750, 13));
        task.run();
        require(w.pilot.zone == "naboo" && at(w.pilot.location, 1370, 2750, 13), "Keren selection returned to Theed");
    });
    // Reverting validation must not evacuate the ship for these invalid targets.
    for (const char* destination: {"disabled_planet", "", "space_tatooine"}) {
        test((String("invalid destination leaves ship and occupants unchanged: ") + destination).c_str(), [destination] {
            World w;
            auto task = stationLanding(&w.pilot, &w.device, destination, Vector3(1, 2, 3));
            task.run();
            untouched(w);
        });
    }
    test("non-finite selected coordinates leave ship and occupants unchanged", [] {
        World w;
        auto task = stationLanding(&w.pilot, &w.device, "tatooine", Vector3(std::numeric_limits<float>::quiet_NaN(), 1, 2));
        task.run();
        untouched(w);
    });
    test("destruction return still uses explicitly supplied saved departure", [] {
        World w;
        // DestroyShipTask supplies these saved control-device values.
        StoreShipTask task(&w.pilot, &w.device, w.device.storedZone, w.device.storedLocation);
        task.run();
        require(w.pilot.zone == "naboo" && at(w.pilot.location, -4860, 4165, 6), "emergency return changed departure");
        require(w.passenger.zone == "naboo" && w.gunner.zone == "naboo", "emergency return stranded crew");
        require(w.device.stored, "emergency return no longer stores ship");
    });
    test("legacy emergency with empty saved origin retains Coronet fallback", [] {
        World w;
        w.ship.launchZone = "";
        w.device.storedZone = "";
        StoreShipTask task(&w.pilot, &w.device, w.device.storedZone, w.device.storedLocation);
        task.run();
        require(w.pilot.zone == "corellia" && at(w.pilot.location, -66, 28, -4711), "empty-origin emergency lost original Coronet fallback");
        require(w.passenger.zone == "corellia" && w.gunner.zone == "corellia", "empty-origin emergency stranded crew");
        require(w.device.stored, "empty-origin emergency did not store ship");
    });
    test("legacy storage keeps saved return without opting into station destination", [] {
        World w;
        StoreShipTask task(&w.pilot, &w.device, "tatooine", Vector3(3600, -4785, 5));
        task.run();
        require(w.pilot.zone == "naboo" && at(w.pilot.location, -4860, 4165, 6), "legacy cleanup unexpectedly used forwarded destination");
    });
    test("load screen postpones landing without changing return or occupants", [] {
        World w;
        w.pilot.ghost.loading = true;
        auto task = stationLanding(&w.pilot, &w.device, "tatooine", Vector3(3600, -4785, 5));
        task.run();
        require(task.rescheduledMs == 2000, "load screen was not deferred");
        untouched(w);
    });
    test("valid landing retains astromech storage cleanup", [] {
        World w;
        PetControlDevice astromech;
        w.server.objects[789] = &astromech;
        w.ship.droidID = 789;
        auto task = stationLanding(&w.pilot, &w.device, "tatooine", Vector3(3600, -4785, 5));
        task.run();
        require(astromech.stored, "landing lost astromech cleanup");
    });
    std::cout << passed << " passed, " << failed << " failed\n";
    return failed == 0 ? 0 : 1;
}
