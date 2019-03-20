library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
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

  type opcodes is (op_halt, op_nop, op_outr, op_jmp, op_jmp_lt, op_jmp_nz,
                   op_load, op_cp, op_inc, op_dec, op_add, op_add_lt, op_sub,
                   op_sub_lt, op_mul, op_mul_lt, op_shr, op_shl, op_outc, op_btfjc, op_btfjs);

    subtype opcode_type is std_logic_vector(4 downto 0);
    attribute opc: integer;

    attribute opc of op_add          : literal is 2#00000#;
    attribute opc of op_add_lt       : literal is 2#00001#;
    attribute opc of op_sub          : literal is 2#00010#;
    attribute opc of op_sub_lt       : literal is 2#00011#;
    attribute opc of op_inc          : literal is 2#00110#;
    attribute opc of op_dec          : literal is 2#00100#;
    attribute opc of op_mul          : literal is 2#01100#;
    attribute opc of op_mul_lt       : literal is 2#01101#;
    attribute opc of op_shr          : literal is 2#01010#;
    attribute opc of op_shl          : literal is 2#01110#;
    attribute opc of op_nop          : literal is 2#01111#;
    attribute opc of op_btfjc        : literal is 2#10010#;
    attribute opc of op_btfjs        : literal is 2#10011#;
    attribute opc of op_outr         : literal is 2#10000#;
    attribute opc of op_outc         : literal is 2#10001#;
    attribute opc of op_cp           : literal is 2#11000#;
    attribute opc of op_load         : literal is 2#11001#;
    attribute opc of op_jmp_lt       : literal is 2#11100#;
    attribute opc of op_jmp_nz       : literal is 2#11101#;
    attribute opc of op_jmp          : literal is 2#11110#;
    attribute opc of op_halt         : literal is 2#11111#;

    constant rom_size: positive := 512;
    subtype  rom_word is std_logic_vector(47 downto 0);
    type     rom_type is array (0 to (rom_size - 1)) of rom_word;

    impure function init_rom_from_file(file_name: string) return rom_type is
        file rom_file:     chr_file open read_mode is file_name;
        variable c:        character;
        variable d:        rom_word;
        variable i:        integer := 0;
        variable rom_data: rom_type;
    begin

        while not endfile(rom_file) loop
          read(rom_file, c);
          d(47 downto 40) := chr_to_byte(c);
          read(rom_file, c);
          d(39 downto 32) := chr_to_byte(c);
          read(rom_file, c);
          d(31 downto 24) := chr_to_byte(c);
          read(rom_file, c);
          d(23 downto 16) := chr_to_byte(c);
          read(rom_file, c);
          d(15 downto 8) := chr_to_byte(c);
          read(rom_file, c);
          d( 7 downto 0) := chr_to_byte(c);
          rom_data(i) := d;
            i := i + 1;
        end loop;

        while (i < rom_size) loop
            rom_data(i) := (others => '0');
            i := i + 1;
        end loop;

        return rom_data;

    end function;

    constant rom: rom_type := init_rom_from_file("julia.bin");

    constant reg_size: positive := 4;
    subtype  reg_word is signed(47 downto 0);
    type     reg_type is array (0 to (reg_size - 1)) of reg_word;

    signal   reg: reg_type := (others => (others => '0'));

    signal   hlt:       std_logic                                   := '0';
    signal   en:        std_logic                                   := '0';
    signal   ins:       rom_word                                    := (others => '0');
    signal   pc:        unsigned(n_bits(rom_size - 1) - 1 downto 0) := (others => '0');
    signal   jmp_dest:  unsigned(n_bits(rom_size - 1) - 1 downto 0) := (others => '0');
    signal   opcode:    integer                                     :=  0;
    signal   reg_dest:  integer                                     :=  0;
    signal   reg_src_a: integer                                     :=  0;
    signal   reg_src_b: integer                                     :=  0;
    signal   idx:       integer                                     :=  0;

    file     f_tx: chr_file open write_mode is "tx_pipe";

begin

    led       <= (0 => hlt, others => '0');
    ins       <= rom(to_integer(pc));
    jmp_dest  <= unsigned(ins(jmp_dest'range));
    opcode    <= to_integer(unsigned(ins(47 downto 43)));
    reg_dest  <= to_integer(unsigned(ins(42 downto 39)));
    reg_src_a <= to_integer(unsigned(ins(38 downto 35)));
    reg_src_b <= to_integer(unsigned(ins(34 downto 31)));
    idx       <= to_integer(unsigned(ins( 4 downto  0)));

    process
    begin

        wait until rising_edge(clk);

        if en = '1' then

            pc <= pc + 1;

            case opcode is

                when op_halt'opc =>

                    hlt <= '1';
                    pc  <= pc;

                when op_nop'opc =>

                    null;

                when op_outr'opc =>

                    if ins(1) = '0' then

                        write(f_tx, character'val(to_integer(unsigned(reg(reg_src_a)(7 downto 0)))));

                    else

                        if ins(0) = '0' then

                            write(f_tx, to_hstring(std_logic_vector(reg(reg_src_a)(3 downto 0))));

                        else

                            write(f_tx, to_hstring(std_logic_vector(reg(reg_src_a)(7 downto 4))));

                        end if;

                    end if;

                when op_jmp'opc =>

                    pc <= jmp_dest;

                when op_jmp_lt'opc =>

                    if reg(reg_dest) < reg(reg_src_a) then

                        pc <= jmp_dest;

                    end if;

                when op_jmp_nz'opc =>

                    if reg(reg_dest) /= 0 then

                        pc <= jmp_dest;

                    end if;

                when op_load'opc =>

                    reg(reg_dest) <= resize(signed(ins(31 downto 0)), 32);

                when op_cp'opc =>

                    reg(reg_dest) <= reg(reg_src_a);

                when op_inc'opc =>

                    reg(reg_dest) <= reg(reg_dest) + 1;

                when op_dec'opc =>

                    reg(reg_dest) <= reg(reg_dest) - 1;

                when op_add'opc =>

                    reg(reg_dest) <= reg(reg_src_a) + reg(reg_src_b);

                when op_add_lt'opc =>

                    reg(reg_dest) <= reg(reg_src_a) + resize(signed(ins(31 downto 0)), reg_word'length);

                when op_sub'opc =>

                    reg(reg_dest) <= reg(reg_src_a) - reg(reg_src_b);

                when op_sub_lt'opc =>

                    reg(reg_dest) <= reg(reg_src_a) - resize(signed(ins(31 downto 0)), reg_word'length);

                when op_mul'opc =>

                    reg(reg_dest) <= resize(reg(reg_src_a) * reg(reg_src_b), reg_word'length);

                when op_mul_lt'opc =>

                    reg(reg_dest) <= resize(reg(reg_src_a) * resize(signed(ins(31 downto 0)), reg_word'length), reg_word'length);

                when op_shr'opc =>

                    reg(reg_dest) <= (others => reg(reg_src_a)(reg_word'high));
                    reg(reg_dest)(reg_word'high - idx downto 0) <=
                     reg(reg_src_a)(reg_word'high downto idx);

                when op_shl'opc =>

                    reg(reg_dest) <= (others => '0');
                    reg(reg_dest)(reg_word'high downto idx) <=
                     reg(reg_src_a)(reg_word'high - idx downto 0);

                when op_outc'opc =>

                    write(f_tx, character'val(to_integer(unsigned(ins(7 downto 0)))));

                when op_btfjc'opc =>

                    if ins(0) = '0' then

                        pc <= jmp_dest;

                    end if;

                when op_btfjs'opc =>

                    if ins(0) = '1' then

                        pc <= jmp_dest;

                    end if;

                when others =>

                    null;

            end case;

        else

            en <= '1';

        end if;

    end process;

end;
