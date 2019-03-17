library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.config.all;
use WORK.util.all;

entity top_level is

    port
    (
        clk    : in  std_logic;

        btn    : in  std_logic_vector (3 downto 0);
        sw     : in  std_logic_vector (1 downto 0);
        dcf    : in  std_logic;
        msf    : in  std_logic;

        led    : out std_logic_vector (3 downto 0);
        led4_r : out std_logic;
        led4_g : out std_logic;
        led4_b : out std_logic;
        led5_r : out std_logic;
        led5_g : out std_logic;
        led5_b : out std_logic;

        rx     : in  std_logic;
        tx     : out std_logic
   );

end;

architecture impl of top_level is

begin

end;
