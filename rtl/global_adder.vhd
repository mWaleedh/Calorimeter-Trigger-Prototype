library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity global_adder is
	generic (
		DATA_WIDTH_g : integer := 16
	);
	port (
		chan0_i, chan1_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan2_i, chan3_i 	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan4_i, chan5_i   : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan6_i, chan7_i	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan8_i, chan9_i	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan10_i, chan11_i : in  unsigned(DATA_WIDTH_g-1 downto 0);
		global_sum_o 		 : out unsigned(DATA_WIDTH_g+3 downto 0)
	);
end global_adder;

architecture rtl of global_adder is
	signal sum_duo0_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_duo1_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_duo2_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_duo3_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_duo4_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_duo5_s  : unsigned(DATA_WIDTH_g downto 0);
	signal sum_quad0_s : unsigned(DATA_WIDTH_g+1 downto 0);
	signal sum_quad1_s : unsigned(DATA_WIDTH_g+1 downto 0);
	signal sum_quad2_s : unsigned(DATA_WIDTH_g+1 downto 0);
begin
	sum_duo0_s <= resize(chan0_i, sum_duo0_s'length) + resize(chan1_i, sum_duo0_s'length);
	sum_duo1_s <= resize(chan2_i, sum_duo1_s'length) + resize(chan3_i, sum_duo1_s'length);
	sum_duo2_s <= resize(chan4_i, sum_duo2_s'length) + resize(chan5_i, sum_duo2_s'length);
	sum_duo3_s <= resize(chan6_i, sum_duo3_s'length) + resize(chan7_i, sum_duo3_s'length);
	sum_duo4_s <= resize(chan8_i, sum_duo4_s'length) + resize(chan9_i, sum_duo4_s'length);
	sum_duo5_s <= resize(chan10_i, sum_duo5_s'length) + resize(chan11_i, sum_duo5_s'length);

	sum_quad0_s <= resize(sum_duo0_s, sum_quad0_s'length) + resize(sum_duo1_s, sum_quad0_s'length);
	sum_quad1_s <= resize(sum_duo2_s, sum_quad1_s'length) + resize(sum_duo3_s, sum_quad1_s'length);
	sum_quad2_s <= resize(sum_duo4_s, sum_quad2_s'length) + resize(sum_duo5_s, sum_quad2_s'length);

	global_sum_o <= resize(sum_quad0_s, global_sum_o'length) +
						 resize(sum_quad1_s, global_sum_o'length) +
						 resize(sum_quad2_s, global_sum_o'length);
end rtl;	