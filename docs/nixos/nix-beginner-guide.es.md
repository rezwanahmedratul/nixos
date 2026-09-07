# ¡Bienvenido a ddubsOS! Guía para principiantes sobre personalización

¡Bienvenido! Esta guía es para usuarios nuevos en Nix que quieren hacer personalizaciones comunes en su instalación de ddubsOS. Mantendremos las cosas simples y nos centraremos en lo esencial.

## Entendiendo la estructura

Las configuraciones de NixOS pueden parecer complejas, pero para los cambios del día a día solo necesitas conocer unos pocos archivos y directorios clave.

-   `flake.nix`: Es el archivo principal de todo el sistema. No deberías necesitar editarlo directamente para la mayoría de cambios comunes.
-   `hosts/`: Contiene la configuración de cada computadora (o "host") donde instalaste ddubsOS.
    -   `hosts/<tu-hostname>/`: Aquí harás la mayoría de tus cambios.
        -   `variables.nix`: Es tu panel de control. Puedes habilitar/deshabilitar funciones, cambiar ajustes y más.
        -   `host-packages.nix`: Aquí puedes añadir paquetes solo para esta computadora.
-   `modules/`: Contiene la mayor parte de la configuración, separada en piezas reutilizables ("módulos").
    -   `modules/core/global-packages.nix`: Puedes añadir paquetes aquí si quieres que se instalen en todas tus máquinas ddubsOS.
    -   `modules/home/hyprland/binds.nix`: Aquí puedes personalizar tus atajos de Hyprland.

## Cómo añadir paquetes

Hay dos formas principales de añadir paquetes:

### 1. Para una sola computadora

Si solo quieres instalar un paquete en tu computadora actual, añádelo a `hosts/<tu-hostname>/host-packages.nix`.

1.  Abre `hosts/<tu-hostname>/host-packages.nix` en tu editor favorito.
2.  Verás una lista de paquetes. Simplemente añade el nombre del paquete que quieres instalar. Por ejemplo, para añadir `cowsay`, cambiarías esto:

    ```nix
    [
      brave
      (catppuccin-vsc.override {
        variant = "mocha";
      })
    ]
    ```

    a esto:

    ```nix
    [
      brave
      (catppuccin-vsc.override {
        variant = "mocha";
      })
      cowsay
    ]
    ```

3.  Guarda el archivo.

### 2. Para todas las computadoras

Si quieres que un paquete se instale en todas tus máquinas, añádelo a `modules/core/global-packages.nix`. El proceso es el mismo que arriba.

## Cómo cambiar ajustes del monitor

Puedes cambiar los ajustes de monitor en `hosts/<tu-hostname>/variables.nix`.

1.  Abre `hosts/<tu-hostname>/variables.nix`.
2.  Busca la línea `extraMonitorSettings`.
3.  Añade tus ajustes de monitor. Por ejemplo, para establecer resolución y tasa de refresco para un monitor llamado `DP-1`, cambia esto:

    ```nix
    extraMonitorSettings = "";
    ```

    a esto:

    ```nix
    extraMonitorSettings = "monitor=DP-1,1920x1080@144";
    ```

4.  Guarda el archivo.

## Cómo cambiar atajos de Hyprland

Puedes cambiar tus atajos en `modules/home/hyprland/binds.nix`.

1.  Abre `modules/home/hyprland/binds.nix`.
2.  Verás una lista de atajos. Puedes cambiarlos a tu gusto. Por ejemplo, para cambiar el atajo de abrir la terminal de `SUPER, Return` a `SUPER, T`, cambia esto:

    ```nix
    "SUPER, Return, exec, ${terminal}"
    ```

    a esto:

    ```nix
    "SUPER, T, exec, ${terminal}"
    ```

3.  Guarda el archivo.

## Aplicar tus cambios

Después de hacer cambios, debes aplicarlos.

1.  Abre una terminal.
2.  Ejecuta `zcli rebuild`. Esto aplicará los cambios al sistema.
3.  Si el comando termina correctamente, ¡tus cambios ya están activos! Algunos cambios pueden requerir reinicio.

