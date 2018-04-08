#include <stdio.h>
#include <stdlib.h>

int randomValue() {
  return rand();
}

int magic(int val) {
  return randomValue() % val;
}

int main(void) {
  return magic(5);
}
