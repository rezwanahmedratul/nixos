{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "ocr-region" ''
      #!/bin/sh

      IMG="/tmp/ocr.png"

      ${pkgs.grim}/bin/grim \
        -g "$(${pkgs.slurp}/bin/slurp)" \
        "$IMG" &&

      ${pkgs.tesseract}/bin/tesseract "$IMG" stdout |
      ${pkgs.wl-clipboard}/bin/wl-copy
    '')
  ];
}