library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.blakeley_utils.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all; 
    
entity blakeley_module_datapath is
    generic (
        c_block_size : integer;
        log2_c_block_size : integer;
                
        -- Where the control fields ends, and datapath filed starts
        num_status_bits : integer := 32;
        datapath_offset : integer := 4;
        ainc_ierr_bit : integer := 0;
        mux_ctl_ierr_bit : integer := 1;
        
        --Length is log2_c_block_size
        ainc_debug_offset : integer := 2;
        
        mux_ctl_size : integer := 2; 
        mux_ctl_offset : integer := 10
        
    );
    port ( 
          --Defaults
          clk : in std_logic;
    
           --Data signals
           a : in std_logic_vector (c_block_size-1 downto 0);
           b : in std_logic_vector (c_block_size-1 downto 0);
           nx1 : in std_logic_vector (c_block_size+1 downto 0);
           nx2 : in std_logic_vector (c_block_size+1 downto 0);
           r : out std_logic_vector (c_block_size-1 downto 0);
           
           --Control signals
           ainc_clk_en : in std_logic;
           ainc_rst : in std_logic;
           add_out_clk_en : in std_logic;
           add_out_rst : in std_logic;
           mux_ctl : in unsigned(1 downto 0);

           sum_out : out std_logic_vector(c_block_size+1 downto 0);   --NB: To avoid overflow
           ainc_out : out std_logic_vector(log2_c_block_size-1 downto 0)
           
           --Status signals
           --datapath_status : out std_logic_vector(num_status_bits-1 downto 0) := (others => '0')
    );
end blakeley_module_datapath;

architecture rtl of blakeley_module_datapath is
    signal ainc : unsigned(log2_c_block_size-1 downto 0);
    signal ainc_nxt : unsigned(log2_c_block_size-1 downto 0);
    
    signal r_out : unsigned (c_block_size-1 downto 0);

    signal dec_out : std_logic_vector (c_block_size-1 downto 0);
    signal mul_out : unsigned(c_block_size-1 downto 0);
    signal shift_out : unsigned(c_block_size+1 downto 0);     --NB: To avoid overflow
    
    signal add_out : unsigned(c_block_size+1 downto 0);       --NB: To avoid overflow
    signal add_out_nxt : unsigned(c_block_size+1 downto 0);   --NB: To avoid overflow
    
    signal subtrahend : unsigned(c_block_size+1 downto 0) := to_unsigned(0,c_block_size+2);
begin
    -- Datapath combinatorials
    ainc_nxt <= ainc + to_unsigned(1,log2_c_block_size);
    sum_out <= std_logic_vector(add_out);
    ainc_out <= std_logic_vector(ainc);
    
    --Select the whole b, only if we got a '1' bit in the current position in a, using ainc to iterate from MSB to LSB
    sel_a_comb : process (a,b,ainc) is
    begin
        if a(to_integer((c_block_size-1)-ainc)) = '1' then
            mul_out <= unsigned(b);
       else
            mul_out <= (others => '0');
        end if;
    end process sel_a_comb;
    
    --Multiply the current r by 2
    shift_out <= resize(r_out,shift_out'length) sll 1;
    
    --Do the addition of the current r and the result from the potential b
    add_out_nxt <= resize(mul_out,add_out_nxt'length) + shift_out;
    
    --Start experimental sub
    sel_sub_comb : process(mux_ctl,nx1,nx2) is
    begin
        case(to_integer(mux_ctl)) is
            when 0 =>
                subtrahend <= to_unsigned(0,c_block_size+2);
            when 1 =>
                subtrahend <= unsigned(nx1);
            when others =>
                subtrahend <= unsigned(nx2);
        end case;
    end process sel_sub_comb;

    r_out <= resize(add_out - subtrahend,r_out'length);
    r <= std_logic_vector(r_out);
        
    -- Datapath sequentials
    datapath_seq : process(clk,ainc_rst,add_out_rst) is
    begin
        --Gated clocks
        if (clk'event and clk='1') then
            if ainc_clk_en = '1' then
                ainc <= ainc_nxt;
            end if;
            if add_out_clk_en = '1' then
                add_out <= add_out_nxt;
            end if;
        end if;
        
        -- Asynchronus reset
        if (ainc_rst = '1') then
            ainc <= to_unsigned(0,log2_c_block_size);
        end if;
        
        if (add_out_rst = '1') then
            add_out <= to_unsigned(0,c_block_size+2);
        end if;
    end process datapath_seq;
end architecture rtl;