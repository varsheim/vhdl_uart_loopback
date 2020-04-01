library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bch_to_segment is
	port (
		i_Digit : in STD_LOGIC_VECTOR(3 downto 0);
		o_SegLED : out STD_LOGIC_VECTOR(7 downto 0)
	);
end bch_to_segment;

architecture Behavioral of bch_to_segment is
begin
	-- 0 is to light up the segment
	-- o_SegLED is dot c b a g f e d
	with i_Digit select
		o_SegLED <= "10001000" when "0000", -- 0
					   "10011111" when "0001", -- 1
					   "11000100" when "0010", -- 2
					   "10000110" when "0011", -- 3
					   "10010011" when "0100", -- 4
					   "10100010" when "0101", -- 5
					   "10100000" when "0110", -- 6
				   	"10001111" when "0111", -- 7
				 	   "10000000" when "1000", -- 8
					   "10000010" when "1001", -- 9
						"10000001" when "1010", -- A
						"10110000" when "1011", -- B
						"11101000" when "1100", -- C
						"10010100" when "1101", -- D
						"11100000" when "1110", -- E
						"11100001" when "1111", -- F
					   "00000000" when others;
end Behavioral;

