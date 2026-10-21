{
  pkgs,
  config,
  ...
}: let
  # v4l2loopback 0.15.4's `install` target delegates to the kernel's
  # `modules_install`, which runs depmod and writes modules.dep,
  # modules.symbols, modules.alias, ... into $out/lib/modules/<ver>/.
  # NixOS merges the kernel modules output and boot.extraModulePackages into
  # system.modulesTree via pkgs.aggregateModules (a buildEnv), so those
  # metadata files collide with the identical files shipped by
  # linux-<ver>-modules and the build fails with:
  #   pkgs.buildEnv error: two given paths contain a conflicting subpath
  #   `.../v4l2loopback-0.15.4/lib/modules/<ver>/modules.symbols` and
  #   `.../linux-<ver>-modules/lib/modules/<ver>/modules.symbols`
  #
  # Forwarding DEPMOD=true to the recursive make suppresses depmod so only
  # the .ko itself lands in the tree. This mirrors the upstream nixpkgs fix
  # (installFlags = [ "DEPMOD=true" ... ]).
  # TODO: drop this override once nixos-unstable carries the upstream fix.
  v4l2loopback = config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
    installFlags = (old.installFlags or []) ++ ["DEPMOD=true"];
  });
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["v4l2loopback"];
    extraModulePackages = [v4l2loopback];
    kernel.sysctl = {"vm.max_map_count" = 2147483642;};
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
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
