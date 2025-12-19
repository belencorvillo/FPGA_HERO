library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity generador_pulsos_1ms is
    Generic (
        CLK_FREQ : integer := 108_000_000 -- Frecuencia del reloj del sistema
    );
    Port ( 
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        tick_1ms : out STD_LOGIC -- Pulso de 1 ciclo cada milisegundo
    );
end generador_pulsos_1ms;

architecture Behavioral of generador_pulsos_1ms is
    constant CYCLES_PER_MS : integer := CLK_FREQ / 1000;
    signal count : integer range 0 to CYCLES_PER_MS := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            count <= 0;
            tick_1ms <= '0';
        elsif rising_edge(clk) then
            tick_1ms <= '0'; -- Por defecto '0'
            if count = CYCLES_PER_MS - 1 then
                count <= 0;
                tick_1ms <= '1'; -- Disparo de un ciclo
            else
                count <= count + 1;
            end if;
        end if;
    end process;
end Behavioral;