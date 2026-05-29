{
  pkgs,
  lib,
  ...
}: let
  version = "1.8.8";

  # 🔥 Java-safe isolated fontconfig (fixes "head is null")
  fontconfigFile = pkgs.writeText "abdm-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>

      <dir>${pkgs.dejavu_fonts}/share/fonts</dir>
      <dir>${pkgs.noto-fonts}/share/fonts/opentype/noto</dir>
      <dir>${pkgs.fira-code}/share/fonts/truetype</dir>
      <dir>${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype</dir>

      <cachedir>/tmp/fontconfig-abdm-cache</cachedir>

      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Noto Sans</family>
        </prefer>
      </alias>

      <alias>
        <family>monospace</family>
        <prefer>
          <family>JetBrains Mono</family>
        </prefer>
      </alias>

    </fontconfig>
  '';
in {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "ab-download-manager";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
        hash = "sha256-79Q2zepTQkyYYTswE/YgqYB9lErSMFQbbAVm+6roru4=";
      };

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        makeWrapper
      ];

      buildInputs = with pkgs; [
        gtk3
        glib
        zlib
        libX11
        libXext
        libXrender
        libXtst
        libXi
        libXrandr
        libXcursor
        libXinerama
        libxcb
        alsa-lib
        freetype
        fontconfig
        jdk17
      ];

      installPhase = ''
                runHook preInstall

                mkdir -p $out/opt/abdm

                # unpacked source already contains ABDownloadManager/
                cp -r . $out/opt/abdm/

                BIN=$out/opt/abdm/bin/ABDownloadManager

                chmod +x $BIN

                mkdir -p $out/bin

        makeWrapper \
          $BIN \
          $out/bin/ab-download-manager \
          --set JAVA_HOME ${pkgs.jdk17} \
          --set FONTCONFIG_FILE /etc/fonts/fonts.conf \
          --set FONTCONFIG_PATH /etc/fonts \
          --set XDG_DATA_DIRS /run/current-system/sw/share \
          --set LD_LIBRARY_PATH ${pkgs.fontconfig.lib}/lib \
          --set _JAVA_OPTIONS "-Dsun.awt.fontconfig=/etc/fonts/fonts.conf -Dawt.useSystemAAFontSettings=on -Djava.awt.headless=false" \
          --set _JAVA_OPTIONS "-Dawt.useSystemAAFontSettings=on -Dsun.java2d.fontpath=${pkgs.fontconfig.lib}/lib"
                mkdir -p $out/share/applications

                cat > $out/share/applications/abdm.desktop <<EOF
        [Desktop Entry]
        Name=AB Download Manager
        Exec=ab-download-manager
        Type=Application
        Categories=Network;
        Terminal=false
        EOF

                runHook postInstall
      '';
    })
  ];
}