#pragma once
// Minimal world/engine boundaries required to execute the production task.
// No landing policy lives here: moving occupants uses the existing ship API's
// saved launch location, exactly as ShipObjectImplementation.cpp does.
#include <cmath>
#include <cstdint>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using uint64 = uint64_t;
using String = std::string;
class Vector3 {
    float x = 0, y = 0, z = 0;
public:
    Vector3() = default;
    Vector3(float x, float y, float z): x(x), y(y), z(z) {}
    float getX() const { return x; }
    float getY() const { return y; }
    float getZ() const { return z; }
};
template<class T> class ManagedReference {
    T value = nullptr;
public:
    ManagedReference() = default;
    ManagedReference(T value): value(value) {}
    T operator->() const { return value; }
    T get() const { return value; }
    operator T() const { return value; }
    template<class U> U castTo() const { return dynamic_cast<U>(value); }
};
template<class T> class ManagedWeakReference {
    T value;
public:
    ManagedWeakReference(T value): value(value) {}
    T get() const { return value; }
};
class Task {
public:
    int rescheduledMs = 0;
    virtual ~Task() = default;
    virtual void run() = 0;
    void reschedule(int delay) { rescheduledMs = delay; }
    void execute() { run(); }
};
class Logger {
    std::ostringstream output;
public:
    void setLoggingName(const char*) {}
    std::ostream& error() { return output; }
};
class Locker {
public:
    template<class... T> Locker(T...) {}
    void release() {}
};
class Zone {
    bool space;
public:
    explicit Zone(bool space = false): space(space) {}
    bool isSpaceZone() const { return space; }
};
class SceneObject {
public:
    virtual ~SceneObject() = default;
    virtual bool isPetControlDevice() const { return false; }
};
class ShipObject;
class GroupObject {
public:
    bool memberShipCleared = false;
    void updateMemberShip(class CreatureObject*, ShipObject*) { memberShipCleared = true; }
};
class ZoneServer {
public:
    std::map<String, Zone*> zones;
    std::map<uint64, SceneObject*> objects;
    Zone* getZone(const String& name) { auto it = zones.find(name); return it == zones.end() ? nullptr : it->second; }
    SceneObject* getObject(uint64 oid) { auto it = objects.find(oid); return it == objects.end() ? nullptr : it->second; }
};
class PlayerObject {
public:
    bool loading = false;
    bool isOnLoadScreen() const { return loading; }
};
class CreatureObject {
public:
    ZoneServer* server = nullptr;
    PlayerObject ghost;
    GroupObject* group = nullptr;
    String zone = "space_tatooine";
    Vector3 location;
    PlayerObject* getPlayerObject() { return &ghost; }
    ZoneServer* getZoneServer() { return server; }
    bool isGrouped() const { return group != nullptr; }
    GroupObject* getGroup() { return group; }
};
namespace OptionBitmask { constexpr int WINGS_OPEN = 1; }
namespace PlayerArrangement { constexpr int RIDER = 4; }
class ShipObject: public SceneObject {
public:
    String launchZone = "naboo";
    Vector3 launchLocation{-4860, 4165, 6};
    std::vector<CreatureObject*> occupants;
    bool inWorld = true;
    bool wingsOpen = true;
    float staffSpeed = 5;
    uint64 droidID = 0;
    ZoneServer* server = nullptr;
    ShipObject* asShipObject() { return this; }
    void setSpaceLaunchZone(const String& zone) { launchZone = zone; }
    void setSpaceLaunchLocation(const Vector3& location) { launchLocation = location; }
    uint64 getShipDroidID() const { return droidID; }
    ZoneServer* getZoneServer() { return server; }
    void removeAllPlayersFromShip() {
        for (auto* occupant: occupants) {
            occupant->zone = launchZone.empty() ? "corellia" : launchZone;
            occupant->location = launchZone.empty() ? Vector3(-66, 28, -4711) : launchLocation;
        }
        occupants.clear();
    }
    void setStaffShipSpeed(float speed) { staffSpeed = speed; }
    void clearOptionBit(int, bool) { wingsOpen = false; }
    void destroyObjectFromWorld(bool) { inWorld = false; }
    uint64 getObjectID() const { return 123; }
};
class ShipControlDevice: public SceneObject {
public:
    ShipObject* ship = nullptr;
    bool stored = false;
    bool statusUpdated = false;
    String storedZone = "naboo";
    Vector3 storedLocation{-4860, 4165, 6};
    ShipObject* getControlledObject() { return ship; }
    bool transferObject(ShipObject*, int, bool, bool, bool) { stored = true; return true; }
    uint64 getObjectID() const { return 456; }
    bool isShipLaunched() const { return ship->inWorld; }
    void updateStatus(bool, bool) { statusUpdated = true; }
    void setStoredLocationData(CreatureObject* player) { storedZone = player->zone; storedLocation = player->location; }
};
class PetControlDevice: public SceneObject {
public:
    bool stored = false;
    bool isPetControlDevice() const override { return true; }
};
class PetControlDeviceStoreTask: public Task {
    PetControlDevice* device;
public:
    PetControlDeviceStoreTask(PetControlDevice* device, CreatureObject*, bool): device(device) {}
    void run() override { device->stored = true; }
};
