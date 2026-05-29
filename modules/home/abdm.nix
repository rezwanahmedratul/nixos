{ pkgs, lib, ... }:

let
  version = "1.8.8";
in
{
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "ab-download-manager";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
        hash = lib.fakeHash;
      };

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        makeWrapper
      ];

      buildInputs = with pkgs; [
        gtk3 glib zlib
        libX11 libXext libXrender libXtst libXi
        libXrandr libXcursor libXinerama libxcb
        alsa-lib freetype fontconfig
        jdk17
      ];

      sourceRoot = ".";

      installPhase = ''
        mkdir -p $out/opt/abdm
        cp -r ./* $out/opt/abdm/

        chmod +x $out/opt/abdm/bin/ABDownloadManager

        mkdir -p $out/bin

        makeWrapper \
          $out/opt/abdm/bin/ABDownloadManager \
          $out/bin/ab-download-manager \
          --set JAVA_HOME ${pkgs.jdk17}

        mkdir -p $out/share/applications

        cat > $out/share/applications/abdm.desktop <<EOF
        [Desktop Entry]
        Name=AB Download Manager
        Exec=ab-download-manager
        Type=Application
        Categories=Network;
        EOF
      '';
    })
  ];
}