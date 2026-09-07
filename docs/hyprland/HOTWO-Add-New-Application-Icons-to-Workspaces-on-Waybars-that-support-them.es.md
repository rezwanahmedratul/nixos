# CÓMO: Añadir iconos de aplicaciones a espacios de trabajo (para Waybars que lo soportan)

[Read in English](./HOTWO-Add-New-Application-Icons-to-Workspaces-on-Waybars-that-support-them.md)

Esta guía explica cómo funciona la característica de “icono por aplicación/ventana” en tus configuraciones de Waybar, qué archivos editar, cómo obtener los identificadores (class/title) y cómo añadir nuevos mapeos. Incluye ejemplos.

Importante:
- Solo ciertos temas de Waybar en este repositorio soportan iconos por aplicación en la lista de espacios de trabajo (usan reglas window-rewrite). Los variantes basados en Jak sí lo hacen; varios otros muestran solo nombres/números.
- Puedes añadir mapeos globalmente (archivo compartido) y/o localmente (archivo del tema).


## 1) ¿Qué Waybars lo soportan?
Estos archivos incluyen un bloque hyprland/workspaces con reglas window-rewrite:
- modules/home/waybar/waybar-jak-catppuccin.nix
- modules/home/waybar/waybar-jak-ml4w-modern.nix
- modules/home/waybar/waybar-jak-oglo-simple.nix
- Reglas compartidas: modules/home/waybar/jak-waybar/ModulesWorkspaces

Otros temas (p. ej. waybar-ddubs.nix, waybar-ddubs-2.nix, waybar-simple.nix, waybar-curved.nix, waybar-tony.nix, waybar-dwm*.nix, waybar-mecha.nix, waybar-jwt-*.nix) no usan window-rewrite; muestran etiquetas/números de espacios de trabajo.


## 2) ¿Cómo funciona?
El módulo hyprland/workspaces de Waybar soporta reglas de reemplazo por regex:
- window-rewrite-default: icono por defecto cuando nada coincide.
- window-rewrite: mapa de selectores regex → iconos.
- Selectores típicos:
  - class<...> para la clase de ventana (Hyprland class)
  - title<...> para el título de la ventana

Ejemplo (fragmento Nix dentro de settings):
```nix
"hyprland/workspaces#rw" = {
  format = "{icon} {windows}";
  "format-window-separator" = " ";
  "window-rewrite-default" = " ";
  "window-rewrite" = {
    "class<firefox|org.mozilla.firefox>" = " ";
    "class<discord|Vesktop>" = " ";
    "title<.*YouTube.*>" = " ";
  };
};
```


## 3) Dónde editar
Puedes añadir reglas en uno o ambos lugares:
- Global (compartido):
  - modules/home/waybar/jak-waybar/ModulesWorkspaces
  - Ventaja: una edición se propaga a todos los temas basados en Jak que importan estas reglas.
- Específico del tema:
  - modules/home/waybar/waybar-jak-catppuccin.nix
  - modules/home/waybar/waybar-jak-ml4w-modern.nix
  - modules/home/waybar/waybar-jak-oglo-simple.nix
  - Ventaja: solo afecta un tema; útil para pruebas.

Sugerencia: si un tema duplica (incluye) reglas, actualiza tanto el archivo compartido como el tema activo para mantener consistencia.


## 4) Obtener la clase y el título de una app
En Hyprland, usa hyprctl:
```bash
hyprctl clients -j | jq '.[] | {class: .class, title: .title}'
```
- class sirve para class<...>
- title sirve para title<...>

Ejemplos:
- Signal en Flatpak suele ser org.signal.Signal
- Signal nativo puede ser signal-desktop
- Algunos títulos cambian por pestaña/documento; class suele ser más estable


## 5) Elegir un icono
- Usa un glifo de Nerd Fonts u otro set ya usado en tu barra.
- Mantén iconos cortos (1–2 glifos + espacio final), ej. "󰍩 " o " ".
- Opcional: color con markup; la mayoría de reglas aquí deja texto plano por uniformidad.


## 6) Añadir un mapeo nuevo (paso a paso)
Ejemplo: Añadir icono para Signal Desktop

A) Actualizar reglas compartidas (recomendado)
- Archivo: modules/home/waybar/jak-waybar/ModulesWorkspaces
- Busca el mapa "hyprland/workspaces#rw" → "window-rewrite"
- Añade patrones para Signal:
```jsonc
"window-rewrite": {
  // ... entradas existentes ...
  "class<[Ss]ignal|signal-desktop|org.signal.Signal>": "󰍩 ",
  "title<.*Signal.*>": "󰍩 ",
}
```
¿Por qué ambas? La clase es fiable, pero la regla de título cubre casos especiales.

B) Actualizar un tema que duplique reglas (si aplica)
- Archivos:
  - modules/home/waybar/waybar-jak-catppuccin.nix
  - modules/home/waybar/waybar-jak-ml4w-modern.nix
  - modules/home/waybar/waybar-jak-oglo-simple.nix
- Busca el bloque hyprland/workspaces con "window-rewrite" y añade las mismas entradas.

C) Reconstruir y recargar Waybar
- Si usas Home Manager:
```bash
home-manager switch
systemctl --user restart waybar.service
```
- Alternativamente, reinicia el proceso Waybar si no usas systemd para gestionarlo.


## 7) Pruebas y solución de problemas
- Lanza la app en algún espacio de trabajo y confirma que aparece el icono junto al botón del espacio.
- Si no aparece:
  - Confirma que el tema activo es uno de Jak con window-rewrite.
  - Revisa que el regex coincida con class/title (de nuevo con hyprctl clients -j).
  - Asegura que tu fuente soporta el glifo elegido (Nerd Font en el CSS de la barra).
  - Revisa comillas o comas erróneas en Nix/JSON.


## 8) Patrones comunes para copiar
- Múltiples clases en una regla (alternancia regex):
```jsonc
"class<Chromium|Thorium|[Cc]hrome>": " ",
```
- Coincidencia pseudo-insensible a mayúsculas (ej., Signal y signal):
```jsonc
"class<[Ss]ignal>": "󰍩 ",
```
- Título que contiene texto:
```jsonc
"title<.*YouTube.*>": " ",
```