#include <stdio.h>

int main() {
% $x=2;
   int i;
   // pragma syn_unwrap_beg 3
   for(i=1; i<=10; i+=1) {
      printf("${x} i=%d\n", i);
   }
   // pragma syn_unwrap_end

   //  pragma syn_unwrap_beg
   for(int i=0; i<3; i++) {
      printf("i=%d\n", i);
      //pragma syn_unwrap_beg
      for(int j=0; j<3; j++) {
         printf("i*j=%d\n", i*j);
      }
      //  pragma syn_unwrap_end
   }
   //  pragma syn_unwrap_end

   //  pragma syn_unwrap_beg
   for(int i=0; i>-3; i--) {
      printf("i=%d\n", i);
   }
   //  pragma syn_unwrap_end

   return 0;
}
