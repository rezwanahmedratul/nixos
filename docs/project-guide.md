English | [Español](./project-guide.es.md)

# ddubsOS Working Guide

Generated: 2025-08-28 Scope: Quick orientation for working on ddubsOS; optimized
for both humans and AI assistants.

Quick Links

- Overview: ../README.md
- TL;DR: #tldr-ai-quick-context
- Repo Layout: #repository-layout-essentials
- Config Model: #configuration-model
- Host Variables: #per-host-variables-hostshostvariablesnix
- Home Manager Entry: #home-manager-entry-moduleshomedefaultnix
- Import Mechanics: #how-imports-are-selected-quick-mental-model
- Hyprland Startup: #hyprland-startup-flow-moduleshomehyprlandexec-oncenix
- zcli: #build-and-ops-zcli
- Install Script: #install-script-install-ddubsossh
- Packages: #packages
- Drivers/Profiles: #drivers-and-profiles
- Theming: #theming-and-styling
- Dev Environments: #dev-environments-optional
- Recipes: #common-task-recipes
- Troubleshooting: #troubleshooting--gotchas
- Conventions: #conventions--notes
- Useful Docs: #useful-docs
- RW Config Pattern (HM copy/sync-back): #rw-config-pattern-home-manager-copy--sync-back
- For AI assistants: #if-you-are-an-ai-assistant

What’s New

- 2025-09-06: Overlay-based external packages
  - Added a nixpkgs overlay (modules/core/overlays.nix) that exposes selected flake inputs as pkgs: wfetch.
  - Refactored modules to consume these via pkgs only (no inputs.* in modules). This improves reusability and composability.
  - Future additions (e.g., quickshell) should be added to the overlay and then referenced as pkgs.<name>.
- 2025-08-29: Flake cleanup and safety hardening
  - Deduplicated nixosConfigurations via mkNixosConfig helper (profiles: amd, intel, nvidia, nvidia-laptop, vm)
  - Preserved a top-level profile variable used by installer and zcli; modules receive it via specialArgs.profile
  - Moved permittedInsecurePackages to hosts/macbook only (Broadcom STA) instead of globally in flake
  - Removed unused nixpkgs-stable input; Audacity builds from primary nixpkgs

TL;DR (AI Quick Context)

- Project type: NixOS flake with Home Manager (multi-host, multi-profile)
- Entry point: flake.nix
- Profiles (select drivers/features): amd, intel, nvidia, nvidia-laptop, vm
- Host selection: set in flake.nix (host, profile, username)
- Flake structure: mkNixosConfig helper builds each nixosConfiguration; a let-bound profile is passed to modules via specialArgs.profile (installer/zcli update this)
- Per-host config:
  hosts/<host>/{hardware.nix,default.nix,variables.nix,host-packages.nix}
- Home config entry: modules/home/default.nix (imports most modules
  conditionally via host variables)
- Key toggles: defined in hosts/<host>/variables.nix (DEs, editors, terminals,
  dev-env, panel choice, waybar choice, animation choice, defaults)
- Build commands: use zcli (rebuild, rebuild-boot, update, update-host,
  add-host, del-host)
- Panels: waybar or noctalia; startup logic in
  modules/home/hyprland/exec-once.nix with wallpaper fallback
- Dev environments: devenv + direnv integrated (optional; enable via
  enableDevEnv)
- Packages: system-wide in modules/core/{req-packages.nix,global-packages.nix}
  and per-host in hosts/<host>/host-packages.nix
- Docs to read next: docs/zcli.md, docs/devenv-usage.md, FAQ.md, README.md

Repository Layout (essentials)

- flake.nix: inputs, nixosConfigurations (profiles), defaults for
  host/profile/username
- profiles/: profile-specific NixOS config by GPU/role (amd, intel, nvidia,
  nvidia-laptop, vm)
- hosts/<host>/
  - hardware.nix: generated per machine
  - default.nix: imports hardware.nix and host-packages.nix
  - host-packages.nix: per-host packages
  - variables.nix: the main toggle hub for this host
- hosts/default/*: template files for new hosts (used by install script and zcli
  add-host). Editing hosts/default/variables.nix sets defaults for future hosts.
- modules/
  - core/: base system configuration (system.nix, security, services, drivers,
    etc.)
  - home/: Home Manager modules (hyprland, editors, terminals, shells, scripts,
    etc.)
  - drivers/: Nvidia/AMD/Intel/VM, prime, guest tools
- docs/: additional project docs (zcli.md, devenv-usage.md, ...)
- cheatsheets/: usage cheatsheets for apps (tmux, wezterm, kitty, etc.)

Configuration Model

- Flake inputs: unstable nixpkgs, catppuccin, wfetch, chaotic, garuda, home-manager, nix-flatpak.
  - Note: nixpkgs-stable was previously pinned for Audacity (July 2025) but has been removed; Audacity now builds from the primary channel. If a future package needs stable pinning, see guidance below.
- nixosConfigurations: built via mkNixosConfig helper for five profiles (amd, intel, nvidia, nvidia-laptop, vm). Each profile’s module stack includes:
  - ./modules/nix-caches.nix
  - ./profiles/<profile>
  - ./modules/home/suckless/dwm-session.nix
  - inputs.catppuccin.nixosModules.catppuccin
  - nix-flatpak.nixosModules.nix-flatpak
- Global nixpkgs.config:
  - allowUnfree = true is set via a tiny inline module within mkNixosConfig (not at flake pkgs import time)
  - permittedInsecurePackages is not set globally; it is enabled only on hosts/macbook (Broadcom STA) via that host’s default.nix
- Defaults (flake.nix) define system = x86_64-linux, host, profile, username. The installer and zcli update-host rewrite host/profile in place.

Per-host Variables (hosts/<host>/variables.nix)

- UI/panel
  - panelChoice: "waybar" or "noctalia"
  - waybarChoice: pick a waybar config nix file (e.g., waybar-ddubs-2.nix)
  - stylixImage: wallpaper path used as fallback by waypaper
  - clock24h: boolean for waybar clock format
- Desktop environments (conditionally imported in modules/home/default.nix)
  - gnomeEnable, dwmEnable
- Editors (conditional)
  - enableEvilhelix, enableVscode; NVF and Doom Emacs are included by default
    modules
- Terminals (conditional)
  - enableAlacritty, enableTmux, enablePtyxis; core terminals (foot, kitty,
    ghostty, wezterm) are always imported by default
- Development tooling
  - enableDevEnv: enables devenv + direnv integration and dev tools
  - enableOpencode: optional CLI AI utility
- System/Apps
  - browser: default browser (e.g., google-chrome-stable)
  - terminal: default terminal (e.g., ghostty)
  - starshipChoice: choose a Starship prompt config nix file (e.g., modules/home/cli/starship.nix; alternatives: starship-1.nix, starship-rbmcg.nix)
  - keyboardLayout, consoleKeyMap
  - enableGlances: enable glances server module
  - enableNFS, printEnable, thunarEnable
- Hyprland specifics
  - waybarChoice: choose a waybar module
  - animChoice: choose animation module (dynamic, end4, end4-slide, moving, def)
  - extraMonitorSettings: additional monitor lines
  - hostId: for ZFS

Home Manager Entry (modules/home/default.nix)

- Unconditionally imports: amfora, gtk, qt, scripts, stylix, wlogout, hyprland,
  gui-apps, shells (bash, fish, zsh, eza, zoxide), CLI utils, gh,
  yazi, terminals/default.nix, nvf.nix, Doom Emacs modules.
- Conditionally imports based on variables (from hosts/<host>/variables.nix):
  DEs (gnome/dwm), editors (evil-helix, vscode), extra
  terminals (alacritty, tmux, ptyxis), opencode, dev-env.
- Starship prompt import is controlled by the file-backed variable starshipChoice; the old unconditional Starship import from modules/home/cli/default.nix was removed. Set starshipChoice in hosts/<host>/variables.nix to select a prompt config.

How imports are selected (quick mental model)

- modules/home/default.nix reads the current host’s toggles via: inherit (import
  ../../hosts/${host}/variables.nix) ...;
- It always imports a base set of modules, then conditionally appends modules
  when a corresponding toggle is true.
- Examples from modules/home/default.nix:
  - gnomeEnable -> imports ./gui/gnome.nix
  - dwmEnable -> imports ./suckless/default.nix
- The variable file hosts/<host>/variables.nix is therefore the switchboard that
  controls which Home Manager modules are active for that host.
- File-backed variables like waybarChoice and starshipChoice point directly to Nix modules which are imported. Example: waybarChoice = ../../modules/home/waybar/waybar-ddubs-2.nix; starshipChoice = ../../modules/home/cli/starship-rbmcg.nix;

Hyprland Startup Flow (modules/home/hyprland/exec-once.nix)

- Common background tasks: cliphist (text+image), dbus env export, start
  hyprpolkitagent, ensure no conflicting notifiers (kill dunst/mako).
- Panel-specific branch:
  - noctalia: stop conflicting bars/notifications and start noctalia-shell
  - waybar: start awww + waybar and run wallpaper restore with fallback to
    waypaper + stylixImage; start nm-applet --indicator
- Post panel: qs overview + DropTerminal

Build and Ops (zcli)

- Location: modules/home/scripts/zcli.nix (installed as a script; see
  docs/zcli.md for full help)
- Common commands:
  - zcli rebuild: nh os switch with safety checks and backups handling (now offers an interactive staging prompt before building)
  - zcli rebuild-boot: nh os boot if you want activation on next reboot (safer
    for major changes)
  - zcli update: flake update + switch (also offers the staging prompt)
  - zcli stage [--all]: interactively stage changes (or stage all) without rebuilding
  - zcli update-host [hostname] [profile]: rewrite host and profile in flake.nix
    (auto-detects profile if omitted)
  - zcli add-host [hostname] [profile?]: copy hosts/default into
    hosts/<hostname>, set profile (auto-detect or prompt), optionally generate
    hardware.nix
  - zcli del-host <hostname>: remove hosts/<hostname>
  - zcli glances <start|stop|restart|status|logs>
  - zcli list-gens, trim, diag, cleanup
- Optional flags supported by rebuild/rebuild-boot/update:
-  - --dry/-n, --ask/-a, --cores N, --verbose/-v, --no-nom, --no-stage, --stage-all
- Backups handling: removes problematic backup files (e.g.,
  ~/.config/mimeapps.list.backup) before rebuilds.

Install Script (install-ddubsos.sh)

- Purpose: bootstrap on a fresh NixOS machine
- Flow:
  1. Checks for git and pciutils; verifies NixOS
  2. Prompts for hostname (warns not to use "default")
  3. Detects GPU profile (nvidia, nvidia-laptop, amd, intel, vm) or prompts
  4. Backs up any existing ~/ddubsos to ~/.config/ddubsos-backups/<timestamp>
  5. Clones repo to ~/ddubsos
  6. Creates hosts/<hostname> from hosts/default
  7. Updates flake.nix (host/profile/username)
  8. Prompts for timezone; writes to modules/core/system.nix
  9. Prompts for Git username/email; writes to hosts/<hostname>/variables.nix
  10. Prompts for keyboard layout and console keymap; writes variables.nix
  11. Generates hardware.nix for the new host
  12. Runs: sudo nixos-rebuild boot --flake ~/ddubsos/#<profile>
- After success: reboot to activate

Packages

- Core required packages and program enables: modules/core/req-packages.nix (very comprehensive CLI/GUI tool stack; includes wfetch via overlay, not direct inputs)
- Global optional packages: modules/core/global-packages.nix
- Per-host packages: hosts/<host>/host-packages.nix
- Overlay pattern for external packages:
  - External flake inputs that provide packages should be surfaced through modules/core/overlays.nix so they become available under pkgs (e.g., pkgs.wfetch).
  - Modules should only reference pkgs.<name>, not inputs.*. This decouples modules from flake wiring and improves reuse.
  - To add a new external package (example: quickshell):
    1) Edit modules/core/overlays.nix and map inputs.quickshell.packages.${final.system}.default to an attribute (e.g., quickshell = ...)
    2) Use it in modules via pkgs.quickshell (e.g., in environment.systemPackages)
- Where to add local packages:
  - For all systems: req-packages.nix (essentials), global-packages.nix (nice-to-haves)
  - For one machine: hosts/<host>/host-packages.nix
- Note on stable pinning:
  - The nixpkgs-stable input was removed. If you need a specific stable package in the future, reintroduce the input in flake.nix and expose a pkgsStable via specialArgs, then selectively use pkgsStable.<pkg> in a module or host file.

Drivers and Profiles

- modules/drivers/: amd, intel, nvidia, nvidia-prime, vm; local-hardware-clock; guest services
- Profiles under profiles/: select appropriate driver stack and options
- Selection flows:
  - nixosConfigurations keys (amd, intel, nvidia, nvidia-laptop, vm) choose which profile directory is included
  - A separate let-bound profile in flake.nix is passed to modules via specialArgs.profile; installer and zcli modify this as part of host updates
- Change profile:
  - zcli update-host <hostname> <profile> (recommended), or edit flake.nix manually
  - Rebuild with zcli rebuild (or zcli rebuild-boot)
- Host-specific insecure packages (example: macbook Broadcom STA)
  - Only hosts/macbook enables nixpkgs.config.permittedInsecurePackages = [ "broadcom-sta-6.30.223.271-57-6.12.43" ]
  - Tip: these strings may change after kernel bumps; update when necessary

Theming and Styling

- Stylix + catppuccin
- stylixImage used as fallback wallpaper in exec-once
- Waybar selection via waybarChoice; several ready-made variants in
  modules/home/waybar/
- Starship prompt selection via starshipChoice; configs under modules/home/cli/
- Hyprland animations selectable via animChoice

Dev Environments (optional)

- Enable via hosts/<host>/variables.nix: enableDevEnv = true;
- Provides:
  - direnv + nix-direnv integration
  - devenv CLI and helpers (aliases like denv, denv-shell, denv-init, etc.)
  - Templates (Python/Node/Rust) under ~/.local/share/devenv-templates/
- See docs/devenv-usage.md for usage details

Common Task Recipes

- Switch panel to waybar
  - Edit hosts/<host>/variables.nix: panelChoice = "waybar"; pick a waybarChoice
  - zcli rebuild (or zcli rebuild-boot)
- Change default terminal and browser
  - Edit hosts/<host>/variables.nix: terminal = "kitty"; browser =
    "google-chrome-stable" (or others)
  - zcli rebuild
- Change Starship prompt
  - zcli settings set starshipChoice modules/home/cli/starship-rbmcg.nix
    (or edit hosts/<host>/variables.nix and set starshipChoice accordingly)
  - zcli rebuild
- Enable a specific editor or terminal
  - Set enableEvilhelix/enableVscode/enableAlacritty/enableTmux/enablePtyxis to
    true
  - zcli rebuild
- Create a new host
  - zcli add-host <hostname> [profile?] # optionally generate hardware.nix when
    prompted
  - zcli update-host <hostname> <profile> # ensures flake host/profile match
  - zcli rebuild (on the target machine)
- Update the system
  - zcli update --ask --verbose
- Safer major change
  - zcli rebuild-boot (reboot to activate)

Troubleshooting & Gotchas

- Home Manager activation blocked by backup files
  - Symptom: rebuild fails or HM activation errors
  - Fix: zcli handles common backup cleanup automatically; otherwise remove
    known backups (e.g., ~/.config/mimeapps.list.backup)
- Waybar wallpaper not set on first boot
  - Fallback is implemented: uses waypaper with backend awww and stylixImage
- GPU-specific issues
  - Ensure correct profile in flake.nix matches the machine or use zcli
    update-host
- CachyOS kernel + v4l2loopback build issues (clang)
  - See docs/Cachy-kernel-v4l2loopback-build-issues.md for the fix and rationale
- Hostname "default"
  - Don’t use: the install script warns because updates may overwrite it
- Power profile
  - modules/core/system.nix sets cpuFreqGovernor = "performance"; adjust if
    needed

Conventions & Notes

- Environment variables (modules/core/system.nix): NIXOS_OZONE_WL=1,
  DDUBSOS_VERSION=2.Next, DDUBSOS=true
- Nix settings: flakes + nix-command enabled; download buffer tuned;
  trusted-users @wheel
- Timezone, locales, consoleKeyMap set in system.nix (consoleKeyMap comes from
  host variables)
- File format: Nix files generally nixfmt-compliant

RW Config Pattern (Home Manager copy & sync-back)

- Overview: Some GUI apps and panels benefit from writable config without symlinks. We use Home Manager activation to:
  - Sync live edits from ~/.config/<app> back into the repo (modules/home/<app-dir>)
  - Back up ~/.config/<app> to a timestamped folder
  - Copy repo contents into ~/.config/<app> as plain files (RW), then chmod -R u+w
- Implemented examples:
- Notes:
  - This is a pragmatic pattern for personal setups where absolute reproducibility isn’t required.

Useful Docs

- docs/zcli.md: all zcli commands and options
- docs/Cachy-kernel-v4l2loopback-build-issues.md: Fix for v4l2loopback when using the CachyOS (clang) kernel
- docs/devenv-usage.md: how to use devenv and templates
- README.md: project overview
- FAQ.md: additional tips and answers
- CHANGELOG.ddubs.md: timeline of changes

If you are an AI assistant

- Check flake.nix for current host/profile/username defaults
- Read hosts/<host>/variables.nix for toggles relevant to the user’s current
  machine
- Prefer zcli for rebuild/update and host mutations
- When editing code, use the existing module patterns and toggles
- For large files, fetch by path with explicit ranges; avoid pagers when reading
  git history

End of guide.
