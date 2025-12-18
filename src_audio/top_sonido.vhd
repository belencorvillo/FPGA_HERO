library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- No necesitamos numeric_std aquí porque solo conectamos cables

entity top_sonido is
    Port ( 
        CLK100MHZ : in STD_LOGIC;
        CPU_RESETN : in STD_LOGIC;
        
        -- INTERFAZ FÍSICA
        SW   : in STD_LOGIC_VECTOR(3 downto 0); -- 4 Interruptores
        BTNC : in STD_LOGIC; -- Botón Central (Fallo)
        BTNU : in STD_LOGIC; -- Botón Arriba (Acierto)
        
        -- SALIDAS
        AUD_PWM : out STD_LOGIC;
        AUD_SD  : out STD_LOGIC;
        LED     : out STD_LOGIC_VECTOR(3 downto 0) -- Feedback visual
    );
end top_sonido;

architecture Behavioral of top_sonido is
    
    signal reset_sys : std_logic;
    signal fin_cancion : std_logic;
    
    -- Señales para separar los cables de los switches y que sea legible
    signal s_play_enable : std_logic;
    signal s_estado_fms  : std_logic_vector(2 downto 0);

begin
    -- 1. Gestión del Reset (El botón rojo es lógica negativa)
    reset_sys <= not CPU_RESETN;
    
    -- 2. Asignación de Interruptores a señales lógicas
    s_play_enable <= SW(0);          -- El interruptor de la derecha del todo
    s_estado_fms  <= SW(3 downto 1); -- Los 3 siguientes
    
    -- 3. Feedback visual en los LEDs
    LED(0) <= fin_cancion;         -- LED 0 avisa si acabó la canción
    LED(3 downto 1) <= s_estado_fms; -- LEDs 3-1 muestran qué estado estamos simulando

    -- 4. Instancia de tu Controladora
    U_AUDIO: entity work.controladora_audio
    port map (
        clk_100MHz    => CLK100MHZ,
        reset         => reset_sys,
        
        -- Entradas de Control
        play_enable   => s_play_enable,
        current_state => s_estado_fms,
        
        -- Entradas de Juego (Botones)
        nota_fallada  => BTNC, -- Botón Central = Error
        user_hit      => BTNU, -- Botón Arriba = Tocar nota
        
        -- Salidas
        pwm_audio     => AUD_PWM,
        pwm_sd        => AUD_SD,
        song_finished => fin_cancion,
        current_note_index => open -- No lo necesitamos para esta prueba física
    );

end Behavioral;