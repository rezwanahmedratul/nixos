{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "presentation-toggle" ''
      #!/usr/bin/env bash

      set -e

      if hyprctl monitors | grep -q "mirrorOf: eDP-1"; then
          # Extended desktop

          hyprctl keyword monitor "eDP-1,1920x1200@60,0x0,1.20"
          hyprctl keyword monitor "HDMI-A-1,1920x1080@60,1600x0,1"

          notify-send "Presentation Mode" "Extended Desktop"
      else
          # Mirror

          hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
          hyprctl keyword monitor "HDMI-A-1,1920x1080@60,0x0,1,mirror,eDP-1"

          notify-send "Presentation Mode" "Mirror Enabled"
      fi
    '')
  ];

  wayland.windowManager.hyprland.settings = {

    monitor = [
      "eDP-1,1920x1200@60,0x0,1.20"
      "HDMI-A-1,1920x1080@60,1600x0,1"
    ];
  };
}