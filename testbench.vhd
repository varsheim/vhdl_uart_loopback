--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:32:09 04/01/2020
-- Design Name:   
-- Module Name:   C:/xilinx_ws/vhdl_uart_loopback/testbench.vhd
-- Project Name:  vhdl_uart_loopback
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top_module
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE behavior OF testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_module
	 GENERIC (
			g_CLKS_PER_UART_BIT : integer := 104     -- Needs to be set correctly
	 );
    PORT(
         i_Switch : IN  std_logic_vector(1 downto 0);
         i_UartRX : IN  std_logic;
         i_Clk : IN  std_logic;
         o_LED : OUT  std_logic;
         o_UartTX : OUT  std_logic;
         o_SegEn : OUT  std_logic_vector(2 downto 0);
         o_SegLED : OUT  std_logic_vector(7 downto 0);
			o_SwitchBCHcnt : OUT std_logic_vector(11 downto 0);
			o_SwitchBCHcntReceived : OUT std_logic_vector(11 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_Switch : std_logic_vector(1 downto 0) := (others => '1'); -- button released is '1'
   signal i_UartRX : std_logic := '1';
   signal i_Clk : std_logic := '0';

 	--Outputs
   signal o_LED : std_logic;
   signal o_UartTX : std_logic;
   signal o_SegEn : std_logic_vector(2 downto 0);
   signal o_SegLED : std_logic_vector(7 downto 0);
	signal o_SwitchBCHcntReceived : std_logic_vector(11 downto 0);
	signal o_SwitchBCHcnt : std_logic_vector(11 downto 0);

   -- Clock period definitions
   constant i_Clk_period : time := 100 ns;
	
	
	-- Test Bench uses a 10 MHz Clock
	-- Want to interface to 115200 baud UART
	-- 10000000 / 115200 = 87 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 87;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_module 
	GENERIC MAP (
			g_CLKS_PER_UART_BIT => c_CLKS_PER_BIT
	)
	PORT MAP (
          i_Switch => i_Switch,
          i_UartRX => o_UartTX,
          i_Clk => i_Clk,
          o_LED => o_LED,
          o_UartTX => o_UartTX,
          o_SegEn => o_SegEn,
          o_SegLED => o_SegLED,
			 o_SwitchBCHcnt => o_SwitchBCHcnt,
			 o_SwitchBCHcntReceived => o_SwitchBCHcntReceived
        );

   -- Clock process definitions
   i_Clk_process :process
   begin
		i_Clk <= '0';
		wait for i_Clk_period/2;
		i_Clk <= '1';
		wait for i_Clk_period/2;
   end process;
 
	-- wire uart output with input
	i_UartRX <= o_UartTX;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for i_Clk_period*10;

      -- insert stimulus here 
		
		wait for 20 ms;
		i_Switch(0) <= '0';
		wait for 50 ms;
		i_Switch(0) <= '1';

		wait for 100 ms;
		i_Switch(0) <= '0';
		wait for 50 ms;
		i_Switch(0) <= '1';
		
		wait for 100 ms;
		i_Switch(0) <= '0';
		wait for 50 ms;
		i_Switch(0) <= '1';
		
		wait for 100 ms;
		i_Switch(0) <= '0';
		wait for 50 ms;
		i_Switch(0) <= '1';
      wait;
   end process;

END;
