{
  inputs,
  host,
  lib,
  pkgs,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  isRyoku = (vars.barChoice or "") == "ryoku" || (vars.ryokuEnable or false);
in {
  imports = [
    inputs.ryoku.nixosModules.default
  ];

  programs.ryoku = {
    enable = isRyoku;
    defaultCompositor = "hyprland";
    browser = null; # Defer default browser to host settings (e.g. Zen Browser)
    shell = "zsh"; # Preserve user's Zsh shell configuration
    binaryCache.enable = true;
    updateFlake = "/home/ratul/nixos";
    updateInput = "ryoku";
  };

  # Prevent conflicts between Ryoku's default power-profiles-daemon and host powerManager (e.g. TLP)
  services.power-profiles-daemon.enable = lib.mkForce (vars.powerManager == "ppd");
}

