----------------------------------------------------------------------
-- Credits to http://www.nandland.com
-- This is slightly modified code from nandland
----------------------------------------------------------------------
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
-- Example: 12 MHz Clock, 115200 baud UART
-- (12000000)/(115200) = 104

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
	generic (
		g_CLKS_PER_BIT : integer := 104     -- Needs to be set correctly
	);
	port (
		i_Clk      : in  STD_LOGIC;
		i_RXSerial : in  STD_LOGIC;
		o_RXDV     : out STD_LOGIC;
		o_RXByte   : out STD_LOGIC_VECTOR(7 downto 0)
	);
end uart_rx;

architecture Behavioral of uart_rx is
	type t_SMMain is (s_Idle, s_RXStartBit, s_RXDataBits, s_RXStopBit, s_Cleanup);
	signal r_SMMain : t_SMMain := s_Idle;
	signal w_SMMain : STD_LOGIC_VECTOR(2 downto 0); -- for simulation only

	signal r_ClkCount : integer range 0 to g_CLKS_PER_BIT-1 := 0;
	signal r_BitIndex : integer range 0 to 7 := 0;  -- 8 Bits Total
	signal r_RXByte : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal r_RXDV : STD_LOGIC := '0';
  
begin
	-- Purpose: Control RX state machine
	p_UART_RX : process (i_Clk)
	begin
		if rising_edge(i_Clk) then
			case r_SMMain is
				when s_Idle =>
					r_RXDV <= '0';
					r_ClkCount <= 0;
					r_BitIndex <= 0;

					if i_RXSerial = '0' then       -- Start bit detected
						r_SMMain <= s_RXStartBit;
					else
						r_SMMain <= s_Idle;
					end if;

				-- Check middle of start bit to make sure it's still low
				when s_RXStartBit =>
					if r_ClkCount = (g_CLKS_PER_BIT-1)/2 then
						if i_RXSerial = '0' then
							r_ClkCount <= 0;  -- reset counter since we found the middle
							r_SMMain <= s_RXDataBits;
						else
							r_SMMain <= s_Idle;
						end if;
					else
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_RXStartBit;
					end if;

				-- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
				when s_RXDataBits =>
					if r_ClkCount < g_CLKS_PER_BIT-1 then
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_RXDataBits;
					else
						r_ClkCount <= 0;
						r_RXByte(r_BitIndex) <= i_RXSerial;

						-- Check if we have sent out all bits
						if r_BitIndex < 7 then
							r_BitIndex <= r_BitIndex + 1;
							r_SMMain <= s_RXDataBits;
						else
							r_BitIndex <= 0;
							r_SMMain <= s_RXStopBit;
						end if;
					end if;

				-- Receive Stop bit.  Stop bit = 1
				when s_RXStopBit =>
					-- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
					if r_ClkCount < g_CLKS_PER_BIT-1 then
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_RXStopBit;
					else
						r_RXDV <= '1';
						r_ClkCount <= 0;
						r_SMMain <= s_Cleanup;
					end if;

				-- Stay here 1 clock
				when s_Cleanup =>
					r_SMMain <= s_Idle;
					r_RXDV <= '0';

				when others =>
					r_SMMain <= s_Idle;

			end case;
		end if;
	end process p_UART_RX;

	o_RXDV   <= r_RXDV;
	o_RXByte <= r_RXByte;

	-- Create a signal for simulation purposes (allows waveform display)
	w_SMMain <= "000" when r_SMMain = s_Idle else
					 "001" when r_SMMain = s_RXStartBit else
					 "010" when r_SMMain = s_RXDataBits else
					 "011" when r_SMMain = s_RXStopBit else
				    "100" when r_SMMain = s_Cleanup else
					 "101"; -- should never get here

end Behavioral;

