{
  pkgs,
  host,
  lib,
  ...
}: let
  vars = import ../../hosts/${host}/variables.nix;
in {
  xdg = {
    enable = true;
    mime.enable = true;

    mimeApps = {
      enable = true;

      defaultApplications = {
        #
        # PDF
        #
        "application/pdf" = ["org.kde.okular.desktop"];
        "application/x-pdf" = ["org.kde.okular.desktop"];

        #
        # Browser
        #
        "x-scheme-handler/http" = ["zen-beta.desktop"];
        "x-scheme-handler/https" = ["zen-beta.desktop"];
        "x-scheme-handler/about" = ["zen-beta.desktop"];
        "x-scheme-handler/unknown" = ["zen-beta.desktop"];
        "text/html" = ["zen-beta.desktop"];
        "application/xhtml+xml" = ["zen-beta.desktop"];

        #
        # Text
        #
        "text/plain" = ["nvim.desktop"];

        #
        # Images
        #
        "image/png" = ["qimgv.desktop"];
        "image/jpeg" = ["qimgv.desktop"];
        "image/jpg" = ["qimgv.desktop"];
        "image/gif" = ["qimgv.desktop"];
        "image/webp" = ["qimgv.desktop"];
        "image/bmp" = ["qimgv.desktop"];
        "image/tiff" = ["qimgv.desktop"];
        "image/x-tga" = ["qimgv.desktop"];
        "image/x-portable-bitmap" = ["qimgv.desktop"];
        "image/x-portable-graymap" = ["qimgv.desktop"];
        "image/x-portable-pixmap" = ["qimgv.desktop"];
        "image/x-portable-anymap" = ["qimgv.desktop"];
        "image/x-xbitmap" = ["qimgv.desktop"];
        "image/x-xpixmap" = ["qimgv.desktop"];
        "image/heic" = ["qimgv.desktop"];
        "image/heif" = ["qimgv.desktop"];
        "image/avif" = ["qimgv.desktop"];
        "image/svg+xml" = ["qimgv.desktop"];
        "image/x-sony-arw" = ["qimgv.desktop"];
        "image/x-canon-cr2" = ["qimgv.desktop"];
        "image/x-adobe-dng" = ["qimgv.desktop"];
        "image/x-nikon-nef" = ["qimgv.desktop"];
        "image/x-fuji-raf" = ["qimgv.desktop"];

        #
        # Video
        #
        "video/mp4" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "video/x-msvideo" = ["mpv.desktop"];
        "video/quicktime" = ["mpv.desktop"];

        #
        # Audio
        #
        "audio/mpeg" = ["mpv.desktop"];
        "audio/flac" = ["mpv.desktop"];
        "audio/x-wav" = ["mpv.desktop"];
        "audio/ogg" = ["mpv.desktop"];

        #
        # Archives
        #
        "application/zip" = ["org.gnome.FileRoller.desktop"];
        "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
        "application/x-rar" = ["org.gnome.FileRoller.desktop"];
        "application/x-rar-compressed" = ["org.gnome.FileRoller.desktop"];
        "application/x-tar" = ["org.gnome.FileRoller.desktop"];
        "application/gzip" = ["org.gnome.FileRoller.desktop"];
        "application/x-xz" = ["org.gnome.FileRoller.desktop"];

        #
        # Directories
        #
        "inode/directory" = ["org.gnome.Nautilus.desktop"];
      };
    };

    portal = {
      enable = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

      config = {
        common.default = [
          "hyprland"
          "gtk"
        ];

        hyprland.default = [
          "hyprland"
          "gtk"
        ];
      };

      configPackages = [pkgs.hyprland];
    };

    desktopEntries.nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text files in Neovim";
      icon = "nvim";

      exec = "${lib.getExe pkgs.ghostty} -e nvim %F";
      terminal = false;

      mimeType = [
        "text/plain"
        "text/english"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];

      categories = [
        "Utility"
        "TextEditor"
      ];
    };
  };
}