{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  customPkgs = inputs.custom-packages.packages.${system};

  downloadcraft = pkgs.callPackage ./downloadcraft.nix {
    inherit (inputs) downloadcraft-src;
  };
in {
  home.packages =
    [
      # customPkgs.ab-download-manager
      # downloadcraft
    ]
    ++ (with pkgs; [
      pangolin-cli
      #obsidian
      # code-cursor
    ]);
}
