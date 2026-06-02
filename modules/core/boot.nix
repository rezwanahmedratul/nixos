{
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isx86_64 isAarch64;
in {
  boot = {
    kernelPackages =
      if isx86_64
      then pkgs.linuxPackages_latest
      else pkgs.linuxPackages_zen;

    kernelModules = ["v4l2loopback"];
    extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};

    loader = {
      grub.enable = false;
      systemd-boot.enable = isx86_64;
      efi.canTouchEfiVariables = true;

      # this is the bootloader used for raspberry pi 4.
      # we will presumably need more fine-grained configuration for what
      # bootloader to use.
      generic-extlinux-compatible.enable = isAarch64;
    };

    # Appimage Support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
    plymouth.enable = false;
  };
}
