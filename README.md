
## Introduction

PP is a general purpose pre-processor. The target laguage can be just about
anything. The control language is Perl. Perl commands are embedded in the 
text to allow for repetition, conditional text etc.

For instance if your input file is:

    <pp.hello.txt>

    % for $i (1..5) {
        ${i} Hellow world!
    % }

After executing:

    $ ./pp.pl pp.hello.txt -o hello.txt

Your output file would be:

    <hello.txt>

    1 Hellow world!
    2 Hellow world!
    3 Hellow world!
    4 Hellow world!
    5 Hellow world!

The example above shows a couple of the most important feature.

* Any line that starts with `%` is considered perl code that is emmitted out to an Intermediate Perl Script (IPS)
* Lines **not** preceeded by `%` are converted into prints. On those:
  * Any `${var}` will be interpolated with the value of variable `$var`.
  * Any `$((expression))` will be interpolated with the value of the given perl expression. For example:
  
        % $a=1; $b=2;
        the value of a + b = $(( $a + $b ))
  
    Will generate:
  
        the value of a + b = 3
    
       
## Command line options

    $ ./pp.pl -h
    
    
```
 Perl Based Preprocessor

 USAGE: ./pp.pl [options] outFilename.ext ...

     -h       : Display this message
     -q       : Quiet mode
     -n       : No comment. Remove initial comment on generated file
     -ips f   : Use 'f' as filename for Intermediate Perl Script (def pp_out_tmp*.pl)
     -c       : Compile only (don't execute fileTmp)

     -pp str  : Perl parameters. Will add "parameters" to 1st line of pp_out_tmp*.pl
                (e.g -w for #!/usr/bin/perl -w)
     -o f     : Output filename (requires only one input file name given)
                when multiple files are given the input filename is expected to
                have a pp. prefix which is removed to generate the output filename
     -I  dir  : Add dir to the set of directories to search on include
     -d  dir  : Destination directory for resulting file (def .)
     -cs str  : Specify comment start sequence (def '//')
     -ce str  : Specify comment end sequence (def '')
     -ps str  : Specify start escape character for Perl code (def '%')
     -ms str  : Specify start escape character for phase 1 calls (def '\@')
     -ts str  : Specify start escape character for phase 2 calls (def '')
     -es str  : Specify start escape character for Perl eval (def '\$\(\(')
     -ee str  : Specify end   escape character for Perl eval (def '\)\)')
     -p var=value
              : pass a parameter to file to process (e.g. -p WIDTH=32)
                multiple can be given with several -p parameters

 An Intermediate Perl Script (fileTmp) will be created.
 The execution of that file generates the post-processed file on stdout.
 It can be used to debug the code embedded in the pre-preprocessed file

 if the string PP_FILENAME="filename" is found in the generated output
 after a comment (as per -cs option) then the output filename is overridden
 by this value (this allows to compute the filename within the body of the
 file based on command line parameters)
```  
