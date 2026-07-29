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

      PRIMARY="eDP-1"
      EXTERNAL="HDMI-A-1"

      # -----------------------------
      # Disable presentation mode
      # -----------------------------
      if [[ -f "$STATE" ]]; then
        hyprctl keyword monitor "$PRIMARY,1920x1200@60,0x0,1.20"
        hyprctl keyword monitor "$EXTERNAL,preferred,auto,1"

        rm -f "$STATE"

        notify "🖥️ Extended desktop restored"
        exit 0
      fi

      # -----------------------------
      # Enable presentation mode
      # -----------------------------
      if ! hyprctl monitors | grep -q "^Monitor $EXTERNAL"; then
        notify "❌ No external display connected"
        exit 1
      fi

      hyprctl keyword monitor "$PRIMARY,1920x1200@60,0x0,1.20"
      hyprctl keyword monitor "$EXTERNAL,preferred,0x0,1,mirror,$PRIMARY"

      touch "$STATE"

      notify "📽️ Mirror mode enabled"
    '')
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1200@60,0x0,1.20"
      "HDMI-A-1,preferred,auto,1"
    ];
  };
}