{config, ...}: {
  hardware = {
    logitech.wireless.enable = false;
    graphics.enable = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };
  programs.solaar.enable = false;
  local.hardware-clock.enable = false;
}
