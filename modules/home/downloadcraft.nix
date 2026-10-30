{
  lib,
  rustPlatform,
  pkg-config,
  copyDesktopItems,
  makeWrapper,
  makeDesktopItem,
  libx11,
  libXcursor,
  libXi,
  libXrandr,
  libxkbcommon,
  wayland,
  libGL,
  dbus,
  fontconfig,
  vulkan-loader,
  ffmpeg,
  yt-dlp,
  downloadcraft-src,
}: let
  runtimeLibs = [
    libGL
    libxkbcommon
    wayland
    libx11
    libXcursor
    libXi
    libXrandr
    fontconfig
    vulkan-loader
  ];
in
  rustPlatform.buildRustPackage {
    pname = "downloadcraft";
    version = let
      ver = lib.strings.fileContents "${downloadcraft-src}/VERSION";
      rev =
        downloadcraft-src.shortRev or (
          if downloadcraft-src ? rev
          then builtins.substring 0 7 downloadcraft-src.rev
          else "latest"
        );
    in "${ver}-${rev}";

    src = downloadcraft-src;

    cargoLock = {
      lockFile = "${downloadcraft-src}/Cargo.lock";
    };

    doCheck = false;

    nativeBuildInputs = [
      pkg-config
      copyDesktopItems
      makeWrapper
    ];

    buildInputs = [
      libx11
      libXcursor
      libXi
      libXrandr
      libxkbcommon
      wayland
      libGL
      dbus
      fontconfig
    ];

    postInstall = ''
      install -Dm644 assets/icon.png $out/share/icons/hicolor/256x256/apps/com.downloadcraft.app.png
      install -Dm644 assets/icon.png $out/share/pixmaps/downloadcraft.png

      # Extensions for browser integration (Chrome / Brave / Firefox)
      mkdir -p $out/lib/downloadcraft
      cp -r browser-extension $out/lib/downloadcraft/browser-extension
      cp -r browser-extension $out/lib/downloadcraft/browser-extension-firefox
      cp browser-extension/manifest-firefox.json $out/lib/downloadcraft/browser-extension-firefox/manifest.json
      rm -f $out/lib/downloadcraft/browser-extension-firefox/manifest-firefox.json \
            $out/lib/downloadcraft/browser-extension-firefox/offscreen.*

      wrapProgram $out/bin/download_craft \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
        --prefix PATH : ${lib.makeBinPath [ffmpeg yt-dlp]}

      ln -s download_craft $out/bin/downloadcraft
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "com.downloadcraft.app";
        desktopName = "Download Craft";
        comment = "Download manager with browser capture";
        exec = "download_craft";
        icon = "com.downloadcraft.app";
        terminal = false;
        categories = ["Network" "FileTransfer"];
        startupNotify = true;
      })
    ];

    meta = with lib; {
      description = "Lightweight offline-first download manager in Rust (egui GUI + CLI)";
      homepage = "https://github.com/hungry-detective/downloadcraft";
      license = licenses.mit;
      mainProgram = "downloadcraft";
      platforms = platforms.linux;
    };
  }
