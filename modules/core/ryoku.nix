{
  host,
  lib,
  pkgs,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  isRyoku = (vars.barChoice or "") == "ryoku" || (vars.ryokuEnable or false);
in {
  # Prevent conflicts between Ryoku's default power-profiles-daemon and host powerManager (e.g. TLP)
  services.power-profiles-daemon.enable = lib.mkForce (vars.powerManager == "ppd");

  # Declarative binary cache for Ryotunes and Quickshell components
  nix.settings = lib.mkIf isRyoku {
    substituters = [
      "https://ryotunes.cachix.org"
    ];
    trusted-public-keys = [
      "ryotunes.cachix.org-1:ZfG/D567QxP8Z015oB7lW+k4/t78y9eE094r8zKjEBE="
    ];
  };

  # Ensure PAM services for Hyprland screen lockers are available
  security.pam.services.hyprlock = lib.mkIf isRyoku {};
}
