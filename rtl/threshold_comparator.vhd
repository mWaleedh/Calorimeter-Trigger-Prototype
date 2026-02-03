library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity threshold_comparator is
	generic (
		DATA_WIDTH_g : integer := 16
	);
	port (
		energy_i 	: in  unsigned(DATA_WIDTH_g-1 downto 0);
		threshold_i : in  unsigned(DATA_WIDTH_g-1 downto 0);
		trigger_o   : out std_logic
	);
end threshold_comparator;

architecture rtl of threshold_comparator is
begin
	trigger_o <= '1' when (energy_i >= threshold_i) else '0';
end rtl;	