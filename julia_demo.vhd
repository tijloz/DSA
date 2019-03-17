library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity julia_demo is
end;

architecture impl of julia_demo is

constant N_x: positive := 640;
constant N_y: positive := 480;

function iter(x: integer; y: integer) return string is
        constant N_lim: positive := 100;
        constant d_lim: real     := 2.0 * 2.0;
        variable i:     integer  := 0;
        variable z_r:   real     := 3.2 * real(x) / real(N_x) - 1.6;
        variable z_i:   real     := 2.4 * real(y) / real(N_y) - 1.2;
        variable c_r:   real     := 0.36;
        variable c_i:   real     := 0.10;
        variable t_r:   real     := 0.0;
        variable t_i:   real     := 0.0;
    begin
    
        while (((z_r * z_r) + (z_i * z_i)) < d_lim) and (i < N_lim) loop
        
            i   := i + 1;
            t_r := z_r;
            t_i := z_i;
            z_r := t_r * t_r - t_i * t_i + c_r;
            z_i := 2.0 * (t_r * t_i) + c_i;

        end loop;

        if (i = N_lim) then

            return "000000";

        elsif ((i mod 2) = 0) then

            return "1f1f9f";

        else

            return "dfdf1f";

        end if;

    end function;

begin

    process
        file     f: text;
        variable l: line;
    begin
        file_open(f, "tx_pipe", write_mode);

        write(l, LF);
        writeline(f, l);
        write(l, string'("C") & LF);
        writeline(f, l);

        for y in N_y - 1 downto 0 loop
        
            for x in 0 to N_x - 1 loop

                write(l, iter(x, y));
                writeline(f, l);

            end loop;
        
        end loop;
        
        file_close(f);
        wait;
    end process;
        
end;
