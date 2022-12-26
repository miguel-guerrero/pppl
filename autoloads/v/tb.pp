
@MacroDef(GenClk, clk_signal, semip)
reg ${clk_signal};
initial begin
   ${clk_signal} <= 1;
   forever begin
      #${semip};
      ${clk_signal} <= ~${clk_signal};
   end
end
@MacroEnd

@MacroDef(GenRst,reset_signal, reset_time, active_value) %%
%  if (!defined($active_value)) { $active_value=0 };
%  my $not_active_value = ! $active_value;
reg ${reset_signal};
initial begin
   ${reset_signal} <= ${active_value};
   #${reset_time};
   ${reset_signal} <= ${not_active_value};
end
@MacroEnd


@MacroDef(GenRstMon,reset_signal, active_value)
%  if (!defined($active_value)) { $active_value=0 };
always @(${reset_signal}) begin
   if (${reset_signal} == ${active_value}) begin
      $display($time, " Reset ${reset_signal} is ACTIVE");
   end
   else begin
      $display($time, " Reset ${reset_signal} is inactive");
   end
end
@MacroEnd

