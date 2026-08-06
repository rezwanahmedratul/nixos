{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  customPkgs = inputs.custom-packages.packages.${system};
in {
  home.packages =
    [
      customPkgs.ab-download-manager
    ]
    ++ (with pkgs; [
      pangolin-cli
      obsidian
      code-cursor
    ]);
}