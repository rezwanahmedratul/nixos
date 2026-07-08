{
  config,
  lib,
  pkgs,
}: {
  # Limit concurrency to lower memory pressure during builds
  nix.settings = {
    # Run only 1 build task at a time (highly effective for saving RAM)
    max-jobs = 1;
    # Allow that single job to utilize up to 14 CPU cores
    cores = 16;
  };
}
