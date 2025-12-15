----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.12.2025 16:47:44
-- Design Name: 
-- Module Name: guitar_decoder - Behavioral
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

entity guitar_decoder is
    Port (        clk            : in  STD_LOGIC;
        reset          : in  STD_LOGIC;
        ps2_code_new   : in  STD_LOGIC;                    
        ps2_code       : in  STD_LOGIC_VECTOR(7 downto 0); 
        
        -- Salida hacia la Lógica de Juego (Game FSM)
        -- Bit 0: Verde (A)
        -- Bit 1: Rojo  (S)
        -- Bit 2: Amarillo (D)
        -- Bit 3: Azul (F)
        -- Bit 4: Naranja (G)
        color_pulsado      : out STD_LOGIC_VECTOR(4 downto 0)
    );
end guitar_decoder;

architecture Behavioral of guitar_decoder is

    -- Definición de Constantes (Códigos de Teclas)
    constant KEY_A_GRN : std_logic_vector(7 downto 0) := x"1C"; -- Tecla A
    constant KEY_S_RED : std_logic_vector(7 downto 0) := x"1B"; -- Tecla S
    constant KEY_D_YEL : std_logic_vector(7 downto 0) := x"23"; -- Tecla D
    constant KEY_F_BLU : std_logic_vector(7 downto 0) := x"2B"; -- Tecla F
    constant KEY_G_ORG : std_logic_vector(7 downto 0) := x"34"; -- Tecla G
    constant CODE_BREAK: std_logic_vector(7 downto 0) := x"F0"; -- Código de soltar

    -- Registros Internos
    signal is_breaking   : std_logic := '0'; -- Bandera: ¿Viene un código de soltar?
    signal buttons_reg   : std_logic_vector(4 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                buttons_reg <= (others => '0');
                is_breaking <= '0';
            else
                -- Si dato nuevo de teclado
                if ps2_code_new = '1' then
                
                    -- CASO 1: Detectamos el código de rotura (F0)
                    if ps2_code = CODE_BREAK then
                        is_breaking <= '1'; -- Activamos la alerta: "Lo siguiente es soltar"
                    
                    -- CASO 2: Llega un código de tecla normal
                    else
                        -- Verificamos qué tecla es y actualizamos su bit correspondiente
                        case ps2_code is
                            
                            -- TECLA A (VERDE) - Bit 0
                            when KEY_A_GRN =>
                                if is_breaking = '1' then
                                    buttons_reg(0) <= '0'; -- Apagar
                                    is_breaking    <= '0'; -- Resetear bandera
                                else
                                    buttons_reg(0) <= '1'; -- Encender
                                end if;

                            -- TECLA S (ROJO) - Bit 1
                            when KEY_S_RED =>
                                if is_breaking = '1' then
                                    buttons_reg(1) <= '0';
                                    is_breaking    <= '0';
                                else
                                    buttons_reg(1) <= '1';
                                end if;

                            -- TECLA D (AMARILLO) - Bit 2
                            when KEY_D_YEL =>
                                if is_breaking = '1' then
                                    buttons_reg(2) <= '0';
                                    is_breaking    <= '0';
                                else
                                    buttons_reg(2) <= '1';
                                end if;

                            -- TECLA F (AZUL) - Bit 3
                            when KEY_F_BLU =>
                                if is_breaking = '1' then
                                    buttons_reg(3) <= '0';
                                    is_breaking    <= '0';
                                else
                                    buttons_reg(3) <= '1';
                                end if;

                            -- TECLA G (NARANJA) - Bit 4
                            when KEY_G_ORG =>
                                if is_breaking = '1' then
                                    buttons_reg(4) <= '0';
                                    is_breaking    <= '0';
                                else
                                    buttons_reg(4) <= '1';
                                end if;

                            -- CUALQUIER OTRA TECLA
                            when others =>
                                is_breaking <= '0'; 
                                
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Asignamos el registro interno a la salida
    color_pulsado <= buttons_reg;

end Behavioral;
