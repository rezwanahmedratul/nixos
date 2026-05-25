{
  pkgs,
  ...
}: {

  services.auto-cpufreq = {
    enable = true;

    settings = {
      charger = {
        governor = "powersave";
        turbo = "never";
      };

      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };
}
