{
  pkgs,
  inputs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPkg = inputs.noctalia.packages.${system}.default;
  noctaliaServiceEntrypoint = pkgs.writeShellScript "noctalia-service-entrypoint" ''
    set -euo pipefail

    ${pkgs.psmisc}/bin/killall -q waybar 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x waybar 2>/dev/null || true
    ${pkgs.psmisc}/bin/killall -q swaync 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x swaync 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x noctalia 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -f noctalia-shell 2>/dev/null || true
    ${pkgs.coreutils}/bin/sleep 0.4

    exec ${noctaliaPkg}/bin/noctalia
  '';
in {
  home.packages = [noctaliaPkg];
  systemd.user.services.noctalia = {
    Unit = {
      Description = "Noctalia panel service";
      PartOf = ["hyprland-session.target"];
      After = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${noctaliaServiceEntrypoint}";
      Restart = "on-failure";
      RestartSec = "1";
    };
  };

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar (disabled by Noctalia)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
    Install = {
      WantedBy = [];
    };
  };

  # Ensure declarative v5 config directory exists
  home.activation.ensureNoctaliaConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    DEST="$HOME/.config/noctalia"

    if [ ! -d "$DEST" ]; then
      $DRY_RUN_CMD mkdir -p "$DEST"
    fi
  '';
}
