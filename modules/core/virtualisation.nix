{pkgs, ...}: {
  # Only enable either docker or podman -- Not both
  virtualisation = {
  
    containers.registries.search = [
      "docker.io"
      "quay.io"
      "ghcr.io"
      ];

    docker = {
      enable = false;
    };

    podman.enable = true;

    libvirtd = {
      enable = true;
    };

    virtualbox.host = {
      enable = false;
      enableExtensionPack = true;
    };
  };

  programs = {
    virt-manager.enable = false;
  };

  environment.systemPackages = with pkgs; [
    #virt-viewer # View Virtual Machines
    #lazydocker
    #docker-client
  ];
}
