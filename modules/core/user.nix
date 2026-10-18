{
  pkgs,
  inputs,
  username,
  host,
  profile,
  ...
}: let
  zaneyos = import ../../hosts/${host}/variables.nix;
  inherit (zaneyos) gitUsername;
in {
  programs.zsh.enable = true;
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = false;
    backupFileExtension = "backup";
    extraSpecialArgs = {inherit inputs username host profile pkgs zaneyos;};
    users.${username} = {
      imports = [./../home];
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "23.11";
      };
    };
  };
  users.mutableUsers = true;
  users.users.${username} = {
    isNormalUser = true;
    description = "${gitUsername}";
    extraGroups = [
      "adbusers"
      "docker" #access to docker as non-root
      "libvirtd" #Virt manager/QEMU access
      "lp"
      "networkmanager"
      "scanner"
      "wheel" #sudo access
      "vboxusers" #Virtual Box
      "dialout" #Serial Port Access
      "uucp" #Modem Access
    ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };
  nix.settings.allowed-users = ["${username}"];
}
