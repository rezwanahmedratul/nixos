{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify
    jq

    (pkgs.writeShellScriptBin "presentation-toggle" ''
      #!/usr/bin/env bash

      set -euo pipefail

      PRIMARY="eDP-1"
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

      # --------------------------------------------------
      # Get connected monitors
      # --------------------------------------------------

      get_monitors() {
        hyprctl monitors -j
      }

      # --------------------------------------------------
      # Disable presentation mode
      # --------------------------------------------------

      if [[ -f "$STATE" ]]; then

        # Restore laptop display
        hyprctl keyword monitor \
          "$PRIMARY,1920x1200@60,0x0,1.20"

        # Restore every connected external monitor
        while read -r monitor; do
          [[ -z "$monitor" ]] && continue
          [[ "$monitor" == "$PRIMARY" ]] && continue

          hyprctl keyword monitor \
            "$monitor,preferred,auto,1"

        done < <(
          get_monitors |
            jq -r --arg primary "$PRIMARY" '
              .[]
              | select(.name != $primary)
              | .name
            '
        )

        rm -f "$STATE"

        notify "Extended desktop restored"
        exit 0
      fi

      # --------------------------------------------------
      # Find external monitors
      # --------------------------------------------------

      EXTERNALS="$(
        get_monitors |
          jq -r --arg primary "$PRIMARY" '
            .[]
            | select(.name != $primary)
            | .name
          '
      )"

      if [[ -z "$EXTERNALS" ]]; then
        notify "No external display connected"
        exit 1
      fi

      # --------------------------------------------------
      # Select external monitor
      #
      # If multiple monitors are connected, use the first
      # external monitor reported by Hyprland.
      # --------------------------------------------------

      EXTERNAL="$(echo "$EXTERNALS" | head -n1)"

      # --------------------------------------------------
      # Get external monitor information
      # --------------------------------------------------

      EXTERNAL_INFO="$(
        get_monitors |
          jq -r --arg monitor "$EXTERNAL" '
            .[]
            | select(.name == $monitor)
          '
      )"

      WIDTH="$(
        echo "$EXTERNAL_INFO" |
          jq -r '.width'
      )"

      HEIGHT="$(
        echo "$EXTERNAL_INFO" |
          jq -r '.height'
      )"

      REFRESH="$(
        echo "$EXTERNAL_INFO" |
          jq -r '.refreshRate'
      )"

      # --------------------------------------------------
      # Validate monitor information
      # --------------------------------------------------

      if [[ -z "$WIDTH" || "$WIDTH" == "null" ||
            -z "$HEIGHT" || "$HEIGHT" == "null" ]]; then

        notify "Could not determine external display resolution"
        exit 1
      fi

      # Hyprland reports refresh rate as a decimal.
      # Round it to an integer for the monitor rule.
      REFRESH_INT="$(
        printf "%.0f" "$REFRESH"
      )"

      # --------------------------------------------------
      # Save state
      # --------------------------------------------------

      printf '%s\n' "$EXTERNAL" > "$STATE"

      # --------------------------------------------------
      # Change laptop resolution
      #
      # The laptop must use the same resolution as the
      # external display for mirroring.
      # --------------------------------------------------

      hyprctl keyword monitor \
        "$PRIMARY,$WIDTH"x"$HEIGHT"@"$REFRESH_INT",0x0,1"

      # --------------------------------------------------
      # Mirror external display
      # --------------------------------------------------

      hyprctl keyword monitor \
        "$EXTERNAL,preferred,0x0,1,mirror,$PRIMARY"

      notify "Mirror mode enabled: $EXTERNAL ($WIDTH"x"$HEIGHT" @ "$REFRESH_INT"Hz)"
    '')
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1,1920x1200@60,0x0,1.20"
      ",preferred,auto,1"
    ];
  };
}