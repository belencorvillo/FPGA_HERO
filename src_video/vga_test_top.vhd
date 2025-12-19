library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_test_top is
    Port ( 
        clk     : in STD_LOGIC; -- Pin E3 (100 MHz)
        rst_n   : in STD_LOGIC; 
        
        -- Salidas VGA físicas
        hsync     : out STD_LOGIC;
        vsync     : out STD_LOGIC;
        red_out   : out STD_LOGIC_VECTOR (3 downto 0);
        green_out : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end vga_test_top;

architecture Behavioral of vga_test_top is

    -- Señales para el reloj
    signal clk_25MHz : std_logic := '0';
    signal clk_cnt   : integer range 0 to 3 := 0; -- Contador de 2 bits

    -- Señales internas del controlador VGA
    signal video_on_sig : std_logic;
    signal pixel_x_sig  : integer;
    signal pixel_y_sig  : integer;

    -- Instancia del componente a probar
    component controlador_VGA
        Port ( 
            clk_25MHz : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            hsync     : out STD_LOGIC;
            vsync     : out STD_LOGIC;
            video_on  : out STD_LOGIC;
            p_tick    : out STD_LOGIC;
            pixel_x   : out INTEGER;
            pixel_y   : out INTEGER
        );
    end component;

begin

    -- 1. DIVISOR DE RELOJ: 100 MHz -> 25 MHz
    -- Necesitamos dividir por 4.
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_cnt = 1 then -- Toggle cada 2 ciclos = periodo de 4 ciclos
                clk_25MHz <= not clk_25MHz;
                clk_cnt <= 0;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    -- 2. INSTANCIA DEL CONTROLADOR
    uut: controlador_VGA Port Map (
        clk_25MHz => clk_25MHz,
        reset     => NOT rst_n,
        hsync     => hsync,
        vsync     => vsync,
        video_on  => video_on_sig,
        p_tick    => open, -- No lo necesitamos para esta prueba
        pixel_x   => pixel_x_sig,
        pixel_y   => pixel_y_sig
    );

    -- 3. GENERADOR DE COLOR DE PRUEBA
    -- Si el video está activo, pintamos ROJO PURO.
    -- Si no, mandamos NEGRO (obligatorio para que el monitor no pierda sincro)
    
    red_out   <= "0000" when video_on_sig = '1' else "0000";
    green_out <= "1111" when video_on_sig = '1' else "0000";-- Todo apagado
    blue_out  <= "0000"; -- Todo apagado

end Behavioral;