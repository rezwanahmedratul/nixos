{ inputs, ... }:

let
  pangolinVersion = "0.15.0";
in
{
  nixpkgs.overlays = [
    inputs.antigravity-nix.overlays.default

    (final: prev:
      let
        version = pangolinVersion;
      in
      {
        pangolin-cli = prev.pangolin-cli.overrideAttrs (_old: {
          inherit version;

          src = prev.fetchFromGitHub {
            owner = "fosrl";
            repo = "cli";
            tag = version;
            hash = "sha256-6TRO7tBrWH6EeMFEA6FrpvmlCkUcMtiZ5qr/LQjcLeY=";
          };

          ldflags = [
            "-X=github.com/fosrl/cli/internal/version.Version=${version}"
          ];

          vendorHash = "sha256-UmzzZDO2lz/HsrUlnV8Wa4GM8lYgoI0ggJlOvxrd79Q=";
        });
      })

    (_final: prev: {
      xfce = prev.xfce // {
        tumbler = prev.xfce.tumbler.overrideAttrs (old: {
          buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
        });
      };
    })
  ];
}