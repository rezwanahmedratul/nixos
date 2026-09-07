# qs-wallpapers and qs-wallpapers-apply

This document explains what the qs-wallpapers tools do, how they are structured, and how they work together.

- Picker: qs-wallpapers (installed from modules/home/scripts/qs-wallpapers.nix)
- Apply wrapper: qs-wallpapers-apply (installed from modules/home/scripts/qs-wallpapers-apply.nix)
- Restore helper: qs-wallpapers-restore (installed from modules/home/scripts/qs-wallpapers-restore.nix)

## What they do

- qs-wallpapers is a fast, Qt/QML thumbnail picker for static wallpapers (images). It scans your wallpaper directory, builds/uses cached thumbnails, and renders a searchable grid UI. When you click a thumbnail, it outputs the selected file path to stdout.
- qs-wallpapers-apply runs the picker, then applies the selected wallpaper using a backend (default: mpvpaper). It also cleans up conflicting wallpaper daemons first. When a selection is applied, it persists the current wallpaper to state files for restore-on-login.
- qs-wallpapers-restore restores the last selected wallpaper on login, respecting backend constraints and providing robust fallbacks. See docs/qs-wallpaper-restore.md for full details.

## Key concepts and flow

1) Collect files
- Scans WALL_DIR (default: $HOME/Pictures/Wallpapers) recursively, following symlinks (`find -L`).
- Image extensions included: jpg, jpeg, png, webp, avif, bmp, tiff.

2) Thumbnail cache
- Thumbnails are cached in WALL_CACHE_DIR (default: $HOME/.cache/wallthumbs) using ImageMagick convert.
- A prebuilt manifest (walls.json) may be populated at activation time to skip runtime manifest building for better startup performance.

3) JSON manifest
- The picker builds (or copies) a JSON array of objects: { path, name, thumb } for each image.
- path: absolute path to the image; name: filename without extension; thumb: cached thumbnail path.

4) QML UI
- A temporary .qml file is generated and executed with Qt 6’s qml binary.
- Visuals: frameless, no-drop-shadow window with increased opacity for frame/header to improve readability; Hyprland rules apply noblur/noborder/rounding.
- The UI shows:
  - A search bar that filters by name/path (case-insensitive), with a subtle gradient for depth.
  - A grid of rounded thumbnails with labels.
  - Clicking a tile prints a line containing "SELECT:<path>" to QML’s console; the shell script captures this and prints just the path to stdout.

5) Output
- If a selection was made, qs-wallpapers prints the path to stdout. If cancelled, it prints nothing.

6) Apply wrapper
- qs-wallpapers-apply orchestrates the picker and applies the result.
- It sets BACKEND = ${WALLPAPER_BACKEND:-mpvpaper}.
- On selection, it persists state to:
  - $XDG_STATE_HOME/qs-wallpapers/current.json (fields: path, backend, timestamp)
  - $XDG_STATE_HOME/qs-wallpapers/current_wallpaper (plain text path)
- Then it applies via the selected backend:
  - mpvpaper: pkill any running awww-daemon, hyprpaper, mpvpaper to avoid conflicts, sleep briefly, then start mpvpaper on all outputs with sensible image options.
  - awww: ensure awww-daemon is running, then run `awww img --resize fill <path>`.
  - hyprpaper: generate a minimal config (per monitor) and start hyprpaper.

## Flags and environment

Picker (qs-wallpapers):
- Flags: -d DIR (wall dir), -t DIR (thumb cache), -s N (thumb size), -h (help)
- Env:
  - WALL_DIR: image search directory (default: $HOME/Pictures/Wallpapers)
  - WALL_CACHE_DIR: thumbnail cache (default: $HOME/.cache/wallthumbs)
  - WALL_THUMB_SIZE: pixel size for thumbnails (default: 200)
  - QS_DEBUG: if set, prints diagnostics and runs QML directly (useful for debugging)
  - QS_PERF: if set, prints timing info
  - QS_AUTO_QUIT: if set, quits QML immediately after building the model (used in print-only/perf scenarios)

Apply (qs-wallpapers-apply):
- Flags:
  - --print-only: runs picker and exits (useful to benchmark/inspect without applying)
  - --shell-only: prepare and run shell portion only (skips QML; perf testing)
- Env:
  - WALLPAPER_BACKEND: mpvpaper (default), awww, or hyprpaper
  - QS_DEBUG / QS_PERF / QS_AUTO_QUIT propagated as needed

## Why two tools (picker vs apply)

- The picker (qs-wallpapers) is composable: it can be used standalone in scripts or piped into other tooling. It does one thing—let the user select a file and return it.
- The apply wrapper (qs-wallpapers-apply) provides a complete UX: it runs the picker and immediately applies the result using your preferred backend with sensible safety (stopping conflicting daemons).

## Performance characteristics

- Pre-building thumbnails and, optionally, a precomputed JSON manifest at activation significantly reduces perceived startup time.
- The picker avoids network calls and large library loads at runtime; it shells out to optimized system tools (find, convert, sha256sum) and inlines the JSON data into the QML scene to avoid file I/O from inside QML.

## Integration notes

- Hyprland rules (in modules/home/hyprland/windowrules.nix) float and style the QML window when the title matches "Wallpapers".
- Keybinding example (Hyprland): `$mod+Shift+W` -> `qs-wallpapers-apply`.
- Restore on login: `qs-wallpapers-restore` is invoked from modules/home/hyprland/exec-once.nix. If no saved state is present or all methods fail, exec-once falls back to `waypaper` with a configured default image.
- See docs/qs-wallpaper-restore.md for environment variables and fallback order.

## Troubleshooting

- No images listed: verify WALL_DIR exists and contains supported extensions (symlinks are supported due to -L).
- Picker prints nothing: cancelled or window closed without a click.
- Apply fails: ensure mpvpaper/awww/hyprpaper is installed for the selected backend.
- Restore does nothing on login: ensure `$XDG_STATE_HOME/qs-wallpapers/current.json` or `current_wallpaper` exists and points to a valid file; otherwise the restore script exits quickly and exec-once will apply the default via waypaper.
- Black screen on mpv: a Hyprland rule sets `content none, class:mpv` to avoid black frames when maximizing; not related to these scripts but noted in configuration.

