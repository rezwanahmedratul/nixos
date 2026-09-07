# HOWTO: Add a Browser to the Support List (ddubsOS)

This guide explains how ddubsOS sets the default browser declaratively and how you can add support for new browsers (for example, Thorium or Ladybird). It also shows what needs to be changed in your hosts/<host>/variables.nix file.

What this module does
- Location: modules/home/xdg/default-apps.nix
- It imports your per-host settings from hosts/<host>/variables.nix and reads the browser key (defaults to google-chrome-stable).
- It maps that browser key to a .desktop ID (e.g., google-chrome-stable -> google-chrome.desktop) and sets XDG default handlers for:
  - x-scheme-handler/http
  - x-scheme-handler/https
  - text/html
  - application/xhtml+xml
- This makes the default browser declarative via Home Manager, so apps (like Zen or Discord) can’t permanently override ~/.config/mimeapps.list.
- If you select Zen (browser = "zen" or "zen-browser"), the module asserts that enableZenBrowser = true so the package is installed.

Where it reads your setting
- hosts/<host>/variables.nix contains a key like:
  ```nix path=null start=null
  browser = "google-chrome-stable";
  ```
- If you don’t set browser, the module defaults to google-chrome-stable.

How to add a new browser (overview)
1) Install the browser (or ensure it’s installable). You can add it via Home Manager or an input overlay; this guide focuses on setting it as default, not packaging steps.
2) Find the .desktop ID provided by the browser package.
   - Typical IDs:
     - google-chrome.desktop, firefox.desktop, chromium.desktop, brave-browser.desktop, vivaldi-stable.desktop, floorp.desktop, etc.
   - To discover the ID after installation:
     ```sh path=null start=null
     # Search system-wide desktop files
     grep -R "Name=.*<Your Browser Name>" /run/current-system/sw/share/applications 2>/dev/null | cut -d: -f1 | sort -u

     # Or search for likely names
     ls /run/current-system/sw/share/applications | grep -iE "(chrome|thorium|ladybird|browser)"
     ```
     If installed only for the user, desktop files may live under ~/.nix-profile/share/applications as well.
3) Update the desktop mapping in modules/home/xdg/default-apps.nix.
   - Add a new entry for your browser key -> desktop file name.
   - Example (Thorium, Ladybird):
     ```nix path=null start=null
     browserDesktop = {
       # ...existing entries...
       "thorium" = "thorium-browser.desktop";  # confirm actual ID after install
       "ladybird" = "ladybird.desktop";        # confirm actual ID after install
     };
     ```
4) Update your host’s variables.nix to use the new key:
   ```nix path=null start=null
   # hosts/<host>/variables.nix
   browser = "thorium";  # or "ladybird"
   ```
5) Rebuild and verify:
   ```sh path=null start=null
   # Rebuild your system (adjust to your workflow)
   nh os switch   # or: sudo nixos-rebuild switch --flake .#<host>

   # Verify the default handlers now point to your browser’s .desktop
   xdg-mime query default x-scheme-handler/http
   xdg-mime query default x-scheme-handler/https
   xdg-mime query default text/html
   xdg-mime query default application/xhtml+xml
   ```

If you use `zcli settings set browser <key>`
- zcli validates supported browser keys using lib/validate.sh. If you want zcli to accept your new key, also add it there.
  - Add the key to the BROWSERS list and update browser_cmd_for() if needed:
    ```bash path=null start=null
    # lib/validate.sh
    BROWSERS=(
      "google-chrome" "google-chrome-stable" "firefox" "firefox-esr" "brave" "chromium" "vivaldi" "floorp"
      "thorium"  # add your browser key here
      "ladybird" # add your browser key here
    )

    browser_cmd_for() {
      case "$1" in
        google-chrome|google-chrome-stable) echo "google-chrome-stable" ;;
        brave) echo "brave-browser" ;;
        chromium) echo "chromium" ;;
        vivaldi) echo "vivaldi" ;;
        floorp) echo "floorp" ;;
        thorium) echo "thorium-browser" ;;  # adjust to actual executable name
        ladybird) echo "ladybird" ;;         # adjust to actual executable name
        firefox) echo "firefox" ;;
        firefox-esr) echo "firefox-esr" ;;
        *) echo ""; return 1 ;;
      esac
    }
    ```
- Regardless of zcli, the declarative default browser mapping lives in modules/home/xdg/default-apps.nix. Make sure you updated both places if you rely on zcli to set values interactively.

Special case: Zen
- If you set browser = "zen" or "zen-browser", ensure enableZenBrowser = true in hosts/<host>/variables.nix so the package is added to home.packages.
  ```nix path=null start=null
  enableZenBrowser = true;
  browser = "zen";
  ```

Troubleshooting tips
- If an app still opens a different browser, re-check which .desktop ID your browser actually installs and verify the mapping.
- Rebuild again; Home Manager will re-assert the defaults. Some apps cache handler decisions—restart them after changes.
- Confirm that only one .desktop record for your browser exists and it matches your mapping.


=== Español ===

CÓMO: Agregar un navegador a la lista de soportados (ddubsOS)

Este documento explica cómo ddubsOS establece el navegador predeterminado de forma declarativa y cómo puedes agregar soporte para navegadores nuevos (por ejemplo, Thorium o Ladybird). También indica qué debes cambiar en tu archivo hosts/<host>/variables.nix.

Qué hace este módulo
- Ruta: modules/home/xdg/default-apps.nix
- Importa la configuración por host desde hosts/<host>/variables.nix y lee la clave browser (por defecto, google-chrome-stable).
- Mapea esa clave a un .desktop ID (p. ej., google-chrome-stable -> google-chrome.desktop) y fija los manejadores XDG predeterminados para:
  - x-scheme-handler/http
  - x-scheme-handler/https
  - text/html
  - application/xhtml+xml
- Esto hace que el navegador predeterminado sea declarativo mediante Home Manager, evitando que aplicaciones (como Zen o Discord) sobreescriban de forma permanente ~/.config/mimeapps.list.
- Si eliges Zen (browser = "zen" o "zen-browser"), el módulo exige enableZenBrowser = true para asegurar que el paquete esté instalado.

De dónde obtiene tu configuración
- hosts/<host>/variables.nix contiene una clave como:
  ```nix path=null start=null
  browser = "google-chrome-stable";
  ```
- Si no defines browser, el módulo usa google-chrome-stable por defecto.

Cómo agregar un navegador nuevo (visión general)
1) Instala el navegador (o asegúrate de que se pueda instalar). Puedes añadirlo con Home Manager o como overlay; esta guía se centra en declararlo como predeterminado.
2) Encuentra el .desktop ID que proporciona el paquete del navegador.
   - IDs típicos:
     - google-chrome.desktop, firefox.desktop, chromium.desktop, brave-browser.desktop, vivaldi-stable.desktop, floorp.desktop, etc.
   - Para descubrirlo después de instalar:
     ```sh path=null start=null
     # Busca archivos .desktop del sistema
     grep -R "Name=.*<Nombre de tu navegador>" /run/current-system/sw/share/applications 2>/dev/null | cut -d: -f1 | sort -u

     # O busca por nombres probables
     ls /run/current-system/sw/share/applications | grep -iE "(chrome|thorium|ladybird|browser)"
     ```
     Si se instala sólo para el usuario, los .desktop pueden estar en ~/.nix-profile/share/applications.
3) Actualiza el mapeo en modules/home/xdg/default-apps.nix.
   - Añade una entrada nueva: clave del navegador -> nombre del archivo .desktop.
   - Ejemplo (Thorium, Ladybird):
     ```nix path=null start=null
     browserDesktop = {
       # ...entradas existentes...
       "thorium" = "thorium-browser.desktop";  # confirma el ID real tras instalar
       "ladybird" = "ladybird.desktop";        # confirma el ID real tras instalar
     };
     ```
4) Actualiza el variables.nix de tu host para usar la nueva clave:
   ```nix path=null start=null
   # hosts/<host>/variables.nix
   browser = "thorium";  # o "ladybird"
   ```
5) Reconstruye y verifica:
   ```sh path=null start=null
   # Reconstruye el sistema (ajústalo a tu flujo de trabajo)
   nh os switch   # o: sudo nixos-rebuild switch --flake .#<host>

   # Verifica que los manejadores apunten a tu .desktop
   xdg-mime query default x-scheme-handler/http
   xdg-mime query default x-scheme-handler/https
   xdg-mime query default text/html
   xdg-mime query default application/xhtml+xml
   ```

Si usas `zcli settings set browser <clave>`
- zcli valida las claves soportadas en lib/validate.sh. Si quieres que zcli acepte tu nueva clave, añádela ahí también.
  - Agrega la clave a BROWSERS y actualiza browser_cmd_for() si corresponde:
    ```bash path=null start=null
    # lib/validate.sh
    BROWSERS=(
      "google-chrome" "google-chrome-stable" "firefox" "firefox-esr" "brave" "chromium" "vivaldi" "floorp"
      "thorium"
      "ladybird"
    )

    browser_cmd_for() {
      case "$1" in
        google-chrome|google-chrome-stable) echo "google-chrome-stable" ;;
        brave) echo "brave-browser" ;;
        chromium) echo "chromium" ;;
        vivaldi) echo "vivaldi" ;;
        floorp) echo "floorp" ;;
        thorium) echo "thorium-browser" ;;  # ajusta al ejecutable real
        ladybird) echo "ladybird" ;;         # ajusta al ejecutable real
        firefox) echo "firefox" ;;
        firefox-esr) echo "firefox-esr" ;;
        *) echo ""; return 1 ;;
      esac
    }
    ```
- Independientemente de zcli, el mapeo declarativo del navegador por defecto está en modules/home/xdg/default-apps.nix. Si dependes de zcli para cambiarlo interactivamente, actualiza ambos lugares.

Caso especial: Zen
- Si defines browser = "zen" o "zen-browser", asegúrate de tener enableZenBrowser = true en hosts/<host>/variables.nix para incluir el paquete en home.packages.
  ```nix path=null start=null
  enableZenBrowser = true;
  browser = "zen";
  ```

Consejos de solución de problemas
- Si una aplicación sigue abriendo otro navegador, revisa cuál es el .desktop ID que instala tu navegador y verifica el mapeo.
- Reconstruye otra vez; Home Manager reimpondrá los valores. Algunas apps guardan en caché: reinícialas tras el cambio.
- Confirma que sólo existe un registro .desktop para tu navegador y que coincide con tu mapeo.

