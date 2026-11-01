#include <atomic>
#include <cassert>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <functional>
#include <iostream>
#include <mutex>
#include <string>
#include <sys/stat.h>
#include <thread>
#include <unistd.h>
#include <vector>
#ifndef LEGACY_FIFO_REPRO
#include "server/FifoConsoleReader.h"
#endif
using namespace std::chrono;
static bool until(const std::function<bool()>& condition, int ms = 1000) {
 const auto end = steady_clock::now() + milliseconds(ms);
 do { if (condition()) return true; std::this_thread::sleep_for(milliseconds(2)); } while (steady_clock::now() < end);
 return condition();
}
int main() {
 char directory[] = "/tmp/swg-fifo-test-XXXXXX";
 assert(mkdtemp(directory)); const std::string path = std::string(directory) + "/console.fifo";
#ifdef LEGACY_FIFO_REPRO
 // Exact old fopen/fgets lifecycle, with the owner kept alive for safe cleanup.
 assert(mkfifo(path.c_str(), 0600) == 0);
 std::atomic<bool> stopping{false}, done{false}, entering{false};
 std::thread thread([&] {
  while (!stopping) {
   entering = true;
   FILE* fifo = fopen(path.c_str(), "r");
   assert(fifo); char line[256]; while (fgets(line, sizeof(line), fifo)) {}
   fclose(fifo);
  }
  done = true;
 });
 assert(until([&] { return entering.load(); }));
 std::this_thread::sleep_for(milliseconds(30)); stopping = true;
 const bool stopped = until([&] { return done.load(); }, 150);
 // Wake only this test's temporary FIFO to reap the thread. Never touch a server.
 const int writer = open(path.c_str(), O_WRONLY | O_NONBLOCK); assert(writer >= 0); close(writer);
 thread.join(); unlink(path.c_str()); rmdir(directory);
 if (!stopped) { std::cerr << "RED: legacy FIFO reader cannot stop while idle in blocking open\n"; return 1; }
 return 0;
#else
 auto scenario = [&](int kind) {
  coredetail::FifoConsoleReader reader(path); std::atomic<bool> done{false}; std::string error;
  std::mutex mutex; std::vector<std::string> commands;
  std::thread thread([&] { assert(reader.run([&](const std::string& command) { std::lock_guard<std::mutex> lock(mutex); commands.push_back(command); }, error)); done = true; });
  int writer = -1;
  assert(until([&] { writer = open(path.c_str(), O_WRONLY | O_NONBLOCK); return writer >= 0; }));
  if (kind == 0) { close(writer); writer = -1; } // idle after zero-byte writer
  if (kind == 2) { assert(write(writer, "unfinished", 10) == 10); } // held partial writer
  if (kind == 3) {
   const std::string data = "alpha\n\n" + std::string(260, 'x') + "\npartial";
   assert(write(writer, data.data(), data.size()) == static_cast<ssize_t>(data.size())); close(writer); writer = -1;
   assert(until([&] { std::lock_guard<std::mutex> lock(mutex); return commands.size() == 5; }));
   std::lock_guard<std::mutex> lock(mutex);
   assert((commands == std::vector<std::string>{"alpha", "", std::string(255, 'x'), std::string(5, 'x'), "partial"}));
  }
  if (kind == 4) { assert(write(writer, "partial", 7) == 7); close(writer); writer = -1; assert(until([&] { std::lock_guard<std::mutex> lock(mutex); return commands.size() == 1; })); }
  const auto begin = steady_clock::now(); reader.requestStop();
  assert(until([&] { return done.load(); }, 500)); thread.join();
  assert(duration_cast<milliseconds>(steady_clock::now() - begin).count() < 500);
  if (writer >= 0) close(writer);
  if (kind < 3) { std::lock_guard<std::mutex> lock(mutex); assert(commands.empty()); }
  assert(error.empty()); unlink(path.c_str());
 };
 for (int i = 0; i != 5; ++i) scenario(i);
 // Initial idle channel has never had a writer at all.
 { coredetail::FifoConsoleReader reader(path); std::atomic<bool> done{false}; std::string error;
   std::thread thread([&] { assert(reader.run([](const std::string&) { assert(false); }, error)); done = true; });
   assert(until([&] { struct stat st{}; return lstat(path.c_str(), &st) == 0; }));
   std::this_thread::sleep_for(milliseconds(20)); reader.requestStop();
   assert(until([&] { return done.load(); }, 500)); thread.join(); unlink(path.c_str()); }
 // Stop inside the first callback suppresses later commands already read in
 // the same batch, and the final partial command is discarded.
 { coredetail::FifoConsoleReader reader(path); std::atomic<int> calls{0}; std::atomic<bool> done{false}; std::string error;
   std::thread thread([&] { assert(reader.run([&](const std::string& line) { assert(line == "first"); ++calls; reader.requestStop(); }, error)); done = true; });
   int writer = -1; assert(until([&] { writer = open(path.c_str(), O_WRONLY | O_NONBLOCK); return writer >= 0; }));
   assert(write(writer, "first\nsecond\npartial", 20) == 20);
   assert(until([&] { return done.load(); }, 500)); thread.join(); close(writer); assert(calls == 1); unlink(path.c_str()); }
 // An in-flight callback completes before join; cancellation does not destroy
 // its owner while it is still executing. This is not a pipe-flood guarantee.
 { coredetail::FifoConsoleReader reader(path); std::atomic<bool> entered{false}, release{false}, done{false}; std::string error;
   std::thread thread([&] { assert(reader.run([&](const std::string&) { entered = true; while (!release) std::this_thread::sleep_for(milliseconds(1)); }, error)); done = true; });
   int writer = -1; assert(until([&] { writer = open(path.c_str(), O_WRONLY | O_NONBLOCK); return writer >= 0; }));
   assert(write(writer, "command\n", 8) == 8); assert(until([&] { return entered.load(); })); reader.requestStop();
   std::this_thread::sleep_for(milliseconds(20)); assert(!done); release = true;
   assert(until([&] { return done.load(); }, 500)); thread.join(); close(writer); unlink(path.c_str()); }
 // POLLHUP after a blank writer must not consume a core while idle.
 { coredetail::FifoConsoleReader reader(path); std::atomic<bool> done{false}; std::string error; long long cpuNanos = 0;
   std::thread thread([&] { timespec before{}, after{}; assert(clock_gettime(CLOCK_THREAD_CPUTIME_ID, &before) == 0);
     assert(reader.run([](const std::string&) { assert(false); }, error));
     assert(clock_gettime(CLOCK_THREAD_CPUTIME_ID, &after) == 0); cpuNanos = (after.tv_sec - before.tv_sec) * 1000000000LL + after.tv_nsec - before.tv_nsec; done = true; });
   int writer = -1; assert(until([&] { writer = open(path.c_str(), O_WRONLY | O_NONBLOCK); return writer >= 0; })); close(writer);
   std::this_thread::sleep_for(milliseconds(250)); reader.requestStop(); assert(until([&] { return done.load(); }, 500)); thread.join();
   assert(cpuNanos < 50000000LL); unlink(path.c_str()); }
 // Stop before thread startup does not create a channel or call the callback.
 { coredetail::FifoConsoleReader reader(path); reader.requestStop(); std::string error; assert(reader.run([](const std::string&) { assert(false); }, error)); assert(access(path.c_str(), F_OK) != 0); }
 // A queued partial command must never be flushed as a shutdown side effect.
 for (int i = 0; i != 20; ++i) scenario(2);
 // Refuse unsafe regular files/symlinks/permissive FIFOs without replacing them.
 auto rejected = [&] { coredetail::FifoConsoleReader reader(path); std::string error; assert(!reader.run([](const std::string&) { assert(false); }, error)); assert(!error.empty()); };
 { int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_EXCL, 0600); assert(fd >= 0); assert(write(fd, "keep", 4) == 4); close(fd); rejected(); struct stat st{}; assert(lstat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode) && st.st_size == 4); unlink(path.c_str()); }
 assert(symlink("missing-target", path.c_str()) == 0); rejected(); struct stat st{}; assert(lstat(path.c_str(), &st) == 0 && S_ISLNK(st.st_mode)); unlink(path.c_str());
 assert(mkfifo(path.c_str(), 0600) == 0); assert(chmod(path.c_str(), 0666) == 0); rejected(); unlink(path.c_str());
 rmdir(directory); std::cout << "PASS: real FIFO idle/open/partial/EOF/framing/stop races/path guards\n";
#endif
}
