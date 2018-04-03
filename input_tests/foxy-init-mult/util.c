#include "util.h"

int max(int a, int b) {
  return (a > b) ? a : b;
}

int LCS(char *s, char *t) {
  if (!s || !t) {
    return 0;
  }

  if (*s == *t) {
    return 1 + LCS(++s, ++t);
  }
  return max(LCS(++s, t), LCS(s, ++t));
}
