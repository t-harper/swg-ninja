/* Copyright <SWGEmu> See file COPYING for copying conditions. */
#pragma once

#include <atomic>
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <poll.h>
#include <string>
#include <sys/stat.h>
#include <unistd.h>

namespace coredetail {
// POSIX input transport only. The owner runs run() on its service thread and
// MUST requestStop()+join before destroying this reader or its callback owner.
// An already-entered callback completes normally; cancellation interrupts FIFO
// waits, not arbitrary callback code (the native console queue can block).
class FifoConsoleReader {
 std::string path;
 std::atomic<bool> stopping{false};
 int wake[2] = {-1, -1};
 int wakeError = 0;

 struct Descriptor {
  int value;
  explicit Descriptor(int fd) : value(fd) {}
  ~Descriptor() { if (value >= 0) ::close(value); }
  Descriptor(const Descriptor&) = delete;
  Descriptor& operator=(const Descriptor&) = delete;
 };

 bool fail(std::string& error, const char* operation, int code = 0) {
  error = operation;
  if (code) { error += ": "; error += std::strerror(code); }
  return false;
 }

 int openChannel(std::string& error) {
  struct stat before{};
  if (::lstat(path.c_str(), &before) != 0) {
   if (errno != ENOENT || ::mkfifo(path.c_str(), 0660) != 0) {
    fail(error, "cannot create console FIFO", errno); return -1;
   }
   if (::lstat(path.c_str(), &before) != 0) {
    fail(error, "cannot inspect console FIFO", errno); return -1;
   }
  }
  // Never unlink an unexpected path, follow a symlink, or accept a world-
  // writable command channel. A same-owner stale FIFO is safe to reuse.
  if (!S_ISFIFO(before.st_mode) || before.st_uid != ::geteuid() || (before.st_mode & 0007)) {
   fail(error, "console path must be an owned restrictive FIFO"); return -1;
  }
  int fd = ::open(path.c_str(), O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW);
  if (fd < 0) { fail(error, "cannot open console FIFO", errno); return -1; }
  struct stat opened{};
  if (::fstat(fd, &opened) != 0 || !S_ISFIFO(opened.st_mode) ||
      opened.st_dev != before.st_dev || opened.st_ino != before.st_ino ||
      opened.st_uid != ::geteuid() || (opened.st_mode & 0007)) {
   ::close(fd); fail(error, "console FIFO changed during open"); return -1;
  }
  return fd;
 }

public:
 explicit FifoConsoleReader(const std::string& fifoPath) : path(fifoPath) {
  if (::pipe2(wake, O_NONBLOCK | O_CLOEXEC) != 0) wakeError = errno;
 }
 ~FifoConsoleReader() {
  for (int fd : wake) if (fd >= 0) ::close(fd);
 }
 FifoConsoleReader(const FifoConsoleReader&) = delete;
 FifoConsoleReader& operator=(const FifoConsoleReader&) = delete;

 void requestStop() {
  stopping.store(true, std::memory_order_release);
  if (wake[1] >= 0) {
   const char byte = 1;
   // EAGAIN means a previous wake already fills the pipe. Retry only EINTR.
   while (::write(wake[1], &byte, 1) < 0 && errno == EINTR) {}
  }
 }

 template<typename Callback>
 bool run(Callback callback, std::string& error) {
  if (stopping.load(std::memory_order_acquire)) return true;
  if (wakeError) return fail(error, "cannot create console wake pipe", wakeError);
  Descriptor fifo(openChannel(error));
  if (fifo.value < 0) return false;
  std::string pending;
  auto emit = [&] {
   if (!stopping.load(std::memory_order_acquire)) callback(pending);
   pending.clear();
  };
  while (!stopping.load(std::memory_order_acquire)) {
   pollfd fds[2] = {{fifo.value, POLLIN, 0}, {wake[0], POLLIN, 0}};
   int ready = ::poll(fds, 2, -1);
   if (ready < 0) { if (errno == EINTR) continue; return fail(error, "console FIFO poll failed", errno); }
   if (stopping.load(std::memory_order_acquire)) break;
   if (fds[0].revents & (POLLERR | POLLNVAL)) return fail(error, "console FIFO poll invalid");
   if (!(fds[0].revents & (POLLIN | POLLHUP))) continue;
   char bytes[256];
   const auto count = ::read(fifo.value, bytes, sizeof(bytes));
   if (count < 0) {
    if (errno == EINTR || errno == EAGAIN) continue;
    return fail(error, "console FIFO read failed", errno);
   }
   if (count == 0) {
    // Match fgets: writer EOF completes a final unterminated line; a blank
    // writer emits nothing. Holding the read FD allows the next writer in.
    if (!pending.empty()) emit();
    if (stopping.load(std::memory_order_acquire)) break;
    // POLLHUP stays asserted without a writer. Sleep interruptibly instead
    // of spinning or blocking in another fopen waiting for a partner.
    pollfd stop = {wake[0], POLLIN, 0};
    if (::poll(&stop, 1, 100) < 0 && errno != EINTR) return fail(error, "console wake poll failed", errno);
    continue;
   }
   for (ssize_t i = 0; i < count && !stopping.load(std::memory_order_acquire); ++i) {
    if (bytes[i] == '\n') emit();
    else { pending += bytes[i]; if (pending.size() == 255) emit(); }
   }
  }
  // Cancellation is not writer EOF: never turn a partial command into a
  // second command after shutdown has already been accepted.
  return true;
 }
};
}
