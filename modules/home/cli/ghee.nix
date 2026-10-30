# ghee - "git, as a place you leave open": a TUI over every repo in a folder.
#
# Comes from the `ghee` flake input (codeberg.org/justaguylinux/ghee), surfaced
# as `pkgs.ghee` by modules/core/overlays.nix. The package wraps git and
# openssh onto its own PATH, and runs $VISUAL/$EDITOR for editing.
#
# Usage: `ghee` (repo you are in, else $GHEE_BASE) or `ghee ~/Code`.
{
  pkgs,
  ...
}: {
  home.packages = [pkgs.ghee];

  # Handy defaults; uncomment to set the folder ghee opens when run with no
  # argument, or an alias for a common entry point.
  # home.sessionVariables.GHEE_BASE = "$HOME/Code";
  # home.shellAliases.g = "ghee";
}
