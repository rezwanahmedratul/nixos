{...}: {
  # NOTE: xdg.portal is deliberately NOT configured here.
  #
  # programs.hyprland (enabled in modules/core/packages.nix) already turns on
  # xdg.portal and sets xdg.portal.extraPortals to its own
  # xdg-desktop-portal-hyprland build, which is built against the module's
  # hyprland package (overridden with `withUWSM = false`).
  #
  # Listing `pkgs.xdg-desktop-portal-hyprland` here as well pulls in a SECOND,
  # differently instantiated copy of the same portal. Both copies ship
  # lib/systemd/user/xdg-desktop-portal-hyprland.service, and the `user-units`
  # derivation links every systemd.packages unit into one directory, so the
  # second link fails:
  #   ln: failed to create symbolic link '.../xdg-desktop-portal-hyprland.service': File exists
  services = {
    flatpak = {
      enable = true;

      packages = [
        "com.rustdesk.RustDesk"
        "com.usebottles.bottles"
        "com.github.tchx84.Flatseal"
        "com.abdownloadmanager.abdownloadmanager"
      ];

      update.onActivation = true;
    };
  };
}
