[English](./project-guide.md) | Español

# Guía de Trabajo de ddubsOS (resumen)

Este documento resume los comandos clave de zcli y opciones útiles. Para la guía completa, consulta docs/project-guide.md y docs/zcli.es.md.

## Compilación y Operaciones (zcli)

- Ubicación: modules/home/scripts/zcli.nix (instalado como script; ver docs/zcli.es.md para ayuda completa)
- Comandos comunes:
  - zcli rebuild: reconstruye el sistema (ahora ofrece un aviso interactivo para preparar cambios antes de compilar)
  - zcli rebuild-boot: reconstruye y activa en el próximo reinicio (recomendado para cambios mayores)
  - zcli update: actualiza el flake y reconstruye (también ofrece el aviso de staging)
  - zcli stage [--all]: prepara (staging) cambios de forma interactiva o agrega todo sin reconstruir
  - zcli update-host [hostname] [profile]: reescribe host y profile en flake.nix (auto-detecta profile si se omite)
  - zcli add-host [hostname] [profile?]: copia hosts/default en hosts/<hostname> y opcionalmente genera hardware.nix
  - zcli del-host <hostname>: elimina hosts/<hostname>
  - zcli doom <install|status|remove|update>
  - zcli glances <start|stop|restart|status|logs>
  - zcli list-gens, trim, diag, cleanup
- Banderas opcionales para rebuild/rebuild-boot/update:
  - --dry/-n, --ask/-a, --cores N, --verbose/-v, --no-nom, --no-stage, --stage-all

Notas:
- El aviso de staging lista archivos sin rastrear/no preparados con índices; puedes elegir números o 'all' para agregarlos, Enter para omitir.
- Usa zcli stage para ejecutar la selección sin reconstruir.

<!--
Author: Don Williams (aka ddubs)
Created: 2025-08-27
Project: git@gitlab.com:dwilliam62/ddubsos
-->

Español | [English](./project-guide.md)

# Guía de Trabajo ddubsOS

Generado: 2025-08-28 Alcance: Orientación rápida para trabajar en ddubsOS;
optimizada para personas e IA.

Enlaces Rápidos

- Descripción general: ../README.md
- TL;DR: #tldr-contexto-rapido-para-ia
- Estructura del repo: #estructura-del-repositorio-esenciales
- Modelo de configuración: #modelo-de-configuracion
- Variables por host: #variables-por-host-hostshostvariablesnix
- Entrada de Home Manager: #entrada-de-home-manager-moduleshomedefaultnix
- Mecánica de importación:
  #como-se-seleccionan-las-importaciones-modelo-mental-rapido
- Inicio de Hyprland:
  #flujo-de-inicio-de-hyprland-moduleshomehyprlandexec-oncenix
- zcli: #construccion-y-operacion-zcli
- Script de instalación: #script-de-instalacion-install-ddubsossh
- Paquetes: #paquetes
- Controladores/Perfiles: #controladores-y-perfiles
- Temas: #temas-y-estilo
- Entornos de desarrollo: #entornos-de-desarrollo-opcional
- Recetas: #recetas-de-tareas-comunes
- Solución de problemas: #solucion-de-problemas-y-consideraciones
- Convenciones: #convenciones-y-notas
- Docs útiles: #documentacion-util
- Patrón RW (HM copia/sync-back): #patron-rw-home-manager-copia--sync-back
- Para asistentes de IA: #si-eres-un-asistente-de-ia

Novedades

- 2025-09-06: Paquetes externos vía overlay
  - Se añadió un overlay de nixpkgs (modules/core/overlays.nix) que expone ciertos inputs del flake como pkgs: wfetch.
  - Se refactorizaron los módulos para consumirlos solo vía pkgs (sin inputs.* en módulos). Mejora la reutilización y la composabilidad.
  - Futuras adiciones (p. ej., quickshell) deben seguir este método: añadir al overlay y referenciar como pkgs.<nombre>.
- 2025-08-29: Limpieza del flake y refuerzo de seguridad
  - Deduplicación de nixosConfigurations mediante el helper mkNixosConfig (perfiles: amd, intel, nvidia, nvidia-laptop, vm)
  - Se mantiene una variable profile en el let superior (flake.nix) usada por el instalador y zcli; los módulos la reciben vía specialArgs.profile
  - Se mueve permittedInsecurePackages únicamente a hosts/macbook (Broadcom STA) en lugar de global en el flake
  - Se elimina el input nixpkgs-stable no utilizado; Audacity compila desde el canal principal

TL;DR (Contexto rápido para IA)

- Tipo de proyecto: NixOS flake con Home Manager (multi-host, multi-perfil)
- Punto de entrada: flake.nix
- Perfiles (drivers/características): amd, intel, nvidia, nvidia-laptop, vm
- Selección de host: en flake.nix (host, profile, username)
- Estructura del flake: un helper mkNixosConfig construye cada nixosConfiguration; un profile definido en el let se pasa a los módulos vía specialArgs.profile (el instalador/zcli lo actualizan)
- Config por host:
  hosts/<host>/{hardware.nix,default.nix,variables.nix,host-packages.nix}
- Entrada de Home: modules/home/default.nix (importa módulos condicionalmente
  vía variables del host)
- Conmutadores clave: definidos en hosts/<host>/variables.nix (DEs, editores,
  terminales, dev-env, panel, waybar, animaciones, valores por defecto)
- Comandos de build: usar zcli (rebuild, rebuild-boot, update, update-host,
  add-host, del-host)
- Paneles: waybar o noctalia; arranque en
  modules/home/hyprland/exec-once.nix con fondo de pantalla de respaldo
- Entornos de dev: devenv + direnv (opcional; activar con enableDevEnv)
- Paquetes: del sistema en modules/core/{req-packages.nix,global-packages.nix} y
  por host en hosts/<host>/host-packages.nix
- Docs siguientes: docs/zcli.md, docs/devenv-usage.md, FAQ.md, README.md

Estructura del repositorio (esenciales)

- flake.nix: inputs, nixosConfigurations (perfiles), valores por defecto de
  host/profile/username
- profiles/: configuración NixOS por GPU/rol (amd, intel, nvidia, nvidia-laptop,
  vm)
- hosts/<host>/
  - hardware.nix: generado por máquina
  - default.nix: importa hardware.nix y host-packages.nix
  - host-packages.nix: paquetes por host
  - variables.nix: panel de interruptores para este host
- hosts/default/*: plantillas para nuevos hosts (usa el script de instalación y
  zcli add-host). Editar hosts/default/variables.nix define por defecto futuros
  hosts.
- modules/
  - core/: configuración base del sistema (system.nix, seguridad, servicios,
    drivers, etc.)
  - home/: módulos de Home Manager (hyprland, editores, terminales, shells,
    scripts, etc.)
  - drivers/: Nvidia/AMD/Intel/VM, prime, guest tools
- docs/: documentación adicional (zcli.md, devenv-usage.md, ...)
- cheatsheets/: chuletas de uso (tmux, wezterm, kitty, etc.)

Modelo de configuración

- Inputs del flake: nixpkgs inestable, catppuccin, wfetch, chaotic, garuda, home-manager, nix-flatpak.
  - Nota: nixpkgs-stable estuvo fijado para Audacity (julio 2025) pero se eliminó; Audacity compila ahora desde el canal principal. Si en el futuro necesitas fijar algo a estable, ver guía abajo.
- nixosConfigurations: construido con el helper mkNixosConfig para cinco perfiles (amd, intel, nvidia, nvidia-laptop, vm). Cada perfil incluye:
  - ./modules/nix-caches.nix
  - ./profiles/<profile>
  - ./modules/home/suckless/dwm-session.nix
  - inputs.catppuccin.nixosModules.catppuccin
  - nix-flatpak.nixosModules.nix-flatpak
- nixpkgs.config global:
  - allowUnfree = true se establece con un pequeño módulo inline dentro de mkNixosConfig (no al importar pkgs en el flake)
  - permittedInsecurePackages no se define globalmente; solo hosts/macbook lo habilita (Broadcom STA) desde su default.nix
- flake.nix define system = x86_64-linux, host, profile, username. El instalador y zcli update-host reescriben host/profile en su lugar.

Variables por host (hosts/<host>/variables.nix)

- UI/panel
  - panelChoice: "waybar" o "noctalia"
  - waybarChoice: elige un archivo nix de waybar (p.ej., waybar-ddubs-2.nix)
  - stylixImage: ruta del fondo usada por waypaper
  - clock24h: reloj 24h en waybar
- Entornos de escritorio (importados condicionalmente en
  modules/home/default.nix)
  - gnomeEnable, dwmEnable
- Editores (condicional)
  - enableEvilhelix, enableVscode; NVF y Doom Emacs están incluidos por defecto
- Terminales (condicional)
  - enableAlacritty, enableTmux, enablePtyxis; terminales base (foot, kitty,
    ghostty, wezterm) siempre importados
- Herramientas de desarrollo
  - enableDevEnv: habilita devenv + direnv e incluye herramientas
  - enableOpencode: utilidad CLI de IA opcional
- Sistema/Apps
  - browser: navegador predeterminado (p. ej., google-chrome-stable)
  - terminal: terminal predeterminado (p. ej., ghostty)
  - starshipChoice: elige un archivo de configuración de Starship (p. ej., modules/home/cli/starship.nix; alternativas: starship-1.nix, starship-rbmcg.nix)
  - keyboardLayout, consoleKeyMap
  - enableGlances, enableNFS, printEnable, thunarEnable
- Hyprland
  - waybarChoice, animChoice, extraMonitorSettings, hostId (ZFS)

Entrada de Home Manager (modules/home/default.nix)

- Importa siempre: amfora, gtk, qt, scripts, stylix, wlogout, hyprland,
  gui-apps, shells (bash, fish, zsh, eza, zoxide), utilidades CLI,
  gh, yazi, terminals/default.nix, nvf.nix, módulos de Doom Emacs.
- Importa condicionalmente según variables del host: DEs
  (gnome/dwm), editores (evil-helix, vscode), terminales
  extra (alacritty, tmux, ptyxis), opencode, dev-env.
- La importación del prompt Starship ahora está controlada por la variable basada en archivo starshipChoice; se eliminó la importación incondicional de Starship desde modules/home/cli/default.nix. Establece starshipChoice en hosts/<host>/variables.nix para seleccionar una configuración.

Cómo se seleccionan las importaciones (modelo mental rápido)

- modules/home/default.nix lee los conmutadores del host: inherit (import
  ../../hosts/${host}/variables.nix) ...;
- Siempre importa una base y añade módulos cuando la variable correspondiente es
  true.
- Ejemplos:
  - gnomeEnable -> ./gui/gnome.nix
  - dwmEnable -> ./suckless/default.nix
- hosts/<host>/variables.nix es el panel de control de módulos de Home Manager.
- Variables basadas en archivo como waybarChoice y starshipChoice apuntan directamente a módulos Nix que se importan. Ejemplo: waybarChoice = ../../modules/home/waybar/waybar-ddubs-2.nix; starshipChoice = ../../modules/home/cli/starship-rbmcg.nix;

Flujo de inicio de Hyprland (modules/home/hyprland/exec-once.nix)

- Tareas comunes: cliphist, export DBUS, hyprpolkitagent, matar notifiers en
  conflicto (dunst/mako).
- Ramas por panel:
  - noctalia: detener barras/notificaciones en conflicto y lanzar noctalia-shell
  - waybar: iniciar awww + waybar y restaurar fondo con fallback a
    waypaper + stylixImage; nm-applet --indicator
- Después del panel: qs overview + DropTerminal

Construcción y operación (zcli)

- Ubicación: modules/home/scripts/zcli.nix (instalado como script; ver
  docs/zcli.md)
- Comandos comunes:
  - zcli rebuild, zcli rebuild-boot, zcli update
  - zcli update-host [hostname] [profile]
  - zcli add-host [hostname] [profile?]
  - zcli del-host <hostname>
  - zcli glances <start|stop|restart|status|logs>
  - zcli list-gens, trim, diag, cleanup
- Flags: --dry/-n, --ask/-a, --cores N, --verbose/-v, --no-nom
- Limpieza de backups: elimina ficheros problemáticos (p.ej.,
  ~/.config/mimeapps.list.backup) antes de rebuilds.

Script de instalación (install-ddubsos.sh)

- Propósito: arrancar en una máquina NixOS fresca
- Flujo (resumen): detectar GPU, crear hosts/<hostname>, actualizar flake.nix
  (host/profile/username), configurar zona horaria/teclado, generar
  hardware.nix, ejecutar nixos-rebuild boot con el perfil.
- Tras éxito: reinicia para activar

Paquetes

- Esenciales: modules/core/req-packages.nix (incluye wfetch vía overlay; no se referencian inputs directamente)
- Globales opcionales: modules/core/global-packages.nix
- Por host: hosts/<host>/host-packages.nix
- Patrón de overlay para paquetes externos:
  - Los inputs externos que proveen paquetes deben exponerse a través de modules/core/overlays.nix para que aparezcan bajo pkgs (p. ej., pkgs.wfetch).
  - Los módulos deben referenciar solo pkgs.<nombre>, no inputs.*. Esto desacopla los módulos del cableado del flake y mejora la reutilización.
  - Para añadir un paquete externo nuevo (ejemplo: quickshell):
    1) Edita modules/core/overlays.nix y mapea inputs.quickshell.packages.${final.system}.default a un atributo (p. ej., quickshell = ...)
    2) Úsalo en módulos vía pkgs.quickshell (p. ej., en environment.systemPackages)
- Dónde añadir paquetes locales:
  - Para todos los sistemas: req-packages.nix (esenciales), global-packages.nix (complementarios)
  - Para una máquina: hosts/<host>/host-packages.nix
- Nota sobre pinning estable:
  - Se eliminó el input nixpkgs-stable. Si necesitas un paquete estable específico en el futuro, reintrodúcelo en flake.nix, expón pkgsStable vía specialArgs y usa selectivamente pkgsStable.<pkg> en un módulo o archivo de host.

Controladores y perfiles

- modules/drivers/: amd, intel, nvidia, nvidia-prime, vm
- profiles/: selecciona el stack adecuado
- Flujos de selección:
  - Las keys de nixosConfigurations (amd, intel, nvidia, nvidia-laptop, vm) deciden qué directorio de perfil se incluye
  - Un profile separado en el let de flake.nix se pasa a los módulos vía specialArgs.profile; el instalador y zcli lo modifican como parte de las actualizaciones del host
- Cambiar de perfil:
  - zcli update-host <hostname> <profile> (recomendado) o edita flake.nix manualmente
  - Reconstruye con zcli rebuild (o zcli rebuild-boot)
- Paquetes inseguros por host (ejemplo: Broadcom STA en macbook)
  - Solo hosts/macbook habilita nixpkgs.config.permittedInsecurePackages = [ "broadcom-sta-6.30.223.271-57-6.12.43" ]
  - Consejo: estas cadenas pueden cambiar con bumps de kernel; actualízalas cuando sea necesario

Temas y estilo

- Stylix + catppuccin, stylixImage respaldo
- Varios waybar en modules/home/waybar/
- Selección de prompt de Starship vía starshipChoice; configuraciones en modules/home/cli/
- Animaciones de Hyprland via animChoice

Entornos de desarrollo (opcional)

- Activar en hosts/<host>/variables.nix: enableDevEnv = true;
- Incluye direnv + nix-direnv, devenv CLI, plantillas (Python/Node/Rust)
- Ver docs/devenv-usage.md

Recetas de tareas comunes

- Cambiar a waybar
  - Edita hosts/<host>/variables.nix: panelChoice = "waybar"; ajusta
    waybarChoice
  - zcli rebuild (o zcli rebuild-boot)
- Cambiar terminal/navegador por defecto
  - terminal = "kitty"; browser = "google-chrome-stable" (u otros)
  - zcli rebuild
- Cambiar el prompt de Starship
  - zcli settings set starshipChoice modules/home/cli/starship-rbmcg.nix
    (o edita hosts/<host>/variables.nix y ajusta starshipChoice)
  - zcli rebuild
- Activar editor/terminal específicos
  - enableEvilhelix/enableVscode/enableAlacritty/enableTmux/enablePtyxis = true
  - zcli rebuild
- Crear un host nuevo
  - zcli add-host <hostname> [profile?]
  - zcli update-host <hostname> <profile>
  - zcli rebuild (en la máquina destino)
- Actualizar el sistema
  - zcli update --ask --verbose
- Cambio mayor más seguro
  - zcli rebuild-boot (aplica tras reinicio)

Solución de problemas y consideraciones

- Bloqueos de Home Manager por backups
  - zcli limpia backups comunes automáticamente
- Fondo de pantalla no se aplica
  - Hay respaldo con waypaper + awww y stylixImage
- Problemas de GPU
  - Verifica que el perfil en flake.nix coincide o usa zcli update-host
- Kernel CachyOS + v4l2loopback (clang) no compila
  - Consulta docs/Cachy-kernel-v4l2loopback-build-issues.md para la solución y el porqué
- Hostname "default"
  - No usar; el script de instalación lo advierte
- Perfil de energía
  - cpuFreqGovernor = "performance" en modules/core/system.nix; ajusta si hace
    falta

Convenciones y notas

- Variables de entorno: NIXOS_OZONE_WL=1, DDUBSOS_VERSION=2.Next, DDUBSOS=true
- Ajustes de Nix: flakes + nix-command; usuarios de confianza @wheel
- Zona horaria, locales, consoleKeyMap en system.nix
- Formato: Nix conforme a nixfmt en general

Patrón RW (Home Manager copia & sync-back)

- Descripción: Algunas apps/paneles se benefician de tener configuración escribible sin symlinks. Usamos activación de Home Manager para:
  - Sincronizar cambios en vivo desde ~/.config/<app> de vuelta al repo (modules/home/<app-dir>)
  - Respaldar ~/.config/<app> a una carpeta con timestamp
  - Copiar el contenido del repo a ~/.config/<app> como archivos normales (RW), y luego chmod -R u+w
- Notas:
  - Es un patrón pragmático para setups personales donde la reproducibilidad absoluta no es requisito.

Documentación útil

- docs/zcli.md
- docs/Cachy-kernel-v4l2loopback-build-issues.md: Solución para v4l2loopback con el kernel CachyOS (clang)
- docs/devenv-usage.md
- README.md (descripción general del proyecto)
- FAQ.md
- CHANGELOG.ddubs.md

Si eres un asistente de IA

- Revisa flake.nix para host/profile/username actuales
- Lee hosts/<host>/variables.nix para conmutadores relevantes
- Prefiere zcli para rebuild/update y cambios de host
- Usa patrones/modularidad existentes al editar
- Para archivos grandes, pide rangos explícitos; evita paginadores en git log

Fin de la guía.
