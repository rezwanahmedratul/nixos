{
  config,
  pkgs,
  username,
  ...
}: {
  fileSystems."/mnt/nas" = {
    device = "//10.0.0.30/storage";
    fsType = "cifs";

    options = [
      "username=ratul"
      "password=GreenApple25"
      "uid=1000"
      "gid=100"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=5s"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=60"
      "vers=3.0"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/nas 0755 root root -"
    "L /home/${username}/NAS - - - - /mnt/nas"
  ];
}
