{configs, pkgs, ...}: {

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


  services.auto-cpufreq.enable = false;
  services.auto-cpufreq.settings = {
    battery = {
       governor = "powersave";
       turbo = "never";
    };
    charger = {
       governor = "performance";
       turbo = "auto";
    };
  };


}
