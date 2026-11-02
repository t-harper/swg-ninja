#ifndef NINJA_MAINTENANCE_GATE_H
#define NINJA_MAINTENANCE_GATE_H

#include <cerrno>
#include <cstddef>
#include <fcntl.h>
#include <mutex>
#include <sstream>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>

// Admission and acquisition share one mutex. Once blocked with zero in-flight
// callbacks, no queued/reconnect/remote-approval callback can enter the world.
// This is independent of the ordinary server lock, which permits administrators.
class NinjaMaintenanceGate {
	std::mutex mutex;
	std::string owner;
	std::size_t inFlight = 0;
	bool blocked = false;

	void finishAdmission() {
		std::lock_guard<std::mutex> lock(mutex);
		--inFlight;
	}

	static bool validToken(const std::string& token) {
		if (token.size() < 32 || token.size() > 64) return false;
		for (char ch : token) {
			if (!((ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f'))) return false;
		}
		return true;
	}

	void loadBootMarker(const std::string& path) {
		int fd = open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NOFOLLOW | O_NONBLOCK);
		if (fd < 0) {
			// Only absence means open admission. Permission/I/O/symlink errors
			// must not silently reopen a failed rollout.
			blocked = errno != ENOENT;
			return;
		}
		blocked = true;
		struct stat metadata;
		if (fstat(fd, &metadata) != 0 || !S_ISREG(metadata.st_mode)) {
			close(fd);
			return;
		}
		char buffer[67]; // token (64) + optional CRLF; anything larger is invalid
		std::size_t length = 0;
		bool failed = false;
		while (length < sizeof(buffer)) {
			ssize_t count = read(fd, buffer + length, sizeof(buffer) - length);
			if (count < 0 && errno == EINTR) continue;
			if (count < 0) failed = true;
			if (count <= 0) break;
			length += static_cast<std::size_t>(count);
		}
		close(fd);
		if (failed || length == sizeof(buffer)) return;
		std::string token(buffer, length);
		if (!token.empty() && token.back() == '\n') {
			token.pop_back();
			if (!token.empty() && token.back() == '\r') token.pop_back();
		}
		if (validToken(token)) owner = token;
		// An invalid marker stays blocked without an owner. Repair the marker
		// and restart; arbitrary tokens cannot claim or release this state.
	}

public:
	class Admission {
		friend class NinjaMaintenanceGate;
		NinjaMaintenanceGate* gate;
		explicit Admission(NinjaMaintenanceGate* owner) : gate(owner) {}

	public:
		Admission(const Admission&) = delete;
		Admission& operator=(const Admission&) = delete;
		Admission(Admission&& other) noexcept : gate(std::exchange(other.gate, nullptr)) {}
		Admission& operator=(Admission&& other) noexcept {
			if (this != &other) {
				if (gate != nullptr) gate->finishAdmission();
				gate = std::exchange(other.gate, nullptr);
			}
			return *this;
		}
		~Admission() { if (gate != nullptr) gate->finishAdmission(); }
		explicit operator bool() const { return gate != nullptr; }
	};

	explicit NinjaMaintenanceGate(const std::string& marker = "conf/ninja-maintenance.token") {
		loadBootMarker(marker);
	}

	static NinjaMaintenanceGate& instance() {
		static NinjaMaintenanceGate gate;
		return gate;
	}

	Admission tryAdmit() {
		std::lock_guard<std::mutex> lock(mutex);
		if (blocked) return Admission(nullptr);
		++inFlight;
		return Admission(this);
	}

	template<class CountPlayers>
	std::string command(const std::string& arguments, CountPlayers countPlayers) {
		std::istringstream input(arguments);
		std::string verb, token, extra;
		input >> verb >> token;
		bool valid = validToken(token) && !(input >> extra);
		bool owned = false;
		bool blockedSnapshot;
		std::size_t flightSnapshot;
		{
			std::lock_guard<std::mutex> lock(mutex);
			if (valid && (verb == "acquire" || verb == "status" || verb == "release")) {
				if (verb == "acquire" && !blocked) {
					blocked = true;
					owner = token;
				}
				owned = blocked && !owner.empty() && owner == token;
				if (verb == "release" && owned) {
					blocked = false;
					owner.clear();
				}
			}
			blockedSnapshot = blocked;
			flightSnapshot = inFlight;
		}
		// Read players AFTER acquiring/snapshotting the gate, never before.
		// A callback publishes its online count before releasing its Admission.
		// Thus blocked=1/inflight=0 cannot pair with a stale pre-drain zero count.
		// Do not call server code while holding the gate mutex (lock ordering).
		int players = countPlayers();
		return "NINJA_MAINTENANCE token=" + (validToken(token) ? token : "invalid") +
			" owned=" + (owned ? "1" : "0") + " blocked=" + (blockedSnapshot ? "1" : "0") +
			" inflight=" + std::to_string(flightSnapshot) + " players=" + std::to_string(players);
	}
};

#endif
