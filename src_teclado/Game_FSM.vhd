----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.12.2025 13:23:43
-- Design Name: 
-- Module Name: Game_FSM - Behavioral
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

entity Game_FSM is
    Port ( 
        clk               : in  STD_LOGIC;
        reset             : in  STD_LOGIC; -- Botón BTNC
        start_btn         : in  STD_LOGIC; -- Botón para iniciar (ej: BTNU o Enter)

        color_pulsado     : in  STD_LOGIC_VECTOR(4 downto 0); -- teclas (G,F,D,S,A)
        esc               : in  std_logic;   
        btn_1             : in  std_logic;   
        btn_2             : in  std_logic;   
        
        nota_en_hitzone   : in  STD_LOGIC_VECTOR(4 downto 0); -- De VIDEO: ¿Qué notas hay en la zona?
        nota_pasa_hitzone : in  STD_LOGIC;                    -- De VIDEO: Hay que restar vida
        song_finished     : in  STD_LOGIC;                    -- De AUDIO: ¿Acabó la canción?
        
        current_state     : out STD_LOGIC_VECTOR(2 downto 0); -- 0:Menu, 1:Play, 2: Pausa, 3:Win, 4:Lose
        puntuacion        : out STD_LOGIC_VECTOR(31 downto 0);
        vida              : out INTEGER range 0 to 3;
        
        nota_destruida    : out std_logic_vector (4 downto 0); -- Vector que se pasa a vídeo si la nota está siendo destruida
        nota_acierto      : out STD_LOGIC;
        nota_fallada      : out STD_LOGIC  -- Para hacer sonar error
    );
end Game_FSM;

architecture Behavioral of Game_FSM is

    -- Definición de Estados
    type state_type is (MENU, JUGANDO, PAUSA, WIN, GAMEOVER);
    signal state, next_state : state_type;

    -- Registros de Juego
    signal score        : integer := 0;
    signal lives        : integer range 0 to 3 := 3;
    signal combo_cnt    : integer range 0 to 20 := 0; -- Contador para el combo
    signal multiplier   : integer range 1 to 2 := 1;  -- x1 o x2
    
    -- Detector de Flancos para los botones (Para no sumar puntos infinitos si mantienes la tecla)
    signal btn_prev     : std_logic_vector(4 downto 0) := (others => '0');
    signal btn_pressed  : std_logic_vector(4 downto 0); -- Solo vale '1' en el instante de pulsar
    signal esc_prev, one_prev, two_prev : std_logic := '0';
    signal btn_pulsado_pulse : std_logic_vector(4 downto 0);
    signal pulse_esc, pulse_1, pulse_2  : std_logic;
    signal acierto : std_logic := '0';
    
begin

    Detectores_Gen: for i in 0 to 4 generate
        Mi_Detector: entity work.DetectorFlancosSubida
        port map (
            CLK     => clk,
            SYNC_IN => color_pulsado(i),      -- Entrada: Tecla mantenida
            EDGE    => btn_pulsado_pulse(i) -- Salida: Pulso de 1 ciclo
        );
    end generate;

    Det_1: entity work.DetectorFlancosSubida
    port map (
        CLK     => clk,
        SYNC_IN => btn_1,
        EDGE    => pulse_1
    );

    Det_2: entity work.DetectorFlancosSubida
    port map (
        CLK     => clk,
        SYNC_IN => btn_2,
        EDGE    => pulse_2
    );
   
    process(clk)
    begin
        if rising_edge(clk) then
            acierto <= '0';         
            nota_fallada <= '0';
            nota_destruida <= "00000";
            if reset = '0' then
                state <= MENU;
                score <= 0;
                lives <= 3;
                combo_cnt <= 0;
                multiplier <= 1;
            else
                -- Máquina de Estados
                case state is

                    when MENU =>
                        score <= 0;
                        lives <= 3;
                        combo_cnt <= 0;
                        if start_btn = '1' then
                            state <= JUGANDO;
                        end if;

                    when JUGANDO =>
                    
                        if pulse_esc = '1' then
                            state <= PAUSA;                            
                        elsif lives = 0 then
                            state <= GAMEOVER; --perder
                        elsif song_finished = '1' then
                            state <= WIN; --ganar
                        end if;

                        if (btn_pulsado_pulse /= "00000") then --Si se pulsa un botón y este coincide con el que viene de vídeo entonces es un acierto
                            if (btn_pulsado_pulse = nota_en_hitzone) then
                                nota_destruida <= btn_pulsado_pulse; --acierto
                                acierto <= '1';
                                -- Cálculo de Puntos
                                if (nota_en_hitzone = "00001" or nota_en_hitzone="00010" or nota_en_hitzone="00100" or nota_en_hitzone="01000" or nota_en_hitzone="10000") then
                                    score <= score + (50 * multiplier); -- Nota normal
                                else
                                    score <= score + (100 * multiplier); -- Acorde
                                end if;
                                
                                if combo_cnt < 10 then -- Gestión del Combo
                                    combo_cnt <= combo_cnt + 1;
                                else
                                    multiplier <= 2; -- Activar x2
                                end if;

                            else -- SI no son exactamente iguales no se destruye nada
                                nota_destruida <= "00000"; --fallo
                    
                            end if;
                        end if;
                        
                        if nota_pasa_hitzone = '1' then
                            nota_fallada <= '1'; -- Feedback visual/sonoro
                            combo_cnt <= 0;
                            multiplier <= 1;
                            if lives > 0 then lives <= lives - 1; end if;
                        end if;
                    
                    when PAUSA =>
                        if pulse_1 = '1' then
                            state <= MENU;
                        
                        elsif pulse_2 = '1' then
                            state <= JUGANDO;
                            
                        elsif pulse_esc = '1' then -- Si pulsa esc tmbn vuelve a partida
                            state <= JUGANDO;
                        end if;
                            
                    when WIN =>
                        if start_btn = '1' then state <= MENU; end if; --Se congela todo y se espera reset

                    when GAMEOVER =>
                        if start_btn = '1' then state <= MENU; end if; --Se congela todo y se espera reset

                    when others =>
                        state <= MENU;
                end case;
            end if;
        end if;
    end process;

    puntuacion <= std_logic_vector(to_unsigned(score, 32)); --cast de integer a vector
    vida <= lives;
    nota_acierto <= acierto;

    with state select
        current_state <= "000" when MENU,
                         "001" when JUGANDO,
                         "010" when WIN,
                         "011" when GAMEOVER,
                         "100" when PAUSA,
                         "000" when others;
end Behavioral;
