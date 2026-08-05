{
  inputs,
  pkgs,
  host,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  inherit (vars) barChoice;
  # Noctalia-specific packages
  noctaliaPkgs =
    if barChoice == "noctalia"
    then
      with pkgs; [
        matugen # color palette generator needed for noctalia-shell
        #app2unit # launcher for noctalia-shell
        gpu-screen-recorder # needed for nnoctalia-shell
      ]
    else [];
in {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    kdeconnect.enable = true; # KDE Connect For Phone Integration
    firefox.enable = false; # Firefox is not installed by default
    hyprland = {
      enable = true; # set this so desktop file is created
      withUWSM = false;
    };
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    hyprlock.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = ["openssl-1.1.1w"];

  environment.systemPackages = with pkgs;
    [
      awww
      inputs.synfetch.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ noctaliaPkgs
    ++ [
      alejandra # nix formatter
      appimage-run # Needed For AppImage Support
      brave # Brave Browser
      brightnessctl # For Screen Brightness Control
      duf # Utility For Viewing Disk Usage In Terminal
      dysk # Disk space util nice formattting
      eza # Beautiful ls Replacement
      ffmpeg # Terminal Video / Audio Editing
      file-roller # Archive Manager
      gearlever # Manage / run Appimages
      icu # dep for gearlever
      gpu-screen-recorder # needed for nnoctalia-shell
      mesa-demos # needed for inxi diag util
      tuigreet # The Login Manager (Sometimes Referred To As Display Manager)
      htop # Simple Terminal Based System Monitor
      killall # For Killing All Instances Of Programs
      libnotify # For Notifications
      lm_sensors # Used For Getting Hardware Temps
      lolcat # Add Colors To Your Terminal Command Output
      mpv # Incredible Video Player
      nixfmt # Nix Formatter
      nwg-displays # configure monitor configs via GUI
      rustc
      cargo
      google-chrome # Google Chrome Browser
      docker # Docker For Containerization
      docker-compose # Docker Compose For Containerization
      #nwg-dock-hyprland # Dock for hyprland
      #nwg-menu # App menu for waybar
      onefetch # provides zsaneyos build info on current system
      pavucontrol # For Editing Audio Levels & Devices
      pciutils # Collection Of Tools For Inspecting PCI Devices
      playerctl # Allows Changing Media Volume Through Scripts
      rhythmbox # audio player
      socat # Needed For Screenshots
      unrar # Tool For Handling .rar Files
      unzip # Tool For Handling .zip Files
      usbutils # Good Tools For USB Devices
      upower # noctalia shell battery
      uwsm # Universal Wayland Session Manager (optional must be enabled)
      waypaper # Change wallpaper
      wget # Tool For Fetching Files With Links
      python3 # Python 3 programming language
      telegram-desktop
      nautilus
      freerdp
      kdePackages.krdc
      kdePackages.okular
      localsend
      gcc
      gdb
      cmake
      gnumake
      libreoffice
      typst
      jq
      slurp
      hyprpicker
      tesseract
      gnome-calculator
      coreutils
      gnugrep
      gawk
      procps
      qimgv
      azuredatastudio
      distrobox
    ];
}
