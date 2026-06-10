{ pkgs, ... }:

let
  cp-session = pkgs.writeShellScriptBin "cp-session" ''
    #!${pkgs.bash}/bin/bash

    # Open Codeforces in default browser
    xdg-open "https://codeforces.com/problemset" &

    sleep 1

    # Open CP folder in VS Code
    code "$HOME/CP" &

    # Wait for both windows to appear and be tiled
    sleep 2

    # Try to focus browser window (best-effort)
    hyprctl dispatch focuswindow "title:.*Codeforces.*"

    # Set dwindle split ratio (browser ~35%, code ~65%)
    hyprctl dispatch splitratio 0.35
  '';
in
{
  home.packages = [
    cp-session
  ];
}