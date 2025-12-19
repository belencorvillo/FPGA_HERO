library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity generador_pixeles is
    Port ( 
        clk              : in  STD_LOGIC;
        video_on         : in  STD_LOGIC;
        pixel_x          : in  INTEGER;
        pixel_y          : in  INTEGER;
        game_active      : in  STD_LOGIC;
        draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
        red_out          : out STD_LOGIC_VECTOR (3 downto 0);
        green_out        : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
    );
end generador_pixeles;

architecture Behavioral of generador_pixeles is

    -- Contador para animar el pixel art (botar)
    signal anim_cnt : unsigned(24 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            anim_cnt <= anim_cnt + 1;
        end if;
    end process;

    process(video_on, pixel_x, pixel_y, draw_note_vector, game_active, anim_cnt)
        variable r, g, b : std_logic_vector(3 downto 0);
        
        -- VARIABLES CAPA 0 (PIXEL ART 8x8)
        variable block_x : integer;
        variable block_y : integer;
        variable jump_offset : integer;
        
        -- VARIABLES CAPA 1 (GUITARRA HD)
        variable lane_idx : integer range -1 to 4; 
        variable rel_x : integer;
        variable is_diag_dark : boolean;
        variable body_half_width : integer;
        variable center_x : integer := 640;
        variable inside_guitar : boolean;
        
    begin
        r := "0000"; g := "0000"; b := "0000";
        inside_guitar := false;
        lane_idx := -1;

        if video_on = '1' then
            
            -- =================================================================
            -- CAPA 0: FONDO PIXEL ART (RESOLUCIÓN 160x128 BLOQUES)
            -- =================================================================
            -- Dividimos por 8 (operación muy eficiente en hardware)
            block_x := pixel_x / 8; 
            block_y := pixel_y / 8;
            

            -- 1. EL CIELO (Los primeros 30 bloques de alto = 240px)
            if block_y < 30 then
                -- Patrón de estrellas pixeladas simples
                -- Si X * Y mod 100 < 2 -> Estrella
                if ((block_x * block_y) mod 97) < 2 then
                     r:="1111"; g:="1111"; b:="1111"; -- Estrella
                else
                     -- Degradado del cielo en 3 bandas de 10 bloques
                     if block_y < 10 then    r:="0000"; g:="0000"; b:="0001"; -- Negro azulado
                     elsif block_y < 20 then r:="0000"; g:="0000"; b:="0010"; -- Azul noche
                     else                    r:="0001"; g:="0000"; b:="0011"; -- Azul morado
                     end if;
                end if;
                
           end if;
            -- =================================================================
            -- CAPA 1: LA GUITARRA HD (Vectorial - Sobrescribe al Pixel Art)
            -- =================================================================
            if game_active = '1' then
                
                -- 1. Silueta Guitarra
                body_half_width := 200 + (pixel_y / 4);
                if (pixel_x > (center_x - body_half_width)) and 
                   (pixel_x < (center_x + body_half_width)) and 
                   (pixel_y > 100) then
                    inside_guitar := true;
                end if;

                -- 2. Dibujar Cuerpo (Tapa el fondo)
                if inside_guitar then
                    if (pixel_x < (center_x - body_half_width + 50)) or 
                       (pixel_x > (center_x + body_half_width - 50)) then
                        r := "0111"; g := "0000"; b := "0000"; -- Borde
                    else
                        r := "1100"; g := "0010"; b := "0000"; -- Centro
                    end if;
                end if;

                -- 3. Mástil y Notas
                if    pixel_x >= 470 and pixel_x < 530 then lane_idx := 0; rel_x := pixel_x - 470;
                elsif pixel_x >= 540 and pixel_x < 600 then lane_idx := 1; rel_x := pixel_x - 540;
                elsif pixel_x >= 610 and pixel_x < 670 then lane_idx := 2; rel_x := pixel_x - 610;
                elsif pixel_x >= 680 and pixel_x < 740 then lane_idx := 3; rel_x := pixel_x - 680;
                elsif pixel_x >= 750 and pixel_x < 810 then lane_idx := 4; rel_x := pixel_x - 750;
                else  lane_idx := -1; end if;

                -- Patrón diagonal (Gema)
                if ((pixel_x + pixel_y) / 8) mod 2 = 0 then is_diag_dark := true; else is_diag_dark := false; end if;

                if lane_idx /= -1 then
                    if draw_note_vector(lane_idx) = '1' then
                        -- NOTAS (GEMAS)
                        if rel_x < 3 or rel_x >= 57 then r := "1111"; g := "1111"; b := "1111";
                        else
                            case lane_idx is
                                when 0 => if is_diag_dark then r:="0000"; g:="1000"; b:="0000"; else r:="0000"; g:="1111"; b:="0000"; end if;
                                when 1 => if is_diag_dark then r:="1000"; g:="0000"; b:="0000"; else r:="1111"; g:="0000"; b:="0000"; end if;
                                when 2 => if is_diag_dark then r:="1000"; g:="1000"; b:="0000"; else r:="1111"; g:="1111"; b:="0000"; end if;
                                when 3 => if is_diag_dark then r:="0000"; g:="0000"; b:="1000"; else r:="0000"; g:="0000"; b:="1111"; end if;
                                when 4 => if is_diag_dark then r:="1001"; g:="0100"; b:="0000"; else r:="1111"; g:="1000"; b:="0000"; end if;
                                when others => null;
                            end case;
                        end if;
                    else
                        -- CARRIL VACÍO (Madera + Cuerdas)
                        if rel_x < 2 or rel_x >= 58 then r := "1010"; g := "1010"; b := "1010";
                        else r := "0110"; g := "0011"; b := "0000"; end if;
                    end if;
                end if;

                -- 4. Puente (Meta)
                if (pixel_y >= 895 and pixel_y < 915) then
                    if (pixel_x > (center_x - body_half_width + 10)) and 
                       (pixel_x < (center_x + body_half_width - 10)) then
                        if pixel_y > 898 and pixel_y < 912 then r := "1111"; g := "1111"; b := "1111";
                        else r := "1000"; g := "1000"; b := "1000"; end if;
                    end if;
                end if;

            end if; -- Fin Game Active
        end if; -- Fin Video On

        red_out <= r; green_out <= g; blue_out <= b;
    end process;
end Behavioral;