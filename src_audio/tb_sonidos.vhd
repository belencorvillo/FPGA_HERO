library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.music_pkg.ALL; 

entity tb_audio_driver is
-- Vacío, es un testbench
end tb_audio_driver;

architecture Behavioral of tb_audio_driver is
    signal tb_clk      : std_logic := '0';
    signal tb_reset    : std_logic := '0';
    signal tb_user_hit : std_logic := '0';
    signal tb_pwm      : std_logic;
    signal tb_sd       : std_logic;
    signal tb_note_idx : integer range 0 to 29;

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
begin

    UUT: entity work.controladora_audio
    port map (
        clk_100MHz => tb_clk,
        reset      => tb_reset,
        user_hit   => tb_user_hit,
        pwm_audio  => tb_pwm,
        pwm_sd     => tb_sd,
        current_note_index => tb_note_idx
    );

    -- Reloj
    process
    begin
        tb_clk <= '0';
        wait for CLK_PERIOD/2;
        tb_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Pruebas
    process
    begin
        tb_reset <= '1';
        wait for 100 ns;
        tb_reset <= '0';
        wait for 100 ns;

        -- 1. Dejar pasar tiempo en silencio (Intro)
        wait for 1 ms; 

        -- 2. Simular que el usuario acierta (Debería verse oscilación en tb_pwm)
        tb_user_hit <= '1';
        wait for 5 ms;

        -- 3. Simular fallo (Debería verse línea plana)
        tb_user_hit <= '0';
        wait for 2 ms;

        -- 4. Volver a acertar
        tb_user_hit <= '1';
        wait for 5 ms;
        
        assert false report "Fin simulacion" severity failure;
    end process;
end Behavioral;
