{
  config,
  lib,
  pkgs,
  ...
}: {
  # Constrain the Nix daemon's resource consumption
  systemd.services.nix-daemon.serviceConfig = {
    # Throttles allocations and cleans up caches once memory hits 14GB
    MemoryHigh = "14G";

    # Enforces a strict cap at 15GB to guarantee 1GB remains free for your system
    MemoryMax = "15G";
  };
}
