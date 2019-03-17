library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.config.all;
use WORK.util.all;

entity assembler is
end;

architecture impl of assembler is

  type opcodes is (op_halt, op_nop, op_outr, op_jmp, op_jmp_lt, op_jmp_nz,
                   op_load, op_cp, op_inc, op_dec, op_add, op_add_lt, op_sub,
                   op_sub_lt, op_mul, op_mul_lt, op_shr, op_shl, op_outc, op_btfjc, op_btfjs);

    subtype l_string is string(1 to 10);

    type instruction is record
        opcd:      opcodes;
        reg_dest:  integer;
        reg_src_a: integer;
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
    constant tmp_l:         integer := 11;
    constant tmp_m:         integer := 12;
    constant tmp_n:         integer := 13;
    constant tmp_o:         integer := 14;
    constant tmp_p:         integer := 15;

    constant ins_list: instruction_vector :=
    (
        -- load initial conditions
        (l(""),       load        (tmp_a, 100)                      ), -- tmp_a - 100
        (l(""),       load        (tmp_b, 671088640)                ), -- tmp_b - 671088640
        (l(""),       load        (tmp_c, 503316480)                ), -- tmp_c - 503316480
        (l(""),       load        (tmp_d, 10485760)                 ), -- tmp_d - 10485760

        -- perform calculation alt
        (l("add"),    add         (tmp_a, tmp_a, tmp_b)             ), -- tmp_a = 671088740
        (l(""),       add_lt      (tmp_a, tmp_a, 503316480)         ), -- tmp_a = 1174405220
        (l(""),       sub         (tmp_a, tmp_a, tmp_c)             ), -- tmp_a = 671088740
        (l(""),       sub_lt      (tmp_c, tmp_c, 671088640)         ), -- tmp_a = 100
        (l("inc"),    inc         (tmp_a)                           ), -- tmp_a = 101
        (l("inc"),    dec         (tmp_a)                           ), -- tmp_a = 100
        (l(""),       mul         (tmp_a, tmp_a, tmp_d)             ), -- tmp_a = 1000
        (l(""),       mul_lt      (tmp_a, tmp_a, 104857)            ), -- tmp_a = 100
        (l(""),       shl         (tmp_e, tmp_e, 1)                 ), -- tmp_a = 200
        (l(""),       shr         (tmp_e, tmp_e, 1)                 ), -- tmp_a = 100
        (l(""),       nop                                           ), -- tmp_a = 100
        (l(""),       btfjc       (tmp_a, l("odd"))                 ), -- if not divisible by 2 jump to odd
        (l("odd"),    btfjs       (tmp_a, l("even"))                ), -- if divisible by 2 jump to even
        (l("even"),   load        (tmp_i, 16#00#)                   ), -- tmp_a = 255
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel R high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel R low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel G high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel G low byte
        (l(""),       outr        (tmp_i, 3)                        ), -- write pixel B high byte
        (l(""),       outr        (tmp_i, 2)                        ), -- write pixel B low byte
        (l(""),       outc        (LF)                              ),
        (l(""),       cp          (tmp_a, tmp_b)                    ), -- tmp_a = tmp_b
        (l(""),       jmp_lt      (tmp_j, tmp_a, l("main"))         ), -- if
        (l("main"),   jmp_nz      (tmp_c, l("out"))                 ), -- jump to start if
        (l("out"),    jmp         (l("halt"))                       ), -- jump to start if
        (l("halt"),   halt                                          )
    );

    function dest_addr(l: l_string) return byte is
    begin

        for i in ins_list'range loop

            if (ins_list(i).lab = l) then

                return std_logic_vector(to_unsigned(i, byte'length));

            end if;

        end loop;

        report "jmp label '" & l & "' not found." severity failure;

    end function;

    subtype reg_addr_slv is std_logic_vector(3 downto 0);

    function reg_addr(i: integer) return reg_addr_slv is
    begin

        return std_logic_vector(to_unsigned(i, 4));

    end function;

    procedure write(f: inout chr_file; i: std_logic_vector(47 downto 0)) is
        variable b: byte;
    begin

        b := i(47 downto 40);
        write(f, byte_to_chr(b));
        b := i(39 downto 32);
        write(f, byte_to_chr(b));
        b := i(31 downto 24);
        write(f, byte_to_chr(b));
        b := i(23 downto 16);
        write(f, byte_to_chr(b));
        b := i(15 downto  8);
        write(f, byte_to_chr(b));
        b := i( 7 downto  0);
        write(f, byte_to_chr(b));

    end procedure;

begin

    process
        variable ins:     instruction;
        file     f_bin:   chr_file;
        variable b:       byte;
        variable c:       character;
        variable bin_ins: std_logic_vector(47 downto 0);
    begin
        file_open(f_bin, "test.bin", write_mode);

        for pc in ins_list'range loop

            ins := ins_list(pc).ins;

            case ins.opcd is

                when op_halt =>

                    bin_ins := "11111" & "0000000000000000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_nop =>

                    bin_ins := "01111" & "0000000000000000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_outr =>

                    bin_ins := "10000" & "0000" & reg_addr(ins.reg_src_a) &
                     std_logic_vector(to_unsigned(ins.reg_src_b, 4)) &
                     "0000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_jmp =>

                    bin_ins := "11110" & "000000000000" & dest_addr(ins.jmp_dest) &
                    "00000000000000000000000";
                    write(f_bin, bin_ins);

                when op_jmp_lt =>

                    bin_ins := "11100" & std_logic_vector(to_unsigned(ins.reg_dest, 4)) &
                     std_logic_vector(to_unsigned(ins.reg_src_a, 4)) & "0000" &
                     dest_addr(ins.jmp_dest) & "00000000000000000000000";
                    write(f_bin, bin_ins);

                when op_jmp_nz =>

                    bin_ins := "11101" & std_logic_vector(to_unsigned(ins.reg_dest, 4)) &
                     "00000000" & dest_addr(ins.jmp_dest) & "00000000000000000000000";
                    write(f_bin, bin_ins);

                when op_load =>

                    bin_ins := "11001" & reg_addr(ins.reg_dest) & "0000000" &
                     std_logic_vector(to_signed(ins.reg_src_a, 32));
                    write(f_bin, bin_ins);

                when op_cp =>

                    bin_ins := "11000" & reg_addr(ins.reg_dest) &
                     std_logic_vector(to_signed(ins.reg_src_a, 4)) &
                     "00000000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_inc =>

                    bin_ins := "00110" & reg_addr(ins.reg_dest) &
                    "000000000000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_dec =>

                    bin_ins := "00100" & reg_addr(ins.reg_dest) &
                    "000000000000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_add =>

                    bin_ins := "00000" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     reg_addr(ins.reg_src_b) & "0000000000000000000000000000000";
                     write(f_bin, bin_ins);

                when op_add_lt =>

                    bin_ins := "00001" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     "000" & std_logic_vector(to_signed(ins.reg_src_b, 32));
                    write(f_bin, bin_ins);

                when op_sub =>

                    bin_ins := "00010" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     reg_addr(ins.reg_src_b) & "0000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_sub_lt =>

                    bin_ins := "00011" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     "000" & std_logic_vector(to_signed(ins.reg_src_b, 32));
                    write(f_bin, bin_ins);

                when op_mul =>

                    bin_ins := "01100" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     reg_addr(ins.reg_src_b) & "0000000000000000000000000000000";
                    write(f_bin, bin_ins);

                when op_shr =>

                    bin_ins := "01010" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     "000" & std_logic_vector(to_unsigned(ins.reg_src_b, 32));
                    write(f_bin, bin_ins);

                when op_shl =>

                    bin_ins := "01110" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) &
                     "000" & std_logic_vector(to_unsigned(ins.reg_src_b, 32));
                    write(f_bin, bin_ins);

                when op_outc =>

                    bin_ins := "10001" & "00000000000" & "000000000000000000000000" &
                     std_logic_vector(to_unsigned(ins.reg_src_b, 8));
                    write(f_bin, bin_ins);

                when op_btfjc =>

                    bin_ins := "10010" & reg_addr(ins.reg_dest) & "00000000" &
                     dest_addr(ins.jmp_dest) & "00000000000000000000000";
                    write(f_bin, bin_ins);

                when op_btfjs =>

                    bin_ins := "10011" & reg_addr(ins.reg_dest) & "00000000" &
                     dest_addr(ins.jmp_dest) & "00000000000000000000000";
                    write(f_bin, bin_ins);

                when others =>

                    null;

            end case;

        end loop;

        file_close(f_bin);
        wait;

    end process;

end;
