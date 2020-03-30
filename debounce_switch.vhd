library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_switch is
	port (
		i_Clk : in STD_LOGIC;
		i_Switch : in STD_LOGIC;
		o_Switch : out STD_LOGIC
		);
		
end debounce_switch;

architecture Behavioral of debounce_switch is
	constant c_DEBOUNCE_LIMIT : integer := 250000;
	
	signal r_Count : integer range 0 to c_DEBOUNCE_LIMIT := 0;
	signal r_State : STD_LOGIC := '1';
	
begin
	p_Debounce : process(i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if i_Switch /= r_State and r_Count < c_DEBOUNCE_LIMIT then
				r_Count <= r_Count + 1;
			elsif r_Count = c_DEBOUNCE_LIMIT then
				r_State <= i_Switch;
				r_Count <= 0;
			else
				r_Count <= 0;
			end if;
		end if;
	end process p_Debounce;

	o_Switch <= r_State;
end Behavioral;
