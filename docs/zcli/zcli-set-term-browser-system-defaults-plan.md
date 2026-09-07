# Plan: Extend `zcli settings set` to apply system defaults for browser and terminal

Context
- Branch: zcli-refactor
- Date: 2025-09-02
- Purpose: When setting browser or terminal via `zcli settings set`, also set user-level system defaults so other apps (e.g., Discord, Thunar) use the same default.

Original request (from user)
- “Can we extend the setting of browser and terminal to also set the xdg portal defaults? So other applications like discord or thunar will open the default set here also.”

Summary of goals
- `browser` attribute: After `zcli settings set browser <key>`, set the default web browser for common MIME types so links open in that browser globally.
- `terminal` attribute: After `zcli settings set terminal <key>`, ensure a default terminal is discoverable by applications (and optionally specific DEs) so “Open Terminal” and similar actions use it.
- Keep existing zcli behavior: validation, backups, `--dry-run`, and post-write verification.

Design analysis
1) Browser defaults (XDG)
- Desired MIME handlers to set:
  - x-scheme-handler/http
  - x-scheme-handler/https
  - text/html
  - application/xhtml+xml
- Preferred mechanism: glib’s `gio` tool (writes user defaults and updates `~/.config/mimeapps.list` safely).
  - Commands (example):
    - `gio mime x-scheme-handler/http <browser.desktop>`
    - `gio mime x-scheme-handler/https <browser.desktop>`
    - `gio mime text/html <browser.desktop>`
    - `gio mime application/xhtml+xml <browser.desktop>`
- Fallback if `gio` isn’t available: edit `~/.config/mimeapps.list` under the `[Default Applications]` section, with a timestamped backup.
- Required mapping: zcli “browser key” → Desktop file name. Example proposal:
  - google-chrome|google-chrome-stable → google-chrome.desktop
  - firefox → firefox.desktop
  - firefox-esr → firefox-esr.desktop
  - brave → brave-browser.desktop
  - chromium → chromium.desktop
  - vivaldi → vivaldi-stable.desktop (verify if `vivaldi.desktop` is used by your package)
  - floorp → floorp.desktop

2) Terminal default
- There’s no standard XDG MIME for “default terminal”. Approaches:
  - Set user environment variable for broad compatibility:
    - Write `~/.config/environment.d/10-terminal.conf` with `TERMINAL=<terminal>`.
    - This is picked up by `systemd --user` on login; many apps respect `$TERMINAL`.
  - Optional DE-specific settings (best-effort, non-fatal):
    - GNOME: `gsettings set org.gnome.desktop.default-applications.terminal exec <terminal>`
    - Xfce: `exo-preferred-applications --set TerminalEmulator <terminal>`
  - Leave window-manager-specific integrations out of scope for now (they often have their own config).

3) Integration location in zcli
- Extend `lib/validate.sh` to add a mapping function for browser → desktop file name.
- In `settings_set_main` after a successful write for `browser` or `terminal`, invoke helper functions to apply system defaults.
- Respect `--dry-run`: print intended `gio` commands and file paths without writing; show intended changes to `mimeapps.list` or `environment.d` files.
- Continue creating timestamped backups for any edited files (`mimeapps.list`, `environment.d/10-terminal.conf`).

Proposed CLI behavior
- Default: apply system defaults automatically for `browser` and `terminal`.
- Add opt-out: `--no-xdg` to skip applying system defaults.
- Optionally add opt-in variant instead (e.g., `--also-xdg`); however, default-on with `--no-xdg` feels most convenient.

Example helpers (to be added to zcli)
- Browser desktop mapping (in `lib/validate.sh`):
```bash path=null start=null
browser_desktop_for() {
  case "${1:-}" in
    google-chrome|google-chrome-stable) echo "google-chrome.desktop" ;;
    firefox) echo "firefox.desktop" ;;
    firefox-esr) echo "firefox-esr.desktop" ;;
    brave) echo "brave-browser.desktop" ;;
    chromium) echo "chromium.desktop" ;;
    vivaldi) echo "vivaldi-stable.desktop" ;;  # verify package’s desktop file name
    floorp) echo "floorp.desktop" ;;
    *) return 1 ;;
  esac
}
```

- Apply browser defaults with `gio`:
```bash path=null start=null
_xdg_set_browser_defaults() {
  local desktop="$1"
  # Best-effort; don’t fail zcli if these fail.
  ${pkgs.glib}/bin/gio mime x-scheme-handler/http "$desktop"      || true
  ${pkgs.glib}/bin/gio mime x-scheme-handler/https "$desktop"     || true
  ${pkgs.glib}/bin/gio mime text/html "$desktop"                   || true
  ${pkgs.glib}/bin/gio mime application/xhtml+xml "$desktop"       || true
}
```

- Fallback: edit `~/.config/mimeapps.list` directly (with backup):
```bash path=null start=null
_xdg_write_mimeapps_defaults() {
  local desktop="$1"
  local f="$HOME/.config/mimeapps.list"
  mkdir -p "$(dirname "$f")"
  [ -f "$f" ] && cp -f "$f" "$f.bak-$(date +%Y%m%d-%H%M%S)"

  # Create a simple Default Applications block if missing
  if ! grep -q "^\[Default Applications\]$" "$f" 2>/dev/null; then
    {
      echo "[Default Applications]"
      echo "x-scheme-handler/http=$desktop;"
      echo "x-scheme-handler/https=$desktop;"
      echo "text/html=$desktop;"
      echo "application/xhtml+xml=$desktop;"
    } >> "$f"
    return 0
  fi

  # Update existing keys idempotently
  awk -v d="$desktop" '
    BEGIN { in_def=0 }
    /^\[Default Applications\]$/ { in_def=1; print; next }
    /^\[/ && $0 != "[Default Applications]" { in_def=0 }
    {
      if (in_def && ($1 ~ /^(x-scheme-handler\/http|x-scheme-handler\/https|text\/html|application\/xhtml\+xml)=/)) {
        print gensub(/=.*/, "=" d ";", 1)
        next
      }
      print
    }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
```

- Apply terminal default to user environment (systemd user env):
```bash path=null start=null
_set_default_terminal_env() {
  local term="$1"
  local dir="$HOME/.config/environment.d"
  local f="$dir/10-terminal.conf"

  mkdir -p "$dir"
  [ -f "$f" ] && cp -f "$f" "$f.bak-$(date +%Y%m%d-%H%M%S)"
  printf "TERMINAL=%s\n" "$term" > "$f"
  systemctl --user daemon-reload 2>/dev/null || true
}
```

- Optional DE hooks (best-effort):
```bash path=null start=null
_try_set_de_terminal_defaults() {
  local term="$1"
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.default-applications.terminal exec "$term" 2>/dev/null || true
  fi
  if command -v exo-preferred-applications >/dev/null 2>&1; then
    exo-preferred-applications --set TerminalEmulator "$term" 2>/dev/null || true
  fi
}
```

Integration points in `zcli`
- In `settings_set_main`:
  - When `attr=browser` and write succeeds:
    - Resolve desktop via `browser_desktop_for "$value"`.
    - If `--dry-run`: print intended `gio` calls or file edits.
    - Else: call `_xdg_set_browser_defaults "$desktop"`; if `gio` is missing or fails, call `_xdg_write_mimeapps_defaults "$desktop"`.
  - When `attr=terminal` and write succeeds:
    - If `--dry-run`: print path to `~/.config/environment.d/10-terminal.conf` and its intended contents; show DE commands if applicable.
    - Else: call `_set_default_terminal_env "$value"` and `_try_set_de_terminal_defaults "$value"` (best-effort).
- Add an opt-out flag `--no-xdg` to `settings set` to suppress applying system defaults.

Backups and idempotency
- Continue timestamped backups for every user file we edit:
  - `~/.config/mimeapps.list.bak-YYYYmmdd-HHMMSS`
  - `~/.config/environment.d/10-terminal.conf.bak-YYYYmmdd-HHMMSS`
- Re-running setter should be idempotent: same values → no effective change.

Security/safety considerations
- Only operate in user scope; avoid `sudo`.
- Best-effort external commands; do not fail the entire settings change if a DE-specific hook fails.
- Respect `--dry-run` thoroughly.

Acceptance criteria
- `zcli settings set browser <key>` updates user default handlers for http/https and HTML types; apps launch the chosen browser.
- `zcli settings set terminal <key>` results in `$TERMINAL` being set in user sessions (after re-login) and DEs updated when applicable.
- `--dry-run` prints intended changes and does not write.
- Backups are created and verification passes (no quote-mismatch issues).

Open questions
- Confirm Vivaldi desktop ID (`vivaldi.desktop` vs `vivaldi-stable.desktop`) based on the installed package.
- Do we want an explicit `zcli settings apply-xdg` subcommand to force re-application without changing values? (Nice-to-have.)
- Should we support additional MIME types (e.g., `application/json`)? Probably not necessary.

Implementation plan (tasks)
1) Extend `lib/validate.sh` with `browser_desktop_for()` mapping.
2) Add `_xdg_set_browser_defaults`, `_xdg_write_mimeapps_defaults`, `_set_default_terminal_env`, `_try_set_de_terminal_defaults` helpers into zcli.
3) Wire these into `settings_set_main` for `browser` and `terminal`, honoring `--dry-run` and `--no-xdg`.
4) Test:
   - Dry-run outputs.
   - Real writes with backups and verification.
   - Behavior when `gio` is present vs absent.
   - Terminal env file creation and `systemctl --user daemon-reload` behavior.
5) Document new behavior in `docs/zcli.md` and help output (mention `--no-xdg`).

Future improvements
- Add a `zcli settings apply-xdg` to re-sync defaults from the currently set values without changing them.
- Add unit tests for mimeapps editing and env file writing.
- Detect desktop files dynamically via `gio mime`/`xdg-mime query default text/html` to confirm state.

