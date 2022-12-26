#include <stdio.h>

main() {
   for(int i=0; i<10; i++) {
      Cover(i,0:3,4:8,9:10);
      printf("i=%d\n", i);
   }
% for $i (0..10) {
   printf("${i}\n");
% }   
   return 0;
}
