library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_sonido is
    Generic (
        G_SIMULATION : boolean := false -- False para síntesis real, True para testbench
        -- La usamos porque sino para ver las notas musicales en un testbench tardaríamos muchísimos ciclos
    );
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        en_bocina: in  STD_LOGIC;                     -- Interruptor de encendido
        nota_sel : in  STD_LOGIC_VECTOR(1 downto 0);  -- Selector de nota (00, 01, 10, 11)
        audio_out: out STD_LOGIC
    );
end top_sonido;

architecture Behavioral of top_sonido is

    -- Frecuencias para 50 MHz (Valores reales)
    -- DO (261 Hz), RE (293 Hz), MI (329 Hz), FA (349 Hz)
    -- Divisor = 50,000,000 / (Frec * 2)
    constant DIV_DO : integer := 95785; 
    constant DIV_RE : integer := 85324;
    constant DIV_MI : integer := 75987;
    constant DIV_FA : integer := 71633;

    signal divisor_actual : integer;
    signal counter        : integer range 0 to 100000 := 0;
    signal audio_reg      : std_logic := '0';

begin

    --  Mux para seleccionar el tope de cuenta según la nota
    process(nota_sel)
    begin
        case nota_sel is
            when "00" => divisor_actual <= DIV_DO;
            when "01" => divisor_actual <= DIV_RE;
            when "10" => divisor_actual <= DIV_MI;
            when "11" => divisor_actual <= DIV_FA;
            when others => divisor_actual <= DIV_DO;
        end case;
    end process;

    --  Generación de Frecuencia
    process(clk, rst)
        -- Variable para ajustar el límite dinámicamente según simulación o real
        variable limite_cuenta : integer;
    begin
        if rst = '1' then
            counter <= 0;
            audio_reg <= '0';
        elsif rising_edge(clk) then
            if en_bocina = '1' then
                
                -- TRUCO PARA TESTBENCH:
                -- Si estamos simulando, contamos solo hasta 100 ticks para ver la onda rápido.
                -- Si es real, usamos el divisor matemático correcto.
                if G_SIMULATION then
                    -- Simulamos diferentes periodos dividiendo el divisor real por 1000 o usando constantes pequeñas
                    limite_cuenta := divisor_actual / 1000; 
                else
                    limite_cuenta := divisor_actual;
                end if;

                if counter >= limite_cuenta then
                    audio_reg <= not audio_reg; -- Conmutar señal
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            else
                -- Si no está habilitado, silencio (salida a 0)
                audio_reg <= '0';
                counter <= 0;
            end if;
        end if;
    end process;

    audio_out <= audio_reg;

end Behavioral;
