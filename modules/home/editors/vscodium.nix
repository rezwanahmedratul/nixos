{ pkgs, lib, ... }:

let
  common = import ./common.nix { inherit pkgs lib; };
in {
  programs.vscodium = {
    enable = true;

    profiles.default = {
      extensions = common.extensions;

      userSettings = lib.mkForce (common.settings pkgs.jdk21);
    };
  };

  home.packages = with pkgs; [ jdk21 ];

  home.file.".config/VSCodium/User/snippets/cpp.json".text =
    common.cppSnippets;
}