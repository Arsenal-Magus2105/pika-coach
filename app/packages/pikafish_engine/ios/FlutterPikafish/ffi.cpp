#include <cstring>
#include <iostream>
#include <unistd.h>

#include "ffi.h"

#define NUM_PIPES 2
#define PARENT_WRITE_PIPE 0
#define PARENT_READ_PIPE 1
#define READ_FD 0
#define WRITE_FD 1
#define PARENT_READ_FD (pipes[PARENT_READ_PIPE][READ_FD])
#define PARENT_WRITE_FD (pipes[PARENT_WRITE_PIPE][WRITE_FD])
#define CHILD_READ_FD (pipes[PARENT_WRITE_PIPE][READ_FD])
#define CHILD_WRITE_FD (pipes[PARENT_READ_PIPE][WRITE_FD])

namespace Stockfish {
int main(int argc, char *argv[]);
}

namespace {
constexpr char quitOk[] = "quitok\n";
int pipes[NUM_PIPES][2];
char buffer[512];
}

int pikafish_init() {
  if (pipe(pipes[PARENT_READ_PIPE]) != 0) return 1;
  if (pipe(pipes[PARENT_WRITE_PIPE]) != 0) return 2;
  return 0;
}

int pikafish_main() {
  if (dup2(CHILD_READ_FD, STDIN_FILENO) < 0) return 3;
  if (dup2(CHILD_WRITE_FD, STDOUT_FILENO) < 0) return 4;

  int argc = 1;
  char executable[] = "pikafish";
  char *argv[] = {executable, nullptr};
  const int exitCode = Stockfish::main(argc, argv);

  std::cout << quitOk << std::flush;
  return exitCode;
}

ssize_t pikafish_stdin_write(char *data) {
  if (data == nullptr) return -1;
  return write(PARENT_WRITE_FD, data, std::strlen(data));
}

char *pikafish_stdout_read() {
  const ssize_t count = read(PARENT_READ_FD, buffer, sizeof(buffer) - 1);
  if (count <= 0) return nullptr;
  buffer[count] = '\0';
  if (std::strcmp(buffer, quitOk) == 0) return nullptr;
  return buffer;
}
