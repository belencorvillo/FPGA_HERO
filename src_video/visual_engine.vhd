library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Importamos paquete de música de Belén (music_pkg.vhd debe estar en el proyecto)
use work.music_pkg.ALL; 

entity visual_engine is
    Generic (
        FALL_SPEED  : integer := 4;    -- Velocidad rápida para pantalla 1024p
        TARGET_Y    : integer := 900;  -- Posición de la línea de meta
        HIT_MARGIN  : integer := 20    -- Margen estricto (+/- 20px = Ventana de ~80ms)
    );
    Port ( 
        clk                 : in STD_LOGIC;
        reset               : in STD_LOGIC;
        
        -- SEÑALES DE CONTROL
        enable              : in STD_LOGIC; -- '1' = Juego corriendo
        tick_1ms            : in STD_LOGIC; -- Pulso de sincronización musical
        
        -- SEÑALES DE VÍDEO (Para renderizado)
        vsync               : in STD_LOGIC; -- Sincronización física (60Hz)
        pixel_x             : in INTEGER; -- Pixeles del VGA
        pixel_y             : in INTEGER;
        
        -- INTERACCIÓN CON USUARIO
        destroy_note    : in STD_LOGIC_VECTOR(4 downto 0); -- Botones del usuario
        
        -- SALIDAS
        life_lost_pulse     : out STD_LOGIC;                  -- Pulso si se escapa una nota (Para MDE - Máquina de Estados)
        note_in_zone        : out STD_LOGIC_VECTOR(4 downto 0); -- Para ver si esta en hit zone la cabeza de la nota (Para MDE)
        draw_note_vector    : out STD_LOGIC_VECTOR(4 downto 0); -- Para Pixel Generator
        audio_start_trigger : out STD_LOGIC                   -- Para sincronizar audio
    );
end visual_engine;

architecture Behavioral of visual_engine is

    -- =========================================================================
    -- 1. CÁLCULOS DE SINCRONIZACIÓN
    -- =========================================================================
    -- Calculamos cuánto tarda una nota en caer desde Y=0 hasta TARGET_Y
    constant FRAMES_TO_FALL : integer := TARGET_Y / FALL_SPEED;
    constant MS_PER_FRAME   : integer := 16; -- 1000ms / 60Hz aprox
    constant AUDIO_DELAY_MS : integer := FRAMES_TO_FALL * MS_PER_FRAME;

    -- =========================================================================
    -- 2. ESTRUCTURA DE DATOS PARA LAS NOTAS 
    -- =========================================================================
    -- tracks_y: Guarda la posición de la CABEZA de la nota (la parte de abajo visualmente).
    -- tracks_len: Guarda la longitud vertical de la nota.
    -- Estado 1200 = Nota inactiva / Fuera de pantalla.
    type lane_y_t is array (0 to 3) of integer range -1000 to 1200;  -- Definimos un array para un solo carril (Max 4 notas simultáneas)  
    type track_y_sys_t is array (0 to 4) of lane_y_t; -- Definimos la pista completa: 5 carriles (0 a 4)
    signal tracks_y : track_y_sys_t := (others => (others => 1200)); -- Inicializamos todas las notas en 1200 (Fuera de pantalla)
    type lane_len_t is array (0 to 3) of integer range 0 to 1000;
    type track_len_sys_t is array (0 to 4) of lane_len_t;
    signal tracks_len : track_len_sys_t := (others => (others => 40)); -- Tamaño predeterminado de 40 pixeles
      
    -- =========================================================================
    -- 3. LECTURA DE LA CANCIÓN
    -- =========================================================================
    signal song_idx      : integer range SEVEN_NATION_SONG'RANGE := 0; -- Recorre array de la partitura
    signal note_timer    : integer range 0 to 5000 := 0; -- Duración nota
    signal audio_go      : std_logic := '0'; -- Señal para dar comienzo al módulo de audio
    signal startup_timer : integer range 0 to AUDIO_DELAY_MS + 200 := 0;
    
    -- =========================================================================
    -- 4. COMUNICACIÓN INTERNA
    -- =========================================================================
    -- Vector interno de disparo (Spawn)
    signal spawn_vector     : std_logic_vector(4 downto 0) := (others => '0');
    signal next_note_len    : integer range 0 to 1000 := 40;
    signal vsync_prev : std_logic := '0';
    
begin

    -- =========================================================================
    -- PROCESO 1: EL DIRECTOR (Spawner)
    -- Lee el music_pkg y decide cuándo y de qué tamaño nacen las notas.
    -- =========================================================================    
    process(clk, reset)
        variable current_dur  : integer;
        variable calc_len  : integer;
        variable current_code : integer;
    begin
        if reset = '1' then
            song_idx <= 0; note_timer <= 0;
            audio_go <= '0'; startup_timer <= 0;
            spawn_vector <= (others => '0');
            next_note_len <= 40;
            
        elsif rising_edge(clk) then
            spawn_vector <= (others => '0'); 
           
            if enable = '1' and tick_1ms = '1' then   -- Si estamos en ESTADO JUEGO y ha pasado 1ms 
                        
            -- 1. Gestión del retardo inicial (para que el audio espere a que la primera nota baje)
                if audio_go = '0' then
                    if startup_timer >= AUDIO_DELAY_MS then audio_go <= '1'; 
                    else startup_timer <= startup_timer + 1; 
                    end if;
                end if;

            -- 2. Cálculo de la Longitud Visual
                current_dur := SEVEN_NATION_SONG(song_idx).dur;
                -- Conversión: Duración / 2 (Aprox 0.48 px/ms para Speed 8)
                calc_len := current_dur / 2;
                -- Clamping (Límites de seguridad visual)
                if calc_len < 20 then calc_len := 20; end if;       -- Mínimo visible
                if calc_len > 1000 then calc_len := 1000; end if;   -- Máximo pantalla
                
                next_note_len <= calc_len;
          
            -- 3. Temporizador de la canción
                if note_timer >= current_dur then
                    note_timer <= 0;
                    if song_idx < SEVEN_NATION_SONG'HIGH then -- comprueba que no haya acabado la canción
                        song_idx <= song_idx + 1;
                        current_code := SEVEN_NATION_SONG(song_idx + 1).code;
                        
                        -- Si es 0-4 (Color) -> Spawn. Si es 5 (Silencio) -> Solo espera.
                        if current_code >= 0 and current_code <= 4 then
                            spawn_vector(current_code) <= '1';
                        end if;
                    end if;
                else
                    note_timer <= note_timer + 1;
                end if;
            end if;
        end if;
    end process;

    -- Salida para dar comienzo al módulo de audio
    audio_start_trigger <= audio_go;

    -- =========================================================================
    -- PROCESO 2: FÍSICA (NACIMIENTO, MOVIMIENTO Y DESTRUCCIÓN)
    -- =========================================================================
    process(clk, reset)
        variable note_head_y : integer; -- Cabeza de la nota
        variable zone_top    : integer; -- Márgenes de la meta
        variable zone_bot    : integer; 
        variable any_miss    : std_logic; -- Ha habido fallo -> para MDE
        variable lane_active : std_logic; -- Variable para saber si el carril K tiene nota en zona
        variable frame_tick  : boolean; -- Variable auxiliar
    begin
        if reset = '1' then
            tracks_y         <= (others => (others => 1200));
            tracks_len       <= (others => (others => 40));
            life_lost_pulse  <= '0';
            note_in_zone <= (others => '0'); -- Reset salida
            vsync_prev      <= '0';
            
        elsif rising_edge(clk) then
        -- DETECTOR DE FLANCO DE VSYNC (Para contar 1 frame exacto)
            frame_tick := false;
            if (vsync = '1' and vsync_prev = '0') then -- Flanco de subida
                frame_tick := true;
            end if;
            vsync_prev <= vsync; -- Guardamos estado anterior
        
            life_lost_pulse <= '0';
            any_miss        := '0';
            zone_top := TARGET_Y - HIT_MARGIN;
            zone_bot := TARGET_Y + HIT_MARGIN;
            
           if enable = '1' then  
            -- 1) SPAWN: Si el proceso 1 pidió nota nueva, buscamos hueco
                 for k in 0 to 4 loop
                    if spawn_vector(k) = '1' then
                        for i in 0 to 3 loop
                            -- Solo creamos si está libre (fuera de pantalla)
                            if tracks_y(k)(i) >= 1200 then 
                                tracks_y(k)(i)   <= 0; -- ¡Nace arriba!
                                tracks_len(k)(i) <= next_note_len; 
                                exit; 
                            end if;
                        end loop;
                    end if;
                end loop;

            -- 2) MOVIMIENTO
                if frame_tick then 
                    for k in 0 to 4 loop
                        lane_active := '0'; -- Reset por carril
                    for i in 0 to 3 loop
                        if tracks_y(k)(i) < 1100 then 
                            note_head_y := tracks_y(k)(i);

                            -- Comprobamos si la nota está en zona de la meta para avisar a MDE
                            if (note_head_y >= zone_top) and (note_head_y <= zone_bot) then
                                lane_active := '1'; 
                            end if;
                            
                            -- Lógica de Fallo
                            if note_head_y > zone_bot then
                                any_miss       := '1';
                                tracks_y(k)(i) <= 1200; -- Cambiar -> Dibujar algo cuando se falla
                            
                            -- Lógica de Acierto 
                            elsif (note_head_y >= zone_top) and (note_head_y <= zone_bot) and (destroy_note(k) = '1') then
                                if tracks_len(k)(i) > FALL_SPEED then
                                    tracks_len(k)(i) <= tracks_len(k)(i) - FALL_SPEED;
                                else
                                    tracks_y(k)(i) <= 1200; 
                                end if;
                            else
                                tracks_y(k)(i) <= tracks_y(k)(i) + FALL_SPEED;
                            end if;
                        end if;
                    end loop; -- Fin loop de notas por carril
                    
                    -- Asignamos el resultado acumulado del carril a la salida
                    note_in_zone(k) <= lane_active;
                end loop; -- Fin loop de carriles                
                if any_miss = '1' then life_lost_pulse <= '1'; 
                end if;
            end if;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- PROCESO 3: RENDERIZADO (Solo dibujado)
    -- =========================================================================
    process(pixel_y, tracks_y)
        variable note_head, note_tail : integer;        
        variable draw_detected : std_logic;
    begin
        -- Bucle para calcular las salidas de los 5 canales
        for k in 0 to 4 loop            
            draw_detected := '0';
            for i in 0 to 3 loop
                note_head := tracks_y(k)(i);
                note_tail := tracks_y(k)(i) - tracks_len(k)(i);

                if (pixel_y <= note_head) and (pixel_y > note_tail) then
                    draw_detected := '1';
                end if;
            end loop;
            draw_note_vector(k) <= draw_detected;
            
        end loop;
    end process;

end Behavioral;