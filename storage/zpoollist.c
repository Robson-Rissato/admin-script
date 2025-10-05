#include <unistd.h>

int main(void) {
  char *binaryPath = "/usr/sbin/zpool";
  char *arg1 = "list";
  char *arg2 = "-Hp";

  execl(binaryPath, binaryPath, arg1, arg2, NULL);

  return 0;
}
