_: {
  stylix.targets = {
    # Avoid fetching GNOME Shell sources on non-GNOME systems (breaks on some remotes)
    gnome.enable = false;
    waybar.enable = false;
    rofi.enable = false;
    hyprland.enable = false;
    hyprlock.enable = false;
    ghostty.enable = true;
    kitty.enable = true;
    vscode.enable = true;
    qt = {
      enable = true;
      platform = "qtct";
    };
  };
}
