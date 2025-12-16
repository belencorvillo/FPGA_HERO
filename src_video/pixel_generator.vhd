library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_generator is
    Port ( 
        clk              : in  STD_LOGIC;
        video_on         : in  STD_LOGIC;
        pixel_x          : in  INTEGER;
        pixel_y          : in  INTEGER;
        
        -- ENTRADA VECTORIAL (Bit 0=Verde, Bit 1=Rojo, Bit 2=Amarillo, Bit 3=Azul, Bit 4=Naranja)
        draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
        
        red_out          : out STD_LOGIC_VECTOR (3 downto 0);
        green_out        : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
    );
end pixel_generator;

architecture Behavioral of pixel_generator is
begin

    process(video_on, pixel_x, pixel_y, draw_note_vector)
        -- VARIABLES PARA EL CÁLCULO DEL FONDO
        -- Necesitamos convertir los enteros pixel_x/y a binario para hacer el efecto de ruido
      --  variable vec_x : unsigned(9 downto 0);
      --  variable vec_y : unsigned(9 downto 0);
    
    begin
        -- Convertimos las coordenadas a binario 
      --  vec_x := to_unsigned(pixel_x, 10);
       -- vec_y := to_unsigned(pixel_y, 10);
        
    --- IF 1 (lo pongo para controlar que cierro todos los if
        if video_on = '0' then -- fuera del tamaño de pantalla -> todo negro
            red_out <= "0000"; green_out <= "0000"; blue_out <= "0000";
        else -- dentro de la pantalla
            -- =========================================================
            -- FONDO - "ESCENARIO DE CONCIERTO"
            -- =========================================================
            
            -- 1. BASE: Degradado Vertical (Cielo nocturno)
            -- Cuanto más abajo (mayor pixel_y), más claro el morado.
            if pixel_y < 300 then
                red_out <= "0001"; green_out <= "0000"; blue_out <= "0010"; -- Morado muy oscuro (Cielo)
            else
                red_out <= "0010"; green_out <= "0000"; blue_out <= "0100"; -- Morado medio
            end if;

            -- 2. FOCOS DE LUZ (Spotlights)
            -- Usamos matemáticas lineales (y = mx + n) para hacer haces de luz diagonales
            
            -- Foco Izquierdo (Sale de abajo izquierda hacia arriba centro)
            if (pixel_x < 275) then
                -- Ecuación: Si X es pequeño comparado con Y, estamos dentro del haz
                if (pixel_x * 3) < pixel_y then
                    -- Sumamos luz (Color Cián tenue)
                    red_out <= "0000"; green_out <= "0100"; blue_out <= "0110"; 
                end if;
            end if;

            -- Foco Derecho (Sale de abajo derecha hacia arriba centro)
            if (pixel_x >= 525) then
                -- Ecuación espejo del lado izquierdo
                if ((799 - pixel_x) * 3) < pixel_y then
                    -- Sumamos luz (Color Cián tenue)
                    red_out <= "0000"; green_out <= "0100"; blue_out <= "0110";
                end if;
            end if;

            -- 3. EFECTO "MULTITUD" o "SUELO" (Parte inferior)
            -- Usamos una operación lógica XOR con los bits de las coordenadas para crear un patrón de "ruido" o textura sin gastar memoria.
           -- if pixel_y > 500 then
                -- Usamos el bit 2 para crear un patrón de tablero de ajedrez pequeño
           --     if (vec_x(2) xor vec_y(2)) = '1' then
           --         red_out <= "0001"; green_out <= "0000"; blue_out <= "0001"; -- Punteado oscuro
             --   end if;
          --  end if;
            ---------- FIN DEL FONDO ----------
            
    --- IF 2 (NOTAS) (CENTRADO 1280x1024) -> X: 515 a 765
            if (pixel_x >= 515 and pixel_x < 765) then -- DENTRO DEL MÁSTIL
                
                -- VERDE (Bit 0)
                if draw_note_vector(0) = '1' and (pixel_x >= 515 and pixel_x < 565) then
                    if pixel_x > 518 and pixel_x < 562 then -- Interior Cuadrado
                        red_out <= "0000"; green_out <= "1111"; blue_out <= "0000"; 
                    else -- Borde Blanco
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111";
                    end if; -- fin verde

                -- ROJO (Bit 1)
                elsif draw_note_vector(1) = '1' and (pixel_x >= 565 and pixel_x < 615) then
                    if pixel_x > 568 and pixel_x < 612 then -- Interior cuadrado
                        red_out <= "1111"; green_out <= "0000"; blue_out <= "0000"; 
                    else -- Borde Blanco
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111";
                    end if; -- fin rojo

                -- AMARILLO (Bit 2)
                elsif draw_note_vector(2) = '1' and (pixel_x >= 615 and pixel_x < 665) then
                    if pixel_x > 618 and pixel_x < 662 then --Interior Cuadrado
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "0000"; 
                    else -- Borde blanco
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; 
                    end if; -- fin amarillo

                -- AZUL (Bit 3)
                elsif draw_note_vector(3) = '1' and (pixel_x >= 665 and pixel_x < 715) then
                    if pixel_x > 668 and pixel_x < 712 then -- Interior cuadrado
                        red_out <= "0000"; green_out <= "0000"; blue_out <= "1111"; 
                    else  -- Borde Blanco
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; 
                    end if; -- fin azul

                -- NARANJA (Bit 4)
                elsif draw_note_vector(4) = '1' and (pixel_x >= 715 and pixel_x < 765) then
                    if pixel_x > 718 and pixel_x < 762 then -- Interior Cuadrado
                        red_out <= "1111"; green_out <= "1000"; blue_out <= "0000"; 
                    else -- Borde Blanco
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; 
                    end if; -- fin naranja

    --- IF 3 (META)
                elsif (pixel_y >= 900 and pixel_y < 905) then
                     red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; -- Línea Blanca
 
                -- CAPA 3 (FONDO): CARRILES OSCUROS
                -- =========================================================
                -- Si no hay nota ni línea, pintamos el carril
                else
    --- IF 4 (MÁSTIL)
                     -- Carril VERDE (Oscuro)
                     if (pixel_x >= 515 and pixel_x < 565) then
                        if (pixel_x = 515 or pixel_x = 564) then -- Borde gris del carril
                            red_out <= "0111"; green_out <= "0111"; blue_out <= "0111"; 
                        else 
                            red_out <= "0000"; green_out <= "0010"; blue_out <= "0000"; 
                        end if; -- fin verde fondo

                     -- Carril ROJO (Oscuro)
                     elsif (pixel_x >= 565 and pixel_x < 615) then
                        if (pixel_x = 565 or pixel_x = 614) then -- Borde gris del carril
                            red_out <= "0111"; green_out <= "0111"; blue_out <= "0111"; 
                        else 
                            red_out <= "0010"; green_out <= "0000"; blue_out <= "0000"; 
                        end if; -- fin rojo fondo

                     -- Carril AMARILLO (Oscuro)
                     elsif (pixel_x >= 615 and pixel_x < 665) then
                        if (pixel_x = 615 or pixel_x = 664) then -- Borde gris del carril
                            red_out <= "0111"; green_out <= "0111"; blue_out <= "0111"; 
                        else 
                            red_out <= "0010"; green_out <= "0010"; blue_out <= "0000"; 
                        end if; -- fin amarillo fondo

                     -- Carril AZUL (Oscuro)
                     elsif (pixel_x >= 665 and pixel_x < 715) then
                        if (pixel_x = 665 or pixel_x = 714) then -- Borde gris del carril
                            red_out <= "0111"; green_out <= "0111"; blue_out <= "0111"; 
                        else 
                            red_out <= "0000"; green_out <= "0000"; blue_out <= "0010"; 
                        end if; -- fin azul fondo

                     -- Carril NARANJA (Oscuro)
                     elsif (pixel_x >= 715 and pixel_x < 765) then
                        if (pixel_x = 715 or pixel_x = 764) then -- Borde gris del carril
                            red_out <= "0111"; green_out <= "0111"; blue_out <= "0111"; 
                        else 
                            red_out <= "0011"; green_out <= "0001"; blue_out <= "0000"; 
                        end if; -- fin naranja fondo
                        
                    end if; -- fin de IF 4 (FONDO)
                end if; -- fin de IF 3 (META)
            end if; -- fin de IF 2 (MÁSTIL)
        end if; -- fin de IF 1
    end process;
end Behavioral;