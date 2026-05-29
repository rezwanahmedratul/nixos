{
  pkgs,
  ...
}: {

  services.auto-cpufreq = {
    enable = true;

    settings = {
      charger = {
        governor = "powermode";
        turbo = "never";
      };

      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };
}
