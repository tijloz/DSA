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

  constant debug:   boolean  := true;
--    constant debug:   boolean  := false;
    constant max_ins: positive := 60;

    type opcodes is (op_halt, op_nop, op_outr, op_jmp, op_jmp_lt, op_jmp_nz,
                     op_load, op_inc, op_dec, op_add, op_sub, op_mul, op_shr,
                     op_shl, op_outc);

    subtype l_string is string(1 to 10);

    type instruction is record
        opcd:      opcodes;
        reg_dest:  integer;
        reg_src_a: integer;
        reg_src_b: integer;
        --reg_mult:  integer;
        jmp_dest:  l_string;
    end record;

    type instruction_list_entry is record
        lab:    l_string;
        ins:    instruction;
    end record;

    function l(s: string) return l_string is
        variable r: l_string := "          ";
    begin

        for i in s'range loop
            r(i) := s(i);
        end loop;

        return r;

    end function;

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

    function halt return instruction is
    begin
        return (op_halt, 0, 0, 0, l(""));
    end;

    function nop return instruction is
    begin
        return (op_nop, 0, 0, 0, l(""));
    end;

    function outr(reg_a: integer; flags: integer) return instruction is
    begin
        return (op_outr, 0, reg_a, flags, l(""));
    end;

    function jmp(jmp_dest: l_string) return instruction is
    begin
        return (op_jmp, 0, 0, 0, jmp_dest);
    end;

    function jmp_lt(reg_a: integer; reg_b: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_jmp_lt, reg_a, reg_b, 0, jmp_dest);
    end;

    function jmp_nz(reg_a: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_jmp_nz, reg_a, 0, 0, jmp_dest);
    end;

    function load(reg_a: integer; v: integer) return instruction is
    begin
        return (op_load, reg_a, v, 0, l(""));
    end;

    function inc(reg_a: integer) return instruction is
    begin
        return (op_inc, reg_a, 0, 0, l(""));
    end;

    function dec(reg_a: integer) return instruction is
    begin
        return (op_dec, reg_a, 0, 0, l(""));
    end;

    function add(reg_d: integer; reg_a: integer; reg_b: integer) return instruction is
    begin
        return (op_add, reg_d, reg_a, reg_b, l(""));
    end;

    function sub(reg_d: integer; reg_a: integer; reg_b: integer) return instruction is
    begin
        return (op_sub, reg_d, reg_a, reg_b, l(""));
    end;

    function mul(reg_d: integer; reg_a: integer; reg_b: integer) return instruction is
    begin
        return (op_mul, reg_d, reg_a, reg_b, l(""));
    end;

    function shr(reg_d: integer; reg_a: integer; imm: integer) return instruction is
    begin
        return (op_shr, reg_d, reg_a, imm, l(""));
    end;

    function shl(reg_d: integer; reg_a: integer; imm: integer) return instruction is
    begin
        return (op_shl, reg_d, reg_a, imm, l(""));
    end;

    function outc(c: character) return instruction is
    begin
        return (op_outc, 0, 0, character'pos(c), l(""));
    end;

    type instruction_vector is array (natural range <>) of instruction_list_entry;

    constant reg_y:         integer := 0;
    constant reg_x:         integer := 1;
    constant reg_tmp_a:     integer := 2;
    constant reg_tmp_b:     integer := 3;

    constant ins_list: instruction_vector :=
    (
        (l(""),       load        (reg_y, 563)                      ), -- y = 2.2

        (l(""),       load        (reg_x, 258)                      ), -- x = 1.009
        (l(""),       mul         (reg_x, reg_x, reg_y)             ), -- tmp_b = (x - 320)^2
        (l(""),       shr         (reg_x, reg_x, 8)                 ),
        --(l(""),     load        (reg_tmp_a, 240.2)                ), -- tmp_a = 240
        --(l(""),     load        (reg_tmp_b, 12.2)                 ), -- tmp_a = 240
        --(l(""),     mul         (reg_tmp_a, reg_tmp_a, reg_tmp_b) ), -- tmp_a = y - 240
        (l(""),       halt                                          )
    );

    function dest_addr(l: l_string) return integer is
    begin

        for i in ins_list'range loop

            if (ins_list(i).lab = l) then

                return i;

            end if;

        end loop;

        report "jmp label '" & l & "' not found." severity failure;

    end function;

    type register_vector is array (natural range <>) of integer;

    signal hlt: std_logic := '0';

begin

    process
        variable pc:      integer := 0;
        variable ins:     instruction;
        variable ins_cnt: integer := 0;
        variable reg:     register_vector(0 to 7);
        file     f_tx:    chr_file;
        variable b:       byte;
        variable c:       character;
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

            ins := ins_list(pc).ins;
            log(string'(format_pc(pc) & " : " & ins_list(pc).lab & " : "));

            case ins.opcd is

                when op_halt =>

                    log(string'("halt") & LF);
                    hlt <= '1';
                    exit;

                when op_nop =>

                    log(string'("nop"));

                when op_outr =>

                    if ((ins.reg_src_b / 2) mod 2) = 0 then

                        log(string'("outr 0x" & to_hstring(std_logic_vector(to_unsigned(reg(ins.reg_src_a) mod 256, 8)))));
                        write(f_tx, character'val(reg(ins.reg_src_a) mod 256));

                    else

                        if (ins.reg_src_b mod 2) = 0 then

                            log(string'("outr 0x" & to_hstring(std_logic_vector(to_unsigned(reg(ins.reg_src_a) mod 16, 4)))));
                            write(f_tx, to_hstring(std_logic_vector(to_unsigned(reg(ins.reg_src_a) mod 16, 4))));

                        else

                            log(string'("outr 0x" & to_hstring(std_logic_vector(to_unsigned((reg(ins.reg_src_a) / 16) mod 16, 4)))));
                            write(f_tx, to_hstring(std_logic_vector(to_unsigned((reg(ins.reg_src_a) / 16) mod 16, 4))));

                        end if;

                    end if;

                when op_jmp =>

                    log(string'("jump to " & ins.jmp_dest));
                    pc := dest_addr(ins.jmp_dest) - 1;

                when op_jmp_lt =>

                    log(string'("(reg[" & int_to_str(ins.reg_dest) & "] < reg[" &
                                int_to_str(ins.reg_src_a) & "]) is "));

                    if reg(ins.reg_dest) < reg(ins.reg_src_a) then

                        log(string'("true -> jump to " & ins.jmp_dest));
                        pc := dest_addr(ins.jmp_dest) - 1;

                    else

                        log(string'("false -> continue"));

                    end if;

                when op_jmp_nz =>

                    log(string'("(reg[" & int_to_str(ins.reg_dest) & "] /= 0) is "));

                    if reg(ins.reg_dest) /= 0 then

                        log(string'("true -> jump to " & ins.jmp_dest));
                        pc := dest_addr(ins.jmp_dest) - 1;

                    else

                        log(string'("false -> continue"));

                    end if;

                when op_load =>

                    log(string'("load reg[" & int_to_str(ins.reg_dest)) & "] = " &
                                "                = " & int_to_str(ins.reg_src_a));
                    reg(ins.reg_dest) := ins.reg_src_a;

                when op_inc =>

                    log(string'("inc  reg[" & int_to_str(ins.reg_dest)) & "] = " &
                                "                = " & int_to_str(reg(ins.reg_dest) + 1));
                    reg(ins.reg_dest) := reg(ins.reg_dest) + 1;

                when op_dec =>

                    log(string'("dec  reg[" & int_to_str(ins.reg_dest)) & "] = " &
                                "                = " & int_to_str(reg(ins.reg_dest) - 1));
                    reg(ins.reg_dest) := reg(ins.reg_dest) - 1;

                when op_add =>

                    log(string'("add  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] + reg[" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) + reg(ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) + reg(ins.reg_src_b);

                when op_sub =>

                    log(string'("sub  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] - reg[" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) - reg(ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) - reg(ins.reg_src_b);

                when op_mul =>

                    log(string'("mul  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] * reg[" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) * reg(ins.reg_src_b)));

                    reg(ins.reg_dest) := reg(ins.reg_src_a) * reg(ins.reg_src_b);

                when op_shr =>

                    log(string'("shr  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] >> " &
                                int_to_str(ins.reg_src_b) & "     = " &
                                int_to_str(reg(ins.reg_src_a) / (2 ** ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) / (2 ** ins.reg_src_b);

                when op_shl =>

                    log(string'("shl  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] << " &
                                int_to_str(ins.reg_src_b) & "     = " &
                                int_to_str(reg(ins.reg_src_a) * (2 ** ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) * (2 ** ins.reg_src_b);

                when op_outc =>

                    log(string'("outc 0x" & to_hstring(std_logic_vector(to_unsigned(ins.reg_src_b mod 256, 8)))));
                    write(f_tx, character'val(ins.reg_src_b mod 256));

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
