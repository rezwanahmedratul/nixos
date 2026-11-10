{ config, pkgs, ... }:

{
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.omniroute = {
    image = "diegosouzapw/omniroute:latest";

    autoStart = true;

    ports = [
      "127.0.0.1:20128:20128"
    ];

    volumes = [
      "/var/lib/omniroute:/app/data"
    ];

    environment = {
      PORT = "20128";
      HOSTNAME = "0.0.0.0";
      DATA_DIR = "/app/data";
    };

    extraOptions = [
      "--stop-timeout=40"
    ];
  };
}