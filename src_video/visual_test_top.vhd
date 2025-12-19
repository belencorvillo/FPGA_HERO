library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity visual_test_top is
    Port ( 
        clk           : in STD_LOGIC; -- 100 MHz
        rst_n         : in STD_LOGIC; -- CPU_RESETN (Activo bajo)
        
        -- CONTROLES
        btn_start     : in STD_LOGIC; -- BTNU (Start Game)
        sw            : in STD_LOGIC_VECTOR(4 downto 0); -- Simula el "Acierto" del usuario
        led           : out STD_LOGIC_VECTOR(4 downto 0); -- Visualiza "Note In Zone"
        
        -- SALIDAS VGA
        hsync         : out STD_LOGIC;
        vsync         : out STD_LOGIC;
        red_out       : out STD_LOGIC_VECTOR (3 downto 0);
        green_out     : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out      : out STD_LOGIC_VECTOR (3 downto 0)
    );
end visual_test_top;

architecture Behavioral of visual_test_top is

    -- SEÑALES INTERNAS
    signal clk_108MHz   : std_logic;
    signal rst_pos      : std_logic;
    
    -- Señales VGA
    signal video_on_sig : std_logic;
    signal vsync_sig    : std_logic; -- Necesitamos leerlo internamente
    signal pixel_x_sig  : integer;
    signal pixel_y_sig  : integer;
    
    -- Señales del Visual Engine
    signal draw_vec_sig     : std_logic_vector(4 downto 0);
    signal note_in_zone_sig : std_logic_vector(4 downto 0);
    
    -- Señal simulada de destrucción (Input del switch)
    -- En el juego real, esto lo calcula el Miembro 3 (Boton AND Zone)
    -- Aquí lo simulamos directo con los switches.
    signal destroy_sig      : std_logic_vector(4 downto 0);

    -- COMPONENTES
    
    -- 1. Clock Wizard (Generado por Vivado)
    component clk_wiz_0
    port(
        clk_out1 : out std_logic;
        clk_in1  : in  std_logic
    );
    end component;

    -- 2. VGA Controller (1280x1024)
    component controlador_VGA
        Port ( 
            clk_108MHz : in STD_LOGIC;
            reset      : in STD_LOGIC;
            hsync, vsync, video_on : out STD_LOGIC;
            pixel_x, pixel_y : out INTEGER
        );
    end component;
    
    -- 3. Visual Engine (Tu Módulo)
    component visual_engine
        Generic (
            CLK_FREQ    : integer := 108_000_000; -- ¡Ajustado a 108 MHz!
            FALL_SPEED  : integer := 4;
            TARGET_Y    : integer := 900;
            HIT_MARGIN  : integer := 30
        );
        Port ( 
            clk               : in STD_LOGIC;
            reset             : in STD_LOGIC;
            game_start_btn    : in STD_LOGIC;
            vsync             : in STD_LOGIC;
            pixel_x, pixel_y  : in INTEGER;
            destroy_note_in   : in STD_LOGIC_VECTOR(4 downto 0);
            note_in_zone_out  : out STD_LOGIC_VECTOR(4 downto 0);
            draw_note_vector  : out STD_LOGIC_VECTOR(4 downto 0);
            audio_start_trigger : out STD_LOGIC
        );
    end component;

    -- 4. Pixel Generator (1280x1024)
    component pixel_generator
        Port ( 
            clk, video_on    : in STD_LOGIC;
            pixel_x, pixel_y : in INTEGER;
            draw_note_vector : in STD_LOGIC_VECTOR(4 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin

    -- GESTIÓN DE RESET (Activo Alto)
    rst_pos <= NOT rst_n;
    
    -- Conectamos la señal interna vsync a la salida también
    vsync <= vsync_sig;

    -- 1. RELOJ
    inst_clk: clk_wiz_0 port map ( 
        clk_out1 => clk_108MHz,
        clk_in1  => clk
    );

    -- 2. VGA CONTROLLER
    inst_vga: controlador_VGA Port Map (
        clk_108MHz => clk_108MHz,
        reset      => rst_pos,
        hsync      => hsync,
        vsync      => vsync_sig, -- Guardamos en señal interna para dársela al visual engine
        video_on   => video_on_sig,
        pixel_x    => pixel_x_sig,
        pixel_y    => pixel_y_sig
    );

    -- 3. VISUAL ENGINE
    -- Simulamos la destrucción: Si el Switch está activo, intentamos destruir
    destroy_sig <= sw; 
    
    inst_engine: visual_engine 
    Generic Map (
        CLK_FREQ => 108_000_000, -- Confirmamos la frecuencia
        TARGET_Y => 900          -- Confirmamos la meta
    )
    Port Map (
        clk                 => clk_108MHz,
        reset               => rst_pos,
        game_start_btn      => btn_start,
        vsync               => vsync_sig,
        pixel_x             => pixel_x_sig,
        pixel_y             => pixel_y_sig,
        
        -- Entradas/Salidas de Juego
        destroy_note_in     => destroy_sig,      -- Conectado a Switches
        note_in_zone_out    => note_in_zone_sig, -- Conectado a LEDs
        draw_note_vector    => draw_vec_sig,     -- Conectado a Pixel Gen
        audio_start_trigger => open              -- No usamos audio en este test
    );

    -- 4. PIXEL GENERATOR
    inst_pix: pixel_generator Port Map (
        clk              => clk_108MHz,
        video_on         => video_on_sig,
        pixel_x          => pixel_x_sig,
        pixel_y          => pixel_y_sig,
        draw_note_vector => draw_vec_sig,
        red_out          => red_out,
        green_out        => green_out,
        blue_out         => blue_out
    );

    -- 5. FEEDBACK VISUAL (LEDs)
    -- Los LEDs se encenderán cuando la nota esté "golpeable"
    led <= note_in_zone_sig;

end Behavioral;