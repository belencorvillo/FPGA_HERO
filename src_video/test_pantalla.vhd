library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_pantalla is
    Port ( 
        clk           : in  STD_LOGIC; -- Reloj físico (100 MHz)
        
        -- CONTROLES
        sw_mode       : in  STD_LOGIC; -- SW1 (L16): 0 = Menú, 1 = Juego
        sw_notes      : in  STD_LOGIC_VECTOR(4 downto 0); -- SW2 a SW6: Simular notas
        
        -- SALIDA VGA
        red_out       : out STD_LOGIC_VECTOR (3 downto 0);
        green_out     : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out      : out STD_LOGIC_VECTOR (3 downto 0);
        hsync         : out STD_LOGIC;
        vsync         : out STD_LOGIC
    );
end test_pantalla;

architecture Behavioral of test_pantalla is

    -- 1. IP CLOCKING WIZARD (Configurado SIN Reset y SIN Locked)
    component clk_wiz_0
        port (
            clk_out1 : out std_logic; -- 108 MHz
            clk_in1  : in  std_logic  -- 100 MHz
        );
    end component;

    -- 2. CONTROLADOR VGA
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

    -- 3. GENERADOR DE PIXELES (Juego/Guitarra)
    component generador_pixeles is
        Port ( 
            clk              : in  STD_LOGIC;
            video_on         : in  STD_LOGIC;
            pixel_x          : in  INTEGER;
            pixel_y          : in  INTEGER;
            game_active      : in  STD_LOGIC;
            draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
            red_out          : out STD_LOGIC_VECTOR (3 downto 0);
            green_out        : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    -- 4. DIBUJO MENU (Imagen)
    component dibujo_menu is
        Port ( 
            clk       : in  STD_LOGIC;
            tick_cambio_frame : in  STD_LOGIC; -- Entrada del pulso lento
            pixel_x   : in  INTEGER;
            pixel_y   : in  INTEGER;
            red_out   : out STD_LOGIC_VECTOR (3 downto 0);
            green_out : out STD_LOGIC_VECTOR (3 downto 0);
            blue_out  : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;
    -- 5. GENERADOR DE PULSOS (Nuevo)
    component generador_pulsos_1ms is
        Generic ( CLK_FREQ : integer := 108_000_000 );
        Port ( 
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            tick_1ms : out STD_LOGIC
        );
    end component;
    -- SEÑALES INTERNAS
    signal clk_108MHz    : std_logic; -- Reloj de píxel
    signal video_on      : std_logic;
    signal pixel_x       : integer;
    signal pixel_y       : integer;
    -- Señales de tiempo
    signal tick_1ms      : std_logic; -- Pulso rápido (cada 1ms)
    signal tick_anim     : std_logic; -- Pulso lento (cada 200ms) para el GIF
    signal contador_ms   : integer range 0 to 500 := 0; -- Cuenta milisegundos
    -- Cables de color
    signal game_r, game_g, game_b : std_logic_vector(3 downto 0);
    signal menu_r, menu_g, menu_b : std_logic_vector(3 downto 0);

begin

    -- RELOJ (Clock Wizard sin reset/locked)
    clk_wiz_inst : clk_wiz_0
    port map (
        clk_in1  => clk,
        clk_out1 => clk_108MHz
    );
    -- GENERADOR DE 1MS
    -- Le pasamos 108 MHz porque esa es la frecuencia real de clk_108MHz
    pulsos_inst : generador_pulsos_1ms
    generic map ( CLK_FREQ => 108_000_000 ) 
    port map (
        clk      => clk_108MHz,
        reset    => '0',
        tick_1ms => tick_1ms
    );
    -- PROCESO DE RALENTIZADO (DE 1ms A 200ms)
    -- Esto convierte el pulso rápido en el ritmo de la animación
    process(clk_108MHz)
    begin
        if rising_edge(clk_108MHz) then
            tick_anim <= '0'; -- Por defecto apagado
            
            if tick_1ms = '1' then
                if contador_ms = 150 then -- ¿Han pasado 200ms?
                    contador_ms <= 0;
                    tick_anim   <= '1'; -- ¡Disparo de cambio de frame!
                else
                    contador_ms <= contador_ms + 1;
                end if;
            end if;
        end if;
    end process;
    -- VGA CONTROLLER
    vga_inst : controlador_VGA
    port map (
        clk_108MHz => clk_108MHz,
        reset      => '0',        -- Sin reset externo, siempre activo
        hsync      => hsync,
        vsync      => vsync,
        video_on   => video_on,
        p_tick     => open,       -- No lo necesitamos aquí
        pixel_x    => pixel_x,
        pixel_y    => pixel_y
    );

    -- MÓDULO JUEGO (Guitarra)
    game_inst : generador_pixeles
    port map (
        clk              => clk_108MHz,
        video_on         => video_on,
        pixel_x          => pixel_x,
        pixel_y          => pixel_y,
        game_active      => '1',       -- Siempre activo internamente, el MUX decide si se ve
        draw_note_vector => sw_notes,  -- Control manual
        red_out          => game_r,
        green_out        => game_g,
        blue_out         => game_b
    );

    -- MÓDULO MENÚ (Imagen estática)
    menu_inst : dibujo_menu
    port map (
        clk       => clk_108MHz,
        tick_cambio_frame => tick_anim, 
        pixel_x   => pixel_x,
        pixel_y   => pixel_y,
        red_out   => menu_r,
        green_out => menu_g,
        blue_out  => menu_b
    );

    -- MULTIPLEXOR 
    process(clk_108MHz)
    begin
        if rising_edge(clk_108MHz) then
            if video_on = '0' then
                -- Zona de blanking (negro obligatorio)
                red_out   <= "0000";
                green_out <= "0000";
                blue_out  <= "0000";
            else
                -- Zona visible: Elegir entre Juego o Menú según SW1
                if sw_mode = '1' then
                    red_out   <= game_r;
                    green_out <= game_g;
                    blue_out  <= game_b;
                else
                    red_out   <= menu_r;
                    green_out <= menu_g;
                    blue_out  <= menu_b;
                end if;
            end if;
        end if;
    end process;

end Behavioral;