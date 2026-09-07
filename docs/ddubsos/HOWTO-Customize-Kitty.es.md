# CÓMO: Personalizar Kitty (ddubsOS)

Este repositorio gestiona Kitty con Home Manager en `modules/home/terminals/kitty.nix`. Incluye un tema Catppuccin Mocha embebido en `extraConfig` y valores por defecto sensatos (Maple Mono NF, pestañas powerline, scrollback 10k, URLs, integraciones de shell).

Sección 1 — Cambios rápidos (fuente, tamaño, comportamiento)
- Edita `modules/home/terminals/kitty.nix` → `programs.kitty.settings`
  - `font_family = "Maple Mono NF";`   # cambia a cualquier fuente instalada
  - `font_size = 12;`                   # ajusta tamaño
  - `window_padding_width`, `tab_bar_style`, `scrollback_lines`, etc.
- Aplica cambios: `zcli rebuild` (preferido) o `nh os switch`.

Ejemplo (Nix):
```conf
programs.kitty.settings = {
  font_family = "JetBrainsMono Nerd Font";
  font_size = 13;
  tab_bar_style = "fade";
  scrollback_lines = 20000;
};
```

Sección 2 — Colores manuales
El `programs.kitty.extraConfig` del módulo contiene una paleta Catppuccin completa (foreground/background, pestañas, color0..15).

Opción A: Colores inline en Nix
- Sustituye las líneas de color en `extraConfig` por tu paleta.
- Claves a definir: `foreground`, `background`, `selection_foreground`, `selection_background`, `cursor`, `active_border_color`, `inactive_border_color`, `active_tab_*`, `inactive_tab_*`, `color0..color15`.

Ejemplo (sintaxis kitty):
```conf
# Tema oscuro mínimo
foreground              #d0d0d0
background              #111216
active_border_color     #8aadf4
inactive_border_color   #3b3d4b
active_tab_foreground   #0e0f13
active_tab_background   #a6e3a1
inactive_tab_foreground #c0c4ce
inactive_tab_background #1a1b22

# paleta de 16 colores
color0  #1b1d24
color8  #3b3d4b
color1  #ff6b6b
color9  #ff8787
color2  #a6e3a1
color10 #b1f0ad
color3  #f9e2af
color11 #ffe7a3
color4  #89b4fa
color12 #9ac1ff
color5  #f5c2e7
color13 #f8c8ee
color6  #94e2d5
color14 #9fe9dc
color7  #c6cad6
color15 #e6e9ef
```

Opción B: Incluir un fichero de tema separado
1) Quita (o comenta) la paleta embebida en `extraConfig` y añade:
```conf
include current-theme.conf
```
2) Crea `~/.config/kitty/current-theme.conf` con tus colores (o deja que el kitten de la Sección 3 lo genere).
3) Reconstruye: `zcli rebuild` o `nh os switch`.

Sección 3 — Usar “kitty +kitten themes”
1) Asegura que tu config incluye el `include` (ver Opción B).
2) Reconstruye.
3) En una ventana de Kitty, ejecuta:
```bash
kitty +kitten themes --reload-in=all
```
- Navega con flechas, Enter para previsualizar.
- Pulsa `s` para guardar; por defecto escribe `current-theme.conf` en `~/.config/kitty/`.
4) El tema persiste porque `kitty.conf` incluye `current-theme.conf`.

Comandos rápidos
- Aplicar un tema sin reiniciar:
```bash
kitty @ set-colors --all ~/.config/kitty/current-theme.conf
```
- Si los colores no cuadran, verifica que no haya directivas de color después del `include` en `extraConfig`.

Sección 4 — Lanzador con imagen de fondo (kitty-bg)
Este repo instala un helper que superpone ajustes de fondo sobre tu config principal y lanza Kitty.

Uso:
```bash
kitty-bg                          # elige fondo aleatorio y lanza en segundo plano
kitty-bg --no-launch              # solo actualiza el symlink del fondo
kitty-bg -s ~/Pictures/Wallpapers/Space
kitty-bg -l ~/Pictures/current_image
kitty-bg --foreground -- -e htop  # argumentos a kitty tras --
```
Qué hace
- Elige imagen aleatoria de `~/Pictures/Wallpapers` (override con `-s`).
- Actualiza symlink `~/Pictures/current_image` (override con `-l`).
- Lanza Kitty con `~/.config/kitty/kitty-bg.conf`, que incluye tu `kitty.conf` y aplica el fondo.

Referencias
- Módulo: `modules/home/terminals/kitty.nix`
- Cheatsheet: `cheatsheets/kitty/kitty.cheatsheet.md`