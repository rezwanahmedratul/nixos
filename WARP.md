# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project: ZaneyOS — NixOS flake for desktop systems with per-host overrides, GPU/VM profiles, and an integrated Home Manager layer.

Important repo expectations
|- This repo is expected at: ~/zaneyos (programs.nh.flake points here). If you keep it elsewhere, update modules/core/nh.nix accordingly.
|- Target OS: NixOS 23.11+; UEFI + GPT expected; systemd-boot is supported out of the box (see README for details).

Common commands
|- Rebuild and switch (preferred via nh/zcli)
  - fr            # zsh alias → nh os switch --hostname <profile>
  - fu            # zsh alias → nh os switch --hostname <profile> --update
  - zcli rebuild [--dry|--ask|--cores N|--verbose|--no-nom]
  - zcli update  [--dry|--ask|--cores N|--verbose|--no-nom]
|- Rebuild for next boot (safer for bigger changes)
  - zcli rebuild-boot [same options]
  - sudo nixos-rebuild boot --flake .#<profile>
|- Direct NixOS (without nh/zcli)
  - sudo nixos-rebuild switch --flake .#<profile>
|- Validate the flake
  - nix flake check
|- Format Nix files (nixfmt-rfc-style is included)
  - find . -name "*.nix" -print0 | xargs -0 nixfmt
|- Configuration comparison (compare against upstream)
  - ./modules/src/compare-zaneyos-config.sh       # compares against official repo
  - ./modules/src/compare-zaneyos-config.sh --branch stable-2.4    # specific branch
|- Host management (zcli)
  - zcli update-host [hostname] [profile]  # auto-detect if args omitted
  - zcli add-host <hostname> [profile]     # copies hosts/default, can gen hardware.nix
  - zcli del-host <hostname>
|- Diagnostics and maintenance
  - zcli diag           # writes ~/diag.txt
  - zcli cleanup        # prunes generations (interactive)
  - zcli trim           # runs fstrim with confirmation
|- 2.3 → 2.4 upgrade (existing installs)
  - ./upgrade-2.3-to-2.4.sh        # automated analysis, backup, and upgrade
  - ./upgrade-2.3-to-2.4.sh --revert

Notes on profiles and hosts
|- Profiles represent hardware targets: amd, intel, nvidia, nvidia-laptop (intel+NVIDIA hybrid), amd-hybrid (AMD+NVIDIA hybrid), vm.
|- Use the profile in flake targets like .#vm or .#nvidia, or via nh's --hostname.
|- Host-specific settings live under hosts/<hostname>/; variables.nix holds UX and feature toggles: barChoice (noctalia or waybar), waybarChoice (when barChoice="waybar"), clock24h, etc.

High-level architecture (big picture)
|- flake.nix
  - Inputs: nixpkgs 25.11, home-manager 25.11, stylix, nvf, nix-flatpak, noctalia; nixvim and quickshell are included but currently inactive (uncommitted to outputs).
  - Defines system, host, profile, username; constructs nixosConfigurations via mkNixosConfig.
  - Each configuration imports profiles/<profile>.
- profiles/<profile>/default.nix
  - Imports host and stacks: ../../hosts/${host}, ../../modules/drivers, ../../modules/core.
  - Toggles drivers and VM guest services per profile; the nvidia-laptop and amd-hybrid profiles consume Bus IDs from host variables.
- hosts/<hostname>/
  - default.nix imports hardware.nix and host-packages.nix.
  - variables.nix is the primary control surface (display manager, terminal/browser defaults, waybarChoice, stylix image, 24h clock, Thunar/printing/NFS flags, intel/nvidia Bus IDs, etc.).
|- modules/options.nix
  - Defines the schema for `zaneyos` configuration options (e.g. enable flags, theme choices).
|- modules/core
  - Composes NixOS modules: boot, flatpak, fonts, hardware, network, nfs, nh, quickshell, packages, printing, display manager (greetd/sddm), security, services (PipeWire/SSH/Bluetooth/fstrim; smartd conditional), steam, stylix, syncthing, system (nix settings, locales, env), thunar, user (Home Manager), virtualization, xserver.
  - quickshell.nix installs quickshell with Qt6 dependencies and required environment variables (needed for noctalia-shell).
  - nh.nix enables nh and pins programs.nh.flake to ~/zaneyos.
  - user.nix integrates Home Manager and creates users.${username}, passing { inputs, username, host, profile } to the home layer.
- modules/drivers
  - AMD, Intel, NVIDIA, NVIDIA Prime, NVIDIA AMD-Hybrid, and VM guest services; nvidia-prime options (enable, intelBusID, nvidiaBusID) are consumed by the nvidia-laptop profile; nvidia-amd-hybrid options (enable, amdgpuBusID, nvidiaBusID) are consumed by the amd-hybrid profile.
|- modules/home
  - Composes the user environment: Hyprland, bar/shell choice (noctalia-shell or Waybar via barChoice), Rofi, Yazi, terminals (Kitty/WezTerm/Ghostty/Alacritty toggles), Zsh/Bash config, Git, NVF/Neovim, OBS, swaync, scripts, Stylix, optional Doom Emacs/VSCodium/Helix.
  - default.nix conditionally imports barModule: either noctalia.nix (when barChoice="noctalia") or waybarChoice (when barChoice="waybar").
  - noctalia.nix installs noctalia-shell and seeds ~/.config/quickshell/noctalia-shell from the package distribution.
  - scripts/default.nix installs zcli; zcli wraps rebuild/update/boot, cleanup, diagnostics, host management, and Doom lifecycle.
- Shell aliases (zsh)
  - fr and fu are defined in modules/home/zsh/default.nix, parameterized by the active profile.

Key development choices
- Repo location matters: nh and zcli assume ~/zaneyos; move it and adjust modules/core/nh.nix.
- Validation is via nix flake check; there is no separate unit test suite.
- Formatting is via nixfmt-rfc-style (provided in system packages).

Migration lessons to preserve (Hyprland Lua + Waybar source)
- Hyprland Lua conversion (critical pitfalls)
  - Do not set `["$modifier"]` via `hl.config`. In Lua mode this is treated as an unknown config key. Keep modifier handling in Lua helpers (`cfg.modifier`) instead.
  - Do not pass border gradients as hyprlang-style strings like `rgb(...) rgb(...) 45deg`. For Lua, use structured values:
    - `general.col.active_border = { colors = { "rgba(...)", "rgba(...)" }, angle = 45 }`
    - `general.col.inactive_border = "rgba(...)"` (or equivalent valid format)
  - Stylix/base16 colors are hex strings; normalize/sanitize them before building `rgba(...)` values (strip `#`, validate length, add alpha if needed).
  - After editing `modules/home/hyprland/lua/*.lua`, remember HM files under `~/.config/hypr/zaneyos/` are store symlinks; changes do not apply until rebuild/switch.

- Hyprland Lua keybind reliability rules
  - Normalize modifier tokens to canonical uppercase (`SUPER`, `SHIFT`, `CTRL`, `ALT`) before calling `hl.bind`; lowercase tokens can produce keysym parse errors.
  - Normalize numeric keycodes used as keys:
    - Keep workspace digits `0-9` as-is.
    - Convert numeric keycodes like `43/44/45/46` to `code:43`/etc to avoid `Unknown keysym` errors.
  - Preserve a single intent per chord to avoid duplicate behavior regressions:
    - `SUPER+SHIFT+arrow` is reserved for resize (`resizeactive`).
    - Movement/swap remain on their dedicated bindings (`SUPER+SHIFT+h/j/k/l` and `SUPER+ALT+...`).

- keybinds-parser expectations after Lua migration
  - Hyprland mode must support all sources in order:
    1) `~/zaneyos/modules/home/hyprland/binds.nix`
    2) `~/.config/hypr/hyprland.conf`
    3) `~/.config/hypr/zaneyos/vars.lua`
    4) Lua function-style bind files (e.g. `hyprland.lua` + `zaneyos/keybinds.lua`)
  - Keep parser output schema stable: `[{ keybind, description, category }]`.

- Waybar source-build override requirements
  - Keep Waybar as a flake input (`inputs.waybar = github:Alexays/Waybar`) and lock it in `flake.lock`.
  - Keep a global overlay in `flake.nix` that overrides `pkgs.waybar` from the flake package and enforces:
    - `mesonFlags` includes only `-Dtests=disabled` for tests (filter out any existing `-Dtests=...` first)
    - `doCheck = false`
    - `doInstallCheck = false`
  - Waybar theme modules should continue using `package = pkgs.waybar` so all themes inherit the same source-build fix.

- Fast validation checklist for these migrations
  - `nix eval --raw path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
  - `nix eval --json path:$PWD#nixosConfigurations.<host>.pkgs.waybar.mesonFlags`
  - `hyprctl configerrors` (after rebuild/switch) to catch Lua runtime/config issues immediately.

Useful docs in-repo
- README.md: requirements, install and upgrade overview (including the 2.3→2.4 process).
- zcli.md: full CLI docs, commands, options, and examples.
- cheatsheets/project-guide.md: quick commands, architecture summary, and common workflows.
- cheatsheets/: Hyprland and terminal/editor quick references.


