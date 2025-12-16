----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2025 22:19:52
-- Design Name: 
-- Module Name: puntacion_display - Behavioral
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

entity score_display_ctrl is
    Port ( 
        clk          : in  STD_LOGIC; -- Reloj de 100MHz
        reset        : in  STD_LOGIC;
        score_in     : in  STD_LOGIC_VECTOR (31 downto 0); -- Entrada de Puntuación: 32 bits (8 dígitos hexadecimales/BCD)
        seg_anodes   : out STD_LOGIC_VECTOR (7 downto 0); -- Anodos (Selección de display)
        seg_cathodes : out STD_LOGIC_VECTOR (6 downto 0)  -- Catodos (Dibujo del número)
    );
end score_display_ctrl;

architecture Behavioral of score_display_ctrl is

    constant REFRESH_DIV : integer := 100000; 
    signal refresh_counter : integer range 0 to REFRESH_DIV := 0;
    signal digit_tick      : std_logic := '0';
    signal digit_select    : integer range 0 to 7 := 0;-- Estado actual
    signal current_nibble  : std_logic_vector(3 downto 0); --  Número en el display

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                refresh_counter <= 0;
                digit_tick <= '0';
            else
                if refresh_counter = REFRESH_DIV then
                    refresh_counter <= 0;
                    digit_tick <= '1';
                else
                    refresh_counter <= refresh_counter + 1;
                    digit_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                digit_select <= 0;
            elsif digit_tick = '1' then
                if digit_select = 7 then
                    digit_select <= 0;
                else
                    digit_select <= digit_select + 1;
                end if;
            end if;
        end if;
    end process;

    -- Dependiendo de 'digit_select', se elige qué bits de los 32 mostrar
    -- y qué ánodo activar
    process(digit_select, score_in)
    begin
   
        seg_anodes <= (others => '1');
        
        case digit_select is
            when 0 => --Derecha LSB
                seg_anodes(0)  <= '0'; -- Encender
                current_nibble <= score_in(3 downto 0);
            when 1 => 
                seg_anodes(1)  <= '0';
                current_nibble <= score_in(7 downto 4);
            when 2 => 
                seg_anodes(2)  <= '0';
                current_nibble <= score_in(11 downto 8);
            when 3 => 
                seg_anodes(3)  <= '0';
                current_nibble <= score_in(15 downto 12);
            when 4 => 
                seg_anodes(4)  <= '0';
                current_nibble <= score_in(19 downto 16);
            when 5 => 
                seg_anodes(5)  <= '0';
                current_nibble <= score_in(23 downto 20);
            when 6 => 
                seg_anodes(6)  <= '0';
                current_nibble <= score_in(27 downto 24);
            when 7 => -- Izquierda MSB
                seg_anodes(7)  <= '0';
                current_nibble <= score_in(31 downto 28);
            when others =>
                current_nibble <= "0000";
        end case;
    end process;

    -- Convierte el número de 4 bits a los segmentos a,b,c,d,e,f,g
    process(current_nibble)
    begin
        case current_nibble is
            when "0000" => seg_cathodes <= "1000000"; -- 0
            when "0001" => seg_cathodes <= "1111001"; -- 1
            when "0010" => seg_cathodes <= "0100100"; -- 2
            when "0011" => seg_cathodes <= "0110000"; -- 3
            when "0100" => seg_cathodes <= "0011001"; -- 4
            when "0101" => seg_cathodes <= "0010010"; -- 5
            when "0110" => seg_cathodes <= "0000010"; -- 6
            when "0111" => seg_cathodes <= "1111000"; -- 7
            when "1000" => seg_cathodes <= "0000000"; -- 8
            when "1001" => seg_cathodes <= "0010000"; -- 9
            -- Letras Hexadecimales 
            when "1010" => seg_cathodes <= "0001000"; -- A
            when "1011" => seg_cathodes <= "0000011"; -- b
            when "1100" => seg_cathodes <= "1000110"; -- C
            when "1101" => seg_cathodes <= "0100001"; -- d
            when "1110" => seg_cathodes <= "0000110"; -- E
            when "1111" => seg_cathodes <= "0001110"; -- F
            when others => seg_cathodes <= "1111111"; -- Todo apagado
        end case;
    end process;

end Behavioral;
