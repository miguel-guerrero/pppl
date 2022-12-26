# This file is copied at the beggining of the perl version of
# your file to pre-process, so all functions here are available
# on your embedded perl code

sub perl_include {
   my ($file, $allow_non_existing) = @_;
   my $finalPath=".";
   for my $p (@include_paths) {
      if (-f "$p/$file") { $finalPath=$p; last; }
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
   my $t = `cat $finalPath/$file`;
   my $rc = eval("$t; 1;");
   if ($rc != 1) { 
     exit 1;
   }
}

# Output the maximum element of an array
sub max {
   my($max) = pop(@_);
   foreach my $foo (@_) {
      $max = $foo if $foo >= $max;
   }
   return $max;
}

# Output the minimum element of an array
sub min {
   my($min) = pop(@_);
   foreach my $foo (@_) {
      $min = $foo if $foo <= $min;
   }
   return $min;
}

# number of bits to hold a given ammount
sub bits_of {
   my($x) = @_;
   my $bits=0;
   my $values_held=1;
   while ($x > $values_held) {
      $values_held *= 2;
      $bits++;
   }
   return $bits;
}

sub clog2 {
   my($x) = @_;
   my $y=log($x)/log(2);
   if ($y != int($y)) { $y=int($y)+1; }
   return $y;
}

sub str_indent {
  my ($msg) = @_;
  return "${pp_src_indent}$msg\n";
}

sub str_indent_nonl {
  my ($msg) = @_;
  return "${pp_src_indent}$msg";
}

sub indent {
  print &str_indent(@_);
}

sub indent_nonl {
  print &str_indent_nonl(@_);
}

sub GetLabel {
  $mlabelid++;
  return "__pp__$mlabelid";
}

sub SyntaxErr {
  my ($msg) = @_;
  die "Syntax Error: $msg";
}

sub pp_error {
   my ($msg) = @_;
   print "ERROR: $msg\n";
   print STDERR "ERROR: $msg\n";
   print "> $pp_curr_line";
   exit(1);
}

