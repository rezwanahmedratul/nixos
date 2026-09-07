# zcli Refactoring Plan Overview

Purpose
- Capture the refactoring direction for zcli (currently >1,000 LoC monolith) and enumerate concrete next steps, including settings editability, validation, and future TUI support. This is written to be executed by an AI agent later; no code changes are made now.

Context summary
- zcli is generated via Nix (writeShellScriptBin) and implements many subcommands: rebuild/update, hosts management, settings display, Doom Emacs ops, Glances server ops, cleanup/diag/trim.
- Cross-cutting logic (argument parsing, validation, printing, color, safety checks) is interleaved with feature logic in one file, complicating growth and a future TUI (whiptail/dialog).

Problem statement
- Hard to scale, test, and add TUI without reworking structure. zcli settings currently displays values from hosts/<host>/variables.nix but cannot change them in place with validation.

Guiding goals
- Separate core logic from UI; keep core headless/non-interactive and testable.
- Introduce modular feature files and shared libraries for parsing, validation, Nix helpers, UX/logging.
- Enable a TUI layer that reuses core functions without duplicating logic.
- Improve determinism by pinning external tools to ${pkgs.*}/bin paths wherever feasible.

High-level architecture (target)
- Entry point (zcli): thin dispatcher that lazy-loads feature modules.
- Shared libraries: common.sh, log/colors, args parsing, nix helpers, sys helpers.
- Feature modules: settings, rebuild, generations, diag, trim, hosts, doom, glances.
- Optional TUI: whiptail/dialog menus calling the same core functions.
- Tests: bats for unit/integration; shellcheck/shfmt for linting.

Immediate To-Do (requested)
1) Make settings editable (beyond display)
   - Add a non-interactive “core” that updates values in variables.nix:
     - panelChoice, browser, terminal, keyboardLayout, consoleKeyMap
     - stylixImage, waybarChoice, animChoice (path-like)
   - Add validation before writing:
     - File existence checks for stylixImage/waybarChoice/animChoice
     - Browser/terminal checks: installed or installable
       - Installed: command presence or Nix profile check
       - Installable: exists in supported mapping; can be surfaced to user
   - Make all edits reversible: create timestamped backups and support --dry-run.

2) Supported browsers list
   - Maintain a curated map: key -> { command, nixPackage }
   - Initial proposal (editable):
     - firefox -> { cmd: firefox, pkg: firefox }
     - chromium -> { cmd: chromium, pkg: chromium }
     - brave -> { cmd: brave-browser, pkg: brave }
     - librewolf -> { cmd: librewolf, pkg: librewolf }
     - qutebrowser -> { cmd: qutebrowser, pkg: qutebrowser }
   - Expose “zcli settings --list-browsers” to print supported keys.

3) Terminal validation
   - Similar curated map for terminals:
     - alacritty, kitty, wezterm, ghostty, ptyxis, gnome-terminal, foot, tmux
   - Expose “zcli settings --list-terminals”.

4) Next phase: hosts-specific applications view
   - Read hosts/<host>/host-packages.nix (or equivalent attribute file) and display the packages uniquely installed for the active host.
   - Prefer nix eval over regex parsing when feasible, e.g.:
     - nix eval --impure --expr '(import ./flake.nix).nixosConfigurations."${HOST}".pkgs' (or a thinner eval path exposing host packages)
   - Present a clean list to the user; optionally diff against “common/default” packages.

Acceptance criteria for these To-Do items
- settings view still works; settings edit commands write correct values with validation and backups.
- zcli returns non-zero when validation fails, with helpful error messages.
- --dry-run prints intended changes without writing.
- Supported browser/terminal lists are discoverable via flags and validated during set/update operations.
- hosts applications view lists only host-specific additions (optionally indicates source files/attrs).

Proposed module boundaries (for later refactor)
- lib/
  - common.sh: set -Eeuo pipefail, traps, env safety, IFS.
  - colors.sh, log.sh: ANSI helpers, log/info/warn/die.
  - args.sh: command-line parsing for shared flags (e.g., --dry-run, --assume-yes).
  - nix.sh: verify_hostname, ensure_accept_flag, robust readers for variables.nix.
  - sys.sh: file checks, command presence, hostname/ip helpers.
  - validate.sh: file validators, enum validators, mappers for browsers/terminals.
- features/
  - settings.sh: view + edit functions; file read/write with backups and --dry-run.
  - hosts.sh: update-host/add-host/del-host; host package inspection.
  - rebuild.sh, generations.sh, diag.sh, trim.sh, doom.sh, glances.sh: unchanged behavior, split per concern.
- tui/
  - menu.sh: whiptail-based menus calling settings/hosts core functions (no logic duplication).

Design notes for editable settings
- Read/write strategy for variables.nix
  - Keep the existing line-oriented sed/grep approach initially, but:
    - Always create a backup: variables.nix.bak-YYYYmmdd-HHMMSS
    - Validate target attribute name before write
    - Normalize strings (quote/unquote); preserve formatting when possible
  - Future: consider nix fmt or using nix eval + yj/json and round-trip with caution (optional).
- File validation
  - Resolve relative paths against $HOME/$PROJECT/ and $HOME when applicable.
  - Support glob/autocomplete later; initially require exact path.
- Installed/installable validation
  - Installed: command -v, or nix profile list, or which from ${pkgs.which}
  - Installable: membership in curated map; provide suggested package name.

CLI contracts (draft)
- Display
  - zcli settings                      # current behavior
  - zcli settings --json               # optional: machine-readable output later
  - zcli hosts-apps                    # list host-specific packages from host-packages.nix (M2)
- Edit
  - zcli settings set panelChoice <value>
  - zcli settings set browser <key> [--dry-run]
  - zcli settings set terminal <key> [--dry-run]
  - zcli settings set stylixImage <path> [--dry-run]
  - zcli settings set waybarChoice <path> [--dry-run]
  - zcli settings set animChoice <path> [--dry-run]
  - zcli settings --list-browsers
  - zcli settings --list-terminals
- Errors return non-zero and print a friendly hint.

TUI considerations (later)
- Whiptail wrappers that:
  - Present menus/selectors for browser/terminal from curated lists
  - File pickers for stylixImage/waybarChoice/animChoice (basic path prompt)
  - Confirm write and show a diff (using colordiff, if available)

Testing strategy
- Unit tests (bats) for:
  - Variable parsing/unquoting
  - File existence validators
  - Mapping validators for browser/terminal
  - Dry-run vs write behavior creates backups and avoids writes
- Integration tests (when feasible):
  - A temporary variables.nix sandbox mutated by set commands; verify idempotency and content

Milestones
- M1: settings edit core, validators, backups, dry-run; supported lists exposed
- M2: hosts-specific apps display from host-packages.nix using nix eval
- M3: refactor into modules (lib + features), zcli as dispatcher
- M4: optional TUI ‘settings’ menu covering the new edit paths

Risks and mitigations
- Sed/grep parsing fragility: constrain patterns with strong anchors; add tests; keep backups.
- Command availability: prefer ${pkgs.*}/bin paths in the generated script where possible.
- Permission/ownership of files under $HOME/$PROJECT: check writability and fail fast with guidance.

How an AI agent should proceed (when authorized)
1) Add curated maps in a new lib/validate.sh (browsers, terminals) and expose validator functions.
2) Implement settings set subcommands (non-interactive core) with:
   - Parse, validate, backup, write (or dry-run), re-verify.
3) Add flags to settings view for listing supported keys.
4) Implement hosts-specific apps view using nix eval; fall back to a readable error if eval path not available.
5) Add tests for validators and set flows; ensure backups are created correctly.
6) Only after these are stable, begin module split so CLI and TUI share the same core functions.

Progress status (as of 2025-09-02)
- Milestones
- M1: COMPLETE
    - Implemented editable settings with validation, backups, and --dry-run in features/settings.sh
    - Curated validators present in lib/validate.sh (browsers: google-chrome, google-chrome-stable, firefox, firefox-esr, brave, chromium, vivaldi, floorp; terminals: kitty, ghostty, alacritty, ptyxis)
    - Listing commands exposed via dispatcher help: `settings --list-browsers`, `settings --list-terminals`
    - Settings view updated: boolean sections now use variable names (e.g., gnomeEnable), and "(settable attributes)" was removed from section headers for consistency with editable settings.
  - M2: COMPLETE (initial parser implementation)
    - `zcli hosts-apps` implemented in features/hosts.sh using an awk-based parser over host-packages.nix
    - Enhancement still open: prefer nix eval path per plan when feasible
  - M3: COMPLETE
    - Dispatcher at modules/home/scripts/zcli.nix sources lib/* and features/*; features split exists (settings/hosts/rebuild/generations/diag/trim/doom/glances); libs present (args/common/nix/sys/validate)
- M4: PENDING
    - No tui/ module yet; whiptail/dialog layer not started

- Repository status
  - zcli-refactor branch has been merged into main and deleted (both local and remote).
  - All recent settings output adjustments are now present on main.

- Immediate To-Do items — current state
  1) Make settings editable: COMPLETE (features/settings.sh implements `settings set <attr> <value>` with validation, backups, dry-run)
  2) Supported browsers list: COMPLETE (lib/validate.sh + flags; note curated set differs slightly from initial proposal)
  3) Terminal validation: COMPLETE (lib/validate.sh + flags)
  4) Hosts-specific applications view: COMPLETE (parser-based); nix eval enhancement still TODO

- Acceptance criteria — status
  - Settings view still works; edits validated with backups and --dry-run: MET
  - Non-zero exit on validation failure with helpful errors: MET (returns 1 on invalid attr/values)
  - Supported browser/terminal lists discoverable via flags: MET
  - Hosts applications view lists host-specific additions: MET (via parser); nix eval variant: TODO

- Open items to resume next
  - Implement nix eval-based hosts-apps path and fall back to parser on failure
  - Add unit tests (bats) for validators, set flows, and dry-run/backup behavior
  - Optional: settings --json output
  - M4: implement basic TUI wrappers (whiptail) that call existing core functions without duplicating logic

Future Consideration: Move lib/ and features/
- Short answer
  - You can move lib/ and features/ under modules/home/scripts/ without breaking functionality as long as you update the dispatcher’s source paths. But unless you have a strong reason, keep lib/ and features/ at the repo root. They’re runtime assets for the zcli CLI, whereas modules/home/scripts/ is your Nix module that generates the zcli binary. Keeping them separate tends to be clearer.

- Detailed analysis
  - Why you might move
    - Co-locates all script-related bits under modules/home/scripts/ and reduces root clutter. There are currently no docs or other references, so the change is mechanical.
  - Cons of tighter coupling between Home Manager/Nix module and runtime CLI assets
    - Reuse and packaging friction
      - lib/ and features/ can be reused as a standalone zcli package, another flake, or outside Home Manager. Nesting them under modules/home/scripts/ suggests module-internals, making reuse less obvious and slightly harder later.
    - Accidental breakage during module refactors
      - The modules/ tree tends to be reorganized as your Home Manager or NixOS configs evolve. If lib/ and features/ live inside that tree, future renames or structure changes can silently break zcli runtime paths.
    - Store vs working-tree expectations
      - Teams often treat modules/ as declarative config edited to trigger rebuilds, while runtime scripts are iterated on without a rebuild cycle. Co-location can mislead contributors into treating scripts as module data or reviewers into conflating unrelated changes.
    - Tooling and evaluation confusion
      - Some editors/linters/pipelines assume modules/ contains .nix. Mixing bash under modules/ can confuse tooling filters (e.g., “run nixfmt over modules/”) or invite attempts to import those bash files in Nix evaluation because of their location.
    - Packaging scope creep
      - If you later produce flake outputs from modules/home/scripts, you may inadvertently drag along runtime files you didn’t intend, or vice versa. Keeping runtime code at the repo root creates a cleaner boundary and smaller, more focused outputs.
    - Cognitive overhead for maintainers
      - The common mental model is: modules/ = Nix expressions; lib/ + features/ = runtime CLI. Violating that convention adds small but persistent friction when navigating the repo.
  - Functional impact
    - Everything will still work if you update the dispatcher’s source paths. The downsides are architectural/maintenance concerns, not runtime blockers.

- If you decide to move them: recommended approach
  - Add a single base var in the zcli dispatcher to avoid path sprawl, then update all source paths to use it.
  - Example adjustment:

```bash
# Currently:
ZROOT_DIR="$HOME/$PROJECT"
VALIDATE_LIB="$ZROOT_DIR/lib/validate.sh"
FEATURE_SETTINGS="$ZROOT_DIR/features/settings.sh"
FEATURE_HOSTS="$ZROOT_DIR/features/hosts.sh"
# etc.

# After moving to modules/home/scripts/:
ZROOT_DIR="$HOME/$PROJECT"
SCRIPTS_DIR="$ZROOT_DIR/modules/home/scripts"

VALIDATE_LIB="$SCRIPTS_DIR/lib/validate.sh"
ARGS_LIB="$SCRIPTS_DIR/lib/args.sh"
NIX_LIB="$SCRIPTS_DIR/lib/nix.sh"
SYS_LIB="$SCRIPTS_DIR/lib/sys.sh"

FEATURE_SETTINGS="$SCRIPTS_DIR/features/settings.sh"
FEATURE_HOSTS="$SCRIPTS_DIR/features/hosts.sh"
FEATURE_REBUILD="$SCRIPTS_DIR/features/rebuild.sh"
FEATURE_GENS="$SCRIPTS_DIR/features/generations.sh"
FEATURE_DIAG="$SCRIPTS_DIR/features/diag.sh"
FEATURE_TRIM="$SCRIPTS_DIR/features/trim.sh"
FEATURE_DOOM="$SCRIPTS_DIR/features/doom.sh"
FEATURE_GLANCES="$SCRIPTS_DIR/features/glances.sh"
```

- Recommendation
  - Keep lib/ and features/ at the repo root unless you specifically want everything under modules/home/scripts for organizational reasons. If you move them, implement SCRIPTS_DIR indirection in the dispatcher so future moves are trivial.
