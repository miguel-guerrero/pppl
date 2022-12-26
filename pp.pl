#!/usr/bin/perl
# ------------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2022-Present Miguel A. Guerrero
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Please send bugs and suggestions to: miguel.a.guerrero@gmail.com
# ------------------------------------------------------------------------------
# command line option defaults
my $verbose = 1;
my $execIps = 1;
my $comment = 1;
my $dstDir = ".";
my $fileTmp = "pp_tmp_$$.pl";
my $keepTmp = 0;
my @include_paths = ();
my $outFileName = "";
my $shParams = "";
my $cs = "//"; 
my $ce = "";
my @params = ();
my $startPerl = "\%";
my $funcCall = '';
my $opEval = '\\$\\(\\(';
my $clEval = '\\)\\)';
my $macroCall = '\@';
my @inFileList = ();
# end of command line option defaults

my $funcRestPat = '\s*|\s*;\s*';
my $funcParsReq = 0;
my $argSep = ',';
my $emitLine = 0;
my $debug = 0;
my $eol = "\\n";
my %funcSeen = ();

our $pp_curr_line;
our $pp_capture_lvl;

our $pp_line;
our $pp_file;

our @pp_line;
our @pp_file;

our %pp_arg_sep;
our %pp_capture_on;
our %pp_capture_off;

# --- rememember command line
my @CMD = @ARGV;

# --- get the path of the executable
my $execPath = &getPath($0);

# --- parse command line arguments
if ($#ARGV == -1) { 
   &Usage;
}
&ParseCmdLineArgs;

# --- get file type based on file extension
my $ext = &getExtension($inFileList[0]);
my $type = "";
# if there is a directory matching extension
# that's what is used
if (-d "${execPath}$ext") { $type = $ext; }
# if not we use an extension to type mapping
else { $type = &getType($inFileList[0]); }
print "filetype = $type\n" if $verbose > 0;

# --- preload a general include file (if existing)
my $allow_non_existing = 1;
&perl_include("${execPath}autoloads/pp_begin.pl", $allow_non_existing);

# --- preload a include file based on file type (if existing)
&perl_include("${execPath}autoloads/$type/pp_begin.pl", $allow_non_existing) if ($type ne "");

# if output outFileName explicitly given
if ($outFileName ne "") { 
   if ($#inFileList != 0) {
      print STDERR "ERROR: -o specified and more than one input file given\n";
      exit(1);
   }
   &prepOne($inFileList[0], $outFileName);
}
else {
   # output filename derived from input one
   foreach my $inFileName (@inFileList) {
      my $fileOut = `basename $inFileName`;

      if ($fileOut =~ /^pp\.(.*)$/) {
         $fileOut = $1;
         chomp $fileOut;
      }
      else {
         print STDERR "WARNING: expecting pp. prefix\n";
         $fileOut = $inFileName;
      }
      &prepOne($inFileName, $fileOut);
   }
}

&perl_include("${execPath}autoloads/$type/pp_end.pl", $allow_non_existing) if ($type ne "");
&perl_include("${execPath}autoloads/pp_end.pl", $allow_non_existing);

exit(0);

#--------------------------------------------
# preprocess a single file and report errors
# if any
#--------------------------------------------
sub prepOne {
   my ($fileIn, $fileOut) = @_;
   print "Generating $fileOut ...\n" if ($verbose > 0) && $execIps;
   my $rc = &prepFile($fileIn, $fileOut);
   if ($rc != 0) {
      print "Some error found on Perl code.\n";
      exit($rc) 
   }
}

#--------------------------------------------
# Preprocess a single file
#--------------------------------------------
sub prepFile {

   my ($fileIn, $fileOut) = @_;

   my $pathTmp = "$dstDir/$fileTmp";

   # --- generate the file to execute in Perl
   &genIps($fileIn, $pathTmp);
   
   # --- make the generated file executable
   &backquote("chmod +x $pathTmp");

   if ($execIps) {
      # --- execute the generated file
      $fileOut = &execIps($pathTmp, $fileOut);
   }

   # remove temporary file unless it was requested to keep it
   &sys("/bin/rm $pathTmp") unless $keepTmp;

   return 0;
}

#--------------------------------------------
# Generate Intermediate Perl script
#--------------------------------------------
sub genIps {
   my ($fileIn, $pathTmp) = @_;

   my $pgm = &getBase($0);  # remove the path of the script
   my $shellPath = "$^X $shParams";
   
   open(fout,"> $pathTmp") || 
      die ("ERROR: [" . pwd() . "] Couldn't create intermediate Perl script $pathTmp");

   &emit("#!$shellPath" );

   if ($comment) {
      my @cmnt;
      $cmnt[0] = "----------------------------------------------------------";
      $cmnt[1] = " File automatically generated by pp preprocessor";
      $cmnt[2] = " Please ***DO NOT EDIT***. Perform changes on SOURCE FILE";
      $cmnt[3] = " CMD LINE: $pgm @CMD";
      $cmnt[4] = "----------------------------------------------------------";
      for my $i (0..$#cmnt) {
         &emit("print qq{$cs $cmnt[$i] $ce$eol};");
      }
   }

   # emit include paths
   for my $p (@include_paths) {
      &emit("push \@include_paths, \"$p\";");
   }

   # output command line parameters as $var=value statements
   for my $param (@params) {
      &emit("\$$param;");
   }

   # copy these files verbatim into IPS if they exist
   &emitFile("${execPath}autoloads/pp_lib.pl");
   &emitFile("${execPath}autoloads/$type/pp_lib.pl") if ($type ne "");

   $pp_capture_lvl = 0;
   &emitCaptureLvl;
   
   # process the input file as if it was included with pp_include
   $pp_line = 1;  # reset line count
   &pp_include($fileIn);

   &emit("exit 0;");
   close(fout);
}


#--------------------------------------------
# Execute Intermediate Perl script and return
# file name of result
#--------------------------------------------
sub execIps {
   my ($pathTmp, $fileOut) = @_;

   my $outIsTmp = $fileOut eq "/dev/stdout";
   if ($outIsTmp) {
       $fileOut = "pp_out_tmp_$$.pl";
   }
   else {
       $fileOut = "$dstDir/$fileOut";
   }

   # execute the intermediate perl script
   &sys("$pathTmp > $fileOut"); 

   # check to see if there is a // PP_FILENAME='file' directive
   my $ren = backquote("grep '${cs}[ \t]*PP_FILENAME=' $fileOut");
   if ($ren ne "") {
      # if so extract the new name of the output file (programatically
      # generated)
      if ($ren =~ /PP_FILENAME\s*=\s*\"(.*?)\"/) {
         if ($outIsTmp) {
             print STDERR "ERROR: PP_FILENAME not supported when output is stdout\n";
             exit(1);
         }
         $ren = "$dstDir/$1";
         print "Renaming output to $ren\n";
         &sys("mv -f $fileOut $ren");
         $fileOut = $ren;
      }
      else {
         print STDERR "ERROR: PP_FILENAME found but outFilename format incorrect\n";
         print STDERR "ERROR: use ${cs} PP_FILENAME=\"output_fname\"\n";
         print STDERR "ERROR: $ren";
         exit(1);
      }
   }
   if ($outIsTmp) {
       &sys("cat $fileOut");
       &sys("rm -f $fileOut");
   }
   return $ren;
}


#--------------------------------------------
# include a PP file
#--------------------------------------------
sub pp_include {
   my ($fileIn) = @_;

   my $finalPath = ".";
   for my $p (@include_paths) {
      if (-f "$p/$fileIn") { $finalPath = $p; last; }
   }
   $fileIn = "$finalPath/$fileIn";

   print STDERR "Entering $fileIn\n" if $verbose > 0;
   &emit("#entering $fileIn");
   local *fin;
   open(fin,"$fileIn") || die "ERROR: cannot pp_include($fileIn)\n";
   $pp_file = $fileIn;
   while (<fin>) {
      $pp_curr_line = $_;
      local $" = ",";
      my $end = chomp;
      my $iter = 0;
      my $done;
      do {
         $done = 1;
         # a per command is just emitted as-is
         if (/^$startPerl(.*)/) {   # Line contains a command 
            &emit($1);              # spit the command
         }
         # if there is a function call pattern, use it to detect them
         elsif ($funcCall ne "" && /^(\s*)$funcCall\s*(\w+)\s*(.*)/) {
            my ($ind, $func, $args) = ($1, $2, $3);
            &emit("print qq{$ind$cs -- $func $args $ce$eol};");
            &pp_func($ind, $func, $args);
         }
         # if not functions can be called raw if declared before
         elsif ($funcCall eq "" && /^(\s*)(\w+)\s*(.*)/ && $funcSeen{$2}) {
            my ($ind, $func, $args) = ($1, $2, $3);
            &emit("print qq{$ind$cs -- $func $args $ce$eol};");
            &pp_func($ind, $func, $args);
         }
         # evaluate an expression and paste its output on the output
         elsif (/^(.*?)$opEval(.*)$clEval(.*)/) {
            my ($pre, $expr, $post) = ($1, $2, $3);
            &emit("{ my \$__pp_t$iter = ($expr);");
            s/^(.*?)($opEval(.*)$clEval)(.*)/$1\${__pp_t$iter}$4/;
            $done = 0;  # iterate once again with the remaining $_
            $iter++;
         }
         # see if this matches the pattern for parsing time func/macro-call
         elsif (/^(\s*)$macroCall(\w+)\s*(.*)/) {
            my ($ind, $func, $args) = ($1, $2, $3);
            my @pars = &pp_get_pars($func, $args);
            push @pp_file, $pp_file;
            push @pp_line, $pp_line;
            my $res = eval("\&$func(@pars);");
            if (! defined $res) { die("ERROR: in macro call $func\n"); }
            $pp_line = pop @pp_line;
            $pp_file = pop @pp_file;
            &emit("# -- result of &$func(@pars); --");
            &emit("$res");
            &emit("# -- end result of &$func(@pars); --");
         }
         else {                                
            if ($pp_capture_lvl > 0) {
               # we are capturing text, not emitting it, quote if needed
               s/([\\"'\@\$])/\\$1/g;        # quote \ ' " $ @
               s/\\([\$\@])\{/$1\{/g;        # unquote $ @ if followed by {
               &emit("\$pp_captured\[$pp_capture_lvl\] .=  \"$_$eol\";");
               $pass1_pp_captured[$pp_capture_lvl] .= "$_$eol";
               &checkCaptureDone;
            }
            else {
               # Line is to be copied verbatim. Do necessary quoting
               s/^\\$startPerl/$startPerl/;  # if 1st char is \ remove the quote
               s/([\\"'\@\$])/\\$1/g;        # quote \ ' " $ @
               s/\\([\$\@])\{/$1\{/g;        # unquote $ @ if followed by {
               &emit("print \"$_$eol\";");   # generate a print command
            }
         }
      } while (!$done);
      # this completer the nesting closing if $(...expr...) where nested
      for(my $j = $iter-1 ; $j >= 0; $j--) {
         &emit("} # __pp_t$j");
      }
      $pp_line++;
   }
   close(fin);
   print STDERR "Leaving  $fileIn\n" if $verbose > 0;
   &emit("#leaving $fileIn");
   return "";
}


# --- process a PP function
sub pp_func {
   my ($ind, $fname, $parList) = @_;
   my @pars = &pp_get_pars($fname, $parList);
   &emit("\$pp_src_indent=\"$ind\"; \&$fname(@pars);");
   &checkCaptureMode($fname);
}


# --- get parameters of a PP function call
sub pp_get_pars {
   my ($fname, $parList) = @_;
   my $sep = $argSep;
   if (defined $pp_arg_sep{$fname}) { $sep = $pp_arg_sep{$fname} }
   # trim parameter list
   $parList =~ s/^\s*//;
   $parList =~ s/\s*$//;
   # extract parameters
   my @pars = ();
   my $funcRest;
   if ($parList =~ /\((.*)\)(.*)/ ) {
      my ($p, $funcRest) = ($1, $2);
      @pars = split(/\s*$sep\s*/, $p);
      unless ($funcRest =~ $funcRestPat) {
         &ppWarn("Extra unexpected chars found : <$funcRest>");
      }
   }
   else {
      if (!$funcParsReq) {
         $parList =~ s/(${funcRestPat})$//;
         @pars = split(/\s*$sep\s*/, $parList);
      }
      else {
         &ppError("Invalid par list: $parList");
      }
   }
   @pars = map { /^".*"$/ ? $_ : "\"$_\"" } @pars;
   return @pars;
}


my $lastLine;
sub emit {
   my ($cmd) = @_;
   if ($emitLine && $lastLine != $pp_line) { 
      print fout "#line $pp_line\n"; 
      $lastLine = $pp_line; 
   }
   if ($cmd =~ /\s*sub\s+(\w+)/) { $funcSeen{$1} = 1; }
   print fout "${cmd}\n";
}


sub checkCaptureMode {
   my ($fname) = @_;
   if (defined $pp_capture_off{$fname}) {
      $pp_capture_lvl--;
      &emitCaptureLvl;
   }
   if (defined $pp_capture_on{$fname}) {
      $pp_capture_lvl++;
      &emitCaptureLvl;
      &emit("\$pp_captured\[$pp_capture_lvl\]=\"\"; ");
      $pass1_pp_captured[$pp_capture_lvl] = "";
      $pass1_pp_capture_ctx[$pp_capture_lvl] = "$fname";
   }
}

sub checkCaptureDone {
   if (!$found) {
      # if there is a function that determines whether catpure should end
      my $sub_name =$pp_capture_mon{$pass1_pp_capture_ctx[$pp_capture_lvl]};
      if (defined $sub_name) {
         # invoke it to check if we need to end capture
         if (&$sub_name) {  # see if the function returns true
            $pp_capture_lvl--;
            &emitCaptureLvl;
         }
      }
   }
}

sub emitCaptureLvl {
   &emit("\$pp_capture_lvl=$pp_capture_lvl;");
}

# --- include a Perl file by eval'ing its contents
sub perl_include {
   my ($file, $allow_non_existing) = @_;
   my $finalPath = ".";
   for my $p (@include_paths) {
      if (-f "$p/$file") { $finalPath = $p; last; }
   }
   if (! -f "$finalPath/$file") {
      if ($allow_non_existing == 1) {
         return 1;
      }
      else {
         print STDERR "ERROR: [$ENV{PWD}] cannot include $file\n";
         exit 1;
      }
   }
   print STDERR "Including <$finalPath/$file>\n" if $verbose > 0;
   my $t = `cat $finalPath/$file`;
   my $rc = eval("$t; 1;");
   if ($rc != 1) { 
     exit 1;
   }
}

# --- emit a file into the Ips
sub emitFile {
   my ($file) = @_;
   open(fin2, "$file") || return 1;
   &emit("# start of '$file'");
   while (<fin2>) { chomp; &emit($_); }
   &emit("# end of '$file'");
   close(fin2);
   return 0;
}

# --- map from extension to file type
sub getType {
   my ($file) = @_;
   my $type = "";
   if ($file =~ /^(.*)\.(.*)$/) {
      $type = $2;
   }
   if ($type eq "vh" || $type eq "vb") { $type = "v"; }
   elsif ($type eq "h") { $type = "c"; }
   elsif ($type eq "hpp" || $type eq "H" || 
          $type eq "cc" || $type eq "cxx" || $type eq "C") { $type = "cpp"; }
   return $type;
}

#--------------------------------------------
# Syntax info
#--------------------------------------------
sub Usage {

   print<<EOF 

 Perl Based Preprocessor

 USAGE: $0 [options] outFilename.ext ...

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
     -d  dir  : Destination directory for resulting file (def $dstDir)
     -cs str  : Specify comment start sequence (def \'$cs\')
     -ce str  : Specify comment end sequence (def \'$ce\')
     -ps str  : Specify start escape character for Perl code (def \'$startPerl\')
     -ms str  : Specify start escape character for phase 1 calls (def \'$macroCall\')
     -ts str  : Specify start escape character for phase 2 calls (def \'$funcCall\')
     -es str  : Specify start escape character for Perl eval (def \'$opEval\')
     -ee str  : Specify end   escape character for Perl eval (def \'$clEval\')
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

EOF
;
   exit(1);
}


#--------------------------------------------
# Parses the commane line arguments
#--------------------------------------------
sub ParseCmdLineArgs () {
   my $i = 0;
   while ($i <= $#ARGV) {
      my $opt = $ARGV[$i];
      my $flag= ($opt =~ s/^-no/-/) ? 0 : 1;

      if    ($opt eq "-q")   { $verbose = 0; }
      elsif ($opt eq "-c")   { $execIps = 0; }
      elsif ($opt eq "-n")   { $comment = 0; }
      elsif ($opt eq "-d")   { $dstDir    = $ARGV[++$i]; }
      elsif ($opt eq "-ips") { $fileTmp   = $ARGV[++$i]; $keepTmp = 1; }
      elsif ($opt eq "-I")   { push @include_paths, $ARGV[++$i]; }
      elsif ($opt eq "-o")   { $outFileName  = $ARGV[++$i]; }
      elsif ($opt eq "-pp")  { $shParams  = $ARGV[++$i]; }
      elsif ($opt eq "-cs")  { $cs        = $ARGV[++$i]; }
      elsif ($opt eq "-ce")  { $ce        = $ARGV[++$i]; }
      elsif ($opt eq "-p")   { push @params,$ARGV[++$i]; }
      elsif ($opt eq "-ps")  { $startPerl = '\\' . $ARGV[++$i]; }
      elsif ($opt eq "-ts")  { $funcCall = ($flag ? $ARGV[++$i] : ""); }
      elsif ($opt eq "-es")  { $opEval = $ARGV[++$i]; }
      elsif ($opt eq "-ee")  { $clEval = $ARGV[++$i]; }
      elsif ($opt eq "-ms")  { $macroCall = '\\' . $ARGV[++$i]; }
      elsif ($opt eq "-h")   { &Usage(); }
      elsif ($opt =~ /^-/) {
         print STDERR "ERROR: Unknown option $ARGV[$i]\n";
         &Usage();
      }
      else { push @inFileList, $ARGV[$i]; }
      $i++;
   }
   if ($#inFileList < 0) {
      print STDERR "ERROR: no input file given\n";
      &Usage();
   }
   if ($outFileName eq "-") {
       $outFileName = "/dev/stdout";
   }
}

#--------------------------------------------
# Display a warning/error message with offending
# line
#--------------------------------------------
sub ppWarn {
   my ($msg) = @_;
   print "WARNING(${pp_file}:${pp_line}): $msg\n";
   print "> $pp_curr_line";
}

sub ppError {
   my ($msg) = @_;
   print "ERROR(${pp_file}:${pp_line}): $msg\n";
   print "> $pp_curr_line";
   exit(1);
}

#--------------------------------------------
# File name utility functions
#--------------------------------------------

sub getExtension {
   my $file = shift;
   $file =~ s/^.*\.//;
   return $file;
}

sub getPath {
   my $path = shift;
   if ($path =~ /\//) {
      $path =~ s/^(.*\/)(.*)/\1/;
   }
   else {
      $path = "";
   }
   return $path
}

sub getBase {
   my $path = shift;
   $path =~ s/^.*\///;  # remove the path of the script
   return $path;
}

#--------------------------------------------
# General utility functions
#--------------------------------------------

# execute an external command, must succeed or will die with error
sub sys {
   my ($cmd) = @_;
   print "$cmd\n" if $debug;
   my $rc = system("$cmd");
   if ($rc) {
      die("ERROR: [" . pwd() . "] executing \"$cmd\"\n");
   }
}


# execute an external command, return the return code
sub sys_rc {
   my ($cmd) = @_;
   print "$cmd\n" if $debug;
   my $rc = system("$cmd");
   return $rc;
}

# execute an external command, return its stdout
sub backquote {
   my ($cmd) = @_;
   print "\`$cmd\`" if $debug;
   my $txt = `$cmd`;
   print " -> $txt\n" if $debug;
   return $txt;
}

# return current working dir
sub pwd {
   my $pwd = `pwd`;
   chomp $pwd;
   return $pwd;
}
