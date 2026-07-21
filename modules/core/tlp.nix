{
  config,
  pkgs,
  ...
}: {
  services.tlp = {
    enable = true;

    settings = {
      # General
      TLP_AUTO_SWITCH = 0;
      TLP_DEFAULT_MODE = "SAV";

      # CPU driver mode
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_DRIVER_OPMODE_ON_SAV = "active";

      # CPU governor
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";

      # Energy perf policy
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "balance-power";

      # CPU performance limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;
      CPU_MIN_PERF_ON_SAV = 0;
      CPU_MAX_PERF_ON_SAV = 50;

      # Boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_SAV = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_SAV = 0;

      # Platform profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      # Intel GPU
      INTEL_GPU_MIN_FREQ_ON_AC = 100;
      INTEL_GPU_MIN_FREQ_ON_BAT = 100;
      INTEL_GPU_MAX_FREQ_ON_AC = 1400;
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1500;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1000;

      # Devices
      DEVICES_TO_ENABLE_ON_STARTUP = "wifi bluetooth";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "nfc wifi wwan";
    };
  };

  # environment.systemPackages = with pkgs; [
  #   tlp-pd
  # ];

  # systemd.services.tlp-pd = {
  #   wantedBy = ["multi-user.target"];
  #   after = ["tlp.service"];

  #   serviceConfig = {
  #     ExecStart = "${pkgs.tlp-pd}/bin/tlp-pd";
  #     Restart = "always";
  #   };
  # };

  # #Optional but recommended
  # powerManagement.enable = true;
}
