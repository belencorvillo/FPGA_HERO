LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ps2_keyboard IS
  GENERIC(
    clk_freq              : INTEGER := 100_000_000; --system clock frequency in Hz
    debounce_counter_size : INTEGER := 9);         --set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
    CLK          : IN  STD_LOGIC;                     --system clock
    ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS/2 keyboard
    ps2_data     : IN  STD_LOGIC;                     --data signal from PS/2 keyboard
    ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
    ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --code received from PS/2
    
    --PRUEBAS
    LED : OUT std_logic_vector (0 downto 0));
END ps2_keyboard;

ARCHITECTURE Behavioral OF ps2_keyboard IS
  SIGNAL sync_ffs     : STD_LOGIC_VECTOR(1 DOWNTO 0);       --synchronizer flip-flops for PS/2 signals
  SIGNAL ps2_clk_int  : STD_LOGIC;                          --debounced clock signal from PS/2 keyboard
  SIGNAL ps2_data_int : STD_LOGIC;
  SIGNAL ps2_clk_prev : STD_LOGIC := '1';                          --debounced clock signal from PS/2 keyboard
  SIGNAL flanco_bajada : STD_LOGIC := '0';                            --debounced data signal from PS/2 keyboard
  SIGNAL ps2_word     : STD_LOGIC_VECTOR(10 DOWNTO 0);      --stores the ps2 data word
  SIGNAL error        : STD_LOGIC;                          --validate parity, start, and stop bits
  SIGNAL count_idle   : INTEGER RANGE 0 TO clk_freq/18_000; --counter to determine PS/2 is idle
  
  --PARA PRUEBAS
  signal break_received : std_logic := '0'; --viene F0
  signal led_state      : std_logic_vector (0 downto 0) := (others => '0'); 
BEGIN
      
  --synchronizer flip-flops
    process(clk)
    begin
        if rising_edge(clk) then
            sync_ffs(0) <= ps2_clk;
            sync_ffs(1) <= ps2_data;
        end if;
    end process;
    
    --debounce PS2 input signals
    debounce_ps2_clk: entity work.debounce
        GENERIC MAP(counter_size => debounce_counter_size)
        PORT MAP(clk => clk, button => sync_ffs(0), result => ps2_clk_int);
    debounce_ps2_data: entity work.debounce
        GENERIC MAP(counter_size => debounce_counter_size)
        PORT MAP(clk => clk, button => sync_ffs(1), result => ps2_data_int);

    process(clk)
    begin
        if rising_edge(clk) then
            -- Detector de flanco de bajada del reloj PS/2
            ps2_clk_prev <= ps2_clk_int;
            
            if (ps2_clk_prev = '1' and ps2_clk_int = '0') then
                flanco_bajada <= '1';
            else
                flanco_bajada <= '0';
            end if;

            -- Shift Register (Se mueve solo cuando hay flanco de bajada)
            if flanco_bajada = '1' then
                ps2_word <= ps2_data_int & ps2_word(10 downto 1);
            end if;
            
            -- Lógica de inactividad (Idle counter)
            if ps2_clk_int = '0' then
                count_idle <= 0;
            elsif count_idle /= clk_freq/18_000 then
                count_idle <= count_idle + 1;
            end if;
            
            -- Salida de resultados
--            if (count_idle = clk_freq/18_000) and (error = '0') then
--                ps2_code_new <= '1';
--                ps2_code     <= ps2_word(8 downto 1);
--            else
--                ps2_code_new <= '0';
--            end if;
            --SALIDA RESULTADOS PRUEBA
            if (count_idle = (clk_freq/18_000)-1) and (error = '0') then
                ps2_code_new <= '1';
                ps2_code     <= ps2_word(8 downto 1);
                
                -- Código F0 recibido (significa que se va a soltar una tecla)
                if ps2_word(8 downto 1) = x"F0" then
                    break_received <= '1';
                
                -- Código 1C recibido (Tecla A)
                elsif ps2_word(8 downto 1) = x"1C" then
                    if break_received = '1' then
                        -- Si antes hubo un F0, es que estamos SOLTANDO la A
                        led_state(0) <= '0';
                        break_received <= '0'; -- Limpiamos la bandera
                    else
                        -- Si NO hubo F0, es que estamos PULSANDO la A
                        led_state(0) <= '1';
                    end if;
                    
                else
                    -- Si llega cualquier otra tecla que no sea A ni F0
                    break_received <= '0'; -- Reset por seguridad
                end if;
                ---------------------------------------------------------
                
            else
                ps2_code_new <= '0';
            end if;
            
        end if;
    end process;

    -- Verificación de Paridad (Start=0, Stop=1, Paridad impar)
    error <= NOT (NOT ps2_word(0) AND ps2_word(10) AND (ps2_word(9) XOR ps2_word(8) XOR
             ps2_word(7) XOR ps2_word(6) XOR ps2_word(5) XOR ps2_word(4) XOR ps2_word(3) XOR 
             ps2_word(2) XOR ps2_word(1)));
    LED <= led_state;

end Behavioral;
