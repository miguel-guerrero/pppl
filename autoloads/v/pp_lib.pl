# -----------------------------------------------------------------------------
# General utility functions
# -----------------------------------------------------------------------------

# Sign extend a bus to a given width
sub sign_extend {
   my ($var, $out_w, $in_w, $in_lsb) = @_;
   if (!defined ($in_lsb)) { $in_lsb = 0; }
   my $in_msb = $in_lsb + $in_w - 1;
   if ($in_w < $out_w) {
      # real sign extension
      my $extl = $out_w - $in_w;
      return "{ {$extl {$var\[$in_msb]}}, $var\[${in_msb}:${in_lsb}] }";
   }
   elsif ($in_w == $out_w) {
      # no need to change
      return "$var\[${in_msb}:${in_lsb}]";
   }
   else {
      # truncation
      my $msb = $in_lsb + $out_w - 1;
      return "$var\[${msb}:${in_lsb}]";
   }
}

# Exsamples of use
#
# $x = &sign_extend(x, 20, 10);
# $x = &sign_extend(x, 10, 10);
# $x = &sign_extend(x,  3, 10, 2);


# Logicaly (zero) extend a bus to a given width
sub logic_extend {
   my ($var, $out_w, $in_w, $in_lsb) = @_;
   if (!defined ($in_lsb)) { $in_lsb = 0; }
   my $in_msb = $in_lsb + $in_w - 1;
   if ($in_w < $out_w) {
      # real extension
      my $extl = $out_w - $in_w;
      return "{$extl\'b0, $var\[${in_msb}:${in_lsb}] }";
   }
   elsif ($in_w == $out_w) {
      # no need to change
      return "$var\[${in_msb}:${in_lsb}]";
   }
   else {
      # truncation
      my $msb = $in_lsb + $out_w - 1;
      return "$var\[${msb}:${in_lsb}]";
   }
}

# Select a range out of a variable given lsb and width
sub bit_select {
   my ($var, $width, $lsb) = @_;
   my $msb = $lsb + $width - 1;
   return "$var\[${msb}:${lsb}]";
}

# --- used by Task/Proc below to parse IO list ---
sub getDirTypeVar {
  my ($combo) = @_;
  $combo =~ s/^\s+|\s+$//g;  # trim spaces
  $combo =~ s/\s+/ /g;  # make inner spaces single ones
  if ($combo =~ /((.*) )?(\S+)/) {
     my ($var, $type, $dir) = ($3, $2, "in");
     if ($type =~ /(in|io|out)\s*(.*)/) {
        $dir = $1;
        $type = $2;
     }
     return ($dir, $type, $var);
  }
  &SyntaxErr("invalid port decl in TaskDef: $combo\n");
}

# -----------------------------------------------------------------------------
# Control structures not handled yet by AlgoFSM. This code emits 
# handled equivalents
# -----------------------------------------------------------------------------
# --- define a loop of $count iters, and convert it to a while statement ---
sub Repeat {
  my ($var, $count) = @_;
  my ($init, $cond, $post) = @_;
  $mlevel++;
  $mtype[$mlevel] = "repeat";
  $mpost[$mlevel] = "$var = $var + 1'b1";
  indent "$var = 0;";
  indent "while ($var < $count) begin";
}

sub RepeatEnd() {
  my $post = $mpost[$mlevel--];
  indent "   ${post};";
  indent "end";
}

# ---- coverts a switch/case into if/elsif/else ---
sub Switch {
  my ($cond) = @_;
  $mlevel++;
  $mtype[$mlevel] = "switch";
  $mcond[$mlevel] = $cond;
  $mcasecnt[$mlevel] = 0;
}

sub Case {
  my ($val) = @_;
  my $cond = $mcond[$mlevel];
  if ($mcasecnt[$mlevel] == 0) {
    indent "if ($cond == ($val)) begin";
  } else {
    indent "end";
    indent "else if ($cond == ($val)) begin";
  }
  $mcasecnt[$mlevel]++;
}

sub Default {
  if ($mcasecnt[$mlevel] == 0) {
  } else {
    indent "end";
    indent "else begin";
  }
  $mcasecnt[$mlevel]++;
}

sub SwitchEnd() {
  $mlevel--;
  indent "end";
}

# -----------------------------------------------------------------------------
# Define a task, the code is inlined at the point of call
# -----------------------------------------------------------------------------
sub TaskDef {
  my ($name, @arg_ios) = @_;
  $mlevel++;
  push @mtasks, $name;
  $mtype[$mlevel] = "taskdef";
  my @ios;
  my @dir;
  my @type;
  foreach my $port (@arg_ios) {
     my ($dir, $type, $var) = getDirTypeVar($port);
     push @ios, $var;
     push @dir, $dir;
     push @type, $type;
     $mtaskios{$name} = [ @ios ];
     $mtaskdir{$name} = [ @dir ];
     $mtasktype{$name} = [ @type ];
  }
}

sub TaskDefEnd() {
  $mlevel--;
  my $name = $mtasks[$#mtasks];
  $mtaskcode{$name} = $pp_captured[1];
}

# --- invoke a task ---
sub Task {
  my ($name, @ios) = @_;
  $mlevel++;
  my @taskios = @{$mtaskios{$name}};
  my @taskdir = @{$mtaskdir{$name}};
  my @tasktype = @{$mtasktype{$name}};
  my $i=0;
  my $lbl=GetLabel();
  indent "begin: __pp_blk${lbl}";
  foreach my $k (0..$#taskios) {
     indent "   reg $tasktype[$k] $taskios[$k];";
  }
  foreach my $actual (@ios) {
    my $formal = $taskios[$i];
    if ($taskdir[$i] ne "out") {
      indent "   ${formal} = ${actual};";
    }
    $i++;
  }
  foreach my $line (split(/\n/, $mtaskcode{$name})) {
     indent "${line}";
  }
  $i=0;
  foreach my $actual (@ios) {
    my $formal = $taskios[$i];
    my $dir    = $taskdir[$i++];
    my ($dummy, $dummy2, $formal_no_decl) = getDirTypeVar($formal);
    if ($dir ne "in") {
       indent "   ${actual} = ${formal_no_decl};";
     }
  }
  indent "end // __pp_blk${lbl}";
}

# -----------------------------------------------------------------------------
# Define a procedure, which becomes a separate FSM that can run in parallel
# with other logic
# -----------------------------------------------------------------------------
sub ProcDef {
  my ($name, @arg_ios) = @_;
  $mlevel++;
  push @mprocs, $name;
  $mtype[$mlevel] = "procdef";
  my @ios;
  my @dir;
  my @type;
  indent "// procdef_begin";
  indent "reg ${name}__go;";
  foreach my $port (@arg_ios) {
     my ($dir, $type, $var) = getDirTypeVar($port);
     push @ios, $var;
     push @dir, $dir;
     push @type, $type;
     $mprocios{$name} = [ @ios ];
     $mprocdir{$name} = [ @dir ];
     $mproctype{$name} = [ @type ];
     if ($dir eq "in") {
         indent "reg $type ${name}__${var} = 'b0;";
     }
  }
  indent "SmBegin";
  foreach my $port (@arg_ios) {
     my ($dir, $type, $var) = getDirTypeVar($port);
     if ($dir eq "out") {
         indent "    reg $type ${name}__${var} = 'b0;";
     }
  }
  indent "reg ${name}__done = 1'b0;";
  foreach my $port (@arg_ios) {
     my ($dir, $type, $var) = getDirTypeVar($port);
     indent "   local reg $type ${var} = 'b0;";
  }
  indent "SmForever";
  indent "   while ( ${name}__go == 1'b0 ) `tick;";
  foreach my $port (@arg_ios) {
     my ($dir, $type, $var) = getDirTypeVar($port);
     if ($dir ne "out") { indent "   ${var} = ${name}__${var};" }
  }
  indent "   // procdef_end";
}

sub ProcDefEnd() {
  $mlevel--;
  my $name = $mprocs[$#mprocs];
  my @procios = @{$mprocios{$name}};
  my @procdir = @{$mprocdir{$name}};
  my @proctype = @{$mproctype{$name}};
  indent "   // procdefend_begin";
  foreach my $k (0..$#procios) {
     my $var = $procios[$k];
     my $dir = $procdir[$k];
     if ($dir ne "in") { indent "   ${name}__${var} = $var;" }
  }
  indent "   ${name}__done = 1'b1;";
  indent "   `tick; while ( ${name}__go == 1'b1 ) `tick;";
  indent "   ${name}__done = 1'b0;";
  indent "SmEnd";
  indent "// procdefend_end";
}

# --- invoke a procedure, to run in parallel in background ---
sub ProcStart {
  my ($name, @ios) = @_;
  $mstartproc{$name} = [ @ios ];
  my @procios = @{$mprocios{$name}};
  my @procdir = @{$mprocdir{$name}};
  my @proctype = @{$mproctype{$name}};
  indent "// start_begin";
  foreach my $k (0..$#procios) {
     my $var = $procios[$k];
     my $dir = $procdir[$k];
     if ($dir ne "out") { indent "${name}__${var} = $ios[$k];" }
  }
  # indent "SmDecl: ${name}__go = 1'b0;";
  indent "${name}__go = 1'b1;";
  indent "// start_end";
}

# --- wait from one or more procedures to complete ---
sub ProcJoin {
   my @names = @_;
   indent "// join_begin";
   my $cond = "";
   my $cnt = 0;
   indent "`tick;";
   foreach my $name (@names) {
      my @ios =  @{$mstartproc{$name}};
      my @procios = @{$mprocios{$name}};
      my @procdir = @{$mprocdir{$name}};
      my @proctype = @{$mproctype{$name}};
      $cond .= " || " if $cnt > 0;
      $cond .= "${name}__done == 1'b0";
      $cnt++;
    }
    indent "while ( $cond ) `tick;";
    foreach my $name (@names) {
       my @ios =  @{$mstartproc{$name}};
       my @procios = @{$mprocios{$name}};
       my @procdir = @{$mprocdir{$name}};
       my @proctype = @{$mproctype{$name}};
       foreach my $k (0..$#procios) {
          my $var = $procios[$k];
          my $dir = $procdir[$k];
          if ($dir ne "in") { indent "$ios[$k] = ${name}__${var};" }
       }
       indent "${name}__go = 1'b0;";
    }
    indent "// join_end";
}

# --- used to end any of for/switch/taskdef/procdef/repeat
sub End() {
  if ($mtype[$mlevel] eq "taskdef") {
     TaskDefEnd;  
  }
  elsif ($mtype[$mlevel] eq "procdef") {
     ProcDefEnd;  
  }
  elsif ($mtype[$mlevel] eq "switch") {
     SwitchEnd;  
  }
  elsif ($mtype[$mlevel] eq "repeat") {
     RepeatEnd;  
  }
}

