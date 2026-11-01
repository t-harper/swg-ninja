#include "gtest/gtest.h"
#include "server/zone/managers/director/DirectorManager.h"
#include "system/thread/Thread.h"

#include <atomic>
#include <chrono>
#include <memory>
#include <vector>

namespace {
bool compareMemory(const char* key, uint64 expected, uint64 desired) {
	lua_State* state = luaL_newstate();
	lua_pushstring(state, key);
	lua_pushinteger(state, expected);
	lua_pushinteger(state, desired);
	const int results = DirectorManager::compareAndSetSharedMemory(state);
	const bool changed = results == 1 && lua_toboolean(state, -1);
	lua_close(state);
	return changed;
}

void writeMemory(const char* key, uint64 value) {
	lua_State* state = luaL_newstate();
	lua_pushstring(state, key);
	lua_pushinteger(state, value);
	DirectorManager::writeSharedMemory(state);
	lua_close(state);
}

void removeMemory(const char* key) {
	lua_State* state = luaL_newstate();
	lua_pushstring(state, key);
	DirectorManager::deleteSharedMemory(state);
	lua_close(state);
}

class ClaimThread : public Thread {
	const char* key;
	std::atomic<int>& ready;
	std::atomic<bool>& go;
	std::atomic<int>& winners;
	std::atomic<int>& invalidResults;

public:
	ClaimThread(const char* key, std::atomic<int>& ready, std::atomic<bool>& go,
			std::atomic<int>& winners, std::atomic<int>& invalidResults)
		: key(key), ready(ready), go(go), winners(winners), invalidResults(invalidResults) {
	}

	void run() override {
		// Engine threads establish the TLS identity required by Director's
		// lock ownership checks. Every contender owns a separate Lua state.
		lua_State* state = luaL_newstate();
		if (state != nullptr) {
			lua_pushstring(state, key);
			lua_pushinteger(state, 1);
			lua_pushinteger(state, 2);
		}
		++ready;
		while (!go.load())
			Thread::yield();

		if (state == nullptr) {
			++invalidResults;
			return;
		}
		const int results = DirectorManager::compareAndSetSharedMemory(state);
		if (results != 1 || !lua_isboolean(state, -1))
			++invalidResults;
		else if (lua_toboolean(state, -1))
			++winners;
		lua_close(state);
	}
};
}

TEST(DirectorSharedMemoryTest, AbsentZeroStateCanBeInitializedAndReadBack) {
	const char* key = "test:space-spawning:initialize";
	removeMemory(key);
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 0u);
	EXPECT_TRUE(compareMemory(key, 0, 1));
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 1u);
	removeMemory(key);
}

TEST(DirectorSharedMemoryTest, MissingAndMismatchedStateCannotBeClaimed) {
	const char* key = "test:space-spawning:missing";
	removeMemory(key);
	EXPECT_FALSE(compareMemory(key, 1, 2));
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 0u);
	writeMemory(key, 2);
	EXPECT_FALSE(compareMemory(key, 1, 0));
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 2u);
	removeMemory(key);
}

TEST(DirectorSharedMemoryTest, SuccessfulClaimChangesStateExactlyOnce) {
	const char* key = "test:space-spawning:transition";
	writeMemory(key, 1);
	EXPECT_TRUE(compareMemory(key, 1, 2));
	EXPECT_FALSE(compareMemory(key, 1, 2));
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 2u);
	EXPECT_TRUE(compareMemory(key, 2, 0));
	EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 0u);
	removeMemory(key);
}

TEST(DirectorSharedMemoryTest, ConcurrentCohortClaimsHaveOneWinner) {
	const char* key = "test:space-spawning:concurrent";
	// Initialize the singleton before starting concurrent engine threads.
	DirectorManager::instance();
	for (int round = 0; round < 20; ++round) {
		writeMemory(key, 1);
		std::atomic<int> winners{0};
		std::atomic<int> ready{0};
		std::atomic<int> invalidResults{0};
		std::atomic<bool> go{false};
		std::vector<std::unique_ptr<ClaimThread>> workers;
		for (int worker = 0; worker < 32; ++worker) {
			workers.emplace_back(new ClaimThread(key, ready, go, winners, invalidResults));
			workers.back()->start();
		}
		const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
		while (ready.load() != 32 && std::chrono::steady_clock::now() < deadline)
			Thread::yield();
		go = true;
		for (auto& worker : workers)
			worker->join();
		EXPECT_EQ(ready.load(), 32) << "round " << round;
		EXPECT_EQ(invalidResults.load(), 0) << "round " << round;
		EXPECT_EQ(winners.load(), 1) << "round " << round;
		EXPECT_EQ(DirectorManager::instance()->readSharedMemory(key), 2u);
	}
	removeMemory(key);
}
