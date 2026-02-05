library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sliding_window_adder is
	generic (
		DATA_WIDTH_g : integer := 16
	);
	port (
		chan0_i 	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan1_i 	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		chan2_i 	 : in  unsigned(DATA_WIDTH_g-1 downto 0);
		window_sum_o : out unsigned(DATA_WIDTH_g+1 downto 0)
	);
end sliding_window_adder;

architecture rtl of sliding_window_adder is
begin
	window_sum_o <= resize(chan0_i, window_sum_o'length) + 
					resize(chan1_i, window_sum_o'length) + 
					resize(chan2_i, window_sum_o'length);
end rtl;