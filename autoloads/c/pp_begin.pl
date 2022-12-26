#this is executed in pass1

$pp_capture_on{ForUnwrap}=1;
$pp_capture_off{ForUnwrapEnd}=1;

$pp_capture_on{syn_unwrap_beg}=1;
$pp_capture_off{syn_unwrap_end}=1;

$pp_capture_on{syn_unwrap}=1;
$pp_capture_mon{syn_unwrap}="find_closing_block";

sub find_closing_block 
{
   my $msg = "$pass1_pp_captured[$pp_capture_lvl]\n";
   my $x = &find_closing($msg, "{,}");
   if ($x >= 0) {
      my $ind = "";
      if ($msg =~ /^(\s+)/) { $ind = $1; }
      &emit( "\$pp_src_indent=\"$ind\";");
      &emit("&syn_unwrap_end;");
      return 1;
   }
   return 0;
}

