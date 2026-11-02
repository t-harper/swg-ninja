#include "server/NinjaMaintenanceGate.h"

#include <atomic>
#include <condition_variable>
#include <cstdio>
#include <fstream>
#include <future>
#include <iostream>
#include <stdexcept>
#include <thread>
#include <vector>
#include <unistd.h>

static const std::string owner(32, 'a');
static const std::string other(64, 'b');

static void require(bool value, const char* reason) {
	if (!value) throw std::runtime_error(reason);
}

struct Marker {
	std::string path;
	Marker() {
		char name[] = "/tmp/ninja-maintenance-spec-XXXXXX";
		int fd = mkstemp(name);
		require(fd >= 0, "create marker fixture");
		close(fd);
		path = name;
		std::remove(path.c_str());
	}

	void write(const std::string& contents) {
		std::ofstream file(path, std::ios::binary);
		file << contents;
		require(file.good(), "write marker fixture");
	}

	~Marker() { std::remove(path.c_str()); }
};

static std::string command(NinjaMaintenanceGate& gate, const std::string& arguments, int players = 0) {
	return gate.command(arguments, [players]() { return players; });
}

static void allAccountsBlocked() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	require(command(gate, "acquire " + owner) ==
		"NINJA_MAINTENANCE token=" + owner + " owned=1 blocked=1 inflight=0 players=0", "acquire acknowledgment");
	for (int adminLevel : {0, 1, 15}) {
		(void)adminLevel; // Admission deliberately has no account/admin exemption.
		auto admission = gate.tryAdmit();
		require(!admission, "maintenance must reject ordinary users and administrators");
	}
	require(command(gate, "status " + owner, 3).find("inflight=0 players=3") != std::string::npos,
		"status must preserve occupied player count");
}

static void inFlightDrains() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	std::promise<void> entered, leave;
	auto ready = entered.get_future();
	auto release = leave.get_future();
	std::atomic<int> players{0};
	std::thread connecting([&]() {
		auto admission = gate.tryAdmit();
		if (!admission) std::terminate();
		entered.set_value();
		release.wait();
		players.store(1);
	});
	ready.wait();
	auto occupied = gate.command("acquire " + owner, [&]() { return players.load(); });
	leave.set_value();
	connecting.join();
	require(occupied.find("blocked=1 inflight=1 players=0") != std::string::npos,
		"acquisition must expose an admission already in progress");
	require(gate.command("status " + owner, [&]() { return players.load(); }).find("inflight=0 players=1") != std::string::npos,
		"drained admission must publish its player count before zero in-flight");
}

static void ownershipAndRelease() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	command(gate, "acquire " + owner);
	require(command(gate, "acquire " + other).find("owned=0 blocked=1") != std::string::npos, "another token cannot steal ownership");
	require(command(gate, "release " + other).find("owned=0 blocked=1") != std::string::npos, "another token cannot release");
	require(!gate.tryAdmit(), "wrong-owner release must keep admission closed");
	require(command(gate, "status " + owner).find("owned=1 blocked=1") != std::string::npos, "owner status");
	require(command(gate, "release " + owner).find("owned=1 blocked=0") != std::string::npos, "matching owner release acknowledgment");
	require(static_cast<bool>(gate.tryAdmit()), "owner release must reopen admission");
	require(command(gate, "status " + owner).find("owned=0 blocked=0") != std::string::npos, "release relinquishes ownership");
}

static void queuedAndAsyncRecheck() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	std::atomic<int> admissions{0};
	auto delayedConnect = [&]() {
		auto admission = gate.tryAdmit();
		if (admission) ++admissions;
	};
	// A reconnect already queued, and a remote approval already requested,
	// both execute after maintenance has acquired the gate.
	{
		auto request = gate.tryAdmit();
		require(static_cast<bool>(request), "pre-maintenance approval request admitted");
	}
	command(gate, "acquire " + owner);
	std::thread queued(delayedConnect), asyncApproval(delayedConnect);
	queued.join();
	asyncApproval.join();
	require(admissions == 0, "queued reconnect and async approval must recheck current gate");
}

static void bootMarkerOwnedUntilRelease() {
	Marker marker;
	marker.write(owner + "\n");
	NinjaMaintenanceGate gate(marker.path);
	require(!gate.tryAdmit(), "boot marker must block before first admission");
	require(command(gate, "status " + owner).find("owned=1 blocked=1") != std::string::npos, "marker token must own gate");
	command(gate, "release " + other);
	require(!gate.tryAdmit(), "wrong boot token cannot release");
	command(gate, "release " + owner);
	require(static_cast<bool>(gate.tryAdmit()), "boot owner can explicitly reopen");
	NinjaMaintenanceGate restarted(marker.path);
	require(!restarted.tryAdmit(), "runtime release must not remove shared boot marker");
}

static void malformedMarkerFailsClosed() {
	for (const auto& contents : std::vector<std::string>{std::string(), "bad", std::string(32, 'A'), owner + "\nextra", std::string(4096, 'a')}) {
		Marker marker;
		marker.write(contents);
		NinjaMaintenanceGate gate(marker.path);
		require(!gate.tryAdmit(), "malformed marker must fail closed");
		require(command(gate, "acquire " + owner).find("owned=0 blocked=1") != std::string::npos,
			"malformed marker cannot be claimed by arbitrary token");
		command(gate, "release " + owner);
		require(!gate.tryAdmit(), "malformed marker must remain closed until repaired");
	}
}

static void malformedCommandsCannotChangeGate() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	for (const auto& token : std::vector<std::string>{"", "short", std::string(31, 'a'), std::string(65, 'a'), std::string(32, 'A')}) {
		require(command(gate, "acquire " + token).find("owned=0 blocked=0") != std::string::npos,
			"invalid token cannot acquire an open gate");
	}
	command(gate, "acquire " + owner);
	require(command(gate, "release " + owner + " extra").find("owned=0 blocked=1") != std::string::npos,
		"extra fields cannot release gate");
	require(command(gate, "unknown " + owner).find("owned=0 blocked=1") != std::string::npos,
		"unknown command cannot change gate");
}

static void raiiSurvivesMovesAndExceptions() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	bool movedValid = false;
	try {
		auto admission = gate.tryAdmit();
		auto moved = std::move(admission);
		movedValid = !admission && moved;
		throw std::runtime_error("simulate failed connect");
	} catch (const std::runtime_error&) {}
	require(movedValid, "move transfers a single admission");
	require(command(gate, "acquire " + owner).find("inflight=0") != std::string::npos, "RAII must drain on failed connection");
}

static void acquisitionRaceIsCountedOrRejected() {
	for (int repeat = 0; repeat < 100; ++repeat) {
		Marker marker;
		NinjaMaintenanceGate gate(marker.path);
		std::promise<void> start, attempted, leave;
		auto race = start.get_future().share();
		auto finished = attempted.get_future();
		auto release = leave.get_future();
		std::atomic<bool> accepted{false};
		std::thread connect([&]() {
			race.wait();
			auto admission = gate.tryAdmit();
			accepted = static_cast<bool>(admission);
			attempted.set_value();
			release.wait();
		});
		start.set_value();
		command(gate, "acquire " + owner);
		finished.wait();
		auto status = command(gate, "status " + owner);
		leave.set_value();
		connect.join();
		require(status.find(accepted ? "inflight=1" : "inflight=0") != std::string::npos,
			"a racing admission must either be counted or rejected");
	}
}

static void playerCountReadAfterGateCloses() {
	Marker marker;
	NinjaMaintenanceGate gate(marker.path);
	std::promise<void> reading, finish;
	auto started = reading.get_future();
	auto allowRead = finish.get_future();
	std::string response;
	std::thread console([&]() {
		response = gate.command("acquire " + owner, [&]() {
			reading.set_value();
			allowRead.wait();
			return 0;
		});
	});
	started.wait();
	auto admission = gate.tryAdmit();
	bool refused = !admission;
	finish.set_value();
	console.join();
	require(refused, "player count must be sampled after the admission gate closes");
	require(response.find("owned=1 blocked=1 inflight=0 players=0") != std::string::npos,
		"empty acknowledgment must observe the closed gate");
}

static void nonRegularOrUnreadableMarkerFailsClosed() {
	for (int kind = 0; kind < 3; ++kind) {
		Marker marker;
		if (kind == 0) {
			require(mkfifo(marker.path.c_str(), 0600) == 0, "FIFO fixture");
		} else if (kind == 1) {
			require(symlink("/nonexistent-ninja-marker", marker.path.c_str()) == 0, "symlink fixture");
		} else {
			marker.write(owner);
			require(chmod(marker.path.c_str(), 0000) == 0, "unreadable fixture");
		}
		NinjaMaintenanceGate gate(marker.path);
		require(!gate.tryAdmit(), "nonregular/unreadable marker must fail closed");
		require(command(gate, "release " + owner).find("owned=0 blocked=1") != std::string::npos,
			"invalid marker cannot be released");
	}
}

static void validMarkerTokenBoundaries() {
	for (const auto& contents : {owner, other + "\r\n"}) {
		Marker marker;
		marker.write(contents);
		NinjaMaintenanceGate gate(marker.path);
		require(!gate.tryAdmit(), "both token length boundaries must start closed");
		std::string token = contents.substr(0, contents.size() == 32 ? 32 : 64);
		require(command(gate, "release " + token).find("owned=1 blocked=0") != std::string::npos,
			"both token length boundaries must retain ownership");
	}
}

int main() {
	int failed = 0;
	const std::pair<const char*, void(*)()> cases[] = {
		{"blocks every account", allAccountsBlocked},
		{"in-flight drain and player publication", inFlightDrains},
		{"ownership and release", ownershipAndRelease},
		{"queued and async recheck", queuedAndAsyncRecheck},
		{"boot marker ownership", bootMarkerOwnedUntilRelease},
		{"malformed marker fails closed", malformedMarkerFailsClosed},
		{"malformed commands", malformedCommandsCannotChangeGate},
		{"RAII moves and exceptions", raiiSurvivesMovesAndExceptions},
		{"acquisition race", acquisitionRaceIsCountedOrRejected},
		{"player count sampled after gate closes", playerCountReadAfterGateCloses},
		{"unsafe marker files fail closed", nonRegularOrUnreadableMarkerFailsClosed},
		{"valid marker token boundaries", validMarkerTokenBoundaries},
	};
	for (const auto& test : cases) {
		try {
			test.second();
			std::cout << "PASS " << test.first << '\n';
		} catch (const std::exception& error) {
			++failed;
			std::cerr << "FAIL " << test.first << ": " << error.what() << '\n';
		}
	}
	return failed ? 1 : 0;
}
