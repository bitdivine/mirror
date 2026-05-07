#include <cstdio>
#include <cstring>

#include "my_application.h"

#ifndef MIRROR_VERSION
#define MIRROR_VERSION "dev"
#endif

int main(int argc, char** argv) {
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--version") == 0) {
      printf("%s\n", MIRROR_VERSION);
      return 0;
    }
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
