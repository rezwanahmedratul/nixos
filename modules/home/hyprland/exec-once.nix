{zaneyos, ...}: let
  inherit (zaneyos) barChoice stylixImage;

  # Noctalia-specific startup commands
  noctaliaExec =
    if barChoice == "noctalia"
    then [
      "sh -lc 'systemctl --user restart noctalia.service || systemctl --user start noctalia.service || true'"
    ]
    else [];

  # Quickshell II specific startup commands
  quickshellExec =
    if barChoice == "quickshell"
    then [
      "systemctl --user stop noctalia || true"
      "pkill -x noctalia || true"
      "killall -q waybar swaync || true"
      "sh -lc 'systemctl --user restart quickshell.service || systemctl --user start quickshell.service || true'"
    ]
    else [];

  # Waybar-specific startup commands
  waybarExec =
    if barChoice != "noctalia" && barChoice != "quickshell"
    then [
      "killall -q awww;sleep .5 && awww-daemon"
      "killall -q waybar;sleep .5 && waybar"
      "killall -q swaync;sleep .5 && swaync"
      "systemctl --user stop noctalia || true"
      "pkill -x noctalia || true"
      "nm-applet --indicator"
      # Delayed-only restore so Stylix finishes first, then user's wallpaper wins with a single change
      "sh -lc 'sleep 2 && (qs-wallpapers-restore || waypaper --wallpaper ${stylixImage} --backend awww) >/dev/null 2>&1 || true'"
    ]
    else [];

  # Legacy overview daemon (only needed when not using Quickshell II)
  overviewExec =
    if barChoice != "quickshell"
    then ["qs -c overview"]
    else [];

  clipboardExec =
    if barChoice == "quickshell"
    then [
      "wl-paste --type text --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update || true'"
      "wl-paste --type image --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update || true'"
    ]
    else [
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
    ];
in {
  wayland.windowManager.hyprland.settings = {
    exec-once =
      clipboardExec
      ++ [
        "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprpolkitagent"
        "hyprland-change-layout init"
      ]
      ++ overviewExec
      ++ noctaliaExec
      ++ quickshellExec
      ++ waybarExec;
  };
}
