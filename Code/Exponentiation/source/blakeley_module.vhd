library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.blakeley_utils.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all; 
    
entity blakeley_module is
    generic (
		c_block_size : integer := 256;
		log2_c_block_size : integer := 8;
		
        num_upper_status_bits : integer := 32;
        num_lower_status_bits : integer := 32
	);
    port ( 
           clk : in std_logic;
           rst : in std_logic; 
            
           A : in std_logic_vector (c_block_size-1 downto 0);
           B : in std_logic_vector (c_block_size-1 downto 0);
           NX1 : in std_logic_vector (c_block_size+1 downto 0);
           NX2 : in std_logic_vector (c_block_size+1 downto 0);
           ABVAL : in std_logic;
           R : out std_logic_vector (c_block_size-1 downto 0);
           RVAL : out std_logic
    );
end blakeley_module;

architecture rtl of blakeley_module is
    signal ainc_clk_en : std_logic;
    signal ainc_rst : std_logic;  
    signal add_out_clk_en : std_logic;
    signal add_out_rst : std_logic;

    --_internals to map between corol and datapath
    signal sum_out_internal : std_logic_vector(c_block_size+1 downto 0);    
    signal ainc_out_internal : std_logic_vector(log2_c_block_size-1 downto 0);
    signal mux_ctl_internal : unsigned(1 downto 0);
    
begin
    --Instantiate the datapath
    datapath: entity work.blakeley_module_datapath
        generic map(
            c_block_size => c_block_size,
            log2_c_block_size => log2_c_block_size,
            num_status_bits => num_lower_status_bits
        )
        port map(
            clk => clk,
            
            a => A,
            b => B,
            nx1 => nx1,
            nx2 => nx2,
            r => R,
            
            ainc_clk_en => ainc_clk_en,
            ainc_rst => ainc_rst,
            add_out_clk_en => add_out_clk_en,
            add_out_rst => add_out_rst,
            
            sum_out => sum_out_internal,
            ainc_out => ainc_out_internal,
            
            mux_ctl => mux_ctl_internal
        );
        
    --Instantiate the control
    control : entity work.blakeley_module_control
        generic map(
            c_block_size => c_block_size,
            log2_c_block_size => log2_c_block_size,
            num_status_bits => num_lower_status_bits
        )
        port map(
            clk => clk,
            rst => rst,
            
            nx1 => nx1,
            nx2 => nx2,
            abval => ABVAL,
            rval => RVAL,
            
            ainc_clk_en => ainc_clk_en,
            ainc_rst => ainc_rst,
            add_out_clk_en => add_out_clk_en,
            add_out_rst => add_out_rst,
            
            sum_out => sum_out_internal,
            ainc_out => ainc_out_internal,
 
            mux_ctl => mux_ctl_internal
        );
end rtl;