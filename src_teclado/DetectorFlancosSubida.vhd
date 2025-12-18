----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2025 13:36:36
-- Design Name: 
-- Module Name: DetectorFlancosSubida - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DetectorFlancosSubida is

port (
    CLK : in std_logic;
    SYNC_IN : in std_logic;
    EDGE : out std_logic
);

end DetectorFlancosSubida;

architecture Behavioral of DetectorFlancosSubida is

    signal sreg : std_logic_vector(2 downto 0) := "000";

begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            sreg <= sreg(1 downto 0) & SYNC_IN;
        end if;
    end process;

    with sreg select
    EDGE <= '1' when "011",
            '0' when others;

end Behavioral;
