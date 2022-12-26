
@MacroDef(waitfor, expr);
    `tick; while (!(${expr})) `tick;
@MacroEnd;

