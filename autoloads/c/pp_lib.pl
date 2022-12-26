#this is copied into ips.pl for pass2

sub pp_error {
   my ($msg) = @_;
   print STDERR "ERROR(${pp_file}:${pp_line}): $msg\n";
   print "> $pp_curr_line";
   exit(1);
}

#-----------------------------------------------------------------------------

sub Cover {
   my ($var, @ranges) = @_;
   indent "{ int cover;";
   foreach my $r (@ranges) {
      my ($lo,$hi) = split(/\s*:\s*/, $r);
      if    ($lo eq "") { indent "   if ($var <= $hi)"; }
      elsif ($hi eq "") { indent "   if ($lo <= $var)"; }
      else              { indent "   if ($lo <= $var && $var <= $hi)"; }
      indent "      cover++;";
   }
   indent "}";
}

#-----------------------------------------------------------------------------

sub ForUnwrap {
  my ($var, $limit, $init, $incr) = @_;
  if (!defined ($init)) { $init = 0; }
  if (!defined ($incr)) { 
     $incr = 1; 
     if ($limit < $init) { $incr = -1; }
  }
  $mlevel++;
  $mtype[$mlevel] = "for_unwrap";
  $mpars[$mlevel] = [$var, $limit, $init, $incr];
}

sub ForUnwrapEnd() {
  my ($var, $limit, $init, $incr) = @{$mpars[$mlevel]};
  $mlevel--;
  my $res = str_indent "// $var, $init .. $limit, $incr";
  if ($limit > $init) {
     for(my $i=$init; $i < $limit; $i+=$incr) {
        $res .= str_indent "{ int $var = $i; ";
        $res .= str_indent_nonl "$pp_captured[$pp_capture_lvl]";
        $res .= str_indent "}";
     }
  }
  else {
     for(my $i=$init; $i > $limit; $i+=$incr) {
        $res .= str_indent "{ int $var = $i; ";
        $res .= str_indent_nonl "$pp_captured[$pp_capture_lvl]";
        $res .= str_indent "}";
     }
  }
  if ($pp_capture_lvl > 1) {
     $pp_captured[$pp_capture_lvl-1] .= $res;
  }
  else {
     print $res;
  }
}

sub End() {
  if ($mtype[$mlevel] eq "for_unwrap") {
     ForUnwrapEnd; 
  }
}

#-----------------------------------------------------------------------------

sub syn_unwrap_beg {
  my ($times) = @_;
  $mlevel++;
  $mtype[$mlevel] = "for_unwrap";
  $mpars[$mlevel] = [$times];
}

sub syn_unwrap_get_incr {
   my ($var, $incr_stm, ) = @_;
   my $incr = 0;
   if ($incr_stm =~ /$var\s*\+\+/ || $incr_stm =~ /\+\+\s*$var/) {
      $incr = 1;
   }
   elsif ($incr_stm =~ /$var\s*\-\-/ || $incr_stm =~ /\-\-\s*$var/) {
      $incr = -1;
   }
   elsif ($incr_stm =~ /$var\s*\+\=\s*(.*)/) {
      $incr = eval($1);
   }
   elsif ($incr_stm =~ /$var\s*\-\=\s*(.*)/) {
      $incr = -eval($1);
   }
   else {
      pp_error("Cannot parse increment portion of loop <$incr_stm> var=<$var>");
   }
   if ($incr == 0) {
      pp_error("Incrementa cannot be eval'ed or is zero in syn_unwrap_for");
   }
   return $incr;
}

sub syn_unwrap_get_limit {
   my ($var, $cond) = @_;
   if ($cond =~ /$var\s*<=\s*(.*)/) {
      $limit = eval($1);
   }
   elsif ($cond =~ /$var\s*<\s*(.*)/) {
      $limit = eval($1) - 1;
   }
   elsif ($cond =~ /$var\s*>=\s*(.*)/) {
      $limit = eval($1);
   }
   elsif ($cond =~ /$var\s*>\s*(.*)/) {
      $limit = eval($1) + 1;
   }
   if ($limit > $var_init) {
      pp_error("for loop has reversed increment") if ($incr < 0)
   }
   elsif ($limit < $var_init) {
      pp_error("for loop has reversed increment") if ($incr > 0)
   }
   return $limit;
}

sub syn_unwrap_end() {
  my ($times) = @{$mpars[$mlevel]};
  $mlevel--;
  my $res; 
  my @line = split(/\n/, $pp_captured[$pp_capture_lvl]);
  my $inner = "";
  if ($line[0] =~ /^\s*for\s*\((.*)/) {
    my $rest = $1;
    if ($rest =~ /(.*)\)\s*\{\s*$/) {
      $inner = $1;
      $inner =~ s/^\s+//;
      $inner =~ s/\s+$//;
    }
    else {
      &pp_error("Expecting for....') {' while scanning <$rest>");
    }
  }
  else {
    &pp_error("Expecting 'for('.....");
  }
  unless ($line[$#line] =~ /^\s*}\s*$/) {
    &pp_error("Expecting '}' at end of unwrap loop while scanning $line[$#line]");
  }
  $pp_captured[$pp_capture_lvl] = join("\n", @line[1..$#line-1]);
 
  my ($var_asgn, $cond, $incr_stm) = split(/\s*;\s*/, $inner);
  my ($var, $var_init) = split(/\s*=\s*/, $var_asgn);
  my $var_type;

  if ($var =~ /(\S+)\s+(\S+)/) {
     $var = $2;
     $var_type = $1;
  }
  $var_init = eval($var_init);
  $incr = &syn_unwrap_get_incr($var, $incr_stm);
  $limit = &syn_unwrap_get_limit($var, $cond);

  if ($times > 0) { #partial unroll

     my $loops = ($limit - $var_init + 1) / $incr;
     my $mod = $loops % $times;

     $res .= str_indent "{";
     $res .= str_indent "   $var_asgn;";
     for my $i (1..$mod) {
        $res .= str_indent "$pp_captured[$pp_capture_lvl]";
        $res .= str_indent "   $incr_stm;";
     }
     $loops = ($loops - $mod) / $times;
     $res .= str_indent "   while ($cond) {" if $loops > 1;
     for my $i (1..$times) {
        $res .= str_indent "$pp_captured[$pp_capture_lvl]";
        $res .= str_indent "      $incr_stm;";
     }
     $res .= str_indent "   }";
     $res .= str_indent "}" if $loops > 1;
  }
  else { #full unroll

     $res .= str_indent "{  $var_type $var;";
     if ($var_init < $limit) {
        for my $i ($var_init..$limit) {
           $res .= str_indent "   $var=$i;";
           $res .= "$pp_captured[$pp_capture_lvl]\n";
        }
     }
     else {
        for(my $i=$var_init; $i >= $limit ; $i += $incr) {
           $res .= str_indent "   $var=$i;";
           $res .= "$pp_captured[$pp_capture_lvl]\n";
        }
     }
     $res .= str_indent "}";
  }

  if ($pp_capture_lvl > 1) {
     $pp_captured[$pp_capture_lvl-1] .= $res;
  }
  else {
     print $res;
  }
}

sub syn_unwrap {
   &syn_unwrap_beg(@_);
}

