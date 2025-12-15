# FPGA-HERO
## 🛠️ Instrucciones de Trabajo con git

Para evitar conflictos con el archivo de proyecto (`.xpr`) y mantener el repositorio limpio, por favor seguid estos pasos.

### ⚠️ IMPORTANTE: Actualización de la URL del Repositorio
Hemos cambiado el nombre del repositorio para eliminar guiones que dan problemas en Vivado. Si ya tenías el repo clonado, debes actualizar la dirección en tu terminal.

Ejecuta esto en la carpeta de tu proyecto:

```bash
# Verifica la URL actual
git remote -v

# Si ves la URL antigua (con guiones), cámbiala por la nueva:
git remote set-url origin [https://github.com/TU_USUARIO/FPGA_HERO.git](https://github.com/TU_USUARIO/FPGA_HERO.git)

# Verifica que se ha cambiado correctamente
git remote -v
```

### 🚫 Política de Ramas
No trabajar ni hacer push directamente a la rama main
El archivo de proyecto (.xpr) y el de restricciones (.xdc) son críticos. Para no romper la configuración de los demás:
1. Crea siempre una rama para tu tarea específica.
2. Trabaja en esa rama y sube tus cambios ahí.
```bash
# 1. Muévete a la rama principal y actualízala
git checkout main
git pull origin main

# 2. Crea tu rama nueva y muévete a ella
git checkout -b nombre-de-tu-rama
```
### Rama Main
Solo estarán las carpetas de cada uno con archivos src. El constrins y el xpr en tu rama. Para mantener el orden:
1. Crea una carpeta dentro del repositorio (por ejemplo, src_video) para guardar tus archivos .vhd. 

2. En Vivado:
      - Usa la opción Add Sources para añadir tus archivos al proyecto apuntando a esa carpeta.
      - Si necesitas simular solo tu parte, añádela y defínela como Top Module temporalmente en la simulación.
      - Puedes añadir y quitar ("Remove from Project") tus fuentes según necesites para probar, pero asegúrate de que el archivo .vhd real sigue guardado en tu carpeta del repo.

### Guardar y subir cambios
```bash
# 1. Comprueba qué archivos has modificado
git status

# 2. Comprueba en qué rama estás
git branch

# 3. Si no estás en la correcta muévete a ella con 
git checkout nombrerama

# 4. Añade tus cambios al área de preparación
git add .

# 5. Guarda el commit con un mensaje descriptivo
git commit -m "Descripción de lo que he hecho"

# 6. Sube tu rama a GitHub
# OPCIÓN A: Si es la PRIMERA VEZ que subes esta rama:
git push -u origin nombre-de-tu-rama

# OPCIÓN B: Si ya la has subido antes:
git push
```

### Archivo xpr
Vivado modifica el archivo .xpr automáticamente cada vez que lo abres (guarda posición de ventanas, última simulación, etc.), aunque no hayas cambiado nada del diseño.
- Si has modificado el diseño (añadido IPs, fuentes, cambiado settings): Haz commit del .xpr.

- Si SOLO has editado código VHDL y el .xpr aparece modificado sin razón descarta los cambios del .xpr antes de hacer commit para evitar conflictos innecesarios:
```bash
git checkout --*.xpr
```

## General
music_pkg.vhd: Contiene la partitura de la canción y el código de colores a usar
(YORGOS, MÍRALO PARA LA PARTE GRÁFICA :) )

controladora_audio.vhd: es el motor del sonido

top_sonido.vhd: ni caso, lo he usado solo para generar el testbench NO INTEGRAR EN EL TOP DEL PROYECTO

EN EL ARCHIVO TOP DEL PROYECTO TENDREMOS QUE TENER ALGO ASÍ PARA USAR controladora_audio:

-- 1. Añadir esto antes del begin (Declaración del componente)
component controladora_audio is
    Port ( 
        clk_100MHz : in STD_LOGIC;
        reset      : in STD_LOGIC;
        user_hit   : in STD_LOGIC; 
        pwm_audio  : out STD_LOGIC;
        pwm_sd     : out STD_LOGIC;
        current_note_index : out integer range 0 to 499
    );
end component;

-- 2. Señal interna para conectar Audio con Video
signal cable_indice_nota : integer range 0 to 499;

begin

-- 3. Instancia (Mapeo)
U_AUDIO: controladora_audio
port map (
    clk_100MHz => CLK100MHZ,
    reset      => reset_interno,
    
    -- CONEXIÓN CLAVE:
    -- Si la lógica dice que el usuario acertó, poner a '1'.
    -- Si falló o no toca nada, poner a '0'.
    user_hit   => senal_acierto_logica, 
    
    -- Salidas físicas
    pwm_audio  => AUD_PWM, -- Al pin A11
    pwm_sd     => AUD_SD,  -- Al pin D12
    
    -- Chivato para el video
    current_note_index => cable_indice_nota
);


@YORGOS

en el modulo de vídeo tienes que añadir use work.music_pkg.ALL; al principio. Así puedes leer directamente:

 - SEVEN_NATION_SONG(cable_indice_nota).code -> Te dice el color (0, 1, 2...).

- SEVEN_NATION_SONG(cable_indice_nota).freq -> Te dice la nota (por si quieres pintar pentagrama).



Sobre los constraints (.xdc): He actualizado el archivo de pines. Aseguraos de descomentar las líneas AUD_PWM y AUD_SD en vuestro proyecto o no sonará.


