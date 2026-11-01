{
  inputs,
  pkgs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  ryokuPkgs = inputs.ryoku.packages.${system};
  materializer = ryokuPkgs.ryoku-materialize;
in {
  home.packages = [
    ryokuPkgs.ryoku-bundle
    pkgs.quickshell
    pkgs.matugen
  ];

  # Qt and Quickshell environment variables for Ryoku QML resolution
  home.sessionVariables = {
    QML_IMPORT_PATH = "${ryokuPkgs.ryoku-qml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
    QML2_IMPORT_PATH = "${ryokuPkgs.ryoku-qml}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  # Activation hook to materialize Ryoku desktop configuration declaratively
  home.activation.ensureRyokuMaterialization = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -x "${materializer}/bin/ryoku-materialize" ]; then
      ${materializer}/bin/ryoku-materialize || true
    fi

    # Trigger shell reload if ryoku-shell is actively running
    if command -v ryoku-shell >/dev/null 2>&1 && pgrep -x ryoku-shell >/dev/null 2>&1; then
      ryoku-shell reload || true
    fi
  '';
}
