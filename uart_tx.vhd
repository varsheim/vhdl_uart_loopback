library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
	generic (
		g_CLKS_PER_BIT : integer := 104     -- Needs to be set correctly
	);
	port (
		i_Clk      : in STD_LOGIC;
		i_TXByte   : in STD_LOGIC_VECTOR(7 downto 0);
		i_TXDV     : in STD_LOGIC;
		o_TXSerial : out STD_LOGIC;
		o_TXActive : out STD_LOGIC
	);
end uart_tx;

architecture Behavioral of uart_tx is
	type t_SMMain is (s_Idle, s_TXStartBit, s_TXByteBits, s_TXStopBit, s_Cleanup);
	signal r_SMMain : t_SMMain := s_Idle;
	signal w_SMMain : STD_LOGIC_VECTOR(2 downto 0); -- for simulation only

	signal r_ClkCount : integer range 0 to g_CLKS_PER_BIT-1 := 0;
	signal r_BitIndex : integer range 0 to 7 := 0;  -- 8 Bits Total
	signal r_TXByte : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal r_TXDone : STD_LOGIC := '0';
	signal r_TXDV : STD_LOGIC := '0';
	
begin
	p_UART_TX : process (i_Clk)
	begin
		if rising_edge(i_Clk) then
			case r_SMMain is
				when s_Idle =>
					o_TXActive <= '0';
					o_TXSerial <= '1';         -- Drive Line High for Idle
					r_TXDone <= '0';
					r_ClkCount <= 0;
					r_BitIndex <= 0;
					r_TXDV <= i_TXDV;

					if i_TXDV = '1' then
						r_TXByte <= i_TXByte;
						r_SMMain <= s_TXStartBit;
					else
						r_SMMain <= s_Idle;
					end if;
					
				when s_TXStartBit =>
					o_TXActive <= '1';
					o_TXSerial <= '0';

					-- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
					if r_ClkCount < g_CLKS_PER_BIT-1 then
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_TXStartBit;
					else
						r_ClkCount <= 0;
						r_SMMain <= s_TXByteBits;
					end if;
		
				when s_TXByteBits =>
					o_TXSerial <= r_TXByte(r_BitIndex);
          
					if r_ClkCount < g_CLKS_PER_BIT-1 then
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_TXByteBits;
					else
						r_ClkCount <= 0;

					-- Check if we have sent out all bits
						if r_BitIndex < 7 then
							r_BitIndex <= r_BitIndex + 1;
							r_SMMain <= s_TXByteBits;
						else
							r_BitIndex <= 0;
							r_SMMain <= s_TXStopBit;
						end if;
					end if;
					
				when s_TXStopBit =>
					o_TXSerial <= '1';

					-- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
					if r_ClkCount < g_CLKS_PER_BIT-1 then
						r_ClkCount <= r_ClkCount + 1;
						r_SMMain <= s_TXStopBit;
					else
						r_TXDone <= '1';
						r_ClkCount <= 0;
						r_SMMain <= s_Cleanup;
					end if;
				
				when s_Cleanup =>
					o_TXActive <= '0';
					r_TXDone <= '1';
					r_SMMain <= s_Idle;
					
				when others =>
					r_SMMain <= s_Idle;
			end case;
		end if;
	end process p_UART_TX;

end Behavioral;

