library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_teclado is
    Port ( 
        CLK          : in  STD_LOGIC;
        RESET        : in  STD_LOGIC; -- Reset Activo Alto (rst_sys)
        
        -- Puertos físicos PS/2
        PS2_CLK      : in  STD_LOGIC;
        PS2_DATA     : in  STD_LOGIC;
        
        -- Salidas de Control para el Juego (FSM)
        user_keys    : out STD_LOGIC_VECTOR(4 downto 0); -- G,F,D,S,A
        cmd_esc      : out STD_LOGIC;
        cmd_1        : out STD_LOGIC;
        cmd_2        : out STD_LOGIC;
        
        -- Salidas de Debug para LEDs físicos
        leds_teclas  : out STD_LOGIC_VECTOR(4 downto 0); -- Ver qué tecla pulso
        led_esc      : out STD_LOGIC                     -- Ver si pulso ESC
    );
end top_teclado;

architecture Behavioral of top_teclado is

    -- Señales internas de comunicación entre driver y decoder
    signal sig_new_code : std_logic;
    signal sig_keycode  : std_logic_vector(7 downto 0);
    
    -- Señal interna para duplicar la salida a user_keys y leds
    signal internal_keys : std_logic_vector(4 downto 0);
    signal internal_esc  : std_logic;

begin

    -------------------------------------------------------------------------
    -- DRIVER PS/2 DE BAJO NIVEL
    -------------------------------------------------------------------------
    KEYBOARD_DRIVER: entity work.ps2_keyboard
    generic map (clk_freq => 100_000_000)
    port map (
        CLK          => CLK, 
        ps2_clk      => PS2_CLK, 
        ps2_data     => PS2_DATA,
        ps2_code_new => sig_new_code, 
        ps2_code     => sig_keycode
    );

    -------------------------------------------------------------------------
    -- DECODIFICADOR DE TECLAS DE GUITARRA
    -------------------------------------------------------------------------
    DECODER: entity work.guitar_decoder
    port map (
        clk          => CLK, 
        reset        => RESET,
        ps2_code_new => sig_new_code, 
        ps2_code     => sig_keycode, 
        
        color_pulse  => internal_keys, 
        esc_pulse    => internal_esc, 
        btn1_pulse   => cmd_1, 
        btn2_pulse   => cmd_2
    );

    -------------------------------------------------------------------------
    -- ASIGNACIÓN DE SALIDAS
    -------------------------------------------------------------------------
    -- Salidas al sistema
    user_keys <= internal_keys;
    cmd_esc   <= internal_esc;
    
    -- Salidas a los LEDs de debug
    leds_teclas <= internal_keys;
    led_esc     <= internal_esc;

end Behavioral;
