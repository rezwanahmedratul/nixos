{profile, ...}: {
  services.fprintd.enable = true;

  # PAM config
  security.pam.services = {
    sddm.fprintAuth = false;
    sddm-greeter.fprintAuth = false;
    login.fprintAuth = false;
    sudo.fprintAuth = true;
    hyprlock.fprintAuth = true;
    kde.fprintAuth = true;
    polkit-1.fprintAuth = true;
  };
}