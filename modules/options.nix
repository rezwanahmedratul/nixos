{lib, ...}:
with lib; {
  options.zaneyos = {
    # Git Configuration ( For Pulling Software Repos )
    gitUsername = mkOption {
      type = types.str;
      example = "Tyler Kelley";
      description = "Git username for configuration.";
    };
    gitEmail = mkOption {
      type = types.str;
      example = "tylerzanekelley@gmail.com";
      description = "Git email for configuration.";
    };
    hostName = mkOption {
      type = types.str;
      description = "Machine hostname, can have .local suffix or a fqdn if needed";
      example = "hostname";
    };

    # Set Display Manager
    # `tui` for Text login
    # `sddm` for graphical GUI (default)
    # SDDM background is set with stylixImage
    displayManager = mkOption {
      type = types.enum ["tui" "sddm"];
      default = "sddm";
      description = "Display manager to use.";
    };

    gpuProfile = mkOption {
      type = types.enum ["amd" "nvidia" "nvidia-laptop" "amd-nvidia-hybrid" "intel" "vm"];
      example = "nvidia";
      description = "GPU profile for drivers.";
    };

    localHardwareClock = mkOption {
      type = types.bool;
      default = false;
      description = "Set hardware clock to local time for better interop with some dual boot or vm setups.";
    };

    # Enable/disable bundled applications
    tmuxEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable tmux.";
    };
    alacrittyEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Alacritty.";
    };
    weztermEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable WezTerm.";
    };
    ghosttyEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Ghostty.";
    };
    vscodeEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable VSCode.";
    };
    # Note: This is evil-helix with VIM keybindings by default
    helixEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Helix.";
    };
    # To install: Enable here, zcli rebuild, then run zcli doom install
    doomEmacsEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Doom Emacs.";
    };
    neovimConfig = mkOption {
      type = types.enum ["nixvim" "nvf"];
      default = "nixvim";
      description = "Select Neovim configuration (nixvim or nvf).";
    };
    obsStudioEnable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable OBS Studio.";
    };
    # Python development tools
    pythonEnable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Python development tools.";
    };

    # Hyprland Settings
    # You can configure multiple monitors.
    # Inside the quotes, create a new line for each monitor.
    extraMonitorSettings =
      mkOption {
        type = types.lines;
        default = "

    ";
        description = "Extra monitor settings for Hyprland.";
      };

    # Bar/Shell Settings
    # Choose between noctalia or waybar
    barChoice = mkOption {
      type = types.enum ["noctalia" "waybar"];
      default = "noctalia";
      description = "Bar/Shell choice.";
    };

    # Waybar Settings (used when barChoice = "waybar")
    clock24h = mkOption {
      type = types.bool;
      default = false;
      description = "Use 24h clock in Waybar.";
    };

    # Program Options
    # Set Default Browser (google-chrome-stable for google-chrome)
    # This does NOT install your browser
    # You need to install it by adding it to the `packages.nix`
    # or as a flatpak
    #
    # refactor TODO: make the options we provide install
    browser = mkOption {
      type = types.str;
      default = "brave";
      description = "Default browser.";
    };
    # Note: kitty, wezterm, alacritty have to be enabled in `variables.nix`
    # Setting it here does not enable it. Kitty is installed by default
    # refactor TODO: combine package insallation and default and options,
    # and make this a package argument so unstable can be given
    terminal = mkOption {
      type = types.str;
      default = "kitty";
      description = "Default system terminal.";
    };

    # Keyboard and Console
    keyboardLayout = mkOption {
      type = types.str;
      default = "us";
      description = "Keyboard layout.";
    };
    keyboardVariant = mkOption {
      type = types.str;
      default = "";
      description = "Keyboard variant.";
    };
    consoleKeyMap = mkOption {
      type = types.str;
      default = "us";
      description = "Console key map.";
    };

    # For hybrid support (Intel/NVIDIA Prime or AMD/NVIDIA)
    intelID = mkOption {
      type = types.str;
      default = "PCI:1:0:0";
      description = "Intel GPU Bus ID.";
    };
    amdgpuID = mkOption {
      type = types.str;
      default = "PCI:5:0:0";
      description = "AMD GPU Bus ID.";
    };
    nvidiaID = mkOption {
      type = types.str;
      default = "PCI:0:2:0";
      description = "Nvidia GPU Bus ID.";
    };

    # Enable NFS
    enableNFS = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NFS.";
    };

    # Enable Printing Support
    printEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable printing support.";
    };
    scannerEnable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable scanning support.";
    };

    # Yazi is default File Manager.
    thunarEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Thunar GUI File Manager.";
    };

    # Themes, waybar and animation

    # Set Stylix Image
    # This will set your color palette
    # Default background
    # Add new images to ~/zaneyos/wallpapers
    stylixImage = mkOption {
      type = types.path;
      example = "../../wallpapers/mountainscapedark.jpg";
      description = "Wallpaper image for Stylix.";
    };
    waybarChoice = mkOption {
      type = types.path;
      example = "../../modules/home/waybar/waybar-curved.nix";
      description = "Path to Waybar configuration file.";
    };
    animChoice = mkOption {
      type = types.path;
      example = "../../modules/home/hyprland/animations-def.nix";
      description = "Path to animation configuration file.";
    };

    enableSmartD = mkOption {
      type = types.bool;
      default = true;
      description = "Can be disabled for hosts without real disks.";
    };

    # Set network hostId if required (needed for zfs)
    # Otherwise leave as-is
    hostId = mkOption {
      type = types.str;
      default = "5ab03f50";
      description = "Network hostId.";
    };

    # Default applications per MIME type (consumed by Home Manager xdg.mimeApps)
    # Example value:
    # {
    #   "application/pdf" = ["okular.desktop"];       # PDF handler
    #   "x-scheme-handler/http" = ["google-chrome.desktop"];  # Browser
    # }
    mimeDefaultApps = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = ''
        Attribute set mapping MIME types or URL schemes to lists of .desktop IDs.
        Applied to xdg.mimeApps.defaultApplications for the user on this host.
      '';
    };
  };
}
