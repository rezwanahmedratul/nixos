{configs, pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    #  Add local packages here
  ];

  # Add host specific flatpaks here
  services = {
    flatpak = {
      packages = [
      ];
    };
  };
}
