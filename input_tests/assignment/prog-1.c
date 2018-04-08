#include <stdio.h>
#include <stdlib.h>

int someValue() {
  return rand();
}

int gamble(int val) {
  return someValue() * val;
}

int main(void) {
  return gamble(5);
}
