
Library contents:

c/pp_lib - this library is automatically included for c/cpp files
--------------------------------------------------------------------------

NAME
   Cover - checks whether a variable falls withing a set of disjoint ranges

SYNTAX
   Cover(var_name, list_of_ranges)

   list_of_ranges := range [, list_of_ranges]
   range := [expression] : [expression]

DESCRIPTION
   Given a variable, it generates code than once checked for statement coverage
   will be equivalent to checking the variable to see if it covers all those ranges

EXAMPLE

   The following

      Cover(a, :0, 1:10, 11:30, 40:)

   Translates into:

      // -- Cover (a, :0, 1:10, 11:30, 40:) 
      { int cover;
         if (a <= 0)
            cover++;
         if (1 <= a && a <= 10)
            cover++;
         if (11 <= a && a <= 30)
            cover++;
         if (40 <= a)
            cover++;
      }

      note that the code above is sufficient to check for coverage by using line
      coverage standard methods

SEE ALSO
   ---

-------------------
NAME
   ForUnwrap - generate a for loop unwrapping the interations

SYNTAX

   ForUnwrap ( var_name, limit [, init [, increment]] )
      ... block ...
   ForUnwrapEnd

   var_name need not be declared. The construct will locally 
   declare it as int

   limit, init and increment must be Perl constants

   init defaults to 0 if omitted
   increment defaults to sign(limit-init) if omitted

   is functionally equivalent to the following:

   if (limit > init)
      for (var_name=init; i<limit; i+=increment) {
         ... block ...
      }
   else
      for (var_name=init; i>limit; i+=increment) {
         ... block ...
      }

DESCRIPTION
   This call implements a regular for loop but completely unwrapped for less
   overhead of execution. The fact that is unwrapped by PP in perl code 
   constraints limit, init and increment to be constatns as seen by Perl

EXAMPLE

   The following

      % $x=2;
         ForUnwrap(i, 10, 5, $x)
            printf("${x} i=%d\n", i);
         ForWrapEnd

   Translates into:

      // -- ForUnwrap (i, 10, 5, 2) 
      // -- ForUnwrapEnd  
      // i, 5 .. 10, 2
      { int i = 5; 
            printf("2 i=%d\n", i);
      }
      { int i = 7; 
            printf("2 i=%d\n", i);
      }
      { int i = 9; 
            printf("2 i=%d\n", i);
      }

   The following

      ForUnwrap(i, 3)
         printf("i=%d\n", i);
      ForUnwrapEnd

   Translates into:

   // -- ForUnwrap (i, 3) 
   // -- ForUnwrapEnd  
   // i, 0 .. 3, 1
   { int i = 0; 
         printf("i=%d\n", i);
   }
   { int i = 1; 
         printf("i=%d\n", i);
   }
   { int i = 2; 
         printf("i=%d\n", i);
   }

SEE ALSO
   ---
