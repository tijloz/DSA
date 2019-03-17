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
    constant max_ins: positive := 100000000;

    type opcodes is (op_halt, op_nop, op_outr, op_jmp, op_jmp_lt, op_jmp_lt_lt, op_jmp_nz,
                     op_load, op_cp, op_inc, op_dec, op_add, op_add_lt, op_sub,
                     op_sub_lt, op_mul, op_mul_lt, op_shr, op_shl, op_outc, op_btfjc, op_btfjs);

    subtype l_string is string(1 to 10);

    type instruction is record
        opcd:      opcodes;
        reg_dest:  integer;
        reg_src_a: integer;   -- range = -2147483648 to 2147483648 (32 bit wide) decimal at 16
        reg_src_b: integer;
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

-- insert serial int out

    function jmp(jmp_dest: l_string) return instruction is
    begin
        return (op_jmp, 0, 0, 0, jmp_dest);
    end;

    function jmp_lt(reg_a: integer; reg_b: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_jmp_lt, reg_a, reg_b, 0, jmp_dest);
    end;

    function jmp_lt_lt(reg_a: integer; v: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_jmp_lt_lt, reg_a, v, 0, jmp_dest);
    end;

    function jmp_nz(reg_a: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_jmp_nz, reg_a, 0, 0, jmp_dest);
    end;

    function load(reg_a: integer; v: integer) return instruction is
    begin
        return (op_load, reg_a, v, 0, l(""));
    end;

    function cp(reg_a: integer; reg_b:integer) return instruction is
    begin
        return (op_cp, reg_a, reg_b, 0, l(""));
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

    function add_lt(reg_d: integer; reg_a: integer; v: integer) return instruction is
    begin
        return (op_add_lt, reg_d, reg_a, v, l(""));
    end;

    function sub(reg_d: integer; reg_a: integer; reg_b: integer) return instruction is
    begin
        return (op_sub, reg_d, reg_a, reg_b, l(""));
    end;

    function sub_lt(reg_d: integer; reg_a: integer; v: integer ) return instruction is    -- sub literal
    begin
        return (op_sub_lt, reg_d, reg_a, v, l(""));
    end;

    function mul(reg_d: integer; reg_a: integer; reg_b: integer) return instruction is
    begin
        return (op_mul, reg_d, reg_a, reg_b, l(""));
    end;

    function mul_lt(reg_d: integer; reg_a: integer; v:integer) return instruction is
    begin
        return (op_mul_lt, reg_d, reg_a, v, l(""));
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





    function btfjc(reg_a: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_btfjc, reg_a, 0, 0, jmp_dest);
    end;

    function btfjs(reg_a: integer; jmp_dest: l_string) return instruction is
    begin
        return (op_btfjs, reg_a, 0, 0, jmp_dest);
    end;




    type instruction_vector is array (natural range <>) of instruction_list_entry;

    constant tmp_a:         integer := 0;
    constant tmp_b:         integer := 1;
    constant tmp_c:         integer := 2;
    constant tmp_d:         integer := 3;
    constant tmp_e:         integer := 4;
    constant tmp_f:         integer := 5;
    constant tmp_g:         integer := 6;
    constant tmp_h:         integer := 7;
    constant tmp_i:         integer := 8;
    constant tmp_j:         integer := 9;
    constant tmp_k:         integer := 10;

    constant ins_list: instruction_vector :=
    (
        -- initialise display
        (l(""),       outc        (LF)                              ),
        (l(""),       outc        ('C')                             ),
        (l(""),       outc        (LF)                              ),

        -- load initial conditions

        (l(""),       load        (tmp_j, 100)                      ), -- tmp_a - main loop count initialised at 100 <<8 for fixedpoint conversion
        (l(""),       load        (tmp_b, 41943040)                 ), -- tmp_b - pixel width count -1 << 16 for fixedpoint conversion
        (l(""),       load        (tmp_c, 31457280)                 ), -- tmp_c - pixel height count -1 << 16 for fixedpoint conversion
        -- perform calculation alt
        (l("start"),  load        (tmp_a, -1)                        ), -- tmp_a - main loop count initialised at 0
        (l(""),       sub_lt      (tmp_b, tmp_b, 65536)             ), -- dec pixel x posn
        (l(""),       jmp         (l("zr"))                         ), -- jump to zr
        (l("main"),   jmp_lt      (tmp_j, tmp_a, l("out"))          ), -- if (tmp_j (max loop iterations) < tmp_a (loop count)) jump to then jump to out
        (l("ret"),    inc         (tmp_a)                           ), -- increment loop count tmp_a
        (l(""),       cp          (tmp_f, tmp_d)                    ), -- tr = zr
        (l(""),       cp          (tmp_g, tmp_e)                    ), -- ti = zi
        (l(""),       mul         (tmp_d, tmp_f, tmp_f)             ), -- zr = tr^2
        (l(""),       shr         (tmp_d, tmp_d, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       mul         (tmp_h, tmp_g, tmp_g)             ), -- tmp = ti^2
        (l(""),       shr         (tmp_h, tmp_h, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       add_lt      (tmp_h, tmp_h, 23593)             ), -- tmp = ti^2 + c_r (0.36)
        (l(""),       sub         (tmp_d, tmp_d, tmp_h)             ), -- zr = zr - ti^2 (tmp)
        (l(""),       mul         (tmp_e, tmp_f, tmp_g)             ), -- zi = tr * ti
        (l(""),       shr         (tmp_e, tmp_e, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       shl         (tmp_e, tmp_e, 1)                 ), -- zi * 2
        (l(""),       add_lt      (tmp_e, tmp_e, 6554)              ), -- zi = zi + c_i (0.1)
        -- loopcheck out of d_lim
        (l("lc"),     mul         (tmp_h, tmp_d, tmp_d)             ), -- tmp = zr^2
        (l(""),       shr         (tmp_h, tmp_h, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       mul         (tmp_i, tmp_e, tmp_e)             ), -- tmp2 = zi^2
        (l(""),       shr         (tmp_i, tmp_i, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       add         (tmp_i, tmp_i, tmp_h)             ), -- tmp = tmp + tmp2 => zr^2 + zi^2
        (l(""),       load        (tmp_h, 262144)                   ), -- if (tmp_d < 4) jump to loop
        (l(""),       jmp_lt      (tmp_i, tmp_h, l("main"))         ), -- if (tmp_d >= 4) jump to test
        (l(""),       jmp_nz      (tmp_b, l("test"))                ), -- jump to start if
        (l(""),       sub_lt      (tmp_c, tmp_c, 65536)             ), -- dec pixel y posn
        (l(""),       jmp_nz      (tmp_c, l("test"))                ), -- jump to start if
        (l(""),       halt                                          ),
        --out
        (l("out"),    load        (tmp_i, 16#00#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel R high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel R low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel G high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel G low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel B high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel B low byte
        (l(""),       outc        (LF)                              ),
        (l(""),       jmp         (l("start"))                      ), -- jump to start if
        --odd
        (l("odd"),    load        (tmp_i, 16#df#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel R high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel R low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel G high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel G low byte
        (l(""),       load        (tmp_i, 16#1f#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel B high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel B low byte
        (l(""),       outc        (LF)                              ),
        (l(""),       jmp         (l("start"))                      ), -- jump to start if
        --even
        (l("even"),   load        (tmp_i, 16#1f#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel R high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel R low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel G high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel G low byte
        (l(""),       load        (tmp_i, 16#9f#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel B high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel B low byte
        (l(""),       outc        (LF)                              ),
        (l(""),       jmp         (l("start"))                      ), -- jump to start if

        --odd / even test
        (l("test"),   btfjc       (tmp_a, l("odd"))                 ),
        (l(""),       btfjs       (tmp_a, l("even"))                ),

        -- find z_r alt
        (l("zr"),     cp          (tmp_d, tmp_b)                    ), -- tmp_d = 639 - pixel width -1 bit shifted
        (l(""),       mul_lt      (tmp_d, tmp_d, 103)               ), -- tmp_d = tmp_d*(1/640)=102
        (l(""),       shr         (tmp_d, tmp_d, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       mul_lt      (tmp_d, tmp_d, 209715)            ), -- tmp_d = 3.2(209715)*6 39/640
        (l(""),       shr         (tmp_d, tmp_d, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       sub_lt      (tmp_d, tmp_d, 104858)            ), -- tmp_d = 3.2*639/640-1.6
        (l(""),       jmp         (l("zi"))                         ), -- jump to end if
        -- find z_i alt
        (l("zi"),     cp          (tmp_e, tmp_c)                    ), -- tmp_e = 479
        (l(""),       mul_lt      (tmp_e, tmp_e, 137)               ), -- tmp_e = 479/(480=0020833)
        (l(""),       shr         (tmp_e, tmp_e, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       mul_lt      (tmp_e, tmp_e, 157286)            ), -- tmp_e = 3.2*479/480
        (l(""),       shr         (tmp_e, tmp_e, 0)                 ), -- shift right 8 bits to correct for fixed point multiplication
        (l(""),       sub_lt      (tmp_e, tmp_e, 78643)             ), -- tmp_e = 3.2*479/480-1.2
        (l(""),       jmp         (l("ret"))                        ) -- jump to end if
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
        variable reg:     register_vector(0 to 23);
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

                when op_jmp_lt_lt =>

                    log(string'("(reg[" & int_to_str(ins.reg_dest) & "] < reg[" &
                                int_to_str(ins.reg_src_a) & "]) is "));

                    if reg(ins.reg_dest) < (ins.reg_src_a) then

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

                when op_cp =>

                    log(string'("cp reg[" & int_to_str(ins.reg_dest)) & "] = " &
                                "                = reg" & int_to_str(ins.reg_src_a));
                    reg(ins.reg_dest) := reg(ins.reg_src_a);

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

                when op_add_lt =>

                    log(string'("add_lt  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] + [" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) + (ins.reg_src_b)));
                    reg(ins.reg_dest) :=reg(ins.reg_src_a) + ins.reg_src_b;

                when op_sub =>

                    log(string'("sub  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] - reg[" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) - reg(ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) - reg(ins.reg_src_b);

                when op_sub_lt =>

                    log(string'("sub_lt  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] - [" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) - (ins.reg_src_b)));
                    reg(ins.reg_dest) := reg(ins.reg_src_a) - (ins.reg_src_b);

                when op_mul =>

                    log(string'("mul  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] * reg[" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) * reg(ins.reg_src_b)));
                    reg(ins.reg_dest) := to_integer((to_signed(reg(ins.reg_src_a),32) * to_signed(reg(ins.reg_src_b),32))srl 16);

                when op_mul_lt =>

                    log(string'("mul_lt  reg[" & int_to_str(ins.reg_dest)) & "] = reg[" &
                                int_to_str(ins.reg_src_a) & "] * [" &
                                int_to_str(ins.reg_src_b) & "] = " &
                                int_to_str(reg(ins.reg_src_a) * (ins.reg_src_b)));
                    reg(ins.reg_dest) := to_integer((to_signed(reg(ins.reg_src_a),32) * to_signed((ins.reg_src_b),32))srl 16);

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






                when op_btfjc =>

                    --log(string'("(reg[" & to_hstring(std_logic_vector(to_unsigned(reg(ins.reg_src_a) mod 2, 8))) & "] mod 2" & "]) is "));

                    if ((reg(ins.reg_src_a)) mod 2) = 0 then
                      log(string'("true -> jump to " & ins.jmp_dest));
                      pc := dest_addr(ins.jmp_dest) - 1;
                    else
                      log(string'("false -> continue"));
                    end if;

                when op_btfjs =>

                    if ((reg(ins.reg_dest)) mod 2) /= 0 then
                      log(string'("true -> jump to " & ins.jmp_dest));
                      pc := dest_addr(ins.jmp_dest) - 1;
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
