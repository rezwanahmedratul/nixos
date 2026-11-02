{zaneyos, ...}: let
  inherit (zaneyos) barChoice stylixImage;
  # Noctalia-specific startup commands
  noctaliaExec =
    if barChoice == "noctalia"
    then [
      "sh -lc 'systemctl --user restart noctalia.service || systemctl --user start noctalia.service || true'"
    ]
    else [];
  # Ryoku-specific startup commands
  ryokuExec =
    if barChoice == "ryoku"
    then [
      "killall -q waybar 2>/dev/null || true"
      "killall -q swaync 2>/dev/null || true"
      "systemctl --user stop noctalia 2>/dev/null || true"
      "pkill -x noctalia 2>/dev/null || true"
      "sh -lc 'systemctl --user restart ryoku-shell || true'"
    ]
    else [
      "systemctl --user stop ryoku-shell 2>/dev/null || true"
      "pkill -x ryoku-shell 2>/dev/null || true"
    ];
  # Waybar-specific startup commands
  waybarExec =
    if barChoice != "noctalia" && barChoice != "ryoku"
    then [
      "killall -q awww;sleep .5 && awww-daemon"
      "killall -q waybar;sleep .5 && waybar"
      "killall -q swaync;sleep .5 && swaync"
      "systemctl --user stop noctalia || true"
      "pkill -x noctalia || true"
      "systemctl --user stop ryoku-shell || true"
      "pkill -x ryoku-shell || true"
      "nm-applet --indicator"
      # Delayed-only restore so Stylix finishes first, then user's wallpaper wins with a single change
      "sh -lc 'sleep 2 && (qs-wallpapers-restore || waypaper --wallpaper ${stylixImage} --backend awww) >/dev/null 2>&1 || true'"
    ]
    else [];
in {
  wayland.windowManager.hyprland.settings = {
    exec-once =
      [
        "wl-paste --type text --watch cliphist store" # Saves text
        "wl-paste --type image --watch cliphist store" # Saves images
        "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprpolkitagent"
        "qs -c overview" # Start quickshell-overview daemon
        "hyprland-change-layout init"
      ]
      ++ noctaliaExec ++ ryokuExec ++ waybarExec;
  };
}
