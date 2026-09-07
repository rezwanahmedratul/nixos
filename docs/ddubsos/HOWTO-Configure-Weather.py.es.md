# HOWTO: Configurar y Usar Weather.py (Open‑Meteo)

Ruta

- Script: `~/.config/hypr/UserSCripts/Weather.py`

Resumen

- Weather.py obtiene el tiempo actual, las temperaturas mínima/máxima diarias,
  la probabilidad de precipitación por hora y el AQI usando las APIs de
  Open‑Meteo (sin clave de API).
- Emite JSON compatible con Waybar para un módulo personalizado y escribe una
  caché de texto simple.
- Robusto: caché, múltiples alternativas de geolocalización por IP,
  geocodificación inversa (con alternativa) y formato seguro del tooltip.

Requisitos

- Python 3.8+
- Paquete de Python: requests Instalar (a nivel de usuario):
  ```bash
  pip install --user requests
  ```

Fuentes e iconos

- La salida incluye iconos Unicode; el script usa glifos de Nerd Font para el
  clima y un marcador de ubicación por defecto (📍).
- Si tu fuente no incluye estos glifos, configura WEATHER_LOC_ICON con un
  carácter ASCII (p. ej., "*") o desactiva el marcado del tooltip.

Opciones de configuración (variables de entorno)

- WEATHER_UNITS: metric | imperial (por defecto: metric)
- WEATHER_LAT / WEATHER_LON: establecer coordenadas manualmente (números). Si no
  se establecen, el script usa coordenadas en caché o geolocalización por IP.
- WEATHER_PLACE: nombre de ubicación amigable para el tooltip.
- WEATHER_CACHE_TTL: tiempo de caché en segundos (por defecto: 600)
- WEATHER_TOOLTIP_MARKUP: 1 para habilitar Pango markup (por defecto), 0 para
  tooltip en texto plano
- WEATHER_LOC_ICON: carácter para el marcador de ubicación (por defecto: 📍)
- WEATHER_LANG: idioma para los resultados de geocodificación inversa (por
  defecto: en)

Prioridad del nombre de ubicación

1. MANUAL_PLACE (constante dentro de Weather.py; actualmente desactivado/None)
2. WEATHER_PLACE (variable de entorno)
3. Geocodificación inversa (Open‑Meteo → alternativa Nominatim)
4. Coordenadas latitud,longitud (redondeadas)

Inicio rápido

- Ejecutar con valores por defecto (unidades métricas):
  ```bash
  python3 /home/dwilliams/Projects/Weather.py
  ```
- Ejecutar con unidades imperiales (un solo uso):
  ```bash
  WEATHER_UNITS=imperial python3 /home/dwilliams/Projects/Weather.py
  ```
- Establecer coordenadas exactas y un nombre amigable:
  ```bash
  export WEATHER_LAT=43.2229
  export WEATHER_LON=-71.332
  export WEATHER_PLACE="Concord, NH"
  python3 /home/dwilliams/Projects/Weather.py
  ```
- Tooltip en texto plano e icono ASCII (para problemas con GTK/Pango):
  ```bash
  export WEATHER_TOOLTIP_MARKUP=0
  export WEATHER_LOC_ICON="*"
  python3 /home/dwilliams/Projects/Weather.py
  ```

Integración con Waybar

1. Crea un módulo personalizado en tu configuración de Waybar (ejemplo):
   ```json
   {
     "custom/weather": {
       "exec": "python3 /home/dwilliams/Projects/Weather.py",
       "return-type": "json",
       "interval": 600
     }
   }
   ```
2. Si necesitas variables de entorno por módulo, usa el bloque "env" de nivel
   superior de Waybar (opcional):
   ```json
   "env": {
     "WEATHER_UNITS": "metric",
     "WEATHER_TOOLTIP_MARKUP": "1",
     "WEATHER_LOC_ICON": "📍"
   }
   ```
3. Recarga Waybar tras los cambios.

Caché

- Caché de API: ~/.cache/open_meteo_cache.json (incluye pronóstico, AQI y
  ubicación resuelta). TTL por defecto: 600 s.
- Caché de texto simple: ~/.cache/.weather_cache (para otras barras o scripts).
- Para limpiar la caché, elimina el archivo:
  ```bash
  rm ~/.cache/open_meteo_cache.json
  ```

Comportamiento de geolocalización

- La obtención de coordenadas sigue esta prioridad: WEATHER_LAT/LON → coords del
  pronóstico en caché → geolocalización IP (ipinfo.io → ipwho.is → ipapi.co) →
  0,0 como último recurso.
- Para evitar usar la IP pública, establece WEATHER_LAT y WEATHER_LON.

Resolución de problemas

- Error de tooltip: "No icon name or pixmap given"
  - Configura WEATHER_TOOLTIP_MARKUP=0 para desactivar el marcado y/o
    WEATHER_LOC_ICON="*" para ASCII.
  - Asegúrate de que tu fuente soporta los glifos (Nerd Font recomendada para
    iconos meteorológicos).
- El tooltip muestra coordenadas en lugar del nombre
  - Falló la geocodificación inversa o fue limitada por tasa. Establece
    WEATHER_PLACE con el nombre deseado o inténtalo de nuevo más tarde.
- Sin salida o bloqueos
  - Asegura que requests está instalado. Verifica red/firewall. Considera
    limpiar la caché y reintentar.
- AQI muestra "AQI N/A"
  - La API de calidad del aire puede no estar disponible temporalmente para tu
    región; se completará cuando esté disponible.

Notas

- Los errores y logs se escriben en stderr y no corrompen la salida JSON de
  Waybar.
- Los iconos se emiten como Unicode; el JSON se imprime con ensure_ascii=False
  para que Waybar los renderice correctamente.
