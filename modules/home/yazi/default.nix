{lib, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  home.file.".config/yazi" = {
    source = ./yazi-src;
    recursive = true;
  };

  # Migration: older generations linked plugin directories directly to /nix/store.
  # When switching to recursive file linking, Home Manager may try to move files
  # inside those symlinked directories and fail with "Read-only file system".
  home.activation.yaziPluginSymlinkMigration = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    set -eu

    plugins_dir="$HOME/.config/yazi/plugins"

    if [ -L "$plugins_dir" ]; then
      target="$(readlink -f "$plugins_dir" || true)"
      case "$target" in
        /nix/store/*)
          $DRY_RUN_CMD rm -f "$plugins_dir"
          ;;
      esac
    fi

    if [ ! -d "$plugins_dir" ]; then
      $DRY_RUN_CMD mkdir -p "$plugins_dir"
    fi

    for plugin_link in "$plugins_dir"/*; do
      [ -e "$plugin_link" ] || continue
      [ -L "$plugin_link" ] || continue

      target="$(readlink -f "$plugin_link" || true)"
      case "$target" in
        /nix/store/*)
          $DRY_RUN_CMD rm -f "$plugin_link"
          ;;
      esac
    done
  '';
}
