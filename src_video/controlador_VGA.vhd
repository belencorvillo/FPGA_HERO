library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controlador_VGA is
    Port ( 
        clk_108MHz : in  STD_LOGIC; -- Reloj generado por el cimponente clk_wiz_0, 108MHz
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

    -- ESTÁNDAR VESA 1280x1024 @ 60Hz (Pixel Clock = 108 MHz)
    
    -- Horizontal (Píxeles)
    constant HD : integer := 1280;  -- Área Visible
    constant HF : integer := 48;   -- Front Porch
    constant HB : integer := 248;   -- Back Porch
    constant HR : integer := 112;   -- Sync Pulse
    -- Total Horizontal = 180 + 48 + 248 + 112 = 1688

    -- Vertical (Líneas)
    constant VD : integer := 1024;  -- Área Visible
    constant VF : integer := 1;   -- Front Porch
    constant VB : integer := 38;   -- Back Porch
    constant VR : integer := 3;    -- Sync Pulse
    -- Total Vertical = 1024 + 1 + 38 + 3 = 1066

    -- Contadores
    signal h_count : integer range 0 to (HD + HF + HB + HR - 1) := 0;
    signal v_count : integer range 0 to (VD + VF + VB + VR - 1) := 0;

    -- Señales internas
    signal h_video_on : boolean;
    signal v_video_on : boolean;

begin

    -- PROCESO 1: Contadores Horizontal y Vertical
    process(clk_108MHz, reset)
    begin
        if reset = '1' then
            h_count <= 0;
            v_count <= 0;
        elsif rising_edge(clk_108MHz) then
            -- Contador Horizontal
            if h_count = (HD + HF + HB + HR - 1) then -- Si llega a 1039
                h_count <= 0;
                
                -- Contador Vertical (solo incrementa cuando H completa una línea)
                if v_count = (VD + VF + VB + VR - 1) then -- Si llega a 665
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
    hsync <= '1' when (h_count >= (HD + HF) and h_count < (HD + HF + HR)) else '0';
    vsync <= '1' when (v_count >= (VD + VF) and v_count < (VD + VF + VR)) else '0';
    
    -- PROCESO 3: Video On y Coordenadas
    -- Solo dibujamos si estamos dentro 
    h_video_on <= (h_count < HD);
    v_video_on <= (v_count < VD);

    video_on <= '1' when (h_video_on and v_video_on) else '0';

    -- Exportar coordenadas (solo válidas cuando video_on = '1')
    pixel_x <= h_count;
    pixel_y <= v_count;
    
    p_tick <= clk_108MHz; -- Pasamos el reloj por si alguien lo necesita

end Behavioral;