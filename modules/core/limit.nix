{
  config,
  lib,
  pkgs,
  ...
}: {
  nix.settings = {
    max-jobs = 1;
    cores = 16;
  };
}
