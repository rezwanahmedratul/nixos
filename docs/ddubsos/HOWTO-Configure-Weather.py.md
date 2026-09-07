# HOWTO: Configure and Use Weather.py (Open‑Meteo)

## Path

- Script: `~/.config/hypr/UserScripts/Weather.py`

## Overview

- Weather.py fetches current weather, daily min/max temperatures, hourly
  precipitation probability, and AQI using Open‑Meteo APIs (no API key).
- Outputs Waybar-compatible JSON for a custom module and writes a simple text
  cache.
- Robust by design: caching, multiple IP geolocation fallbacks, reverse
  geocoding (with fallback), and safe tooltip formatting.

## Requirements

- Python 3.8+
- Python package: `requests`

Install (user-level):

```bash
pip install --user requests
```

## Fonts and Icons

- The script outputs Unicode icons; weather icons use Nerd Font glyphs and the
  default location marker is 📍.
- If your font lacks these glyphs, set `WEATHER_LOC_ICON` to an ASCII-safe
  character (e.g., `*`) or disable tooltip markup.

## Configuration (Environment Variables)

- `WEATHER_UNITS`: `metric` | `imperial` (default: `metric`)
- `WEATHER_LAT` / `WEATHER_LON`: manually set coordinates (floats). If unset,
  the script tries cached coords or IP geolocation.
- `WEATHER_PLACE`: manual friendly location name for the tooltip.
- `WEATHER_CACHE_TTL`: cache time in seconds (default: `600`)
- `WEATHER_TOOLTIP_MARKUP`: `1` to enable Pango markup (default), `0` for
  plain-text tooltips
- `WEATHER_LOC_ICON`: location marker character (default: `📍`)
- `WEATHER_LANG`: language for reverse geocoding results (default: `en`)

### Place Name Priority

1. MANUAL_PLACE (constant inside Weather.py; currently disabled/None)
2. `WEATHER_PLACE` (env var)
3. Reverse geocoding (Open‑Meteo → Nominatim fallback)
4. Latitude,Longitude (rounded)

## Quick Start

- Run with defaults (metric units):

```bash
python3 /home/dwilliams/Projects/Weather.py
```

- Run with imperial units (one-off):

```bash
WEATHER_UNITS=imperial python3 /home/dwilliams/Projects/Weather.py
```

- Pin exact coordinates and a friendly name:

```bash
export WEATHER_LAT=43.2229
export WEATHER_LON=-71.332
export WEATHER_PLACE="Concord, NH"
python3 /home/dwilliams/Projects/Weather.py
```

- Plain-text tooltip and ASCII location icon (for GTK/Pango issues):

```bash
export WEATHER_TOOLTIP_MARKUP=0
export WEATHER_LOC_ICON="*"
python3 /home/dwilliams/Projects/Weather.py
```

## Waybar Integration

1. Create a custom module in your Waybar config (example):

```json
{
  "custom/weather": {
    "exec": "python3 /home/dwilliams/Projects/Weather.py",
    "return-type": "json",
    "interval": 600
  }
}
```

2. If you want per-module environment variables, use Waybar’s top-level `env`
   block (optional):

```json
"env": {
  "WEATHER_UNITS": "metric",
  "WEATHER_TOOLTIP_MARKUP": "1",
  "WEATHER_LOC_ICON": "📍"
}
```

3. Reload Waybar after changes.

## Caching

- API cache: `~/.cache/open_meteo_cache.json` (includes forecast, AQI, and
  resolved place). Default TTL: 600 seconds.
- Simple text cache: `~/.cache/.weather_cache` (for other status bars or
  scripts).
- To clear cached data, remove the cache file:

```bash
rm ~/.cache/open_meteo_cache.json
```

## Geolocation Behavior

- Coordinate source priority: `WEATHER_LAT/LON` → cached forecast coords → IP
  geolocation (`ipinfo.io` → `ipwho.is` → `ipapi.co`) → `0,0` fallback.
- To avoid using public IP geolocation, set `WEATHER_LAT` and `WEATHER_LON`.

## Troubleshooting

- Tooltip error: "No icon name or pixmap given"
  - Set `WEATHER_TOOLTIP_MARKUP=0` to disable markup, and/or set
    `WEATHER_LOC_ICON="*"` for ASCII.
  - Ensure your font supports the glyphs (Nerd Font recommended for weather
    icons).
- Location shows coordinates instead of a name
  - Reverse geocoding failed or was rate-limited. Set `WEATHER_PLACE` to your
    desired name or try again later.
- No output or hangs
  - Ensure `requests` is installed. Check network/firewall. Consider clearing
    the cache and retrying.
- AQI shows "AQI N/A"
  - The Air Quality API may be unavailable for your region at that moment; it
    will populate when available.

## Notes

- Errors and logs are written to stderr and do not corrupt Waybar JSON output.
- Icons are emitted as Unicode; JSON is printed with `ensure_ascii=False` so
  Waybar can render them.

