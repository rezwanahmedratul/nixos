{
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    # ghee: "git, as a place you leave open", a TUI over every repo in a folder.
    # The flake input only ships packages.<system>.{ghee,default}, so surface it
    # as pkgs.ghee for the rest of the configuration (installed in
    # modules/home/cli/ghee.nix).
    (
      final: prev: {
        ghee = inputs.ghee.packages.${final.stdenv.hostPlatform.system}.ghee;
      }
    )
  ];
}
