English | [Español](./zcli.es.md)

# ddubsOS Command Line Utility (zcli) - Version 1.2.0
zcli is a handy tool for performing common maintenance tasks on your ddubsOS
system with a single command. Below is a detailed guide to its usage and
commands.

## What’s new in v1.2.0

- Panel selection supports waybar | noctalia.
  - Set with: `zcli settings set panelChoice <waybar|noctalia>`.
  - Hyprland startup updated to launch the selected panel; Noctalia runs via `qs -c noctalia-shell`.
- Noctalia Shell integration: packaged QuickShell config is linked under `~/.config/quickshell/noctalia-shell` when selected.
- Settings hints updated to include new panel options.

## What’s new in v1.1.0

- Interactive staging before rebuild/update
  - Rebuild commands will list untracked/unstaged files indexed. Choose numbers or 'all' to stage, or press Enter to skip.
  - New flags:
    - --no-stage: skip the staging prompt entirely
    - --stage-all: stage all untracked/unstaged files automatically before rebuild
  - New command:
    - zcli stage [--all] — run the interactive staging selector or stage all without rebuilding

## What’s new in v1.0.4

- Settings editing with validation, backups, and --dry-run
  - zcli settings set <attr> <value> [--dry-run]
  - Validates browser/terminal keys against supported lists; validates file paths for stylixImage, waybarChoice, starshipChoice, animChoice
  - Boolean attributes now editable (e.g., gnomeEnable, enableVscode, enableNFS). Accepts true/false/on/off/yes/no/1/0. List them with: zcli settings --list-bools
  - Discoverability: zcli settings --list-browsers, zcli settings --list-terminals, zcli settings --list-bools
- Hosts apps overview
  - zcli hosts-apps lists host-specific packages from hosts/<host>/host-packages.nix
- Quality-of-life
  - zcli upgrade is an alias for zcli update
- Internal refactor (no action needed by users)
  - Dispatcher generated at modules/home/scripts/zcli.nix sources feature modules (features/*) and shared libraries (lib/*)

### Settings usage examples

```bash
# Discover supported keys
zcli settings --list-browsers
zcli settings --list-terminals
zcli settings --list-bools

# Set browser and terminal
zcli settings set browser google-chrome-stable
zcli settings set terminal kitty

# Set panel (waybar | noctalia)
zcli settings set panelChoice noctalia

# Set boolean attributes (accepts true/false/on/off/yes/no/1/0)
zcli settings set gnomeEnable true
zcli settings set enableVscode off
zcli settings set thunarEnable yes --dry-run

# Dry-run a change (no write)
zcli settings set browser firefox --dry-run

# Set file-backed attributes (accepts absolute or repo-relative paths)
 zcli settings set stylixImage ~/ddubsos/wallpapers/AnimeGirlNightSky.jpg
 zcli settings set waybarChoice modules/home/waybar/waybar-ddubs.nix
 zcli settings set starshipChoice modules/home/cli/starship-rbmcg.nix
 zcli settings set animChoice modules/home/hyprland/animations-end-slide.nix
```

Guardrails and auto-enables
- Browser: when setting `browser`, zcli verifies the corresponding command exists on PATH. If not installed, it prints an error and does not update the value.
- Terminal: when setting `terminal`, zcli auto-enables matching toggles when applicable (honors `--dry-run`):
  - alacritty → enableAlacritty = true
  - ptyxis → enablePtyxis = true
  - wezterm → enableWezterm = true
  - ghostty → enableGhostty = true

#### Editable boolean attributes

- Desktop: gnomeEnable, dwmEnable
- Editors & terminals: enableEvilhelix, enableVscode, enableMicro, enableAlacritty, enableTmux, enablePtyxis, enableWezterm, enableGhostty
- System & services: enableDevEnv, sddmWaylandEnable, enableOpencode, enableObs, clock24h, enableNFS, printEnable, thunarEnable, enableGlances

Tip: list on your system with: zcli settings --list-bools

## Usage

Run the utility with a specific command:

`zcli`

If no command is provided, it displays this help message.

## Available Commands

Here’s a quick reference table for all commands, followed by detailed
descriptions:

| Command     | Icon | Description                                                                                                                                           | Example Usage                           |
| ----------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| cleanup     | 🧹   | Removes old system generations, either all or by specifying a number to keep, helping free up space.                                                  | `zcli cleanup` (prompted for all or #)  |
| diag        | 🛠️   | Generates a system diagnostic report and saves it to `diag.txt` in your home directory.                                                               | `zcli diag`                             |
| doom        | 🔥   | Manage Doom Emacs installation - install, check status, remove, or update Doom Emacs.                                                                | `zcli doom install`                     |
| glances     | 📊   | Manage Docker-based Glances monitoring server - start, stop, restart, check status, or view logs.                                                     | `zcli glances start`                    |
| list-gens   | 📋   | Lists user and system generations, showing active and existing ones.                                                                                  | `zcli list-gens`                        |
|| rebuild     | 🔨   | Rebuilds the NixOS system configuration. Now offers an interactive staging prompt to stage new/unstaged files before building.                                        | `zcli rebuild`                          |
| trim        | ✂️   | Trims filesystems to improve SSD performance and optimize storage.                                                                                    | `zcli trim`                             |
|| update      | 🔄   | Updates the flake and rebuilds the system. Now offers an interactive staging prompt to stage new/unstaged files before building.                      | `zcli update`                           |
|| update-host | 🏠   | Automatically sets the host and profile in your `flake.nix` file based on the current system. It detects the GPU type or prompts for input if needed. | `zcli update-host [hostname] [profile]` |
|| update-warp | ⚡   | Update vendored Warp Terminal (current) to the latest upstream release; recomputes SRI and updates versions.json. Optional --commit to auto-commit. | `zcli update-warp [--commit]` |
|| stage       | ✅   | Interactively stage changes (or use --all to stage everything) without rebuilding.                                                            | `zcli stage`, `zcli stage --all`        |

## Detailed Command Descriptions

- **🧹 cleanup**: This command helps manage system storage by removing old
  generations. You can remove all generations or specify a number to retain
  (e.g., `zcli cleanup` free's up space and removes the entries from boot menu.

- **🛠️ diag**: Creates a comprehensive diagnostic report by running
  `inxi --full` and saving the output to `diag.txt` in your home directory. This
  is ideal for troubleshooting or sharing system details when reporting issues.

- **📋 list-gens**: Displays a clear list of your current user and system
  generations, including active ones. This allows you to review what's installed
  and plan cleanups.

- **🔨 rebuild**: Performs a system rebuild for NixOS by first checking for any
  files that could block Home Manager from completing the process. It's similar
  to standard rebuild functions but with added safeguards.

- **✂️ trim**: Optimizes your filesystems, particularly for SSDs, to improve
  performance and reduce wear. Run this regularly as part of your maintenance
  routine.

- **🔄 update**: Streamlines updates by checking for potential issues with Home
  Manager, then updating the flake and rebuilding the system. This combines
  flake updates and rebuilds into one efficient step.

- **🏠 update-host**: Simplifies managing multiple hosts by automatically
  updating the `hostname` and `profile` in your `~/ddubsos/flake.nix` file. It
  attempts to detect your GPU type; if it fails, you'll be prompted to enter the
  details manually.

- **⚡ update-warp**: Updates the vendored Warp Terminal (current) packaging inside this repo.
  - Bumps to the latest upstream release by following Warp’s download redirects.
  - Recomputes SRI hashes and updates pkgs/warp-terminal-current/versions.json.
  - Optional `--commit` will auto-commit the versions file change.
  - Rebuild afterwards with `zcli rebuild`.

## Emacs notes

- Emacs is managed as a standard feature via Home Manager (no zcli subcommands).
- The Emacs user daemon is enabled; use emacsclient for fast startup:
  - GUI: `emacsclient -c -n -a ""`
  - TTY: `et` (wrapper that prefers truecolor via xterm-direct/tmux-direct) or `emacsclient -t -a ""`
- Doom packages/autoloads are synchronized automatically on Home Manager activation (`doom sync -u`).
- First-time install is bootstrapped during activation; if offline, it will retry on the next activation.

## Glances Server Management

The `glances` command provides Docker-based system monitoring server management:

- **📊 glances start**: Starts the Glances monitoring server in a Docker
  container. The server will be accessible via web interface for real-time system
  monitoring.

- **📊 glances stop**: Stops the running Glances server Docker container,
  shutting down the monitoring service.

- **📊 glances restart**: Restarts the Glances server by stopping and then
  starting the Docker container. Useful for applying configuration changes.

- **📊 glances status**: Shows the current status of the Glances server,
  including whether it's running and provides access URLs. Displays local,
  network, and hostname-based access points for the web interface (typically on
  port 61210).

- **📊 glances logs**: Displays the Docker container logs for the Glances
  server, useful for troubleshooting issues or monitoring server activity.

**Note**: Glances server management requires the `glances-server.nix` module to
be enabled in your system configuration. The server provides a web-based
interface for monitoring system resources, processes, and network activity.

## Optional Parameters for Build Commands

The `rebuild`, `rebuild-boot`, and `update` commands support additional optional
parameters to customize the build process:

### Available Options:

- **--dry, -n**: Shows what would be done without actually executing the changes.
  Perfect for previewing updates or rebuilds before committing to them.

- **--ask, -a**: Enables confirmation prompts before proceeding with the operation.
  Provides an extra safety layer for system changes.

- **--cores N**: Limits the build process to use only N CPU cores. This is
  particularly useful for virtual machines or systems where you want to preserve
  resources for other tasks.

- **--verbose, -v**: Enables detailed output during the build process, showing
  more information about what's happening during system updates.

- **--no-nom**: Disables the nix-output-monitor tool, falling back to standard
  Nix output. Useful if you prefer traditional build output or encounter issues
  with the output monitor.
- **--no-stage**: Skip the staging prompt (do not stage anything before building).
- **--stage-all**: Stage all untracked/unstaged files automatically before building.

### Usage Examples:

```bash
# Dry run to see what would be updated
zcli update --dry

# Rebuild with confirmation prompts and limited to 2 CPU cores
zcli rebuild --ask --cores 2

# Verbose update without nix-output-monitor
zcli update --verbose --no-nom

# Combine multiple options
zcli rebuild-boot --dry --ask --verbose
```

These options provide flexibility and control over system operations, allowing
you to customize the build process according to your specific needs and system
constraints.

## Additional Notes

- **Why use zcli?** This utility saves time on routine tasks, reducing the need
  for multiple commands or manual edits.
- **Version and Compatibility:** Ensure you're using the latest version (1.2.0
  as per the source). For any issues, generate a diagnostic report with
  `zcli diag` and consult your system logs.
