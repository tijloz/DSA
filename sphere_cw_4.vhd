library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
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

    type opcodes is (op_halt, op_nop, op_outr, op_jmp, op_jmp_lt, op_jmp_nz, 
                     op_load, op_inc, op_dec, op_add, op_sub, op_mul, op_shr, 
                     op_shl, op_outc);
                     
    subtype opcode_type is std_logic_vector(3 downto 0);
    attribute opc: integer;

    attribute opc of op_halt         : literal is 16#0#; -- 0000
    attribute opc of op_nop          : literal is 16#5#; -- 0101
    attribute opc of op_outr         : literal is 16#a#; -- 1010
    attribute opc of op_jmp          : literal is 16#1#; -- 0001
    attribute opc of op_jmp_lt       : literal is 16#6#; -- 0110
    attribute opc of op_jmp_nz       : literal is 16#b#; -- 1011
--  attribute opc of op_unused       : literal is 16#2#; -- 0010
    attribute opc of op_load         : literal is 16#7#; -- 0111
    attribute opc of op_inc          : literal is 16#c#; -- 1100
    attribute opc of op_dec          : literal is 16#3#; -- 0011
    attribute opc of op_add          : literal is 16#8#; -- 1000
    attribute opc of op_sub          : literal is 16#d#; -- 1101
    attribute opc of op_mul          : literal is 16#4#; -- 0100
    attribute opc of op_shr          : literal is 16#9#; -- 1001
    attribute opc of op_shl          : literal is 16#e#; -- 1110
    attribute opc of op_outc         : literal is 16#f#; -- 1111

    constant rom_size: positive := 128;
    subtype  rom_word is std_logic_vector(15 downto 0);
    subtype  rom_addr is unsigned(n_bits(rom_size - 1) - 1 downto 0);
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

    signal   rom: rom_type := init_rom_from_file("sphere.bin");

    constant reg_size: positive := 4;
    subtype  reg_word is signed(31 downto 0);
    subtype  reg_addr is unsigned(n_bits(reg_size - 1) - 1 downto 0);
    type     reg_type is array (0 to (reg_size - 1)) of reg_word;
    
    signal   reg: reg_type := (others => (others => '0'));

    signal   hlt:        std_logic                                   := '0';

    signal   rom_a_en:   std_logic                                   := '0';
    signal   rom_a_addr: rom_addr                                    := (others => '0');
    signal   rom_a_dout: rom_word                                    := (others => '0');

    signal   reg_a_en:   std_logic                                   := '0';
    signal   reg_a_addr: reg_addr                                    := (others => '0');
    signal   reg_a_dout: reg_word                                    := (others => '0');

    signal   reg_b_en:   std_logic                                   := '0';
    signal   reg_b_addr: reg_addr                                    := (others => '0');
    signal   reg_b_dout: reg_word                                    := (others => '0');

    signal   reg_c_wr:   std_logic                                   := '0';
    signal   reg_c_addr: reg_addr                                    := (others => '0');
    signal   reg_c_din:  reg_word                                    := (others => '0');

    signal   sp_tx:      std_logic                                   := '0';
    signal   sp_bsy:     std_logic                                   := '0';
    signal   sp_wr:      std_logic                                   := '0';
    signal   sp_data:    byte                                        := byte_null;

    constant bit_cycles: positive                                    := (clk_freq / baud_rate) - 1;
    signal   bit_cnt:    unsigned(n_bits(bit_cycles) - 1 downto 0)   := (others => '0');
    signal   bsy_int:    std_logic_vector(9 downto 0)                := (others => '0');
    signal   tx_int:     std_logic_vector(9 downto 0)                := (others => '1');

    constant en_states:  integer                                     := 3;
    constant en_reset:   std_logic_vector(0 to en_states - 1)        := (others => '0');
    signal   en:         std_logic_vector(0 to en_states - 1)        := en_reset;

    signal   ins:        rom_word                                    := (others => '0');
    signal   pc:         unsigned(n_bits(rom_size - 1) - 1 downto 0) := (others => '0');
    signal   jmp_dest:   unsigned(n_bits(rom_size - 1) - 1 downto 0) := (others => '0');
    signal   opcode:     integer                                     :=  0;
    signal   reg_dest:   reg_addr                                    := (others => '0');
    signal   reg_src_a:  reg_addr                                    := (others => '0');
    signal   reg_src_b:  reg_addr                                    := (others => '0');
    signal   idx:        integer                                     :=  0;

begin

    led <= (0 => hlt, others => '0');

    -- ROM (read only)

    process
    begin
    
        wait until rising_edge(clk);
        
        if (rom_a_en = '1') then

            rom_a_dout <= rom(to_integer(rom_a_addr));

        end if;
            
    end process;

    -- Register Bank Port A (read only)

    process
    begin

        wait until rising_edge(clk);
        
        if (reg_a_en = '1') then
        
            reg_a_dout <= reg(to_integer(reg_a_addr));

        end if;
            
    end process;

    -- Register Bank Port B (read only)

    process
    begin

        wait until rising_edge(clk);
        
        if (reg_b_en = '1') then
        
            reg_b_dout <= reg(to_integer(reg_b_addr));

        end if;
            
    end process;

    -- Register Bank Port C (write only)

    process
    begin

        wait until rising_edge(clk);
        
        if (reg_c_wr = '1') then

            reg(to_integer(reg_c_addr)) <= reg_c_din;
                
        end if;
                
    end process;

    -- Serial Port

    sp_bsy <= sp_wr or bsy_int(0);
    tx     <= tx_int(0);

    process
    begin

        wait until rising_edge(clk);
        
        if (bit_cnt < bit_cycles) then

            bit_cnt <= bit_cnt + 1;

        else

            bit_cnt <= (others => '0');

        end if;
    
        if (bsy_int(0) = '0') and (sp_wr = '1') then

            tx_int(9 downto 1) <= sp_data & '0';
            bsy_int            <= (others => '1');

        elsif (bit_cnt = 0) then
        
            tx_int  <= '1' & tx_int (9 downto 1);
            bsy_int <= '0' & bsy_int(9 downto 1);

        end if;

    end process;

    -- Instruction Sequenzer

    process
    begin
 
        wait until rising_edge(clk);
        
        if en = en_reset then
        
            en <= (0 => '1', others => '0');
            
        else

            en <= en(en'high) & en(0 to en'high - 1);

        end if;
        
    end process;
    
    -- Instruction Fetch (stage 0)

    process(en(0), pc)
    begin

        rom_a_en   <= '0';
        rom_a_addr <= (others => '0');

        if en(0) = '1' then

            rom_a_en   <= '1';
            rom_a_addr <= pc;

        end if;

    end process;

    -- Instruction Decode (stage 1)

    ins       <= rom_a_dout;
    jmp_dest  <= unsigned(ins(jmp_dest'range));
    opcode    <= to_integer(unsigned(ins(15 downto 12)));
    reg_dest  <= unsigned(ins(11 downto 10));
    reg_src_a <= unsigned(ins( 9 downto  8));
    reg_src_b <= unsigned(ins( 7 downto  6));
    idx       <= to_integer(unsigned(ins( 4 downto  0)));

    process(en(1), opcode, reg_dest, reg_src_a, reg_src_b)
    begin
        
        reg_a_en   <= '0';
        reg_a_addr <= (others => '0');

        reg_b_en   <= '0';
        reg_b_addr <= (others => '0');

        if en(1) = '1' then

            case opcode is
            
                when op_outr'opc | op_shr'opc | op_shl'opc =>
                
                    reg_a_en   <= '1';
                    reg_a_addr <= reg_src_a;

                when op_jmp_lt'opc =>
                
                    reg_a_en   <= '1';
                    reg_a_addr <= reg_dest;

                    reg_b_en   <= '1';
                    reg_b_addr <= reg_src_a;

                when op_jmp_nz'opc | op_inc'opc | op_dec'opc =>
                
                    reg_a_en   <= '1';
                    reg_a_addr <= reg_dest;

                when op_add'opc | op_sub'opc | op_mul'opc =>
                
                    reg_a_en   <= '1';
                    reg_a_addr <= reg_src_a;

                    reg_b_en   <= '1';
                    reg_b_addr <= reg_src_b;

                when others =>
                
                    null;
                
            end case;

        end if;
    
    end process;

    -- Execute (stage 2)

    process
    begin
        
        wait until rising_edge(clk);
        
        reg_c_wr   <= '0';
        reg_c_addr <= (others => '0');
        reg_c_din  <= (others => '0');

        sp_wr   <= '0';
        sp_data <= byte_null;

        if en(2) = '1' then

            pc <= pc + 1;

            case opcode is
            
                when op_halt'opc =>
                
                    hlt <= '1';
                    pc  <= pc;
                
                when op_nop'opc =>
                
                    null;
                
                when op_outr'opc =>
                
                    if sp_bsy = '0' then
 
                        sp_wr   <= '1';
                        
                        if ins(1) = '0' then

                            sp_data <= std_logic_vector(reg_a_dout(7 downto 0));
                        
                        else
                        
                            if ins(0) = '0' then

                                sp_data <= byte_hex(to_integer(unsigned(reg_a_dout(3 downto 0))));
                            
                            else

                                sp_data <= byte_hex(to_integer(unsigned(reg_a_dout(7 downto 4))));
                            
                            end if;
                            
                        end if;

                    else

                        pc <= pc;

                    end if;
                    
                when op_jmp'opc =>
                
                    pc <= jmp_dest;
                                
                when op_jmp_lt'opc =>
                
                    if reg_a_dout < reg_b_dout then
                    
                        pc <= jmp_dest;
                    
                    end if;
                                
                when op_jmp_nz'opc =>
                
                    if reg_a_dout /= 0 then
                    
                        pc <= jmp_dest;
                    
                    end if;
                                
                when op_load'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= resize(signed(ins(9 downto 0)), reg_word'length);

                when op_inc'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= reg_a_dout + 1;

                when op_dec'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= reg_a_dout - 1;

                when op_add'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= reg_a_dout + reg_b_dout;

                when op_sub'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= reg_a_dout - reg_b_dout;

                when op_mul'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= resize(reg_a_dout * reg_b_dout, reg_word'length);

                when op_shr'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= (others => reg_a_dout(reg_word'high));
                    reg_c_din(reg_word'high - idx downto 0) <= 
                     reg_a_dout(reg_word'high downto idx);

                when op_shl'opc =>
                
                    reg_c_wr   <= '1';
                    reg_c_addr <= reg_dest;
                    reg_c_din  <= (others => '0');
                    reg_c_din(reg_word'high downto idx) <= 
                     reg_a_dout(reg_word'high - idx downto 0);

                when op_outc'opc =>
                
                    if sp_bsy = '0' then
 
                        sp_wr   <= '1';
                        sp_data <= ins(7 downto 0);

                    else

                        pc <= pc;

                    end if;

                when others =>
                
                    null;
                
            end case;

        end if;
    
    end process;

end;
