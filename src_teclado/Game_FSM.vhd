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
        
        notas_a_destruir    : out std_logic_vector (4 downto 0); -- Vector que se pasa a vídeo si la nota está siendo destruida
        nota_acierto      : out STD_LOGIC;
        nota_fallada      : out STD_LOGIC  -- Para hacer sonar error
    );
end Game_FSM;

architecture Behavioral of Game_FSM is

    -- Definición de Estados
    type state_type is (MENU, JUGANDO, PAUSA, WIN, GAMEOVER);
    signal state : state_type;
    signal aux_reset    : std_logic := '0';

    -- Registros de Juego
    signal score        : unsigned (puntuacion'range) := (others=>'0');
    signal lives        : integer range 0 to 3 := 3;
    signal combo_cnt    : integer range 0 to 20 := 0; -- Contador para el combo
    signal multiplier   : integer range 1 to 2 := 1;  -- x1 o x2
    --signal acierto : std_logic := '0';
    
    -- Señales para detección de flancos interna
    signal color_prev   : std_logic_vector(4 downto 0) := (others => '0');
    signal esc_prev     : std_logic := '0';
    signal btn1_prev    : std_logic := '0';
    signal btn2_prev    : std_logic := '0';

    -- Flags de "Acaba de pulsar"
    signal color_hit    : std_logic_vector(4 downto 0);
    signal any_new_press: std_logic; -- Para saber si hay que comprobar
    signal esc_hit, btn1_hit, btn2_hit : std_logic;
    
    -- Señal interna para notas a destruir
    signal notas_destroy_int : std_logic_vector(4 downto 0);
    
begin

    process(clk)
    begin
        if rising_edge(clk) then
            color_prev <= color_pulsado;
            esc_prev   <= esc;
            btn1_prev  <= btn_1;
            btn2_prev  <= btn_2;
        end if;
    end process;

     -- Generamos pulsos solo cuando hay flanco de subida
    color_hit <= color_pulsado and (not color_prev);
    esc_hit   <= esc and (not esc_prev);
    btn1_hit  <= btn_1 and (not btn1_prev);
    btn2_hit  <= btn_2 and (not btn2_prev);
    
    notas_destroy_int <= (color_pulsado and nota_en_hitzone) when state = JUGANDO else "00000";
    notas_a_destruir  <= notas_destroy_int;
    
    process(clk)
    begin
        if rising_edge(clk) then
            nota_acierto <= '0';         
            nota_fallada <= '0';
            if reset = '1' or aux_reset = '1' then
                state <= MENU;
                score <= (others=>'0');
                lives <= 3;
                combo_cnt <= 0;
                multiplier <= 1;
                aux_reset <= '0';
            else
                -- Máquina de Estados
                case state is

                    when MENU =>
                        score <= (others=>'0');
                        lives <= 3;
                        combo_cnt <= 0;
                        if start_btn = '1' then
                            state <= JUGANDO;
                        end if;

                    when JUGANDO =>
                    
                        if esc_hit = '1' then
                            state <= PAUSA;                            
                        elsif lives = 0 then
                            state <= GAMEOVER; --perder
                        elsif song_finished = '1' then
                            state <= WIN; --ganar
                        end if;

                        if nota_pasa_hitzone = '1' then --FALLO
                            nota_fallada <= '1'; -- Feedback visual/sonoro
                            combo_cnt <= 0;
                            multiplier <= 1;
                            if lives > 0 then lives <= lives - 1; end if;
                        
                        elsif (color_hit and nota_en_hitzone) /= "00000" then  --Si alguna de las teclas que se pulsa coincide con una nota en la hitzone
                                nota_acierto <= '1';
                                -- Cálculo de Puntos
                                score <= score + (50 * multiplier); -- Nota normal
                                if combo_cnt < 10 then -- Gestión del Combo
                                    combo_cnt <= combo_cnt + 1;
                                else
                                    multiplier <= 2; -- Activar x2
                                end if;
                        end if;
                        

                    
                    when PAUSA =>
                        if btn1_hit = '1' then
                            aux_reset <= '1';
                        
                        elsif btn2_hit = '1' then
                            state <= JUGANDO;
                            
                        elsif esc_hit = '1' then -- Si pulsa esc tmbn vuelve a partida
                            state <= JUGANDO;
                        end if;
                            
                    when WIN =>
                        if start_btn = '1' then state <= MENU; end if; --Se congela todo y se espera reset

                    when GAMEOVER =>
                        if start_btn = '1' then aux_reset <= '1'; end if; --Se congela todo y se espera reset

                    when others =>
                        state <= MENU;
                end case;
            end if;
        end if;
    end process;

    puntuacion <= std_logic_vector(score); --cast de integer a vector
    vida <= lives;

    with state select
        current_state <= "000" when MENU,
                         "001" when JUGANDO,
                         "010" when WIN,
                         "011" when GAMEOVER,
                         "100" when PAUSA,
                         "000" when others;
end Behavioral;
