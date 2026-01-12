library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity visual_top is
    Port ( 
        clk           : in  STD_LOGIC; -- Reloj físico 100 MHz
        reset         : in  STD_LOGIC; -- BOTÓN ROJO (CPU_RESETN) -> Activo a '0'
       
        sw_mode       : in  STD_LOGIC_VECTOR(2 downto 0); 
        destruccion     : in  STD_LOGIC_VECTOR(4 downto 0);       
        hitzone      : out STD_LOGIC_VECTOR(4 downto 0); 
        fallo      : out STD_LOGIC; 
        vida          : in INTEGER range 0 to 3;
        comienzo_audio : out STD_LOGIC;
        
        -- SALIDA VGA
        red_out       : out STD_LOGIC_VECTOR (3 downto 0);
        green_out     : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out      : out STD_LOGIC_VECTOR (3 downto 0);
        hsync         : out STD_LOGIC;
        vsync         : out STD_LOGIC
    );
end visual_top;

architecture Behavioral of visual_top is

    -- =========================================================================
    -- COMPONENTES
    -- =========================================================================

    -- 1. RELOJ (100 -> 108 MHz)
    component clk_wiz_0
        port ( clk_out1 : out std_logic; clk_in1 : in std_logic );
    end component;

    -- 2. GENERADOR DE PULSOS (1 ms)
    component generador_pulsos_1ms is
        Generic ( CLK_FREQ : integer := 108_000_000 );
        Port ( 
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            tick_1ms : out STD_LOGIC
        );
    end component;

    -- 3. CONTROLADOR VGA
    component controlador_VGA is
        Port ( 
            clk_108MHz : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            hsync      : out STD_LOGIC;
            vsync      : out STD_LOGIC;
            video_on   : out STD_LOGIC;
            p_tick     : out STD_LOGIC;
            pixel_x    : out INTEGER;
            pixel_y    : out INTEGER
        );
    end component;

    -- 4. MOTOR DE JUEGO 
    component visual_engine is
        Generic ( FALL_SPEED : integer := 8; TARGET_Y : integer := 900; HIT_MARGIN : integer := 20 );
        Port ( 
            clk                 : in STD_LOGIC;
            reset               : in STD_LOGIC;
            enable              : in STD_LOGIC;
            tick_1ms            : in STD_LOGIC;
            vsync               : in STD_LOGIC;
            pixel_x             : in INTEGER;
            pixel_y             : in INTEGER;
            destroy_note        : in STD_LOGIC_VECTOR(4 downto 0);
            life_lost_pulse     : out STD_LOGIC;
            note_in_zone        : out STD_LOGIC_VECTOR(4 downto 0);
            draw_note_vector    : out STD_LOGIC_VECTOR(4 downto 0);
            audio_start_trigger : out STD_LOGIC
        );
    end component;

    -- 5. RENDERIZADO JUEGO 
    component generador_pixeles is
        Port ( 
            clk              : in  STD_LOGIC;
            video_on         : in  STD_LOGIC;
            pixel_x          : in  INTEGER;
            pixel_y          : in  INTEGER;
            game_active      : in  STD_LOGIC;
            num_lives        : in  INTEGER range 0 to 3;
            btn_player       : in  STD_LOGIC_VECTOR(4 downto 0);
            draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
            red_out          : out STD_LOGIC_VECTOR (3 downto 0);
            green_out        : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    -- 6. DIBUJOS
    component dibujo_pausa is
        Port ( 
            clk               : in  STD_LOGIC;
            tick_cambio_frame : in  STD_LOGIC;
            pixel_x           : in  INTEGER;
            pixel_y           : in  INTEGER;
            red_out           : out STD_LOGIC_VECTOR (3 downto 0);
            green_out         : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out          : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    component dibujo_victoria is
        Port ( 
            clk               : in  STD_LOGIC;
            pixel_x           : in  INTEGER;
            pixel_y           : in  INTEGER;
            red_out           : out STD_LOGIC_VECTOR (3 downto 0);
            green_out         : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out          : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    component dibujo_derrota is
        Port ( 
            clk               : in  STD_LOGIC;
            pixel_x           : in  INTEGER;
            pixel_y           : in  INTEGER;
            red_out           : out STD_LOGIC_VECTOR (3 downto 0);
            green_out         : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out          : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    component dibujo_menu_simple is 
        Port ( 
        clk      : in  STD_LOGIC; -- Necesitamos reloj para leer la ROM sincronizada
        pixel_x  : in  INTEGER;
        pixel_y  : in  INTEGER;
        red_out  : out STD_LOGIC_VECTOR (3 downto 0);
        green_out: out STD_LOGIC_VECTOR (3 downto 0);
        blue_out : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component;
    -- =========================================================================
    -- SEÑALES
    -- =========================================================================
    signal clk_108MHz    : std_logic;
    signal rst_sys       : std_logic; -- SEÑAL DE RESET INTERNA (ACTIVA A '1')
    -- Video Signals
    signal video_on      : std_logic;
    signal vsync_int     : std_logic; -- Señal interna de vsync para el motor
    signal pixel_x       : integer;
    signal pixel_y       : integer;
    signal juego         : std_logic;

    -- Timing
    signal tick_1ms      : std_logic;
    signal tick_anim     : std_logic;
    signal count_anim    : integer range 0 to 200 := 0;

    -- Game Logic Interconnects
    signal engine_draw_vec : std_logic_vector(4 downto 0); -- Del Motor al Pintor
    
    -- Colors
    signal game_r, game_g, game_b : std_logic_vector(3 downto 0);
    signal menu_r, menu_g, menu_b : std_logic_vector(3 downto 0);
    signal pausa_r, pausa_g, pausa_b : std_logic_vector(3 downto 0);
    signal win_r, win_g, win_b : std_logic_vector(3 downto 0);
    signal lose_r, lose_g, lose_b : std_logic_vector(3 downto 0);
    


begin
    -- 0. GESTIÓN DEL RESET (INVERSOR)
    -- El botón da '0' al pulsar -> Nosotros queremos '1' para resetear
    rst_sys <= NOT reset;
-- Esto va en la arquitectura, fuera de cualquier process
    juego <= '1' when sw_mode = "001" else '0';    -- 1. RELOJ PRINCIPAL
    clk_wiz_inst : clk_wiz_0 port map ( clk_in1 => clk, clk_out1 => clk_108MHz );

    -- 2. GENERADOR DE PULSOS
    pulsos_inst : generador_pulsos_1ms
    generic map ( CLK_FREQ => 108_000_000 )
    port map ( clk => clk_108MHz, reset => rst_sys, tick_1ms => tick_1ms );

    -- 3. CONTADOR PARA ANIMACIÓN DEL MENÚ (150ms aprox)
    process(clk_108MHz)
    begin
        if rising_edge(clk_108MHz) then
           if rst_sys = '1' then -- Si pulsamos reset, reiniciamos la animación también
                count_anim <= 0;
                tick_anim <= '0';
            else
                tick_anim <= '0';
                if tick_1ms = '1' then
                    if count_anim = 150 then
                        count_anim <= 0;
                        tick_anim <= '1';
                    else
                        count_anim <= count_anim + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- 4. VGA CONTROLLER
    vga_inst : controlador_VGA
    port map (
        clk_108MHz => clk_108MHz,
        reset      => rst_sys,
        hsync      => hsync,
        vsync      => vsync_int, -- Guardamos copia interna
        video_on   => video_on,
        p_tick     => open,
        pixel_x    => pixel_x,
        pixel_y    => pixel_y
    );
    vsync <= vsync_int; -- Sacamos la copia al puerto

    -- 5. VISUAL ENGINE (EL CEREBRO)
    engine_inst : visual_engine
    generic map ( 
        FALL_SPEED => 8,    -- Ajusta si caen muy rápido o lento
        TARGET_Y   => 900,  -- Altura de la barra de metal
        HIT_MARGIN => 20    -- Margen de error en píxeles
    )
    port map (
        clk                 => clk_108MHz,
        reset               => rst_sys,
        enable              => juego, 
        tick_1ms            => tick_1ms,
        vsync               => vsync_int,
        pixel_x             => pixel_x,
        pixel_y             => pixel_y,
        destroy_note        => destruccion, -- Botones físicos
        life_lost_pulse     => fallo,  -- LED de fallo (LED 15)
        note_in_zone        => hitzone,  -- LEDs de zona (LED 0-4)
        draw_note_vector    => engine_draw_vec, -- Esto le dice al pintor qué dibujar
        audio_start_trigger => comienzo_audio
    );

    -- 6. GENERADOR PIXELES (PINTOR DEL JUEGO)
    game_painter : generador_pixeles
    port map (
        clk              => clk_108MHz,
        video_on         => video_on,
        pixel_x          => pixel_x,
        pixel_y          => pixel_y,
        btn_player       => destruccion,
        num_lives        => vida,
        game_active      => '1', -- Siempre "activo" internamente, el MUX final decide si se ve
        draw_note_vector => engine_draw_vec, -- Recibe datos del ENGINE
        red_out          => game_r,
        green_out        => game_g,
        blue_out         => game_b
    );

    -- 7. DIBUJOS
    pausa_painter : dibujo_pausa
    port map (
        clk               => clk_108MHz,
        tick_cambio_frame => tick_anim,
        pixel_x           => pixel_x,
        pixel_y           => pixel_y,
        red_out           => pausa_r,
        green_out         => pausa_g,
        blue_out          => pausa_b
    );
    
    win_painter : dibujo_victoria
    port map (
        clk               => clk_108MHz,
        pixel_x           => pixel_x,
        pixel_y           => pixel_y,
        red_out           => win_r,
        green_out         => win_g,
        blue_out          => win_b
    );

    lose_painter : dibujo_derrota
    port map (
        clk               => clk_108MHz,
        pixel_x           => pixel_x,
        pixel_y           => pixel_y,
        red_out           => lose_r,
        green_out         => lose_g,
        blue_out          => lose_b
    );

    menu_painter: dibujo_menu_simple 
        Port map ( 
        clk      => clk_108MHz,
        pixel_x           => pixel_x,
        pixel_y           => pixel_y,
        red_out           => menu_r,
        green_out         => menu_g,
        blue_out          => menu_b
    );
    -- MULTIPLEXOR DE SALIDA
    process(clk_108MHz)
    begin
        if rising_edge(clk_108MHz) then
            if video_on = '0' then
                red_out <= "0000"; green_out <= "0000"; blue_out <= "0000";
            else
            case sw_mode is when "000" => red_out <= menu_r; green_out <= menu_g; blue_out <= menu_b;
                            when "001" => red_out <= game_r; green_out <= game_g; blue_out <= game_b;
                            when "010" => red_out <= win_r; green_out <= win_g; blue_out <= win_b;
                            when "011" => red_out <= lose_r; green_out <= lose_g; blue_out <= lose_b;
                            when "100" => red_out <= pausa_r; green_out <= pausa_g; blue_out <= pausa_b;
                            when others => red_out <= "0000"; green_out <= "0000"; blue_out <= "0000";
             end case;                          
            end if;
        end if;
    end process;

end Behavioral;
