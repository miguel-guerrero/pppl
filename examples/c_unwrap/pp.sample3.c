#include <stdio.h>

int main() {
   int k;

   // pragma syn_unwrap 3
   for(k=1; k<=10; k+=1) {
      printf("k=%d\n", k);
   }

   //  pragma syn_unwrap
   for(int i=0; i<3; i++) {
      printf("i=%d\n", i);
      //pragma syn_unwrap
      for(int j=0; j<3; j++) {
         printf("i*j=%d\n", i*j);
      }
   }

   //  pragma syn_unwrap
   for(int i=0; i>-3; i--) {
      printf("i=%d\n", i);
   }

   return 0;
}
