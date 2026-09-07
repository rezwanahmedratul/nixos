# Guía para personalizar Hyprland en ddubsOS

Esta guía ofrece una mirada más detallada a cómo personalizar tu experiencia con Hyprland en ddubsOS. Veremos los archivos de configuración más importantes, explicando qué hacen y cómo puedes editarlos.

Advertencia: Los archivos de configuración están escritos en el lenguaje Nix. Nix tiene una sintaxis muy específica y cualquier error puede impedir que tu sistema se construya correctamente. Sé cuidadoso al editar estos archivos y sigue de cerca los ejemplos.

## Aplicar tus cambios

Después de hacer cambios en estos archivos, tendrás que aplicarlos. Abre una terminal y ejecuta:

```bash
zcli rebuild
```

Este comando reconstruirá tu sistema con la nueva configuración. Si hay errores en tu configuración, el comando fallará.

---

### `binds.nix` - Atajos de teclado

Este archivo controla todos tus atajos de teclado y ratón en Hyprland.

Ubicación: `modules/home/hyprland/binds.nix`

Puedes cambiar atajos existentes o añadir nuevos. El formato es una cadena con valores separados por comas: `MODIFICADOR, TECLA, DISPATCHER, VALOR`.

Ejemplo:

Digamos que quieres cambiar el atajo para abrir una terminal de `SUPER + Return` a `SUPER + T`.

Original:

```nix
# ...
    bind = [
      # ...
      "$modifier,Return,exec, ${terminal}"
      # ...
    ];
# ...
```

Modificado:

```nix
# ...
    bind = [
      # ...
      "$modifier,T,exec, ${terminal}"
      # ...
    ];
# ...
```

---

### `exec-once.nix` - Aplicaciones de inicio

Este archivo lista las aplicaciones y comandos que se ejecutan automáticamente al iniciar Hyprland.

Ubicación: `modules/home/hyprland/exec-once.nix`

Puedes añadir o eliminar comandos de esta lista. Cada comando es una cadena.

Ejemplo:

Si quieres iniciar la aplicación `copyq` cada vez que inicias sesión, puedes añadirla a la lista.

Original:

```nix
# ...
    exec-once = [
      # ...
    ];
# ...
```

Modificado:

```nix
# ...
    exec-once = [
      # ...
      "copyq"
    ];
# ...
```

---

### `decoration.nix` - Decoración de ventanas

Este archivo controla la apariencia de bordes, sombras y efectos de desenfoque.

Ubicación: `modules/home/hyprland/decoration.nix`

Puedes cambiar valores como `rounding` para esquinas redondeadas o ajustar `blur` y `shadow`.

Ejemplo:

Aumentar el redondeo de esquinas de `0` a `10`.

Original:

```nix
# ...
      decoration = {
        rounding = 0;
# ...
```

Modificado:

```nix
# ...
      decoration = {
        rounding = 10;
# ...
```

---

### `env.nix` - Variables de entorno

Este archivo define variables de entorno para tu sesión de Hyprland. Pueden afectar el comportamiento de las aplicaciones.

Ubicación: `modules/home/hyprland/env.nix`

Puedes añadir o cambiar variables en esta lista.

Ejemplo:

Establecer `MOZ_ENABLE_WAYLAND` a `1`, lo que fuerza a Firefox a ejecutarse en Wayland.

Original:

```nix
# ...
    env = [
      # ...
      "SDL_VIDEODRIVER, wayland"
      # ...
    ];
# ...
```

Modificado:

```nix
# ...
    env = [
      # ...
      "SDL_VIDEODRIVER, wayland"
      "MOZ_ENABLE_WAYLAND, 1"
      # ...
    ];
# ...
```

---

### `gestures.nix` - Gestos del touchpad

Este archivo controla los gestos del touchpad, como deslizar entre espacios de trabajo.

Ubicación: `modules/home/hyprland/gestures.nix`

Puedes habilitar o deshabilitar gestos y cambiar su comportamiento.

Ejemplo:

Desactivar el swiping de espacios de trabajo.

Original:

```nix
# ...
      gestures = {
        workspace_swipe = 1;
# ...
```

Modificado:

```nix
# ...
      gestures = {
        workspace_swipe = 0;
# ...
```

---

### `misc.nix` - Ajustes varios

Este archivo contiene varios ajustes que no encajan en otras categorías.

Ubicación: `modules/home/hyprland/misc.nix`

Puedes cambiar ajustes como `vrr` (tasa de refresco variable) o `disable_hyprland_logo`.

Ejemplo:

Habilitar VRR.

Original:

```nix
# ...
      misc = {
        # ...
        vrr = 0;
        # ...
      };
# ...
```

Modificado:

```nix
# ...
      misc = {
        # ...
        vrr = 1;
        # ...
      };
# ...
```

---

### `hyprland.nix` - Configuración principal

Este es el archivo principal de Hyprland. Define ajustes generales, dispositivos de entrada y el layout de ventanas.

Ubicación: `modules/home/hyprland/hyprland.nix`

Puedes cambiar cosas como el layout del teclado, ajustes del touchpad y el motor de layout.

Ejemplo:

Cambiar el layout del teclado al `us`.

Original:

```nix
# ...
      input = {
        kb_layout = "${keyboardLayout}";
# ...
```

Modificado:

```nix
# ...
      input = {
        kb_layout = "us";
# ...
```

---

### `windowrules.nix` - Reglas de ventanas

Este archivo define reglas para cómo deben comportarse ventanas específicas. Puedes hacer que ciertas aplicaciones siempre floten, se abran en un workspace concreto o tengan cierta opacidad.

Ubicación: `modules/home/hyprland/windowrules.nix`

Puedes añadir reglas nuevas a la lista `windowrule`.

Ejemplo:

Hacer que el gestor de archivos `thunar` siempre flote.

Original:

```nix
# ...
      windowrule = [
        # ...
        "float, class:^(foot-floating)$"
        # ...
      ];
# ...
```

Modificado:

```nix
# ...
      windowrule = [
        # ...
        "float, class:^(foot-floating)$"
        "float, class:^(Thunar)$"
        # ...
      ];
# ...
```

