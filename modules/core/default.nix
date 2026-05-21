{
  inputs,
  host,
  ...
}: let
  # Import the host-specific variables.nix
  vars = import ../../hosts/${host}/variables.nix;
in {
  imports = [
    ./boot.nix
    ./flatpak.nix
    ./fonts.nix
    ./hardware.nix
    ./network.nix
    ./nfs.nix
    ./nh.nix
    ./quickshell.nix
    ./packages.nix
    ./printing.nix
    ./recording.nix
    # Conditionally import the display manager module
    (
      if vars.displayManager == "tui"
      then ./ly.nix
      else ./sddm.nix
    )
    (
      if vars.powerManager == "auto-cpufreq"
      then ./auto-cpufreq.nix
      else ./tlp.nix
    )
    ./security.nix
    ./services.nix
    ./steam.nix
    ./stylix.nix
    ./syncthing.nix
    ./system.nix
    ./thunar.nix
    ./user.nix
    ./virtualisation.nix
    ./xserver.nix
    ./cachix.nix
    #./auto-cpufreq.nix
    ./fingerprint.nix
    ./shadowsocks.nix
    inputs.stylix.nixosModules.stylix
  ];
}
