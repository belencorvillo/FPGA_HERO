library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_sonido is
    Port ( 
        CLK100MHZ : in STD_LOGIC;    -- Reloj principal
        CPU_RESETN : in STD_LOGIC;   -- Botón rojo de reset (activo bajo)
        SW : in STD_LOGIC_VECTOR(0 downto 0); -- Interruptor 0 (Simula "Hit")
        AUD_PWM : out STD_LOGIC;     -- Salida Audio
        AUD_SD : out STD_LOGIC;      -- Enable Audio
        LED : out STD_LOGIC_VECTOR(0 downto 0) -- LED 0 para ver si suena
    );
end top_sonido;

architecture Behavioral of top_sonido is
    signal reset_sys : std_logic;
begin
    -- El botón de reset de la Nexys A7 es '0' cuando se pulsa, lo invertimos a '1'
    reset_sys <= not CPU_RESETN; 
    
    -- Visualización: Si el Switch está arriba, encendemos el LED
    LED(0) <= SW(0);

    -- Instancia del Driver de Audio
    U_AUDIO: entity work.controladora_audio
    port map (
        clk_100MHz => CLK100MHZ,
        reset      => reset_sys,
        user_hit   => SW(0), -- ¡Truco! El Switch 0 simula que estás acertando notas
        pwm_audio  => AUD_PWM,
        pwm_sd     => AUD_SD,
        current_note_index => open -- De momento no lo conectamos a nada
        
        --AHORA MISMO DEJAMOS current_note_index en open (para que la variable se pierda sin dar error)
        -- pero la cosa sería implementar en el top total algo así:
        
        --U_AUDIO: entity work.controladora_audio
        --port map (
        --  ...
        --current_note_index => cable_indice -- ¡Conectado al cable!
        --);

        --U_VIDEO: entity work.controladora_video
        --port map (
        --  ...
        --note_to_draw => cable_indice -- El video lee el cable
        --);
        
    );

end Behavioral;