----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.12.2025 11:35:07
-- Design Name: 
-- Module Name: TOP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP is
    Port(
        CLK          : in  STD_LOGIC;
        BTNC         : in  STD_LOGIC; -- Reset Global
        BTNU         : in  STD_LOGIC; -- Botón Start (Físico en placa)

        -- ENTRADA TECLADO
        PS2_CLK      : in  STD_LOGIC;
        PS2_DATA     : in  STD_LOGIC;

        -- SALIDA VIDEO 
        VGA_R        : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G        : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B        : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_HS       : out STD_LOGIC;
        VGA_VS       : out STD_LOGIC;

        -- SALIDA AUDIO
        AUD_PWM      : out STD_LOGIC; -- Salida de Audio Mono
        AUD_SD       : out STD_LOGIC; -- Shutdown (dejar a '1')

        -- 5. PERIFÉRICOS DE PLACA 
        -- Display 7-Segmentos para puntuación
        CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;
        DP : out STD_LOGIC;
        AN : out STD_LOGIC_VECTOR(7 downto 0);
        
        -- LEDs RGB (Vidas)
        LED16_G, LED16_R, LED16_B : out STD_LOGIC;
        LED17_G, LED17_R, LED17_B : out STD_LOGIC;
        
        -- LEDs Normales (Debug / Estado)
        LED          : out STD_LOGIC_VECTOR(15 downto 0));
end TOP;

architecture Behavioral of TOP is

component VGA_Controller_Top is
        Port ( 
            clk      : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            
            -- Datos del Juego
            current_state   : in  STD_LOGIC_VECTOR(2 downto 0); -- Menu, Play...
            nota_destruida  : in  STD_LOGIC_VECTOR(4 downto 0); -- vector pulsado
            puntuacion      : in  STD_LOGIC_VECTOR(31 downto 0); 
            
            -- Retorno a la FSM 
            note_en_hitzone    : out STD_LOGIC_VECTOR(4 downto 0);
            note_pasa_hitzone  : out STD_LOGIC;                    

            -- Salidas Físicas
            vga_r, vga_g, vga_b : out STD_LOGIC_VECTOR(3 downto 0);
            vga_hs, vga_vs      : out STD_LOGIC
        );
    end component;

component Audio_Controller_Top is
        Port ( 
            CLK             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            
            -- Control
            current_state   : in  STD_LOGIC_VECTOR(2 downto 0);
            user_hit        : in  STD_LOGIC; -- Sonido de acierto
            play_enable     : in  STD_LOGIC; 
            nota_fallada    : in  STD_LOGIC; -- Sonido de error
            
            -- Retorno a FSM
            song_finished   : out STD_LOGIC;
            
            -- Salidas Físicas
            pwm_audio       : out STD_LOGIC;
            pwm_sd          : out STD_LOGIC;
            current_note_index: out integer range 0 to 499
        );
    end component;
    
    -- Teclado y Decoder
    signal sig_new_code : std_logic;
    signal sig_keycode  : std_logic_vector(7 downto 0);
    signal user_keys    : std_logic_vector(4 downto 0); -- G,F,D,S,A
    signal cmd_esc, cmd_1, cmd_2 : std_logic;

    -- Interacción FSM <-> Video/Audio
    signal game_state   : std_logic_vector(2 downto 0);
    signal score_data   : std_logic_vector(31 downto 0);
    signal lives_data   : integer range 0 to 3;
    
    -- Señales que vienen DE Video/Audio HACIA FSM
    signal vid_hitzone  : std_logic_vector(4 downto 0);
    signal vid_miss     : std_logic;
    signal aud_done     : std_logic;
    
    -- Señales que van DE FSM HACIA Video/Audio
    signal acierto_fsm   : std_logic;
    signal nota_fallada_fms  : std_logic;
    signal nota_destruida_fms  : std_logic_vector(4 downto 0);

    -- Cables Display
    signal seg_vector   : std_logic_vector(6 downto 0);
begin
-- Asignaciones Físicas Estáticas
    AUD_SD <= '1'; -- Habilitar amplificador de audio
    DP     <= '1'; -- Apagar punto decimal
    LED(15 downto 3) <= (others => '0'); -- Limpiar LEDs extra
    
    -- Debug visual simple en LEDs 0-2 (Estado del juego)
    LED(2 downto 0) <= game_state; 

    -------------------------------------------------------------------------
    -- 1. BLOQUE DE ENTRADA (TUS MÓDULOS)
    -------------------------------------------------------------------------
    KEYBOARD: entity work.ps2_keyboard
    generic map (clk_freq => 100_000_000)
    port map (
        CLK => CLK, ps2_clk => PS2_CLK, ps2_data => PS2_DATA,
        ps2_code_new => sig_new_code, ps2_code => sig_keycode);

    DECODER: entity work.guitar_decoder
    port map (
        clk => CLK, reset => BTNC,
        ps2_code_new => sig_new_code, ps2_code => sig_keycode, 
        color_pulsado => user_keys, 
        btn_esc => cmd_esc, btn_1 => cmd_1, btn_2 => cmd_2
    );

    -------------------------------------------------------------------------
    -- 2. CEREBRO DEL SISTEMA (TU FSM)
    -------------------------------------------------------------------------
    BRAIN: entity work.Game_FSM
    port map (
        clk             => CLK,
        reset           => BTNC,
        start_btn       => BTNU,
        
        -- Entradas de Control
        color_pulsado   => user_keys,
        esc             => cmd_esc,
        btn_1           => cmd_1,
        btn_2           => cmd_2,
        
        -- Entradas desde Módulos de Compañeros
        nota_en_hitzone   => vid_hitzone,  -- Viene de VIDEO
        nota_pasa_hitzone => vid_miss,     -- Viene de VIDEO
        song_finished     => aud_done,     -- Viene de AUDIO
        
        -- Salidas de Estado
        current_state   => game_state,
        puntuacion      => score_data,
        vida            => lives_data,
        
        -- Feedback
        nota_destruida  => nota_destruida_fms,
        nota_fallada    => nota_fallada_fms, -- Usaremos esto para sonido miss
        nota_acierto    => acierto_fsm
    );

    -------------------------------------------------------------------------
    -- 3. PERIFÉRICOS DE SALIDA (TUS MÓDULOS)
    -------------------------------------------------------------------------
    -- Pantalla 7 Segmentos
    SCORE_DISP: entity work.score_display_ctrl
    port map (
        clk => CLK, reset => BTNC, score_in => score_data, 
        seg_anodes => AN, seg_cathodes => seg_vector
    );
    -- Desempaquetado 7-seg
    CA <= seg_vector(0); CB <= seg_vector(1); CC <= seg_vector(2);
    CD <= seg_vector(3); CE <= seg_vector(4); CF <= seg_vector(5); CG <= seg_vector(6);

    -- Barra de Vida RGB
    LIVES_CTRL: entity work.life_bar_ctrl
    port map (
        clk => CLK, reset => BTNC, lives => lives_data,
        led16_r => LED16_R, led16_g => LED16_G, led16_b => LED16_B,
        led17_r => LED17_R, led17_g => LED17_G, led17_b => LED17_B
    );

    -------------------------------------------------------------------------
    -- 4. INTEGRACIÓN DE COMPAÑEROS (PLACEHOLDERS)
    -------------------------------------------------------------------------
    
    -- MIEMBRO 1: VIDEO
    -- Descomentar cuando te pase el archivo "VGA_Controller_Top.vhd"
    -- VIDEO_SYS: component VGA_Controller_Top
    -- port map (
    --     clk_100mhz      => CLK100MHZ,
    --     reset           => BTNC,
    --     current_state   => game_state,
    --     keys_pressed    => user_keys,    -- Para que pinte qué pulsas
    --     score           => score_data,   -- Para pintar puntuación en pantalla (opcional)
    --     nota_destruida  => nota_destruida_fms,  -- Para la explosión visual
    --     
    --     note_hitzone    => vid_hitzone,  -- CABLE CLAVE: FSM lee esto
    --     note_miss_pulse => vid_miss,     -- CABLE CLAVE: FSM lee esto
    --     
    --     vga_r => VGA_R, vga_g => VGA_G, vga_b => VGA_B,
    --     vga_hs => VGA_HS, vga_vs => VGA_VS
    -- );
    
    -- MIEMBRO 2: AUDIO
    -- Descomentar cuando te pase el archivo "Audio_Controller_Top.vhd"
    -- AUDIO_SYS: component Audio_Controller_Top
    -- port map (
    --     clk_100mhz      => CLK100MHZ,
    --     reset           => BTNC,
    --     current_state   => game_state,
    --     hit_effect      => acierto_fsm,
    --     miss_effect     => nota_fallada_fms, -- Viene de nota_fallada de la FSM
    --     song_finished   => aud_done,    -- CABLE CLAVE: FSM lee esto
    --     audio_out       => AUD_PWM
    -- );

end Behavioral;