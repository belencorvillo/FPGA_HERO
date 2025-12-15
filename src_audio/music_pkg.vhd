
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package music_pkg is
    -- Creamos un tipo de dato "note_t"
    -- Estructura de una nota: Sonido, Duración y Color visual
    type note_t is record
        freq1 : integer; --Nota principal 
        freq2 : integer; -- Nota secundaria (acorde)
        dur  : integer; -- duración en ms
        code : integer; -- 0=Verde, 1=Rojo, etc.
    end record;

    -- Array de la canción (hasta el minuto 2:44)
    
    type song_t is array (0 to 499) of note_t; 

    -- FRECUENCIAS (Octava 3 - Grave)
    constant E3 : integer := 165; 
    constant G3 : integer := 196; 
    constant D3 : integer := 147; 
    constant C3 : integer := 131; 
    constant B2 : integer := 123; 
    constant A3 : integer := 220;
    
    -- FRECUENCIAS (Octava 4 - Aguda/Solo)
    constant E4 : integer := 330;
    constant G4 : integer := 392;
    constant D4 : integer := 294;
    constant C4 : integer := 262;
    constant B3 : integer := 247;
    
    -- Quintas para Power Chords (Freq2)
    constant B3_P : integer := 247; -- Quinta de E3
    constant D4_P : integer := 294; -- Quinta de G3
    constant A3_P : integer := 220; -- Quinta de D3
    constant G3_P : integer := 196; -- Quinta de C3
    constant F3_P : integer := 185; -- Quinta de B2
    
    -- Silencio
    constant SIL : integer := 0; 
    
    -- Códigos de color 
    constant C_GRN : integer := 0; --verde (E)
    constant C_RED : integer := 1; --rojo (D)
    constant C_YEL : integer := 2; --amarillo (G)
    constant C_BLU : integer := 3; --azul (C)
    constant C_ORG : integer := 4; --naranja (B)
    constant C_NUL : integer := 5; --silencio (ninguna nota cae), el usuario no debe pulsar

    -- CANCIÓN: Seven Nation Army
    constant SEVEN_NATION_SONG : song_t := (
     ------------------------------------------------------------
        -- INTRO (Silencios)
        ------------------------------------------------------------
        (SIL, SIL, 1000, C_NUL), (SIL, SIL, 1000, C_NUL),
        (SIL, SIL, 1000, C_NUL), (SIL, SIL, 1000, C_NUL),
        
        ------------------------------------------------------------
        -- 1. RIFF SIMPLE (UNA NOTA) X12
        -- E (larga) - E (corta) - G - E - D - C - B
        ------------------------------------------------------------
        -- x1
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 250, C_GRN), (G3, 0, 250, C_YEL), (E3, 0, 250, C_GRN), (D3, 0, 250, C_RED), (C3, 0, 1000, C_BLU), (B2, 0, 1000, C_ORG), (SIL, SIL, 50, C_NUL),
        -- x2
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1000, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x3
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x4
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x5
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x6
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x7
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x8
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x9
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x10
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x11
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x12
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        ------------------------------------------------------------
        -- 2. BUILD UP (O:53 - 0:57) 
        -- Dos notas sonando a la vez (E3 + E4) machaconas
        ------------------------------------------------------------
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), -- Sube un poco al final
        (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED),
        
        ------------------------------------------------------------
        -- 3. RIFF ARMÓNICO (CHORUS) x2
        -- Estructura: [Riff Normal] + [Riff Variación]
        ------------------------------------------------------------
        -- === REPETICIÓN 1 ===
        -- Parte A: Normal (Con Acordes Power Chords)
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 1100, C_BLU),
        (B2, F3_P, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- Parte B: Variación Melódica (Final C-D-C-B)
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU),
        (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU), (B2, F3_P, 1100, C_ORG),

        -- === REPETICIÓN 2 ===
        -- Parte A: Normal
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 1100, C_BLU),
        (B2, F3_P, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- Parte B: Variación Melódica
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU),
        (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU), (B2, F3_P, 1100, C_ORG),

        ------------------------------------------------------------
        -- 4. BUILD UP
        ------------------------------------------------------------
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL),
        (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED),
        ------------------------------------------------------------
        -- 5. RIFF SIMPLE (MONOFÓNICO) x12
        ------------------------------------------------------------
        -- x1
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x2
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x3
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x4
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x5
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x6
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x7
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x8
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x9
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x10
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x11
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        -- x12
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU), (B2, 0, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        
        ------------------------------------------------------------
        -- 6. BUILD UP
        ------------------------------------------------------------
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL),
        (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED),
        (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED), (A3, A3, 160, C_RED),
        
        ------------------------------------------------------------
        -- 7. RIFF ARMÓNICO (CHORUS 2) x2
        ------------------------------------------------------------
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 1100, C_BLU),
        (B2, F3_P, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU),
        (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU), (B2, F3_P, 1100, C_ORG),

        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 1100, C_BLU),
        (B2, F3_P, 1100, C_ORG), (SIL, SIL, 100, C_NUL),
        (E3, B3_P, 850, C_GRN), (E3, B3_P, 300, C_GRN), (G3, D4_P, 300, C_YEL),
        (E3, B3_P, 300, C_GRN), (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU),
        (D3, A3_P, 300, C_RED), (C3, G3_P, 300, C_BLU), (B2, F3_P, 1100, C_ORG),
        
        ------------------------------------------------------------
        -- 8. RIFF SIMPLE EN AGUDO (SOLO)
        -- Usamos frecuencias de octava 4 y colores diferentes (Azul/Naranja)
        ------------------------------------------------------------
        -- Melodía en agudo (E4)
        (E4, 0, 850, C_BLU), (E4, 0, 300, C_BLU), (G4, 0, 300, C_ORG), 
        (E4, 0, 300, C_BLU), (D4, 0, 300, C_YEL), (C4, 0, 1100, C_RED),
        (B3, 0, 1100, C_GRN), (SIL, SIL, 100, C_NUL),
        -- Repetición
        (E4, 0, 850, C_BLU), (E4, 0, 300, C_BLU), (G4, 0, 300, C_ORG), 
        (E4, 0, 300, C_BLU), (D4, 0, 300, C_YEL), (C4, 0, 1100, C_RED),
        (B3, 0, 1100, C_GRN), (SIL, SIL, 100, C_NUL),

        ------------------------------------------------------------
        -- 9. BUILD UP FINAL
        ------------------------------------------------------------
        (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN), (E3, E4, 160, C_GRN),
        (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL), (G3, G4, 160, C_YEL),

        ------------------------------------------------------------
        -- 10. RIFF FINAL (Outro)
        ------------------------------------------------------------
        (E3, 0, 800, C_GRN), (SIL, SIL, 50, C_NUL), (E3, 0, 300, C_GRN), (G3, 0, 300, C_YEL), 
        (E3, 0, 300, C_GRN), (D3, 0, 300, C_RED), (C3, 0, 1100, C_BLU),
        (B2, 0, 2000, C_ORG), -- Nota final larga
        
        
        -- Relleno hasta el 200 para evitar errores de array
        others => (SIL, SIL, 1100, C_NUL)
    );   
end music_pkg;
