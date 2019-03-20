library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity top_level is
end;

architecture impl of top_level is

--  constant debug:   boolean  := true;
    constant debug:   boolean  := false;
    constant max_ins: positive := 100000000;

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

    constant rom_size: positive := 1024;
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

    function format_pc(pc: integer) return string is
        variable l: line;
        variable s: integer;
    begin

        if (pc = 0) then

            s := 0;

        else

            s := integer(floor(log10(real(pc))));

        end if;

        for i in 1 to 4 - s loop

            write(l, ' ');

        end loop;

        write(l, int_to_str(pc));

        return l.all;

    end function;

    procedure log(s: string) is
    begin

        if debug then

            print(s);

        end if;

    end procedure;

    type register_vector is array (natural range <>) of integer;

    signal hlt: std_logic := '0';

begin

    process
        variable pc:        integer := 0;
        variable ins:       rom_word;
        variable opcode:    integer;
        variable reg_dest:  integer;
        variable reg_src_a: integer;
        variable reg_src_b: integer;
        variable jmp_dest:  integer;
        variable imm_value: integer;
        variable ins_cnt:   integer := 0;
        variable reg:       register_vector(0 to 31);
        file     f_tx:      chr_file;
        variable b:         byte;
        variable c:         character;
        variable multiply:  signed (63 downto 0);

    begin
        file_open(f_tx, "tx_pipe", write_mode);
        write(f_tx, LF);

        hlt <= '0';

        for r in reg'range loop

            reg(r) := 0;

        end loop;

        while true loop

            ins_cnt := ins_cnt + 1;

            if debug and (ins_cnt >= max_ins) then
                hlt <= '1';
                exit;
            end if;

            ins       := rom(pc);
            opcode    := to_integer(unsigned(ins(47 downto 43)));
            reg_dest  := to_integer(unsigned(ins(42 downto 39)));
            reg_src_a := to_integer(unsigned(ins(38 downto 35)));
            reg_src_b := to_integer(unsigned(ins(34 downto 31)));
            jmp_dest  := to_integer(unsigned(ins(30 downto 23)));

            log(string'(format_pc(pc) & " : "));

            case opcode is

                when op_halt'opc =>

                    log(string'("halt") & LF);
                    hlt <= '1';
                    exit;

                when op_nop'opc =>

                    log(string'("nop"));

                when op_outr'opc =>

                    if ins(1) = '0' then

                        write(f_tx, character'val(reg(reg_src_a) mod 256));

                    else

                        if ins(0) = '0' then

                            write(f_tx, to_hstring(std_logic_vector(to_unsigned(reg(reg_src_a) mod 16, 4))));

                        else

                            write(f_tx, to_hstring(std_logic_vector(to_unsigned((reg(reg_src_a) / 16) mod 16, 4))));

                        end if;

                    end if;

                when op_jmp'opc =>

                    log(string'("jump to " & int_to_str(jmp_dest)));
                    pc := jmp_dest - 1;

                when op_jmp_lt'opc =>

                    log(string'("(reg[" & int_to_str(reg_dest) & "] < reg[" &
                                int_to_str(reg_src_a) & "]) is "));

                    if reg(reg_dest) < reg(reg_src_a) then

                        log(string'("true -> jump to " & int_to_str(jmp_dest)));
                        pc := jmp_dest - 1;

                    else

                        log(string'("false -> continue"));

                    end if;

                when op_jmp_nz'opc =>

                    log(string'("(reg[" & int_to_str(reg_dest) & "] /= 0) is "));

                    if reg(reg_dest) /= 0 then

                        log(string'("true -> jump to " & int_to_str(jmp_dest)));
                        pc := jmp_dest - 1;

                    else

                        log(string'("false -> continue"));

                    end if;

                when op_load'opc =>

                    imm_value := to_integer(signed(ins(31 downto 0)));
                    log(string'("load reg[" & int_to_str(reg_dest) & "] = " &
                                "                = " & int_to_str(imm_value)));
                    reg(reg_dest) := imm_value;

                when op_cp'opc =>

                    log(string'("cp reg[" & int_to_str(reg_dest)) & "] = " &
                                "                = reg" & int_to_str(reg_src_a));
                    reg(reg_dest) := reg(reg_src_a);

                when op_inc'opc =>

                    log(string'("inc  reg[" & int_to_str(reg_dest)) & "] = " &
                                "                = " & int_to_str(reg(reg_dest) + 1));
                    reg(reg_dest) := reg(reg_dest) + 1;

                when op_dec'opc =>

                    log(string'("dec  reg[" & int_to_str(reg_dest)) & "] = " &
                                "                = " & int_to_str(reg(reg_dest) - 1));
                    reg(reg_dest) := reg(reg_dest) - 1;

                when op_add'opc =>

                    log(string'("add  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] + reg[" &
                                int_to_str(reg_src_b) & "] = " &
                                int_to_str(reg(reg_src_a) + reg(reg_src_b)));
                    reg(reg_dest) := reg(reg_src_a) + reg(reg_src_b);

                when op_add_lt'opc =>
                    imm_value := to_integer(signed(ins(31 downto 0)));
                    log(string'("add_lt  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] + [" &
                                int_to_str(imm_value) & "] = " &
                                int_to_str(reg(reg_src_a) + (imm_value)));
                    reg(reg_dest) :=reg(reg_src_a) + (imm_value);

                when op_sub'opc =>

                    log(string'("sub  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] - reg[" &
                                int_to_str(reg_src_b) & "] = " &
                                int_to_str(reg(reg_src_a) - reg(reg_src_b)));
                    reg(reg_dest) := reg(reg_src_a) - reg(reg_src_b);

                when op_sub_lt'opc =>
                    imm_value := to_integer(signed(ins(31 downto 0)));
                    log(string'("sub_lt  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] - [" &
                                int_to_str(imm_value) & "] = " &
                                int_to_str(reg(reg_src_a) - (imm_value)));
                    reg(reg_dest) := reg(reg_src_a) - (imm_value);

                when op_mul'opc =>

                        multiply := (to_signed(reg(reg_src_a),32) * to_signed(reg(reg_src_b),32));
                        reg(reg_dest) := to_integer(multiply(51 downto 20));

                    log(string'("mul  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] * reg[" &
                                int_to_str(reg_src_b) & "] = " &
                                int_to_str(to_integer(multiply(51 downto 20))));

                when op_mul_lt'opc =>
                    imm_value := to_integer(signed(ins(31 downto 0)));

                    multiply := (to_signed(reg(reg_src_a),32) * to_signed((imm_value),32));
                    reg(reg_dest) := to_integer(multiply(51 downto 20));

                    log(string'("mul_lt  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] * [" &
                                int_to_str(imm_value) & "] = " &
                                int_to_str(to_integer(multiply(51 downto 20))));

                when op_shr'opc =>

                    imm_value := to_integer(unsigned(ins(7 downto 0)));
                    log(string'("shr  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] >> " &
                                int_to_str(imm_value) & "     = " &
                                int_to_str(reg(reg_src_a) / (2 ** imm_value)));
                    reg(reg_dest) := reg(reg_src_a) / (2 ** imm_value);

                when op_shl'opc =>

                    imm_value := to_integer(unsigned(ins(7 downto 0)));
                    log(string'("shl  reg[" & int_to_str(reg_dest)) & "] = reg[" &
                                int_to_str(reg_src_a) & "] << " &
                                int_to_str(imm_value) & "     = " &
                                int_to_str(reg(reg_src_a) * (2 ** imm_value)));
                    reg(reg_dest) := reg(reg_src_a) * (2 ** imm_value);

                when op_outc'opc =>

                    write(f_tx, character'val(to_integer(unsigned(ins(7 downto 0)))));

                when op_btfjc'opc =>
                    log(string'("(reg[" & int_to_str(reg_src_a) & "] mod 2 = 0) is "));

                    if ((reg(reg_src_a)) mod 2) = 0 then
                      log(string'("true -> jump to " & int_to_str(jmp_dest)));
                      pc := jmp_dest - 1;
                    else
                      log(string'("false -> continue"));
                    end if;

                when op_btfjs'opc =>

                    log(string'("(reg[" & int_to_str(reg_src_a) & "] mod 2 = 0) is "));

                    if ((reg(reg_dest)) mod 2) /= 0 then
                      log(string'("true -> jump to " & int_to_str(jmp_dest)));
                      pc := jmp_dest - 1;
                    else
                      log(string'("false -> continue"));
                    end if;

                when others =>

                    null;

            end case;

            if debug then
                print(LF);
            end if;

            pc := pc + 1;

        end loop;

        file_close(f_tx);
        wait;

    end process;

end;
