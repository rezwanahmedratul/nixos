_: {
  # Welcome to your ZaneyOS configuration!
  # This block is where you can customize your NixOS experience.
  #
  # For a comprehensive list of all available options, their descriptions,
  # and default values, please refer to the following file:
  # ../../modules/options.nix
  #
  # You can override any of those options here. Most settings are optional
  # and can be removed to use the project defaults.
  zaneyos = {
    # Git Configuration
    gitUsername = "Don Williams";
    gitEmail = "don.e.williams@gmail.com";

    # does not have to be the same as the directory name, but
    # would be common
    hostName = "zaneyos-next";

    gpuProfile = "vm";

    # Set Display Manager
    # `tui` for Text login
    # `sddm` for graphical GUI (default)
    # SDDM background is set with stylixImage
    displayManager = "tui";

    # Emable/disable bundled applications
    tmuxEnable = true;
    alacrittyEnable = true;
    weztermEnable = true;
    ghosttyEnable = true;
    vscodeEnable = false;
    # Note: This is evil-helix with VIM keybindings by default
    helixEnable = false;
    #To install: Enable here, zcli rebuild, then run zcli doom install
    doomEmacsEnable = true;
    # Neovim config: "nixvim" | "nvf"
    neovimConfig = "nixvim";

    # Bar/Shell Settings
    # Choose between noctalia or waybar
    barChoice = "noctalia";

    # Waybar Settings (used when barChoice = "waybar")
    clock24h = false;

    # Program Options
    # Set Default Browser (google-chrome-stable for google-chrome)
    # This does NOT install your browser
    # You need to install it by adding it to the `packages.nix`
    # or as a flatpak
    browser = "google-chrome-stable";

    # Default applications for this host (written to ~/.config/mimeapps.list)
    # Uncomment and adjust to set per-host defaults.
    # mimeDefaultApps = {
    #   # PDFs
    #   "application/pdf" = ["okular.desktop"];
    #   "application/x-pdf" = ["okular.desktop"];
    #   # Web browser
    #   "x-scheme-handler/http"  = ["google-chrome.desktop"];  # or brave-browser.desktop, firefox.desktop
    #   "x-scheme-handler/https" = ["google-chrome.desktop"];
    #   "text/html"              = ["google-chrome.desktop"];
    #   # Text files
    #   "text/plain" = ["nvim.desktop"];             # or code.desktop, org.gnome.TextEditor.desktop
    #   # Images and video
    #   "image/png" = ["imv.desktop"];               # or org.gnome.eog.desktop
    #   "video/mp4" = ["mpv.desktop"];               # or vlc.desktop
    #   # Folders (file manager)
    #   "inode/directory" = ["thunar.desktop"];      # Thunar; or org.gnome.Nautilus.desktop, org.kde.dolphin.desktop
    # };

    # Available Options:
    # Kitty, ghostty, wezterm, aalacrity
    # Note: kitty, wezterm, alacritty have to be enabled in `variables.nix`
    # Setting it here does not enable it. Kitty is installed by default
    terminal = "kitty"; # Set Default System Terminal

    keyboardLayout = "us";
    keyboardVariant = "";
    consoleKeyMap = "us";

    # Themes, waybar and animation.
    # Set Stylix Image
    # This will set your color palette
    # Default background
    # Add new images to ~/zaneyos/wallpapers
    #stylixImage = ../../wallpapers/mountainscapedark.jpg;
    #stylixImage = ../../wallpapers/AnimeGirlNightSky.jpg;
    #stylixImage = ../../wallpapers/Anime-Purple-eyes.png;
    stylixImage = ../../wallpapers/Rainnight.jpg;
    #stylixImage = ../../wallpapers/zaney-wallpaper.jpg;
    #stylixImage = ../../wallpapers/nix-wallpapers-strips-logo.jpg;
    #stylixImage = ../../wallpapers/beautifulmountainscape.jpg;

    # Set Waybar
    #  Available Options:
    #waybarChoice = ../../modules/home/waybar/waybar-curved.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jak-catppuccin.nix;
    waybarChoice = ../../modules/home/waybar/waybar-jak-catppuccin-v2.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-ddubs-2.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-ddubs.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-simple.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-dwm.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-dwm-2.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jerry.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-nekodyke.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-TheBlackDon.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-tony.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-ddubsos-v1.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-mecha.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jak-ml4w-modern.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jak-oglo-simple.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jwt-catppuccin.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jwt-transparent.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-jwt-ultradark.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-pctrade-catppuccin.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-mangowc-jak-catppuccin.nix;
    #waybarChoice = ../../modules/home/waybar/waybar-old-ddubsos.nix;

    # Set Animation style
    # Available options are:
    #animChoice = ../../modules/home/hyprland/animations-def.nix;
    #animChoice = ../../modules/home/hyprland/animations-end4.nix;
    #animChoice = ../../modules/home/hyprland/animations-end4-slide.nix;
    #animChoice = ../../modules/home/hyprland/animations-end-slide.nix;
    #animChoice = ../../modules/home/hyprland/animations-dynamic.nix;
    #animChoice = ../../modules/home/hyprland/animations-moving.nix;
    #animChoice = ../../modules/home/hyprland/animations-hyde-optimized.nix;
    #animChoice = ../../modules/home/hyprland/animations-mahaveer-me-1.nix;
    #animChoice = ../../modules/home/hyprland/animations-mahaveer-me-2.nix;
    animChoice = ../../modules/home/hyprland/animations-ml4w-classic.nix;
    #animChoice = ../../modules/home/hyprland/animations-ml4w-fast.nix;
    #animChoice = ../../modules/home/hyprland/animations-ml4w-high.nix;

    # Set network hostId if required (needed for zfs)
    # Otherwise leave as-is
    hostId = "5ab03f50";
  };
}
