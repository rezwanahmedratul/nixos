{
  pkgs,
  ...
}: let
  # Quickshell wrapped with all required Qt 6 and KDE QML plugins
  quickshellWrapped = pkgs.stdenv.mkDerivation {
    name = "quickshell-wrapped";
    dontUnpack = true;
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.qt6.wrapQtAppsHook
    ];
    buildInputs = with pkgs; [
      quickshell
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qt5compat
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qttranslations
      qt6.qtvirtualkeyboard
      qt6.qtwayland
      kdePackages.kirigami
      kdePackages.kdialog
      kdePackages.syntax-highlighting
      kdePackages.kconfig
      kdePackages.kguiaddons
      kdePackages.ki18n
      kdePackages.kiconthemes
      kdePackages.qqc2-desktop-style
      gsettings-desktop-schemas
    ];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/qs \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
      makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/quickshell \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
      wrapQtApp $out/bin/qs
      wrapQtApp $out/bin/quickshell
    '';
  };

  # Complete Python environment with all dependencies needed by dots-hyprland
  quickshellPython = pkgs.python3.withPackages (ps: with ps; [
    pillow
    pywayland
    psutil
    kde-material-you-colors
    materialyoucolor
    libsass
    material-color-utilities
    setproctitle
    click
    loguru
    pycairo
    pygobject3
    tqdm
    numpy
    opencv4
    google-auth
    requests
  ]);
in {
  environment.systemPackages = with pkgs; [
    quickshellWrapped
    quickshellPython

    # Rice tooling & utilities
    matugen
    imagemagick
    hyprsunset
    fuzzel
    swappy
    wf-recorder
    tesseract
    songrec
    translate-shell
    libqalculate
    bc
    jq
    brightnessctl
    ddcutil
    wtype

    # KDE utilities used by quickshell widgets
    kdePackages.bluedevil
    kdePackages.plasma-nm
    kdePackages.dolphin
    kdePackages.kdialog
    kdePackages.kconfig

    # Theming / cursors
    bibata-cursors
    darkly
    adw-gtk3
  ];

  # System service for ydotool virtual keyboard & input simulation
  programs.ydotool.enable = true;

  # Ensure PAM service is configured for hyprlock screen unlock
  security.pam.services.hyprlock = {};

  # Kernel modules for DDC/CI monitor control and virtual input
  boot.kernelModules = ["i2c-dev" "uinput"];

  # Udev rules for backlight DDC/CI and input access
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
    KERNEL=="i2c-[0-9]*", GROUP="video", MODE="0660"
  '';

  # Font packages required by the illogical-impulse rice
  fonts.packages = with pkgs; [
    material-symbols
    rubik
    readexpro
    twemoji-color-font
  ];

  # Session environment variables
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = "$HOME/.local/state/quickshell/.venv";
  };
}
