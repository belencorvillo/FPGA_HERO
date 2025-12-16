----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2025 23:48:54
-- Design Name: 
-- Module Name: vida_display - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity life_bar_ctrl is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        lives      : in  INTEGER range 0 to 3; -- Entrada de vidas (3, 2, 1, 0)
        led16_r, led16_g, led16_b : out STD_LOGIC;
        led17_r, led17_g, led17_b : out STD_LOGIC
    );
end life_bar_ctrl;

architecture Behavioral of life_bar_ctrl is

    signal r_val, g_val, b_val : std_logic;
    constant BLINK_SPEED : integer := 25_000_000;
    signal blink_count   : integer range 0 to BLINK_SPEED := 0;
    signal blink_state   : std_logic := '0';

begin

    -- Parpadeo
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                blink_count <= 0;
                blink_state <= '0';
            else
                if blink_count = BLINK_SPEED then
                    blink_count <= 0;
                    blink_state <= not blink_state; -- Invierte estado
                else
                    blink_count <= blink_count + 1;
                end if;
            end if;
        end if;
    end process;

    process(lives, blink_state)
    begin
        r_val <= '0'; g_val <= '0'; b_val <= '0'; --todo apagado
        
        case lives is
            when 3 => -- VERDE
                g_val <= '1'; 
          
            when 2 => -- AMARILLO
                r_val <= '1';
                g_val <= '1';
                
            when 1 => -- ROJO
                r_val <= '1';
                
            when 0 => -- GAME OVER (Rojo Parpadeando)
                if blink_state = '1' then
                    r_val <= '1';
                else
                    r_val <= '0';
                end if;
                
            when others => -- Azul para error
                b_val <= '1'; 
        end case;
    end process;

    led16_r <= r_val; led16_g <= g_val; led16_b <= b_val;
    led17_r <= r_val; led17_g <= g_val; led17_b <= b_val;

end Behavioral;
