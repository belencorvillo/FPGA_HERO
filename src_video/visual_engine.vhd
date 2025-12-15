library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.music_pkg.ALL; 

entity visual_engine is
    Generic (
        CLK_FREQ    : integer := 25_000_000;
        FALL_SPEED  : integer := 3;
        TARGET_Y    : integer := 400;
        HIT_MARGIN  : integer := 25
    );
    Port ( 
        clk               : in STD_LOGIC;
        reset             : in STD_LOGIC;
        game_start_btn    : in STD_LOGIC;
        vsync             : in STD_LOGIC;
        pixel_x           : in INTEGER;
        pixel_y           : in INTEGER;
        
        -- VECTORES LIMPIOS (0=Verde ... 4=Naranja)
        
        -- Entrada: Miembro 3 dice "Destruye esta nota"
        destroy_note_in   : in STD_LOGIC_VECTOR(4 downto 0);
        
        -- Salida: Avisar al Miembro 3 si hay nota en zona
        note_in_zone_out  : out STD_LOGIC_VECTOR(4 downto 0);
        
        -- Salida: Para el Pixel Generator (Pintar)
        draw_note_vector  : out STD_LOGIC_VECTOR(4 downto 0);
        
        -- Sincronización Audio
        audio_start_trigger : out STD_LOGIC
    );
end visual_engine;

architecture Behavioral of visual_engine is

    -- Configuración de Retardo
    constant FRAMES_TO_FALL : integer := TARGET_Y / FALL_SPEED;
    constant MS_PER_FRAME   : integer := 16; 
    constant AUDIO_DELAY_MS : integer := FRAMES_TO_FALL * MS_PER_FRAME;

    -- =========================================================================
    -- MATRIZ 2D PARA LAS NOTAS
    -- =========================================================================
    -- Carril: Array de 4 posibles notas cayendo
    type lane_buffer_t is array (0 to 3) of integer range -50 to 650;
    -- Pista Completa: Array de 5 carriles (0 a 4)
    type track_system_t is array (0 to 4) of lane_buffer_t;
    
    -- tracks_y(0) son las notas VERDES, tracks_y(1) ROJAS, etc.
    signal tracks_y : track_system_t := (others => (others => 600));

    -- Variables de canción
    constant CYCLES_PER_MS : integer := CLK_FREQ / 1000;
    signal clk_cnt         : integer range 0 to CYCLES_PER_MS := 0;
    signal ms_tick         : std_logic := '0';
    
    signal song_idx        : integer range SEVEN_NATION_SONG'RANGE := 0;
    signal note_timer      : integer range 0 to 5000 := 0;
    signal internal_playing : std_logic := '0';
    signal audio_go         : std_logic := '0';
    signal startup_timer    : integer range 0 to AUDIO_DELAY_MS + 100 := 0;

    -- Vector de disparo (Spawning)
    signal spawn_vector : std_logic_vector(4 downto 0) := (others => '0');

begin

    -- PROCESO 1: LECTURA Y SYNC (Idéntico pero asigna al vector spawn)
    process(clk, reset)
        variable current_dur  : integer;
        variable current_code : integer;
    begin
        if reset = '1' then
            clk_cnt <= 0; ms_tick <= '0';
            song_idx <= 0; note_timer <= 0;
            internal_playing <= '0'; audio_go <= '0'; startup_timer <= 0;
            spawn_vector <= (others => '0');
        elsif rising_edge(clk) then
            ms_tick <= '0';
            spawn_vector <= (others => '0'); -- Reset pulso

            if clk_cnt = CYCLES_PER_MS - 1 then
                clk_cnt <= 0; ms_tick <= '1';
            else
                clk_cnt <= clk_cnt + 1;
            end if;

            if game_start_btn = '1' then internal_playing <= '1'; end if;

            if internal_playing = '1' and ms_tick = '1' then
                if audio_go = '0' then
                    if startup_timer >= AUDIO_DELAY_MS then audio_go <= '1';
                    else startup_timer <= startup_timer + 1; end if;
                end if;

                current_dur := SEVEN_NATION_SONG(song_idx).dur;
                if note_timer >= current_dur then
                    note_timer <= 0;
                    if song_idx < SEVEN_NATION_SONG'HIGH then
                        song_idx <= song_idx + 1;
                        current_code := SEVEN_NATION_SONG(song_idx + 1).code;
                        
                        -- Asignamos directamente al bit correspondiente si es válido (0-4)
                        if current_code >= 0 and current_code <= 4 then
                            spawn_vector(current_code) <= '1';
                        end if;
                    else
                        internal_playing <= '0';
                    end if;
                else
                    note_timer <= note_timer + 1;
                end if;
            end if;
        end if;
    end process;
    audio_start_trigger <= audio_go;

    -- PROCESO 2: FÍSICA Y LOGICA CON BUCLES (Mucho más limpio)
    process(clk, reset)
    begin
        if reset = '1' then
            tracks_y <= (others => (others => 600));
        elsif rising_edge(clk) then
            if vsync = '0' then
                
                -- Bucle mágico: Repite la lógica para los 5 colores (k = 0 to 4)
                for k in 0 to 4 loop
                    
                    -- A) SPAWN
                    if spawn_vector(k) = '1' then
                        for i in 0 to 3 loop
                            if tracks_y(k)(i) >= 600 then 
                                tracks_y(k)(i) <= 0; 
                                exit; 
                            end if;
                        end loop;
                    end if;

                    -- B) GRAVEDAD
                    for i in 0 to 3 loop
                        if tracks_y(k)(i) < 600 then
                            tracks_y(k)(i) <= tracks_y(k)(i) + FALL_SPEED;
                        end if;
                    end loop;

                    -- C) DESTRUCCIÓN (Input del vector)
                    if destroy_note_in(k) = '1' then
                        for i in 0 to 3 loop
                            if (tracks_y(k)(i) >= TARGET_Y - HIT_MARGIN) and 
                               (tracks_y(k)(i) <= TARGET_Y + HIT_MARGIN) then
                                tracks_y(k)(i) <= 600; -- Destruir
                            end if;
                        end loop;
                    end if;
                    
                end loop; -- Fin del bucle de colores
            end if;
        end if;
    end process;

    -- PROCESO 3: SALIDAS COMBINACIONALES (Drawing & Zone Check)
    process(pixel_y, tracks_y)
        variable hit_detected : std_logic;
        variable draw_detected : std_logic;
    begin
        -- Bucle para calcular las salidas de los 5 canales
        for k in 0 to 4 loop
            
            -- 1. Zona de Acierto (Para Miembro 3)
            hit_detected := '0';
            for i in 0 to 3 loop
                if (tracks_y(k)(i) >= TARGET_Y - HIT_MARGIN) and 
                   (tracks_y(k)(i) <= TARGET_Y + HIT_MARGIN) then
                    hit_detected := '1';
                end if;
            end loop;
            note_in_zone_out(k) <= hit_detected;

            -- 2. Dibujado (Para Pixel Generator)
            draw_detected := '0';
            for i in 0 to 3 loop
                if (pixel_y >= tracks_y(k)(i)) and (pixel_y < tracks_y(k)(i) + 20) then
                    draw_detected := '1';
                end if;
            end loop;
            draw_note_vector(k) <= draw_detected;
            
        end loop;
    end process;

end Behavioral;