# qs-vid-wallpapers y qs-vid-wallpapers-apply

Este documento explica el selector QS orientado a video y su wrapper de aplicación.

- Selector: qs-vid-wallpapers (instalado desde modules/home/scripts/qs-vid-wallpapers.nix)
- Wrapper de aplicación: qs-vid-wallpapers-apply (instalado desde modules/home/scripts/qs-vid-wallpapers-apply.nix)

## Qué hacen

- qs-vid-wallpapers es un selector de miniaturas Qt/QML especializado en fondos animados/video. Escanea tu directorio de fondos, construye miniaturas con ffmpegthumbnailer (con ffmpeg como respaldo) y renderiza una cuadrícula con búsqueda. También muestra un encabezado de estado con un botón para detener sesiones mpvpaper basadas en video.
- qs-vid-wallpapers-apply ejecuta el selector y aplica el video seleccionado al escritorio con mpvpaper.

## Conceptos clave y flujo

1) Recolectar archivos
- Escanea WALL_DIR (por defecto: $HOME/Pictures/Wallpapers) recursivamente, siguiendo symlinks (`find -L`).
- Incluye formatos de video comunes soportados por mpv/mpvpaper: mp4, m4v, mp4v, mov, webm, avi, mkv, mpeg/mpg, wmv, avchd, flv, ogv, m2ts/ts, 3gp. AVIF animado también es soportado para miniaturas y puede usarse con mpvpaper (transcodificado opcionalmente en otro lado).

2) Caché de miniaturas
- Las miniaturas se cachean en VID_WALL_CACHE_DIR (por defecto: $HOME/.cache/vidthumbs).
- Primario: ffmpegthumbnailer (rápido). Respaldo: extracción de fotograma con ffmpeg con escalado y relleno a cuadrado.

3) Manifiesto JSON
- Construye un array JSON inline de { path, name, thumb } y lo inserta en el QML (mismo patrón que el selector de imágenes).

4) Encabezado de estado/controles
- El encabezado muestra el estado de MPVPaper: ACTIVE/INACTIVE — pero solo para instancias mpvpaper basadas en video.
- Insignia de estado: MPVPaper: ACTIVE se enfatiza con una píldora brillante con efecto 3D; INACTIVE se atenúa.
- La detección de “solo video” es robusta: inspecciona cada argumento del proceso mpvpaper (ignorando `-o` y su valor) y lo considera activo por video si cualquier argumento parece una ruta a archivo de video.
- El botón "Stop Video Wallpaper" mata solo procesos mpvpaper que estén reproduciendo video y deja corriendo sesiones solo-imagen (fondos estáticos).
- Después de detener, la UI espera brevemente y se relanza para que el encabezado actualice a INACTIVE sin necesidad de reejecutar el comando.

5) UI QML
- Se genera un archivo QML temporal y se ejecuta con qml de Qt 6.
- La UI refleja qs-wallpapers: barra de búsqueda, cuadrícula de miniaturas con esquinas redondeadas, clic para seleccionar.
- Conmutador de audio: “Deshabilitar sonido” está ACTIVO por defecto; al pulsar alterna audio. Al seleccionar, el selector imprime dos líneas en consola: SELECT:<path> y AUDIO:<ON|OFF>.
- El wrapper de shell captura ambas y aplica el audio según corresponda.

6) Salida
- Si hubo selección, qs-vid-wallpapers imprime la ruta por stdout. Si se canceló, no imprime nada.

7) Wrapper de aplicación
- qs-vid-wallpapers-apply orquesta el selector y luego aplica la selección usando mpvpaper, deteniendo awww-daemon/hyprpaper/mpvpaper primero para evitar conflictos, luego lanza mpvpaper en todas las salidas con opciones adecuadas (loop, sin OSC/OSD). El audio se deshabilita salvo que se reciba AUDIO:ON.
- Actualmente, el wrapper apunta al backend mpvpaper (el más apropiado para video). Si se desea, se puede extender para más backends o delegar al `awp` para comportamientos por monitor o de relleno/ajuste.

## Flags y entorno

Selector (qs-vid-wallpapers):
- Flags: -d DIR (dir de videos), -t DIR (cache de miniaturas), -s N (tamaño de miniatura), -h (ayuda)
- Env:
  - WALL_DIR: directorio de búsqueda (por defecto: $HOME/Pictures/Wallpapers)
  - VID_WALL_CACHE_DIR: cache de miniaturas (por defecto: $HOME/.cache/vidthumbs)
  - VID_WALL_THUMB_SIZE: tamaño en píxeles de miniaturas (por defecto: 200)
  - QS_DEBUG: imprime diagnósticos y ejecuta QML directamente
  - QS_PERF: imprime información de tiempos
  - QS_AUTO_QUIT: no se usa típicamente aquí; disponible para pruebas de rendimiento

Aplicación (qs-vid-wallpapers-apply):
- Flags:
  - --print-only: ejecuta el selector y sale (para benchmarks/inspección)
  - --shell-only: omite QML (pruebas de rendimiento)
- Env:
  - WALLPAPER_BACKEND: por defecto mpvpaper (otros aún no añadidos en este wrapper)
  - QS_DEBUG / QS_PERF / QS_AUTO_QUIT propagados según sea necesario

## Diferencias respecto al selector de imágenes

- Detección y control de procesos de fondos en ejecución:
  - qs-vid-wallpapers muestra estado y provee botón de parada específicamente para sesiones mpvpaper de video. Evita interrumpir sesiones estáticas (solo imagen).
- Generación de miniaturas: para video usa ffmpegthumbnailer/ffmpeg en lugar de ImageMagick.
- Enfoque del wrapper de aplicación: qs-vid-wallpapers-apply se centra en mpvpaper por ser el motor de video.

## ¿Por qué dos familias (qs-wallpapers* vs qs-vid-wallpapers*)?

- Imágenes estáticas y videos tienen necesidades distintas:
  - Herramientas de miniatura y rendimiento diferentes.
  - Comportamiento en ejecución distinto (videos consumen CPU/GPU; imágenes no).
  - Diferentes affordances de UX (estado y botón de parada solo para video vs selección simple para imágenes).
- Mantenerlas separadas mantiene cada ruta de código enfocada, más simple y fácil de ajustar sin regresiones.

## Notas de integración

- Las reglas de Hyprland incluyen entradas para flotar y centrar la ventana QML por título:
  - "Wallpapers" (imágenes) y "Video Wallpapers" (videos) se dirigen por separado.
  - Estilo vía windowrulev2: noborder, noshadow, noblur, rounding 12 para ambos títulos.
- Flags de ventana piden sin marco y sin sombra (Qt.NoDropShadowWindowHint), y la UI usa fondos más opacos para legibilidad en setups con blur.
- Atajos recomendados:
  - Imagen: `$mod+Shift+W` -> `qs-wallpapers-apply`
  - Video: elige una combinación conveniente, p.ej., `$mod+Shift+V` -> `qs-vid-wallpapers-apply`

## Solución de problemas

- El estado muestra INACTIVE mientras un video corre:
  - Asegura que el proceso mpvpaper incluya la ruta del archivo de video como argumento distinto (el script busca todos los args, ignorando `-o` y su valor). Si el archivo se lanza vía un wrapper que oculta la ruta o usa una invocación no estándar, la detección puede fallar.
- El botón de parar no hace nada:
  - Revisa permisos y que `pgrep`/`kill` estén disponibles; asegúrate de que el dueño del proceso sea el usuario actual.
- No se listan videos:
  - Verifica WALL_DIR y extensiones soportadas; los symlinks se soportan gracias a `find -L`.

## Posibles extensiones

- Delegación opcional a `awp` para selección avanzada por monitor y comportamientos de relleno/ajuste.
- Backends adicionales en el wrapper de aplicación si se desea.
- Ajustes persistentes (última selección, monitor) vía un pequeño archivo de estado si se necesita.

