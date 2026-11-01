{
  pkgs,
  lib,
  ...
}: let
  # Using nixpkgs package by default
  noctaliaPkg = pkgs.noctalia;

  # To build the latest version from source via flake input:
  # 1. Re-enable the noctalia input in flake.nix
  # 2. Comment out the pkgs.noctalia line above
  # 3. Uncomment the two lines below:
  # system = pkgs.stdenv.hostPlatform.system;
  # noctaliaPkg = inputs.noctalia.packages.${system}.default;
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

  # Declarative Noctalia settings
  xdg.configFile."noctalia/settings.toml".source = ./noctalia/settings.toml;

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

  # Ensure declarative config and synchronize state
  home.activation.ensureNoctaliaConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    STATE_DIR="$HOME/.local/state/noctalia"
    mkdir -p "$STATE_DIR"

    # Synchronize declarative settings to state so Noctalia restores exact config on switch
    if [ -f "$HOME/.config/noctalia/settings.toml" ]; then
      cp -f "$HOME/.config/noctalia/settings.toml" "$STATE_DIR/settings.toml"
      chmod 644 "$STATE_DIR/settings.toml" 2>/dev/null || true
    fi

    # Tell running Noctalia instance to reload its config if active
    if command -v noctalia >/dev/null 2>&1 && pgrep -x noctalia >/dev/null 2>&1; then
      noctalia msg config-reload >/dev/null 2>&1 || true
    fi
  '';
}
