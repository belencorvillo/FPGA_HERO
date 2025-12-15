library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_generator is
    Port ( 
        clk              : in  STD_LOGIC;
        video_on         : in  STD_LOGIC;
        pixel_x          : in  INTEGER;
        pixel_y          : in  INTEGER;
        
        -- ENTRADA VECTORIAL (Bit 0=Verde, ..., Bit 4=Naranja)
        draw_note_vector : in  STD_LOGIC_VECTOR(4 downto 0);
        
        red_out          : out STD_LOGIC_VECTOR (3 downto 0);
        green_out        : out STD_LOGIC_VECTOR (3 downto 0);
        blue_out         : out STD_LOGIC_VECTOR (3 downto 0)
    );
end pixel_generator;

architecture Behavioral of pixel_generator is
begin

    process(video_on, pixel_x, pixel_y, draw_note_vector)
    begin
        if video_on = '0' then
            red_out <= "0000"; green_out <= "0000"; blue_out <= "0000";
        else
            red_out <= "0000"; green_out <= "0000"; blue_out <= "0000";

            if (pixel_x >= 195 and pixel_x < 445) then
                
                -- CAPA 1: NOTAS (Usando indices del vector)
                
                -- VERDE (Bit 0)
                if draw_note_vector(0) = '1' and (pixel_x >= 195 and pixel_x < 245) then
                    if pixel_x > 198 and pixel_x < 242 then
                        red_out <= "0000"; green_out <= "1111"; blue_out <= "0000"; 
                    else
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "1111";
                    end if;

                -- ROJO (Bit 1)
                elsif draw_note_vector(1) = '1' and (pixel_x >= 245 and pixel_x < 295) then
                    if pixel_x > 248 and pixel_x < 292 then
                        red_out <= "1111"; green_out <= "0000"; blue_out <= "0000"; 
                    else red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; end if;

                -- AMARILLO (Bit 2)
                elsif draw_note_vector(2) = '1' and (pixel_x >= 295 and pixel_x < 345) then
                    if pixel_x > 298 and pixel_x < 342 then
                        red_out <= "1111"; green_out <= "1111"; blue_out <= "0000"; 
                    else red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; end if;

                -- AZUL (Bit 3)
                elsif draw_note_vector(3) = '1' and (pixel_x >= 345 and pixel_x < 395) then
                    if pixel_x > 348 and pixel_x < 392 then
                        red_out <= "0000"; green_out <= "0000"; blue_out <= "1111"; 
                    else red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; end if;

                -- NARANJA (Bit 4)
                elsif draw_note_vector(4) = '1' and (pixel_x >= 395 and pixel_x < 445) then
                    if pixel_x > 398 and pixel_x < 442 then
                        red_out <= "1111"; green_out <= "1000"; blue_out <= "0000"; 
                    else red_out <= "1111"; green_out <= "1111"; blue_out <= "1111"; end if;

                -- CAPA 2 y 3 (Linea de meta y Mástil)
                else
                    -- ... (Aquí va el mismo código de Fondo/Mástil que ya tenías)
                    -- (Lo omito para no llenar la pantalla, pero copia la parte 'else' del anterior)
                    
                    -- Código rápido de fondo para referencia:
                    if (pixel_y >= 400 and pixel_y < 405) then -- Meta
                         red_out <= "1111"; green_out <= "1111"; blue_out <= "1111";
                    else
                         -- Poner carriles oscuros según pixel_x
                         if (pixel_x >= 195 and pixel_x < 245) then red_out <= "0000"; green_out <= "0010"; blue_out <= "0000";
                         elsif (pixel_x >= 245 and pixel_x < 295) then red_out <= "0010"; green_out <= "0000"; blue_out <= "0000";
                         elsif (pixel_x >= 295 and pixel_x < 345) then red_out <= "0010"; green_out <= "0010"; blue_out <= "0000";
                         elsif (pixel_x >= 345 and pixel_x < 395) then red_out <= "0000"; green_out <= "0000"; blue_out <= "0010";
                         elsif (pixel_x >= 395 and pixel_x < 445) then red_out <= "0011"; green_out <= "0001"; blue_out <= "0000";
                         end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;