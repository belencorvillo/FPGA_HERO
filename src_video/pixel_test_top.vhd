library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_test_top is
    Port ( 
        clk     : in STD_LOGIC;
        rst_n   : in STD_LOGIC; -- Botón CPU_RESETN (Activo bajo)
        
        -- INTERRUPTORES (Para activar las notas manualmente)
        sw      : in STD_LOGIC_VECTOR (4 downto 0); 
        
        -- SALIDAS VGA
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        red_out   : out STD_LOGIC_VECTOR (3 downto 0);
        green_out : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end pixel_test_top;

architecture Behavioral of pixel_test_top is

    -- Señales internas
    signal rst_pos: std_logic;
    signal clk_108MHz : std_logic := '0';
    
    -- Señales de interconexión
    signal video_on_sig : std_logic;
    signal pixel_x_sig  : integer;
    signal pixel_y_sig  : integer;
    
    -- Vector de prueba que mandaremos al pixel_generator
    signal test_draw_vector : std_logic_vector(4 downto 0);

    -- COMPONENTES
    -- Componente CLOCKING WIZARD (Generado por Vivado)
    component clk_wiz_0
    port(
        clk_out1 : out std_logic;
        clk_in1  : in  std_logic
    );
    end component;  
     
    component controlador_VGA
        Port ( 
            clk_108MHz : in STD_LOGIC;
            reset     : in STD_LOGIC;
            hsync, vsync, video_on : out STD_LOGIC;
            pixel_x, pixel_y : out INTEGER
        );
    end component;

    component pixel_generator
        Port ( 
            clk              : in STD_LOGIC;
            video_on         : in STD_LOGIC;
            pixel_x, pixel_y : in INTEGER;
            draw_note_vector : in STD_LOGIC_VECTOR(4 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin
    rst_pos<= NOT rst_n; -- Inversión para reset activo alto
    
    -- INSTANCIA DEL RELOJ MÁGICO (IP CORE)
    -- Convierte 100MHz -> 108MHz
    clock_gen_inst : clk_wiz_0
    port map ( 
        clk_out1 => clk_108MHz,
        clk_in1  => clk      -- Entrada de 100MHz
    );

    -- 2. INSTANCIA CONTROLADOR VGA 
    inst_vga: controlador_VGA Port Map (
        clk_108MHz => clk,
        reset     => rst_pos, 
        hsync     => hsync,
        vsync     => vsync,
        video_on  => video_on_sig,
        pixel_x   => pixel_x_sig,
        pixel_y   => pixel_y_sig
    );

    -- 3. GENERADOR DE SEÑALES DE PRUEBA (LA SIMULACIÓN DEL JUEGO)
    -- Aquí hacemos el truco:
    -- Si el usuario activa el SW(0), le decimos al generador que pinte nota verde,
    -- PERO solo si estamos en el medio de la pantalla
    -- Esto crea un cuadrado visual en lugar de una barra infinita.
    
    process(pixel_y_sig, sw)
    begin
        -- Solo generamos notas en una franja horizontal central
        -- para ver si se dibujan ENCIMA del mástil
        if (pixel_y_sig > 400 and pixel_y_sig < 500) then
            test_draw_vector <= sw; -- Pasamos el estado de los switches
        else
            test_draw_vector <= (others => '0');
        end if;
    end process;

    -- 4. INSTANCIA PIXEL GENERATOR (LO QUE PROBAMOS)
    inst_pix_gen: pixel_generator Port Map (
        clk              => clk_108MHz,
        video_on         => video_on_sig,
        pixel_x          => pixel_x_sig,
        pixel_y          => pixel_y_sig,
        draw_note_vector => test_draw_vector, -- Conectamos nuestra señal trucada
        red_out          => red_out,
        green_out        => green_out,
        blue_out         => blue_out
    );

end Behavioral;