{ config, pkgs, username, ... }:

{
  fileSystems."/home/${username}/NAS" = {
    device = "//10.0.0.30/shared";
    fsType = "cifs";

    options = [
      "username=ratul"
      "password=GreenApple25"
      "uid=1000"
      "gid=100"
      "file_mode=0644"
      "dir_mode=0755"
      "_netdev"
      "x-systemd.automount"
      "noauto"
      "vers=3.0"
    ];
  };
}