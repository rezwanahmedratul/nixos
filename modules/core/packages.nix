{
  inputs,
  pkgs,
  lib,
  host,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
  inherit (vars) barChoice;

  # Local build of synfetch (github:SXSLVT/synfetch).
  #
  # The upstream flake's package reads the deprecated `pkgs.stdenv.isLinux`
  # attribute, so pulling in `inputs.synfetch.packages.<system>.default` makes
  # every evaluation of this configuration print:
  #   evaluation warning: stdenv.isLinux is deprecated, use stdenv.hostPlatform.isLinux instead
  #
  # Rebuilding the same writeShellApplication here, using the script from the
  # input, keeps the tool and drops the warning. Remove this and go back to
  # `inputs.synfetch.packages.<system>.default` once upstream is fixed.
  synfetch = pkgs.writeShellApplication {
    name = "synfetch";
    runtimeInputs =
      with pkgs;
      [
        coreutils
        ncurses
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pciutils
        procps
      ];
    checkPhase = "";
    text = builtins.readFile "${inputs.synfetch}/synfetch";
  };
  # Noctalia-specific packages
  noctaliaPkgs =
    if barChoice == "noctalia"
    then
      with pkgs; [
        matugen # color palette generator needed for noctalia-shell
      ]
    else [];
in {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
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
  #nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  environment.systemPackages = with pkgs;
    [
      awww
      synfetch
    ]
    ++ noctaliaPkgs
    ++ [
      alejandra # nix formatter
      amfora # Fancy Terminal Browser For Gemini Protocol
      brave-origin # Brave Browser
      brightnessctl # For Screen Brightness Control
      cliamp # terminal music player
      cliphist # Clipboard manager using rofi menu
      cmatrix # Matrix Movie Effect In Terminal
      cowsay # Great Fun Terminal Program
      docker-compose # Allows Controlling Docker From A Single File
      duf # Utility For Viewing Disk Usage In Terminal
      dysk # Disk space util nice formattting
      eza # Beautiful ls Replacement
      ffmpeg # Terminal Video / Audio Editing
      file-roller # Archive Manager
      fd # find util needed for emacs but good util regardless vs. find
      #gearlever # Manage / run Appimages  # Causes install to fail b/c overlay
      icu # dep for gearlever
      gimp # Great Photo Editor
      gnumake # Needed for emacs
      google-chrome # default browser
      gpu-screen-recorder # needed for noctalia-shell
      power-profiles-daemon # needed for noctalia-shell power cycle
      mesa-demos # needed for inxi diag util
      tuigreet # The Login Manager (Sometimes Referred To As Display Manager)
      htop # Simple Terminal Based System Monitor
      eog # For Image Viewing
      inxi # CLI System Information Tool
      killall # For Killing All Instances Of Programs
      libnotify # For Notifications
      lm_sensors # Used For Getting Hardware Temps
      lolcat # Add Colors To Your Terminal Command Output
      lshw # Detailed Hardware Information
      mdcat # CLI markdown parser
      mpv # Incredible Video Player
      ncdu # Disk Usage Analyzer With Ncurses Interface
      nixfmt # Nix Formatter
      nwg-displays # configure monitor configs via GUI
      nwg-drawer # Application launcher for wayland
      nwg-dock-hyprland # Dock for hyprland
      nwg-menu # App menu for waybar
      onefetch # provides zsaneyos build info on current system
      pandoc # format MD to HTML for cheatsheet parser
      pavucontrol # For Editing Audio Levels & Devices
      pciutils # Collection Of Tools For Inspecting PCI Devices
      picard # For Changing Music Metadata & Getting Cover Art
      pkg-config # Wrapper Script For Allowing Packages To Get Info On Others
      playerctl # Allows Changing Media Volume Through Scripts
      rhythmbox # audio player
      ripgrep # Improved Grep
      sqlite # needed for emaacs
      socat # Needed For Screenshots
      ttop # top with histogram
      unrar # Tool For Handling .rar Files
      unzip # Tool For Handling .zip Files
      usbutils # Good Tools For USB Devices
      upower # noctalia shell battery
      #uwsm # Universal Wayland Session Manager (optional must be enabled)
      v4l-utils # Used For Things Like OBS Virtual Camera
      waybar
      waypaper # Change wallpaper
      wget # Tool For Fetching Files With Links
      ytmdl # Tool For Downloading Audio From YouTube
      python3 # Python 3 programming language
      zenith # like htop but more
      isd # system util
      netscanner # find devices on network
      lstr # Tree alternative
      cointop # top for ctrypto
      bottom # top alternative
      gotop # Another top
    ];
}
