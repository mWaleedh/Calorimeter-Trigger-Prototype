library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calo_trigger_top is
	generic (
		DATA_WIDTH_g : integer := 16
	);
	port (
		clk_i			   : in  std_logic;
		reset_i			   : in  std_logic;
		event_valid_i	   : in  std_logic;
		chan0_i, chan1_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan2_i, chan3_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan4_i, chan5_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan6_i, chan7_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan8_i, chan9_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan10_i, chan11_i : in  unsigned(DATA_WIDTH_g-1 downto 0);
		threshold_stage1_i : in  unsigned(DATA_WIDTH_g+1 downto 0);
		threshold_stage2_i : in  unsigned(DATA_WIDTH_g+3 downto 0);
		trigger_accept_o   : out std_logic
	);
end calo_trigger_top;

architecture rtl of calo_trigger_top is
begin
	inst_trigger_dp : entity work.trigger_datapath(rtl)
		generic map ( DATA_WIDTH_g => DATA_WIDTH_g )
		port map (
			clk_i => clk_i, reset_i => reset_i,
			event_valid_i => event_valid_i,
			chan0_i  => chan0_i,  chan1_i  => chan1_i, 
			chan2_i  => chan2_i,  chan3_i  => chan3_i, 
			chan4_i  => chan4_i,  chan5_i  => chan5_i,
			chan6_i  => chan6_i,  chan7_i  => chan7_i, 
			chan8_i  => chan8_i,  chan9_i  => chan9_i, 
			chan10_i => chan10_i, chan11_i => chan11_i,
			threshold_stage1_i => threshold_stage1_i,
			threshold_stage2_i => threshold_stage2_i,
			final_accept_o => trigger_accept_o
		);
end rtl;