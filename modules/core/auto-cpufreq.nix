{
  inputs,
  pkgs,
  ...
}: {
  programs.auto-cpufreq.enable = true;
  programs.auto-cpufreq.settings = {
    charger = {
      governor = "powersave";
      turbo = "never";
    };

    battery = {
      governor = "powersave";
      turbo = "never";
    };
  };
}
