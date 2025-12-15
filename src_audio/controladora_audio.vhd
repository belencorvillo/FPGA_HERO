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
        pwm_audio  : out STD_LOGIC;
        pwm_sd     : out STD_LOGIC; -- apagamos sonido (shutdown)
        current_note_index : out integer range 0 to 499
        
    );
end controladora_audio;

architecture Behavioral of controladora_audio is

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
    
begin
    -- Ponemos esto a '1' para que el chip de audio de la Nexys se encienda
    pwm_sd <= '1'; 
    
    -- Lectura de datos del paquete
    current_freq1 <= SEVEN_NATION_SONG(note_idx).freq1;
    current_freq2 <= SEVEN_NATION_SONG(note_idx).freq2;
    current_dur   <= SEVEN_NATION_SONG(note_idx).dur;
    current_note_index <= note_idx;

    process(clk_100MHz, reset)
        variable ticks_1 : integer; --ticks por media onda (para generar onda cuadrada)
        variable ticks_2 : integer;
    begin
        if reset = '1' then
            note_idx <= 0;
            counter_ms <= 0;
            pwm_toggle1 <= '0';
            pwm_toggle2 <= '0';
        elsif rising_edge(clk_100MHz) then
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

            -- RITMO -> Avanza la canción aunque no suene
            -- Usamos 100,000 ciclos como aproximación de 1ms a 100MHz
            if counter_ms >= (current_dur * 100000) then 
                counter_ms <= 0;
                
                -- ESTE IF HACE QUE CUANDO ACABE VUELVA A EMPEZAR, A LO MEJOR NOS INTERESA FINALIZAR Y YA ESTÁ
                -- YA LO HABLAREMOS :)
                if note_idx = 400 then 
                    note_idx <= 2; -- Bucle infinito saltando intro
                else
                    note_idx <= note_idx + 1;
                end if;
            else
                counter_ms <= counter_ms + 1;
            end if;
        end if;
    end process;

    -- SALIDA FÍSICA: Solo sacamos sonido si hay frecuencia Y el usuario acierta
    -- MEZCLADOR: Puerta OR para juntar las dos ondas (Efecto Distorsión)
    pwm_audio <= (pwm_toggle1 or pwm_toggle2) when (user_hit = '1') else '0';

end Behavioral;
