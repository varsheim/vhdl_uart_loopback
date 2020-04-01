library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top_module is
	generic (
		g_CLKS_PER_UART_BIT : integer := 104     -- Needs to be set correctly
	);
	port (
		i_Switch : in STD_LOGIC_VECTOR(1 downto 0);
		i_UartRX : in STD_LOGIC;
		i_Clk : in STD_LOGIC;
		
		o_LED : out STD_LOGIC;
		o_UartTX : out STD_LOGIC;
		o_SegEn : out STD_LOGIC_VECTOR(2 downto 0);
		o_SegLED : out STD_LOGIC_VECTOR(7 downto 0)
		
		-- simulation only
		--o_SwitchBCHcnt : OUT std_logic_vector(11 downto 0);
		--o_SwitchBCHcntReceived : out STD_LOGIC_VECTOR(11 downto 0)
	);
end top_module;

architecture Behavioral of top_module is
	-- CONSTANTS
	constant c_SEGMENT_PERIOD : integer := 12000; -- 1 miliseconds
	
	-- SIGNALS
	signal r_LED_1 : STD_LOGIC := '0';
	signal r_Switch : STD_LOGIC_VECTOR(1 downto 0) := "00";
	signal w_Switch : STD_LOGIC_VECTOR(1 downto 0);
	
	-- SIGNALS button counter
	signal r_SwitchBCHcnt : STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
	
	-- SIGNALS 7 segments display
	signal r_CurrentSegment : STD_LOGIC_VECTOR(2 downto 0) := "001"; --change to std_logic_vector
	signal r_SegmentTimer : integer range 0 to c_SEGMENT_PERIOD := 0;
	signal r_SegmentCurrentDigit : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	-- UART COMMUNICATION
	signal w_RXDV : STD_LOGIC := '0';
	signal w_TXDV : STD_LOGIC;-- := '0';
	
	signal w_TXActive : STD_LOGIC := '0';
	signal w_TXSerial : STD_LOGIC := '1';

	signal w_RXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	signal w_TXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	
	signal r_SwitchBCHcntReceived : STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
	
	signal r_TXDataReady : STD_LOGIC := '0';
	
begin
	-- Instantiate Debounce Filter
	DebounceInst1 : entity work.debounce_switch
		port map (
			i_Clk    => i_Clk,
			i_Switch => i_Switch(0),
			o_Switch => w_Switch(0));
	
	DebounceInst2 : entity work.debounce_switch
		port map (
			i_Clk    => i_Clk,
			i_Switch => i_Switch(1),
			o_Switch => w_Switch(1));
			
	-- Instantiate UART RX
	UARTRX : entity work.uart_rx
		generic map (
			g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)            -- 12,000,000 / 115,200
		port map (
			i_Clk      => i_Clk,
			i_RXSerial => i_UartRX,
			o_RXDV     => w_RXDV,
			o_RXByte   => w_RXByte);

	-- Instantiate UART TX
	UARTTX : entity work.uart_tx
		generic map (
			g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)            -- 12,000,000 / 115,200
		port map (
			i_Clk      => i_Clk,
			i_TXDV     => w_TXDV,
			i_TXByte   => w_TXByte,
			o_TXSerial => w_TXSerial,
			o_TXActive => w_TXActive);
			
	o_UartTX <= w_TXSerial when w_TXActive = '1' else '1';
	
	-- Instantiate BCH (Binary Coded Hexadecimal) to 7SEG
	BCHToSegmentInst : entity work.bch_to_segment
		port map (
			i_Digit => r_SegmentCurrentDigit,
			o_SegLED => o_SegLED);

	p_Register : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			r_Switch <= not(w_Switch);
			
			-- switch 1 is released
			-- increment HEX counter
			-- send it via UART
			if r_Switch(0) = '1' and not(w_Switch(0)) = '0' then
				-- zmiana stanu LED
				r_LED_1 <= not r_LED_1;
				
				-- BCH increment
				if r_SwitchBCHcnt(3 downto 0) < 15 then
					r_SwitchBCHcnt(3 downto 0) <= r_SwitchBCHcnt(3 downto 0) + 1;
				else
					r_SwitchBCHcnt(3 downto 0) <= "0000";
					if r_SwitchBCHcnt(7 downto 4) < 15 then
						r_SwitchBCHcnt(7 downto 4) <= r_SwitchBCHcnt(7 downto 4) + 1;
					else
						r_SwitchBCHcnt(7 downto 4) <= "0000";
						if r_SwitchBCHcnt(11 downto 8) < 0 then
							r_SwitchBCHcnt(11 downto 8) <= r_SwitchBCHcnt(11 downto 8) + 1;
						else
							r_SwitchBCHcnt(11 downto 8) <= "0000";
						end if;
					end if;
				end if;
				
				-- send the youngest 8 bits of counter via UART
				r_TXDataReady <= '1';
			end if;
			
			-- switch 2 is released
			if r_Switch(1) = '1' and not(w_Switch(1)) = '0' then
				r_SwitchBCHcnt(11 downto 0) <= "000000000000";
				
				-- send the youngest 8 bits of counter via UART
				r_TXDataReady <= '1';
			end if;
			
			if r_TXDataReady = '1' then
				w_TXByte <= r_SwitchBCHcnt(7 downto 0);
				w_TXDV <= '1';
				r_TXDataReady <= '0';
			else
				w_TXDV <= '0';
			end if;
			
			-- set new data to display when it is received
			if w_RXDV = '1' then
				r_SwitchBCHcntReceived(7 downto 0) <= w_RXByte;
			end if;
			
		end if;
	end process p_Register;
	
	p_Display : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			-- activate segment for a specified time
			if r_SegmentTimer < c_SEGMENT_PERIOD - 1 then
				r_SegmentTimer <= r_SegmentTimer + 1;
			elsif r_SegmentTimer = c_SEGMENT_PERIOD - 1 then
				-- shift register
				r_CurrentSegment <= r_CurrentSegment(0) & r_CurrentSegment(2 downto 1);
				r_SegmentTimer <= 0;
			end if;
		end if;
	end process p_Display;
	
	-- multiplex every digit
	with r_CurrentSegment select
		r_SegmentCurrentDigit <= r_SwitchBCHcntReceived(3 downto 0) when "001",
										 r_SwitchBCHcntReceived(7 downto 4) when "010",
										 r_SwitchBCHcntReceived(11 downto 8) when "100",
										 "0000" when others;
	
	o_SegEn <= not(r_CurrentSegment);
	o_LED <= r_LED_1;
	
	-- simulation only
	--o_SwitchBCHcnt <= r_SwitchBCHcnt;
	--o_SwitchBCHcntReceived <= r_SwitchBCHcntReceived;
	
end Behavioral;

