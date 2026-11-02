{
  pkgs,
  lib,
  ...
}: let
  # Build ryoku-shell Go IPC daemon locally from source
  ryokuShell = pkgs.stdenv.mkDerivation {
    pname = "ryoku-shell";
    version = "1.0.0";
    src = ./ryoku/ipc;

    nativeBuildInputs = [
      pkgs.go
      pkgs.makeWrapper
    ];

    postPatch = ''
      # Patch polkit helper path to NixOS store location
      test -x "${lib.getOutput "out" pkgs.polkit}/lib/polkit-1/polkit-agent-helper-1"
      substituteInPlace polkit.go \
        --replace-fail \
          'var polkitHelperPath = "/usr/lib/polkit-1/polkit-agent-helper-1"' \
          'var polkitHelperPath = "${lib.getOutput "out" pkgs.polkit}/lib/polkit-1/polkit-agent-helper-1"'
    '';

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR"
      export GOCACHE="$TMPDIR/go-cache"
      export GOTOOLCHAIN=local

      go build \
        -mod=vendor \
        -trimpath \
        -o ryoku-shell \
        .

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      install -Dm755 ryoku-shell "$out/bin/ryoku-shell"

      wrapProgram "$out/bin/ryoku-shell" \
        --prefix PATH : ${lib.makeBinPath [
          pkgs.quickshell
          pkgs.matugen
          pkgs.coreutils
          pkgs.procps
          pkgs.psmisc
          pkgs.jq
          pkgs.libnotify
          pkgs.wl-clipboard
          pkgs.grim
          pkgs.slurp
        ]}

      runHook postInstall
    '';

    meta = {
      description = "Ryoku desktop shell IPC and process supervisor";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
    };
  };

  # Build Ryoku.Blobs and Ryoku.Spatial3D Qt6/QML C++ plugins
  ryokuBlobs = pkgs.stdenv.mkDerivation {
    pname = "ryoku-blobs";
    version = "1.0.0";
    dontWrapQtApps = true;
    src = ./ryoku/plugin;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.pkg-config
      pkgs.qt6.qtshadertools
    ];

    buildInputs = [
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtmultimedia
      pkgs.qt6.qtquick3d
      pkgs.qt6.qtshadertools
    ];

    preConfigure = ''
      rm -rf build
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/qt-6/qml/Ryoku"
      for module in Blobs Spatial3D; do
        cp -a "qml/Ryoku/$module" "$out/lib/qt-6/qml/Ryoku/$module"
        rm -f "$out/lib/qt-6/qml/Ryoku/$module/"*.qrc
      done

      runHook postInstall
    '';

    meta = {
      description = "Ryoku.Blobs and Ryoku.Spatial3D Qt6/QML modules";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
    };
  };

  # Build pure QML module tree
  ryokuQml = pkgs.runCommand "ryoku-qml-modules" {} ''
    mkdir -p "$out/lib/qt-6/qml/Ryoku/Wm"
    cp -a ${./ryoku/qml/Ryoku/Ui} "$out/lib/qt-6/qml/Ryoku/Ui"
    cp -a ${./ryoku/qml/Ryoku/FrameBars} "$out/lib/qt-6/qml/Ryoku/FrameBars"
    cp -a ${./ryoku/qml/Ryoku/PluginKit} "$out/lib/qt-6/qml/Ryoku/PluginKit"
    cp -a ${./ryoku/qml/Ryoku/Wm/Hyprland} "$out/lib/qt-6/qml/Ryoku/Wm/Hyprland"
  '';
in {
  home.packages = [
    ryokuShell
    ryokuBlobs
    pkgs.quickshell
    pkgs.matugen
    pkgs.grim
    pkgs.slurp
    pkgs.hyprpicker
    pkgs.wl-clipboard
    pkgs.imagemagick
    pkgs.playerctl
    pkgs.brightnessctl
    pkgs.pamixer
  ];

  # Qt and Quickshell environment variables for Ryoku QML module resolution
  home.sessionVariables = {
    QML_IMPORT_PATH = "${ryokuBlobs}/lib/qt-6/qml:${ryokuQml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtquick3d}/lib/qt-6/qml:$HOME/.config/quickshell";
    QML2_IMPORT_PATH = "${ryokuBlobs}/lib/qt-6/qml:${ryokuQml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtquick3d}/lib/qt-6/qml:$HOME/.config/quickshell";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  # Seed Quickshell shell widgets, stage layout, and inir once into ~/.config/quickshell
  # We do NOT manage ui widgets / stage layout declaratively as read-only store symlinks:
  # copying them ensures the user can customize, edit widgets, and adjust stage layout freely.
  home.activation.seedRyokuQuickshell = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    QS_CONFIG="$HOME/.config/quickshell"
    mkdir -p "$QS_CONFIG"

    # Seed Quickshell shell widgets if not already present, keeping them user-mutable
    if [ ! -d "$QS_CONFIG/shell" ]; then
      cp -R "${./ryoku/quickshell/shell}" "$QS_CONFIG/shell"
      chmod -R u+rwX "$QS_CONFIG/shell"
    fi

    # Seed Quickshell stage layout if not already present, keeping it user-mutable
    if [ ! -d "$QS_CONFIG/stage" ]; then
      cp -R "${./ryoku/quickshell/stage}" "$QS_CONFIG/stage"
      chmod -R u+rwX "$QS_CONFIG/stage"
    fi

    # Seed Quickshell inir services if not already present
    if [ ! -d "$QS_CONFIG/inir" ]; then
      cp -R "${./ryoku/quickshell/inir}" "$QS_CONFIG/inir"
      chmod -R u+rwX "$QS_CONFIG/inir"
    fi

    # Seed Quickshell keybind cheat sheet if not already present
    if [ ! -d "$QS_CONFIG/keys" ]; then
      cp -R "${./ryoku/quickshell/keys}" "$QS_CONFIG/keys"
      chmod -R u+rwX "$QS_CONFIG/keys"
    fi
  '';

  # Declarative user systemd service to supervise Ryoku Quickshell daemon
  systemd.user.services.ryoku-shell = {
    Unit = {
      Description = "Ryoku Quickshell desktop service";
      PartOf = ["hyprland-session.target"];
      After = ["hyprland-session.target"];
    };

    Service = {
      Type = "simple";
      Environment = [
        "QML_IMPORT_PATH=${ryokuBlobs}/lib/qt-6/qml:${ryokuQml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtquick3d}/lib/qt-6/qml:%h/.config/quickshell"
        "QML2_IMPORT_PATH=${ryokuBlobs}/lib/qt-6/qml:${ryokuQml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtquick3d}/lib/qt-6/qml:%h/.config/quickshell"
        "QT_QPA_PLATFORM=wayland;xcb"
        "PATH=${lib.makeBinPath [
          ryokuShell
          pkgs.quickshell
          pkgs.matugen
          pkgs.coreutils
          pkgs.procps
          pkgs.psmisc
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gawk
          pkgs.gnused
          pkgs.jq
          pkgs.libnotify
          pkgs.wl-clipboard
          pkgs.grim
          pkgs.slurp
          pkgs.imagemagick
          pkgs.pipewire
          pkgs.pulseaudio
          pkgs.playerctl
          pkgs.brightnessctl
          pkgs.systemd
        ]}:/run/current-system/sw/bin:%h/.nix-profile/bin"
      ];
      ExecStart = "${ryokuShell}/bin/ryoku-shell daemon";
      Restart = "always";
      RestartSec = "2";
    };
  };
}
