{ config, pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/lib/omniroute 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.omniroute = {
    image = "diegosouzapw/omniroute:latest";

    autoStart = false;

    # In host network mode, port mappings are not needed
    ports = [];

    volumes = [
      "/var/lib/omniroute:/app/data"
    ];

    environment = {
      PORT = "20128";
      HOSTNAME = "127.0.0.1"; # Use "0.0.0.0" if you want LAN access
      DATA_DIR = "/app/data";
    };

    extraOptions = [
      "--network=host"
      "--stop-timeout=40"
    ];
  };
}