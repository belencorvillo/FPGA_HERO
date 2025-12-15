library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controlador_VGA is
    Port ( 
        clk_25MHz : in  STD_LOGIC; -- ¡Importante! Debe ser 25 MHz exactos
        reset     : in  STD_LOGIC;
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        video_on  : out STD_LOGIC; -- '1' = Zona visible, '0' = Zona negra (blanking)
        p_tick    : out STD_LOGIC; -- Pulso de reloj de pixel (opcional, útil para debug)
        pixel_x   : out INTEGER;   -- Coordenada X (0 a 639)
        pixel_y   : out INTEGER    -- Coordenada Y (0 a 479)
    );
end controlador_VGA;

architecture Behavioral of controlador_VGA is

    -- CONSTANTES ESTÁNDAR VGA 640x480 @ 60Hz
    -- Horizontal (Píxeles)
    constant HD : integer := 640;  -- Display Area (Visible)
    constant HF : integer := 16;   -- Front Porch
    constant HB : integer := 48;   -- Back Porch
    constant HR : integer := 96;   -- Retrace (Sync Pulse)
    -- Total Horizontal = 640 + 16 + 48 + 96 = 800

    -- Vertical (Líneas)
    constant VD : integer := 480;  -- Display Area (Visible)
    constant VF : integer := 10;   -- Front Porch
    constant VB : integer := 33;   -- Back Porch
    constant VR : integer := 2;    -- Retrace (Sync Pulse)
    -- Total Vertical = 480 + 10 + 33 + 2 = 525

    -- Contadores
    signal h_count : integer range 0 to (HD + HF + HB + HR - 1) := 0;
    signal v_count : integer range 0 to (VD + VF + VB + VR - 1) := 0;

    -- Señales internas
    signal h_video_on : boolean;
    signal v_video_on : boolean;

begin

    -- PROCESO 1: Contadores Horizontal y Vertical
    process(clk_25MHz, reset)
    begin
        if reset = '1' then
            h_count <= 0;
            v_count <= 0;
        elsif rising_edge(clk_25MHz) then
            -- Contador Horizontal
            if h_count = (HD + HF + HB + HR - 1) then -- Si llega a 799
                h_count <= 0;
                
                -- Contador Vertical (solo incrementa cuando H completa una línea)
                if v_count = (VD + VF + VB + VR - 1) then -- Si llega a 524
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    -- PROCESO 2: Generación de Señales de Sincronismo
    -- El estándar 640x480 usa polaridad NEGATIVA (Activo a '0')
    -- El pulso de sincro ocurre DESPUÉS del Display y el Front Porch
    
    -- HSYNC: Activo bajo entre (640+16) y (640+16+96)
    hsync <= '0' when (h_count >= (HD + HF) and h_count < (HD + HF + HR)) else '1';
    
    -- VSYNC: Activo bajo entre (480+10) y (480+10+2)
    vsync <= '0' when (v_count >= (VD + VF) and v_count < (VD + VF + VR)) else '1';

    -- PROCESO 3: Video On y Coordenadas
    -- Solo dibujamos si estamos dentro de 640 horizontal y 480 vertical
    h_video_on <= (h_count < HD);
    v_video_on <= (v_count < VD);

    video_on <= '1' when (h_video_on and v_video_on) else '0';

    -- Exportar coordenadas (solo válidas cuando video_on = '1')
    pixel_x <= h_count;
    pixel_y <= v_count;
    
    p_tick <= clk_25MHz; -- Pasamos el reloj por si alguien lo necesita

end Behavioral;