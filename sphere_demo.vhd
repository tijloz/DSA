library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity sphere_demo is
end;

architecture impl of sphere_demo is

constant N_x: positive := 640;
constant N_y: positive := 480;

function sphere(x: integer; y: integer) return string is
        variable x_r:   integer;
        variable y_r:   integer;
        variable delta: integer;
        variable r:     integer;
        variable g:     integer;
        variable b:     integer;
        variable l:     line;
    begin
        x_r   := x - N_x / 2;
        y_r   := y - N_y / 2;
        delta := ((x_r * x_r) + (y_r * y_r)) / 128;
    
        if (delta > 255) then
        
            delta := 255;
            
        end if;

        r := 255 - delta;
        g := 255 - delta;
        b := delta / 2;
       
        write(l, to_hstring(std_logic_vector(to_unsigned(r, 8))));
        write(l, to_hstring(std_logic_vector(to_unsigned(g, 8))));
        write(l, to_hstring(std_logic_vector(to_unsigned(b, 8))));

        return l.all;
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

                write(l, sphere(x, y));
                writeline(f, l);

            end loop;
        
        end loop;
        
        file_close(f);
        wait;
    end process;
        
end;
