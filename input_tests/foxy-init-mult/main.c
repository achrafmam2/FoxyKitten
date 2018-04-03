#include <stdio.h>
#include <string.h>
#include "util.h"

int main(void) {
  char *s = "aaabcx";
  char *t = "abaabx";

  printf("%i\n", LCS(s, t));

  return 0;
}
