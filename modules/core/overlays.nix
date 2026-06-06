{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default

    # Override pangolin-cli to 0.9.0 (nixpkgs lags behind)
    (final: prev: {
      pangolin-cli = prev.pangolin-cli.overrideAttrs (old: {
        version = "0.9.0";
        src = prev.fetchFromGitHub {
          owner = "fosrl";
          repo = "cli";
          tag = "0.9.0";
          hash = prev.lib.fakeHash; # Replace after first failed build
        };
        ldflags = [
          "-X github.com/fosrl/cli/internal/version.Version=0.9.0"
        ];
        vendorHash = prev.lib.fakeHash; # Replace after first failed build
      });
    })

    # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
    (_final: prev: {
      xfce = prev.xfce // {
        tumbler = prev.xfce.tumbler.overrideAttrs (old: {
          buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
        });
      };
    })
  ];
}