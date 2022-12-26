#This code is *executed* before your file is pre-processed

sub MacroDef {
   my ($name, @pars) = @_;
   local $"=",\$";
   my $res = "sub $name {\n";
   if ($#pars >= 0) {
      $res .= "my (\$@pars) = \@_;\n";
   }
   return $res;
}

sub MacroEnd {
   return "}\n";
}

sub in_list {
   my ($item, @list) = @_;
   foreach my $x (@list) {
      if ($item eq $x) { return 1; }
   }
   return 0;
}

sub max {
   my (@lst) = @_;
   my $m = $lst[0];
   for my $i (1..$#lst) {
      $m = $lst[$i] > $m ? $lst[$i] : $m;
   }
   return $m;
}


sub find_closing {
   my ($msg, $seek_pair, @avoid_pairs) = @_;
   my $dbg = 0;
   if ($#avoid_pairs < 0) {
      #if there are 2 commas it means the closing can be found
      #without the operning without giving an error
      @avoid_pairs = ('","',"','", "/*,*/","//,\n,noerr");
   }
   print "avoid_pairs=@avoid_pairs\n" if $dbg;
   my @seek_pair = split ",", $seek_pair;
   my $max_token_len;
   my @beg_avoid;
   my @end_avoid;
   my %opening;
   my @stk;
   my %no_err;

   $max_token_len = &max (length($seek_pair[0]), length($seek_pair[1]));
   foreach my $pair (@avoid_pairs) {
      my @l = split ",", $pair;
      push @beg_avoid, $l[0];
      push @end_avoid, $l[1];
      $opening{$l[1]} = $l[0];
      if (defined $l[2]) {
         $no_err{"$l[1]"} = 1;
      }
      $max_token_len = &max ( $max_token_len, length($l[0]), length($l[1]));
   }
   for (my $i=0; $i<length($msg) ; $i++) {
      for my $token_len (1 .. $max_token_len) {
         my $ch = substr($msg, $i, $token_len);
         print "<$ch>\n" if $dbg;
         if (&in_list($ch, @beg_avoid) && !($#stk >= 0 && $ch eq $stk[$#stk] && in_list($ch,@end_avoid)) ) {
            push @stk, $ch;
            print "ch=$ch stk=<@stk>\n" if $dbg;
            $i += $token_len - 1;
            last;
         }
         elsif (&in_list($ch, @end_avoid)) {
            if ($#stk == -1 || $opening{$ch} ne $stk[$#stk]) {
               if (!$no_err{"$ch"}) { die "ERROR: Found unmatched closing <$ch>"; }
            }
            else {
               pop @stk;
               print "ch=$ch stk=<@stk>\n" if $dbg;
            }
            $i += $token_len - 1;
            last;
         }
         elsif ($ch eq $seek_pair[0]) {
            if ($#stk == -1 || !&in_list($stk[$#stk], @beg_avoid)) { 
               push @stk, $ch; 
               print "ch=$ch stk=<@stk>\n" if $dbg;
            }
            $i += $token_len - 1;
            last;
         }
         elsif ($ch eq $seek_pair[1]) {
            if ($#stk == -1) {
               die "ERROR: Found unmatched closing <$ch>";
            }
            if (!&in_list($stk[$#stk], @beg_avoid)) { 
               if ($#stk == -1 || $stk[$#stk] ne $seek_pair[0]) {
                  die "ERROR: Found unmatched closing <$ch>";
               }
               pop @stk;
               print "ch=$ch stk=<@stk>\n" if $dbg;
               if ($#stk == -1) {
                  return $i+1;
               }
            }
            $i += $token_len - 1;
            last;
         }
      }
   }
   return -1;
}
