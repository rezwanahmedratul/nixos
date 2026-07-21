{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify

    (pkgs.writeShellScriptBin "presentation-toggle" ''
      #!/usr/bin/env bash

      set -euo pipefail

      STATE="$XDG_RUNTIME_DIR/hypr-presentation-mode"

      notify() {
        notify-send \
          -a "Presentation" \
          -u low \
          -h string:x-canonical-private-synchronous:presentation \
          -i video-display \
          "Presentation Mode" \
          "$1"
      }

      # -----------------------------
      # Disable presentation mode
      # -----------------------------
      if [[ -f "$STATE" ]]; then
        hyprctl keyword monitor "eDP-1,1920x1200@60,0x0,1.20"
        hyprctl keyword monitor "HDMI-A-1,1920x1080@60,1600x0,1"

        rm -f "$STATE"

        notify "🖥️ Extended desktop restored"
        exit 0
      fi

      # -----------------------------
      # Enable presentation mode
      # -----------------------------

      # Ensure HDMI monitor is connected
      if ! hyprctl monitors | grep -q "^Monitor HDMI-A-1"; then
        notify "❌ No external display connected"
        exit 1
      fi

      hyprctl keyword monitor "eDP-1,1920x1080@60,0x0,1"
      hyprctl keyword monitor "HDMI-A-1,1920x1080@60,0x0,1,mirror,eDP-1"

      touch "$STATE"

      notify "📽️ Mirror mode enabled"
    '')
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1200@60,0x0,1.20"
      "HDMI-A-1,1920x1080@60,1600x0,1"
    ];
  };
}