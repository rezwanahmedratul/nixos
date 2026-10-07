{pkgs, ...}: {
  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];

    config = {
      hyprland = {
        default = ["hyprland" "gtk"];
      };

      common = {
        default = ["hyprland" "gtk"];
      };
    };

    configPackages = [pkgs.hyprland];
  };

  services.flatpak = {
    enable = true;

    packages = [
      "com.rustdesk.RustDesk"
      "com.usebottles.bottles"
      "com.github.tchx84.Flatseal"
      "io.github.C_Yassin.FlameGet"
    ];

    update.onActivation = true;
  };
}
