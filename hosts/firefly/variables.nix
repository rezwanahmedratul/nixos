{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "Rezwan Ahmed Ratul";
  gitEmail = "rezwanahmedratul007@gmail.com";

  # Set Displau Manager
  # `tui` for Text login
  # `sddm` for graphical GUI (default)
  # SDDM background is set with stylixImage
  displayManager = "tui";
  # Set Power Manager
  # `tlp` for laptops (default)
  # `auto-cpufreq` for desktops (more aggressive performance)
  # `ppd` for power-profiles-daemon (more aggressive performance)
  # `none` to disable power management
  powerManager = "auto-cpufreq";

  # Emable/disable bundled applications
  tmuxEnable = true; # Terminal Multiplexer
  alacrittyEnable = true;
  weztermEnable = false;
  ghosttyEnable = false;
  vscodeEnable = true; # Microsoft VSCode with telemetry
  zed-editorEnable = false;
  vscodiumEnable = false; # Open-source build of VSCode without telemetry
  antigravityEnable = true; # Google port of vscodium
  # Note: This is evil-helix with VIM keybindings by default
  helixEnable = false;
  #To install: Enable here, zcli rebuild, then run zcli doom install
  doomEmacsEnable = false;
  obsEnable = false;

  # Available Options:
  # Kitty, ghostty, wezterm, aalacrity
  # Note: kitty, wezterm, alacritty have to be enabled in `variables.nix`
  # Setting it here does not enable it. Kitty is installed by default
  terminal = "alacritty"; # Set Default System Terminal

  # Python development tools are included by default

  # Hyprland Settings
  # Examples:
  # extraMonitorSettings = "monitor = Virtual-1,1920x1080@60,auto,1";
  # extraMonitorSettings = "monitor = HDMI-A-1,1920x1080@60,auto,1";
  # You can configure multiple monitors.
  # Inside the quotes, create a new line for each monitor.
  # extraMonitorSettings = "monitor = eDP-1, 1920x1200@60, 0x0, 1.20";

  # Bar/Shell Settings
  # Choose between noctalia or waybar
  barChoice = "noctalia"; # Set Bar Choice
  # barChoice = "waybar"; # Set Bar Choice

  # Waybar Settings (used when barChoice = "waybar")
  clock24h = false;

  # Program Options
  # Set Default Browser (google-chrome-stable for google-chrome)
  # This does NOT install your browser
  # You need to install it by adding it to the `packages.nix`
  # or as a flatpak
  browser = "zen-beta";
  #browser = "brave";

  # Host-level default applications (picked up by Home Manager xdg.mimeApps)
  # Uncomment and adjust the .desktop IDs to set per-host defaults.
  mimeDefaultApps = {
    #   # PDFs
    "application/pdf" = ["okular.desktop"]; # change to your preferred reader
    "application/x-pdf" = ["okular.desktop"]; # legacy alias

    # Web browser
    "x-scheme-handler/http" = ["zen-beta.desktop"]; # or brave-browser.desktop, firefox.desktop, etc.
    "x-scheme-handler/https" = ["zen-beta.desktop"];
    "text/html" = ["zen-beta.desktop"];

    # Text files
    "text/plain" = ["nvim.desktop"]; # or code.desktop, org.gnome.TextEditor.desktop

    # Images and video
    "image/png" = ["qimgv.desktop"]; # or org.gnome.eog.desktop
    "image/jpeg" = ["qimgv.desktop"];
    "image/jpg" = ["qimgv.desktop"];
    "image/gif" = ["qimgv.desktop"];
    "image/webp" = ["qimgv.desktop"];
    "video/mp4" = ["mpv.desktop"]; # or vlc.desktop

    # Archives
    "application/zip" = ["org.gnome.FileRoller.desktop"]; # or xarchiver.desktop, peazip.desktop

    # Folders (file manager)
    "inode/directory" = ["org.gnome.Nautilus.desktop"]; # or org.gnome.Nautilus.desktop, org.kde.dolphin.desktop
  };

  keyboardLayout = "us";
  keyboardVariant = "";
  consoleKeyMap = "us";

  # For hybrid support (Intel/NVIDIA Prime or AMD/NVIDIA)
  intelID = "PCI:1:0:0";
  amdgpuID = "PCI:5:0:0";
  nvidiaID = "PCI:0:2:0";

  # Enable NFS
  enableNFS = true;

  # Enable Printing Support
  printEnable = false;

  # Enable Thunar GUI File Manager
  # Yazi is alternate File Manager
  thunarEnable = false;

  # Themes, waybar and animation.
  #  Only uncomment your selection
  # The others much be commented out.

  # Set Stylix Image
  # This will set your color palette
  # Default background
  # Add new images to ~/zaneyos/wallpapers
  #stylixImage = ../../wallpapers/mountainscapedark.jpg;
  #stylixImage = ../../wallpapers/AnimeGirlNightSky.jpg;
  #stylixImage = ../../wallpapers/Anime-Purple-eyes.png;
  #stylixImage = ../../wallpapers/Rainnight.jpg;
  #stylixImage = ../../wallpapers/zaney-wallpaper.jpg;
  #stylixImage = ../../wallpapers/nix-wallpaper-stripes-logo.png;
  #stylixImage = ../../wallpapers/beautifulmountainscape.jpg;
  #stylixImage = ../../wallpapers/mountainscapedark.jpg;
  #stylixImage = ../../wallpapers/Skyscraper.jpg;
  #stylixImage = ../../wallpapers/fuji.jpg;
  # stylixImage = ../../wallpapers/daniel-leone-v7daTKlZzaw-unsplash.jpg;
  # stylixImage = ../../wallpapers/gruv-portal-cake.png;
  stylixImage = ../../wallpapers/call-it-a-day.jpg;

  # Set Waybar
  #  Available Options:
  #waybarChoice = ../../modules/home/waybar/waybar-curved.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-ddubs.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-ddubs-2.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-simple.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-dwm.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-dwm-2.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-nekodyke.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jerry.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-TheBlackDon.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-tony.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-ddubsos-v1.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-mecha.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jak-catppuccin.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jak-ml4w-modern.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jak-oglo-simple.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jwt-catppuccin.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jwt-transparent.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-jwt-ultradark.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-pctrade-catppuccin.nix;
  #waybarChoice = ../../modules/home/waybar/waybar-mangowc-jak-catppuccin.nix;
  waybarChoice = ../../modules/home/waybar/waybar-old-ddubsos.nix;

  # Set Animation style
  # Available options are:
  #animChoice = ../../modules/home/hyprland/animations-def.nix;
  #animChoice = ../../modules/home/hyprland/animations-end4.nix;
  #animChoice = ../../modules/home/hyprland/animations-end4-slide.nix;
  #animChoice = ../../modules/home/hyprland/animations-end-slide.nix;
  animChoice = ../../modules/home/hyprland/animations-dynamic.nix;
  #animChoice = ../../modules/home/hyprland/animations-moving.nix;
  #animChoice = ../../modules/home/hyprland/animations-hyde-optimized.nix;
  #animChoice = ../../modules/home/hyprland/animations-mahaveer-me-1.nix;
  #animChoice = ../../modules/home/hyprland/animations-mahaveer-me-2.nix;
  #animChoice = ../../modules/home/hyprland/animations-ml4w-classic.nix;
  #animChoice = ../../modules/home/hyprland/animations-ml4w-fast.nix;
  #animChoice = ../../modules/home/hyprland/animations-ml4w-high.nix;

  # Set network hostId if required (needed for zfs)
  # Otherwise leave as-is
  hostId = "5ab03f50";
}
