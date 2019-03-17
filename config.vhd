library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.util.all;

package config is

    constant clk_freq:        frequency := 125 MHz;
    constant clk_period:      time      := 1 sec / (clk_freq / 1 Hz);
    constant gate_delay:      time      := 0.1 ns;

    constant baud_rate:       frequency := 921600 Hz;

end;
