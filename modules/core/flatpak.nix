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

      # List the Flatpak applications you want to install
      # Use the official Flatpak application ID (e.g., from flathub.org)
      # Examples:
      packages = [
        #"com.github.tchx84.Flatseal" #Manage flatpak permissions - should always have this
        #"com.rtosta.zapzap"              # WhatsApp client
        #"io.github.flattool.Warehouse"   # Manage flatpaks, clean data, remove flatpaks and deps
        "it.mijorus.gearlever" # Manage and support AppImages
        #"io.github.freedoom.Phase1"      #  Classic Doom FPS 1
        #"io.github.freedoom.Phase2"      #  Classic Doom FPS 2
        #"io.github.dvlv.boxbuddyrs"      #  Manage distroboxes
        #"de.schmidhuberj.tubefeeder"     #watch YT videos

        # Add other Flatpak IDs here, e.g., "org.mozilla.firefox"
      ];

      # Optional: Automatically update Flatpaks when you run nixos-rebuild swit ch
      update.onActivation = true;
    };
  };
}
