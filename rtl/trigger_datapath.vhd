library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger_datapath is
	generic (
		DATA_WIDTH_g : integer := 16
	);
	port (
		clk_i, reset_i		 : in  std_logic;
		event_valid_i		 : in  std_logic;
		chan0_i, chan1_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan2_i, chan3_i 	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan4_i, chan5_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan6_i, chan7_i	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan8_i, chan9_i	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan10_i, chan11_i : in  unsigned(DATA_WIDTH_g-1 downto 0);
		threshold_stage1_i : in  unsigned(DATA_WIDTH_g+1 downto 0);
		threshold_stage2_i : in  unsigned(DATA_WIDTH_g+3 downto 0);
		final_accept_o 	 : out std_logic
    );
end entity trigger_datapath;

architecture rtl of trigger_datapath is
	type channel_array_t is array (0 to 11) of unsigned(DATA_WIDTH_g-1 downto 0);
	type window_sum_array_t is array (0 to 9) of unsigned(DATA_WIDTH_g+1 downto 0); 
	
	signal s0_channels 		 : channel_array_t;
	signal s0_valid			 : std_logic;
	signal s0_thres_st1 		 : unsigned(DATA_WIDTH_g+1 downto 0);
	signal s0_thres_st2 		 : unsigned(DATA_WIDTH_g+3 downto 0);
	
	signal window_sums_comb	 : window_sum_array_t;
	signal window_pass_flags : std_logic_vector(9 downto 0);
	signal stage1_pass_comb	 : std_logic;
	
	signal s1_channels 		 : channel_array_t;
	signal s1_valid 			 : std_logic;
	signal s1_thres_st2 		 : unsigned(DATA_WIDTH_g+3 downto 0);
	signal s1_stage1_pass	 : std_logic;
	
	signal global_sum_comb 	 : unsigned(DATA_WIDTH_g+3 downto 0);
	signal stage2_pass_comb  : std_logic;
	
	signal s2_valid			 : std_logic;
	signal s2_stage1_pass	 : std_logic;
	signal s2_stage2_pass	 : std_logic;
	
	signal final_accept_comb : std_logic;
	
	signal s3_valid			 : std_logic;

begin
	process(clk_i)
		begin
		if rising_edge(clk_i) then
			if reset_i = '1' then
				s0_valid <= '0';
			else
				s0_valid 		 <= event_valid_i;
				s0_channels(0)  <= chan0_i;  s0_channels(1)  <= chan1_i;
				s0_channels(2)  <= chan2_i;  s0_channels(3)  <= chan3_i;
				s0_channels(4)  <= chan4_i;  s0_channels(5)  <= chan5_i;
				s0_channels(6)  <= chan6_i;  s0_channels(7)  <= chan7_i;
				s0_channels(8)  <= chan8_i;  s0_channels(9)  <= chan9_i;
				s0_channels(10) <= chan10_i; s0_channels(11) <= chan11_i;
				s0_thres_st1 	 <= threshold_stage1_i; 
				s0_thres_st2 	 <= threshold_stage2_i;
			end if;
		end if;
	end process;

	GEN_STAGE1: for i in 0 to 9 generate     
		inst_sw_adder : entity work.sliding_window_adder(rtl)
			generic map ( DATA_WIDTH_g => DATA_WIDTH_g )
			port map (
				 chan0_i 	  => s0_channels(i),
				 chan1_i 	  => s0_channels(i+1),
				 chan2_i 	  => s0_channels(i+2),
				 window_sum_o => window_sums_comb(i)
			);
			
		inst_sw_comp : entity work.threshold_comparator(rtl)
			generic map ( DATA_WIDTH_g => DATA_WIDTH_g+2 )
			port map (
				energy_i    => window_sums_comb(i),
				threshold_i => s0_thres_st1,
				trigger_o   => window_pass_flags(i)
			);
	end generate GEN_STAGE1;

	stage1_pass_comb <= '1' when (unsigned(window_pass_flags) > 0) else '0';
	
	process(clk_i)
		begin
		if rising_edge(clk_i) then
			if reset_i = '1' then
				s1_valid <= '0';
			else
				s1_valid 		<= s0_valid;
				s1_channels 	<= s0_channels;
				s1_thres_st2 	<= s0_thres_st2;
				s1_stage1_pass <= stage1_pass_comb;
			end if;
		end if;
	end process;

	inst_global_adder : entity work.global_adder(rtl)
		generic map ( DATA_WIDTH_g => DATA_WIDTH_g )
		port map (
			chan0_i  => s1_channels(0),  chan1_i  => s1_channels(1), 
			chan2_i  => s1_channels(2),  chan3_i  => s1_channels(3), 
			chan4_i  => s1_channels(4),  chan5_i  => s1_channels(5),
			chan6_i  => s1_channels(6),  chan7_i  => s1_channels(7), 
			chan8_i  => s1_channels(8),  chan9_i  => s1_channels(9), 
			chan10_i	=> s1_channels(10), chan11_i => s1_channels(11),
			global_sum_o => global_sum_comb
		);

	inst_global_comp : entity work.threshold_comparator(rtl)
		generic map ( DATA_WIDTH_g => DATA_WIDTH_g+4 )
		port map (
			energy_i    => global_sum_comb,
			threshold_i => s1_thres_st2,
			trigger_o   => stage2_pass_comb
		);
		
	process(clk_i)
		begin
		if rising_edge(clk_i) then
			if reset_i = '1' then
				s2_valid <= '0';
			else
				s2_valid 		<= s1_valid;
				s2_stage1_pass <= s1_stage1_pass;
				s2_stage2_pass <= stage2_pass_comb;
			end if;
		end if;
	end process;
	
	final_accept_comb <= '1' when (s2_stage1_pass = '1' and s2_stage2_pass = '1') else '0';
	
	process(clk_i)
	begin
	  if rising_edge(clk_i) then
		 if reset_i = '1' then
			s3_valid       <= '0';
			final_accept_o <= '0';
		 else
			s3_valid       <= s2_valid;
			final_accept_o <= final_accept_comb;
		 end if;
	  end if;
	end process;

	end rtl;