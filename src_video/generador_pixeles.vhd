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
        num_lives        : in  INTEGER range 0 to 3;
        draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
        btn_player       : in  STD_LOGIC_VECTOR(4 downto 0);        
        red_out          : out STD_LOGIC_VECTOR (3 downto 0);
        green_out        : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
    );
end generador_pixeles;

architecture Behavioral of generador_pixeles is
    signal anim_cnt : unsigned(24 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            anim_cnt <= anim_cnt + 1;
        end if;
    end process;

    process(video_on, pixel_x, pixel_y, draw_note_vector, game_active, btn_player)
        variable r, g, b : std_logic_vector(3 downto 0);
        
        -- Variables de geometría
        variable center_x : integer := 640;
        variable body_half_width : integer;
        variable lane_idx : integer range -1 to 4; 
        variable rel_x : integer; 
        
        -- Variables visuales
        variable inside_guitar_body : boolean;
        variable star_seed : integer;
        variable is_fret : boolean;
        variable is_string : boolean;
        variable is_diag_dark : boolean;

        -- Variables Corazones
        variable heart_idx : integer;
        variable hx, hy : integer;
        variable draw_heart : boolean;
        
    begin
        r := "0000"; g := "0000"; b := "0000";
        inside_guitar_body := false;
        lane_idx := -1;

        if video_on = '1' then
            
            -- =================================================================
            -- 1. FONDO: NOCHE ESTRELLADA
            -- =================================================================
            if pixel_y < 500 then     r:="0000"; g:="0000"; b:="0000";
            elsif pixel_y < 800 then  r:="0000"; g:="0000"; b:="0001";
            else                      r:="0000"; g:="0000"; b:="0010"; 
            end if;

            star_seed := (pixel_x * 11 + pixel_y * 57 + pixel_y*pixel_x/64) mod 2000;
            -- ESTRELLAS GRANDES (Brillantes)
            if star_seed < 2 then 
                if ((star_seed + to_integer(anim_cnt(24 downto 20))) mod 17 = 0) then
                    r:="0100"; g:="0100"; b:="0100"; 
                else
                    r:="1111"; g:="1111"; b:="1111"; 
                end if;

            -- ESTRELLAS PEQUEÑAS (Tenues)
            elsif star_seed < 5 then
                if ((star_seed + to_integer(anim_cnt(22 downto 19))) mod 13 = 0) then
                    r:="0001"; g:="0001"; b:="0001"; 
                else
                    r:="0111"; g:="0111"; b:="0111"; 
                end if;
            end if;

            -- =================================================================
            -- 2. CORAZONES ZELDA (HUD) - ARRIBA A LA DERECHA
            -- =================================================================
            -- Zona: X[1100-1220], Y[30-60]
            if (pixel_y >= 30 and pixel_y < 50) and (pixel_x >= 1100 and pixel_x < 1220) then
                
                -- Calculamos cuál de los 3 corazones es (0, 1 o 2)
                heart_idx := (pixel_x - 1100) / 40;
                hx := (pixel_x - 1100) mod 40; -- Coordenada local X
                hy := pixel_y - 30;            -- Coordenada local Y
                hx := hx - 10;                 -- Centrado                
                draw_heart := false;
                
                -- SI TENEMOS ESA VIDA, DIBUJAMOS EL CORAZÓN
                if (hx >= 0 and hx <= 18) and (heart_idx < num_lives) then
                    if (hy < 6 and (hx/6 /= 1) and (hx mod 6 > 0) and (hx mod 6 < 5)) or 
                       (hy >= 6 and hy < 10) or
                       (hy >= 10 and (hx >= (hy-10) and hx <= (18-(hy-10)))) then
                       draw_heart := true;
                    end if;
                end if;

                if draw_heart then
                    r := "1111"; g := "0000"; b := "0000"; 
                    if hy=2 and hx=3 then r:="1111"; g:="1111"; b:="1111"; end if;
                end if;
            end if;

            -- =================================================================
            -- 3. LA GUITARRA HD
            -- =================================================================
            if game_active = '1' then
                
                -- Detectar Carril
                if    pixel_x >= 470 and pixel_x < 530 then lane_idx := 0; rel_x := pixel_x - 470;
                elsif pixel_x >= 540 and pixel_x < 600 then lane_idx := 1; rel_x := pixel_x - 540;
                elsif pixel_x >= 610 and pixel_x < 670 then lane_idx := 2; rel_x := pixel_x - 610;
                elsif pixel_x >= 680 and pixel_x < 740 then lane_idx := 3; rel_x := pixel_x - 680;
                elsif pixel_x >= 750 and pixel_x < 810 then lane_idx := 4; rel_x := pixel_x - 750;
                else  lane_idx := -1; end if;

                -- A) CUERPO GUITARRA
                body_half_width := 180 + (pixel_y / 3); 
                if (pixel_y > 200) then 
                    if (pixel_x > (center_x - body_half_width)) and (pixel_x < (center_x + body_half_width)) then
                        if pixel_y > 600 or (abs(pixel_x - center_x) > 175) then 
                             inside_guitar_body := true;
                        end if;
                    end if;
                end if;

                if inside_guitar_body then
                    if (pixel_x < (center_x - body_half_width + 15)) or (pixel_x > (center_x + body_half_width - 15)) then
                        r := "0101"; g := "0000"; b := "0000"; -- Borde
                    else
                        r := "1100"; g := "0000"; b := "0000"; -- Centro
                    end if;
                end if;

                -- B) MÁSTIL
                if pixel_x >= 460 and pixel_x <= 820 then
                    if not inside_guitar_body then r := "0011"; g := "0010"; b := "0000"; end if;
                    is_fret := (pixel_y mod 120) < 4; 
                    if is_fret and not inside_guitar_body then r := "0110"; g := "0110"; b := "0110"; end if;
                end if;

                -- C) CARRILES, NOTAS Y ANILLOS
                if lane_idx /= -1 then
                    is_string := (rel_x >= 29 and rel_x <= 30);
                    
                    if draw_note_vector(lane_idx) = '1' then
                        -- >>> NOTA (GEMA) <<<
                        is_diag_dark := ((pixel_x + pixel_y)/4) mod 2 = 0;
                        if rel_x < 4 or rel_x > 56 then 
                            r:="1111"; g:="1111"; b:="1111";
                        else
                            case lane_idx is
                                when 0 => if is_diag_dark then r:="0000"; g:="1010"; b:="0000"; else r:="0000"; g:="1111"; b:="0000"; end if;
                                when 1 => if is_diag_dark then r:="1010"; g:="0000"; b:="0000"; else r:="1111"; g:="0000"; b:="0000"; end if;
                                when 2 => if is_diag_dark then r:="1010"; g:="1010"; b:="0000"; else r:="1111"; g:="1111"; b:="0000"; end if;
                                when 3 => if is_diag_dark then r:="0000"; g:="0000"; b:="1010"; else r:="0000"; g:="0000"; b:="1111"; end if;
                                when 4 => if is_diag_dark then r:="1010"; g:="0100"; b:="0000"; else r:="1111"; g:="1000"; b:="0000"; end if;
                                when others => null;
                            end case;
                        end if;
                    else
                        -- >>> CARRIL VACÍO + ANILLOS REACTIVOS <<<
                        if is_string then r := "1000"; g := "1000"; b := "1000"; end if;
                        
                        -- ZONA DE HIT (ANILLOS)
                        if pixel_y > 880 and pixel_y < 920 then
                             if rel_x < 5 or rel_x > 55 or pixel_y < 885 or pixel_y > 915 then
                                if btn_player(lane_idx) = '1' then
                                    -- Si pulsa: Anillo DORADO BRILLANTE
                                    r:="1111"; g:="1111"; b:="1000"; 
                                else
                                    -- Si no pulsa: Color oscuro (apagado)
                                    case lane_idx is
                                        when 0 => r:="0000"; g:="0100"; b:="0000";
                                        when 1 => r:="0100"; g:="0000"; b:="0000";
                                        when 2 => r:="0100"; g:="0100"; b:="0000";
                                        when 3 => r:="0000"; g:="0000"; b:="0100";
                                        when 4 => r:="0100"; g:="0010"; b:="0000";
                                        when others => null;
                                    end case;
                                end if;
                             else
                                -- Centro del anillo
                                if btn_player(lane_idx) = '1' then
                                     r:="0100"; g:="0100"; b:="0100"; -- Centro gris claro al pulsar
                                else
                                     r:="0000"; g:="0000"; b:="0000"; -- Negro
                                end if;
                             end if;
                        end if;
                    end if;
                end if;

                -- D) PUENTE METAL
                if (pixel_y >= 930 and pixel_y < 960) and (pixel_x > 450 and pixel_x < 830) then
                    r := "0100"; g := "0100"; b := "0100"; 
                    if pixel_y > 935 and pixel_y < 945 then r := "1000"; g := "1000"; b := "1000"; end if;
                end if;
                

            end if; 
        end if; 
        red_out <= r; green_out <= g; blue_out <= b;
    end process;
end Behavioral;