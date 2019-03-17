library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use WORK.config.all;
use WORK.util.all;

entity simulator is
end;

architecture impl of simulator is

    constant bit_period : time                          := 1 sec / (baud_rate / 1 Hz);

    signal   clk        : std_logic                     := '0';

    signal   btn        : std_logic_vector (3 downto 0) := (others => '0');
    signal   sw         : std_logic_vector (1 downto 0) := (others => '0');
    signal   dcf        : std_logic                     := '0';
    signal   msf        : std_logic                     := '0';

    signal   led        : std_logic_vector (3 downto 0) := (others => 'X');
    signal   led4_r     : std_logic                     := 'X';
    signal   led4_g     : std_logic                     := 'X';
    signal   led4_b     : std_logic                     := 'X';
    signal   led5_r     : std_logic                     := 'X';
    signal   led5_g     : std_logic                     := 'X';
    signal   led5_b     : std_logic                     := 'X';

    signal   rx         : std_logic                     := '0';
    signal   tx         : std_logic                     := 'X';

    file     f_tx       : chr_file open write_mode is "tx_pipe";

begin

    process
    begin
    
        wait for clk_period;
    
        while led(0) = '0' loop

            wait for 0.5 * clk_period;
            clk <= not clk;

        end loop;
        
        wait;

    end process;
    
    process
        variable b: byte;
    begin
    
        wait until tx = '0';
        wait for 0.5 * bit_period;
        
        for i in 0 to 7 loop
        
            wait for bit_period;
            b := tx & b(7 downto 1);
            
        end loop;
        
        write(f_tx, character'val(to_integer(unsigned(b))));
        
    end process;

    top_level_unit: entity WORK.top_level
    port map
    (
        clk    => clk,

        btn    => btn,
        sw     => sw,
        dcf    => dcf,
        msf    => msf,

        led    => led,
        led4_r => led4_r,
        led4_g => led4_g,
        led4_b => led4_b,
        led5_r => led5_r,
        led5_g => led5_g,
        led5_b => led5_b,

        rx     => rx,
        tx     => tx

    );

end;
