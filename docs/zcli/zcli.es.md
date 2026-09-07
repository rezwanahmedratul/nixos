[English](./zcli.md) | Español

# Utilidad de Línea de Comandos de ddubsOS (zcli) - Versión 1.2.0
zcli es una herramienta práctica para realizar tareas comunes de mantenimiento en tu sistema ddubsOS con un solo comando. A continuación, se presenta una guía detallada sobre su uso y comandos.

## Novedades en la versión 1.2.0

- Selección de panel: panelChoice soporta waybar | noctalia.
  - Establécelo con: `zcli settings set panelChoice <waybar|noctalia>`.
  - Inicio de Hyprland actualizado para lanzar el panel seleccionado; Noctalia se ejecuta con `qs -c noctalia-shell`.
- Integración de Noctalia Shell: la configuración de QuickShell se enlaza en `~/.config/quickshell/noctalia-shell` cuando se selecciona.
- Pistas de ajustes actualizadas para incluir las nuevas opciones de panel.

## Novedades en la versión 1.1.0

- Interfaz de etapa (staging) interactiva antes de reconstruir/actualizar
  - Los comandos de reconstrucción listan archivos sin rastrear/no preparados con índices. Elige números o 'all' para agregarlos, o Enter para omitir.
  - Nuevas banderas:
    - --no-stage: omite el aviso de staging por completo
    - --stage-all: agrega automáticamente todos los archivos sin rastrear/no preparados antes de reconstruir
  - Nuevo comando:
    - zcli stage [--all] — ejecuta el selector interactivo de staging o agrega todo sin reconstruir

## Novedades en la versión 1.0.4

- Edición de ajustes con validación, copias de seguridad y --dry-run
  - zcli settings set <attr> <valor> [--dry-run]
  - Valida las claves de navegador/terminal contra listas soportadas; valida rutas de archivo para stylixImage, waybarChoice, starshipChoice, animChoice
  - Atributos booleanos ahora editables (p. ej., gnomeEnable, enableVscode, enableNFS). Acepta true/false/on/off/yes/no/1/0. Lista con: zcli settings --list-bools
  - Descubrimiento: zcli settings --list-browsers, zcli settings --list-terminals, zcli settings --list-bools
- Resumen de apps por host
  - zcli hosts-apps lista los paquetes específicos del host desde hosts/<host>/host-packages.nix
- Comodidad
  - zcli upgrade es un alias de zcli update
- Refactor interno (sin acciones para el usuario)
  - El despachador generado en modules/home/scripts/zcli.nix carga módulos de funciones (features/*) y bibliotecas compartidas (lib/*)

### Ejemplos de uso de settings

```bash
# Descubrir claves soportadas
zcli settings --list-browsers
zcli settings --list-terminals
zcli settings --list-bools

# Establecer navegador y terminal
zcli settings set browser google-chrome-stable
zcli settings set terminal kitty

# Establecer panel (waybar | noctalia)
zcli settings set panelChoice noctalia

# Establecer atributos booleanos (acepta true/false/on/off/yes/no/1/0)
zcli settings set gnomeEnable true
zcli settings set enableVscode off
zcli settings set thunarEnable yes --dry-run

# Simulación (no escribe cambios)
zcli settings set browser firefox --dry-run

# Establecer atributos basados en archivos (rutas absolutas o relativas al repo)
 zcli settings set stylixImage ~/ddubsos/wallpapers/AnimeGirlNightSky.jpg
 zcli settings set waybarChoice modules/home/waybar/waybar-ddubs.nix
 zcli settings set starshipChoice modules/home/cli/starship-rbmcg.nix
 zcli settings set animChoice modules/home/hyprland/animations-end-slide.nix
```

Resguardos y autoactivaciones
- Navegador: al establecer `browser`, zcli verifica que el comando correspondiente exista en PATH. Si no está instalado, muestra un error y no actualiza el valor.
- Terminal: al establecer `terminal`, zcli autoactiva las banderas correspondientes cuando aplica (respeta `--dry-run`):
  - alacritty → enableAlacritty = true
  - ptyxis → enablePtyxis = true
  - wezterm → enableWezterm = true
  - ghostty → enableGhostty = true

#### Atributos booleanos editables

- Escritorios: gnomeEnable, dwmEnable
- Editores y terminales: enableEvilhelix, enableVscode, enableMicro, enableAlacritty, enableTmux, enablePtyxis, enableWezterm, enableGhostty
- Sistema y servicios: enableDevEnv, sddmWaylandEnable, enableOpencode, enableObs, clock24h, enableNFS, printEnable, thunarEnable, enableGlances

Consejo: lista en tu sistema con: zcli settings --list-bools

## Uso

Ejecuta la utilidad con un comando específico:

`zcli`

Si no se proporciona ningún comando, muestra este mensaje de ayuda.

## Comandos Disponibles

Aquí tienes una tabla de referencia rápida para todos los comandos, seguida de descripciones detalladas:

| Comando     | Icono | Descripción                                                                                                                                           | Ejemplo de Uso                          |
| ----------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| cleanup     | 🧹   | Elimina generaciones antiguas del sistema, ya sea todas o especificando un número a conservar, ayudando a liberar espacio.                                                  | `zcli cleanup` (pregunta si todas o un #)  |
| diag        | 🛠️   | Genera un informe de diagnóstico del sistema y lo guarda en `diag.txt` en tu directorio de inicio.                                                               | `zcli diag`                             |
| doom        | 🔥   | Gestiona la instalación de Doom Emacs: instala, comprueba el estado, elimina o actualiza Doom Emacs.                                                                | `zcli doom install`                     |
| glances     | 📊   | Gestiona el servidor de monitoreo Glances basado en Docker: inicia, detiene, reinicia, comprueba el estado o ve los registros.                                                     | `zcli glances start`                    |
| list-gens   | 📋   | Lista las generaciones de usuario y del sistema, mostrando las activas y existentes.                                                                                  | `zcli list-gens`                        |
|| rebuild     | 🔨   | Reconstruye la configuración del sistema NixOS. Ahora ofrece un aviso interactivo para preparar (staging) cambios antes de compilar.                                        | `zcli rebuild`                          |
| trim        | ✂️   | Recorta los sistemas de archivos para mejorar el rendimiento de los SSD y optimizar el almacenamiento.                                                                                    | `zcli trim`                             |
|| update      | 🔄   | Actualiza el flake y reconstruye el sistema. Ahora ofrece un aviso interactivo para preparar (staging) cambios antes de compilar.                      | `zcli update`                           |
|| update-host | 🏠   | Establece automáticamente el host y el perfil en tu archivo `flake.nix` según el sistema actual. Detecta el tipo de GPU o solicita la entrada si es necesario. | `zcli update-host [hostname] [profile]` |
|| update-warp | ⚡   | Actualiza el Warp Terminal (actual) "vendorizado" en este repositorio a la última versión; recalcula el SRI y actualiza versions.json. Opción --commit para auto-commit. | `zcli update-warp [--commit]` |
|| stage       | ✅   | Prepara (staging) cambios de forma interactiva (o usa --all para preparar todo) sin reconstruir.                                                        | `zcli stage`, `zcli stage --all`        |

## Descripciones Detalladas de los Comandos

- **🧹 cleanup**: Este comando ayuda a gestionar el almacenamiento del sistema eliminando generaciones antiguas. Puedes eliminar todas las generaciones o especificar un número a conservar (p. ej., `zcli cleanup` libera espacio y elimina las entradas del menú de arranque).

- **🛠️ diag**: Crea un informe de diagnóstico completo ejecutando `inxi --full` y guardando la salida en `diag.txt` en tu directorio de inicio. Es ideal para solucionar problemas o compartir detalles del sistema al informar de problemas.

- **📋 list-gens**: Muestra una lista clara de tus generaciones de usuario y del sistema actuales, incluidas las activas. Esto te permite revisar lo que está instalado y planificar limpiezas.

- **🔨 rebuild**: Realiza una reconstrucción del sistema para NixOS comprobando primero si hay archivos que puedan impedir que Home Manager complete el proceso. Es similar a las funciones de reconstrucción estándar pero con salvaguardas adicionales.

- **✂️ trim**: Optimiza tus sistemas de archivos, especialmente para SSD, para mejorar el rendimiento y reducir el desgaste. Ejecuta esto regularmente como parte de tu rutina de mantenimiento.

- **🔄 update**: Agiliza las actualizaciones comprobando posibles problemas con Home Manager, luego actualiza el flake y reconstruye el sistema. Esto combina las actualizaciones del flake y las reconstrucciones en un solo paso eficiente.

- **🏠 update-host**: Simplifica la gestión de múltiples hosts actualizando automáticamente el `hostname` y el `profile` en tu archivo `~/ddubsos/flake.nix`. Intenta detectar tu tipo de GPU; si falla, se te pedirá que introduzcas los detalles manualmente.

- **⚡ update-warp**: Actualiza el empaquetado de Warp Terminal (actual) "vendorizado" dentro de este repositorio.
  - Sube a la última versión de Warp siguiendo las redirecciones de descarga.
  - Recalcula los hashes SRI y actualiza pkgs/warp-terminal-current/versions.json.
  - Opción `--commit` realizará automáticamente el commit del archivo versions.
  - Reconstruye después con `zcli rebuild`.

## Notas de Emacs

- Emacs ahora se gestiona como una característica estándar mediante Home Manager (sin subcomandos de zcli).
- El servicio de usuario (daemon) de Emacs está habilitado; usa emacsclient para inicio rápido:
  - GUI: `emacsclient -c -n -a ""`
  - TTY: `et` (wrapper que prefiere truecolor vía xterm-direct/tmux-direct) o `emacsclient -t -a ""`
- Los paquetes/autoloads de Doom se sincronizan automáticamente en la activación de Home Manager (`doom sync -u`).
- La instalación inicial se realiza automáticamente durante la activación; si no hay red, reintenta en la próxima activación.

## Gestión del Servidor Glances

El comando `glances` proporciona gestión del servidor de monitoreo del sistema basado en Docker:

- **📊 glances start**: Inicia el servidor de monitoreo Glances en un contenedor Docker. El servidor será accesible a través de una interfaz web para el monitoreo del sistema en tiempo real.

- **📊 glances stop**: Detiene el contenedor Docker del servidor Glances en ejecución, apagando el servicio de monitoreo.

- **📊 glances restart**: Reinicia el servidor Glances deteniendo y luego iniciando el contenedor Docker. Útil para aplicar cambios de configuración.

- **📊 glances status**: Muestra el estado actual del servidor Glances, incluyendo si está en ejecución y proporciona las URL de acceso. Muestra los puntos de acceso locales, de red y basados en el nombre de host para la interfaz web (normalmente en el puerto 61210).

- **📊 glances logs**: Muestra los registros del contenedor Docker para el servidor Glances, útil para solucionar problemas o monitorear la actividad del servidor.

**Nota**: La gestión del servidor Glances requiere que el módulo `glances-server.nix` esté habilitado en la configuración de tu sistema. El servidor proporciona una interfaz basada en web para monitorear los recursos del sistema, los procesos y la actividad de la red.

## Parámetros Opcionales para los Comandos de Compilación

Los comandos `rebuild`, `rebuild-boot` y `update` admiten parámetros opcionales adicionales para personalizar el proceso de compilación:

### Opciones Disponibles:

- **--dry, -n**: Muestra lo que se haría sin ejecutar realmente los cambios. Perfecto para previsualizar actualizaciones o reconstrucciones antes de confirmarlas.

- **--ask, -a**: Habilita las solicitudes de confirmación antes de proceder con la operación. Proporciona una capa de seguridad adicional para los cambios en el sistema.

- **--cores N**: Limita el proceso de compilación para usar solo N núcleos de CPU. Esto es particularmente útil para máquinas virtuales o sistemas donde deseas conservar recursos para otras tareas.

- **--verbose, -v**: Habilita una salida detallada durante el proceso de compilación, mostrando más información sobre lo que está sucediendo durante las actualizaciones del sistema.

- **--no-nom**: Desactiva la herramienta nix-output-monitor, volviendo a la salida estándar de Nix. Útil si prefieres la salida de compilación tradicional o encuentras problemas con el monitor de salida.
- **--no-stage**: Omite el aviso de staging (no prepara nada antes de compilar).
- **--stage-all**: Prepara automáticamente todos los archivos sin rastrear/no preparados antes de compilar.

### Ejemplos de Uso:

```bash
# Ejecución en seco para ver qué se actualizaría
zcli update --dry

# Reconstruir con solicitudes de confirmación y limitado a 2 núcleos de CPU
zcli rebuild --ask --cores 2

# Actualización detallada sin nix-output-monitor
zcli update --verbose --no-nom

# Combinar múltiples opciones
zcli rebuild-boot --dry --ask --verbose
```

Estas opciones proporcionan flexibilidad y control sobre las operaciones del sistema, permitiéndote personalizar el proceso de compilación según tus necesidades específicas y las limitaciones del sistema.

## Notas Adicionales

- **¿Por qué usar zcli?** Esta utilidad ahorra tiempo en tareas rutinarias, reduciendo la necesidad de múltiples comandos o ediciones manuales.
- **Versión y Compatibilidad:** Asegúrate de estar utilizando la última versión (1.2.0 según el código fuente). Para cualquier problema, genera un informe de diagnóstico con `zcli diag` y consulta los registros de tu sistema.
