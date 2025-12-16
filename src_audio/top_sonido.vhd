library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_sonido is
    Port ( 
        CLK100MHZ : in STD_LOGIC;
        CPU_RESETN : in STD_LOGIC;
        SW : in STD_LOGIC_VECTOR(1 downto 0); -- Ahora usamos 2 interruptores
        AUD_PWM : out STD_LOGIC;
        AUD_SD : out STD_LOGIC;
        LED : out STD_LOGIC_VECTOR(1 downto 0) -- Ahora usamos 2 LEDs
    );
end top_sonido;

architecture Behavioral of top_sonido is
    signal reset_sys : std_logic;
    signal fin_cancion : std_logic; -- Cable para ver si ha acabado
begin
    reset_sys <= not CPU_RESETN; 
    
    -- Visualización
    LED(0) <= SW(0); -- Muestra si estás "tocando"
    LED(1) <= fin_cancion; -- Se enciende cuando acaba la canción

    -- Instancia
    U_AUDIO: entity work.controladora_audio
    port map (
        clk_100MHz => CLK100MHZ,
        reset      => reset_sys,
        
        -- NUEVAS CONEXIONES
        play_enable => SW(1),      -- Interruptor 1 para ARRANCAR la canción
        song_finished => fin_cancion, -- Salida al LED 1
        
        user_hit   => SW(0),       -- Interruptor 0 para ACERTAR notas
        pwm_audio  => AUD_PWM,
        pwm_sd     => AUD_SD,
        current_note_index => open
    );

end Behavioral;