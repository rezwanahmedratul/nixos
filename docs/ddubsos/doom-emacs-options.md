# Doom Emacs on NixOS: options and recommended path

Goals
- Keep your current Doom config (bindings, plugins, etc.) as-is
- Reliable updates tied to Nix rebuilds or flake updates
- Prefer Emacs daemon + emacsclient workflow (not strictly required)

Summary of options
1) Minimal, reliable autosync (recommended starting point)
   - Keep Doom Emacs installed in ~/.emacs.d (as today)
   - Keep ~/.doom.d managed by Home Manager (already in repo)
   - Enable the user-level Emacs daemon via Home Manager
   - Hook a doom sync -u into Home Manager activation so every rebuild refreshes Doom packages/autoloads
   - Pros: Small change, uses your existing setup, works with your zcli doom commands
   - Cons: Doom core (doomemacs repo) still lives outside Nix and won’t be pinned; you’ll occasionally run zcli doom update or doom upgrade for core updates

2) Fully declarative via nix-doom-emacs
   - Add the nix-doom-emacs flake input and module
   - Declare your Doom modules and extra packages in Nix; nix builds the Emacs+packages closure
   - Pros: Fully reproducible; Doom and its packages are pinned by flake.lock; rebuilds update as inputs change
   - Cons: Requires migrating pieces of your packages.el/config to Nix expressions or wiring your existing files into nix-doom-emacs’ module options; initial setup effort
   - Notes: Your ~/.doom.d content can still be preserved or layered, but the package resolution moves into Nix. This is a stronger guarantee and eliminates “drift” in ~/.emacs.d.

3) Emacs server + mixed approach
   - Run Emacs daemon (as in 1) but use a pinned Doom checkout via a flake-controlled fetch (e.g., fetchFromGitHub in Nix) and point EMACSDIR to that path
   - Pros: Keeps a familiar ~/.doom.d workflow while pinning Doom core; updates when the flake updates
   - Cons: You still run package syncs; and you need to carefully reference a read-only store path for doom core (no git pulls there). Usually combine with a wrapper that sets DOOMDIR and XDG paths to writable locations for cache/build

What I implemented in this branch
- Enabled Emacs user service (daemon) and default EDITOR to emacsclient
- Switched to emacs-pgtk (better Wayland/GTK integration)
- Added a Home Manager activation hook that runs:
  - ~/.emacs.d/bin/doom sync -u
  - This ensures your Doom autoloads and packages are refreshed each rebuild
- Removed Doom-specific commands from zcli to reduce complexity (Doom is now a standard feature via Home Manager)

How to try it
- Rebuild: sudo nixos-rebuild switch --flake .#<your-host>
- Start a client GUI: emacsclient -c
- If Doom isn’t installed yet (first-time only):
  1) git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.emacs.d
  2) ~/.emacs.d/bin/doom install
  3) Rebuild again to benefit from autosync

Caveats
- doom sync -u will only run if ~/.emacs.d/bin/doom exists. First-time installs still require get-doom or zcli doom install
- This does not pin Doom core; if you want fully pinned Doom, consider moving to nix-doom-emacs (Option 2)

Next steps (optional)
- Wire nix-doom-emacs as an input and prototype a declarative module for a single host/user
- If you like it, migrate more of the config. Otherwise, keep Option 1 and continue to rely on HM activation + zcli for updates

