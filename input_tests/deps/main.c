#include <stdio.h>
#include <string.h>
#include "util.h"

int print(char *s) {
  return printf("%s", s);
}

int main(void) {
  char *s = "aaabcx";
  char *t = "abaabx";

  printf("%i\n", LCS(s, t));
  print("test");

  return 0;
}
