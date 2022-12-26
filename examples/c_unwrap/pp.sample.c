#include <stdio.h>

int main() {
% $x=2;
   ForUnwrap(i, 10, 5, $x)
      printf("${x} i=%d\n", i);
   ForUnwrapEnd

   ForUnwrap(i, 3)
      printf("i=%d\n", i);
      ForUnwrap(j, 3)
         printf("i*j=%d\n", i*j);
      ForUnwrapEnd
   ForUnwrapEnd

   ForUnwrap(i, -3)
      printf("i=%d\n", i);
   ForUnwrapEnd

   return 0;
}
