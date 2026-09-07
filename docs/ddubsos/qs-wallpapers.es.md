# qs-wallpapers y qs-wallpapers-apply

Este documento explica qué hacen las herramientas qs-wallpapers, cómo están estructuradas y cómo trabajan juntas.

- Selector: qs-wallpapers (instalado desde modules/home/scripts/qs-wallpapers.nix)
- Wrapper de aplicación: qs-wallpapers-apply (instalado desde modules/home/scripts/qs-wallpapers-apply.nix)
- Ayudante de restauración: qs-wallpapers-restore (instalado desde modules/home/scripts/qs-wallpapers-restore.nix)

## Qué hacen

- qs-wallpapers es un selector rápido de miniaturas Qt/QML para fondos estáticos (imágenes). Escanea tu directorio de fondos, construye/usa miniaturas en caché y renderiza una cuadrícula con búsqueda. Al hacer clic en una miniatura, devuelve la ruta seleccionada por stdout.
- qs-wallpapers-apply ejecuta el selector y luego aplica el fondo usando un backend (por defecto: mpvpaper). También limpia demonios de fondos en conflicto antes. Cuando se aplica una selección, persiste el fondo actual en archivos de estado para restaurar al iniciar sesión.
- qs-wallpapers-restore restaura el último fondo al iniciar sesión, respetando restricciones de backend y ofreciendo respaldos robustos. Ver docs/qs-wallpaper-restore.md para detalles.

## Conceptos clave y flujo

1) Recolectar archivos
- Escanea WALL_DIR (por defecto: $HOME/Pictures/Wallpapers) recursivamente, siguiendo symlinks (`find -L`).
- Extensiones de imagen incluidas: jpg, jpeg, png, webp, avif, bmp, tiff.

2) Caché de miniaturas
- Las miniaturas se cachean en WALL_CACHE_DIR (por defecto: $HOME/.cache/wallthumbs) usando ImageMagick convert.
- Un manifiesto precalculado (walls.json) puede poblarse en activación para evitar construirlo en tiempo de ejecución y mejorar el arranque.

3) Manifiesto JSON
- El selector construye (o copia) un array JSON de objetos: { path, name, thumb } para cada imagen.
- path: ruta absoluta de la imagen; name: nombre de archivo sin extensión; thumb: ruta al thumbnail cacheado.

4) UI QML
- Se genera un .qml temporal y se ejecuta con qml de Qt 6.
- Visuales: ventana sin marco y sin sombra con mayor opacidad en marco/encabezado para legibilidad; reglas de Hyprland aplican noblur/noborder/rounding.
- La UI muestra:
  - Barra de búsqueda que filtra por nombre/ruta (insensible a mayúsculas), con degradado sutil para profundidad.
  - Cuadrícula de miniaturas redondeadas con etiquetas.
  - Al hacer clic, imprime una línea que contiene "SELECT:<path>" en la consola de QML; el script de shell captura y imprime solo la ruta por stdout.

5) Salida
- Si hubo selección, qs-wallpapers imprime la ruta por stdout. Si se cancela, no imprime nada.

6) Wrapper de aplicación
- qs-wallpapers-apply orquesta el selector y aplica el resultado.
- Establece BACKEND = ${WALLPAPER_BACKEND:-mpvpaper}.
- Al seleccionar, persiste estado en:
  - $XDG_STATE_HOME/qs-wallpapers/current.json (campos: path, backend, timestamp)
  - $XDG_STATE_HOME/qs-wallpapers/current_wallpaper (ruta en texto plano)
- Luego aplica vía el backend seleccionado:
  - mpvpaper: pkill de awww-daemon, hyprpaper, mpvpaper para evitar conflictos, breve sleep y luego inicia mpvpaper en todas las salidas con opciones razonables para imágenes.
  - awww: asegura awww-daemon corriendo y luego `awww img --resize fill <path>`.
  - hyprpaper: genera una config mínima (por monitor) y arranca hyprpaper.

## Flags y entorno

Selector (qs-wallpapers):
- Flags: -d DIR (dir de imágenes), -t DIR (cache de miniaturas), -s N (tamaño de miniatura), -h (ayuda)
- Env:
  - WALL_DIR: directorio de búsqueda (por defecto: $HOME/Pictures/Wallpapers)
  - WALL_CACHE_DIR: cache de miniaturas (por defecto: $HOME/.cache/wallthumbs)
  - WALL_THUMB_SIZE: tamaño en píxeles de miniaturas (por defecto: 200)
  - QS_DEBUG: si está, imprime diagnósticos y ejecuta QML directamente (útil para depuración)
  - QS_PERF: si está, imprime tiempos
  - QS_AUTO_QUIT: si está, cierra QML inmediatamente tras construir el modelo (usado en modos print-only/perf)

Aplicación (qs-wallpapers-apply):
- Flags:
  - --print-only: ejecuta el selector y sale (útil para benchmark/inspección)
  - --shell-only: prepara y ejecuta solo la parte de shell (omite QML; pruebas de rendimiento)
- Env:
  - WALLPAPER_BACKEND: mpvpaper (por defecto), awww, o hyprpaper
  - QS_DEBUG / QS_PERF / QS_AUTO_QUIT propagados según sea necesario

## ¿Por qué dos herramientas (selector vs aplicar)?

- El selector (qs-wallpapers) es componible: puede usarse solo en scripts o encadenado a otras herramientas. Hace una cosa: permitir seleccionar un archivo y devolverlo.
- El wrapper (qs-wallpapers-apply) ofrece una UX completa: ejecuta el selector y aplica de inmediato usando tu backend preferido con seguridad (deteniendo demonios en conflicto).

## Rendimiento

- Preconstruir miniaturas y, opcionalmente, un manifiesto JSON en activación reduce notablemente el tiempo percibido de inicio.
- El selector evita llamadas de red y cargas de librerías pesadas en tiempo de ejecución; usa herramientas del sistema optimizadas (find, convert, sha256sum) y embebe el JSON en la escena QML para evitar I/O dentro de QML.

## Notas de integración

- Reglas de Hyprland (en modules/home/hyprland/windowrules.nix) flotan y estilizan la ventana QML cuando el título coincide con "Wallpapers".
- Ejemplo de atajo (Hyprland): `$mod+Shift+W` -> `qs-wallpapers-apply`.
- Restaurar al iniciar sesión: `qs-wallpapers-restore` se llama desde modules/home/hyprland/exec-once.nix. Si no hay estado guardado o todos los métodos fallan, exec-once recurre a `waypaper` con una imagen por defecto.

## Solución de problemas

- No se listan imágenes: verifica que WALL_DIR exista y tenga extensiones soportadas (los symlinks se soportan con -L).
- El selector no imprime nada: cancelaste o cerraste la ventana sin clic.
- La aplicación falla: asegúrate de tener mpvpaper/awww/hyprpaper instalados para el backend elegido.
- La pantalla negra en mpv: una regla de Hyprland establece `content none, class:mpv` para evitar cuadros negros al maximizar; no está relacionado con estas herramientas pero se menciona en la configuración.

