{
  inputs,
  host,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
in {
  imports =
    [
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
    ]
    # Display manager
    ++ (
      if vars.displayManager == "tui"
      then [./ly.nix]
      else [./sddm.nix]
    )
    # Power manager (with "none" option)
    ++ (
      if vars.powerManager == "auto-cpufreq"
      then [./auto-cpufreq.nix]
      else if vars.powerManager == "tlp"
      then [./tlp.nix]
      else if vars.powerManager == "ppd"
      then [./power-profiles-deamon.nix]
      else []
    )
    ++ [
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
      ./fingerprint.nix
      ./shadowsocks.nix
      #./smb.nix
      ./limit.nix
      inputs.stylix.nixosModules.stylix
    ];
}
