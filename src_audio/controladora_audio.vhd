library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.music_pkg.ALL; 

entity controladora_audio is
    Port ( 
        clk_100MHz : in STD_LOGIC;
        reset      : in STD_LOGIC;
        user_hit   : in STD_LOGIC; -- '1' si el usuario está acertando (suena), '0' silencio
        modo_demo  : in std_logic;
        pwm_audio  : out STD_LOGIC;
        pwm_sd     : out STD_LOGIC; -- apagamos sonido (shutdown)
        current_note_index : out integer range 0 to 499;
        play_enable : in STD_LOGIC;  -- '1' = Reproducir, '0' = Reset/Parar
        song_finished : out STD_LOGIC; -- '1' = Canción terminada
        current_state : in STD_LOGIC_VECTOR(2 downto 0); -- Viene de la FSM
        nota_fallada  : in STD_LOGIC  -- Pulso cuando el usuario falla
        
    );
end controladora_audio;

architecture Behavioral of controladora_audio is

-- ESTADOS
    constant ST_MENU     : std_logic_vector(2 downto 0) := "000";
    constant ST_JUGANDO  : std_logic_vector(2 downto 0) := "001";
    constant ST_WIN      : std_logic_vector(2 downto 0) := "010";
    constant ST_GAMEOVER : std_logic_vector(2 downto 0) := "011";
    constant ST_PAUSA    : std_logic_vector(2 downto 0) := "100";

--CANAL 1
    signal counter_pwm1 : integer := 0; --para generar las ondas de sonido
    signal current_freq1 : integer := 0;
    signal pwm_toggle1 : std_logic := '0'; --cambiar pwm para generar vibración (nota)
--CANAL 2
    signal counter_pwm2 : integer := 0;
    signal current_freq2 : integer := 0;
    signal pwm_toggle2 : std_logic := '0';
    
-- RITMO Y TEMPO    
    signal counter_ms  : integer := 0; --para contar en qué ms va de la canción
    signal note_idx : integer range 0 to 499 := 0; --índice nota
    signal current_dur  : integer := 0;
    
-- Señal interna de fin
    signal finished_internal : std_logic := '0';
    
-- Para audio de error por si el usuario falla la nota:
    constant ERROR_FREQ : integer := 50; --50 Hz 
    signal counter_err  : integer := 0;
    signal pwm_err      : std_logic := '0';
    signal error_timer  : integer := 0; --el sonido de error durará 200ms
    signal is_error_active : std_logic := '0';
    
begin
    -- Ponemos esto a '1' para que el chip de audio de la Nexys se encienda
    pwm_sd <= '1'; 
    song_finished <= finished_internal;
    
    -- Lectura de datos del paquete
    current_freq1 <= SEVEN_NATION_SONG(note_idx).freq1;
    current_freq2 <= SEVEN_NATION_SONG(note_idx).freq2;
    current_dur   <= SEVEN_NATION_SONG(note_idx).dur;
    current_note_index <= note_idx;

    process(clk_100MHz, reset)
        variable ticks_1 : integer; --ticks por media onda (para generar onda cuadrada)
        variable ticks_2 : integer;
        variable ticks_err : integer;
    begin
    -- RESET GLOBAL o APAGADO TOTAL
        if reset = '1' or play_enable = '0' then
            note_idx <= 0;
            counter_ms <= 0;
            pwm_toggle1 <= '0';
            pwm_toggle2 <= '0';
            counter_pwm1 <= 0;
            counter_pwm2 <= 0;
            finished_internal <= '0';
            error_timer <= 0;
            is_error_active <= '0';
            counter_err <= 0;
            pwm_err <= '0';
            
        elsif rising_edge(clk_100MHz) then
        
           -- GESTIÓN DE ERROR
           -- Si llega un pulso de fallo, cargamos el temporizador (200ms)
            if nota_fallada = '1' then
                error_timer <= 20000000; -- 200ms a 100MHz
                is_error_active <= '1';
            elsif error_timer > 0 then
                error_timer <= error_timer - 1;
                is_error_active <= '1';
            else
                is_error_active <= '0';
            end if;
            
            -- Generador de onda de Error (Solo si está activo)
            if is_error_active = '1' then
                ticks_err := (100000000 / ERROR_FREQ) / 2;
                if counter_err >= ticks_err then
                    pwm_err <= not pwm_err;
                    counter_err <= 0;
                else
                    counter_err <= counter_err + 1;
                end if;
            else
                pwm_err <= '0';
                counter_err <= 0;
            end if;
           
        --     MÁQUINA DE ESTADOS
     case current_state is
                
              when ST_MENU => 
                note_idx <= 0;
                counter_ms <= 0;
                finished_internal <= '0';
                counter_pwm1 <= 0;
                counter_pwm2 <= 0;
                pwm_toggle1 <= '0';
                pwm_toggle2 <= '0';
                        
               when ST_JUGANDO =>
                
                --Avanzamos si NO ha terminado la cancion
                if finished_internal = '0' then
                
                    -- GENERADOR 1 (Melodía Principal)
                    if current_freq1 > 0 then
                        -- Fórmula: (100MHz / Freq) / 2
                        -- (Se divide entre 2 porque es una onda cuadrada con dos partes iguales)
                        ticks_1 := (100000000 / current_freq1) / 2;
                        
                        if counter_pwm1 >= ticks_1 then --si ya ha pasado el tiempo...
                            pwm_toggle1 <= not pwm_toggle1; --cambio para generar vibración
                            counter_pwm1 <= 0; --reiniciamos para contar el siguiente medio ciclo
                        else
                            counter_pwm1 <= counter_pwm1 + 1;
                        end if;
                    else
                        pwm_toggle1 <= '0';
                    end if;
                    
                    -- GENERADOR 2 (Acorde)
                    if current_freq2 > 0 then
                        ticks_2 := (100000000 / current_freq2) / 2;
                        if counter_pwm2 >= ticks_2 then
                            pwm_toggle2 <= not pwm_toggle2;
                            counter_pwm2 <= 0;
                        else
                            counter_pwm2 <= counter_pwm2 + 1;
                        end if;
                    else
                        pwm_toggle2 <= '0'; -- Si no hay segunda nota, silencio en este canal
                    end if;
        
                    -- RITMO -> Avanza la canción aunque no suene y aunque falle el usuario
                    -- Usamos 100,000 ciclos como aproximación de 1ms a 100MHz
                    if counter_ms >= (current_dur * 100000) then 
                        counter_ms <= 0;
                        
                        -- LÓGICA DE FIN DE CANCIÓN
                            if note_idx = 499 then 
                                finished_internal <= '1'; 
                                -- Nos quedamos aquí (idx 499) hasta que reinicien play_enable
                            else
                                note_idx <= note_idx + 1;
                            end if;   
                    else
                        counter_ms <= counter_ms + 1;
                    end if;
                 end if;
                    
            when ST_PAUSA => 
                    -- Aquí NO sumamos a counter_ms, así que el tiempo se para.
                    -- Correcto para pausa.
                    null;
                    
            when others => --Win/Gameover
                    -- Si finished_internal = '1', nos aseguramos de que haya silencio
                        pwm_toggle1 <= '0';
                        pwm_toggle2 <= '0';
        end case;
     end if;
    end process;

    -- SALIDA FÍSICA: Solo sacamos sonido si hay frecuencia Y el usuario acierta
    -- MEZCLADOR: Puerta OR para juntar las dos ondas (Efecto Distorsión)
    pwm_audio <= pwm_err when (is_error_active = '1') else  -- Prioridad 1: Error
                 (pwm_toggle1 or pwm_toggle2) when (current_state = ST_JUGANDO and (user_hit = '1' or modo_demo = '1')) else -- Prioridad 2: Música
                 '0'; -- Silencio
end Behavioral;
