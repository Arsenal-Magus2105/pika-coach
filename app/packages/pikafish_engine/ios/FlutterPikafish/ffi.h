#pragma once

#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((visibility("default"))) __attribute__((used))
int pikafish_init(void);

__attribute__((visibility("default"))) __attribute__((used))
int pikafish_main(void);

__attribute__((visibility("default"))) __attribute__((used))
ssize_t pikafish_stdin_write(char *data);

__attribute__((visibility("default"))) __attribute__((used))
char *pikafish_stdout_read(void);

#ifdef __cplusplus
}
#endif
