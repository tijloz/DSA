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
                     op_load, op_inc, op_dec, op_add, op_sub, op_mul, op_shr, 
                     op_shl, op_outc);
    
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
        (l(""),       outc        (LF)                              ),
        (l(""),       outc        ('C')                             ),
        (l(""),       outc        (LF)                              ),
        (l(""),       load        (reg_y, 480)                      ), -- y = 480
        (l("y loop"), load        (reg_x, 320)                      ), -- x = 320
        (l(""),       shl         (reg_x, reg_x, 1)                 ), -- x = x << 1
        (l("x loop"), load        (reg_tmp_a, 240)                  ), -- tmp_a = 240
        (l(""),       sub         (reg_tmp_a, reg_y, reg_tmp_a)     ), -- tmp_a = y - 240
        (l(""),       mul         (reg_tmp_a, reg_tmp_a, reg_tmp_a) ), -- tmp_a = (y - 240)^2
        (l(""),       load        (reg_tmp_b, 320)                  ), -- tmp_b = 320
        (l(""),       sub         (reg_tmp_b, reg_x, reg_tmp_b)     ), -- tmp_b = x - 320
        (l(""),       mul         (reg_tmp_b, reg_tmp_b, reg_tmp_b) ), -- tmp_b = (x - 320)^2
        (l(""),       add         (reg_tmp_a, reg_tmp_a, reg_tmp_b) ), -- tmp_a = (x - 320)^2 + (y - 240)^2
        (l(""),       shr         (reg_tmp_a, reg_tmp_a, 7)         ), -- tmp_a = ((x - 320)^2 + (y - 240)^2) >> 7
        (l(""),       load        (reg_tmp_b, 256)                  ), -- tmp_b = 256
        (l("if"),     jmp_lt      (reg_tmp_a, reg_tmp_b, l("then")) ), -- if (tmp_a < tmp_b) jump to then
        (l("else"),   load        (reg_tmp_a, 255)                  ), -- tmp_a = 255
        (l(""),       jmp         (l("end if"))                     ), -- jump to end if
        (l("then"),   nop                                           ), -- nop
        (l("end if"), load        (reg_tmp_b, 255)                  ), -- tmp_b = 255
        (l(""),       sub         (reg_tmp_b, reg_tmp_b, reg_tmp_a) ), -- tmp_b = 255 - tmp_a
        (l(""),       shr         (reg_tmp_a, reg_tmp_a, 1)         ), -- tmp_a = tmp_a >> 1
        (l(""),       outr        (reg_tmp_b, 3)                    ), -- write pixel R high byte
        (l(""),       outr        (reg_tmp_b, 2)                    ), -- write pixel R low byte
        (l(""),       outr        (reg_tmp_b, 3)                    ), -- write pixel G high byte
        (l(""),       outr        (reg_tmp_b, 2)                    ), -- write pixel G low byte
        (l(""),       outr        (reg_tmp_a, 3)                    ), -- write pixel B high byte
        (l(""),       outr        (reg_tmp_a, 2)                    ), -- write pixel B low byte
        (l(""),       outc        (LF)                              ),
        (l(""),       dec         (reg_x)                           ), -- x = x - 1
        (l(""),       jmp_nz      (reg_x, l("x loop"))              ), -- if (x != 0) jump to x loop
        (l(""),       dec         (reg_y)                           ), -- y = y - 1
        (l(""),       jmp_nz      (reg_y, l("y loop"))              ), -- if (y != 0) jump to y loop
        (l(""),       halt                                          )
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

    subtype reg_addr_slv is std_logic_vector(1 downto 0);

    function reg_addr(i: integer) return reg_addr_slv is
    begin

        return std_logic_vector(to_unsigned(i, 2));

    end function;
    
    procedure write(f: inout chr_file; i: std_logic_vector(15 downto 0)) is
        variable b: byte;
    begin
    
        b := i(15 downto 8);
        write(f, byte_to_chr(b));
        b := i( 7 downto 0);
        write(f, byte_to_chr(b));
    
    end procedure;
       
begin

    process
        variable ins:     instruction;
        file     f_bin:   chr_file;
        variable b:       byte;
        variable c:       character;
        variable bin_ins: std_logic_vector(15 downto 0);
    begin
        file_open(f_bin, "sphere.bin", write_mode);

        for pc in ins_list'range loop
        
            ins := ins_list(pc).ins;

            case ins.opcd is
            
                when op_halt =>
                
                    bin_ins := "0000" & "000000000000";
                    write(f_bin, bin_ins);

                when op_nop =>
                
                    bin_ins := "0101" & "000000000000";
                    write(f_bin, bin_ins);

                when op_outr =>
                
                    bin_ins := "1010" & "00" & reg_addr(ins.reg_src_a) &
                     "000000" & std_logic_vector(to_unsigned(ins.reg_src_b, 2));
                    write(f_bin, bin_ins);
                    
                when op_jmp =>
                
                    bin_ins := "0001" & "0000" & dest_addr(ins.jmp_dest);
                    write(f_bin, bin_ins);
                                
                when op_jmp_lt =>
                
                    bin_ins := "0110" & std_logic_vector(to_unsigned(ins.reg_dest, 2)) &
                     std_logic_vector(to_unsigned(ins.reg_src_a, 2)) & dest_addr(ins.jmp_dest);
                    write(f_bin, bin_ins);
                                
                when op_jmp_nz =>
                
                    bin_ins := "1011" & std_logic_vector(to_unsigned(ins.reg_dest, 2)) &
                     "00" & dest_addr(ins.jmp_dest);
                    write(f_bin, bin_ins);
                                
                when op_load =>
                
                    bin_ins := "0111" & reg_addr(ins.reg_dest) & 
                     std_logic_vector(to_signed(ins.reg_src_a, 10)); 
                    write(f_bin, bin_ins);

                when op_inc =>
                
                    bin_ins := "1100" & reg_addr(ins.reg_dest) & "0000000000";
                    write(f_bin, bin_ins);

                when op_dec =>
                
                    bin_ins := "0011" & reg_addr(ins.reg_dest) & "0000000000";
                    write(f_bin, bin_ins);

                when op_add =>
                
                    bin_ins := "1000" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) & 
                     reg_addr(ins.reg_src_b) & "000000";
                    write(f_bin, bin_ins);

                when op_sub =>
                
                    bin_ins := "1101" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) & 
                     reg_addr(ins.reg_src_b) & "000000";
                    write(f_bin, bin_ins);

                when op_mul =>
                
                    bin_ins := "0100" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) & 
                     reg_addr(ins.reg_src_b) & "000000";
                    write(f_bin, bin_ins);

                when op_shr =>
                
                    bin_ins := "1001" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) & 
                     std_logic_vector(to_unsigned(ins.reg_src_b, 8));
                    write(f_bin, bin_ins);

                when op_shl =>
                
                    bin_ins := "1110" & reg_addr(ins.reg_dest) & reg_addr(ins.reg_src_a) & 
                     std_logic_vector(to_unsigned(ins.reg_src_b, 8));
                    write(f_bin, bin_ins);

                when op_outc =>
                
                    bin_ins := "1111" & "0000" & 
                     std_logic_vector(to_unsigned(ins.reg_src_b, 8)); 
                    write(f_bin, bin_ins);

                when others =>
                
                    null;
                
            end case;
        
        end loop;
        
        file_close(f_bin);
        wait;
    
    end process;

end;
