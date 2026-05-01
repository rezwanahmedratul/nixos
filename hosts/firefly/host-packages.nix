{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    #  Add local pacakaged here
  ];
  # Add host specific flatpaks here
  services = {
    flatpak = {
      packages = [
      ];
    };
  };
}
