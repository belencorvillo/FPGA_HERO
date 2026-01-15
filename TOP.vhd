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

entity TOP is
    Port(
        CLK          : in  STD_LOGIC;
        CPU_RESETN    : in  STD_LOGIC; -- Reset Global
        BTNU         : in  STD_LOGIC; -- Botón Start (Físico en placa)

        -- ENTRADA TECLADO
        PS2_CLK      : in  STD_LOGIC;
        PS2_DATA     : in  STD_LOGIC;

        -- SALIDA VIDEO 
        red_out        : out STD_LOGIC_VECTOR(3 downto 0);
        green_out        : out STD_LOGIC_VECTOR(3 downto 0);
        blue_out        : out STD_LOGIC_VECTOR(3 downto 0);
        hsync       : out STD_LOGIC;
        vsync       : out STD_LOGIC;

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
        LED :out std_logic_vector (2 downto 0);
        LED1 :out std_logic_vector (4 downto 0);
        LED_esc: out std_logic;
        LED_pulso: out std_logic
        );
        

end TOP;

architecture Behavioral of TOP is
    
    signal rst_sys : std_logic;
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
    signal acierto_fms   : std_logic;
    signal nota_fallada_fms  : std_logic;
    signal notas_a_destruir_fsm  : std_logic_vector(4 downto 0);
    
    --De video a audio
    signal empezar :std_logic;

    -- Cables Display
    signal seg_vector   : std_logic_vector(6 downto 0);
begin
    rst_sys <= NOT CPU_RESETN;
    LED1 <= user_keys;      -- Se enciende si pulsas las teclas de color
    LED_esc <= cmd_esc;
    LED_pulso <= vid_miss;
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
        clk => CLK, reset => rst_sys,
        ps2_code_new => sig_new_code, ps2_code => sig_keycode, 
        color_pulse => user_keys, 
       esc_pulse => cmd_esc, btn1_pulse => cmd_1, btn2_pulse => cmd_2
    );

    -------------------------------------------------------------------------
    -- 2. CEREBRO DEL SISTEMA (TU FSM)
    -------------------------------------------------------------------------
    BRAIN: entity work.Game_FSM
    port map (
        clk             => CLK,
        reset           => rst_sys,
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
        notas_a_destruir  => notas_a_destruir_fsm,
        nota_fallada    => nota_fallada_fms, -- Usaremos esto para sonido miss
        nota_acierto    => acierto_fms
    );

    -------------------------------------------------------------------------
    -- 3. PERIFÉRICOS DE SALIDA (TUS MÓDULOS)
    -------------------------------------------------------------------------
    -- Pantalla 7 Segmentos
    SCORE_DISP: entity work.score_display_ctrl
    port map (
        clk => CLK, reset => rst_sys, score_in => score_data, 
        seg_anodes => AN, seg_cathodes => seg_vector
    );
    -- Desempaquetado 7-seg
    CA <= seg_vector(0); CB <= seg_vector(1); CC <= seg_vector(2);
    CD <= seg_vector(3); CE <= seg_vector(4); CF <= seg_vector(5); CG <= seg_vector(6);

    -- Barra de Vida RGB
    LIVES_CTRL: entity work.life_bar_ctrl
    port map (
        clk => CLK, reset => rst_sys, lives => lives_data,
        led16_r => LED16_R, led16_g => LED16_G, led16_b => LED16_B,
        led17_r => LED17_R, led17_g => LED17_G, led17_b => LED17_B
    );

    -------------------------------------------------------------------------
    -- 4. INTEGRACIÓN DE COMPAÑEROS (PLACEHOLDERS)
    -------------------------------------------------------------------------
    
    AUDIO: entity work.controladora_audio
    port map (
        clk_100MHz => CLK,
        reset      => rst_sys,
        user_hit   => acierto_fms, -- '1' si el usuario está acertando (suena), '0' silencio
        pwm_audio  => AUD_PWM,
        pwm_sd     => AUD_SD, -- apagamos sonido (shutdown)
        play_enable => empezar,  -- '1' = Reproducir, '0' = Reset/Parar
        song_finished => aud_done, -- '1' = Canción terminada
        current_state =>  game_state, -- Viene de la FSM
        nota_fallada  => nota_fallada_fms  -- Pulso cuando el usuario falla
    );

    VIDEO: entity work.visual_top
    port map (
         clk      => CLK,
         reset           => CPU_RESETN,
         
         sw_mode   => game_state,
         destruccion  => notas_a_destruir_fsm,  -- Para la explosión visual
         botones => user_keys,
         hitzone    => vid_hitzone,  -- CABLE CLAVE: FSM lee esto
         fallo => vid_miss,     -- CABLE CLAVE: FSM lee esto
         comienzo_audio => empezar,
         vida            => lives_data,
         
         red_out => red_out, green_out => green_out, blue_out => blue_out,
         hsync => hsync, vsync => vsync
    );
    
    LED <= game_state;
end Behavioral;