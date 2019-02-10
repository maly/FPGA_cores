-- BBC Micro for Altera DE1
--
-- Copyright (c) 2011 Mike Stirling
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity m6522_tb is
end entity;

architecture tb of m6522_tb is

component M6522 is
  port (

    I_RS              : in    std_logic_vector(3 downto 0);
    I_DATA            : in    std_logic_vector(7 downto 0);
    O_DATA            : out   std_logic_vector(7 downto 0);
    O_DATA_OE_L       : out   std_logic;

    I_RW_L            : in    std_logic;
    I_CS1             : in    std_logic;
    I_CS2_L           : in    std_logic;

    O_IRQ_L           : out   std_logic; -- note, not open drain
    -- port a
    I_CA1             : in    std_logic;
    I_CA2             : in    std_logic;
    O_CA2             : out   std_logic;
    O_CA2_OE_L        : out   std_logic;

    I_PA              : in    std_logic_vector(7 downto 0);
    O_PA              : out   std_logic_vector(7 downto 0);
    O_PA_OE_L         : out   std_logic_vector(7 downto 0);

    -- port b
    I_CB1             : in    std_logic;
    O_CB1             : out   std_logic;
    O_CB1_OE_L        : out   std_logic;

    I_CB2             : in    std_logic;
    O_CB2             : out   std_logic;
    O_CB2_OE_L        : out   std_logic;

    I_PB              : in    std_logic_vector(7 downto 0);
    O_PB              : out   std_logic_vector(7 downto 0);
    O_PB_OE_L         : out   std_logic_vector(7 downto 0);

    I_P2_H            : in    std_logic; -- high for phase 2 clock  ____----__
    RESET_L           : in    std_logic;
    ENA_4             : in    std_logic; -- clk enable
    CLK               : in    std_logic
    );
end component;

signal rs		:	std_logic_vector(3 downto 0) := "0000";
signal di		:	std_logic_vector(7 downto 0) := "00000000";
signal do		:	std_logic_vector(7 downto 0);
signal n_d_oe	:	std_logic;
signal r_nw		:	std_logic := '1';
signal cs1		:	std_logic := '0';
signal n_cs2	:	std_logic := '0'; 
signal n_irq	:	std_logic;
signal ca1_in	:	std_logic := '0';
signal ca2_in	:	std_logic := '0';
signal ca2_out	:	std_logic;
signal n_ca2_oe	:	std_logic;
signal pa_in	:	std_logic_vector(7 downto 0) := "00000000";
signal pa_out	:	std_logic_vector(7 downto 0);
signal n_pa_oe	:	std_logic_vector(7 downto 0);
signal cb1_in	:	std_logic := '0';
signal cb1_out	:	std_logic;
signal n_cb1_oe	:	std_logic;
signal cb2_in	:	std_logic := '0';
signal cb2_out	:	std_logic;
signal n_cb2_oe	:	std_logic;
signal pb_in	:	std_logic_vector(7 downto 0) := "00000000";
signal pb_out	:	std_logic_vector(7 downto 0);
signal n_pb_oe	:	std_logic_vector(7 downto 0);

signal phase2	:	std_logic := '0';
signal n_reset	:	std_logic := '0';
signal clken	:	std_logic := '0';
signal clock	:	std_logic := '0';

begin

	uut: m6522 port map (
		rs, di, do, n_d_oe,
		r_nw, cs1, n_cs2, n_irq,
		ca1_in, ca2_in, ca2_out, n_ca2_oe,
		pa_in, pa_out, n_pa_oe,
		cb1_in, cb1_out, n_cb1_oe,
		cb2_in, cb2_out, n_cb2_oe,
		pb_in, pb_out, n_pb_oe,
		phase2, n_reset, clken, clock
		);
		
	clock <= not clock after 125 ns; -- 4x 1 MHz
	phase2 <= not phase2 after 500 ns;
	clken <= '1'; -- all cycles enabled
		
	process
	begin
		wait for 1 us;
		-- Release reset
		n_reset <= '1';
	end process;
	
	process
	
	procedure reg_write(
		a : in std_logic_vector(3 downto 0);
		d : in std_logic_vector(7 downto 0)) is
	begin
		wait until falling_edge(phase2);
		rs <= a;
		di <= d;
		cs1 <= '1';
		r_nw <= '0';
		wait until falling_edge(phase2);
		cs1 <= '0';
		r_nw <= '1';
	end procedure;
	
	procedure reg_read(
		a : in std_logic_vector(3 downto 0)) is
	begin
		wait until falling_edge(phase2);
		rs <= a;
		cs1 <= '1';
		r_nw <= '1';
		wait until falling_edge(phase2);
		cs1 <= '0';
	end procedure;
	
	begin
		wait for 2 us;
		
		-- Set port A and B to output
		reg_write("0010","11111111");
		reg_write("0011","11111111");
		
		-- Write to port B
		reg_write("0000","10101010");
		-- Write to port B
		reg_write("0000","01010101");
		-- Write to port A (no handshake)
		reg_write("1111","10101010");
		-- Write to port A (with handshake)
		reg_write("0001","01010101");
		
		-- Set port A and B to input
		reg_write("0010","00000000");
		reg_write("0011","00000000");
		
		-- Apply input stimuli and read from ports
		pa_in <= "10101010";
		pb_in <= "01010101";
		reg_read("0000");
		reg_read("0001");
		
		-- Test CA1 interrupt
		ca1_in <= '0';
		reg_write("1100","00000001"); -- PCR - interrupt on rising edge
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","10000010"); -- Enable CA1 interrupt
		ca1_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0001"); -- Should clear interrupt
		wait for 2 us;
		reg_write("1100","00000000"); -- PCR - interrupt on falling edge
		ca1_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_write("1101","00000010"); -- Should clear interrupt
		wait for 2 us;
		reg_write("1110","00000010"); -- Disable CA1 interrupt
		
		-- Test CB1 interrupt
		cb1_in <= '0';
		reg_write("1100","00010000"); -- PCR - interrupt on rising edge
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","10010000"); -- Enable CB1 interrupt
		cb1_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0000"); -- Should clear interrupt
		wait for 2 us;
		reg_write("1100","00000000"); -- PCR - interrupt on falling edge
		cb1_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_write("1101","00010000"); -- Should clear interrupt
		wait for 2 us;
		reg_write("1110","00010000"); -- Disable CA1 interrupt
		
		-- Test CA2 interrupt modes
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","10000001"); -- Enable CA2 interrupt
		-- mode 2 (+ve edge, clear on read/write)
		reg_write("1100","00000100"); -- PCR
		ca2_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("1111"); -- Should not clear interrupt
		reg_read("0001"); -- Should clear interrupt
		wait for 2 us;
		-- mode 0 (-ve edge, clear on read/write)
		reg_write("1100","00000000"); -- PCR
		ca2_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("1111"); -- Should not clear interrupt
		reg_read("0001"); -- Should clear interrupt
		wait for 2 us;
		-- mode 3 (+ve edge, don't clear on read/write)
		reg_write("1100","00000110");
		ca2_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("1111"); -- Should not clear interrupt
		reg_read("0001"); -- Should not clear interrupt
		reg_write("1101","00000001"); -- Should clear interrupt
		wait for 2 us;
		-- mode 1 (-ve edge, don't clear on read/write)
		reg_write("1100","00000010");
		ca2_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("1111"); -- Should not clear interrupt
		reg_read("0001"); -- Should not clear interrupt
		reg_write("1101","00000001"); -- Should clear interrupt
		wait for 2 us;
		
		-- Test CA2 output modes
		-- mode 4 (set low on read/write of ORA, set high on CA1 interrupt edge)
		reg_write("1100","00001000");
		-- mode 5 (set low for 1 cycle on read/write ORA)
		reg_write("1100","00001010");
		-- mode 6 (held low)
		reg_write("1100","00001100");
		-- mode 7 (held high)
		reg_write("1100","00001110");

		-- Test CB2 interrupt modes
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","10001000"); -- Enable CB2 interrupt
		-- mode 2 (+ve edge, clear on read/write)
		reg_write("1100","01000000"); -- PCR
		cb2_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0000"); -- Should clear interrupt
		wait for 2 us;
		-- mode 0 (-ve edge, clear on read/write)
		reg_write("1100","00000000"); -- PCR
		cb2_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0000"); -- Should clear interrupt
		wait for 2 us;
		-- mode 3 (+ve edge, don't clear on read/write)
		reg_write("1100","01100000");
		cb2_in <= '1'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0000"); -- Should not clear interrupt
		reg_write("1101","00001000"); -- Should clear interrupt
		wait for 2 us;
		-- mode 1 (-ve edge, don't clear on read/write)
		reg_write("1100","00100000");
		cb2_in <= '0'; -- Trigger event
		wait for 2 us;
		reg_read("1101");
		reg_read("0000"); -- Should not clear interrupt
		reg_write("1101","00001000"); -- Should clear interrupt
		wait for 2 us;
		
		-- Test CB2 output modes
		-- mode 4 (set low on read/write of ORA, set high on CA1 interrupt edge)
		reg_write("1100","10000000");
		-- mode 5 (set low for 1 cycle on read/write ORA)
		reg_write("1100","10100000");
		-- mode 6 (held low)
		reg_write("1100","11000000");
		-- mode 7 (held high)
		reg_write("1100","11100000");		
		
		-- Timer 1 timeout
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","11000000"); -- Enable timer 1 interrupt
		-- Count to 16
		reg_write("0100","00010000");
		reg_write("0101","00000000");
		wait for 50 us;
		-- Count to 16
		reg_write("0100","00010000");
		reg_write("0101","00000000"); -- Should clear interrupt
		wait for 50 us;
		reg_read("0100"); -- Should clear interrupt
		
		-- Timer 2 timeout
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1110","10100000"); -- Enable timer 2 interrupt
		-- Count to 16
		reg_write("1000","00010000");
		reg_write("1001","00000000");
		wait for 50 us;
		-- Count to 16
		reg_write("1000","00010000");
		reg_write("1001","00000000"); -- Should clear interrupt
		wait for 50 us;
		reg_read("1000"); -- Should clear interrupt
		
		-- Timer 2 test similar to BBC usage (speech interrupt)
		-- PB6 high
		pb_in(6) <= '1';
		reg_write("1101","01111111"); -- Clear interrupts
		reg_write("1110","01111111"); -- Disable all interrupts
		reg_write("1011","00100000"); -- Timer 2 PB6 counter mode
		reg_write("1000","00000001"); -- Start at 1
		reg_write("1001","00000000");
		reg_write("1110","10100000"); -- Enable timer 2 interrupt
		wait for 5 us;
		-- Generate falling edge
		pb_in(6) <= '0';
		wait for 5 us;
		-- Clear interrupt
		reg_write("1101","00100000");
		-- Zero timer high byte
		reg_write("1001","00000000");
		
		wait;
	end process;

end architecture;
