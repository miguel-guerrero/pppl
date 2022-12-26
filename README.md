
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

