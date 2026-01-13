library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity guitar_decoder is
    Port ( 
        clk           : in  std_logic;
        reset         : in  std_logic; 
        ps2_code_new  : in  std_logic;
        ps2_code      : in  std_logic_vector(7 downto 0);

        color_pulse   : out std_logic_vector(4 downto 0); -- A S D F G (Ahora es ESTADO)
        esc_pulse     : out std_logic;
        btn1_pulse    : out std_logic;
        btn2_pulse    : out std_logic
    );
end guitar_decoder;

architecture Behavioral of guitar_decoder is

    -- Códigos de teclas
    constant KEY_A   : std_logic_vector(7 downto 0) := x"1C";
    constant KEY_S   : std_logic_vector(7 downto 0) := x"1B";
    constant KEY_D   : std_logic_vector(7 downto 0) := x"23";
    constant KEY_F   : std_logic_vector(7 downto 0) := x"2B";
    constant KEY_G   : std_logic_vector(7 downto 0) := x"34";
    constant KEY_ESC : std_logic_vector(7 downto 0) := x"76";
    constant KEY_1   : std_logic_vector(7 downto 0) := x"16";
    constant KEY_2   : std_logic_vector(7 downto 0) := x"1E";
    constant CODE_F0 : std_logic_vector(7 downto 0) := x"F0";

    signal break_seen : std_logic := '0';
    
    -- Registros internos para mantener el estado
    signal reg_color : std_logic_vector(4 downto 0) := (others => '0');
    signal reg_esc   : std_logic := '0';
    signal reg_btn1  : std_logic := '0';
    signal reg_btn2  : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reg_color <= (others => '0');
                reg_esc   <= '0';
                reg_btn1  <= '0';
                reg_btn2  <= '0';
                break_seen <= '0';
            elsif ps2_code_new = '1' then
                if ps2_code = CODE_F0 then
                    break_seen <= '1'; -- ¡OJO! El siguiente código es para soltar
                else
                    -- Si break_seen es '1', apagamos (SOLTAR). Si es '0', encendemos (PULSAR).
                    if break_seen = '1' then
                        case ps2_code is
                            when KEY_A   => reg_color(0) <= '0';
                            when KEY_S   => reg_color(1) <= '0';
                            when KEY_D   => reg_color(2) <= '0';
                            when KEY_F   => reg_color(3) <= '0';
                            when KEY_G   => reg_color(4) <= '0';
                            when KEY_ESC => reg_esc      <= '0';
                            when KEY_1   => reg_btn1     <= '0';
                            when KEY_2   => reg_btn2     <= '0';
                            when others  => null;
                        end case;
                        break_seen <= '0'; -- Ya hemos procesado el soltar
                    else
                        case ps2_code is
                            when KEY_A   => reg_color(0) <= '1';
                            when KEY_S   => reg_color(1) <= '1';
                            when KEY_D   => reg_color(2) <= '1';
                            when KEY_F   => reg_color(3) <= '1';
                            when KEY_G   => reg_color(4) <= '1';
                            when KEY_ESC => reg_esc      <= '1';
                            when KEY_1   => reg_btn1     <= '1';
                            when KEY_2   => reg_btn2     <= '1';
                            when others  => null;
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Asignación a salidas
    color_pulse <= reg_color;
    esc_pulse   <= reg_esc;
    btn1_pulse  <= reg_btn1;
    btn2_pulse  <= reg_btn2;

end Behavioral;