{...}: {
  wayland.windowManager.hyprland.settings = {
    # Ryoku Animations Preset
    # Power and beauty in motion: calm settle with slight bloom on window open
    animations = {
      enabled = true;
      bezier = [
        "easeOutQuint, 0.23, 1, 0.32, 1"
        "quick, 0.15, 0, 0.1, 1"
        "almostLinear, 0.5, 0.5, 0.75, 1"
        "ryokuBloom, 0.16, 1.12, 0.24, 1"
        "ryokuSettle, 0.18, 0.86, 0.24, 1"
      ];
      animation = [
        "global, 1, 3.2, ryokuSettle"
        "windows, 1, 3.2, ryokuSettle"
        "windowsIn, 1, 3.8, ryokuBloom, popin 78%"
        "windowsOut, 1, 2.4, ryokuSettle, popin 86%"
        "border, 1, 3.5, quick"
        "fade, 1, 3, almostLinear"
        "fadeIn, 1, 3.2, almostLinear"
        "fadeOut, 1, 2.2, almostLinear"
        "layers, 1, 7, easeOutQuint, popin 90%"
        "fadeLayersIn, 1, 7, easeOutQuint"
        "fadeLayersOut, 1, 7, easeOutQuint"
        "workspaces, 1, 3.5, easeOutQuint, slide"
        "specialWorkspace, 1, 6, easeOutQuint, slidefadevert 20%"
      ];
    };
  };
}

